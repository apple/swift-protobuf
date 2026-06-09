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
    #if !REMOVE_DEPRECATED_APIS
    /// Creates a new message by decoding the given `Data` value
    /// containing a serialized message in Protocol Buffer binary format.
    ///
    /// - Parameters:
    ///   - data: The binary-encoded message `Data` to decode.
    ///   - extensions: An ``ExtensionMap`` used to look up and decode any
    ///     extensions in this message or messages nested within this message's
    ///     fields.
    ///   - partial: If `false` (the default), this method will verify that all required
    ///     fields are present while decoding. If any are missing, this method throws
    ///     ``BinaryDecodingError/missingRequiredFields``.
    ///   - options: The ``BinaryDecodingOptions`` to use.
    /// - Throws: ``BinaryDecodingError`` if decoding fails.
    @inlinable
    @available(*, deprecated, renamed: "init(serializedBytes:extensions:partial:options:)")
    public init(
        serializedData data: Data,
        extensions: ExtensionMap? = nil,
        partial: Bool = false,
        options: BinaryDecodingOptions = BinaryDecodingOptions()
    ) throws {
        self.init()
        try merge(serializedBytes: data, extensions: extensions, partial: partial, options: options)
    }

    /// Creates a new message by decoding the given `Foundation/ContiguousBytes` value
    /// containing a serialized message in Protocol Buffer binary format.
    ///
    /// - Parameters:
    ///   - bytes: The binary-encoded message data to decode.
    ///   - extensions: An ``ExtensionMap`` used to look up and decode any
    ///     extensions in this message or messages nested within this message's
    ///     fields.
    ///   - partial: If `false` (the default), this method will verify that all required
    ///     fields are present while decoding. If any are missing, this method throws
    ///     ``SwiftProtobufError/BinaryDecoding/missingRequiredFields``.
    ///   - options: The ``BinaryDecodingOptions`` to use.
    /// - Throws: ``SwiftProtobufError`` if decoding fails.
    @inlinable
    @_disfavoredOverload
    @available(*, deprecated, renamed: "init(serializedBytes:extensions:partial:options:)")
    public init<Bytes: ContiguousBytes>(
        contiguousBytes bytes: Bytes,
        extensions: ExtensionMap? = nil,
        partial: Bool = false,
        options: BinaryDecodingOptions = BinaryDecodingOptions()
    ) throws {
        self.init()
        try merge(serializedBytes: bytes, extensions: extensions, partial: partial, options: options)
    }

    /// Creates a new message by decoding the given `Foundation/ContiguousBytes` value
    /// containing a serialized message in Protocol Buffer binary format.
    ///
    /// - Parameters:
    ///   - bytes: The binary-encoded message data to decode.
    ///   - extensions: An ``ExtensionMap`` used to look up and decode any
    ///     extensions in this message or messages nested within this message's
    ///     fields.
    ///   - partial: If `false` (the default), this method will verify that all required
    ///     fields are present while decoding. If any are missing, this method throws
    ///     ``SwiftProtobufError/BinaryDecoding/missingRequiredFields``.
    ///   - options: The ``BinaryDecodingOptions`` to use.
    /// - Throws: ``SwiftProtobufError`` if decoding fails.
    @inlinable
    @_disfavoredOverload
    @available(
        *,
        deprecated,
        message:
            "Please conform your Bytes type to `SwiftProtobufContiguousBytes` instead of `Foundation.ContiguousBytes`."
    )
    public init<Bytes: ContiguousBytes>(
        serializedBytes bytes: Bytes,
        extensions: ExtensionMap? = nil,
        partial: Bool = false,
        options: BinaryDecodingOptions = BinaryDecodingOptions()
    ) throws {
        self.init()
        try merge(serializedBytes: bytes, extensions: extensions, partial: partial, options: options)
    }

    /// Updates the message by decoding the given `Foundation/ContiguousBytes` value
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
    ///   - partial: If `false` (the default), this method will verify that all required
    ///     fields are present while decoding. If any are missing, this method throws
    ///     ``SwiftProtobufError/BinaryDecoding/missingRequiredFields``.
    ///   - options: The ``BinaryDecodingOptions`` to use.
    /// - Throws: ``SwiftProtobufError`` if decoding fails.
    @inlinable
    @_disfavoredOverload
    @available(*, deprecated, renamed: "merge(serializedBytes:extensions:partial:options:)")
    public mutating func merge<Bytes: ContiguousBytes>(
        contiguousBytes bytes: Bytes,
        extensions: ExtensionMap? = nil,
        partial: Bool = false,
        options: BinaryDecodingOptions = BinaryDecodingOptions()
    ) throws {
        var options = options
        options.allowPartial = partial
        try bytes.withUnsafeBytes { (body: UnsafeRawBufferPointer) in
            try _decode(rawBuffer: body, extensions: extensions, options: options, isNewInstance: false)
        }
    }

    /// Updates the message by decoding the given `Foundation/ContiguousBytes` value
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
    ///   - partial: If `false` (the default), this method will verify that all required
    ///     fields are present while decoding. If any are missing, this method throws
    ///     ``SwiftProtobufError/BinaryDecoding/missingRequiredFields``.
    ///   - options: The ``BinaryDecodingOptions`` to use.
    /// - Throws: ``SwiftProtobufError`` if decoding fails.
    @inlinable
    @_disfavoredOverload
    @available(
        *,
        deprecated,
        message:
            "Please conform your Bytes type to `SwiftProtobufContiguousBytes` instead of `Foundation.ContiguousBytes`."
    )
    public mutating func merge<Bytes: ContiguousBytes>(
        serializedBytes bytes: Bytes,
        extensions: ExtensionMap? = nil,
        partial: Bool = false,
        options: BinaryDecodingOptions = BinaryDecodingOptions()
    ) throws {
        var options = options
        options.allowPartial = partial
        try bytes.withUnsafeBytes { (body: UnsafeRawBufferPointer) in
            try _decode(rawBuffer: body, extensions: extensions, options: options, isNewInstance: false)
        }
    }
    #endif  // !REMOVE_DEPRECATED_APIS

    /// Updates the message by decoding the given `Data` value
    /// containing a serialized message in Protocol Buffer binary format into the
    /// receiver.
    ///
    /// - Note: If this method throws an error, the message may still have been
    ///   partially mutated by the binary data that was decoded before the error
    ///   occurred.
    ///
    /// - Parameters:
    ///   - data: The binary-encoded message data to decode.
    ///   - extensions: An ``ExtensionMap`` used to look up and decode any
    ///     extensions in this message or messages nested within this message's
    ///     fields.
    ///   - options: The ``BinaryDecodingOptions`` to use.
    /// - Throws: ``BinaryDecodingError`` if decoding fails.
    @inlinable
    public mutating func merge(
        serializedData data: Data,
        extensions: ExtensionMap? = nil,
        options: BinaryDecodingOptions = BinaryDecodingOptions()
    ) throws {
        try merge(serializedBytes: data, extensions: extensions, options: options)
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
    ///   - data: The binary-encoded message data to decode.
    ///   - extensions: An ``ExtensionMap`` used to look up and decode any
    ///     extensions in this message or messages nested within this message's
    ///     fields.
    ///   - partial: If `false` (the default), this method will verify that all required
    ///     fields are present while decoding. If any are missing, this method throws
    ///     ``BinaryDecodingError/missingRequiredFields``.
    ///   - options: The ``BinaryDecodingOptions`` to use.
    /// - Throws: ``BinaryDecodingError`` if decoding fails.
    @available(
        *,
        deprecated,
        message: "Use merge(serializedData:extensions:options:) with options.allowPartial instead"
    )
    @inlinable
    public mutating func merge(
        serializedData data: Data,
        extensions: ExtensionMap? = nil,
        partial: Bool,
        options: BinaryDecodingOptions = BinaryDecodingOptions()
    ) throws {
        var options = options
        options.allowPartial = partial
        try merge(serializedData: data, extensions: extensions, options: options)
    }

    /// Returns a `Data` instance containing the Protocol Buffer binary
    /// format serialization of the message.
    ///
    /// - Parameters:
    ///   - partial: If `false` (the default), this method will verify that all required
    ///     fields are present while encoding. If any are missing, this method throws
    ///     ``BinaryEncodingError/missingRequiredFields``.
    /// - Returns: A `Data` instance containing the binary serialization of the message.
    /// - Throws: ``BinaryEncodingError`` if encoding fails.
    @available(*, deprecated, message: "Use serializedData(options:) with options.allowPartial instead")
    public func serializedData(partial: Bool) throws -> Data {
        var options = BinaryEncodingOptions()
        options.allowPartial = partial
        return try serializedData(options: options)
    }

    /// Returns a `Data` instance containing the Protocol Buffer binary
    /// format serialization of the message.
    ///
    /// - Parameters:
    ///   - options: The ``BinaryEncodingOptions`` to use.
    /// - Returns: A `Data` instance containing the binary serialization of the message.
    /// - Throws: ``BinaryEncodingError`` if encoding fails.
    public func serializedData(
        options: BinaryEncodingOptions = BinaryEncodingOptions()
    ) throws -> Data {
        try serializedBytes(options: options)
    }

    /// Returns a `Data` instance containing the Protocol Buffer binary
    /// format serialization of the message.
    ///
    /// - Parameters:
    ///   - partial: If `false` (the default), this method will verify that all required
    ///     fields are present while encoding. If any are missing, this method throws
    ///     ``BinaryEncodingError/missingRequiredFields``.
    ///   - options: The ``BinaryEncodingOptions`` to use.
    /// - Returns: A `Data` instance containing the binary serialization of the message.
    /// - Throws: ``BinaryEncodingError`` if encoding fails.
    @available(*, deprecated, message: "Use serializedData(options:) with options.allowPartial instead")
    public func serializedData(
        partial: Bool,
        options: BinaryEncodingOptions = BinaryEncodingOptions()
    ) throws -> Data {
        var options = options
        options.allowPartial = partial
        return try serializedData(options: options)
    }
}
