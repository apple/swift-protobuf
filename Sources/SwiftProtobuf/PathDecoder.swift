// Sources/SwiftProtobuf/PathDecoder.swift - Path decoder
//
// Copyright (c) 2014 - 2023 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Decoder which sets value of a field by its path.
///
// -----------------------------------------------------------------------------

import Foundation

/// Describes errors can occure during decoding a proto by path.
public enum PathDecodingError: Error {

    /// Describes a mismatch in type of the fields.
    ///
    /// If a value of type A is applied to a path with type B.
    /// this error will be thrown.
    case typeMismatch

    /// Describes path is not found in message type.
    ///
    /// If a message has no field with the given path this
    /// error will be thrown.
    case pathNotFound
}

extension Message {
    static func number(for field: String) -> Int? {
        guard let type = Self.self as? any _ProtoNameProviding.Type else {
            return nil
        }
        guard
            let number = Array(field.utf8).withUnsafeBytes({ bytes in
                type._protobuf_nameMap.number(forProtoName: bytes)
            })
        else {
            return nil
        }
        if type._protobuf_nameMap.names(for: number)?.proto.description != field {
            return nil
        }
        return number
    }

    static func name(for field: Int) -> String? {
        guard let type = Self.self as? any _ProtoNameProviding.Type else {
            return nil
        }
        return type._protobuf_nameMap.names(for: field)?.proto.description
    }
}

// Decoder that set value of a message field by the given path
struct PathDecoder<T: Message>: Decoder {

    // The value should be set to the path
    private let value: Any?

    // Field number should be overriden by decoder
    private var number: Int?

    // The path only including sub-paths
    private let nextPath: [String]

    // Merge options to be concidered while setting value
    private let mergeOption: Google_Protobuf_FieldMask.MergeOptions

    private var replaceRepeatedFields: Bool {
        mergeOption.replaceRepeatedFields
    }

    init(
        path: [String],
        value: Any?,
        mergeOption: Google_Protobuf_FieldMask.MergeOptions
    ) throws {
        if let firstComponent = path.first,
            let number = T.number(for: firstComponent)
        {
            self.number = number
            self.nextPath = .init(path.dropFirst())
        } else {
            throw PathDecodingError.pathNotFound
        }
        self.value = value
        self.mergeOption = mergeOption
    }

    private func setValue<V>(_ value: inout V, defaultValue: V) throws {
        if !nextPath.isEmpty {
            throw PathDecodingError.pathNotFound
        }
        if self.value == nil {
            value = defaultValue
            return
        }
        guard let castedValue = self.value as? V else {
            throw PathDecodingError.typeMismatch
        }
        value = castedValue
    }

    private func setRepeatedValue<V>(_ value: inout [V]) throws {
        if !nextPath.isEmpty {
            throw PathDecodingError.pathNotFound
        }
        var castedValue: [V] = []
        if self.value != nil {
            guard let v = self.value as? [V] else {
                throw PathDecodingError.typeMismatch
            }
            castedValue = v
        }
        if replaceRepeatedFields {
            value = castedValue
        } else {
            value.append(contentsOf: castedValue)
        }
    }

    private func setMapValue<K, V>(
        _ value: inout [K: V]
    ) throws {
        if !nextPath.isEmpty {
            throw PathDecodingError.pathNotFound
        }
        var castedValue: [K: V] = [:]
        if self.value != nil {
            guard let v = self.value as? [K: V] else {
                throw PathDecodingError.typeMismatch
            }
            castedValue = v
        }
        if replaceRepeatedFields {
            value = castedValue
        } else {
            value.merge(castedValue) { _, new in
                new
            }
        }
    }

    private func setMessageValue<M: Message>(
        _ value: inout M?
    ) throws {
        if nextPath.isEmpty {
            try setValue(&value, defaultValue: nil)
            return
        }
        var decoder = try PathDecoder<M>(
            path: nextPath,
            value: self.value,
            mergeOption: mergeOption
        )
        if value == nil {
            value = .init()
        }
        try value?.decodeMessage(decoder: &decoder)
    }

    mutating func handleConflictingOneOf() throws {}

    mutating func nextFieldNumber() throws -> Int? {
        defer { number = nil }
        return number
    }

    mutating func decodeSingularFloatField(value: inout Float) throws {
        try setValue(&value, defaultValue: .init())
    }

