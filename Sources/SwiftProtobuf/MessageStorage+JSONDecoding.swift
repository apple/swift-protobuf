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

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

extension MessageStorage {
    /// Decodes field values from the given JSON reader into this storage class.
    func merge(byParsingJSONFrom reader: inout JSONReader) throws {
        // Helper function that throws an appropriate error if `null` is encountered as the next
        // value. `null` is disallowed at the top-level but allowed as the value of a keyed field
        // (this is handled in `scanSingularValue`).
        func verifyNotNull() throws {
            if try reader.consumeNullIfPresent() {
                throw reader.parsingError(reason: "null is not allowed here")
            }
        }

        // Count every materialized protobuf message (regular objects, `Any`, `Struct`, `Value`,
        // `ListValue`, and scalar-JSON well-known types) toward the recursion budget once at entry
        // so JSON decoding matches binary decoding and JSON encoding.
        try reader.decrementRecursionBudget()
        defer { reader.incrementRecursionBudget() }

        switch CustomJSONWKTClassification(messageSchema: schema) {
        case .any:
            try parseAsAny(from: &reader)

        case .boolValue:
            try verifyNotNull()
            updateValue(of: KnownField.boolValueValue(in: schema), to: try reader.consumeBool())

        case .bytesValue:
            try verifyNotNull()
            updateValue(of: KnownField.bytesValueValue(in: schema), to: try reader.consumeBytes())

        case .doubleValue:
            try verifyNotNull()
            updateValue(of: KnownField.doubleValueValue(in: schema), to: try reader.consumeDouble())

        case .duration:
            try parseAsDuration(from: &reader)

        case .fieldMask:
            try parseAsFieldMask(from: &reader)

        case .floatValue:
            try verifyNotNull()
            updateValue(of: KnownField.floatValueValue(in: schema), to: try reader.consumeFloat())

        case .int32Value:
            try verifyNotNull()
            let n = try reader.consumeSignedInteger(upperBound: Int64(Int32.max))
            updateValue(of: KnownField.int32ValueValue(in: schema), to: Int32(truncatingIfNeeded: n))

        case .int64Value:
            try verifyNotNull()
            updateValue(
                of: KnownField.int64ValueValue(in: schema),
                to: try reader.consumeSignedInteger(upperBound: Int64.max)
            )

        case .listValue:
            try parseAsListValue(from: &reader)

        case .nullValue:
            // `NullValue` is an enum, so we should never see it here.
            preconditionFailure("Unreachable")

        case .stringValue:
            try verifyNotNull()
            updateValue(of: KnownField.stringValueValue(in: schema), to: try reader.consumeString())

        case .struct:
            try parseAsStruct(from: &reader)

        case .timestamp:
            try parseAsTimestamp(from: &reader)

        case .uint32Value:
            try verifyNotNull()
            let n = try reader.consumeUnsignedInteger(upperBound: UInt64(UInt32.max))
            updateValue(of: KnownField.uint32ValueValue(in: schema), to: UInt32(truncatingIfNeeded: n))

        case .uint64Value:
            try verifyNotNull()
            let n = try reader.consumeUnsignedInteger(upperBound: UInt64.max)
            updateValue(of: KnownField.uint64ValueValue(in: schema), to: n)

        case .value:
            try parseAsValue(from: &reader)

        case .notWellKnown:
            // This is the common case.
            var mapEntryWorkingSpace = MapEntryWorkingSpace(ownerSchema: schema)
            var seenFields = FieldBitSet()

            try reader.consumeObject(impactsRecursionDepth: false) { reader in
                try decodeKeyValuePair(
                    from: &reader,
                    seenFields: &seenFields,
                    mapEntryWorkingSpace: &mapEntryWorkingSpace
                )
            }
        }
    }

    /// Decodes the next key-value pair from a regular JSON object in the reader.
    private func decodeKeyValuePair(
        from reader: inout JSONReader,
        seenFields: inout FieldBitSet,
        mapEntryWorkingSpace: inout MapEntryWorkingSpace
    ) throws {
        let fieldOrExtension = try reader.consumeFieldOrExtension()
        try reader.consume(.colon)
        try decodeFieldOrExtensionValue(
            fieldOrExtension,
            from: &reader,
            seenFields: &seenFields,
            mapEntryWorkingSpace: &mapEntryWorkingSpace
        )
    }

