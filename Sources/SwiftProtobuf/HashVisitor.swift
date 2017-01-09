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
final class HashVisitor: Visitor {

  // Roughly based on FNV hash: http://tools.ietf.org/html/draft-eastlake-fnv-03
  private(set) var hashValue = i_2166136261

  private func mix(_ hash: Int) {
    hashValue = (hashValue ^ hash) &* i_16777619
  }

  init() {}

  func visitUnknown(bytes: Data) {
    if bytes.count > 0 { // Workaround for Linux Foundation bug
      mix(bytes.hashValue)
    }
  }

  func visitSingularField<S: FieldType>(fieldType: S.Type,
                                        value: S.BaseType,
                                        fieldNumber: Int) {
    mix(fieldNumber)
    mix(value.hashValue)
  }

  func visitRepeatedField<S: FieldType>(fieldType: S.Type,
                                        value: [S.BaseType],
                                        fieldNumber: Int) {
    mix(fieldNumber)
    for v in value {
      mix(v.hashValue)
    }
  }

  func visitSingularMessageField<M: Message>(value: M, fieldNumber: Int) {
    mix(fieldNumber)
    mix(value.hashValue)
  }

  func visitRepeatedMessageField<M: Message>(value: [M], fieldNumber: Int) {
    mix(fieldNumber)
    for v in value {
      mix(v.hashValue)
    }
  }

  func visitMapField<KeyType: MapKeyType, ValueType: MapValueType>(
    fieldType: ProtobufMap<KeyType, ValueType>.Type,
    value: ProtobufMap<KeyType, ValueType>.BaseType,
    fieldNumber: Int
  ) where KeyType.BaseType: Hashable {
    mix(fieldNumber)
    // Note: When ProtobufMap<Hashable, Hashable> is Hashable, this will
    // simplify to mix(value.hashValue).
    var mapHash = 0
    for (k, v) in value {
      // Note: This calculation cannot depend on the order of the items.
      mapHash += k.hashValue ^ v.hashValue
    }
    mix(mapHash)
  }
}
