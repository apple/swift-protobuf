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

///
/// Messages
///
public extension Message {
    func jsonString() throws -> String {
        var visitor = JSONEncodingVisitor(message: self)
        visitor.encoder.startObject()
        try traverse(visitor: &visitor)
        visitor.encoder.endObject()
        return visitor.stringResult
    }

    func anyJSONString() throws -> String {
        var visitor = JSONEncodingVisitor(message: self)
        visitor.encoder.startObject()
        visitor.encoder.startField(name: "@type")
        visitor.encoder.putStringValue(value: Self.anyTypeURL)
        try traverse(visitor: &visitor)
        visitor.encoder.endObject()
        return visitor.stringResult
    }

    public init(jsonString: String) throws {
        let data = jsonString.data(using: String.Encoding.utf8)!
        try self.init(jsonUTF8Data: data)
    }

    public init(jsonUTF8Data: Data) throws {
        self.init()
        try jsonUTF8Data.withUnsafeBytes { (bytes:UnsafePointer<UInt8>) in
            var decoder = JSONDecoder(utf8Pointer: bytes,
                                      count: jsonUTF8Data.count)
            if !decoder.scanner.skipOptionalNull() {
                try self.decodeJSON(from: &decoder)
            }
            if !decoder.scanner.complete {
                throw JSONDecodingError.trailingGarbage
            }
        }
    }

    public mutating func decodeJSON(from decoder: inout JSONDecoder) throws {
        try decoder.decodeFullObject(message: &self)
    }
}

