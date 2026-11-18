// Sources/SwiftProtobuf/MessageStorage+FieldMask.swift - FieldMask support for MessageStorage
//
// Copyright (c) 2014 - 2026 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Extend `MessageStorage` with methods to support `FieldMask` operations.
///
// -----------------------------------------------------------------------------

#if FieldMaskUtilities

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// A prefix trie of field-mask paths used by `MessageStorage.merge`.
///
/// Building the trie once per `merge` call groups paths that share a prefix so each submessage is
/// traversed at most once, collapses duplicates and descendants covered by an ancestor leaf
/// (matching C++ `FieldMaskTree`), short-circuits unknown or invalid prefixes without allocating
/// nodes for trailing components, and validates every reachable non-leaf segment iteratively
/// before any destination storage is mutated.
internal struct FieldMaskMergeTrie {
    internal struct Child {
        internal let field: MessageSchema.Field
        internal let nodeIndex: Int
    }

    internal struct Node {
        internal var isLeaf: Bool = false
        internal var hasInvalidSubpath: Bool = false
        internal var hasResolvedLeaf: Bool = false
        internal var children: [Child] = []
        internal var childIndexByFieldNumber: [UInt32: Int]?
    }

    internal var nodes: [Node] = [Node()]

    internal var hasResolvedLeaf: Bool {
        nodes[0].hasResolvedLeaf
    }

    internal init(paths: [String], rootSchema: MessageSchema) throws {
        for path in paths where !path.isEmpty {
            try insert(path, rootSchema: rootSchema)
        }
        try validateAndFinalize()
    }

    private mutating func insert(_ path: String, rootSchema: MessageSchema) throws {
        let utf8 = path.utf8
        var cursor = utf8.startIndex
        var current = 0
        var schema = rootSchema

        while true {
            if current != 0 && nodes[current].isLeaf {
                // An ancestor path is already a leaf and covers this descendant path.
                return
            }

            let dotIndex = utf8[cursor...].firstIndex(of: UInt8(ascii: "."))
            let endIndex = dotIndex ?? utf8.endIndex
            guard cursor < endIndex else {
                // Empty component (leading, trailing, or consecutive dot): unknown field name.
                return
            }

            let component = String(decoding: utf8[cursor..<endIndex], as: UTF8.self)
            // `fieldNumber(forTextName:)` has a fallback that allows lowercased group names.
            // Field masks require exact proto field names, so double-check the name.
            guard
                let fieldNumber = schema.fieldNumber(forTextName: component),
                let textName = schema.textName(forFieldNumber: fieldNumber),
                textName.utf8CodeUnitsEqual(component)
            else {
                // Unknown field name: skip without allocating nodes for trailing segments.
                return
            }

            guard let field = schema[fieldNumber: fieldNumber] else {
                throw FieldMaskError.invalidPath
            }

            let childNodeIndex = childNode(for: field, in: current)

            if let dotIndex {
                if nodes[childNodeIndex].isLeaf {
                    // An ancestor leaf already covers this descendant path.
                    return
                }
                guard
                    field.fieldMode.cardinality == .scalar
                        && (field.rawFieldType == .message || field.rawFieldType == .group)
                else {
                    // Defer throwing until finalization in case a later path in the mask names this
                    // ancestor field directly and subsumes this invalid sub-path.
                    nodes[childNodeIndex].hasInvalidSubpath = true
                    return
                }
                current = childNodeIndex
                schema = schema.messageSchema(for: field)
                cursor = utf8.index(after: dotIndex)
            } else {
                // Mark this node as a leaf and prune any previously inserted descendant paths.
                nodes[childNodeIndex].isLeaf = true
                nodes[childNodeIndex].hasInvalidSubpath = false
                nodes[childNodeIndex].children.removeAll()
                nodes[childNodeIndex].childIndexByFieldNumber = nil
                return
            }
        }
    }

