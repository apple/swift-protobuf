// Sources/SwiftProtobuf/_MessageStorage+JSONDecoding.swift - JSON decoding for messages
//
// Copyright (c) 2014 - 2026 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// JSON decoding support for `_MessageStorage.`
///
// -----------------------------------------------------------------------------

import Foundation

extension _MessageStorage {
    /// Decodes field values from the given UTF-8-encoded JSON buffer into this storage class.
    ///
    /// - Parameters:
    ///   - buffer: The UTF-8-encoded JSON message data to decode.
    ///   - options: The ``JSONDecodingOptions`` to use.
    /// - Throws: ``JSONDecodingError`` if decoding fails.
    public func merge(
        byParsingJSONUTF8Bytes buffer: UnsafeRawBufferPointer,
        extensions: (any ExtensionMap)?,
        options: JSONDecodingOptions
    ) throws {
        var reader = JSONReader(
            buffer: buffer,
            nameMap: schema.nameMap,
            messageSchema: schema,
            options: options,
            extensions: extensions
        )
        try merge(byParsingJSONFrom: &reader)

        guard reader.complete else {
            throw JSONDecodingError.trailingGarbage
        }
    }

    func merge(byParsingJSONFrom reader: inout JSONReader) throws {
        // Helper function that throws an appropriate error if `null` is encountered as the next
        // value. `null` is disallowed at the top-level but allowed as the value of a keyed field
        // (this is handled in `scanSingularValue`).
        func disallowingNull<Result>(_ perform: () throws -> Result) throws -> Result {
            if reader.scanner.skipOptionalNull() {
                throw JSONDecodingError.illegalNull
            }
            return try perform()
        }

        switch CustomJSONWKTClassification(messageSchema: schema) {
        case .any:
            try parseAsAny(from: &reader)

        case .boolValue:
            try disallowingNull {
                updateValue(of: schema[fieldNumber: 1]!, to: try reader.scanner.nextBool())
            }

        case .bytesValue:
            try disallowingNull {
                updateValue(of: schema[fieldNumber: 1]!, to: try reader.scanner.nextBytesValue())
            }

        case .doubleValue:
            try disallowingNull {
                updateValue(of: schema[fieldNumber: 1]!, to: try reader.scanner.nextDouble())
            }

        case .duration:
            try parseAsDuration(from: &reader)

        case .floatValue:
            try disallowingNull {
                updateValue(of: schema[fieldNumber: 1]!, to: try reader.scanner.nextFloat())
            }

        case .int32Value:
            try disallowingNull {
                let n = try reader.scanner.nextSInt()
                if n > Int64(Int32.max) || n < Int64(Int32.min) {
                    throw JSONDecodingError.malformedNumber
                }
                updateValue(of: schema[fieldNumber: 1]!, to: Int32(truncatingIfNeeded: n))
            }

        case .int64Value:
            try disallowingNull {
                updateValue(of: schema[fieldNumber: 1]!, to: try reader.scanner.nextSInt())
            }

        case .listValue:
            try parseAsListValue(from: &reader)

        case .nullValue:
            // `NullValue` is an enum, so we should never see it here.
            preconditionFailure("Unreachable")

        case .stringValue:
            try disallowingNull {
                updateValue(of: schema[fieldNumber: 1]!, to: try reader.scanner.nextQuotedString())
            }

        case .struct:
            try parseAsStruct(from: &reader)

        case .timestamp:
            try parseAsTimestamp(from: &reader)

        case .uint32Value:
            try disallowingNull {
                let n = try reader.scanner.nextUInt()
                if n > UInt64(UInt32.max) {
                    throw JSONDecodingError.malformedNumber
                }
                updateValue(of: schema[fieldNumber: 1]!, to: UInt32(truncatingIfNeeded: n))
            }

        case .uint64Value:
            try disallowingNull {
                updateValue(of: schema[fieldNumber: 1]!, to: try reader.scanner.nextUInt())
            }

        case .value:
            try parseAsValue(from: &reader)

        case .fieldMask:
            // TODO: Actually implement these. For now, just fall through to the default.
            fallthrough

        case .notWellKnown:
            // This is the common case.
            try reader.scanner.skipRequiredObjectStart()
            if reader.scanner.skipOptionalObjectEnd() {
                return
            }

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
                    // It is an error in JSON if we encounter values for more than one member of the same
                    // `oneof`.
                    if case .oneOfMember(let oneOfOffset) = field.presence {
                        if populatedOneofMember(at: oneOfOffset) != 0 {
                            throw JSONDecodingError.conflictingOneOf
                        }
                    }
                    try decodeNextFieldValue(from: &reader, field: field, mapEntryWorkingSpace: &mapEntryWorkingSpace)
                } else if let extensions = reader.scanner.extensions.flatMap({ $0 as? NewExtensionMap }),
                    let ext = extensions[fieldNumber: fieldNumber, in: schema] {
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
        from reader: inout JSONReader,
        field: FieldSchema,
        mapEntryWorkingSpace: inout MapEntryWorkingSpace
    ) throws {
        let fieldType = field.rawFieldType

        switch field.fieldMode.cardinality {
        case .map:
            if reader.scanner.skipOptionalNull() {
                // TODO: Figure out if we should clear the field. The old JSONDecoder implementation
                // just returns, but that might be because we don't have a distinction between
                // merge and init for JSON.
                return
            }
            try scanMapField(field, from: &reader, mapEntryWorkingSpace: &mapEntryWorkingSpace)

        case .array:
            try scanArray(from: &reader) { reader in
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
                    let n = try reader.scanner.nextUInt()
                    if n > UInt64(UInt32.max) {
                        throw JSONDecodingError.malformedNumber
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
                        throw JSONDecodingError.malformedNumber
                    }
                    appendValue(Int32(truncatingIfNeeded: n), to: field)

                case .int64, .sfixed64, .sint64:
                    appendValue(try reader.scanner.nextSInt(), to: field)

                case .string:
                    appendValue(try reader.scanner.nextQuotedString(), to: field)

                default:
                    preconditionFailure("Unreachable")
                }
            }
            break

        case .scalar:
            try scanSingularValue(of: field, from: &reader)

        default:
            preconditionFailure("Unreachable")
        }
    }

