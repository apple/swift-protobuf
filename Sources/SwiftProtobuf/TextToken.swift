// ProtobufRuntime/Sources/Protobuf/ProtobufTextDecoding.swift - Text format decoding
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
/// Test format decoding engine.
///
// -----------------------------------------------------------------------------

import Foundation
import Swift

private func fromHexDigit(_ c: UInt8) -> UInt8? {
    if c >= 48 && c <= 57 {
        return c - 48
    }
    switch c {
    case 65, 97: return 10
    case 66, 98: return 11
    case 67, 99: return 12
    case 68, 100: return 13
    case 69, 101: return 14
    case 70, 102: return 15
    default:
        return nil
    }
}


// Protobuf JSON allows integers (signed and unsigned) to be
// coded using floating-point exponential format, but does
// reject anything that actually has a fractional part.
// This code converts numbers like 4.294967e9 to a standard
// integer decimal string format 429496700 using only pure
// textual operations (adding/removing trailing zeros, removing
// decimal point character).  The result can be handed
// to IntMax(string:) or UIntMax(string:) as appropriate.
//
// Returns an array of Character (to make it easy for clients to
// check specific character values) or nil if the provided string
// cannot be normalized to a valid integer format.
//
// Here are some sample inputs and outputs to clarify what this function does:
//   = "0.1.2" => nil (extra period)
//   = "0x02" => nil (invalid 'x' character)
//   = "4.123" => nil (not an integer)
//   = "012" => nil (leading zero rejected)
//   = "0" => "0" (bare zero is okay)
//   = "400e-1" => "40" (adjust decimal point)
//   = "4.12e2" => "412" (adjust decimal point)
//   = "1.0000" => "1" (drop extraneous trailing zeros)
//
// Note: This does reject sequences that are "obviously" out
// of the range of a 64-bit integer, but that's just to avoid
// crazy cases like trying to build million-character string for
// "1e1000000".  The client code is responsible for real range
// checking.
//
private func normalizeIntString(_ s: String) -> [Character]? {
    var total = 0
    var digits = 0
    var fractionalDigits: Int?
    var hasLeadingZero = false
    var chars = s.characters.makeIterator()
    var number = [Character]()
    while let c = chars.next() {
        if hasLeadingZero { // Leading zero must be last character
            return nil
        }
        switch c {
        case "-":
            if total > 0 {
                return nil
            }
            number.append(c)
            total += 1
        case "0":
            if digits == 0 {
                hasLeadingZero = true
            }
            fallthrough
        case "1", "2", "3", "4", "5", "6", "7", "8", "9":
            if fractionalDigits != nil {
                fractionalDigits = fractionalDigits! + 1
            } else {
                digits += 1
            }
            number.append(c)
            total += 1
        case ".":
            if fractionalDigits != nil {
                return nil // Duplicate '.'
            }
            fractionalDigits = 0
            total += 1
        case "e", "E":
            var expString = ""
            var c2 = chars.next()
            if c2 == "+" || c2 == "-" {
                expString.append(c2!)
                c2 = chars.next()
            }
            if c2 == nil {
                return nil
            }
            while let expDigit = c2 {
                switch expDigit {
                case "0", "1", "2", "3", "4", "5", "6", "7", "8", "9":
                    expString.append(expDigit)
                default:
                    return nil
                }
                c2 = chars.next()
            }
            // Limit on exp here follows from:
            //   = 64-bit int has range less than 10 ^ 20,
            //     so a positive exponent can't result in
            //     more than 20 digits wihout overflow
            //   = Value must be integral, so a negative exponent
            //     can't be greater than number of digits
            // The limit here is deliberately sloppy, it is only intended
            // to avoid painful abuse cases (e.g., 1e1000000000 will be
            // quickly dropped without trying to build a an array
            // of a billion characters).
            if let exp = Int(expString), exp + digits < 20 && exp > -digits {
                // Fold fractional digits into exponent
                var adjustment = exp - (fractionalDigits ?? 0)
                fractionalDigits = 0
                // Adjust digit string to account for exponent
                while adjustment > 0 {
                    number.append("0")
                    adjustment -= 1
                }
                while adjustment < 0 {
                    if number.isEmpty || number[number.count - 1] != "0" {
                        return nil
                    }
                    number.remove(at: number.count - 1)
                    adjustment += 1
                }
            } else {
                // Error if exponent is malformed or out of range
                return nil
            }
        default:
            return nil
        }
    }
    if number.isEmpty {
        return nil
    }
    // Allow 7.000 and 1.23000e2 by trimming fractional zero digits
    if let f = fractionalDigits {
        var fractionalDigits = f
        while fractionalDigits > 0 && !number.isEmpty && number[number.count - 1] == "0" {
            number.remove(at: number.count - 1)
            fractionalDigits -= 1
        }
        if fractionalDigits > 0 {
            return nil
        }
    }
    return number
}

