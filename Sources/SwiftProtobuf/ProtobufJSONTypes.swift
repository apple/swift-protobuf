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

public protocol ProtobufJSONCodableType: ProtobufTypePropertiesBase {
    static func serializeJSONValue(encoder: inout ProtobufJSONEncoder, value: BaseType) throws
    /// Consume tokens from a JSON decoder
    static func decodeJSONMapFieldValue(jsonDecoder: inout ProtobufJSONDecoder) throws -> BaseType?
    /// Set the value given a single JSON token
    static func setFromJSONToken(token: ProtobufJSONToken, value: inout BaseType?) throws
    /// Update the repeated value given a single JSON token (used by repeated fields of basic types)
    static func setFromJSONToken(token: ProtobufJSONToken, value: inout [BaseType]) throws
}

extension ProtobufJSONCodableType {
    public static func setFromJSONToken(token: ProtobufJSONToken, value: inout BaseType?) throws {
        throw ProtobufDecodingError.schemaMismatch
    }

    public static func setFromJSONToken(token: ProtobufJSONToken, value: inout [BaseType]) throws {
        throw ProtobufDecodingError.schemaMismatch
    }
}

public protocol ProtobufJSONCodableMapKeyType: ProtobufTypePropertiesBase {
    static func serializeJSONMapKeyValue(encoder: inout ProtobufJSONEncoder, value: BaseType)
    static func decodeJSONMapKeyValue(token: ProtobufJSONToken) throws -> BaseType?
}

///
/// Float traits
///
public extension ProtobufFloat {
    public static func setFromJSONToken(token: ProtobufJSONToken, value: inout BaseType?) throws {
        if let n = token.asFloat {
            value = n
        } else {
            throw ProtobufDecodingError.malformedJSONNumber
        }
    }


    public static func setFromJSONToken(token: ProtobufJSONToken, value: inout [BaseType]) throws {
        if let n = token.asFloat {
            value.append(n)
        } else {
            throw ProtobufDecodingError.malformedJSONNumber
        }
    }

    public static func serializeJSONValue(encoder: inout ProtobufJSONEncoder, value: Float) {
        encoder.putFloatValue(value: value, quote: false)
    }

