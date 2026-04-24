// Sources/SwiftProtobuf/MessageStorage+BinaryEncoding.swift - Binary encoding for messages
//
// Copyright (c) 2014 - 2025 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Binary encoding support for `MessageStorage.`
///
// -----------------------------------------------------------------------------

import Foundation

extension MessageStorage {
    /// Serializes the message represented by this storage into binary format and returns the
    /// corresponding bytes.
    func serializedBytes<Bytes: SwiftProtobufContiguousBytes>(
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
    func serializeBytes(into encoder: inout BinaryEncoder, options: BinaryEncodingOptions) throws {
        var mapEntryWorkingSpace = MapEntryWorkingSpace(ownerSchema: schema)
        for field in schema.fields {
            guard isPresent(field) else { continue }
            try serializeField(field, into: &encoder, mapEntryWorkingSpace: &mapEntryWorkingSpace, options: options)
        }
        encoder.appendUnknown(data: unknownFields.data)
        try extensionStorage.serializeBytes(into: &encoder, options: options)
    }

    /// Serializes a single field in the storage into the given binary encoder.
    private func serializeField(
        _ field: FieldSchema,
        into encoder: inout BinaryEncoder,
        mapEntryWorkingSpace: inout MapEntryWorkingSpace,
        options: BinaryEncodingOptions
    ) throws {
        let fieldNumber = Int(field.fieldNumber)
        let offset = field.offset
        switch field.fieldMode.cardinality {
        case .map:
            _ = try! schema.performOnMapEntry(
                MessageSchema.TrampolineToken(index: field.submessageIndex),
                field,
                self,
                mapEntryWorkingSpace.storage(for: field.submessageIndex),
                .read,
                options.useDeterministicOrdering
            ) {
                encoder.startField(fieldNumber: fieldNumber, wireFormat: .lengthDelimited)
                encoder.putVarInt(value: $0.serializedBytesSize())
                try $0.serializeBytes(into: &encoder, options: options)
                return true
            }

        case .array:
            let isPacked = field.fieldMode.isPacked
            switch field.rawFieldType {
            case .bool:
                let values = assumedPresentValue(at: offset, as: [Bool].self)
                if isPacked {
                    encoder.serializePackedFixedField(values, for: fieldNumber) {
                        $1.putBoolValue(value: $0)
                    }
                } else {
                    for value in values {
                        encoder.serializeBoolField(value, for: fieldNumber)
                    }
                }

            case .bytes:
                precondition(!isPacked, "a packed bytes field should not be reachable")
                for value in assumedPresentValue(at: offset, as: [Data].self) {
                    encoder.serializeBytesField(value, for: fieldNumber)
                }

            case .double:
                let values = assumedPresentValue(at: offset, as: [Double].self)
                if isPacked {
                    encoder.serializePackedFixedField(values, for: fieldNumber) {
                        $1.putDoubleValue(value: $0)
                    }
                } else {
                    for value in values {
                        encoder.serializeDoubleField(value, for: fieldNumber)
                    }
                }

            case .enum:
                try serializeRepeatedEnumField(for: fieldNumber, field: field, into: &encoder, isPacked: isPacked)

            case .fixed32:
                let values = assumedPresentValue(at: offset, as: [UInt32].self)
                if isPacked {
                    encoder.serializePackedFixedField(values, for: fieldNumber) {
                        $1.putFixedUInt32(value: $0)
                    }
                } else {
                    for value in values {
                        encoder.serializeFixed32Field(value, for: fieldNumber)
                    }
                }

            case .fixed64:
                let values = assumedPresentValue(at: offset, as: [UInt64].self)
                if isPacked {
                    encoder.serializePackedFixedField(values, for: fieldNumber) {
                        $1.putFixedUInt64(value: $0)
                    }
                } else {
                    for value in values {
                        encoder.serializeFixed64Field(value, for: fieldNumber)
                    }
                }

            case .float:
                let values = assumedPresentValue(at: offset, as: [Float].self)
                if isPacked {
                    encoder.serializePackedFixedField(values, for: fieldNumber) {
                        $1.putFloatValue(value: $0)
                    }
                } else {
                    for value in values {
                        encoder.serializeFloatField(value, for: fieldNumber)
                    }
                }

            case .group:
                precondition(!isPacked, "a packed group field should not be reachable")
                try serializeGroupField(for: fieldNumber, field: field, into: &encoder, options: options)

            case .int32:
                let values = assumedPresentValue(at: offset, as: [Int32].self)
                if isPacked {
                    encoder.serializePackedVarintsField(values, for: fieldNumber) {
                        $1.putVarInt(value: UInt64(bitPattern: Int64($0)))
                    } lengthOfElement: {
                        Varint.encodedSize(of: $0)
                    }
                } else {
                    for value in values {
                        encoder.serializeInt32Field(value, for: fieldNumber)
                    }
                }

            case .int64:
                let values = assumedPresentValue(at: offset, as: [Int64].self)
                if isPacked {
                    encoder.serializePackedVarintsField(values, for: fieldNumber) {
                        $1.putVarInt(value: UInt64(bitPattern: $0))
                    } lengthOfElement: {
                        Varint.encodedSize(of: $0)
                    }
                } else {
                    for value in values {
                        encoder.serializeInt64Field(value, for: fieldNumber)
                    }
                }

            case .message:
                precondition(!isPacked, "a packed message field should not be reachable")
                try serializeMessageField(for: fieldNumber, field: field, into: &encoder, options: options)

            case .sfixed32:
                let values = assumedPresentValue(at: offset, as: [Int32].self)
                if isPacked {
                    encoder.serializePackedFixedField(values, for: fieldNumber) {
                        $1.putFixedUInt32(value: UInt32(bitPattern: $0))
                    }
                } else {
                    for value in values {
                        encoder.serializeSFixed32Field(value, for: fieldNumber)
                    }
                }

            case .sfixed64:
                let values = assumedPresentValue(at: offset, as: [Int64].self)
                if isPacked {
                    encoder.serializePackedFixedField(values, for: fieldNumber) {
                        $1.putFixedUInt64(value: UInt64(bitPattern: $0))
                    }
                } else {
                    for value in values {
                        encoder.serializeSFixed64Field(value, for: fieldNumber)
                    }
                }

            case .sint32:
                let values = assumedPresentValue(at: offset, as: [Int32].self)
                if isPacked {
                    encoder.serializePackedVarintsField(values, for: fieldNumber) {
                        $1.putVarInt(value: ZigZag.encoded(Int64($0)))
                    } lengthOfElement: {
                        Varint.encodedSize(of: ZigZag.encoded(Int64($0)))
                    }
                } else {
                    for value in values {
                        encoder.serializeSInt32Field(value, for: fieldNumber)
                    }
                }

            case .sint64:
                let values = assumedPresentValue(at: offset, as: [Int64].self)
                if isPacked {
                    encoder.serializePackedVarintsField(values, for: fieldNumber) {
                        $1.putVarInt(value: ZigZag.encoded($0))
                    } lengthOfElement: {
                        Varint.encodedSize(of: ZigZag.encoded($0))
                    }
                } else {
                    for value in values {
                        encoder.serializeSInt64Field(value, for: fieldNumber)
                    }
                }

            case .string:
                precondition(!isPacked, "a packed string field should not be reachable")
                for value in assumedPresentValue(at: offset, as: [String].self) {
                    encoder.serializeStringField(value, for: fieldNumber)
                }

            case .uint32:
                let values = assumedPresentValue(at: offset, as: [UInt32].self)
                if isPacked {
                    encoder.serializePackedVarintsField(values, for: fieldNumber) {
                        $1.putVarInt(value: UInt64($0))
                    } lengthOfElement: {
                        Varint.encodedSize(of: $0)
                    }
                } else {
                    for value in values {
                        encoder.serializeUInt32Field(value, for: fieldNumber)
                    }
                }

            case .uint64:
                let values = assumedPresentValue(at: offset, as: [UInt64].self)
                if isPacked {
                    encoder.serializePackedVarintsField(values, for: fieldNumber) {
                        $1.putVarInt(value: $0)
                    } lengthOfElement: {
                        Varint.encodedSize(of: $0)
                    }
                } else {
                    for value in values {
                        encoder.serializeUInt64Field(value, for: fieldNumber)
                    }
                }

            default:
                preconditionFailure("Unreachable")
            }

        case .scalar:
            switch field.rawFieldType {
            case .bool:
                encoder.serializeBoolField(assumedPresentValue(at: offset), for: fieldNumber)

            case .bytes:
                encoder.serializeBytesField(assumedPresentValue(at: offset), for: fieldNumber)

            case .double:
                encoder.serializeDoubleField(assumedPresentValue(at: offset), for: fieldNumber)

            case .enum:
                encoder.serializeInt32Field(assumedPresentValue(at: offset), for: fieldNumber)

            case .fixed32:
                encoder.serializeFixed32Field(assumedPresentValue(at: offset), for: fieldNumber)

            case .fixed64:
                encoder.serializeFixed64Field(assumedPresentValue(at: offset), for: fieldNumber)

            case .float:
                encoder.serializeFloatField(assumedPresentValue(at: offset), for: fieldNumber)

            case .group:
                try serializeGroupField(for: fieldNumber, field: field, into: &encoder, options: options)

            case .int32:
                encoder.serializeInt32Field(assumedPresentValue(at: offset), for: fieldNumber)

            case .int64:
                encoder.serializeInt64Field(assumedPresentValue(at: offset), for: fieldNumber)

            case .message:
                try serializeMessageField(for: fieldNumber, field: field, into: &encoder, options: options)

            case .sfixed32:
                encoder.serializeSFixed32Field(assumedPresentValue(at: offset), for: fieldNumber)

            case .sfixed64:
                encoder.serializeSFixed64Field(assumedPresentValue(at: offset), for: fieldNumber)

            case .sint32:
                encoder.serializeSInt32Field(assumedPresentValue(at: offset), for: fieldNumber)

            case .sint64:
                encoder.serializeSInt64Field(assumedPresentValue(at: offset), for: fieldNumber)

            case .string:
                encoder.serializeStringField(assumedPresentValue(at: offset), for: fieldNumber)

            case .uint32:
                encoder.serializeUInt32Field(assumedPresentValue(at: offset), for: fieldNumber)

            case .uint64:
                encoder.serializeUInt64Field(assumedPresentValue(at: offset), for: fieldNumber)

            default: preconditionFailure("Unreachable")
            }

        default:
            preconditionFailure("Unreachable")
        }
    }

    /// Serializes the start-group/end-group tags and contents for a `group` field.
    ///
    /// Since this function recurses via `performOnSubmessageStorage`, it supports both the singular
    /// case and the repeated case (i.e., calling this on a repeated field will iterate over all of
    /// the elements).
    private func serializeGroupField(
        for fieldNumber: Int,
        field: FieldSchema,
        into encoder: inout BinaryEncoder,
        options: BinaryEncodingOptions
    ) throws {
        _ = try schema.performOnSubmessageStorage(
            MessageSchema.TrampolineToken(index: field.submessageIndex),
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

    /// Serializes the tag, length prefix, and contents for a submessage field.
    ///
    /// Since this function recurses via `performOnSubmessageStorage`, it supports both the singular
    /// case and the repeated case (i.e., calling this on a repeated field will iterate over all of
    /// the elements).
    private func serializeMessageField(
        for fieldNumber: Int,
        field: FieldSchema,
        into encoder: inout BinaryEncoder,
        options: BinaryEncodingOptions
    ) throws {
        _ = try schema.performOnSubmessageStorage(
            MessageSchema.TrampolineToken(index: field.submessageIndex),
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

    /// Serializes the field tag and values for a repeated (packed or unpacked) `enum` field.
    private func serializeRepeatedEnumField(
        for fieldNumber: Int,
        field: FieldSchema,
        into encoder: inout BinaryEncoder,
        isPacked: Bool
    ) throws {
        if isPacked {
            // First, iterate over the values to compute the packed length.
            var length = 0
            _ = try schema.performOnRawEnumValues(
                MessageSchema.TrampolineToken(index: field.submessageIndex),
                field,
                self,
                .read
            ) { _, value in
                length += Varint.encodedSize(of: value)
                return true
            } /*onInvalidValue*/ _: { _ in
                assertionFailure("invalid value handler should never be called for .read")
            }

            encoder.startField(fieldNumber: fieldNumber, wireFormat: .lengthDelimited)
            encoder.putVarInt(value: length)

            // Then, iterate over them again to encode the actual varints.
            _ = try schema.performOnRawEnumValues(
                MessageSchema.TrampolineToken(index: field.submessageIndex),
                field,
                self,
                .read
            ) { _, value in
                encoder.putVarInt(value: Int64(value))
                return true
            } /*onInvalidValue*/ _: { _ in
                assertionFailure("invalid value handler should never be called for .read")
            }
        } else {
            // Iterate over the raw values and encode each as its own tag and varint.
            _ = try schema.performOnRawEnumValues(
                MessageSchema.TrampolineToken(index: field.submessageIndex),
                field,
                self,
                .read
            ) { _, value in
                encoder.startField(fieldNumber: fieldNumber, wireFormat: .varint)
                encoder.putVarInt(value: Int64(value))
                return true
            } /*onInvalidValue*/ _: { _ in
                assertionFailure("invalid value handler should never be called for .read")
            }
        }
    }
}
