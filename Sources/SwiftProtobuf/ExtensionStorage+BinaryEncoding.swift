// Sources/SwiftProtobuf/ExtensionStorage+BinaryEncoding.swift - Binary encoding for extensions
//
// Copyright (c) 2014 - 2025 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Binary encoding support for `ExtensionStorage.`
///
// -----------------------------------------------------------------------------

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

extension ExtensionStorage {
    /// Serializes the extension fields in the receiver to the given encoder.
    func serializeBytes(into encoder: inout BinaryEncoder, options: BinaryEncodingOptions) throws {
        for (_, value) in values.sorted(by: { $0.key < $1.key }) {
            try serializeExtensionValue(value, into: &encoder, options: options)
        }
    }

    /// Serializes a single extension field in the storage into the given binary encoder.
    private func serializeExtensionValue(
        _ value: ExtensionValueStorage,
        into encoder: inout BinaryEncoder,
        options: BinaryEncodingOptions
    ) throws {
        let schema = value.schema
        let field = schema.field
        let fieldNumber = Int(field.fieldNumber)
        switch field.fieldMode.cardinality {
        case .map:
            preconditionFailure("unreachable")

        case .array:
            let isPacked = field.fieldMode.isPacked
            switch field.rawFieldType {
            case .bool:
                let values = value.value(as: [Bool].self)
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
                for value in value.value(as: [Data].self) {
                    encoder.serializeBytesField(value, for: fieldNumber)
                }

            case .double:
                let values = value.value(as: [Double].self)
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
                try serializeRepeatedEnumExtension(for: fieldNumber, schema: schema, into: &encoder, isPacked: isPacked)

            case .fixed32:
                let values = value.value(as: [UInt32].self)
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
                let values = value.value(as: [UInt64].self)
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
                let values = value.value(as: [Float].self)
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
                try forEachMessage(inAssumedPresentRepeatedMessageField: schema) { groupStorage in
                    encoder.startField(fieldNumber: fieldNumber, wireFormat: .startGroup)
                    try groupStorage.serializeBytes(into: &encoder, options: options)
                    encoder.startField(fieldNumber: fieldNumber, wireFormat: .endGroup)
                    return .continue
                }

            case .int32:
                let values = value.value(as: [Int32].self)
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
                let values = value.value(as: [Int64].self)
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
                try forEachMessage(inAssumedPresentRepeatedMessageField: schema) { subMessageStorage in
                    encoder.startField(fieldNumber: fieldNumber, wireFormat: .lengthDelimited)
                    encoder.putVarInt(value: subMessageStorage.serializedBytesSize())
                    try subMessageStorage.serializeBytes(into: &encoder, options: options)
                    return .continue
                }

            case .sfixed32:
                let values = value.value(as: [Int32].self)
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
                let values = value.value(as: [Int64].self)
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
                let values = value.value(as: [Int32].self)
                if isPacked {
                    encoder.serializePackedVarintsField(values, for: fieldNumber) {
                        $1.putVarInt(value: UInt64(zigZagEncoded: Int64($0)))
                    } lengthOfElement: {
                        Varint.encodedSize(of: UInt64(zigZagEncoded: Int64($0)))
                    }
                } else {
                    for value in values {
                        encoder.serializeSInt32Field(value, for: fieldNumber)
                    }
                }

            case .sint64:
                let values = value.value(as: [Int64].self)
                if isPacked {
                    encoder.serializePackedVarintsField(values, for: fieldNumber) {
                        $1.putVarInt(value: UInt64(zigZagEncoded: $0))
                    } lengthOfElement: {
                        Varint.encodedSize(of: UInt64(zigZagEncoded: $0))
                    }
                } else {
                    for value in values {
                        encoder.serializeSInt64Field(value, for: fieldNumber)
                    }
                }

            case .string:
                precondition(!isPacked, "a packed string field should not be reachable")
                for value in value.value(as: [String].self) {
                    encoder.serializeStringField(value, for: fieldNumber)
                }

            case .uint32:
                let values = value.value(as: [UInt32].self)
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
                let values = value.value(as: [UInt64].self)
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
                encoder.serializeBoolField(value.value(as: Bool.self), for: fieldNumber)

            case .bytes:
                encoder.serializeBytesField(value.value(as: Data.self), for: fieldNumber)

            case .double:
                encoder.serializeDoubleField(value.value(as: Double.self), for: fieldNumber)

            case .enum:
                encoder.serializeInt32Field(value.value(as: Int32.self), for: fieldNumber)

            case .fixed32:
                encoder.serializeFixed32Field(value.value(as: UInt32.self), for: fieldNumber)

            case .fixed64:
                encoder.serializeFixed64Field(value.value(as: UInt64.self), for: fieldNumber)

            case .float:
                encoder.serializeFloatField(value.value(as: Float.self), for: fieldNumber)

            case .group:
                encoder.startField(fieldNumber: fieldNumber, wireFormat: .startGroup)
                try messageStorage(forAssumedPresentSingularMessageField: schema)
                    .serializeBytes(into: &encoder, options: options)
                encoder.startField(fieldNumber: fieldNumber, wireFormat: .endGroup)

            case .int32:
                encoder.serializeInt32Field(value.value(as: Int32.self), for: fieldNumber)

            case .int64:
                encoder.serializeInt64Field(value.value(as: Int64.self), for: fieldNumber)

            case .message:
                let subMessageStorage = messageStorage(forAssumedPresentSingularMessageField: schema)
                if schema.extendedMessage.extensibilityMode == .messageSet {
                    encoder.startField(tag: messageSetItemStartTag)
                    encoder.startField(tag: messageSetTypeIDTag)
                    encoder.putVarInt(value: UInt64(fieldNumber))
                    encoder.startField(tag: messageSetMessageTag)
                    encoder.putVarInt(value: subMessageStorage.serializedBytesSize())
                    try subMessageStorage.serializeBytes(into: &encoder, options: options)
                    encoder.startField(tag: messageSetItemEndTag)
                } else {
                    encoder.startField(fieldNumber: fieldNumber, wireFormat: .lengthDelimited)
                    encoder.putVarInt(value: subMessageStorage.serializedBytesSize())
                    try subMessageStorage.serializeBytes(into: &encoder, options: options)
                }

            case .sfixed32:
                encoder.serializeSFixed32Field(value.value(as: Int32.self), for: fieldNumber)

            case .sfixed64:
                encoder.serializeSFixed64Field(value.value(as: Int64.self), for: fieldNumber)

            case .sint32:
                encoder.serializeSInt32Field(value.value(as: Int32.self), for: fieldNumber)

            case .sint64:
                encoder.serializeSInt64Field(value.value(as: Int64.self), for: fieldNumber)

            case .string:
                encoder.serializeStringField(value.value(as: String.self), for: fieldNumber)

            case .uint32:
                encoder.serializeUInt32Field(value.value(as: UInt32.self), for: fieldNumber)

            case .uint64:
                encoder.serializeUInt64Field(value.value(as: UInt64.self), for: fieldNumber)

            default: preconditionFailure("Unreachable")
            }

        default:
            preconditionFailure("Unreachable")
        }
    }

