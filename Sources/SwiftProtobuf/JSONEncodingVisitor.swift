// Sources/SwiftProtobuf/JSONEncodingVisitor.swift - JSON encoding visitor
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
// -----------------------------------------------------------------------------
///
/// Visitor that writes a message in JSON format.
///
// -----------------------------------------------------------------------------

import Foundation

/// Visitor that serializes a message into JSON format.
internal struct JSONEncodingVisitor: Visitor {

  internal var encoder = JSONEncoder()
  private var nameResolver: (Int) -> StaticString?

  /// The JSON text produced by the visitor, as raw UTF8 bytes.
  var dataResult: Data {
    return encoder.dataResult
  }

  /// The JSON text produced by the visitor, as a String.
  internal var stringResult: String {
      return encoder.stringResult
  }

  /// Creates a new visitor that serializes the given message to JSON format.
  init(message: Message) {
    self.nameResolver =
      ProtoNameResolvers.jsonFieldNameResolver(for: message)
  }

  mutating func visitUnknown(bytes: Data) throws {
    // JSON encoding has no provision for carrying proto2 unknown fields.
  }

  mutating func visitSingularDoubleField(value: Double, fieldNumber: Int) throws {
    try startField(for: fieldNumber)
    encoder.putDoubleValue(value: value)
  }

  mutating func visitSingularInt32Field(value: Int32, fieldNumber: Int) throws {
    try startField(for: fieldNumber)
    encoder.putInt32(value: value)
  }

  mutating func visitSingularInt64Field(value: Int64, fieldNumber: Int) throws {
    try startField(for: fieldNumber)
    encoder.putInt64(value: value)
  }

  mutating func visitSingularUInt32Field(value: UInt32, fieldNumber: Int) throws {
    try startField(for: fieldNumber)
    encoder.putUInt32(value: value)
  }

  mutating func visitSingularUInt64Field(value: UInt64, fieldNumber: Int) throws {
    try startField(for: fieldNumber)
    encoder.putUInt64(value: value)
  }

  mutating func visitSingularFixed32Field(value: UInt32, fieldNumber: Int) throws {
    try startField(for: fieldNumber)
    encoder.putUInt32(value: value)
  }

  mutating func visitSingularSFixed32Field(value: Int32, fieldNumber: Int) throws {
    try startField(for: fieldNumber)
    encoder.putInt32(value: value)
  }

  mutating func visitSingularBoolField(value: Bool, fieldNumber: Int) throws {
    try startField(for: fieldNumber)
    encoder.putBoolValue(value: value)
  }

  mutating func visitSingularStringField(value: String, fieldNumber: Int) throws {
    try startField(for: fieldNumber)
    encoder.putStringValue(value: value)
  }

  mutating func visitSingularBytesField(value: Data, fieldNumber: Int) throws {
    try startField(for: fieldNumber)
    encoder.putBytesValue(value: value)
  }

  private mutating func _visitRepeated<T>(value: [T], fieldNumber: Int, encode: (T) -> ()) throws {
    try startField(for: fieldNumber)
    var arraySeparator = ""
    encoder.append(text: "[")
    for v in value {
      encoder.append(text: arraySeparator)
      encode(v)
      arraySeparator = ","
    }
    encoder.append(text: "]")
  }

  mutating func visitSingularEnumField<E: Enum>(value: E, fieldNumber: Int) throws {
    try startField(for: fieldNumber)
    if let n = value.name {
      encoder.putStringValue(value: String(describing: n))
    } else {
      encoder.putEnumInt(value: value.rawValue)
    }
  }

  mutating func visitSingularMessageField<M: Message>(value: M, fieldNumber: Int) throws {
    try startField(for: fieldNumber)
    let json = try value.jsonString()
    encoder.append(text: json)
  }

  mutating func visitSingularGroupField<G: Message>(value: G, fieldNumber: Int) throws {
    // Google does not serialize groups into JSON
  }

  mutating func visitRepeatedFloatField(value: [Float], fieldNumber: Int) throws {
    try _visitRepeated(value: value, fieldNumber: fieldNumber) { (v: Float) in
      encoder.putFloatValue(value: v)
    }
  }

  mutating func visitRepeatedDoubleField(value: [Double], fieldNumber: Int) throws {
    try _visitRepeated(value: value, fieldNumber: fieldNumber) { (v: Double) in
      encoder.putDoubleValue(value: v)
    }
  }

  mutating func visitRepeatedInt32Field(value: [Int32], fieldNumber: Int) throws {
    try _visitRepeated(value: value, fieldNumber: fieldNumber) { (v: Int32) in
      encoder.putInt32(value: v)
    }
  }

  mutating func visitRepeatedInt64Field(value: [Int64], fieldNumber: Int) throws {
    try _visitRepeated(value: value, fieldNumber: fieldNumber) { (v: Int64) in
      encoder.putInt64(value: v)
    }
  }