// Protobuf Text format uses C ASCII conventions for
// encoding byte sequences, including the use of octal
// and hexadecimal escapes.
private func decodeBytes(_ s: String) -> Data? {
    var out = [UInt8]()
    var bytes = s.utf8.makeIterator()
    while let byte = bytes.next() {
        switch byte {
        case 92: //  "\\"
            if let escaped = bytes.next() {
                switch escaped {
                case 48, 49, 50, 51, 52, 53, 54, 55: // '0'...'9'
                    // C standard allows 1, 2, or 3 octal digits.
                    let savedPosition = bytes
                    if let digit2 = bytes.next(), digit2 >= 48, digit2 <= 55 {
                        let innerSavedPosition = bytes
                        if let digit3 = bytes.next(), digit3 >= 48, digit3 <= 55 {
                            let n = (escaped - 48) * 64 + (digit2 - 48) * 8 + (digit3 - 48)
                            out.append(UInt8(n))
                        } else {
                            let n = (escaped - 48) * 8 + (digit2 - 48)
                            out.append(UInt8(n))
                            bytes = innerSavedPosition
                        }
                    } else {
                        let n = (escaped - 48)
                        out.append(UInt8(n))
                        bytes = savedPosition
                    }
                case 120: // 'x' hexadecimal escape
                    // C standard allows any number of digits after \x
                    // We ignore all but the last two
                    var n: UInt8 = 0
                    var count = 0
                    var savedPosition = bytes
                    while let byte = bytes.next(), let digit = fromHexDigit(byte) {
                        n &= 15
                        n = n * 16
                        n += digit
                        count += 1
                        savedPosition = bytes
                    }
                    bytes = savedPosition
                    if count > 0 {
                        out.append(n)
                    } else {
                        return nil // Hex escape must have at least 1 digit
                    }
                case 97: // \a
                    out.append(UInt8(7))
                case 98: // \b
                    out.append(UInt8(8))
                case 102: // \f
                    out.append(UInt8(12))
                case 110: // \n
                    out.append(UInt8(10))
                case 114: // \r
                    out.append(UInt8(13))
                case 116: // \t
                    out.append(UInt8(9))
                case 118: // \v
                    out.append(UInt8(11))
                case 39, 34, 63: // \'  \"  \?
                    out.append(escaped)
                default:
                    return nil // Unrecognized escape
                }
            } else {
                return nil // Input ends with backslash
            }
        default:
            out.append(byte)
        }
    }
    return Data(bytes: out)
}

