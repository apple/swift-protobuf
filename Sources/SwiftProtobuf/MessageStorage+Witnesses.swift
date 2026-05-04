// Sources/SwiftProtobuf/MessageStorage+Witnesses.swift - Message/enum witness helpers
//
// Copyright (c) 2014 - 2026 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Helper methods for calling message, enum, and map witness functions to keep
/// the call sites within the rest of the runtime clean.
///
// -----------------------------------------------------------------------------

// MARK: - Submessage/enum field schema resolvers

extension MessageStorage {
    /// Returns the message schema for the given field.
    ///
    /// - Precondition: The field must be a message, group, or map field.
    func messageSchema(for field: FieldSchema) -> MessageSchema {
        let resolution = schema.submessageOrEnumResolver(MessageSchema.TrampolineToken(index: field.submessageIndex))
        guard case .message(let subSchema) = resolution else {
            preconditionFailure("Field should have a message schema; this is a generator bug")
        }
        return subSchema
    }

    /// Returns the enum schema for the given field.
    ///
    /// - Precondition: The field must be an enum field.
    func enumSchema(for field: FieldSchema) -> EnumSchema {
        let resolution = schema.submessageOrEnumResolver(MessageSchema.TrampolineToken(index: field.submessageIndex))
        guard case .enum(let enumSchema) = resolution else {
            preconditionFailure("Field should have an enum schema; this is a generator bug")
        }
        return enumSchema
    }
}

// MARK: - Message witness helpers

extension MessageStorage {
    /// Returns the storage for the given submessage field.
    ///
    /// - Precondition: The field must be present and must be a message or group field.
    func messageStorage(forAssumedPresentSingularMessageField field: FieldSchema) -> MessageStorage {
        let pointer = buffer.baseAddress! + field.offset
        var submessageStorage: Unmanaged<MessageStorage>? = nil
        withUnsafeMutablePointer(to: &submessageStorage) {
            messageSchema(for: field).invokeWitness(.messageGetStorage(pointer: pointer, result: $0))
        }
        return submessageStorage!.takeUnretainedValue()
    }

    /// Returns storage for the given singular message field, ensuring that it is unique for mutation.
    ///
    /// If the field is not yet present, its value will be initialized first.
    ///
    /// - Precondition: The field must be a singular message or group field.
    @inline(never)
    func uniqueMessageStorage(forSingularMessageField field: FieldSchema) -> MessageStorage {
        let pointer = buffer.baseAddress! + field.offset
        let submessageSchema = messageSchema(for: field)

        var submessageStorage: Unmanaged<MessageStorage>? = nil
        withUnsafeMutablePointer(to: &submessageStorage) { submessageStoragePointer in
            if !isPresent(field) {
                // If the field is not present, initialize it and update its presence.
                submessageSchema.invokeWitness(.messageInitialize(pointer: pointer, result: submessageStoragePointer))
                switch field.presence {
                case .hasBit(let hasByteOffset, let hasMask):
                    _ = updatePresence(hasBit: (hasByteOffset, hasMask), willBeSet: true)
                case .oneOfMember(let oneofOffset):
                    _ = updatePopulatedOneofMember((oneofOffset, field.fieldNumber))
                }
            } else {
                // The message already exists, so ensure that its storage is unique for mutation
                // before returning it.
                submessageSchema.invokeWitness(
                    .messageGetUniqueStorage(pointer: pointer, result: submessageStoragePointer)
                )
            }
        }
        return submessageStorage!.takeUnretainedValue()
    }

    /// Returns the number of elements for the given repeated submessage field.
    ///
    /// - Precondition: The field must be present and must be a repeated message or group field.
    func elementCount(forAssumedPresentRepeatedMessageField field: FieldSchema) -> Int {
        let pointer = buffer.baseAddress! + field.offset
        var count: Int = 0
        withUnsafeMutablePointer(to: &count) {
            messageSchema(for: field).invokeWitness(.arrayGetCount(pointer: pointer, result: $0))
        }
        return count
    }

