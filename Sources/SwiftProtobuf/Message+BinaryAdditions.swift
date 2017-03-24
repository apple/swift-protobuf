// Sources/SwiftProtobuf/Message+BinaryAdditions.swift - Per-type binary coding
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Extensions to `Message` to provide binary coding and decoding.
///
// -----------------------------------------------------------------------------

import Foundation

/// Binary encoding and decoding methods for messages.
public extension Message {
  /// Returns a `Data` value containing the Protocol Buffer binary format
  /// serialization of the message.
  ///
  /// - Parameters:
  ///   - partial: If `false` (the default), this method will check
  ///     `Message.isInitialized` before encoding to verify that all required
  ///     fields are present. If any are missing, this method throws
  ///     `BinaryEncodingError.missingRequiredFields`.
  /// - Returns: A `Data` value containing the binary serialization of the
  ///   message.
  /// - Throws: `BinaryEncodingError` if encoding fails.
  func serializedData(partial: Bool = false) throws -> Data {
    if !partial && !isInitialized {
      throw BinaryEncodingError.missingRequiredFields
    }
    let requiredSize = try serializedDataSize()
    var data = Data(count: requiredSize)
    try data.withUnsafeMutableBytes { (pointer: UnsafeMutablePointer<UInt8>) in
      try serializeBinary(into: pointer)
    }
    return data
  }

  private func serializeBinary(
    into pointer: UnsafeMutablePointer<UInt8>
  ) throws {
    var visitor = BinaryEncodingVisitor(forWritingInto: pointer)
    try traverse(visitor: &visitor)
  }

  /// Returns the size in bytes required to encode the message in binary format.
  /// This is used by `serializedData()` to precalculate the size of the buffer
  /// so that encoding can proceed without bounds checks or reallocation.
  internal func serializedDataSize() throws -> Int {
    // Note: since this api is internal, it doesn't currently worry about
    // needing a partial argument to handle proto2 syntax required fields.
    // If this become public, it will need that added.
    var visitor = BinaryEncodingSizeVisitor()
    try traverse(visitor: &visitor)
    return visitor.serializedSize
  }

  /// Creates a new message by decoding the given `Data` value containing a
  /// serialized message in Protocol Buffer binary format.
  ///
  /// - Parameters:
  ///   - serializedData: The binary-encoded message data to decode.
  ///   - extensions: An `ExtensionMap` used to look up and decode any
  ///     extensions in this message or messages nested within this message's
  ///     fields.
  ///   - partial: If `false` (the default), this method will check
  ///     `Message.isInitialized` before encoding to verify that all required
  ///     fields are present. If any are missing, this method throws
  ///     `BinaryEncodingError.missingRequiredFields`.
  /// - Throws: `BinaryDecodingError` if decoding fails.
  init(
    serializedData data: Data,
    extensions: ExtensionMap? = nil,
    partial: Bool = false
  ) throws {
    self.init()
    try merge(serializedData: data, extensions: extensions, partial: partial)
  }

  /// Updates the message by decoding the given `Data` value containing a
  /// serialized message in Protocol Buffer binary format into the receiver.
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
  ///     `Message.isInitialized` before encoding to verify that all required
  ///     fields are present. If any are missing, this method throws
  ///     `BinaryEncodingError.missingRequiredFields`.
  /// - Throws: `BinaryDecodingError` if decoding fails.
  mutating func merge(
    serializedData data: Data,
    extensions: ExtensionMap? = nil,
    partial: Bool = false
  ) throws {
    if !data.isEmpty {
      try data.withUnsafeBytes { (pointer: UnsafePointer<UInt8>) in
        try _protobuf_mergeSerializedBytes(from: pointer,
                                           count: data.count,
                                           extensions: extensions)
      }
    }
    if !partial && !isInitialized {
      throw BinaryDecodingError.missingRequiredFields
    }
  }

  /// SwiftProtobuf Internal: Common support for decoding.
  internal mutating func _protobuf_mergeSerializedBytes(
    from bytes: UnsafePointer<UInt8>,
    count: Int,
    extensions: ExtensionMap?
  ) throws {
    var decoder = BinaryDecoder(forReadingFrom: bytes, count: count, extensions: extensions)
    try decodeMessage(decoder: &decoder)
    guard decoder.complete else {
      throw BinaryDecodingError.trailingGarbage
    }
    if let unknownData = decoder.unknownData {
      unknownFields.append(protobufData: unknownData)
    }
  }
}
