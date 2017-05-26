// Sources/SwiftProtobuf/Message+JSONAdditions.swift - JSON format primitive types
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Extensions to `Message` to support JSON encoding/decoding.
///
// -----------------------------------------------------------------------------

import Foundation

/// JSON encoding and decoding methods for messages.
public extension Message {
  /// Returns a string containing the JSON serialization of the message.
  ///
  /// Unlike binary encoding, presence of required fields is not enforced when
  /// serializing to JSON.
  ///
  /// - Returns: A string containing the JSON serialization of the message.
  /// - Throws: `JSONEncodingError` if encoding fails.
  func jsonString() throws -> String {
    let data = try jsonUTF8Data()
    return String(data: data, encoding: String.Encoding.utf8)!
  }

  /// Returns a Data containing the UTF-8 JSON serialization of the message.
  ///
  /// Unlike binary encoding, presence of required fields is not enforced when
  /// serializing to JSON.
  ///
  /// - Returns: A Data containing the JSON serialization of the message.
  /// - Throws: `JSONEncodingError` if encoding fails.
  func jsonUTF8Data() throws -> Data {
    if let m = self as? _CustomJSONCodable {
      let string = try m.encodedJSONString()
      let data = string.data(using: String.Encoding.utf8)! // Cannot fail!
      return data
    }
    var visitor = try JSONEncodingVisitor(message: self)
    visitor.startObject()
    try traverse(visitor: &visitor)
    visitor.endObject()
    return visitor.dataResult
  }

  /// Creates a new message by decoding the given string containing a
  /// serialized message in JSON format.
  ///
  /// - Parameter jsonString: The JSON-formatted string to decode.
  /// - Parameter options: The JSONDecodingOptions to use. If `nil` a
  ///   default instance will be used.
  /// - Throws: `JSONDecodingError` if decoding fails.
  public init(
    jsonString: String,
    options: JSONDecodingOptions = JSONDecodingOptions()
  ) throws {
    if jsonString.isEmpty {
      throw JSONDecodingError.truncated
    }
    if let data = jsonString.data(using: String.Encoding.utf8) {
      try self.init(jsonUTF8Data: data, options: options)
    } else {
      throw JSONDecodingError.truncated
    }
  }

  /// Creates a new message by decoding the given `Data` containing a
  /// serialized message in JSON format, interpreting the data as UTF-8 encoded
  /// text.
  ///
  /// - Parameter jsonUTF8Data: The JSON-formatted data to decode, represented
  ///   as UTF-8 encoded text.
  /// - Parameter options: The JSONDecodingOptions to use. If `nil` a
  ///   default instance will be used.
  /// - Throws: `JSONDecodingError` if decoding fails.
  public init(
    jsonUTF8Data: Data,
    options: JSONDecodingOptions = JSONDecodingOptions()
  ) throws {
    self.init()
    try jsonUTF8Data.withUnsafeBytes { (bytes:UnsafePointer<UInt8>) in
      let buffer = UnsafeBufferPointer(start: bytes, count: jsonUTF8Data.count)
      var decoder = JSONDecoder(source: buffer, options: options)
      if !decoder.scanner.skipOptionalNull() {
        try decoder.decodeFullObject(message: &self)
      } else if Self.self is _CustomJSONCodable.Type {
        if let message = try (Self.self as! _CustomJSONCodable.Type)
          .decodedFromJSONNull() {
          self = message as! Self
        } else {
          throw JSONDecodingError.illegalNull
        }
      }
      if !decoder.scanner.complete {
        throw JSONDecodingError.trailingGarbage
      }
    }
  }
}

