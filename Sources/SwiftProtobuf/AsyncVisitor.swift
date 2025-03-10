// Sources/SwiftProtobuf/Visitor.swift - Basic serialization machinery
//
// Copyright (c) 2025 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------

import Foundation

/// This is the protocol used by the generated async `traverse()` methods.
public protocol AsyncVisitor {
    /// Called for each non-repeated float field
    ///
    /// A default implementation is provided that just widens the value
    /// and calls `visitSingularDoubleField`
    mutating func visitSingularFloatField(value: inout Float, fieldNumber: Int) async throws

    /// Called for each non-repeated double field
    ///
    /// There is no default implementation.  This must be implemented.
    mutating func visitSingularDoubleField(value: inout Double, fieldNumber: Int) async throws

    /// Called for each non-repeated int32 field
    ///
    /// A default implementation is provided that just widens the value
    /// and calls `visitSingularInt64Field`
    mutating func visitSingularInt32Field(value: inout Int32, fieldNumber: Int) async throws

    /// Called for each non-repeated int64 field
    ///
    /// There is no default implementation.  This must be implemented.
    mutating func visitSingularInt64Field(value: inout Int64, fieldNumber: Int) async throws

    /// Called for each non-repeated uint32 field
    ///
    /// A default implementation is provided that just widens the value
    /// and calls `visitSingularUInt64Field`
    mutating func visitSingularUInt32Field(value: inout UInt32, fieldNumber: Int) async throws

    /// Called for each non-repeated uint64 field
    ///
    /// There is no default implementation.  This must be implemented.
    mutating func visitSingularUInt64Field(value: inout UInt64, fieldNumber: Int) async throws

    /// Called for each non-repeated sint32 field
    ///
    /// A default implementation is provided that just forwards to
    /// `visitSingularInt32Field`
    mutating func visitSingularSInt32Field(value: inout Int32, fieldNumber: Int) async throws

    /// Called for each non-repeated sint64 field
    ///
    /// A default implementation is provided that just forwards to
    /// `visitSingularInt64Field`
    mutating func visitSingularSInt64Field(value: inout Int64, fieldNumber: Int) async throws

    /// Called for each non-repeated fixed32 field
    ///
    /// A default implementation is provided that just forwards to
    /// `visitSingularUInt32Field`
    mutating func visitSingularFixed32Field(value: inout UInt32, fieldNumber: Int) async throws

    /// Called for each non-repeated fixed64 field
    ///
    /// A default implementation is provided that just forwards to
    /// `visitSingularUInt64Field`
    mutating func visitSingularFixed64Field(value: inout UInt64, fieldNumber: Int) async throws

    /// Called for each non-repeated sfixed32 field
    ///
    /// A default implementation is provided that just forwards to
    /// `visitSingularInt32Field`
    mutating func visitSingularSFixed32Field(value: inout Int32, fieldNumber: Int) async throws

    /// Called for each non-repeated sfixed64 field
    ///
    /// A default implementation is provided that just forwards to
    /// `visitSingularInt64Field`
    mutating func visitSingularSFixed64Field(value: inout Int64, fieldNumber: Int) async throws

    /// Called for each non-repeated bool field
    ///
    /// There is no default implementation.  This must be implemented.
    mutating func visitSingularBoolField(value: inout Bool, fieldNumber: Int) async throws

    /// Called for each non-repeated string field
    ///
    /// There is no default implementation.  This must be implemented.
    mutating func visitSingularStringField(value: inout String, fieldNumber: Int) async throws

    /// Called for each non-repeated bytes field
    ///
    /// There is no default implementation.  This must be implemented.
    mutating func visitSingularBytesField(value: inout Data, fieldNumber: Int) async throws

    /// Called for each non-repeated enum field
    ///
    /// There is no default implementation.  This must be implemented.
    mutating func visitSingularEnumField<E: Enum>(value: inout E, fieldNumber: Int) async throws

    /// Called for each non-repeated nested message field.
    ///
    /// There is no default implementation.  This must be implemented.
    mutating func visitSingularMessageField<M: Message>(value: inout M, fieldNumber: Int) async throws

    /// Called for each non-repeated proto2 group field.
    ///
    /// A default implementation is provided that simply forwards to
    /// `visitSingularMessageField`. Implementors who need to handle groups
    /// differently than nested messages can override this and provide distinct
    /// implementations.
    mutating func visitSingularGroupField<G: Message>(value: inout G, fieldNumber: Int) async throws

    // Called for each non-packed repeated float field.
    /// The method is called once with the complete array of values for
    /// the field.
    ///
    /// A default implementation is provided that simply calls
    /// `visitSingularFloatField` once for each item in the array.
    mutating func visitRepeatedFloatField(value: inout [Float], fieldNumber: Int) async throws

