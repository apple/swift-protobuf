// Sources/SwiftProtobuf/_MessageStorage+BinaryEncoding.swift - Binary encoding for messages
//
// Copyright (c) 2014 - 2025 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Binary encoding support for `_MessageStorage.`
///
// -----------------------------------------------------------------------------

import Foundation

extension _MessageStorage {
    /// Serializes the message represented by this storage into binary format and returns the
    /// corresponding bytes.
    public func serializedBytes<Bytes: SwiftProtobufContiguousBytes>(
        partial: Bool,
        options: BinaryEncodingOptions
    ) throws -> Bytes {
        if !partial && !isInitialized {
            throw BinaryEncodingError.missingRequiredFields
        }

        // Note that this assumes `options` will not change the required size.
        let requiredSize = serializedBytesSize()

        // Messages have a 2GB limit in encoded size, the upstread C++ code
        // (message_lite, etc.) does this enforcement also.
        // https://protobuf.dev/programming-guides/encoding/#cheat-sheet
        //
        // Testing here enables the limit without adding extra conditionals to all
        // the places that encode message fields (or strings/bytes fields), keeping
        // the overhead of the check to a minimum.
        guard requiredSize < 0x7fff_ffff else {
            // Adding a new error is a breaking change.
            throw BinaryEncodingError.missingRequiredFields
        }

        var data = Bytes(repeating: 0, count: requiredSize)
        try data.withUnsafeMutableBytes { (body: UnsafeMutableRawBufferPointer) in
            var encoder = BinaryEncoder(forWritingInto: body)
            try serializeBytes(into: &encoder, options: options)
            // Currently not exposing this from the api because it really would be
            // an internal error in the library and should never happen.
            assert(encoder.remainder.count == 0)
        }
        return data
    }

    /// A recursion helper that serializes the message represented by this storage into the given
    /// binary encoder.
    private func serializeBytes(into encoder: inout BinaryEncoder, options: BinaryEncodingOptions) throws {
        for field in layout.fields {
            guard isPresent(field) else { continue }
            try serializeField(field, into: &encoder, options: options)
        }
        // TODO: Support unknown fields and extensions.
    }