    /// Serializes the field tag and values for a repeated (packed or unpacked) `enum` extension
    /// field.
    private func serializeRepeatedEnumExtension(
        for fieldNumber: Int,
        schema: ExtensionSchema,
        into encoder: inout BinaryEncoder,
        isPacked: Bool
    ) throws {
        if isPacked {
            // First, iterate over the values to compute the packed length.
            var length = 0
            forEachRawValue(inAssumedPresentRepeatedEnumField: schema) { value in
                length += Varint.encodedSize(of: value)
                return .continue
            }

            encoder.startField(fieldNumber: fieldNumber, wireFormat: .lengthDelimited)
            encoder.putVarInt(value: length)

            // Then, iterate over them again to encode the actual varints.
            forEachRawValue(inAssumedPresentRepeatedEnumField: schema) { value in
                encoder.putVarInt(value: Int64(value))
                return .continue
            }
        } else {
            // Iterate over the raw values and encode each as its own tag and varint.
            forEachRawValue(inAssumedPresentRepeatedEnumField: schema) { value in
                encoder.startField(fieldNumber: fieldNumber, wireFormat: .varint)
                encoder.putVarInt(value: Int64(value))
                return .continue
            }
        }
    }
}

private var messageSetItemStartTag: FieldTag {
    .init(fieldNumber: Int(KnownField.messageSetItem.number), wireFormat: .startGroup)
}
private var messageSetItemEndTag: FieldTag {
    .init(fieldNumber: Int(KnownField.messageSetItem.number), wireFormat: .endGroup)
}
private var messageSetTypeIDTag: FieldTag {
    .init(fieldNumber: Int(KnownField.messageSetTypeID.number), wireFormat: .varint)
}
private var messageSetMessageTag: FieldTag {
    .init(fieldNumber: Int(KnownField.messageSetMessage.number), wireFormat: .lengthDelimited)
}

// The size of all the tags needed to write out an extension in MessageSet format.
var messageSetItemTagsEncodedSize: Int {
    messageSetItemStartTag.encodedSize
        + messageSetItemEndTag.encodedSize
        + messageSetTypeIDTag.encodedSize
        + messageSetMessageTag.encodedSize
}
