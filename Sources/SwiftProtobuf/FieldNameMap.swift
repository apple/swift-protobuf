// Sources/SwiftProtobuf/FieldNameMap.swift - Bidirectional field number/name mapping
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------

/// An immutable bidirectional mapping between field names and numbers, used
/// for various text-based serialization (JSON and text).
public struct FieldNameMap: ExpressibleByDictionaryLiteral {

  /// A "bundle" of names for a particular field. We use different "packed"
  /// representations to minimize the amount of string data that we store in the
  /// binary.
  ///
  /// TODO: Remove the Swift field name since it's only used for debugging
  /// purposes and use the proto name instead at those usage sites.
  public enum Names {

    /// The proto name and the JSON name are the same string
    case same(proto: String, swift: String)

    /// The JSON and text names are different and not derivable from each other.
    case unique(proto: String, json: String, swift: String)

    // TODO: Add a case for JSON names that are computable from the proto name
    // using the same algorithm implemented by protoc; for example,
    // "foo_bar" -> "fooBar". This allows us to only store the string pointer
    // in the payload once.

    /// Returns the proto (and text format) name in the bundle.
    public var protoName: String {
      switch self {
      case .same(proto: let name, swift: _): return name
      case .unique(proto: let name, json: _, swift: _): return name
      }
    }

    /// Returns the JSON name in the bundle.
    public var jsonName: String {
      switch self {
      case .same(proto: let name, swift: _): return name
      case .unique(proto: _, json: let name, swift: _): return name
      }
    }

    /// Returns the Swift property name in the bundle.
    public var swiftName: String {
      switch self {
      case .same(proto: _, swift: let name): return name
      case .unique(proto: _, json: _, swift: let name): return name
      }
    }
  }

  /// The mapping from field numbers to name bundles.
  private var numberToNameMap: [Int: Names] = [:]

  /// The mapping from proto/text names to field numbers.
  private var protoToNumberMap: [String: Int] = [:]

  /// The mapping from JSON names to field numbers.
  private var jsonToNumberMap: [String: Int] = [:]

  /// Creates a new empty field name/number mapping.
  public init() {}

  /// Creates a new bidirectional field name/number mapping from the dictionary
  /// literal.
  public init(dictionaryLiteral elements: (Int, Names)...) {
    for (number, name) in elements {
      numberToNameMap[number] = name
      protoToNumberMap[name.protoName] = number
    }
    // JSON map includes proto names as well.
    jsonToNumberMap = protoToNumberMap
    for (number, name) in elements {
      jsonToNumberMap[name.jsonName] = number
    }
  }

  /// Returns the name bundle for the field with the given number, or `nil` if
  /// there is no match.
  public func fieldNames(for number: Int) -> Names? {
    return numberToNameMap[number]
  }

  /// Returns the field number that has the given proto/text name, or `nil` if
  /// there is no match.
  public func fieldNumber(forProtoName name: String) -> Int? {
    return protoToNumberMap[name]
  }

  /// Returns the field number that has the given JSON name, or `nil` if there
  /// is no match.
  ///
  /// JSON parsing must interpret *both* the JSON name of the field provided by
  /// the descriptor *as well as* its original proto/text name. Because of this,
  /// this function checks both mappings -- first the JSON mapping, then the
  /// proto mapping.
  public func fieldNumber(forJSONName name: String) -> Int? {
    return jsonToNumberMap[name]
  }
}
