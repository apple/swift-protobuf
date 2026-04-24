// Sources/SwiftProtobuf/Array+JSONAdditions.swift - JSON format primitive types
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Extensions to `Array` to support JSON encoding/decoding.
///
// -----------------------------------------------------------------------------

import Foundation

/// JSON encoding and decoding methods for arrays of messages.
extension Message {
    /// Returns a string containing the JSON serialization of the messages.
    ///
    /// Unlike binary encoding, presence of required fields is not enforced when
    /// serializing to JSON.
    ///
    /// - Returns: A string containing the JSON serialization of the messages.
    /// - Parameters:
    ///   - collection: The list of messages to encode.
    ///   - options: The JSONEncodingOptions to use.
    /// - Throws: ``SwiftProtobufError`` or ``JSONEncodingError`` if encoding fails.
    public static func jsonString<C: Collection>(
        from collection: C,
        options: JSONEncodingOptions = JSONEncodingOptions()
    ) throws -> String where C.Iterator.Element == Self {
        let data: [UInt8] = try jsonUTF8Bytes(from: collection, options: options)
        return String(decoding: data, as: UTF8.self)
    }

    /// Returns a `SwiftProtobufContiguousBytes` containing the UTF-8 JSON serialization of the messages.
    ///
    /// Unlike binary encoding, presence of required fields is not enforced when
    /// serializing to JSON.
    ///
    /// - Returns: A `SwiftProtobufContiguousBytes` containing the JSON serialization of the messages.
    /// - Parameters:
    ///   - collection: The list of messages to encode.
    ///   - options: The JSONEncodingOptions to use.
    /// - Throws: ``SwiftProtobufError`` or ``JSONEncodingError`` if encoding fails.
    public static func jsonUTF8Bytes<C: Collection, Bytes: SwiftProtobufContiguousBytes>(
        from collection: C,
        options: JSONEncodingOptions = JSONEncodingOptions()
    ) throws -> Bytes where C.Iterator.Element == Self {
        var encoder = JSONEncoder()
        encoder.startArray()
        var firstItem = true
        for message in collection {
            if !firstItem {
                encoder.comma()
            }
            try message.storageForRuntime.serializeJSON(into: &encoder, options: options)
            firstItem = false
        }
        encoder.endArray()
        return Bytes(encoder.bytesResult)
    }

    /// Creates a new array of messages by decoding the given string containing a
    /// serialized array of messages in JSON format.
    ///
    /// - Parameter jsonString: The JSON-formatted string to decode.
    /// - Parameter extensions: The extension map to use with this decode
    /// - Parameter options: The JSONDecodingOptions to use.
    /// - Throws: ``SwiftProtobufError`` or ``JSONDecodingError`` if decoding fails.
    public static func array(
        fromJSONString jsonString: String,
        extensions: ExtensionMap? = nil,
        options: JSONDecodingOptions = JSONDecodingOptions()
    ) throws -> [Self] {
        if jsonString.isEmpty {
            throw JSONDecodingError.truncated
        }
        if let data = jsonString.data(using: String.Encoding.utf8) {
            return try array(fromJSONUTF8Bytes: data, extensions: extensions, options: options)
        } else {
            throw JSONDecodingError.truncated
        }
    }

    /// Creates a new array of messages by decoding the given ``SwiftProtobufContiguousBytes``
    /// containing a serialized array of messages in JSON format, interpreting the data as
    /// UTF-8 encoded text.
    ///
    /// - Parameter jsonUTF8Bytes: The JSON-formatted data to decode, represented
    ///   as UTF-8 encoded text.
    /// - Parameter extensions: The extension map to use with this decode
    /// - Parameter options: The JSONDecodingOptions to use.
    /// - Throws: ``SwiftProtobufError`` or ``JSONDecodingError`` if decoding fails.
    public static func array<Bytes: SwiftProtobufContiguousBytes>(
        fromJSONUTF8Bytes jsonUTF8Bytes: Bytes,
        extensions: ExtensionMap? = nil,
        options: JSONDecodingOptions = JSONDecodingOptions()
    ) throws -> [Self] {
        try jsonUTF8Bytes.withUnsafeBytes { (body: UnsafeRawBufferPointer) in
            var array = [Self]()
            if body.count > 0 {
                // TODO: It's a little awkward that we need to create a dummy instance to get the
                // schema to pass into the reader. Revisit this if we look at a bigger refactor of
                // the readers/writers or when we look at reflection.
                var reader = JSONReader(
                    buffer: body,
                    messageSchema: Self().messageSchema,
                    options: options,
                    extensions: extensions
                )

                try scanArray(from: &reader) { reader in
                    let message = Self()
                    try reader.withReaderForNextObject(expectedSchema: message.messageSchema) { subReader in
                        try message.storageForRuntime.merge(byParsingJSONFrom: &subReader)
                    }
                    array.append(message)
                }
                
                guard reader.complete else {
                    throw JSONDecodingError.trailingGarbage
                }
            }
            return array
        }
    }
}
