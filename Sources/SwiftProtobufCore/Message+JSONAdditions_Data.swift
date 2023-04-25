// Sources/SwiftProtobufCore/Message+JSONAdditions_Data.swift - JSON format primitive types
//
// Copyright (c) 2022 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Extensions to `Message` to support JSON encoding/decoding  using ``Foundation/Data``.
///
// -----------------------------------------------------------------------------

import Foundation

/// JSON encoding and decoding methods for messages.
extension Message {
  /// Creates a new message by decoding the given `Data` containing a serialized message
  /// in JSON format, interpreting the data as UTF-8 encoded text.
  ///
  /// - Parameter jsonUTF8Data: The JSON-formatted data to decode, represented
  ///   as UTF-8 encoded text.
  /// - Parameter options: The JSONDecodingOptions to use.
  /// - Throws: `JSONDecodingError` if decoding fails.
  public init(
    jsonUTF8Data: Data,
    options: JSONDecodingOptions = JSONDecodingOptions()
  ) throws {
    try self.init(jsonUTF8Bytes: jsonUTF8Data, extensions: nil, options: options)
  }

  /// Creates a new message by decoding the given `Data` containing a serialized message
  /// in JSON format, interpreting the data as UTF-8 encoded text.
  ///
  /// - Parameter jsonUTF8Data: The JSON-formatted data to decode, represented
  ///   as UTF-8 encoded text.
  /// - Parameter extensions: The extension map to use with this decode
  /// - Parameter options: The JSONDecodingOptions to use.
  /// - Throws: `JSONDecodingError` if decoding fails.
  public init(
    jsonUTF8Data: Data,
    extensions: ExtensionMap? = nil,
    options: JSONDecodingOptions = JSONDecodingOptions()
  ) throws {
    try self.init(jsonUTF8Bytes: jsonUTF8Data, extensions: extensions, options: options)
  }
}

