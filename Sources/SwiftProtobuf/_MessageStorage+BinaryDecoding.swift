// Sources/SwiftProtobuf/_MessageStorage+BinaryDecoding.swift - Binary decoding for messages
//
// Copyright (c) 2014 - 2025 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Binary decoding support for `_MessageStorage.`
///
// -----------------------------------------------------------------------------

import Foundation

extension _MessageStorage {
    /// Decodes field values from the given binary-encoded buffer into this storage class.
    ///
    /// - Parameters:
    ///   - buffer: The binary-encoded message data to decode.
    ///   - partial: If `false` (the default), this method will check
    ///     ``Message/isInitialized-6abgi`` after decoding to verify that all required
    ///     fields are present. If any are missing, this method throws
    ///     ``BinaryDecodingError/missingRequiredFields``.
    ///   - options: The ``BinaryDecodingOptions`` to use.
    /// - Throws: ``BinaryDecodingError`` if decoding fails.
    public func merge(
        byReadingFrom buffer: UnsafeRawBufferPointer,
        partial: Bool,
        options: BinaryDecodingOptions
    ) throws {
        var reader = WireFormatReader(buffer: buffer, recursionBudget: options.messageDepthLimit)
        try merge(byReadingFrom: &reader, partial: partial, discardUnknownFields: options.discardUnknownFields)
    }

    /// Decodes field values from the given wire format reader into this storage class.
    ///
    /// - Parameters:
    ///   - buffer: The binary-encoded message data to decode.
    ///   - partial: If `false` (the default), this method will check
    ///     ``Message/isInitialized-6abgi`` after decoding to verify that all required
    ///     fields are present. If any are missing, this method throws
    ///     ``BinaryDecodingError/missingRequiredFields``.
    ///   - discardUnknownFields: If true, unknown fields will be discarded during
    ///     parsing.
    private func merge(
        byReadingFrom reader: inout WireFormatReader,
        partial: Bool,
        discardUnknownFields: Bool
    ) throws {
        var mapEntryWorkingSpace = MapEntryWorkingSpace(ownerLayout: layout)
        while reader.hasAvailableData {
            let tag = try reader.nextTag()
            let consumed = try decodeNextField(
                from: &reader,
                tag: tag,
                partial: partial,
                discardUnknownFields: discardUnknownFields,
                mapEntryWorkingSpace: &mapEntryWorkingSpace
            )
            if !consumed {
                try decodeUnknownField(from: &reader, tag: tag, discard: discardUnknownFields)
            }
        }
        if reader.isTrackingGroup {
            // If `nextTag` saw the expected end-group tag, it would have cleared out the reader's
            // group tracking state. If that didn't happen, then we ran out of data too early.
            throw BinaryDecodingError.truncated
        }
        if !partial && !isInitialized {
            throw BinaryDecodingError.missingRequiredFields
        }
    }