    private mutating func childNode(for field: MessageSchema.Field, in parentIndex: Int) -> Int {
        let fieldNumber = field.fieldNumber
        if let existingPos = findChildIndex(for: fieldNumber, in: parentIndex) {
            return nodes[parentIndex].children[existingPos].nodeIndex
        }
        let nextIndex = nodes.count
        nodes.append(Node())
        let childPos = nodes[parentIndex].children.count
        nodes[parentIndex].children.append(Child(field: field, nodeIndex: nextIndex))
        if nodes[parentIndex].childIndexByFieldNumber != nil {
            nodes[parentIndex].childIndexByFieldNumber![fieldNumber] = childPos
        } else if nodes[parentIndex].children.count > 8 {
            var index = [UInt32: Int](minimumCapacity: nodes[parentIndex].children.count)
            for (i, child) in nodes[parentIndex].children.enumerated() {
                index[child.field.fieldNumber] = i
            }
            nodes[parentIndex].childIndexByFieldNumber = index
        }
        return nextIndex
    }

    private func findChildIndex(for fieldNumber: UInt32, in nodeIndex: Int) -> Int? {
        if let index = nodes[nodeIndex].childIndexByFieldNumber {
            return index[fieldNumber]
        }
        for i in nodes[nodeIndex].children.indices {
            if nodes[nodeIndex].children[i].field.fieldNumber == fieldNumber {
                return i
            }
        }
        return nil
    }

    /// Validates that no reachable non-leaf node carries an invalid sub-path and propagates
    /// `hasResolvedLeaf` bottom-up so unknown-only sub-paths never allocate empty submessages or
    /// trigger unnecessary CoW copies.
    private mutating func validateAndFinalize() throws {
        var stack: [Int] = [0]
        var visitedOrder: [Int] = []
        while let nodeIndex = stack.popLast() {
            visitedOrder.append(nodeIndex)
            if nodes[nodeIndex].isLeaf {
                continue
            }
            if nodes[nodeIndex].hasInvalidSubpath {
                throw FieldMaskError.invalidPath
            }
            for child in nodes[nodeIndex].children {
                stack.append(child.nodeIndex)
            }
        }

        for nodeIndex in visitedOrder.reversed() {
            if nodes[nodeIndex].isLeaf {
                nodes[nodeIndex].hasResolvedLeaf = true
                continue
            }
            var resolved = false
            for child in nodes[nodeIndex].children {
                if nodes[child.nodeIndex].hasResolvedLeaf {
                    resolved = true
                    break
                }
            }
            nodes[nodeIndex].hasResolvedLeaf = resolved
        }
    }
}

