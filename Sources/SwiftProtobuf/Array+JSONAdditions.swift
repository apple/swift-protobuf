// Sources/SwiftProtobuf/Array+JSONAdditions.swift - JSON format primitive types
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Extensions to `Array` to support JSON encoding/decoding.
///
// -----------------------------------------------------------------------------

import Foundation

/// JSON encoding and decoding methods for arrays of messages.
public extension Array where Iterator.Element: Message {
  /// Returns a string containing the JSON serialization of the messages.
  ///
  /// Unlike binary encoding, presence of required fields is not enforced when
  /// serializing to JSON.
  ///
  /// - Returns: A string containing the JSON serialization of the messages.
  /// - Throws: `JSONEncodingError` if encoding fails.
  func jsonString() throws -> String {
    let data = try jsonUTF8Data()
    return String(data: data, encoding: String.Encoding.utf8)!
  }

  /// Returns a Data containing the UTF-8 JSON serialization of the messages.
  ///
  /// Unlike binary encoding, presence of required fields is not enforced when
  /// serializing to JSON.
  ///
  /// - Returns: A Data containing the JSON serialization of the messages.
  /// - Throws: `JSONEncodingError` if encoding fails.
  func jsonUTF8Data() throws -> Data {
    var visitor = try JSONEncodingVisitor(type: Iterator.Element.self)
    visitor.startArray()
    for v in self {
        visitor.startObject()
        try v.traverse(visitor: &visitor)
        visitor.endObject()
    }
    visitor.endArray()
    return visitor.dataResult
  }

  /// Creates a new array of messages by decoding the given string containing a
  /// serialized array of messages in JSON format.
  ///
  /// - Parameter jsonString: The JSON-formatted string to decode.
  /// - Throws: `JSONDecodingError` if decoding fails.
  public init(jsonString: String) throws {
    if jsonString.isEmpty {
      throw JSONDecodingError.truncated
    }
    if let data = jsonString.data(using: String.Encoding.utf8) {
      try self.init(jsonUTF8Data: data)
    } else {
      throw JSONDecodingError.truncated
    }
  }

  /// Creates a new array of messages by decoding the given `Data` containing a
  /// serialized array of messages in JSON format, interpreting the data as
  /// UTF-8 encoded text.
  ///
  /// - Parameter jsonUTF8Data: The JSON-formatted data to decode, represented
  ///   as UTF-8 encoded text.
  /// - Throws: `JSONDecodingError` if decoding fails.
  public init(jsonUTF8Data: Data) throws {
    self.init()
    try jsonUTF8Data.withUnsafeBytes { (bytes:UnsafePointer<UInt8>) in
      let buffer = UnsafeBufferPointer(start: bytes, count: jsonUTF8Data.count)
      var decoder = JSONDecoder(source: buffer)
      try decoder.decodeRepeatedMessageField(value: &self)
      if !decoder.scanner.complete {
        throw JSONDecodingError.trailingGarbage
      }
    }
  }

}
