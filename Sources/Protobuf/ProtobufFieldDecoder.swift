// ProtobufRuntime/Sources/Protobuf/ProtobufFieldDecoder.swift - Basic field setting
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

public protocol ProtobufFieldDecoder {
    // Some decoders require that multiple values for a oneof must fail
    var rejectConflictingOneof: Bool { get }

    // Special support for protobuf binary decoder; all other formats should ignore this.
    mutating func asProtobufUnknown() throws -> [UInt8]?

    // Generic decode methods; defaults are provided below
    mutating func decodeOptionalField<S: ProtobufTypeProperties>(fieldType: S.Type, value: inout S.BaseType?) throws -> Bool
    mutating func decodeRequiredField<S: ProtobufTypeProperties>(fieldType: S.Type, value: inout S.BaseType) throws -> Bool
    mutating func decodeSingularField<S: ProtobufTypeProperties>(fieldType: S.Type, value: inout S.BaseType) throws -> Bool
    mutating func decodeRepeatedField<S: ProtobufTypeProperties>(fieldType: S.Type, value: inout [S.BaseType]) throws -> Bool
    mutating func decodePackedField<S: ProtobufTypeProperties>(fieldType: S.Type, value: inout [S.BaseType]) throws -> Bool
    mutating func decodeOptionalMessageField<M: ProtobufMessage>(fieldType: M.Type, value: inout M?) throws -> Bool
    mutating func decodeRequiredMessageField<M: ProtobufMessage>(fieldType: M.Type, value: inout M?) throws -> Bool
    mutating func decodeSingularMessageField<M: ProtobufMessage>(fieldType: M.Type, value: inout M?) throws -> Bool
    mutating func decodeRepeatedMessageField<M: ProtobufMessage>(fieldType: M.Type, value: inout [M]) throws -> Bool
    mutating func decodeOptionalGroupField<G: ProtobufGroup>(fieldType: G.Type, value: inout G?) throws -> Bool
    mutating func decodeRequiredGroupField<G: ProtobufGroup>(fieldType: G.Type, value: inout G?) throws -> Bool
    mutating func decodeRepeatedGroupField<G: ProtobufGroup>(fieldType: G.Type, value: inout [G]) throws -> Bool
    mutating func decodeMapField<KeyType: ProtobufTypeProperties, ValueType: ProtobufTypeProperties>(fieldType: ProtobufMap<KeyType, ValueType>.Type, value: inout ProtobufMap<KeyType, ValueType>.BaseType) throws -> Bool  where KeyType: ProtobufMapKeyType, KeyType.BaseType: Hashable, ValueType: ProtobufMapValueType
    mutating func decodeExtensionField(values: inout ProtobufExtensionFieldValueSet, messageType: ProtobufMessage.Type, protoFieldNumber: Int) throws -> Bool
}

public extension ProtobufFieldDecoder {
    var rejectConflictingOneof: Bool {return false}

    public mutating func asProtobufUnknown() throws -> [UInt8]? {
        return nil
    }

    public mutating func decodeOptionalField<S: ProtobufTypeProperties>(fieldType: S.Type, value: inout S.BaseType?) throws -> Bool {
        throw ProtobufDecodingError.schemaMismatch
    }
    public mutating func decodeSingularField<S: ProtobufTypeProperties>(fieldType: S.Type, value: inout S.BaseType) throws -> Bool {
        var t: S.BaseType? = value
        if try decodeOptionalField(fieldType: fieldType, value: &t) {
            if let newValue = t {
                value = newValue
            }
            // TODO: else value = S.proto3DefaultValue
            return true
        }
        throw ProtobufDecodingError.schemaMismatch
    }
    public mutating func decodeRequiredField<S: ProtobufTypeProperties>(fieldType: S.Type, value: inout S.BaseType) throws -> Bool {
        return try decodeSingularField(fieldType: fieldType, value: &value)
    }
    public mutating func decodeRepeatedField<S: ProtobufTypeProperties>(fieldType: S.Type, value: inout [S.BaseType]) throws -> Bool {
        throw ProtobufDecodingError.schemaMismatch
    }
    public mutating func decodePackedField<S: ProtobufTypeProperties>(fieldType: S.Type, value: inout [S.BaseType]) throws -> Bool {
        throw ProtobufDecodingError.schemaMismatch
    }
    public mutating func decodeOptionalMessageField<M: ProtobufMessage>(fieldType: M.Type, value: inout M?) throws -> Bool {
        throw ProtobufDecodingError.schemaMismatch
    }
    public mutating func decodeRequiredMessageField<M: ProtobufMessage>(fieldType: M.Type, value: inout M?) throws -> Bool {
        return try decodeOptionalMessageField(fieldType: fieldType, value: &value)
    }
    public mutating func decodeSingularMessageField<M: ProtobufMessage>(fieldType: M.Type, value: inout M?) throws -> Bool {
        return try decodeOptionalMessageField(fieldType: fieldType, value: &value)
    }
    public mutating func decodeRepeatedMessageField<M: ProtobufMessage>(fieldType: M.Type, value: inout [M]) throws -> Bool {
        throw ProtobufDecodingError.schemaMismatch
    }
    public mutating func decodeOptionalGroupField<G: ProtobufGroup>(fieldType: G.Type, value: inout G?) throws -> Bool {
        throw ProtobufDecodingError.schemaMismatch
    }
    public mutating func decodeRequiredGroupField<G: ProtobufGroup>(fieldType: G.Type, value: inout G?) throws -> Bool {
        return try decodeOptionalGroupField(fieldType: fieldType, value: &value)
    }
    public mutating func decodeRepeatedGroupField<G: ProtobufGroup>(fieldType: G.Type, value: inout [G]) throws -> Bool {
        throw ProtobufDecodingError.schemaMismatch
    }
    public mutating func decodeMapField<KeyType: ProtobufMapKeyType, ValueType: ProtobufMapValueType>(fieldType: ProtobufMap<KeyType, ValueType>.Type, value: inout ProtobufMap<KeyType, ValueType>.BaseType) throws -> Bool  where KeyType.BaseType: Hashable {
        throw ProtobufDecodingError.schemaMismatch
    }
    mutating func decodeExtensionField(values: inout ProtobufExtensionFieldValueSet, messageType: ProtobufMessage.Type, protoFieldNumber: Int) throws -> Bool {
        return false
    }
}


