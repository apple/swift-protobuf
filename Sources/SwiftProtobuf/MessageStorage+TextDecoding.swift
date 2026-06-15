// Sources/SwiftProtobuf/MessageStorage+TextDecoding.swift - Text format decoding for messages
//
// Copyright (c) 2014 - 2026 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Text format decoding support for `MessageStorage.`
///
// -----------------------------------------------------------------------------

import Foundation

extension MessageStorage {
    /// Decodes values from the given text format reader into the receiver.
    func merge(byParsingTextFormatFrom reader: inout TextFormatReader) throws {
        switch CustomJSONWKTClassification(messageSchema: schema) {
        case .any:
            // Check if the message is the expanded form of `google.protobuf.Any`.
            if reader.at(.leftBracket) {
                let typeURL = try reader.consumeAnyTypeURLOrExtensionName()
                try parseAsExpandedAny(from: &reader, typeURL: typeURL)
                break
            }

            // If it didn't use the expanded form, then we should parse it as regular fields.
            fallthrough

        default:
            var mapEntryWorkingSpace = MapEntryWorkingSpace(ownerSchema: schema)
            while let fieldOrExtension = try reader.consumeFieldOrExtensionIfPresent() {
                switch fieldOrExtension {
                case .field(let field):
                    try decodeNextFieldValue(from: &reader, field: field, mapEntryWorkingSpace: &mapEntryWorkingSpace)
                case .extension(let ext):
                    try extensionStorage.decodeNextExtension(ext, from: &reader)
                case .unknown:
                    try reader.skipField(wasNameAlreadyConsumed: true)
                }
                try reader.consumeFieldSeparatorIfPresent()
            }
        }
    }

