// Sources/SwiftProtobuf/GetPathDecoder.swift - Path decoder (Getter)
//
// Copyright (c) 2014 - 2023 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Decoder which captures value of a field by its path.
///
// -----------------------------------------------------------------------------

import Foundation

struct GetPathDecoder<T: Message>: Decoder {

  private let nextPath: [String]
  private var number: Int?

  private var _value: Any?
  private var _hasPath: Bool = false

  internal var value: Any? {
    _value
  }

  internal var hasPath: Bool {
    _hasPath
  }

  internal init(path: [String]) {
    if let firstComponent = path.first {
      self.number = T.number(for: firstComponent)
    }
    self.nextPath = .init(path.dropFirst())
  }

  mutating func handleConflictingOneOf() throws {}

  mutating func nextFieldNumber() throws -> Int? {
    defer { number = nil }
    return number
  }

  private mutating func captureValue(_ value: Any?) {
    self._value = value
    self._hasPath = true
  }

  mutating func decodeSingularFloatField(value: inout Float) throws {
    captureValue(value)
  }

  mutating func decodeSingularFloatField(value: inout Float?) throws {
    captureValue(value)
  }

  mutating func decodeRepeatedFloatField(value: inout [Float]) throws {
    captureValue(value)
  }

  mutating func decodeSingularDoubleField(value: inout Double) throws {
    captureValue(value)
  }

  mutating func decodeSingularDoubleField(value: inout Double?) throws {
    captureValue(value)
  }

  mutating func decodeRepeatedDoubleField(value: inout [Double]) throws {
    captureValue(value)
  }

  mutating func decodeSingularInt32Field(value: inout Int32) throws {
    captureValue(value)
  }

  mutating func decodeSingularInt32Field(value: inout Int32?) throws {
    captureValue(value)
  }

  mutating func decodeRepeatedInt32Field(value: inout [Int32]) throws {
    captureValue(value)
  }

  mutating func decodeSingularInt64Field(value: inout Int64) throws {
    captureValue(value)
  }

  mutating func decodeSingularInt64Field(value: inout Int64?) throws {
    captureValue(value)
  }

  mutating func decodeRepeatedInt64Field(value: inout [Int64]) throws {
    captureValue(value)
  }

  mutating func decodeSingularUInt32Field(value: inout UInt32) throws {
    captureValue(value)
  }

  mutating func decodeSingularUInt32Field(value: inout UInt32?) throws {
    captureValue(value)
  }

  mutating func decodeRepeatedUInt32Field(value: inout [UInt32]) throws {
    captureValue(value)
  }

  mutating func decodeSingularUInt64Field(value: inout UInt64) throws {
    captureValue(value)
  }

  mutating func decodeSingularUInt64Field(value: inout UInt64?) throws {
    captureValue(value)
  }

  mutating func decodeRepeatedUInt64Field(value: inout [UInt64]) throws {
    captureValue(value)
  }

  mutating func decodeSingularSInt32Field(value: inout Int32) throws {
    captureValue(value)
  }

  mutating func decodeSingularSInt32Field(value: inout Int32?) throws {
    captureValue(value)
  }

  mutating func decodeRepeatedSInt32Field(value: inout [Int32]) throws {
    captureValue(value)
  }

  mutating func decodeSingularSInt64Field(value: inout Int64) throws {
    captureValue(value)
  }

  mutating func decodeSingularSInt64Field(value: inout Int64?) throws {
    captureValue(value)
  }

  mutating func decodeRepeatedSInt64Field(value: inout [Int64]) throws {
    captureValue(value)
  }

  mutating func decodeSingularFixed32Field(value: inout UInt32) throws {
    captureValue(value)
  }

  mutating func decodeSingularFixed32Field(value: inout UInt32?) throws {
    captureValue(value)
  }

  mutating func decodeRepeatedFixed32Field(value: inout [UInt32]) throws {
    captureValue(value)
  }

  mutating func decodeSingularFixed64Field(value: inout UInt64) throws {
    captureValue(value)
  }

  mutating func decodeSingularFixed64Field(value: inout UInt64?) throws {
    captureValue(value)
  }

  mutating func decodeRepeatedFixed64Field(value: inout [UInt64]) throws {
    captureValue(value)
  }

