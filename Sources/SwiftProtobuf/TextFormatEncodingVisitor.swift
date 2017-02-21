// Sources/SwiftProtobuf/TextFormatEncodingVisitor.swift - Text format encoding support
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Text format serialization engine.
///
// -----------------------------------------------------------------------------

import Foundation

private func mapNameResolver(fieldNumber: Int) -> StaticString? {
    switch fieldNumber {
    case 1: return "key"
    case 2: return "value"
    default: return nil
    }
}

/// Visitor that serializes a message into protobuf text format.
internal struct TextFormatEncodingVisitor: Visitor {

  private var encoder: TextFormatEncoder
  private var inExtension = false
  private var nameResolver: (Int) -> StaticString?

  /// The protobuf text produced by the visitor.
  var result: String {
    return encoder.stringResult
  }

  /// Creates a new visitor that serializes the given message to protobuf text
  /// format.
  init(message: Message) {
    self.init(message: message, encoder: TextFormatEncoder())
  }

  /// Creates a new visitor that serializes the given message to protobuf text
  /// format, using an existing encoder.
  private init(message: Message, encoder: TextFormatEncoder) {
    self.init(nameResolver: ProtoNameResolvers.protoFieldNameResolver(for: message), encoder: encoder)
  }

  private init(nameResolver: @escaping (Int) -> StaticString?, encoder: TextFormatEncoder) {
    self.nameResolver = nameResolver
    self.encoder = encoder
  }

  private func protoFieldName(for number: Int) throws -> StaticString {
    if let protoName = nameResolver(number) {
      return protoName
    }
    throw EncodingError.missingFieldNames
  }

  private mutating func startField(name: StaticString) {
      encoder.startField(name: name, inExtension: inExtension)
  }

  private mutating func startField(fieldNumber: Int) throws {
    let protoFieldName = try self.protoFieldName(for: fieldNumber)
    startField(name: protoFieldName)
  }


  mutating func visitUnknown(bytes: Data) {
    // TODO: Print unknown fields by tag number.
  }

  // Visitor.swift defines default versions for other singular field types
  // that simply widen and dispatch to one of the following.  Since Text format
  // does not distinguish e.g., Fixed64 vs. UInt64, this is sufficient.

  mutating func visitSingularDoubleField(value: Double, fieldNumber: Int) throws {
    try startField(fieldNumber: fieldNumber)
    encoder.putDoubleValue(value: value)
    encoder.endField()
  }

  mutating func visitSingularInt64Field(value: Int64, fieldNumber: Int) throws {
    try startField(fieldNumber: fieldNumber)
    encoder.putInt64(value: value)
    encoder.endField()
  }

  mutating func visitSingularUInt64Field(value: UInt64, fieldNumber: Int) throws {
    try startField(fieldNumber: fieldNumber)
    encoder.putUInt64(value: value)
    encoder.endField()
  }

  mutating func visitSingularBoolField(value: Bool, fieldNumber: Int) throws {
    try startField(fieldNumber: fieldNumber)
    encoder.putBoolValue(value: value)
    encoder.endField()
  }

  mutating func visitSingularStringField(value: String, fieldNumber: Int) throws {
    try startField(fieldNumber: fieldNumber)
    encoder.putStringValue(value: value)
    encoder.endField()
  }

  mutating func visitSingularBytesField(value: Data, fieldNumber: Int) throws {
    try startField(fieldNumber: fieldNumber)
    encoder.putBytesValue(value: value)
    encoder.endField()
  }

  mutating func visitSingularEnumField<E: Enum>(value: E, fieldNumber: Int) throws {
    try startField(fieldNumber: fieldNumber)
    encoder.putEnumValue(value: value)
    encoder.endField()
  }

  mutating func visitSingularMessageField<M: Message>(value: M,
                                             fieldNumber: Int) throws {
    let protoFieldName = try self.protoFieldName(for: fieldNumber)
    encoder.startMessageField(name: protoFieldName, inExtension: inExtension)
    encoder.startObject()
    var visitor = TextFormatEncodingVisitor(message: value, encoder: encoder)
    try value.traverse(visitor: &visitor)
    encoder = visitor.encoder
    encoder.endObject()
    encoder.endField()
  }

