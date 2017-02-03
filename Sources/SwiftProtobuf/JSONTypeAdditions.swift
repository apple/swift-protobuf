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
import Swift

public extension FieldType {
    public static func setFromJSON(decoder: inout JSONDecoder, value: inout BaseType) throws {
        var v: BaseType?
        try setFromJSON(decoder: &decoder, value: &v)
        if let v = v {
            value = v
        }
    }
}

///
/// Float traits
///
public extension ProtobufFloat {
    public static func setFromJSON(decoder: inout JSONDecoder, value: inout BaseType?) throws {
        value = try decoder.scanner.nextFloat()
    }

    public static func setFromJSON(decoder: inout JSONDecoder, value: inout [BaseType]) throws {
        let n = try decoder.scanner.nextFloat()
        value.append(n)
    }

    public static func serializeJSONValue(encoder: inout JSONEncoder, value: Float) {
        encoder.putFloatValue(value: value, quote: false)
    }
}

///
/// Double traits
///
public extension ProtobufDouble {

    public static func setFromJSON(decoder: inout JSONDecoder, value: inout BaseType?) throws {
        value = try decoder.scanner.nextDouble()
    }

    public static func setFromJSON(decoder: inout JSONDecoder, value: inout [BaseType]) throws {
        let n = try decoder.scanner.nextDouble()
        value.append(n)
    }

    public static func serializeJSONValue(encoder: inout JSONEncoder, value: Double) {
        encoder.putDoubleValue(value: value, quote: false)
    }
}

///
/// Int32 traits
///
public extension ProtobufInt32 {
    public static func setFromJSON(decoder: inout JSONDecoder, value: inout BaseType?) throws {
        let n = try decoder.scanner.nextSInt()
        if n > Int64(Int32.max) || n < Int64(Int32.min) {
            throw DecodingError.malformedJSONNumber
        }
        value = Int32(truncatingBitPattern: n)
    }

    public static func setFromJSON(decoder: inout JSONDecoder, value: inout [BaseType]) throws {
        let n = try decoder.scanner.nextSInt()
        if n > Int64(Int32.max) || n < Int64(Int32.min) {
            throw DecodingError.malformedJSONNumber
        }
        value.append(Int32(truncatingBitPattern: n))
    }

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
    public static func setFromJSON(decoder: inout JSONDecoder, value: inout BaseType?) throws {
        value = try decoder.scanner.nextSInt()
    }

    public static func setFromJSON(decoder: inout JSONDecoder, value: inout [BaseType]) throws {
        let n = try decoder.scanner.nextSInt()
        value.append(n)
    }

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
    public static func setFromJSON(decoder: inout JSONDecoder, value: inout BaseType?) throws {
        let n = try decoder.scanner.nextUInt()
        if n > UInt64(UInt32.max) {
            throw DecodingError.malformedJSONNumber
        }
        value = UInt32(truncatingBitPattern: n)
    }

    public static func setFromJSON(decoder: inout JSONDecoder, value: inout [BaseType]) throws {
        let n = try decoder.scanner.nextUInt()
        if n > UInt64(UInt32.max) {
            throw DecodingError.malformedJSONNumber
        }
        value.append(UInt32(truncatingBitPattern: n))
    }

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
    public static func setFromJSON(decoder: inout JSONDecoder, value: inout BaseType?) throws {
        value = try decoder.scanner.nextUInt()
    }

    public static func setFromJSON(decoder: inout JSONDecoder, value: inout [BaseType]) throws {
        let n = try decoder.scanner.nextUInt()
        value.append(n)
    }

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
    public static func setFromJSON(decoder: inout JSONDecoder, value: inout BaseType?) throws {
        try ProtobufInt32.setFromJSON(decoder: &decoder, value: &value)
    }

    public static func setFromJSON(decoder: inout JSONDecoder, value: inout [BaseType]) throws {
        try ProtobufInt32.setFromJSON(decoder: &decoder, value: &value)
    }

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
    public static func setFromJSON(decoder: inout JSONDecoder, value: inout BaseType?) throws {
        try ProtobufInt64.setFromJSON(decoder: &decoder, value: &value)
    }

    public static func setFromJSON(decoder: inout JSONDecoder, value: inout [BaseType]) throws {
        try ProtobufInt64.setFromJSON(decoder: &decoder, value: &value)
    }

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
    public static func setFromJSON(decoder: inout JSONDecoder, value: inout BaseType?) throws {
        try ProtobufUInt32.setFromJSON(decoder: &decoder, value: &value)
    }

    public static func setFromJSON(decoder: inout JSONDecoder, value: inout [BaseType]) throws {
        try ProtobufUInt32.setFromJSON(decoder: &decoder, value: &value)
    }

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
    public static func setFromJSON(decoder: inout JSONDecoder, value: inout BaseType?) throws {
        try ProtobufUInt64.setFromJSON(decoder: &decoder, value: &value)
    }

