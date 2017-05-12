// Sources/SwiftProtobuf/JSONMapEncodingVisitor.swift - JSON map encoding visitor
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Visitor that writes out the key/value pairs for a JSON map.
///
// -----------------------------------------------------------------------------

import Foundation

/// Visitor that serializes a message into JSON map format.
///
/// This expects to alternately visit the keys and values for a JSON
/// map.  It only accepts singular values.  Keys should be identified
/// as `fieldNumber:1`, values should be identified as `fieldNumber:2`
///
internal struct JSONMapEncodingVisitor: Visitor {
  private var separator: StaticString?
  internal var encoder: JSONEncoder

  init(encoder: JSONEncoder) {
      self.encoder = encoder
  }

  private mutating func startKey() {
      if let s = separator {
          encoder.append(staticText: s)
      } else {
          separator = ","
      }
  }

  private mutating func startValue() {
      encoder.append(staticText: ":")
  }

  mutating func visitUnknown(bytes: Data) throws {
      assert(false)
  }

  mutating func visitSingularDoubleField(value: Double, fieldNumber: Int) throws {
      // Doubles/Floats can never be map keys, only values
      assert(fieldNumber == 2)
      startValue()
      encoder.putDoubleValue(value: value)
  }

  mutating func visitSingularInt32Field(value: Int32, fieldNumber: Int) throws {
      if fieldNumber == 1 {
          startKey()
          encoder.putQuotedInt32(value: value)
      } else {
          startValue()
          encoder.putInt32(value: value)
      }
  }

  mutating func visitSingularInt64Field(value: Int64, fieldNumber: Int) throws {
      if fieldNumber == 1 {
          startKey()
      } else {
          startValue()
      }
      // Int64 fields are always quoted anyway
      encoder.putInt64(value: value)
  }

  mutating func visitSingularUInt32Field(value: UInt32, fieldNumber: Int) throws {
      if fieldNumber == 1 {
          startKey()
          encoder.putQuotedUInt32(value: value)
      } else {
          startValue()
          encoder.putUInt32(value: value)
      }
  }

  mutating func visitSingularUInt64Field(value: UInt64, fieldNumber: Int) throws {
      if fieldNumber == 1 {
          startKey()
      } else {
          startValue()
      }
      encoder.putUInt64(value: value)
  }

  mutating func visitSingularBoolField(value: Bool, fieldNumber: Int) throws {
      if fieldNumber == 1 {
          startKey()
          encoder.putQuotedBoolValue(value: value)
      } else {
          startValue()
          encoder.putBoolValue(value: value)
      }
  }

  mutating func visitSingularStringField(value: String, fieldNumber: Int) throws {
      if fieldNumber == 1 {
          startKey()
      } else {
          startValue()
      }
      encoder.putStringValue(value: value)
  }

  mutating func visitSingularBytesField(value: Data, fieldNumber: Int) throws {
      // Bytes can only be map values, never keys
      assert(fieldNumber == 2)
      startValue()
      encoder.putBytesValue(value: value)
  }

  mutating func visitSingularEnumField<E: Enum>(value: E, fieldNumber: Int) throws {
      // Enums can only be map values, never keys
      assert(fieldNumber == 2)
      startValue()
      if let n = value.name {
          encoder.putStringValue(value: String(describing: n))
      } else {
          encoder.putEnumInt(value: value.rawValue)
      }
  }

  mutating func visitSingularMessageField<M: Message>(value: M, fieldNumber: Int) throws {
      // Messages can only be map values, never keys
      assert(fieldNumber == 2)
      startValue()
      let json = try value.jsonString()
      encoder.append(text: json)
  }

  mutating func visitSingularGroupField<G: Message>(value: G, fieldNumber: Int) throws {
      // protoc does not permit group-valued maps
      assert(false)
  }

  // Repeated values are not supported in maps.

  mutating func visitRepeatedFloatField(value: [Float], fieldNumber: Int) throws {
      assert(false)
  }

  mutating func visitRepeatedDoubleField(value: [Double], fieldNumber: Int) throws {
      assert(false)
  }

  mutating func visitRepeatedInt32Field(value: [Int32], fieldNumber: Int) throws {
      assert(false)
  }

  mutating func visitRepeatedInt64Field(value: [Int64], fieldNumber: Int) throws {
      assert(false)
  }

  mutating func visitRepeatedUInt32Field(value: [UInt32], fieldNumber: Int) throws {
      assert(false)
  }

