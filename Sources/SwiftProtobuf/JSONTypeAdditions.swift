// Sources/SwiftProtobuf/JSONTypeAdditions.swift - JSON primitive types
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
/// of JSON handling.
///
// -----------------------------------------------------------------------------

import Foundation
import Swift

///
/// Float traits
///
public extension ProtobufFloat {
    public static func setFromJSON(decoder: JSONDecoder, value: inout BaseType?) throws {
        if let token = try decoder.nextToken() {
            if let n = token.asFloat {
                value = n
                return
            } else if token == .null {
                value = nil
                return
            }
        }
        throw DecodingError.malformedJSONNumber
    }


    public static func setFromJSON(decoder: JSONDecoder, value: inout [BaseType]) throws {
        if let token = try decoder.nextToken(), let n = token.asFloat {
            value.append(n)
        } else {
            throw DecodingError.malformedJSONNumber
        }
    }

    public static func serializeJSONValue(encoder: inout JSONEncoder, value: Float) {
        encoder.putFloatValue(value: value, quote: false)
    }
}

///
/// Double traits
///
public extension ProtobufDouble {

    public static func setFromJSON(decoder: JSONDecoder, value: inout BaseType?) throws {
        if let token = try decoder.nextToken() {
            if let n = token.asDouble {
                value = n
                return
            } else if token == .null {
                value = nil
                return
            }
        }
        throw DecodingError.malformedJSONNumber
    }

    public static func setFromJSON(decoder: JSONDecoder, value: inout [BaseType]) throws {
        if let token = try decoder.nextToken(), let n = token.asDouble {
            value.append(n)
        } else {
            throw DecodingError.malformedJSONNumber
        }
    }

    public static func serializeJSONValue(encoder: inout JSONEncoder, value: Double) {
        encoder.putDoubleValue(value: value, quote: false)
    }
}

///
/// Int32 traits
///
public extension ProtobufInt32 {
    public static func setFromJSON(decoder: JSONDecoder, value: inout BaseType?) throws {
        if let token = try decoder.nextToken() {
            if let n = token.asInt32 {
                value = n
                return
            } else if token == .null {
                value = nil
                return
            }
        }
        throw DecodingError.malformedJSONNumber
    }

    public static func setFromJSON(decoder: JSONDecoder, value: inout [BaseType]) throws {
        if let token = try decoder.nextToken(), let n = token.asInt32 {
            value.append(n)
        } else {
            throw DecodingError.malformedJSONNumber
        }
    }

    public static func serializeJSONValue(encoder: inout JSONEncoder, value: Int32) {
        encoder.putInt64(value: Int64(value), quote: false)
    }

    public static func serializeJSONMapKey(encoder: inout JSONEncoder, value: Int32) {
        encoder.putInt64(value: Int64(value), quote: true)
    }

    public static func decodeJSONMapKey(token: JSONToken) -> Int32? {
        return token.asInt32
    }
}

///
/// Int64 traits
///
public extension ProtobufInt64 {
    public static func setFromJSON(decoder: JSONDecoder, value: inout BaseType?) throws {
        if let token = try decoder.nextToken() {
            if let n = token.asInt64 {
                value = n
                return
            } else if token == .null {
                value = nil
                return
            }
        }
        throw DecodingError.malformedJSONNumber
    }

    public static func setFromJSON(decoder: JSONDecoder, value: inout [BaseType]) throws {
        if let token = try decoder.nextToken(), let n = token.asInt64 {
            value.append(n)
        } else {
            throw DecodingError.malformedJSONNumber
        }
    }

    public static func serializeJSONValue(encoder: inout JSONEncoder, value: Int64) {
        encoder.putInt64(value: value, quote: true)
    }

    public static func serializeJSONMapKey(encoder: inout JSONEncoder, value: Int64) {
        encoder.putInt64(value: value, quote: true)
    }

    public static func decodeJSONMapKey(token: JSONToken) -> Int64? {
        return token.asInt64
    }
}

///
/// UInt32 traits
///
public extension ProtobufUInt32 {
    public static func setFromJSON(decoder: JSONDecoder, value: inout BaseType?) throws {
        if let token = try decoder.nextToken() {
            if let n = token.asUInt32 {
                value = n
                return
            } else if token == .null {
                value = nil
                return
            }
        }
        throw DecodingError.malformedJSONNumber
    }

    public static func setFromJSON(decoder: JSONDecoder, value: inout [BaseType]) throws {
        if let token = try decoder.nextToken(), let n = token.asUInt32 {
            value.append(n)
        } else {
            throw DecodingError.malformedJSONNumber
        }
    }

    public static func serializeJSONValue(encoder: inout JSONEncoder, value: UInt32) {
        encoder.putUInt64(value: UInt64(value), quote: false)
    }

