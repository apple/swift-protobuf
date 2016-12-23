// Sources/SwiftProtobuf/TextTypeAdditions.swift - Text format primitive types
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
/// of protobuf text format handling.
///
// -----------------------------------------------------------------------------

import Foundation
import Swift

///
/// Float traits
///
public extension ProtobufFloat {
    public static func setFromText(scanner: TextScanner, value: inout BaseType?) throws {
        if let token = try scanner.next(), let n = token.asFloat {
            value = n
        } else {
            throw DecodingError.malformedTextNumber
        }
    }

    public static func setFromText(scanner: TextScanner, value: inout [BaseType]) throws {
        if let token = try scanner.next(), let n = token.asFloat {
            value.append(n)
        } else {
            throw DecodingError.malformedTextNumber
        }
    }

    public static func serializeTextValue(encoder: TextEncoder, value: Float) {
        encoder.putDoubleValue(value: Double(value))
    }
}

///
/// Double traits
///
public extension ProtobufDouble {

    public static func setFromText(scanner: TextScanner, value: inout BaseType?) throws {
        if let token = try scanner.next(), let n = token.asDouble {
            value = n
        } else {
            throw DecodingError.malformedTextNumber
        }
    }

    public static func setFromText(scanner: TextScanner, value: inout [BaseType]) throws {
        if let token = try scanner.next(), let n = token.asDouble {
            value.append(n)
        } else {
            throw DecodingError.malformedTextNumber
        }
    }

    public static func serializeTextValue(encoder: TextEncoder, value: Double) {
        encoder.putDoubleValue(value: value)
    }
}

///
/// Int32 traits
///
public extension ProtobufInt32 {
    public static func setFromText(scanner: TextScanner, value: inout BaseType?) throws {
        if let token = try scanner.next(), let n = token.asInt32 {
            value = n
        } else {
            throw DecodingError.malformedTextNumber
        }
    }

    public static func setFromText(scanner: TextScanner, value: inout [BaseType]) throws {
        if let token = try scanner.next(), let n = token.asInt32 {
            value.append(n)
        } else {
            throw DecodingError.malformedTextNumber
        }
    }

    public static func serializeTextValue(encoder: TextEncoder, value: Int32) {
        encoder.putInt64(value: Int64(value))
    }
}

///
/// Int64 traits
///
public extension ProtobufInt64 {
    public static func setFromText(scanner: TextScanner, value: inout BaseType?) throws {
        if let token = try scanner.next(), let n = token.asInt64 {
            value = n
        } else {
            throw DecodingError.malformedTextNumber
        }
    }

    public static func setFromText(scanner: TextScanner, value: inout [BaseType]) throws {
        if let token = try scanner.next(), let n = token.asInt64 {
            value.append(n)
        } else {
            throw DecodingError.malformedTextNumber
        }
    }

    public static func serializeTextValue(encoder: TextEncoder, value: Int64) {
        encoder.putInt64(value: value)
    }
}

///
/// UInt32 traits
///
public extension ProtobufUInt32 {
    public static func setFromText(scanner: TextScanner, value: inout BaseType?) throws {
        if let token = try scanner.next(), let n = token.asUInt32 {
            value = n
        } else {
            throw DecodingError.malformedTextNumber
        }
    }

    public static func setFromText(scanner: TextScanner, value: inout [BaseType]) throws {
        if let token = try scanner.next(), let n = token.asUInt32 {
            value.append(n)
        } else {
            throw DecodingError.malformedTextNumber
        }
    }

    public static func serializeTextValue(encoder: TextEncoder, value: UInt32) {
        encoder.putUInt64(value: UInt64(value))
    }
}

///
/// UInt64 traits
///
public extension ProtobufUInt64 {
    public static func setFromText(scanner: TextScanner, value: inout BaseType?) throws {
        if let token = try scanner.next(), let n = token.asUInt64 {
            value = n
        } else {
            throw DecodingError.malformedTextNumber
        }
    }

    public static func setFromText(scanner: TextScanner, value: inout [BaseType]) throws {
        if let token = try scanner.next(), let n = token.asUInt64 {
            value.append(n)
        } else {
            throw DecodingError.malformedTextNumber
        }
    }

    public static func serializeTextValue(encoder: TextEncoder, value: UInt64) {
        encoder.putUInt64(value: value)
    }
}

