// Sources/SwiftProtobuf/BinaryEncodingError.swift - Error constants
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Enum constants that identify the particular error.
///
// -----------------------------------------------------------------------------

/// Describes errors that can occur when decoding a message from binary format.
public enum BinaryEncodingError: Error, Hashable {
    /// An unexpected failure when deserializing a `Google_Protobuf_Any`.
    case anyTranscodeFailure
    /// The definition of the message or one of its nested messages has required
    /// fields but the message being encoded did not include values for them. You
    /// must pass `partial: true` during encoding if you wish to explicitly ignore
    /// missing required fields.
    case missingRequiredFields
}