  // The default implementations in Visitor.swift provide the correct
  // results, but we get significantly better performance by only doing
  // the name lookup once for the array, rather than once for each element:

  mutating func visitRepeatedFloatField(value: [Float], fieldNumber: Int) throws {
    let protoFieldName = try self.protoFieldName(for: fieldNumber)
    for v in value {
      startField(name: protoFieldName)
      encoder.putDoubleValue(value: Double(v))
      encoder.endField()
    }
  }

  mutating func visitRepeatedDoubleField(value: [Double], fieldNumber: Int) throws {
    let protoFieldName = try self.protoFieldName(for: fieldNumber)
    for v in value {
      startField(name: protoFieldName)
      encoder.putDoubleValue(value: v)
      encoder.endField()
    }
  }

  mutating func visitRepeatedInt32Field(value: [Int32], fieldNumber: Int) throws {
    let protoFieldName = try self.protoFieldName(for: fieldNumber)
    for v in value {
      startField(name: protoFieldName)
      encoder.putInt64(value: Int64(v))
      encoder.endField()
    }
  }

  mutating func visitRepeatedInt64Field(value: [Int64], fieldNumber: Int) throws {
    let protoFieldName = try self.protoFieldName(for: fieldNumber)
    for v in value {
      startField(name: protoFieldName)
      encoder.putInt64(value: v)
      encoder.endField()
    }
  }

  mutating func visitRepeatedUInt32Field(value: [UInt32], fieldNumber: Int) throws {
    let protoFieldName = try self.protoFieldName(for: fieldNumber)
    for v in value {
      startField(name: protoFieldName)
      encoder.putUInt64(value: UInt64(v))
      encoder.endField()
    }
  }

  mutating func visitRepeatedUInt64Field(value: [UInt64], fieldNumber: Int) throws {
    let protoFieldName = try self.protoFieldName(for: fieldNumber)
    for v in value {
      startField(name: protoFieldName)
      encoder.putUInt64(value: v)
      encoder.endField()
    }
  }

  mutating func visitRepeatedSInt32Field(value: [Int32], fieldNumber: Int) throws {
    try visitRepeatedInt32Field(value: value, fieldNumber: fieldNumber)
  }
  mutating func visitRepeatedSInt64Field(value: [Int64], fieldNumber: Int) throws {
    try visitRepeatedInt64Field(value: value, fieldNumber: fieldNumber)
  }
  mutating func visitRepeatedFixed32Field(value: [UInt32], fieldNumber: Int) throws {
    try visitRepeatedUInt32Field(value: value, fieldNumber: fieldNumber)
  }
  mutating func visitRepeatedFixed64Field(value: [UInt64], fieldNumber: Int) throws {
    try visitRepeatedUInt64Field(value: value, fieldNumber: fieldNumber)
  }
  mutating func visitRepeatedSFixed32Field(value: [Int32], fieldNumber: Int) throws {
    try visitRepeatedInt32Field(value: value, fieldNumber: fieldNumber)
  }
  mutating func visitRepeatedSFixed64Field(value: [Int64], fieldNumber: Int) throws {
    try visitRepeatedInt64Field(value: value, fieldNumber: fieldNumber)
  }

  mutating func visitRepeatedBoolField(value: [Bool], fieldNumber: Int) throws {
    let protoFieldName = try self.protoFieldName(for: fieldNumber)
    for v in value {
      startField(name: protoFieldName)
      encoder.putBoolValue(value: v)
      encoder.endField()
    }
  }

  mutating func visitRepeatedStringField(value: [String], fieldNumber: Int) throws {
    let protoFieldName = try self.protoFieldName(for: fieldNumber)
    for v in value {
      startField(name: protoFieldName)
      encoder.putStringValue(value: v)
      encoder.endField()
    }
  }

