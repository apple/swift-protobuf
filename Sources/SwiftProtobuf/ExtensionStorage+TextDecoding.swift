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
            _ = reader.scanner.skipOptionalColon()
        default:
            try reader.scanner.skipRequiredColon()
        }

        switch field.fieldMode.cardinality {
        case .map:
            preconditionFailure("Unreachable")

        case .array:
            try scanPossibleArray(from: &reader) { reader in
                switch fieldType {
                case .bool:
                    appendValue(try reader.scanner.nextBool(), to: schema)

                case .bytes:
                    appendValue(try reader.scanner.nextBytesValue(), to: schema)

                case .double:
                    appendValue(try reader.scanner.nextDouble(), to: schema)

                case .enum:
                    appendEnumValue(
                        withRawValue: try scanEnumValue(schema, from: &reader),
                        toRepeatedEnumField: schema
                    )

                case .fixed32, .uint32:
                    let n = try reader.scanner.nextSInt()
                    if n > UInt64(UInt32.max) {
                        throw TextFormatDecodingError.malformedNumber
                    }
                    appendValue(UInt32(truncatingIfNeeded: n), to: schema)

                case .fixed64, .uint64:
                    appendValue(try reader.scanner.nextUInt(), to: schema)

                case .float:
                    appendValue(try reader.scanner.nextFloat(), to: schema)

                case .group, .message:
                    let submessageStorage = messageStorage(forNewlyAppendedElementOfRepeatedMessageField: schema)
                    try reader.withReaderForNextObject(expectedSchema: submessageStorage.schema) { subReader in
                        try submessageStorage.merge(byParsingTextFormatFrom: &subReader)
                    }

                case .int32, .sfixed32, .sint32:
                    let n = try reader.scanner.nextSInt()
                    if n > Int64(Int32.max) || n < Int64(Int32.min) {
                        throw TextFormatDecodingError.malformedNumber
                    }
                    appendValue(Int32(truncatingIfNeeded: n), to: schema)

                case .int64, .sfixed64, .sint64:
                    appendValue(try reader.scanner.nextSInt(), to: schema)

                case .string:
                    appendValue(try reader.scanner.nextStringValue(), to: schema)

                default:
                    preconditionFailure("Unreachable")
                }
            }

        case .scalar:
            switch fieldType {
            case .bool:
                updateValue(of: schema, to: try reader.scanner.nextBool())

            case .bytes:
                updateValue(of: schema, to: try reader.scanner.nextBytesValue())

            case .double:
                updateValue(of: schema, to: try reader.scanner.nextDouble())

            case .enum:
                updateValue(of: schema, to: try scanEnumValue(schema, from: &reader))

            case .fixed32, .uint32:
                let n = try reader.scanner.nextUInt()
                if n > UInt64(UInt32.max) {
                    throw TextFormatDecodingError.malformedNumber
                }
                updateValue(of: schema, to: UInt32(truncatingIfNeeded: n))

            case .fixed64, .uint64:
                updateValue(of: schema, to: try reader.scanner.nextUInt())

            case .float:
                updateValue(of: schema, to: try reader.scanner.nextFloat())

            case .group, .message:
                let submessageStorage = uniqueMessageStorage(forSingularMessageField: schema)
                try reader.withReaderForNextObject(expectedSchema: submessageStorage.schema) { subReader in
                    try submessageStorage.merge(byParsingTextFormatFrom: &subReader)
                }

            case .int32, .sfixed32, .sint32:
                let n = try reader.scanner.nextSInt()
                if n > Int64(Int32.max) || n < Int64(Int32.min) {
                    throw TextFormatDecodingError.malformedNumber
                }
                updateValue(of: schema, to: Int32(truncatingIfNeeded: n))

            case .int64, .sfixed64, .sint64:
                updateValue(of: schema, to: try reader.scanner.nextSInt())

            case .string:
                updateValue(of: schema, to: try reader.scanner.nextStringValue())

            default:
                preconditionFailure("Unreachable")
            }

        default:
            preconditionFailure("Unreachable")
        }
    }

    /// Scans the enum value of the given extension field from the reader (handling both name and
    /// numeric cases), performing the given operation on its raw value (either mutate or append).
    private func scanEnumValue(_ schema: ExtensionSchema, from reader: inout TextFormatReader) throws -> Int32 {
        let enumSchema = schema.enumSchema

        if let name = try reader.scanner.nextOptionalEnumName() {
            guard let rawValue = enumSchema.enumCase(forTextName: name) else {
                throw TextFormatDecodingError.unrecognizedEnumValue
            }
            return rawValue
        }

        let number = try reader.scanner.nextSInt()
        guard number >= Int64(Int32.min) && number <= Int64(Int32.max) else {
            throw TextFormatDecodingError.malformedText
        }

        let rawValue = Int32(truncatingIfNeeded: number)
        guard enumSchema.isValidValue(rawValue) else {
            throw TextFormatDecodingError.unrecognizedEnumValue
        }
        return rawValue
    }
}