    mutating func decodeSingularFloatField(value: inout Float?) throws {
        try setValue(&value, defaultValue: nil)
    }

    mutating func decodeRepeatedFloatField(value: inout [Float]) throws {
        try setRepeatedValue(&value)
    }

    mutating func decodeSingularDoubleField(value: inout Double) throws {
        try setValue(&value, defaultValue: .init())
    }

    mutating func decodeSingularDoubleField(value: inout Double?) throws {
        try setValue(&value, defaultValue: nil)
    }

    mutating func decodeRepeatedDoubleField(value: inout [Double]) throws {
        try setRepeatedValue(&value)
    }

    mutating func decodeSingularInt32Field(value: inout Int32) throws {
        try setValue(&value, defaultValue: .init())
    }

    mutating func decodeSingularInt32Field(value: inout Int32?) throws {
        try setValue(&value, defaultValue: nil)
    }

    mutating func decodeRepeatedInt32Field(value: inout [Int32]) throws {
        try setRepeatedValue(&value)
    }

    mutating func decodeSingularInt64Field(value: inout Int64) throws {
        try setValue(&value, defaultValue: .init())
    }

    mutating func decodeSingularInt64Field(value: inout Int64?) throws {
        try setValue(&value, defaultValue: nil)
    }

    mutating func decodeRepeatedInt64Field(value: inout [Int64]) throws {
        try setRepeatedValue(&value)
    }

    mutating func decodeSingularUInt32Field(value: inout UInt32) throws {
        try setValue(&value, defaultValue: .init())
    }

    mutating func decodeSingularUInt32Field(value: inout UInt32?) throws {
        try setValue(&value, defaultValue: nil)
    }

    mutating func decodeRepeatedUInt32Field(value: inout [UInt32]) throws {
        try setRepeatedValue(&value)
    }

    mutating func decodeSingularUInt64Field(value: inout UInt64) throws {
        try setValue(&value, defaultValue: .init())
    }

    mutating func decodeSingularUInt64Field(value: inout UInt64?) throws {
        try setValue(&value, defaultValue: nil)
    }

    mutating func decodeRepeatedUInt64Field(value: inout [UInt64]) throws {
        try setRepeatedValue(&value)
    }

    mutating func decodeSingularSInt32Field(value: inout Int32) throws {
        try setValue(&value, defaultValue: .init())
    }

    mutating func decodeSingularSInt32Field(value: inout Int32?) throws {
        try setValue(&value, defaultValue: nil)
    }

    mutating func decodeRepeatedSInt32Field(value: inout [Int32]) throws {
        try setRepeatedValue(&value)
    }

    mutating func decodeSingularSInt64Field(value: inout Int64) throws {
        try setValue(&value, defaultValue: .init())
    }

    mutating func decodeSingularSInt64Field(value: inout Int64?) throws {
        try setValue(&value, defaultValue: nil)
    }

    mutating func decodeRepeatedSInt64Field(value: inout [Int64]) throws {
        try setRepeatedValue(&value)
    }

    mutating func decodeSingularFixed32Field(value: inout UInt32) throws {
        try setValue(&value, defaultValue: .init())
    }

    mutating func decodeSingularFixed32Field(value: inout UInt32?) throws {
        try setValue(&value, defaultValue: nil)
    }

    mutating func decodeRepeatedFixed32Field(value: inout [UInt32]) throws {
        try setRepeatedValue(&value)
    }

    mutating func decodeSingularFixed64Field(value: inout UInt64) throws {
        try setValue(&value, defaultValue: .init())
    }

    mutating func decodeSingularFixed64Field(value: inout UInt64?) throws {
        try setValue(&value, defaultValue: nil)
    }

    mutating func decodeRepeatedFixed64Field(value: inout [UInt64]) throws {
        try setRepeatedValue(&value)
    }

    mutating func decodeSingularSFixed32Field(value: inout Int32) throws {
        try setValue(&value, defaultValue: .init())
    }

    mutating func decodeSingularSFixed32Field(value: inout Int32?) throws {
        try setValue(&value, defaultValue: nil)
    }

    mutating func decodeRepeatedSFixed32Field(value: inout [Int32]) throws {
        try setRepeatedValue(&value)
    }

