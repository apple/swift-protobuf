// Sources/SwiftProtobuf/Message.swift - Message support
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Internal helpers on Messages for the library. These are public
/// just so the generated code can call them, but shouldn't be called
/// by developers directly.
///
// -----------------------------------------------------------------------------


import Foundation
import Swift

public struct Internal {
  private init() {}

  public static func areAllInitialized(_ listOfMessages: [Message]) -> Bool {
    for msg in listOfMessages {
      if !msg.isInitialized {
        return false
      }
    }
    return true
  }

  public static func areAllInitialized<K: Hashable>(_ mapToMessages: [K: Message]) -> Bool {
    for (_, msg) in mapToMessages {
      if !msg.isInitialized {
        return false
      }
    }
    return true
  }

}