    /// Decodes the value for an already-resolved field or extension after its name and colon have been consumed.
    private func decodeFieldOrExtensionValue(
        _ fieldOrExtension: FieldOrExtensionSchema,
        from reader: inout JSONReader,
        seenFields: inout FieldBitSet,
        mapEntryWorkingSpace: inout MapEntryWorkingSpace
    ) throws {
        switch fieldOrExtension {
        case .field(let field):
            guard seenFields.insert(fieldIndex: schema.fieldIndex(of: field)) else {
                let jsonName = schema.jsonName(forFieldNumber: field.fieldNumber)!
                throw reader.parsingError(reason: "Field '\(jsonName)' specified more than once")
            }

            // It is an error in JSON if we encounter values for more than one member of the same
            // `oneof`.
            if case .oneOfMember(let oneOfOffset) = field.presence {
                if populatedOneofMember(at: oneOfOffset) != 0 {
                    // JSON only allows multiple keys from a `oneof` to be set if at most one is
                    // not `null`.
                    if try reader.consumeNullIfPresent() {
                        break
                    }
                    throw reader.parsingError(reason: "Conflicting oneof values")
                }
            }
            try decodeNextFieldValue(from: &reader, field: field, mapEntryWorkingSpace: &mapEntryWorkingSpace)
        case .extension(let ext):
            guard seenFields.insert(extensionFieldNumber: ext.field.fieldNumber) else {
                throw reader.parsingError(reason: "Field '\(ext.fieldName)' specified more than once")
            }
            try extensionStorage.decodeNextExtension(ext, from: &reader)
        case .unknown:
            try reader.skipField(wereNameAndColonAlreadyConsumed: true)
        }
    }