extension MessageStorage {
    /// Merges fields specified by a validated `FieldMaskMergeTrie` from another message storage
    /// into this one.
    ///
    /// - Parameters:
    ///   - source: The message storage to merge from.
    ///   - trie: The validated prefix trie specifying which fields to merge.
    ///   - mergeOptions: Options for merging the fields.
    internal func merge(
        from source: MessageStorage,
        trie: FieldMaskMergeTrie,
        mergeOptions: Google_Protobuf_FieldMask.MergeOptions
    ) {
        struct Frame {
            let dest: MessageStorage
            let source: MessageStorage?
            let nodeIndex: Int
            var nextChildIndex: Int
        }

        var stack: [Frame] = [Frame(dest: self, source: source, nodeIndex: 0, nextChildIndex: 0)]
        var pendingSubmessages: [(dest: MessageStorage, source: MessageStorage)] = []

        while !stack.isEmpty {
            let frameIndex = stack.count - 1
            let nodeIndex = stack[frameIndex].nodeIndex
            let childIndex = stack[frameIndex].nextChildIndex
            let children = trie.nodes[nodeIndex].children

            guard childIndex < children.count else {
                stack.removeLast()
                continue
            }
            stack[frameIndex].nextChildIndex = childIndex + 1

            let child = children[childIndex]
            let field = child.field

            let dest = stack[frameIndex].dest
            let src = stack[frameIndex].source
            let sourceIsPresent = src?.isPresent(field) ?? false

            if trie.nodes[child.nodeIndex].isLeaf {
                switch field.fieldMode.cardinality {
                case .map, .array:
                    if sourceIsPresent {
                        dest.mergeRepeatedOrMapField(
                            field,
                            from: src!,
                            replace: mergeOptions.replaceRepeatedFields || !dest.isPresent(field),
                            pendingSubmessages: &pendingSubmessages
                        )
                        if !pendingSubmessages.isEmpty {
                            Self.drainPendingSubmessageMerges(&pendingSubmessages)
                        }
                    } else if mergeOptions.replaceRepeatedFields {
                        dest.clearValue(of: field)
                    }

                case .scalar:
                    switch field.rawFieldType {
                    case .group, .message:
                        if mergeOptions.replaceMessageFields {
                            if sourceIsPresent {
                                dest.copySingularMessageField(field, from: src!)
                            } else {
                                dest.clearValue(of: field)
                            }
                        } else if sourceIsPresent {
                            if dest.isPresent(field) {
                                let srcSub = src!.messageStorage(forAssumedPresentSingularMessageField: field)
                                let destSub = dest.uniqueMessageStorage(forSingularMessageField: field)
                                pendingSubmessages.append((dest: destSub, source: srcSub))
                                Self.drainPendingSubmessageMerges(&pendingSubmessages)
                            } else {
                                dest.copySingularMessageField(field, from: src!)
                            }
                        }

                    default:
                        if sourceIsPresent {
                            dest.copyScalarField(field, from: src!)
                        } else {
                            dest.clearValue(of: field)
                        }
                    }

                default:
                    preconditionFailure("Unreachable")
                }
            } else {
                // Non-leaf path: already validated as a singular message or group field.
                guard trie.nodes[child.nodeIndex].hasResolvedLeaf else { continue }
                if sourceIsPresent {
                    let srcSub = src!.messageStorage(forAssumedPresentSingularMessageField: field)
                    let destSub = dest.uniqueMessageStorage(forSingularMessageField: field)
                    stack.append(Frame(dest: destSub, source: srcSub, nodeIndex: child.nodeIndex, nextChildIndex: 0))
                } else if dest.isPresent(field) {
                    let destSub = dest.uniqueMessageStorage(forSingularMessageField: field)
                    stack.append(Frame(dest: destSub, source: nil, nodeIndex: child.nodeIndex, nextChildIndex: 0))
                }
            }
        }
    }

    /// Removes from this storage any field that is not represented in the given field mask.
    @discardableResult
    func trim(keeping fieldMask: Google_Protobuf_FieldMask, prefix: String = "") -> Bool {
        var changed = false

        for field in schema.fields {
            guard let name = schema.textName(forFieldNumber: field.fieldNumber) else {
                continue
            }
            let subPath = String(protobufUTF8Name: name)
            let fullPath = prefix.isEmpty ? subPath : "\(prefix).\(subPath)"
            if fieldMask.contains(fullPath) {
                continue
            }

            // Check if the current field is a prefix of any path in the mask.
            let isPrefix = fieldMask.paths.contains { $0.hasPrefix("\(fullPath).") }
            if isPrefix {
                if field.fieldMode.cardinality == .scalar
                    && (field.rawFieldType == .message || field.rawFieldType == .group)
                {
                    if isPresent(field) {
                        let subStorage = uniqueMessageStorage(forSingularMessageField: field)
                        if subStorage.trim(keeping: fieldMask, prefix: fullPath) {
                            changed = true
                        }
                    }
                }
            } else {
                // It's not in the mask nor is it a prefix of any that are in the mask, so clear it.
                if clearValue(of: field) {
                    changed = true
                }
            }
        }
        return changed
    }

