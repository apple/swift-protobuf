// ProtobufRuntime/Sources/Protobuf/ProtobufTextTypes.swift - Text format primitive types
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
/// of protobuf text format handling.
///
// -----------------------------------------------------------------------------

import Foundation
import Swift

extension FieldType {
    /// Set the value given a single text token
    public static func setFromTextToken(token: TextToken, value: inout BaseType?) throws {
        throw DecodingError.schemaMismatch
    }
    /// Update the repeated value given a single text token (used by repeated fields of basic types)
    public static func setFromTextToken(token: TextToken, value: inout [BaseType]) throws {
        throw DecodingError.schemaMismatch
    }
}

///
/// Float traits
///
public extension ProtobufFloat {
    public static func setFromTextToken(token: TextToken, value: inout BaseType?) throws {
        if let n = token.asFloat {
            value = n
        } else {
            throw DecodingError.malformedTextNumber
        }
    }


    public static func setFromTextToken(token: TextToken, value: inout [BaseType]) throws {
        if let n = token.asFloat {
            value.append(n)
        } else {
            throw DecodingError.malformedTextNumber
        }
    }

    public static func serializeTextValue(encoder: TextEncoder, value: Float) {
        encoder.putFloatValue(value: value, quote: false)
    }

    public static func decodeTextMapValue(textDecoder: inout TextDecoder) throws -> Float? {
        if let t = try textDecoder.nextToken() {
            if let n = t.asFloat {
                return n
            }
            throw DecodingError.malformedTextNumber
        }
        throw DecodingError.truncatedInput
    }
}

///
/// Double traits
///
public extension ProtobufDouble {

    public static func setFromTextToken(token: TextToken, value: inout BaseType?) throws {
        if let n = token.asDouble {
            value = n
        } else {
            throw DecodingError.malformedTextNumber
        }
    }

    public static func setFromTextToken(token: TextToken, value: inout [BaseType]) throws {
        if let n = token.asDouble {
            value.append(n)
        } else {
            throw DecodingError.malformedTextNumber
        }
    }

    public static func serializeTextValue(encoder: TextEncoder, value: Double) {
        encoder.putDoubleValue(value: value, quote: false)
    }

    public static func decodeTextMapValue(textDecoder: inout TextDecoder) throws -> Double? {
        if let t = try textDecoder.nextToken() {
            if let n = t.asDouble {
                return n
            }
            throw DecodingError.malformedTextNumber
        }
        throw DecodingError.truncatedInput
    }
}

///
/// Int32 traits
///
public extension ProtobufInt32 {
    public static func setFromTextToken(token: TextToken, value: inout BaseType?) throws {
        if let n = token.asInt32 {
            value = n
        } else {
            throw DecodingError.malformedTextNumber
        }
    }

    public static func setFromTextToken(token: TextToken, value: inout [BaseType]) throws {
        if let n = token.asInt32 {
            value.append(n)
        } else {
            throw DecodingError.malformedTextNumber
        }
    }

    public static func serializeTextValue(encoder: TextEncoder, value: Int32) {
        encoder.putInt64(value: Int64(value), quote: false)
    }

    public static func decodeTextMapValue(textDecoder: inout TextDecoder) throws -> Int32? {
        if let t = try textDecoder.nextToken() {
            if let n = t.asInt32 {
                return n
            }
            throw DecodingError.malformedTextNumber
        }
        throw DecodingError.truncatedInput
    }

    public static func serializeTextMapKey(encoder: TextEncoder, value: Int32) {
        encoder.putInt64(value: Int64(value), quote: true)
    }

    public static func decodeTextMapKey(token: TextToken) -> Int32? {
        return token.asInt32
    }
}

///
/// Int64 traits
///
public extension ProtobufInt64 {
    public static func setFromTextToken(token: TextToken, value: inout BaseType?) throws {
        if let n = token.asInt64 {
            value = n
        } else {
            throw DecodingError.malformedTextNumber
        }
    }

    public static func setFromTextToken(token: TextToken, value: inout [BaseType]) throws {
        if let n = token.asInt64 {
            value.append(n)
        } else {
            throw DecodingError.malformedTextNumber
        }
    }

    public static func serializeTextValue(encoder: TextEncoder, value: Int64) {
        encoder.putInt64(value: value, quote: true)
    }

    public static func decodeTextMapValue(textDecoder: inout TextDecoder) throws -> Int64? {
        if let t = try textDecoder.nextToken() {
            if let n = t.asInt64 {
                return n
            }
            throw DecodingError.malformedTextNumber
        }
        throw DecodingError.truncatedInput
    }

