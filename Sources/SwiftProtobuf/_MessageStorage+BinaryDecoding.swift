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
        while reader.hasAvailableData {
            let tag = try reader.nextTag()
            let consumed = try decodeNextField(
                from: &reader,
                tag: tag,
                partial: partial,
                discardUnknownFields: discardUnknownFields
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
        discardUnknownFields: Bool
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
            // TODO: Support map fields.
            break

        case .array:
            // TODO: Support repeated fields.
            break

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
                // TODO: Support enums.
                break

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
                    _MessageLayout.SubmessageToken(index: field.submessageIndex),
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
                    _MessageLayout.SubmessageToken(index: field.submessageIndex),
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
