// Sources/SwiftProtobuf/JSONDecoder.swift - JSON format decoding
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// JSON format decoding engine.
///
// -----------------------------------------------------------------------------

import Foundation

internal struct JSONDecoder: Decoder {
  internal var scanner: JSONScanner
  internal var messageType: Message.Type
  private var fieldCount = 0
  private var isMapKey = false
  private var fieldNameMap: _NameMap?

  internal var options: JSONDecodingOptions {
    return scanner.options
  }

  mutating func handleConflictingOneOf() throws {
    throw JSONDecodingError.conflictingOneOf
  }

  internal init(source: UnsafeRawBufferPointer, options: JSONDecodingOptions,
                messageType: Message.Type, extensions: ExtensionMap?) {
    let scanner = JSONScanner(source: source,
                               options: options,
                               extensions: extensions)
    self.init(scanner: scanner, messageType: messageType)
  }

  private init(scanner: JSONScanner, messageType: Message.Type) {
    self.scanner = scanner
    self.messageType = messageType
  }

  mutating func nextFieldNumber() throws -> Int? {
    if scanner.skipOptionalObjectEnd() {
      return nil
    }
    if fieldCount > 0 {
      try scanner.skipRequiredComma()
    }
    let fieldNumber = try scanner.nextFieldNumber(names: fieldNameMap!,
                                                  messageType: messageType)
    if let fieldNumber = fieldNumber {
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
    value = Int32(truncatingIfNeeded: n)
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
    value = Int32(truncatingIfNeeded: n)
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
      value.append(Int32(truncatingIfNeeded: n))
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
    value = UInt32(truncatingIfNeeded: n)
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
    value = UInt32(truncatingIfNeeded: n)
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
      value.append(UInt32(truncatingIfNeeded: n))
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
      value = Data()
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
      if let customDecodable = E.self as? _CustomJSONCodable.Type {
        value = try customDecodable.decodedFromJSONNull() as? E
        return
      }
      value = nil
      return
    }
    // Only change the value if a value was read.
    if let e: E = try scanner.nextEnumValue() {
      value = e
    }
  }

  mutating func decodeSingularEnumField<E: Enum>(value: inout E) throws
  where E.RawValue == Int {
    if scanner.skipOptionalNull() {
      if let customDecodable = E.self as? _CustomJSONCodable.Type {
        value = try customDecodable.decodedFromJSONNull() as! E
        return
      }
      value = E()
      return
    }
    if let e: E = try scanner.nextEnumValue() {
      value = e
    }

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
    let maybeCustomDecodable = E.self as? _CustomJSONCodable.Type
    while true {
      if scanner.skipOptionalNull() {
        if let customDecodable = maybeCustomDecodable {
          let e = try customDecodable.decodedFromJSONNull() as! E
          value.append(e)
        } else {
          throw JSONDecodingError.illegalNull
        }
      } else {
        if let e: E = try scanner.nextEnumValue() {
          value.append(e)
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
    var subDecoder = JSONDecoder(scanner: scanner, messageType: M.self)
    try subDecoder.decodeFullObject(message: &value!)
    assert(scanner.recursionBudget == subDecoder.scanner.recursionBudget)
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
        var subDecoder = JSONDecoder(scanner: scanner, messageType: M.self)
        try subDecoder.decodeFullObject(message: &message)
        value.append(message)
        assert(scanner.recursionBudget == subDecoder.scanner.recursionBudget)
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

  mutating func decodeMapField<KeyType, ValueType: MapValueType>(
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

  mutating func decodeMapField<KeyType, ValueType>(
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
      var keyFieldOpt: KeyType.BaseType?
      try KeyType.decodeSingular(value: &keyFieldOpt, from: &self)
      guard let keyField = keyFieldOpt else {
        throw JSONDecodingError.malformedMap
      }
      isMapKey = false
      try scanner.skipRequiredColon()
      var valueField: ValueType?
      try decodeSingularEnumField(value: &valueField)
      if let valueField = valueField {
        value[keyField] = valueField
      } else {
        // Nothing, the only way ``decodeSingularEnumField(value:)`` leaves
        // it as nil is if ignoreUnknownFields option is enabled which also
        // means to ignore unknown enum values.
      }
      if scanner.skipOptionalObjectEnd() {
        return
      }
      try scanner.skipRequiredComma()
    }
  }

  mutating func decodeMapField<KeyType, ValueType>(
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
    // Force-unwrap: we can only get here if the extension exists.
    let ext = scanner.extensions[messageType, fieldNumber]!

    try values.modify(index: fieldNumber) { fieldValue in
      if fieldValue != nil {
        try fieldValue!.decodeExtensionField(decoder: &self)
      } else {
        fieldValue = try ext._protobuf_newField(decoder: &self)
      }
    }
  }
}
