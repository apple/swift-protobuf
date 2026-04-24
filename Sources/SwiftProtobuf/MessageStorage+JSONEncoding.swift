// Sources/SwiftProtobuf/MessageStorage+JSONEncoding.swift - JSON format encoding for messages
//
// Copyright (c) 2014 - 2026 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// JSON format encoding support for `MessageStorage.`
///
// -----------------------------------------------------------------------------

import Foundation

extension MessageStorage {
    /// A recursion helper that serializes the fields in the storage into the given JSON encoder.
    ///
    /// - Parameters:
    ///   - encoder: The JSON encoder into which the message should be serialized.
    ///   - options: The options to use when encoding the message.
    ///   - shouldInlineFields: If true, the fields of the receiver will be inlined into an already
    ///     existing JSON object instead of starting a new object. This is used when serializing
    ///     messaged tested inside a `google.protobuf.Any`.
    func serializeJSON(
        into encoder: inout JSONEncoder,
        options: JSONEncodingOptions,
        shouldInlineFields: Bool = false
    ) throws {
        switch CustomJSONWKTClassification(messageSchema: schema) {
        case .any:
            try emitAsAny(into: &encoder, options: options)

        case .boolValue:
            encoder.putNonQuotedBoolValue(value: value(of: schema[fieldNumber: 1]!))

        case .bytesValue:
            encoder.putBytesValue(value: value(of: schema[fieldNumber: 1]!))

        case .doubleValue:
            encoder.putDoubleValue(value: value(of: schema[fieldNumber: 1]!))

        case .duration:
            try emitAsDuration(into: &encoder)

        case .fieldMask:
            try emitAsFieldMask(into: &encoder)

        case .floatValue:
            encoder.putFloatValue(value: value(of: schema[fieldNumber: 1]!))

        case .int32Value:
            encoder.putNonQuotedInt32(value: value(of: schema[fieldNumber: 1]!))

        case .int64Value:
            if options.alwaysPrintInt64sAsNumbers {
                encoder.putNonQuotedInt64(value: value(of: schema[fieldNumber: 1]!))
            } else {
                encoder.putQuotedInt64(value: value(of: schema[fieldNumber: 1]!))
            }

        case .listValue:
            try emitAsListValue(into: &encoder, options: options)

        case .nullValue:
            // `NullValue` is an enum, so we should never see it here.
            preconditionFailure("Unreachable")

        case .stringValue:
            encoder.putStringValue(value: value(of: schema[fieldNumber: 1]!))

        case .struct:
            try emitAsStruct(into: &encoder, options: options)

        case .timestamp:
            try emitAsTimestamp(into: &encoder)

        case .uint32Value:
            encoder.putNonQuotedUInt32(value: value(of: schema[fieldNumber: 1]!))

        case .uint64Value:
            if options.alwaysPrintInt64sAsNumbers {
                encoder.putNonQuotedUInt64(value: value(of: schema[fieldNumber: 1]!))
            } else {
                encoder.putQuotedUInt64(value: value(of: schema[fieldNumber: 1]!))
            }

        case .value:
            try emitAsValue(into: &encoder, options: options)

        case .notWellKnown:
            // This is the common case.
            if !shouldInlineFields {
                encoder.startObject()
            }
            var mapEntryWorkingSpace = MapEntryWorkingSpace(ownerSchema: schema)
            for field in schema.fields {
                guard isPresent(field) else { continue }
                try serializeField(field, into: &encoder, mapEntryWorkingSpace: &mapEntryWorkingSpace, options: options)
            }
            try extensionStorage.serializeJSON(into: &encoder, options: options)
            if !shouldInlineFields {
                encoder.endObject()
            }
        }
    }

