// Sources/SwiftProtobuf/BinaryReverseEncodingVisitor.swift - Binary encoding support
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Core support for protobuf binary encoding.  Note that this is built
/// on the general traversal machinery.
///
// -----------------------------------------------------------------------------

import Foundation

/// Visitor that encodes a message graph in the protobuf binary wire format.
internal struct BinaryReverseEncodingVisitor: Visitor {
  private let options: BinaryEncodingOptions

  var encoder: BinaryReverseEncoder

  /// Creates a new visitor that writes the binary-coded message into the memory
  /// at the given pointer.
  ///
  /// - Precondition: `pointer` must point to an allocated block of memory that
  ///   is large enough to hold the entire encoded message. For performance
  ///   reasons, the encoder does not make any attempts to verify this.
  init(forWritingInto buffer: UnsafeMutableRawBufferPointer, options: BinaryEncodingOptions) {
    self.encoder = BinaryReverseEncoder(forWritingInto: buffer)
    self.options = options
  }

  mutating func visitUnknown(bytes: Data) throws {
    encoder.appendUnknown(data: bytes)
  }

  mutating func visitSingularFloatField(value: Float, fieldNumber: Int) throws {
    encoder.putFloatValue(value: value)
    encoder.startField(fieldNumber: fieldNumber, wireFormat: .fixed32)
  }

  mutating func visitSingularDoubleField(value: Double, fieldNumber: Int) throws {
    encoder.putDoubleValue(value: value)
    encoder.startField(fieldNumber: fieldNumber, wireFormat: .fixed64)
  }

  mutating func visitSingularInt64Field(value: Int64, fieldNumber: Int) throws {
    try visitSingularUInt64Field(value: UInt64(bitPattern: value), fieldNumber: fieldNumber)
  }

  mutating func visitSingularUInt64Field(value: UInt64, fieldNumber: Int) throws {
    encoder.putVarInt(value: value)
    encoder.startField(fieldNumber: fieldNumber, wireFormat: .varint)
  }

  mutating func visitSingularSInt32Field(value: Int32, fieldNumber: Int) throws {
    try visitSingularSInt64Field(value: Int64(value), fieldNumber: fieldNumber)
  }

  mutating func visitSingularSInt64Field(value: Int64, fieldNumber: Int) throws {
    try visitSingularUInt64Field(value: ZigZag.encoded(value), fieldNumber: fieldNumber)
  }

  mutating func visitSingularFixed32Field(value: UInt32, fieldNumber: Int) throws {
    encoder.putFixedUInt32(value: value)
    encoder.startField(fieldNumber: fieldNumber, wireFormat: .fixed32)
  }

  mutating func visitSingularFixed64Field(value: UInt64, fieldNumber: Int) throws {
    encoder.putFixedUInt64(value: value)
    encoder.startField(fieldNumber: fieldNumber, wireFormat: .fixed64)
  }

  mutating func visitSingularSFixed32Field(value: Int32, fieldNumber: Int) throws {
    try visitSingularFixed32Field(value: UInt32(bitPattern: value), fieldNumber: fieldNumber)
  }

  mutating func visitSingularSFixed64Field(value: Int64, fieldNumber: Int) throws {
    try visitSingularFixed64Field(value: UInt64(bitPattern: value), fieldNumber: fieldNumber)
  }

  mutating func visitSingularBoolField(value: Bool, fieldNumber: Int) throws {
    try visitSingularUInt64Field(value: value ? 1 : 0, fieldNumber: fieldNumber)
  }

  mutating func visitSingularStringField(value: String, fieldNumber: Int) throws {
    encoder.putStringValue(value: value)
    encoder.startField(fieldNumber: fieldNumber, wireFormat: .lengthDelimited)
  }

  mutating func visitSingularBytesField(value: Data, fieldNumber: Int) throws {
    encoder.putBytesValue(value: value)
    encoder.startField(fieldNumber: fieldNumber, wireFormat: .lengthDelimited)
  }

  mutating func visitSingularEnumField<E: Enum>(value: E,
                                                fieldNumber: Int) throws {
    try visitSingularUInt64Field(value: UInt64(bitPattern: Int64(value.rawValue)),
                                 fieldNumber: fieldNumber)
  }

  mutating func visitSingularMessageField<M: Message>(value: M,
                                             fieldNumber: Int) throws {
    let before = encoder.used
    try value.traverse(visitor: &self)
    let length = encoder.used - before
    encoder.putVarInt(value: length)
    encoder.startField(fieldNumber: fieldNumber, wireFormat: .lengthDelimited)
  }

