// Sources/SwiftProtobuf/TextFormatEncodingOptions.swift - Text format encoding options
//
// Copyright (c) 2014 - 2019 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
//
// Text format encoding options
//
// -----------------------------------------------------------------------------

/// Options for TextFormatEncoding.
public struct TextFormatEncodingOptions: Sendable {

    /// Default: Do print unknown fields using numeric notation
    public var printUnknownFields: Bool = true

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
    public var useDeterministicOrdering: Bool = true

    public init() {}
}
