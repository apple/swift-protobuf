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
/// Float traits
///
extension ProtobufFloat {
    public static func serializeJSONValue(encoder: inout JSONEncoder, value: Float) {
        encoder.putFloatValue(value: value)
    }
}

///
/// Double traits
///
public extension ProtobufDouble {
    public static func serializeJSONValue(encoder: inout JSONEncoder, value: Double) {
        encoder.putDoubleValue(value: value)
    }
}

///
/// Int32 traits
///
public extension ProtobufInt32 {
    public static func serializeJSONValue(encoder: inout JSONEncoder, value: Int32) {
        encoder.putInt32(value: value)
    }
}

///
/// Int64 traits
///
public extension ProtobufInt64 {
    public static func serializeJSONValue(encoder: inout JSONEncoder, value: Int64) {
        encoder.putInt64(value: value)
    }
}

///
/// UInt32 traits
///
public extension ProtobufUInt32 {
    public static func serializeJSONValue(encoder: inout JSONEncoder, value: UInt32) {
      encoder.putUInt32(value: value)
    }
}

///
/// UInt64 traits
///
public extension ProtobufUInt64 {
    public static func serializeJSONValue(encoder: inout JSONEncoder, value: UInt64) {
        encoder.putUInt64(value: value)
    }
}

///
/// SInt32 traits
///
public extension ProtobufSInt32 {
    public static func serializeJSONValue(encoder: inout JSONEncoder, value: Int32) {
        encoder.putInt32(value: value)
    }
}

///
/// SInt64 traits
///
public extension ProtobufSInt64 {
    public static func serializeJSONValue(encoder: inout JSONEncoder, value: Int64) {
        encoder.putInt64(value: value)
    }
}

///
/// Fixed32 traits
///
public extension ProtobufFixed32 {
    public static func serializeJSONValue(encoder: inout JSONEncoder, value: UInt32) {
        encoder.putUInt32(value: value)
    }
}

///
/// Fixed64 traits
///
public extension ProtobufFixed64 {
    public static func serializeJSONValue(encoder: inout JSONEncoder, value: UInt64) {
        encoder.putUInt64(value: value)
    }
}

///
/// SFixed32 traits
///
public extension ProtobufSFixed32 {
    public static func serializeJSONValue(encoder: inout JSONEncoder, value: Int32) {
        encoder.putInt32(value: value)
    }
}

///
/// SFixed64 traits
///
public extension ProtobufSFixed64 {
    public static func serializeJSONValue(encoder: inout JSONEncoder, value: Int64) {
        encoder.putInt64(value: value)
    }
}

///
/// Bool traits
///
public extension ProtobufBool {
    public static func serializeJSONValue(encoder: inout JSONEncoder, value: Bool) {
        encoder.putBoolValue(value: value)
    }
}

///
/// String traits
///
public extension ProtobufString {
    public static func serializeJSONValue(encoder: inout JSONEncoder, value: String) {
        encoder.putStringValue(value: value)
    }
}

///
/// Bytes traits
///
public extension ProtobufBytes {
    public static func serializeJSONValue(encoder: inout JSONEncoder, value: Data) {
        encoder.putBytesValue(value: value)
    }
}

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
        ProtobufString.serializeJSONValue(encoder: &visitor.encoder, value: Self.anyTypeURL)
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

