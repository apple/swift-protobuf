// Sources/SwiftProtobuf/FieldNameMap.swift - Bidirectional field number/name mapping
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------

/// Proto field names are always ASCII, so we can improve the
/// performance of some of our parsing by storing them as
/// arrays of UInt8 to avoid the overhead of creating and
/// comparing Unicode Strings.


// A simple byte wrapper than can hold (and hash/compare)
// either a [UInt8] or a pointer/count to bytes in memory.
// The .array([UInt8]) version is stored in the jsonToNumberMap;
// the .mem(UBP<UInt8>) is the form the JSON parser gives us
// for lookup.

// Constants for FNV hash http://tools.ietf.org/html/draft-eastlake-fnv-03
private let i_2166136261 = Int(bitPattern: 2166136261)
private let i_16777619 = Int(16777619)

private struct AsciiName: Hashable {
    private let value: UnsafeBufferPointer<UInt8>

    init(buffer: UnsafeBufferPointer<UInt8>) {
        value = buffer
    }

    init(bytes: UnsafePointer<UInt8>, count: Int) {
        value = UnsafeBufferPointer<UInt8>(start: bytes, count: count)
    }

    var hashValue: Int {
        var h = i_2166136261
        for byte in value {
            h = (h ^ Int(byte)) &* i_16777619
        }
        return h
    }

    static func ==(lhs: AsciiName, rhs: AsciiName) -> Bool {
      if lhs.value.count != rhs.value.count {
          return false
      }
      return lhs.value.elementsEqual(rhs.value)
    }
}


/// An immutable bidirectional mapping between field names and numbers, used
/// for various text-based serialization (JSON and text).
public struct FieldNameMap: ExpressibleByDictionaryLiteral {

  /// A "bundle" of names for a particular field. We use different "packed"
  /// representations to minimize the amount of string data that we store in the
  /// binary.
  public enum Names {

    /// The proto name and the JSON name are the same string
    case same(proto: StaticString)

    /// The JSON and text names are different and not derivable from each other.
    case unique(proto: StaticString, json: StaticString)

    // TODO: Add a case for JSON names that are computable from the proto name
    // using the same algorithm implemented by protoc; for example,
    // "foo_bar" -> "fooBar". This allows us to only store the string pointer
    // in the payload once.

    /// Returns the proto (and text format) name in the bundle.
    internal var protoStaticStringName: StaticString {
      switch self {
      case .same(proto: let name): return name
      case .unique(proto: let name, json: _): return name
      }
    }

    /// Returns the JSON name in the bundle.
    internal var jsonStaticStringName: StaticString {
      switch self {
      case .same(proto: let name): return name
      case .unique(proto: _, json: let name): return name
      }
    }
  }

  /// The mapping from field numbers to name bundles.
  private var numberToNameMap: [Int: Names] = [:]

  /// The mapping from proto/text names to field numbers.
  private var protoToNumberMap: [AsciiName: Int] = [:]

  /// The mapping from JSON names to field numbers.
  private var jsonToNumberMap: [AsciiName: Int] = [:]

  /// Creates a new empty field name/number mapping.
  public init() {}

  /// Creates a new bidirectional field name/number mapping from the dictionary
  /// literal.
  public init(dictionaryLiteral elements: (Int, Names)...) {
    for (number, name) in elements {
      numberToNameMap[number] = name
      let s = name.protoStaticStringName
      let p = AsciiName(bytes: s.utf8Start, count: s.utf8CodeUnitCount)
      protoToNumberMap[p] = number
    }
    // JSON map includes proto names as well.
    jsonToNumberMap = protoToNumberMap
    for (number, name) in elements {
      let s = name.jsonStaticStringName
      let j = AsciiName(bytes: s.utf8Start, count: s.utf8CodeUnitCount)
      jsonToNumberMap[j] = number
    }
  }

  /// Returns the name bundle for the field with the given number, or `nil` if
  /// there is no match.
  public func fieldNames(for number: Int) -> Names? {
    return numberToNameMap[number]
  }

  internal func fieldNumber(forProtoName raw: UnsafeBufferPointer<UInt8>) -> Int? {
    let n = AsciiName(buffer: raw)
    return protoToNumberMap[n]
  }

  /// Returns the field number that has the given JSON name, or `nil` if there
  /// is no match.
  ///
  /// JSON parsing must interpret *both* the JSON name of the field provided by
  /// the descriptor *as well as* its original proto/text name. Because of this,
  /// this function checks both mappings -- first the JSON mapping, then the
  /// proto mapping.
  internal func fieldNumber(forJSONName name: String) -> Int? {
    let utf8 = Array(name.utf8)
    return utf8.withUnsafeBufferPointer { (buffer: UnsafeBufferPointer<UInt8>) in
      let n = AsciiName(buffer: buffer)
      return jsonToNumberMap[n]
    }
  }

  /// Private version of fieldNumber(forJSONName:) that accepts a
  /// pointer/size to a block of memory holding UTF8 text.  This is
  /// used by the JSON decoder to avoid the overhead of creating a new
  /// String object for every field name.
  internal func fieldNumber(forJSONName raw: UnsafeBufferPointer<UInt8>) -> Int? {
    let n = AsciiName(buffer: raw)
    return jsonToNumberMap[n]
  }

}