  mutating func visitSingularGroupField<G: Message>(value: G, fieldNumber: Int) throws {
    encoder.startField(fieldNumber: fieldNumber, wireFormat: .endGroup)
    try value.traverse(visitor: &self)
    encoder.startField(fieldNumber: fieldNumber, wireFormat: .startGroup)
  }

  // Repeated Fields

  public mutating func visitRepeatedFloatField(value: [Float], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    for v in value.reversed() {
      try visitSingularFloatField(value: v, fieldNumber: fieldNumber)
    }
  }

  public mutating func visitRepeatedDoubleField(value: [Double], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    for v in value.reversed() {
      try visitSingularDoubleField(value: v, fieldNumber: fieldNumber)
    }
  }

  public mutating func visitRepeatedInt32Field(value: [Int32], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    for v in value.reversed() {
      try visitSingularInt32Field(value: v, fieldNumber: fieldNumber)
    }
  }

  public mutating func visitRepeatedInt64Field(value: [Int64], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    for v in value.reversed() {
      try visitSingularInt64Field(value: v, fieldNumber: fieldNumber)
    }
  }

  public mutating func visitRepeatedUInt32Field(value: [UInt32], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    for v in value.reversed() {
      try visitSingularUInt32Field(value: v, fieldNumber: fieldNumber)
    }
  }

  public mutating func visitRepeatedUInt64Field(value: [UInt64], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    for v in value.reversed() {
      try visitSingularUInt64Field(value: v, fieldNumber: fieldNumber)
    }
  }

  public mutating func visitRepeatedSInt32Field(value: [Int32], fieldNumber: Int) throws {
      assert(!value.isEmpty)
      for v in value.reversed() {
          try visitSingularSInt32Field(value: v, fieldNumber: fieldNumber)
      }
  }

  public mutating func visitRepeatedSInt64Field(value: [Int64], fieldNumber: Int) throws {
      assert(!value.isEmpty)
      for v in value.reversed() {
          try visitSingularSInt64Field(value: v, fieldNumber: fieldNumber)
      }
  }

  public mutating func visitRepeatedFixed32Field(value: [UInt32], fieldNumber: Int) throws {
      assert(!value.isEmpty)
      for v in value.reversed() {
          try visitSingularFixed32Field(value: v, fieldNumber: fieldNumber)
      }
  }

  public mutating func visitRepeatedFixed64Field(value: [UInt64], fieldNumber: Int) throws {
      assert(!value.isEmpty)
      for v in value.reversed() {
          try visitSingularFixed64Field(value: v, fieldNumber: fieldNumber)
      }
  }

  public mutating func visitRepeatedSFixed32Field(value: [Int32], fieldNumber: Int) throws {
      assert(!value.isEmpty)
      for v in value.reversed() {
          try visitSingularSFixed32Field(value: v, fieldNumber: fieldNumber)
      }
  }

  public mutating func visitRepeatedSFixed64Field(value: [Int64], fieldNumber: Int) throws {
      assert(!value.isEmpty)
      for v in value.reversed() {
          try visitSingularSFixed64Field(value: v, fieldNumber: fieldNumber)
      }
  }

  public mutating func visitRepeatedBoolField(value: [Bool], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    for v in value.reversed() {
      try visitSingularBoolField(value: v, fieldNumber: fieldNumber)
    }
  }

  public mutating func visitRepeatedStringField(value: [String], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    for v in value.reversed() {
      try visitSingularStringField(value: v, fieldNumber: fieldNumber)
    }
  }

  public mutating func visitRepeatedBytesField(value: [Data], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    for v in value.reversed() {
      try visitSingularBytesField(value: v, fieldNumber: fieldNumber)
    }
  }

  public mutating func visitRepeatedEnumField<E: Enum>(value: [E], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    for v in value.reversed() {
        try visitSingularEnumField(value: v, fieldNumber: fieldNumber)
    }
  }

  public mutating func visitRepeatedMessageField<M: Message>(value: [M], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    for v in value.reversed() {
      try visitSingularMessageField(value: v, fieldNumber: fieldNumber)
    }
  }

  public mutating func visitRepeatedGroupField<G: Message>(value: [G], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    for v in value.reversed() {
      try visitSingularGroupField(value: v, fieldNumber: fieldNumber)
    }
  }

  // Packed Fields

  mutating func visitPackedFloatField(value: [Float], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    let before = encoder.used
    for v in value.reversed() {
      encoder.putFloatValue(value: v)
    }
    encoder.putVarInt(value: encoder.used - before)
    encoder.startField(fieldNumber: fieldNumber, wireFormat: .lengthDelimited)
  }