private func decodeString(_ s: String) -> String? {
    return s
/*
    var result = ""
    while let c = charGenerator.next() {
        if c == terminator {
            return result
        }
        switch c {
        case "\\":
            if let escaped = charGenerator.next() {
                switch escaped {
                case "b": result.append(Character("\u{0008}"))
                case "t": result.append(Character("\u{0009}"))
                case "n": result.append(Character("\u{000a}"))
                case "f": result.append(Character("\u{000c}"))
                case "r": result.append(Character("\u{000d}"))
                case "\"": result.append(escaped)
                case "\\": result.append(escaped)
                case "/": result.append(escaped)
                case "u":
                    if let c1 = fromHexDigit(charGenerator.next()),
                        let c2 = fromHexDigit(charGenerator.next()),
                        let c3 = fromHexDigit(charGenerator.next()),
                        let c4 = fromHexDigit(charGenerator.next()) {
                        let scalar = ((c1 * 16 + c2) * 16 + c3) * 16 + c4
                        if let char = UnicodeScalar(scalar) {
                            result.append(String(char))
                        } else if scalar < 0xD800 || scalar >= 0xE000 {
                            // Invalid Unicode scalar
                            return nil
                        } else if scalar >= UInt32(0xDC00) {
                            // Low surrogate is invalid
                            return nil
                        } else {
                            // We have a high surrogate, must be followed by low
                            if let slash = charGenerator.next(), slash == "\\",
                                let u = charGenerator.next(), u == "u",
                                let c1 = fromHexDigit(charGenerator.next()),
                                let c2 = fromHexDigit(charGenerator.next()),
                                let c3 = fromHexDigit(charGenerator.next()),
                                let c4 = fromHexDigit(charGenerator.next()) {
                                let follower = ((c1 * 16 + c2) * 16 + c3) * 16 + c4
                                if follower >= UInt32(0xDC00) && follower < UInt32(0xE000) {
                                    let high = scalar - UInt32(0xD800)
                                    let low = follower - UInt32(0xDC00)
                                    let composed = UInt32(0x10000) + high << 10 + low
                                    if let char = UnicodeScalar(composed) {
                                        result.append(String(char))
                                    } else {
                                        // Composed value is not valid
                                        return nil
                                    }
                                } else {
                                    // high surrogate was not followed by low
                                    return nil
                                }
                            } else {
                                // high surrogate not followed by unicode hex escape
                                return nil
                            }
                        }
                    } else {
                        // Broken unicode escape
                        return nil
                    }
                default:
                    // Unrecognized backslash escape
                    return nil
                }
            } else {
                // Input ends in backslash
                return nil
            }
        default:
            result.append(c)
        }
    }
    // Unterminated quoted string
    return nil
}
*/
}


public enum TextToken: Equatable, FieldDecoder {
    case colon
    case comma
    case beginObject
    case endObject
    case beginArray
    case endArray
    case string(String)
    case identifier(String)
    case octalInteger(String)
    case hexadecimalInteger(String)
    case decimalInteger(String)
    case floatingPointLiteral(String)

    public var asBoolean: Bool? {
        switch self {
        case .identifier("true"): return true
        case .identifier("True"): return true
        case .identifier("t"): return true
        case .decimalInteger("1"): return true
        case .identifier("false"): return false
        case .identifier("False"): return false
        case .identifier("f"): return false
        case .decimalInteger("0"): return false
        default: return nil
        }
    }

    var isNumber: Bool {
        switch self {
        case .octalInteger(_), .hexadecimalInteger(_),
             .decimalInteger(_), .floatingPointLiteral(_):
            return true
        default:
            return false
        }
    }

    // The scanner only identifies tokens, it does not do detailed
    // validation.  Normally, such validation requires schema information
    // so gets handled when we process the tokens to set an actual
    // field.  When skipping tokens, we need a way to verify that the
    // token was actually valid, hence this hook:
    var isValid: Bool {
        // TODO: Implement this
        return true
    }

    var asInt64: Int64? {
        switch self {
        case .decimalInteger(let n):
            if let normalized = normalizeIntString(n) {
                let numberString = String(normalized)
                return Int64(numberString)
            }
        case .octalInteger(let n):
            return Int64(n, radix: 8)
        case .hexadecimalInteger(let n):
            var s = n
            if s.hasPrefix("0x") {
                s.remove(at: s.startIndex)
                s.remove(at: s.startIndex)
                return Int64(s, radix: 16)
            } else if s.hasPrefix("-0x") {
                s.remove(at: s.startIndex)
                s.remove(at: s.startIndex)
                s.remove(at: s.startIndex)
                return Int64("-" + s, radix: 16)
            }
        default: return nil
        }
        return nil
    }

