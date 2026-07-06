// Sources/SwiftProtobuf/Google_Protobuf_Any+Extensions.swift - Well-known Any type
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Extends the `Google_Protobuf_Any` type with various custom behaviors.
///
// -----------------------------------------------------------------------------

// Explicit import of Foundation is necessary on Linux,
// don't remove unless obsolete on all platforms
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

public var defaultAnyTypeURLPrefix: String { "type.googleapis.com" }

extension Google_Protobuf_Any {
    /// Initialize an Any object from the provided message.
    ///
    /// This corresponds to the `pack` operation in the C++ API.
    ///
    /// - Parameters:
    ///   - message: The ``Message`` to serialized into this Any.
    ///   - options: The ``BinaryEncodingOptions`` to use.
    ///   - typeURLPrefix: The prefix to be used when building the `type_url`.
    ///     Defaults to "type.googleapis.com".
    /// - Throws: ``BinaryEncodingError/missingRequiredFields`` if
    ///   `options.allowPartial` is false and `message` wasn't fully initialized.
    public init<M: Message>(
        packing message: M,
        options: BinaryEncodingOptions = BinaryEncodingOptions(),
        typeURLPrefix: String = defaultAnyTypeURLPrefix
    ) throws {
        // Since we're passing a concrete message type here, we can auto-register it for
        // convenience.
        Google_Protobuf_Any.register(messageType: M.self)

        self.init()
        typeURL = buildTypeURL(forMessage: message, typePrefix: typeURLPrefix)
        value = try message.serializedData(options: options)
    }

    /// Initialize an Any object from the provided message.
    ///
    /// This corresponds to the `pack` operation in the C++ API.
    ///
    /// - Parameters:
    ///   - message: The ``Message`` to serialized into this Any.
    ///   - partial: If `false` (the default), this method will verify that all required
    ///     fields are present while encoding. If any are missing, this method throws
    ///     ``BinaryEncodingError/missingRequiredFields``.
    ///   - typeURLPrefix: The prefix to be used when building the `type_url`.
    ///     Defaults to "type.googleapis.com".
    /// - Throws: ``BinaryEncodingError/missingRequiredFields`` if
    ///   `partial` is false and `message` wasn't fully initialized.
    @available(*, deprecated, message: "Use init(packing:options:typeURLPrefix:) with options.allowPartial instead")
    public init<M: Message>(
        packing message: M,
        partial: Bool,
        typeURLPrefix: String = defaultAnyTypeURLPrefix
    ) throws {
        var options = BinaryEncodingOptions()
        options.allowPartial = partial
        try self.init(packing: message, options: options, typeURLPrefix: typeURLPrefix)
    }

    /// Initialize an Any object from the provided message.
    ///
    /// This corresponds to the `pack` operation in the C++ API.
    ///
    /// - Parameters:
    ///   - message: The ``Message`` to serialized into this Any.
    ///   - options: The ``BinaryEncodingOptions`` to use.
    ///   - typePrefix: The prefix to be used when building the `type_url`.
    ///     Defaults to "type.googleapis.com".
    /// - Throws: ``BinaryEncodingError/missingRequiredFields`` if
    /// `options.allowPartial` is false and `message` wasn't fully initialized.
    @available(*, deprecated, renamed: "init(packing:options:typeURLPrefix:)")
    public init(
        message: any Message,
        options: BinaryEncodingOptions = BinaryEncodingOptions(),
        typePrefix: String = defaultAnyTypeURLPrefix
    ) throws {
        // Since we're passing a concrete message type here, we can auto-register it for
        // convenience.
        Google_Protobuf_Any.register(messageType: type(of: message))

        self.init()
        typeURL = buildTypeURL(forMessage: message, typePrefix: typePrefix)
        value = try message.serializedData(options: options)
    }

    /// Initialize an Any object from the provided message.
    ///
    /// This corresponds to the `pack` operation in the C++ API.
    ///
    /// - Parameters:
    ///   - message: The ``Message`` to serialized into this Any.
    ///   - partial: If `false` (the default), this method will verify that all required
    ///     fields are present while encoding. If any are missing, this method throws
    ///     ``BinaryEncodingError/missingRequiredFields``.
    ///   - typePrefix: The prefix to be used when building the `type_url`.
    ///     Defaults to "type.googleapis.com".
    /// - Throws: ``BinaryEncodingError/missingRequiredFields`` if
    /// `partial` is false and `message` wasn't fully initialized.
    @available(*, deprecated, message: "Use init(message:options:typePrefix:) with options.allowPartial instead")
    public init(
        message: any Message,
        partial: Bool,
        typePrefix: String = defaultAnyTypeURLPrefix
    ) throws {
        var options = BinaryEncodingOptions()
        options.allowPartial = partial
        try self.init(message: message, options: options, typePrefix: typePrefix)
    }

    /// Returns true if this `Google_Protobuf_Any` message contains the given
    /// message type.
    ///
    /// The check is performed by looking at the passed `Message.Type` and the
    /// `typeURL` of this message.
    ///
    /// - Parameter type: The concrete message type.
    /// - Returns: True if the receiver contains the given message type.
    public func isA<M: Message>(_ type: M.Type) -> Bool {
        if typeURL.isEmpty {
            return false
        }
        let encodedType = typeName(fromURL: typeURL)
        return encodedType == M.protoMessageName
    }
}
