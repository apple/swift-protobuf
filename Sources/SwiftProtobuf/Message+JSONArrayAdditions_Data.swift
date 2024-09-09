// Sources/SwiftProtobuf/Message+JSONArrayAdditions_Data.swift - JSON format primitive types
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
    /// Creates a new array of messages by decoding the given `Data`
    /// containing a serialized array of messages in JSON format, interpreting the data as
    /// UTF-8 encoded text.
    ///
    /// - Parameter jsonUTF8Data: The JSON-formatted data to decode, represented
    ///   as UTF-8 encoded text.
    /// - Parameter options: The JSONDecodingOptions to use.
    /// - Throws: ``JSONDecodingError`` if decoding fails.
    public static func array(
        fromJSONUTF8Data jsonUTF8Data: Data,
        options: JSONDecodingOptions = JSONDecodingOptions()
    ) throws -> [Self] {
        try self.array(
            fromJSONUTF8Bytes: jsonUTF8Data,
            extensions: SimpleExtensionMap(),
            options: options
        )
    }

    /// Creates a new array of messages by decoding the given `Data`
    /// containing a serialized array of messages in JSON format, interpreting the data as
    /// UTF-8 encoded text.
    ///
    /// - Parameter jsonUTF8Data: The JSON-formatted data to decode, represented
    ///   as UTF-8 encoded text.
    /// - Parameter extensions: The extension map to use with this decode
    /// - Parameter options: The JSONDecodingOptions to use.
    /// - Throws: ``JSONDecodingError`` if decoding fails.
    public static func array(
        fromJSONUTF8Data jsonUTF8Data: Data,
        extensions: any ExtensionMap = SimpleExtensionMap(),
        options: JSONDecodingOptions = JSONDecodingOptions()
    ) throws -> [Self] {
        try array(
            fromJSONUTF8Bytes: jsonUTF8Data,
            extensions: extensions,
            options: options
        )
    }

    /// Returns a Data containing the UTF-8 JSON serialization of the messages.
    ///
    /// Unlike binary encoding, presence of required fields is not enforced when
    /// serializing to JSON.
    ///
    /// - Returns: A Data containing the JSON serialization of the messages.
    /// - Parameters:
    ///   - collection: The list of messages to encode.
    ///   - options: The JSONEncodingOptions to use.
    /// - Throws: ``JSONEncodingError`` if encoding fails.
    public static func jsonUTF8Data<C: Collection>(
        from collection: C,
        options: JSONEncodingOptions = JSONEncodingOptions()
    ) throws -> Data where C.Iterator.Element == Self {
        try jsonUTF8Bytes(from: collection, options: options)
    }
}