  mutating func visitRepeatedBytesField(value: [Data], fieldNumber: Int) throws {
    let protoFieldName = try self.protoFieldName(for: fieldNumber)
    for v in value {
      startField(name: protoFieldName)
      encoder.putBytesValue(value: v)
      encoder.endField()
    }
  }

  mutating func visitRepeatedEnumField<E: Enum>(value: [E], fieldNumber: Int) throws {
    let protoFieldName = try self.protoFieldName(for: fieldNumber)
    for v in value {
      startField(name: protoFieldName)
      encoder.putEnumValue(value: v)
      encoder.endField()
    }
  }

  // Messages and groups
  mutating func visitRepeatedMessageField<M: Message>(value: [M],
                                             fieldNumber: Int) throws {
    let protoFieldName = try self.protoFieldName(for: fieldNumber)
    for v in value {
      encoder.startMessageField(name: protoFieldName, inExtension: inExtension)
      encoder.startObject()
      var visitor = TextFormatEncodingVisitor(message: v, encoder: encoder)
      try v.traverse(visitor: &visitor)
      encoder = visitor.encoder
      encoder.endObject()
      encoder.endField()
    }
  }

  // Google's C++ implementation of Text format supports two formats
  // for repeated numeric fields: "short" format writes the list as a
  // single field with values enclosed in `[...]`, "long" format
  // writes a separate field name/value for each item.  They provide
  // an option for callers to select which output version they prefer.

  // Since this distinction mirrors the difference in Protobuf Binary
  // between "packed" and "non-packed", I've chosen to use the short
  // format for packed fields and the long version for repeated
  // fields.  This provides a clear visual distinction between these
  // fields (including proto3's default use of packed) without
  // introducing the baggage of a separate option.

  private mutating func _visitPacked<T>(value: [T], fieldNumber: Int, encode: (T) -> ()) throws {
    try startField(fieldNumber: fieldNumber)
    var firstItem = true
    encoder.startArray()
    for v in value {
      if !firstItem {
        encoder.arraySeparator()
      }
      encode(v)
      firstItem = false
    }
    encoder.endArray()
    encoder.endField()
  }

  mutating func visitPackedFloatField(value: [Float], fieldNumber: Int) throws {
    try _visitPacked(value: value, fieldNumber: fieldNumber) { (v: Float) in
      encoder.putDoubleValue(value: Double(v))
    }
  }

  mutating func visitPackedDoubleField(value: [Double], fieldNumber: Int) throws {
    try _visitPacked(value: value, fieldNumber: fieldNumber) { (v: Double) in
      encoder.putDoubleValue(value: v)
    }
  }

  mutating func visitPackedInt32Field(value: [Int32], fieldNumber: Int) throws {
    try _visitPacked(value: value, fieldNumber: fieldNumber) { (v: Int32) in
      encoder.putInt64(value: Int64(v))
    }
  }

  mutating func visitPackedInt64Field(value: [Int64], fieldNumber: Int) throws {
    try _visitPacked(value: value, fieldNumber: fieldNumber) { (v: Int64) in
      encoder.putInt64(value: v)
    }
  }

  mutating func visitPackedUInt32Field(value: [UInt32], fieldNumber: Int) throws {
    try _visitPacked(value: value, fieldNumber: fieldNumber) { (v: UInt32) in
      encoder.putUInt64(value: UInt64(v))
    }
  }

  mutating func visitPackedUInt64Field(value: [UInt64], fieldNumber: Int) throws {
    try _visitPacked(value: value, fieldNumber: fieldNumber) { (v: UInt64) in
      encoder.putUInt64(value: v)
    }
  }

  mutating func visitPackedSInt32Field(value: [Int32], fieldNumber: Int) throws {
    try visitPackedInt32Field(value: value, fieldNumber: fieldNumber)
  }

  mutating func visitPackedSInt64Field(value: [Int64], fieldNumber: Int) throws {
    try visitPackedInt64Field(value: value, fieldNumber: fieldNumber)
  }

  mutating func visitPackedFixed32Field(value: [UInt32], fieldNumber: Int) throws {
    try visitPackedUInt32Field(value: value, fieldNumber: fieldNumber)
  }

