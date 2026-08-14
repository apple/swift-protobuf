// Sources/SwiftProtobuf/TextFormatDecodingOptions.swift - Text format decoding options
//
// Copyright (c) 2014 - 2021 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
//
// Text format decoding options
//
// -----------------------------------------------------------------------------

/// Options for TextFormatDecoding.
public struct TextFormatDecodingOptions: Sendable {
    /// The maximum nesting of messages within messages.
    ///
    /// The default is 100. To prevent corrupt or malicious messages from causing
    /// stack overflows, this controls how deeply the parser allows messages to
    /// nest within other messages.
    public var messageDepthLimit: Int = 100

    /// Whether the decoder ignores unknown fields in the text format.
    ///
    /// If it doesn't ignore them, it raises an error when it encounters one.
    ///
    /// Note: This is a lossy option, enabling it means the decoder silently
    /// skips part of the TextFormat.
    public var ignoreUnknownFields: Bool = false

    /// Whether the decoder ignores unknown extension fields in the text format.
    ///
    /// If it doesn't ignore them, it raises an error when it encounters one.
    ///
    /// Note: This is a lossy option, enabling it means the decoder silently
    /// skips part of the TextFormat.
    public var ignoreUnknownExtensionFields: Bool = false

    public init() {}
}
