// Sources/SwiftProtobuf/JSONScanner.swift - JSON format decoding
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// JSON format decoding engine.
///
// -----------------------------------------------------------------------------

import Foundation
import Swift

private let asciiBell = UInt8(7)
private let asciiBackspace = UInt8(8)
private let asciiTab = UInt8(9)
private let asciiNewLine = UInt8(10)
private let asciiVerticalTab = UInt8(11)
private let asciiFormFeed = UInt8(12)
private let asciiCarriageReturn = UInt8(13)
private let asciiZero = UInt8(ascii: "0")
private let asciiOne = UInt8(ascii: "1")
private let asciiSeven = UInt8(ascii: "7")
private let asciiNine = UInt8(ascii: "9")
private let asciiColon = UInt8(ascii: ":")
private let asciiPeriod = UInt8(ascii: ".")
private let asciiPlus = UInt8(ascii: "+")
private let asciiComma = UInt8(ascii: ",")
private let asciiSemicolon = UInt8(ascii: ";")
private let asciiDoubleQuote = UInt8(ascii: "\"")
private let asciiSingleQuote = UInt8(ascii: "\'")
private let asciiBackslash = UInt8(ascii: "\\")
private let asciiForwardSlash = UInt8(ascii: "/")
private let asciiHash = UInt8(ascii: "#")
private let asciiUnderscore = UInt8(ascii: "_")
private let asciiQuestionMark = UInt8(ascii: "?")
private let asciiSpace = UInt8(ascii: " ")
private let asciiOpenSquareBracket = UInt8(ascii: "[")
private let asciiCloseSquareBracket = UInt8(ascii: "]")
private let asciiOpenCurlyBracket = UInt8(ascii: "{")
private let asciiCloseCurlyBracket = UInt8(ascii: "}")
private let asciiOpenAngleBracket = UInt8(ascii: "<")
private let asciiCloseAngleBracket = UInt8(ascii: ">")
private let asciiMinus = UInt8(ascii: "-")
private let asciiLowerA = UInt8(ascii: "a")
private let asciiUpperA = UInt8(ascii: "A")
private let asciiLowerB = UInt8(ascii: "b")
private let asciiLowerE = UInt8(ascii: "e")
private let asciiLowerF = UInt8(ascii: "f")
private let asciiUpperI = UInt8(ascii: "I")
private let asciiLowerL = UInt8(ascii: "l")
private let asciiLowerN = UInt8(ascii: "n")
private let asciiUpperN = UInt8(ascii: "N")
private let asciiLowerR = UInt8(ascii: "r")
private let asciiLowerS = UInt8(ascii: "s")
private let asciiLowerT = UInt8(ascii: "t")
private let asciiLowerU = UInt8(ascii: "u")
private let asciiLowerZ = UInt8(ascii: "z")
private let asciiUpperZ = UInt8(ascii: "Z")