  mutating func visitPackedFixed64Field(value: [UInt64], fieldNumber: Int) throws {
    try visitPackedUInt64Field(value: value, fieldNumber: fieldNumber)
  }

  mutating func visitPackedSFixed32Field(value: [Int32], fieldNumber: Int) throws {
    try visitPackedInt32Field(value: value, fieldNumber: fieldNumber)
  }

  mutating func visitPackedSFixed64Field(value: [Int64], fieldNumber: Int) throws {
    try visitPackedInt64Field(value: value, fieldNumber: fieldNumber)
  }

  mutating func visitPackedBoolField(value: [Bool], fieldNumber: Int) throws {
    try _visitPacked(value: value, fieldNumber: fieldNumber) { (v: Bool) in
      encoder.putBoolValue(value: v)
    }
  }

  mutating func visitPackedEnumField<E: Enum>(value: [E], fieldNumber: Int) throws {
    try _visitPacked(value: value, fieldNumber: fieldNumber) { (v: E) in
      encoder.putEnumValue(value: v)
    }
  }

  /// Helper to encapsulate the common structure of iterating over a map
  /// and encoding the keys and values.
  private mutating func _visitMap<K, V>(
    map: Dictionary<K, V>,
    fieldNumber: Int,
    coder: (inout TextFormatEncodingVisitor, K, V) throws -> ()
  ) throws {
    let protoFieldName = try self.protoFieldName(for: fieldNumber)
    for (k,v) in map {
      encoder.startMessageField(name: protoFieldName, inExtension: inExtension)
      encoder.startObject()
      var visitor = TextFormatEncodingVisitor(nameResolver: mapNameResolver, encoder: encoder)
      try coder(&visitor, k, v)
      encoder = visitor.encoder
      encoder.endObject()
      encoder.endField()
    }
  }

  mutating func visitMapField<KeyType: MapKeyType, ValueType: MapValueType>(
    fieldType: ProtobufMap<KeyType, ValueType>.Type,
    value: ProtobufMap<KeyType, ValueType>.BaseType,
    fieldNumber: Int
  ) throws where KeyType.BaseType: Hashable {
      try _visitMap(map: value, fieldNumber: fieldNumber) {
          (visitor: inout TextFormatEncodingVisitor, key, value) throws -> () in
          try KeyType.visitSingular(value: key, fieldNumber: 1, with: &visitor)
          try ValueType.visitSingular(value: value, fieldNumber: 2, with: &visitor)
      }
  }

  mutating func visitMapField<KeyType: MapKeyType, ValueType: Enum>(
    fieldType: ProtobufEnumMap<KeyType, ValueType>.Type,
    value: ProtobufEnumMap<KeyType, ValueType>.BaseType,
    fieldNumber: Int
  ) throws where KeyType.BaseType: Hashable, ValueType.RawValue == Int {
      try _visitMap(map: value, fieldNumber: fieldNumber) {
          (visitor: inout TextFormatEncodingVisitor, key, value) throws -> () in
          try KeyType.visitSingular(value: key, fieldNumber: 1, with: &visitor)
          try visitor.visitSingularEnumField(value: value, fieldNumber: 2)
      }
  }

  mutating func visitMapField<KeyType: MapKeyType, ValueType: Message & Hashable>(
    fieldType: ProtobufMessageMap<KeyType, ValueType>.Type,
    value: ProtobufMessageMap<KeyType, ValueType>.BaseType,
    fieldNumber: Int
  ) throws where KeyType.BaseType: Hashable {
      try _visitMap(map: value, fieldNumber: fieldNumber) {
          (visitor: inout TextFormatEncodingVisitor, key, value) throws -> () in
          try KeyType.visitSingular(value: key, fieldNumber: 1, with: &visitor)
          try visitor.visitSingularMessageField(value: value, fieldNumber: 2)
      }
  }

  /// Called for each extension range.
  mutating func visitExtensionFields(fields: ExtensionFieldValueSet, start: Int, end: Int) throws {
    inExtension = true
    try fields.traverse(visitor: &self, start: start, end: end)
    inExtension = false
  }
}
