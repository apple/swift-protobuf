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
public extension ProtobufFloat {
    public static func serializeJSONValue(encoder: inout JSONEncoder, value: Float) {
        encoder.putFloatValue(value: value, quote: false)
    }
}

///
/// Double traits
///
public extension ProtobufDouble {
    public static func serializeJSONValue(encoder: inout JSONEncoder, value: Double) {
        encoder.putDoubleValue(value: value, quote: false)
    }
}

///
/// Int32 traits
///
public extension ProtobufInt32 {
    public static func serializeJSONValue(encoder: inout JSONEncoder, value: Int32) {
        encoder.putInt64(value: Int64(value), quote: false)
    }

    public static func serializeJSONMapKey(encoder: inout JSONEncoder, value: Int32) {
        encoder.putInt64(value: Int64(value), quote: true)
    }
}

///
/// Int64 traits
///
public extension ProtobufInt64 {
    public static func serializeJSONValue(encoder: inout JSONEncoder, value: Int64) {
        encoder.putInt64(value: value, quote: true)
    }

    public static func serializeJSONMapKey(encoder: inout JSONEncoder, value: Int64) {
        encoder.putInt64(value: value, quote: true)
    }
}

///
/// UInt32 traits
///
public extension ProtobufUInt32 {
    public static func serializeJSONValue(encoder: inout JSONEncoder, value: UInt32) {
        encoder.putUInt64(value: UInt64(value), quote: false)
    }

    public static func serializeJSONMapKey(encoder: inout JSONEncoder, value: UInt32) {
        encoder.putUInt64(value: UInt64(value), quote: true)
    }
}

///
/// UInt64 traits
///
public extension ProtobufUInt64 {
    public static func serializeJSONValue(encoder: inout JSONEncoder, value: UInt64) {
        encoder.putUInt64(value: value, quote: true)
    }

    public static func serializeJSONMapKey(encoder: inout JSONEncoder, value: UInt64) {
        encoder.putUInt64(value: value, quote: true)
    }
}

///
/// SInt32 traits
///
public extension ProtobufSInt32 {
    public static func serializeJSONValue(encoder: inout JSONEncoder, value: Int32) {
        encoder.putInt64(value: Int64(value), quote: false)
    }

    public static func serializeJSONMapKey(encoder: inout JSONEncoder, value: Int32) {
        encoder.putInt64(value: Int64(value), quote: true)
    }
}

///
/// SInt64 traits
///
public extension ProtobufSInt64 {
    public static func serializeJSONValue(encoder: inout JSONEncoder, value: Int64) {
        encoder.putInt64(value: value, quote: true)
    }

    public static func serializeJSONMapKey(encoder: inout JSONEncoder, value: Int64) {
        encoder.putInt64(value: value, quote: true)
    }
}

///
/// Fixed32 traits
///
public extension ProtobufFixed32 {
    public static func serializeJSONValue(encoder: inout JSONEncoder, value: UInt32) {
        encoder.putUInt64(value: UInt64(value), quote: false)
    }

    public static func serializeJSONMapKey(encoder: inout JSONEncoder, value: UInt32) {
        encoder.putUInt64(value: UInt64(value), quote: true)
    }
}

///
/// Fixed64 traits
///
public extension ProtobufFixed64 {
    public static func serializeJSONValue(encoder: inout JSONEncoder, value: UInt64) {
        encoder.putUInt64(value: value, quote: true)
    }

    public static func serializeJSONMapKey(encoder: inout JSONEncoder, value: UInt64) {
        encoder.putUInt64(value: value.littleEndian, quote: true)
    }
}

///
/// SFixed32 traits
///
public extension ProtobufSFixed32 {
    public static func serializeJSONValue(encoder: inout JSONEncoder, value: Int32) {
        encoder.putInt64(value: Int64(value), quote: false)
    }

    public static func serializeJSONMapKey(encoder: inout JSONEncoder, value: Int32) {
        encoder.putInt64(value: Int64(value), quote: true)
    }
}

///
/// SFixed64 traits
///
public extension ProtobufSFixed64 {
    public static func serializeJSONValue(encoder: inout JSONEncoder, value: Int64) {
        encoder.putInt64(value: value, quote: true)
    }

    public static func serializeJSONMapKey(encoder: inout JSONEncoder, value: Int64) {
        encoder.putInt64(value: value, quote: true)
    }
}

///
/// Bool traits
///
public extension ProtobufBool {
    public static func serializeJSONValue(encoder: inout JSONEncoder, value: Bool) {
        encoder.putBoolValue(value: value, quote: false)
    }

    public static func serializeJSONMapKey(encoder: inout JSONEncoder, value: Bool) {
        encoder.putBoolValue(value: value, quote: true)
    }
}

///
/// String traits
///
public extension ProtobufString {
    public static func serializeJSONValue(encoder: inout JSONEncoder, value: String) {
        encoder.putStringValue(value: value)
    }

    public static func serializeJSONMapKey(encoder: inout JSONEncoder, value: String) {
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
        return try JSONEncodingVisitor(message: self).result
    }

    func anyJSONString() throws -> String {
        return try JSONEncodingVisitor(message: self, anyTypeURL: type(of: self).anyTypeURL).result
    }

    static func serializeJSONValue(encoder: inout JSONEncoder, value: Self) throws {
        let json = try value.jsonString()
        encoder.append(text: json)
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