  mutating func visitRepeatedUInt64Field(value: [UInt64], fieldNumber: Int) throws {
      assert(false)
  }

  mutating func visitRepeatedSInt32Field(value: [Int32], fieldNumber: Int) throws {
      assert(false)
  }

  mutating func visitRepeatedSInt64Field(value: [Int64], fieldNumber: Int) throws {
      assert(false)
  }

  mutating func visitRepeatedFixed32Field(value: [UInt32], fieldNumber: Int) throws {
      assert(false)
  }

  mutating func visitRepeatedFixed64Field(value: [UInt64], fieldNumber: Int) throws {
      assert(false)
  }

  mutating func visitRepeatedSFixed32Field(value: [Int32], fieldNumber: Int) throws {
      assert(false)
  }

  mutating func visitRepeatedSFixed64Field(value: [Int64], fieldNumber: Int) throws {
      assert(false)
  }

  mutating func visitRepeatedBoolField(value: [Bool], fieldNumber: Int) throws {
      assert(false)
  }

  mutating func visitRepeatedStringField(value: [String], fieldNumber: Int) throws {
      assert(false)
  }

  mutating func visitRepeatedBytesField(value: [Data], fieldNumber: Int) throws {
      assert(false)
  }

  mutating func visitRepeatedEnumField<E: Enum>(value: [E], fieldNumber: Int) throws {
      assert(false)
  }

  mutating func visitRepeatedMessageField<M: Message>(value: [M], fieldNumber: Int) throws {
      assert(false)
  }

  mutating func visitRepeatedGroupField<G: Message>(value: [G], fieldNumber: Int) throws {
      assert(false)
  }

  // Packed values are not supported in maps.

  mutating func visitPackedFloatField(value: [Float], fieldNumber: Int) throws {
      assert(false)
  }

  mutating func visitPackedDoubleField(value: [Double], fieldNumber: Int) throws {
      assert(false)
  }

  mutating func visitPackedInt32Field(value: [Int32], fieldNumber: Int) throws {
      assert(false)
  }

  mutating func visitPackedInt64Field(value: [Int64], fieldNumber: Int) throws {
      assert(false)
  }

  mutating func visitPackedUInt32Field(value: [UInt32], fieldNumber: Int) throws {
      assert(false)
  }

  mutating func visitPackedUInt64Field(value: [UInt64], fieldNumber: Int) throws {
      assert(false)
  }

  mutating func visitPackedSInt32Field(value: [Int32], fieldNumber: Int) throws {
      assert(false)
  }

  mutating func visitPackedSInt64Field(value: [Int64], fieldNumber: Int) throws {
      assert(false)
  }

  mutating func visitPackedFixed32Field(value: [UInt32], fieldNumber: Int) throws {
      assert(false)
  }

  mutating func visitPackedFixed64Field(value: [UInt64], fieldNumber: Int) throws {
      assert(false)
  }

  mutating func visitPackedSFixed32Field(value: [Int32], fieldNumber: Int) throws {
      assert(false)
  }

  mutating func visitPackedSFixed64Field(value: [Int64], fieldNumber: Int) throws {
      assert(false)
  }

  mutating func visitPackedBoolField(value: [Bool], fieldNumber: Int) throws {
      assert(false)
  }

  mutating func visitPackedEnumField<E: Enum>(value: [E], fieldNumber: Int) throws {
      assert(false)
  }

  // Maps cannot directly appear in other maps

  mutating func visitMapField<KeyType, ValueType: MapValueType>(fieldType: _ProtobufMap<KeyType, ValueType>.Type, value: _ProtobufMap<KeyType, ValueType>.BaseType, fieldNumber: Int) throws {
      assert(false)
  }

  mutating func visitMapField<KeyType, ValueType>(fieldType: _ProtobufEnumMap<KeyType, ValueType>.Type, value: _ProtobufEnumMap<KeyType, ValueType>.BaseType, fieldNumber: Int) throws  where ValueType.RawValue == Int {
      assert(false)
  }

  mutating func visitMapField<KeyType, ValueType>(fieldType: _ProtobufMessageMap<KeyType, ValueType>.Type, value: _ProtobufMessageMap<KeyType, ValueType>.BaseType, fieldNumber: Int) throws {
      assert(false)
  }

  // Extensions cannot appear in maps
  mutating func visitExtensionFields(fields: ExtensionFieldValueSet, start: Int, end: Int) throws {
      assert(false)
  }
}
