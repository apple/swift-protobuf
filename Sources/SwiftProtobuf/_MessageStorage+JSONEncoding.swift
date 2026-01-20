// Sources/SwiftProtobuf/_MessageStorage+JSONEncoding.swift - JSON format encoding for messages
//
// Copyright (c) 2014 - 2026 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// JSON format encoding support for `_MessageStorage.`
///
// -----------------------------------------------------------------------------

import Foundation

extension _MessageStorage {
    /// Returns the Protocol Buffer JSON serialization of the message.
    ///
    /// - Parameter options: The options to use when encoding the message.
    /// - Returns: The JSON serialization of the message.
    public func jsonUTF8Bytes<Bytes: SwiftProtobufContiguousBytes>(options: JSONEncodingOptions) throws -> Bytes {
        var encoder = JSONEncoder()
        try serializeJSON(into: &encoder, options: options)
        return Bytes(encoder.bytesResult)
    }

    /// A recursion helper that serializes the fields in the storage into the given JSON encoder.
    private func serializeJSON(into encoder: inout JSONEncoder, options: JSONEncodingOptions) throws {
        // TODO: If the message being serialized is a WKT that has a custom JSON representation,
        // do that here instead. If we move the fully-qualified message name into the layout, we
        // can compare against that.

        encoder.startObject()
        var mapEntryWorkingSpace = MapEntryWorkingSpace(ownerLayout: layout)
        for field in layout.fields {
            guard isPresent(field) else { continue }
            try serializeField(field, into: &encoder, mapEntryWorkingSpace: &mapEntryWorkingSpace, options: options)
        }
        // TODO: Support extensions.
        encoder.endObject()
    }

    /// Serializes a single field in the storage into the given JSON  encoder.
    private func serializeField(
        _ field: FieldLayout,
        into encoder: inout JSONEncoder,
        mapEntryWorkingSpace: inout MapEntryWorkingSpace,
        options: JSONEncodingOptions
    ) throws {
        let fieldNumber = Int(field.fieldNumber)
        let fieldType = field.rawFieldType
        let offset = field.offset

        try emitKey(forFieldNumber: fieldNumber, into: &encoder, options: options)

        switch field.fieldMode.cardinality {
        case .map:
            encoder.startObject()

            var firstItem = true
            _ = try layout.performOnMapEntry(
                _MessageLayout.TrampolineToken(index: field.submessageIndex),
                field,
                self,
                mapEntryWorkingSpace.storage(for: field.submessageIndex),
                .read,
                false  // useDeterministicOrdering
            ) { mapEntryStorage in
                if !firstItem {
                    encoder.comma()
                }
                let mapEntryLayout = mapEntryStorage.layout
                try mapEntryStorage.emitAsMapKey(mapEntryLayout[fieldNumber: 1]!, to: &encoder)
                encoder.append(text: ":")
                try mapEntryStorage.emitSingularValue(
                    of: mapEntryLayout[fieldNumber: 2]!,
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
                _ = try! layout.performOnRawEnumValues(
                    _MessageLayout.TrampolineToken(index: field.submessageIndex),
                    field,
                    self,
                    .read
                ) { enumLayout, value in
                    if !firstItem {
                        encoder.comma()
                    }
                    // TODO: Handle the WKT `NullValue` with a custom JSON representation.
                    encoder.putEnumValue(
                        rawValue: value,
                        nameMap: enumLayout.nameMap,
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
                _ = try layout.performOnSubmessageStorage(
                    _MessageLayout.TrampolineToken(index: field.submessageIndex),
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
        forFieldNumber fieldNumber: Int,
        into encoder: inout JSONEncoder,
        options: JSONEncodingOptions
    ) throws {
        let name: _NameMap.Name?
        if options.preserveProtoFieldNames {
            name = layout.nameMap.names(for: fieldNumber)?.proto
        } else {
            name = layout.nameMap.names(for: fieldNumber)?.json
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
        of field: FieldLayout,
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
            _ = try layout.performOnRawEnumValues(
                _MessageLayout.TrampolineToken(index: field.submessageIndex),
                field,
                self,
                .read
            ) { enumLayout, value in
                // TODO: Handle the WKT `NullValue` with a custom JSON representation.
                encoder.putEnumValue(
                    rawValue: value,
                    nameMap: enumLayout.nameMap,
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
            _ = try layout.performOnSubmessageStorage(
                _MessageLayout.TrampolineToken(index: field.submessageIndex),
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
    private func emitAsMapKey(_ field: FieldLayout, to encoder: inout JSONEncoder) throws {
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
}
