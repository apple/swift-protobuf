// Sources/SwiftProtobuf/BinaryEncodingError.swift - Error constants
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

public enum BinaryEncodingError: Error {
    /// Any fields that were decoded from JSON cannot be re-encoded to
    /// binary unless the object they hold is a well-known type or a
    /// type registered with via Google_Protobuf_Any.register()
    case anyTranscodeFailure
    /// The message or nested messages definitions have required fields, and the
    /// Message being encoded does not include values for some of them. The
    /// `partial` support will allow this incomplete data to be decoded.
    case missingRequiredFields
}
