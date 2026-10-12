// Sources/SwiftProtobuf/BinaryDecodingOptions.swift - Binary decoding options
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
//
// Binary decoding options
//
// -----------------------------------------------------------------------------

/// Options for binary decoding.
public struct BinaryDecodingOptions: Sendable {
    /// The maximum nesting of messages within messages.
    ///
    /// The default is 100. To prevent corrupt or malicious messages from causing
    /// stack overflows, this controls how deeply the decoder nests messages
    /// within other messages while parsing.
    public var messageDepthLimit: Int = 100

    /// Discard unknown fields while parsing.
    ///
    /// The default is false, so parsing does not discard unknown fields.
    ///
    /// The Protobuf binary format lets parsers still parse unknown fields so
    /// publishers can expand the schema without requiring all readers to
    /// update. This works in part because the decoder preserves any unknown
    /// fields so it can relay them on without loss. For a while the proto3
    /// syntax definition called for readers to drop unknown fields, but that
    /// lead to problems in some case. The default is to follow the spec and
    /// keep them, but setting this option to `true` allows a developer to
    /// strip them during a parse in case they have a specific need to drop
    /// the unknown fields from the object graph they're creating.
    public var discardUnknownFields: Bool = false

    /// Creates a default set of options for binary decoding.
    public init() {}
}