///
/// SInt32 traits
///
public extension ProtobufSInt32 {
    public static func setFromText(scanner: TextScanner, value: inout BaseType?) throws {
        if let token = try scanner.next(), let n = token.asInt32 {
            value = n
        } else {
            throw DecodingError.malformedTextNumber
        }
    }

    public static func setFromText(scanner: TextScanner, value: inout [BaseType]) throws {
        if let token = try scanner.next(), let n = token.asInt32 {
            value.append(n)
        } else {
            throw DecodingError.malformedTextNumber
        }
    }

    public static func serializeTextValue(encoder: TextEncoder, value: Int32) {
        encoder.putInt64(value: Int64(value))
    }
}

///
/// SInt64 traits
///
public extension ProtobufSInt64 {
    public static func setFromText(scanner: TextScanner, value: inout BaseType?) throws {
        if let token = try scanner.next(), let n = token.asInt64 {
            value = n
        } else {
            throw DecodingError.malformedTextNumber
        }
    }

    public static func setFromText(scanner: TextScanner, value: inout [BaseType]) throws {
        if let token = try scanner.next(), let n = token.asInt64 {
            value.append(n)
        } else {
            throw DecodingError.malformedTextNumber
        }
    }

    public static func serializeTextValue(encoder: TextEncoder, value: Int64) {
        encoder.putInt64(value: value)
    }
}

///
/// Fixed32 traits
///
public extension ProtobufFixed32 {
    public static func setFromText(scanner: TextScanner, value: inout BaseType?) throws {
        if let token = try scanner.next(), let n = token.asUInt32 {
            value = n
        } else {
            throw DecodingError.malformedTextNumber
        }
    }

    public static func setFromText(scanner: TextScanner, value: inout [BaseType]) throws {
        if let token = try scanner.next(), let n = token.asUInt32 {
            value.append(n)
        } else {
            throw DecodingError.malformedTextNumber
        }
    }

    public static func serializeTextValue(encoder: TextEncoder, value: UInt32) {
        encoder.putUInt64(value: UInt64(value))
    }
}

///
/// Fixed64 traits
///
public extension ProtobufFixed64 {
    public static func setFromText(scanner: TextScanner, value: inout BaseType?) throws {
        if let token = try scanner.next(), let n = token.asUInt64 {
            value = n
        } else {
            throw DecodingError.malformedTextNumber
        }
    }

    public static func setFromText(scanner: TextScanner, value: inout [BaseType]) throws {
        if let token = try scanner.next(), let n = token.asUInt64 {
            value.append(n)
        } else {
            throw DecodingError.malformedTextNumber
        }
    }

    public static func serializeTextValue(encoder: TextEncoder, value: UInt64) {
        encoder.putUInt64(value: value)
    }
}

///
/// SFixed32 traits
///
public extension ProtobufSFixed32 {
    public static func setFromText(scanner: TextScanner, value: inout BaseType?) throws {
        if let token = try scanner.next(), let n = token.asInt32 {
            value = n
        } else {
            throw DecodingError.malformedTextNumber
        }
    }

    public static func setFromText(scanner: TextScanner, value: inout [BaseType]) throws {
        if let token = try scanner.next(), let n = token.asInt32 {
            value.append(n)
        } else {
            throw DecodingError.malformedTextNumber
        }
    }

    public static func serializeTextValue(encoder: TextEncoder, value: Int32) {
        encoder.putInt64(value: Int64(value))
    }
}

///
/// SFixed64 traits
///
public extension ProtobufSFixed64 {
    public static func setFromText(scanner: TextScanner, value: inout BaseType?) throws {
        if let token = try scanner.next(), let n = token.asInt64 {
            value = n
        } else {
            throw DecodingError.malformedTextNumber
        }
    }

    public static func setFromText(scanner: TextScanner, value: inout [BaseType]) throws {
        if let token = try scanner.next(), let n = token.asInt64 {
            value.append(n)
        } else {
            throw DecodingError.malformedTextNumber
        }
    }

    public static func serializeTextValue(encoder: TextEncoder, value: Int64) {
        encoder.putInt64(value: value)
    }
}

///
/// Bool traits
///
public extension ProtobufBool {
    public static func setFromText(scanner: TextScanner, value: inout BaseType?) throws {
        if let token = try scanner.next(), let n = token.asBoolean {
            value = n
        } else {
            throw DecodingError.malformedText
        }
    }