    /// Decodes the next field from the binary reader, assuming that its tag has already been read.
    ///
    /// - Parameters:
    ///   - reader: The reader from which to read the next field's data.
    ///   - tag: The tag that was just read from the reader.
    /// - Returns: True if the field was consumed, or false to indicate that it should be stored in
    ///   unknown fields (for example, because the field did not exist or the data on the wire did
    ///   not match the expected wire format)).
    private func decodeNextField(
        from reader: inout WireFormatReader,
        tag: FieldTag,
        partial: Bool,
        discardUnknownFields: Bool,
        mapEntryWorkingSpace: inout MapEntryWorkingSpace
    ) throws -> Bool {
        guard tag.wireFormat != .endGroup else {
            // Just consume it; `nextTag` has already validated that it matches the last started
            // group.
            return true
        }

        guard let field = layout[fieldNumber: UInt32(tag.fieldNumber)] else {
            // If the field number didn't exist, return false to indicate to the caller that the
            // field wasn't consumed so that they can put it into unknown fields.

            // TODO: When we come back to support extension fields, make sure we handle those
            // correctly, since that might hit this code path depending on how we represent them.
            return false
        }

        switch field.fieldMode.cardinality {
        case .map:
            guard tag.wireFormat == .lengthDelimited else { return false }
            _ = try layout.performOnMapEntry(
                _MessageLayout.TrampolineToken(index: field.submessageIndex),
                field,
                self,
                mapEntryWorkingSpace.storage(for: field.submessageIndex),
                .append,
                // Deterministic ordering doesn't apply to decoding.
                false
            ) { workingSpace in
                try reader.withReaderForNextLengthDelimitedSlice { subReader in
                    try workingSpace.merge(byReadingFrom: &subReader, partial: partial, discardUnknownFields: true)
                }
                return true
            }

        case .array:
            switch field.rawFieldType {
            case .bool:
                return try appendMaybePackedValues(from: &reader, to: field, tag: tag, unpackedWireFormat: .varint) {
                    try $0.nextVarint() != 0
                }

            case .bytes:
                guard tag.wireFormat == .lengthDelimited else { return false }
                try reader.nextLengthDelimitedSlice().withMemoryRebound(to: UInt8.self) { buffer in
                    appendValue(Data(buffer: buffer), to: field)
                }

            case .double:
                return try appendMaybePackedValues(from: &reader, to: field, tag: tag, unpackedWireFormat: .fixed64) {
                    Double(bitPattern: try $0.nextLittleEndianUInt64())
                }

            case .enum:
                switch tag.wireFormat {
                case .varint:
                    try updateEnumValue(of: field, from: &reader, fieldNumber: tag.fieldNumber, isRepeated: true)
                case .lengthDelimited:
                    try appendPackedEnumValues(from: &reader, to: field, fieldNumber: tag.fieldNumber)
                default:
                    return false
                }

            case .fixed32:
                return try appendMaybePackedValues(from: &reader, to: field, tag: tag, unpackedWireFormat: .fixed32) {
                    try $0.nextLittleEndianUInt32()
                }

            case .fixed64:
                return try appendMaybePackedValues(from: &reader, to: field, tag: tag, unpackedWireFormat: .fixed64) {
                    try $0.nextLittleEndianUInt64()
                }

            case .float:
                return try appendMaybePackedValues(from: &reader, to: field, tag: tag, unpackedWireFormat: .fixed32) {
                    Float(bitPattern: try $0.nextLittleEndianUInt32())
                }

            case .group:
                guard tag.wireFormat == .startGroup else { return false }
                _ = try layout.performOnSubmessageStorage(
                    _MessageLayout.TrampolineToken(index: field.submessageIndex),
                    field,
                    self,
                    .append
                ) { submessageStorage in
                    try reader.withReaderForNextGroup(withFieldNumber: UInt32(tag.fieldNumber)) { subReader in
                        try submessageStorage.merge(
                            byReadingFrom: &subReader,
                            partial: partial,
                            discardUnknownFields: discardUnknownFields
                        )
                    }
                    return true
                }

            case .int32:
                return try appendMaybePackedValues(from: &reader, to: field, tag: tag, unpackedWireFormat: .varint) {
                    // If the number on the wire is larger than fits into an `Int32`, this is not an
                    // error; we truncate it.
                    Int32(truncatingIfNeeded: try $0.nextVarint())
                }

            case .int64:
                return try appendMaybePackedValues(from: &reader, to: field, tag: tag, unpackedWireFormat: .varint) {
                    Int64(truncatingIfNeeded: try $0.nextVarint())
                }

            case .message:
                guard tag.wireFormat == .lengthDelimited else { return false }
                _ = try layout.performOnSubmessageStorage(
                    _MessageLayout.TrampolineToken(index: field.submessageIndex),
                    field,
                    self,
                    .append
                ) { submessageStorage in
                    try reader.withReaderForNextLengthDelimitedSlice { subReader in
                        try submessageStorage.merge(
                            byReadingFrom: &subReader,
                            partial: partial,
                            discardUnknownFields: discardUnknownFields
                        )
                    }
                    return true
                }

            case .sfixed32:
                return try appendMaybePackedValues(from: &reader, to: field, tag: tag, unpackedWireFormat: .fixed32) {
                    Int32(bitPattern: try $0.nextLittleEndianUInt32())
                }

            case .sfixed64:
                return try appendMaybePackedValues(from: &reader, to: field, tag: tag, unpackedWireFormat: .fixed64) {
                    Int64(bitPattern: try $0.nextLittleEndianUInt64())
                }

            case .sint32:
                return try appendMaybePackedValues(from: &reader, to: field, tag: tag, unpackedWireFormat: .varint) {
                    // If the number on the wire is larger than fits into an `Int32`, this is not an
                    // error; we truncate it.
                    ZigZag.decoded(UInt32(truncatingIfNeeded: try $0.nextVarint()))
                }

            case .sint64:
                return try appendMaybePackedValues(from: &reader, to: field, tag: tag, unpackedWireFormat: .varint) {
                    ZigZag.decoded(try $0.nextVarint())
                }

            case .string:
                guard tag.wireFormat == .lengthDelimited else { return false }
                let buffer = try reader.nextLengthDelimitedSlice()
                guard let string = utf8ToString(bytes: buffer.baseAddress!, count: buffer.count) else {
                    throw BinaryDecodingError.invalidUTF8
                }
                appendValue(string, to: field)

            case .uint32:
                return try appendMaybePackedValues(from: &reader, to: field, tag: tag, unpackedWireFormat: .varint) {
                    // If the number on the wire is larger than fits into a `UInt32`, this is not an
                    // error; we truncate it.
                    UInt32(truncatingIfNeeded: try $0.nextVarint())
                }

            case .uint64:
                return try appendMaybePackedValues(from: &reader, to: field, tag: tag, unpackedWireFormat: .varint) {
                    try $0.nextVarint()
                }

            default:
                preconditionFailure("Unreachable")
            }

        case .scalar:
            switch field.rawFieldType {
            case .bool:
                guard tag.wireFormat == .varint else { return false }
                updateValue(of: field, to: try reader.nextVarint() != 0)

            case .bytes:
                guard tag.wireFormat == .lengthDelimited else { return false }
                try reader.nextLengthDelimitedSlice().withMemoryRebound(to: UInt8.self) { buffer in
                    updateValue(of: field, to: Data(buffer: buffer))
                }

            case .double:
                guard tag.wireFormat == .fixed64 else { return false }
                updateValue(of: field, to: Double(bitPattern: try reader.nextLittleEndianUInt64()))

            case .enum:
                guard tag.wireFormat == .varint else { return false }
                try updateEnumValue(of: field, from: &reader, fieldNumber: tag.fieldNumber, isRepeated: false)

            case .fixed32:
                guard tag.wireFormat == .fixed32 else { return false }
                updateValue(of: field, to: try reader.nextLittleEndianUInt32())

            case .fixed64:
                guard tag.wireFormat == .fixed64 else { return false }
                updateValue(of: field, to: try reader.nextLittleEndianUInt64())

            case .float:
                guard tag.wireFormat == .fixed32 else { return false }
                updateValue(of: field, to: Float(bitPattern: try reader.nextLittleEndianUInt32()))

            case .group:
                guard tag.wireFormat == .startGroup else { return false }
                _ = try layout.performOnSubmessageStorage(
                    _MessageLayout.TrampolineToken(index: field.submessageIndex),
                    field,
                    self,
                    .mutate
                ) { submessageStorage in
                    try reader.withReaderForNextGroup(withFieldNumber: UInt32(tag.fieldNumber)) { subReader in
                        try submessageStorage.merge(
                            byReadingFrom: &subReader,
                            partial: partial,
                            discardUnknownFields: discardUnknownFields
                        )
                    }
                    return true
                }

            case .int32:
                guard tag.wireFormat == .varint else { return false }
                // If the number on the wire is larger than fits into an `Int32`, this is not an
                // error; we truncate it.
                updateValue(of: field, to: Int32(truncatingIfNeeded: try reader.nextVarint()))

            case .int64:
                guard tag.wireFormat == .varint else { return false }
                updateValue(of: field, to: Int64(bitPattern: try reader.nextVarint()))

            case .message:
                guard tag.wireFormat == .lengthDelimited else { return false }
                _ = try layout.performOnSubmessageStorage(
                    _MessageLayout.TrampolineToken(index: field.submessageIndex),
                    field,
                    self,
                    .mutate
                ) { submessageStorage in
                    try reader.withReaderForNextLengthDelimitedSlice { subReader in
                        try submessageStorage.merge(
                            byReadingFrom: &subReader,
                            partial: partial,
                            discardUnknownFields: discardUnknownFields
                        )
                    }
                    return true
                }

            case .sfixed32:
                guard tag.wireFormat == .fixed32 else { return false }
                updateValue(of: field, to: Int32(bitPattern: try reader.nextLittleEndianUInt32()))

            case .sfixed64:
                guard tag.wireFormat == .fixed64 else { return false }
                updateValue(of: field, to: Int64(bitPattern: try reader.nextLittleEndianUInt64()))

            case .sint32:
                guard tag.wireFormat == .varint else { return false }
                // If the number on the wire is larger than fits into an `Int32`, this is not an
                // error; we truncate it.
                updateValue(of: field, to: ZigZag.decoded(UInt32(truncatingIfNeeded: try reader.nextVarint())))

            case .sint64:
                guard tag.wireFormat == .varint else { return false }
                updateValue(of: field, to: ZigZag.decoded(try reader.nextVarint()))

            case .string:
                guard tag.wireFormat == .lengthDelimited else { return false }
                let buffer = try reader.nextLengthDelimitedSlice()
                guard let string = utf8ToString(bytes: buffer.baseAddress!, count: buffer.count) else {
                    throw BinaryDecodingError.invalidUTF8
                }
                updateValue(of: field, to: string)

            case .uint32:
                guard tag.wireFormat == .varint else { return false }
                // If the number on the wire is larger than fits into a `UInt32`, this is not an
                // error; we truncate it.
                updateValue(of: field, to: UInt32(truncatingIfNeeded: try reader.nextVarint()))

            case .uint64:
                guard tag.wireFormat == .varint else { return false }
                updateValue(of: field, to: try reader.nextVarint())

            default:
                preconditionFailure("Unreachable")
            }

        default:
            preconditionFailure("Unreachable")
        }
        return true
    }

