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
            var seenFields = Set<UInt32>()

            try reader.consumeObject { reader in
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
        seenFields: inout Set<UInt32>,
        mapEntryWorkingSpace: inout MapEntryWorkingSpace
    ) throws {
        let fieldOrExtension = try reader.consumeFieldOrExtension()
        try reader.consume(.colon)

        switch fieldOrExtension {
        case .field(let field):
            guard seenFields.insert(field.fieldNumber).inserted else {
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
            guard seenFields.insert(ext.field.fieldNumber).inserted else {
                throw reader.parsingError(reason: "Field '\(ext.fieldName)' specified more than once")
            }
            try extensionStorage.decodeNextExtension(ext, from: &reader)
        case .unknown:
            _ = try reader.skipField(wereNameAndColonAlreadyConsumed: true)
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
                    // This returns nil if the value was unknown and we're ignoring unknowns.
                    guard let value = try reader.consumeEnumValue(schema: enumSchema(for: field)) else {
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

            // This returns nil if the value was unknown and we're ignoring unknowns.
            guard let value = try reader.consumeEnumValue(schema: enumSchema(for: field)) else {
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
        try reader.consumeObject { reader in
            let submessageStorage = mapEntryWorkingSpace.storage(for: field.submessageIndex)
            let mapEntrySchema = submessageStorage.schema

            // The next value must be a double-quoted string, because map keys must always be
            // strings.
            guard reader.at(.string, .stringWithEscapes) else {
                throw reader.parsingError(expected: "a string map key")
            }
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
                insertMapEntry(in: field, from: submessageStorage)
            }
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

    /// Parses the next object from the input and interprets it as the JSON representation of a
    /// well-known type `Any`.
    ///
    /// - Precondition: The receiver must be the storage for `google.protobuf.Any`.
    private func parseAsAny(from reader: inout JSONReader) throws {
        let typeURLField = KnownField.anyTypeURL(in: schema)
        let valueField = KnownField.anyValue(in: schema)

        var wasEmpty = false
        var typeURL: String? = nil
        var possibleWKTValueJSON = ""
        var hadFieldsOtherThanValue = false

        var jsonEncoder = JSONEncoder()
        jsonEncoder.startObject()

        try reader.consumeObject { reader in
            guard reader.at(.string, .stringWithEscapes) else {
                throw reader.parsingError(expected: "a field or extension name")
            }

            let key = try reader.consumeString()
            try reader.consume(.colon)
            if key == "@type" {
                let scannedURL = try reader.consumeString()
                guard isTypeURLValid(scannedURL) else {
                    throw SwiftProtobufError.JSONDecoding.invalidAnyTypeURL(type_url: scannedURL)
                }
                typeURL = scannedURL
            } else {
                jsonEncoder.startField(name: key)
                let keyValueJSON = try reader.skipField(wereNameAndColonAlreadyConsumed: true)
                if key == "value" {
                    // When we encounter the key `value`, we may need to parse this as a well-known
                    // type with a special representation, so keep track of it.
                    possibleWKTValueJSON = String(data: Data(keyValueJSON), encoding: .utf8) ?? ""
                } else {
                    // Keep track of this because if it's a well-known type, we need to fail later
                    // if we're not ignoring unknown fields.
                    hadFieldsOtherThanValue = true
                }
                jsonEncoder.append(utf8Bytes: Array(keyValueJSON))
            }
        } ifEmpty: {
            clearValue(of: typeURLField, type: String.self)
            clearValue(of: valueField, type: Data.self)
            wasEmpty = true
        }

        jsonEncoder.endObject()

        if wasEmpty {
            return
        }
        guard let typeURL else {
            throw SwiftProtobufError.JSONDecoding.invalidAnyTypeURL(type_url: "")
        }
        guard let messageSchema = Google_Protobuf_Any.messageSchema(forTypeURL: typeURL) else {
            throw SwiftProtobufError.JSONDecoding.unknownAnyTypeURL(type_url: typeURL)
        }

        let messageStorage = MessageStorage(schema: messageSchema)
        func parseJSONBuffer(_ buffer: UnsafeBufferPointer<UInt8>) throws {
            var subReader = try JSONReader(
                buffer: buffer,
                messageSchema: messageSchema,
                options: reader.options,
                extensions: reader.extensions
            )
            try messageStorage.merge(byParsingJSONFrom: &subReader)
        }

        switch CustomJSONWKTClassification(messageSchema: messageSchema) {
        case .notWellKnown:
            try jsonEncoder.bytesResult.withUnsafeBufferPointer { buffer in
                try parseJSONBuffer(buffer)
            }

        default:
            // Well-known types in `Any` must *only* have a `value` field, unless we're ignoring
            // unknown fields.
            if hadFieldsOtherThanValue && !reader.options.ignoreUnknownFields {
                throw AnyUnpackError.malformedWellKnownTypeJSON
            }
            try possibleWKTValueJSON.withUTF8 { buffer in
                try parseJSONBuffer(buffer)
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
        try reader.consumeArray(impactsRecursionDepth: true) { reader in
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

        try reader.consumeObject { reader in
            guard reader.at(.string, .stringWithEscapes) else {
                throw reader.parsingError(expected: "a string key")
            }

            let submessageStorage = mapEntryWorkingSpace.storage(for: fieldsField.submessageIndex)
            let mapEntrySchema = submessageStorage.schema

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
                insertMapEntry(in: fieldsField, from: submessageStorage)
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