    /// Iteratively merges all present fields, extensions, and unknown fields for each
    /// `(dest, source)` message pair on `stack`, matching C++ `Message::MergeFrom` semantics.
    private static func drainPendingSubmessageMerges(
        _ stack: inout [(dest: MessageStorage, source: MessageStorage)]
    ) {
        while let (dest, source) = stack.popLast() {
            let schema = dest.schema
            for field in schema.fields {
                guard source.isPresent(field) else { continue }

                switch field.fieldMode.cardinality {
                case .map, .array:
                    dest.mergeRepeatedOrMapField(
                        field,
                        from: source,
                        replace: !dest.isPresent(field),
                        pendingSubmessages: &stack
                    )

                case .scalar:
                    switch field.rawFieldType {
                    case .group, .message:
                        if dest.isPresent(field) {
                            let srcSub = source.messageStorage(forAssumedPresentSingularMessageField: field)
                            let destSub = dest.uniqueMessageStorage(forSingularMessageField: field)
                            stack.append((dest: destSub, source: srcSub))
                        } else {
                            dest.copySingularMessageField(field, from: source)
                        }

                    default:
                        dest.copyScalarField(field, from: source)
                    }

                default:
                    preconditionFailure("Unreachable")
                }
            }

            if !source.extensionStorage.values.isEmpty {
                dest.extensionStorage.mergeAllPresentExtensions(
                    from: source.extensionStorage,
                    pendingSubmessages: &stack
                )
            }

            if !source.unknownFields.data.isEmpty {
                dest.unknownFields.append(protobufData: source.unknownFields.data)
            }
        }
    }

    /// Merges a present repeated or map field from `source` into this storage.
    private func mergeRepeatedOrMapField(
        _ field: MessageSchema.Field,
        from source: MessageStorage,
        replace: Bool,
        pendingSubmessages: inout [(dest: MessageStorage, source: MessageStorage)]
    ) {
        let sourcePointer = source.rawPointer(for: field)
        let destinationPointer = self.rawPointer(for: field)

        switch field.fieldMode.cardinality {
        case .map:
            if replace {
                self.deinitializeField(field)
                let mapSchema = self.messageSchema(for: field)
                mapSchema.invokeWitness(
                    .mapCopyInitialize(source: sourcePointer, destination: destinationPointer)
                )
                self.setPresence(of: field)
            } else {
                // Insert the map entries from the source into the destination (overwriting any that
                // have matching keys).
                var mapEntryWorkingSpace = MapEntryWorkingSpace(ownerSchema: self.schema)
                if let workingSpace = mapEntryWorkingSpace.storage(for: field.submessageIndex) {
                    source.forEachMapEntry(
                        in: field,
                        useDeterministicOrdering: false,
                        workingSpace: workingSpace
                    ) { entry in
                        self.insertMapEntry(in: field, from: entry)
                        return .continue
                    }
                }
            }

        case .array:
            switch field.rawFieldType {
            case .bool:
                mergeRepeatedField(field, from: source, replace: replace, type: [Bool].self)

            case .bytes:
                mergeRepeatedField(field, from: source, replace: replace, type: [Data].self)

            case .double:
                mergeRepeatedField(field, from: source, replace: replace, type: [Double].self)

            case .enum:
                if source.elementCount(forAssumedPresentRepeatedEnumField: field) == 0 {
                    if replace {
                        self.clearValue(of: field)
                    }
                    return
                }
                if replace {
                    self.deinitializeField(field)
                    let resolvedEnumSchema = self.enumSchema(for: field)
                    resolvedEnumSchema.invokeWitness(
                        .arrayCopyInitialize(source: sourcePointer, destination: destinationPointer)
                    )
                    self.setPresence(of: field)
                } else {
                    source.forEachRawValue(inAssumedPresentRepeatedEnumField: field) { rawValue in
                        self.appendEnumValue(withRawValue: rawValue, toRepeatedEnumField: field)
                        return .continue
                    }
                }

            case .fixed32, .uint32:
                mergeRepeatedField(field, from: source, replace: replace, type: [UInt32].self)

            case .fixed64, .uint64:
                mergeRepeatedField(field, from: source, replace: replace, type: [UInt64].self)

            case .float:
                mergeRepeatedField(field, from: source, replace: replace, type: [Float].self)

            case .group, .message:
                if source.elementCount(forAssumedPresentRepeatedMessageField: field) == 0 {
                    if replace {
                        self.clearValue(of: field)
                    }
                    return
                }
                if replace {
                    self.deinitializeField(field)
                    let submessageSchema = self.messageSchema(for: field)
                    submessageSchema.invokeWitness(
                        .arrayCopyInitialize(source: sourcePointer, destination: destinationPointer)
                    )
                    self.setPresence(of: field)
                } else {
                    // For each message in the source array, append a new empty message in the
                    // destination and queue its fields to be copied into the new storage.
                    source.forEachMessage(inAssumedPresentRepeatedMessageField: field) { sourceStorage in
                        let destinationStorage =
                            self.messageStorage(forNewlyAppendedElementOfRepeatedMessageField: field)
                        pendingSubmessages.append((dest: destinationStorage, source: sourceStorage))
                        return .continue
                    }
                }

            case .int32, .sfixed32, .sint32:
                mergeRepeatedField(field, from: source, replace: replace, type: [Int32].self)

            case .int64, .sfixed64, .sint64:
                mergeRepeatedField(field, from: source, replace: replace, type: [Int64].self)

            case .string:
                mergeRepeatedField(field, from: source, replace: replace, type: [String].self)

            default:
                preconditionFailure("Unreachable")
            }

        default:
            preconditionFailure("Unreachable")
        }
    }