    /// Appends either a single unpacked value or multiple packed values to the array value of the
    /// given field, depending on the wire format of the corresponding tag.
    ///
    /// - Parameters:
    ///   - reader: The reader from which the values to append should be read.
    ///   - field: The field being decoded.
    ///   - tag: The tag that was read from the wire.
    ///   - unpackedWireFormat: The wire format that should be expected for values of this type if
    ///     they are unpacked.
    ///   - decodeElement: A function that takes a `WireFormatReader` covering the slice of packed
    ///     elements and reads and returns a single element from it.
    /// - Returns: True if the value was consumed properly, or false if the wire format was not
    ///   what was expected.
    private func appendMaybePackedValues<T>(
        from reader: inout WireFormatReader,
        to field: FieldLayout,
        tag: FieldTag,
        unpackedWireFormat: WireFormat,
        decodeElement: (inout WireFormatReader) throws -> T
    ) throws -> Bool {
        assert(
            field.rawFieldType != .bytes && field.rawFieldType != .group && field.rawFieldType != .message
                && field.rawFieldType != .string,
            "Internal error: length-delimited singular values should not reach here"
        )

        switch tag.wireFormat {
        case unpackedWireFormat:
            appendValue(try decodeElement(&reader), to: field)
            return true
        case .lengthDelimited:
            try appendPackedValues(from: &reader, to: field, hasVarints: unpackedWireFormat == .varint) {
                try decodeElement(&$0)
            }
            return true
        default:
            return false
        }
    }

