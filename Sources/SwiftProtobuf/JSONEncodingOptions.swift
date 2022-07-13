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

  /// Always prints int64s values as numbers.
  /// By default, they are printed as strings as per proto3 JSON mapping rules.
  /// NB: When used as Map keys, int64s will be printed as strings as expected.
  public var alwaysPrintInt64sAsNumbers: Bool = false

  /// Always print enums as ints. By default they are printed as strings.
  public var alwaysPrintEnumsAsInts: Bool = false

  /// Whether to preserve proto field names.
  /// By default they are converted to JSON(lowerCamelCase) names.
  public var preserveProtoFieldNames: Bool = false

  public init() {}
}