    public static func setFromJSON(decoder: inout JSONDecoder, value: inout [BaseType]) throws {
        try ProtobufUInt64.setFromJSON(decoder: &decoder, value: &value)
    }

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
    public static func setFromJSON(decoder: inout JSONDecoder, value: inout BaseType?) throws {
        try ProtobufInt32.setFromJSON(decoder: &decoder, value: &value)
    }

    public static func setFromJSON(decoder: inout JSONDecoder, value: inout [BaseType]) throws {
        try ProtobufInt32.setFromJSON(decoder: &decoder, value: &value)
    }

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
    public static func setFromJSON(decoder: inout JSONDecoder, value: inout BaseType?) throws {
        try ProtobufInt64.setFromJSON(decoder: &decoder, value: &value)
    }

    public static func setFromJSON(decoder: inout JSONDecoder, value: inout [BaseType]) throws {
        try ProtobufInt64.setFromJSON(decoder: &decoder, value: &value)
    }

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
    public static func setFromJSON(decoder: inout JSONDecoder, value: inout BaseType?) throws {
        value = try decoder.scanner.nextBool()
    }

    public static func setFromJSON(decoder: inout JSONDecoder, value: inout [BaseType]) throws {
        let n = try decoder.scanner.nextBool()
        value.append(n)
    }

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
    public static func setFromJSON(decoder: inout JSONDecoder, value: inout BaseType?) throws {
        value = try decoder.scanner.nextQuotedString()
    }

    public static func setFromJSON(decoder: inout JSONDecoder, value: inout BaseType) throws {
        value = try decoder.scanner.nextQuotedString()
    }

    public static func setFromJSON(decoder: inout JSONDecoder, value: inout [BaseType]) throws {
        let result = try decoder.scanner.nextQuotedString()
        value.append(result)
    }

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
    public static func setFromJSON(decoder: inout JSONDecoder, value: inout Data?) throws {
        value = try decoder.scanner.nextBytesValue()
    }

    public static func setFromJSON(decoder: inout JSONDecoder, value: inout [BaseType]) throws {
        let result = try decoder.scanner.nextBytesValue()
        value.append(result)
    }

    public static func serializeJSONValue(encoder: inout JSONEncoder, value: Data) {
        encoder.putBytesValue(value: value)
    }
}

//
// Enum traits
//
extension Enum where RawValue == Int {
    public static func setFromJSON(decoder: inout JSONDecoder, value: inout Self?) throws {
        if decoder.scanner.skipOptionalNull() {
            value = Self(rawValue: 0)
            return
        }
        if let name = try decoder.scanner.nextOptionalQuotedString() {
            if let b = Self(jsonName: name) {
                value = b
                return
            }
        } else {
            let n = try decoder.scanner.nextSInt()
            if let i = Int(exactly: n) {
                value = Self(rawValue: i)
                return
            }
        }
        throw DecodingError.unrecognizedEnumValue
    }

    public static func setFromJSON(decoder: inout JSONDecoder, value: inout [Self]) throws {
        if let name = try decoder.scanner.nextOptionalQuotedString() {
            if let b = Self(protoName: name) {
                value.append(b)
                return
            }
        } else {
            let n = try decoder.scanner.nextSInt()
            if let i = Int(exactly: n) {
                let e = Self(rawValue: i)!
                value.append(e)
                return
            }
        }
        throw DecodingError.unrecognizedEnumValue
    }

    public static func serializeJSONValue(encoder: inout JSONEncoder, value: Self) {
        encoder.append(text: value.json)
    }
}

///
/// Messages
///
public extension Message {
    func serializeJSON() throws -> String {
        return try JSONEncodingVisitor(message: self).result
    }

    func serializeAnyJSON() throws -> String {
        return try JSONEncodingVisitor(message: self, anyTypeURL: anyTypeURL).result
    }

    static func serializeJSONValue(encoder: inout JSONEncoder, value: Self) throws {
        let json = try value.serializeJSON()
        encoder.append(text: json)
    }

    static func setFromJSON(decoder: inout JSONDecoder, value: inout Self?) throws {
        if decoder.scanner.skipOptionalNull() {
            // Fields of type google.protobuf.Value actually get set from 'null'
            if self == Google_Protobuf_Value.self {
                value = Self()
            } else {
                // All other message field types treat 'null' as an unset field
                value = nil
            }
            return
        }
        let message = try Self(decoder: &decoder)
        value = message
    }

    static func setFromJSON(decoder: inout JSONDecoder, value: inout [Self]) throws {
        let message = try Self(decoder: &decoder)
        value.append(message)
    }

    public init(json: String) throws {
        var decoder = JSONDecoder(json: json)
        if decoder.scanner.skipOptionalNull() {
            self.init()
        } else {
            try self.init(decoder: &decoder)
        }
        if !decoder.scanner.complete {
            throw DecodingError.trailingGarbage
        }
    }

    init(decoder: inout JSONDecoder) throws {
        self.init()
        try decoder.decodeFullObject(message: &self)
    }
}

