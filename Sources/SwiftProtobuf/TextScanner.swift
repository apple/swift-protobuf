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

private func fromHexDigit(_ c: Character) -> UInt8? {
  switch c {
  case "0": return 0
  case "1": return 1
  case "2": return 2
  case "3": return 3
  case "4": return 4
  case "5": return 5
  case "6": return 6
  case "7": return 7
  case "8": return 8
  case "9": return 9
  case "a", "A": return 10
  case "b", "B": return 11
  case "c", "C": return 12
  case "d", "D": return 13
  case "e", "E": return 14
  case "f", "F": return 15
  default: return nil
  }
}

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

// Protobuf Text encoding assumes that you're working directly
// in UTF-8.  So this implementation converts the string to UTF8,
// then decodes it into a sequence of bytes, then converts
// it back into a string.
private func decodeString(_ s: String) -> String? {
  var out = [UInt8]()
  var bytes = s.utf8.makeIterator()
  while let byte = bytes.next() {
    switch byte {
    case 92: // backslash
      if let escaped = bytes.next() {
        switch escaped {
        case 48...55:
          // C standard allows 1, 2, or 3 octal digits.
          let savedPosition = bytes
          if let digit2 = bytes.next(),
            digit2 >= 48 && digit2 <= 55 {
            let digit2Value = digit2 - 48
            let innerSavedPosition = bytes
            if let digit3 = bytes.next(),
              digit3 >= 48 && digit3 <= 55 {
              let digit3Value = digit3 - 48
              let n = (escaped - 48) * 64 + digit2Value * 8 + digit3Value
              out.append(n)
            } else {
              let n = (escaped - 48) * 8 + digit2Value
              out.append(n)
              bytes = innerSavedPosition
            }
          } else {
            let n = escaped - 48
            out.append(n)
            bytes = savedPosition
          }
        case 120: // "x"
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
          out.append(7)
        case 98: // \b
          out.append(8)
        case 102: // \f
          out.append(12)
        case 110: // \n
          out.append(10)
        case 114: // \r
          out.append(13)
        case 116: // \t
          out.append(9)
        case 118: // \v
          out.append(11)
        case 34, 39, 63, 92: // " ' ? \
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
  out.append(0)
  return out.withUnsafeBufferPointer { ptr in
    if let addr = ptr.baseAddress {
      return addr.withMemoryRebound(to: CChar.self, capacity: ptr.count) { p in
        let q = UnsafePointer<CChar>(p)
        let s = String(validatingUTF8: q)
        return s
      }
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
    private var eof: Bool = false
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
        var lastIndex = index
        while index != utf8.endIndex {
            let u = utf8[index]
            switch u {
            case 32, 9, 10, 13: // space, tab, NL, CR
                index = utf8.index(after: index)
                lastIndex = index
            case 35: // #
                while index != utf8.endIndex {
                    // Skip until end of line
                    let c = utf8[index]
                    index = utf8.index(after: index)
                    if c == 10 || c == 13 {
                        break
                    }
                }
            default:
                index = lastIndex
                return
            }
        }
    }

    private func parseIdentifier() -> String? {
        let start = index
        while index != utf8.endIndex {
            let c = utf8[index]
            switch c {
            case 97...122, 65...90, 48...57, 95:
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
    private func parseExtensionIdentifier() -> String? {
        let start = index
        if index == utf8.endIndex {
            return nil
        }
        let c = utf8[index]
        switch c {
        case 97...122, 65...90:
            index = utf8.index(after: index)
        default:
            return nil
        }
        while index != utf8.endIndex {
            let c = utf8[index]
            switch c {
            case 97...122, 65...90, 48...57, 95, 46, 47:
                index = utf8.index(after: index)
            case 93: // ]
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
            if c == 92 { //  \
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
            if c == 92 { //  \
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
            throw DecodingError.malformedTextNumber
        }
        let c = utf8[index]
        index = utf8.index(after: index)
        if c == 48 { // leading '0' precedes octal or hex
            if utf8[index] == 120 { // 'x' => hex
                index = utf8.index(after: index)
                var n: UInt64 = 0
                while index != utf8.endIndex {
                    let digit = utf8[index]
                    let val: UInt64
                    switch digit {
                    case 48...57: // 0...9
                        val = UInt64(digit - 48)
                    case 97...102: // a...f
                        val = UInt64(digit - 87)
                    case 65...70:
                        val = UInt64(digit - 55)
                    case 117: // trailing 'u'
                        index = utf8.index(after: index)
                        return n
                    default:
                        return n
                    }
                    if n > UInt64.max / 16 {
                        throw DecodingError.malformedTextNumber
                    }
                    index = utf8.index(after: index)
                    n = n * 16 + val
                }
                return n
            } else { // octal
                var n: UInt64 = 0
                while index != utf8.endIndex {
                    let digit = utf8[index]
                    if digit == 117 { // trailing 'u'
                        index = utf8.index(after: index)
                        return n
                    }
                    if digit < 48 || digit > 55 { // not octal digit
                        return n
                    }
                    let val = UInt64(digit - 48)
                    if n > UInt64.max / 8 {
                        throw DecodingError.malformedTextNumber
                    }
                    index = utf8.index(after: index)
                    n = n * 8 + val
                }
                return n
            }
        } else if c > 48 && c <= 57 { // 1...9
            var n = UInt64(c - 48)
            while index != utf8.endIndex {
                let digit = utf8[index]
                if digit == 117 { // trailing 'u'
                    index = utf8.index(after: index)
                    return n
                }
                if digit < 48 || digit > 57 { // next character not a digit
                    return n
                }
                let val = UInt64(digit - 48)
                if n >= UInt64.max / 10 {
                    if n > UInt64.max / 10 || val > UInt64.max % 10 {
                        throw DecodingError.malformedTextNumber
                    }
                }
                index = utf8.index(after: index)
                n = n * 10 + val
            }
            return n
        }
        throw DecodingError.malformedTextNumber
    }

    internal func nextSInt() throws -> Int64 {
        skipWhitespace()
        if index == utf8.endIndex {
            throw DecodingError.malformedTextNumber
        }
        let c = utf8[index]
        if c == 45 { // -
            index = utf8.index(after: index)
            // character after '-' must be digit
            let digit = utf8[index]
            if digit < 48 || digit > 57 {
                throw DecodingError.malformedTextNumber
            }
            let n = try nextUInt()
            if n >= 0x8000000000000000 { // -Int64.min
                if n > 0x8000000000000000 {
                    // Too large negative number
                    throw DecodingError.malformedTextNumber
                } else {
                    return Int64.min // Special case for Int64.min
                }
            }
            return -Int64(bitPattern: n)
        } else {
            let n = try nextUInt()
            if n > UInt64(bitPattern: Int64.max) {
                throw DecodingError.malformedTextNumber
            }
            return Int64(bitPattern: n)
        }
    }

    internal func nextStringValue() throws -> String {
        var result: String
        skipWhitespace()
        if index == utf8.endIndex {
            throw DecodingError.malformedText
        }
        let c = utf8[index]
        if c != 39 && c != 34 {
            throw DecodingError.malformedText
        }
        index = utf8.index(after: index)
        if let s = parseStringSegment(terminator: c) {
            result = s
        } else {
            throw DecodingError.malformedText
        }

        while true {
            skipWhitespace()
            if index == utf8.endIndex {
                return result
            }
            let c = utf8[index]
            if c != 39 && c != 34 {
                return result
            }
            index = utf8.index(after: index)
            if let s = parseStringSegment(terminator: c) {
                result.append(s)
            } else {
                throw DecodingError.malformedText
            }
        }
    }

    internal func nextBytesValue() throws -> Data {
        var result: Data
        skipWhitespace()
        if index == utf8.endIndex {
            throw DecodingError.malformedText
        }
        let c = utf8[index]
        if c != 39 && c != 34 {
            throw DecodingError.malformedText
        }
        index = utf8.index(after: index)
        if let s = parseQuotedString(terminator: c), let b = decodeBytes(s) {
            result = b
        } else {
            throw DecodingError.malformedText
        }

        while true {
            skipWhitespace()
            if index == utf8.endIndex {
                return result
            }
            let c = utf8[index]
            if c != 39 && c != 34 {
                return result
            }
            index = utf8.index(after: index)
            if let s = parseQuotedString(terminator: c), let b = decodeBytes(s) {
                result.append(b)
            } else {
                throw DecodingError.malformedText
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
        if c == 45 {
            index = utf8.index(after: index)
            guard index != utf8.endIndex else {index = start; return nil}
            c = utf8[index]
        }
        switch c {
        case 48: // '0' as first character only if followed by '.'
            index = utf8.index(after: index)
            guard index != utf8.endIndex else {index = start; return nil}
            c = utf8[index]
            if c != 46 {
                index = start
                return nil
            }
        case 46: // '.' as first char only if followed by digit
            index = utf8.index(after: index)
            guard index != utf8.endIndex else {index = start; return nil}
            c = utf8[index]
            if c < 48 || c > 57 {
                index = start
                return nil
            }
        case 49...57:
            break
        default:
            index = start
            return nil
        }
        while index != utf8.endIndex {
            let c = utf8[index]
            switch c {
            case 48...57, 46, 43, 45, 101, 69: // 0...9, ., +, -, e, E
                index = utf8.index(after: index)
            case 102: // f
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
            if c >= 65 && c <= 90 {
                c += 32
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
        if (c >= 65 && c <= 90) || (c >= 97 && c <= 122) {
            index = start
            return false
        }
        return true
    }

    // If the next token is the identifier "nan", return true.
    private func skipOptionalNaN() -> Bool {
        return skipOptionalKeyword(bytes: [110, 97, 110])
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
        if c == 45 {
            negated = true
            index = utf8.index(after: index)
        } else {
            negated = false
        }
        if (skipOptionalKeyword(bytes: [105, 110, 102])
            || skipOptionalKeyword(bytes: [105, 110, 102, 105, 110, 105, 116, 121])) {
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
        throw DecodingError.malformedTextNumber
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
        throw DecodingError.malformedTextNumber
    }

    internal func nextBool() throws -> Bool {
        skipWhitespace()
        if index == utf8.endIndex {
            throw DecodingError.malformedText
        }
        let c = utf8[index]
        switch c {
        case 48: // 0
            index = utf8.index(after: index)
            return false
        case 49: // 1
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
        throw DecodingError.malformedText
    }

    internal func nextOptionalEnumName() throws -> String? {
        skipWhitespace()
        if index == utf8.endIndex {
            throw DecodingError.malformedText
        }
        let c = utf8[index]
        let start = index
        switch c {
        case 97...122, 65...90:
            if let s = parseIdentifier() {
                return s
            }
        default:
            break
        }
        index = start
        return nil
    }

    internal func nextOptionalAnyURL() throws -> String? {
        skipWhitespace()
        if index == utf8.endIndex {
            eof = true
            return nil
        }
        let c = utf8[index]
        if c == 91 { // [
            index = utf8.index(after: index)
            if let s = parseExtensionIdentifier() {
                if index == utf8.endIndex || utf8[index] != 93 {
                    throw DecodingError.malformedText
                }
                // Skip ]
                index = utf8.index(after: index)
                return s
            } else {
                throw DecodingError.malformedText
            }
        } else {
            return nil
        }
    }

    /// Returns next key
    /// Note:  This treats [abc] as a single "extension identifier"
    /// token, consistent with Text format key handling.
    internal func nextKey() throws -> TextToken? {
        skipWhitespace()
        if index == utf8.endIndex {
            eof = true
            return nil
        }
        let c = utf8[index]
        switch c {
        case 91: // [
            index = utf8.index(after: index)
            if let s = parseExtensionIdentifier() {
                if index == utf8.endIndex || utf8[index] != 93 {
                    throw DecodingError.malformedText
                }
                // Skip ]
                index = utf8.index(after: index)
                return .extensionIdentifier(s)
            } else {
                print("Error parsing extension identifier")
                throw DecodingError.malformedText
            }
        case 97...122, 65...90: // a...z, A...Z
            if let s = parseIdentifier() {
                return .identifier(s)
            } else {
                throw DecodingError.malformedText
            }
        default:
            throw DecodingError.malformedText
        }
    }

    private func skipRequiredCharacter(_ c: UInt8) throws {
        skipWhitespace()
        if index != utf8.endIndex && utf8[index] == c {
            index = utf8.index(after: index)
        } else {
            throw DecodingError.malformedText
        }
    }

    internal func skipRequiredComma() throws {
        try skipRequiredCharacter(44)
    }

    internal func skipRequiredColon() throws {
        try skipRequiredCharacter(58)
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
        return skipOptionalCharacter(58)
    }

    internal func skipOptionalEndArray() -> Bool {
        return skipOptionalCharacter(93)
    }

    internal func skipOptionalBeginArray() -> Bool {
        return skipOptionalCharacter(91)
    }

    internal func skipOptionalObjectEnd(_ c: UInt8) -> Bool {
        return skipOptionalCharacter(c)
    }

    internal func skipOptionalSeparator() {
        skipWhitespace()
        if index != utf8.endIndex {
            let c = utf8[index]
            if c == 44 || c == 59 { // comma or semicolon
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
            case 123: // {
                return 125 // }
            case 60: // <
                return 62 // >
            default:
                break
            }
        }
        throw DecodingError.malformedText
    }
}
