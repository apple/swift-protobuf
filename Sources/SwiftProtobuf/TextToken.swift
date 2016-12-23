// Sources/SwiftProtobuf/TextToken.swift - Text format decoding
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


private func fromOctalDigit(_ c: Character) -> UInt8? {
  switch c {
  case "0": return 0
  case "1": return 1
  case "2": return 2
  case "3": return 3
  case "4": return 4
  case "5": return 5
  case "6": return 6
  case "7": return 7
  default: return nil
  }
}

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


public enum TextToken: Equatable, FieldDecoder {
  case colon
  case semicolon
  case comma
  case beginObject
  case endObject
  case altBeginObject
  case altEndObject
  case beginArray
  case endArray
  case string(String)
  case identifier(String)
  case octalInteger(String)
  case hexadecimalInteger(String)
  case decimalInteger(String)
  case floatingPointLiteral(String)

  public static func ==(lhs: TextToken, rhs: TextToken) -> Bool {
    switch (lhs, rhs) {
    case (.colon, .colon),
         (.semicolon, .semicolon),
         (.comma, .comma),
         (.beginObject, .beginObject),
         (.endObject, .endObject),
         (.altBeginObject, .altBeginObject),
         (.altEndObject, .altEndObject),
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
  //
  // Hmmmm.... Actually, Text decoder does not skip and ignore
  // unknown fields, so maybe we never need this?
  var isValid: Bool {
    // TODO: Implement this
    return true
  }

  var asInt64: Int64? {
    switch self {
    case .decimalInteger(let n):
      return Int64(n)
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
      return Int32(n)
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
      return UInt64(n)
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
      return UInt32(n)
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
    case .identifier(let s):
      let l = s.lowercased()
      switch l {
      case "inf": return Float.infinity
      case "infinity": return Float.infinity
      case "nan": return Float.nan
      default: return nil
      }
    case .decimalInteger(let n):
      return Float(n)
    case .floatingPointLiteral(let n):
      // There is special logic in the scanner to parse
      // "-" followed by identifier as a single floatingPointLiteral
      let l = n.lowercased()
      switch l {
      case "-inf": return -Float.infinity
      case "-infinity": return -Float.infinity
      default: return Float(n)
      }
    default: return nil
    }
  }

  var asDouble: Double? {
    switch self {
    case .identifier(let s):
      let l = s.lowercased()
      switch l {
      case "inf": return Double.infinity
      case "infinity": return Double.infinity
      case "nan": return Double.nan
      default: return nil
      }
    case .decimalInteger(let n):
      return Double(n)
    case .floatingPointLiteral(let n):
      // There is special logic in the scanner to parse
      // "-" followed by identifier as a single floatingPointLiteral
      let l = n.lowercased()
      switch l {
      case "-inf": return -Double.infinity
      case "-infinity": return -Double.infinity
      default: return Double(n)
      }
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