    /// Updates the value of the given field by reading the next varint from the reader and treating
    /// it as the raw value of that enum field.
    ///
    /// This method handles both the singular case (by setting the field) and the repeated unpacked
    /// case (by appending to it).
    private func updateEnumValue(
        of field: FieldLayout,
        from reader: inout WireFormatReader,
        fieldNumber: Int,
        isRepeated: Bool
    ) throws {
        var alreadyReadValue = false
        try layout.performOnRawEnumValues(
            _MessageLayout.TrampolineToken(index: field.submessageIndex),
            field,
            self,
            isRepeated ? .append : .mutate
        ) { _, outRawValue in
            // In the singular case, this doesn't matter. In the repeated case, we need to return
            // true *exactly once* and then return false the next time this is called. This is
            // because the same trampoline function is used to handle the packed case, where it
            // calls the closure over and over until it returns that there is no data left.
            guard !alreadyReadValue else { return false }
            outRawValue = Int32(bitPattern: UInt32(truncatingIfNeeded: try reader.nextVarint()))
            alreadyReadValue = true
            return true
        } /*onInvalidValue*/ _: { rawValue in
            // Serialize the invalid values into a binary blob that will be passed as a single
            // varint field into unknown fields.
            //
            // Note that because we've already read the value, we have to put it into unknown fields
            // ourselves. The `decodeUnknownField` flow assumes that we've only read the tag and
            // are positioned at the beginning of the value.
            let fieldTag = FieldTag(fieldNumber: fieldNumber, wireFormat: .varint)
            let fieldSize = fieldTag.encodedSize + Varint.encodedSize(of: Int64(rawValue))
            var field = Data(count: fieldSize)
            field.withUnsafeMutableBytes { body in
                var encoder = BinaryEncoder(forWritingInto: body)
                encoder.startField(tag: fieldTag)
                encoder.putVarInt(value: Int64(rawValue))
                unknownFields.append(protobufBytes: UnsafeRawBufferPointer(body))
            }
        }
    }