    /// Serializes a single field in the storage into the given JSON  encoder.
    private func serializeField(
        _ field: FieldSchema,
        into encoder: inout JSONEncoder,
        mapEntryWorkingSpace: inout MapEntryWorkingSpace,
        options: JSONEncodingOptions
    ) throws {
        let fieldNumber = field.fieldNumber
        let fieldType = field.rawFieldType
        let offset = field.offset

        try emitKey(forFieldNumber: fieldNumber, into: &encoder, options: options)

        switch field.fieldMode.cardinality {
        case .map:
            encoder.startObject()

            var firstItem = true
            _ = try schema.performOnMapEntry(
                MessageSchema.TrampolineToken(index: field.submessageIndex),
                field,
                self,
                mapEntryWorkingSpace.storage(for: field.submessageIndex),
                .read,
                options.useDeterministicOrdering
            ) { mapEntryStorage in
                if !firstItem {
                    encoder.comma()
                }
                let mapEntrySchema = mapEntryStorage.schema
                try mapEntryStorage.emitAsMapKey(mapEntrySchema[fieldNumber: 1]!, to: &encoder)
                encoder.append(text: ":")
                try mapEntryStorage.emitSingularValue(
                    of: mapEntrySchema[fieldNumber: 2]!,
                    to: &encoder,
                    options: options
                )
                firstItem = false
                return true
            }

            encoder.endObject()

        case .array:
            encoder.startArray()

            func emitRepeatedField<Value>(_ emitValue: (Value) -> Void) {
                let values = assumedPresentValue(at: offset, as: [Value].self)
                var firstItem = true
                for value in values {
                    if !firstItem {
                        encoder.comma()
                    }
                    emitValue(value)
                    firstItem = false
                }
            }

            switch fieldType {
            case .bool:
                emitRepeatedField { encoder.putNonQuotedBoolValue(value: $0) }

            case .bytes:
                emitRepeatedField { (value: Data) in encoder.putBytesValue(value: value) }

            case .double:
                emitRepeatedField { encoder.putDoubleValue(value: $0) }

            case .enum:
                var firstItem = true
                _ = try! schema.performOnRawEnumValues(
                    MessageSchema.TrampolineToken(index: field.submessageIndex),
                    field,
                    self,
                    .read
                ) { enumSchema, value in
                    if !firstItem {
                        encoder.comma()
                    }
                    // TODO: Handle the WKT `NullValue` with a custom JSON representation.
                    encoder.putEnumValue(
                        rawValue: value,
                        enumSchema: enumSchema,
                        alwaysPrintEnumsAsInts: options.alwaysPrintEnumsAsInts
                    )
                    firstItem = false
                    return true
                } /*onInvalidValue*/ _: { _ in
                    assertionFailure("invalid value handler should never be called for .read")
                }

            case .fixed32, .uint32:
                emitRepeatedField { (value: UInt32) in encoder.putNonQuotedUInt32(value: value) }

            case .fixed64, .uint64:
                emitRepeatedField { (value: UInt64) in
                    options.alwaysPrintInt64sAsNumbers
                        ? encoder.putNonQuotedUInt64(value: value)
                        : encoder.putQuotedUInt64(value: value)
                }

            case .float:
                emitRepeatedField { encoder.putFloatValue(value: $0) }

            case .group, .message:
                var firstItem = true
                _ = try schema.performOnSubmessageStorage(
                    MessageSchema.TrampolineToken(index: field.submessageIndex),
                    field,
                    self,
                    .read
                ) {
                    if !firstItem {
                        encoder.comma()
                    }
                    try $0.serializeJSON(into: &encoder, options: options)
                    firstItem = false
                    return true
                }

            case .int32, .sfixed32, .sint32:
                emitRepeatedField { (value: Int32) in encoder.putNonQuotedInt32(value: value) }

            case .int64, .sfixed64, .sint64:
                emitRepeatedField { (value: Int64) in
                    options.alwaysPrintInt64sAsNumbers
                        ? encoder.putNonQuotedInt64(value: value)
                        : encoder.putQuotedInt64(value: value)
                }

            case .string:
                emitRepeatedField { encoder.putStringValue(value: $0) }

            default: preconditionFailure("Unreachable")
            }

            encoder.endArray()

        case .scalar:
            try emitSingularValue(of: field, to: &encoder, options: options)

        default: preconditionFailure("Unreachable")
        }
    }

    /// Emits the JSON key (and subsequent colon) for the field with the given number, throwing an
    /// error if the field's name isn't found.
    private func emitKey(
        forFieldNumber fieldNumber: UInt32,
        into encoder: inout JSONEncoder,
        options: JSONEncodingOptions
    ) throws {
        let name: String?
        if options.preserveProtoFieldNames {
            name = schema.textName(forFieldNumber: fieldNumber)
        } else {
            name = schema.jsonName(forFieldNumber: fieldNumber)
        }

        // TODO: When we support extensions, look those up after this first branch.
        if let name {
            encoder.startField(name: name)
        } else {
            throw JSONEncodingError.missingFieldNames
        }
    }

