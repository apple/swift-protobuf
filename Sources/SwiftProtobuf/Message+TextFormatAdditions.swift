// Sources/SwiftProtobuf/Message+TextFormatAdditions.swift - Text format primitive types
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Extensions to `Message` to support text format encoding/decoding.
///
// -----------------------------------------------------------------------------

import Foundation

/// Text format encoding and decoding methods for messages.
extension Message {
    /// Returns a string containing the Protocol Buffer text format serialization
    /// of the message.
    ///
    /// Unlike binary encoding, presence of required fields is not enforced when
    /// serializing to text format.
    ///
    /// - Returns: A string containing the text format serialization of the
    ///   message.
    public func textFormatString() -> String {
        // This is implemented as a separate zero-argument function
        // to preserve binary compatibility.
        textFormatString(options: TextFormatEncodingOptions())
    }

    /// Returns a string containing the Protocol Buffer text format serialization
    /// of the message.
    ///
    /// Unlike binary encoding, presence of required fields is not enforced when
    /// serializing to text format.
    ///
    /// - Returns: A string containing the text format serialization of the message.
    /// - Parameters:
    ///   - options: The TextFormatEncodingOptions to use.
    public func textFormatString(
        options: TextFormatEncodingOptions
    ) -> String {
        var encoder = TextFormatEncoder()
        storageForRuntime.serializeText(into: &encoder, options: options)
        return encoder.stringResult
    }

    /// Creates a new message by decoding the given string containing a
    /// serialized message in Protocol Buffer text format.
    ///
    /// - Parameters:
    ///   - textFormatString: The text format string to decode.
    ///   - extensions: An ``ExtensionMap`` used to look up and decode any
    ///     extensions in this message or messages nested within this message's
    ///     fields.
    /// - Throws: ``SwiftProtobufError`` on failure.
    // TODO: delete this (and keep the one with the extra param instead) when we break API
    public init(
        textFormatString: String,
        extensions: ExtensionMap? = nil
    ) throws {
        try self.init(
            textFormatString: textFormatString,
            options: TextFormatDecodingOptions(),
            extensions: extensions
        )
    }

    /// Creates a new message by decoding the given string containing a
    /// serialized message in Protocol Buffer text format.
    ///
    /// - Parameters:
    ///   - textFormatString: The text format string to decode.
    ///   - options: The ``TextFormatDecodingOptions`` to use.
    ///   - extensions: An ``ExtensionMap`` used to look up and decode any
    ///     extensions in this message or messages nested within this message's
    ///     fields.
    /// - Throws: ``TextFormatDecodingError`` on failure.
    public init(
        textFormatString: String,
        options: TextFormatDecodingOptions = TextFormatDecodingOptions(),
        extensions: ExtensionMap? = nil
    ) throws {
        self.init()
        var textFormatString = textFormatString
        try textFormatString.withUTF8 { utf8Buffer in
            // Since we're inside an initializer, there's no need to ensure that the storage is unique.
            // If we ever implement a true `merge` for text format, we would need to do it there.
            guard utf8Buffer.baseAddress != nil, utf8Buffer.count > 0 else { return }

            let storage = storageForRuntime
            var reader = TextFormatReader(
                buffer: utf8Buffer,
                messageSchema: storage.schema,
                options: options,
                extensions: extensions
            )
            try storage.merge(byParsingTextFormatFrom: &reader)

            guard reader.complete else {
                throw TextFormatDecodingError.trailingGarbage
            }
        }
    }
}