    public static func setFromText(scanner: TextScanner, value: inout [BaseType]) throws {
        if let token = try scanner.next(), let n = token.asBoolean {
            value.append(n)
        } else {
            throw DecodingError.malformedText
        }
    }

    public static func serializeTextValue(encoder: TextEncoder, value: Bool) {
        encoder.putBoolValue(value: value)
    }
}

///
/// String traits
///
public extension ProtobufString {
    public static func setFromText(scanner: TextScanner, value: inout BaseType?) throws {
        if let token = try scanner.next(), case .string(_) = token, let s = token.asString {
            value = s
        } else {
            throw DecodingError.malformedText
        }
        while let token = try scanner.next() {
            if case .string = token, let s = token.asString {
                value!.append(s)
            } else {
                scanner.pushback(token: token)
                return
            }
        }
    }

    public static func setFromText(scanner: TextScanner, value: inout [BaseType]) throws {
        var result: String
        if let token = try scanner.next(), let s = token.asString {
            result = s
        } else {
            throw DecodingError.malformedText
        }
        while let token = try scanner.next() {
            if case .string = token, let s = token.asString {
                result.append(s)
            } else {
                scanner.pushback(token: token)
                break
            }
        }
        value.append(result)
    }

    public static func serializeTextValue(encoder: TextEncoder, value: String) {
        encoder.putStringValue(value: value)
    }
}

///
/// Bytes traits
///
public extension ProtobufBytes {
    public static func setFromText(scanner: TextScanner, value: inout Data?) throws {
        if let token = try scanner.next(), let n = token.asBytes {
            value = n
        } else {
            throw DecodingError.malformedText
        }
        while let token = try scanner.next() {
            if let n = token.asBytes {
                value!.append(n)
            } else {
                scanner.pushback(token: token)
                return
            }
        }
    }

    public static func setFromText(scanner: TextScanner, value: inout [BaseType]) throws {
        var result: Data
        if let token = try scanner.next(), let n = token.asBytes {
            result = n
        } else {
            throw DecodingError.malformedText
        }
        while let token = try scanner.next() {
            if let n = token.asBytes {
                result.append(n)
            } else {
                scanner.pushback(token: token)
                break
            }
        }
        value.append(result)
    }

    public static func serializeTextValue(encoder: TextEncoder, value: Data) {
        encoder.putBytesValue(value: value)
    }
}

//
// Enum traits
//
extension Enum where RawValue == Int {
    public static func setFromText(scanner: TextScanner, value: inout Self?) throws {
        if let token = try scanner.next() {
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
        } else {
            throw DecodingError.malformedText
        }
    }

    public static func setFromText(scanner: TextScanner, value: inout [Self]) throws {
        if let token = try scanner.next() {
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
        } else {
            throw DecodingError.malformedText
        }
    }

    public static func serializeTextValue(encoder: TextEncoder, value: Self) {
        encoder.putEnumValue(value: value)
    }
}

///
/// Messages
///
public extension Message {

    init(scanner: TextScanner) throws {
        self.init()
        let terminator = try scanner.readObjectStart()
        var subDecoder = TextDecoder(scanner: scanner)
        try subDecoder.decodeFullObject(message: &self, terminator: terminator)
    }

    static func setFromText(scanner: TextScanner, value: inout Self?) throws {
        let message = try Self(scanner: scanner)
        value = message
    }

    static func setFromText(scanner: TextScanner, value: inout [Self]) throws {
        let message = try Self(scanner: scanner)
        value.append(message)
    }

    public func serializeText() throws -> String {
        let visitor = TextEncodingVisitor(message: self)
        try traverse(visitor: visitor)
        return visitor.result
    }

    static func serializeTextValue(encoder: TextEncoder, value: Self) throws {
        encoder.startObject()
        let visitor = TextEncodingVisitor(message: value, encoder: encoder)
        try value.traverse(visitor: visitor)
        encoder.endObject()
    }

    public init(text: String, extensions: ExtensionSet? = nil) throws {
        self.init()
        var textDecoder = TextDecoder(text: text, extensions: extensions)
        try textDecoder.decodeFullObject(message: &self, terminator: nil)
        if !textDecoder.complete {
            throw DecodingError.trailingGarbage
        }
    }
}