    /// Emits the JSON value for the field with the given number.
    private func emitSingularValue(
        of field: FieldSchema,
        to encoder: inout JSONEncoder,
        options: JSONEncodingOptions
    ) throws {
        let fieldType = field.rawFieldType
        let offset = field.offset

        switch fieldType {
        case .bool:
            encoder.putNonQuotedBoolValue(value: assumedPresentValue(at: offset))

        case .bytes:
            encoder.putBytesValue(value: assumedPresentValue(at: offset) as Data)

        case .double:
            encoder.putDoubleValue(value: assumedPresentValue(at: offset))

        case .enum:
            _ = try schema.performOnRawEnumValues(
                MessageSchema.TrampolineToken(index: field.submessageIndex),
                field,
                self,
                .read
            ) { enumSchema, value in
                // TODO: Handle the WKT `NullValue` with a custom JSON representation.
                encoder.putEnumValue(
                    rawValue: value,
                    enumSchema: enumSchema,
                    alwaysPrintEnumsAsInts: options.alwaysPrintEnumsAsInts
                )
                return true
            } /*onInvalidValue*/ _: { _ in
                assertionFailure("invalid value handler should never be called for .read")
            }

        case .fixed32, .uint32:
            encoder.putNonQuotedUInt32(value: assumedPresentValue(at: offset))

        case .fixed64, .uint64:
            let value: UInt64 = assumedPresentValue(at: offset)
            options.alwaysPrintInt64sAsNumbers
                ? encoder.putNonQuotedUInt64(value: value)
                : encoder.putQuotedUInt64(value: value)

        case .float:
            encoder.putFloatValue(value: assumedPresentValue(at: offset))

        case .group, .message:
            _ = try schema.performOnSubmessageStorage(
                MessageSchema.TrampolineToken(index: field.submessageIndex),
                field,
                self,
                .read
            ) {
                try $0.serializeJSON(into: &encoder, options: options)
                return true
            }

        case .int32, .sfixed32, .sint32:
            encoder.putNonQuotedInt32(value: assumedPresentValue(at: offset))

        case .int64, .sfixed64, .sint64:
            let value: Int64 = assumedPresentValue(at: offset)
            options.alwaysPrintInt64sAsNumbers
                ? encoder.putNonQuotedInt64(value: value)
                : encoder.putQuotedInt64(value: value)

        case .string:
            encoder.putStringValue(value: assumedPresentValue(at: offset))

        default: preconditionFailure("Unreachable")
        }
    }

    /// Emits the JSON value for the field with the given number, treating it as needed for a valid
    /// map key (i.e., always double-quoted).
    private func emitAsMapKey(_ field: FieldSchema, to encoder: inout JSONEncoder) throws {
        let offset = field.offset
        switch field.rawFieldType {
        case .bool:
            encoder.putQuotedBoolValue(value: assumedPresentValue(at: offset))

        case .fixed32, .uint32:
            encoder.putQuotedUInt32(value: assumedPresentValue(at: offset))

        case .fixed64, .uint64:
            encoder.putQuotedUInt64(value: assumedPresentValue(at: offset))

        case .int32, .sfixed32, .sint32:
            encoder.putQuotedInt32(value: assumedPresentValue(at: offset))

        case .int64, .sfixed64, .sint64:
            encoder.putQuotedInt64(value: assumedPresentValue(at: offset))

        case .string:
            encoder.putStringValue(value: assumedPresentValue(at: offset))

        default: preconditionFailure("Unreachable")
        }
    }

