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
    ///   - options: The ``BinaryEncodingOptions`` to use.
    /// - Returns: A ``SwiftProtobufContiguousBytes`` instance containing the binary serialization
    /// of the message.
    ///
    /// - Throws: ``SwiftProtobufError`` or ``BinaryEncodingError`` if encoding fails.
    public func serializedBytes<Bytes: SwiftProtobufContiguousBytes>(
        options: BinaryEncodingOptions = BinaryEncodingOptions()
    ) throws -> Bytes {
        try storageForRuntime.serializedBytes(options: options)
    }

    /// Returns a ``SwiftProtobufContiguousBytes`` instance containing the Protocol Buffer binary
    /// format serialization of the message.
    ///
    /// - Parameters:
    ///   - partial: If `false` (the default), this method will verify that all required
    ///     fields are present before encoding. If any are missing, this method throws
    ///     ``BinaryEncodingError/missingRequiredFields``.
    ///   - options: The ``BinaryEncodingOptions`` to use.
    /// - Returns: A ``SwiftProtobufContiguousBytes`` instance containing the binary serialization
    /// of the message.
    ///
    /// - Throws: ``SwiftProtobufError`` or ``BinaryEncodingError`` if encoding fails.
    @available(*, deprecated, message: "Use serializedBytes(options:) with options.allowPartial instead")
    public func serializedBytes<Bytes: SwiftProtobufContiguousBytes>(
        partial: Bool,
        options: BinaryEncodingOptions = BinaryEncodingOptions()
    ) throws -> Bytes {
        var options = options
        options.allowPartial = partial
        return try serializedBytes(options: options)
    }

    /// Creates a new message by decoding the given `SwiftProtobufContiguousBytes` value
    /// containing a serialized message in Protocol Buffer binary format.
    ///
    /// - Parameters:
    ///   - bytes: The binary-encoded message data to decode.
    ///   - extensions: An ``ExtensionMap`` used to look up and decode any
    ///     extensions in this message or messages nested within this message's
    ///     fields.
    ///   - options: The ``BinaryDecodingOptions`` to use.
    /// - Throws: ``BinaryDecodingError`` if decoding fails.
    @inlinable
    public init<Bytes: SwiftProtobufContiguousBytes>(
        serializedBytes bytes: Bytes,
        extensions: ExtensionMap? = nil,
        options: BinaryDecodingOptions = BinaryDecodingOptions()
    ) throws {
        self.init()
        try bytes.withUnsafeBytes { (body: UnsafeRawBufferPointer) in
            try _parse(rawBuffer: body, extensions: extensions, options: options)
        }
    }

    /// Creates a new message by decoding the given `SwiftProtobufContiguousBytes` value
    /// containing a serialized message in Protocol Buffer binary format.
    ///
    /// - Parameters:
    /// - Parameters:
    ///   - bytes: The binary-encoded message data to decode.
    ///   - extensions: An ``ExtensionMap`` used to look up and decode any
    ///     extensions in this message or messages nested within this message's
    ///     fields.
    ///   - partial: If `false` (the default), this method will verify that all required
    ///     fields are present before encoding. If any are missing, this method throws
    ///     ``BinaryDecodingError/missingRequiredFields``.
    ///   - options: The ``BinaryDecodingOptions`` to use.
    /// - Throws: ``BinaryDecodingError`` if decoding fails.
    @available(
        *,
        deprecated,
        message: "Use init(serializedBytes:extensions:options:) with options.allowPartial instead"
    )
    @inlinable
    public init<Bytes: SwiftProtobufContiguousBytes>(
        serializedBytes bytes: Bytes,
        extensions: ExtensionMap? = nil,
        partial: Bool,
        options: BinaryDecodingOptions = BinaryDecodingOptions()
    ) throws {
        self.init()
        var options = options
        options.allowPartial = partial
        try merge(serializedBytes: bytes, extensions: extensions, options: options)
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
    ///   - options: The ``BinaryDecodingOptions`` to use.
    /// - Throws: ``BinaryDecodingError`` if decoding fails.
    @inlinable
    @available(macOS 10.14.4, iOS 12.2, watchOS 5.2, tvOS 12.2, visionOS 1.0, *)
    public init(
        serializedBytes bytes: RawSpan,
        extensions: ExtensionMap? = nil,
        options: BinaryDecodingOptions = BinaryDecodingOptions()
    ) throws {
        self.init()
        try bytes.withUnsafeBytes { (body: UnsafeRawBufferPointer) in
            try _parse(rawBuffer: body, extensions: extensions, options: options)
        }
    }

    /// Creates a new message by decoding the bytes provided by a `RawSpan`
    /// containing a serialized message in Protocol Buffer binary format.
    ///
    /// - Parameters:
    /// - Parameters:
    ///   - bytes: The `RawSpan` of binary-encoded message data to decode.
    ///   - extensions: An ``ExtensionMap`` used to look up and decode any
    ///     extensions in this message or messages nested within this message's
    ///     fields.
    ///   - partial: If `false` (the default), this method will verify that all required
    ///     fields are present before encoding. If any are missing, this method throws
    ///     ``BinaryDecodingError/missingRequiredFields``.
    ///   - options: The ``BinaryDecodingOptions`` to use.
    /// - Throws: ``BinaryDecodingError`` if decoding fails.
    @available(
        *,
        deprecated,
        message: "Use init(serializedBytes:extensions:options:) with options.allowPartial instead"
    )
    @inlinable
    @available(macOS 10.14.4, iOS 12.2, watchOS 5.2, tvOS 12.2, visionOS 1.0, *)
    public init(
        serializedBytes bytes: RawSpan,
        extensions: ExtensionMap? = nil,
        partial: Bool,
        options: BinaryDecodingOptions = BinaryDecodingOptions()
    ) throws {
        self.init()
        var options = options
        options.allowPartial = partial
        try merge(serializedBytes: bytes, extensions: extensions, options: options)
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
    ///   - options: The ``BinaryDecodingOptions`` to use.
    /// - Throws: ``BinaryDecodingError`` if decoding fails.
    @inlinable
    public mutating func merge<Bytes: SwiftProtobufContiguousBytes>(
        serializedBytes bytes: Bytes,
        extensions: ExtensionMap? = nil,
        options: BinaryDecodingOptions = BinaryDecodingOptions()
    ) throws {
        try bytes.withUnsafeBytes { (body: UnsafeRawBufferPointer) in
            try _merge(rawBuffer: body, extensions: extensions, options: options)
        }
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
    /// - Parameters:
    ///   - bytes: The binary-encoded message data to decode.
    ///   - extensions: An ``ExtensionMap`` used to look up and decode any
    ///     extensions in this message or messages nested within this message's
    ///     fields.
    ///   - partial: If `false` (the default), this method will verify that all required
    ///     fields are present before encoding. If any are missing, this method throws
    ///     ``BinaryDecodingError/missingRequiredFields``.
    ///   - options: The ``BinaryDecodingOptions`` to use.
    /// - Throws: ``BinaryDecodingError`` if decoding fails.
    @available(
        *,
        deprecated,
        message: "Use merge(serializedBytes:extensions:options:) with options.allowPartial instead"
    )
    @inlinable
    public mutating func merge<Bytes: SwiftProtobufContiguousBytes>(
        serializedBytes bytes: Bytes,
        extensions: ExtensionMap? = nil,
        partial: Bool,
        options: BinaryDecodingOptions = BinaryDecodingOptions()
    ) throws {
        var options = options
        options.allowPartial = partial
        try merge(serializedBytes: bytes, extensions: extensions, options: options)
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
    ///   - options: The ``BinaryDecodingOptions`` to use.
    /// - Throws: ``BinaryDecodingError`` if decoding fails.
    @inlinable
    @available(macOS 10.14.4, iOS 12.2, watchOS 5.2, tvOS 12.2, visionOS 1.0, *)
    public mutating func merge(
        serializedBytes bytes: RawSpan,
        extensions: ExtensionMap? = nil,
        options: BinaryDecodingOptions = BinaryDecodingOptions()
    ) throws {
        try bytes.withUnsafeBytes { (body: UnsafeRawBufferPointer) in
            try _merge(rawBuffer: body, extensions: extensions, options: options)
        }
    }

    /// Updates the message by decoding the bytes provided by a `RawSpan` containing
    /// a serialized message in Protocol Buffer binary format into the receiver.
    ///
    /// - Note: If this method throws an error, the message may still have been
    ///   partially mutated by the binary data that was decoded before the error
    ///   occurred.
    ///
    /// - Parameters:
    /// - Parameters:
    ///   - bytes: The `RawSpan` of binary-encoded message data to decode.
    ///   - extensions: An ``ExtensionMap`` used to look up and decode any
    ///     extensions in this message or messages nested within this message's
    ///     fields.
    ///   - partial: If `false` (the default), this method will verify that all required
    ///     fields are present before encoding. If any are missing, this method throws
    ///     ``BinaryDecodingError/missingRequiredFields``.
    ///   - options: The ``BinaryDecodingOptions`` to use.
    /// - Throws: ``BinaryDecodingError`` if decoding fails.
    @available(
        *,
        deprecated,
        message: "Use merge(serializedBytes:extensions:options:) with options.allowPartial instead"
    )
    @inlinable
    @available(macOS 10.14.4, iOS 12.2, watchOS 5.2, tvOS 12.2, visionOS 1.0, *)
    public mutating func merge(
        serializedBytes bytes: RawSpan,
        extensions: ExtensionMap? = nil,
        partial: Bool,
        options: BinaryDecodingOptions = BinaryDecodingOptions()
    ) throws {
        var options = options
        options.allowPartial = partial
        try merge(serializedBytes: bytes, extensions: extensions, options: options)
    }
    #endif

    // Helper for public methods that initialize a new instance. For some historical discussion on the
    // inline usage, see https://github.com/apple/swift-protobuf/pull/914#issuecomment-555458153
    @usableFromInline
    mutating func _parse(
        rawBuffer body: UnsafeRawBufferPointer,
        extensions: ExtensionMap?,
        options: BinaryDecodingOptions
    ) throws {
        _protobuf_ensureUniqueStorage(accessToken: MessageStorageToken())
        var isShallowInitCheckPassed = true
        try storageForRuntime.merge(
            byReadingFrom: body,
            extensions: extensions,
            options: options,
            isInitializedShallow: &isShallowInitCheckPassed
        )
        if !options.allowPartial && !isShallowInitCheckPassed {
            // Fallback: A shallow check failure might be a false positive if a submessage was
            // parsed as incomplete initially but completed by a subsequent payload block in the
            // stream. We must run a full deep `isInitialized` check to verify actual completeness.
            guard isInitialized else {
                throw BinaryDecodingError.missingRequiredFields
            }
        }
    }

    // Helper for public methods that merge into existing instance. For some historical discussion
    // on the inline usage, see https://github.com/apple/swift-protobuf/pull/914#issuecomment-555458153
    @usableFromInline
    mutating func _merge(
        rawBuffer body: UnsafeRawBufferPointer,
        extensions: ExtensionMap?,
        options: BinaryDecodingOptions
    ) throws {
        // Optimization: Since we are merging into an existing message structure, we must
        // always perform a final deep recursive `isInitialized` check at the end (because
        // required fields in pre-existing submessages not present in the binary payload
        // won't be visited during decoding). Therefore, we bypass all parsing-time shallow
        // validation checks by setting `allowPartial = true` during the merge execution.
        var subOptions = options
        subOptions.allowPartial = true
        _protobuf_ensureUniqueStorage(accessToken: MessageStorageToken())
        var ignored = true
        try storageForRuntime.merge(
            byReadingFrom: body,
            extensions: extensions,
            options: subOptions,
            isInitializedShallow: &ignored
        )
        if !options.allowPartial && !isInitialized {
            throw BinaryDecodingError.missingRequiredFields
        }
    }
}