    /// Returns the storage for the element at the given index in the given repeated submessage field.
    ///
    /// - Precondition: The field must be present and must be a repeated message or group field.
    func messageStorage(at index: Int, inAssumedPresentRepeatedMessageField field: FieldSchema) -> MessageStorage {
        let pointer = buffer.baseAddress! + field.offset
        var submessageStorage: Unmanaged<MessageStorage>? = nil
        withUnsafeMutablePointer(to: &submessageStorage) {
            messageSchema(for: field).invokeWitness(.arrayGetElementStorage(pointer: pointer, index: index, result: $0))
        }
        return submessageStorage!.takeUnretainedValue()
    }

    /// Performs the given action for each message in the repeated message or group field.
    ///
    /// - Precondition: The field must be present and must be a repeated message or group field.
    func forEachMessage(
        inAssumedPresentRepeatedField field: FieldSchema,
        perform: (MessageStorage) throws -> Void
    ) rethrows {
        let count = elementCount(forAssumedPresentRepeatedMessageField: field)
        for i in 0..<count {
            try perform(messageStorage(at: i, inAssumedPresentRepeatedMessageField: field))
        }
    }

    /// Appends a new element to the repeated message or group field and returns its storage.
    ///
    /// If the field is not yet present, its array value will be initialized first.
    ///
    /// - Precondition: The field must be a repeated message or group field.
    func messageStorage(forNewlyAppendedElementOfRepeatedMessageField field: FieldSchema) -> MessageStorage {
        let pointer = buffer.baseAddress! + field.offset
        let submessageSchema = messageSchema(for: field)

        if !isPresent(field) {
            // If the field is not present, initialize it with an empty array and update its presence.
            submessageSchema.invokeWitness(.arrayInitialize(pointer: pointer))
            switch field.presence {
            case .hasBit(let hasByteOffset, let hasMask):
                _ = updatePresence(hasBit: (hasByteOffset, hasMask), willBeSet: true)
            case .oneOfMember(let oneofOffset):
                _ = updatePopulatedOneofMember((oneofOffset, field.fieldNumber))
            }
        }

        // Append a new element to the array and return its storage.
        var submessageStorage: Unmanaged<MessageStorage>? = nil
        withUnsafeMutablePointer(to: &submessageStorage) {
            submessageSchema.invokeWitness(.arrayAppendNew(pointer: pointer, result: $0))
        }
        return submessageStorage!.takeUnretainedValue()
    }

    /// Clears the singular message or group field.
    ///
    /// If the field is not present, this method does nothing.
    ///
    /// - Precondition: The field must be a singular message or group field.
    func clearSingularMessageField(_ field: FieldSchema) {
        guard isPresent(field) else { return }

        let pointer = buffer.baseAddress! + field.offset
        switch field.presence {
        case .hasBit(let hasByteOffset, let hasMask):
            let wasSet = updatePresence(hasBit: (hasByteOffset, hasMask), willBeSet: false)
            if wasSet {
                deinitializeField(field)
                pointer.withMemoryRebound(to: UInt8.self, capacity: field.scalarStride) { bytes in
                    bytes.initialize(repeating: 0, count: field.scalarStride)
                }
            }
        case .oneOfMember(let oneofOffset):
            clearPopulatedOneofMember(at: oneofOffset)
        }
    }

