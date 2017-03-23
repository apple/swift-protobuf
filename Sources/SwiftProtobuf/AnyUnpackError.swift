// Sources/SwiftProtobuf/AnyUnpackError.swift - Any Unpacking Errors
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Errors that can be throw when unpacking a Google_Protobuf_Any.
///
// -----------------------------------------------------------------------------

import Foundation

/// Any objects can be parsed from Protobuf Binary, Protobuf Text, or JSON.
/// The contents are not parsed immediately; the raw data is held in the Any
/// object until you `unpack()` it into a message.  At this time, any
/// error can occur that might have occurred from a regular decoding
/// operation.  In addition, there are a number of other errors that are
/// possible, involving the structure of the Any object itself.
public enum AnyUnpackError: Error {
  /// The `urlType` field in the Any object did not match the message type
  /// provided to the `unpack()` method.
  case typeMismatch
  /// Well-known types being decoded from JSON must have only two
  /// fields:  the `@type` field and a `value` field containing
  /// the specialized JSON coding of the well-known type.
  case malformedWellKnownTypeJSON
  /// Decoding JSON or Text format requires the message type
  /// to have been compiled with textual field names.
  case missingFieldNames
}
