// Sources/SwiftProtobuf/TextFormatDecodingError.swift - Protobuf text format decoding errors
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
//
// Protobuf text format decoding errors
//
// -----------------------------------------------------------------------------

/// The errors that can occur when decoding a message from text format.
public enum TextFormatDecodingError: Error {
    /// The decoder could not parse the text data
    case malformedText
    /// The decoder could not parse a number
    case malformedNumber
    /// Extraneous data remained after decoding should have been complete
    case trailingGarbage
    /// The data stopped before we expected
    case truncated
    /// A string was not valid UTF8
    case invalidUTF8
    /// The data does not match the type specified in the proto file
    case schemaMismatch
    /// The generated code does not include field names
    case missingFieldNames
    /// The decoder could not find a field identifier (name or number) on the message
    case unknownField
    /// The decoder did not recognize the enum value
    case unrecognizedEnumValue
    /// Text format rejects conflicting values for the same oneof field
    case conflictingOneOf
    /// An internal error happened while decoding.
    ///
    /// If you ever encounter this, please file an issue with SwiftProtobuf
    /// with as much details as possible for what happened (proto definitions,
    /// bytes being decoded (if possible)).
    case internalExtensionError
    /// Reached the nesting limit for messages within messages while decoding.
    case messageDepthLimit
}