    /// Clears the repeated or map field.
    ///
    /// If the field is not present, this method does nothing.
    ///
    /// - Precondition: The field must be a repeated or map field.
    func clearRepeatedOrMapField(_ field: FieldSchema) {
        precondition(field.fieldMode.cardinality != .scalar)
        guard isPresent(field) else { return }

        let pointer = buffer.baseAddress! + field.offset
        switch field.presence {
        case .hasBit(let hasByteOffset, let hasMask):
            let wasSet = updatePresence(hasBit: (hasByteOffset, hasMask), willBeSet: false)
            if wasSet {
                deinitializeField(field)
                // We take advantage of the fact that repeated fields and maps are stored as
                // `Array` and `Dictionary` respectively, and both of these types are frozen
                // with a single pointer representation. This avoids having to invoke a
                // witness just to get at the size of the actual collection type.
                pointer.withMemoryRebound(to: UInt8.self, capacity: MemoryLayout<UnsafeRawPointer>.stride) { bytes in
                    bytes.initialize(repeating: 0, count: MemoryLayout<UnsafeRawPointer>.stride)
                }
            }
        case .oneOfMember:
            preconditionFailure("Unreachable")
        }
    }
}

// MARK: - Enum witness helpers

extension MessageStorage {
    /// Returns the number of elements for the given repeated enum field.
    ///
    /// - Precondition: The field must be present and must be a repeated enum field.
    func elementCount(forAssumedPresentRepeatedEnumField field: FieldSchema) -> Int {
        let pointer = buffer.baseAddress! + field.offset
        var count: Int = 0
        withUnsafeMutablePointer(to: &count) {
            enumSchema(for: field).invokeWitness(.arrayGetCount(pointer: pointer, result: $0))
        }
        return count
    }

    /// Returns the raw value for the enum element at the given index in the given repeated enum field.
    ///
    /// - Precondition: The field must be present and must be a repeated enum field.
    func rawValue(at index: Int, inAssumedPresentRepeatedEnumField field: FieldSchema) -> Int32 {
        let pointer = buffer.baseAddress! + field.offset
        var value: Int32 = 0
        withUnsafeMutablePointer(to: &value) {
            enumSchema(for: field).invokeWitness(.arrayGetElementRawValue(pointer: pointer, index: index, result: $0))
        }
        return value
    }

    /// Performs the given action for each raw value in the repeated enum field.
    ///
    /// - Precondition: The field must be present and must be a repeated enum field.
    func forEachRawValue(
        inAssumedPresentRepeatedEnumField field: FieldSchema,
        perform: (Int32) throws -> Void
    ) rethrows {
        let count = elementCount(forAssumedPresentRepeatedEnumField: field)
        for i in 0..<count {
            try perform(rawValue(at: i, inAssumedPresentRepeatedEnumField: field))
        }
    }

    /// Appends a new element with the given raw value to the repeated enum field.
    ///
    /// If the field is not yet present, its array value will be initialized first.
    ///
    /// - Precondition: The field must be a repeated enum field.
    func appendEnumValue(withRawValue rawValue: Int32, toRepeatedEnumField field: FieldSchema) {
        let pointer = buffer.baseAddress! + field.offset
        let enumSchema = enumSchema(for: field)

        if !isPresent(field) {
            // If the field is not present, initialize it with an empty array and update its presence.
            enumSchema.invokeWitness(.arrayInitialize(pointer: pointer))
            switch field.presence {
            case .hasBit(let hasByteOffset, let hasMask):
                _ = updatePresence(hasBit: (hasByteOffset, hasMask), willBeSet: true)
            case .oneOfMember(let oneofOffset):
                _ = updatePopulatedOneofMember((oneofOffset, field.fieldNumber))
            }
        }
        enumSchema.invokeWitness(.arrayAppendRawValue(pointer: pointer, rawValue: rawValue))
    }
}

// MARK: - Map witness helpers

