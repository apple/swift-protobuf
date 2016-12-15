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

public class TextEncoder {
    var text: [String] = []
    private var tabLevel = 0

    init() {}

    var result: String { return text.joined(separator: "") }

    func append(text newText: String) {
        text.append(newText)
    }

    func startField(name: String) {
        for _ in 0..<tabLevel {
            append(text:"  ")
        }
        append(text: name)
        append(text: ":")
        append(text: " ")
    }

    func startMessageField(name: String) {
        for _ in 0..<tabLevel {
            append(text: "  ")
        }
        append(text: name)
        append(text: " ")
    }

    func endField() {
        append(text: "\n")
    }

    func startObject() {
        tabLevel += 1
        append(text: "{\n")
    }

    func endObject() {
        tabLevel -= 1
        for _ in 0..<tabLevel {
            append(text:"  ")
        }

        append(text: "}")
    }

    func putDoubleValue(value: Double) {
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
            append(text: s)
        }
    }

    func putInt64(value: Int64) {
        append(text: String(value))
    }

    func putUInt64(value: UInt64) {
        append(text: String(value))
    }

    func putBoolValue(value: Bool) {
        append(text: value ? "true" : "false")
    }

    func putStringValue(value: String) {
        let octalDigits = ["0", "1", "2", "3", "4", "5", "6", "7"]
        append(text: "\"")
        for c in value.unicodeScalars {
            switch c.value {
            // Special two-byte escapes
            case 8: append(text: "\\b")
            case 9: append(text: "\\t")
            case 10: append(text: "\\n")
            case 11: append(text: "\\v")
            case 12: append(text: "\\f")
            case 13: append(text: "\\r")
            case 34: append(text: "\\\"")
            case 92: append(text: "\\\\")
            case 0...31, 127: // Hex form for C0 control chars
                let digit1 = octalDigits[Int(c.value / 64)]
                let digit2 = octalDigits[Int(c.value / 8 % 8)]
                let digit3 = octalDigits[Int(c.value % 8)]
                append(text: "\\\(digit1)\(digit2)\(digit3)")
            case 0...127:  // ASCII
                append(text: String(c))
            default: // Non-ASCII
                append(text: String(c))
            }
        }
        append(text: "\"")
    }

    func putBytesValue(value: Data) {
        append(text: "\"")
        value.withUnsafeBytes { (p: UnsafePointer<UInt8>) in
            for i in 0..<value.count {
                let c = p[i]
                switch c {
                // Special two-byte escapes
                case 8: append(text: "\\b")
                case 9: append(text: "\\t")
                case 10: append(text: "\\n")
                case 11: append(text: "\\v")
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