    // Called for each non-packed repeated double field.
    /// The method is called once with the complete array of values for
    /// the field.
    ///
    /// A default implementation is provided that simply calls
    /// `visitSingularDoubleField` once for each item in the array.
    mutating func visitRepeatedDoubleField(value: inout [Double], fieldNumber: Int) async throws

    // Called for each non-packed repeated int32 field.
    /// The method is called once with the complete array of values for
    /// the field.
    ///
    /// A default implementation is provided that simply calls
    /// `visitSingularInt32Field` once for each item in the array.
    mutating func visitRepeatedInt32Field(value: inout [Int32], fieldNumber: Int) async throws

    // Called for each non-packed repeated int64 field.
    /// The method is called once with the complete array of values for
    /// the field.
    ///
    /// A default implementation is provided that simply calls
    /// `visitSingularInt64Field` once for each item in the array.
    mutating func visitRepeatedInt64Field(value: inout [Int64], fieldNumber: Int) async throws

    // Called for each non-packed repeated uint32 field.
    /// The method is called once with the complete array of values for
    /// the field.
    ///
    /// A default implementation is provided that simply calls
    /// `visitSingularUInt32Field` once for each item in the array.
    mutating func visitRepeatedUInt32Field(value: inout [UInt32], fieldNumber: Int) async throws

    // Called for each non-packed repeated uint64 field.
    /// The method is called once with the complete array of values for
    /// the field.
    ///
    /// A default implementation is provided that simply calls
    /// `visitSingularUInt64Field` once for each item in the array.
    mutating func visitRepeatedUInt64Field(value: inout [UInt64], fieldNumber: Int) async throws

    // Called for each non-packed repeated sint32 field.
    /// The method is called once with the complete array of values for
    /// the field.
    ///
    /// A default implementation is provided that simply calls
    /// `visitSingularSInt32Field` once for each item in the array.
    mutating func visitRepeatedSInt32Field(value: inout [Int32], fieldNumber: Int) async throws

    // Called for each non-packed repeated sint64 field.
    /// The method is called once with the complete array of values for
    /// the field.
    ///
    /// A default implementation is provided that simply calls
    /// `visitSingularSInt64Field` once for each item in the array.
    mutating func visitRepeatedSInt64Field(value: inout [Int64], fieldNumber: Int) async throws

    // Called for each non-packed repeated fixed32 field.
    /// The method is called once with the complete array of values for
    /// the field.
    ///
    /// A default implementation is provided that simply calls
    /// `visitSingularFixed32Field` once for each item in the array.
    mutating func visitRepeatedFixed32Field(value: inout [UInt32], fieldNumber: Int) async throws

    // Called for each non-packed repeated fixed64 field.
    /// The method is called once with the complete array of values for
    /// the field.
    ///
    /// A default implementation is provided that simply calls
    /// `visitSingularFixed64Field` once for each item in the array.
    mutating func visitRepeatedFixed64Field(value: inout [UInt64], fieldNumber: Int) async throws

    // Called for each non-packed repeated sfixed32 field.
    /// The method is called once with the complete array of values for
    /// the field.
    ///
    /// A default implementation is provided that simply calls
    /// `visitSingularSFixed32Field` once for each item in the array.
    mutating func visitRepeatedSFixed32Field(value: inout [Int32], fieldNumber: Int) async throws

    // Called for each non-packed repeated sfixed64 field.
    /// The method is called once with the complete array of values for
    /// the field.
    ///
    /// A default implementation is provided that simply calls
    /// `visitSingularSFixed64Field` once for each item in the array.
    mutating func visitRepeatedSFixed64Field(value: inout [Int64], fieldNumber: Int) async throws

    // Called for each non-packed repeated bool field.
    /// The method is called once with the complete array of values for
    /// the field.
    ///
    /// A default implementation is provided that simply calls
    /// `visitSingularBoolField` once for each item in the array.
    mutating func visitRepeatedBoolField(value: inout [Bool], fieldNumber: Int) async throws

    // Called for each non-packed repeated string field.
    /// The method is called once with the complete array of values for
    /// the field.
    ///
    /// A default implementation is provided that simply calls
    /// `visitSingularStringField` once for each item in the array.
    mutating func visitRepeatedStringField(value: inout [String], fieldNumber: Int) async throws

    // Called for each non-packed repeated bytes field.
    /// The method is called once with the complete array of values for
    /// the field.
    ///
    /// A default implementation is provided that simply calls
    /// `visitSingularBytesField` once for each item in the array.
    mutating func visitRepeatedBytesField(value: inout [Data], fieldNumber: Int) async throws

