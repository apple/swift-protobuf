// Sources/SwiftProtobuf/Message+BinaryAdditions_Data.swift - Per-type binary coding
//
// Copyright (c) 2022 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Extensions to `Message` to provide binary coding and decoding using ``Foundation/Data``.
///
// -----------------------------------------------------------------------------

import Foundation

/// Binary encoding and decoding methods for messages.
extension Message {
  /// Creates a new message by decoding the given `Data` value
  /// containing a serialized message in Protocol Buffer binary format.
  ///
  /// - Parameters:
  ///   - serializedData: The binary-encoded message data to decode.
  ///   - extensions: An `ExtensionMap` used to look up and decode any
  ///     extensions in this message or messages nested within this message's
  ///     fields.
  ///   - partial: If `false` (the default), this method will check
  ///     `Message.isInitialized` after decoding to verify that all required
  ///     fields are present. If any are missing, this method throws
  ///     `BinaryDecodingError.missingRequiredFields`.
  ///   - options: The BinaryDecodingOptions to use.
  /// - Throws: `BinaryDecodingError` if decoding fails.
  @inlinable
  public init(
    serializedData data: Data,
    extensions: (any ExtensionMap)? = nil,
    partial: Bool = false,
    options: BinaryDecodingOptions = BinaryDecodingOptions()
  ) throws {
    self.init()
    try merge(serializedBytes: data, extensions: extensions, partial: partial, options: options)
  }

  /// Updates the message by decoding the given `Data` value
  /// containing a serialized message in Protocol Buffer binary format into the
  /// receiver.
  ///
  /// - Note: If this method throws an error, the message may still have been
  ///   partially mutated by the binary data that was decoded before the error
  ///   occurred.
  ///
  /// - Parameters:
  ///   - serializedData: The binary-encoded message data to decode.
  ///   - extensions: An `ExtensionMap` used to look up and decode any
  ///     extensions in this message or messages nested within this message's
  ///     fields.
  ///   - partial: If `false` (the default), this method will check
  ///     `Message.isInitialized` after decoding to verify that all required
  ///     fields are present. If any are missing, this method throws
  ///     `BinaryDecodingError.missingRequiredFields`.
  ///   - options: The `BinaryDecodingOptions` to use.
  /// - Throws: `BinaryDecodingError` if decoding fails.
  @inlinable
  public mutating func merge(
    serializedData data: Data,
    extensions: (any ExtensionMap)? = nil,
    partial: Bool = false,
    options: BinaryDecodingOptions = BinaryDecodingOptions()
  ) throws {
    try merge(serializedBytes: data, extensions: extensions, partial: partial, options: options)
  }

  /// Returns a `Data` instance containing the Protocol Buffer binary
  /// format serialization of the message.
  ///
  /// - Parameters:
  ///   - partial: If `false` (the default), this method will check
  ///     `Message.isInitialized` before encoding to verify that all required
  ///     fields are present. If any are missing, this method throws
  ///     `BinaryEncodingError.missingRequiredFields`.
  ///   - options: The `BinaryEncodingOptions` to use.
  /// - Returns: A `Data` instance containing the binary serialization of the message.
  /// - Throws: `BinaryEncodingError` if encoding fails.
  public func serializedData(
    partial: Bool = false, 
    options: BinaryEncodingOptions = BinaryEncodingOptions()
  ) throws -> Data {
    try serializedBytes(partial: partial, options: options)
  }
}
