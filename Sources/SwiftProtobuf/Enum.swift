// Sources/SwiftProtobuf/Enum.swift - Enum support
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Generated enums conform to SwiftProtobuf.Enum
///
/// See ProtobufTypes and JSONTypes for extension
/// methods to support binary and JSON coding.
///
// -----------------------------------------------------------------------------

/// Generated enum types conform to this protocol, which provides the
/// hashability requirement for enums as well as the name mapping requirement
/// for encoding/decoding text-based formats.
public protocol Enum: RawRepresentable, Hashable {
  init()

  init?(rawValue: Int)

  var rawValue: Int { get }
}

extension Enum {

  /// Default implementation.
  public var hashValue: Int {
    return rawValue
  }

  /// Internal convenience property representing the name of the enum value (or
  /// `nil` if it is an `UNRECOGNIZED` value or doesn't provide names).
  ///
  /// Since the text format and JSON names are always identical, we don't need
  /// to distinguish them.
  internal var name: _NameMap.Name? {
    guard let nameProviding = self as? _ProtoNameProviding else {
      return nil
    }
    return nameProviding._protobuf_names(for: rawValue)?.proto
  }

  /// Internal convenience initializer that returns the enum value with the
  /// given name, if it provides names.
  ///
  /// Since the text format and JSON names are always identical, we don't need
  /// to distinguish them.
  ///
  /// - Parameter name: The name of the enum case.
  internal init?(name: String) {
    guard let nameProviding = Self.self as? _ProtoNameProviding.Type,
      let number = nameProviding._protobuf_nameMap.number(forJSONName: name) else {
      return nil
    }
    self.init(rawValue: number)
  }
}
