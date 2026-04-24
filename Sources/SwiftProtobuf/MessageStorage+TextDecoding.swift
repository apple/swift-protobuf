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
            if let typeURL = try reader.scanner.nextOptionalAnyURL() {
                try parseAsExpandedAny(from: &reader, typeURL: typeURL)
                break
            }

            // If it didn't use the expanded form, then we should parse it as regular fields.
            fallthrough

        default:
            var mapEntryWorkingSpace = MapEntryWorkingSpace(ownerSchema: schema)
            while let fieldNumber = try reader.nextFieldNumber() {
                // TODO: This is a little awkward, because in the extension case we're doing the lookup
                // into the extension map twice: inside `reader.nextFieldNumber` (because we need to
                // find the extension that matches the name we parsed), and then here below. Once we've
                // removed the relevant bits of the old implementation, we can clean this up by having
                // a method on `TextFormatReader` that returns a structured value containing either the
                // `FieldSchema` or the `ExtensionSchema` that corresponds to whatever it reads from the
                // input.
                if let field = schema[fieldNumber: fieldNumber] {
                    try decodeNextFieldValue(from: &reader, field: field, mapEntryWorkingSpace: &mapEntryWorkingSpace)
                } else if let extensions = reader.scanner.extensions,
                          let ext = extensions[fieldNumber: fieldNumber, in: schema]
                {
                    try extensionStorage.decodeNextExtension(ext, from: &reader)
                } else {
                    // The scanner should have already skipped any unknown fields or thrown an error
                    // (depending on the decoding options), so any field we get back from this reader
                    // should always exist.
                    preconditionFailure("unreachable")
                }
            }
        }
    }

    private func decodeNextFieldValue(
        from reader: inout TextFormatReader,
        field: FieldSchema,
        mapEntryWorkingSpace: inout MapEntryWorkingSpace
    ) throws {
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
            try scanPossibleArray(from: &reader) { reader in
                _ = try schema.performOnMapEntry(
                    MessageSchema.TrampolineToken(index: field.submessageIndex),
                    field,
                    self,
                    mapEntryWorkingSpace.storage(for: field.submessageIndex),
                    .append,
                    // Deterministic ordering doesn't apply to decoding.
                    false
                ) { submessageStorage in
                    let mapEntrySchema = submessageStorage.schema
                    try reader.withReaderForNextObject(expectedSchema: mapEntrySchema) { subReader in
                        try submessageStorage.merge(byParsingTextFormatFrom: &subReader)
                    }
                    return true
                }
            }

        case .array:
            try scanPossibleArray(from: &reader) { reader in
                switch fieldType {
                case .bool:
                    appendValue(try reader.scanner.nextBool(), to: field)

                case .bytes:
                    appendValue(try reader.scanner.nextBytesValue(), to: field)

                case .double:
                    appendValue(try reader.scanner.nextDouble(), to: field)

                case .enum:
                    try scanEnumValue(field, from: &reader, operation: .append)

                case .fixed32, .uint32:
                    let n = try reader.scanner.nextSInt()
                    if n > UInt64(UInt32.max) {
                        throw TextFormatDecodingError.malformedNumber
                    }
                    appendValue(UInt32(truncatingIfNeeded: n), to: field)

                case .fixed64, .uint64:
                    appendValue(try reader.scanner.nextUInt(), to: field)

                case .float:
                    appendValue(try reader.scanner.nextFloat(), to: field)

                case .group, .message:
                    try scanSubmessageValue(field, from: &reader, operation: .append)

                case .int32, .sfixed32, .sint32:
                    let n = try reader.scanner.nextSInt()
                    if n > Int64(Int32.max) || n < Int64(Int32.min) {
                        throw TextFormatDecodingError.malformedNumber
                    }
                    appendValue(Int32(truncatingIfNeeded: n), to: field)

                case .int64, .sfixed64, .sint64:
                    appendValue(try reader.scanner.nextSInt(), to: field)

                case .string:
                    appendValue(try reader.scanner.nextStringValue(), to: field)

                default:
                    preconditionFailure("Unreachable")
                }
            }

        case .scalar:
            switch fieldType {
            case .bool:
                updateValue(of: field, to: try reader.scanner.nextBool())

            case .bytes:
                updateValue(of: field, to: try reader.scanner.nextBytesValue())

            case .double:
                // Special case: If the text format value is negative zero, we need to preserve
                // that. The `updateValue` overload that takes a `FieldSchema` only checks for zero
                // equality, so we need to manually manage the presence here.
                let d = try reader.scanner.nextDouble()
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
                try scanEnumValue(field, from: &reader, operation: .mutate)

            case .fixed32, .uint32:
                let n = try reader.scanner.nextUInt()
                if n > UInt64(UInt32.max) {
                    throw TextFormatDecodingError.malformedNumber
                }
                updateValue(of: field, to: UInt32(truncatingIfNeeded: n))

            case .fixed64, .uint64:
                updateValue(of: field, to: try reader.scanner.nextUInt())

            case .float:
                // Special case: If the text format value is negative zero, we need to preserve
                // that. The `updateValue` overload that takes a `FieldSchema` only checks for zero
                // equality, so we need to manually manage the presence here.
                let f = try reader.scanner.nextFloat()
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
                try scanSubmessageValue(field, from: &reader, operation: .mutate)

            case .int32, .sfixed32, .sint32:
                let n = try reader.scanner.nextSInt()
                if n > Int64(Int32.max) || n < Int64(Int32.min) {
                    throw TextFormatDecodingError.malformedNumber
                }
                updateValue(of: field, to: Int32(truncatingIfNeeded: n))

            case .int64, .sfixed64, .sint64:
                updateValue(of: field, to: try reader.scanner.nextSInt())

            case .string:
                updateValue(of: field, to: try reader.scanner.nextStringValue())

            default:
                preconditionFailure("Unreachable")
            }

        default:
            preconditionFailure("Unreachable")
        }
    }

    /// Scans the submessage value of the given field from the reader, performing the given
    /// operation on its storage (either mutate or append).
    private func scanSubmessageValue(
        _ field: FieldSchema,
        from reader: inout TextFormatReader,
        operation: TrampolineFieldOperation
    ) throws {
        _ = try schema.performOnSubmessageStorage(
            MessageSchema.TrampolineToken(index: field.submessageIndex),
            field,
            self,
            operation
        ) { submessageStorage in
            try reader.withReaderForNextObject(expectedSchema: submessageStorage.schema) { subReader in
                try submessageStorage.merge(byParsingTextFormatFrom: &subReader)
            }
            return true
        }
    }

    /// Scans the enum value of the given field from the reader (handling both name and numeric
    /// cases), performing the given operation on its raw value (either mutate or append).
    private func scanEnumValue(
        _ field: FieldSchema,
        from reader: inout TextFormatReader,
        operation: TrampolineFieldOperation
    ) throws {
        var hasSeenValue = false

        _ = try schema.performOnRawEnumValues(
            MessageSchema.TrampolineToken(index: field.submessageIndex),
            field,
            self,
            operation
        ) { enumSchema, value in
            // For the repeated case, terminate the loop inside `performOnRawEnumValues` after
            // having read one value.
            if hasSeenValue {
                return false
            }
            hasSeenValue = true

            if let name = try reader.scanner.nextOptionalEnumName() {
                guard let number = enumSchema.enumCase(forTextName: name) else {
                    throw TextFormatDecodingError.unrecognizedEnumValue
                }
                value = number
                return true
            }

            let number = try reader.scanner.nextSInt()
            guard number >= Int64(Int32.min) && number <= Int64(Int32.max) else {
                throw TextFormatDecodingError.malformedText
            }

            value = Int32(truncatingIfNeeded: number)
            return true
        } /*onInvalidValue*/ _: { _ in
            throw TextFormatDecodingError.unrecognizedEnumValue
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
        if try reader.nextFieldNumber() != nil {
            throw TextFormatDecodingError.malformedText
        }

        updateValue(of: schema[fieldNumber: 1]!, to: typeURL)
        updateValue(
            of: schema[fieldNumber: 2]!,
            to: try messageStorage.serializedBytes(partial: true, options: BinaryEncodingOptions())
        )
    }
}

/// Called to scan the next value, which might be an array of values.
///
/// In text format, repeated fields of non-message types can be represented in two ways:
/// repetition of the field name and value, or as the field name followed by an array of values
/// in square brackets. If we detect the square bracket, we delegate to the given closure to
/// scan and append the value until we encounter the corresponding closing bracket. Otherwise,
/// we call the closure only once to scan and append an individual value.
func scanPossibleArray(
    from reader: inout TextFormatReader,
    scanAndAppendSingleValue: (inout TextFormatReader) throws -> Void
) throws {
    guard reader.scanner.skipOptionalBeginArray() else {
        // If we didn't see a square bracket, assume it's a single element and call the closure
        // once.
        try scanAndAppendSingleValue(&reader)
        return
    }

    // We saw a left bracket, so read multiple elements, calling the closure for each one.
    var firstItem = true
    while true {
        if reader.scanner.skipOptionalEndArray() {
            return
        }
        if firstItem {
            firstItem = false
        } else {
            try reader.scanner.skipRequiredComma()
        }
        try scanAndAppendSingleValue(&reader)
    }
}
