// ProtobufRuntime/Sources/Protobuf/ProtobufError.swift - Error constants
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
// -----------------------------------------------------------------------------
///
/// Enum constants that identify the particular error.
///
// -----------------------------------------------------------------------------

// TODO: It would be nice if coding/decoding errors could include the name
// of the specific field where the error was detected.

import Swift

public enum ProtobufDecodingError: Error {
    /// An unspecified decoding failure
    case failure
    /// JSON format does not allow a oneof field to be specified more than once
    /// TODO: Remove me!  (This was in generated code until May 18, 2016; remove in July 2016.)
    case DuplicatedOneOf // TODO: Remove me!
    /// JSON format does not allow a oneof field to be specified more than once
    /// Note:  This is used in generated code!  Changing this is difficult.
    case duplicatedOneOf
    /// Extraneous data remained after decoding should have been complete
    case trailingGarbage
    /// Input was truncated
    case truncatedInput
    /// The data being parsed does not match the type specified in the proto file
    case schemaMismatch
    /// Any field could not be unpacked
    case malformedAnyField
    /// Names in a field mask could not be converted
    case fieldMaskConversion
    /// The JSON was syntactically invalid
    case malformedJSON
    /// A JSON number was not parseable
    case malformedJSONNumber
    /// A JSON timestamp was not parseable
    case malformedJSONTimestamp
    /// The enum value was not recognized (for JSON, this is a parse error)
    case unrecognizedEnumValue
    /// Strings must always be valid UTF-8
    case invalidUTF8
    /// Protobuf binary was syntactically invalid
    case malformedProtobuf
    /// TODO: More here?
}

public enum ProtobufEncodingError: Error {
    /// An unspecified encoding failure
    case failure
    /// Any fields cannot be transcoded between JSON and protobuf unless
    /// the object they hold is a well-known type or a type registered with
    /// via Google_Protobuf_Any.register()
    case anyTranscodeFailure
    /// Timestamp values can only be JSON encoded if they hold a value
    /// between 0001-01-01Z00:00:00 and 9999-12-31Z23:59:59.
    case timestampJSONRange
    /// Duration values can only be JSON encoded if they hold a value
    /// less than +/- 100 years.
    case durationJSONRange
    /// Field masks get edited when converting between JSON and protobuf
    case fieldMaskConversion
    /// TODO: More here.
}
