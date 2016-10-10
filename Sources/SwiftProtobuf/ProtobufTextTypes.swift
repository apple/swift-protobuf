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
/// of text format handling.
///
// -----------------------------------------------------------------------------

import Foundation
import Swift

public protocol ProtobufTextCodableType: ProtobufTypePropertiesBase {
    static func serializeTextValue(encoder: inout ProtobufTextEncoder, value: BaseType) throws
    /// Consume tokens from a text format decoder
    static func decodeTextMapFieldValue(textDecoder: inout ProtobufTextDecoder) throws -> BaseType?
    /// Set the value given a single text token
    static func setFromTextToken(token: ProtobufTextToken, value: inout BaseType?) throws
    /// Update the repeated value given a single text token (used by repeated fields of basic types)
    static func setFromTextToken(token: ProtobufTextToken, value: inout [BaseType]) throws
}

extension ProtobufTextCodableType {
    public static func setFromTextToken(token: ProtobufTextToken, value: inout BaseType?) throws {
        throw ProtobufDecodingError.schemaMismatch
    }
    
    public static func setFromTextToken(token: ProtobufTextToken, value: inout [BaseType]) throws {
        throw ProtobufDecodingError.schemaMismatch
    }
}

public protocol ProtobufTextCodableMapKeyType: ProtobufTypePropertiesBase {
    static func serializeTextMapKeyValue(encoder: inout ProtobufTextEncoder, value: BaseType)
    static func decodeTextMapKeyValue(token: ProtobufTextToken) throws -> BaseType?
}

///
/// Float traits
///
public extension ProtobufFloat {
    public static func setFromTextToken(token: ProtobufTextToken, value: inout BaseType?) throws {
        if let n = token.asFloat {
            value = n
        } else {
            throw ProtobufDecodingError.malformedJSONNumber
        }
    }
    
    
    public static func setFromTextToken(token: ProtobufTextToken, value: inout [BaseType]) throws {
        if let n = token.asFloat {
            value.append(n)
        } else {
            throw ProtobufDecodingError.malformedJSONNumber
        }
    }
    
    public static func serializeTextValue(encoder: inout ProtobufTextEncoder, value: Float) {
        encoder.putFloatValue(value: value, quote: false)
    }
    
    public static func decodeTextMapFieldValue(textDecoder: inout ProtobufTextDecoder) throws -> Float? {
        if let t = try textDecoder.nextToken() {
            if case .null = t {
                return nil
            } else if let n = t.asFloat {
                return n
            }
            throw ProtobufDecodingError.malformedJSONNumber
        }
        throw ProtobufDecodingError.truncatedInput
    }
}

///
/// Double traits
///
public extension ProtobufDouble {
    
    public static func setFromTextToken(token: ProtobufTextToken, value: inout BaseType?) throws {
        if let n = token.asDouble {
            value = n
        } else {
            throw ProtobufDecodingError.malformedJSONNumber
        }
    }
    
    public static func setFromTextToken(token: ProtobufTextToken, value: inout [BaseType]) throws {
        if let n = token.asDouble {
            value.append(n)
        } else {
            throw ProtobufDecodingError.malformedJSONNumber
        }
    }
    
    public static func serializeTextValue(encoder: inout ProtobufTextEncoder, value: Double) {
        encoder.putDoubleValue(value: value, quote: false)
    }
    
    public static func decodeTextMapFieldValue(textDecoder: inout ProtobufTextDecoder) throws -> Double? {
        if let t = try textDecoder.nextToken() {
            if case .null = t {
                return nil
            } else if let n = t.asDouble {
                return n
            }
            throw ProtobufDecodingError.malformedJSONNumber
        }
        throw ProtobufDecodingError.truncatedInput
    }
}

///
/// Int32 traits
///
public extension ProtobufInt32 {
    public static func setFromTextToken(token: ProtobufTextToken, value: inout BaseType?) throws {
        if let n = token.asInt32 {
            value = n
        } else {
            throw ProtobufDecodingError.malformedJSONNumber
        }
    }
    
    public static func setFromTextToken(token: ProtobufTextToken, value: inout [BaseType]) throws {
        if let n = token.asInt32 {
            value.append(n)
        } else {
            throw ProtobufDecodingError.malformedJSONNumber
        }
    }
    