  mutating func decodeSingularSFixed32Field(value: inout Int32) throws {
    captureValue(value)
  }

  mutating func decodeSingularSFixed32Field(value: inout Int32?) throws {
    captureValue(value)
  }

  mutating func decodeRepeatedSFixed32Field(value: inout [Int32]) throws {
    captureValue(value)
  }

  mutating func decodeSingularSFixed64Field(value: inout Int64) throws {
    captureValue(value)
  }

  mutating func decodeSingularSFixed64Field(value: inout Int64?) throws {
    captureValue(value)
  }

  mutating func decodeRepeatedSFixed64Field(value: inout [Int64]) throws {
    captureValue(value)
  }

  mutating func decodeSingularBoolField(value: inout Bool) throws {
    captureValue(value)
  }

  mutating func decodeSingularBoolField(value: inout Bool?) throws {
    captureValue(value)
  }

  mutating func decodeRepeatedBoolField(value: inout [Bool]) throws {
    captureValue(value)
  }

  mutating func decodeSingularStringField(value: inout String) throws {
    captureValue(value)
  }

  mutating func decodeSingularStringField(value: inout String?) throws {
    captureValue(value)
  }

  mutating func decodeRepeatedStringField(value: inout [String]) throws {
    captureValue(value)
  }

  mutating func decodeSingularBytesField(value: inout Data) throws {
    captureValue(value)
  }

  mutating func decodeSingularBytesField(value: inout Data?) throws {
    captureValue(value)
  }

  mutating func decodeRepeatedBytesField(value: inout [Data]) throws {
    captureValue(value)
  }

  mutating func decodeSingularEnumField<E>(value: inout E) throws {
    captureValue(value)
  }

  mutating func decodeSingularEnumField<E>(value: inout E?) throws {
    captureValue(value)
  }

  mutating func decodeRepeatedEnumField<E>(value: inout [E]) throws {
    captureValue(value)
  }

  mutating func decodeSingularMessageField<M>(
    value: inout M?
  ) throws where M : Message {
    if nextPath.isEmpty {
      captureValue(value)
      return
    }
    var decoder = GetPathDecoder<M>(path: nextPath)
    if value != nil {
      try value?.decodeMessage(decoder: &decoder)
    } else {
      var tmp = M()
      try tmp.decodeMessage(decoder: &decoder)
    }
    self._value = decoder.value
    self._hasPath = decoder.hasPath
  }

  mutating func decodeRepeatedMessageField<M>(value: inout [M]) throws {
    captureValue(value)
  }

  mutating func decodeSingularGroupField<G>(value: inout G?) throws {
    captureValue(value)
  }

  mutating func decodeRepeatedGroupField<G>(value: inout [G]) throws {
    captureValue(value)
  }

  mutating func decodeMapField<KeyType, ValueType>(
    fieldType: _ProtobufMap<KeyType, ValueType>.Type,
    value: inout _ProtobufMap<KeyType, ValueType>.BaseType
  ) throws {
    captureValue(value)
  }

  mutating func decodeMapField<KeyType, ValueType>(
    fieldType: _ProtobufEnumMap<KeyType, ValueType>.Type,
    value: inout _ProtobufEnumMap<KeyType, ValueType>.BaseType
  ) throws {
    captureValue(value)
  }

  mutating func decodeMapField<KeyType, ValueType>(
    fieldType: _ProtobufMessageMap<KeyType, ValueType>.Type,
    value: inout _ProtobufMessageMap<KeyType, ValueType>.BaseType
  ) throws {
    captureValue(value)
  }

  mutating func decodeExtensionField(
    values: inout ExtensionFieldValueSet,
    messageType: Message.Type,
    fieldNumber: Int
  ) throws {}

}

extension Message {
  mutating func `get`(path: String) throws -> Any? {
    let _path = path.components(separatedBy: ".")
    var decoder = GetPathDecoder<Self>(path: _path)
    try decodeMessage(decoder: &decoder)
    return decoder.value
  }

  mutating func hasPath(path: String) -> Bool {
    let _path = path.components(separatedBy: ".")
    var decoder = GetPathDecoder<Self>(path: _path)
    try? decodeMessage(decoder: &decoder)
    return decoder.hasPath
  }
}
