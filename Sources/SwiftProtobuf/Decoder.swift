// Sources/SwiftProtobuf/Decoder.swift - Basic field setting
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// In this way, the generated code only knows about schema
/// information; the decoder logic knows how to decode particular
/// wire types based on that information.
///
// -----------------------------------------------------------------------------

import Foundation

/// Abstract protocol used by the generated code
/// to deserialize data.
///
/// The generated code looks roughly like this:
///
/// ```
///   while fieldNumber = try decoder.nextFieldNumber() {
///      switch fieldNumber {
///      case 1: decoder.decodeRepeatedInt32Field(value: &_field)
///      ... etc ...
///   }
/// ```
///
/// In particular, note that the decoder must provide field _numbers_
/// corresponding to the numbers in the original proto file.
/// For formats such as Protobuf Binary format that encode field numbers
/// directly, this is trivial.  Decoders for formats such as Protobuf
/// Text Format or JSON must use auxiliary information attached to
/// the message type to translate string field names to field numbers.
///
/// For performance, the field decoding provides three separate methods
/// for every primitive type:
/// * Repeated support accepts an inout Array for repeated fields
/// * Singular support that accepts an inout `Optional`, for proto2
/// * Singular support that accepts an inout non-`Optional`, for proto3
///
/// Note that we don't distinguish "packed" here, since all existing decoders
/// treat "packed" the same as "repeated" at this level. (That is,
/// even when the serializer distinguishes packed and non-packed
/// forms, the deserializer always accepts both.)
///
/// Generics come into play at only a few points: `Enum`s and `Message`s
/// use a generic type to locate the correct initializer. Maps and
/// extensions use generics to avoid the method explosion of having to
/// support a separate method for every map and extension type. Maps
/// do distinguish `Enum`-valued and `Message`-valued maps to avoid
/// polluting the generated `Enum` and `Message` types with all of the
/// necessary generic methods to support this.
public protocol Decoder {
    /// Called by a `oneof` when it already has a value and is being asked to
    /// accept a new value. Some formats require `oneof` decoding to fail in this
    /// case.
    mutating func handleConflictingOneOf() throws

    /// Returns the next field number, or nil when the end of the input is
    /// reached.
    ///
    /// For JSON and text format, the decoder translates the field name to a
    /// number at this point, based on information it obtained from the message
    /// when it was initialized.
    mutating func nextFieldNumber() throws -> Int?