    public static func serializeTextValue(encoder: inout ProtobufTextEncoder, value: Int32) {
        encoder.putInt64(value: Int64(value), quote: false)
    }
    
    public static func decodeTextMapFieldValue(textDecoder: inout ProtobufTextDecoder) throws -> Int32? {
        if let t = try textDecoder.nextToken() {
            if case .null = t {
                return nil
            } else if let n = t.asInt32 {
                return n
            }
            throw ProtobufDecodingError.malformedJSONNumber
        }
        throw ProtobufDecodingError.truncatedInput
    }
    
    public static func serializeTextMapKeyValue(encoder: inout ProtobufTextEncoder, value: Int32) {
        encoder.putInt64(value: Int64(value), quote: true)
    }
    
    public static func decodeTextMapKeyValue(token: ProtobufTextToken) -> Int32? {
        return token.asInt32
    }
}

///
/// Int64 traits
///
public extension ProtobufInt64 {
    public static func setFromTextToken(token: ProtobufTextToken, value: inout BaseType?) throws {
        if let n = token.asInt64 {
            value = n
        } else {
            throw ProtobufDecodingError.malformedJSONNumber
        }
    }
    
    public static func setFromTextToken(token: ProtobufTextToken, value: inout [BaseType]) throws {
        if let n = token.asInt64 {
            value.append(n)
        } else {
            throw ProtobufDecodingError.malformedJSONNumber
        }
    }
    
    public static func serializeTextValue(encoder: inout ProtobufTextEncoder, value: Int64) {
        encoder.putInt64(value: value, quote: true)
    }
    
    public static func decodeTextMapFieldValue(textDecoder: inout ProtobufTextDecoder) throws -> Int64? {
        if let t = try textDecoder.nextToken() {
            if case .null = t {
                return nil
            } else if let n = t.asInt64 {
                return n
            }
            throw ProtobufDecodingError.malformedJSONNumber
        }
        throw ProtobufDecodingError.truncatedInput
    }
    
    public static func serializeTextMapKeyValue(encoder: inout ProtobufTextEncoder, value: Int64) {
        encoder.putInt64(value: value, quote: true)
    }
    
    public static func decodeTextMapKeyValue(token: ProtobufTextToken) -> Int64? {
        return token.asInt64
    }
}

///
/// UInt32 traits
///
public extension ProtobufUInt32 {
    public static func setFromTextToken(token: ProtobufTextToken, value: inout BaseType?) throws {
        if let n = token.asUInt32 {
            value = n
        } else {
            throw ProtobufDecodingError.malformedJSONNumber
        }
    }
    
    public static func setFromTextToken(token: ProtobufTextToken, value: inout [BaseType]) throws {
        if let n = token.asUInt32 {
            value.append(n)
        } else {
            throw ProtobufDecodingError.malformedJSONNumber
        }
    }
    
    public static func serializeTextValue(encoder: inout ProtobufTextEncoder, value: UInt32) {
        encoder.putUInt64(value: UInt64(value), quote: false)
    }
    
    public static func decodeTextMapFieldValue(textDecoder: inout ProtobufTextDecoder) throws -> UInt32? {
        if let t = try textDecoder.nextToken() {
            if case .null = t {
                return nil
            } else if let n = t.asUInt32 {
                return n
            }
            throw ProtobufDecodingError.malformedJSONNumber
        }
        throw ProtobufDecodingError.truncatedInput
    }
    
    public static func decodeTextMapKeyValue(token: ProtobufTextToken) -> UInt32? {
        return token.asUInt32
    }
    
    public static func serializeTextMapKeyValue(encoder: inout ProtobufTextEncoder, value: UInt32) {
        encoder.putUInt64(value: UInt64(value), quote: true)
    }
}

///
/// UInt64 traits
///
public extension ProtobufUInt64 {
    public static func setFromTextToken(token: ProtobufTextToken, value: inout BaseType?) throws {
        if let n = token.asUInt64 {
            value = n
        } else {
            throw ProtobufDecodingError.malformedJSONNumber
        }
    }
    
    public static func setFromTextToken(token: ProtobufTextToken, value: inout [BaseType]) throws {
        if let n = token.asUInt64 {
            value.append(n)
        } else {
            throw ProtobufDecodingError.malformedJSONNumber
        }
    }
    
