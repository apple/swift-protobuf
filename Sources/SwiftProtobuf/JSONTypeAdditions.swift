// Sources/SwiftProtobuf/JSONTypeAdditions.swift - JSON format primitive types
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Extend the type definitions from ProtobufTypes.swift with details
/// of protobuf JSON format handling.
///
// -----------------------------------------------------------------------------

import Foundation

//
// Messages
//
public extension Message {
    func jsonString() throws -> String {
        if let m = self as? _CustomJSONCodable {
            return try m.encodedJSONString()
        }
        var visitor = JSONEncodingVisitor(message: self)
        visitor.encoder.startObject()
        try traverse(visitor: &visitor)
        visitor.encoder.endObject()
        return visitor.stringResult
    }

    /// Creates an instance of the message by deserializing the given
    /// JSON-format `String`.
    ///
    /// - Throws: an instance of `JSONDecodingError` if the JSON cannot be
    ///   decoded.
    public init(jsonString: String) throws {
        if let data = jsonString.data(using: String.Encoding.utf8) {
            try self.init(jsonUTF8Data: data)
        } else {
            throw JSONDecodingError.truncated
        }
    }

    /// Creates an instance of the message by deserializing the given
    /// `Data` as UTF-8 encoded JSON.
    ///
    /// - Throws: an instance of `JSONDecodingError` if the JSON cannot be
    ///   decoded.
    public init(jsonUTF8Data: Data) throws {
        self.init()
        try jsonUTF8Data.withUnsafeBytes { (bytes:UnsafePointer<UInt8>) in
            var decoder = JSONDecoder(utf8Pointer: bytes,
                                      count: jsonUTF8Data.count)
            if !decoder.scanner.skipOptionalNull() {
                try decoder.decodeFullObject(message: &self)
            }
            if !decoder.scanner.complete {
                throw JSONDecodingError.trailingGarbage
            }
        }
    }
}