    public static func serializeTextMapKey(encoder: TextEncoder, value: Int64) {
        encoder.putInt64(value: value, quote: true)
    }

    public static func decodeTextMapKey(token: TextToken) -> Int64? {
        return token.asInt64
    }
}

///
/// UInt32 traits
///
public extension ProtobufUInt32 {
    public static func setFromTextToken(token: TextToken, value: inout BaseType?) throws {
        if let n = token.asUInt32 {
            value = n
        } else {
            throw DecodingError.malformedTextNumber
        }
    }

    public static func setFromTextToken(token: TextToken, value: inout [BaseType]) throws {
        if let n = token.asUInt32 {
            value.append(n)
        } else {
            throw DecodingError.malformedTextNumber
        }
    }

    public static func serializeTextValue(encoder: TextEncoder, value: UInt32) {
        encoder.putUInt64(value: UInt64(value), quote: false)
    }

    public static func decodeTextMapValue(textDecoder: inout TextDecoder) throws -> UInt32? {
        if let t = try textDecoder.nextToken() {
            if let n = t.asUInt32 {
                return n
            }
            throw DecodingError.malformedTextNumber
        }
        throw DecodingError.truncatedInput
    }

    public static func decodeTextMapKey(token: TextToken) -> UInt32? {
        return token.asUInt32
    }

    public static func serializeTextMapKey(encoder: TextEncoder, value: UInt32) {
        encoder.putUInt64(value: UInt64(value), quote: true)
    }
}

///
/// UInt64 traits
///
public extension ProtobufUInt64 {
    public static func setFromTextToken(token: TextToken, value: inout BaseType?) throws {
        if let n = token.asUInt64 {
            value = n
        } else {
            throw DecodingError.malformedTextNumber
        }
    }

    public static func setFromTextToken(token: TextToken, value: inout [BaseType]) throws {
        if let n = token.asUInt64 {
            value.append(n)
        } else {
            throw DecodingError.malformedTextNumber
        }
    }

    public static func serializeTextValue(encoder: TextEncoder, value: UInt64) {
        encoder.putUInt64(value: value, quote: true)
    }

    public static func decodeTextMapValue(textDecoder: inout TextDecoder) throws -> UInt64? {
        if let t = try textDecoder.nextToken() {
            if let n = t.asUInt64 {
                return n
            }
            throw DecodingError.malformedTextNumber
        }
        throw DecodingError.truncatedInput
    }

    public static func serializeTextMapKey(encoder: TextEncoder, value: UInt64) {
        encoder.putUInt64(value: value, quote: true)
    }

    public static func decodeTextMapKey(token: TextToken) -> UInt64? {
        return token.asUInt64
    }
}

///
/// SInt32 traits
///
public extension ProtobufSInt32 {
    public static func setFromTextToken(token: TextToken, value: inout BaseType?) throws {
        if let n = token.asInt32 {
            value = n
        } else {
            throw DecodingError.malformedTextNumber
        }
    }

    public static func setFromTextToken(token: TextToken, value: inout [BaseType]) throws {
        if let n = token.asInt32 {
            value.append(n)
        } else {
            throw DecodingError.malformedTextNumber
        }
    }

    public static func serializeTextValue(encoder: TextEncoder, value: Int32) {
        encoder.putInt64(value: Int64(value), quote: false)
    }

    public static func decodeTextMapValue(textDecoder: inout TextDecoder) throws -> Int32? {
        if let t = try textDecoder.nextToken() {
            if let n = t.asInt32 {
                return n
            }
            throw DecodingError.malformedTextNumber
        }
        throw DecodingError.truncatedInput
    }

    public static func decodeTextMapKey(token: TextToken) -> Int32? {
        return token.asInt32
    }

    public static func serializeTextMapKey(encoder: TextEncoder, value: Int32) {
        encoder.putInt64(value: Int64(value), quote: true)
    }
}

///
/// SInt64 traits
///
public extension ProtobufSInt64 {
    public static func setFromTextToken(token: TextToken, value: inout BaseType?) throws {
        if let n = token.asInt64 {
            value = n
        } else {
            throw DecodingError.malformedTextNumber
        }
    }

    public static func setFromTextToken(token: TextToken, value: inout [BaseType]) throws {
        if let n = token.asInt64 {
            value.append(n)
        } else {
            throw DecodingError.malformedTextNumber
        }
    }