    public static func serializeTextValue(encoder: inout ProtobufTextEncoder, value: UInt64) {
        encoder.putUInt64(value: value, quote: true)
    }
    
    public static func decodeTextMapFieldValue(textDecoder: inout ProtobufTextDecoder) throws -> UInt64? {
        if let t = try textDecoder.nextToken() {
            if case .null = t {
                return nil
            } else if let n = t.asUInt64 {
                return n
            }
            throw ProtobufDecodingError.malformedJSONNumber
        }
        throw ProtobufDecodingError.truncatedInput
    }
    
    public static func serializeTextMapKeyValue(encoder: inout ProtobufTextEncoder, value: UInt64) {
        encoder.putUInt64(value: value, quote: true)
    }
    
    public static func decodeTextMapKeyValue(token: ProtobufTextToken) -> UInt64? {
        return token.asUInt64
    }
}

///
/// SInt32 traits
///
public extension ProtobufSInt32 {
    public static func setFromTextToken(token: ProtobufTextToken, value: inout BaseType?) throws {
        if let n = token.asInt32 {
            value = n
        } else {
            throw ProtobufDecodingError.malformedJSONNumber
        }
    }
    
    public static func setFromTextToken(token: ProtobufTextToken, value: inout [BaseType]) throws {
        if let n = token.asInt32 {
            value.append(n)
        } else {
            throw ProtobufDecodingError.malformedJSONNumber
        }
    }
    
    public static func serializeTextValue(encoder: inout ProtobufTextEncoder, value: Int32) {
        encoder.putInt64(value: Int64(value), quote: false)
    }
    
    public static func decodeTextMapFieldValue(textDecoder: inout ProtobufTextDecoder) throws -> Int32? {
        if let t = try textDecoder.nextToken() {
            if case .null = t {
                return nil
            } else if let n = t.asInt32 {
                return n
            }
            throw ProtobufDecodingError.malformedJSONNumber
        }
        throw ProtobufDecodingError.truncatedInput
    }
    
    public static func decodeTextMapKeyValue(token: ProtobufTextToken) -> Int32? {
        return token.asInt32
    }
    
    public static func serializeTextMapKeyValue(encoder: inout ProtobufTextEncoder, value: Int32) {
        encoder.putInt64(value: Int64(value), quote: true)
    }
}

///
/// SInt64 traits
///
public extension ProtobufSInt64 {
    public static func setFromTextToken(token: ProtobufTextToken, value: inout BaseType?) throws {
        if let n = token.asInt64 {
            value = n
        } else {
            throw ProtobufDecodingError.malformedJSONNumber
        }
    }
    
    public static func setFromTextToken(token: ProtobufTextToken, value: inout [BaseType]) throws {
        if let n = token.asInt64 {
            value.append(n)
        } else {
            throw ProtobufDecodingError.malformedJSONNumber
        }
    }
    
    public static func serializeTextValue(encoder: inout ProtobufTextEncoder, value: Int64) {
        encoder.putInt64(value: value, quote: true)
    }
    
    public static func decodeTextMapFieldValue(textDecoder: inout ProtobufTextDecoder) throws -> Int64? {
        if let t = try textDecoder.nextToken() {
            if case .null = t {
                return nil
            } else if let n = t.asInt64 {
                return n
            }
            throw ProtobufDecodingError.malformedJSONNumber
        }
        throw ProtobufDecodingError.truncatedInput
    }
    
    public static func serializeTextMapKeyValue(encoder: inout ProtobufTextEncoder, value: Int64) {
        encoder.putInt64(value: value, quote: true)
    }
    
    public static func decodeTextMapKeyValue(token: ProtobufTextToken) -> Int64? {
        return token.asInt64
    }
}

///
/// Fixed32 traits
///
public extension ProtobufFixed32 {
    public static func setFromTextToken(token: ProtobufTextToken, value: inout BaseType?) throws {
        if let n = token.asUInt32 {
            value = n
        } else {
            throw ProtobufDecodingError.malformedJSONNumber
        }
    }
    
    public static func setFromTextToken(token: ProtobufTextToken, value: inout [BaseType]) throws {
        if let n = token.asUInt32 {
            value.append(n)
        } else {
            throw ProtobufDecodingError.malformedJSONNumber
        }
    }
    
