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
extension Message {
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
  public func serializedData(partial: Bool = false) throws -> Data {
    if !partial && !isInitialized {
      throw BinaryEncodingError.missingRequiredFields
    }
    let requiredSize = try serializedBinarySize()
    var data = Data(count: requiredSize)
    try data.withUnsafeMutableBytes { (body: UnsafeMutableRawBufferPointer) in
      let bytesWritten = try self.serializeBinary(into: body, partial: partial)

      // Currently not exposing this from the api because it really would be
      // an internal error in the library and should never happen.
      assert(requiredSize == bytesWritten)
    }
    return data
  }

  /// Returns the size in bytes required to encode the message in binary format.
  ///
  /// This should be used with `serializeBytes(into:partial:)` so that enough space may
  /// be allocated for the buffer so that encoding can proceed without bounds checks
  /// or reallocation.
  public func serializedBinarySize() throws -> Int {
    // Note: since this api is internal, it doesn't currently worry about
    // needing a partial argument to handle proto2 syntax required fields.
    // If this become public, it will need that added.
    var visitor = BinaryEncodingSizeVisitor()
    try traverse(visitor: &visitor)
    return visitor.serializedSize
  }

  /// Writes the message in the Protocol Buffer binary format into the given buffer.
  ///
  /// - Parameters:
  ///   - buffer: An `UnsafeMutableRawBufferPointer` into which the serialized message
  ///     will be written. The buffer should be at least `serializedDataSize()` bytes
  ///     in size.
  ///   - partial: If `false` (the default), this method will check
  ///     `Message.isInitialized` before encoding to verify that all required
  ///     fields are present. If any are missing, this method throws
  ///     `BinaryEncodingError.missingRequiredFields`.
  /// - Returns: The number of bytes written into the buffer.
  /// - Throws: `BinaryEncodingError` if encoding fails.
  @discardableResult
  public func serializeBinary(into buffer: UnsafeMutableRawBufferPointer, partial: Bool = false) throws -> Int {
    if !partial && !isInitialized {
      throw BinaryEncodingError.missingRequiredFields
    }
    guard let baseAddress = buffer.baseAddress, buffer.count > 0 else {
      return 0
    }

    let pointer = baseAddress.assumingMemoryBound(to: UInt8.self)
    var visitor = BinaryEncodingVisitor(forWritingInto: pointer)
    try traverse(visitor: &visitor)

    return visitor.encoder.distance(pointer: pointer)
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
  ///   - options: The BinaryDecodingOptions to use.
  /// - Throws: `BinaryDecodingError` if decoding fails.
  public init(
    serializedData data: Data,
    extensions: ExtensionMap? = nil,
    partial: Bool = false,
    options: BinaryDecodingOptions = BinaryDecodingOptions()
  ) throws {
    self.init()
    try merge(serializedData: data, extensions: extensions, partial: partial, options: options)
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
  ///     `Message.isInitialized` after decoding to verify that all required
  ///     fields are present. If any are missing, this method throws
  ///     `BinaryDecodingError.missingRequiredFields`.
  ///   - options: The BinaryDecodingOptions to use.
  /// - Throws: `BinaryDecodingError` if decoding fails.
  public mutating func merge(
    serializedData data: Data,
    extensions: ExtensionMap? = nil,
    partial: Bool = false,
    options: BinaryDecodingOptions = BinaryDecodingOptions()
  ) throws {
    if !data.isEmpty {
      try data.withUnsafeBytes { (body: UnsafeRawBufferPointer) in
        try self.merge(body: body, extensions: extensions, options: options)
      }
    }
    if !partial && !isInitialized {
      throw BinaryDecodingError.missingRequiredFields
    }
  }

  /// Creates a new message by decoding the given bytes containing a
  /// serialized message in Protocol Buffer binary format.
  ///
  /// - Parameters:
  ///   - body: The binary-encoded message buffer to decode.
  ///   - extensions: An `ExtensionMap` used to look up and decode any
  ///     extensions in this message or messages nested within this message's
  ///     fields.
  ///   - partial: If `false` (the default), this method will check
  ///     `Message.isInitialized` after decoding to verify that all required
  ///     fields are present. If any are missing, this method throws
  ///     `BinaryDecodingError.missingRequiredFields`.
  ///   - options: The BinaryDecodingOptions to use.
  /// - Throws: `BinaryDecodingError` if decoding fails.
  public init(
    body: UnsafeRawBufferPointer,
    extensions: ExtensionMap? = nil,
    partial: Bool = false,
    options: BinaryDecodingOptions = BinaryDecodingOptions()
  ) throws {
    self.init()
    try merge(body: body, extensions: extensions, partial: partial, options: options)
  }

  /// Updates the message by decoding the given `buffer` value containing a
  /// serialized message in Protocol Buffer binary format into the receiver.
  ///
  /// - Note: If this method throws an error, the message may still have been
  ///   partially mutated by the binary data that was decoded before the error
  ///   occurred.
  ///
  /// - Parameters:
  ///   - buffer: The binary-encoded message data to decode.
  ///   - extensions: An `ExtensionMap` used to look up and decode any
  ///     extensions in this message or messages nested within this message's
  ///     fields.
  ///   - partial: If `false` (the default), this method will check
  ///     `Message.isInitialized` after decoding to verify that all required
  ///     fields are present. If any are missing, this method throws
  ///     `BinaryDecodingError.missingRequiredFields`.
  ///   - options: The BinaryDecodingOptions to use.
  /// - Throws: `BinaryDecodingError` if decoding fails.
  public mutating func merge(
    body: UnsafeRawBufferPointer,
    extensions: ExtensionMap? = nil,
    partial: Bool = false,
    options: BinaryDecodingOptions = BinaryDecodingOptions()
  ) throws {
    try self.merge(body: body, extensions: extensions, options: options)
    if !partial && !isInitialized {
      throw BinaryDecodingError.missingRequiredFields
    }
  }

  /// Updates the message by decoding the given `buffer` value containing a
  /// serialized message in Protocol Buffer binary format into the receiver.
  private mutating func merge(
    body: UnsafeRawBufferPointer,
    extensions: ExtensionMap?,
    options: BinaryDecodingOptions
  ) throws {
    if let baseAddress = body.baseAddress, body.count > 0 {
      let pointer = baseAddress.assumingMemoryBound(to: UInt8.self)
      var decoder = BinaryDecoder(forReadingFrom: pointer,
                                  count: body.count,
                                  options: options,
                                  extensions: extensions)
      try decoder.decodeFullMessage(message: &self)
    }
  }
}
