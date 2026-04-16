// Sources/SwiftProtobuf/TextFormatEncodingOptions.swift - Text format encoding options
//
// Copyright (c) 2014 - 2019 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Text format encoding options
///
// -----------------------------------------------------------------------------

/// Options for TextFormatEncoding.
public struct TextFormatEncodingOptions: Sendable {

    /// Default: Do print unknown fields using numeric notation
    public var printUnknownFields: Bool = true

    /// The extension map to use when encoding messages that have been packed in a
    /// `google.protobuf.Any` message.
    ///
    /// The in-memory representation of a `google.protobuf.Any` message stores the
    /// packed message as its binary wire encoding. text format serialization
    /// requires parsing that packed message data in order to re-encode it, because
    /// unlike regular messages where the information about stored extensions is
    /// already in memory, parsing the binary data requires the extension map.
    public var extensions: ExtensionMap? = nil

    public init() {}
}