    /// Serializes a single field in the storage into the given binary encoder.
    private func serializeField(
        _ field: FieldLayout,
        into encoder: inout BinaryEncoder,
        options: BinaryEncodingOptions
    ) throws {
        let fieldNumber = Int(field.fieldNumber)
        let offset = field.offset
        switch field.fieldMode.cardinality {
        case .map:
            // TODO: Support maps.
            break

        case .array:
            let isPacked = field.fieldMode.isPacked
            switch field.rawFieldType {
            case .bool:
                let values = assumedPresentValue(at: offset, as: [Bool].self)
                if isPacked {
                    serializePackedTrivialField(values, for: fieldNumber, into: &encoder) {
                        $1.putBoolValue(value: $0)
                    }
                } else {
                    for value in values {
                        serializeBoolField(value, for: fieldNumber, into: &encoder)
                    }
                }

            case .bytes:
                precondition(!isPacked, "a packed bytes field should not be reachable")
                for value in assumedPresentValue(at: offset, as: [Data].self) {
                    serializeBytesField(value, for: fieldNumber, into: &encoder)
                }

            case .double:
                let values = assumedPresentValue(at: offset, as: [Double].self)
                if isPacked {
                    serializePackedTrivialField(values, for: fieldNumber, into: &encoder) {
                        $1.putDoubleValue(value: $0)
                    }
                } else {
                    for value in values {
                        serializeDoubleField(value, for: fieldNumber, into: &encoder)
                    }
                }

            case .enum:
                // TODO: Support enums.
                break

            case .fixed32:
                let values = assumedPresentValue(at: offset, as: [UInt32].self)
                if isPacked {
                    serializePackedTrivialField(values, for: fieldNumber, into: &encoder) {
                        $1.putFixedUInt32(value: $0)
                    }
                } else {
                    for value in values {
                        serializeFixed32Field(value, for: fieldNumber, into: &encoder)
                    }
                }

            case .fixed64:
                let values = assumedPresentValue(at: offset, as: [UInt64].self)
                if isPacked {
                    serializePackedTrivialField(values, for: fieldNumber, into: &encoder) {
                        $1.putFixedUInt64(value: $0)
                    }
                } else {
                    for value in values {
                        serializeFixed64Field(value, for: fieldNumber, into: &encoder)
                    }
                }

            case .float:
                let values = assumedPresentValue(at: offset, as: [Float].self)
                if isPacked {
                    serializePackedTrivialField(values, for: fieldNumber, into: &encoder) {
                        $1.putFloatValue(value: $0)
                    }
                } else {
                    for value in values {
                        serializeFloatField(value, for: fieldNumber, into: &encoder)
                    }
                }

            case .group:
                precondition(!isPacked, "a packed group field should not be reachable")
                try serializeGroupField(for: fieldNumber, field: field, into: &encoder, options: options)

            case .int32:
                let values = assumedPresentValue(at: offset, as: [Int32].self)
                if isPacked {
                    serializePackedTrivialField(values, for: fieldNumber, into: &encoder) {
                        $1.putVarInt(value: UInt64(UInt32(bitPattern: $0)))
                    }
                } else {
                    for value in values {
                        serializeInt32Field(value, for: fieldNumber, into: &encoder)
                    }
                }

            case .int64:
                let values = assumedPresentValue(at: offset, as: [Int64].self)
                if isPacked {
                    serializePackedTrivialField(values, for: fieldNumber, into: &encoder) {
                        $1.putVarInt(value: UInt64(bitPattern: $0))
                    }
                } else {
                    for value in values {
                        serializeInt64Field(value, for: fieldNumber, into: &encoder)
                    }
                }

            case .message:
                precondition(!isPacked, "a packed message field should not be reachable")
                try serializeMessageField(for: fieldNumber, field: field, into: &encoder, options: options)

            case .sfixed32:
                let values = assumedPresentValue(at: offset, as: [Int32].self)
                if isPacked {
                    serializePackedTrivialField(values, for: fieldNumber, into: &encoder) {
                        $1.putFixedUInt32(value: UInt32(bitPattern: $0))
                    }
                } else {
                    for value in values {
                        serializeSFixed32Field(value, for: fieldNumber, into: &encoder)
                    }
                }

            case .sfixed64:
                let values = assumedPresentValue(at: offset, as: [Int64].self)
                if isPacked {
                    serializePackedTrivialField(values, for: fieldNumber, into: &encoder) {
                        $1.putFixedUInt64(value: UInt64(bitPattern: $0))
                    }
                } else {
                    for value in values {
                        serializeSFixed64Field(value, for: fieldNumber, into: &encoder)
                    }
                }

            case .sint32:
                let values = assumedPresentValue(at: offset, as: [Int32].self)
                if isPacked {
                    serializePackedTrivialField(values, for: fieldNumber, into: &encoder) {
                        $1.putVarInt(value: UInt64(ZigZag.encoded($0)))
                    }
                } else {
                    for value in values {
                        serializeSInt32Field(value, for: fieldNumber, into: &encoder)
                    }
                }

            case .sint64:
                let values = assumedPresentValue(at: offset, as: [Int64].self)
                if isPacked {
                    serializePackedTrivialField(values, for: fieldNumber, into: &encoder) {
                        $1.putVarInt(value: ZigZag.encoded($0))
                    }
                } else {
                    for value in values {
                        serializeSInt64Field(value, for: fieldNumber, into: &encoder)
                    }
                }

            case .string:
                precondition(!isPacked, "a packed string field should not be reachable")
                for value in assumedPresentValue(at: offset, as: [String].self) {
                    serializeStringField(value, for: fieldNumber, into: &encoder)
                }

            case .uint32:
                let values = assumedPresentValue(at: offset, as: [UInt32].self)
                if isPacked {
                    serializePackedTrivialField(values, for: fieldNumber, into: &encoder) {
                        $1.putVarInt(value: UInt64($0))
                    }
                } else {
                    for value in values {
                        serializeUInt32Field(value, for: fieldNumber, into: &encoder)
                    }
                }

            case .uint64:
                let values = assumedPresentValue(at: offset, as: [UInt64].self)
                if isPacked {
                    serializePackedTrivialField(values, for: fieldNumber, into: &encoder) {
                        $1.putVarInt(value: $0)
                    }
                } else {
                    for value in values {
                        serializeUInt64Field(value, for: fieldNumber, into: &encoder)
                    }
                }

            default:
                preconditionFailure("Unreachable")
            }

        case .scalar:
            switch field.rawFieldType {
            case .bool:
                serializeBoolField(assumedPresentValue(at: offset), for: fieldNumber, into: &encoder)

            case .bytes:
                serializeBytesField(assumedPresentValue(at: offset), for: fieldNumber, into: &encoder)

            case .double:
                serializeDoubleField(assumedPresentValue(at: offset), for: fieldNumber, into: &encoder)

            case .enum:
                // TODO: Support enums.
                break

            case .fixed32:
                serializeFixed32Field(assumedPresentValue(at: offset), for: fieldNumber, into: &encoder)

            case .fixed64:
                serializeFixed64Field(assumedPresentValue(at: offset), for: fieldNumber, into: &encoder)

            case .float:
                serializeFloatField(assumedPresentValue(at: offset), for: fieldNumber, into: &encoder)

            case .group:
                try serializeGroupField(for: fieldNumber, field: field, into: &encoder, options: options)

            case .int32:
                serializeInt32Field(assumedPresentValue(at: offset), for: fieldNumber, into: &encoder)

            case .int64:
                serializeInt64Field(assumedPresentValue(at: offset), for: fieldNumber, into: &encoder)

            case .message:
                try serializeMessageField(for: fieldNumber, field: field, into: &encoder, options: options)

            case .sfixed32:
                serializeSFixed32Field(assumedPresentValue(at: offset), for: fieldNumber, into: &encoder)

            case .sfixed64:
                serializeSFixed64Field(assumedPresentValue(at: offset), for: fieldNumber, into: &encoder)

            case .sint32:
                serializeSInt32Field(assumedPresentValue(at: offset), for: fieldNumber, into: &encoder)

            case .sint64:
                serializeSInt64Field(assumedPresentValue(at: offset), for: fieldNumber, into: &encoder)

            case .string:
                serializeStringField(assumedPresentValue(at: offset), for: fieldNumber, into: &encoder)

            case .uint32:
                serializeUInt32Field(assumedPresentValue(at: offset), for: fieldNumber, into: &encoder)

            case .uint64:
                serializeUInt64Field(assumedPresentValue(at: offset), for: fieldNumber, into: &encoder)

            default: preconditionFailure("Unreachable")
            }

        default:
            preconditionFailure("Unreachable")
        }
    }

