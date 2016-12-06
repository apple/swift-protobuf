// ProtobufRuntime/Sources/Protobuf/ProtobufJSONDecoding.swift - JSON decoding
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
/// JSONToken represents a single lexical token in a JSON
/// stream.
///
// -----------------------------------------------------------------------------

import Foundation
import Swift

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

private func decodeBytes(_ s: String) -> Data? {
    var out = [UInt8]()
    let digits = s.utf8
    var n = 0
    var bits = 0
    for (i, digit) in digits.enumerated() {
        n <<= 6
        switch digit {
        case 65...90: n |= Int(digit - 65); bits += 6
        case 97...122: n |= Int(digit - 97 + 26); bits += 6
        case 48...57: n |= Int(digit - 48 + 52); bits += 6
        case 43: n |= 62; bits += 6
        case 47: n |= 63; bits += 6
        case 61: n |= 0
        default:
            return nil
        }
        if i % 4 == 3 {
            out.append(UInt8(truncatingBitPattern: n >> 16))
            if bits >= 16 {
                out.append(UInt8(truncatingBitPattern: n >> 8))
                if bits >= 24 {
                    out.append(UInt8(truncatingBitPattern: n))
                }
            }
            bits = 0
        }
    }
    if bits != 0 {
        return nil
    }
    return Data(bytes: out)
}

public enum JSONToken: Equatable {
    case colon
    case comma
    case beginObject
    case endObject
    case beginArray
    case endArray
    case null
    case boolean(Bool)
    case string(String)
    case number(String)
    
    public var asBoolean: Bool? {
        switch self {
        case .boolean(let b): return b
        default: return nil
        }
    }
    
    public var asBooleanMapKey: Bool? {
        switch self {
        case .string("true"): return true
        case .string("false"): return false
        default: return nil
        }
    }
    
    var asInt64: Int64? {
        let text: String
        switch self {
        case .string(let s): text = s
        case .number(let n): text = n
        default: return nil
        }
        if let normalized = normalizeIntString(text) {
            let numberString = String(normalized)
            if let n = Int64(numberString) {
                return n
            }
        }
        return nil
    }
    
    var asInt32: Int32? {
        let text: String
        switch self {
        case .string(let s): text = s
        case .number(let n): text = n
        default: return nil
        }
        if let normalized = normalizeIntString(text) {
            let numberString = String(normalized)
            if let n = Int32(numberString) {
                return n
            }
        }
        return nil
    }
    
    var asUInt64: UInt64? {
        let text: String
        switch self {
        case .string(let s): text = s
        case .number(let n): text = n
        default: return nil
        }
        if let normalized = normalizeIntString(text), normalized[0] != "-" {
            let numberString = String(normalized)
            if let n = UInt64(numberString) {
                return n
            }
        }
        return nil
    }
    
    var asUInt32: UInt32? {
        let text: String
        switch self {
        case .string(let s): text = s
        case .number(let n): text = n
        default: return nil
        }
        if let normalized = normalizeIntString(text), normalized[0] != "-" {
            let numberString = String(normalized)
            if let n = UInt32(numberString) {
                return n
            }
        }
        return nil
    }
    
    var asFloat: Float? {
        switch self {
        case .string(let s): return Float(s)
        case .number(let n): return Float(n)
        default: return nil
        }
    }
    
    var asDouble: Double? {
        switch self {
        case .string(let s): return Double(s)
        case .number(let n): return Double(n)
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

public func ==(lhs: JSONToken, rhs: JSONToken) -> Bool {
    switch (lhs, rhs) {
    case (.colon, .colon),
         (.comma, .comma),
         (.beginObject, .beginObject),
         (.endObject, .endObject),
         (.beginArray, .beginArray),
         (.endArray, .endArray),
         (.null, .null):
        return true
    case (.boolean(let a), .boolean(let b)):
        return a == b
    case (.string(let a), .string(let b)):
        return a == b
    case (.number(let a), .number(let b)):
        return a == b
    default:
        return false
    }
}
