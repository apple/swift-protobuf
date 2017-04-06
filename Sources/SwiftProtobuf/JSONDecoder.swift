// Sources/SwiftProtobuf/JSONDecoder.swift - JSON format decoding
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// JSON format decoding engine.
///
// -----------------------------------------------------------------------------

import Foundation

internal struct JSONDecoder: Decoder {
  internal var scanner: JSONScanner
  private var fieldCount = 0
  private var isMapKey = false
  private var fieldNameMap: _NameMap?

  mutating func handleConflictingOneOf() throws {
    throw JSONDecodingError.conflictingOneOf
  }

  internal init(source: UnsafeBufferPointer<UInt8>) {
    self.scanner = JSONScanner(source: source)
  }

  private init(scanner: JSONScanner) {
    self.scanner = scanner
  }

  mutating func nextFieldNumber() throws -> Int? {
    if scanner.skipOptionalObjectEnd() {
      return nil
    }
    if fieldCount > 0 {
      try scanner.skipRequiredComma()
    }
    if let fieldNumber = try scanner.nextFieldNumber(names: fieldNameMap!) {
      fieldCount += 1
      return fieldNumber
    }
    return nil
  }

  mutating func decodeSingularFloatField(value: inout Float) throws {
    if scanner.skipOptionalNull() {
      value = 0
      return
    }
    value = try scanner.nextFloat()
  }

  mutating func decodeSingularFloatField(value: inout Float?) throws {
    if scanner.skipOptionalNull() {
      value = nil
      return
    }
    value = try scanner.nextFloat()
  }

  mutating func decodeRepeatedFloatField(value: inout [Float]) throws {
    if scanner.skipOptionalNull() {
      return
    }
    try scanner.skipRequiredArrayStart()
    if scanner.skipOptionalArrayEnd() {
      return
    }
    while true {
      let n = try scanner.nextFloat()
      value.append(n)
      if scanner.skipOptionalArrayEnd() {
        return
      }
      try scanner.skipRequiredComma()
    }
  }

  mutating func decodeSingularDoubleField(value: inout Double) throws {
    if scanner.skipOptionalNull() {
      value = 0
      return
    }
    value = try scanner.nextDouble()
  }

  mutating func decodeSingularDoubleField(value: inout Double?) throws {
    if scanner.skipOptionalNull() {
      value = nil
      return
    }
    value = try scanner.nextDouble()
  }

  mutating func decodeRepeatedDoubleField(value: inout [Double]) throws {
    if scanner.skipOptionalNull() {
      return
    }
    try scanner.skipRequiredArrayStart()
    if scanner.skipOptionalArrayEnd() {
      return
    }
    while true {
      let n = try scanner.nextDouble()
      value.append(n)
      if scanner.skipOptionalArrayEnd() {
        return
      }
      try scanner.skipRequiredComma()
    }
  }

  mutating func decodeSingularInt32Field(value: inout Int32) throws {
    if scanner.skipOptionalNull() {
      value = 0
      return
    }
    let n = try scanner.nextSInt()
    if n > Int64(Int32.max) || n < Int64(Int32.min) {
      throw JSONDecodingError.numberRange
    }
    value = Int32(truncatingBitPattern: n)
  }

  mutating func decodeSingularInt32Field(value: inout Int32?) throws {
    if scanner.skipOptionalNull() {
      value = nil
      return
    }
    let n = try scanner.nextSInt()
    if n > Int64(Int32.max) || n < Int64(Int32.min) {
      throw JSONDecodingError.numberRange
    }
    value = Int32(truncatingBitPattern: n)
  }

  mutating func decodeRepeatedInt32Field(value: inout [Int32]) throws {
    if scanner.skipOptionalNull() {
      return
    }
    try scanner.skipRequiredArrayStart()
    if scanner.skipOptionalArrayEnd() {
      return
    }
    while true {
      let n = try scanner.nextSInt()
      if n > Int64(Int32.max) || n < Int64(Int32.min) {
        throw JSONDecodingError.numberRange
      }
      value.append(Int32(truncatingBitPattern: n))
      if scanner.skipOptionalArrayEnd() {
        return
      }
      try scanner.skipRequiredComma()
    }
  }