extension MessageStorage {
    /// Performs the given closure for each entry in the given map field.
    ///
    /// - Precondition: The field must be present and must be a map field.
    ///
    /// - Parameters:
    ///   - field: The map field to iterate over.
    ///   - useDeterministicOrdering: If true, the iteration order is deterministic.
    ///   - workingSpace: The map-entry-shaped `MessageStorage` that will be used to hold the
    ///     key and value of each entry during the iteration.
    ///   - perform: The closure to perform for each map entry.
    @inline(never)
    func forEachMapEntry(
        in field: FieldSchema,
        useDeterministicOrdering: Bool,
        workingSpace: MessageStorage,
        perform: (MessageStorage) throws -> Void
    ) rethrows {
        let pointer = buffer.baseAddress! + field.offset
        let mapSchema = messageSchema(for: field)

        // Compute the required size and alignment for the map iterator.
        var iteratorSize = 0
        var iteratorAlignment = 0
        withUnsafeMutablePointer(to: &iteratorSize) { iteratorSizePointer in
            withUnsafeMutablePointer(to: &iteratorAlignment) { iteratorAlignmentPointer in
                mapSchema.invokeWitness(
                    .mapGetIteratorSize(
                        useDeterministicOrdering: useDeterministicOrdering,
                        size: iteratorSizePointer,
                        alignment: iteratorAlignmentPointer
                    )
                )
            }
        }

        // Create a temporary allocation to hold the map iterator. Though never *guaranteed* by the
        // language, this is very likely to be allocated on the stack rather than the heap.
        try withUnsafeTemporaryAllocation(byteCount: iteratorSize, alignment: iteratorAlignment) { iteratorBuffer in
            // Initialize the iterator into the buffer.
            mapSchema.invokeWitness(
                .mapInitializeIterator(
                    pointer: pointer,
                    iterator: iteratorBuffer.baseAddress!,
                    useDeterministicOrdering: useDeterministicOrdering
                )
            )
            defer {
                mapSchema.invokeWitness(
                    .mapDeinitializeIterator(
                        iterator: iteratorBuffer.baseAddress!,
                        useDeterministicOrdering: useDeterministicOrdering
                    )
                )
            }

            func gotNextElement() -> Bool {
                var success: Bool = false
                withUnsafeMutablePointer(to: &success) { successPointer in
                    mapSchema.invokeWitness(
                        .mapNextElement(
                            iterator: iteratorBuffer.baseAddress!,
                            useDeterministicOrdering: useDeterministicOrdering,
                            workingSpace: workingSpace,
                            success: successPointer
                        )
                    )
                }
                return success
            }

            // Iterate through the map elements, copying the key and value into the working space.
            while gotNextElement() {
                try perform(workingSpace)
            }
        }
    }

    /// Inserts a new entry into the map field that has been read into the given working space.
    ///
    /// If the field is not yet present, its map value will be initialized first.
    ///
    /// - Precondition: The field must be a map field.
    @inline(never)
    func insertMapEntry(in field: FieldSchema, from workingSpace: MessageStorage) {
        let pointer = buffer.baseAddress! + field.offset
        let mapSchema = messageSchema(for: field)

        if !isPresent(field) {
            // If the field is not present, initialize it with an empty dictionary and update its presence.
            mapSchema.invokeWitness(.mapInitialize(pointer: pointer))
            switch field.presence {
            case .hasBit(let hasByteOffset, let hasMask):
                _ = updatePresence(hasBit: (hasByteOffset, hasMask), willBeSet: true)
            case .oneOfMember(let oneofOffset):
                _ = updatePopulatedOneofMember((oneofOffset, field.fieldNumber))
            }
        }
        mapSchema.invokeWitness(.mapInsertElement(pointer: pointer, workingSpace: workingSpace))
    }

    /// Checks equality between two map fields.
    ///
    /// - Precondition: The field must be present and must be a map field.
    func isMapField(_ field: FieldSchema, equalToSameFieldIn other: MessageStorage) -> Bool {
        let mapSchema = messageSchema(for: field)
        let pointer = buffer.baseAddress! + field.offset
        let otherPointer = other.buffer.baseAddress! + field.offset
        var result: Bool = false
        withUnsafeMutablePointer(to: &result) {
            mapSchema.invokeWitness(.mapCheckEquality(lhs: pointer, rhs: otherPointer, result: $0))
        }
        return result
    }
}