  mutating func visitPackedDoubleField(value: [Double], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    let before = encoder.used
    for v in value.reversed() {
      encoder.putDoubleValue(value: v)
    }
    encoder.putVarInt(value: encoder.used - before)
    encoder.startField(fieldNumber: fieldNumber, wireFormat: .lengthDelimited)
  }

  mutating func visitPackedInt32Field(value: [Int32], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    let before = encoder.used
    for v in value.reversed() {
        encoder.putVarInt(value: Int64(v))
    }
    encoder.putVarInt(value: encoder.used - before)
    encoder.startField(fieldNumber: fieldNumber, wireFormat: .lengthDelimited)
  }

  mutating func visitPackedInt64Field(value: [Int64], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    let before = encoder.used
    for v in value.reversed() {
        encoder.putVarInt(value: v)
    }
    encoder.putVarInt(value: encoder.used - before)
    encoder.startField(fieldNumber: fieldNumber, wireFormat: .lengthDelimited)
  }

  mutating func visitPackedSInt32Field(value: [Int32], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    let before = encoder.used
    for v in value.reversed() {
        encoder.putZigZagVarInt(value: Int64(v))
    }
    encoder.putVarInt(value: encoder.used - before)
    encoder.startField(fieldNumber: fieldNumber, wireFormat: .lengthDelimited)
  }

  mutating func visitPackedSInt64Field(value: [Int64], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    let before = encoder.used
    for v in value.reversed() {
        encoder.putZigZagVarInt(value: v)
    }
    encoder.putVarInt(value: encoder.used - before)
    encoder.startField(fieldNumber: fieldNumber, wireFormat: .lengthDelimited)
  }

  mutating func visitPackedUInt32Field(value: [UInt32], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    let before = encoder.used
    for v in value.reversed() {
        encoder.putVarInt(value: UInt64(v))
    }
    encoder.putVarInt(value: encoder.used - before)
    encoder.startField(fieldNumber: fieldNumber, wireFormat: .lengthDelimited)
  }

  mutating func visitPackedUInt64Field(value: [UInt64], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    let before = encoder.used
    for v in value.reversed() {
        encoder.putVarInt(value: v)
    }
    encoder.putVarInt(value: encoder.used - before)
    encoder.startField(fieldNumber: fieldNumber, wireFormat: .lengthDelimited)
  }

  mutating func visitPackedFixed32Field(value: [UInt32], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    let before = encoder.used
    for v in value.reversed() {
      encoder.putFixedUInt32(value: v)
    }
    encoder.putVarInt(value: encoder.used - before)
    encoder.startField(fieldNumber: fieldNumber, wireFormat: .lengthDelimited)
  }

  mutating func visitPackedFixed64Field(value: [UInt64], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    let before = encoder.used
    for v in value.reversed() {
      encoder.putFixedUInt64(value: v)
    }
    encoder.putVarInt(value: encoder.used - before)
    encoder.startField(fieldNumber: fieldNumber, wireFormat: .lengthDelimited)
  }

  mutating func visitPackedSFixed32Field(value: [Int32], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    let before = encoder.used
    for v in value.reversed() {
       encoder.putFixedUInt32(value: UInt32(bitPattern: v))
    }
    encoder.putVarInt(value: encoder.used - before)
    encoder.startField(fieldNumber: fieldNumber, wireFormat: .lengthDelimited)
  }

  mutating func visitPackedSFixed64Field(value: [Int64], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    let before = encoder.used
    for v in value.reversed() {
      encoder.putFixedUInt64(value: UInt64(bitPattern: v))
    }
    encoder.putVarInt(value: encoder.used - before)
    encoder.startField(fieldNumber: fieldNumber, wireFormat: .lengthDelimited)
  }

  mutating func visitPackedBoolField(value: [Bool], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    for v in value.reversed() {
      encoder.putVarInt(value: v ? 1 : 0)
    }
    encoder.putVarInt(value: value.count)
    encoder.startField(fieldNumber: fieldNumber, wireFormat: .lengthDelimited)
  }

  mutating func visitPackedEnumField<E: Enum>(value: [E], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    let before = encoder.used
    for v in value.reversed() {
      encoder.putVarInt(value: v.rawValue)
    }
    encoder.putVarInt(value: encoder.used - before)
    encoder.startField(fieldNumber: fieldNumber, wireFormat: .lengthDelimited)
  }

