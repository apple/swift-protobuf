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
@available(*, deprecated, message: "This error type has been deprecated and won't be thrown anymore; it has been replaced by `SwiftProtobufError`.")
public enum BinaryEncodingError: Error, Equatable {
  /// `Any` fields that were decoded from JSON cannot be re-encoded to binary
  /// unless the object they hold is a well-known type or a type registered via
  /// `Google_Protobuf_Any.register()`.
  case anyTypeURLNotRegistered(typeURL: String)
  /// An unexpected failure when deserializing a `Google_Protobuf_Any`.
  case anyTranscodeFailure
  /// The definition of the message or one of its nested messages has required
  /// fields but the message being encoded did not include values for them. You
  /// must pass `partial: true` during encoding if you wish to explicitly ignore
  /// missing required fields.
  case missingRequiredFields
  /// Messages are limited to a maximum of 2GB in encoded size.
  case tooLarge
}