    /// Serializes the field tag and value for a singular or unpacked `bool` field.
    @inline(__always)
    private func serializeBoolField(_ value: Bool, for fieldNumber: Int, into encoder: inout BinaryEncoder) {
        encoder.startField(fieldNumber: fieldNumber, wireFormat: .varint)
        encoder.putVarInt(value: value ? 1 : 0)
    }

    /// Serializes the field tag and value for a singular `bytes` field.
    @inline(__always)
    private func serializeBytesField(_ value: Data, for fieldNumber: Int, into encoder: inout BinaryEncoder) {
        encoder.startField(fieldNumber: fieldNumber, wireFormat: .lengthDelimited)
        encoder.putBytesValue(value: value)
    }

    /// Serializes the field tag and value for a singular or unpacked `double` field.
    @inline(__always)
    private func serializeDoubleField(_ value: Double, for fieldNumber: Int, into encoder: inout BinaryEncoder) {
        encoder.startField(fieldNumber: fieldNumber, wireFormat: .fixed64)
        encoder.putDoubleValue(value: value)
    }

    /// Serializes the field tag and value for a singular or unpacked `fixed32` field.
    @inline(__always)
    private func serializeFixed32Field(_ value: UInt32, for fieldNumber: Int, into encoder: inout BinaryEncoder) {
        encoder.startField(fieldNumber: fieldNumber, wireFormat: .fixed32)
        encoder.putFixedUInt32(value: value)
    }

    /// Serializes the field tag and value for a singular or unpacked `fixed64` field.
    @inline(__always)
    private func serializeFixed64Field(_ value: UInt64, for fieldNumber: Int, into encoder: inout BinaryEncoder) {
        encoder.startField(fieldNumber: fieldNumber, wireFormat: .fixed64)
        encoder.putFixedUInt64(value: value)
    }

    /// Serializes the field tag and value for a singular or unpacked `float` field.
    @inline(__always)
    private func serializeFloatField(_ value: Float, for fieldNumber: Int, into encoder: inout BinaryEncoder) {
        encoder.startField(fieldNumber: fieldNumber, wireFormat: .fixed32)
        encoder.putFloatValue(value: value)
    }

    /// Serializes the start-group/end-group tags and contents for a `group` field.
    ///
    /// Since this function recurses via `performOnSubmessageStorage`, it supports both the singular
    /// case and the repeated case (i.e., calling this on a repeated field will iterate over all of
    /// the elements).
    private func serializeGroupField(
        for fieldNumber: Int,
        field: FieldLayout,
        into encoder: inout BinaryEncoder,
        options: BinaryEncodingOptions
    ) throws {
        _ = try layout.performOnSubmessageStorage(
            _MessageLayout.SubmessageToken(index: field.submessageIndex),
            field,
            self,
            .read
        ) {
            encoder.startField(fieldNumber: fieldNumber, wireFormat: .startGroup)
            try $0.serializeBytes(into: &encoder, options: options)
            encoder.startField(fieldNumber: fieldNumber, wireFormat: .endGroup)
            return true
        }
    }