    public static func serializeTextValue(encoder: TextEncoder, value: Int64) {
        encoder.putInt64(value: value, quote: true)
    }

    public static func decodeTextMapValue(textDecoder: inout TextDecoder) throws -> Int64? {
        if let t = try textDecoder.nextToken() {
            if let n = t.asInt64 {
                return n
            }
            throw DecodingError.malformedTextNumber
        }
        throw DecodingError.truncatedInput
    }

    public static func serializeTextMapKey(encoder: TextEncoder, value: Int64) {
        encoder.putInt64(value: value, quote: true)
    }

    public static func decodeTextMapKey(token: TextToken) -> Int64? {
        return token.asInt64
    }
}

///
/// Fixed32 traits
///
public extension ProtobufFixed32 {
    public static func setFromTextToken(token: TextToken, value: inout BaseType?) throws {
        if let n = token.asUInt32 {
            value = n
        } else {
            throw DecodingError.malformedTextNumber
        }
    }

    public static func setFromTextToken(token: TextToken, value: inout [BaseType]) throws {
        if let n = token.asUInt32 {
            value.append(n)
        } else {
            throw DecodingError.malformedTextNumber
        }
    }

    public static func serializeTextValue(encoder: TextEncoder, value: UInt32) {
        encoder.putUInt64(value: UInt64(value), quote: false)
    }

    public static func decodeTextMapValue(textDecoder: inout TextDecoder) throws -> UInt32? {
        if let t = try textDecoder.nextToken() {
            if let n = t.asUInt32 {
                return n
            }
            throw DecodingError.malformedTextNumber
        }
        throw DecodingError.truncatedInput
    }

    public static func serializeTextMapKey(encoder: TextEncoder, value: UInt32) {
        encoder.putUInt64(value: UInt64(value), quote: true)
    }

    public static func decodeTextMapKey(token: TextToken) -> UInt32? {
        return token.asUInt32
    }
}

///
/// Fixed64 traits
///
public extension ProtobufFixed64 {
    public static func setFromTextToken(token: TextToken, value: inout BaseType?) throws {
        if let n = token.asUInt64 {
            value = n
        } else {
            throw DecodingError.malformedTextNumber
        }
    }

    public static func setFromTextToken(token: TextToken, value: inout [BaseType]) throws {
        if let n = token.asUInt64 {
            value.append(n)
        } else {
            throw DecodingError.malformedTextNumber
        }
    }

    public static func serializeTextValue(encoder: TextEncoder, value: UInt64) {
        encoder.putUInt64(value: value, quote: true)
    }
    public static func decodeTextMapValue(textDecoder: inout TextDecoder) throws -> UInt64? {
        if let t = try textDecoder.nextToken() {
            if let n = t.asUInt64 {
                return n
            }
            throw DecodingError.malformedTextNumber
        }
        throw DecodingError.truncatedInput
    }

    public static func serializeTextMapKey(encoder: TextEncoder, value: UInt64) {
        encoder.putUInt64(value: value.littleEndian, quote: true)
    }

    public static func decodeTextMapKey(token: TextToken) -> UInt64? {
        return token.asUInt64
    }
}

///
/// SFixed32 traits
///
public extension ProtobufSFixed32 {
    public static func setFromTextToken(token: TextToken, value: inout BaseType?) throws {
        if let n = token.asInt32 {
            value = n
        } else {
            throw DecodingError.malformedTextNumber
        }
    }

    public static func setFromTextToken(token: TextToken, value: inout [BaseType]) throws {
        if let n = token.asInt32 {
            value.append(n)
        } else {
            throw DecodingError.malformedTextNumber
        }
    }

    public static func serializeTextValue(encoder: TextEncoder, value: Int32) {
        encoder.putInt64(value: Int64(value), quote: false)
    }

    public static func decodeTextMapValue(textDecoder: inout TextDecoder) throws -> Int32? {
        if let t = try textDecoder.nextToken() {
            if let n = t.asInt32 {
                return n
            }
            throw DecodingError.malformedTextNumber
        }
        throw DecodingError.truncatedInput
    }

    public static func serializeTextMapKey(encoder: TextEncoder, value: Int32) {
        encoder.putInt64(value: Int64(value), quote: true)
    }

    public static func decodeTextMapKey(token: TextToken) -> Int32? {
        return token.asInt32
    }
}

