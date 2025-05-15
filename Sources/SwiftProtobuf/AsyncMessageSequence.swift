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

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension AsyncSequence where Element == UInt8 {
    /// Creates an asynchronous sequence of size-delimited messages from this sequence of bytes.
    /// Delimited format allows a single file or stream to contain multiple messages. A delimited message
    /// is a varint encoding the message size followed by a message of exactly that size.
    ///
    /// - Parameters:
    ///   - messageType: The type of message to read.
    ///   - extensions: An ``ExtensionMap`` used to look up and decode any extensions in
    ///    messages encoded by this sequence, or in messages nested within these messages.
    ///   - partial: If `false` (the default),  after decoding a message, ``Message/isInitialized-6abgi`
    ///     will be checked to ensure all fields are present.
    ///   - options: The ``BinaryDecodingOptions`` to use.
    /// - Returns: An asynchronous sequence of messages read from the `AsyncSequence` of bytes.
    @inlinable
    public func binaryProtobufDelimitedMessages<M: Message>(
        of messageType: M.Type = M.self,
        extensions: (any ExtensionMap)? = nil,
        partial: Bool = false,
        options: BinaryDecodingOptions = BinaryDecodingOptions()
    ) -> AsyncMessageSequence<Self, M> {
        AsyncMessageSequence<Self, M>(
            base: self,
            extensions: extensions,
            partial: partial,
            options: options
        )
    }
}

/// An asynchronous sequence of messages decoded from an asynchronous sequence of bytes.
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public struct AsyncMessageSequence<
    Base: AsyncSequence,
    M: Message
>: AsyncSequence where Base.Element == UInt8 {

    /// The message type in this asynchronous sequence.
    public typealias Element = M

    private let base: Base
    private let extensions: (any ExtensionMap)?
    private let partial: Bool
    private let options: BinaryDecodingOptions

    /// Reads size-delimited messages from the given sequence of bytes. Delimited
    /// format allows a single file or stream to contain multiple messages. A delimited message
    /// is a varint encoding the message size followed by a message of exactly that size.
    ///
    /// - Parameters:
    ///   - baseSequence: The `AsyncSequence` to read messages from.
    ///   - extensions: An ``ExtensionMap`` used to look up and decode any extensions in
    ///    messages encoded by this sequence, or in messages nested within these messages.
    ///   - partial: If `false` (the default), after decoding a message, ``Message/isInitialized-6abgi``
    ///     will be checked to ensure all fields are present.
    ///   - options: The ``BinaryDecodingOptions`` to use.
    /// - Returns: An asynchronous sequence of messages read from the `AsyncSequence` of bytes.
    public init(
        base: Base,
        extensions: (any ExtensionMap)? = nil,
        partial: Bool = false,
        options: BinaryDecodingOptions = BinaryDecodingOptions()
    ) {
        self.base = base
        self.extensions = extensions
        self.partial = partial
        self.options = options
    }

    /// An asynchronous iterator that produces the messages of this asynchronous sequence.
    public struct AsyncIterator: AsyncIteratorProtocol {
        @usableFromInline
        var iterator: Base.AsyncIterator?
        @usableFromInline
        let extensions: (any ExtensionMap)?
        @usableFromInline
        let partial: Bool
        @usableFromInline
        let options: BinaryDecodingOptions

        init(
            iterator: Base.AsyncIterator,
            extensions: (any ExtensionMap)?,
            partial: Bool,
            options: BinaryDecodingOptions
        ) {
            self.iterator = iterator
            self.extensions = extensions
            self.partial = partial
            self.options = options
        }

        /// Asynchronously reads the next varint.
        @inlinable
        mutating func nextVarInt() async throws -> UInt64? {
            var messageSize: UInt64 = 0
            var shift: UInt64 = 0

            while let byte = try await iterator?.next() {
                messageSize |= UInt64(byte & 0x7f) << shift
                shift += UInt64(7)
                if shift > 35 {
                    iterator = nil
                    throw SwiftProtobufError.BinaryStreamDecoding.malformedLength()
                }
                if byte & 0x80 == 0 {
                    return messageSize
                }
            }
            if shift > 0 {
                // The stream has ended inside a varint.
                iterator = nil
                throw BinaryDelimited.Error.truncated
            }
            return nil  // End of stream reached.
        }

        /// Helper to read the given number of bytes.
        @usableFromInline
        mutating func readBytes(_ size: Int) async throws -> [UInt8] {
            // Even though the bytes are read in chunks, things can still hard fail if
            // there isn't enough memory to append to have all the bytes at once for
            // parsing; but this at least catches some possible OOM attacks.
            var bytesNeeded = size
            var buffer = [UInt8]()
            let kChunkSize = 16 * 1024 * 1024
            var chunk = [UInt8](repeating: 0, count: Swift.min(bytesNeeded, kChunkSize))
            while bytesNeeded > 0 {
                var consumedBytes = 0
                let maxLength = Swift.min(bytesNeeded, chunk.count)
                while consumedBytes < maxLength {
                    guard let byte = try await iterator?.next() else {
                        // The iterator hit the end, but the chunk wasn't filled, so the full
                        // payload wasn't read.
                        throw BinaryDelimited.Error.truncated
                    }
                    chunk[consumedBytes] = byte
                    consumedBytes += 1
                }
                if consumedBytes < chunk.count {
                    buffer += chunk[0..<consumedBytes]
                } else {
                    buffer += chunk
                }
                bytesNeeded -= maxLength
            }
            return buffer
        }

        /// Asynchronously advances to the next message and returns it, or ends the
        /// sequence if there is no next message.
        ///
        /// - Returns: The next message, if it exists, or `nil` to signal the end of
        ///   the sequence.
        @inlinable
        public mutating func next() async throws -> M? {
            guard let messageSize = try await nextVarInt() else {
                iterator = nil
                return nil
            }
            guard messageSize <= UInt64(0x7fff_ffff) else {
                iterator = nil
                throw SwiftProtobufError.BinaryDecoding.tooLarge()
            }
            if messageSize == 0 {
                return try M(
                    serializedBytes: [],
                    extensions: extensions,
                    partial: partial,
                    options: options
                )
            }
            let buffer = try await readBytes(Int(messageSize))
            return try M(
                serializedBytes: buffer,
                extensions: extensions,
                partial: partial,
                options: options
            )
        }
    }

    /// Creates the asynchronous iterator that produces elements of this
    /// asynchronous sequence.
    ///
    /// - Returns: An instance of the `AsyncIterator` type used to produce
    /// messages in the asynchronous sequence.
    public func makeAsyncIterator() -> AsyncMessageSequence.AsyncIterator {
        AsyncIterator(
            iterator: base.makeAsyncIterator(),
            extensions: extensions,
            partial: partial,
            options: options
        )
    }
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension AsyncMessageSequence: Sendable where Base: Sendable {}

@available(*, unavailable)
extension AsyncMessageSequence.AsyncIterator: Sendable {}