   mutating func visitRepeatedUInt32Field(value: [UInt32], fieldNumber: Int) throws {
    try _visitRepeated(value: value, fieldNumber: fieldNumber) { (v: UInt32) in
      encoder.putUInt32(value: v)
    }
  }

  mutating func visitRepeatedUInt64Field(value: [UInt64], fieldNumber: Int) throws {
    try _visitRepeated(value: value, fieldNumber: fieldNumber) { (v: UInt64) in
      encoder.putUInt64(value: v)
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
    try _visitRepeated(value: value, fieldNumber: fieldNumber) { (v: Bool) in
      encoder.putBoolValue(value: v)
    }
  }

  mutating func visitRepeatedStringField(value: [String], fieldNumber: Int) throws {
    try _visitRepeated(value: value, fieldNumber: fieldNumber) { (v: String) in
      encoder.putStringValue(value: v)
    }
  }

  mutating func visitRepeatedBytesField(value: [Data], fieldNumber: Int) throws {
    try _visitRepeated(value: value, fieldNumber: fieldNumber) { (v: Data) in
      encoder.putBytesValue(value: v)
    }
  }

  mutating func visitRepeatedEnumField<E: Enum>(value: [E], fieldNumber: Int) throws {
    try startField(for: fieldNumber)
    var arraySeparator = ""
    encoder.append(text: "[")
    for v in value {
      encoder.append(text: arraySeparator)
      if let n = v.name {
        encoder.putStringValue(value: String(describing: n))
      } else {
        encoder.putEnumInt(value: v.rawValue)
      }
      arraySeparator = ","
    }
    encoder.append(text: "]")
  }

  mutating func visitRepeatedMessageField<M: Message>(value: [M], fieldNumber: Int) throws {
    try startField(for: fieldNumber)
    var arraySeparator = ""
    encoder.append(text: "[")
    for v in value {
      encoder.append(text: arraySeparator)
      let json = try v.jsonString()
      encoder.append(text: json)
      arraySeparator = ","
    }
    encoder.append(text: "]")
  }

  mutating func visitRepeatedGroupField<G: Message>(value: [G], fieldNumber: Int) throws {
    // Google does not serialize groups into JSON
  }

  // Packed fields are handled the same as non-packed fields, so JSON just
  // relies on the default implementations in Visitor.swift



  mutating func visitMapField<KeyType: MapKeyType, ValueType: MapValueType>(fieldType: _ProtobufMap<KeyType, ValueType>.Type, value: _ProtobufMap<KeyType, ValueType>.BaseType, fieldNumber: Int) throws  where KeyType.BaseType: Hashable {
    try startField(for: fieldNumber)
    encoder.append(text: "{")
    var mapVisitor = JSONMapEncodingVisitor(encoder: encoder)
    for (k,v) in value {
        try KeyType.visitSingular(value: k, fieldNumber: 1, with: &mapVisitor)
        try ValueType.visitSingular(value: v, fieldNumber: 2, with: &mapVisitor)
    }
    encoder = mapVisitor.encoder
    encoder.append(text: "}")
  }

  mutating func visitMapField<KeyType: MapKeyType, ValueType: Enum>(fieldType: _ProtobufEnumMap<KeyType, ValueType>.Type, value: _ProtobufEnumMap<KeyType, ValueType>.BaseType, fieldNumber: Int) throws  where KeyType.BaseType: Hashable, ValueType.RawValue == Int {
    try startField(for: fieldNumber)
    encoder.append(text: "{")
    var mapVisitor = JSONMapEncodingVisitor(encoder: encoder)
    for (k, v) in value {
      try KeyType.visitSingular(value: k, fieldNumber: 1, with: &mapVisitor)
      try mapVisitor.visitSingularEnumField(value: v, fieldNumber: 2)
    }
    encoder = mapVisitor.encoder
    encoder.append(text: "}")
  }

  mutating func visitMapField<KeyType: MapKeyType, ValueType: Message & Hashable>(fieldType: _ProtobufMessageMap<KeyType, ValueType>.Type, value: _ProtobufMessageMap<KeyType, ValueType>.BaseType, fieldNumber: Int) throws  where KeyType.BaseType: Hashable {
    try startField(for: fieldNumber)
    encoder.append(text: "{")
    var mapVisitor = JSONMapEncodingVisitor(encoder: encoder)
    for (k,v) in value {
        try KeyType.visitSingular(value: k, fieldNumber: 1, with: &mapVisitor)
        try mapVisitor.visitSingularMessageField(value: v, fieldNumber: 2)
    }
    encoder = mapVisitor.encoder
    encoder.append(text: "}")
  }

  /// Called for each extension range.
  mutating func visitExtensionFields(fields: ExtensionFieldValueSet, start: Int, end: Int) throws {
    // JSON does not store extensions
  }

  /// Helper function that throws an error if the field number could not be
  /// resolved.
  private mutating func startField(for number: Int) throws {
    if let jsonName = nameResolver(number) {
        encoder.startField(name: jsonName)
    } else {
        throw JSONEncodingError.missingFieldNames
    }
  }
}