  mutating func decodeSingularInt64Field(value: inout Int64) throws {
    if scanner.skipOptionalNull() {
      value = 0
      return
    }
    value = try scanner.nextSInt()
  }

  mutating func decodeSingularInt64Field(value: inout Int64?) throws {
    if scanner.skipOptionalNull() {
      value = nil
      return
    }
    value = try scanner.nextSInt()
  }

  mutating func decodeRepeatedInt64Field(value: inout [Int64]) throws {
    if scanner.skipOptionalNull() {
      return
    }
    try scanner.skipRequiredArrayStart()
    if scanner.skipOptionalArrayEnd() {
      return
    }
    while true {
      let n = try scanner.nextSInt()
      value.append(n)
      if scanner.skipOptionalArrayEnd() {
        return
      }
      try scanner.skipRequiredComma()
    }
  }

  mutating func decodeSingularUInt32Field(value: inout UInt32) throws {
    if scanner.skipOptionalNull() {
      value = 0
      return
    }
    let n = try scanner.nextUInt()
    if n > UInt64(UInt32.max) {
      throw JSONDecodingError.numberRange
    }
    value = UInt32(truncatingBitPattern: n)
  }

  mutating func decodeSingularUInt32Field(value: inout UInt32?) throws {
    if scanner.skipOptionalNull() {
      value = nil
      return
    }
    let n = try scanner.nextUInt()
    if n > UInt64(UInt32.max) {
      throw JSONDecodingError.numberRange
    }
    value = UInt32(truncatingBitPattern: n)
  }

  mutating func decodeRepeatedUInt32Field(value: inout [UInt32]) throws {
    if scanner.skipOptionalNull() {
      return
    }
    try scanner.skipRequiredArrayStart()
    if scanner.skipOptionalArrayEnd() {
      return
    }
    while true {
      let n = try scanner.nextUInt()
      if n > UInt64(UInt32.max) {
        throw JSONDecodingError.numberRange
      }
      value.append(UInt32(truncatingBitPattern: n))
      if scanner.skipOptionalArrayEnd() {
        return
      }
      try scanner.skipRequiredComma()
    }
  }

  mutating func decodeSingularUInt64Field(value: inout UInt64) throws {
    if scanner.skipOptionalNull() {
      value = 0
      return
    }
    value = try scanner.nextUInt()
  }

  mutating func decodeSingularUInt64Field(value: inout UInt64?) throws {
    if scanner.skipOptionalNull() {
      value = nil
      return
    }
    value = try scanner.nextUInt()
  }

  mutating func decodeRepeatedUInt64Field(value: inout [UInt64]) throws {
    if scanner.skipOptionalNull() {
      return
    }
    try scanner.skipRequiredArrayStart()
    if scanner.skipOptionalArrayEnd() {
      return
    }
    while true {
      let n = try scanner.nextUInt()
      value.append(n)
      if scanner.skipOptionalArrayEnd() {
        return
      }
      try scanner.skipRequiredComma()
    }
  }

  mutating func decodeSingularSInt32Field(value: inout Int32) throws {
    try decodeSingularInt32Field(value: &value)
  }

  mutating func decodeSingularSInt32Field(value: inout Int32?) throws {
    try decodeSingularInt32Field(value: &value)
  }

  mutating func decodeRepeatedSInt32Field(value: inout [Int32]) throws {
    try decodeRepeatedInt32Field(value: &value)
  }

  mutating func decodeSingularSInt64Field(value: inout Int64) throws {
    try decodeSingularInt64Field(value: &value)
  }

  mutating func decodeSingularSInt64Field(value: inout Int64?) throws {
    try decodeSingularInt64Field(value: &value)
  }

  mutating func decodeRepeatedSInt64Field(value: inout [Int64]) throws {
    try decodeRepeatedInt64Field(value: &value)
  }

  mutating func decodeSingularFixed32Field(value: inout UInt32) throws {
    try decodeSingularUInt32Field(value: &value)
  }

  mutating func decodeSingularFixed32Field(value: inout UInt32?) throws {
    try decodeSingularUInt32Field(value: &value)
  }