    /// Called for each repeated, unpacked enum field.
    /// The method is called once with the complete array of values for
    /// the field.
    ///
    /// A default implementation is provided that simply calls
    /// `visitSingularEnumField` once for each item in the array.
    mutating func visitRepeatedEnumField<E: Enum>(value: inout [E], fieldNumber: Int) async throws

    /// Called for each repeated nested message field. The method is called once
    /// with the complete array of values for the field.
    ///
    /// A default implementation is provided that simply calls
    /// `visitSingularMessageField` once for each item in the array.
    mutating func visitRepeatedMessageField<M: Message>(
        value: inout [M],
        fieldNumber: Int
    ) async throws

    /// Called for each repeated proto2 group field.
    ///
    /// A default implementation is provided that simply calls
    /// `visitSingularGroupField` once for each item in the array.
    mutating func visitRepeatedGroupField<G: Message>(value: inout [G], fieldNumber: Int) async throws

    // Called for each packed, repeated float field.
    ///
    /// This is called once with the complete array of values for
    /// the field.
    ///
    /// There is a default implementation that forwards to the non-packed
    /// function.
    mutating func visitPackedFloatField(value: inout [Float], fieldNumber: Int) async throws

    // Called for each packed, repeated double field.
    ///
    /// This is called once with the complete array of values for
    /// the field.
    ///
    /// There is a default implementation that forwards to the non-packed
    /// function.
    mutating func visitPackedDoubleField(value: inout [Double], fieldNumber: Int) async throws

    // Called for each packed, repeated int32 field.
    ///
    /// This is called once with the complete array of values for
    /// the field.
    ///
    /// There is a default implementation that forwards to the non-packed
    /// function.
    mutating func visitPackedInt32Field(value: inout [Int32], fieldNumber: Int) async throws

    // Called for each packed, repeated int64 field.
    ///
    /// This is called once with the complete array of values for
    /// the field.
    ///
    /// There is a default implementation that forwards to the non-packed
    /// function.
    mutating func visitPackedInt64Field(value: inout [Int64], fieldNumber: Int) async throws

    // Called for each packed, repeated uint32 field.
    ///
    /// This is called once with the complete array of values for
    /// the field.
    ///
    /// There is a default implementation that forwards to the non-packed
    /// function.
    mutating func visitPackedUInt32Field(value: inout [UInt32], fieldNumber: Int) async throws

    // Called for each packed, repeated uint64 field.
    ///
    /// This is called once with the complete array of values for
    /// the field.
    ///
    /// There is a default implementation that forwards to the non-packed
    /// function.
    mutating func visitPackedUInt64Field(value: inout [UInt64], fieldNumber: Int) async throws

    // Called for each packed, repeated sint32 field.
    ///
    /// This is called once with the complete array of values for
    /// the field.
    ///
    /// There is a default implementation that forwards to the non-packed
    /// function.
    mutating func visitPackedSInt32Field(value: inout [Int32], fieldNumber: Int) async throws

    // Called for each packed, repeated sint64 field.
    ///
    /// This is called once with the complete array of values for
    /// the field.
    ///
    /// There is a default implementation that forwards to the non-packed
    /// function.
    mutating func visitPackedSInt64Field(value: inout [Int64], fieldNumber: Int) async throws

    // Called for each packed, repeated fixed32 field.
    ///
    /// This is called once with the complete array of values for
    /// the field.
    ///
    /// There is a default implementation that forwards to the non-packed
    /// function.
    mutating func visitPackedFixed32Field(value: inout [UInt32], fieldNumber: Int) async throws

    // Called for each packed, repeated fixed64 field.
    ///
    /// This is called once with the complete array of values for
    /// the field.
    ///
    /// There is a default implementation that forwards to the non-packed
    /// function.
    mutating func visitPackedFixed64Field(value: inout [UInt64], fieldNumber: Int) async throws

    // Called for each packed, repeated sfixed32 field.
    ///
    /// This is called once with the complete array of values for
    /// the field.
    ///
    /// There is a default implementation that forwards to the non-packed
    /// function.
    mutating func visitPackedSFixed32Field(value: inout [Int32], fieldNumber: Int) async throws

    // Called for each packed, repeated sfixed64 field.
    ///
    /// This is called once with the complete array of values for
    /// the field.
    ///
    /// There is a default implementation that forwards to the non-packed
    /// function.
    mutating func visitPackedSFixed64Field(value: inout [Int64], fieldNumber: Int) async throws

