// Sources/SwiftProtobuf/Decoder.swift - Basic field setting
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// A "field decoder" is an object that knows how to set
/// specific field types.
///
/// The rough flow is:
///   * Decoder looks ahead and creates a suitable field decoder
///     for the upcoming field data
///   * Decoder calls decodeField() with the field decoder object
///   * decodeField() calls the appropriate field decoder method
///     based on the schema.
///
/// In this way, the generated code only knows about schema
/// information; the decoder logic knows how to decode particular
/// wire types based on that information.
///
// -----------------------------------------------------------------------------

import Swift
import Foundation

public protocol Decoder {

    mutating func nextFieldNumber() throws -> Int?

    // Some decoders require that multiple values for a oneof must fail
    var rejectConflictingOneof: Bool { get }

    // Singular primitive fields
    mutating func decodeSingularFloatField(value: inout Float) throws
    mutating func decodeSingularFloatField(value: inout Float?) throws
    mutating func decodeSingularDoubleField(value: inout Double) throws
    mutating func decodeSingularDoubleField(value: inout Double?) throws
    mutating func decodeSingularInt32Field(value: inout Int32) throws
    mutating func decodeSingularInt32Field(value: inout Int32?) throws
    mutating func decodeSingularInt64Field(value: inout Int64) throws
    mutating func decodeSingularInt64Field(value: inout Int64?) throws
    mutating func decodeSingularUInt32Field(value: inout UInt32) throws
    mutating func decodeSingularUInt32Field(value: inout UInt32?) throws
    mutating func decodeSingularUInt64Field(value: inout UInt64) throws
    mutating func decodeSingularUInt64Field(value: inout UInt64?) throws
    mutating func decodeSingularSInt32Field(value: inout Int32) throws
    mutating func decodeSingularSInt32Field(value: inout Int32?) throws
    mutating func decodeSingularSInt64Field(value: inout Int64) throws
    mutating func decodeSingularSInt64Field(value: inout Int64?) throws
    mutating func decodeSingularFixed32Field(value: inout UInt32) throws
    mutating func decodeSingularFixed32Field(value: inout UInt32?) throws
    mutating func decodeSingularFixed64Field(value: inout UInt64) throws
    mutating func decodeSingularFixed64Field(value: inout UInt64?) throws
    mutating func decodeSingularSFixed32Field(value: inout Int32) throws
    mutating func decodeSingularSFixed32Field(value: inout Int32?) throws
    mutating func decodeSingularSFixed64Field(value: inout Int64) throws
    mutating func decodeSingularSFixed64Field(value: inout Int64?) throws
    mutating func decodeSingularBoolField(value: inout Bool) throws
    mutating func decodeSingularBoolField(value: inout Bool?) throws
    mutating func decodeSingularStringField(value: inout String) throws
    mutating func decodeSingularStringField(value: inout String?) throws
    mutating func decodeSingularBytesField(value: inout Data) throws
    mutating func decodeSingularBytesField(value: inout Data?) throws

    // Legacy generic version...  Should these be removed?
//    mutating func decodeSingularField<S: FieldType>(fieldType: S.Type, value: inout S.BaseType?) throws
//    mutating func decodeSingularField<S: FieldType>(fieldType: S.Type, value: inout S.BaseType) throws

    mutating func decodeRepeatedField<S: FieldType>(fieldType: S.Type, value: inout [S.BaseType]) throws

    mutating func decodeSingularEnumField<E: Enum>(value: inout E) throws where E.RawValue == Int
    mutating func decodeSingularEnumField<E: Enum>(value: inout E?) throws where E.RawValue == Int
    mutating func decodeRepeatedEnumField<E: Enum>(value: inout [E]) throws where E.RawValue == Int
    mutating func decodeSingularMessageField<M: Message>(value: inout M?) throws
    mutating func decodeRepeatedMessageField<M: Message>(value: inout [M]) throws
    mutating func decodeSingularGroupField<G: Message>(value: inout G?) throws
    mutating func decodeRepeatedGroupField<G: Message>(value: inout [G]) throws
    mutating func decodeMapField<KeyType: MapKeyType, ValueType: MapValueType>(fieldType: ProtobufMap<KeyType, ValueType>.Type, value: inout ProtobufMap<KeyType, ValueType>.BaseType) throws
    mutating func decodeMapField<KeyType: MapKeyType, ValueType: Enum>(fieldType: ProtobufEnumMap<KeyType, ValueType>.Type, value: inout ProtobufEnumMap<KeyType, ValueType>.BaseType) throws where ValueType.RawValue == Int
    mutating func decodeMapField<KeyType: MapKeyType, ValueType: Message>(fieldType: ProtobufMessageMap<KeyType, ValueType>.Type, value: inout ProtobufMessageMap<KeyType, ValueType>.BaseType) throws
    mutating func decodeExtensionField(values: inout ExtensionFieldValueSet, messageType: Message.Type, fieldNumber: Int) throws
}

public extension Decoder {
    var rejectConflictingOneof: Bool {return false}

    public mutating func nextFieldNumber() throws -> Int? {
        throw DecodingError.failure
    }

    /*
*/
}