  mutating func decodeRepeatedFixed32Field(value: inout [UInt32]) throws {
    try decodeRepeatedUInt32Field(value: &value)
  }

  mutating func decodeSingularFixed64Field(value: inout UInt64) throws {
    try decodeSingularUInt64Field(value: &value)
  }

  mutating func decodeSingularFixed64Field(value: inout UInt64?) throws {
    try decodeSingularUInt64Field(value: &value)
  }

  mutating func decodeRepeatedFixed64Field(value: inout [UInt64]) throws {
    try decodeRepeatedUInt64Field(value: &value)
  }

  mutating func decodeSingularSFixed32Field(value: inout Int32) throws {
    try decodeSingularInt32Field(value: &value)
  }

  mutating func decodeSingularSFixed32Field(value: inout Int32?) throws {
    try decodeSingularInt32Field(value: &value)
  }

  mutating func decodeRepeatedSFixed32Field(value: inout [Int32]) throws {
    try decodeRepeatedInt32Field(value: &value)
  }

  mutating func decodeSingularSFixed64Field(value: inout Int64) throws {
    try decodeSingularInt64Field(value: &value)
  }

  mutating func decodeSingularSFixed64Field(value: inout Int64?) throws {
    try decodeSingularInt64Field(value: &value)
  }

  mutating func decodeRepeatedSFixed64Field(value: inout [Int64]) throws {
    try decodeRepeatedInt64Field(value: &value)
  }

  mutating func decodeSingularBoolField(value: inout Bool) throws {
    if scanner.skipOptionalNull() {
      value = false
      return
    }
    if isMapKey {
      value = try scanner.nextQuotedBool()
    } else {
      value = try scanner.nextBool()
    }
  }

  mutating func decodeSingularBoolField(value: inout Bool?) throws {
    if scanner.skipOptionalNull() {
      value = nil
      return
    }
    if isMapKey {
      value = try scanner.nextQuotedBool()
    } else {
      value = try scanner.nextBool()
    }
  }

  mutating func decodeRepeatedBoolField(value: inout [Bool]) throws {
    if scanner.skipOptionalNull() {
      return
    }
    try scanner.skipRequiredArrayStart()
    if scanner.skipOptionalArrayEnd() {
      return
    }
    while true {
      let n = try scanner.nextBool()
      value.append(n)
      if scanner.skipOptionalArrayEnd() {
        return
      }
      try scanner.skipRequiredComma()
    }
  }

  mutating func decodeSingularStringField(value: inout String) throws {
    if scanner.skipOptionalNull() {
      value = String()
      return
    }
    value = try scanner.nextQuotedString()
  }

  mutating func decodeSingularStringField(value: inout String?) throws {
    if scanner.skipOptionalNull() {
      value = nil
      return
    }
    value = try scanner.nextQuotedString()
  }

  mutating func decodeRepeatedStringField(value: inout [String]) throws {
    if scanner.skipOptionalNull() {
      return
    }
    try scanner.skipRequiredArrayStart()
    if scanner.skipOptionalArrayEnd() {
      return
    }
    while true {
      let n = try scanner.nextQuotedString()
      value.append(n)
      if scanner.skipOptionalArrayEnd() {
        return
      }
      try scanner.skipRequiredComma()
    }
  }

  mutating func decodeSingularBytesField(value: inout Data) throws {
    if scanner.skipOptionalNull() {
      value = Internal.emptyData
      return
    }
    value = try scanner.nextBytesValue()
  }

  mutating func decodeSingularBytesField(value: inout Data?) throws {
    if scanner.skipOptionalNull() {
      value = nil
      return
    }
    value = try scanner.nextBytesValue()
  }

  mutating func decodeRepeatedBytesField(value: inout [Data]) throws {
    if scanner.skipOptionalNull() {
      return
    }
    try scanner.skipRequiredArrayStart()
    if scanner.skipOptionalArrayEnd() {
      return
    }
    while true {
      let n = try scanner.nextBytesValue()
      value.append(n)
      if scanner.skipOptionalArrayEnd() {
        return
      }
      try scanner.skipRequiredComma()
    }
  }


