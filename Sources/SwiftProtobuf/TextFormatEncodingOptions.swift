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
    public var printUnknownFields: Bool

    /// Whether to use deterministic ordering when serializing.
    ///
    /// Note that the deterministic serialization is NOT canonical across languages.
    /// It is NOT guaranteed to remain stable over time. It is unstable across
    /// different builds with schema changes due to unknown fields. Users who need
    /// canonical serialization (e.g., persistent storage in a canonical form,
    /// fingerprinting, etc.) should define their own canonicalization specification
    /// and implement their own serializer rather than relying on this API.
    ///
    /// If deterministic serialization is requested, map entries will be sorted
    /// by keys in lexicographical order. This is an implementation detail
    /// and subject to change.
    ///
    /// Default: `true` (to adhere to Protocol Buffers TextFormat specification
    /// and conformance requirements for sorted map keys).
    public var useDeterministicOrdering: Bool

    /// The extension map to use when encoding messages that have been packed in a
    /// `google.protobuf.Any` message.
    ///
    /// The in-memory representation of a `google.protobuf.Any` message stores the
    /// packed message as its binary wire encoding. text format serialization
    /// requires parsing that packed message data in order to re-encode it, because
    /// unlike regular messages where the information about stored extensions is
    /// already in memory, parsing the binary data requires the extension map.
    public var extensions: Optional<any ExtensionMap>

    public init() {
        self.printUnknownFields = true
        self.useDeterministicOrdering = true
        self.extensions = nil
    }
}
