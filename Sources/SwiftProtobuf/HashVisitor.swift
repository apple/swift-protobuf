// Sources/SwiftProtobuf/HashVisitor.swift - Hashing support
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Hashing is basically a serialization problem, so we can leverage the
/// generated traversal methods for that.
///
// -----------------------------------------------------------------------------

import Foundation

private let i_2166136261 = Int(bitPattern: 2166136261)
private let i_16777619 = Int(16777619)

/// Computes the hash value of a message by visiting its fields recursively.
///
/// Note that because this visits every field, it has the potential to be slow
/// for large or deeply nested messages. Users who need to use such messages as
/// dictionary keys or set members should override `hashValue` in an extension
/// and provide a more efficient implementation by examining only a subset of
/// key fields.
internal struct HashVisitor: Visitor {

  // Roughly based on FNV hash: http://tools.ietf.org/html/draft-eastlake-fnv-03
  private(set) var hashValue = i_2166136261

  private mutating func mix(_ hash: Int) {
    hashValue = (hashValue ^ hash) &* i_16777619
  }

  private mutating func mixMap<K, V: Hashable>(map: Dictionary<K,V>) {
    var mapHash = 0
    for (k, v) in map {
      // Note: This calculation cannot depend on the order of the items.
      mapHash = mapHash &+ (k.hashValue ^ v.hashValue)
    }
    mix(mapHash)
  }


  init() {}

  mutating func visitUnknown(bytes: Data) throws {
    mix(bytes.hashValue)
  }

  mutating func visitSingularDoubleField(value: Double, fieldNumber: Int) throws {
    mix(fieldNumber)
    mix(value.hashValue)
  }

  mutating func visitSingularInt64Field(value: Int64, fieldNumber: Int) throws {
    mix(fieldNumber)
    mix(value.hashValue)
  }

  mutating func visitSingularUInt64Field(value: UInt64, fieldNumber: Int) throws {
    mix(fieldNumber)
    mix(value.hashValue)
  }

  mutating func visitSingularBoolField(value: Bool, fieldNumber: Int) throws {
    mix(fieldNumber)
    mix(value.hashValue)
  }

  mutating func visitSingularStringField(value: String, fieldNumber: Int) throws {
    mix(fieldNumber)
    mix(value.hashValue)
  }

  mutating func visitSingularBytesField(value: Data, fieldNumber: Int) throws {
    mix(fieldNumber)
#if swift(>=3.1)
    mix(value.hashValue)
#else
    // Workaround for https://bugs.swift.org/browse/SR-936
    // (Fortunately, seems to have been fixed in Swift 3.1)
    value.enumerateBytes { (block, index, stop) in
        for b in block {
            mix(Int(b))
        }
    }
#endif
  }

  mutating func visitSingularEnumField<E: Enum>(value: E,
                                   fieldNumber: Int) {
    mix(fieldNumber)
    mix(value.hashValue)
  }

  mutating func visitSingularMessageField<M: Message>(value: M, fieldNumber: Int) {
    mix(fieldNumber)
    mix(value.hashValue)
  }

  mutating func visitMapField<KeyType, ValueType: MapValueType>(
    fieldType: _ProtobufMap<KeyType, ValueType>.Type,
    value: _ProtobufMap<KeyType, ValueType>.BaseType,
    fieldNumber: Int
  ) throws {
    mix(fieldNumber)
    mixMap(map: value)
  }


  mutating func visitMapField<KeyType, ValueType>(
    fieldType: _ProtobufEnumMap<KeyType, ValueType>.Type,
    value: _ProtobufEnumMap<KeyType, ValueType>.BaseType,
    fieldNumber: Int
  ) throws where ValueType.RawValue == Int {
    mix(fieldNumber)
    mixMap(map: value)
  }


  mutating func visitMapField<KeyType, ValueType>(
    fieldType: _ProtobufMessageMap<KeyType, ValueType>.Type,
    value: _ProtobufMessageMap<KeyType, ValueType>.BaseType,
    fieldNumber: Int
  ) throws {
    mix(fieldNumber)
    mixMap(map: value)
  }
}
