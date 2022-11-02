// Sources/SwiftProtobuf/TextFormatDecodingOptions.swift - Text format decoding options
//
// Copyright (c) 2014 - 2021 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Text format decoding options
///
// -----------------------------------------------------------------------------

/// Options for TextFormatDecoding.
public struct TextFormatDecodingOptions {
  /// The maximum nesting of message with messages.  The default is 100.
  ///
  /// To prevent corrupt or malicious messages from causing stack overflows,
  /// this controls how deep messages can be nested within other messages
  /// while parsing.
  public var messageDepthLimit: Int = 100

  public init() {}
}
