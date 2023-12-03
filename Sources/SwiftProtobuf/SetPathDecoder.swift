// Sources/SwiftProtobuf/SetPathDecoder.swift - Path decoder (Setter)
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Decoder which sets value of a field by its path.
///
// -----------------------------------------------------------------------------

import Foundation

extension Message {
  static func number(for field: String) -> Int? {
    guard let type = Self.self as? _ProtoNameProviding.Type else {
      return nil
    }
    return type._protobuf_nameMap.number(forJSONName: field)
  }
}

enum PathDecodingError: Error {
  case typeMismatch
}

struct SetPathDecoder<T: Message>: Decoder {

  private let path: String
  private let value: Any?
  private var number: Int?

  init(path: String, value: Any?) {
    self.path = path
    self.value = value
    if let firstPathComponent {
      self.number = T.number(for: firstPathComponent)
    }
  }

  var firstPathComponent: String? {
    return path
          .components(separatedBy: ".")
          .first
  }

  var nextPath: String {
    return path
          .components(separatedBy: ".")
          .dropFirst()
          .joined(separator: ".")
  }

  func _value<V>(as: V.Type) throws -> V {
    guard let __value = self.value as? V else {
      throw PathDecodingError.typeMismatch
    }
    return __value
  }

  mutating func handleConflictingOneOf() throws {}

  mutating func nextFieldNumber() throws -> Int? {
    defer { number = nil }
    return number
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

  mutating func decodeSingularEnumField<E>(
    value: inout E
  ) throws where E : Enum, E.RawValue == Int {
    value = try _value(as: E.self)
  }

  mutating func decodeSingularEnumField<E>(
    value: inout E?
  ) throws where E : Enum, E.RawValue == Int {
    value = try _value(as: E?.self)
  }

  mutating func decodeRepeatedEnumField<E>(
    value: inout [E]
  ) throws where E : Enum, E.RawValue == Int {
    value = try _value(as: [E].self)
  }

  mutating func decodeSingularMessageField<M>(
    value: inout M?
  ) throws where M : Message {
    if nextPath.isEmpty {
      value = try _value(as: M?.self)
      return
    }
    var decoder = SetPathDecoder<M>(
        path: nextPath, value: self.value
    )
    try value?.decodeMessage(decoder: &decoder)
  }

  mutating func decodeRepeatedMessageField<M>(
    value: inout [M]
  ) throws where M : Message {
    value = try _value(as: [M].self)
  }

  mutating func decodeSingularGroupField<G>(
    value: inout G?
  ) throws where G : Message {
    value = try _value(as: G?.self)
  }

  mutating func decodeRepeatedGroupField<G>(
    value: inout [G]
  ) throws where G : Message {
    value = try _value(as: [G].self)
  }

  mutating func decodeMapField<KeyType, ValueType>(
    fieldType: _ProtobufMap<KeyType, ValueType>.Type,
    value: inout _ProtobufMap<KeyType, ValueType>.BaseType
  ) throws where KeyType : MapKeyType, ValueType : MapValueType {
    value = try _value(as: _ProtobufMap<KeyType, ValueType>.BaseType.self)
  }

  mutating func decodeMapField<KeyType, ValueType>(
    fieldType: _ProtobufEnumMap<KeyType, ValueType>.Type,
    value: inout _ProtobufEnumMap<KeyType, ValueType>.BaseType
  ) throws where KeyType : MapKeyType, ValueType : Enum, ValueType.RawValue == Int {
    value = try _value(as: _ProtobufEnumMap<KeyType, ValueType>.BaseType.self)
  }

  mutating func decodeMapField<KeyType, ValueType>(
    fieldType: _ProtobufMessageMap<KeyType, ValueType>.Type,
    value: inout _ProtobufMessageMap<KeyType, ValueType>.BaseType
  ) throws where KeyType : MapKeyType, ValueType : Hashable, ValueType : Message {
    value = try _value(as: _ProtobufMessageMap<KeyType, ValueType>.BaseType.self)
  }

  mutating func decodeExtensionField(values: inout ExtensionFieldValueSet, messageType: Message.Type, fieldNumber: Int) throws {}

}

extension Message {
  mutating func `set`(path: String, value: Any?) throws {
    var decoder = SetPathDecoder<Self>(path: path, value: value)
    try decodeMessage(decoder: &decoder)
  }
}
