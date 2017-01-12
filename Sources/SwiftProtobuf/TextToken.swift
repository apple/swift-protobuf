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


public enum TextToken: Equatable, FieldDecoder {
  case identifier(String)
  case extensionIdentifier(String)

  public static func ==(lhs: TextToken, rhs: TextToken) -> Bool {
    switch (lhs, rhs) {
    case (.identifier(let a), .identifier(let b)):
      return a == b
    case (.extensionIdentifier(let a), .extensionIdentifier(let b)):
      return a == b
    default:
      return false
    }
  }

/*
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
*/
}