    var asInt32: Int32? {
        switch self {
        case .decimalInteger(let n):
            if let normalized = normalizeIntString(n) {
                let numberString = String(normalized)
                return Int32(numberString)
            }
        case .octalInteger(let n):
            return Int32(n, radix: 8)
        case .hexadecimalInteger(let n):
            var s = n
            if s.hasPrefix("0x") {
                s.remove(at: s.startIndex)
                s.remove(at: s.startIndex)
                return Int32(s, radix: 16)
            } else if s.hasPrefix("-0x") {
                s.remove(at: s.startIndex)
                s.remove(at: s.startIndex)
                s.remove(at: s.startIndex)
                return Int32("-" + s, radix: 16)
            }
        default:
            return nil
        }
        return nil
    }

    var asUInt64: UInt64? {
        switch self {
        case .decimalInteger(let n):
            if let normalized = normalizeIntString(n), normalized[0] != "-" {
                let numberString = String(normalized)
                return UInt64(numberString)
            }
        case .octalInteger(let n):
            return UInt64(n, radix: 8)
        case .hexadecimalInteger(let n):
            var s = n
            if s.hasPrefix("0x") {
                s.remove(at: s.startIndex)
                s.remove(at: s.startIndex)
                return UInt64(s, radix: 16)
            }
        default: return nil
        }
        return nil
    }

    var asUInt32: UInt32? {
        switch self {
        case .decimalInteger(let n):
            if let normalized = normalizeIntString(n), normalized[0] != "-" {
                let numberString = String(normalized)
                return UInt32(numberString)
            }
        case .octalInteger(let n):
            return UInt32(n, radix: 8)
        case .hexadecimalInteger(let n):
            var s = n
            if s.hasPrefix("0x") {
                s.remove(at: s.startIndex)
                s.remove(at: s.startIndex)
                return UInt32(s, radix: 16)
            }
        default: return nil
        }
        return nil
    }

    var asFloat: Float? {
        switch self {
        case .identifier("inf"): return Float.infinity
        case .identifier("nan"): return Float.nan
        case .identifier("-inf"): return -Float.infinity
        case .decimalInteger(let n): return Float(n)
        case .floatingPointLiteral(let n): return Float(n)
        default: return nil
        }
    }

    var asDouble: Double? {
        switch self {
        case .identifier("inf"): return Double.infinity
        case .identifier("nan"): return Double.nan
        case .identifier("-inf"): return -Double.infinity
        case .decimalInteger(let n): return Double(n)
        case .floatingPointLiteral(let n): return Double(n)
        default: return nil
        }
    }

    var asString: String? {
        switch self {
        case .string(let s): return decodeString(s)
        default: return nil
        }
    }

    var asBytes: Data? {
        switch self {
        case .string(let s): return decodeBytes(s)
        default: return nil
        }
    }
}

public func ==(lhs: TextToken, rhs: TextToken) -> Bool {
    switch (lhs, rhs) {
    case (.colon, .colon),
         (.comma, .comma),
         (.beginObject, .beginObject),
         (.endObject, .endObject),
         (.beginArray, .beginArray),
         (.endArray, .endArray):
        return true
    case (.string(let a), .string(let b)):
        return a == b
    case (.identifier(let a), .identifier(let b)):
        return a == b
    case (.octalInteger(let a), .octalInteger(let b)):
        return a == b
    case (.decimalInteger(let a), .decimalInteger(let b)):
        return a == b
    case (.hexadecimalInteger(let a), .hexadecimalInteger(let b)):
        return a == b
    case (.floatingPointLiteral(let a), .floatingPointLiteral(let b)):
        return a == b
    default:
        return false
    }
}
