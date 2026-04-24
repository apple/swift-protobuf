// Sources/SwiftProtobuf/ExtensionStorage+JSONEncoding.swift - JSON format encoding for extensions
//
// Copyright (c) 2014 - 2026 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// JSON format encoding support for `ExtensionStorage`.
///
// -----------------------------------------------------------------------------

import Foundation

extension ExtensionStorage {
    /// Serializes the values of all of the extension fields into the given JSON encoder.
    func serializeJSON(into encoder: inout JSONEncoder, options: JSONEncodingOptions) throws {
        for (_, value) in values {
            try serializeExtensionValue(value, into: &encoder, options: options)
        }
    }

    /// Serializes a single field in the storage into the given JSON encoder.
    private func serializeExtensionValue(
        _ value: ExtensionValueStorage,
        into encoder: inout JSONEncoder,
        options: JSONEncodingOptions
    ) throws {
        let schema = value.schema
        let field = schema.field
        let fieldType = field.rawFieldType

        encoder.startExtensionField(name: schema.fieldName)

        switch field.fieldMode.cardinality {
        case .map:
            preconditionFailure("unreachable")

        case .array:
            encoder.startArray()

            func emitRepeatedField<Value>(_ emitValue: (Value) -> Void) {
                let values = value.value(as: [Value].self)
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
                    schema,
                    self,
                    .read
                ) { enumSchema, value in
                    if !firstItem {
                        encoder.comma()
                    }
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
                    schema,
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
            try emitSingularValue(value, to: &encoder, options: options)

        default: preconditionFailure("Unreachable")
        }
    }

    /// Emits the JSON value for the field with the given number.
    private func emitSingularValue(
        _ value: ExtensionValueStorage,
        to encoder: inout JSONEncoder,
        options: JSONEncodingOptions
    ) throws {
        let schema = value.schema
        let field = schema.field
        let fieldType = field.rawFieldType

        switch fieldType {
        case .bool:
            encoder.putNonQuotedBoolValue(value: value.value(as: Bool.self))

        case .bytes:
            encoder.putBytesValue(value: value.value(as: Data.self))

        case .double:
            encoder.putDoubleValue(value: value.value(as: Double.self))

        case .enum:
            _ = try schema.performOnRawEnumValues(
                schema,
                self,
                .read
            ) { enumSchema, value in
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
            encoder.putNonQuotedUInt32(value: value.value(as: UInt32.self))

        case .fixed64, .uint64:
            let value = value.value(as: UInt64.self)
            options.alwaysPrintInt64sAsNumbers
                ? encoder.putNonQuotedUInt64(value: value)
                : encoder.putQuotedUInt64(value: value)

        case .float:
            encoder.putFloatValue(value: value.value(as: Float.self))

        case .group, .message:
            _ = try schema.performOnSubmessageStorage(
                schema,
                self,
                .read
            ) {
                try $0.serializeJSON(into: &encoder, options: options)
                return true
            }

        case .int32, .sfixed32, .sint32:
            encoder.putNonQuotedInt32(value: value.value(as: Int32.self))

        case .int64, .sfixed64, .sint64:
            let value = value.value(as: Int64.self)
            options.alwaysPrintInt64sAsNumbers
                ? encoder.putNonQuotedInt64(value: value)
                : encoder.putQuotedInt64(value: value)

        case .string:
            encoder.putStringValue(value: value.value(as: String.self))

        default: preconditionFailure("Unreachable")
        }
    }
}