    public static func decodeJSONMapKey(token: JSONToken) -> UInt32? {
        return token.asUInt32
    }

    public static func serializeJSONMapKey(encoder: inout JSONEncoder, value: UInt32) {
        encoder.putUInt64(value: UInt64(value), quote: true)
    }
}

///
/// UInt64 traits
///
public extension ProtobufUInt64 {
    public static func setFromJSON(decoder: JSONDecoder, value: inout BaseType?) throws {
        if let token = try decoder.nextToken() {
            if let n = token.asUInt64 {
                value = n
                return
            } else if token == .null {
                value = nil
                return
            }
        }
        throw DecodingError.malformedJSONNumber
    }

    public static func setFromJSON(decoder: JSONDecoder, value: inout [BaseType]) throws {
        if let token = try decoder.nextToken(), let n = token.asUInt64 {
            value.append(n)
        } else {
            throw DecodingError.malformedJSONNumber
        }
    }

    public static func serializeJSONValue(encoder: inout JSONEncoder, value: UInt64) {
        encoder.putUInt64(value: value, quote: true)
    }

    public static func serializeJSONMapKey(encoder: inout JSONEncoder, value: UInt64) {
        encoder.putUInt64(value: value, quote: true)
    }

    public static func decodeJSONMapKey(token: JSONToken) -> UInt64? {
        return token.asUInt64
    }
}

///
/// SInt32 traits
///
public extension ProtobufSInt32 {
    public static func setFromJSON(decoder: JSONDecoder, value: inout BaseType?) throws {
        if let token = try decoder.nextToken() {
            if let n = token.asInt32 {
                value = n
                return
            } else if token == .null {
                value = nil
                return
            }
        }
        throw DecodingError.malformedJSONNumber
    }

    public static func setFromJSON(decoder: JSONDecoder, value: inout [BaseType]) throws {
        if let token = try decoder.nextToken(), let n = token.asInt32 {
            value.append(n)
        } else {
            throw DecodingError.malformedJSONNumber
        }
    }

    public static func serializeJSONValue(encoder: inout JSONEncoder, value: Int32) {
        encoder.putInt64(value: Int64(value), quote: false)
    }

    public static func decodeJSONMapKey(token: JSONToken) -> Int32? {
        return token.asInt32
    }

    public static func serializeJSONMapKey(encoder: inout JSONEncoder, value: Int32) {
        encoder.putInt64(value: Int64(value), quote: true)
    }
}

///
/// SInt64 traits
///
public extension ProtobufSInt64 {
    public static func setFromJSON(decoder: JSONDecoder, value: inout BaseType?) throws {
        if let token = try decoder.nextToken() {
            if let n = token.asInt64 {
                value = n
                return
            } else if token == .null {
                value = nil
                return
            }
        }
        throw DecodingError.malformedJSONNumber
    }

    public static func setFromJSON(decoder: JSONDecoder, value: inout [BaseType]) throws {
        if let token = try decoder.nextToken(), let n = token.asInt64 {
            value.append(n)
        } else {
            throw DecodingError.malformedJSONNumber
        }
    }

    public static func serializeJSONValue(encoder: inout JSONEncoder, value: Int64) {
        encoder.putInt64(value: value, quote: true)
    }

    public static func serializeJSONMapKey(encoder: inout JSONEncoder, value: Int64) {
        encoder.putInt64(value: value, quote: true)
    }

    public static func decodeJSONMapKey(token: JSONToken) -> Int64? {
        return token.asInt64
    }
}

///
/// Fixed32 traits
///
public extension ProtobufFixed32 {
    public static func setFromJSON(decoder: JSONDecoder, value: inout BaseType?) throws {
        if let token = try decoder.nextToken() {
            if let n = token.asUInt32 {
                value = n
                return
            } else if token == .null {
                value = nil
                return
            }
        }
        throw DecodingError.malformedJSONNumber
    }

    public static func setFromJSON(decoder: JSONDecoder, value: inout [BaseType]) throws {
        if let token = try decoder.nextToken(), let n = token.asUInt32 {
            value.append(n)
        } else {
            throw DecodingError.malformedJSONNumber
        }
    }

    public static func serializeJSONValue(encoder: inout JSONEncoder, value: UInt32) {
        encoder.putUInt64(value: UInt64(value), quote: false)
    }

    public static func serializeJSONMapKey(encoder: inout JSONEncoder, value: UInt32) {
        encoder.putUInt64(value: UInt64(value), quote: true)
    }

    public static func decodeJSONMapKey(token: JSONToken) -> UInt32? {
        return token.asUInt32
    }
}

