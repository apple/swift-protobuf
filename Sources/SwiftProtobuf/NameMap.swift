// Sources/SwiftProtobuf/NameMap.swift - Bidirectional number/name mapping
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------

// Proto names are always ASCII and are always literals, so we can improve the
// performance of some of our parsing by storing them as pointers to the
// underlying bytes of a StaticString to avoid the overhead of creating and
// comparing Unicode Strings.

// Constants for FNV hash http://tools.ietf.org/html/draft-eastlake-fnv-03
private let i_2166136261 = Int(bitPattern: 2166136261)
private let i_16777619 = Int(16777619)

/// A simple byte wrapper than can hold (and hash/compare) either a
/// pointer/count to bytes in memory. We don't worry about retention because the
/// data is assumed to either (1) come from literal strings in the data segment
/// or (2) not escape the lifetime of the `String` object from which the data
/// was taken. This is inherently unsafe; use caution when using this type.
private struct ASCIIName: Hashable {

  private let buffer: UnsafeBufferPointer<UInt8>

  init(buffer: UnsafeBufferPointer<UInt8>) {
    self.buffer = buffer
  }

  init(bytes: UnsafePointer<UInt8>, count: Int) {
    self.init(buffer: UnsafeBufferPointer<UInt8>(start: bytes, count: count))
  }

  var hashValue: Int {
    var h = i_2166136261
    for byte in buffer {
      h = (h ^ Int(byte)) &* i_16777619
    }
    return h
  }

  static func ==(lhs: ASCIIName, rhs: ASCIIName) -> Bool {
    if lhs.buffer.count != rhs.buffer.count {
      return false
    }
    return lhs.buffer.elementsEqual(rhs.buffer)
  }
}

/// An immutable bidirectional mapping between field/enum-case names and
/// numbers, used for various text-based serialization (JSON and text).
public struct _NameMap: ExpressibleByDictionaryLiteral {

  /// A "bundle" of names for a particular field or enum case. We use different
  /// "packed" representations to minimize the amount of string data that we
  /// store in the binary.
  public enum Names {

    /// The proto (text format) name and the JSON name are the same string.
    case same(proto: StaticString)

    /// The JSON and text format names are different and not derivable from each
    /// other.
    case unique(proto: StaticString, json: StaticString)

    /// Used for enum cases only to represent a value's primary proto name (the
    /// first defined case) and its aliases. The JSON and text format names for
    /// enums are always the same.
    case aliased(proto: StaticString, aliases: [StaticString])

    // TODO: Add a case for JSON names that are computable from the proto name
    // using the same algorithm implemented by protoc; for example,
    // "foo_bar" -> "fooBar". This allows us to only store the string pointer
    // in the payload once.

    /// Returns the proto (text format) name in the bundle.
    internal var protoStaticStringName: StaticString {
      switch self {
      case .same(proto: let name): return name
      case .unique(proto: let name, json: _): return name
      case .aliased(proto: let name, aliases: _): return name
      }
    }

    /// Returns the JSON name in the bundle.
    internal var jsonStaticStringName: StaticString {
      switch self {
      case .same(proto: let name): return name
      case .unique(proto: _, json: let name): return name
      case .aliased(proto: let name, aliases: _): return name
      }
    }

    /// Returns the array of all text format names in this bundle. Used when
    /// building the name-to-number dictionary.
    fileprivate var allProtoNames: [StaticString] {
      switch self {
      case .same(proto: let name): return [name]
      case .unique(proto: let name, json: _): return [name]
      case .aliased(proto: let name, aliases: let aliases):
        var names = [name]
        names.append(contentsOf: aliases)
        return names
      }
    }

    /// Returns the array of all text format names in this bundle. Used when
    /// building the name-to-number dictionary.
    fileprivate var allJSONNames: [StaticString] {
      switch self {
      case .same(proto: let name): return [name]
      case .unique(proto: _, json: let name): return [name]
      case .aliased(proto: let name, aliases: let aliases):
        var names = [name]
        names.append(contentsOf: aliases)
        return names
      }
    }
  }

  /// The mapping from field/enum-case numbers to name bundles.
  private var numberToNameMap: [Int: Names] = [:]

  /// The mapping from proto/text names to field/enum-case numbers.
  private var protoToNumberMap: [ASCIIName: Int] = [:]

  /// The mapping from JSON names to field/enum-case numbers.
  private var jsonToNumberMap: [ASCIIName: Int] = [:]

  /// Creates a new empty field/enum-case name/number mapping.
  public init() {}

  /// Creates a new bidirectional field/enum-case name/number mapping from the
  /// dictionary literal.
  public init(dictionaryLiteral elements: (Int, Names)...) {
    for (number, names) in elements {
      numberToNameMap[number] = names
      for s in names.allProtoNames {
        let p = ASCIIName(bytes: s.utf8Start, count: s.utf8CodeUnitCount)
        protoToNumberMap[p] = number
      }
    }
    // JSON map includes proto names as well.
    jsonToNumberMap = protoToNumberMap
    for (number, names) in elements {
      for s in names.allJSONNames {
        let j = ASCIIName(bytes: s.utf8Start, count: s.utf8CodeUnitCount)
        jsonToNumberMap[j] = number
      }
    }
  }

  /// Returns the name bundle for the field/enum-case with the given number, or
  /// `nil` if there is no match.
  public func names(for number: Int) -> Names? {
    return numberToNameMap[number]
  }

  internal func number(forProtoName raw: UnsafeBufferPointer<UInt8>) -> Int? {
    let n = ASCIIName(buffer: raw)
    return protoToNumberMap[n]
  }

  /// Returns the field/enum-case number that has the given JSON name, or `nil`
  /// if there is no match.
  ///
  /// JSON parsing must interpret *both* the JSON name of the field/enum-case
  /// provided by the descriptor *as well as* its original proto/text name.
  /// Because of this, this function checks both mappings -- first the JSON
  /// mapping, then the proto mapping.
  internal func number(forJSONName name: String) -> Int? {
    let utf8 = Array(name.utf8)
    return utf8.withUnsafeBufferPointer { (buffer: UnsafeBufferPointer<UInt8>) in
      let n = ASCIIName(buffer: buffer)
      return jsonToNumberMap[n]
    }
  }

  /// Private version of fieldNumber(forJSONName:) that accepts a
  /// pointer/size to a block of memory holding UTF8 text.  This is
  /// used by the JSON decoder to avoid the overhead of creating a new
  /// String object for every field name.
  internal func number(forJSONName raw: UnsafeBufferPointer<UInt8>) -> Int? {
    let n = ASCIIName(buffer: raw)
    return jsonToNumberMap[n]
  }
}