    /// Appends either a single enum value or multiple packed values to the array value of the
    /// given field, depending on the wire format of the corresponding tag.
    ///
    /// - Parameters:
    ///   - reader: The reader from which the values to append should be read.
    ///   - field: The field being decoded.
    ///   - tag: The tag that was read from the wire.
    private func appendPackedEnumValues(
        from reader: inout WireFormatReader,
        to field: FieldLayout,
        fieldNumber: Int
    ) throws {
        assert(field.rawFieldType == .enum, "Internal error: should only be called for enum fields")

        let elementsBuffer = try reader.nextLengthDelimitedSlice()
        guard elementsBuffer.baseAddress != nil, elementsBuffer.count > 0 else {
            return
        }

        // If we see any invalid values during decode them, save them here so we can write them
        // into unknown fields at the end.
        var invalidValues: [Int32] = []

        // Recursion budget is irrelevant here because we're only reading enums.
        var elementsReader = WireFormatReader(buffer: elementsBuffer, recursionBudget: 0)

        try layout.performOnRawEnumValues(
            _MessageLayout.TrampolineToken(index: field.submessageIndex),
            field,
            self,
            .append
        ) { _, outRawValue in
            guard elementsReader.hasAvailableData else { return false }
            outRawValue = Int32(bitPattern: UInt32(truncatingIfNeeded: try elementsReader.nextVarint()))
            return true
        } /*onInvalidValue*/ _: {
            invalidValues.append($0)
        }

        if invalidValues.isEmpty {
            return
        }

        // Serialize all of the invalid values into a binary blob that will be passed as a
        // single length-delimited field into unknown fields.
        //
        // Note that because we've already read the values, we have to put them into unknown fields
        // ourselves. The `decodeUnknownField` flow assumes that we've only read the tag and
        // are positioned at the beginning of the value.
        let fieldTag = FieldTag(fieldNumber: fieldNumber, wireFormat: .lengthDelimited)
        let bodySize = invalidValues.reduce(0) { $0 + Varint.encodedSize(of: Int64($1)) }
        let fieldSize = fieldTag.encodedSize + Varint.encodedSize(of: Int64(bodySize)) + bodySize
        var field = Data(count: fieldSize)
        field.withUnsafeMutableBytes { body in
            var encoder = BinaryEncoder(forWritingInto: body)
            encoder.startField(tag: fieldTag)
            encoder.putVarInt(value: Int64(bodySize))
            for value in invalidValues {
                encoder.putVarInt(value: Int64(value))
            }
            unknownFields.append(protobufBytes: UnsafeRawBufferPointer(body))
        }
    }

