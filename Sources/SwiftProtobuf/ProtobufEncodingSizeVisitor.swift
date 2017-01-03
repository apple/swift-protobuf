// Sources/SwiftProtobuf/ProtobufEncodingSizeVisitor.swift - Binary size calculation support
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Visitor used during binary encoding that precalcuates the size of a
/// serialized message.
///
// -----------------------------------------------------------------------------

import Foundation

/// Visitor that calculates the binary-encoded size of a message so that a
/// properly sized `Data` or `UInt8` array can be pre-allocated before
/// serialization.
final class ProtobufEncodingSizeVisitor: Visitor {

  /// Accumulates the required size of the message during traversal.
  var serializedSize: Int = 0

  init() {}

  func visitUnknown(bytes: Data) {
    serializedSize += bytes.count
  }

  func visitSingularField<S: FieldType>(fieldType: S.Type,
                                        value: S.BaseType,
                                        fieldNumber: Int) throws {
    let tagSize = FieldTag(fieldNumber: fieldNumber,
                           wireFormat: S.protobufWireFormat).encodedSize
    serializedSize += try tagSize + S.encodedSizeWithoutTag(of: value)
  }

  func visitRepeatedField<S: FieldType>(fieldType: S.Type,
                                        value: [S.BaseType],
                                        fieldNumber: Int) throws {
    let tagSize = FieldTag(fieldNumber: fieldNumber,
                           wireFormat: S.protobufWireFormat).encodedSize
    serializedSize += value.count * tagSize
    for v in value {
      serializedSize += try S.encodedSizeWithoutTag(of: v)
    }
  }

  func visitPackedField<S: FieldType>(fieldType: S.Type,
                                      value: [S.BaseType],
                                      fieldNumber: Int) throws {
    guard !value.isEmpty else {
      return
    }

    let tagSize = FieldTag(fieldNumber: fieldNumber,
                           wireFormat: S.protobufWireFormat).encodedSize
    var dataSize = 0
    for v in value {
      dataSize += try S.encodedSizeWithoutTag(of: v)
    }
    serializedSize +=
      tagSize + Varint.encodedSize(of: Int64(dataSize)) + dataSize
  }

  func visitSingularMessageField<M: Message>(value: M,
                                             fieldNumber: Int) throws {
    let tagSize = FieldTag(fieldNumber: fieldNumber,
                           wireFormat: M.protobufWireFormat).encodedSize
    let messageSize = try value.serializedProtobufSize()
    serializedSize +=
      tagSize + Varint.encodedSize(of: UInt64(messageSize)) + messageSize
  }

  func visitRepeatedMessageField<M: Message>(value: [M],
                                             fieldNumber: Int) throws {
    let tagSize = FieldTag(fieldNumber: fieldNumber,
                           wireFormat: M.protobufWireFormat).encodedSize
    serializedSize += value.count * tagSize
    for v in value {
      let messageSize = try v.serializedProtobufSize()
      serializedSize +=
        Varint.encodedSize(of: UInt64(messageSize)) + messageSize
    }
  }

  func visitSingularGroupField<G: Message>(value: G, fieldNumber: Int) throws {
    // The wire format doesn't matter here because the encoded size of the
    // integer won't change based on the low three bits.
    let tagSize = FieldTag(fieldNumber: fieldNumber,
                           wireFormat: .startGroup).encodedSize
    serializedSize += 2 * tagSize
    try value.traverse(visitor: self)
  }

  func visitRepeatedGroupField<G: Message>(value: [G],
                                           fieldNumber: Int) throws {
    let tagSize = FieldTag(fieldNumber: fieldNumber,
                           wireFormat: .startGroup).encodedSize
    serializedSize += 2 * value.count * tagSize
    for v in value {
      try v.traverse(visitor: self)
    }
  }

  func visitMapField<KeyType: MapKeyType, ValueType: MapValueType>(
    fieldType: ProtobufMap<KeyType, ValueType>.Type,
    value: ProtobufMap<KeyType, ValueType>.BaseType,
    fieldNumber: Int
  ) throws where KeyType.BaseType: Hashable {
    let tagSize = FieldTag(fieldNumber: fieldNumber,
                           wireFormat: .lengthDelimited).encodedSize
    let keyTagSize = FieldTag(
      fieldNumber: 1, wireFormat: KeyType.protobufWireFormat).encodedSize
    let valueTagSize = FieldTag(
      fieldNumber: 2, wireFormat: ValueType.protobufWireFormat).encodedSize
    for (k,v) in value {
      let entrySize = try keyTagSize + KeyType.encodedSizeWithoutTag(of: k) +
        valueTagSize + ValueType.encodedSizeWithoutTag(of: v)
      serializedSize += entrySize + Varint.encodedSize(of: Int64(entrySize))
    }
    serializedSize += value.count * tagSize
  }
}