    public static func serializeTextValue(encoder: inout ProtobufTextEncoder, value: UInt32) {
        encoder.putUInt64(value: UInt64(value), quote: false)
    }
    
    public static func decodeTextMapFieldValue(textDecoder: inout ProtobufTextDecoder) throws -> UInt32? {
        if let t = try textDecoder.nextToken() {
            if case .null = t {
                return nil
            } else if let n = t.asUInt32 {
                return n
            }
            throw ProtobufDecodingError.malformedJSONNumber
        }
        throw ProtobufDecodingError.truncatedInput
    }
    
    public static func serializeTextMapKeyValue(encoder: inout ProtobufTextEncoder, value: UInt32) {
        encoder.putUInt64(value: UInt64(value), quote: true)
    }
    
    public static func decodeTextMapKeyValue(token: ProtobufTextToken) -> UInt32? {
        return token.asUInt32
    }
}

///
/// Fixed64 traits
///
public extension ProtobufFixed64 {
    public static func setFromTextToken(token: ProtobufTextToken, value: inout BaseType?) throws {
        if let n = token.asUInt64 {
            value = n
        } else {
            throw ProtobufDecodingError.malformedJSONNumber
        }
    }
    
    public static func setFromTextToken(token: ProtobufTextToken, value: inout [BaseType]) throws {
        if let n = token.asUInt64 {
            value.append(n)
        } else {
            throw ProtobufDecodingError.malformedJSONNumber
        }
    }
    
    public static func serializeTextValue(encoder: inout ProtobufTextEncoder, value: UInt64) {
        encoder.putUInt64(value: value, quote: true)
    }
    public static func decodeTextMapFieldValue(textDecoder: inout ProtobufTextDecoder) throws -> UInt64? {
        if let t = try textDecoder.nextToken() {
            if case .null = t {
                return nil
            } else if let n = t.asUInt64 {
                return n
            }
            throw ProtobufDecodingError.malformedJSONNumber
        }
        throw ProtobufDecodingError.truncatedInput
    }
    
    public static func serializeTextMapKeyValue(encoder: inout ProtobufTextEncoder, value: UInt64) {
        encoder.putUInt64(value: value.littleEndian, quote: true)
    }
    
    public static func decodeTextMapKeyValue(token: ProtobufTextToken) -> UInt64? {
        return token.asUInt64
    }
}

///
/// SFixed32 traits
///
public extension ProtobufSFixed32 {
    public static func setFromTextToken(token: ProtobufTextToken, value: inout BaseType?) throws {
        if let n = token.asInt32 {
            value = n
        } else {
            throw ProtobufDecodingError.malformedJSONNumber
        }
    }
    
    public static func setFromTextToken(token: ProtobufTextToken, value: inout [BaseType]) throws {
        if let n = token.asInt32 {
            value.append(n)
        } else {
            throw ProtobufDecodingError.malformedJSONNumber
        }
    }
    
    public static func serializeTextValue(encoder: inout ProtobufTextEncoder, value: Int32) {
        encoder.putInt64(value: Int64(value), quote: false)
    }
    
    public static func decodeTextMapFieldValue(textDecoder: inout ProtobufTextDecoder) throws -> Int32? {
        if let t = try textDecoder.nextToken() {
            if case .null = t {
                return nil
            } else if let n = t.asInt32 {
                return n
            }
            throw ProtobufDecodingError.malformedJSONNumber
        }
        throw ProtobufDecodingError.truncatedInput
    }
    
    public static func serializeTextMapKeyValue(encoder: inout ProtobufTextEncoder, value: Int32) {
        encoder.putInt64(value: Int64(value), quote: true)
    }
    
    public static func decodeTextMapKeyValue(token: ProtobufTextToken) -> Int32? {
        return token.asInt32
    }
}

///
/// SFixed64 traits
///
public extension ProtobufSFixed64 {
    public static func setFromTextToken(token: ProtobufTextToken, value: inout BaseType?) throws {
        if let n = token.asInt64 {
            value = n
        } else {
            throw ProtobufDecodingError.malformedJSONNumber
        }
    }
    
    public static func setFromTextToken(token: ProtobufTextToken, value: inout [BaseType]) throws {
        if let n = token.asInt64 {
            value.append(n)
        } else {
            throw ProtobufDecodingError.malformedJSONNumber
        }
    }
    
