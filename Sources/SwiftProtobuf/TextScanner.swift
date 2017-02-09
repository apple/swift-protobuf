// Sources/SwiftProtobuf/TextScanner.swift - Text format decoding
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Test format decoding engine.
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
private let asciiUpperE = UInt8(ascii: "E")
private let asciiLowerF = UInt8(ascii: "f")
private let asciiUpperF = UInt8(ascii: "F")
private let asciiLowerI = UInt8(ascii: "i")
private let asciiLowerN = UInt8(ascii: "n")
private let asciiLowerR = UInt8(ascii: "r")
private let asciiLowerT = UInt8(ascii: "t")
private let asciiLowerU = UInt8(ascii: "u")
private let asciiLowerV = UInt8(ascii: "v")
private let asciiLowerX = UInt8(ascii: "x")
private let asciiLowerY = UInt8(ascii: "y")
private let asciiLowerZ = UInt8(ascii: "z")
private let asciiUpperZ = UInt8(ascii: "Z")

private func fromHexDigit(_ c: UInt8) -> UInt8? {
  if c >= asciiZero && c <= asciiNine {
    return c - asciiZero
  }
  if c >= asciiUpperA && c <= asciiUpperF {
      return c - asciiUpperA + 10
  }
  if c >= asciiLowerA && c <= asciiLowerF {
      return c - asciiLowerA + 10
  }
  return nil
}