    /// Copies a present non-message scalar field from `source` into this storage.
    private func copyScalarField(_ field: MessageSchema.Field, from source: MessageStorage) {
        switch field.rawFieldType {
        case .bool:
            self.updateValue(of: field, to: source.value(of: field) as Bool)

        case .bytes:
            self.updateValue(of: field, to: source.value(of: field) as Data)

        case .enum:
            self.updateValue(of: field, to: source.value(of: field) as Int32)

        case .int32, .sfixed32, .sint32:
            self.updateValue(of: field, to: source.value(of: field) as Int32)

        case .int64, .sfixed64, .sint64:
            self.updateValue(of: field, to: source.value(of: field) as Int64)

        case .double:
            let value = source.value(of: field) as Double
            let offset = schema.byteOffset(of: field)
            switch field.presence {
            case .hasBit(let hasByteOffset, let hasMask):
                // Preserve `-0.0` on proto3 implicit-presence fields without leaving non-zero
                // sign bits in `buffer` alongside a cleared has-bit.
                let willBeSet = schema.fieldHasPresence(field) ? true : (value != 0 || value.sign == .minus)
                updateValue(
                    at: offset,
                    to: willBeSet ? value : 0,
                    willBeSet: willBeSet,
                    hasBit: (hasByteOffset, hasMask)
                )
            case .oneOfMember(let oneofOffset):
                updateValue(at: offset, to: value, oneofPresence: (oneofOffset, field.fieldNumber))
            }

        case .float:
            let value = source.value(of: field) as Float
            let offset = schema.byteOffset(of: field)
            switch field.presence {
            case .hasBit(let hasByteOffset, let hasMask):
                // Preserve `-0.0` on proto3 implicit-presence fields without leaving non-zero
                // sign bits in `buffer` alongside a cleared has-bit.
                let willBeSet = schema.fieldHasPresence(field) ? true : (value != 0 || value.sign == .minus)
                updateValue(
                    at: offset,
                    to: willBeSet ? value : 0,
                    willBeSet: willBeSet,
                    hasBit: (hasByteOffset, hasMask)
                )
            case .oneOfMember(let oneofOffset):
                updateValue(at: offset, to: value, oneofPresence: (oneofOffset, field.fieldNumber))
            }

        case .string:
            self.updateValue(of: field, to: source.value(of: field) as String)

        case .uint32, .fixed32:
            self.updateValue(of: field, to: source.value(of: field) as UInt32)

        case .uint64, .fixed64:
            self.updateValue(of: field, to: source.value(of: field) as UInt64)

        default:
            preconditionFailure("Unreachable")
        }
    }