    public static func decodeJSONMapFieldValue(jsonDecoder: inout ProtobufJSONDecoder) throws -> Float? {
        if let t = try jsonDecoder.nextToken() {
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

    public static func setFromJSONToken(token: ProtobufJSONToken, value: inout BaseType?) throws {
        if let n = token.asDouble {
            value = n
        } else {
            throw ProtobufDecodingError.malformedJSONNumber
        }
    }

    public static func setFromJSONToken(token: ProtobufJSONToken, value: inout [BaseType]) throws {
        if let n = token.asDouble {
            value.append(n)
        } else {
            throw ProtobufDecodingError.malformedJSONNumber
        }
    }

    public static func serializeJSONValue(encoder: inout ProtobufJSONEncoder, value: Double) {
        encoder.putDoubleValue(value: value, quote: false)
    }

    public static func decodeJSONMapFieldValue(jsonDecoder: inout ProtobufJSONDecoder) throws -> Double? {
        if let t = try jsonDecoder.nextToken() {
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
    public static func setFromJSONToken(token: ProtobufJSONToken, value: inout BaseType?) throws {
        if let n = token.asInt32 {
            value = n
        } else {
            throw ProtobufDecodingError.malformedJSONNumber
        }
    }

    public static func setFromJSONToken(token: ProtobufJSONToken, value: inout [BaseType]) throws {
        if let n = token.asInt32 {
            value.append(n)
        } else {
            throw ProtobufDecodingError.malformedJSONNumber
        }
    }

    public static func serializeJSONValue(encoder: inout ProtobufJSONEncoder, value: Int32) {
        encoder.putInt64(value: Int64(value), quote: false)
    }

    public static func decodeJSONMapFieldValue(jsonDecoder: inout ProtobufJSONDecoder) throws -> Int32? {
        if let t = try jsonDecoder.nextToken() {
            if case .null = t {
                return nil
            } else if let n = t.asInt32 {
                return n
            }
            throw ProtobufDecodingError.malformedJSONNumber
        }
        throw ProtobufDecodingError.truncatedInput
    }

    public static func serializeJSONMapKeyValue(encoder: inout ProtobufJSONEncoder, value: Int32) {
        encoder.putInt64(value: Int64(value), quote: true)
    }

    public static func decodeJSONMapKeyValue(token: ProtobufJSONToken) -> Int32? {
        return token.asInt32
    }
}

///
/// Int64 traits
///
public extension ProtobufInt64 {
    public static func setFromJSONToken(token: ProtobufJSONToken, value: inout BaseType?) throws {
        if let n = token.asInt64 {
            value = n
        } else {
            throw ProtobufDecodingError.malformedJSONNumber
        }
    }

    public static func setFromJSONToken(token: ProtobufJSONToken, value: inout [BaseType]) throws {
        if let n = token.asInt64 {
            value.append(n)
        } else {
            throw ProtobufDecodingError.malformedJSONNumber
        }
    }

    public static func serializeJSONValue(encoder: inout ProtobufJSONEncoder, value: Int64) {
        encoder.putInt64(value: value, quote: true)
    }

    public static func decodeJSONMapFieldValue(jsonDecoder: inout ProtobufJSONDecoder) throws -> Int64? {
        if let t = try jsonDecoder.nextToken() {
            if case .null = t {
                return nil
            } else if let n = t.asInt64 {
                return n
            }
            throw ProtobufDecodingError.malformedJSONNumber
        }
        throw ProtobufDecodingError.truncatedInput
    }

    public static func serializeJSONMapKeyValue(encoder: inout ProtobufJSONEncoder, value: Int64) {
        encoder.putInt64(value: value, quote: true)
    }

    public static func decodeJSONMapKeyValue(token: ProtobufJSONToken) -> Int64? {
        return token.asInt64
    }
}

///
/// UInt32 traits
///
public extension ProtobufUInt32 {
    public static func setFromJSONToken(token: ProtobufJSONToken, value: inout BaseType?) throws {
        if let n = token.asUInt32 {
            value = n
        } else {
            throw ProtobufDecodingError.malformedJSONNumber
        }
    }

    public static func setFromJSONToken(token: ProtobufJSONToken, value: inout [BaseType]) throws {
        if let n = token.asUInt32 {
            value.append(n)
        } else {
            throw ProtobufDecodingError.malformedJSONNumber
        }
    }

    public static func serializeJSONValue(encoder: inout ProtobufJSONEncoder, value: UInt32) {
        encoder.putUInt64(value: UInt64(value), quote: false)
    }

    public static func decodeJSONMapFieldValue(jsonDecoder: inout ProtobufJSONDecoder) throws -> UInt32? {
        if let t = try jsonDecoder.nextToken() {
            if case .null = t {
                return nil
            } else if let n = t.asUInt32 {
                return n
            }
            throw ProtobufDecodingError.malformedJSONNumber
        }
        throw ProtobufDecodingError.truncatedInput
    }

    public static func decodeJSONMapKeyValue(token: ProtobufJSONToken) -> UInt32? {
        return token.asUInt32
    }

    public static func serializeJSONMapKeyValue(encoder: inout ProtobufJSONEncoder, value: UInt32) {
        encoder.putUInt64(value: UInt64(value), quote: true)
    }
}

///
/// UInt64 traits
///
public extension ProtobufUInt64 {
    public static func setFromJSONToken(token: ProtobufJSONToken, value: inout BaseType?) throws {
        if let n = token.asUInt64 {
            value = n
        } else {
            throw ProtobufDecodingError.malformedJSONNumber
        }
    }

    public static func setFromJSONToken(token: ProtobufJSONToken, value: inout [BaseType]) throws {
        if let n = token.asUInt64 {
            value.append(n)
        } else {
            throw ProtobufDecodingError.malformedJSONNumber
        }
    }

    public static func serializeJSONValue(encoder: inout ProtobufJSONEncoder, value: UInt64) {
        encoder.putUInt64(value: value, quote: true)
    }

    public static func decodeJSONMapFieldValue(jsonDecoder: inout ProtobufJSONDecoder) throws -> UInt64? {
        if let t = try jsonDecoder.nextToken() {
            if case .null = t {
                return nil
            } else if let n = t.asUInt64 {
                return n
            }
            throw ProtobufDecodingError.malformedJSONNumber
        }
        throw ProtobufDecodingError.truncatedInput
    }

    public static func serializeJSONMapKeyValue(encoder: inout ProtobufJSONEncoder, value: UInt64) {
        encoder.putUInt64(value: value, quote: true)
    }

    public static func decodeJSONMapKeyValue(token: ProtobufJSONToken) -> UInt64? {
        return token.asUInt64
    }
}

///
/// SInt32 traits
///
public extension ProtobufSInt32 {
    public static func setFromJSONToken(token: ProtobufJSONToken, value: inout BaseType?) throws {
        if let n = token.asInt32 {
            value = n
        } else {
            throw ProtobufDecodingError.malformedJSONNumber
        }
    }

    public static func setFromJSONToken(token: ProtobufJSONToken, value: inout [BaseType]) throws {
        if let n = token.asInt32 {
            value.append(n)
        } else {
            throw ProtobufDecodingError.malformedJSONNumber
        }
    }

    public static func serializeJSONValue(encoder: inout ProtobufJSONEncoder, value: Int32) {
        encoder.putInt64(value: Int64(value), quote: false)
    }

    public static func decodeJSONMapFieldValue(jsonDecoder: inout ProtobufJSONDecoder) throws -> Int32? {
        if let t = try jsonDecoder.nextToken() {
            if case .null = t {
                return nil
            } else if let n = t.asInt32 {
                return n
            }
            throw ProtobufDecodingError.malformedJSONNumber
        }
        throw ProtobufDecodingError.truncatedInput
    }

    public static func decodeJSONMapKeyValue(token: ProtobufJSONToken) -> Int32? {
        return token.asInt32
    }

    public static func serializeJSONMapKeyValue(encoder: inout ProtobufJSONEncoder, value: Int32) {
        encoder.putInt64(value: Int64(value), quote: true)
    }
}

///
/// SInt64 traits
///
public extension ProtobufSInt64 {
    public static func setFromJSONToken(token: ProtobufJSONToken, value: inout BaseType?) throws {
        if let n = token.asInt64 {
            value = n
        } else {
            throw ProtobufDecodingError.malformedJSONNumber
        }
    }

    public static func setFromJSONToken(token: ProtobufJSONToken, value: inout [BaseType]) throws {
        if let n = token.asInt64 {
            value.append(n)
        } else {
            throw ProtobufDecodingError.malformedJSONNumber
        }
    }

    public static func serializeJSONValue(encoder: inout ProtobufJSONEncoder, value: Int64) {
        encoder.putInt64(value: value, quote: true)
    }

    public static func decodeJSONMapFieldValue(jsonDecoder: inout ProtobufJSONDecoder) throws -> Int64? {
        if let t = try jsonDecoder.nextToken() {
            if case .null = t {
                return nil
            } else if let n = t.asInt64 {
                return n
            }
            throw ProtobufDecodingError.malformedJSONNumber
        }
        throw ProtobufDecodingError.truncatedInput
    }

    public static func serializeJSONMapKeyValue(encoder: inout ProtobufJSONEncoder, value: Int64) {
        encoder.putInt64(value: value, quote: true)
    }

    public static func decodeJSONMapKeyValue(token: ProtobufJSONToken) -> Int64? {
        return token.asInt64
    }
}

///
/// Fixed32 traits
///
public extension ProtobufFixed32 {
    public static func setFromJSONToken(token: ProtobufJSONToken, value: inout BaseType?) throws {
        if let n = token.asUInt32 {
            value = n
        } else {
            throw ProtobufDecodingError.malformedJSONNumber
        }
    }

    public static func setFromJSONToken(token: ProtobufJSONToken, value: inout [BaseType]) throws {
        if let n = token.asUInt32 {
            value.append(n)
        } else {
            throw ProtobufDecodingError.malformedJSONNumber
        }
    }

    public static func serializeJSONValue(encoder: inout ProtobufJSONEncoder, value: UInt32) {
        encoder.putUInt64(value: UInt64(value), quote: false)
    }

    public static func decodeJSONMapFieldValue(jsonDecoder: inout ProtobufJSONDecoder) throws -> UInt32? {
        if let t = try jsonDecoder.nextToken() {
            if case .null = t {
                return nil
            } else if let n = t.asUInt32 {
                return n
            }
            throw ProtobufDecodingError.malformedJSONNumber
        }
        throw ProtobufDecodingError.truncatedInput
    }

    public static func serializeJSONMapKeyValue(encoder: inout ProtobufJSONEncoder, value: UInt32) {
        encoder.putUInt64(value: UInt64(value), quote: true)
    }

    public static func decodeJSONMapKeyValue(token: ProtobufJSONToken) -> UInt32? {
        return token.asUInt32
    }
}

///
/// Fixed64 traits
///
public extension ProtobufFixed64 {
    public static func setFromJSONToken(token: ProtobufJSONToken, value: inout BaseType?) throws {
        if let n = token.asUInt64 {
            value = n
        } else {
            throw ProtobufDecodingError.malformedJSONNumber
        }
    }

    public static func setFromJSONToken(token: ProtobufJSONToken, value: inout [BaseType]) throws {
        if let n = token.asUInt64 {
            value.append(n)
        } else {
            throw ProtobufDecodingError.malformedJSONNumber
        }
    }

    public static func serializeJSONValue(encoder: inout ProtobufJSONEncoder, value: UInt64) {
        encoder.putUInt64(value: value, quote: true)
    }
    public static func decodeJSONMapFieldValue(jsonDecoder: inout ProtobufJSONDecoder) throws -> UInt64? {
        if let t = try jsonDecoder.nextToken() {
            if case .null = t {
                return nil
            } else if let n = t.asUInt64 {
                return n
            }
            throw ProtobufDecodingError.malformedJSONNumber
        }
        throw ProtobufDecodingError.truncatedInput
    }

    public static func serializeJSONMapKeyValue(encoder: inout ProtobufJSONEncoder, value: UInt64) {
        encoder.putUInt64(value: value.littleEndian, quote: true)
    }

    public static func decodeJSONMapKeyValue(token: ProtobufJSONToken) -> UInt64? {
        return token.asUInt64
    }
}

///
/// SFixed32 traits
///
public extension ProtobufSFixed32 {
    public static func setFromJSONToken(token: ProtobufJSONToken, value: inout BaseType?) throws {
        if let n = token.asInt32 {
            value = n
        } else {
            throw ProtobufDecodingError.malformedJSONNumber
        }
    }

    public static func setFromJSONToken(token: ProtobufJSONToken, value: inout [BaseType]) throws {
        if let n = token.asInt32 {
            value.append(n)
        } else {
            throw ProtobufDecodingError.malformedJSONNumber
        }
    }

    public static func serializeJSONValue(encoder: inout ProtobufJSONEncoder, value: Int32) {
        encoder.putInt64(value: Int64(value), quote: false)
    }

    public static func decodeJSONMapFieldValue(jsonDecoder: inout ProtobufJSONDecoder) throws -> Int32? {
        if let t = try jsonDecoder.nextToken() {
            if case .null = t {
                return nil
            } else if let n = t.asInt32 {
                return n
            }
            throw ProtobufDecodingError.malformedJSONNumber
        }
        throw ProtobufDecodingError.truncatedInput
    }

    public static func serializeJSONMapKeyValue(encoder: inout ProtobufJSONEncoder, value: Int32) {
        encoder.putInt64(value: Int64(value), quote: true)
    }

    public static func decodeJSONMapKeyValue(token: ProtobufJSONToken) -> Int32? {
        return token.asInt32
    }
}

///
/// SFixed64 traits
///
public extension ProtobufSFixed64 {
    public static func setFromJSONToken(token: ProtobufJSONToken, value: inout BaseType?) throws {
        if let n = token.asInt64 {
            value = n
        } else {
            throw ProtobufDecodingError.malformedJSONNumber
        }
    }

    public static func setFromJSONToken(token: ProtobufJSONToken, value: inout [BaseType]) throws {
        if let n = token.asInt64 {
            value.append(n)
        } else {
            throw ProtobufDecodingError.malformedJSONNumber
        }
    }

    public static func serializeJSONValue(encoder: inout ProtobufJSONEncoder, value: Int64) {
        encoder.putInt64(value: value, quote: true)
    }

    public static func decodeJSONMapFieldValue(jsonDecoder: inout ProtobufJSONDecoder) throws -> Int64? {
        if let t = try jsonDecoder.nextToken() {
            if case .null = t {
                return nil
            } else if let n = t.asInt64 {
                return n
            }
            throw ProtobufDecodingError.malformedJSONNumber
        }
        throw ProtobufDecodingError.truncatedInput
    }

    public static func serializeJSONMapKeyValue(encoder: inout ProtobufJSONEncoder, value: Int64) {
        encoder.putInt64(value: value, quote: true)
    }

    public static func decodeJSONMapKeyValue(token: ProtobufJSONToken) -> Int64? {
        return token.asInt64
    }
}

///
/// Bool traits
///
public extension ProtobufBool {
    public static func setFromJSONToken(token: ProtobufJSONToken, value: inout BaseType?) throws {
        if let n = token.asBoolean {
            value = n
        } else {
            throw ProtobufDecodingError.malformedJSON
        }
    }

    public static func setFromJSONToken(token: ProtobufJSONToken, value: inout [BaseType]) throws {
        if let n = token.asBoolean {
            value.append(n)
        } else {
            throw ProtobufDecodingError.malformedJSON
        }
    }

    public static func serializeJSONValue(encoder: inout ProtobufJSONEncoder, value: Bool) {
        encoder.putBoolValue(value: value, quote: false)
    }

    public static func decodeJSONMapFieldValue(jsonDecoder: inout ProtobufJSONDecoder) throws -> Bool? {
        if let t = try jsonDecoder.nextToken() {
            if case .null = t {
                return nil
            } else if let n = t.asBoolean {
                return n
            }
            throw ProtobufDecodingError.malformedJSON
        }
        throw ProtobufDecodingError.truncatedInput
    }

    public static func serializeJSONMapKeyValue(encoder: inout ProtobufJSONEncoder, value: Bool) {
        encoder.putBoolValue(value: value, quote: true)
    }

    public static func decodeJSONMapKeyValue(token: ProtobufJSONToken) -> Bool? {
        return token.asBooleanMapKey
    }
}

///
/// String traits
///
public extension ProtobufString {
    public static func setFromJSONToken(token: ProtobufJSONToken, value: inout BaseType?) throws {
        if case .string(let s) = token {
            value = s
        } else {
            throw ProtobufDecodingError.malformedJSON
        }
    }

    public static func setFromJSONToken(token: ProtobufJSONToken, value: inout [BaseType]) throws {
        if case .string(let s) = token {
            value.append(s)
        } else {
            throw ProtobufDecodingError.malformedJSON
        }
    }

    public static func serializeJSONValue(encoder: inout ProtobufJSONEncoder, value: String) {
        encoder.putStringValue(value: value)
    }

    public static func decodeJSONMapFieldValue(jsonDecoder: inout ProtobufJSONDecoder) throws -> String? {
        switch try jsonDecoder.nextToken() {
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

    public static func serializeJSONMapKeyValue(encoder: inout ProtobufJSONEncoder, value: String) {
        encoder.putStringValue(value: value)
    }
    public static func decodeJSONMapKeyValue(token: ProtobufJSONToken) -> String? {
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
    public static func setFromJSONToken(token: ProtobufJSONToken, value: inout BaseType?) throws {
        if let n = token.asBytes {
            value = n
        } else {
            throw ProtobufDecodingError.malformedJSON
        }
    }

    public static func setFromJSONToken(token: ProtobufJSONToken, value: inout [BaseType]) throws {
        if let n = token.asBytes {
            value.append(n)
        } else {
            throw ProtobufDecodingError.malformedJSON
        }
    }

    public static func serializeJSONValue(encoder: inout ProtobufJSONEncoder, value: Data) {
        encoder.putBytesValue(value: value)
    }

    public static func decodeJSONMapFieldValue(jsonDecoder: inout ProtobufJSONDecoder) throws -> Data? {
        if let token = try jsonDecoder.nextToken() {
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
    public static func setFromJSONToken(token: ProtobufJSONToken, value: inout Self?) throws {
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

    public static func setFromJSONToken(token: ProtobufJSONToken, value: inout [Self]) throws {
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

    public static func serializeJSONValue(encoder: inout ProtobufJSONEncoder, value: Self) {
        encoder.append(text: value.json)
    }

    public static func decodeJSONMapFieldValue(jsonDecoder: inout ProtobufJSONDecoder) throws -> Self? {
        if let token = try jsonDecoder.nextToken() {
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
public protocol ProtobufJSONMessageBase: ProtobufMessageBase {
    init()

    // Serialize to JSON
    func serializeJSON() throws -> String

    // Decode from JSON
    init(json: String) throws
    // Decode from JSON
    init(json: String, extensions: ProtobufExtensionSet) throws

    // TODO:  Can we get rid of this?
    mutating func decodeFromJSON(jsonDecoder: inout ProtobufJSONDecoder) throws -> Bool
    // Messages such as Value, NullValue override this to decode from Null.
    // Default just returns nil.
    static func decodeFromJSONNull() throws -> Self?
    // Duration, Timestamp, FieldMask override this
    // to decode themselves from a single token.
    // Default always throws an error.
    mutating func decodeFromJSONToken(token: ProtobufJSONToken) throws
    // Value, Struct, Any override this to change
    // how they decode from a JSON object form.
    // Default decodes keys and feeds them to decodeField()
    mutating func decodeFromJSONObject(jsonDecoder: inout ProtobufJSONDecoder) throws
    // Value, ListValue override this to decode self from a JSON array form
    // Default always throws an error
    mutating func decodeFromJSONArray(jsonDecoder: inout ProtobufJSONDecoder) throws
}

public extension ProtobufJSONMessageBase {
    public static func decodeJSONMapFieldValue(jsonDecoder: inout ProtobufJSONDecoder) throws -> Self? {
        var m = Self()
        if try m.decodeFromJSON(jsonDecoder: &jsonDecoder) {
            return m
        } else {
            return nil
        }
    }

    func serializeJSON() throws -> String {
        return try ProtobufJSONEncodingVisitor(message: self).result
    }

    func serializeAnyJSON() throws -> String {
        var jsonVisitor = ProtobufJSONEncodingVisitor()
        try jsonVisitor.withAbstractVisitor {(visitor: inout ProtobufVisitor) in
            try visitor.visitSingularField(fieldType: ProtobufString.self, value: anyTypeURL, protoFieldNumber: 1, protoFieldName: "type_url", jsonFieldName: "@type", swiftFieldName: "typeURL")
            try traverse(visitor: &visitor)
        }
        return jsonVisitor.result
    }

    // TODO: Can we get rid of this?  (This is leftover from an earlier generation of JSON encoding logic.)
    static func serializeJSONValue(encoder: inout ProtobufJSONEncoder, value: Self) throws {
        let json = try value.serializeJSON()
        encoder.append(text: json)
    }

    // TODO: Can we get rid of this?  (This is leftover from an earlier generation of JSON decoding logic.)
    public mutating func decodeFromJSON(jsonDecoder: inout ProtobufJSONDecoder) throws -> Bool {
        if let token = try jsonDecoder.nextToken() {
            switch token {
            case .beginObject:
                try decodeFromJSONObject(jsonDecoder: &jsonDecoder)
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
    public init(json: String) throws {
        self.init()
        var jsonDecoder = ProtobufJSONDecoder(json: json)
        try jsonDecoder.decodeFullObject(message: &self)
        if !jsonDecoder.complete {
            throw ProtobufDecodingError.trailingGarbage
        }
    }

    public init(json: String, extensions: ProtobufExtensionSet) throws {
        self.init()
        var jsonDecoder = ProtobufJSONDecoder(json: json, extensions: extensions)
        try jsonDecoder.decodeFullObject(message: &self)
        if !jsonDecoder.complete {
            throw ProtobufDecodingError.trailingGarbage
        }
    }

    public static func decodeFromJSONNull() -> Self? {
        return nil
    }

    public mutating func decodeFromJSONToken(token: ProtobufJSONToken) throws {
        throw ProtobufDecodingError.schemaMismatch
    }

    public mutating func decodeFromJSONArray(jsonDecoder: inout ProtobufJSONDecoder) throws {
        throw ProtobufDecodingError.schemaMismatch
    }
}

extension ProtobufMessage {
    // Open curly brace already consumed.
    public mutating func decodeFromJSONObject(jsonDecoder: inout ProtobufJSONDecoder) throws {
        var key = ""
        var state = ProtobufJSONDecoder.ObjectParseState.expectFirstKey
        while let token = try jsonDecoder.nextToken() {
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
                try jsonDecoder.decodeValue(key: key, message: &self)
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
    public mutating func decodeFromJSONObject(jsonDecoder: inout ProtobufJSONDecoder) throws {
        var key = ""
        var state = ProtobufJSONDecoder.ObjectParseState.expectFirstKey
        while let token = try jsonDecoder.nextToken() {
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
                try jsonDecoder.decodeValue(key: key, group: &self)
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
/// Maps
///
public extension ProtobufMap {
}