private func fromHexDigit(_ c: UnicodeScalar) -> UInt32? {
  let n = c.value
  if n >= 48 && n <= 57 {
    return n - 48
  }
  switch n {
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

/// Returns a `Data` value containing bytes equivalent to the given
/// Base64-encoded string, or nil if the conversion fails.
private func decodeBytes(base64String s: String) -> Data? {
  var out = [UInt8]()
  let digits = s.utf8
  var n = 0
  var bits = 0
  for (i, digit) in digits.enumerated() {
    n <<= 6
    switch digit {
    case asciiUpperA...asciiUpperZ: n |= Int(digit - asciiUpperA); bits += 6
    case asciiLowerA...asciiLowerZ: n |= Int(digit - asciiLowerA + 26); bits += 6
    case asciiZero...asciiNine: n |= Int(digit - asciiZero + 52); bits += 6
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

// JSON encoding allows a variety of \-escapes, including
// escaping UTF-16 code points (which may be surrogate pairs).
private func decodeString(_ s: String) -> String? {
    var out = String.UnicodeScalarView()
    var chars = s.unicodeScalars.makeIterator()
    while let c = chars.next() {
        switch c.value {
        case UInt32(asciiBackslash): // backslash
            if let escaped = chars.next() {
                switch escaped.value {
                case UInt32(asciiLowerU): // "\u"
                    // Exactly 4 hex digits:
                    if let digit1 = chars.next(),
                       let d1 = fromHexDigit(digit1),
                       let digit2 = chars.next(),
                       let d2 = fromHexDigit(digit2),
                       let digit3 = chars.next(),
                       let d3 = fromHexDigit(digit3),
                       let digit4 = chars.next(),
                       let d4 = fromHexDigit(digit4) {
                        let codePoint = ((d1 * 16 + d2) * 16 + d3) * 16 + d4
                        if let scalar = UnicodeScalar(codePoint) {
                            out.append(scalar)
                        } else if codePoint < 0xD800 || codePoint >= 0xE000 {
                            // Not a valid Unicode scalar.
                            return nil
                        } else if codePoint >= 0xDC00 {
                            // Low surrogate without a preceding high surrogate.
                            return nil
                        } else {
                            // We have a high surrogate (in the range 0xD800..<0xDC00), so verify that
                            // it is followed by a low surrogate.
                            guard chars.next() == "\\", chars.next() == "u" else {
                                // High surrogate was not followed by a Unicode escape sequence.
                                return nil
                            }
                            if let digit1 = chars.next(),
                               let d1 = fromHexDigit(digit1),
                               let digit2 = chars.next(),
                               let d2 = fromHexDigit(digit2),
                               let digit3 = chars.next(),
                               let d3 = fromHexDigit(digit3),
                               let digit4 = chars.next(),
                               let d4 = fromHexDigit(digit4) {
                                let follower = ((d1 * 16 + d2) * 16 + d3) * 16 + d4
                                guard 0xDC00 <= follower && follower < 0xE000 else {
                                    // High surrogate was not followed by a low surrogate.
                                    return nil
                                }
                                let high = codePoint - 0xD800
                                let low = follower - 0xDC00
                                let composed = 0x10000 | high << 10 | low
                                guard let composedScalar = UnicodeScalar(composed) else {
                                    // Composed value is not a valid Unicode scalar.
                                    return nil
                                }
                                out.append(composedScalar)
                            } else {
                                // Malformed \u escape for low surrogate
                                return nil
                            }
                        }
                    } else {
                        // Malformed \u escape
                        return nil
                    }
                case UInt32(asciiLowerB): // \b
                    out.append("\u{08}")
                case UInt32(asciiLowerF): // \f
                    out.append("\u{0c}")
                case UInt32(asciiLowerN): // \n
                    out.append("\u{0a}")
                case UInt32(asciiLowerR): // \r
                    out.append("\u{0d}")
                case UInt32(asciiLowerT): // \t
                    out.append("\u{09}")
                case UInt32(asciiDoubleQuote), UInt32(asciiBackslash), UInt32(asciiForwardSlash): // " \ /
                    out.append(escaped)
                default:
                    return nil // Unrecognized escape
                }
            } else {
                return nil // Input ends with backslash
            }
        default:
            out.append(c)
        }
    }
    return String(out)
}

// Parse the leading UInt64 from the provided utf8.
//
// This usually does a direct conversion of utf8 to UInt64.  It is
// called for both unquoted numbers and for numbers stored in quoted
// strings.  In the latter case, the caller is responsible for
// consuming the leading quote and verifying the trailing quote.
//
// If the number is in floating-point format, this uses a slower
// and less accurate approach identifies a substring comprising
// a float, and then uses Double() and UInt64() to convert that
// string to an unsigned intger.
//
// If it encounters a "\" backslash character, it returns a nil.  This
// is used by callers that are parsing quoted numbers.  See nextSInt()
// and nextUInt() below.
private func parseBareUInt(utf8: String.UTF8View, index: inout String.UTF8View.Index) throws -> UInt64? {
    let start = index
    let c = utf8[index]
    index = utf8.index(after: index)
    switch c {
    case asciiZero: // 0
        if index != utf8.endIndex {
            let after = utf8[index]
            switch after {
            case asciiZero...asciiNine: // 0...9
                // leading '0' forbidden unless it is the only digit
                throw DecodingError.malformedJSONNumber
            case asciiPeriod, asciiLowerE: // . e
                // Slow path: JSON numbers can be written in floating-point notation
                index = start
                if let s = try parseBareFloatString(utf8: utf8, index: &index) {
                    if let d = Double(s) {
                        if let u = UInt64(safely: d) {
                            return u
                        }
                    }
                }
                throw DecodingError.malformedJSONNumber
            case asciiBackslash:
                return nil
            default:
                return 0
            }
        }
        return 0
    case asciiOne...asciiNine: // 1...9
        var n = UInt64(c - 48)
        while index != utf8.endIndex {
            let digit = utf8[index]
            switch digit {
            case asciiZero...asciiNine: // 0...9
                let val = UInt64(digit - asciiZero)
                if n >= UInt64.max / 10 {
                    if n > UInt64.max / 10 || val > UInt64.max % 10 {
                        throw DecodingError.malformedJSONNumber
                    }
                }
                index = utf8.index(after: index)
                n = n * 10 + val
            case asciiPeriod, asciiLowerE: // . e
                // Slow path: JSON allows floating-point notation for integers
                index = start
                if let s = try parseBareFloatString(utf8: utf8, index: &index) {
                    if let d = Double(s) {
                        if let u = UInt64(safely: d) {
                            return u
                        }
                    }
                }
                throw DecodingError.malformedJSONNumber
            case asciiBackslash:
                return nil
            default:
                return n
            }
        }
        return n
    case asciiBackslash:
        return nil
    default:
        throw DecodingError.malformedJSONNumber
    }
}

// Parse the leading Int64 from the provided utf8.
//
// This uses parseBareUInt() to do the heavy lifting;
// we just check for a leading minus and negate the result
// as necessary.
//
// As with parseBareUInt(), if it encounters a "\" backslash
// character, it returns a nil.  This is used by callers that are
// parsing quoted numbers.  See nextSInt() and nextUInt() below.

private func parseBareSInt(utf8: String.UTF8View, index: inout String.UTF8View.Index) throws -> Int64? {
    if index == utf8.endIndex {
        throw DecodingError.malformedJSONNumber
    }
    let c = utf8[index]
    if c == asciiMinus { // -
        index = utf8.index(after: index)
        // character after '-' must be digit
        let digit = utf8[index]
        if digit < asciiZero || digit > asciiNine {
            throw DecodingError.malformedJSONNumber
        }
        if let n = try parseBareUInt(utf8: utf8, index: &index) {
            if n >= 0x8000000000000000 { // -Int64.min
                if n > 0x8000000000000000 {
                    // Too large negative number
                    throw DecodingError.malformedJSONNumber
                } else {
                    return Int64.min // Special case for Int64.min
                }
            }
            return -Int64(bitPattern: n)
        } else {
            return nil
        }
    } else if let n = try parseBareUInt(utf8: utf8, index: &index) {
        if n > UInt64(bitPattern: Int64.max) {
            throw DecodingError.malformedJSONNumber
        }
        return Int64(bitPattern: n)
    } else {
        return nil
    }
}

// Identify a floating-point value in the upcoming UTF8 bytes.
//
// This implements the full grammar defined by the JSON RFC 7159.
// Note that Swift's string-to-number conversions are much more
// lenient, so this is necessary if we want to accurately reject
// malformed JSON numbers.
//
// This is used by nextDouble() and nextFloat() to parse double and
// floating-point values, including values that happen to be in quotes.
// It's also used by the slow path in parseBareSInt() and parseBareUInt()
// above to handle integer values that are written in float-point notation.
private func parseBareFloatString(utf8: String.UTF8View, index: inout String.UTF8View.Index) throws -> String? {
    // RFC 7159 defines the grammar for JSON numbers as:
    // number = [ minus ] int [ frac ] [ exp ]
    let start = index
    var c = utf8[index]
    if c == asciiBackslash {
        return nil
    }

    // Optional leading minus sign
    if c == asciiMinus { // -
        index = utf8.index(after: index)
        if index == utf8.endIndex {
            index = start
            throw DecodingError.malformedJSONNumber
        }
        c = utf8[index]
        if c == asciiBackslash {
            return nil
        }
    } else if c == asciiUpperN { // Maybe NaN?
        // Return nil, let the caller deal with it.
        return nil
    }

    if c == asciiUpperI { // Maybe Infinity, Inf, -Infinity, or -Inf ?
        // Return nil, let the caller deal with it.
        return nil
    }

    // Integer part can be zero or a series of digits not starting with zero
    // int = zero / (digit1-9 *DIGIT)
    switch c {
    case asciiZero:
        // First digit can be zero only if not followed by a digit
        index = utf8.index(after: index)
        if index == utf8.endIndex {
            return String(utf8[start..<index])!
        }
        c = utf8[index]
        if c == asciiBackslash {
            return nil
        }
        if c >= asciiZero && c <= asciiNine {
            throw DecodingError.malformedJSONNumber
        }
    case asciiOne...asciiNine:
        while c >= asciiZero && c <= asciiNine {
            index = utf8.index(after: index)
            if index == utf8.endIndex {
                return String(utf8[start..<index])!
            }
            c = utf8[index]
            if c == asciiBackslash {
                return nil
            }
        }
    default:
        // Integer part cannot be empty
        throw DecodingError.malformedJSONNumber
    }

    // frac = decimal-point 1*DIGIT
    if c == asciiPeriod {
        index = utf8.index(after: index)
        if index == utf8.endIndex {
            throw DecodingError.malformedJSONNumber // decimal point must have a following digit
        }
        c = utf8[index]
        switch c {
        case asciiZero...asciiNine: // 0...9
            while c >= asciiZero && c <= asciiNine {
                index = utf8.index(after: index)
                if index == utf8.endIndex {
                    return String(utf8[start..<index])!
                }
                c = utf8[index]
                if c == asciiBackslash {
                    return nil
                }
            }
        case asciiBackslash:
            return nil
        default:
            throw DecodingError.malformedJSONNumber // decimal point must be followed by at least one digit
        }
    }

    // exp = e [ minus / plus ] 1*DIGIT
    if c == asciiLowerE {
        index = utf8.index(after: index)
        if index == utf8.endIndex {
            throw DecodingError.malformedJSONNumber // "e" must be followed by + or -
        }
        c = utf8[index]
        if c == asciiBackslash {
            return nil
        }
        if c == asciiPlus || c == asciiMinus { // + -
            index = utf8.index(after: index)
            if index == utf8.endIndex {
                throw DecodingError.malformedJSONNumber // must be at least one digit in exponent
            }
            c = utf8[index]
            if c == asciiBackslash {
                return nil
            }
        }
        switch c {
        case asciiZero...asciiNine:
            while c >= asciiZero && c <= asciiNine {
                index = utf8.index(after: index)
                if index == utf8.endIndex {
                    return String(utf8[start..<index])!
                }
                c = utf8[index]
                if c == asciiBackslash {
                    return nil
                }
            }
        default:
            throw DecodingError.malformedJSONNumber // must be at least one digit in exponent
        }
    }
    return String(utf8[start..<index])!
}

///
/// The basic scanner support is entirely private
///
internal struct JSONScanner {
    private var utf8: String.UTF8View
    private var index: String.UTF8View.Index
    private var eof: Bool = false

    internal var complete: Bool {
        mutating get {
            skipWhitespace()
            return index == utf8.endIndex
        }
    }

    internal init(json: String) {
        utf8 = json.utf8
        index = utf8.startIndex
    }

    /// Skip whitespace
    private mutating func skipWhitespace() {
        while index != utf8.endIndex {
            let u = utf8[index]
            switch u {
            case asciiSpace, asciiTab, asciiNewLine, asciiCarriageReturn: // space, tab, NL, CR
                index = utf8.index(after: index)
            default:
                return
            }
        }
    }

    internal mutating func peekOneCharacter() throws -> Character {
        skipWhitespace()
        if index == utf8.endIndex {
            throw DecodingError.truncatedInput
        }
        return Character(UnicodeScalar(UInt32(utf8[index]))!)
    }

    /// Assumes the leading quote has been verified (but not consumed)
    private mutating func parseOptionalQuotedString() -> String? {
        // Caller has already asserted that utf8[index] == quote here
        var sawBackslash = false
        index = utf8.index(after: index)
        let start = index
        while index != utf8.endIndex {
            let c = utf8[index]
            if c == asciiDoubleQuote { // "
                let s = String(utf8[start..<index])
                index = utf8.index(after: index)
                if let t = s {
                    if sawBackslash {
                        return decodeString(t)
                    } else {
                        return t
                    }
                } else {
                    return nil // Invalid UTF8
                }
            }
            if c == asciiBackslash { //  \
                index = utf8.index(after: index)
                if index == utf8.endIndex {
                    return nil // Unterminated escape
                }
                sawBackslash = true
            }
            index = utf8.index(after: index)
        }
        return nil // Unterminated quoted string
    }

    // Parse an unsigned integer, whether or not its quoted.
    //
    // This supports the full range of UInt64 (whether quoted or not)
    // unless the number is written in floating-point format.  In that
    // case, we decode it with only Double precision.
    internal mutating func nextUInt() throws -> UInt64 {
        skipWhitespace()
        if index == utf8.endIndex {
            throw DecodingError.malformedJSONNumber
        }
        let c = utf8[index]
        if c == asciiDoubleQuote {
            let start = index
            index = utf8.index(after: index)
            if let u = try parseBareUInt(utf8: utf8, index: &index) {
               if index == utf8.endIndex {
                   throw DecodingError.truncatedInput
               }
               if utf8[index] != asciiDoubleQuote {
                   throw DecodingError.malformedJSON
               }
               index = utf8.index(after: index)
               return u
            } else {
                // Couldn't parse because it had a "\" in the string,
                // so parse out the quoted string and then reparse
                // the result as an UInt
                index = start
                let s = try nextQuotedString()
                let subUtf8 = s.utf8
                var subIndex = subUtf8.startIndex
                if let u = try parseBareUInt(utf8: subUtf8, index: &subIndex) {
                    if subIndex == subUtf8.endIndex {
                        return u
                    }
                }
            }
        } else if let u = try parseBareUInt(utf8: utf8, index: &index) {
            return u
        }
        throw DecodingError.malformedJSON
    }


    // Parse a signed integer, quoted or not.
    //
    // This supports the full range of Int64 (whether quoted or not)
    // unless the number is written in floating-point format.  In that
    // case, we decode it with only Double precision.
    internal mutating func nextSInt() throws -> Int64 {
        skipWhitespace()
        if index == utf8.endIndex {
            throw DecodingError.malformedJSONNumber
        }
        let c = utf8[index]
        if c == asciiDoubleQuote {
            let start = index
            index = utf8.index(after: index)
            if let s = try parseBareSInt(utf8: utf8, index: &index) {
                if index == utf8.endIndex {
                    throw DecodingError.truncatedInput
                }
                if utf8[index] != asciiDoubleQuote {
                    throw DecodingError.malformedJSON
                }
                index = utf8.index(after: index)
                return s
            } else {
                // Couldn't parse because it had a "\" in the string,
                // so parse out the quoted string and then reparse
                // the result as an SInt
                index = start
                let s = try nextQuotedString()
                let subUtf8 = s.utf8
                var subIndex = subUtf8.startIndex
                if let s = try parseBareSInt(utf8: subUtf8, index: &subIndex) {
                    if subIndex == subUtf8.endIndex {
                        return s
                    }
                }
            }
        } else if let s = try parseBareSInt(utf8: utf8, index: &index) {
            return s
        }
        throw DecodingError.malformedJSON
    }

    internal mutating func nextFloat() throws -> Float {
        skipWhitespace()
        if index == utf8.endIndex {
            throw DecodingError.malformedJSONNumber
        }
        let c = utf8[index]
        if c == asciiDoubleQuote { // "
            let start = index
            index = utf8.index(after: index)
            if let s = try parseBareFloatString(utf8: utf8, index: &index) {
                if index == utf8.endIndex {
                    throw DecodingError.truncatedInput
                }
                if utf8[index] != asciiDoubleQuote {
                    throw DecodingError.malformedJSON
                }
                index = utf8.index(after: index)
                if let f = Float(s) {
                    return f
                }
            } else {
                // Slow Path: parseBareFloatString returned nil: It might be
                // a valid float, but had something that
                // parseBareFloatString cannot directly handle.  So we reset,
                // try a full string parse, then examine the result:
                index = start
                let s = try nextQuotedString()
                switch s {
                case "NaN": return Float.nan
                case "Inf": return Float.infinity
                case "-Inf": return -Float.infinity
                case "Infinity": return Float.infinity
                case "-Infinity": return -Float.infinity
                default:
                    let subUtf8 = s.utf8
                    var subIndex = subUtf8.startIndex
                    if let s = try parseBareFloatString(utf8: subUtf8, index: &subIndex) {
                        if let f = Float(s), subIndex == subUtf8.endIndex {
                            return f
                        }
                    }
                }
            }
        } else {
            if let s = try parseBareFloatString(utf8: utf8, index: &index), let n = Float(s) {
                return n
            }
        }
        throw DecodingError.malformedJSONNumber
    }

    internal mutating func nextDouble() throws -> Double {
        skipWhitespace()
        if index == utf8.endIndex {
            throw DecodingError.malformedJSONNumber
        }
        let c = utf8[index]
        if c == asciiDoubleQuote { // "
            let start = index
            index = utf8.index(after: index)
            if let s = try parseBareFloatString(utf8: utf8, index: &index) {
                if index == utf8.endIndex {
                    throw DecodingError.truncatedInput
                }
                if utf8[index] != asciiDoubleQuote {
                    throw DecodingError.malformedJSON
                }
                index = utf8.index(after: index)
                if let f = Double(s) {
                    return f
                }
            } else {
                // Slow Path: parseBareFloatString returned nil: It might be
                // a valid float, but had something that
                // parseBareFloatString cannot directly handle.  So we reset,
                // try a full string parse, then examine the result:
                index = start
                let s = try nextQuotedString()
                switch s {
                case "NaN": return Double.nan
                case "Inf": return Double.infinity
                case "-Inf": return -Double.infinity
                case "Infinity": return Double.infinity
                case "-Infinity": return -Double.infinity
                default:
                    let subUtf8 = s.utf8
                    var subIndex = subUtf8.startIndex
                    if let s = try parseBareFloatString(utf8: subUtf8, index: &subIndex) {
                        if let f = Double(s), subIndex == subUtf8.endIndex {
                            return f
                        }
                    }
                }
            }
        } else {
            if let s = try parseBareFloatString(utf8: utf8, index: &index), let n = Double(s) {
                return n
            }
        }
        throw DecodingError.malformedJSONNumber
    }

    internal mutating func nextQuotedString() throws -> String {
        skipWhitespace()
        if index == utf8.endIndex {
            throw DecodingError.malformedJSON
        }
        let c = utf8[index]
        if c != asciiDoubleQuote {
            throw DecodingError.malformedJSON
        }
        if let s = parseOptionalQuotedString() {
            return s
        } else {
            throw DecodingError.malformedJSON
        }
    }

    internal mutating func nextOptionalQuotedString() throws -> String? {
        skipWhitespace()
        if index == utf8.endIndex {
            return nil
        }
        let c = utf8[index]
        if c != asciiDoubleQuote {
            return nil
        }
        return try nextQuotedString()
    }

    internal mutating func nextBytesValue() throws -> Data {
        skipWhitespace()
        if index == utf8.endIndex {
            throw DecodingError.malformedJSON
        }
        let c = utf8[index]
        if c != asciiDoubleQuote {
            throw DecodingError.malformedJSON
        }
        if let s = parseOptionalQuotedString(), let b = decodeBytes(base64String: s) {
            return b
        } else {
            throw DecodingError.malformedJSON
        }
    }

    private mutating func skipOptionalKeyword(bytes: [UInt8]) -> Bool {
        let start = index
        for b in bytes {
            if index == utf8.endIndex {
                index = start
                return false
            }
            let c = utf8[index]
            if c != b {
                index = start
                return false
            }
            index = utf8.index(after: index)
        }
        if index != utf8.endIndex {
            let c = utf8[index]
            if (c >= asciiUpperA && c <= asciiUpperZ) || (c >= asciiLowerA && c <= asciiLowerZ) {
                index = start
                return false
            }
        }
        return true
    }

    // If the next token is the identifier "null", return true.
    internal mutating func skipOptionalNull() -> Bool {
        skipWhitespace()
        if index != utf8.endIndex && utf8[index] == asciiLowerN {
            return skipOptionalKeyword(bytes: [asciiLowerN, asciiLowerU, asciiLowerL, asciiLowerL])
        }
        return false
    }

    internal mutating func nextBool() throws -> Bool {
        skipWhitespace()
        if index == utf8.endIndex {
            throw DecodingError.malformedJSON
        }
        let c = utf8[index]
        switch c {
        case asciiDoubleQuote: // "
            if let s = parseOptionalQuotedString() {
                switch s {
                case "false": return false
                case "true": return true
                default: break
                }
            }
        case asciiLowerF: // f
            if skipOptionalKeyword(bytes: [asciiLowerF, asciiLowerA, asciiLowerL, asciiLowerS, asciiLowerE]) {
                return false
            }
        case asciiLowerT: // t
            if skipOptionalKeyword(bytes: [asciiLowerT, asciiLowerR, asciiLowerU, asciiLowerE]) {
                return true
            }
        default:
            break
        }
        throw DecodingError.malformedJSON
    }

    /// Returns text of next regular key or nil if end-of-input.
    /// Skips required : as well.
    ///
    /// This is only used by map parsing.
    internal mutating func nextKey() throws -> String {
        skipWhitespace()
        if index == utf8.endIndex {
            throw DecodingError.truncatedInput
        }
        let s = try nextQuotedString()
        try skipRequiredCharacter(asciiColon) // :
        return s
    }

    /// Parse a field name, look it up, and return the corresponding
    /// field number.
    ///
    /// Throws if field name cannot be parsed or if field name is
    /// unknown.
    ///
    /// This function accounts for as much as 2/3 of the total run
    /// time of the entire parse.  The bulk of that time is creating
    /// the String object which we then look up and immediately discard.
    /// Techniques that look up the field number without creating a
    /// temporary string object could have big benefits.
    internal mutating func nextFieldNumber(names: FieldNameMap) throws -> Int? {
        while true {
            skipWhitespace()
            if index == utf8.endIndex {
                throw DecodingError.truncatedInput
            }
            let key = try nextQuotedString()
            try skipRequiredCharacter(asciiColon) // :
            if let fieldNumber = names.fieldNumber(forJSONName: key) {
                return fieldNumber
            } else {
                try skipValue()
                if skipOptionalObjectEnd() {
                    return nil
                }
                try skipRequiredComma()
            }
        }
    }

    private mutating func skipRequiredCharacter(_ required: UInt8) throws {
        skipWhitespace()
        if index != utf8.endIndex {
            let next = utf8[index]
            if next == required {
                index = utf8.index(after: index)
                return
            }
        }
        throw DecodingError.malformedJSON
    }

    internal mutating func skipRequiredObjectStart() throws {
        try skipRequiredCharacter(asciiOpenCurlyBracket) // {
    }

    internal mutating func skipRequiredComma() throws {
        try skipRequiredCharacter(asciiComma)
    }

    internal mutating func skipRequiredColon() throws {
        try skipRequiredCharacter(asciiColon)
    }

    internal mutating func skipRequiredArrayStart() throws {
        try skipRequiredCharacter(asciiOpenSquareBracket) // [
    }

    private mutating func skipOptionalCharacter(_ c: UInt8) -> Bool {
        skipWhitespace()
        if index != utf8.endIndex && utf8[index] == c {
            index = utf8.index(after: index)
            return true
        }
        return false
    }

    internal mutating func skipOptionalArrayEnd() -> Bool {
        return skipOptionalCharacter(asciiCloseSquareBracket) // ]
    }

    internal mutating func skipOptionalObjectEnd() -> Bool {
        return skipOptionalCharacter(asciiCloseCurlyBracket) // }
    }

    /// Used by Any to get the upcoming JSON value as a string.
    /// Note: The value might be an object or array.
    internal mutating func skip() throws -> String {
        skipWhitespace()
        let start = index
        try skipValue()
        if let s = String(utf8[start..<index]) {
            return s
        } else {
            throw DecodingError.malformedJSON
        }
    }

    /// Advance index past the next value.  This is used
    /// by skip() and by unknown field handling.
    private mutating func skipValue() throws {
        skipWhitespace()
        if index == utf8.endIndex {
            throw DecodingError.truncatedInput
        }
        switch utf8[index] {
        case asciiDoubleQuote: // " begins a string
            try skipString()
        case asciiOpenCurlyBracket: // { begins an object
            try skipObject()
        case asciiOpenSquareBracket: // [ begins an array
            try skipArray()
        case asciiLowerN: // n must be null
            if !skipOptionalKeyword(bytes: [asciiLowerN, asciiLowerU, asciiLowerL, asciiLowerL]) {
                throw DecodingError.truncatedInput
            }
        case asciiLowerF: // f must be false
            if !skipOptionalKeyword(bytes: [asciiLowerF, asciiLowerA, asciiLowerL, asciiLowerS, asciiLowerE]) {
                throw DecodingError.truncatedInput
            }
        case asciiLowerT: // t must be true
            if !skipOptionalKeyword(bytes: [asciiLowerT, asciiLowerR, asciiLowerU, asciiLowerE]) {
                throw DecodingError.truncatedInput
            }
        default: // everything else is a number token
            _ = try nextDouble()
        }
    }

    private mutating func skipObject() throws {
        try skipRequiredObjectStart()
        if skipOptionalObjectEnd() {
            return
        }
        while true {
            try skipString()
            try skipRequiredColon()
            try skipValue()
            if skipOptionalObjectEnd() {
                return
            }
            try skipRequiredComma()
        }
    }

    private mutating func skipArray() throws {
        try skipRequiredArrayStart()
        if skipOptionalArrayEnd() {
            return
        }
        while true {
            try skipValue()
            if skipOptionalArrayEnd() {
                return
            }
            try skipRequiredComma()
        }
    }

    // Caveat:  This doesn't actually validate; it will accept
    // strings that have malformed \ escapes.
    //
    // It would be nice to do better, but I don't think it's critical,
    // since there are many reasons that strings (and other tokens for
    // that matter) may be skippable but not parseable.  For example,
    // Old clients that don't know new field types will skip fields
    // they don't know; newer clients may reject the same input due to
    // schema mismatches or other issues.
    private mutating func skipString() throws {
        if utf8[index] != asciiDoubleQuote {
            throw DecodingError.malformedJSON
        }
        index = utf8.index(after: index)
        while index != utf8.endIndex {
            let c = utf8[index]
            switch c {
            case asciiDoubleQuote:
                index = utf8.index(after: index)
                return
            case asciiBackslash:
                index = utf8.index(after: index)
                if index == utf8.endIndex {
                    throw DecodingError.truncatedInput
                }
                index = utf8.index(after: index)
            default:
                index = utf8.index(after: index)
            }
        }
        throw DecodingError.truncatedInput
    }
}
