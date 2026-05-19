// Sources/SwiftProtobuf/ExtensionStorage+TextDecoding.swift - Text format decoding for extensions
//
// Copyright (c) 2014 - 2026 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Text format decoding support for `ExtensionStorage`.
///
// -----------------------------------------------------------------------------

import Foundation

extension ExtensionStorage {
    /// Decodes the next value from the reader, which has already been determined to be for the
    /// extension field with the given schema.
    ///
    /// - Parameters:
    ///   - schema: The ``ExtensionSchema`` of the extension field being decoded.
    ///   - reader: The ``TextFormatReader`` from which the value should be read.
    func decodeNextExtension(_ schema: ExtensionSchema, from reader: inout TextFormatReader) throws {
        let field = schema.field
        let fieldType = field.rawFieldType

        // A colon after the field name is required unless it's a group/message field.
        switch fieldType {
        case .group, .message:
            _ = try reader.consumeIfPresent(.colon)
        default:
            try reader.consume(.colon)
        }

        switch field.fieldMode.cardinality {
        case .map:
            preconditionFailure("Unreachable")

        case .array:
            try reader.consumePossibleArray { reader in
                switch fieldType {
                case .bool:
                    appendValue(try reader.consumeBool(), to: schema)

                case .bytes:
                    appendValue(try reader.consumeBytes(), to: schema)

                case .double:
                    appendValue(try reader.consumeDouble(), to: schema)

                case .enum:
                    appendEnumValue(
                        withRawValue: try reader.consumeEnumValue(schema: schema.enumSchema),
                        toRepeatedEnumField: schema
                    )

                case .fixed32, .uint32:
                    let n = try reader.consumeUnsignedInteger(upperBound: UInt64(UInt32.max))
                    appendValue(UInt32(truncatingIfNeeded: n), to: schema)

                case .fixed64, .uint64:
                    appendValue(try reader.consumeUnsignedInteger(upperBound: UInt64.max), to: schema)

                case .float:
                    appendValue(try Float(reader.consumeDouble()), to: schema)

                case .group, .message:
                    let submessageStorage = messageStorage(forNewlyAppendedElementOfRepeatedMessageField: schema)
                    try reader.withReaderForNextObject(expectedSchema: submessageStorage.schema) { subReader in
                        try submessageStorage.merge(byParsingTextFormatFrom: &subReader)
                    }

                case .int32, .sfixed32, .sint32:
                    let n = try reader.consumeSignedInteger(upperBound: Int64(Int32.max))
                    appendValue(Int32(truncatingIfNeeded: n), to: schema)

                case .int64, .sfixed64, .sint64:
                    appendValue(try reader.consumeSignedInteger(upperBound: Int64.max), to: schema)

                case .string:
                    appendValue(try reader.consumeString(), to: schema)

                default:
                    preconditionFailure("Unreachable")
                }
            }

        case .scalar:
            switch fieldType {
            case .bool:
                updateValue(of: schema, to: try reader.consumeBool())

            case .bytes:
                updateValue(of: schema, to: try reader.consumeBytes())

            case .double:
                updateValue(of: schema, to: try reader.consumeDouble())

            case .enum:
                updateValue(of: schema, to: try reader.consumeEnumValue(schema: schema.enumSchema))

            case .fixed32, .uint32:
                let n = try reader.consumeUnsignedInteger(upperBound: UInt64(UInt32.max))
                updateValue(of: schema, to: UInt32(truncatingIfNeeded: n))

            case .fixed64, .uint64:
                updateValue(of: schema, to: try reader.consumeUnsignedInteger(upperBound: UInt64.max))

            case .float:
                updateValue(of: schema, to: try Float(reader.consumeDouble()))

            case .group, .message:
                let submessageStorage = uniqueMessageStorage(forSingularMessageField: schema)
                try reader.withReaderForNextObject(expectedSchema: submessageStorage.schema) { subReader in
                    try submessageStorage.merge(byParsingTextFormatFrom: &subReader)
                }

            case .int32, .sfixed32, .sint32:
                let n = try reader.consumeSignedInteger(upperBound: Int64(Int32.max))
                updateValue(of: schema, to: Int32(truncatingIfNeeded: n))

            case .int64, .sfixed64, .sint64:
                updateValue(of: schema, to: try reader.consumeSignedInteger(upperBound: Int64.max))

            case .string:
                updateValue(of: schema, to: try reader.consumeString())

            default:
                preconditionFailure("Unreachable")
            }

        default:
            preconditionFailure("Unreachable")
        }
    }
}