    /// Scans a value from the JSON reader, whose storage location and type are provided by the
    /// given field schema.
    ///
    /// - Parameters:
    ///   - field: The ``FieldSchema`` of the field being scanned.
    ///   - reader: The ``JSONReader`` from which to scan the value.
    ///   - requireQuotedBool: If true and the field's type is `bool`, the value is expected to be
    ///     quoted. This is used when scanning map keys.
    private func scanSingularValue(
        of field: FieldSchema,
        from reader: inout JSONReader,
        requireQuotedBool: Bool = false
    ) throws {
        let isNull = reader.scanner.skipOptionalNull()
        switch field.rawFieldType {
        case .bool:
            if isNull {
                clearValue(of: field, type: Bool.self)
                break
            }
            updateValue(
                of: field,
                to: requireQuotedBool ? try reader.scanner.nextQuotedBool() : try reader.scanner.nextBool()
            )

        case .bytes:
            if isNull {
                clearValue(of: field, type: Data.self)
                break
            }
            updateValue(of: field, to: try reader.scanner.nextBytesValue())

        case .double:
            if isNull {
                clearValue(of: field, type: Double.self)
                break
            }
            updateValue(of: field, to: try reader.scanner.nextDouble())

        case .enum:
            if isNull {
                // We don't have the concrete type information for the enum here, but that's
                // fine because we store the raw value for singular enum fields.
                clearValue(of: field, type: Int32.self)
                break
            }
            try scanEnumValue(field, from: &reader, operation: .mutate)

        case .fixed32, .uint32:
            if isNull {
                clearValue(of: field, type: UInt32.self)
                break
            }
            let n = try reader.scanner.nextUInt()
            if n > UInt64(UInt32.max) {
                throw JSONDecodingError.malformedNumber
            }
            updateValue(of: field, to: UInt32(truncatingIfNeeded: n))

        case .fixed64, .uint64:
            if isNull {
                clearValue(of: field, type: UInt64.self)
                break
            }
            updateValue(of: field, to: try reader.scanner.nextUInt())

        case .float:
            if isNull {
                clearValue(of: field, type: Float.self)
                break
            }
            updateValue(of: field, to: try reader.scanner.nextFloat())

        case .group, .message:
            if isNull {
                _ = try schema.performOnSubmessageStorage(
                    MessageSchema.TrampolineToken(index: field.submessageIndex),
                    field,
                    self,
                    .jsonNull
                ) { _ in preconditionFailure("should never be called") }
                return
            }
            try scanSubmessageValue(field, from: &reader, operation: .mutate)

        case .int32, .sfixed32, .sint32:
            if isNull {
                clearValue(of: field, type: Int32.self)
                break
            }
            let n = try reader.scanner.nextSInt()
            if n > Int64(Int32.max) || n < Int64(Int32.min) {
                throw JSONDecodingError.malformedNumber
            }
            updateValue(of: field, to: Int32(truncatingIfNeeded: n))

        case .int64, .sfixed64, .sint64:
            if isNull {
                clearValue(of: field, type: Int64.self)
                break
            }
            updateValue(of: field, to: try reader.scanner.nextSInt())

        case .string:
            if isNull {
                clearValue(of: field, type: String.self)
                break
            }
            updateValue(of: field, to: try reader.scanner.nextQuotedString())

        default:
            preconditionFailure("Unreachable")
        }
    }