    /// Replaces a singular message or group field in this storage with a CoW copy of the present
    /// field in `source`, properly deinitializing any previously set field or oneof member.
    private func copySingularMessageField(_ field: MessageSchema.Field, from source: MessageStorage) {
        switch field.presence {
        case .hasBit:
            if isPresent(field) {
                deinitializeFieldForced(field)
            }
        case .oneOfMember(let oneofOffset):
            clearPopulatedOneofMember(at: oneofOffset)
        }
        let submessageSchema = source.messageSchema(for: field)
        submessageSchema.invokeWitness(
            .messageCopyInitialize(
                source: source.rawPointer(for: field),
                destination: self.rawPointer(for: field)
            )
        )
        self.setPresence(of: field)
    }

    /// Merges the values of a repeated field from the source into the destination.
    ///
    /// - Parameters:
    ///   - field: The field to merge.
    ///   - source: The source message storage.
    ///   - replace: If true, the elements in the destination should be replaced; otherwise, they
    ///     should be appended to the existing values.
    ///   - type: The array type of the repeated field.
    private func mergeRepeatedField<T>(
        _ field: MessageSchema.Field,
        from source: MessageStorage,
        replace: Bool,
        type: [T].Type
    ) {
        let sourcePointer = source.typedPointer(for: field, as: [T].self)
        if sourcePointer.pointee.isEmpty {
            if replace {
                self.clearValue(of: field)
            }
            return
        }
        let destinationPointer = self.typedPointer(for: field, as: [T].self)

        if replace {
            // Deinitialize the field (a no-op if it's not already present) and then copy-initialize
            // the new value.
            self.deinitializeField(field)
            destinationPointer.initialize(to: sourcePointer.pointee)
            self.setPresence(of: field)
        } else {
            // Append the new elements to the existing array.
            destinationPointer.pointee.append(contentsOf: sourcePointer.pointee)
        }
    }

    /// Updates the presence of the given field to indicate that it is set.
    private func setPresence(of field: MessageSchema.Field) {
        switch field.presence {
        case .hasBit(let byteOffset, let mask):
            _ = updatePresence(hasBit: (byteOffset, mask), willBeSet: true)
        case .oneOfMember(let oneofOffset):
            _ = updatePopulatedOneofMember((oneofOffset, field.fieldNumber))
        }
    }

    /// Clears the value of a field and returns a value indicating whether that changed the message.
    @discardableResult
    private func clearValue(of field: MessageSchema.Field) -> Bool {
        guard isPresent(field) else { return false }

        switch field.presence {
        case .hasBit(let byteOffset, let mask):
            deinitializeFieldForced(field)
            _ = updatePresence(hasBit: (byteOffset, mask), willBeSet: false)
            let byteCount: Int
            switch field.fieldMode.cardinality {
            case .scalar:
                byteCount = field.scalarStride
            case .array, .map:
                byteCount = MemoryLayout<UnsafeRawPointer>.stride
            default:
                preconditionFailure("Unreachable")
            }
            zeroOut(pointer: rawPointer(for: field), count: byteCount)

        case .oneOfMember(let oneofOffset):
            clearPopulatedOneofMember(at: oneofOffset)
        }
        return true
    }
}

