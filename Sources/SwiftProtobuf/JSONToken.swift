// Sources/SwiftProtobuf/JSONToken.swift - JSON decoding
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// JSONToken represents a single lexical token in a JSON
/// stream.
///
// -----------------------------------------------------------------------------

import Foundation


/// Returns a `Data` value containing bytes equivalent to the given
/// Base64-encoded string, or nil if the conversion fails.
private func decodedBytes(base64String s: String) -> Data? {
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

/// A token scanned from string input using `JSONDecoder`.
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
  case number(Number)

  /// A `number` token can be represented as either a double, a signed integer
  /// (which is always negative due to the scanning logic used), or an unsigned
  /// integer. The type is determined at scanning type based on the appearance
  /// of the literal; conversion from these types to actual field types occurs
  /// later in the decoder.
  public enum Number: Equatable {
    case double(Double)
    case int(Int64)
    case uint(UInt64)

    public static func ==(lhs: Number, rhs: Number) -> Bool {
      switch (lhs, rhs) {
      case (.double(let lhsValue), .double(let rhsValue)):
        return lhsValue == rhsValue
      case (.int(let lhsValue), .int(let rhsValue)):
        return lhsValue == rhsValue
      case (.uint(let lhsValue), .uint(let rhsValue)):
        return lhsValue == rhsValue
      default:
        return false
      }
    }

    /// Returns the receiver's value as the given integer type if the conversion
    /// can be made safely and exactly; otherwise, it returns nil.
    fileprivate func exactValue<
      T: JSONIntegerConverting
    >(as type: T.Type) -> T? {
      switch self {
      case .double(let value):
        return type.init(safely: value)
      case .int(let value):
        return type.init(exactly: value)
      case .uint(let value):
        return type.init(exactly: value)
      }
    }

    /// The single-precision floating point value of the receiver if the
    /// conversion can be made exactly; otherwise, nil.
    fileprivate var floatValue: Float? {
      switch self {
      case .double(let value):
        // We can't use Float(exactly:) here because that would require that the
        // scanned Double value be representable as a Float without loss of
        // precision; this is too strict because Javascript and JSON treat all
        // numbers as double-precision which could produce rounding/tolerance
        // errors in some cases. Instead, we just ensure that the number's
        // magnitude is within the allowable range for Floats and let precision
        // loss happen silently.
        let floatMax = Double(Float.greatestFiniteMagnitude)
        if -floatMax <= value && value <= floatMax {
          return Float(value)
        }
        return nil
      case .int(let value):
        let float = Float(value)
        if Int64(float) == value {
          return float
        }
        return nil
      case .uint(let value):
        let float = Float(value)
        if UInt64(float) == value {
          return float
        }
        return nil
      }
    }

    /// The double-precision floating point value of the receiver if the
    /// conversion can be made exactly; otherwise, nil.
    fileprivate var doubleValue: Double? {
      switch self {
      case .double(let value):
        return value
      case .int(let value):
        let double = Double(value)
        if Int64(double) == value {
          return double
        }
        return nil
      case .uint(let value):
        let double = Double(value)
        if UInt64(double) == value {
          return double
        }
        return nil
      }
    }
  }

  public static func ==(lhs: JSONToken, rhs: JSONToken) -> Bool {
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

  public var asBoolean: Bool? {
    if case .boolean(let b) = self {
      return b
    }
    return nil
  }

  public var asBooleanMapKey: Bool? {
    switch self {
    case .string("true"): return true
    case .string("false"): return false
    default: return nil
    }
  }

  var asInt64: Int64? {
    switch self {
    case .string(let s): return validatedIntegerValue(of: s, as: Int64.self)
    case .number(let n): return n.exactValue(as: Int64.self)
    default: return nil
    }
  }

  var asInt32: Int32? {
    switch self {
    case .string(let s): return validatedIntegerValue(of: s, as: Int32.self)
    case .number(let n): return n.exactValue(as: Int32.self)
    default: return nil
    }
  }

  var asUInt64: UInt64? {
    switch self {
    case .string(let s): return validatedIntegerValue(of: s, as: UInt64.self)
    case .number(let n): return n.exactValue(as: UInt64.self)
    default: return nil
    }
  }

  var asUInt32: UInt32? {
    switch self {
    case .string(let s): return validatedIntegerValue(of: s, as: UInt32.self)
    case .number(let n): return n.exactValue(as: UInt32.self)
    default: return nil
    }
  }

  var asFloat: Float? {
    switch self {
    case .string(let s): return Float(s)
    case .number(let n): return n.floatValue
    default: return nil
    }
  }

  var asDouble: Double? {
    switch self {
    case .string(let s): return Double(s)
    case .number(let n): return n.doubleValue
    default: return nil
    }
  }

  var asBytes: Data? {
    if case .string(let s) = self {
      return decodedBytes(base64String: s)
    }
    return nil
  }
}

/// Returns the integer corresponding to the given JSON string token, or nil if
/// the string does not represent a valid JSON integer literal according to the
/// protobuf spec.
///
/// It is necessary for this validation to occur here since string literals are
/// not validated during scanning like numeric literals are (because there is no
/// context to determine if the string is destined for a numeric field or not).
fileprivate func validatedIntegerValue<T: JSONIntegerConverting>(
  of text: String,
  as type: T.Type
) -> T? {
  let scalars = text.unicodeScalars
  let count = scalars.count
  let startIndex = scalars.startIndex

  // If the string is empty, return nil.
  if count == 0 {
    return nil
  }

  if scalars[startIndex] == "-" {
    // For an integer with a leading minus sign, zero is never allowed to follow
    // it.
    let secondIndex = scalars.index(after: startIndex)
    if count == 1 || count > 2 && scalars[secondIndex] == "0" {
      return nil
    }
    return T.init(text, radix: 10)
  }

  // For a non-negative integer, the only time a zero is allowed in the leading
  // position is if it is the only digit.
  if count > 1 && scalars[startIndex] == "0" {
    return nil
  }
  return T.init(text, radix: 10)
}
