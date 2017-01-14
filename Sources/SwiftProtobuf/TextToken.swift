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
}
