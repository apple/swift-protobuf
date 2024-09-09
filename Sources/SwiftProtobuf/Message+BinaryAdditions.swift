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
        if !partial && !isInitialized {
            throw BinaryEncodingError.missingRequiredFields
        }

        // Note that this assumes `options` will not change the required size.
        let requiredSize = try serializedDataSize()

        // Messages have a 2GB limit in encoded size, the upstread C++ code
        // (message_lite, etc.) does this enforcement also.
        // https://protobuf.dev/programming-guides/encoding/#cheat-sheet
        //
        // Testing here enables the limit without adding extra conditionals to all
        // the places that encode message fields (or strings/bytes fields), keeping
        // the overhead of the check to a minimum.
        guard requiredSize < 0x7fff_ffff else {
            // Adding a new error is a breaking change.
            throw BinaryEncodingError.missingRequiredFields
        }

        var data = Bytes(repeating: 0, count: requiredSize)
        try data.withUnsafeMutableBytes { (body: UnsafeMutableRawBufferPointer) in
            var visitor = BinaryEncodingVisitor(forWritingInto: body, options: options)
            try traverse(visitor: &visitor)
            // Currently not exposing this from the api because it really would be
            // an internal error in the library and should never happen.
            assert(visitor.encoder.remainder.count == 0)
        }
        return data
    }

    /// Returns the size in bytes required to encode the message in binary format.
    /// This is used by `serializedData()` to precalculate the size of the buffer
    /// so that encoding can proceed without bounds checks or reallocation.
    internal func serializedDataSize() throws -> Int {
        // Note: since this api is internal, it doesn't currently worry about
        // needing a partial argument to handle required fields. If this become
        // public, it will need that added.
        var visitor = BinaryEncodingSizeVisitor()
        try traverse(visitor: &visitor)
        return visitor.serializedSize
    }

    /// Creates a new message by decoding the given `SwiftProtobufContiguousBytes` value
    /// containing a serialized message in Protocol Buffer binary format.
    ///
    /// - Parameters:
    ///   - serializedBytes: The binary-encoded message data to decode.
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
        extensions: (any ExtensionMap)? = nil,
        partial: Bool = false,
        options: BinaryDecodingOptions = BinaryDecodingOptions()
    ) throws {
        self.init()
        try merge(serializedBytes: bytes, extensions: extensions, partial: partial, options: options)
    }

    /// Updates the message by decoding the given `SwiftProtobufContiguousBytes` value
    /// containing a serialized message in Protocol Buffer binary format into the
    /// receiver.
    ///
    /// - Note: If this method throws an error, the message may still have been
    ///   partially mutated by the binary data that was decoded before the error
    ///   occurred.
    ///
    /// - Parameters:
    ///   - serializedBytes: The binary-encoded message data to decode.
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
        extensions: (any ExtensionMap)? = nil,
        partial: Bool = false,
        options: BinaryDecodingOptions = BinaryDecodingOptions()
    ) throws {
        try bytes.withUnsafeBytes { (body: UnsafeRawBufferPointer) in
            try _merge(rawBuffer: body, extensions: extensions, partial: partial, options: options)
        }
    }

    // Helper for `merge()`s to keep the Decoder internal to SwiftProtobuf while
    // allowing the generic over `SwiftProtobufContiguousBytes` to get better codegen from the
    // compiler by being `@inlinable`. For some discussion on this see
    // https://github.com/apple/swift-protobuf/pull/914#issuecomment-555458153
    @usableFromInline
    internal mutating func _merge(
        rawBuffer body: UnsafeRawBufferPointer,
        extensions: (any ExtensionMap)?,
        partial: Bool,
        options: BinaryDecodingOptions
    ) throws {
        if let baseAddress = body.baseAddress, body.count > 0 {
            var decoder = BinaryDecoder(
                forReadingFrom: baseAddress,
                count: body.count,
                options: options,
                extensions: extensions
            )
            try decoder.decodeFullMessage(message: &self)
        }
        if !partial && !isInitialized {
            throw BinaryDecodingError.missingRequiredFields
        }
    }
}
