// Sources/SwiftProtobuf/BinaryDecodingOptions.swift - Binary decoding options
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Binary decoding options
///
// -----------------------------------------------------------------------------

/// Options for JSONDecoding.
public struct BinaryDecodingOptions {
  /// The maximum nesting of message with messages.  The default is 100.
  ///
  /// To prevent corrupt or malicious messages from causing stack overflows,
  /// this controls how deep messages can be nested within other messages
  /// while parsing.
  public var messageDepthLimit: Int = 100

  public init() {}
}