///
/// Fixed64 traits
///
public extension ProtobufFixed64 {
    public static func setFromJSON(decoder: JSONDecoder, value: inout BaseType?) throws {
        if let token = try decoder.nextToken() {
            if let n = token.asUInt64 {
                value = n
                return
            } else if token == .null {
                value = nil
                return
            }
        }
        throw DecodingError.malformedJSONNumber
    }

    public static func setFromJSON(decoder: JSONDecoder, value: inout [BaseType]) throws {
        if let token = try decoder.nextToken(), let n = token.asUInt64 {
            value.append(n)
        } else {
            throw DecodingError.malformedJSONNumber
        }
    }

    public static func serializeJSONValue(encoder: inout JSONEncoder, value: UInt64) {
        encoder.putUInt64(value: value, quote: true)
    }

    public static func serializeJSONMapKey(encoder: inout JSONEncoder, value: UInt64) {
        encoder.putUInt64(value: value.littleEndian, quote: true)
    }

    public static func decodeJSONMapKey(token: JSONToken) -> UInt64? {
        return token.asUInt64
    }
}

///
/// SFixed32 traits
///
public extension ProtobufSFixed32 {
    public static func setFromJSON(decoder: JSONDecoder, value: inout BaseType?) throws {
        if let token = try decoder.nextToken() {
            if let n = token.asInt32 {
                value = n
                return
            } else if token == .null {
                value = nil
                return
            }
        }
        throw DecodingError.malformedJSONNumber
    }

    public static func setFromJSON(decoder: JSONDecoder, value: inout [BaseType]) throws {
        if let token = try decoder.nextToken(), let n = token.asInt32 {
            value.append(n)
        } else {
            throw DecodingError.malformedJSONNumber
        }
    }

    public static func serializeJSONValue(encoder: inout JSONEncoder, value: Int32) {
        encoder.putInt64(value: Int64(value), quote: false)
    }

    public static func serializeJSONMapKey(encoder: inout JSONEncoder, value: Int32) {
        encoder.putInt64(value: Int64(value), quote: true)
    }

    public static func decodeJSONMapKey(token: JSONToken) -> Int32? {
        return token.asInt32
    }
}

///
/// SFixed64 traits
///
public extension ProtobufSFixed64 {
    public static func setFromJSON(decoder: JSONDecoder, value: inout BaseType?) throws {
        if let token = try decoder.nextToken() {
            if let n = token.asInt64 {
                value = n
                return
            } else if token == .null {
                value = nil
                return
            }
        }
        throw DecodingError.malformedJSONNumber
    }

    public static func setFromJSON(decoder: JSONDecoder, value: inout [BaseType]) throws {
        if let token = try decoder.nextToken(), let n = token.asInt64 {
            value.append(n)
        } else {
            throw DecodingError.malformedJSONNumber
        }
    }

    public static func serializeJSONValue(encoder: inout JSONEncoder, value: Int64) {
        encoder.putInt64(value: value, quote: true)
    }

    public static func serializeJSONMapKey(encoder: inout JSONEncoder, value: Int64) {
        encoder.putInt64(value: value, quote: true)
    }

    public static func decodeJSONMapKey(token: JSONToken) -> Int64? {
        return token.asInt64
    }
}

///
/// Bool traits
///
public extension ProtobufBool {
    public static func setFromJSON(decoder: JSONDecoder, value: inout BaseType?) throws {
        if let token = try decoder.nextToken() {
            if let n = token.asBoolean {
                value = n
                return
            } else if token == .null {
                value = nil
                return
            }
        }
        throw DecodingError.malformedJSON
    }

    public static func setFromJSON(decoder: JSONDecoder, value: inout [BaseType]) throws {
        if let token = try decoder.nextToken(), let n = token.asBoolean {
            value.append(n)
        } else {
            throw DecodingError.malformedJSON
        }
    }

    public static func serializeJSONValue(encoder: inout JSONEncoder, value: Bool) {
        encoder.putBoolValue(value: value, quote: false)
    }

    public static func serializeJSONMapKey(encoder: inout JSONEncoder, value: Bool) {
        encoder.putBoolValue(value: value, quote: true)
    }

    public static func decodeJSONMapKey(token: JSONToken) -> Bool? {
        return token.asBooleanMapKey
    }
}

///
/// String traits
///
public extension ProtobufString {
    public static func setFromJSON(decoder: JSONDecoder, value: inout BaseType?) throws {
        if let token = try decoder.nextToken() {
            switch token {
            case .string(let s):
                value = s
                return
            case .null:
                value = nil
                return
            default:
                break
            }
        }
        throw DecodingError.malformedJSON
    }

