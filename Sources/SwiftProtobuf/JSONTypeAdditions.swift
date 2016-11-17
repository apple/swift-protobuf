// ProtobufRuntime/Sources/Protobuf/ProtobufJSONTypes.swift - JSON primitive types
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
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
/// Default implementations of JSON-specific coding/decoding methods
///
extension FieldType {
    public static func setFromJSONToken(token: JSONToken, value: inout BaseType?) throws {
        throw DecodingError.schemaMismatch
    }

    public static func setFromJSONToken(token: JSONToken, value: inout [BaseType]) throws {
        throw DecodingError.schemaMismatch
    }
}

///
/// Float traits
///
public extension ProtobufFloat {
    public static func setFromJSONToken(token: JSONToken, value: inout BaseType?) throws {
        if let n = token.asFloat {
            value = n
        } else {
            throw DecodingError.malformedJSONNumber
        }
    }


    public static func setFromJSONToken(token: JSONToken, value: inout [BaseType]) throws {
        if let n = token.asFloat {
            value.append(n)
        } else {
            throw DecodingError.malformedJSONNumber
        }
    }

    public static func serializeJSONValue(encoder: inout JSONEncoder, value: Float) {
        encoder.putFloatValue(value: value, quote: false)
    }

    public static func decodeJSONMapValue(jsonDecoder: inout JSONDecoder) throws -> Float? {
        if let t = try jsonDecoder.nextToken() {
            if case .null = t {
                return nil
            } else if let n = t.asFloat {
                return n
            }
            throw DecodingError.malformedJSONNumber
        }
        throw DecodingError.truncatedInput
    }
}

///
/// Double traits
///
public extension ProtobufDouble {

    public static func setFromJSONToken(token: JSONToken, value: inout BaseType?) throws {
        if let n = token.asDouble {
            value = n
        } else {
            throw DecodingError.malformedJSONNumber
        }
    }

    public static func setFromJSONToken(token: JSONToken, value: inout [BaseType]) throws {
        if let n = token.asDouble {
            value.append(n)
        } else {
            throw DecodingError.malformedJSONNumber
        }
    }

    public static func serializeJSONValue(encoder: inout JSONEncoder, value: Double) {
        encoder.putDoubleValue(value: value, quote: false)
    }

    public static func decodeJSONMapValue(jsonDecoder: inout JSONDecoder) throws -> Double? {
        if let t = try jsonDecoder.nextToken() {
            if case .null = t {
                return nil
            } else if let n = t.asDouble {
                return n
            }
            throw DecodingError.malformedJSONNumber
        }
        throw DecodingError.truncatedInput
    }
}

///
/// Int32 traits
///
public extension ProtobufInt32 {
    public static func setFromJSONToken(token: JSONToken, value: inout BaseType?) throws {
        if let n = token.asInt32 {
            value = n
        } else {
            throw DecodingError.malformedJSONNumber
        }
    }

    public static func setFromJSONToken(token: JSONToken, value: inout [BaseType]) throws {
        if let n = token.asInt32 {
            value.append(n)
        } else {
            throw DecodingError.malformedJSONNumber
        }
    }

    public static func serializeJSONValue(encoder: inout JSONEncoder, value: Int32) {
        encoder.putInt64(value: Int64(value), quote: false)
    }