    /// Emits the JSON representation of the receiver as a well-known-type `Any` to the encoder.
    ///
    /// For `Any`s that wrap a well-known type, this will represent it using that value's custom
    /// JSON representation as the value of the `value` field (for example, a `Duration` is stored
    /// like `"value": "0s"`). For all other messages, the fields of that message are _inlined_
    /// into the same JSON object that holds the `Any`'s type URL.
    ///
    /// - Precondition: The receiver must be the storage for `google.protobuf.Any`.
    private func emitAsAny(into encoder: inout JSONEncoder, options: JSONEncodingOptions) throws {
        encoder.startObject()
        defer { encoder.endObject() }

        let typeURLField = schema[fieldNumber: 1]!
        let valueField = schema[fieldNumber: 2]!

        let isValuePresent = isPresent(valueField)

        // Follow the C++ protostream_objectsource.cc's
        // `ProtoStreamObjectSource::RenderAny()` special casing of an empty value.
        if !isPresent(typeURLField) && !isValuePresent {
            return
        }

        let typeURL = value(of: typeURLField) as String
        guard !typeURL.isEmpty else {
            throw SwiftProtobufError.JSONEncoding.emptyAnyTypeURL()
        }
        guard isTypeURLValid(typeURL) else {
            throw SwiftProtobufError.JSONEncoding.invalidAnyTypeURL(type_url: typeURL)
        }
        encoder.startField(name: "@type")
        encoder.putStringValue(value: typeURL)

        guard isValuePresent else {
            // If the value field is not present, then there's nothing to decode, and we don't
            // check if the type URL is registered.
            return
        }

        guard let messageSchema = Google_Protobuf_Any.messageSchema(forTypeURL: typeURL) else {
            throw SwiftProtobufError.JSONEncoding.invalidAnyTypeURL(type_url: typeURL)
        }
        let isWKT = CustomJSONWKTClassification(messageSchema: messageSchema) != .notWellKnown
        if isWKT {
            encoder.startField(name: "value")
        }
        let bytes = assumedPresentValue(at: valueField.offset) as Data
        try bytes.withUnsafeBytes { buffer in
            let messageStorage = MessageStorage(schema: messageSchema)
            try messageStorage.merge(byReadingFrom: buffer, extensions: options.extensions, partial: false, options: BinaryDecodingOptions())
            try messageStorage.serializeJSON(into: &encoder, options: options, shouldInlineFields: !isWKT)
        }
    }

    /// Emits a double-quoted string to the encoder that is the JSON representation of the receiver
    /// as a well-known-type `Duration`.
    ///
    /// - Precondition: The receiver must be the storage for `google.protobuf.Duration`.
    private func emitAsDuration(into encoder: inout JSONEncoder) throws {
        let seconds = value(of: schema[fieldNumber: 1]!) as Int64
        let nanos = value(of: schema[fieldNumber: 2]!) as Int32
        guard let formatted = formatDuration(seconds: seconds, nanos: nanos) else {
            throw JSONEncodingError.durationRange
        }
        encoder.putStringValue(value: formatted)
    }

    /// Emits a double-quoted string to the encoder that is the JSON representation of the receiver
    /// as a well-known-type `FieldMask`.
    ///
    /// - Precondition: The receiver must be the storage for `google.protobuf.FieldMask`.
    private func emitAsFieldMask(into encoder: inout JSONEncoder) throws {
        let paths = value(of: schema[fieldNumber: 1]!, default: []) as [String]
        var jsonPaths = [String]()
        jsonPaths.reserveCapacity(paths.count)
        for path in paths {
            if let jsonPath = jsonName(forProtoFieldMaskPath: path) {
                jsonPaths.append(jsonPath)
            } else {
                throw JSONEncodingError.fieldMaskConversion
            }
        }
        encoder.putStringValue(value: jsonPaths.joined(separator: ","))
    }

    /// Emits a JSON array to the encoder that is the JSON representation of the receiver as a
    /// well-known-type `ListValue`.
    ///
    /// - Precondition: The receiver must be the storage for `google.protobuf.ListValue`.
    private func emitAsListValue(into encoder: inout JSONEncoder, options: JSONEncodingOptions) throws {
        encoder.startArray()

        let valuesField = schema[fieldNumber: 1]!
        if isPresent(valuesField) {
            var firstItem = true
            _ = try schema.performOnSubmessageStorage(
                MessageSchema.TrampolineToken(index: valuesField.submessageIndex),
                valuesField,
                self,
                .read
            ) {
                if !firstItem {
                    encoder.comma()
                }
                try $0.serializeJSON(into: &encoder, options: options)
                firstItem = false
                return true
            }
        }

        encoder.endArray()
    }

