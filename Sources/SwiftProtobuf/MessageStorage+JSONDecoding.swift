// Sources/SwiftProtobuf/MessageStorage+JSONDecoding.swift - JSON decoding for messages
//
// Copyright (c) 2014 - 2026 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// JSON decoding support for `MessageStorage.`
///
// -----------------------------------------------------------------------------

import Foundation

extension MessageStorage {
    /// Decodes field values from the given JSON reader into this storage class.
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
                updateValue(of: KnownField.boolValueValue(in: schema), to: try reader.scanner.nextBool())
            }

        case .bytesValue:
            try disallowingNull {
                updateValue(of: KnownField.bytesValueValue(in: schema), to: try reader.scanner.nextBytesValue())
            }

        case .doubleValue:
            try disallowingNull {
                updateValue(of: KnownField.doubleValueValue(in: schema), to: try reader.scanner.nextDouble())
            }

        case .duration:
            try parseAsDuration(from: &reader)

        case .fieldMask:
            try parseAsFieldMask(from: &reader)

        case .floatValue:
            try disallowingNull {
                updateValue(of: KnownField.floatValueValue(in: schema), to: try reader.scanner.nextFloat())
            }

        case .int32Value:
            try disallowingNull {
                let n = try reader.scanner.nextSInt()
                if n > Int64(Int32.max) || n < Int64(Int32.min) {
                    throw JSONDecodingError.malformedNumber
                }
                updateValue(of: KnownField.int32ValueValue(in: schema), to: Int32(truncatingIfNeeded: n))
            }

        case .int64Value:
            try disallowingNull {
                updateValue(of: KnownField.int64ValueValue(in: schema), to: try reader.scanner.nextSInt())
            }

        case .listValue:
            try parseAsListValue(from: &reader)

        case .nullValue:
            // `NullValue` is an enum, so we should never see it here.
            preconditionFailure("Unreachable")

        case .stringValue:
            try disallowingNull {
                updateValue(of: KnownField.stringValueValue(in: schema), to: try reader.scanner.nextQuotedString())
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
                updateValue(of: KnownField.uint32ValueValue(in: schema), to: UInt32(truncatingIfNeeded: n))
            }

        case .uint64Value:
            try disallowingNull {
                updateValue(of: KnownField.uint64ValueValue(in: schema), to: try reader.scanner.nextUInt())
            }

        case .value:
            try parseAsValue(from: &reader)

        case .notWellKnown:
            // This is the common case.
            try reader.scanner.skipRequiredObjectStart()
            if reader.scanner.skipOptionalObjectEnd() {
                return
            }

            var mapEntryWorkingSpace = MapEntryWorkingSpace(ownerSchema: schema)
            var seenFields = Set<UInt32>()
            while let fieldNumber = try reader.nextFieldNumber() {
                if !seenFields.insert(fieldNumber).inserted {
                    // It's an error if we see the same field more than once (even with different
                    // spellings, like JSON and text format).
                    throw JSONDecodingError.failure
                }
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
                            // JSON only allows multiple keys from a `oneof` to be set if at most one is
                            // not `null`.
                            if reader.scanner.skipOptionalNull() {
                                continue
                            }
                            throw JSONDecodingError.conflictingOneOf
                        }
                    }
                    try decodeNextFieldValue(from: &reader, field: field, mapEntryWorkingSpace: &mapEntryWorkingSpace)
                } else if let extensions = reader.scanner.extensions,
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
                    do {
                        appendEnumValue(
                            withRawValue: try scanEnumValue(field, from: &reader),
                            toRepeatedEnumField: field
                        )
                    } catch JSONDecodingError.unrecognizedEnumValue where reader.options.ignoreUnknownFields {
                        // Ignore unknown enum values if requested.
                    }

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
                    try scanRepeatedMessageField(field, from: &reader)

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
        // `null` is only allowed as the value of a map entry if the value type is a group or a
        // message.
        if isNull && schema.extensibilityMode == .mapEntry && field.fieldNumber == 2 {
            switch field.rawFieldType {
            case .group, .message:
                break
            default:
                throw JSONDecodingError.illegalNull
            }
        }
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
            // Special case: If the JSON value is negative zero, we need to preserve that. The
            // `updateValue` overload that takes a `FieldSchema` only checks for zero equality, so
            // we need to manually manage the presence here.
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
            // If we're decoding a `NullValue` well-known type, `null` should be
            // stored as the `NULL_VALUE` value, not clear the field.
            if isNull {
                let enumSchema = enumSchema(for: field)
                switch CustomJSONWKTClassification(enumSchema: enumSchema) {
                case .nullValue:
                    updateValue(of: field, to: Int32(0))
                default:
                    clearValue(of: field, type: Int32.self)
                }
                break
            }

            let ignoreUnknown = reader.options.ignoreUnknownFields && schema.extensibilityMode != .mapEntry
            do {
                updateValue(of: field, to: try scanEnumValue(field, from: &reader))
            } catch JSONDecodingError.unrecognizedEnumValue where ignoreUnknown {
                // Ignore unknown enum values if requested, unless this is a map entry.
            }

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
            // Special case: If the JSON value is negative zero, we need to preserve that. The
            // `updateValue` overload that takes a `FieldSchema` only checks for zero equality, so
            // we need to manually manage the presence here.
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
            if !isNull {
                try scanSingularMessageField(field, from: &reader)
                break
            }

            switch CustomJSONWKTClassification(messageSchema: messageSchema(for: field)) {
            case .value:
                // A `null` value for `google.protobuf.Value` decodes to a message whose
                // `nullValue` field is set to `google.protobuf.NullValue.nullValue`.
                let submessageStorage = uniqueMessageStorage(forSingularMessageField: field)
                let nullValueField = KnownField.valueNullValue(in: submessageStorage.schema)
                guard case .oneOfMember(let oneofOffset) = nullValueField.presence else {
                    preconditionFailure("expected nullValue to be a oneof member; this is a generator bug")
                }
                submessageStorage.updateValue(
                    at: nullValueField.offset,
                    to: Int32(0),
                    oneofPresence: (oneofOffset, 1)
                )

            default:
                clearSingularMessageField(field)
            }
 
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
            let submessageStorage = mapEntryWorkingSpace.storage(for: field.submessageIndex)
            let mapEntrySchema = submessageStorage.schema

            // The next character must be double quotes, because map keys must always be
            // quoted strings.
            let c = try reader.scanner.peekOneCharacter()
            guard c == "\"" else {
                throw JSONDecodingError.unquotedMapKey
            }
            try submessageStorage.scanSingularValue(
                of: KnownField.mapEntryKey(in: mapEntrySchema),
                from: &reader,
                requireQuotedBool: true
            )
            try reader.scanner.skipRequiredColon()

            do {
                try submessageStorage.scanSingularValue(of: KnownField.mapEntryValue(in: mapEntrySchema), from: &reader)
                insertMapEntry(in: field, from: submessageStorage)
            } catch JSONDecodingError.unrecognizedEnumValue where reader.options.ignoreUnknownFields {
                // `ignoreUnknownFields` also means to ignore unknown enum values. If we got
                // here, it means that the key was valid but the value was not. We should
                // discard this entry.
            } catch {
                throw error
            }

            if reader.scanner.skipOptionalObjectEnd() {
                hasNextElement = false
            } else {
                try reader.scanner.skipRequiredComma()
            }
        }
    }

    /// Scans the next message from the JSON reader into the storage of the given field.
    ///
    /// - Parameters:
    ///   - field: The ``FieldSchema`` of the field being scanned.
    ///   - reader: The ``JSONReader`` from which to scan the value.
    private func scanSingularMessageField(_ field: FieldSchema, from reader: inout JSONReader) throws {
        let submessageStorage = uniqueMessageStorage(forSingularMessageField: field)
        try reader.withReaderForNextObject(expectedSchema: submessageStorage.schema) { subReader in
            try submessageStorage.merge(byParsingJSONFrom: &subReader)
        }
    }

    /// Scans the next message from the JSON reader and appends it to the repeated message field.
    ///
    /// - Parameters:
    ///   - field: The ``FieldSchema`` of the field being scanned.
    ///   - reader: The ``JSONReader`` from which to scan the value.
    private func scanRepeatedMessageField(_ field: FieldSchema, from reader: inout JSONReader) throws {
        let submessageStorage = messageStorage(forNewlyAppendedElementOfRepeatedMessageField: field)
        try reader.withReaderForNextObject(expectedSchema: submessageStorage.schema) { subReader in
            try submessageStorage.merge(byParsingJSONFrom: &subReader)
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
        from reader: inout JSONReader
    ) throws -> Int32 {
        let enumSchema = enumSchema(for: field)

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

    /// Parses the next object from the input and interprets it as the JSON representation of a
    /// well-known type `Any`.
    ///
    /// - Precondition: The receiver must be the storage for `google.protobuf.Any`.
    private func parseAsAny(from reader: inout JSONReader) throws {
        let typeURLField = KnownField.anyTypeURL(in: schema)
        let valueField = KnownField.anyValue(in: schema)

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

        let messageStorage = MessageStorage(schema: messageSchema)
        func parseJSONBuffer(_ buffer: UnsafeRawBufferPointer) throws {
            var subReader = JSONReader(
                buffer: buffer,
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
        updateValue(of: KnownField.durationSeconds(in: schema), to: seconds)
        updateValue(of: KnownField.durationNanos(in: schema), to: nanos)
    }

    /// Parses the next quoted string from the input and interprets it as the JSON representation
    /// of a well-known type `FieldMask`.
    ///
    /// - Precondition: The receiver must be the storage for `google.protobuf.FieldMask`.
    private func parseAsFieldMask(from reader: inout JSONReader) throws {
        let pathsField = KnownField.fieldMaskPaths(in: schema)
        let fieldMaskString = try reader.scanner.nextQuotedString()
        try parseFieldMask(fieldMaskString) { name in
            appendValue(name, to: pathsField)
        }
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

        let valuesField = KnownField.listValueValues(in: schema)
        while true {
            try scanRepeatedMessageField(valuesField, from: &reader)
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
        let fieldsField = KnownField.structFields(in: schema)
        var hasNextElement = true
        while hasNextElement {
            let submessageStorage = mapEntryWorkingSpace.storage(for: fieldsField.submessageIndex)
            let mapEntrySchema = submessageStorage.schema

            // The next character must be double quotes, because map keys must always be
            // quoted strings.
            let c = try reader.scanner.peekOneCharacter()
            guard c == "\"" else {
                throw JSONDecodingError.unquotedMapKey
            }
            try submessageStorage.scanSingularValue(
                of: KnownField.mapEntryKey(in: mapEntrySchema),
                from: &reader,
                requireQuotedBool: true
            )
            try reader.scanner.skipRequiredColon()

            do {
                try submessageStorage.scanSingularValue(
                    of: KnownField.mapEntryValue(in: mapEntrySchema),
                    from: &reader
                )
                insertMapEntry(in: fieldsField, from: submessageStorage)
            } catch JSONDecodingError.unrecognizedEnumValue where reader.options.ignoreUnknownFields {
                // `ignoreUnknownFields` also means to ignore unknown enum values. If we got
                // here, it means that the key was valid but the value was not. We should
                // discard this entry.
            } catch {
                throw error
            }

            if reader.scanner.skipOptionalObjectEnd() {
                hasNextElement = false
            } else {
                try reader.scanner.skipRequiredComma()
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
        updateValue(of: KnownField.timestampSeconds(in: schema), to: seconds)
        updateValue(of: KnownField.timestampNanos(in: schema), to: nanos)
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
            updateValue(of: KnownField.valueNullValue(in: schema), to: Google_Protobuf_NullValue.nullValue)

        case "[":
            try scanSingularMessageField(KnownField.valueListValue(in: schema), from: &reader)

        case "{":
            try scanSingularMessageField(KnownField.valueStructValue(in: schema), from: &reader)

        case "t", "f":
            updateValue(of: KnownField.valueBoolValue(in: schema), to: try reader.scanner.nextBool())

        case "\"":
            updateValue(of: KnownField.valueStringValue(in: schema), to: try reader.scanner.nextQuotedString())

        default:
            updateValue(of: KnownField.valueNumberValue(in: schema), to: try reader.scanner.nextDouble())
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

private func parseFieldMask(_ names: String, receive: (String) -> Void) throws {
    guard !names.isEmpty else {
        // Empty string is allowed.
        return
    }
    var fieldNameCount = 0
    var fieldName = String()
    for c in names {
        switch c {
        case ",":
            if fieldNameCount == 0 {
                throw JSONEncodingError.fieldMaskConversion
            }
            if let pbName = protoName(forJSONFieldMaskPath: fieldName) {
                receive(pbName)
            } else {
                throw JSONEncodingError.fieldMaskConversion
            }
            fieldName = String()
            fieldNameCount = 0
        default:
            fieldName.append(c)
            fieldNameCount += 1
        }
    }
    if fieldNameCount == 0 {  // Last field name can't be empty
        throw JSONEncodingError.fieldMaskConversion
    }
    if let pbName = protoName(forJSONFieldMaskPath: fieldName) {
        receive(pbName)
    } else {
        throw JSONEncodingError.fieldMaskConversion
    }
}

/// Returns the protobuf form of the field mask path with the given JSON name, or nil if it was not
/// possible to convert it to a protobuf form.
private func protoName(forJSONFieldMaskPath name: String) -> String? {
    guard isPrintableASCII(name) else { return nil }
    var path = String()
    for c in name {
        switch c {
        case "_":
            return nil
        case "A"..."Z":
            path.append(Character("_"))
            path.append(String(c).lowercased())
        case "a"..."z", "0"..."9", ".", "(", ")":
            path.append(c)
        default:
            // TODO: Change to `return nil` once
            // we know everything legal is being
            // handled above
            path.append(c)
        }
    }
    return path
}