    /// Decode a float value to non-`Optional` field storage
    mutating func decodeSingularFloatField(value: inout Float) throws
    /// Decode a float value to `Optional` field storage
    mutating func decodeSingularFloatField(value: inout Float?) throws
    /// Decode float values to repeated field storage
    mutating func decodeRepeatedFloatField(value: inout [Float]) throws
    /// Decode a double value to non-`Optional` field storage
    mutating func decodeSingularDoubleField(value: inout Double) throws
    /// Decode a double value to `Optional` field storage
    mutating func decodeSingularDoubleField(value: inout Double?) throws
    /// Decode double values to repeated field storage
    mutating func decodeRepeatedDoubleField(value: inout [Double]) throws
    /// Decode an int32 value to non-`Optional` field storage
    mutating func decodeSingularInt32Field(value: inout Int32) throws
    /// Decode an int32 value to `Optional` field storage
    mutating func decodeSingularInt32Field(value: inout Int32?) throws
    /// Decode int32 values to repeated field storage
    mutating func decodeRepeatedInt32Field(value: inout [Int32]) throws
    /// Decode an int64 value to non-`Optional` field storage
    mutating func decodeSingularInt64Field(value: inout Int64) throws
    /// Decode an int64 value to `Optional` field storage
    mutating func decodeSingularInt64Field(value: inout Int64?) throws
    /// Decode int64 values to repeated field storage
    mutating func decodeRepeatedInt64Field(value: inout [Int64]) throws
    /// Decode a uint32 value to non-`Optional` field storage
    mutating func decodeSingularUInt32Field(value: inout UInt32) throws
    /// Decode a uint32 value to `Optional` field storage
    mutating func decodeSingularUInt32Field(value: inout UInt32?) throws
    /// Decode uint32 values to repeated field storage
    mutating func decodeRepeatedUInt32Field(value: inout [UInt32]) throws
    /// Decode a uint64 value to non-`Optional` field storage
    mutating func decodeSingularUInt64Field(value: inout UInt64) throws
    /// Decode a uint64 value to `Optional` field storage
    mutating func decodeSingularUInt64Field(value: inout UInt64?) throws
    /// Decode uint64 values to repeated field storage
    mutating func decodeRepeatedUInt64Field(value: inout [UInt64]) throws
    /// Decode an sint32 value to non-`Optional` field storage
    mutating func decodeSingularSInt32Field(value: inout Int32) throws
    /// Decode an sint32 value to `Optional` field storage
    mutating func decodeSingularSInt32Field(value: inout Int32?) throws
    /// Decode sint32 values to repeated field storage
    mutating func decodeRepeatedSInt32Field(value: inout [Int32]) throws
    /// Decode an sint64 value to non-`Optional` field storage
    mutating func decodeSingularSInt64Field(value: inout Int64) throws
    /// Decode an sint64 value to `Optional` field storage
    mutating func decodeSingularSInt64Field(value: inout Int64?) throws
    /// Decode sint64 values to repeated field storage
    mutating func decodeRepeatedSInt64Field(value: inout [Int64]) throws
    /// Decode a fixed32 value to non-`Optional` field storage
    mutating func decodeSingularFixed32Field(value: inout UInt32) throws
    /// Decode a fixed32 value to `Optional` field storage
    mutating func decodeSingularFixed32Field(value: inout UInt32?) throws
    /// Decode fixed32 values to repeated field storage
    mutating func decodeRepeatedFixed32Field(value: inout [UInt32]) throws
    /// Decode a fixed64 value to non-`Optional` field storage
    mutating func decodeSingularFixed64Field(value: inout UInt64) throws
    /// Decode a fixed64 value to `Optional` field storage
    mutating func decodeSingularFixed64Field(value: inout UInt64?) throws
    /// Decode fixed64 values to repeated field storage
    mutating func decodeRepeatedFixed64Field(value: inout [UInt64]) throws
    /// Decode an sfixed32 value to non-`Optional` field storage
    mutating func decodeSingularSFixed32Field(value: inout Int32) throws
    /// Decode an sfixed32 value to `Optional` field storage
    mutating func decodeSingularSFixed32Field(value: inout Int32?) throws
    /// Decode sfixed32 values to repeated field storage
    mutating func decodeRepeatedSFixed32Field(value: inout [Int32]) throws
    /// Decode an sfixed64 value to non-`Optional` field storage
    mutating func decodeSingularSFixed64Field(value: inout Int64) throws
    /// Decode an sfixed64 value to `Optional` field storage
    mutating func decodeSingularSFixed64Field(value: inout Int64?) throws
    /// Decode sfixed64 values to repeated field storage
    mutating func decodeRepeatedSFixed64Field(value: inout [Int64]) throws
    /// Decode a bool value to non-`Optional` field storage
    mutating func decodeSingularBoolField(value: inout Bool) throws
    /// Decode a bool value to `Optional` field storage
    mutating func decodeSingularBoolField(value: inout Bool?) throws
    /// Decode bool values to repeated field storage
    mutating func decodeRepeatedBoolField(value: inout [Bool]) throws
    /// Decode a string value to non-`Optional` field storage
    mutating func decodeSingularStringField(value: inout String) throws
    /// Decode a string value to `Optional` field storage
    mutating func decodeSingularStringField(value: inout String?) throws
    /// Decode string values to repeated field storage
    mutating func decodeRepeatedStringField(value: inout [String]) throws
    /// Decode a bytes value to non-`Optional` field storage
    mutating func decodeSingularBytesField(value: inout Data) throws
    /// Decode a bytes value to `Optional` field storage
    mutating func decodeSingularBytesField(value: inout Data?) throws
    /// Decode bytes values to repeated field storage
    mutating func decodeRepeatedBytesField(value: inout [Data]) throws

