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
public struct TextFormatDecodingOptions: Sendable {
    /// The maximum nesting of message with messages.  The default is 100.
    ///
    /// To prevent corrupt or malicious messages from causing stack overflows,
    /// this controls how deep messages can be nested within other messages
    /// while parsing.
    public var messageDepthLimit: Int = 100

    /// If unknown fields in the TextFormat should be ignored. If they aren't
    /// ignored, an error will be raised if one is encountered.
    ///
    /// Note: This is a lossy option, enabling it means part of the TextFormat
    /// is silently skipped.
    public var ignoreUnknownFields: Bool = false

    /// If unknown extension fields in the TextFormat should be ignored. If they
    /// aren't ignored, an error will be raised if one is encountered.
    ///
    /// Note: This is a lossy option, enabling it means part of the TextFormat
    /// is silently skipped.
    public var ignoreUnknownExtensionFields: Bool = false

    public init() {}
}
