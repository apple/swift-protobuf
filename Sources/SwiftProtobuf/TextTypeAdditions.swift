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

public extension FieldType {
    public static func setFromText(scanner: TextScanner, value: inout BaseType) throws {
        var v: BaseType?
        try setFromText(scanner: scanner, value: &v)
        if let v = v {
            value = v
        }
    }
}

///
/// Float traits
///
public extension ProtobufFloat {
    public static func setFromText(scanner: TextScanner, value: inout BaseType?) throws {
        value = try scanner.nextFloat()
    }

    public static func setFromText(scanner: TextScanner, value: inout [BaseType]) throws {
        let n = try scanner.nextFloat()
        value.append(n)
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
        value = try scanner.nextDouble()
    }

    public static func setFromText(scanner: TextScanner, value: inout [BaseType]) throws {
        let n = try scanner.nextDouble()
        value.append(n)
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
        let n = try scanner.nextSInt()
        if n > Int64(Int32.max) || n < Int64(Int32.min) {
            throw DecodingError.malformedTextNumber
        }
        value = Int32(truncatingBitPattern: n)
    }

    public static func setFromText(scanner: TextScanner, value: inout [BaseType]) throws {
        let n = try scanner.nextSInt()
        if n > Int64(Int32.max) || n < Int64(Int32.min) {
            throw DecodingError.malformedTextNumber
        }
        value.append(Int32(truncatingBitPattern: n))
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
        value = try scanner.nextSInt()
    }

    public static func setFromText(scanner: TextScanner, value: inout [BaseType]) throws {
        let n = try scanner.nextSInt()
        value.append(n)
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
        let n = try scanner.nextUInt()
        if n > UInt64(UInt32.max) {
            throw DecodingError.malformedTextNumber
        }
        value = UInt32(truncatingBitPattern: n)
    }

    public static func setFromText(scanner: TextScanner, value: inout [BaseType]) throws {
        let n = try scanner.nextUInt()
        if n > UInt64(UInt32.max) {
            throw DecodingError.malformedTextNumber
        }
        value.append(UInt32(truncatingBitPattern: n))
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
        value = try scanner.nextUInt()
    }

    public static func setFromText(scanner: TextScanner, value: inout [BaseType]) throws {
        let n = try scanner.nextUInt()
        value.append(n)
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
        try ProtobufInt32.setFromText(scanner: scanner, value: &value)
    }

    public static func setFromText(scanner: TextScanner, value: inout [BaseType]) throws {
        try ProtobufInt32.setFromText(scanner: scanner, value: &value)
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
        try ProtobufInt64.setFromText(scanner: scanner, value: &value)
    }

    public static func setFromText(scanner: TextScanner, value: inout [BaseType]) throws {
        try ProtobufInt64.setFromText(scanner: scanner, value: &value)
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
        try ProtobufUInt32.setFromText(scanner: scanner, value: &value)
    }

    public static func setFromText(scanner: TextScanner, value: inout [BaseType]) throws {
        try ProtobufUInt32.setFromText(scanner: scanner, value: &value)
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
        try ProtobufUInt64.setFromText(scanner: scanner, value: &value)
    }

    public static func setFromText(scanner: TextScanner, value: inout [BaseType]) throws {
        try ProtobufUInt64.setFromText(scanner: scanner, value: &value)
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
        try ProtobufInt32.setFromText(scanner: scanner, value: &value)
    }

    public static func setFromText(scanner: TextScanner, value: inout [BaseType]) throws {
        try ProtobufInt32.setFromText(scanner: scanner, value: &value)
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
        try ProtobufInt64.setFromText(scanner: scanner, value: &value)
    }

    public static func setFromText(scanner: TextScanner, value: inout [BaseType]) throws {
        try ProtobufInt64.setFromText(scanner: scanner, value: &value)
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
        value = try scanner.nextBool()
    }

    public static func setFromText(scanner: TextScanner, value: inout [BaseType]) throws {
        let n = try scanner.nextBool()
        value.append(n)
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
        value = try scanner.nextStringValue()
    }

    public static func setFromText(scanner: TextScanner, value: inout [BaseType]) throws {
        let result = try scanner.nextStringValue()
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
        value = try scanner.nextBytesValue()
    }

    public static func setFromText(scanner: TextScanner, value: inout [BaseType]) throws {
        let result = try scanner.nextBytesValue()
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
        if let name = try scanner.nextOptionalEnumName() {
            if let b = Self(protoName: name) {
                value = b
                return
            } else {
                throw DecodingError.unrecognizedEnumValue
            }
        }
        let number = try scanner.nextSInt()
        if number >= Int64(Int32.min) && number <= Int64(Int32.max) {
            let n = Int32(truncatingBitPattern: number)
            value = Self(rawValue: Int(n))
            return
        }
        throw DecodingError.malformedText
    }

    public static func setFromText(scanner: TextScanner, value: inout [Self]) throws {
        if let name = try scanner.nextOptionalEnumName() {
            if let b = Self(protoName: name) {
                value.append(b)
                return
            } else {
                throw DecodingError.unrecognizedEnumValue
            }
        }
        let number = try scanner.nextSInt()
        if number >= Int64(Int32.min) && number <= Int64(Int32.max) {
            let n = Int32(truncatingBitPattern: number)
            let e = Self(rawValue: Int(n))!  // Note: Can never fail!
            // TODO: Google's C++ implementation of text format rejects unknown enum values
            value.append(e)
            return
        }
        throw DecodingError.malformedText
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
        let terminator = try scanner.skipObjectStart()
        var subDecoder = TextDecoder(scanner: scanner)
        try subDecoder.decodeFullObject(message: &self, terminator: terminator)
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