    /// Serializes the field tag and value for a singular or unpacked `int32` field.
    @inline(__always)
    private func serializeInt32Field(_ value: Int32, for fieldNumber: Int, into encoder: inout BinaryEncoder) {
        encoder.startField(fieldNumber: fieldNumber, wireFormat: .varint)
        encoder.putVarInt(value: UInt64(bitPattern: Int64(value)))
    }

    /// Serializes the field tag and value for a singular or unpacked `int64` field.
    @inline(__always)
    private func serializeInt64Field(_ value: Int64, for fieldNumber: Int, into encoder: inout BinaryEncoder) {
        encoder.startField(fieldNumber: fieldNumber, wireFormat: .varint)
        encoder.putVarInt(value: UInt64(bitPattern: value))
    }

    /// Serializes the tag, length prefix, and contents for a submessage field.
    ///
    /// Since this function recurses via `performOnSubmessageStorage`, it supports both the singular
    /// case and the repeated case (i.e., calling this on a repeated field will iterate over all of
    /// the elements).
    private func serializeMessageField(
        for fieldNumber: Int,
        field: FieldLayout,
        into encoder: inout BinaryEncoder,
        options: BinaryEncodingOptions
    ) throws {
        _ = try layout.performOnSubmessageStorage(
            _MessageLayout.SubmessageToken(index: field.submessageIndex),
            field,
            self,
            .read
        ) {
            encoder.startField(fieldNumber: fieldNumber, wireFormat: .lengthDelimited)
            encoder.putVarInt(value: $0.serializedBytesSize())
            try $0.serializeBytes(into: &encoder, options: options)
            return true
        }
    }

    /// Serializes the field tag and value for a singular or unpacked `sfixed32` field.
    @inline(__always)
    private func serializeSFixed32Field(_ value: Int32, for fieldNumber: Int, into encoder: inout BinaryEncoder) {
        encoder.startField(fieldNumber: fieldNumber, wireFormat: .fixed32)
        encoder.putFixedUInt32(value: UInt32(bitPattern: value))
    }

    /// Serializes the field tag and value for a singular or unpacked `sfixed64` field.
    @inline(__always)
    private func serializeSFixed64Field(_ value: Int64, for fieldNumber: Int, into encoder: inout BinaryEncoder) {
        encoder.startField(fieldNumber: fieldNumber, wireFormat: .fixed64)
        encoder.putFixedUInt64(value: UInt64(bitPattern: value))
    }

    /// Serializes the field tag and value for a singular or unpacked `sint32` field.
    @inline(__always)
    private func serializeSInt32Field(_ value: Int32, for fieldNumber: Int, into encoder: inout BinaryEncoder) {
        encoder.startField(fieldNumber: fieldNumber, wireFormat: .varint)
        encoder.putVarInt(value: UInt64(ZigZag.encoded(value)))
    }

    /// Serializes the field tag and value for a singular or unpacked `sint64` field.
    @inline(__always)
    private func serializeSInt64Field(_ value: Int64, for fieldNumber: Int, into encoder: inout BinaryEncoder) {
        encoder.startField(fieldNumber: fieldNumber, wireFormat: .varint)
        encoder.putVarInt(value: ZigZag.encoded(value))
    }

    /// Serializes the field tag and value for a singular `string` field.
    @inline(__always)
    private func serializeStringField(_ value: String, for fieldNumber: Int, into encoder: inout BinaryEncoder) {
        encoder.startField(fieldNumber: fieldNumber, wireFormat: .lengthDelimited)
        encoder.putStringValue(value: value)
    }

    /// Serializes the field tag and value for a singular or unpacked `uint32` field.
    @inline(__always)
    private func serializeUInt32Field(_ value: UInt32, for fieldNumber: Int, into encoder: inout BinaryEncoder) {
        encoder.startField(fieldNumber: fieldNumber, wireFormat: .varint)
        encoder.putVarInt(value: UInt64(value))
    }

    /// Serializes the field tag and value for a singular or unpacked `uint64` field.
    @inline(__always)
    private func serializeUInt64Field(_ value: UInt64, for fieldNumber: Int, into encoder: inout BinaryEncoder) {
        encoder.startField(fieldNumber: fieldNumber, wireFormat: .varint)
        encoder.putVarInt(value: value)
    }

    /// Serializes a packed repeated field of trivial values by writing the tag and length-delimited
    /// prefix, then calls the given closure to encode the individual values themselves.
    private func serializePackedTrivialField<T>(
        _ values: [T],
        for fieldNumber: Int,
        into encoder: inout BinaryEncoder,
        encode: (T, inout BinaryEncoder) -> Void
    ) {
        encoder.startField(fieldNumber: fieldNumber, wireFormat: .lengthDelimited)
        encoder.putVarInt(value: values.count * MemoryLayout<T>.size)
        for value in values {
            encode(value, &encoder)
        }
    }
}
