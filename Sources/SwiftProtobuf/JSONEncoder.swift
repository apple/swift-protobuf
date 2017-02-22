// Sources/SwiftProtobuf/JSONEncoder.swift - JSON Encoding support
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// JSON serialization engine.
///
// -----------------------------------------------------------------------------

import Foundation

private let asciiZero = UInt8(ascii: "0")
private let asciiOne = UInt8(ascii: "1")
private let asciiTwo = UInt8(ascii: "2")
private let asciiThree = UInt8(ascii: "3")
private let asciiFour = UInt8(ascii: "4")
private let asciiFive = UInt8(ascii: "5")
private let asciiSix = UInt8(ascii: "6")
private let asciiSeven = UInt8(ascii: "7")
private let asciiEight = UInt8(ascii: "8")
private let asciiNine = UInt8(ascii: "9")
private let asciiMinus = UInt8(ascii: "-")
private let asciiColon = UInt8(ascii: ":")
private let asciiComma = UInt8(ascii: ",")
private let asciiDoubleQuote = UInt8(ascii: "\"")
private let asciiBackslash = UInt8(ascii: "\\")
private let asciiOpenCurlyBracket = UInt8(ascii: "{")
private let asciiCloseCurlyBracket = UInt8(ascii: "}")
private let asciiLowerA = UInt8(ascii: "a")
private let asciiUpperA = UInt8(ascii: "A")
private let asciiUpperB = UInt8(ascii: "B")
private let asciiLowerB = UInt8(ascii: "b")
private let asciiUpperC = UInt8(ascii: "C")
private let asciiUpperD = UInt8(ascii: "D")
private let asciiUpperE = UInt8(ascii: "E")
private let asciiLowerE = UInt8(ascii: "e")
private let asciiUpperF = UInt8(ascii: "F")
private let asciiLowerF = UInt8(ascii: "f")
private let asciiUpperI = UInt8(ascii: "I")
private let asciiLowerL = UInt8(ascii: "l")
private let asciiLowerN = UInt8(ascii: "n")
private let asciiUpperN = UInt8(ascii: "N")
private let asciiLowerR = UInt8(ascii: "r")
private let asciiLowerS = UInt8(ascii: "s")
private let asciiLowerT = UInt8(ascii: "t")
private let asciiLowerU = UInt8(ascii: "u")

// Although JSONEncoder itself is public, it has no public members.
// It is only public because FieldType is public and we're currently
// implementing JSON maps by reflecting JSONEncoders through the FieldTypes.

// This problem doesn't arise for other formats because they don't
// use map keys as field names.

public struct JSONEncoder {
    private var data = [UInt8]()
    private var separator: UInt8?
    internal var isMapKey = false

    internal init() {}

    internal var dataResult: Data { return Data(bytes: data) }

    internal var stringResult: String {
        get {
            return String(bytes: data, encoding: String.Encoding.utf8)!
        }
    }

    internal mutating func append(staticText: StaticString) {
        let buff = UnsafeBufferPointer(start: staticText.utf8Start, count: staticText.utf8CodeUnitCount)
        data.append(contentsOf: buff)
    }

    internal mutating func append(text: String) {
        data.append(contentsOf: text.utf8)
    }

    internal mutating func startField(name: StaticString) {
        if let s = separator {
            data.append(s)
        }
        data.append(asciiDoubleQuote)
        // Append the StaticString's utf8 contents directly
        append(staticText: name)
        append(staticText: "\":")
        separator = asciiComma
    }

    internal mutating func startField(name: String) {
        if let s = separator {
            data.append(s)
        }
        data.append(asciiDoubleQuote)
        // Can avoid overhead of putStringValue, since
        // the JSON field names are always clean ASCII.
        data.append(contentsOf: name.utf8)
        append(staticText: "\":")
        separator = asciiComma
    }