    /// Decodes the value of the next regular (non-extension) field from the JSON reader.
    private func decodeNextFieldValue(
        from reader: inout JSONReader,
        field: MessageSchema.Field,
        mapEntryWorkingSpace: inout MapEntryWorkingSpace
    ) throws {
        let fieldType = field.rawFieldType

        switch field.fieldMode.cardinality {
        case .map:
            if try reader.consumeNullIfPresent() {
                // TODO: Figure out if we should clear the field. The old JSONDecoder implementation
                // just returns, but that might be because we don't have a distinction between
                // merge and init for JSON.
                return
            }
            try scanMapField(field, from: &reader, mapEntryWorkingSpace: &mapEntryWorkingSpace)

        case .array:
            try reader.consumeArray { reader in
                switch fieldType {
                case .bool:
                    appendValue(try reader.consumeBool(), to: field)

                case .bytes:
                    appendValue(try reader.consumeBytes(), to: field)

                case .double:
                    appendValue(try reader.consumeDouble(), to: field)

                case .enum:
                    let resolvedEnumSchema = enumSchema(for: field)
                    guard let value = try reader.consumeEnumValue(schema: resolvedEnumSchema) else {
                        break
                    }
                    appendEnumValue(withRawValue: value, toRepeatedEnumField: field)

                case .fixed32, .uint32:
                    let n = try reader.consumeUnsignedInteger(upperBound: UInt64(UInt32.max))
                    appendValue(UInt32(truncatingIfNeeded: n), to: field)

                case .fixed64, .uint64:
                    appendValue(try reader.consumeUnsignedInteger(upperBound: UInt64.max), to: field)

                case .float:
                    appendValue(try reader.consumeFloat(), to: field)

                case .group, .message:
                    try scanRepeatedMessageField(field, from: &reader)

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
    ///   - field: The ``MessageSchema.Field`` of the field being scanned.
    ///   - reader: The ``JSONReader`` from which to scan the value.
    ///   - requireQuotedBool: If true and the field's type is `bool`, the value is expected to be
    ///     quoted. This is used when scanning map keys.
    /// - Returns: True if the value was processed, otherwise false. The latter only happens when
    ///   scanning an unknown enum case value, which should be silently ignored in map values
    ///   instead of throwing an error.
    @discardableResult
    private func scanSingularValue(
        of field: MessageSchema.Field,
        from reader: inout JSONReader,
        requireQuotedBool: Bool = false
    ) throws -> Bool {
        let isNull = try reader.consumeNullIfPresent()
        // `null` is only allowed as the value of a map entry if the value type is a group or a
        // message.
        if isNull && schema.extensibilityMode == .mapEntry && field.fieldNumber == 2 {
            switch field.rawFieldType {
            case .group, .message:
                break
            default:
                throw reader.parsingError(reason: "null is only allowed in maps when the value is a message or group")
            }
        }
        switch field.rawFieldType {
        case .bool:
            if isNull {
                clearValue(of: field, type: Bool.self)
                break
            }
            updateValue(of: field, to: try reader.consumeBool(asQuotedString: requireQuotedBool))

        case .bytes:
            if isNull {
                clearValue(of: field, type: Data.self)
                break
            }
            updateValue(of: field, to: try reader.consumeBytes())

        case .double:
            if isNull {
                clearValue(of: field, type: Double.self)
                break
            }
            // Special case: If the JSON value is negative zero, we need to preserve that. The
            // `updateValue` overload that takes a `MessageSchema.Field` only checks for zero
            // equality, so we need to manually manage the presence here.
            let d = try reader.consumeDouble()
            let offset = schema.byteOffset(of: field)
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
            let resolvedEnumSchema = enumSchema(for: field)

            // If we're decoding a `NullValue` well-known type, `null` should be
            // stored as the `NULL_VALUE` value, not clear the field.
            if isNull {
                switch CustomJSONWKTClassification(enumSchema: resolvedEnumSchema) {
                case .nullValue:
                    updateValue(of: field, to: Int32(0))
                default:
                    clearValue(of: field, type: Int32.self)
                }
                break
            }

            // This returns nil if the value was unknown and we're ignoring unknowns.
            guard let value = try reader.consumeEnumValue(schema: resolvedEnumSchema) else {
                return false
            }
            updateValue(of: field, to: value)

        case .fixed32, .uint32:
            if isNull {
                clearValue(of: field, type: UInt32.self)
                break
            }
            let n = try reader.consumeUnsignedInteger(upperBound: UInt64(UInt32.max))
            updateValue(of: field, to: UInt32(truncatingIfNeeded: n))

        case .fixed64, .uint64:
            if isNull {
                clearValue(of: field, type: UInt64.self)
                break
            }
            updateValue(of: field, to: try reader.consumeUnsignedInteger(upperBound: UInt64.max))

        case .float:
            if isNull {
                clearValue(of: field, type: Float.self)
                break
            }
            // Special case: If the JSON value is negative zero, we need to preserve that. The
            // `updateValue` overload that takes a `MessageSchema.Field` only checks for zero
            // equality, so we need to manually manage the presence here.
            let f = try reader.consumeFloat()
            let offset = schema.byteOffset(of: field)
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

            let submessageSchema = messageSchema(for: field)
            switch CustomJSONWKTClassification(messageSchema: submessageSchema) {
            case .value:
                // Even for JSON `null`, a `google.protobuf.Value` field materializes a submessage
                // with `nullValue` set, so count it toward the recursion budget just like
                // `parseAsValue(from:)`.
                try reader.decrementRecursionBudget()
                defer { reader.incrementRecursionBudget() }

                // A `null` value for `google.protobuf.Value` decodes to a message whose
                // `nullValue` field is set to `google.protobuf.NullValue.nullValue`.
                //
                // This is safe to force-unwrap because it would only return nil if the schema
                // wasn't found, which is checked above.
                let submessageStorage = uniqueMessageStorage(forSingularMessageField: field)
                let nullValueField = KnownField.valueNullValue(in: submessageStorage.schema)
                guard case .oneOfMember(let oneofOffset) = nullValueField.presence else {
                    preconditionFailure("expected nullValue to be a oneof member; this is a generator bug")
                }
                submessageStorage.updateValue(
                    at: submessageStorage.schema.byteOffset(of: nullValueField),
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
            let n = try reader.consumeSignedInteger(upperBound: Int64(Int32.max))
            updateValue(of: field, to: Int32(truncatingIfNeeded: n))

        case .int64, .sfixed64, .sint64:
            if isNull {
                clearValue(of: field, type: Int64.self)
                break
            }
            updateValue(of: field, to: try reader.consumeSignedInteger(upperBound: Int64.max))

        case .string:
            if isNull {
                clearValue(of: field, type: String.self)
                break
            }
            updateValue(of: field, to: try reader.consumeString())

        default:
            preconditionFailure("Unreachable")
        }
        return true
    }

    /// Scans a map represented as a JSON object from the reader.
    ///
    /// - Parameters:
    ///   - field: The ``MessageSchema.Field`` of the field being scanned.
    ///   - reader: The ``JSONReader`` from which to scan the value.
    ///   - mapEntryWorkingSpace: The working space that manages reusable map storage objects during
    ///     decoding.
    private func scanMapField(
        _ field: MessageSchema.Field,
        from reader: inout JSONReader,
        mapEntryWorkingSpace: inout MapEntryWorkingSpace
    ) throws {
        // Lazily allocated only if an unknown enum value is ignored under `ignoreUnknownFields`,
        // where the entry is not inserted into the underlying `Dictionary` so duplicate keys
        // involving ignored entries cannot be detected from `Dictionary.updateValue` alone.
        var ignoredEnumKeys: Set<AnyHashable>? = nil

        try reader.consumeObject { reader in
            guard let submessageStorage = mapEntryWorkingSpace.storage(for: field.submessageIndex) else {
                throw reader.parsingError(reason: "Could not resolve schema for map entry field \(field.fieldNumber)")
            }
            let mapEntrySchema = submessageStorage.schema
            let keyField = KnownField.mapEntryKey(in: mapEntrySchema)

            // The next value must be a double-quoted string, because map keys must always be
            // strings.
            guard reader.at(.string, .stringWithEscapes) else {
                throw reader.parsingError(expected: "a string map key")
            }
            let keyToken = reader.tokenizer.current
            try submessageStorage.scanSingularValue(
                of: keyField,
                from: &reader,
                requireQuotedBool: true
            )
            try reader.consume(.colon)

            let success = try submessageStorage.scanSingularValue(
                of: KnownField.mapEntryValue(in: mapEntrySchema),
                from: &reader
            )
            if success {
                if let ignoredEnumKeys,
                    ignoredEnumKeys.contains(submessageStorage.mapKeyAnyHashable(of: keyField))
                {
                    throw reader.parsingError(reason: "Duplicate key in map", at: keyToken)
                }
                if !insertUniqueMapEntry(in: field, from: submessageStorage) {
                    throw reader.parsingError(reason: "Duplicate key in map", at: keyToken)
                }
            } else {
                if containsMapKey(in: field, from: submessageStorage) {
                    throw reader.parsingError(reason: "Duplicate key in map", at: keyToken)
                }
                let key = submessageStorage.mapKeyAnyHashable(of: keyField)
                if ignoredEnumKeys == nil {
                    ignoredEnumKeys = [key]
                } else if !ignoredEnumKeys!.insert(key).inserted {
                    throw reader.parsingError(reason: "Duplicate key in map", at: keyToken)
                }
            }
        }
    }

    /// Returns the parsed map entry key stored in `keyField` wrapped in `AnyHashable`.
    ///
    /// - Precondition: `self` must be a map-entry `MessageStorage` and `keyField` must be its key
    ///   field.
    private func mapKeyAnyHashable(of keyField: MessageSchema.Field) -> AnyHashable {
        switch keyField.rawFieldType {
        case .bool:
            return AnyHashable(value(of: keyField) as Bool)
        case .int32, .sfixed32, .sint32:
            return AnyHashable(value(of: keyField) as Int32)
        case .fixed32, .uint32:
            return AnyHashable(value(of: keyField) as UInt32)
        case .int64, .sfixed64, .sint64:
            return AnyHashable(value(of: keyField) as Int64)
        case .fixed64, .uint64:
            return AnyHashable(value(of: keyField) as UInt64)
        case .string:
            return AnyHashable(value(of: keyField) as String)
        default:
            preconditionFailure("Unreachable")
        }
    }

    /// Scans the next message from the JSON reader into the storage of the given field.
    ///
    /// - Parameters:
    ///   - field: The ``MessageSchema.Field`` of the field being scanned.
    ///   - reader: The ``JSONReader`` from which to scan the value.
    private func scanSingularMessageField(_ field: MessageSchema.Field, from reader: inout JSONReader) throws {
        let submessageStorage = uniqueMessageStorage(forSingularMessageField: field)
        try reader.withReaderForNextObject(expectedSchema: submessageStorage.schema) { subReader in
            try submessageStorage.merge(byParsingJSONFrom: &subReader)
        }
    }

    /// Scans the next message from the JSON reader and appends it to the repeated message field.
    ///
    /// - Parameters:
    ///   - field: The ``MessageSchema.Field`` of the field being scanned.
    ///   - reader: The ``JSONReader`` from which to scan the value.
    private func scanRepeatedMessageField(_ field: MessageSchema.Field, from reader: inout JSONReader) throws {
        let submessageStorage = messageStorage(forNewlyAppendedElementOfRepeatedMessageField: field)
        try reader.withReaderForNextObject(expectedSchema: submessageStorage.schema) { subReader in
            try submessageStorage.merge(byParsingJSONFrom: &subReader)
        }
    }

    /// Consumes a string key and following colon from a `google.protobuf.Any` JSON object.
    private func consumeAnyKeyAndColon(from reader: inout JSONReader) throws -> String {
        guard reader.at(.string, .stringWithEscapes) else {
            throw reader.parsingError(expected: "a field or extension name")
        }
        let key = try reader.consumeString()
        try reader.consume(.colon)
        return key
    }

    /// Replays any fields that appeared before `@type` in a `google.protobuf.Any` JSON object and then streams all
    /// remaining keys after `@type` through `consumeField`.
    private func replayAndStreamAnyFields(
        from subReader: inout JSONReader,
        typeURL: String,
        preTypeStartTokenizer: Tokenizer?,
        preTypeEndOffset: Int,
        consumeField: (_ key: String, _ reader: inout JSONReader) throws -> Void
    ) throws {
        if let preTypeStartTokenizer {
            let postTypeTokenizer = subReader.tokenizer
            subReader.tokenizer = preTypeStartTokenizer
            defer { subReader.tokenizer = postTypeTokenizer }
            while true {
                let key = try consumeAnyKeyAndColon(from: &subReader)
                try consumeField(key, &subReader)
                if subReader.tokenizer.currentOffset >= preTypeEndOffset {
                    guard subReader.tokenizer.currentOffset == preTypeEndOffset else {
                        throw subReader.parsingError(reason: "Malformed JSON")
                    }
                    break
                }
                try subReader.consume(.comma)
            }
        }

        while try !subReader.consumeIfPresent(.rightBrace) {
            try subReader.consume(.comma)
            let key = try consumeAnyKeyAndColon(from: &subReader)
            if key == "@type" {
                let duplicateURL = try subReader.consumeString()
                throw SwiftProtobufError.JSONDecoding.duplicateAnyTypeURL(
                    type_url: typeURL,
                    duplicate_type_url: duplicateURL
                )
            }
            try consumeField(key, &subReader)
        }
    }

    /// Parses the next object from the input and interprets it as the JSON representation of a well-known type `Any`.
    ///
    /// - Precondition: The receiver must be the storage for `google.protobuf.Any`.
    private func parseAsAny(from reader: inout JSONReader) throws {
        let typeURLField = KnownField.anyTypeURL(in: schema)
        let valueField = KnownField.anyValue(in: schema)

        try reader.consume(.leftBrace)

        if try reader.consumeIfPresent(.rightBrace) {
            clearValue(of: typeURLField, type: String.self)
            clearValue(of: valueField, type: Data.self)
            return
        }

        // Phase 1: Scan forward until `@type` is found. In the common case where `@type` is first,
        // `preTypeStartTokenizer` remains `nil` and all remaining fields stream directly in a
        // single pass. If fields appear before `@type`, save a value copy of `reader.tokenizer` at
        // the first pre-`@type` key token (zero heap copy, preserving original line/column) and
        // record the offset immediately after the last skipped pre-`@type` value so we can replay
        // only the pre-`@type` slice once the target schema is known.
        var typeURL: String? = nil
        var preTypeStartTokenizer: Tokenizer? = nil
        var preTypeEndOffset = 0

        while true {
            let keyTokenizer = reader.tokenizer
            let key = try consumeAnyKeyAndColon(from: &reader)
            if key == "@type" {
                let scannedURL = try reader.consumeString()
                guard isTypeURLValid(scannedURL) else {
                    throw SwiftProtobufError.JSONDecoding.invalidAnyTypeURL(type_url: scannedURL)
                }
                typeURL = scannedURL
                break
            }

            if preTypeStartTokenizer == nil {
                preTypeStartTokenizer = keyTokenizer
            }
            try reader.skipField(wereNameAndColonAlreadyConsumed: true)
            preTypeEndOffset = reader.tokenizer.currentOffset

            if try reader.consumeIfPresent(.rightBrace) {
                break
            }
            try reader.consume(.comma)
        }

        guard let typeURL else {
            throw SwiftProtobufError.JSONDecoding.emptyAnyTypeURL()
        }

        guard let messageSchema = Google_Protobuf_Any.messageSchema(forTypeURL: typeURL) else {
            // Finish scanning remaining keys before reporting the unregistered type URL so
            // duplicate `@type` keys and trailing JSON syntax errors are still caught.
            while try !reader.consumeIfPresent(.rightBrace) {
                try reader.consume(.comma)
                let key = try consumeAnyKeyAndColon(from: &reader)
                if key == "@type" {
                    let duplicateURL = try reader.consumeString()
                    throw SwiftProtobufError.JSONDecoding.duplicateAnyTypeURL(
                        type_url: typeURL,
                        duplicate_type_url: duplicateURL
                    )
                }
                try reader.skipField(wereNameAndColonAlreadyConsumed: true)
            }
            throw SwiftProtobufError.JSONDecoding.unknownAnyTypeURL(type_url: typeURL)
        }

        let messageStorage = MessageStorage(schema: messageSchema)
        try reader.withReaderForNextObject(expectedSchema: messageSchema) { subReader in
            switch CustomJSONWKTClassification(messageSchema: messageSchema) {
            case .notWellKnown:
                // Account for the packed message itself in addition to the enclosing `Any`
                // object so JSON decoding matches the Protobuf-message depth model used by
                // binary decoding, TextFormat encoding, and JSON encoding.
                try subReader.decrementRecursionBudget()
                defer { subReader.incrementRecursionBudget() }

                var mapEntryWorkingSpace = MapEntryWorkingSpace(ownerSchema: messageSchema)
                var seenFields = FieldBitSet()
                try replayAndStreamAnyFields(
                    from: &subReader,
                    typeURL: typeURL,
                    preTypeStartTokenizer: preTypeStartTokenizer,
                    preTypeEndOffset: preTypeEndOffset
                ) { key, subReader in
                    let fieldOrExtension = try subReader.resolveFieldOrExtension(named: key)
                    try messageStorage.decodeFieldOrExtensionValue(
                        fieldOrExtension,
                        from: &subReader,
                        seenFields: &seenFields,
                        mapEntryWorkingSpace: &mapEntryWorkingSpace
                    )
                }

            default:
                var sawValueKey = false
                try replayAndStreamAnyFields(
                    from: &subReader,
                    typeURL: typeURL,
                    preTypeStartTokenizer: preTypeStartTokenizer,
                    preTypeEndOffset: preTypeEndOffset
                ) { key, subReader in
                    if key == "value" {
                        guard !sawValueKey else {
                            throw subReader.parsingError(reason: "Field 'value' specified more than once")
                        }
                        sawValueKey = true
                        try messageStorage.merge(byParsingJSONFrom: &subReader)
                    } else if subReader.options.ignoreUnknownFields {
                        try subReader.skipField(wereNameAndColonAlreadyConsumed: true)
                    } else {
                        throw AnyUnpackError.malformedWellKnownTypeJSON
                    }
                }
                if !sawValueKey {
                    // Omitting `"value"` still materializes a default-initialized packed WKT
                    // message inside the `Any`.
                    try subReader.decrementRecursionBudget()
                    subReader.incrementRecursionBudget()
                }
            }
        }

        updateValue(of: typeURLField, to: typeURL)
        var options = BinaryEncodingOptions()
        options.allowPartial = true
        updateValue(of: valueField, to: try messageStorage.serializedBytes(options: options))
    }

    /// Parses the next quoted string from the input and interprets it as the JSON representation
    /// of a well-known type `Duration`.
    ///
    /// - Precondition: The receiver must be the storage for `google.protobuf.Duration`.
    private func parseAsDuration(from reader: inout JSONReader) throws {
        let durationString = try reader.consumeString()
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
        let fieldMaskString = try reader.consumeString()
        try parseFieldMask(fieldMaskString) { name in
            appendValue(name, to: pathsField)
        }
    }

    /// Parses the next value from the input and interprets it as the JSON representation of a
    /// well-known type `ListValue`.
    ///
    /// - Precondition: The receiver must be the storage for `google.protobuf.ListValue`.
    private func parseAsListValue(from reader: inout JSONReader) throws {
        let valuesField = KnownField.listValueValues(in: schema)
        try reader.consumeArray { reader in
            try scanRepeatedMessageField(valuesField, from: &reader)
        }
    }

    /// Parses the next value from the input and interprets it as the JSON representation of a
    /// well-known type `Struct`.
    ///
    /// - Precondition: The receiver must be the storage for `google.protobuf.Value`.
    private func parseAsStruct(from reader: inout JSONReader) throws {
        var mapEntryWorkingSpace = MapEntryWorkingSpace(ownerSchema: schema)
        let fieldsField = KnownField.structFields(in: schema)

        try reader.consumeObject(impactsRecursionDepth: false) { reader in
            guard reader.at(.string, .stringWithEscapes) else {
                throw reader.parsingError(expected: "a string key")
            }

            guard let submessageStorage = mapEntryWorkingSpace.storage(for: fieldsField.submessageIndex) else {
                throw reader.parsingError(reason: "Could not resolve schema for struct fields")
            }
            let mapEntrySchema = submessageStorage.schema

            let keyToken = reader.tokenizer.current
            try submessageStorage.scanSingularValue(
                of: KnownField.mapEntryKey(in: mapEntrySchema),
                from: &reader,
                requireQuotedBool: true
            )
            try reader.consume(.colon)

            let success = try submessageStorage.scanSingularValue(
                of: KnownField.mapEntryValue(in: mapEntrySchema),
                from: &reader
            )
            if success {
                if !insertUniqueMapEntry(in: fieldsField, from: submessageStorage) {
                    throw reader.parsingError(reason: "Duplicate key in Struct", at: keyToken)
                }
            }
        }
    }

    /// Parses the next quoted string from the input and interprets it as the JSON representation
    /// of a well-known type `Timestamp`.
    ///
    /// - Precondition: The receiver must be the storage for `google.protobuf.Timestamp`.
    private func parseAsTimestamp(from reader: inout JSONReader) throws {
        let timestampString = try reader.consumeString()
        let (seconds, nanos) = try parseTimestamp(s: timestampString)
        updateValue(of: KnownField.timestampSeconds(in: schema), to: seconds)
        updateValue(of: KnownField.timestampNanos(in: schema), to: nanos)
    }

    /// Parses the next value from the input and interprets it as the JSON representation of a
    /// well-known type `Value`.
    ///
    /// - Precondition: The receiver must be the storage for `google.protobuf.Value`.
    private func parseAsValue(from reader: inout JSONReader) throws {
        if reader.at(.identifier) {
            if try reader.consumeNullIfPresent() {
                updateValue(of: KnownField.valueNullValue(in: schema), to: Google_Protobuf_NullValue.nullValue)
            } else {
                updateValue(of: KnownField.valueBoolValue(in: schema), to: try reader.consumeBool())
            }
            return
        }
        if reader.at(.leftBracket) {
            try scanSingularMessageField(KnownField.valueListValue(in: schema), from: &reader)
            return
        }
        if reader.at(.leftBrace) {
            try scanSingularMessageField(KnownField.valueStructValue(in: schema), from: &reader)
            return
        }
        if reader.at(.string, .stringWithEscapes) {
            updateValue(of: KnownField.valueStringValue(in: schema), to: try reader.consumeString())
            return
        }
        updateValue(of: KnownField.valueNumberValue(in: schema), to: try reader.consumeDouble())
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
                throw JSONDecodingError.malformedFieldMask
            }
            if let pbName = protoName(forJSONFieldMaskPath: fieldName) {
                receive(pbName)
            } else {
                throw JSONDecodingError.malformedFieldMask
            }
            fieldName = String()
            fieldNameCount = 0
        default:
            fieldName.append(c)
            fieldNameCount += 1
        }
    }
    if fieldNameCount == 0 {  // Last field name can't be empty
        throw JSONDecodingError.malformedFieldMask
    }
    if let pbName = protoName(forJSONFieldMaskPath: fieldName) {
        receive(pbName)
    } else {
        throw JSONDecodingError.malformedFieldMask
    }
}

/// Returns the protobuf form of the field mask path with the given JSON name, or nil if it was not
/// possible to convert it to a protobuf form.
internal func protoName(forJSONFieldMaskPath name: String) -> String? {
    guard !name.isEmpty, isPrintableASCII(name) else { return nil }
    var path = String()
    for c in name {
        switch c {
        case "_":
            return nil
        case "A"..."Z":
            path.append(Character("_"))
            path.append(String(c).lowercased())
        case "a"..."z", "0"..."9", ".":
            path.append(c)
        default:
            return nil
        }
    }
    return path
}
