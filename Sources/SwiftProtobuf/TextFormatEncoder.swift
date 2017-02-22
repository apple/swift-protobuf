// Sources/SwiftProtobuf/TextFormatEncoder.swift - Text format encoding support
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Text format serialization engine.
///
// -----------------------------------------------------------------------------

import Foundation

private let asciiSpace = UInt8(ascii: " ")
private let asciiColon = UInt8(ascii: ":")
private let asciiComma = UInt8(ascii: ",")
private let asciiMinus = UInt8(ascii: "-")
private let asciiBackslash = UInt8(ascii: "\\")
private let asciiDoubleQuote = UInt8(ascii: "\"")
private let asciiZero = UInt8(ascii: "0")
private let asciiOpenCurlyBracket = UInt8(ascii: "{")
private let asciiCloseCurlyBracket = UInt8(ascii: "}")
private let asciiOpenSquareBracket = UInt8(ascii: "[")
private let asciiCloseSquareBracket = UInt8(ascii: "]")
private let asciiNewline = UInt8(ascii: "\n")
private let asciiLowerB = UInt8(ascii: "b")
private let asciiLowerF = UInt8(ascii: "f")
private let asciiLowerN = UInt8(ascii: "n")
private let asciiLowerR = UInt8(ascii: "r")
private let asciiLowerT = UInt8(ascii: "t")
private let asciiLowerV = UInt8(ascii: "v")

private let tabSize = 2

/// TextFormatEncoder has no public members.
internal struct TextFormatEncoder {
    private var data = [UInt8]()
    private var indent: [UInt8] = []
    var stringResult: String {
        get {
            return String(bytes: data, encoding: String.Encoding.utf8)!
        }
    }

    private mutating func append(text: String) {
        data.append(contentsOf: text.utf8)
    }

    init() {}

    private mutating func appendFieldName(name: StaticString, inExtension: Bool) {
        data.append(contentsOf: indent)
        if inExtension {
            data.append(asciiOpenSquareBracket)
        }
        let buff = UnsafeBufferPointer(start: name.utf8Start, count: name.utf8CodeUnitCount)
        data.append(contentsOf: buff)
        if inExtension {
            data.append(asciiCloseSquareBracket)
        }
    }

    // In Text format, fields with simple types write the name with
    // a trailing colon:
    //    name_of_field: value
    mutating func startField(name: StaticString, inExtension: Bool) {
        appendFieldName(name: name, inExtension: inExtension)
        data.append(asciiColon)
        data.append(asciiSpace)
    }

    // In Text format, a message-valued field writes the name
    // without a trailing colon:
    //    name_of_field {key: value key2: value2}
    mutating func startMessageField(name: StaticString, inExtension: Bool) {
        appendFieldName(name: name, inExtension: inExtension)
        data.append(asciiSpace)
    }

    mutating func endField() {
        data.append(asciiNewline)
    }

    mutating func startObject() {
        for _ in 1...tabSize {
            indent.append(asciiSpace)
        }
        data.append(asciiOpenCurlyBracket)
        data.append(asciiNewline)
    }

    mutating func endObject() {
        for _ in 1...tabSize {
            indent.remove(at: indent.count - 1)
        }
        data.append(contentsOf: indent)
        data.append(asciiCloseCurlyBracket)
    }

    mutating func startArray() {
        data.append(asciiOpenSquareBracket)
    }

    mutating func arraySeparator() {
        data.append(asciiComma)
        data.append(asciiSpace)
    }

    mutating func endArray() {
        data.append(asciiCloseSquareBracket)
    }

    mutating func putEnumValue<E: Enum>(value: E) {
        // The JSON enum text is the same as the Text value, so we can
        // reuse the JSON serialization.
        if let json = value._protobuf_jsonName {
            append(text: json)
        } else {
            appendInt(value: Int64(value.rawValue))
        }
    }

    mutating func putDoubleValue(value: Double) {
        if value.isNaN {
            append(text: "nan")
        } else if !value.isFinite {
            if value < 0 {
                append(text: "-inf")
            } else {
                append(text: "inf")
            }
        } else {
            // TODO: Be smarter here about choosing significant digits
            // See: protoc source has C++ code for this with interesting ideas
            if let v = Int64(exactly: value) {
                appendInt(value: v)
            } else {
                let s = String(value)
                append(text: s)
            }
        }
    }

