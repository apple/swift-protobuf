// Sources/SwiftProtobuf/ExtensionStorage+JSONDecoding.swift - JSON format decoding for extensions
//
// Copyright (c) 2014 - 2026 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// JSON format decoding support for `ExtensionStorage`.
///
// -----------------------------------------------------------------------------

import Foundation

extension ExtensionStorage {
    /// Decodes the next value from the reader, which has already been determined to be for the
    /// extension field with the given schema.
    ///
    /// - Parameters:
    ///   - schema: The ``ExtensionSchema`` of the extension field being decoded.
    ///   - reader: The ``JSONReader`` from which the value should be read.
    func decodeNextExtension(_ schema: ExtensionSchema, from reader: inout JSONReader) throws {
        let field = schema.field
        let fieldType = field.rawFieldType

        switch field.fieldMode.cardinality {
        case .map:
            preconditionFailure("Unreachable")

        case .array:
            try scanArray(from: &reader) { reader in
                switch fieldType {
                case .bool:
                    appendValue(try reader.scanner.nextBool(), to: schema)

                case .bytes:
                    appendValue(try reader.scanner.nextBytesValue(), to: schema)

                case .double:
                    appendValue(try reader.scanner.nextDouble(), to: schema)

                case .enum:
                    do {
                        appendValue(try scanEnumValue(schema, from: &reader), to: schema)
                    } catch JSONDecodingError.unrecognizedEnumValue where reader.options.ignoreUnknownFields {
                        // Ignore unknown enum values if requested.
                    }

                case .fixed32, .uint32:
                    let n = try reader.scanner.nextUInt()
                    if n > UInt64(UInt32.max) {
                        throw JSONDecodingError.malformedNumber
                    }
                    appendValue(UInt32(truncatingIfNeeded: n), to: schema)

                case .fixed64, .uint64:
                    appendValue(try reader.scanner.nextUInt(), to: schema)

                case .float:
                    appendValue(try reader.scanner.nextFloat(), to: schema)

                case .group, .message:
                    try scanRepeatedMessageField(schema, from: &reader)

                case .int32, .sfixed32, .sint32:
                    let n = try reader.scanner.nextSInt()
                    if n > Int64(Int32.max) || n < Int64(Int32.min) {
                        throw JSONDecodingError.malformedNumber
                    }
                    appendValue(Int32(truncatingIfNeeded: n), to: schema)

                case .int64, .sfixed64, .sint64:
                    appendValue(try reader.scanner.nextSInt(), to: schema)

                case .string:
                    appendValue(try reader.scanner.nextQuotedString(), to: schema)

                default:
                    preconditionFailure("Unreachable")
                }
            }
            break

        case .scalar:
            try scanSingularValue(of: schema, from: &reader)

        default:
            preconditionFailure("Unreachable")
        }
    }

