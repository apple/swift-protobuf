// Sources/SwiftProtobuf/Message+AnyAdditions.swift - Any-related Message extensions
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
//
// Extends the ``Message`` type with ``Google_Protobuf_Any``-specific behavior.
//
// -----------------------------------------------------------------------------

extension Message {
    /// Creates a message by unpacking the Any message you provide.
    ///
    /// This corresponds to the `unpack` method in the Google C++ API.
    ///
    /// If the binary or JSON decoder decoded the Any object, it stored the
    /// enclosed field data and does not fully decode it until you unpack
    /// the Any object into a message.
    /// As such, this method will typically need to perform a full
    /// deserialization of the enclosed data and can fail for any
    /// reason that deserialization can fail.
    ///
    /// See `Google_Protobuf_Any.unpackTo()` for more discussion.
    ///
    /// - Parameter unpackingAny: the message to decode.
    /// - Parameter extensions: An ``ExtensionMap`` that looks up and decodes
    ///   any extensions in this message or in messages within this
    ///   message's fields.
    /// - Parameter options: The BinaryDecodingOptions to use.
    /// - Throws: an instance of ``AnyUnpackError``, ``JSONDecodingError``, or
    ///   ``BinaryDecodingError`` on failure.
    public init(
        unpackingAny: Google_Protobuf_Any,
        extensions: (any ExtensionMap)? = nil,
        options: BinaryDecodingOptions = BinaryDecodingOptions()
    ) throws {
        self.init()
        try unpackingAny._storage.unpackTo(target: &self, extensions: extensions, options: options)
    }
}