    internal mutating func startObject() {
        data.append(asciiOpenCurlyBracket)
        separator = nil
    }
    internal mutating func endObject() {
        data.append(asciiCloseCurlyBracket)
        separator = asciiComma
    }
    internal mutating func putNullValue() {
        append(staticText: "null")
    }
    internal mutating func putFloatValue(value: Float) {
        putDoubleValue(value: Double(value))
    }
    internal mutating func putDoubleValue(value: Double) {
        if value.isNaN {
            append(staticText: "\"NaN\"")
        } else if !value.isFinite {
            if value < 0 {
                append(staticText: "\"-Infinity\"")
            } else {
                append(staticText: "\"Infinity\"")
            }
        } else {
            // TODO: Be smarter here about choosing significant digits
            // See: protoc source has C++ code for this with interesting ideas
            if let v = Int64(safely: value) {
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
    internal mutating func putEnumInt(value: Int) {
        appendInt(value: Int64(value))
    }
    internal mutating func putInt64(value: Int64) {
        data.append(asciiDoubleQuote)
        appendInt(value: value)
        data.append(asciiDoubleQuote)
    }
    internal mutating func putInt32(value: Int32) {
        if isMapKey {
            data.append(asciiDoubleQuote)
            appendInt(value: Int64(value))
            data.append(asciiDoubleQuote)
        } else {
            appendInt(value: Int64(value))
        }
    }

    internal mutating func putUInt64(value: UInt64) {
        data.append(asciiDoubleQuote)
        appendUInt(value: value)
        data.append(asciiDoubleQuote)
    }

    internal mutating func putUInt32(value: UInt32) {
        if isMapKey {
            data.append(asciiDoubleQuote)
            appendUInt(value: UInt64(value))
            data.append(asciiDoubleQuote)
        } else {
            appendUInt(value: UInt64(value))
        }
    }

    internal mutating func putBoolValue(value: Bool) {
        if isMapKey {
            data.append(asciiDoubleQuote)
        }
        if value {
            append(staticText: "true")
        } else {
            append(staticText: "false")
        }
        if isMapKey {
            data.append(asciiDoubleQuote)
        }
    }
    internal mutating func putStringValue(value: String) {
        let hexDigits = [asciiZero, asciiOne, asciiTwo, asciiThree, asciiFour, asciiFive, asciiSix, asciiSeven,
                         asciiEight, asciiNine, asciiUpperA, asciiUpperB, asciiUpperC, asciiUpperD, asciiUpperE, asciiUpperF];
        data.append(asciiDoubleQuote)
        for c in value.unicodeScalars {
            switch c.value {
            // Special two-byte escapes
            case 8: append(staticText: "\\b")
            case 9: append(staticText: "\\t")
            case 10: append(staticText: "\\n")
            case 12: append(staticText: "\\f")
            case 13: append(staticText: "\\r")
            case 34: append(staticText: "\\\"")
            case 92: append(staticText: "\\\\")
            case 0...31, 127...159: // Hex form for C0 control chars
                append(staticText: "\\u00")
                data.append(hexDigits[Int(c.value / 16)])
                data.append(hexDigits[Int(c.value & 15)])
            case 23...126:
                data.append(UInt8(truncatingBitPattern: c.value))
            case 0x80...0x7ff:
                data.append(0xc0 + UInt8(truncatingBitPattern: c.value >> 6))
                data.append(0x80 + UInt8(truncatingBitPattern: c.value & 0x3f))
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

    internal mutating func putBytesValue(value: Data) {
        var out: String = ""
        if value.count > 0 {
            let digits: [Character] = ["A", "B", "C", "D", "E", "F",
            "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q",
            "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "a", "b",
            "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m",
            "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x",
            "y", "z", "0", "1", "2", "3", "4", "5", "6", "7", "8",
            "9", "+", "/"]
            var t: Int = 0
            for (i,v) in value.enumerated() {
                if i > 0 && i % 3 == 0 {
                    out.append(digits[(t >> 18) & 63])
                    out.append(digits[(t >> 12) & 63])
                    out.append(digits[(t >> 6) & 63])
                    out.append(digits[t & 63])
                    t = 0
                }
                t <<= 8
                t += Int(v)
            }
            switch value.count % 3 {
            case 0:
                out.append(digits[(t >> 18) & 63])
                out.append(digits[(t >> 12) & 63])
                out.append(digits[(t >> 6) & 63])
                out.append(digits[t & 63])
            case 1:
                t <<= 16
                out.append(digits[(t >> 18) & 63])
                out.append(digits[(t >> 12) & 63])
                out.append(Character("="))
                out.append(Character("="))
            default:
                t <<= 8
                out.append(digits[(t >> 18) & 63])
                out.append(digits[(t >> 12) & 63])
                out.append(digits[(t >> 6) & 63])
                out.append(Character("="))
            }
        }
        append(text: "\"" + out + "\"")
    }
}

