// Sources/SwiftProtobuf/TextFormatEncoder.swift - Text format encoding support
//
// Copyright (c) 2014 - 2019 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
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
private let asciiUpperA = UInt8(ascii: "A")

private let tabSize = 2
private let tab = [UInt8](repeating: asciiSpace, count: tabSize)

/// TextFormatEncoder has no public members.
internal struct TextFormatEncoder {
    private static let foyerSize = 4096
    private var foyer = Array<UInt8>(repeating: 0, count: TextFormatEncoder.foyerSize)
    private var foyerIndex = 0

    private var data = [UInt8]()
    private var indentString: [UInt8] = []

    internal mutating func constructFinalResult() -> String {
        if foyerIndex > 0 {
            let subfoyer = foyer[0..<foyerIndex]
            data.append(contentsOf: subfoyer)
            foyerIndex = 0
        }
        return String(bytes: data, encoding: String.Encoding.utf8)!
    }

    // Append each byte to the foyer, append and
    // recycle the foyer when it fills up.
    private mutating func append(byte: UInt8) {
        if foyerIndex > TextFormatEncoder.foyerSize - 1 {
            data.append(contentsOf: foyer)
            foyerIndex = 0
        }
        foyer[foyerIndex] = byte
        foyerIndex += 1
    }

    internal mutating func append(staticText: StaticString) {
        let buff = UnsafeBufferPointer(start: staticText.utf8Start, count: staticText.utf8CodeUnitCount)
        for b in buff {
            append(byte: b)
        }
    }

    internal mutating func append(name: _NameMap.Name) {
        for b in name.utf8Buffer {
            append(byte: b)
        }
    }

    internal mutating func append(bytes: [UInt8]) {
        for b in bytes {
            append(byte: b)
        }
    }

    private mutating func append(bytes: UnsafeRawBufferPointer) {
        for b in bytes {
            append(byte: b)
        }
    }

    private mutating func append(text: String) {
        for u in text.utf8 {
            append(byte: u)
        }
    }

    init() {}

    internal mutating func indent() {
        append(bytes: indentString)
    }

    mutating func emitFieldName(name: UnsafeRawBufferPointer) {
        indent()
        append(bytes: name)
    }

    mutating func emitFieldName(name: StaticString) {
        let buff = UnsafeRawBufferPointer(start: name.utf8Start, count: name.utf8CodeUnitCount)
        indent()
        append(bytes: buff)
    }

    mutating func emitFieldName(name: [UInt8]) {
        indent()
        append(bytes: name)
    }

    mutating func emitExtensionFieldName(name: String) {
        indent()
        append(byte: asciiOpenSquareBracket)
        append(text: name)
        append(byte: asciiCloseSquareBracket)
    }

    mutating func emitFieldNumber(number: Int) {
        indent()
        appendUInt(value: UInt64(number))
    }

    mutating func startRegularField() {
        append(staticText: ": ")
    }
    mutating func endRegularField() {
        append(byte: asciiNewline)
    }

    // In Text format, a message-valued field writes the name
    // without a trailing colon:
    //    name_of_field {key: value key2: value2}
    mutating func startMessageField() {
        append(staticText: " {\n")
        indentString.append(contentsOf: tab)
    }

    mutating func endMessageField() {
        indentString.removeLast(tabSize)
        indent()
        append(staticText: "}\n")
    }

    mutating func startArray() {
        append(byte: asciiOpenSquareBracket)
    }

    mutating func arraySeparator() {
        append(staticText: ", ")
    }

    mutating func endArray() {
        append(byte: asciiCloseSquareBracket)
    }

    mutating func putEnumValue<E: Enum>(value: E) {
        if let name = value.name {
            append(bytes: name.utf8Buffer)
        } else {
            appendInt(value: Int64(value.rawValue))
        }
    }

    mutating func putFloatValue(value: Float) {
        if value.isNaN {
            append(staticText: "nan")
        } else if !value.isFinite {
            if value < 0 {
                append(staticText: "-inf")
            } else {
                append(staticText: "inf")
            }
        } else {
            append(text: value.debugDescription)
        }
    }

    mutating func putDoubleValue(value: Double) {
        if value.isNaN {
            append(staticText: "nan")
        } else if !value.isFinite {
            if value < 0 {
                append(staticText: "-inf")
            } else {
                append(staticText: "inf")
            }
        } else {
            append(text: value.debugDescription)
        }
    }

