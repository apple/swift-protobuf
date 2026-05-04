// Sources/SwiftProtobuf/CustomJSONWKTClassification.swift - Custom JSON classification
//
// Copyright (c) 2014 - 2026 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Classification of well-known types based on custom JSON encodings.
///
// -----------------------------------------------------------------------------

/// Classifies a subset of the well-known types based on the nature of their custom JSON encodings.
package enum CustomJSONWKTClassification {
    case notWellKnown
    case any
    case boolValue
    case bytesValue
    case doubleValue
    case duration
    case fieldMask
    case floatValue
    case int32Value
    case int64Value
    case listValue
    case nullValue
    case stringValue
    case `struct`
    case uint32Value
    case uint64Value
    case timestamp
    case value

    var hasNonEmptyNullRepresentation: Bool {
        switch self {
        case .nullValue, .value: return true
        default: return false
        }
    }

    /// Classifies the message represented by the given schema.
    package init(messageSchema: MessageSchema) {
        guard let suffix = messageSchema.messageName.consumePrefix("google.protobuf.") else {
            self = .notWellKnown
            return
        }
        if suffix.utf8CodeUnitsEqual("Any") {
            self = .any
        } else if suffix.utf8CodeUnitsEqual("BoolValue") {
            self = .boolValue
        } else if suffix.utf8CodeUnitsEqual("BytesValue") {
            self = .bytesValue
        } else if suffix.utf8CodeUnitsEqual("DoubleValue") {
            self = .doubleValue
        } else if suffix.utf8CodeUnitsEqual("Duration") {
            self = .duration
        } else if suffix.utf8CodeUnitsEqual("FieldMask") {
            self = .fieldMask
        } else if suffix.utf8CodeUnitsEqual("FloatValue") {
            self = .floatValue
        } else if suffix.utf8CodeUnitsEqual("Int32Value") {
            self = .int32Value
        } else if suffix.utf8CodeUnitsEqual("Int64Value") {
            self = .int64Value
        } else if suffix.utf8CodeUnitsEqual("ListValue") {
            self = .listValue
        } else if suffix.utf8CodeUnitsEqual("StringValue") {
            self = .stringValue
        } else if suffix.utf8CodeUnitsEqual("Struct") {
            self = .struct
        } else if suffix.utf8CodeUnitsEqual("Timestamp") {
            self = .timestamp
        } else if suffix.utf8CodeUnitsEqual("UInt32Value") {
            self = .uint32Value
        } else if suffix.utf8CodeUnitsEqual("UInt64Value") {
            self = .uint64Value
        } else if suffix.utf8CodeUnitsEqual("Value") {
            self = .value
        } else {
            self = .notWellKnown
        }
    }

    /// Classifies the enum represented by the given schema.
    package init(enumSchema: EnumSchema) {
        self = enumSchema.enumName.utf8CodeUnitsEqual("google.protobuf.NullValue") ? .nullValue : .notWellKnown
    }
}
