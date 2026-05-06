// Sources/SwiftProtobuf/KnownField.swift - Conveniences for field numbers of WKTs
//
// Copyright (c) 2014 - 2026 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Convenience field accessors for well-known types and message sets.
///
// -----------------------------------------------------------------------------

/// A "handle" to a specific field number on well-known types or other messages
/// needed directly by the runtime.
///
/// This type can be used in one of two ways:
///
/// *   If the field number itself is needed (for example, to match during
///     decoding), use the `number` property.
/// *   As a convenience to get the `FieldSchema` from a `MessageSchema`, call
///     the `KnownField` instance as a function: `KnownField.name(in: schema)`
///     where `name` is one of the static properties.
///
/// We use computed properties rather than stored properties to avoid the values
/// having storage or generating an `unsafeMutableAddressor`.
struct KnownField: ExpressibleByIntegerLiteral {
    /// The number of the field.
    let number: UInt32

    init(integerLiteral number: UInt32) {
        self.number = number
    }

    /// Returns the `FieldSchema` for this field number in the given schema.
    func callAsFunction(in schema: MessageSchema) -> FieldSchema {
        schema[fieldNumber: number]!
    }
}

extension KnownField {
    /// The `null_value` field in `google.protobuf.Value`.
    static var valueNullValue: Self { 1 }
    /// The `number_value` field in `google.protobuf.Value`.
    static var valueNumberValue: Self { 2 }
    /// The `string_value` field in `google.protobuf.Value`.
    static var valueStringValue: Self { 3 }
    /// The `bool_value` field in `google.protobuf.Value`.
    static var valueBoolValue: Self { 4 }
    /// The `struct_value` field in `google.protobuf.Value`.
    static var valueStructValue: Self { 5 }
    /// The `list_value` field in `google.protobuf.Value`.
    static var valueListValue: Self { 6 }

    /// The `value` field in `google.protobuf.BoolValue`.
    static var boolValueValue: Self { 1 }

    /// The `value` field in `google.protobuf.BytesValue`.
    static var bytesValueValue: Self { 1 }

    /// The `value` field in `google.protobuf.DoubleValue`.
    static var doubleValueValue: Self { 1 }

    /// The `value` field in `google.protobuf.FloatValue`.
    static var floatValueValue: Self { 1 }

    /// The `value` field in `google.protobuf.Int32Value`.
    static var int32ValueValue: Self { 1 }

    /// The `value` field in `google.protobuf.Int64Value`.
    static var int64ValueValue: Self { 1 }

    /// The `value` field in `google.protobuf.StringValue`.
    static var stringValueValue: Self { 1 }

    /// The `value` field in `google.protobuf.UInt32Value`.
    static var uint32ValueValue: Self { 1 }

    /// The `value` field in `google.protobuf.UInt64Value`.
    static var uint64ValueValue: Self { 1 }

    /// The `values` field in `google.protobuf.ListValue`.
    static var listValueValues: Self { 1 }

    /// The `fields` field in `google.protobuf.Struct`.
    static var structFields: Self { 1 }

    /// The `seconds` field in `google.protobuf.Timestamp`.
    static var timestampSeconds: Self { 1 }
    /// The `nanos` field in `google.protobuf.Timestamp`.
    static var timestampNanos: Self { 2 }

    /// The `seconds` field in `google.protobuf.Duration`.
    static var durationSeconds: Self { 1 }
    /// The `nanos` field in `google.protobuf.Duration`.
    static var durationNanos: Self { 2 }

    /// The `paths` field in `google.protobuf.FieldMask`.
    static var fieldMaskPaths: Self { 1 }

    /// The `type_url` field in `google.protobuf.Any`.
    static var anyTypeURL: Self { 1 }
    /// The `value` field in `google.protobuf.Any`.
    static var anyValue: Self { 2 }

    /// The `key` field in the pseudo-message used to represent a `map` entry.
    static var mapEntryKey: Self { 1 }
    /// The `value` field in the pseudo-message used to represent a `map` entry.
    static var mapEntryValue: Self { 2 }

    /// The `item` group field that denotes an extension that is serialized in message set format.
    static var messageSetItem: Self { 1 }
    /// The `type_id` field that represents the extension field number in a message set.
    static var messageSetTypeID: Self { 2 }
    /// The `message` field that holds the extension field value in a message set.
    static var messageSetMessage: Self { 3 }
}
