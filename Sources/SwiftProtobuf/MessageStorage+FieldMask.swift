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

import Foundation

extension MessageStorage {
    /// Merges fields specified in a field mask from another message storage into this one.
    ///
    /// - Parameters:
    ///   - source: The message storage to merge from.
    ///   - fieldMask: The field mask specifying which fields to merge.
    ///   - mergeOptions: Options for merging the fields.
    func merge(
        from source: MessageStorage,
        fieldMask: Google_Protobuf_FieldMask,
        mergeOptions: Google_Protobuf_FieldMask.MergeOptions
    ) throws {
        let schema = self.schema
        for path in fieldMask.paths {
            let components = path.split(separator: ".")
            guard !components.isEmpty else { continue }

            let component = String(components[0])
            // `fieldNumber(forTextName:)` does a fallback that allows lowercased
            // group names. We don't want to match those for field masks, so we
            // double-check that the name we got back was an exact match.
            guard let fieldNumber = schema.fieldNumber(forTextName: component),
                let textName = schema.textName(forFieldNumber: fieldNumber),
                String(protobufUTF8Name: textName) == component
            else {
                continue
            }

            guard let field = schema[fieldNumber: fieldNumber] else {
                throw FieldMaskError.invalidPath
            }

            if components.count == 1 {
                // We're merging a top-level field, so it can be any type.
                if source.isPresent(field) {
                    try mergeField(field, from: source, mergeOptions: mergeOptions)
                } else {
                    // If the field is in the mask but not in the source, clear it in the destination.
                    clearValue(of: field)
                }
            } else {
                // We're merging a path with multiple components, so the first component must be a
                // message or group.
                guard field.rawFieldType == .message || field.rawFieldType == .group else {
                    throw FieldMaskError.invalidPath
                }

                let subMask = removingPrefix(component, from: fieldMask)
                guard !subMask.paths.isEmpty else { continue }

                if source.isPresent(field) {
                    let sourceSubmessage = source.messageStorage(forAssumedPresentSingularMessageField: field)
                    let destinationSubmessage = self.uniqueMessageStorage(forSingularMessageField: field)
                    try destinationSubmessage.merge(
                        from: sourceSubmessage,
                        fieldMask: subMask,
                        mergeOptions: mergeOptions
                    )
                } else {
                    // If not present in source, but we have a sub-mask, we should still clear fields
                    // in destination according to sub-mask if it exists in destination.
                    clearValue(of: field)
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
                if field.rawFieldType == .message || field.rawFieldType == .group {
                    if isPresent(field) {
                        let subStorage = messageStorage(forAssumedPresentSingularMessageField: field)
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

    /// Copies a field value from source to destination.
    private func mergeField(
        _ field: FieldSchema,
        from source: MessageStorage,
        mergeOptions: Google_Protobuf_FieldMask.MergeOptions
    ) throws {
        let sourcePointer = source.buffer.baseAddress! + field.offset
        let destinationPointer = self.buffer.baseAddress! + field.offset

        // If the destination doesn't have the field set, we can essentially treat that the same
        // as a "replacement".
        let replaceRepeated = mergeOptions.replaceRepeatedFields || !self.isPresent(field)

        switch field.fieldMode.cardinality {
        case .map:
            if replaceRepeated {
                self.deinitializeField(field)
                self.messageSchema(for: field).invokeWitness(
                    .mapCopyInitialize(source: sourcePointer, destination: destinationPointer)
                )
                self.setPresence(of: field)
            } else {
                // Insert the map entries from the source into the destination (overwriting any that
                // have matching keys).
                var mapEntryWorkingSpace = MapEntryWorkingSpace(ownerSchema: self.schema)
                let workingSpace = mapEntryWorkingSpace.storage(for: field.submessageIndex)
                source.forEachMapEntry(
                    in: field,
                    useDeterministicOrdering: false,
                    workingSpace: workingSpace
                ) { entry in
                    self.insertMapEntry(in: field, from: entry)
                    return .continue
                }
            }

        case .array:
            switch field.rawFieldType {
            case .bool:
                mergeRepeatedField(field, from: source, replace: replaceRepeated, type: [Bool].self)

            case .bytes:
                mergeRepeatedField(field, from: source, replace: replaceRepeated, type: [Data].self)

            case .double:
                mergeRepeatedField(field, from: source, replace: replaceRepeated, type: [Double].self)

            case .enum:
                if replaceRepeated {
                    self.deinitializeField(field)
                    self.enumSchema(for: field).invokeWitness(
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
                mergeRepeatedField(field, from: source, replace: replaceRepeated, type: [UInt32].self)

            case .fixed64, .uint64:
                mergeRepeatedField(field, from: source, replace: replaceRepeated, type: [UInt64].self)

            case .float:
                mergeRepeatedField(field, from: source, replace: replaceRepeated, type: [Float].self)

            case .group, .message:
                if replaceRepeated {
                    self.deinitializeField(field)
                    self.messageSchema(for: field).invokeWitness(
                        .arrayCopyInitialize(source: sourcePointer, destination: destinationPointer)
                    )
                    self.setPresence(of: field)
                } else {
                    // For each message in the source array, create a new message in the destination
                    // and then copy the fields of the source message into the destination message.
                    source.forEachMessage(inAssumedPresentRepeatedMessageField: field) { sourceStorage in
                        let destinationStorage =
                            self.messageStorage(forNewlyAppendedElementOfRepeatedMessageField: field)
                        let sourcePointer = sourceStorage.buffer.baseAddress!
                        let destinationPointer = destinationStorage.buffer.baseAddress!
                        self.messageSchema(for: field).invokeWitness(
                            .messageCopyInitialize(source: sourcePointer, destination: destinationPointer)
                        )
                        return .continue
                    }
                }

            case .int32, .sfixed32, .sint32:
                mergeRepeatedField(field, from: source, replace: replaceRepeated, type: [Int32].self)

            case .int64, .sfixed64, .sint64:
                mergeRepeatedField(field, from: source, replace: replaceRepeated, type: [Int64].self)

            case .string:
                mergeRepeatedField(field, from: source, replace: replaceRepeated, type: [String].self)

            default:
                preconditionFailure("Unreachable")
            }

        case .scalar:
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
                self.updateValue(of: field, to: source.value(of: field) as Double)

            case .float:
                self.updateValue(of: field, to: source.value(of: field) as Float)

            case .group, .message:
                let submessageSchema = source.messageSchema(for: field)
                if self.isPresent(field) {
                    // Recursively merge the fields of the source message into the destination message.
                    let sourceSubstorage = source.messageStorage(forAssumedPresentSingularMessageField: field)
                    let destinationSubstorage = self.uniqueMessageStorage(forSingularMessageField: field)

                    var subPaths: [String] = []
                    for f in submessageSchema.fields {
                        if let name = submessageSchema.textName(forFieldNumber: f.fieldNumber) {
                            subPaths.append(String(decoding: name.buffer, as: UTF8.self))
                        }
                    }
                    let fullSubMask = Google_Protobuf_FieldMask(protoPaths: subPaths)
                    try destinationSubstorage.merge(
                        from: sourceSubstorage,
                        fieldMask: fullSubMask,
                        mergeOptions: mergeOptions
                    )
                } else {
                    // If the destination field is not set, copy the source message into the
                    // destination message.
                    submessageSchema.invokeWitness(
                        .messageCopyInitialize(source: sourcePointer, destination: destinationPointer)
                    )
                    self.setPresence(of: field)
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

        default:
            preconditionFailure("Unreachable")
        }
    }

    /// Merges the values of a repeated field from the source into the destination.
    ///
    /// - Parameters:
    ///   - field: The field to merge.
    ///   - source: The source message storage.
    ///   - destination: The destination message storage.
    ///   - replace: If true, the elements in the destination should be replaced; otherwise, they
    ///     should be appended to the existing values.
    ///   - type: The array type of the repeated field.
    private func mergeRepeatedField<T>(
        _ field: FieldSchema,
        from source: MessageStorage,
        replace: Bool,
        type: [T].Type
    ) {
        let sourcePointer = (source.buffer.baseAddress! + field.offset).bindMemory(to: [T].self, capacity: 1)
        let destinationPointer = (self.buffer.baseAddress! + field.offset).bindMemory(to: [T].self, capacity: 1)

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
    private func setPresence(of field: FieldSchema) {
        switch field.presence {
        case .hasBit(let byteOffset, let mask):
            _ = updatePresence(hasBit: (byteOffset, mask), willBeSet: true)
        case .oneOfMember(let oneofOffset):
            _ = updatePopulatedOneofMember((oneofOffset, field.fieldNumber))
        }
    }

    /// Clears the value of a field and returns a value indicating whether that changed the message.
    @discardableResult
    private func clearValue(of field: FieldSchema) -> Bool {
        if isPresent(field) {
            deinitializeField(field)

            switch field.presence {
            case .hasBit(let byteOffset, let mask):
                _ = updatePresence(hasBit: (byteOffset, mask), willBeSet: false)
            case .oneOfMember(let oneofOffset):
                (buffer.baseAddress! + oneofOffset).bindMemory(to: UInt32.self, capacity: 1).pointee = 0
            }
            return true
        }
        return false
    }
}

/// Returns a new FieldMask containing paths that start with the given prefix,
/// with the prefix removed.
///
/// For example, if the mask has paths `["a.b", "a.c", "d"]` and the prefix is `"a"`,
/// the returned mask will have paths `["b", "c"]`. Fields that lack the prefix are
/// dropped.
private func removingPrefix(
    _ prefix: String,
    from fieldMask: Google_Protobuf_FieldMask
) -> Google_Protobuf_FieldMask {
    var subPaths: [String] = []
    let prefixWithDot = "\(prefix)."
    for path in fieldMask.paths {
        if path.hasPrefix(prefixWithDot) {
            subPaths.append(String(path.dropFirst(prefixWithDot.count)))
        }
    }
    return .with { $0.paths = subPaths }
}
