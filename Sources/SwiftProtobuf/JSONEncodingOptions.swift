// Sources/SwiftProtobuf/JSONEncodingOptions.swift - JSON encoding options
//
// Copyright (c) 2014 - 2018 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
//
// JSON encoding options
//
// -----------------------------------------------------------------------------

/// Options for JSONEncoding.
public struct JSONEncodingOptions: Sendable {

    /// Always prints int64s values as numbers.
    ///
    /// By default, the encoder prints them as strings, per proto3 JSON
    /// mapping rules. When int64s serve as map keys, the encoder prints
    /// them as strings regardless of this option.
    public var alwaysPrintInt64sAsNumbers: Bool = false

    /// Always print enums as ints.
    ///
    /// By default, the encoder prints enums as strings.
    public var alwaysPrintEnumsAsInts: Bool = false

    /// Whether to preserve proto field names.
    ///
    /// By default, the encoder converts field names to JSON lowerCamelCase
    /// names.
    public var preserveProtoFieldNames: Bool = false

    /// Whether to use deterministic ordering when serializing.
    ///
    /// Note that the deterministic serialization is NOT canonical across languages.
    /// This library does NOT guarantee it will remain stable over time. It is
    /// unstable across different builds with schema changes due to unknown
    /// fields. Users who need canonical serialization (e.g., persistent
    /// storage in a canonical form, fingerprinting, etc.) should define their
    /// own canonicalization specification and implement their own serializer
    /// rather than relying on this API.
    ///
    /// If you request deterministic serialization, the encoder sorts map
    /// entries by key in lexicographical order. This is an implementation
    /// detail and subject to change.
    public var useDeterministicOrdering: Bool = false

    public init() {}
}
