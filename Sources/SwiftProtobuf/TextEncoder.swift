// Sources/SwiftProtobuf/TextEncoder.swift - Text format encoding support
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

/// TextEncoder has no public members.
public class TextEncoder {
    var text: String = ""
    private var tabLevel = 0
    var result: String { return text }

    init() {}

    // In Text format, fields with simple types write the name with
    // a trailing colon:
    //    name_of_field: value
    func startField(name: String) {
        for _ in 0..<tabLevel {
            text.append("  ")
        }
        text.append(name)
        text.append(":")
        text.append(" ")
    }

    // In Text format, a message-valued field writes the name
    // without a trailing colon:
    //    name_of_field {key: value key2: value2}
    func startMessageField(name: String) {
        for _ in 0..<tabLevel {
            text.append("  ")
        }
        text.append(name)
        text.append(" ")
    }

    func endField() {
        text.append("\n")
    }

    func startObject() {
        tabLevel += 1
        text.append("{\n")
    }

    func endObject() {
        tabLevel -= 1
        for _ in 0..<tabLevel {
            text.append("  ")
        }

        text.append("}")
    }

    func startArray() {
        text.append("[")
    }

    func arraySeparator() {
        text.append(", ")
    }

    func endArray() {
        text.append("]")
    }

    func putEnumValue<E: Enum>(value: E) {
        // The JSON enum text is the same as the Text value, so we can
        // reuse the JSON serialization (after stripping quotes).
        text.append(value.json.trimmingCharacters(in:["\""]))
    }

    func putDoubleValue(value: Double) {
        if value.isNaN {
            text.append("nan")
        } else if !value.isFinite {
            if value < 0 {
                text.append("-inf")
            } else {
                text.append("inf")
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
            text.append(s)
        }
    }

    func putInt64(value: Int64) {
        text.append(String(value))
    }

    func putUInt64(value: UInt64) {
        text.append(String(value))
    }

    func putBoolValue(value: Bool) {
        text.append(value ? "true" : "false")
    }

    func putStringValue(value: String) {
        let octalDigits = ["0", "1", "2", "3", "4", "5", "6", "7"]
        text.append("\"")
        for c in value.unicodeScalars {
            switch c.value {
            // Special two-byte escapes
            case 8: text.append("\\b")
            case 9: text.append("\\t")
            case 10: text.append("\\n")
            case 11: text.append("\\v")
            case 12: text.append("\\f")
            case 13: text.append("\\r")
            case 34: text.append("\\\"")
            case 92: text.append("\\\\")
            case 0...31, 127: // Hex form for C0 control chars
                let digit1 = octalDigits[Int(c.value / 64)]
                let digit2 = octalDigits[Int(c.value / 8 % 8)]
                let digit3 = octalDigits[Int(c.value % 8)]
                text.append("\\\(digit1)\(digit2)\(digit3)")
            case 0...127:  // ASCII
                text.append(String(c))
            default: // Non-ASCII
                text.append(String(c))
            }
        }
        text.append("\"")
    }

    func putBytesValue(value: Data) {
        text.append("\"")
        value.withUnsafeBytes { (p: UnsafePointer<UInt8>) in
            for i in 0..<value.count {
                let c = p[i]
                switch c {
                // Special two-byte escapes
                case 8: text.append("\\b")
                case 9: text.append("\\t")
                case 10: text.append("\\n")
                case 11: text.append("\\v")
                case 12: text.append("\\f")
                case 13: text.append("\\r")
                case 34: text.append("\\\"")
                case 92: text.append("\\\\")
                case 32...126:  // printable ASCII
                    text.append(String(UnicodeScalar(c)))
                default:
                    let digit1 = Int(c / 64)
                    let digit2 = Int((c / 8) & 7)
                    let digit3 = Int(c & 7)
                    text.append("\\\(digit1)\(digit2)\(digit3)")
                }
            }
        }
        text.append("\"")
    }
}