    mutating func decodeSingularSFixed64Field(value: inout Int64) throws {
        try setValue(&value, defaultValue: .init())
    }

    mutating func decodeSingularSFixed64Field(value: inout Int64?) throws {
        try setValue(&value, defaultValue: nil)
    }

    mutating func decodeRepeatedSFixed64Field(value: inout [Int64]) throws {
        try setRepeatedValue(&value)
    }

    mutating func decodeSingularBoolField(value: inout Bool) throws {
        try setValue(&value, defaultValue: .init())
    }

    mutating func decodeSingularBoolField(value: inout Bool?) throws {
        try setValue(&value, defaultValue: nil)
    }

    mutating func decodeRepeatedBoolField(value: inout [Bool]) throws {
        try setRepeatedValue(&value)
    }

    mutating func decodeSingularStringField(value: inout String) throws {
        try setValue(&value, defaultValue: .init())
    }

    mutating func decodeSingularStringField(value: inout String?) throws {
        try setValue(&value, defaultValue: nil)
    }

    mutating func decodeRepeatedStringField(value: inout [String]) throws {
        try setRepeatedValue(&value)
    }

    mutating func decodeSingularBytesField(value: inout Data) throws {
        try setValue(&value, defaultValue: .init())
    }

    mutating func decodeSingularBytesField(value: inout Data?) throws {
        try setValue(&value, defaultValue: nil)
    }

    mutating func decodeRepeatedBytesField(value: inout [Data]) throws {
        try setRepeatedValue(&value)
    }

    mutating func decodeSingularEnumField<E>(
        value: inout E
    ) throws where E: Enum, E.RawValue == Int {
        try setValue(&value, defaultValue: .init())
    }

    mutating func decodeSingularEnumField<E>(
        value: inout E?
    ) throws where E: Enum, E.RawValue == Int {
        try setValue(&value, defaultValue: nil)
    }

    mutating func decodeRepeatedEnumField<E>(
        value: inout [E]
    ) throws where E: Enum, E.RawValue == Int {
        try setRepeatedValue(&value)
    }

    mutating func decodeSingularMessageField<M>(
        value: inout M?
    ) throws where M: Message {
        try setMessageValue(&value)
    }

    mutating func decodeRepeatedMessageField<M>(
        value: inout [M]
    ) throws where M: Message {
        try setRepeatedValue(&value)
    }

    mutating func decodeSingularGroupField<G>(
        value: inout G?
    ) throws where G: Message {
        try setMessageValue(&value)
    }

    mutating func decodeRepeatedGroupField<G>(
        value: inout [G]
    ) throws where G: Message {
        try setRepeatedValue(&value)
    }

    mutating func decodeMapField<KeyType, ValueType>(
        fieldType: _ProtobufMap<KeyType, ValueType>.Type,
        value: inout _ProtobufMap<KeyType, ValueType>.BaseType
    ) throws where KeyType: MapKeyType, ValueType: MapValueType {
        try setMapValue(&value)
    }

    mutating func decodeMapField<KeyType, ValueType>(
        fieldType: _ProtobufEnumMap<KeyType, ValueType>.Type,
        value: inout _ProtobufEnumMap<KeyType, ValueType>.BaseType
    ) throws where KeyType: MapKeyType, ValueType: Enum, ValueType.RawValue == Int {
        try setMapValue(&value)
    }

    mutating func decodeMapField<KeyType, ValueType>(
        fieldType: _ProtobufMessageMap<KeyType, ValueType>.Type,
        value: inout _ProtobufMessageMap<KeyType, ValueType>.BaseType
    ) throws where KeyType: MapKeyType, ValueType: Hashable, ValueType: Message {
        try setMapValue(&value)
    }

    mutating func decodeExtensionField(
        values: inout ExtensionFieldValueSet,
        messageType: any Message.Type,
        fieldNumber: Int
    ) throws {
        preconditionFailure(
            "Internal Error: Path decoder should never decode an extension field"
        )
    }

}

extension Message {
    mutating func `set`(
        path: String,
        value: Any?,
        mergeOption: Google_Protobuf_FieldMask.MergeOptions
    ) throws {
        let _path = path.components(separatedBy: ".")
        var decoder = try PathDecoder<Self>(
            path: _path,
            value: value,
            mergeOption: mergeOption
        )
        try decodeMessage(decoder: &decoder)
    }
}