    private mutating func appendUInt(value: UInt64) {
        if value >= 10 {
            appendUInt(value: value / 10)
        }
        data.append(asciiZero + UInt8(value % 10))
    }
    private mutating func appendInt(value: Int64) {
        if value < 0 {
            data.append(asciiMinus)
            // This is the twos-complement negation of value,
            // computed in a way that won't overflow a 64-bit
            // signed integer.
            appendUInt(value: 1 + ~UInt64(bitPattern: value))
        } else {
            appendUInt(value: UInt64(bitPattern: value))
        }
    }

    mutating func putInt64(value: Int64) {
        appendInt(value: value)
    }

    mutating func putUInt64(value: UInt64) {
        appendUInt(value: value)
    }

    mutating func putBoolValue(value: Bool) {
        append(text: value ? "true" : "false")
    }

    mutating func putStringValue(value: String) {
        data.append(asciiDoubleQuote)
        for c in value.unicodeScalars {
            switch c.value {
            // Special two-byte escapes
            case 8:
                data.append(asciiBackslash)
                data.append(asciiLowerB)
            case 9:
                data.append(asciiBackslash)
                data.append(asciiLowerT)
            case 10:
                data.append(asciiBackslash)
                data.append(asciiLowerN)
            case 11:
                data.append(asciiBackslash)
                data.append(asciiLowerV)
            case 12:
                data.append(asciiBackslash)
                data.append(asciiLowerF)
            case 13:
                data.append(asciiBackslash)
                data.append(asciiLowerR)
            case 34:
                data.append(asciiBackslash)
                data.append(asciiDoubleQuote)
            case 92:
                data.append(asciiBackslash)
                data.append(asciiBackslash)
            case 0...31, 127: // Hex form for C0 control chars
                data.append(asciiBackslash)
                data.append(asciiZero + UInt8(c.value / 64))
                data.append(asciiZero + UInt8(c.value / 8 % 8))
                data.append(asciiZero + UInt8(c.value % 8))
            case 0...127:  // ASCII
                data.append(UInt8(truncatingBitPattern: c.value))
            case 0x80...0x7ff:
                data.append(0xc0 + UInt8(c.value / 64))
                data.append(0x80 + UInt8(c.value % 64))
            case 0x800...0xffff:
                data.append(0xe0 + UInt8(truncatingBitPattern: c.value >> 12))
                data.append(0x80 + UInt8(truncatingBitPattern: (c.value >> 6) & 0x3f))
                data.append(0x80 + UInt8(truncatingBitPattern: c.value & 0x3f))
            default:
                data.append(0xf0 + UInt8(truncatingBitPattern: c.value >> 18))
                data.append(0x80 + UInt8(truncatingBitPattern: (c.value >> 12) & 0x3f))
                data.append(0x80 + UInt8(truncatingBitPattern: (c.value >> 6) & 0x3f))
                data.append(0x80 + UInt8(truncatingBitPattern: c.value & 0x3f))
            }
        }
        data.append(asciiDoubleQuote)
    }

    mutating func putBytesValue(value: Data) {
        data.append(asciiDoubleQuote)
        value.withUnsafeBytes { (p: UnsafePointer<UInt8>) in
            for i in 0..<value.count {
                let c = p[i]
                switch c {
                // Special two-byte escapes
                case 8:
                    data.append(asciiBackslash)
                    data.append(asciiLowerB)
                case 9:
                    data.append(asciiBackslash)
                    data.append(asciiLowerT)
                case 10:
                    data.append(asciiBackslash)
                    data.append(asciiLowerN)
                case 11:
                    data.append(asciiBackslash)
                    data.append(asciiLowerV)
                case 12:
                    data.append(asciiBackslash)
                    data.append(asciiLowerF)
                case 13:
                    data.append(asciiBackslash)
                    data.append(asciiLowerR)
                case 34:
                    data.append(asciiBackslash)
                    data.append(asciiDoubleQuote)
                case 92:
                    data.append(asciiBackslash)
                    data.append(asciiBackslash)
                case 32...126:  // printable ASCII
                    data.append(c)
                default: // Octal form for non-printable chars
                    data.append(asciiBackslash)
                    data.append(asciiZero + UInt8(c / 64))
                    data.append(asciiZero + UInt8(c / 8 % 8))
                    data.append(asciiZero + UInt8(c % 8))
                }
            }
        }
        data.append(asciiDoubleQuote)
    }
}