  mutating func visitMapField<KeyType, ValueType: MapValueType>(
    fieldType: _ProtobufMap<KeyType, ValueType>.Type,
    value: _ProtobufMap<KeyType, ValueType>.BaseType,
    fieldNumber: Int
  ) throws {
    try iterateAndEncode(
      map: value, fieldNumber: fieldNumber, isOrderedBefore: KeyType._lessThan,
      encodeWithVisitor: { visitor, key, value in
        try ValueType.visitSingular(value: value, fieldNumber: 2, with: &visitor)
        try KeyType.visitSingular(value: key, fieldNumber: 1, with: &visitor)
      }
    )
  }

  mutating func visitMapField<KeyType, ValueType>(
    fieldType: _ProtobufEnumMap<KeyType, ValueType>.Type,
    value: _ProtobufEnumMap<KeyType, ValueType>.BaseType,
    fieldNumber: Int
  ) throws where ValueType.RawValue == Int {
    try iterateAndEncode(
      map: value, fieldNumber: fieldNumber, isOrderedBefore: KeyType._lessThan,
      encodeWithVisitor: { visitor, key, value in
        try visitor.visitSingularEnumField(value: value, fieldNumber: 2)
        try KeyType.visitSingular(value: key, fieldNumber: 1, with: &visitor)
      }
    )
  }

  mutating func visitMapField<KeyType, ValueType>(
    fieldType: _ProtobufMessageMap<KeyType, ValueType>.Type,
    value: _ProtobufMessageMap<KeyType, ValueType>.BaseType,
    fieldNumber: Int
  ) throws {
    try iterateAndEncode(
      map: value, fieldNumber: fieldNumber, isOrderedBefore: KeyType._lessThan,
      encodeWithVisitor: { visitor, key, value in
        try visitor.visitSingularMessageField(value: value, fieldNumber: 2)
        try KeyType.visitSingular(value: key, fieldNumber: 1, with: &visitor)
      }
    )
  }

  /// Helper to encapsulate the common structure of iterating over a map
  /// and encoding the keys and values.
  private mutating func iterateAndEncode<K, V>(
    map: Dictionary<K, V>,
    fieldNumber: Int,
    isOrderedBefore: (K, K) -> Bool,
    encodeWithVisitor: (inout BinaryReverseEncodingVisitor, K, V) throws -> ()
  ) throws {
    if options.useDeterministicOrdering {
      for (k,v) in map.sorted(by: { isOrderedBefore( $0.0, $1.0) }).reversed() {
        let before = encoder.used
        try encodeWithVisitor(&self, k, v)
        encoder.putVarInt(value: encoder.used - before)
        encoder.startField(fieldNumber: fieldNumber, wireFormat: .lengthDelimited)
      }
    } else {
      for (k,v) in map {
        let before = encoder.used
        try encodeWithVisitor(&self, k, v)
        encoder.putVarInt(value: encoder.used - before)
        encoder.startField(fieldNumber: fieldNumber, wireFormat: .lengthDelimited)
      }
    }
  }

  mutating func visitExtensionFieldsAsMessageSet(
    fields: ExtensionFieldValueSet,
    start: Int,
    end: Int
  ) throws {
    var subVisitor = BinaryReverseEncodingMessageSetVisitor(encoder: encoder, options: options)
    try fields.traverse(visitor: &subVisitor, start: start, end: end)
    encoder = subVisitor.encoder
  }
}

extension BinaryReverseEncodingVisitor {

  // Helper Visitor to when writing out the extensions as MessageSets.
  internal struct BinaryReverseEncodingMessageSetVisitor: SelectiveVisitor {
    private let options: BinaryEncodingOptions

    var encoder: BinaryReverseEncoder

    init(encoder: BinaryReverseEncoder, options: BinaryEncodingOptions) {
      self.options = options
      self.encoder = encoder
    }

    mutating func visitSingularMessageField<M: Message>(value: M, fieldNumber: Int) throws {
      encoder.putVarInt(value: Int64(WireFormat.MessageSet.Tags.itemEnd.rawValue))

      var subVisitor = BinaryReverseEncodingVisitor(
        forWritingInto: encoder.remainder, options: options
      )
      try value.traverse(visitor: &subVisitor)
      encoder.consume(subVisitor.encoder.used)
      encoder.putVarInt(value: subVisitor.encoder.used)

      encoder.putVarInt(value: Int64(WireFormat.MessageSet.Tags.message.rawValue))
      encoder.putVarInt(value: fieldNumber)
      encoder.putVarInt(value: Int64(WireFormat.MessageSet.Tags.typeId.rawValue))
      encoder.putVarInt(value: Int64(WireFormat.MessageSet.Tags.itemStart.rawValue))
    }

    // SelectiveVisitor handles the rest.
  }
}
