// Sources/SwiftProtobuf/Google_Protobuf_Any+Extensions.swift - Well-known Any type
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Extends the Google_Protobuf_Any and Message structs with various
/// custom behaviors.
///
// -----------------------------------------------------------------------------

import Foundation


public extension Message {
  /// Initialize this message from the provided `google.protobuf.Any`
  /// well-known type.
  ///
  /// This corresponds to the `unpack` method in the Google C++ API.
  ///
  /// If the Any object was decoded from Protobuf Binary or JSON
  /// format, then the enclosed field data was stored and is not
  /// fully decoded until you unpack the Any object into a message.
  /// As such, this method will typically need to perform a full
  /// deserialization of the enclosed data and can fail for any
  /// reason that deserialization can fail.
  ///
  /// See `Google_Protobuf_Any.unpackTo()` for more discussion.
  ///
  /// - Parameter unpackingAny: the message to decode.
  /// - Throws: an instance of `AnyUnpackError`, `JSONDecodingError`, or
  ///   `BinaryDecodingError` on failure.
  public init(unpackingAny: Google_Protobuf_Any) throws {
    self.init()
    try unpackingAny.unpackTo(target: &self)
  }
}


public extension Google_Protobuf_Any {
  /// Decode an Any object from Protobuf Text Format.
  public init(textFormatString: String, extensions: ExtensionSet? = nil) throws {
    self.init()
    var textDecoder = try TextFormatDecoder(messageType: Google_Protobuf_Any.self,
                                            text: textFormatString,
                                            extensions: extensions)
    try decodeTextFormat(decoder: &textDecoder)
    if !textDecoder.complete {
      throw TextFormatDecodingError.trailingGarbage
    }
  }

}


extension Google_Protobuf_Any {

  // Custom text format decoding support for Any objects.
  // (Note: This is not a part of any protocol; it's invoked
  // directly from TextFormatDecoder whenever it sees an attempt
  // to decode an Any object)
  internal mutating func decodeTextFormat(decoder: inout TextFormatDecoder) throws {
    // First, check if this uses the "verbose" Any encoding.
    // If it does, and we have the type available, we can
    // eagerly decode the contained Message object.
    if let url = try decoder.scanner.nextOptionalAnyURL() {
      // Decoding the verbose form requires knowing the type:
      typeURL = url
      let messageTypeName = typeName(fromURL: url)
      let terminator = try decoder.scanner.skipObjectStart()
      // Is it a well-known type? Or a user-registered type?
      if messageTypeName == "google.protobuf.Any" {
        var subDecoder = try TextFormatDecoder(messageType: Google_Protobuf_Any.self, scanner: decoder.scanner, terminator: terminator)
        var any = Google_Protobuf_Any()
        try any.decodeTextFormat(decoder: &subDecoder)
        decoder.scanner = subDecoder.scanner
        if let _ = try decoder.nextFieldNumber() {
          // Verbose any can never have additional keys
          throw TextFormatDecodingError.malformedText
        }
        _message = any
        return
      } else if let messageType = Google_Protobuf_Any.lookupMessageType(forMessageName: messageTypeName) {
        var subDecoder = try TextFormatDecoder(messageType: messageType, scanner: decoder.scanner, terminator: terminator)
        _message = messageType.init()
        try _message!.decodeMessage(decoder: &subDecoder)
        decoder.scanner = subDecoder.scanner
        if let _ = try decoder.nextFieldNumber() {
          // Verbose any can never have additional keys
          throw TextFormatDecodingError.malformedText
        }
        return
      }
      // TODO: If we don't know the type, we should consider deferring the
      // decode as we do for JSON and Protobuf binary.
      throw TextFormatDecodingError.malformedText
    }

    // This is not using the specialized encoding, so we can use the
    // standard path to decode the binary value.
    try decodeMessage(decoder: &decoder)
  }

}