///
/// SFixed64 traits
///
public extension ProtobufSFixed64 {
    public static func setFromTextToken(token: TextToken, value: inout BaseType?) throws {
        if let n = token.asInt64 {
            value = n
        } else {
            throw DecodingError.malformedTextNumber
        }
    }

    public static func setFromTextToken(token: TextToken, value: inout [BaseType]) throws {
        if let n = token.asInt64 {
            value.append(n)
        } else {
            throw DecodingError.malformedTextNumber
        }
    }

    public static func serializeTextValue(encoder: TextEncoder, value: Int64) {
        encoder.putInt64(value: value, quote: true)
    }

    public static func decodeTextMapValue(textDecoder: inout TextDecoder) throws -> Int64? {
        if let t = try textDecoder.nextToken() {
            if let n = t.asInt64 {
                return n
            }
            throw DecodingError.malformedTextNumber
        }
        throw DecodingError.truncatedInput
    }

    public static func serializeTextMapKey(encoder: TextEncoder, value: Int64) {
        encoder.putInt64(value: value, quote: true)
    }

    public static func decodeTextMapKey(token: TextToken) -> Int64? {
        return token.asInt64
    }
}

///
/// Bool traits
///
public extension ProtobufBool {
    public static func setFromTextToken(token: TextToken, value: inout BaseType?) throws {
        if let n = token.asBoolean {
            value = n
        } else {
            throw DecodingError.malformedText
        }
    }

    public static func setFromTextToken(token: TextToken, value: inout [BaseType]) throws {
        if let n = token.asBoolean {
            value.append(n)
        } else {
            throw DecodingError.malformedText
        }
    }

    public static func serializeTextValue(encoder: TextEncoder, value: Bool) {
        encoder.putBoolValue(value: value, quote: false)
    }

    public static func decodeTextMapValue(textDecoder: inout TextDecoder) throws -> Bool? {
        if let t = try textDecoder.nextToken() {
            if let n = t.asBoolean {
                return n
            }
            throw DecodingError.malformedText
        }
        throw DecodingError.truncatedInput
    }

    public static func serializeTextMapKey(encoder: TextEncoder, value: Bool) {
        encoder.putBoolValue(value: value, quote: true)
    }

    public static func decodeTextMapKey(token: TextToken) -> Bool? {
        return token.asBoolean
    }
}

///
/// String traits
///
public extension ProtobufString {
    public static func setFromTextToken(token: TextToken, value: inout BaseType?) throws {
        if case .string(_) = token, let s = token.asString {
            value = s
        } else {
            throw DecodingError.malformedText
        }
    }

    public static func setFromTextToken(token: TextToken, value: inout [BaseType]) throws {
        if let s = token.asString {
            value.append(s)
        } else {
            throw DecodingError.malformedText
        }
    }

    public static func serializeTextValue(encoder: TextEncoder, value: String) {
        encoder.putStringValue(value: value)
    }

    public static func decodeTextMapValue(textDecoder: inout TextDecoder) throws -> String? {
        if let t = try textDecoder.nextToken() {
            if let s = t.asString {
                return s
            } else {
                throw DecodingError.malformedText
            }
        }
        throw DecodingError.truncatedInput
    }

    public static func serializeTextMapKey(encoder: TextEncoder, value: String) {
        encoder.putStringValue(value: value)
    }
    public static func decodeTextMapKey(token: TextToken) -> String? {
        return token.asString
    }
}

///
/// Bytes traits
///
public extension ProtobufBytes {
    public static func setFromTextToken(token: TextToken, value: inout BaseType?) throws {
        if let n = token.asBytes {
            value = n
        } else {
            throw DecodingError.malformedText
        }
    }

    public static func setFromTextToken(token: TextToken, value: inout [BaseType]) throws {
        if let n = token.asBytes {
            value.append(n)
        } else {
            throw DecodingError.malformedText
        }
    }

    public static func serializeTextValue(encoder: TextEncoder, value: Data) {
        encoder.putBytesValue(value: value)
    }

    public static func decodeTextMapValue(textDecoder: inout TextDecoder) throws -> Data? {
        if let token = try textDecoder.nextToken() {
            switch token {
            case .string:
                if let bytes = token.asBytes {
                    return bytes
                }
            default:
                throw DecodingError.malformedText
            }
        }
        throw DecodingError.truncatedInput
    }
}

