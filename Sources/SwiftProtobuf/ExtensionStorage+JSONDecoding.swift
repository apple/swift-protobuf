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
                    try scanEnumValue(schema, from: &reader, operation: .append)

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
                    try scanSubmessageValue(schema, from: &reader, operation: .append)

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
            try scanEnumValue(schema, from: &reader, operation: .mutate)

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
                _ = try schema.performOnSubmessageStorage(
                    schema,
                    self,
                    .jsonNull
                ) { _ in preconditionFailure("should never be called") }
                return
            }
            try scanSubmessageValue(schema, from: &reader, operation: .mutate)

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

    /// Scans the submessage value of the given extension from the reader, performing the given
    /// operation on its storage (either mutate or append).
    ///
    /// - Parameters:
    ///   - field: The ``ExtensionSchema`` of the extension being scanned.
    ///   - reader: The ``JSONReader`` from which to scan the value.
    ///   - operation: The trampoline operation to perform on the submessage storage.
    private func scanSubmessageValue(
        _ schema: ExtensionSchema,
        from reader: inout JSONReader,
        operation: TrampolineFieldOperation
    ) throws {
        _ = try schema.performOnSubmessageStorage(
            schema,
            self,
            operation
        ) { submessageStorage in
            try reader.withReaderForNextObject(expectedSchema: submessageStorage.schema) { subReader in
                try submessageStorage.merge(byParsingJSONFrom: &subReader)
            }
            return true
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
        operation: TrampolineFieldOperation
    ) throws {
        var hasSeenValue = false

        _ = try schema.performOnRawEnumValues(
            schema,
            self,
            operation
        ) { enumSchema, value in
            // For the repeated case, terminate the loop inside `performOnRawEnumValues` after
            // having read one value.
            if hasSeenValue {
                return false
            }
            hasSeenValue = true

            if let name = try reader.scanner.nextOptionalQuotedString() {
                guard let number = enumSchema.enumCase(forTextName: name) else {
                    throw JSONDecodingError.unrecognizedEnumValue
                }
                value = number
                return true
            }

            let number = try reader.scanner.nextSInt()
            guard number >= Int64(Int32.min) && number <= Int64(Int32.max) else {
                throw JSONDecodingError.numberRange
            }

            value = Int32(truncatingIfNeeded: number)
            return true
        } /*onInvalidValue*/ _: { _ in
            throw JSONDecodingError.unrecognizedEnumValue
        }
    }
}
