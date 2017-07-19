// Sources/SwiftProtobuf/SelectiveVisitor.swift - Base for custom Visitors
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// A base for Visitors that only expect a subset of things to called.
///
// -----------------------------------------------------------------------------

import Foundation

/// A base for Visitors that only expects a subset of things to called.
internal protocol SelectiveVisitor: Visitor {
  // Adds nothing.
}

/// Default impls for everything so things using this only have to write the
/// methods they expect.  Asserts to catch developer errors, but becomes
/// nothing in release to keep code size small.
///
/// NOTE: This is an impl for *everything*. This means the default impls
/// provided by Visitor to bridge packed->repeated, repeated->singular, etc
/// won't kick in.
internal extension SelectiveVisitor {
  mutating func visitSingularFloatField(value: Float, fieldNumber: Int) throws {
    assert(false)
  }

  mutating func visitSingularDoubleField(value: Double, fieldNumber: Int) throws {
    assert(false)
  }

  mutating func visitSingularInt32Field(value: Int32, fieldNumber: Int) throws {
    assert(false)
  }

  mutating func visitSingularInt64Field(value: Int64, fieldNumber: Int) throws {
    assert(false)
  }

  mutating func visitSingularUInt32Field(value: UInt32, fieldNumber: Int) throws {
    assert(false)
  }

  mutating func visitSingularUInt64Field(value: UInt64, fieldNumber: Int) throws {
    assert(false)
  }

  mutating func visitSingularSInt32Field(value: Int32, fieldNumber: Int) throws {
    assert(false)
  }

  mutating func visitSingularSInt64Field(value: Int64, fieldNumber: Int) throws {
    assert(false)
  }

  mutating func visitSingularFixed32Field(value: UInt32, fieldNumber: Int) throws {
    assert(false)
  }

  mutating func visitSingularFixed64Field(value: UInt64, fieldNumber: Int) throws {
    assert(false)
  }

  mutating func visitSingularSFixed32Field(value: Int32, fieldNumber: Int) throws {
    assert(false)
  }

  mutating func visitSingularSFixed64Field(value: Int64, fieldNumber: Int) throws {
    assert(false)
  }

  mutating func visitSingularBoolField(value: Bool, fieldNumber: Int) throws {
    assert(false)
  }

  mutating func visitSingularStringField(value: String, fieldNumber: Int) throws {
    assert(false)
  }

  mutating func visitSingularBytesField(value: Data, fieldNumber: Int) throws {
    assert(false)
  }

  mutating func visitSingularEnumField<E: Enum>(value: E, fieldNumber: Int) throws {
    assert(false)
  }

  mutating func visitSingularMessageField<M: Message>(value: M, fieldNumber: Int) throws {
    assert(false)
  }

  mutating func visitSingularGroupField<G: Message>(value: G, fieldNumber: Int) throws {
    assert(false)
  }

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

  mutating func visitMapField<KeyType, ValueType: MapValueType>(
    fieldType: _ProtobufMap<KeyType, ValueType>.Type,
    value: _ProtobufMap<KeyType, ValueType>.BaseType,
    fieldNumber: Int) throws {
    assert(false)
  }

  mutating func visitMapField<KeyType, ValueType>(
    fieldType: _ProtobufEnumMap<KeyType, ValueType>.Type,
    value: _ProtobufEnumMap<KeyType, ValueType>.BaseType,
    fieldNumber: Int
  ) throws where ValueType.RawValue == Int {
    assert(false)
  }

  mutating func visitMapField<KeyType, ValueType>(
    fieldType: _ProtobufMessageMap<KeyType, ValueType>.Type,
    value: _ProtobufMessageMap<KeyType, ValueType>.BaseType,
    fieldNumber: Int
  ) throws {
    assert(false)
  }

  mutating func visitExtensionFields(fields: ExtensionFieldValueSet, start: Int, end: Int) throws {
    assert(false)
  }

  mutating func visitExtensionFieldsAsMessageSet(
    fields: ExtensionFieldValueSet,
    start: Int,
    end: Int
  ) throws {
    assert(false)
  }

  mutating func visitUnknown(bytes: Data) throws {
    assert(false)
  }
}
