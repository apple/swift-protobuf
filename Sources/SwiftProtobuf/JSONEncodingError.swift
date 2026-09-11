// Sources/SwiftProtobuf/JSONEncodingError.swift - Error constants
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
//
// Enum constants that identify the particular error.
//
// -----------------------------------------------------------------------------

/// The errors that can occur when encoding a message to JSON format.
public enum JSONEncodingError: Error, Hashable {
    /// The JSON encoder cannot re-encode a field that the binary decoder
    /// produced unless the object it holds is a well-known type or a type
    /// registered with Google_Protobuf_Any.register()
    case anyTranscodeFailure
    /// The JSON encoder can only encode a timestamp value that holds a
    /// value between 0001-01-01Z00:00:00 and 9999-12-31Z23:59:59.
    case timestampRange
    /// The JSON encoder can only encode a duration value that holds a
    /// value less than +/- 100 years.
    case durationRange
    /// Converting between JSON and protobuf edits field masks
    case fieldMaskConversion
    /// The build did not compile field names into the binary
    case missingFieldNames
    /// A value that must hold one of its supported kinds didn't have any set.
    ///
    /// The encoder can only encode an instance of ``Google_Protobuf_Value``
    /// that has a valid `kind` (that is, it represents a null value, number,
    /// boolean, string, struct, or list).
    case missingValue
    /// google.protobuf.Value cannot encode double values for infinity or nan,
    /// because the parser would parse them as a string.
    case valueNumberNotFinite
}
