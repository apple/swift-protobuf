// Sources/SwiftProtobuf/JSONDecodingOptions.swift - JSON decoding options
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
//
// JSON decoding options
//
// -----------------------------------------------------------------------------

/// Options for JSONDecoding.
public struct JSONDecodingOptions: Sendable {
    /// The maximum nesting of messages within messages.
    ///
    /// The default is 100. To prevent corrupt or malicious messages from causing
    /// stack overflows, this controls how deeply the decoder can nest messages
    /// within other messages while parsing.
    public var messageDepthLimit: Int = 100

    /// If the decoder should ignore unknown fields in the JSON.
    ///
    /// If it doesn't ignore them, it raises an error when it encounters one.
    /// This also causes it to silently ignore unknown enum values
    /// (especially string values).
    public var ignoreUnknownFields: Bool = false

    public init() {}
}