    /// Reads the next length-delimited slice from the reader and calls the given function to
    /// decode and append the elements, having already initialized the array (if not present) and
    /// reserved capacity for the expected number of new elements.
    ///
    /// - Parameters:
    ///   - reader: The reader from which the next length-delimited slice of values should be read.
    ///   - field: The field being decoded.
    ///   - hasVarints: If true, determine the number of new elements by counting the varints in the
    ///     slice; otherwise, compute them based on the element's fixed size.
    ///   - decodeElement: A function that takes a `WireFormatReader` covering the slice of packed
    ///     elements and reads and returns a single element from it.
    private func appendPackedValues<T>(
        from reader: inout WireFormatReader,
        to field: FieldLayout,
        hasVarints: Bool,
        decodeElement: (inout WireFormatReader) throws -> T
    ) throws {
        // TODO: Constrain `T` to `BitwiseCopyable` if we decide to drop Swift 5.x support.

        // If the field isn't already present, we need to initialize a new array first.
        let pointer = (buffer.baseAddress! + field.offset).bindMemory(to: [T].self, capacity: 1)
        if !isPresent(field) {
            pointer.initialize(to: [])
            switch field.presence {
            case .hasBit(let hasByteOffset, let hasMask):
                _ = updatePresence(hasBit: (hasByteOffset, hasMask), willBeSet: true)
            case .oneOfMember(let oneofOffset):
                _ = updatePopulatedOneofMember((oneofOffset, field.fieldNumber))
            }
        }

        let elementsBuffer = try reader.nextLengthDelimitedSlice()
        guard let elementsPointer = elementsBuffer.baseAddress, elementsBuffer.count > 0 else {
            return
        }

        // Reserve additional capacity for the number of values in the buffer. In the varint case,
        // it's still likely cheaper to do a quick pre-scan than to potentially reallocate multiple
        // times.
        let count =
            hasVarints
            ? Varint.countVarintsInBuffer(start: elementsPointer, count: elementsBuffer.count)
            : elementsBuffer.count / MemoryLayout<T>.size
        pointer.pointee.reserveCapacity(pointer.pointee.count + count)

        // Recursion budget is irrelevant here because we should never recurse into groups or
        // messages here; they're not supported as packed fields.
        var elementsReader = WireFormatReader(buffer: elementsBuffer, recursionBudget: 0)
        while elementsReader.hasAvailableData {
            pointer.pointee.append(try decodeElement(&elementsReader))
        }
    }

    /// Decodes the next field in the reader as an unknown field.
    ///
    /// - Parameters:
    ///   - reader: The `WireFormatReader` from which to read the next field.
    ///   - tag: The tag representing the current field that was just read from the reader.
    ///   - discard: If true, the field's data should be skipped. Otherwise, it will be stored in
    ///     the unknown fields storage.
    /// - Throws: `BinaryDecodingError` if an error occurred while reading from the buffer.
    private func decodeUnknownField(from reader: inout WireFormatReader, tag: FieldTag, discard: Bool) throws {
        let slice = try reader.sliceBySkippingField(tag: tag)
        if !discard {
            unknownFields.append(protobufBytes: slice)
        }
    }
}
