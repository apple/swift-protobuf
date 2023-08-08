//
// Sources/SwiftProtobuf/AsyncMessageSequence.swift - Async sequence over binary delimited protobuf
//
// Copyright (c) 2023 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// An async sequence of messages decoded from a binary delimited protobuf stream.
///
// -----------------------------------------------------------------------------

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
public struct AsyncMessageSequence<Base: AsyncSequence, M: Message>:
  AsyncSequence, AsyncIteratorProtocol where Base.Element == UInt8 {
  
  /// The message type in this asynchronous sequence.
  public typealias Element = M
  
  var iterator: Base.AsyncIterator?
  let extensions: ExtensionMap?
  let partial: Bool
  let options: BinaryDecodingOptions
  
  public init(
    baseSequence: Base,
    extensions: ExtensionMap? = nil,
    partial: Bool = false,
    options: BinaryDecodingOptions = BinaryDecodingOptions()
  ) {
    self.iterator = baseSequence.makeAsyncIterator()
    self.extensions = extensions
    self.partial = partial
    self.options = options
  }
  
  /// Aysnchronously reads the next varint
  mutating func nextVarInt() async throws -> UInt64? {
    var messageSize: UInt64 = 0
    var shift: UInt64 = 0
    
    while let byte = try await iterator?.next() {
      messageSize |= UInt64(byte & 0x7f) << shift
      shift += UInt64(7)
      if shift > 35 {
        throw BinaryDecodingError.malformedProtobuf
      }
      if (byte & 0x80 == 0) {
        return messageSize
      }
    }
    if (shift > 0) {
      // The stream has ended inside a varint.
      throw BinaryDecodingError.truncated
    }
    return nil // End of stream reached.
  }
  
  /// Asynchronously advances to the next message and returns it, or ends the
  /// sequence if there is no next message.
  ///
  /// - Returns: The next message, if it exists, or `nil` to signal the end of
  ///   the sequence.
  public mutating func next() async throws -> M? {
    guard let messageSize = try await nextVarInt() else {
      iterator = nil
      return nil
    }
    if messageSize == 0 {
      return try M(
        serializedBytes: [],
        extensions: extensions,
        partial: partial,
        options: options
      )
    } else if messageSize > 0x7fffffff {
      throw BinaryDecodingError.tooLarge
    }
    
    var buffer = [UInt8](repeating: 0, count: Int(messageSize))
    var consumedBytes = 0
    
    while let byte = try await iterator?.next() {
      buffer[consumedBytes] = byte
      consumedBytes += 1
      if consumedBytes == messageSize {
        return try M(
          serializedBytes: buffer,
          extensions: extensions,
          partial: partial,
          options: options
        )
      }
    }
    throw BinaryDecodingError.truncated // The buffer was not filled.
  }
  
  /// Creates the asynchronous iterator that produces elements of this
  /// asynchronous sequence.
  ///
  /// - Returns: An instance of the `AsyncIterator` type used to produce
  /// messages in the asynchronous sequence.
  public func makeAsyncIterator() -> AsyncMessageSequence {
    self
  }
}