// Protobuf Text format uses C ASCII conventions for
// encoding byte sequences, including the use of octal
// and hexadecimal escapes.
private func decodeBytes(_ s: String) -> Data? {
  var out = [UInt8]()
  var bytes = s.utf8.makeIterator()
  while let byte = bytes.next() {
    switch byte {
    case asciiBackslash: //  "\\"
      if let escaped = bytes.next() {
        switch escaped {
        case asciiZero...asciiSeven: // '0'...'7'
          // C standard allows 1, 2, or 3 octal digits.
          let savedPosition = bytes
          let digit1 = escaped
          let digit1Value = digit1 - asciiZero
          if let digit2 = bytes.next(),
             digit2 >= asciiZero, digit2 <= asciiSeven {
            let digit2Value = digit2 - asciiZero
            let innerSavedPosition = bytes
            if let digit3 = bytes.next(),
               digit3 >= asciiZero, digit3 <= asciiSeven {
              let digit3Value = digit3 - asciiZero
              let n = digit1Value * 64 + digit2Value * 8 + digit3Value
              out.append(UInt8(n))
            } else {
              let n = digit1Value * 8 + digit2Value
              out.append(UInt8(n))
              bytes = innerSavedPosition
            }
          } else {
            let n = digit1Value
            out.append(UInt8(n))
            bytes = savedPosition
          }
        case asciiLowerX: // 'x' hexadecimal escape
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
        case asciiLowerA: // \a ("alert")
          out.append(asciiBell)
        case asciiLowerB: // \b
          out.append(asciiBackspace)
        case asciiLowerF: // \f
          out.append(asciiFormFeed)
        case asciiLowerN: // \n
          out.append(asciiNewLine)
        case asciiLowerR: // \r
          out.append(asciiCarriageReturn)
        case asciiLowerT: // \t
          out.append(asciiTab)
        case asciiLowerV: // \v
          out.append(asciiVerticalTab)
        case asciiSingleQuote,
             asciiDoubleQuote,
             asciiQuestionMark: // \'  \"  \?
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

// Protobuf Text encoding assumes that you're working directly
// in UTF-8.  So this implementation converts the string to UTF8,
// then decodes it into a sequence of bytes, then converts
// it back into a string.
private func decodeString(_ s: String) -> String? {
  var out = [UInt8]()
  var bytes = s.utf8.makeIterator()
  while let byte = bytes.next() {
    switch byte {
    case asciiBackslash: // backslash
      if let escaped = bytes.next() {
        switch escaped {
        case asciiZero...asciiSeven: // 0...7
          // C standard allows 1, 2, or 3 octal digits.
          let savedPosition = bytes
          let digit1 = escaped
          let digit1Value = digit1 - asciiZero
          if let digit2 = bytes.next(),
            digit2 >= asciiZero && digit2 <= asciiSeven {
            let digit2Value = digit2 - asciiZero
            let innerSavedPosition = bytes
            if let digit3 = bytes.next(),
              digit3 >= asciiZero && digit3 <= asciiSeven {
              let digit3Value = digit3 - asciiZero
              let n = digit1Value * 64 + digit2Value * 8 + digit3Value
              out.append(n)
            } else {
              let n = digit1Value * 8 + digit2Value
              out.append(n)
              bytes = innerSavedPosition
            }
          } else {
            let n = digit1Value
            out.append(n)
            bytes = savedPosition
          }
        case asciiLowerX: // "x"
          // C standard allows any number of hex digits after \x
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
        case asciiLowerA: // \a
          out.append(asciiBell)
        case asciiLowerB: // \b
          out.append(asciiBackspace)
        case asciiLowerF: // \f
          out.append(asciiFormFeed)
        case asciiLowerN: // \n
          out.append(asciiNewLine)
        case asciiLowerR: // \r
          out.append(asciiCarriageReturn)
        case asciiLowerT: // \t
          out.append(asciiTab)
        case asciiLowerV: // \v
          out.append(asciiVerticalTab)
        case asciiDoubleQuote,
             asciiSingleQuote,
             asciiQuestionMark,
             asciiBackslash: // " ' ? \
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
  // There has got to be an easier way to convert a [UInt8] into a String.
  return out.withUnsafeBufferPointer { ptr in
    if let addr = ptr.baseAddress {
        return utf8ToString(bytes: addr, count: ptr.count)
    } else {
      return ""
    }
  }
}

///
/// TextScanner has no public members.
///
public class TextScanner {
    internal var extensions: ExtensionSet?
    private var utf8: String.UTF8View
    private var index: String.UTF8View.Index

    internal var complete: Bool {
        skipWhitespace()
        return index == utf8.endIndex
    }

    internal init(text: String, extensions: ExtensionSet? = nil) {
        utf8 = text.utf8
        index = utf8.startIndex
        self.extensions = extensions
    }

    /// Skip whitespace
    private func skipWhitespace() {
        while index != utf8.endIndex {
            let u = utf8[index]
            switch u {
            case asciiSpace,
                 asciiTab,
                 asciiNewLine,
                 asciiCarriageReturn: // space, tab, NL, CR
                index = utf8.index(after: index)
            case asciiHash: // #
                index = utf8.index(after: index)
                while index != utf8.endIndex {
                    // Skip until end of line
                    let c = utf8[index]
                    index = utf8.index(after: index)
                    if c == asciiNewLine || c == asciiCarriageReturn {
                        break
                    }
                }
            default:
                return
            }
        }
    }

    private func parseIdentifier() -> String? {
        let start = index
        while index != utf8.endIndex {
            let c = utf8[index]
            switch c {
            case asciiLowerA...asciiLowerZ,
                 asciiUpperA...asciiUpperZ,
                 asciiZero...asciiNine,
                 asciiUnderscore:
                index = utf8.index(after: index)
            default:
                return String(utf8[start..<index])
            }
        }
        return String(utf8[start..<index])
    }

    /// Parse the rest of an [extension_field_name] in the input, assuming the
    /// initial "[" character has already been read (and is in the prefix)
    /// This is also used for AnyURL, so we include "/", "."
    private func parseExtensionKey() -> String? {
        let start = index
        if index == utf8.endIndex {
            return nil
        }
        let c = utf8[index]
        switch c {
        case asciiLowerA...asciiLowerZ, asciiUpperA...asciiUpperZ:
            index = utf8.index(after: index)
        default:
            return nil
        }
        while index != utf8.endIndex {
            let c = utf8[index]
            switch c {
            case asciiLowerA...asciiLowerZ,
                 asciiUpperA...asciiUpperZ,
                 asciiZero...asciiNine,
                 asciiUnderscore,
                 asciiPeriod,
                 asciiForwardSlash:
                index = utf8.index(after: index)
            case asciiCloseSquareBracket: // ]
                let s = String(utf8[start..<index])
                return s
            default:
                return nil
            }
        }
        return nil
    }

    /// Assumes the leading quote has already been consumed
    private func parseQuotedString(terminator: UInt8) -> String? {
        let start = index
        while index != utf8.endIndex {
            let c = utf8[index]
            if c == terminator {
                let s = String(utf8[start..<index])
                index = utf8.index(after: index)
                return s
            }
            index = utf8.index(after: index)
            if c == asciiBackslash { //  \
                if index == utf8.endIndex {
                    return nil
                }
                index = utf8.index(after: index)
            }
        }
        return nil // Unterminated quoted string
    }

    /// Assumes the leading quote has already been consumed
    private func parseStringSegment(terminator: UInt8) -> String? {
        let start = index
        var sawBackslash = false
        while index != utf8.endIndex {
            let c = utf8[index]
            if c == terminator {
                let s = String(utf8[start..<index])
                index = utf8.index(after: index)
                if let s = s, sawBackslash {
                    return decodeString(s)
                } else {
                    return s
                }
            }
            index = utf8.index(after: index)
            if c == asciiBackslash { //  \
                if index == utf8.endIndex {
                    return nil
                }
                sawBackslash = true
                index = utf8.index(after: index)
            }
        }
        return nil // Unterminated quoted string
    }

    internal func nextUInt() throws -> UInt64 {
        skipWhitespace()
        if index == utf8.endIndex {
            throw TextDecodingError.malformedNumber
        }
        let c = utf8[index]
        index = utf8.index(after: index)
        if c == asciiZero { // leading '0' precedes octal or hex
            if utf8[index] == asciiLowerX { // 'x' => hex
                index = utf8.index(after: index)
                var n: UInt64 = 0
                while index != utf8.endIndex {
                    let digit = utf8[index]
                    let val: UInt64
                    switch digit {
                    case asciiZero...asciiNine: // 0...9
                        val = UInt64(digit - asciiZero)
                    case asciiLowerA...asciiLowerF: // a...f
                        val = UInt64(digit - asciiLowerA + 10)
                    case asciiUpperA...asciiUpperF:
                        val = UInt64(digit - asciiUpperA + 10)
                    case asciiLowerU: // trailing 'u'
                        index = utf8.index(after: index)
                        return n
                    default:
                        return n
                    }
                    if n > UInt64.max / 16 {
                        throw TextDecodingError.malformedNumber
                    }
                    index = utf8.index(after: index)
                    n = n * 16 + val
                }
                return n
            } else { // octal
                var n: UInt64 = 0
                while index != utf8.endIndex {
                    let digit = utf8[index]
                    if digit == asciiLowerU { // trailing 'u'
                        index = utf8.index(after: index)
                        return n
                    }
                    if digit < asciiZero || digit > asciiSeven {
                        return n // not octal digit
                    }
                    let val = UInt64(digit - asciiZero)
                    if n > UInt64.max / 8 {
                        throw TextDecodingError.malformedNumber
                    }
                    index = utf8.index(after: index)
                    n = n * 8 + val
                }
                return n
            }
        } else if c > asciiZero && c <= asciiNine { // 1...9
            var n = UInt64(c - asciiZero)
            while index != utf8.endIndex {
                let digit = utf8[index]
                if digit == asciiLowerU { // trailing 'u'
                    index = utf8.index(after: index)
                    return n
                }
                if digit < asciiZero || digit > asciiNine {
                    return n // not a digit
                }
                let val = UInt64(digit - asciiZero)
                if n >= UInt64.max / 10 {
                    if n > UInt64.max / 10 || val > UInt64.max % 10 {
                        throw TextDecodingError.malformedNumber
                    }
                }
                index = utf8.index(after: index)
                n = n * 10 + val
            }
            return n
        }
        throw TextDecodingError.malformedNumber
    }

    internal func nextSInt() throws -> Int64 {
        skipWhitespace()
        if index == utf8.endIndex {
            throw TextDecodingError.malformedNumber
        }
        let c = utf8[index]
        if c == asciiMinus { // -
            index = utf8.index(after: index)
            // character after '-' must be digit
            let digit = utf8[index]
            if digit < asciiZero || digit > asciiNine {
                throw TextDecodingError.malformedNumber
            }
            let n = try nextUInt()
            if n >= 0x8000000000000000 { // -Int64.min
                if n > 0x8000000000000000 {
                    // Too large negative number
                    throw TextDecodingError.malformedNumber
                } else {
                    return Int64.min // Special case for Int64.min
                }
            }
            return -Int64(bitPattern: n)
        } else {
            let n = try nextUInt()
            if n > UInt64(bitPattern: Int64.max) {
                throw TextDecodingError.malformedNumber
            }
            return Int64(bitPattern: n)
        }
    }

    internal func nextStringValue() throws -> String {
        var result: String
        skipWhitespace()
        if index == utf8.endIndex {
            throw TextDecodingError.malformedText
        }
        let c = utf8[index]
        if c != asciiSingleQuote && c != asciiDoubleQuote {
            throw TextDecodingError.malformedText
        }
        index = utf8.index(after: index)
        if let s = parseStringSegment(terminator: c) {
            result = s
        } else {
            throw TextDecodingError.malformedText
        }

        while true {
            skipWhitespace()
            if index == utf8.endIndex {
                return result
            }
            let c = utf8[index]
            if c != asciiSingleQuote && c != asciiDoubleQuote {
                return result
            }
            index = utf8.index(after: index)
            if let s = parseStringSegment(terminator: c) {
                result.append(s)
            } else {
                throw TextDecodingError.malformedText
            }
        }
    }

    internal func nextBytesValue() throws -> Data {
        var result: Data
        skipWhitespace()
        if index == utf8.endIndex {
            throw TextDecodingError.malformedText
        }
        let c = utf8[index]
        if c != asciiSingleQuote && c != asciiDoubleQuote {
            throw TextDecodingError.malformedText
        }
        index = utf8.index(after: index)
        if let s = parseQuotedString(terminator: c), let b = decodeBytes(s) {
            result = b
        } else {
            throw TextDecodingError.malformedText
        }

        while true {
            skipWhitespace()
            if index == utf8.endIndex {
                return result
            }
            let c = utf8[index]
            if c != asciiSingleQuote && c != asciiDoubleQuote {
                return result
            }
            index = utf8.index(after: index)
            if let s = parseQuotedString(terminator: c),
               let b = decodeBytes(s) {
                result.append(b)
            } else {
                throw TextDecodingError.malformedText
            }
        }
    }

    // Tries to identify a sequence of UTF8 characters
    // that represent a numeric floating-point value.
    private func tryParseFloatString() -> String? {
        skipWhitespace()
        guard index != utf8.endIndex else {return nil}
        let start = index
        var c = utf8[index]
        if c == asciiMinus {
            index = utf8.index(after: index)
            guard index != utf8.endIndex else {index = start; return nil}
            c = utf8[index]
        }
        switch c {
        case asciiZero: // '0' as first character only if followed by '.'
            index = utf8.index(after: index)
            guard index != utf8.endIndex else {index = start; return nil}
            c = utf8[index]
            if c != asciiPeriod {
                index = start
                return nil
            }
        case asciiPeriod: // '.' as first char only if followed by digit
            index = utf8.index(after: index)
            guard index != utf8.endIndex else {index = start; return nil}
            c = utf8[index]
            if c < asciiZero || c > asciiNine {
                index = start
                return nil
            }
        case asciiOne...asciiNine:
            break
        default:
            index = start
            return nil
        }
        while index != utf8.endIndex {
            let c = utf8[index]
            switch c {
            case asciiZero...asciiNine,
                 asciiPeriod,
                 asciiPlus,
                 asciiMinus,
                 asciiLowerE,
                 asciiUpperE: // 0...9, ., +, -, e, E
                index = utf8.index(after: index)
            case asciiLowerF: // f
                // proto1 allowed floats to be suffixed with 'f'
                let s = String(utf8[start..<index])!
                // Just skip the 'f'
                index = utf8.index(after: index)
                return s
            default:
                return String(utf8[start..<index])!
            }
        }
        return String(utf8[start..<index])!
    }

    private func skipOptionalKeyword(bytes: [UInt8]) -> Bool {
        skipWhitespace()
        let start = index
        for b in bytes {
            if index == utf8.endIndex {
                index = start
                return false
            }
            var c = utf8[index]
            if c >= asciiUpperA && c <= asciiUpperZ {
                // Convert to lower case
                // (Protobuf text keywords are case insensitive)
                c += asciiLowerA - asciiUpperA
            }
            if c != b {
                index = start
                return false
            }
            index = utf8.index(after: index)
        }
        if index == utf8.endIndex {
            index = start
            return true
        }
        let c = utf8[index]
        if ((c >= asciiUpperA && c <= asciiUpperZ)
            || (c >= asciiLowerA && c <= asciiLowerZ)) {
            index = start
            return false
        }
        return true
    }

    // If the next token is the identifier "nan", return true.
    private func skipOptionalNaN() -> Bool {
        return skipOptionalKeyword(bytes:
                                  [asciiLowerN, asciiLowerA, asciiLowerN])
    }

    // If the next token is a recognized spelling of "infinity",
    // return Float.infinity or -Float.infinity
    private func skipOptionalInfinity() -> Float? {
        skipWhitespace()
        if index == utf8.endIndex {
            return nil
        }
        let c = utf8[index]
        let negated: Bool
        if c == asciiMinus {
            negated = true
            index = utf8.index(after: index)
        } else {
            negated = false
        }
        let inf = [asciiLowerI, asciiLowerN, asciiLowerF]
        let infinity = [asciiLowerI, asciiLowerN, asciiLowerF, asciiLowerI,
                        asciiLowerN, asciiLowerI, asciiLowerT, asciiLowerY]
        if (skipOptionalKeyword(bytes: inf)
            || skipOptionalKeyword(bytes: infinity)) {
            return negated ? -Float.infinity : Float.infinity
        }
        return nil
    }

    internal func nextFloat() throws -> Float {
        if let s = tryParseFloatString() {
            if let n = Float(s) {
                return n
            }
        }
        if skipOptionalNaN() {
            return Float.nan
        }
        if let inf = skipOptionalInfinity() {
            return inf
        }
        throw TextDecodingError.malformedNumber
    }

    internal func nextDouble() throws -> Double {
        if let s = tryParseFloatString() {
            if let n = Double(s) {
                return n
            }
        }
        if skipOptionalNaN() {
            return Double.nan
        }
        if let inf = skipOptionalInfinity() {
            return Double(inf)
        }
        throw TextDecodingError.malformedNumber
    }

    internal func nextBool() throws -> Bool {
        skipWhitespace()
        if index == utf8.endIndex {
            throw TextDecodingError.malformedText
        }
        let c = utf8[index]
        switch c {
        case asciiZero: // 0
            index = utf8.index(after: index)
            return false
        case asciiOne: // 1
            index = utf8.index(after: index)
            return true
        default:
            if let s = parseIdentifier() {
                switch s {
                case "f", "false", "False":
                    return false
                case "t", "true", "True":
                    return true
                default:
                    break
                }
            }
        }
        throw TextDecodingError.malformedText
    }

    internal func nextOptionalEnumName() throws -> String? {
        skipWhitespace()
        if index == utf8.endIndex {
            throw TextDecodingError.malformedText
        }
        let c = utf8[index]
        let start = index
        switch c {
        case asciiLowerA...asciiLowerZ, asciiUpperA...asciiUpperZ:
            if let s = parseIdentifier() {
                return s
            }
        default:
            break
        }
        index = start
        return nil
    }

    /// Any URLs are syntactically (almost) identical to extension
    /// keys, so we share the code for those.
    internal func nextOptionalAnyURL() throws -> String? {
        return try nextOptionalExtensionKey()
    }

    /// Returns next extension key or nil if end-of-input or
    /// if next token is not an extension key.
    ///
    /// Throws an error if the next token starts with '[' but
    /// cannot be parsed as an extension key.
    ///
    /// Note: This accepts / characters to support Any URL parsing.
    /// Technically, Any URLs can contain / characters and extension
    /// key names cannot.  But in practice, accepting / chracters for
    /// extension keys works fine, since the result just gets rejected
    /// when the key is looked up.
    internal func nextOptionalExtensionKey() throws -> String? {
        skipWhitespace()
        if index == utf8.endIndex {
            return nil
        }
        if utf8[index] == asciiOpenSquareBracket { // [
            index = utf8.index(after: index)
            if let s = parseExtensionKey() {
                if index == utf8.endIndex || utf8[index] != asciiCloseSquareBracket {
                    throw TextDecodingError.malformedText
                }
                // Skip ]
                index = utf8.index(after: index)
                return s
            } else {
                print("Error parsing extension identifier")
                throw TextDecodingError.malformedText
            }
        }
        return nil
    }

    /// Returns text of next regular key or nil if end-of-input.
    /// This considers an extension key [keyname] to be an
    /// error, so call nextOptionalExtensionKey first if you
    /// want to handle extension keys.
    ///
    /// This is only used by map parsing; we should be able to
    /// rework that to use nextFieldNumber instead.
    internal func nextKey() throws -> String? {
        skipWhitespace()
        if index == utf8.endIndex {
            return nil
        }
        let c = utf8[index]
        switch c {
        case asciiOpenSquareBracket: // [
            throw TextDecodingError.malformedText
        case asciiLowerA...asciiLowerZ,
             asciiUpperA...asciiUpperZ: // a...z, A...Z
            if let s = parseIdentifier() {
                return s
            } else {
                throw TextDecodingError.malformedText
            }
        default:
            throw TextDecodingError.malformedText
        }
    }

    /// Parse a field name, look it up, and return the corresponding
    /// field number.
    ///
    /// returns nil at end-of-input
    ///
    /// Throws if field name cannot be parsed or if field name is
    /// unknown.
    ///
    /// This function accounts for as much as 2/3 of the total run
    /// time of the entire parse.
    internal func nextFieldNumber(names: FieldNameMap) throws -> Int? {
        skipWhitespace()
        if index == utf8.endIndex {
            return nil
        }
        let c = utf8[index]
        switch c {
        case asciiLowerA...asciiLowerZ,
             asciiUpperA...asciiUpperZ: // a...z, A...Z
            let start = index
            index = utf8.index(after: index)
            scanKeyLoop: while index != utf8.endIndex {
                let c = utf8[index]
                switch c {
                case asciiLowerA...asciiLowerZ,
                     asciiUpperA...asciiUpperZ,
                     asciiZero...asciiNine,
                     asciiUnderscore: // a...z, A...Z, 0...9, _
                    index = utf8.index(after: index)
                default:
                    break scanKeyLoop
                }
            }
            // The next line can account for more than 1/3 of the total
            // run time of the entire parse, just to create a String
            // object that is discarded almost immediately.
            //
            // One idea: Have the name map build a ternary tree
            // instead of a hash table, turn the character scan above
            // into a walk of that tree.  This would look up the field
            // number directly from the character scan without
            // creating this intermediate string.
            if let key = String(utf8[start..<index]) {
                if let fieldNumber = names.fieldNumber(forProtoName: key) {
                    return fieldNumber
                } else {
                    throw TextDecodingError.unknownField
                }
            }
        default:
            break
        }
        throw TextDecodingError.malformedText
    }

    private func skipRequiredCharacter(_ c: UInt8) throws {
        skipWhitespace()
        if index != utf8.endIndex && utf8[index] == c {
            index = utf8.index(after: index)
        } else {
            throw TextDecodingError.malformedText
        }
    }

    internal func skipRequiredComma() throws {
        try skipRequiredCharacter(asciiComma)
    }

    internal func skipRequiredColon() throws {
        try skipRequiredCharacter(asciiColon)
    }

    private func skipOptionalCharacter(_ c: UInt8) -> Bool {
        skipWhitespace()
        if index != utf8.endIndex && utf8[index] == c {
            index = utf8.index(after: index)
            return true
        }
        return false
    }

    internal func skipOptionalColon() -> Bool {
        return skipOptionalCharacter(asciiColon)
    }

    internal func skipOptionalEndArray() -> Bool {
        return skipOptionalCharacter(asciiCloseSquareBracket)
    }

    internal func skipOptionalBeginArray() -> Bool {
        return skipOptionalCharacter(asciiOpenSquareBracket)
    }

    internal func skipOptionalObjectEnd(_ c: UInt8) -> Bool {
        return skipOptionalCharacter(c)
    }

    internal func skipOptionalSeparator() {
        skipWhitespace()
        if index != utf8.endIndex {
            let c = utf8[index]
            if c == asciiComma || c == asciiSemicolon { // comma or semicolon
                index = utf8.index(after: index)
            }
        }
    }

    /// Returns the character that should end this field.
    /// E.g., if object starts with "{", returns "}"
    internal func skipObjectStart() throws -> UInt8 {
        skipWhitespace()
        if index != utf8.endIndex {
            let c = utf8[index]
            index = utf8.index(after: index)
            switch c {
            case asciiOpenCurlyBracket: // {
                return asciiCloseCurlyBracket // }
            case asciiOpenAngleBracket: // <
                return asciiCloseAngleBracket // >
            default:
                break
            }
        }
        throw TextDecodingError.malformedText
    }
}