    public static func serializeTextValue(encoder: inout ProtobufTextEncoder, value: Int64) {
        encoder.putInt64(value: value, quote: true)
    }
    
    public static func decodeTextMapFieldValue(textDecoder: inout ProtobufTextDecoder) throws -> Int64? {
        if let t = try textDecoder.nextToken() {
            if case .null = t {
                return nil
            } else if let n = t.asInt64 {
                return n
            }
            throw ProtobufDecodingError.malformedJSONNumber
        }
        throw ProtobufDecodingError.truncatedInput
    }
    
    public static func serializeTextMapKeyValue(encoder: inout ProtobufTextEncoder, value: Int64) {
        encoder.putInt64(value: value, quote: true)
    }
    
    public static func decodeTextMapKeyValue(token: ProtobufTextToken) -> Int64? {
        return token.asInt64
    }
}

///
/// Bool traits
///
public extension ProtobufBool {
    public static func setFromTextToken(token: ProtobufTextToken, value: inout BaseType?) throws {
        if let n = token.asBoolean {
            value = n
        } else {
            throw ProtobufDecodingError.malformedJSON
        }
    }
    
    public static func setFromTextToken(token: ProtobufTextToken, value: inout [BaseType]) throws {
        if let n = token.asBoolean {
            value.append(n)
        } else {
            throw ProtobufDecodingError.malformedJSON
        }
    }
    
    public static func serializeTextValue(encoder: inout ProtobufTextEncoder, value: Bool) {
        encoder.putBoolValue(value: value, quote: false)
    }
    
    public static func decodeTextMapFieldValue(textDecoder: inout ProtobufTextDecoder) throws -> Bool? {
        if let t = try textDecoder.nextToken() {
            if case .null = t {
                return nil
            } else if let n = t.asBoolean {
                return n
            }
            throw ProtobufDecodingError.malformedJSON
        }
        throw ProtobufDecodingError.truncatedInput
    }
    
    public static func serializeTextMapKeyValue(encoder: inout ProtobufTextEncoder, value: Bool) {
        encoder.putBoolValue(value: value, quote: true)
    }
    
    public static func decodeTextMapKeyValue(token: ProtobufTextToken) -> Bool? {
        return token.asBooleanMapKey
    }
}

///
/// String traits
///
public extension ProtobufString {
    public static func setFromTextToken(token: ProtobufTextToken, value: inout BaseType?) throws {
        if case .string(let s) = token {
            value = s
        } else {
            throw ProtobufDecodingError.malformedJSON
        }
    }
    
    public static func setFromTextToken(token: ProtobufTextToken, value: inout [BaseType]) throws {
        if case .string(let s) = token {
            value.append(s)
        } else {
            throw ProtobufDecodingError.malformedJSON
        }
    }
    
    public static func serializeTextValue(encoder: inout ProtobufTextEncoder, value: String) {
        encoder.putStringValue(value: value)
    }
    
    public static func decodeTextMapFieldValue(textDecoder: inout ProtobufTextDecoder) throws -> String? {
        switch try textDecoder.nextToken() {
        case .some(.string(let s)):
            return s
        case .some(.null):
            return nil
        case .some(_):
            throw ProtobufDecodingError.malformedJSON
        default:
            throw ProtobufDecodingError.truncatedInput
        }
    }
    
    public static func serializeTextMapKeyValue(encoder: inout ProtobufTextEncoder, value: String) {
        encoder.putStringValue(value: value)
    }
    public static func decodeTextMapKeyValue(token: ProtobufTextToken) -> String? {
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
    public static func setFromTextToken(token: ProtobufTextToken, value: inout BaseType?) throws {
        if let n = token.asBytes {
            value = n
        } else {
            throw ProtobufDecodingError.malformedJSON
        }
    }
    
    public static func setFromTextToken(token: ProtobufTextToken, value: inout [BaseType]) throws {
        if let n = token.asBytes {
            value.append(n)
        } else {
            throw ProtobufDecodingError.malformedJSON
        }
    }
    
    public static func serializeTextValue(encoder: inout ProtobufTextEncoder, value: Data) {
        encoder.putBytesValue(value: value)
    }
    
    public static func decodeTextMapFieldValue(textDecoder: inout ProtobufTextDecoder) throws -> Data? {
        if let token = try textDecoder.nextToken() {
            switch token {
            case .string(_):
                if let bytes = token.asBytes {
                    return bytes
                }
            case .null:
                return nil
            default:
                throw ProtobufDecodingError.malformedJSON
            }
        }
        throw ProtobufDecodingError.truncatedInput
    }
}

//
// Enum traits
//
extension ProtobufEnum where RawValue == Int {
    public static func setFromTextToken(token: ProtobufTextToken, value: inout Self?) throws {
        switch token {
        case .string(let s):
            if let b = Self(jsonName: s) {
                value = b
            } else {
                throw ProtobufDecodingError.unrecognizedEnumValue
            }
        case .number(_):
            if let n = token.asInt32 {
                value = Self(rawValue: Int(n))
            } else {
                throw ProtobufDecodingError.malformedJSONNumber
            }
        default:
            throw ProtobufDecodingError.malformedJSON
        }
    }
    