    // Called for each packed, repeated bool field.
    ///
    /// This is called once with the complete array of values for
    /// the field.
    ///
    /// There is a default implementation that forwards to the non-packed
    /// function.
    mutating func visitPackedBoolField(value: inout [Bool], fieldNumber: Int) async throws

    /// Called for each repeated, packed enum field.
    /// The method is called once with the complete array of values for
    /// the field.
    ///
    /// A default implementation is provided that simply forwards to
    /// `visitRepeatedEnumField`. Implementors who need to handle packed fields
    /// differently than unpacked fields can override this and provide distinct
    /// implementations.
    mutating func visitPackedEnumField<E: Enum>(value: inout [E], fieldNumber: Int) async throws

    /// Called for each map field with primitive values. The method is
    /// called once with the complete dictionary of keys/values for the
    /// field.
    ///
    /// There is no default implementation.  This must be implemented.
    mutating func visitMapField<KeyType, ValueType: MapValueType>(
        fieldType: _ProtobufMap<KeyType, ValueType>.Type,
        value: inout _ProtobufMap<KeyType, ValueType>.BaseType,
        fieldNumber: Int
    ) async throws

    /// Called for each map field with enum values. The method is called
    /// once with the complete dictionary of keys/values for the field.
    ///
    /// There is no default implementation.  This must be implemented.
    mutating func visitMapField<KeyType, ValueType>(
        fieldType: _ProtobufEnumMap<KeyType, ValueType>.Type,
        value: inout _ProtobufEnumMap<KeyType, ValueType>.BaseType,
        fieldNumber: Int
    ) async throws where ValueType.RawValue == Int

    /// Called for each map field with message values. The method is
    /// called once with the complete dictionary of keys/values for the
    /// field.
    ///
    /// There is no default implementation.  This must be implemented.
    mutating func visitMapField<KeyType, ValueType>(
        fieldType: _ProtobufMessageMap<KeyType, ValueType>.Type,
        value: inout _ProtobufMessageMap<KeyType, ValueType>.BaseType,
        fieldNumber: Int
    ) async throws

    /// Called for each extension range.
    mutating func visitExtensionFields(fields: inout ExtensionFieldValueSet, start: Int, end: Int) async throws

    /// Called for each extension range.
    mutating func visitExtensionFieldsAsMessageSet(
        fields: inout ExtensionFieldValueSet,
        start: Int,
        end: Int
    ) async throws

    /// Called with the raw bytes that represent any unknown fields.
    mutating func visitUnknown(bytes: inout Data) async throws
}

