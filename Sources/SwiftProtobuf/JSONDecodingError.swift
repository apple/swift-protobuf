// Sources/SwiftProtobuf/JSONDecodingError.swift - JSON decoding errors
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
//
// JSON decoding errors
//
// -----------------------------------------------------------------------------

/// The errors that can occur when decoding a message from JSON format.
public enum JSONDecodingError: Error {
    /// Something was wrong
    case failure
    /// A number failed to parse
    case malformedNumber
    /// A numeric value was out of range, or wasn't an integer where the decoder expected one
    case numberRange
    /// A map failed to parse
    case malformedMap
    /// A bool failed to parse
    case malformedBool
    /// We expected a quoted string, or a quoted string has a malformed backslash sequence
    case malformedString
    /// We encountered malformed UTF8
    case invalidUTF8
    /// The message does not have fieldName information
    case missingFieldNames
    /// The data type does not match the schema description
    case schemaMismatch
    /// A value (text or numeric) for an enum didn't match any of the enum's cases
    case unrecognizedEnumValue
    /// A 'null' token appeared in an illegal location.
    ///
    /// For example, Protobuf JSON does not allow 'null' tokens to appear
    /// in lists.
    case illegalNull
    /// A map key lacked quotes
    case unquotedMapKey
    /// JSON RFC 7519 does not allow numbers to have extra leading zeros
    case leadingZero
    /// We hit the end of the JSON string and expected something more...
    case truncated
    /// A JSON Duration failed to parse
    case malformedDuration
    /// A JSON Timestamp failed to parse
    case malformedTimestamp
    /// A FieldMask failed to parse
    case malformedFieldMask
    /// Extraneous data remained after decoding should have been complete
    case trailingGarbage
    /// The JSON specified more than one value for the same oneof field
    case conflictingOneOf
    /// Reached the nesting limit for messages within messages while decoding.
    case messageDepthLimit
    /// Encountered an unknown field with the given name.
    ///
    /// When parsing JSON, you can instead instruct the library to ignore this
    /// via `JSONDecodingOptions.ignoreUnknownFields`.
    case unknownField(String)
}
