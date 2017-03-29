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

///
/// The basic scanner support is entirely private
///
/// For performance, it works directly against UTF-8 bytes in memory.
///
internal struct JSONScanner {
    private var p: UnsafePointer<UInt8>
    private var end: UnsafePointer<UInt8>
    private var doubleFormatter = DoubleFormatter()

    internal var complete: Bool {
        mutating get {
            skipWhitespace()
            return p == end
        }
    }

    internal init(utf8Pointer: UnsafePointer<UInt8>, count: Int) {
        p = utf8Pointer
        end = p + count
    }

    // Parse the leading UInt64 from the provided utf8 bytes.
    //
    // This usually does a direct conversion of utf8 to UInt64.  It is
    // called for both unquoted numbers and for numbers stored in quoted
    // strings.  In the latter case, the caller is responsible for
    // consuming the leading quote and verifying the trailing quote.
    //
    // If the number is in floating-point format, this uses a slower
    // and less accurate approach: it identifies a substring comprising
    // a float, and then uses Double() and UInt64() to convert that
    // string to an unsigned intger.
    //
    // If it encounters a "\" backslash character, it returns a nil.  This
    // is used by callers that are parsing quoted numbers.  See nextSInt()
    // and nextUInt() below.
    private func parseBareUInt(p: inout UnsafePointer<UInt8>, end: UnsafePointer<UInt8>) throws -> UInt64? {
        let start = p
        let c = p[0]
        p = p + 1
        switch c {
        case asciiZero: // 0
            if p != end {
                let after = p[0]
                switch after {
                case asciiZero...asciiNine: // 0...9
                    // leading '0' forbidden unless it is the only digit
                    throw JSONDecodingError.leadingZero
                case asciiPeriod, asciiLowerE: // . e
                    // Slow path: JSON numbers can be written in floating-point notation
                    p = start
                    if let d = try parseBareDouble(p: &p, end: end) {
                        if let u = UInt64(exactly: d) {
                            return u
                        }
                    }
                    throw JSONDecodingError.malformedNumber
                case asciiBackslash:
                    return nil
                default:
                    return 0
                }
            }
            return 0
        case asciiOne...asciiNine: // 1...9
            var n = UInt64(c - 48)
            while p != end {
                let digit = p[0]
                switch digit {
                case asciiZero...asciiNine: // 0...9
                    let val = UInt64(digit - asciiZero)
                    if n >= UInt64.max / 10 {
                        if n > UInt64.max / 10 || val > UInt64.max % 10 {
                            throw JSONDecodingError.numberRange
                        }
                    }
                    p = p + 1
                    n = n * 10 + val
                case asciiPeriod, asciiLowerE: // . e
                    // Slow path: JSON allows floating-point notation for integers
                    p = start
                    if let d = try parseBareDouble(p: &p, end: end) {
                        if let u = UInt64(exactly: d) {
                            return u
                        }
                    }
                    throw JSONDecodingError.malformedNumber
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
            throw JSONDecodingError.malformedNumber
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
    private func parseBareSInt(p: inout UnsafePointer<UInt8>, end: UnsafePointer<UInt8>) throws -> Int64? {
        if p == end {
            throw JSONDecodingError.truncated
        }
        let c = p[0]
        if c == asciiMinus { // -
            p = p + 1
            // character after '-' must be digit
            let digit = p[0]
            if digit < asciiZero || digit > asciiNine {
                throw JSONDecodingError.malformedNumber
            }
            if let n = try parseBareUInt(p: &p, end: end) {
                if n >= 0x8000000000000000 { // -Int64.min
                    if n > 0x8000000000000000 {
                        // Too large negative number
                        throw JSONDecodingError.numberRange
                    } else {
                        return Int64.min // Special case for Int64.min
                    }
                }
                return -Int64(bitPattern: n)
            } else {
                return nil
            }
        } else if let n = try parseBareUInt(p: &p, end: end) {
            if n > UInt64(bitPattern: Int64.max) {
                throw JSONDecodingError.numberRange
            }
            return Int64(bitPattern: n)
        } else {
            return nil
        }
    }

    // Identify a floating-point token in the upcoming UTF8 bytes.
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
    private func parseBareDouble(p: inout UnsafePointer<UInt8>, end: UnsafePointer<UInt8>) throws -> Double? {
        // RFC 7159 defines the grammar for JSON numbers as:
        // number = [ minus ] int [ frac ] [ exp ]
        let start = p
        var c = p[0]
        if c == asciiBackslash {
            return nil
        }

        // Optional leading minus sign
        if c == asciiMinus { // -
            p += 1
            if p == end {
                p = start
                throw JSONDecodingError.truncated
            }
            c = p[0]
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
            p += 1
            if p == end {
                if let d = doubleFormatter.utf8ToDouble(bytes: start, count: p - start) {
                    return d
                } else {
                    throw JSONDecodingError.malformedNumber
                }
            }
            c = p[0]
            if c == asciiBackslash {
                return nil
            }
            if c >= asciiZero && c <= asciiNine {
                throw JSONDecodingError.leadingZero
            }
        case asciiOne...asciiNine:
            while c >= asciiZero && c <= asciiNine {
                p = p + 1
                if p == end {
                    if let d = doubleFormatter.utf8ToDouble(bytes: start, count: p - start) {
                        return d
                    } else {
                        throw JSONDecodingError.invalidUTF8
                    }
                }
                c = p[0]
                if c == asciiBackslash {
                    return nil
                }
            }
        default:
            // Integer part cannot be empty
            throw JSONDecodingError.malformedNumber
        }

        // frac = decimal-point 1*DIGIT
        if c == asciiPeriod {
            p = p + 1
            if p == end {
                // decimal point must have a following digit
                throw JSONDecodingError.truncated
            }
            c = p[0]
            switch c {
            case asciiZero...asciiNine: // 0...9
                while c >= asciiZero && c <= asciiNine {
                    p = p + 1
                    if p == end {
                        if let d = doubleFormatter.utf8ToDouble(bytes: start, count: p - start) {
                            return d
                        } else {
                            throw JSONDecodingError.malformedNumber
                        }
                    }
                    c = p[0]
                    if c == asciiBackslash {
                        return nil
                    }
                }
            case asciiBackslash:
                return nil
            default:
                throw JSONDecodingError.malformedNumber // decimal point must be followed by at least one digit
            }
        }

        // exp = e [ minus / plus ] 1*DIGIT
        if c == asciiLowerE {
            p = p + 1
            if p == end {
                // "e" must be followed by +,-, or digit
                throw JSONDecodingError.truncated
            }
            c = p[0]
            if c == asciiBackslash {
                return nil
            }
            if c == asciiPlus || c == asciiMinus { // + -
                p = p + 1
                if p == end {
                    // must be at least one digit in exponent
                    throw JSONDecodingError.truncated
                }
                c = p[0]
                if c == asciiBackslash {
                    return nil
                }
            }
            switch c {
            case asciiZero...asciiNine:
                while c >= asciiZero && c <= asciiNine {
                    p = p + 1
                    if p == end {
                        if let d = doubleFormatter.utf8ToDouble(bytes: start, count: p - start) {
                            return d
                        } else {
                            throw JSONDecodingError.malformedNumber
                        }
                    }
                    c = p[0]
                    if c == asciiBackslash {
                        return nil
                    }
                }
            default:
                // must be at least one digit in exponent
                throw JSONDecodingError.malformedNumber
            }
        }
        if let d = doubleFormatter.utf8ToDouble(bytes: start, count: p - start) {
            return d
        } else {
            throw JSONDecodingError.malformedNumber
        }
    }

    /// Skip whitespace
    private mutating func skipWhitespace() {
        while p != end {
            let u = p[0]
            switch u {
            case asciiSpace, asciiTab, asciiNewLine, asciiCarriageReturn: // space, tab, NL, CR
                p += 1
            default:
                return
            }
        }
    }

    /// Returns (but does not consume) the next non-whitespace
    /// character.  This is used by google.protobuf.Value, for
    /// example, for custom JSON parsing.
    internal mutating func peekOneCharacter() throws -> Character {
        skipWhitespace()
        if p == end {
            throw JSONDecodingError.truncated
        }
        return Character(UnicodeScalar(UInt32(p[0]))!)
    }

    /// Returns a fully-parsed string with all backslash escapes
    /// correctly processed, or nil if next token is not a string.
    ///
    /// Assumes the leading quote has been verified (but not consumed)
    private mutating func parseOptionalQuotedString() -> String? {
        // Caller has already asserted that p[0] == quote here
        var sawBackslash = false
        p = p + 1
        let start = p
        while p != end {
            switch p[0] {
            case asciiDoubleQuote: // "
                let s = utf8ToString(bytes: start, count: p - start)
                p = p + 1
                if let t = s {
                    if sawBackslash {
                        return decodeString(t)
                    } else {
                        return t
                    }
                } else {
                    return nil // Invalid UTF8
                }
            case asciiBackslash: //  \
                p = p + 1
                if p == end {
                    return nil // Unterminated escape
                }
                sawBackslash = true
            default:
                break
            }
            p = p + 1
        }
        return nil // Unterminated quoted string
    }

    /// Parse an unsigned integer, whether or not its quoted.
    /// This also handles cases such as quoted numbers that have
    /// backslash escapes in them.
    ///
    /// This supports the full range of UInt64 (whether quoted or not)
    /// unless the number is written in floating-point format.  In that
    /// case, we decode it with only Double precision.
    internal mutating func nextUInt() throws -> UInt64 {
        skipWhitespace()
        if p == end {
            throw JSONDecodingError.truncated
        }
        let c = p[0]
        if c == asciiDoubleQuote {
            let start = p
            p = p + 1
            if let u = try parseBareUInt(p: &p, end: end) {
               if p == end {
                   throw JSONDecodingError.truncated
               }
               if p[0] != asciiDoubleQuote {
                   throw JSONDecodingError.malformedNumber
               }
               p = p + 1
               return u
            } else {
                // Couldn't parse because it had a "\" in the string,
                // so parse out the quoted string and then reparse
                // the result to get a UInt
                p = start
                let s = try nextQuotedString()
                let raw = s.data(using: String.Encoding.utf8)!
                let n = try raw.withUnsafeBytes { (bytes: UnsafePointer<UInt8>) -> UInt64? in
                    var p = bytes
                    let end = p + raw.count
                    if let u = try parseBareUInt(p: &p, end: end) {
                        if p == end {
                            return u
                        }
                    }
                    return nil
                }
                if let n = n {
                    return n
                }
            }
        } else if let u = try parseBareUInt(p: &p, end: end) {
            return u
        }
        throw JSONDecodingError.malformedNumber
    }


    /// Parse a signed integer, quoted or not, including handling
    /// backslash escapes for quoted values.
    ///
    /// This supports the full range of Int64 (whether quoted or not)
    /// unless the number is written in floating-point format.  In that
    /// case, we decode it with only Double precision.
    internal mutating func nextSInt() throws -> Int64 {
        skipWhitespace()
        if p == end {
            throw JSONDecodingError.truncated
        }
        let c = p[0]
        if c == asciiDoubleQuote {
            let start = p
            p = p + 1
            if let s = try parseBareSInt(p: &p, end: end) {
                if p == end {
                    throw JSONDecodingError.truncated
                }
                if p[0] != asciiDoubleQuote {
                    throw JSONDecodingError.malformedNumber
                }
                p = p + 1
                return s
            } else {
                // Couldn't parse because it had a "\" in the string,
                // so parse out the quoted string and then reparse
                // the result as an SInt
                p = start
                let s = try nextQuotedString()
                let raw = s.data(using: String.Encoding.utf8)!
                let n = try raw.withUnsafeBytes { (bytes: UnsafePointer<UInt8>) -> Int64? in
                    var p = bytes
                    let end = p + raw.count
                    if let s = try parseBareSInt(p: &p, end: end) {
                        if p == end {
                            return s
                        }
                    }
                    return nil
                }
                if let n = n {
                    return n
                }
            }
        } else if let s = try parseBareSInt(p: &p, end: end) {
            return s
        }
        throw JSONDecodingError.malformedNumber
    }

    /// Parse the next Float value, regardless of whether it
    /// is quoted, including handling backslash escapes for
    /// quoted strings.
    internal mutating func nextFloat() throws -> Float {
        skipWhitespace()
        if p == end {
            throw JSONDecodingError.truncated
        }
        let c = p[0]
        if c == asciiDoubleQuote { // "
            let start = p
            p = p + 1
            if let d = try parseBareDouble(p: &p, end: end) {
                if p == end {
                    throw JSONDecodingError.truncated
                }
                if p[0] != asciiDoubleQuote {
                    throw JSONDecodingError.malformedNumber
                }
                p = p + 1
                let f = Float(d)
                if f.isFinite {
                    return f
                }
            } else {
                // Slow Path: parseBareDouble returned nil: It might be
                // a valid float, but had something that
                // parseBareDouble cannot directly handle.  So we reset,
                // try a full string parse, then examine the result:
                p = start
                let s = try nextQuotedString()
                switch s {
                case "NaN": return Float.nan
                case "Inf": return Float.infinity
                case "-Inf": return -Float.infinity
                case "Infinity": return Float.infinity
                case "-Infinity": return -Float.infinity
                default:
                    let raw = s.data(using: String.Encoding.utf8)!
                    let n = try raw.withUnsafeBytes { (bytes: UnsafePointer<UInt8>) -> Float? in
                        var p = bytes
                        let end = p + raw.count
                        if let d = try parseBareDouble(p: &p, end: end) {
                            let f = Float(d)
                            if p == end && f.isFinite {
                                return f
                            }
                        }
                        return nil
                    }
                    if let n = n {
                        return n
                    }
                }
            }
        } else {
            if let d = try parseBareDouble(p: &p, end: end) {
                let f = Float(d)
                if f.isFinite {
                    return f
                }
            }
        }
        throw JSONDecodingError.malformedNumber
    }

    /// Parse the next Double value, regardless of whether it
    /// is quoted, including handling backslash escapes for
    /// quoted strings.
    internal mutating func nextDouble() throws -> Double {
        skipWhitespace()
        if p == end {
            throw JSONDecodingError.truncated
        }
        let c = p[0]
        if c == asciiDoubleQuote { // "
            let start = p
            p = p + 1
            if let d = try parseBareDouble(p: &p, end: end) {
                if p == end {
                    throw JSONDecodingError.truncated
                }
                if p[0] != asciiDoubleQuote {
                    throw JSONDecodingError.malformedNumber
                }
                p = p + 1
                return d
            } else {
                // Slow Path: parseBareDouble returned nil: It might be
                // a valid float, but had something that
                // parseBareDouble cannot directly handle.  So we reset,
                // try a full string parse, then examine the result:
                p = start
                let s = try nextQuotedString()
                switch s {
                case "NaN": return Double.nan
                case "Inf": return Double.infinity
                case "-Inf": return -Double.infinity
                case "Infinity": return Double.infinity
                case "-Infinity": return -Double.infinity
                default:
                    let raw = s.data(using: String.Encoding.utf8)!
                    let n = try raw.withUnsafeBytes { (bytes: UnsafePointer<UInt8>) -> Double? in
                        var p = bytes
                        let end = p + raw.count
                        if let d = try parseBareDouble(p: &p, end: end), p == end {
                            return d
                        }
                        return nil
                    }
                    if let n = n {
                        return n
                    }
                }
            }
        } else {
            if let d = try parseBareDouble(p: &p, end: end) {
                return d
            }
        }
        throw JSONDecodingError.malformedNumber
    }

    /// Return the contents of the following quoted string,
    /// or throw an error if the next token is not a string.
    internal mutating func nextQuotedString() throws -> String {
        skipWhitespace()
        if p == end {
            throw JSONDecodingError.truncated
        }
        let c = p[0]
        if c != asciiDoubleQuote {
            throw JSONDecodingError.malformedString
        }
        if let s = parseOptionalQuotedString() {
            return s
        } else {
            throw JSONDecodingError.malformedString
        }
    }

    /// Return the contents of the following quoted string,
    /// or nil if the next token is not a string.
    /// This will only throw an error if the next token starts
    /// out as a string but is malformed in some way.
    internal mutating func nextOptionalQuotedString() throws -> String? {
        skipWhitespace()
        if p == end {
            return nil
        }
        let c = p[0]
        if c != asciiDoubleQuote {
            return nil
        }
        return try nextQuotedString()
    }

    /// Return a Data with the decoded contents of the
    /// following base-64 string.
    internal mutating func nextBytesValue() throws -> Data {
        skipWhitespace()
        if p == end {
            throw JSONDecodingError.truncated
        }
        let c = p[0]
        if c != asciiDoubleQuote {
            throw JSONDecodingError.malformedString
        }
        if let s = parseOptionalQuotedString(), let b = decodeBytes(base64String: s) {
            return b
        } else {
            throw JSONDecodingError.malformedString
        }
    }

    /// Private function to help parse keywords.
    private mutating func skipOptionalKeyword(bytes: [UInt8]) -> Bool {
        let start = p
        for b in bytes {
            if p == end {
                p = start
                return false
            }
            let c = p[0]
            if c != b {
                p = start
                return false
            }
            p = p + 1
        }
        if p != end {
            let c = p[0]
            if (c >= asciiUpperA && c <= asciiUpperZ) || (c >= asciiLowerA && c <= asciiLowerZ) {
                p = start
                return false
            }
        }
        return true
    }

    /// If the next token is the identifier "null", consume it and return true.
    internal mutating func skipOptionalNull() -> Bool {
        skipWhitespace()
        if p != end && p[0] == asciiLowerN {
            return skipOptionalKeyword(bytes: [asciiLowerN, asciiLowerU, asciiLowerL, asciiLowerL])
        }
        return false
    }

    /// Return the following Bool "true" or "false", including
    /// full processing of quoted boolean values.  (Used in map
    /// keys, for instance.)
    internal mutating func nextBool() throws -> Bool {
        skipWhitespace()
        if p == end {
            throw JSONDecodingError.truncated
        }
        let c = p[0]
        switch c {
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
        throw JSONDecodingError.malformedBool
    }

    /// Return the following Bool "true" or "false", including
    /// full processing of quoted boolean values.  (Used in map
    /// keys, for instance.)
    internal mutating func nextQuotedBool() throws -> Bool {
        skipWhitespace()
        if p == end {
            throw JSONDecodingError.truncated
        }
        if p[0] != asciiDoubleQuote {
            throw JSONDecodingError.unquotedMapKey
        }
        if let s = parseOptionalQuotedString() {
            switch s {
            case "false": return false
            case "true": return true
            default: break
            }
        }
        throw JSONDecodingError.malformedBool
    }

    /// Returns pointer/count spanning the UTF8 bytes of the next regular
    /// key or nil if the key contains a backslash (and therefore requires
    /// the full string-parsing logic to properly parse).
    private mutating func nextBareKey() throws -> UnsafeBufferPointer<UInt8>? {
        skipWhitespace()
        let stringStart = p
        if p == end {
            throw JSONDecodingError.truncated
        }
        if p[0] != asciiDoubleQuote {
            throw JSONDecodingError.malformedString
        }
        p = p + 1
        let nameStart = p
        while p != end && p[0] != asciiDoubleQuote {
            if p[0] == asciiBackslash {
                p = stringStart // Reset to open quote
                return nil
            }
            p = p + 1
        }
        if p == end {
            throw JSONDecodingError.truncated
        }
        let buff = UnsafeBufferPointer<UInt8>(start: nameStart, count: p - nameStart)
        p = p + 1
        return buff
    }

    /// Parse a field name, look it up in the provided field name map,
    /// and return the corresponding field number.
    ///
    /// Throws if field name cannot be parsed.
    /// If it encounters an unknown field name, it silently skips
    /// the value and looks at the following field name.
    internal mutating func nextFieldNumber(names: _NameMap) throws -> Int? {
        while true {
            if let key = try nextBareKey() {
                try skipRequiredCharacter(asciiColon) // :
                if let fieldNumber = names.number(forJSONName: key) {
                    return fieldNumber
                }
            } else {
                let key = try nextQuotedString()
                try skipRequiredCharacter(asciiColon) // :
                if let fieldNumber = names.number(forJSONName: key) {
                    return fieldNumber
                }
            }
            // Unknown field, skip it and try to parse the next field name
            try skipValue()
            if skipOptionalObjectEnd() {
                return nil
            }
            try skipRequiredComma()
        }
    }

    /// Helper for skipping a single-character token.
    private mutating func skipRequiredCharacter(_ required: UInt8) throws {
        skipWhitespace()
        if p == end {
            throw JSONDecodingError.truncated
        }
        let next = p[0]
        if next == required {
            p = p + 1
            return
        }
        throw JSONDecodingError.failure
    }

    /// Skip "{", throw if that's not the next character
    internal mutating func skipRequiredObjectStart() throws {
        try skipRequiredCharacter(asciiOpenCurlyBracket) // {
    }

    /// Skip ",", throw if that's not the next character
    internal mutating func skipRequiredComma() throws {
        try skipRequiredCharacter(asciiComma)
    }

    /// Skip ":", throw if that's not the next character
    internal mutating func skipRequiredColon() throws {
        try skipRequiredCharacter(asciiColon)
    }

    /// Skip "[", throw if that's not the next character
    internal mutating func skipRequiredArrayStart() throws {
        try skipRequiredCharacter(asciiOpenSquareBracket) // [
    }

    /// Helper for skipping optional single-character tokens
    private mutating func skipOptionalCharacter(_ c: UInt8) -> Bool {
        skipWhitespace()
        if p != end && p[0] == c {
            p = p + 1
            return true
        }
        return false
    }

    /// If the next non-whitespace character is "]", skip it
    /// and return true.  Otherwise, return false.
    internal mutating func skipOptionalArrayEnd() -> Bool {
        return skipOptionalCharacter(asciiCloseSquareBracket) // ]
    }

    /// If the next non-whitespace character is "}", skip it
    /// and return true.  Otherwise, return false.
    internal mutating func skipOptionalObjectEnd() -> Bool {
        return skipOptionalCharacter(asciiCloseCurlyBracket) // }
    }

    /// Return the next complete JSON structure as a string.
    /// For example, this might return "true", or "123.456",
    /// or "{\"foo\": 7, \"bar\": [8, 9]}"
    ///
    /// Used by Any to get the upcoming JSON value as a string.
    /// Note: The value might be an object or array.
    internal mutating func skip() throws -> String {
        skipWhitespace()
        let start = p
        try skipValue()
        if let s = utf8ToString(bytes: start, count: p - start) {
            return s
        } else {
            throw JSONDecodingError.invalidUTF8
        }
    }

    /// Advance index past the next value.  This is used
    /// by skip() and by unknown field handling.
    private mutating func skipValue() throws {
        skipWhitespace()
        if p == end {
            throw JSONDecodingError.truncated
        }
        switch p[0] {
        case asciiDoubleQuote: // " begins a string
            try skipString()
        case asciiOpenCurlyBracket: // { begins an object
            try skipObject()
        case asciiOpenSquareBracket: // [ begins an array
            try skipArray()
        case asciiLowerN: // n must be null
            if !skipOptionalKeyword(bytes: [asciiLowerN, asciiLowerU, asciiLowerL, asciiLowerL]) {
                throw JSONDecodingError.truncated
            }
        case asciiLowerF: // f must be false
            if !skipOptionalKeyword(bytes: [asciiLowerF, asciiLowerA, asciiLowerL, asciiLowerS, asciiLowerE]) {
                throw JSONDecodingError.truncated
            }
        case asciiLowerT: // t must be true
            if !skipOptionalKeyword(bytes: [asciiLowerT, asciiLowerR, asciiLowerU, asciiLowerE]) {
                throw JSONDecodingError.truncated
            }
        default: // everything else is a number token
            _ = try nextDouble()
        }
    }

    /// Advance the index past the next complete {...} construct.
    private mutating func skipObject() throws {
        try skipRequiredObjectStart()
        if skipOptionalObjectEnd() {
            return
        }
        while true {
            skipWhitespace()
            try skipString()
            try skipRequiredColon()
            try skipValue()
            if skipOptionalObjectEnd() {
                return
            }
            try skipRequiredComma()
        }
    }

    /// Advance the index past the next complete [...] construct.
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

    /// Advance the index past the next complete quoted string.
    ///
    // Caveat:  This does not fully validate; it will accept
    // strings that have malformed \ escapes.
    //
    // It would be nice to do better, but I don't think it's critical,
    // since there are many reasons that strings (and other tokens for
    // that matter) may be skippable but not parseable.  For example:
    // Old clients that don't know new field types will skip fields
    // they don't know; newer clients may reject the same input due to
    // schema mismatches or other issues.
    private mutating func skipString() throws {
        if p[0] != asciiDoubleQuote {
            throw JSONDecodingError.malformedString
        }
        p = p + 1
        while p != end {
            let c = p[0]
            switch c {
            case asciiDoubleQuote:
                p = p + 1
                return
            case asciiBackslash:
                p = p + 1
                if p == end {
                    throw JSONDecodingError.truncated
                }
                p = p + 1
            default:
                p = p + 1
            }
        }
        throw JSONDecodingError.truncated
    }
}