//
// Enum traits
//
extension Enum where RawValue == Int {
    public static func setFromTextToken(token: TextToken, value: inout Self?) throws {
        switch token {
        case .identifier(let s):
            if let b = Self(protoName: s) {
                value = b
            } else {
                throw DecodingError.unrecognizedEnumValue
            }
        default:
            if token.isNumber {
                if let n = token.asInt32 {
                    value = Self(rawValue: Int(n))
                } else {
                    throw DecodingError.malformedTextNumber
                }
            } else {
                throw DecodingError.malformedText
            }
        }
    }

    public static func setFromTextToken(token: TextToken, value: inout [Self]) throws {
        switch token {
        case .identifier(let s):
            if let b = Self(protoName: s) {
                value.append(b)
            } else {
                throw DecodingError.unrecognizedEnumValue
            }
        default:
            if token.isNumber {
                if let n = token.asInt32 {
                    let e = Self(rawValue: Int(n))! // Note: Can never fail!
                    // TODO: Google's C++ implementation of text format rejects unknown enum values
                    value.append(e)
                } else {
                    throw DecodingError.malformedTextNumber
                }
            } else {
                throw DecodingError.malformedText
            }
        }
    }

    public static func serializeTextValue(encoder: TextEncoder, value: Self) {
        encoder.append(text: value.json.trimmingCharacters(in:["\""]))
    }

    public static func decodeTextMapValue(textDecoder: inout TextDecoder) throws -> Self? {
        if let token = try textDecoder.nextToken() {
            switch token {
            case .identifier(let s):
                if let b = Self(protoName: s) {
                    return b
                }
                throw DecodingError.unrecognizedEnumValue
            default:
                if token.isNumber {
                    if let n = token.asInt32 {
                        return Self(rawValue: Int(n))
                    }
                    throw DecodingError.malformedTextNumber
                } else {
                    throw DecodingError.malformedText
                }
            }
        }
        throw DecodingError.truncatedInput
    }
}

///
/// Messages
///
public extension Message {
    public static func decodeTextMapValue(textDecoder: inout TextDecoder) throws -> Self? {
        var m = Self()
        if try m.decodeFromText(textDecoder: &textDecoder) {
            return m
        } else {
            return nil
        }
    }

    public func serializeText() throws -> String {
        return try TextEncodingVisitor(message: self).result
    }

    static func serializeTextValue(encoder: TextEncoder, value: Self) throws {
        encoder.startObject()
        _ = try TextEncodingVisitor(message: value as Message, encoder: encoder)
        encoder.endObject()
    }

    mutating func decodeFromText(textDecoder: inout TextDecoder) throws -> Bool {
        if let token = try textDecoder.nextToken() {
            switch token {
            case .beginObject:
                try decodeFromTextObject(textDecoder: &textDecoder)
                return true
            default:
                throw DecodingError.malformedText
            }
        }
        return false
    }

    /// Decode an instance of this message type from the provided text format string.
    public init(text: String) throws {
        self.init()
        var textDecoder = TextDecoder(text: text)
        try textDecoder.decodeFullObject(message: &self, alreadyInsideObject: true)
        if !textDecoder.complete {
            throw DecodingError.trailingGarbage
        }
    }

    public init(text: String, extensions: ExtensionSet) throws {
        self.init()
        var textDecoder = TextDecoder(text: text, extensions: extensions)
        try textDecoder.decodeFullObject(message: &self, alreadyInsideObject: true)
        if !textDecoder.complete {
            throw DecodingError.trailingGarbage
        }
    }

    // Open curly brace already consumed.
    mutating func decodeFromTextObject(textDecoder: inout TextDecoder) throws {
        var key = ""
        var state = TextDecoder.ObjectParseState.expectFirstKey
        while let token = try textDecoder.nextToken() {
            switch token {
            case .beginObject:
                try textDecoder.decodeValue(key: key, message: &self, parsingObject: true)
                state = .expectKey
            case .identifier(let s):
                if state != .expectKey && state != .expectFirstKey {
                    throw DecodingError.malformedText
                }
                key = s
                state = .expectColon
            case .colon:
                try textDecoder.decodeValue(key: key, message: &self, parsingObject: try textDecoder.nextTokenIsBeginObject())
                state = .expectKey
            case .comma:
                if state != .expectComma {
                    throw DecodingError.malformedText
                }
                state = .expectKey
            case .endObject:
                state = .expectKey
                return
            default:
                throw DecodingError.malformedText
            }
        }
        if state != .expectKey && state != .expectFirstKey {
            throw DecodingError.malformedText
        }
   }
}