    // Decode Enum fields

    /// Decode an enum value to non-`Optional` field storage
    mutating func decodeSingularEnumField<E: Enum>(value: inout E) throws where E.RawValue == Int
    /// Decode an enum value to `Optional` field storage
    mutating func decodeSingularEnumField<E: Enum>(value: inout E?) throws where E.RawValue == Int
    /// Decode enum values to repeated field storage
    mutating func decodeRepeatedEnumField<E: Enum>(value: inout [E]) throws where E.RawValue == Int

    // Decode Message fields

    /// Decode a message value to `Optional` field storage.
    ///
    /// Unlike the primitive types, message fields are always stored
    /// as Swift `Optional` values.
    mutating func decodeSingularMessageField<M: Message>(value: inout M?) throws
    /// Decode message values to repeated field storage
    mutating func decodeRepeatedMessageField<M: Message>(value: inout [M]) throws

    // Decode Group fields

    /// Decode a group value to `Optional` field storage.
    ///
    /// Unlike the primitive types, message fields are always stored
    /// as Swift `Optional` values.
    /// Note that groups are only used in proto2.
    mutating func decodeSingularGroupField<G: Message>(value: inout G?) throws
    /// Decode group values to repeated field storage
    mutating func decodeRepeatedGroupField<G: Message>(value: inout [G]) throws

    // Decode Map fields.
    // This is broken into separate methods depending on whether the value
    // type is primitive (_ProtobufMap), enum (_ProtobufEnumMap), or message
    // (_ProtobufMessageMap)

    /// Decode a map whose values are primitive types (including string and bytes)
    mutating func decodeMapField<KeyType, ValueType: MapValueType>(
        fieldType: _ProtobufMap<KeyType, ValueType>.Type,
        value: inout _ProtobufMap<KeyType, ValueType>.BaseType
    ) throws
    /// Decode a map whose values are protobuf enum types
    mutating func decodeMapField<KeyType, ValueType>(
        fieldType: _ProtobufEnumMap<KeyType, ValueType>.Type,
        value: inout _ProtobufEnumMap<KeyType, ValueType>.BaseType
    ) throws where ValueType.RawValue == Int
    /// Decode a map whose values are protobuf message types
    mutating func decodeMapField<KeyType, ValueType>(
        fieldType: _ProtobufMessageMap<KeyType, ValueType>.Type,
        value: inout _ProtobufMessageMap<KeyType, ValueType>.BaseType
    ) throws

    // Decode extension fields

    /// Decode an extension field
    mutating func decodeExtensionField(
        values: inout ExtensionFieldValueSet,
        messageType: any Message.Type,
        fieldNumber: Int
    ) throws

    // Run a decode loop decoding the MessageSet format for Extensions.
    mutating func decodeExtensionFieldsAsMessageSet(
        values: inout ExtensionFieldValueSet,
        messageType: any Message.Type
    ) throws
}

/// Most Decoders won't care about Extension handing as in MessageSet
/// format, so provide a default implementation simply looping on the
/// fieldNumbers and feeding through to extension decoding.
extension Decoder {
    public mutating func decodeExtensionFieldsAsMessageSet(
        values: inout ExtensionFieldValueSet,
        messageType: any Message.Type
    ) throws {
        while let fieldNumber = try self.nextFieldNumber() {
            try self.decodeExtensionField(
                values: &values,
                messageType: messageType,
                fieldNumber: fieldNumber
            )
        }
    }
}