    private func decodeNextFieldValue(
        from reader: inout TextFormatReader,
        field: MessageSchema.Field,
        mapEntryWorkingSpace: inout MapEntryWorkingSpace
    ) throws {
        let fieldType = field.rawFieldType

        // A colon after the field name is required unless it's a group/message field.
        switch fieldType {
        case .group, .message:
            try reader.consumeIfPresent(.colon)
        default:
            try reader.consume(.colon)
        }

        switch field.fieldMode.cardinality {
        case .map:
            try reader.consumePossibleArray { reader in
                let workingSpace = mapEntryWorkingSpace.storage(for: field.submessageIndex)
                let mapEntrySchema = workingSpace.schema
                try reader.withReaderForNextObject(expectedSchema: mapEntrySchema) { subReader in
                    try workingSpace.merge(byParsingTextFormatFrom: &subReader)
                }
                insertMapEntry(in: field, from: workingSpace)
            }

        case .array:
            try reader.consumePossibleArray { reader in
                switch fieldType {
                case .bool:
                    appendValue(try reader.consumeBool(), to: field)

                case .bytes:
                    appendValue(try reader.consumeBytes(), to: field)

                case .double:
                    appendValue(try reader.consumeDouble(), to: field)

                case .enum:
                    appendEnumValue(
                        withRawValue: try reader.consumeEnumValue(schema: enumSchema(for: field)),
                        toRepeatedEnumField: field
                    )

                case .fixed32, .uint32:
                    let n = try reader.consumeUnsignedInteger(upperBound: UInt64(UInt32.max))
                    appendValue(UInt32(truncatingIfNeeded: n), to: field)

                case .fixed64, .uint64:
                    appendValue(try reader.consumeUnsignedInteger(upperBound: UInt64.max), to: field)

                case .float:
                    appendValue(try Float(reader.consumeDouble()), to: field)

                case .group, .message:
                    let submessageStorage = messageStorage(forNewlyAppendedElementOfRepeatedMessageField: field)
                    try reader.withReaderForNextObject(expectedSchema: submessageStorage.schema) { subReader in
                        try submessageStorage.merge(byParsingTextFormatFrom: &subReader)
                    }

                case .int32, .sfixed32, .sint32:
                    let n = try reader.consumeSignedInteger(upperBound: Int64(Int32.max))
                    appendValue(Int32(truncatingIfNeeded: n), to: field)

                case .int64, .sfixed64, .sint64:
                    appendValue(try reader.consumeSignedInteger(upperBound: Int64.max), to: field)

                case .string:
                    appendValue(try reader.consumeString(), to: field)

                default:
                    preconditionFailure("Unreachable")
                }
            }

        case .scalar:
            switch fieldType {
            case .bool:
                updateValue(of: field, to: try reader.consumeBool())

            case .bytes:
                updateValue(of: field, to: try reader.consumeBytes())

            case .double:
                // Special case: If the text format value is negative zero, we need to preserve
                // that. The `updateValue` overload that takes a `MessageSchema.Field` only checks
                // for zero equality, so we need to manually manage the presence here.
                let d = try reader.consumeDouble()
                let offset = field.offset
                switch field.presence {
                case .hasBit(let hasByteOffset, let hasMask):
                    updateValue(
                        at: offset,
                        to: d,
                        willBeSet: schema.fieldHasPresence(field) ? true : (d != 0 || d.sign == .minus),
                        hasBit: (hasByteOffset, hasMask)
                    )
                case .oneOfMember(let oneofOffset):
                    updateValue(at: offset, to: d, oneofPresence: (oneofOffset, field.fieldNumber))
                }

            case .enum:
                updateValue(of: field, to: try reader.consumeEnumValue(schema: enumSchema(for: field)))

            case .fixed32, .uint32:
                let n = try reader.consumeUnsignedInteger(upperBound: UInt64(UInt32.max))
                updateValue(of: field, to: UInt32(truncatingIfNeeded: n))

            case .fixed64, .uint64:
                updateValue(of: field, to: try reader.consumeUnsignedInteger(upperBound: UInt64.max))

            case .float:
                // Special case: If the text format value is negative zero, we need to preserve
                // that. The `updateValue` overload that takes a `MessageSchema.Field` only checks
                // for zero equality, so we need to manually manage the presence here.
                let f = Float(try reader.consumeDouble())
                let offset = field.offset
                switch field.presence {
                case .hasBit(let hasByteOffset, let hasMask):
                    updateValue(
                        at: offset,
                        to: f,
                        willBeSet: schema.fieldHasPresence(field) ? true : (f != 0 || f.sign == .minus),
                        hasBit: (hasByteOffset, hasMask)
                    )
                case .oneOfMember(let oneofOffset):
                    updateValue(at: offset, to: f, oneofPresence: (oneofOffset, field.fieldNumber))
                }

            case .group, .message:
                let submessageStorage = uniqueMessageStorage(forSingularMessageField: field)
                try reader.withReaderForNextObject(expectedSchema: submessageStorage.schema) { subReader in
                    try submessageStorage.merge(byParsingTextFormatFrom: &subReader)
                }

            case .int32, .sfixed32, .sint32:
                let n = try reader.consumeSignedInteger(upperBound: Int64(Int32.max))
                updateValue(of: field, to: Int32(truncatingIfNeeded: n))

            case .int64, .sfixed64, .sint64:
                updateValue(of: field, to: try reader.consumeSignedInteger(upperBound: Int64.max))

            case .string:
                updateValue(of: field, to: try reader.consumeString())

            default:
                preconditionFailure("Unreachable")
            }

        default:
            preconditionFailure("Unreachable")
        }
    }

    /// Parses the next object from the input and interprets it as the expanded form of the
    /// well-known type `Any` containing a message with the given type URL.
    ///
    /// - Precondition: The receiver must be the storage for `google.protobuf.Any`.
    private func parseAsExpandedAny(from reader: inout TextFormatReader, typeURL: String) throws {
        guard let messageSchema = Google_Protobuf_Any.messageSchema(forTypeURL: typeURL) else {
            throw SwiftProtobufError.TextFormatDecoding.invalidAnyTypeURL(type_url: typeURL)
        }

        let messageStorage = MessageStorage(schema: messageSchema)

        try reader.withReaderForNextObject(expectedSchema: messageSchema) { subReader in
            try messageStorage.merge(byParsingTextFormatFrom: &subReader)
        }
        // The expanded form of `Any` can never have additional keys. This call is required to
        // verify that and to consume the closing separator.
        guard reader.at(.rightBrace, .rightAngle, .end) else {
            throw reader.parsingError(reason: "Expected end of message after expanded 'Any' form")
        }

        updateValue(of: KnownField.anyTypeURL(in: schema), to: typeURL)
        var options = BinaryEncodingOptions()
        options.allowPartial = true
        updateValue(
            of: KnownField.anyValue(in: schema),
            to: try messageStorage.serializedBytes(options: options)
        )
    }
}
