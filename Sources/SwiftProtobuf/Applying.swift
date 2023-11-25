//
// Sources/SwiftProtobuf/Applying.swift - Applying protocol and errors
//
// Copyright (c) 2023 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Applying feature (including decoder and errors)
///
// -----------------------------------------------------------------------------

import Foundation

/// Describes errors can occure during applying a value to proto
public enum ProtoApplyingError: Error {

  /// Describes a mismatch in type of the field
  ///
  /// If a value of type A is applied to a fieldNumber with type B
  /// this error will be thrown by the applying() method.
  case typeMismatch
}

internal struct ApplyingDecoder: Decoder {

  private var _fieldNumber: Int?
  private var _value: Any

  init(fieldNumber: Int, value: Any) {
    self._fieldNumber = fieldNumber
    self._value = value
  }

  mutating func handleConflictingOneOf() throws {}

  mutating func nextFieldNumber() throws -> Int? {
    if let fieldNumber = _fieldNumber {
      _fieldNumber = nil
      return fieldNumber
    }
    return nil
  }

  private func _value<T>(as type: T.Type) throws -> T {
    guard let __value = _value as? T else {
      throw ProtoApplyingError.typeMismatch
    }
    return __value
  }

  mutating func decodeSingularFloatField(value: inout Float) throws {
    value = try _value(as: Float.self)
  }

  mutating func decodeSingularFloatField(value: inout Float?) throws {
    value = try _value(as: Float?.self)
  }

  mutating func decodeRepeatedFloatField(value: inout [Float]) throws {
    value = try _value(as: [Float].self)
  }

  mutating func decodeSingularDoubleField(value: inout Double) throws {
    value = try _value(as: Double.self)
  }

  mutating func decodeSingularDoubleField(value: inout Double?) throws {
    value = try _value(as: Double?.self)
  }

  mutating func decodeRepeatedDoubleField(value: inout [Double]) throws {
    value = try _value(as: [Double].self)
  }

  mutating func decodeSingularInt32Field(value: inout Int32) throws {
    value = try _value(as: Int32.self)
  }

  mutating func decodeSingularInt32Field(value: inout Int32?) throws {
    value = try _value(as: Int32?.self)
  }

  mutating func decodeRepeatedInt32Field(value: inout [Int32]) throws {
    value = try _value(as: [Int32].self)
  }

  mutating func decodeSingularInt64Field(value: inout Int64) throws {
    value = try _value(as: Int64.self)
  }

  mutating func decodeSingularInt64Field(value: inout Int64?) throws {
    value = try _value(as: Int64?.self)
  }

  mutating func decodeRepeatedInt64Field(value: inout [Int64]) throws {
    value = try _value(as: [Int64].self)
  }

  mutating func decodeSingularUInt32Field(value: inout UInt32) throws {
    value = try _value(as: UInt32.self)
  }

  mutating func decodeSingularUInt32Field(value: inout UInt32?) throws {
    value = try _value(as: UInt32?.self)
  }

  mutating func decodeRepeatedUInt32Field(value: inout [UInt32]) throws {
    value = try _value(as: [UInt32].self)
  }

  mutating func decodeSingularUInt64Field(value: inout UInt64) throws {
    value = try _value(as: UInt64.self)
  }

  mutating func decodeSingularUInt64Field(value: inout UInt64?) throws {
    value = try _value(as: UInt64?.self)
  }

  mutating func decodeRepeatedUInt64Field(value: inout [UInt64]) throws {
    value = try _value(as: [UInt64].self)
  }

  mutating func decodeSingularSInt32Field(value: inout Int32) throws {
    value = try _value(as: Int32.self)
  }

  mutating func decodeSingularSInt32Field(value: inout Int32?) throws {
    value = try _value(as: Int32?.self)
  }

  mutating func decodeRepeatedSInt32Field(value: inout [Int32]) throws {
    value = try _value(as: [Int32].self)
  }

  mutating func decodeSingularSInt64Field(value: inout Int64) throws {
    value = try _value(as: Int64.self)
  }

  mutating func decodeSingularSInt64Field(value: inout Int64?) throws {
    value = try _value(as: Int64?.self)
  }

  mutating func decodeRepeatedSInt64Field(value: inout [Int64]) throws {
    value = try _value(as: [Int64].self)
  }

  mutating func decodeSingularFixed32Field(value: inout UInt32) throws {
    value = try _value(as: UInt32.self)
  }

  mutating func decodeSingularFixed32Field(value: inout UInt32?) throws {
    value = try _value(as: UInt32?.self)
  }

  mutating func decodeRepeatedFixed32Field(value: inout [UInt32]) throws {
    value = try _value(as: [UInt32].self)
  }

  mutating func decodeSingularFixed64Field(value: inout UInt64) throws {
    value = try _value(as: UInt64.self)
  }