extension ExtensionStorage {
    /// Merges all extension values from `source` into this storage, matching C++
    /// `ExtensionSet::MergeFrom` semantics.
    internal func mergeAllPresentExtensions(
        from source: ExtensionStorage,
        pendingSubmessages: inout [(dest: MessageStorage, source: MessageStorage)]
    ) {
        for (fieldNumber, srcValue) in source.values {
            let ext = srcValue.schema
            let field = ext.field

            switch field.fieldMode.cardinality {
            case .map:
                preconditionFailure("Unreachable")

            case .array:
                switch field.rawFieldType {
                case .bool:
                    appendExtensionArray(ext, from: srcValue, type: [Bool].self)
                case .bytes:
                    appendExtensionArray(ext, from: srcValue, type: [Data].self)
                case .double:
                    appendExtensionArray(ext, from: srcValue, type: [Double].self)
                case .enum:
                    let count = source.elementCount(forAssumedPresentRepeatedEnumField: ext)
                    guard count > 0 else { continue }
                    if values[fieldNumber] == nil {
                        let destValue = ExtensionValueStorage(uninitializedMessageExtensionField: ext)
                        ext.enumSchema.invokeWitness(
                            .arrayCopyInitialize(
                                source: srcValue.unsafeRawPointer,
                                destination: destValue.unsafeMutableRawPointer
                            )
                        )
                        values[fieldNumber] = destValue
                    } else {
                        source.forEachRawValue(inAssumedPresentRepeatedEnumField: ext) { rawValue in
                            self.appendEnumValue(withRawValue: rawValue, toRepeatedEnumField: ext)
                            return .continue
                        }
                    }
                case .group, .message:
                    let count = source.elementCount(forAssumedPresentRepeatedMessageField: ext)
                    guard count > 0 else { continue }
                    if values[fieldNumber] == nil {
                        let destValue = ExtensionValueStorage(uninitializedMessageExtensionField: ext)
                        ext.messageSchema.invokeWitness(
                            .arrayCopyInitialize(
                                source: srcValue.unsafeRawPointer,
                                destination: destValue.unsafeMutableRawPointer
                            )
                        )
                        values[fieldNumber] = destValue
                    } else {
                        source.forEachMessage(inAssumedPresentRepeatedMessageField: ext) { srcStorage in
                            let destStorage =
                                self.messageStorage(forNewlyAppendedElementOfRepeatedMessageField: ext)
                            pendingSubmessages.append((dest: destStorage, source: srcStorage))
                            return .continue
                        }
                    }
                case .fixed32, .uint32:
                    appendExtensionArray(ext, from: srcValue, type: [UInt32].self)
                case .fixed64, .uint64:
                    appendExtensionArray(ext, from: srcValue, type: [UInt64].self)
                case .float:
                    appendExtensionArray(ext, from: srcValue, type: [Float].self)
                case .int32, .sfixed32, .sint32:
                    appendExtensionArray(ext, from: srcValue, type: [Int32].self)
                case .int64, .sfixed64, .sint64:
                    appendExtensionArray(ext, from: srcValue, type: [Int64].self)
                case .string:
                    appendExtensionArray(ext, from: srcValue, type: [String].self)
                default:
                    preconditionFailure("Unreachable")
                }

            case .scalar:
                switch field.rawFieldType {
                case .bytes:
                    updateValue(of: ext, to: srcValue.value(as: Data.self))

                case .group, .message:
                    if values[fieldNumber] != nil {
                        let srcStorage = source.messageStorage(forAssumedPresentSingularMessageField: ext)
                        let destStorage = self.uniqueMessageStorage(forSingularMessageField: ext)
                        pendingSubmessages.append((dest: destStorage, source: srcStorage))
                    } else {
                        let destValue = ExtensionValueStorage(uninitializedMessageExtensionField: ext)
                        ext.messageSchema.invokeWitness(
                            .messageCopyInitialize(
                                source: srcValue.unsafeRawPointer,
                                destination: destValue.unsafeMutableRawPointer
                            )
                        )
                        values[fieldNumber] = destValue
                    }

                case .string:
                    updateValue(of: ext, to: srcValue.value(as: String.self))

                default:
                    // POD scalar or enum raw value stored inline in `ExtensionValueStorage`.
                    values[fieldNumber]?.release()
                    values[fieldNumber] = srcValue
                }

            default:
                preconditionFailure("Unreachable")
            }
        }
    }

    private func appendExtensionArray<T>(
        _ ext: ExtensionSchema,
        from srcValue: ExtensionValueStorage,
        type: [T].Type
    ) {
        let srcArray = srcValue.value(as: [T].self)
        guard !srcArray.isEmpty else { return }
        if let existing = values[ext.field.fieldNumber] {
            existing.unsafeMutablePointerToValue(as: [T].self).pointee.append(contentsOf: srcArray)
        } else {
            values[ext.field.fieldNumber] = ExtensionValueStorage(schema: ext, value: srcArray)
        }
    }
}

#endif
