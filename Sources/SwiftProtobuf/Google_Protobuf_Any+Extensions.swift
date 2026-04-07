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
import Foundation

public let defaultAnyTypeURLPrefix: String = "type.googleapis.com"

extension Google_Protobuf_Any {
    /// Initialize an Any object from the provided message.
    ///
    /// This corresponds to the `pack` operation in the C++ API.
    ///
    /// - Parameters:
    ///   - message: The ``Message`` to serialized into this Any.
    ///   - partial: If `false` (the default), this method will check
    ///     ``Message/isInitialized-6abgi`` before encoding to verify that all required
    ///     fields are present. If any are missing, this method throws
    ///     ``BinaryEncodingError/missingRequiredFields``.
    ///   - typeURLPrefix: The prefix to be used when building the `type_url`.
    ///     Defaults to "type.googleapis.com".
    /// - Throws: ``BinaryEncodingError/missingRequiredFields`` if
    ///   `partial` is false and `message` wasn't fully initialized.
    public init<M: Message>(
        packing message: M,
        partial: Bool = false,
        typeURLPrefix: String = defaultAnyTypeURLPrefix
    ) throws {
        // Since we're passing a concrete message type here, we can auto-register it for
        // convenience.
        Google_Protobuf_Any.register(messageType: M.self)

        self.init()
        typeURL = buildTypeURL(forMessage: message, typePrefix: typeURLPrefix)
        value = try message.serializedData(partial: partial)
    }

    /// Initialize an Any object from the provided message.
    ///
    /// This corresponds to the `pack` operation in the C++ API.
    ///
    /// - Parameters:
    ///   - message: The ``Message`` to serialized into this Any.
    ///   - partial: If `false` (the default), this method will check
    ///     ``Message/isInitialized-6abgi`` before encoding to verify that all required
    ///     fields are present. If any are missing, this method throws
    ///     ``BinaryEncodingError/missingRequiredFields``.
    ///   - typePrefix: The prefix to be used when building the `type_url`.
    ///     Defaults to "type.googleapis.com".
    /// - Throws: ``BinaryEncodingError/missingRequiredFields`` if
    /// `partial` is false and `message` wasn't fully initialized.
    @available(*, deprecated, renamed: "init(packing:partial:typeURLPrefix:)")
    public init(
        message: any Message,
        partial: Bool = false,
        typePrefix: String = defaultAnyTypeURLPrefix
    ) throws {
        // Since we're passing a concrete message type here, we can auto-register it for
        // convenience.
        Google_Protobuf_Any.register(messageType: type(of: message))

        self.init()
        typeURL = buildTypeURL(forMessage: message, typePrefix: typePrefix)
        value = try message.serializedData(partial: partial)
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