    public static func setFromTextToken(token: ProtobufTextToken, value: inout [Self]) throws {
        switch token {
        case .string(let s):
            if let b = Self(jsonName: s) {
                value.append(b)
            } else {
                throw ProtobufDecodingError.unrecognizedEnumValue
            }
        case .number(_):
            if let n = token.asInt32 {
                let e = Self(rawValue: Int(n))! // Note: Can never fail!
                value.append(e)
            } else {
                throw ProtobufDecodingError.malformedJSONNumber
            }
        default:
            throw ProtobufDecodingError.malformedJSON
        }
    }
    
    public static func serializeTextValue(encoder: inout ProtobufTextEncoder, value: Self) {
        encoder.append(text: value.json)
    }
    
    public static func decodeTextMapFieldValue(textDecoder: inout ProtobufTextDecoder) throws -> Self? {
        if let token = try textDecoder.nextToken() {
            switch token {
            case .null: return nil
            case .string(let s):
                if let b = Self(jsonName: s) {
                    return b
                }
                throw ProtobufDecodingError.unrecognizedEnumValue
            case .number(_):
                if let n = token.asInt32 {
                    return Self(rawValue: Int(n))
                }
                throw ProtobufDecodingError.malformedJSONNumber
            default:
                throw ProtobufDecodingError.malformedJSON
            }
        }
        throw ProtobufDecodingError.truncatedInput
    }
}

///
/// Messages
///
public protocol ProtobufTextMessageBase: ProtobufMessageBase {
    init()
    
    // Serialize to text
    func serializeText() throws -> String
    
    // Decode from text
    init(text: String) throws
    // Decode from text
    init(text: String, extensions: ProtobufExtensionSet) throws
    
    // TODO:  Can we get rid of this?
    mutating func decodeFromText(textDecoder: inout ProtobufTextDecoder) throws -> Bool
    // Messages such as Value, NullValue override this to decode from Null.
    // Default just returns nil.
    static func decodeFromTextNull() throws -> Self?
    // Duration, Timestamp, FieldMask override this
    // to decode themselves from a single token.
    // Default always throws an error.
    mutating func decodeFromTextToken(token: ProtobufTextToken) throws
    // Value, Struct, Any override this to change
    // how they decode from a JSON object form.
    // Default decodes keys and feeds them to decodeField()
    mutating func decodeFromTextObject(textDecoder: inout ProtobufTextDecoder) throws
    // Value, ListValue override this to decode self from a JSON array form
    // Default always throws an error
    mutating func decodeFromTextArray(textDecoder: inout ProtobufTextDecoder) throws
}

public extension ProtobufTextMessageBase {
    public static func decodeTextMapFieldValue(textDecoder: inout ProtobufTextDecoder) throws -> Self? {
        var m = Self()
        if try m.decodeFromText(textDecoder: &textDecoder) {
            return m
        } else {
            return nil
        }
    }
    
    func serializeText() throws -> String {
        return try ProtobufTextEncodingVisitor(message: self).result
    }
    
    func serializeAnyText() throws -> String {
        var textVisitor = ProtobufTextEncodingVisitor()
        try textVisitor.withAbstractVisitor {(visitor: inout ProtobufVisitor) in
            try visitor.visitSingularField(fieldType: ProtobufString.self, value: anyTypeURL, protoFieldNumber: 1, protoFieldName: "type_url", jsonFieldName: "@type", swiftFieldName: "typeURL")
            try traverse(visitor: &visitor)
        }
        return textVisitor.result
    }
    