  mutating func decodeSingularFixed64Field(value: inout UInt64?) throws {
    value = try _value(as: UInt64?.self)
  }

  mutating func decodeRepeatedFixed64Field(value: inout [UInt64]) throws {
    value = try _value(as: [UInt64].self)
  }

  mutating func decodeSingularSFixed32Field(value: inout Int32) throws {
    value = try _value(as: Int32.self)
  }

  mutating func decodeSingularSFixed32Field(value: inout Int32?) throws {
    value = try _value(as: Int32?.self)
  }

  mutating func decodeRepeatedSFixed32Field(value: inout [Int32]) throws {
    value = try _value(as: [Int32].self)
  }

  mutating func decodeSingularSFixed64Field(value: inout Int64) throws {
    value = try _value(as: Int64.self)
  }

  mutating func decodeSingularSFixed64Field(value: inout Int64?) throws {
    value = try _value(as: Int64?.self)
  }

  mutating func decodeRepeatedSFixed64Field(value: inout [Int64]) throws {
    value = try _value(as: [Int64].self)
  }

  mutating func decodeSingularBoolField(value: inout Bool) throws {
    value = try _value(as: Bool.self)
  }

  mutating func decodeSingularBoolField(value: inout Bool?) throws {
    value = try _value(as: Bool?.self)
  }

  mutating func decodeRepeatedBoolField(value: inout [Bool]) throws {
    value = try _value(as: [Bool].self)
  }

  mutating func decodeSingularStringField(value: inout String) throws {
    value = try _value(as: String.self)
  }

  mutating func decodeSingularStringField(value: inout String?) throws {
    value = try _value(as: String?.self)
  }

  mutating func decodeRepeatedStringField(value: inout [String]) throws {
    value = try _value(as: [String].self)
  }

  mutating func decodeSingularBytesField(value: inout Data) throws {
    value = try _value(as: Data.self)
  }

  mutating func decodeSingularBytesField(value: inout Data?) throws {
    value = try _value(as: Data?.self)
  }

  mutating func decodeRepeatedBytesField(value: inout [Data]) throws {
    value = try _value(as: [Data].self)
  }

  mutating func decodeSingularEnumField<E>(value: inout E) throws {
    value = try _value(as: E.self)
  }

  mutating func decodeSingularEnumField<E>(value: inout E?) throws {
    value = try _value(as: E?.self)
  }

  mutating func decodeRepeatedEnumField<E>(value: inout [E]) throws {
    value = try _value(as: [E].self)
  }

  mutating func decodeSingularMessageField<M>(value: inout M?) throws {
    value = try _value(as: M?.self)
  }

  mutating func decodeRepeatedMessageField<M>(value: inout [M]) throws {
    value = try _value(as: [M].self)
  }

  mutating func decodeSingularGroupField<G>(value: inout G?) throws {
    value = try _value(as: G?.self)
  }

  mutating func decodeRepeatedGroupField<G>(value: inout [G]) throws {
    value = try _value(as: [G].self)
  }

  mutating func decodeMapField<KeyType, ValueType>(
    fieldType: _ProtobufMap<KeyType, ValueType>.Type,
    value: inout _ProtobufMap<KeyType, ValueType>.BaseType
  ) throws {
    value = try _value(as: _ProtobufMap<KeyType, ValueType>.BaseType.self)
  }

  mutating func decodeMapField<KeyType, ValueType>(
    fieldType: _ProtobufEnumMap<KeyType, ValueType>.Type,
    value: inout _ProtobufEnumMap<KeyType, ValueType>.BaseType
  ) throws {
    value = try _value(as: _ProtobufEnumMap<KeyType, ValueType>.BaseType.self)
  }

  mutating func decodeMapField<KeyType, ValueType>(
    fieldType: _ProtobufMessageMap<KeyType, ValueType>.Type,
    value: inout _ProtobufMessageMap<KeyType, ValueType>.BaseType
  ) throws {
    value = try _value(as: _ProtobufMessageMap<KeyType, ValueType>.BaseType.self)
  }

  mutating func decodeExtensionField(
    values: inout ExtensionFieldValueSet,
    messageType: Message.Type,
    fieldNumber: Int
  ) throws {
    try values.modify(index: fieldNumber) { ext in
      try ext?.decodeExtensionField(decoder: &self)
    }
  }

}

public extension Message {
  func applying(_ value: Any, for fieldNumber: Int) throws -> Self {
    var copy = self
    try copy.apply(value, for: fieldNumber)
    return copy
  }

  mutating func apply(_ value: Any, for fieldNumber: Int) throws {
    var decoder = ApplyingDecoder(fieldNumber: fieldNumber, value: value)
    try decodeMessage(decoder: &decoder)
  }
}