    /// Emits a JSON object to the encoder that is the JSON representation of the receiver as a
    /// well-known-type `Struct`.
    ///
    /// - Precondition: The receiver must be the storage for `google.protobuf.Struct`.
    private func emitAsStruct(into encoder: inout JSONEncoder, options: JSONEncodingOptions) throws {
        encoder.startObject()

        let fieldsField = schema[fieldNumber: 1]!
        if isPresent(fieldsField) {
            var mapEntryWorkingSpace = MapEntryWorkingSpace(ownerSchema: schema)
            var firstItem = true
            _ = try schema.performOnMapEntry(
                MessageSchema.TrampolineToken(index: fieldsField.submessageIndex),
                fieldsField,
                self,
                mapEntryWorkingSpace.storage(for: fieldsField.submessageIndex),
                .read,
                false  // useDeterministicOrdering
            ) { mapEntryStorage in
                if !firstItem {
                    encoder.comma()
                }
                let mapEntrySchema = mapEntryStorage.schema
                try mapEntryStorage.emitAsMapKey(mapEntrySchema[fieldNumber: 1]!, to: &encoder)
                encoder.append(text: ":")
                try mapEntryStorage.emitSingularValue(
                    of: mapEntrySchema[fieldNumber: 2]!,
                    to: &encoder,
                    options: options
                )
                firstItem = false
                return true
            }
        }

        encoder.endObject()
    }

    /// Emits a double-quoted string to the encoder that is the JSON representation of the receiver
    /// as a well-known-type `Timestamp`.
    ///
    /// - Precondition: The receiver must be the storage for `google.protobuf.Timestamp`.
    private func emitAsTimestamp(into encoder: inout JSONEncoder) throws {
        let seconds = value(of: schema[fieldNumber: 1]!) as Int64
        let nanos = value(of: schema[fieldNumber: 2]!) as Int32
        guard let formatted = formatTimestamp(seconds: seconds, nanos: nanos) else {
            throw JSONEncodingError.durationRange
        }
        encoder.putStringValue(value: formatted)
    }

    /// Emits a JSON value to the encoder that is the JSON representation of the receiver as a
    /// well-known-type `Value`.
    ///
    /// - Precondition: The receiver must be the storage for `google.protobuf.Value`.
    private func emitAsValue(into encoder: inout JSONEncoder, options: JSONEncodingOptions) throws {
        // It doesn't matter which field number we pass in here, as long as it's valid and a member
        // of the one-of we're interested in.
        let populatedFieldNumber = populatedOneofMember(of: schema[fieldNumber: 1]!)
        let field = schema[fieldNumber: populatedFieldNumber]!
        switch populatedFieldNumber {
        case 1:
            encoder.putNullValue()

        case 2:
            let numberValue = value(of: field) as Double
            guard numberValue.isFinite else {
                throw JSONEncodingError.valueNumberNotFinite
            }
            encoder.putDoubleValue(value: numberValue)

        case 3:
            encoder.putStringValue(value: value(of: field))

        case 4:
            encoder.putNonQuotedBoolValue(value: value(of: field))

        case 5, 6:
            _ = try schema.performOnSubmessageStorage(
                MessageSchema.TrampolineToken(index: field.submessageIndex),
                field,
                self,
                .read
            ) {
                try $0.serializeJSON(into: &encoder, options: options)
                return true
            }

        default:
            throw JSONEncodingError.missingValue
        }
    }
}

/// Returns the JSON form of the field mask path with the given proto name, or nil if it was not
/// possible to convert it to a JSON form.
private func jsonName(forProtoFieldMaskPath name: String) -> String? {
    guard isPrintableASCII(name) else { return nil }
    var jsonPath = String()
    var chars = name.makeIterator()
    while let c = chars.next() {
        switch c {
        case "_":
            if let toupper = chars.next() {
                switch toupper {
                case "a"..."z":
                    jsonPath.append(String(toupper).uppercased())
                default:
                    return nil
                }
            } else {
                return nil
            }
        case "A"..."Z":
            return nil
        case "a"..."z", "0"..."9", ".", "(", ")":
            jsonPath.append(c)
        default:
            // TODO: Change this to `return nil`
            // once we know everything legal is handled
            // above.
            jsonPath.append(c)
        }
    }
    return jsonPath
}
