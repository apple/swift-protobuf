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

    /// Classifies the message represented by the given layout.
    package init(messageLayout: _MessageLayout) {
        guard let suffix = suffixIfWellKnown(messageLayout.nameMap.fullyQualifiedName) else {
            self = .notWellKnown
            return
        }
        switch suffix {
        case "Any": self = .any
        case "BoolValue": self = .boolValue
        case "BytesValue": self = .bytesValue
        case "DoubleValue": self = .doubleValue
        case "Duration": self = .duration
        case "FieldMask": self = .fieldMask
        case "FloatValue": self = .floatValue
        case "Int32Value": self = .int32Value
        case "Int64Value": self = .int64Value
        case "ListValue": self = .listValue
        case "StringValue": self = .stringValue
        case "Struct": self = .struct
        case "Timestamp": self = .timestamp
        case "UInt32Value": self = .uint32Value
        case "UInt64Value": self = .uint64Value
        case "Value": self = .value
        default: self = .notWellKnown
        }
    }

    /// Classifies the enum represented by the given layout.
    package init(enumLayout: EnumLayout) {
        self = enumLayout.nameMap.fullyQualifiedName == "google.protobuf.NullValue" ? .nullValue : .notWellKnown
    }
}

/// Returns the portion of the full message/enum name that follows `google.protobuf.` if it is a
/// well-known type.
private func suffixIfWellKnown(_ fullName: String) -> Substring? {
    let prefix = "google.protobuf."
    guard fullName.starts(with: prefix) else {
        return nil
    }
    return fullName.dropFirst(prefix.count)
}