    public static func decodeJSONMapValue(jsonDecoder: inout JSONDecoder) throws -> Int32? {
        if let t = try jsonDecoder.nextToken() {
            if case .null = t {
                return nil
            } else if let n = t.asInt32 {
                return n
            }
            throw DecodingError.malformedJSONNumber
        }
        throw DecodingError.truncatedInput
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
    public static func setFromJSONToken(token: JSONToken, value: inout BaseType?) throws {
        if let n = token.asInt64 {
            value = n
        } else {
            throw DecodingError.malformedJSONNumber
        }
    }

    public static func setFromJSONToken(token: JSONToken, value: inout [BaseType]) throws {
        if let n = token.asInt64 {
            value.append(n)
        } else {
            throw DecodingError.malformedJSONNumber
        }
    }

    public static func serializeJSONValue(encoder: inout JSONEncoder, value: Int64) {
        encoder.putInt64(value: value, quote: true)
    }

    public static func decodeJSONMapValue(jsonDecoder: inout JSONDecoder) throws -> Int64? {
        if let t = try jsonDecoder.nextToken() {
            if case .null = t {
                return nil
            } else if let n = t.asInt64 {
                return n
            }
            throw DecodingError.malformedJSONNumber
        }
        throw DecodingError.truncatedInput
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
    public static func setFromJSONToken(token: JSONToken, value: inout BaseType?) throws {
        if let n = token.asUInt32 {
            value = n
        } else {
            throw DecodingError.malformedJSONNumber
        }
    }

    public static func setFromJSONToken(token: JSONToken, value: inout [BaseType]) throws {
        if let n = token.asUInt32 {
            value.append(n)
        } else {
            throw DecodingError.malformedJSONNumber
        }
    }

    public static func serializeJSONValue(encoder: inout JSONEncoder, value: UInt32) {
        encoder.putUInt64(value: UInt64(value), quote: false)
    }

    public static func decodeJSONMapValue(jsonDecoder: inout JSONDecoder) throws -> UInt32? {
        if let t = try jsonDecoder.nextToken() {
            if case .null = t {
                return nil
            } else if let n = t.asUInt32 {
                return n
            }
            throw DecodingError.malformedJSONNumber
        }
        throw DecodingError.truncatedInput
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
    public static func setFromJSONToken(token: JSONToken, value: inout BaseType?) throws {
        if let n = token.asUInt64 {
            value = n
        } else {
            throw DecodingError.malformedJSONNumber
        }
    }

    public static func setFromJSONToken(token: JSONToken, value: inout [BaseType]) throws {
        if let n = token.asUInt64 {
            value.append(n)
        } else {
            throw DecodingError.malformedJSONNumber
        }
    }

    public static func serializeJSONValue(encoder: inout JSONEncoder, value: UInt64) {
        encoder.putUInt64(value: value, quote: true)
    }

    public static func decodeJSONMapValue(jsonDecoder: inout JSONDecoder) throws -> UInt64? {
        if let t = try jsonDecoder.nextToken() {
            if case .null = t {
                return nil
            } else if let n = t.asUInt64 {
                return n
            }
            throw DecodingError.malformedJSONNumber
        }
        throw DecodingError.truncatedInput
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
    public static func setFromJSONToken(token: JSONToken, value: inout BaseType?) throws {
        if let n = token.asInt32 {
            value = n
        } else {
            throw DecodingError.malformedJSONNumber
        }
    }

    public static func setFromJSONToken(token: JSONToken, value: inout [BaseType]) throws {
        if let n = token.asInt32 {
            value.append(n)
        } else {
            throw DecodingError.malformedJSONNumber
        }
    }

    public static func serializeJSONValue(encoder: inout JSONEncoder, value: Int32) {
        encoder.putInt64(value: Int64(value), quote: false)
    }

    public static func decodeJSONMapValue(jsonDecoder: inout JSONDecoder) throws -> Int32? {
        if let t = try jsonDecoder.nextToken() {
            if case .null = t {
                return nil
            } else if let n = t.asInt32 {
                return n
            }
            throw DecodingError.malformedJSONNumber
        }
        throw DecodingError.truncatedInput
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
    public static func setFromJSONToken(token: JSONToken, value: inout BaseType?) throws {
        if let n = token.asInt64 {
            value = n
        } else {
            throw DecodingError.malformedJSONNumber
        }
    }

    public static func setFromJSONToken(token: JSONToken, value: inout [BaseType]) throws {
        if let n = token.asInt64 {
            value.append(n)
        } else {
            throw DecodingError.malformedJSONNumber
        }
    }

    public static func serializeJSONValue(encoder: inout JSONEncoder, value: Int64) {
        encoder.putInt64(value: value, quote: true)
    }

    public static func decodeJSONMapValue(jsonDecoder: inout JSONDecoder) throws -> Int64? {
        if let t = try jsonDecoder.nextToken() {
            if case .null = t {
                return nil
            } else if let n = t.asInt64 {
                return n
            }
            throw DecodingError.malformedJSONNumber
        }
        throw DecodingError.truncatedInput
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
    public static func setFromJSONToken(token: JSONToken, value: inout BaseType?) throws {
        if let n = token.asUInt32 {
            value = n
        } else {
            throw DecodingError.malformedJSONNumber
        }
    }

    public static func setFromJSONToken(token: JSONToken, value: inout [BaseType]) throws {
        if let n = token.asUInt32 {
            value.append(n)
        } else {
            throw DecodingError.malformedJSONNumber
        }
    }

    public static func serializeJSONValue(encoder: inout JSONEncoder, value: UInt32) {
        encoder.putUInt64(value: UInt64(value), quote: false)
    }

    public static func decodeJSONMapValue(jsonDecoder: inout JSONDecoder) throws -> UInt32? {
        if let t = try jsonDecoder.nextToken() {
            if case .null = t {
                return nil
            } else if let n = t.asUInt32 {
                return n
            }
            throw DecodingError.malformedJSONNumber
        }
        throw DecodingError.truncatedInput
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
    public static func setFromJSONToken(token: JSONToken, value: inout BaseType?) throws {
        if let n = token.asUInt64 {
            value = n
        } else {
            throw DecodingError.malformedJSONNumber
        }
    }

    public static func setFromJSONToken(token: JSONToken, value: inout [BaseType]) throws {
        if let n = token.asUInt64 {
            value.append(n)
        } else {
            throw DecodingError.malformedJSONNumber
        }
    }

    public static func serializeJSONValue(encoder: inout JSONEncoder, value: UInt64) {
        encoder.putUInt64(value: value, quote: true)
    }
    public static func decodeJSONMapValue(jsonDecoder: inout JSONDecoder) throws -> UInt64? {
        if let t = try jsonDecoder.nextToken() {
            if case .null = t {
                return nil
            } else if let n = t.asUInt64 {
                return n
            }
            throw DecodingError.malformedJSONNumber
        }
        throw DecodingError.truncatedInput
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
    public static func setFromJSONToken(token: JSONToken, value: inout BaseType?) throws {
        if let n = token.asInt32 {
            value = n
        } else {
            throw DecodingError.malformedJSONNumber
        }
    }

    public static func setFromJSONToken(token: JSONToken, value: inout [BaseType]) throws {
        if let n = token.asInt32 {
            value.append(n)
        } else {
            throw DecodingError.malformedJSONNumber
        }
    }

    public static func serializeJSONValue(encoder: inout JSONEncoder, value: Int32) {
        encoder.putInt64(value: Int64(value), quote: false)
    }

    public static func decodeJSONMapValue(jsonDecoder: inout JSONDecoder) throws -> Int32? {
        if let t = try jsonDecoder.nextToken() {
            if case .null = t {
                return nil
            } else if let n = t.asInt32 {
                return n
            }
            throw DecodingError.malformedJSONNumber
        }
        throw DecodingError.truncatedInput
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
    public static func setFromJSONToken(token: JSONToken, value: inout BaseType?) throws {
        if let n = token.asInt64 {
            value = n
        } else {
            throw DecodingError.malformedJSONNumber
        }
    }

    public static func setFromJSONToken(token: JSONToken, value: inout [BaseType]) throws {
        if let n = token.asInt64 {
            value.append(n)
        } else {
            throw DecodingError.malformedJSONNumber
        }
    }

    public static func serializeJSONValue(encoder: inout JSONEncoder, value: Int64) {
        encoder.putInt64(value: value, quote: true)
    }

    public static func decodeJSONMapValue(jsonDecoder: inout JSONDecoder) throws -> Int64? {
        if let t = try jsonDecoder.nextToken() {
            if case .null = t {
                return nil
            } else if let n = t.asInt64 {
                return n
            }
            throw DecodingError.malformedJSONNumber
        }
        throw DecodingError.truncatedInput
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
    public static func setFromJSONToken(token: JSONToken, value: inout BaseType?) throws {
        if let n = token.asBoolean {
            value = n
        } else {
            throw DecodingError.malformedJSON
        }
    }

    public static func setFromJSONToken(token: JSONToken, value: inout [BaseType]) throws {
        if let n = token.asBoolean {
            value.append(n)
        } else {
            throw DecodingError.malformedJSON
        }
    }

    public static func serializeJSONValue(encoder: inout JSONEncoder, value: Bool) {
        encoder.putBoolValue(value: value, quote: false)
    }

    public static func decodeJSONMapValue(jsonDecoder: inout JSONDecoder) throws -> Bool? {
        if let t = try jsonDecoder.nextToken() {
            if case .null = t {
                return nil
            } else if let n = t.asBoolean {
                return n
            }
            throw DecodingError.malformedJSON
        }
        throw DecodingError.truncatedInput
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
    public static func setFromJSONToken(token: JSONToken, value: inout BaseType?) throws {
        if case .string(let s) = token {
            value = s
        } else {
            throw DecodingError.malformedJSON
        }
    }

    public static func setFromJSONToken(token: JSONToken, value: inout [BaseType]) throws {
        if case .string(let s) = token {
            value.append(s)
        } else {
            throw DecodingError.malformedJSON
        }
    }

    public static func serializeJSONValue(encoder: inout JSONEncoder, value: String) {
        encoder.putStringValue(value: value)
    }

    public static func decodeJSONMapValue(jsonDecoder: inout JSONDecoder) throws -> String? {
        switch try jsonDecoder.nextToken() {
        case .some(.string(let s)):
            return s
        case .some(.null):
            return nil
        case .some(_):
            throw DecodingError.malformedJSON
        default:
            throw DecodingError.truncatedInput
        }
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
    public static func setFromJSONToken(token: JSONToken, value: inout BaseType?) throws {
        if let n = token.asBytes {
            value = n
        } else {
            throw DecodingError.malformedJSON
        }
    }

    public static func setFromJSONToken(token: JSONToken, value: inout [BaseType]) throws {
        if let n = token.asBytes {
            value.append(n)
        } else {
            throw DecodingError.malformedJSON
        }
    }

    public static func serializeJSONValue(encoder: inout JSONEncoder, value: Data) {
        encoder.putBytesValue(value: value)
    }

    public static func decodeJSONMapValue(jsonDecoder: inout JSONDecoder) throws -> Data? {
        if let token = try jsonDecoder.nextToken() {
            switch token {
            case .string(_):
                if let bytes = token.asBytes {
                    return bytes
                }
            case .null:
                return nil
            default:
                throw DecodingError.malformedJSON
            }
        }
        throw DecodingError.truncatedInput
    }
}

//
// Enum traits
//
extension Enum where RawValue == Int {
    public static func setFromJSONToken(token: JSONToken, value: inout Self?) throws {
        switch token {
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

    public static func setFromJSONToken(token: JSONToken, value: inout [Self]) throws {
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

    public static func serializeJSONValue(encoder: inout JSONEncoder, value: Self) {
        encoder.append(text: value.json)
    }

    public static func decodeJSONMapValue(jsonDecoder: inout JSONDecoder) throws -> Self? {
        if let token = try jsonDecoder.nextToken() {
            switch token {
            case .null: return nil
            case .string(let s):
                if let b = Self(jsonName: s) {
                    return b
                }
                throw DecodingError.unrecognizedEnumValue
            case .number(_):
                if let n = token.asInt32 {
                    return Self(rawValue: Int(n))
                }
                throw DecodingError.malformedJSONNumber
            default:
                throw DecodingError.malformedJSON
            }
        }
        throw DecodingError.truncatedInput
    }
}

///
/// Messages
///
public extension Message {
    public static func decodeJSONMapValue(jsonDecoder: inout JSONDecoder) throws -> Self? {
        var m = Self()
        if try m.decodeFromJSON(jsonDecoder: &jsonDecoder) {
            return m
        } else {
            return nil
        }
    }

    func serializeJSON() throws -> String {
        return try JSONEncodingVisitor(message: self).result
    }

    func serializeAnyJSON() throws -> String {
        var jsonVisitor = JSONEncodingVisitor()
        try jsonVisitor.withAbstractVisitor {(visitor: inout Visitor) in
            try visitor.visitSingularField(fieldType: ProtobufString.self, value: anyTypeURL, protoFieldNumber: 1, protoFieldName: "type_url", jsonFieldName: "@type", swiftFieldName: "typeURL")
            try traverse(visitor: &visitor)
        }
        return jsonVisitor.result
    }

    // TODO: Can we get rid of this?  (This is leftover from an earlier generation of JSON encoding logic.)
    static func serializeJSONValue(encoder: inout JSONEncoder, value: Self) throws {
        let json = try value.serializeJSON()
        encoder.append(text: json)
    }

    // TODO: Can we get rid of this?  (This is leftover from an earlier generation of JSON decoding logic.)
    public mutating func decodeFromJSON(jsonDecoder: inout JSONDecoder) throws -> Bool {
        if let token = try jsonDecoder.nextToken() {
            switch token {
            case .beginObject:
                try decodeFromJSONObject(jsonDecoder: &jsonDecoder)
                return true
            case .null:
                break
            default:
                throw DecodingError.malformedJSON
            }
        }
        return false
    }

    /// Decode an instance of this message type from the provided JSON string.
    /// JSON "null" decodes to an empty object.
    public init(json: String) throws {
        self.init()
        var jsonDecoder = JSONDecoder(json: json)
        try jsonDecoder.decodeFullObject(message: &self)
        if !jsonDecoder.complete {
            throw DecodingError.trailingGarbage
        }
    }

    public init(json: String, extensions: ExtensionSet) throws {
        self.init()
        var jsonDecoder = JSONDecoder(json: json, extensions: extensions)
        try jsonDecoder.decodeFullObject(message: &self)
        if !jsonDecoder.complete {
            throw DecodingError.trailingGarbage
        }
    }

    public static func decodeFromJSONNull() throws -> Self? {
        return nil
    }

    public mutating func decodeFromJSONToken(token: JSONToken) throws {
        throw DecodingError.schemaMismatch
    }

    public mutating func decodeFromJSONArray(jsonDecoder: inout JSONDecoder) throws {
        throw DecodingError.schemaMismatch
    }

    // Open curly brace already consumed.
    public mutating func decodeFromJSONObject(jsonDecoder: inout JSONDecoder) throws {
        var key = ""
        var state = JSONDecoder.ObjectParseState.expectFirstKey
        while let token = try jsonDecoder.nextToken() {
            switch token {
            case .string(let s): // This is a key
                if state != .expectKey && state != .expectFirstKey {
                    throw DecodingError.malformedJSON
                }
                key = s
                state = .expectColon
            case .colon:
                if state != .expectColon {
                    throw DecodingError.malformedJSON
                }
                try jsonDecoder.decodeValue(key: key, message: &self)
                state = .expectComma
            case .comma:
                if state != .expectComma {
                    throw DecodingError.malformedJSON
                }
                state = .expectKey
            case .endObject:
                if state != .expectFirstKey && state != .expectComma {
                    throw DecodingError.malformedJSON
                }
                return
            default:
                throw DecodingError.malformedJSON
            }
        }
        throw DecodingError.truncatedInput
    }
}

///
/// Maps
///
public extension ProtobufMap {
}
