// Sources/SwiftProtobuf/Message+TextFormatAdditions.swift - Text format primitive types
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
//
// Extensions to ``Message`` to support text format encoding/decoding.
//
// -----------------------------------------------------------------------------

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Text format encoding and decoding methods for messages.
extension Message {
    /// Returns the Protocol Buffer text-format serialization of the message as a string.
    ///
    /// Unlike binary encoding, serializing to text format doesn't enforce the
    /// presence of required fields.
    ///
    /// - Returns: A string containing the text format serialization of the
    ///   message.
    public func textFormatString() -> String {
        // This is implemented as a separate zero-argument function
        // to preserve binary compatibility.
        textFormatString(options: TextFormatEncodingOptions())
    }

    /// Returns the Protocol Buffer text-format serialization of the message as a string, using the encoding options you provide.
    ///
    /// Unlike binary encoding, serializing to text format doesn't enforce the
    /// presence of required fields.
    ///
    /// - Returns: A string containing the text format serialization of the message.
    /// - Parameters:
    ///   - options: The TextFormatEncodingOptions to use.
    public func textFormatString(
        options: TextFormatEncodingOptions
    ) -> String {
        var visitor = TextFormatEncodingVisitor(message: self, options: options)
        if let any = self as? Google_Protobuf_Any {
            any._storage.textTraverse(visitor: &visitor)
        } else {
            // Although the general traversal/encoding infrastructure supports
            // throwing errors (needed for JSON/Binary WKTs support, binary format
            // missing required fields); TextEncoding never actually does throw.
            try! traverse(visitor: &visitor)
        }
        return visitor.result
    }

    // TODO: delete this (and keep the one with the extra param instead) when we break API

    /// Creates a message by decoding the Protocol Buffer text-format string you provide.
    ///
    /// - Parameters:
    ///   - textFormatString: The text format string to decode.
    ///   - extensions: An ``ExtensionMap`` for looking up and decoding any
    ///     extensions in this message or messages nested within this message's
    ///     fields.
    /// - Throws: ``SwiftProtobufError`` on failure.
    public init(
        textFormatString: String,
        extensions: (any ExtensionMap)? = nil
    ) throws {
        try self.init(
            textFormatString: textFormatString,
            options: TextFormatDecodingOptions(),
            extensions: extensions
        )
    }

    /// Creates a message by decoding the Protocol Buffer text-format string you provide, using the decoding options you supply.
    ///
    /// - Parameters:
    ///   - textFormatString: The text format string to decode.
    ///   - options: The ``TextFormatDecodingOptions`` to use.
    ///   - extensions: An ``ExtensionMap`` for looking up and decoding any
    ///     extensions in this message or messages nested within this message's
    ///     fields.
    /// - Throws: ``TextFormatDecodingError`` on failure.
    public init(
        textFormatString: String,
        options: TextFormatDecodingOptions = TextFormatDecodingOptions(),
        extensions: (any ExtensionMap)? = nil
    ) throws {
        self.init()
        if !textFormatString.isEmpty {
            if let data = textFormatString.data(using: String.Encoding.utf8) {
                try data.withUnsafeBytes { (body: UnsafeRawBufferPointer) in
                    if let baseAddress = body.baseAddress, body.count > 0 {
                        var decoder = try TextFormatDecoder(
                            messageType: Self.self,
                            utf8Pointer: baseAddress,
                            count: body.count,
                            options: options,
                            extensions: extensions
                        )
                        try decodeMessage(decoder: &decoder)
                        if !decoder.complete {
                            throw TextFormatDecodingError.trailingGarbage
                        }
                    }
                }
            }
        }
    }
}
