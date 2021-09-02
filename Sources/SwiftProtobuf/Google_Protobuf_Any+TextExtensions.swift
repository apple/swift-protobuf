// Sources/SwiftProtobuf/Google_Protobuf_Any+TextExtensions.swift - Well-known Any type
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Extends the `Google_Protobuf_Any` type with various custom behaviors.
///
// -----------------------------------------------------------------------------

// Explicit import of Foundation is necessary on Linux,
// don't remove unless obsolete on all platforms
import Foundation

extension Google_Protobuf_Any {
  /// Creates a new `Google_Protobuf_Any` by decoding the given string
  /// containing a serialized message in Protocol Buffer text format.
  ///
  /// - Parameters:
  ///   - textFormatString: The text format string to decode.
  ///   - options: The `TextFormatDencodingOptions` to use.
  ///   - extensions: An `ExtensionMap` used to look up and decode any
  ///     extensions in this message or messages nested within this message's
  ///     fields.
  /// - Throws: an instance of `TextFormatDecodingError` on failure.
  public init(
    textFormatString: String,
    options: TextFormatDecodingOptions = TextFormatDecodingOptions(),
    extensions: ExtensionMap? = nil
  ) throws {
    self.init()
    if !textFormatString.isEmpty {
      if let data = textFormatString.data(using: String.Encoding.utf8) {
        try data.withUnsafeBytes { (body: UnsafeRawBufferPointer) in
          if let baseAddress = body.baseAddress, body.count > 0 {
            var textDecoder = try TextFormatDecoder(
              messageType: Google_Protobuf_Any.self,
              utf8Pointer: baseAddress,
              count: body.count,
              options: options,
              extensions: extensions)
            try decodeTextFormat(decoder: &textDecoder)
            if !textDecoder.complete {
              throw TextFormatDecodingError.trailingGarbage
            }
          }
        }
      }
    }
  }
}

extension Google_Protobuf_Any {
  internal func textTraverse(visitor: inout TextFormatEncodingVisitor) {
    _storage.textTraverse(visitor: &visitor)
    try! unknownFields.traverse(visitor: &visitor)
  }
}

extension Google_Protobuf_Any {
  // Custom text format decoding support for Any objects.
  // (Note: This is not a part of any protocol; it's invoked
  // directly from TextFormatDecoder whenever it sees an attempt
  // to decode an Any object)
  internal mutating func decodeTextFormat(
    decoder: inout TextFormatDecoder
  ) throws {
    // First, check if this uses the "verbose" Any encoding.
    // If it does, and we have the type available, we can
    // eagerly decode the contained Message object.
    if let url = try decoder.scanner.nextOptionalAnyURL() {
      try _uniqueStorage().decodeTextFormat(typeURL: url, decoder: &decoder)
    } else {
      // This is not using the specialized encoding, so we can use the
      // standard path to decode the binary value.
      // First, clear the fields so we don't waste time re-serializing
      // the previous contents as this instances get replaced with a
      // new value (can happen when a field name/number is repeated in
      // the TextFormat input).
      self.typeURL = ""
      self.value = Data()
      try decodeMessage(decoder: &decoder)
    }
  }
}

extension Google_Protobuf_Any: _CustomJSONCodable {
  internal func encodedJSONString(options: JSONEncodingOptions) throws -> String {
    return try _storage.encodedJSONString(options: options)
  }

  internal mutating func decodeJSON(from decoder: inout JSONDecoder) throws {
    try _uniqueStorage().decodeJSON(from: &decoder)
  }
}
