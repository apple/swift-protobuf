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

/// Describes errors that can occur when unpacking an `Any` message.
///
/// `Any` messages can be decoded from protobuf binary, text format, or JSON.
/// The contents are not parsed immediately; the raw data is held in the `Any`
/// message until you `unpack()` it into a message.  At this time, any
/// error can occur that might have occurred from a regular decoding
/// operation.  In addition, there are a number of other errors that are
/// possible, involving the structure of the `Any` object itself.
public enum AnyUnpackError: Error {
  /// The `typeURL` field in the `Any` message did not match the message type
  /// provided to the `unpack()` method.
  case typeMismatch

  /// Well-known types being decoded from JSON must have only two
  /// fields: the `@type` field and a `value` field containing
  /// the specialized JSON coding of the well-known type.
  case malformedWellKnownTypeJSON

  /// The `Any` message was malformed in some other way not covered by the other
  /// error cases.
  case malformedAnyField

  /// Decoding JSON or text format requires the message type
  /// to have been compiled with textual field names.
  case missingFieldNames
}
