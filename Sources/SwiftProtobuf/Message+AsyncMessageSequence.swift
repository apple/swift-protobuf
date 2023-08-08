//
// Sources/SwiftProtobuf/Message+AsyncMessageSequence.swift - Async sequence over binary delimited protobuf
//
// Copyright (c) 2023 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Extensions to `Message` to provide an async sequence over a binary delimited protobuf stream.
///
// -----------------------------------------------------------------------------

import Foundation

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
extension Message {
  
  /// Creates an asynchronous sequence of messages decoded from resource bytes
  public static func asyncSequence(
    asyncBytes: URL.AsyncBytes,
    extensions: ExtensionMap? = nil,
    partial: Bool = false,
    options: BinaryDecodingOptions = BinaryDecodingOptions()
  ) -> AsyncMessageSequence<Self> {
    let messageFactory = MessageFactory<Self>(
      extensions: extensions,
      partial: partial,
      options: options
    )
    return AsyncMessageSequence(
      asyncBytesIterator: asyncBytes.makeAsyncIterator(),
      messageFactory: messageFactory
    )
  }
}

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
public struct AsyncMessageSequence<M: Message> : AsyncSequence, Sendable {
  
  let asyncBytesIterator: URL.AsyncBytes.AsyncIterator
  fileprivate let messageFactory: MessageFactory<M>
  
  /// The message type in this asynchronous sequence.
  public typealias Element = M
  
  /// An asynchronous iterator that produces the messages of this asynchronous sequence
  public struct AsyncIterator : AsyncIteratorProtocol, Sendable {
    
    public var iter: URL.AsyncBytes.AsyncIterator
    fileprivate let messageFactory: MessageFactory<M>
    
    /// Aysnchronously reads the next varint
    @inlinable public mutating func nextVarInt() async throws -> UInt64? {
      var messageSize: UInt64 = 0
      var shift: UInt64 = 0
      
      while let byte = try await iter.next() {
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
        return nil
      }
      if messageSize == 0 {
        return try messageFactory.createMesssage(serializedBytes: [])
      } else if messageSize > 0x7fffffff {
        throw BinaryDecodingError.tooLarge
      }
      
      var buffer = [UInt8](repeating: 0, count: Int(messageSize))
      var consumedBytes = 0
      
      while let byte = try await iter.next() {
        buffer[consumedBytes] = byte
        consumedBytes += 1
        if consumedBytes == messageSize {
          return try messageFactory.createMesssage(serializedBytes: buffer)
        }
      }
      throw BinaryDecodingError.truncated // The buffer was not filled.
    }
    
    public typealias Element = M
  }
  
  /// Creates the asynchronous iterator that produces elements of this
  /// asynchronous sequence.
  ///
  /// - Returns: An instance of the `AsyncIterator` type used to produce
  /// messages in the asynchronous sequence.
  public func makeAsyncIterator() -> AsyncMessageSequence.AsyncIterator {
    return AsyncIterator(
      iter: asyncBytesIterator,
      messageFactory: messageFactory
    )
  }
}

// Currently neither ExtensionMap nor BinaryDecodingOptions are Sendable
// hence the @unchecked to suppress warnings
fileprivate struct MessageFactory<M: Message>: @unchecked Sendable {
  let extensions: ExtensionMap?
  let partial: Bool
  let options: BinaryDecodingOptions
  
  func createMesssage(serializedBytes: [UInt8]) throws -> M {
    try M(
      serializedBytes: serializedBytes,
      extensions: extensions,
      options: options
    )
  }
}
