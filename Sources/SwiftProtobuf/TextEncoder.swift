// ProtobufRuntime/Sources/Protobuf/ProtobufTextEncoding.swift - Text format encoding support
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
/// Text format serialization engine.
///
// -----------------------------------------------------------------------------

import Foundation

public struct TextEncoder {
    var text: [String] = []
    public init() {}
    public var result: String { return text.joined(separator: "") }

    mutating func append(text newText: String) {
        text.append(newText)
    }
    mutating func appendTokens(tokens: [TextToken]) {
        for t in tokens {
            switch t {
            case .beginArray: append(text: "[")
            case .beginObject: append(text: "{")
            case .colon: append(text: ":")
            case .comma: append(text: ",")
            case .endArray: append(text: "]")
            case .endObject: append(text: "}")
            case .octalInteger(let v): append(text: v)
            case .hexadecimalInteger(let v): append(text: v)
            case .decimalInteger(let v): append(text: v)
            case .floatingPointLiteral(let v): append(text: v)
            case .string(let v): putStringValue(value: v)
            case .identifier(let v): append(text: v)
            }
        }
    }
    mutating func startField(name: String, tabLevel: Int, dropColon:Bool = false) {
        for _ in 0..<tabLevel {
            append(text:"  ")
        }

        if dropColon {
            append(text: name + " ")
        } else {
            append(text: name + ": ")
        }
    }
    mutating func endField() {
        append(text: "\n")
    }
    public mutating func startObject() {
        append(text: "{\n")
    }
    public mutating func endObject(tabLevel: Int) {
        for _ in 0..<tabLevel {
            append(text:"  ")
        }

        append(text: "}")
    }
    mutating func putNullValue() {
        append(text: "null")
    }
    mutating func putFloatValue(value: Float, quote: Bool) {
        putDoubleValue(value: Double(value), quote: quote)
    }
    mutating func putDoubleValue(value: Double, quote: Bool) {
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
            let s: String
            if value < Double(Int64.max) && value > Double(Int64.min) && value == Double(Int64(value)) {
                s = String(Int64(value))
            } else {
                s = String(value)
            }
            if quote {
                append(text: "\"" + s + "\"")
            } else {
                append(text: s)
            }
        }
    }
    mutating func putInt64(value: Int64, quote: Bool) {
        append(text: String(value))
    }
    mutating func putUInt64(value: UInt64, quote: Bool) {
        append(text: String(value))
    }

    mutating func putBoolValue(value: Bool, quote: Bool) {
        if quote {
            append(text: value ? "\"true\"" : "\"false\"")
        } else {
            append(text: value ? "true" : "false")
        }
    }
    mutating func putStringValue(value: String) {
        let hexDigits = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F"];
        append(text: "\"")
        for c in value.unicodeScalars {
            switch c.value {
            // Special two-byte escapes
            case 8: append(text: "\\b")
            case 9: append(text: "\\t")
            case 10: append(text: "\\n")
            case 12: append(text: "\\f")
            case 13: append(text: "\\r")
            case 34: append(text: "\\\"")
            case 92: append(text: "\\\\")
            case 0...31, 127...159: // Hex form for C0 and C1 control chars
                let digit1 = hexDigits[Int(c.value / 16)]
                let digit2 = hexDigits[Int(c.value & 15)]
                append(text: "\\u00\(digit1)\(digit2)")
            case 0...127:  // ASCII
                append(text: String(c))
            default: // Non-ASCII
                append(text: String(c))
            }
        }
        append(text: "\"")
    }

    mutating func putBytesValue(value: Data) {
        append(text: "\"")
        value.withUnsafeBytes { (p: UnsafePointer<UInt8>) in
            for i in 0..<value.count {
                let c = p[i]
                switch c {
                // Special two-byte escapes
                case 8: append(text: "\\b")
                case 9: append(text: "\\t")
                case 10: append(text: "\\n")
                case 12: append(text: "\\f")
                case 13: append(text: "\\r")
                case 34: append(text: "\\\"")
                case 92: append(text: "\\\\")
                case 32...126:  // printable ASCII
                    append(text: String(UnicodeScalar(c)))
                default:
                    let digit1 = Int(c / 64)
                    let digit2 = Int((c / 8) & 7)
                    let digit3 = Int(c & 7)
                    append(text: "\\\(digit1)\(digit2)\(digit3)")
                }
            }
        }
        append(text: "\"")
    }
}

