// Sources/SwiftProtobuf/FieldDecoder.swift - Basic field setting
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

public protocol FieldDecoder {
    // Some decoders require that multiple values for a oneof must fail
    var rejectConflictingOneof: Bool { get }

    // Special support for protobuf binary decoder; all other formats should ignore this.
    mutating func asProtobufUnknown(protoFieldNumber: Int) throws -> Data?

    // Generic decode methods; defaults are provided below
    mutating func decodeSingularField<S: FieldType>(fieldType: S.Type, value: inout S.BaseType?) throws
    mutating func decodeSingularField<S: FieldType>(fieldType: S.Type, value: inout S.BaseType) throws
    mutating func decodeRepeatedField<S: FieldType>(fieldType: S.Type, value: inout [S.BaseType]) throws
    mutating func decodePackedField<S: FieldType>(fieldType: S.Type, value: inout [S.BaseType]) throws
    mutating func decodeSingularMessageField<M: Message>(fieldType: M.Type, value: inout M?) throws
    mutating func decodeRepeatedMessageField<M: Message>(fieldType: M.Type, value: inout [M]) throws
    mutating func decodeSingularGroupField<G: Message>(fieldType: G.Type, value: inout G?) throws
    mutating func decodeRepeatedGroupField<G: Message>(fieldType: G.Type, value: inout [G]) throws
    mutating func decodeMapField<KeyType: FieldType, ValueType: FieldType>(fieldType: ProtobufMap<KeyType, ValueType>.Type, value: inout ProtobufMap<KeyType, ValueType>.BaseType) throws where KeyType: MapKeyType, KeyType.BaseType: Hashable, ValueType: MapValueType
    mutating func decodeExtensionField(values: inout ExtensionFieldValueSet, messageType: Message.Type, protoFieldNumber: Int) throws
}

public extension FieldDecoder {
    var rejectConflictingOneof: Bool {return false}

    public mutating func asProtobufUnknown(protoFieldNumber: Int) throws -> Data? {
        return nil
    }

    public mutating func decodeSingularField<S: FieldType>(fieldType: S.Type, value: inout S.BaseType?) throws {
        throw DecodingError.schemaMismatch
    }
    public mutating func decodeSingularField<S: FieldType>(fieldType: S.Type, value: inout S.BaseType) throws {
        var t: S.BaseType? = nil
        try decodeSingularField(fieldType: fieldType, value: &t)
        if let newValue = t {
            value = newValue
        }
        // TODO: else value = S.proto3DefaultValue
    }
    public mutating func decodeRepeatedField<S: FieldType>(fieldType: S.Type, value: inout [S.BaseType]) throws {
        throw DecodingError.schemaMismatch
    }
    public mutating func decodePackedField<S: FieldType>(fieldType: S.Type, value: inout [S.BaseType]) throws {
        throw DecodingError.schemaMismatch
    }
    public mutating func decodeSingularMessageField<M: Message>(fieldType: M.Type, value: inout M?) throws {
        throw DecodingError.schemaMismatch
    }
    public mutating func decodeRepeatedMessageField<M: Message>(fieldType: M.Type, value: inout [M]) throws {
        throw DecodingError.schemaMismatch
    }
    public mutating func decodeSingularGroupField<G: Message>(fieldType: G.Type, value: inout G?) throws {
        throw DecodingError.schemaMismatch
    }
    public mutating func decodeRepeatedGroupField<G: Message>(fieldType: G.Type, value: inout [G]) throws {
        throw DecodingError.schemaMismatch
    }
    public mutating func decodeMapField<KeyType: MapKeyType, ValueType: MapValueType>(fieldType: ProtobufMap<KeyType, ValueType>.Type, value: inout ProtobufMap<KeyType, ValueType>.BaseType) throws where KeyType.BaseType: Hashable {
        throw DecodingError.schemaMismatch
    }
    mutating func decodeExtensionField(values: inout ExtensionFieldValueSet, messageType: Message.Type, protoFieldNumber: Int) throws {
    }
}