    /// Scans a map represented as a JSON object from the reader.
    ///
    /// - Parameters:
    ///   - field: The ``FieldSchema`` of the field being scanned.
    ///   - reader: The ``JSONReader`` from which to scan the value.
    ///   - mapEntryWorkingSpace: The working space that manages reusable map storage objects during
    ///     decoding.
    private func scanMapField(
        _ field: FieldSchema,
        from reader: inout JSONReader,
        mapEntryWorkingSpace: inout MapEntryWorkingSpace
    ) throws {
        try reader.scanner.skipRequiredObjectStart()
        if reader.scanner.skipOptionalObjectEnd() {
            return
        }

        var hasNextElement = true
        while hasNextElement {
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

                // The next character must be double quotes, because map keys must always be
                // quoted strings.
                let c = try reader.scanner.peekOneCharacter()
                guard c == "\"" else {
                    throw JSONDecodingError.unquotedMapKey
                }
                try submessageStorage.scanSingularValue(
                    of: mapEntrySchema[fieldNumber: 1]!,
                    from: &reader,
                    requireQuotedBool: true
                )
                try reader.scanner.skipRequiredColon()

                let isEntryValid: Bool
                do {
                    try submessageStorage.scanSingularValue(of: mapEntrySchema[fieldNumber: 2]!, from: &reader)
                    isEntryValid = true
                } catch JSONDecodingError.unrecognizedEnumValue where reader.options.ignoreUnknownFields {
                    // `ignoreUnknownFields` also means to ignore unknown enum values. If we got
                    // here, set a value indicating that we should discard the map entry instead
                    // of inserting it into the map.
                    isEntryValid = false
                } catch {
                    throw error
                }

                if reader.scanner.skipOptionalObjectEnd() {
                    hasNextElement = false
                } else {
                    try reader.scanner.skipRequiredComma()
                }
                return isEntryValid
            }
        }
    }

    /// Scans the submessage value of the given field from the reader, performing the given
    /// operation on its storage (either mutate or append).
    ///
    /// - Parameters:
    ///   - field: The ``FieldSchema`` of the field being scanned.
    ///   - reader: The ``JSONReader`` from which to scan the value.
    ///   - operation: The trampoline operation to perform on the submessage storage.
    private func scanSubmessageValue(
        _ field: FieldSchema,
        from reader: inout JSONReader,
        operation: TrampolineFieldOperation
    ) throws {
        _ = try schema.performOnSubmessageStorage(
            MessageSchema.TrampolineToken(index: field.submessageIndex),
            field,
            self,
            operation
        ) { submessageStorage in
            try reader.withReaderForNextObject(expectedSchema: submessageStorage.schema) { subReader in
                try submessageStorage.merge(byParsingJSONFrom: &subReader)
            }
            return true
        }
    }

    /// Scans the enum value of the given field from the reader (handling both name and numeric
    /// cases), performing the given operation on its raw value (either mutate or append).
    ///
    /// - Parameters:
    ///   - field: The ``FieldSchema`` of the field being scanned.
    ///   - reader: The ``JSONReader`` from which to scan the value.
    ///   - operation: The trampoline operation to perform on the enum's raw value.
    private func scanEnumValue(
        _ field: FieldSchema,
        from reader: inout JSONReader,
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

            if let name = try reader.scanner.nextOptionalQuotedString() {
                guard let number = enumSchema.nameMap.number(forJSONName: name) else {
                    throw JSONDecodingError.unrecognizedEnumValue
                }
                value = Int32(number)
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

    /// Parses the next object from the input and interprets it as the JSON representation of a
    /// well-known type `Any`.
    ///
    /// - Precondition: The receiver must be the storage for `google.protobuf.Any`.
    private func parseAsAny(from reader: inout JSONReader) throws {
        let typeURLField = schema[fieldNumber: 1]!
        let valueField = schema[fieldNumber: 2]!

        try reader.scanner.skipRequiredObjectStart()

        // An empty JSON object is allowed.
        if reader.scanner.skipOptionalObjectEnd() {
            clearValue(of: typeURLField, type: String.self)
            clearValue(of: valueField, type: Data.self)
            return
        }

        var typeURL: String? = nil
        var possibleWKTValueJSON = ""
        var hadFieldsOtherThanValue = false

        var jsonEncoder = JSONEncoder()
        jsonEncoder.startObject()
        while true {
            let key = try reader.scanner.nextQuotedString()
            try reader.scanner.skipRequiredColon()
            if key == "@type" {
                let scannedURL = try reader.scanner.nextQuotedString()
                guard isTypeURLValid(scannedURL) else {
                    throw SwiftProtobufError.JSONDecoding.invalidAnyTypeURL(type_url: scannedURL)
                }
                typeURL = scannedURL
            } else {
                jsonEncoder.startField(name: key)
                let keyValueJSON = try reader.scanner.skip()
                if key == "value" {
                    // When we encounter the key `value`, we may need to parse this as a well-known
                    // type with a special representation, so keep track of it.
                    possibleWKTValueJSON = keyValueJSON
                } else {
                    // Keep track of this because if it's a well-known type, we need to fail later
                    // if we're not ignoring unknown fields.
                    hadFieldsOtherThanValue = true
                }
                jsonEncoder.append(text: keyValueJSON)
            }
            if reader.scanner.skipOptionalObjectEnd() {
                if typeURL == nil {
                    throw SwiftProtobufError.JSONDecoding.emptyAnyTypeURL()
                }
                break
            }
            try reader.scanner.skipRequiredComma()
        }
        jsonEncoder.endObject()

        guard let typeURL else {
            throw SwiftProtobufError.JSONDecoding.invalidAnyTypeURL(type_url: "")
        }
        guard let messageSchema = Google_Protobuf_Any.messageSchema(forTypeURL: typeURL) else {
            throw SwiftProtobufError.JSONDecoding.unknownAnyTypeURL(type_url: typeURL)
        }

        let messageStorage = _MessageStorage(schema: messageSchema)
        func parseJSONBuffer(_ buffer: UnsafeRawBufferPointer) throws {
            var subReader = JSONReader(
                buffer: buffer,
                nameMap: messageSchema.nameMap,
                messageSchema: messageSchema,
                options: reader.options,
                extensions: reader.scanner.extensions)
            try messageStorage.merge(byParsingJSONFrom: &subReader)
        }

        switch CustomJSONWKTClassification(messageSchema: messageSchema) {
        case .notWellKnown:
            try jsonEncoder.bytesResult.withUnsafeBytes { buffer in
                try parseJSONBuffer(buffer)
            }

        default:
            // Well-known types in `Any` must *only* have a `value` field, unless we're ignoring
            // unknown fields.
            if hadFieldsOtherThanValue && !reader.options.ignoreUnknownFields {
                throw AnyUnpackError.malformedWellKnownTypeJSON
            }
            try possibleWKTValueJSON.withUTF8 { buffer in
                try parseJSONBuffer(UnsafeRawBufferPointer(buffer))
            }
        }

        updateValue(of: typeURLField, to: typeURL)
        updateValue(of: valueField, to: try messageStorage.serializedBytes(partial: true, options: BinaryEncodingOptions()))
    }

    /// Parses the next quoted string from the input and interprets it as the JSON representation
    /// of a well-known type `Duration`.
    ///
    /// - Precondition: The receiver must be the storage for `google.protobuf.Duration`.
    private func parseAsDuration(from reader: inout JSONReader) throws {
        let durationString = try reader.scanner.nextQuotedString()
        let (seconds, nanos) = try parseDuration(text: durationString)
        updateValue(of: schema[fieldNumber: 1]!, to: seconds)
        updateValue(of: schema[fieldNumber: 2]!, to: nanos)
    }

    /// Parses the next value from the input and interprets it as the JSON representation of a
    /// well-known type `ListValue`.
    ///
    /// - Precondition: The receiver must be the storage for `google.protobuf.ListValue`.
    private func parseAsListValue(from reader: inout JSONReader) throws {
        if reader.scanner.skipOptionalNull() {
            // TODO: Figure out if we should clear the field. The old JSONDecoder implementation
            // just returns, but that might be because we don't have a distinction between
            // merge and init for JSON.
            return
        }
        try reader.scanner.skipRequiredArrayStart()
        // Since we override the JSON decoding, we can't rely on the default recursion depth
        // tracking.
        try reader.scanner.incrementRecursionDepth()
        if reader.scanner.skipOptionalArrayEnd() {
            reader.scanner.decrementRecursionDepth()
            return
        }

        while true {
            try scanSubmessageValue(schema[fieldNumber: 1]!, from: &reader, operation: .append)
            if reader.scanner.skipOptionalArrayEnd() {
                reader.scanner.decrementRecursionDepth()
                return
            }
            try reader.scanner.skipRequiredComma()
        }
    }

    /// Parses the next value from the input and interprets it as the JSON representation of a
    /// well-known type `Struct`.
    ///
    /// - Precondition: The receiver must be the storage for `google.protobuf.Value`.
    private func parseAsStruct(from reader: inout JSONReader) throws {
        try reader.scanner.skipRequiredObjectStart()
        if reader.scanner.skipOptionalObjectEnd() {
            return
        }

        var mapEntryWorkingSpace = MapEntryWorkingSpace(ownerSchema: schema)
        let fieldsField = schema[fieldNumber: 1]!
        var hasNextElement = true
        while hasNextElement {
            _ = try schema.performOnMapEntry(
                MessageSchema.TrampolineToken(index: fieldsField.submessageIndex),
                fieldsField,
                self,
                mapEntryWorkingSpace.storage(for: fieldsField.submessageIndex),
                .append,
                // Deterministic ordering doesn't apply to decoding.
                false
            ) { submessageStorage in
                let mapEntrySchema = submessageStorage.schema

                // The next character must be double quotes, because map keys must always be
                // quoted strings.
                let c = try reader.scanner.peekOneCharacter()
                guard c == "\"" else {
                    throw JSONDecodingError.unquotedMapKey
                }
                try submessageStorage.scanSingularValue(
                    of: mapEntrySchema[fieldNumber: 1]!,
                    from: &reader,
                    requireQuotedBool: true
                )
                try reader.scanner.skipRequiredColon()

                let isEntryValid: Bool
                do {
                    try submessageStorage.scanSingularValue(of: mapEntrySchema[fieldNumber: 2]!, from: &reader)
                    isEntryValid = true
                } catch JSONDecodingError.unrecognizedEnumValue where reader.options.ignoreUnknownFields {
                    // `ignoreUnknownFields` also means to ignore unknown enum values. If we got
                    // here, set a value indicating that we should discard the map entry instead
                    // of inserting it into the map.
                    isEntryValid = false
                } catch {
                    throw error
                }

                if reader.scanner.skipOptionalObjectEnd() {
                    hasNextElement = false
                } else {
                    try reader.scanner.skipRequiredComma()
                }
                return isEntryValid
            }
        }
    }

    /// Parses the next quoted string from the input and interprets it as the JSON representation
    /// of a well-known type `Timestamp`.
    ///
    /// - Precondition: The receiver must be the storage for `google.protobuf.Timestamp`.
    private func parseAsTimestamp(from reader: inout JSONReader) throws {
        let timestampString = try reader.scanner.nextQuotedString()
        let (seconds, nanos) = try parseTimestamp(s: timestampString)
        updateValue(of: schema[fieldNumber: 1]!, to: seconds)
        updateValue(of: schema[fieldNumber: 2]!, to: nanos)
    }

    /// Parses the next value from the input and interprets it as the JSON representation of a
    /// well-known type `Value`.
    ///
    /// - Precondition: The receiver must be the storage for `google.protobuf.Value`.
    private func parseAsValue(from reader: inout JSONReader) throws {
        let c = try reader.scanner.peekOneCharacter()
        switch c {
        case "n":
            if !reader.scanner.skipOptionalNull() {
                throw JSONDecodingError.failure
            }
            updateValue(of: schema[fieldNumber: 1]!, to: Google_Protobuf_NullValue.nullValue)

        case "[":
            try scanSubmessageValue(schema[fieldNumber: 6]!, from: &reader, operation: .mutate)

        case "{":
            try scanSubmessageValue(schema[fieldNumber: 5]!, from: &reader, operation: .mutate)

        case "t", "f":
            updateValue(of: schema[fieldNumber: 4]!, to: try reader.scanner.nextBool())

        case "\"":
            updateValue(of: schema[fieldNumber: 3]!, to: try reader.scanner.nextQuotedString())

        default:
            updateValue(of: schema[fieldNumber: 2]!, to: try reader.scanner.nextDouble())
        }
    }
}

/// Called to scan an array of values.
///
/// - Parameters:
///   - reader: The ``JSONReader`` from which to scan the value.
///   - scanAndAppendSingleValue: A closure that is called for each perceived element in the
///     array, which is responsible for scanning the next value from the reader and appending it
///     to the field's storage.
func scanArray(
    from reader: inout JSONReader,
    scanAndAppendSingleValue: (inout JSONReader) throws -> Void
) throws {
    if reader.scanner.skipOptionalNull() {
        // TODO: Figure out if we should clear the field. The old JSONDecoder implementation
        // just returns, but that might be because we don't have a distinction between
        // merge and init for JSON.
        return
    }
    try reader.scanner.skipRequiredArrayStart()
    if reader.scanner.skipOptionalArrayEnd() {
        return
    }

    while true {
        try scanAndAppendSingleValue(&reader)
        if reader.scanner.skipOptionalArrayEnd() {
            return
        }
        try reader.scanner.skipRequiredComma()
    }
}

// Spec for Any says this should contain atleast one slash. Looking at upstream languages, most
// actually look up the value in their runtime registries, but since we don't have a complete type
// registry, just do this minimal validation check.
func isTypeURLValid(_ typeURL: String) -> Bool {
    typeURL.contains(where: { $0 == "/" })
}