    // TODO: Can we get rid of this?  (This is leftover from an earlier generation of JSON encoding logic.)
    static func serializeTextValue(encoder: inout ProtobufTextEncoder, value: Self) throws {
        let text = try value.serializeText()
        encoder.append(text: text)
    }
    
    // TODO: Can we get rid of this?  (This is leftover from an earlier generation of JSON decoding logic.)
    public mutating func decodeFromText(textDecoder: inout ProtobufTextDecoder) throws -> Bool {
        if let token = try textDecoder.nextToken() {
            switch token {
            case .beginObject:
                try decodeFromTextObject(textDecoder: &textDecoder)
                return true
            case .null:
                break
            default:
                throw ProtobufDecodingError.malformedJSON
            }
        }
        return false
    }
    
    /// Decode an instance of this message type from the provided JSON string.
    /// JSON "null" decodes to an empty object.
    public init(text: String) throws {
        self.init()
        var textDecoder = ProtobufTextDecoder(text: text)
        try textDecoder.decodeFullObject(message: &self)
        if !textDecoder.complete {
            throw ProtobufDecodingError.trailingGarbage
        }
    }
    
    public init(text: String, extensions: ProtobufExtensionSet) throws {
        self.init()
        var textDecoder = ProtobufTextDecoder(text: text, extensions: extensions)
        try textDecoder.decodeFullObject(message: &self)
        if !textDecoder.complete {
            throw ProtobufDecodingError.trailingGarbage
        }
    }
    
    public static func decodeFromTextNull() -> Self? {
        return nil
    }
    
    public mutating func decodeFromTextToken(token: ProtobufTextToken) throws {
        throw ProtobufDecodingError.schemaMismatch
    }
    
    public mutating func decodeFromTextArray(textDecoder: inout ProtobufTextDecoder) throws {
        throw ProtobufDecodingError.schemaMismatch
    }
}

extension ProtobufMessage {
    // Open curly brace already consumed.
    public mutating func decodeFromTextObject(textDecoder: inout ProtobufTextDecoder) throws {
        var key = ""
        var state = ProtobufTextDecoder.ObjectParseState.expectFirstKey
        while let token = try textDecoder.nextToken() {
            switch token {
            case .string(let s): // This is a key
                if state != .expectKey && state != .expectFirstKey {
                    throw ProtobufDecodingError.malformedJSON
                }
                key = s
                state = .expectColon
            case .colon:
                if state != .expectColon {
                    throw ProtobufDecodingError.malformedJSON
                }
                try textDecoder.decodeValue(key: key, message: &self)
                state = .expectComma
            case .comma:
                if state != .expectComma {
                    throw ProtobufDecodingError.malformedJSON
                }
                state = .expectKey
            case .endObject:
                if state != .expectFirstKey && state != .expectComma {
                    throw ProtobufDecodingError.malformedJSON
                }
                return
            default:
                throw ProtobufDecodingError.malformedJSON
            }
        }
        throw ProtobufDecodingError.truncatedInput
    }
}

///
/// Groups
///
public extension ProtobufGroup {
    // Open curly brace already consumed.
    public mutating func decodeFromTextObject(textDecoder: inout ProtobufTextDecoder) throws {
        var key = ""
        var state = ProtobufTextDecoder.ObjectParseState.expectFirstKey
        while let token = try textDecoder.nextToken() {
            switch token {
            case .string(let s): // This is a key
                if state != .expectKey && state != .expectFirstKey {
                    throw ProtobufDecodingError.malformedJSON
                }
                key = s
                state = .expectColon
            case .colon:
                if state != .expectColon {
                    throw ProtobufDecodingError.malformedJSON
                }
                try textDecoder.decodeValue(key: key, group: &self)
                state = .expectComma
            case .comma:
                if state != .expectComma {
                    throw ProtobufDecodingError.malformedJSON
                }
                state = .expectKey
            case .endObject:
                if state != .expectFirstKey && state != .expectComma {
                    throw ProtobufDecodingError.malformedJSON
                }
                return
            default:
                throw ProtobufDecodingError.malformedJSON
            }
        }
        throw ProtobufDecodingError.truncatedInput
    }
}