extension AsyncVisitor {
    public mutating func visitSingularFloatField(value: inout Float, fieldNumber: Int) async throws {}
    public mutating func visitSingularDoubleField(value: inout Double, fieldNumber: Int) async throws {}
    public mutating func visitSingularInt32Field(value: inout Int32, fieldNumber: Int) async throws {}
    public mutating func visitSingularInt64Field(value: inout Int64, fieldNumber: Int) async throws {}
    public mutating func visitSingularUInt32Field(value: inout UInt32, fieldNumber: Int) async throws {}
    public mutating func visitSingularUInt64Field(value: inout UInt64, fieldNumber: Int) async throws {}
    public mutating func visitSingularSInt32Field(value: inout Int32, fieldNumber: Int) async throws {}
    public mutating func visitSingularSInt64Field(value: inout Int64, fieldNumber: Int) async throws {}
    public mutating func visitSingularFixed32Field(value: inout UInt32, fieldNumber: Int) async throws {}
    public mutating func visitSingularFixed64Field(value: inout UInt64, fieldNumber: Int) async throws {}
    public mutating func visitSingularSFixed32Field(value: inout Int32, fieldNumber: Int) async throws {}
    public mutating func visitSingularSFixed64Field(value: inout Int64, fieldNumber: Int) async throws {}
    public mutating func visitSingularBoolField(value: inout Bool, fieldNumber: Int) async throws {}
    public mutating func visitSingularStringField(value: inout String, fieldNumber: Int) async throws {}
    public mutating func visitSingularBytesField(value: inout Data, fieldNumber: Int) async throws {}
    public mutating func visitSingularEnumField<E: Enum>(value: inout E, fieldNumber: Int) async throws {}
    public mutating func visitSingularMessageField<M: Message>(value: inout M, fieldNumber: Int) async throws {}
    public mutating func visitSingularGroupField<G: Message>(value: inout G, fieldNumber: Int) async throws {}
    public mutating func visitRepeatedFloatField(value: inout [Float], fieldNumber: Int) async throws {}
    public mutating func visitRepeatedDoubleField(value: inout [Double], fieldNumber: Int) async throws {}
    public mutating func visitRepeatedInt32Field(value: inout [Int32], fieldNumber: Int) async throws {}
    public mutating func visitRepeatedInt64Field(value: inout [Int64], fieldNumber: Int) async throws {}
    public mutating func visitRepeatedUInt32Field(value: inout [UInt32], fieldNumber: Int) async throws {}
    public mutating func visitRepeatedUInt64Field(value: inout [UInt64], fieldNumber: Int) async throws {}
    public mutating func visitRepeatedSInt32Field(value: inout [Int32], fieldNumber: Int) async throws {}
    public mutating func visitRepeatedSInt64Field(value: inout [Int64], fieldNumber: Int) async throws {}
    public mutating func visitRepeatedFixed32Field(value: inout [UInt32], fieldNumber: Int) async throws {}
    public mutating func visitRepeatedFixed64Field(value: inout [UInt64], fieldNumber: Int) async throws {}
    public mutating func visitRepeatedSFixed32Field(value: inout [Int32], fieldNumber: Int) async throws {}
    public mutating func visitRepeatedSFixed64Field(value: inout [Int64], fieldNumber: Int) async throws {}
    public mutating func visitRepeatedBoolField(value: inout [Bool], fieldNumber: Int) async throws {}
    public mutating func visitRepeatedStringField(value: inout [String], fieldNumber: Int) async throws {}
    public mutating func visitRepeatedBytesField(value: inout [Data], fieldNumber: Int) async throws {}
    public mutating func visitRepeatedEnumField<E: Enum>(value: inout [E], fieldNumber: Int) async throws {}
    public mutating func visitRepeatedMessageField<M: Message>(
        value: inout [M],
        fieldNumber: Int
    ) async throws {}
    public mutating func visitRepeatedGroupField<G: Message>(value: inout [G], fieldNumber: Int) async throws {}
    public mutating func visitPackedFloatField(value: inout [Float], fieldNumber: Int) async throws {}
    public mutating func visitPackedDoubleField(value: inout [Double], fieldNumber: Int) async throws {}
    public mutating func visitPackedInt32Field(value: inout [Int32], fieldNumber: Int) async throws {}
    public mutating func visitPackedInt64Field(value: inout [Int64], fieldNumber: Int) async throws {}
    public mutating func visitPackedUInt32Field(value: inout [UInt32], fieldNumber: Int) async throws {}
    public mutating func visitPackedUInt64Field(value: inout [UInt64], fieldNumber: Int) async throws {}
    public mutating func visitPackedSInt32Field(value: inout [Int32], fieldNumber: Int) async throws {}
    public mutating func visitPackedSInt64Field(value: inout [Int64], fieldNumber: Int) async throws {}
    public mutating func visitPackedFixed32Field(value: inout [UInt32], fieldNumber: Int) async throws {}
    public mutating func visitPackedFixed64Field(value: inout [UInt64], fieldNumber: Int) async throws {}
    public mutating func visitPackedSFixed32Field(value: inout [Int32], fieldNumber: Int) async throws {}
    public mutating func visitPackedSFixed64Field(value: inout [Int64], fieldNumber: Int) async throws {}
    public mutating func visitPackedBoolField(value: inout [Bool], fieldNumber: Int) async throws {}
    public mutating func visitPackedEnumField<E: Enum>(value: inout [E], fieldNumber: Int) async throws {}
    public mutating func visitMapField<KeyType, ValueType: MapValueType>(
        fieldType: _ProtobufMap<KeyType, ValueType>.Type,
        value: inout _ProtobufMap<KeyType, ValueType>.BaseType,
        fieldNumber: Int
    ) async throws {}
    public mutating func visitMapField<KeyType, ValueType>(
        fieldType: _ProtobufEnumMap<KeyType, ValueType>.Type,
        value: inout _ProtobufEnumMap<KeyType, ValueType>.BaseType,
        fieldNumber: Int
    ) async throws where ValueType.RawValue == Int {}
    public mutating func visitMapField<KeyType, ValueType>(
        fieldType: _ProtobufMessageMap<KeyType, ValueType>.Type,
        value: inout _ProtobufMessageMap<KeyType, ValueType>.BaseType,
        fieldNumber: Int
    ) async throws {}
    public mutating func visitExtensionFields(fields: inout ExtensionFieldValueSet, start: Int, end: Int) async throws {
    }
    public mutating func visitExtensionFieldsAsMessageSet(
        fields: inout ExtensionFieldValueSet,
        start: Int,
        end: Int
    ) async throws {}
    public mutating func visitUnknown(bytes: inout Data) async throws {}
}