  mutating func decodeSingularEnumField<E: Enum>(value: inout E?) throws
  where E.RawValue == Int {
    if scanner.skipOptionalNull() {
      value = nil
      return
    } else if let name = try scanner.nextOptionalQuotedString() {
      if let v = E(name: name) {
        value = v
        return
      }
    } else {
      let n = try scanner.nextSInt()
      if let i = Int(exactly: n) {
        value = E(rawValue: i)
        return
      }
    }
    throw JSONDecodingError.unrecognizedEnumValue
  }

  mutating func decodeSingularEnumField<E: Enum>(value: inout E) throws
  where E.RawValue == Int {
    if scanner.skipOptionalNull() {
      value = E()
      return
    } else if let name = try scanner.nextOptionalQuotedString() {
      if let v = E(name: name) {
        value = v
        return
      }
    } else {
      let n = try scanner.nextSInt()
      if let i = Int(exactly: n) {
        if let v = E(rawValue: i) {
          value = v
          return
        }
      }
    }
    throw JSONDecodingError.unrecognizedEnumValue
  }

  mutating func decodeRepeatedEnumField<E: Enum>(value: inout [E]) throws
  where E.RawValue == Int {
    if scanner.skipOptionalNull() {
      return
    }
    try scanner.skipRequiredArrayStart()
    if scanner.skipOptionalArrayEnd() {
      return
    }
    while true {
      if let name = try scanner.nextOptionalQuotedString() {
        if let v = E(name: name) {
          value.append(v)
        } else {
          throw JSONDecodingError.unrecognizedEnumValue
        }
      } else {
        let n = try scanner.nextSInt()
        if let i = Int(exactly: n) {
          if let v = E(rawValue: i) {
            value.append(v)
          } else {
            throw JSONDecodingError.unrecognizedEnumValue
          }
        } else {
          throw JSONDecodingError.numberRange
        }
      }
      if scanner.skipOptionalArrayEnd() {
        return
      }
      try scanner.skipRequiredComma()
    }
  }

  internal mutating func decodeFullObject<M: Message>(message: inout M) throws {
    guard let nameProviding = (M.self as? _ProtoNameProviding.Type) else {
      throw JSONDecodingError.missingFieldNames
    }
    fieldNameMap = nameProviding._protobuf_nameMap
    if let m = message as? _CustomJSONCodable {
      var customCodable = m
      try customCodable.decodeJSON(from: &self)
      message = customCodable as! M
    } else {
      try scanner.skipRequiredObjectStart()
      if scanner.skipOptionalObjectEnd() {
        return
      }
      try message.decodeMessage(decoder: &self)
    }
  }

  mutating func decodeSingularMessageField<M: Message>(value: inout M?) throws {
    if scanner.skipOptionalNull() {
      if M.self is _CustomJSONCodable.Type {
        value =
          try (M.self as! _CustomJSONCodable.Type).decodedFromJSONNull() as? M
        return
      }
      // All other message field types treat 'null' as an unset
      value = nil
      return
    }
    if value == nil {
      value = M()
    }
    var subDecoder = JSONDecoder(scanner: scanner)
    try subDecoder.decodeFullObject(message: &value!)
    scanner = subDecoder.scanner
  }

  mutating func decodeRepeatedMessageField<M: Message>(
    value: inout [M]
  ) throws {
    if scanner.skipOptionalNull() {
      return
    }
    try scanner.skipRequiredArrayStart()
    if scanner.skipOptionalArrayEnd() {
      return
    }
    while true {
      if scanner.skipOptionalNull() {
        var appended = false
        if M.self is _CustomJSONCodable.Type {
          if let message = try (M.self as! _CustomJSONCodable.Type)
            .decodedFromJSONNull() as? M {
            value.append(message)
            appended = true
          }
        }
        if !appended {
          throw JSONDecodingError.illegalNull
        }
      } else {
        var message = M()
        var subDecoder = JSONDecoder(scanner: scanner)
        try subDecoder.decodeFullObject(message: &message)
        scanner = subDecoder.scanner
        value.append(message)
        scanner = subDecoder.scanner
      }
      if scanner.skipOptionalArrayEnd() {
        return
      }
      try scanner.skipRequiredComma()
    }
  }