    public static func setFromJSON(decoder: JSONDecoder, value: inout [BaseType]) throws {
        if let token = try decoder.nextToken(), case .string(let s) = token {
            value.append(s)
        } else {
            throw DecodingError.malformedJSON
        }
    }

    public static func serializeJSONValue(encoder: inout JSONEncoder, value: String) {
        encoder.putStringValue(value: value)
    }

    public static func serializeJSONMapKey(encoder: inout JSONEncoder, value: String) {
        encoder.putStringValue(value: value)
    }
    public static func decodeJSONMapKey(token: JSONToken) -> String? {
        if case .string(let s) = token {
            return s
        }
        return nil
    }
}

///
/// Bytes traits
///
public extension ProtobufBytes {
    public static func setFromJSON(decoder: JSONDecoder, value: inout BaseType?) throws {
        if let token = try decoder.nextToken() {
            if let n = token.asBytes {
                value = n
                return
            } else if token == .null {
                value = nil
                return
            }
        }
        throw DecodingError.malformedJSON
    }

    public static func setFromJSON(decoder: JSONDecoder, value: inout [BaseType]) throws {
        if let token = try decoder.nextToken(), let n = token.asBytes {
            value.append(n)
        } else {
            throw DecodingError.malformedJSON
        }
    }

    public static func serializeJSONValue(encoder: inout JSONEncoder, value: Data) {
        encoder.putBytesValue(value: value)
    }
}

//
// Enum traits
//
extension Enum where RawValue == Int {
    public static func setFromJSON(decoder: JSONDecoder, value: inout Self?) throws {
        if let token = try decoder.nextToken() {
            switch token {
            case .null:
                value = Self(rawValue: 0)! // Note: Can never fail!
            case .string(let s):
                if let b = Self(jsonName: s) {
                    value = b
                } else {
                    throw DecodingError.unrecognizedEnumValue
                }
            case .number(_):
                if let n = token.asInt32 {
                    value = Self(rawValue: Int(n))
                } else {
                    throw DecodingError.malformedJSONNumber
                }
            default:
                throw DecodingError.malformedJSON
            }
        }
    }

    public static func setFromJSON(decoder: JSONDecoder, value: inout [Self]) throws {
        if let token = try decoder.nextToken() {
            switch token {
            case .string(let s):
                if let b = Self(jsonName: s) {
                    value.append(b)
                } else {
                    throw DecodingError.unrecognizedEnumValue
                }
            case .number(_):
                if let n = token.asInt32 {
                    let e = Self(rawValue: Int(n))! // Note: Can never fail!
                    value.append(e)
                } else {
                    throw DecodingError.malformedJSONNumber
                }
            default:
                throw DecodingError.malformedJSON
            }
        }
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

    /// Decode an instance of this message type from the provided JSON string.
    /// JSON "null" decodes to an empty object.
    public init(json: String) throws {
        self.init()
        let decoder = JSONDecoder(json: json)
        try setFromJSON(decoder: decoder)
        if !decoder.complete {
            throw DecodingError.trailingGarbage
        }
    }

    mutating func setFromJSON(decoder: JSONDecoder) throws {
        guard let nameProviding = (self as? ProtoNameProviding) else {
            throw DecodingError.missingFieldNames
        }
        let fieldNames = type(of: nameProviding)._protobuf_fieldNames
        if try decoder.skipOptionalNull() {
            return
        }
        if try decoder.isObjectEmpty() {
            return
        }
        while true {
            let key = try decoder.nextKey()
            if let protoFieldNumber = fieldNames.fieldNumber(forJSONName: key) {
                var mutableDecoder = decoder
                try decodeField(setter: &mutableDecoder, protoFieldNumber: protoFieldNumber)
            } else {
                _ = try decoder.skip()
            }
            if let token = try decoder.nextToken() {
                switch token {
                case .endObject:
                    return
                case .comma:
                    break
                default:
                    throw DecodingError.malformedJSON
                }
            } else {
                throw DecodingError.truncatedInput
            }
        }
    }

    static func setFromJSON(decoder: JSONDecoder, value: inout Self?) throws {
        if try decoder.skipOptionalNull() {
            if Self.self == Google_Protobuf_Value.self {
                value = Self()
                return
            } else {
                value = nil
                return
            }
        }
        var m = Self()
        try m.setFromJSON(decoder: decoder)
        value = m
    }

    static func setFromJSON(decoder: JSONDecoder, value: inout [Self]) throws {
        if try decoder.skipOptionalNull() {
            if Self.self == Google_Protobuf_Value.self {
                value.append(Self())
                return
            } else {
                throw DecodingError.malformedJSON
            }
        }
        var m = Self()
        try m.setFromJSON(decoder: decoder)
        value.append(m)
    }
}