    /// Scans an extension value from the JSON reader.
    ///
    /// - Parameters:
    ///   - schema: The ``ExtensionSchema`` of the extension being scanned.
    ///   - reader: The ``JSONReader`` from which to scan the value.
    private func scanSingularValue(of schema: ExtensionSchema, from reader: inout JSONReader) throws {
        let field = schema.field
        let isNull = reader.scanner.skipOptionalNull()
        switch field.rawFieldType {
        case .bool:
            if isNull {
                clearValue(of: schema, type: Bool.self)
                break
            }
            updateValue(of: schema, to: try reader.scanner.nextBool())

        case .bytes:
            if isNull {
                clearValue(of: schema, type: Data.self)
                break
            }
            updateValue(of: schema, to: try reader.scanner.nextBytesValue())

        case .double:
            if isNull {
                clearValue(of: schema, type: Double.self)
                break
            }
            updateValue(of: schema, to: try reader.scanner.nextDouble())

        case .enum:
            if isNull {
                // We don't have the concrete type information for the enum here, but that's
                // fine because we store the raw value for singular enum fields.
                clearValue(of: schema, type: Int32.self)
                break
            }
            updateValue(of: schema, to: try scanEnumValue(schema, from: &reader))

        case .fixed32, .uint32:
            if isNull {
                clearValue(of: schema, type: UInt32.self)
                break
            }
            let n = try reader.scanner.nextUInt()
            if n > UInt64(UInt32.max) {
                throw JSONDecodingError.malformedNumber
            }
            updateValue(of: schema, to: UInt32(truncatingIfNeeded: n))

        case .fixed64, .uint64:
            if isNull {
                clearValue(of: schema, type: UInt64.self)
                break
            }
            updateValue(of: schema, to: try reader.scanner.nextUInt())

        case .float:
            if isNull {
                clearValue(of: schema, type: Float.self)
                break
            }
            updateValue(of: schema, to: try reader.scanner.nextFloat())

        case .group, .message:
            if isNull {
                clearSingularMessageField(schema)
                break
            }
            try scanSingularMessageField(schema, from: &reader)

        case .int32, .sfixed32, .sint32:
            if isNull {
                clearValue(of: schema, type: Int32.self)
                break
            }
            let n = try reader.scanner.nextSInt()
            if n > Int64(Int32.max) || n < Int64(Int32.min) {
                throw JSONDecodingError.malformedNumber
            }
            updateValue(of: schema, to: Int32(truncatingIfNeeded: n))

        case .int64, .sfixed64, .sint64:
            if isNull {
                clearValue(of: schema, type: Int64.self)
                break
            }
            updateValue(of: schema, to: try reader.scanner.nextSInt())

        case .string:
            if isNull {
                clearValue(of: schema, type: String.self)
                break
            }
            updateValue(of: schema, to: try reader.scanner.nextQuotedString())

        default:
            preconditionFailure("Unreachable")
        }
    }

    /// Scans the next message from the JSON reader into the storage of the given field.
    ///
    /// - Parameters:
    ///   - ext: The ``ExtensionSchema`` of the extension field being scanned.
    ///   - reader: The ``JSONReader`` from which to scan the value.
    private func scanSingularMessageField(_ ext: ExtensionSchema, from reader: inout JSONReader) throws {
        let submessageStorage = uniqueMessageStorage(forSingularMessageField: ext)
        try reader.withReaderForNextObject(expectedSchema: submessageStorage.schema) { subReader in
            try submessageStorage.merge(byParsingJSONFrom: &subReader)
        }
    }

    /// Scans the next message from the JSON reader and appends it to the repeated message field.
    ///
    /// - Parameters:
    ///   - ext: The ``ExtensionSchema`` of the extension field being scanned.
    ///   - reader: The ``JSONReader`` from which to scan the value.
    private func scanRepeatedMessageField(_ ext: ExtensionSchema, from reader: inout JSONReader) throws {
        let submessageStorage = messageStorage(forNewlyAppendedElementOfRepeatedMessageField: ext)
        try reader.withReaderForNextObject(expectedSchema: submessageStorage.schema) { subReader in
            try submessageStorage.merge(byParsingJSONFrom: &subReader)
        }
    }

    /// Scans the enum value of the given extension from the reader (handling both name and numeric
    /// cases), performing the given operation on its raw value (either mutate or append).
    ///
    /// - Parameters:
    ///   - schema: The ``ExtensionSchema`` of the field being scanned.
    ///   - reader: The ``JSONReader`` from which to scan the value.
    ///   - operation: The trampoline operation to perform on the enum's raw value.
    private func scanEnumValue(
        _ schema: ExtensionSchema,
        from reader: inout JSONReader,
    ) throws -> Int32 {
        let enumSchema = schema.enumSchema

        if let name = try reader.scanner.nextOptionalQuotedString() {
            guard let number = enumSchema.enumCase(forTextName: name) else {
                throw JSONDecodingError.unrecognizedEnumValue
            }
            return Int32(number)
        }

        if reader.scanner.skipOptionalNull() {
            switch CustomJSONWKTClassification(enumSchema: enumSchema) {
            case .nullValue:
                return 0
            default:
                throw JSONDecodingError.illegalNull
            }
        }

        let number = try reader.scanner.nextSInt()
        guard number >= Int64(Int32.min) && number <= Int64(Int32.max) else {
            throw JSONDecodingError.numberRange
        }

        let rawValue = Int32(truncatingIfNeeded: number)
        guard enumSchema.isValidValue(rawValue) else {
            throw JSONDecodingError.unrecognizedEnumValue
        }
        return rawValue
    }
}
