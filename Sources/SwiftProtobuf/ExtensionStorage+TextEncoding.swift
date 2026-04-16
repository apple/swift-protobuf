// Sources/SwiftProtobuf/ExtensionStorage+TextEncoding.swift - Text format encoding for extensions
//
// Copyright (c) 2014 - 2026 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Text format encoding support for `ExtensionStorage`.
///
// -----------------------------------------------------------------------------

import Foundation

extension ExtensionStorage {
    /// Serializes the extension fields in the receiver to the given text format encoder.
    func serializeText(into encoder: inout TextFormatEncoder, options: TextFormatEncodingOptions) {
        for (_, value) in values {
            serializeExtensionValue(value, into: &encoder, options: options)
        }
    }

    /// Serializes a single extension field in the storage into the given text format encoder.
    private func serializeExtensionValue(
        _ value: ExtensionValueStorage,
        into encoder: inout TextFormatEncoder,
        options: TextFormatEncodingOptions
    ) {
        let schema = value.schema
        let field = schema.field
        let fieldType = field.rawFieldType

        switch field.fieldMode.cardinality {
        case .map:
            preconditionFailure("unreachable")

        case .array:
            let isPacked = field.fieldMode.isPacked

            func emitRepeatedField<Value>(_ emitValue: (Value) -> Void) {
                let values = value.value(as: [Value].self)
                if isPacked {
                    // Use the shorthand representation, "fieldName: [...]".
                    encoder.emitExtensionFieldName(name: schema.fieldName)
                    encoder.startRegularField()
                    encoder.startArray()
                    var firstItem = true
                    for value in values {
                        if !firstItem {
                            encoder.arraySeparator()
                        }
                        emitValue(value)
                        firstItem = false
                    }
                    encoder.endArray()
                    encoder.endRegularField()
                } else {
                    // Each element is a fully serialized "name: value" pair.
                    for value in values {
                        encoder.emitExtensionFieldName(name: schema.fieldName)
                        encoder.startRegularField()
                        emitValue(value)
                        encoder.endRegularField()
                    }
                }
            }

            switch fieldType {
            case .bool:
                emitRepeatedField { encoder.putBoolValue(value: $0) }

            case .bytes:
                precondition(!isPacked, "a packed bytes field should not be reachable")
                emitRepeatedField { encoder.putBytesValue(value: $0) }

            case .double:
                emitRepeatedField { encoder.putDoubleValue(value: $0) }

            case .enum:
                emitRepeatedEnumField(schema, into: &encoder)

            case .fixed32, .uint32:
                emitRepeatedField { (value: UInt32) in encoder.putUInt64(value: UInt64(value)) }

            case .fixed64, .uint64:
                emitRepeatedField { (value: UInt64) in encoder.putUInt64(value: value) }

            case .float:
                emitRepeatedField { encoder.putFloatValue(value: $0) }

            case .group, .message:
                precondition(!isPacked, "a packed group/message field should not be reachable")
                _ = try! schema.performOnSubmessageStorage(
                    schema,
                    self,
                    .read
                ) {
                    encoder.emitExtensionFieldName(name: schema.fieldName)
                    encoder.startMessageField()
                    $0.serializeText(into: &encoder, options: options)
                    encoder.endMessageField()
                    return true
                }

            case .int32, .sfixed32, .sint32:
                emitRepeatedField { (value: Int32) in encoder.putInt64(value: Int64(value)) }

            case .int64, .sfixed64, .sint64:
                emitRepeatedField { (value: Int64) in encoder.putInt64(value: value) }

            case .string:
                precondition(!isPacked, "a packed string field should not be reachable")
                emitRepeatedField { encoder.putStringValue(value: $0) }

            default: preconditionFailure("Unreachable")
            }

        case .scalar:
            encoder.emitExtensionFieldName(name: schema.fieldName)

            // Handle groups/messages separately since they have different delimiters than regular
            // fields.
            switch fieldType {
            case .group, .message:
                _ = try! schema.performOnSubmessageStorage(
                    schema,
                    self,
                    .read
                ) {
                    encoder.startMessageField()
                    $0.serializeText(into: &encoder, options: options)
                    encoder.endMessageField()
                    return true
                }
                return

            default:
                // Continue below.
                break
            }

            encoder.startRegularField()

            switch fieldType {
            case .bool:
                encoder.putBoolValue(value: value.value(as: Bool.self))

            case .bytes:
                encoder.putBytesValue(value: value.value(as: Data.self))

            case .double:
                encoder.putDoubleValue(value: value.value(as: Double.self))

            case .enum:
                _ = try! schema.performOnRawEnumValues(
                    schema,
                    self,
                    .read
                ) { enumSchema, value in
                    encoder.putEnumValue(rawValue: value, enumSchema: enumSchema)
                    return true
                } /*onInvalidValue*/ _: { _ in
                    assertionFailure("invalid value handler should never be called for .read")
                }

            case .fixed32, .uint32:
                encoder.putUInt64(value: UInt64(value.value(as: UInt32.self)))

            case .fixed64, .uint64:
                encoder.putUInt64(value: value.value(as: UInt64.self))

            case .float:
                encoder.putFloatValue(value: value.value(as: Float.self))

            case .int32, .sfixed32, .sint32:
                encoder.putInt64(value: Int64(value.value(as: Int32.self)))

            case .int64, .sfixed64, .sint64:
                encoder.putInt64(value: value.value(as: Int64.self))

            case .string:
                encoder.putStringValue(value: value.value(as: String.self))

            default: preconditionFailure("Unreachable")
            }

            encoder.endRegularField()

        default: preconditionFailure("Unreachable")
        }
    }

    /// Emits the name and values of a repeated enum field, using compact representation if the
    /// field is packed.
    private func emitRepeatedEnumField(_ schema: ExtensionSchema, into encoder: inout TextFormatEncoder) {
        if schema.field.fieldMode.isPacked {
            // Use the shorthand representation, "fieldName: [...]".
            encoder.emitExtensionFieldName(name: schema.fieldName)
            encoder.startRegularField()
            encoder.startArray()
            var firstItem = true

            _ = try! schema.performOnRawEnumValues(
                schema,
                self,
                .read
            ) { enumSchema, value in
                if !firstItem {
                    encoder.arraySeparator()
                }
                encoder.putEnumValue(rawValue: value, enumSchema: enumSchema)
                firstItem = false
                return true
            } /*onInvalidValue*/ _: { _ in
                assertionFailure("invalid value handler should never be called for .read")
            }

            encoder.endArray()
            encoder.endRegularField()
        } else {
            // Each element is a fully serialized "name: value" pair.
            _ = try! schema.performOnRawEnumValues(
                schema,
                self,
                .read
            ) { enumSchema, value in
                encoder.emitExtensionFieldName(name: schema.fieldName)
                encoder.startRegularField()
                encoder.putEnumValue(rawValue: value, enumSchema: enumSchema)
                encoder.endRegularField()
                return true
            } /*onInvalidValue*/ _: { _ in
                assertionFailure("invalid value handler should never be called for .read")
            }
        }
    }
}
