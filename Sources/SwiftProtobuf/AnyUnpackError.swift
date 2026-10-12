// Sources/SwiftProtobuf/AnyUnpackError.swift - Any Unpacking Errors
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
//
// Errors that can be throw when unpacking a Google_Protobuf_Any.
//
// -----------------------------------------------------------------------------

/// The errors that can occur when unpacking an Any message.
///
/// You can decode ``Google_Protobuf_Any`` messages from protobuf binary, text
/// format, or JSON. SwiftProtobuf doesn't parse the contents immediately; it
/// holds the raw data in the ``Google_Protobuf_Any`` message until you call
/// `unpack()` to convert it into a message.  At that point, any error from a
/// regular decoding operation can occur.  Other errors can also occur due
/// to problems with the `Any` value's structure.
public enum AnyUnpackError: Error {
    /// The recorded message type doesn't match the type you're unpacking into.
    ///
    /// The `type_url` field in the ``Google_Protobuf_Any`` message did not match
    /// the message type you passed to the `unpack()` method.
    case typeMismatch

    /// The JSON encoding of a well-known type didn't have the fields it needs.
    ///
    /// When you decode a well-known type from JSON, it must have only two
    /// fields: the `@type` field and a `value` field containing the
    /// specialized JSON coding of the well-known type.
    case malformedWellKnownTypeJSON

    /// The Any message was malformed in some other way that the other error
    /// cases don't cover.
    case malformedAnyField
}
