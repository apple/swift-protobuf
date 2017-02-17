// Sources/SwiftProtobuf/Errors.swift - Error constants
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Enum constants that identify the particular error.
///
// -----------------------------------------------------------------------------

// TODO: It would be nice if coding/decoding errors could include the name
// of the specific field where the error was detected.

public enum EncodingError: Error {
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
    /// Field names were not compiled into the binary
    case missingFieldNames
    /// TODO: More here.
}
