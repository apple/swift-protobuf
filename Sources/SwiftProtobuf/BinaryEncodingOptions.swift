// Sources/SwiftProtobuf/BinaryEncodingOptions.swift - Binary encoding options
//
// Copyright (c) 2014 - 2023 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Binary encoding options
///
// -----------------------------------------------------------------------------

/// Options for binary encoding.
public struct BinaryEncodingOptions: Sendable {
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
    public var useDeterministicOrdering: Bool = false

    public init() {}
}
