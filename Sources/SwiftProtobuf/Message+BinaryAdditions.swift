// Sources/SwiftProtobuf/Message+BinaryAdditions.swift - Per-type binary coding
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Extensions to `Message` to provide binary coding and decoding.
///
// -----------------------------------------------------------------------------

import Foundation

/// Binary encoding and decoding methods for messages.
extension Message {
    /// Returns a ``SwiftProtobufContiguousBytes`` instance containing the Protocol Buffer binary
    /// format serialization of the message.
    ///
    /// - Parameters:
    ///   - partial: If `false` (the default), this method will check
    ///     `Message.isInitialized` before encoding to verify that all required
    ///     fields are present. If any are missing, this method throws.
    ///     ``BinaryEncodingError/missingRequiredFields``.
    ///   - options: The ``BinaryEncodingOptions`` to use.
    /// - Returns: A ``SwiftProtobufContiguousBytes`` instance containing the binary serialization
    /// of the message.
    ///
    /// - Throws: ``SwiftProtobufError`` or ``BinaryEncodingError`` if encoding fails.
    public func serializedBytes<Bytes: SwiftProtobufContiguousBytes>(
        partial: Bool = false,
        options: BinaryEncodingOptions = BinaryEncodingOptions()
    ) throws -> Bytes {
        return try storageForRuntime.serializedBytes(partial: partial, options: options)
    }

    internal func serializedDataSize() throws -> Int {
        fatalError("no longer used")
    }

    /// Creates a new message by decoding the given `SwiftProtobufContiguousBytes` value
    /// containing a serialized message in Protocol Buffer binary format.
    ///
    /// - Parameters:
    ///   - bytes: The binary-encoded message data to decode.
    ///   - extensions: An ``ExtensionMap`` used to look up and decode any
    ///     extensions in this message or messages nested within this message's
    ///     fields.
    ///   - partial: If `false` (the default), this method will check
    ///     ``Message/isInitialized-6abgi`` after decoding to verify that all required
    ///     fields are present. If any are missing, this method throws
    ///     ``BinaryDecodingError/missingRequiredFields``.
    ///   - options: The ``BinaryDecodingOptions`` to use.
    /// - Throws: ``BinaryDecodingError`` if decoding fails.
    @inlinable
    public init<Bytes: SwiftProtobufContiguousBytes>(
        serializedBytes bytes: Bytes,
        extensions: ExtensionMap? = nil,
        partial: Bool = false,
        options: BinaryDecodingOptions = BinaryDecodingOptions()
    ) throws {
        self.init()
        try merge(serializedBytes: bytes, extensions: extensions, partial: partial, options: options)
    }

    #if compiler(>=6.2)
    /// Creates a new message by decoding the bytes provided by a `RawSpan`
    /// containing a serialized message in Protocol Buffer binary format.
    ///
    /// - Parameters:
    ///   - bytes: The `RawSpan` of binary-encoded message data to decode.
    ///   - extensions: An ``ExtensionMap`` used to look up and decode any
    ///     extensions in this message or messages nested within this message's
    ///     fields.
    ///   - partial: If `false` (the default), this method will check
    ///     ``Message/isInitialized-6abgi`` after decoding to verify that all required
    ///     fields are present. If any are missing, this method throws
    ///     ``BinaryDecodingError/missingRequiredFields``.
    ///   - options: The ``BinaryDecodingOptions`` to use.
    /// - Throws: ``BinaryDecodingError`` if decoding fails.
    @inlinable
    @available(macOS 10.14.4, iOS 12.2, watchOS 5.2, tvOS 12.2, visionOS 1.0, *)
    public init(
        serializedBytes bytes: RawSpan,
        extensions: ExtensionMap? = nil,
        partial: Bool = false,
        options: BinaryDecodingOptions = BinaryDecodingOptions()
    ) throws {
        self.init()
        try merge(serializedBytes: bytes, extensions: extensions, partial: partial, options: options)
    }
    #endif

    /// Updates the message by decoding the given `SwiftProtobufContiguousBytes` value
    /// containing a serialized message in Protocol Buffer binary format into the
    /// receiver.
    ///
    /// - Note: If this method throws an error, the message may still have been
    ///   partially mutated by the binary data that was decoded before the error
    ///   occurred.
    ///
    /// - Parameters:
    ///   - bytes: The binary-encoded message data to decode.
    ///   - extensions: An ``ExtensionMap`` used to look up and decode any
    ///     extensions in this message or messages nested within this message's
    ///     fields.
    ///   - partial: If `false` (the default), this method will check
    ///     ``Message/isInitialized-6abgi`` after decoding to verify that all required
    ///     fields are present. If any are missing, this method throws
    ///     ``BinaryDecodingError/missingRequiredFields``.
    ///   - options: The ``BinaryDecodingOptions`` to use.
    /// - Throws: ``BinaryDecodingError`` if decoding fails.
    @inlinable
    public mutating func merge<Bytes: SwiftProtobufContiguousBytes>(
        serializedBytes bytes: Bytes,
        extensions: ExtensionMap? = nil,
        partial: Bool = false,
        options: BinaryDecodingOptions = BinaryDecodingOptions()
    ) throws {
        try bytes.withUnsafeBytes { (body: UnsafeRawBufferPointer) in
            try _merge(rawBuffer: body, extensions: extensions, partial: partial, options: options)
        }
    }

    #if compiler(>=6.2)
    /// Updates the message by decoding the bytes provided by a `RawSpan` containing
    /// a serialized message in Protocol Buffer binary format into the receiver.
    ///
    /// - Note: If this method throws an error, the message may still have been
    ///   partially mutated by the binary data that was decoded before the error
    ///   occurred.
    ///
    /// - Parameters:
    ///   - bytes: The `RawSpan` of binary-encoded message data to decode.
    ///   - extensions: An ``ExtensionMap`` used to look up and decode any
    ///     extensions in this message or messages nested within this message's
    ///     fields.
    ///   - partial: If `false` (the default), this method will check
    ///     ``Message/isInitialized-6abgi`` after decoding to verify that all required
    ///     fields are present. If any are missing, this method throws
    ///     ``BinaryDecodingError/missingRequiredFields``.
    ///   - options: The ``BinaryDecodingOptions`` to use.
    /// - Throws: ``BinaryDecodingError`` if decoding fails.
    @inlinable
    @available(macOS 10.14.4, iOS 12.2, watchOS 5.2, tvOS 12.2, visionOS 1.0, *)
    public mutating func merge(
        serializedBytes bytes: RawSpan,
        extensions: ExtensionMap? = nil,
        partial: Bool = false,
        options: BinaryDecodingOptions = BinaryDecodingOptions()
    ) throws {
        try bytes.withUnsafeBytes { (body: UnsafeRawBufferPointer) in
            try _merge(rawBuffer: body, extensions: extensions, partial: partial, options: options)
        }
    }
    #endif

    // Helper for `merge()`s to keep the Decoder internal to SwiftProtobuf while
    // allowing the generic over `SwiftProtobufContiguousBytes` to get better codegen from the
    // compiler by being `@inlinable`. For some discussion on this see
    // https://github.com/apple/swift-protobuf/pull/914#issuecomment-555458153
    @usableFromInline
    mutating func _merge(
        rawBuffer body: UnsafeRawBufferPointer,
        extensions: ExtensionMap?,
        partial: Bool,
        options: BinaryDecodingOptions
    ) throws {
        _protobuf_ensureUniqueStorage(accessToken: _MessageStorageToken())
        try storageForRuntime.merge(byReadingFrom: body, extensions: extensions, partial: partial, options: options)
    }
}
