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
import Foundation

public protocol ProtobufFieldDecoder {
    // Some decoders require that multiple values for a oneof must fail
    var rejectConflictingOneof: Bool { get }

    // Special support for protobuf binary decoder; all other formats should ignore this.
    mutating func asProtobufUnknown(protoFieldNumber: Int) throws -> Data?

    // Generic decode methods; defaults are provided below
    mutating func decodeSingularField<S: ProtobufTypeProperties>(fieldType: S.Type, value: inout S.BaseType?) throws
    mutating func decodeSingularField<S: ProtobufTypeProperties>(fieldType: S.Type, value: inout S.BaseType) throws
    mutating func decodeRepeatedField<S: ProtobufTypeProperties>(fieldType: S.Type, value: inout [S.BaseType]) throws
    mutating func decodePackedField<S: ProtobufTypeProperties>(fieldType: S.Type, value: inout [S.BaseType]) throws
    mutating func decodeSingularMessageField<M: ProtobufMessage>(fieldType: M.Type, value: inout M?) throws
    mutating func decodeRepeatedMessageField<M: ProtobufMessage>(fieldType: M.Type, value: inout [M]) throws
    mutating func decodeSingularGroupField<G: ProtobufMessage>(fieldType: G.Type, value: inout G?) throws
    mutating func decodeRepeatedGroupField<G: ProtobufMessage>(fieldType: G.Type, value: inout [G]) throws
    mutating func decodeMapField<KeyType: ProtobufTypeProperties, ValueType: ProtobufTypeProperties>(fieldType: ProtobufMap<KeyType, ValueType>.Type, value: inout ProtobufMap<KeyType, ValueType>.BaseType) throws where KeyType: ProtobufMapKeyType, KeyType.BaseType: Hashable, ValueType: ProtobufMapValueType
    mutating func decodeExtensionField(values: inout ProtobufExtensionFieldValueSet, messageType: ProtobufMessage.Type, protoFieldNumber: Int) throws
}

public extension ProtobufFieldDecoder {
    var rejectConflictingOneof: Bool {return false}

    public mutating func asProtobufUnknown(protoFieldNumber: Int) throws -> Data? {
        return nil
    }

    public mutating func decodeSingularField<S: ProtobufTypeProperties>(fieldType: S.Type, value: inout S.BaseType?) throws {
        throw ProtobufDecodingError.schemaMismatch
    }
    public mutating func decodeSingularField<S: ProtobufTypeProperties>(fieldType: S.Type, value: inout S.BaseType) throws {
        var t: S.BaseType? = nil
        try decodeSingularField(fieldType: fieldType, value: &t)
        if let newValue = t {
            value = newValue
        }
        // TODO: else value = S.proto3DefaultValue
    }
    public mutating func decodeRepeatedField<S: ProtobufTypeProperties>(fieldType: S.Type, value: inout [S.BaseType]) throws {
        throw ProtobufDecodingError.schemaMismatch
    }
    public mutating func decodePackedField<S: ProtobufTypeProperties>(fieldType: S.Type, value: inout [S.BaseType]) throws {
        throw ProtobufDecodingError.schemaMismatch
    }
    public mutating func decodeSingularMessageField<M: ProtobufMessage>(fieldType: M.Type, value: inout M?) throws {
        throw ProtobufDecodingError.schemaMismatch
    }
    public mutating func decodeRepeatedMessageField<M: ProtobufMessage>(fieldType: M.Type, value: inout [M]) throws {
        throw ProtobufDecodingError.schemaMismatch
    }
    public mutating func decodeSingularGroupField<G: ProtobufMessage>(fieldType: G.Type, value: inout G?) throws {
        throw ProtobufDecodingError.schemaMismatch
    }
    public mutating func decodeRepeatedGroupField<G: ProtobufMessage>(fieldType: G.Type, value: inout [G]) throws {
        throw ProtobufDecodingError.schemaMismatch
    }
    public mutating func decodeMapField<KeyType: ProtobufMapKeyType, ValueType: ProtobufMapValueType>(fieldType: ProtobufMap<KeyType, ValueType>.Type, value: inout ProtobufMap<KeyType, ValueType>.BaseType) throws where KeyType.BaseType: Hashable {
        throw ProtobufDecodingError.schemaMismatch
    }
    mutating func decodeExtensionField(values: inout ProtobufExtensionFieldValueSet, messageType: ProtobufMessage.Type, protoFieldNumber: Int) throws {
    }
}