    private mutating func appendUInt(value: UInt64) {
        if value >= 1000 {
            appendUInt(value: value / 1000)
        }
        if value >= 100 {
            append(byte: asciiZero + UInt8((value / 100) % 10))
        }
        if value >= 10 {
            append(byte: asciiZero + UInt8((value / 10) % 10))
        }
        append(byte: asciiZero + UInt8(value % 10))
    }
    private mutating func appendInt(value: Int64) {
        if value < 0 {
            append(byte: asciiMinus)
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

    mutating func appendUIntHex(value: UInt64, digits: Int) {
        if digits == 0 {
            append(staticText: "0x")
        } else {
            appendUIntHex(value: value >> 4, digits: digits - 1)
            let d = UInt8(truncatingIfNeeded: value % 16)
            append(byte: d < 10 ? asciiZero + d : asciiUpperA + d - 10)
        }
    }

    mutating func putUInt64Hex(value: UInt64, digits: Int) {
        appendUIntHex(value: value, digits: digits)
    }

    mutating func putBoolValue(value: Bool) {
        append(staticText: value ? "true" : "false")
    }

    mutating func putStringValue(value: String) {
        append(byte: asciiDoubleQuote)
        for c in value.unicodeScalars {
            switch c.value {
            // Special two-byte escapes
            case 8:
                append(staticText: "\\b")
            case 9:
                append(staticText: "\\t")
            case 10:
                append(staticText: "\\n")
            case 11:
                append(staticText: "\\v")
            case 12:
                append(staticText: "\\f")
            case 13:
                append(staticText: "\\r")
            case 34:
                append(staticText: "\\\"")
            case 92:
                append(staticText: "\\\\")
            case 0...31, 127: // Octal form for C0 control chars
                append(byte: asciiBackslash)
                append(byte: asciiZero + UInt8(c.value / 64))
                append(byte: asciiZero + UInt8(c.value / 8 % 8))
                append(byte: asciiZero + UInt8(c.value % 8))
            case 0...127:  // ASCII
                append(byte: UInt8(truncatingIfNeeded: c.value))
            case 0x80...0x7ff:
                append(byte: 0xc0 + UInt8(c.value / 64))
                append(byte: 0x80 + UInt8(c.value % 64))
            case 0x800...0xffff:
                append(byte: 0xe0 + UInt8(truncatingIfNeeded: c.value >> 12))
                append(byte: 0x80 + UInt8(truncatingIfNeeded: (c.value >> 6) & 0x3f))
                append(byte: 0x80 + UInt8(truncatingIfNeeded: c.value & 0x3f))
            default:
                append(byte: 0xf0 + UInt8(truncatingIfNeeded: c.value >> 18))
                append(byte: 0x80 + UInt8(truncatingIfNeeded: (c.value >> 12) & 0x3f))
                append(byte: 0x80 + UInt8(truncatingIfNeeded: (c.value >> 6) & 0x3f))
                append(byte: 0x80 + UInt8(truncatingIfNeeded: c.value & 0x3f))
            }
        }
        append(byte: asciiDoubleQuote)
    }

    mutating func putBytesValue(value: Data) {
        append(byte: asciiDoubleQuote)
        value.withUnsafeBytes { (body: UnsafeRawBufferPointer) in
            if let p = body.baseAddress, body.count > 0 {
                for i in 0..<body.count {
                    let c = p[i]
                    switch c {
                    // Special two-byte escapes
                    case 8:
                        append(staticText: "\\b")
                    case 9:
                        append(staticText: "\\t")
                    case 10:
                        append(staticText: "\\n")
                    case 11:
                        append(staticText: "\\v")
                    case 12:
                        append(staticText: "\\f")
                    case 13:
                        append(staticText: "\\r")
                    case 34:
                        append(staticText: "\\\"")
                    case 92:
                        append(staticText: "\\\\")
                    case 32...126:  // printable ASCII
                        append(byte: c)
                    default: // Octal form for non-printable chars
                        append(byte: asciiBackslash)
                        append(byte: asciiZero + UInt8(c / 64))
                        append(byte: asciiZero + UInt8(c / 8 % 8))
                        append(byte: asciiZero + UInt8(c % 8))
                    }
                }
            }
        }
        append(byte: asciiDoubleQuote)
    }
}