  mutating func decodeSingularGroupField<G: Message>(value: inout G?) throws {
    throw JSONDecodingError.schemaMismatch
  }

  mutating func decodeRepeatedGroupField<G: Message>(value: inout [G]) throws {
    throw JSONDecodingError.schemaMismatch
  }

  mutating func decodeMapField<KeyType: MapKeyType, ValueType: MapValueType>(
    fieldType: _ProtobufMap<KeyType, ValueType>.Type,
    value: inout _ProtobufMap<KeyType, ValueType>.BaseType
  ) throws {
    if scanner.skipOptionalNull() {
      return
    }
    try scanner.skipRequiredObjectStart()
    if scanner.skipOptionalObjectEnd() {
      return
    }
    while true {
      // Next character must be double quote, because
      // map keys must always be quoted strings.
      let c = try scanner.peekOneCharacter()
      if c != "\"" {
        throw JSONDecodingError.unquotedMapKey
      }
      isMapKey = true
      var keyField: KeyType.BaseType?
      try KeyType.decodeSingular(value: &keyField, from: &self)
      isMapKey = false
      try scanner.skipRequiredColon()
      var valueField: ValueType.BaseType?
      try ValueType.decodeSingular(value: &valueField, from: &self)
      if let keyField = keyField, let valueField = valueField {
        value[keyField] = valueField
      } else {
        throw JSONDecodingError.malformedMap
      }
      if scanner.skipOptionalObjectEnd() {
        return
      }
      try scanner.skipRequiredComma()
    }
  }

  mutating func decodeMapField<KeyType: MapKeyType, ValueType: Enum>(
    fieldType: _ProtobufEnumMap<KeyType, ValueType>.Type,
    value: inout _ProtobufEnumMap<KeyType, ValueType>.BaseType
  ) throws where ValueType.RawValue == Int {
    if scanner.skipOptionalNull() {
      return
    }
    try scanner.skipRequiredObjectStart()
    if scanner.skipOptionalObjectEnd() {
      return
    }
    while true {
      // Next character must be double quote, because
      // map keys must always be quoted strings.
      let c = try scanner.peekOneCharacter()
      if c != "\"" {
        throw JSONDecodingError.unquotedMapKey
      }
      isMapKey = true
      var keyField: KeyType.BaseType?
      try KeyType.decodeSingular(value: &keyField, from: &self)
      isMapKey = false
      try scanner.skipRequiredColon()
      var valueField: ValueType?
      try decodeSingularEnumField(value: &valueField)
      if let keyField = keyField, let valueField = valueField {
        value[keyField] = valueField
      } else {
        throw JSONDecodingError.malformedMap
      }
      if scanner.skipOptionalObjectEnd() {
        return
      }
      try scanner.skipRequiredComma()
    }
  }

  mutating func decodeMapField<
    KeyType: MapKeyType,
    ValueType: Message & Hashable
  >(
    fieldType: _ProtobufMessageMap<KeyType, ValueType>.Type,
    value: inout _ProtobufMessageMap<KeyType, ValueType>.BaseType
  ) throws {
    if scanner.skipOptionalNull() {
      return
    }
    try scanner.skipRequiredObjectStart()
    if scanner.skipOptionalObjectEnd() {
      return
    }
    while true {
      // Next character must be double quote, because
      // map keys must always be quoted strings.
      let c = try scanner.peekOneCharacter()
      if c != "\"" {
        throw JSONDecodingError.unquotedMapKey
      }
      isMapKey = true
      var keyField: KeyType.BaseType?
      try KeyType.decodeSingular(value: &keyField, from: &self)
      isMapKey = false
      try scanner.skipRequiredColon()
      var valueField: ValueType?
      try decodeSingularMessageField(value: &valueField)
      if let keyField = keyField, let valueField = valueField {
        value[keyField] = valueField
      } else {
        throw JSONDecodingError.malformedMap
      }
      if scanner.skipOptionalObjectEnd() {
        return
      }
      try scanner.skipRequiredComma()
    }
  }

  mutating func decodeExtensionField(
    values: inout ExtensionFieldValueSet,
    messageType: Message.Type,
    fieldNumber: Int
  ) throws {
    throw JSONDecodingError.schemaMismatch
  }
}
