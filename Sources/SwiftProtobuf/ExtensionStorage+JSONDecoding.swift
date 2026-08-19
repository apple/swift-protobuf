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

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

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
            try reader.consumeArray { reader in
                switch fieldType {
                case .bool:
                    appendValue(try reader.consumeBool(), to: schema)

                case .bytes:
                    appendValue(try reader.consumeBytes(), to: schema)

                case .double:
                    appendValue(try reader.consumeDouble(), to: schema)

                case .enum:
                    // Decoding an enum field in JSON requires that the schema be linked into the
                    // binary; otherwise, we don't know the value names.
                    guard let enumSchema = schema.enumSchema else {
                        throw reader.parsingError(
                            reason: """
                                Schema not found for extension enum field \(schema.fieldNumber); \
                                was it weak-linked and dropped by the linker?
                                """
                        )
                    }
                    guard let value = try reader.consumeEnumValue(schema: enumSchema) else {
                        break
                    }
                    appendValue(value, to: schema)

                case .fixed32, .uint32:
                    let n = try reader.consumeUnsignedInteger(upperBound: UInt64(UInt32.max))
                    appendValue(UInt32(truncatingIfNeeded: n), to: schema)

                case .fixed64, .uint64:
                    appendValue(try reader.consumeUnsignedInteger(upperBound: UInt64.max), to: schema)

                case .float:
                    appendValue(try reader.consumeFloat(), to: schema)

                case .group, .message:
                    try scanRepeatedMessageField(schema, from: &reader)

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
        let isNull = try reader.consumeNullIfPresent()
        switch field.rawFieldType {
        case .bool:
            if isNull {
                clearValue(of: schema, type: Bool.self)
                break
            }
            updateValue(of: schema, to: try reader.consumeBool())

        case .bytes:
            if isNull {
                clearValue(of: schema, type: Data.self)
                break
            }
            updateValue(of: schema, to: try reader.consumeBytes())

        case .double:
            if isNull {
                clearValue(of: schema, type: Double.self)
                break
            }
            updateValue(of: schema, to: try reader.consumeDouble())

        case .enum:
            if isNull {
                // We don't have the concrete type information for the enum here, but that's
                // fine because we store the raw value for singular enum fields.
                clearValue(of: schema, type: Int32.self)
                break
            }
            // Decoding an enum field in JSON requires that the schema be linked into the
            // binary; otherwise, we don't know the value names.
            guard let enumSchema = schema.enumSchema else {
                throw reader.parsingError(
                    reason: """
                        Schema not found for extension enum field \(schema.fieldNumber); \
                        was it weak-linked and dropped by the linker?
                        """
                )
            }
            guard let value = try reader.consumeEnumValue(schema: enumSchema) else {
                break
            }
            updateValue(of: schema, to: value)

        case .fixed32, .uint32:
            if isNull {
                clearValue(of: schema, type: UInt32.self)
                break
            }
            let n = try reader.consumeUnsignedInteger(upperBound: UInt64(UInt32.max))
            updateValue(of: schema, to: UInt32(truncatingIfNeeded: n))

        case .fixed64, .uint64:
            if isNull {
                clearValue(of: schema, type: UInt64.self)
                break
            }
            updateValue(of: schema, to: try reader.consumeUnsignedInteger(upperBound: UInt64.max))

        case .float:
            if isNull {
                clearValue(of: schema, type: Float.self)
                break
            }
            updateValue(of: schema, to: try reader.consumeFloat())

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
            let n = try reader.consumeSignedInteger(upperBound: Int64(Int32.max))
            updateValue(of: schema, to: Int32(truncatingIfNeeded: n))

        case .int64, .sfixed64, .sint64:
            if isNull {
                clearValue(of: schema, type: Int64.self)
                break
            }
            updateValue(of: schema, to: try reader.consumeSignedInteger(upperBound: Int64.max))

        case .string:
            if isNull {
                clearValue(of: schema, type: String.self)
                break
            }
            updateValue(of: schema, to: try reader.consumeString())

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
        guard let submessageStorage = uniqueMessageStorage(forSingularMessageField: ext) else {
            throw reader.parsingError(
                reason: """
                    Schema not found for extension message field \(ext.fieldNumber); \
                    was it weak-linked and dropped by the linker?
                    """
            )
        }
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
        guard let submessageStorage = messageStorage(forNewlyAppendedElementOfRepeatedMessageField: ext) else {
            throw reader.parsingError(
                reason: """
                    Schema not found for extension message field \(ext.fieldNumber); \
                    was it weak-linked and dropped by the linker?
                    """
            )
        }
        try reader.withReaderForNextObject(expectedSchema: submessageStorage.schema) { subReader in
            try submessageStorage.merge(byParsingJSONFrom: &subReader)
        }
    }
}
