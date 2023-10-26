// Sources/SwiftProtobuf/JSONEncodingOptions.swift - JSON encoding options
//
// Copyright (c) 2014 - 2018 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// JSON encoding options
///
// -----------------------------------------------------------------------------

/// Options for JSONEncoding.
public struct JSONEncodingOptions {

  /// Always print enums as ints. By default they are printed as strings.
  public var alwaysPrintEnumsAsInts: Bool = false

  /// Whether to preserve proto field names.
  /// By default they are converted to JSON(lowerCamelCase) names.
  public var preserveProtoFieldNames: Bool = false

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
  /// by keys in lexographical order. This is an implementation detail
  /// and subject to change.
  public var useDeterministicOrdering: Bool = false

  public init() {}
}
