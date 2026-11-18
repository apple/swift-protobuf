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

#if FieldMaskUtilities

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

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
    static func number(for field: Substring) -> Int? {
        guard let type = Self.self as? any _ProtoNameProviding.Type else {
            return nil
        }
        let number: Int?
        if let lookedUp = field.utf8.withContiguousStorageIfAvailable({ bytes in
            type._protobuf_nameMap.number(forProtoName: UnsafeRawBufferPointer(bytes))
        }) {
            number = lookedUp
        } else {
            number = Array(field.utf8).withUnsafeBytes { bytes in
                type._protobuf_nameMap.number(forProtoName: bytes)
            }
        }
        guard let number,
            let names = type._protobuf_nameMap.names(for: number),
            names.proto.description[...] == field
        else {
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
    private let fieldNumber: Int
    private var number: Int?

    // Remaining sub-path after the first component, or nil when at a leaf
    private let nextPath: Substring?

    // Merge options to be concidered while setting value
    private let mergeOption: Google_Protobuf_FieldMask.MergeOptions

    // Set when replaceMessageFields requests clearing a present singular
    // message/group field so the caller can clear oneof storage if generated
    // decodeMessage ignored the nil writeback.
    internal private(set) var pendingOneofClearFieldNumber: Int?

    private var replaceRepeatedFields: Bool {
        mergeOption.replaceRepeatedFields
    }

    init(
        path: Substring,
        value: Any?,
        mergeOption: Google_Protobuf_FieldMask.MergeOptions
    ) throws {
        let firstComponent: Substring
        let remaining: Substring?
        if let dot = path.firstIndex(of: ".") {
            firstComponent = path[..<dot]
            remaining = path[path.index(after: dot)...]
        } else {
            firstComponent = path
            remaining = nil
        }
        guard !firstComponent.isEmpty,
            let number = T.number(for: firstComponent)
        else {
            throw PathDecodingError.pathNotFound
        }
        self.fieldNumber = number
        self.number = number
        self.nextPath = remaining
        self.value = value
        self.mergeOption = mergeOption
    }

    private func setValue<V>(_ value: inout V, defaultValue: V) throws {
        if nextPath != nil {
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
        if nextPath != nil {
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
        if nextPath != nil {
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

    private mutating func setMessageValue<M: Message>(
        _ value: inout M?
    ) throws {
        guard let nextPath else {
            // A singular message field named directly by the mask.
            guard let sourceValue = self.value else {
                // When the source has no value for it, clear the destination if
                // replaceMessageFields is set; otherwise leave it untouched.
                if mergeOption.replaceMessageFields, value != nil {
                    value = nil
                    pendingOneofClearFieldNumber = fieldNumber
                }
                return
            }
            guard let src = sourceValue as? M else {
                throw PathDecodingError.typeMismatch
            }
            if mergeOption.replaceMessageFields {
                value = src
                return
            }
            guard var dst = value else {
                value = src
                return
            }
            try mergeMessage(src, into: &dst)
            value = dst
            return
        }
        if M.self == Google_Protobuf_Any.self {
            if value != nil {
                var dstAny = value! as! Google_Protobuf_Any
                try setAnySubPath(path: nextPath, value: self.value, into: &dstAny)
                value = dstAny as? M
            } else {
                var sub = Google_Protobuf_Any()
                try setAnySubPath(path: nextPath, value: self.value, into: &sub)
                value = sub as? M
            }
            return
        }
        var decoder = try PathDecoder<M>(
            path: nextPath,
            value: self.value,
            mergeOption: mergeOption
        )
        if value != nil {
            try value!.decodeMessage(decoder: &decoder)
            if let fieldToClear = decoder.pendingOneofClearFieldNumber {
                try value!.clearFieldIfPresent(fieldNumber: fieldToClear)
            }
        } else {
            var sub = M()
            try sub.decodeMessage(decoder: &decoder)
            if let fieldToClear = decoder.pendingOneofClearFieldNumber {
                try sub.clearFieldIfPresent(fieldNumber: fieldToClear)
            }
            value = sub
        }
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
    internal mutating func `set`(
        path: Substring,
        value: Any?,
        mergeOption: Google_Protobuf_FieldMask.MergeOptions
    ) throws {
        if Self.self == Google_Protobuf_Any.self {
            var anySelf = self as! Google_Protobuf_Any
            try setAnySubPath(path: path, value: value, into: &anySelf)
            self = anySelf as! Self
            return
        }
        var decoder = try PathDecoder<Self>(
            path: path,
            value: value,
            mergeOption: mergeOption
        )
        try decodeMessage(decoder: &decoder)
        if let fieldToClear = decoder.pendingOneofClearFieldNumber {
            try clearFieldIfPresent(fieldNumber: fieldToClear)
        }
    }

    fileprivate mutating func clearFieldIfPresent(fieldNumber: Int) throws {
        var checker = MessageFieldPresenceVisitor(targetFieldNumber: fieldNumber)
        do {
            try traverse(visitor: &checker)
        } catch is MessageFieldFound {
            var visitor = MessageMergeVisitor(excludingFieldNumber: fieldNumber)
            try traverse(visitor: &visitor)
            var rebuilt = Self()
            if !visitor.fields.isEmpty {
                var decoder = MessageMergeDecoder(fields: visitor.fields)
                try rebuilt.decodeMessage(decoder: &decoder)
            }
            if let srcExt = self as? any ExtensibleMessage,
                !srcExt._protobuf_extensionFieldValues.isEmpty,
                var dstExt = rebuilt as? any ExtensibleMessage
            {
                dstExt._protobuf_extensionFieldValues = srcExt._protobuf_extensionFieldValues
                if let updated = dstExt as? Self {
                    rebuilt = updated
                }
            }
            rebuilt.unknownFields = self.unknownFields
            self = rebuilt
        }
    }
}

private struct MessageFieldFound: Error {}

private struct NonEmptyFieldFound: Error {}

/// Merges `src` into `dst` with protobuf `MergeFrom` semantics directly in
/// memory, avoiding binary serialization round-trips.
private func mergeMessage<M: Message>(_ src: M, into dst: inout M) throws {
    if M.self == Google_Protobuf_Any.self {
        var dstAny = dst as! Google_Protobuf_Any
        try mergeAny(src as! Google_Protobuf_Any, into: &dstAny)
        dst = dstAny as! M
        return
    }
    var visitor = MessageMergeVisitor()
    try src.traverse(visitor: &visitor)
    if !visitor.fields.isEmpty {
        var decoder = MessageMergeDecoder(fields: visitor.fields)
        try dst.decodeMessage(decoder: &decoder)
    }
    if let srcExt = src as? any ExtensibleMessage,
        !srcExt._protobuf_extensionFieldValues.isEmpty,
        var dstExt = dst as? any ExtensibleMessage
    {
        try dstExt._protobuf_extensionFieldValues.merge(
            from: srcExt._protobuf_extensionFieldValues
        )
        if let updated = dstExt as? M {
            dst = updated
        }
    }
    if !src.unknownFields.data.isEmpty {
        dst.unknownFields.append(protobufData: src.unknownFields.data)
    }
}

/// Merges two `Google_Protobuf_Any` messages with proto3 `MergeFrom` semantics
/// (`type_url` and `value` overwrite when non-empty) while preserving decoded
/// binary depth budgets and avoiding cross-type `AnyMessageStorage` corruption
/// or unnecessary JSON/message transcoding.
private func mergeAny(_ src: Google_Protobuf_Any, into dst: inout Google_Protobuf_Any) throws {
    if dst._storage !== src._storage {
        let srcTypeURL = src._storage._typeURL
        switch src._storage.state {
        case .binary(let srcData):
            if !srcData.isEmpty {
                let storage = dst._uniqueStorage()
                if !srcTypeURL.isEmpty {
                    storage._typeURL = srcTypeURL
                }
                storage.state = .binary(srcData)
                storage._binaryRemainingDepth = src._storage._binaryRemainingDepth
            } else if !srcTypeURL.isEmpty {
                try materializeTypeURLChangeOnly(newTypeURL: srcTypeURL, into: &dst)
            }
        case .message(let srcMsg):
            if try hasSerializedContent(srcMsg) {
                if !srcTypeURL.isEmpty {
                    let storage = dst._uniqueStorage()
                    storage._typeURL = srcTypeURL
                    storage.state = .message(srcMsg)
                } else if dst._storage._typeURL.isEmpty {
                    dst._uniqueStorage().state = .message(srcMsg)
                } else {
                    let srcBytes: Data = try srcMsg.serializedBytes(partial: true)
                    dst._uniqueStorage().state = .binary(srcBytes)
                }
            } else if !srcTypeURL.isEmpty {
                try materializeTypeURLChangeOnly(newTypeURL: srcTypeURL, into: &dst)
            }
        case .contentJSON(let srcJSON, let srcOpts):
            let dstHasEmptyValue: Bool
            switch dst._storage.state {
            case .binary(let dstData):
                dstHasEmptyValue = dstData.isEmpty
            case .message(let dstMsg):
                dstHasEmptyValue = !(try hasSerializedContent(dstMsg))
            case .contentJSON:
                dstHasEmptyValue = false
            }
            if dstHasEmptyValue && !srcTypeURL.isEmpty {
                let storage = dst._uniqueStorage()
                storage._typeURL = srcTypeURL
                storage.state = .contentJSON(srcJSON, srcOpts)
            } else {
                let srcBytes = try src._storage.serializedContentJSONBytes(
                    contentJSON: srcJSON,
                    options: srcOpts
                )
                if !srcBytes.isEmpty {
                    let storage = dst._uniqueStorage()
                    if !srcTypeURL.isEmpty {
                        storage._typeURL = srcTypeURL
                        storage.state = .contentJSON(srcJSON, srcOpts)
                    } else {
                        storage.state = .binary(srcBytes)
                    }
                } else if !srcTypeURL.isEmpty {
                    try materializeTypeURLChangeOnly(newTypeURL: srcTypeURL, into: &dst)
                }
            }
        }
    }
    if !src.unknownFields.data.isEmpty {
        dst.unknownFields.append(protobufData: src.unknownFields.data)
    }
}

/// Applies a `"type_url"` or `"value"` sub-path write directly to a
/// `Google_Protobuf_Any`, maintaining `AnyMessageStorage` state invariants and
/// preserving decoded binary recursion budgets.
private func setAnySubPath(
    path: Substring,
    value: Any?,
    into dst: inout Google_Protobuf_Any
) throws {
    switch path {
    case "type_url":
        let newTypeURL: String
        if let value {
            guard let stringValue = value as? String else {
                throw PathDecodingError.typeMismatch
            }
            newTypeURL = stringValue
        } else {
            newTypeURL = ""
        }
        try materializeTypeURLChangeOnly(newTypeURL: newTypeURL, into: &dst)
    case "value":
        let newData: Data
        let newRemainingDepth: Int?
        if let value {
            if let wrapped = value as? AnyBinaryFieldValue {
                newData = wrapped.data
                newRemainingDepth = wrapped.binaryRemainingDepth
            } else if let rawData = value as? Data {
                newData = rawData
                newRemainingDepth = nil
            } else {
                throw PathDecodingError.typeMismatch
            }
        } else {
            newData = Data()
            newRemainingDepth = nil
        }
        if case .binary(let existing) = dst._storage.state,
            existing == newData,
            dst._storage._binaryRemainingDepth == newRemainingDepth
        {
            return
        }
        let storage = dst._uniqueStorage()
        storage.state = .binary(newData)
        storage._binaryRemainingDepth = newRemainingDepth
    default:
        throw PathDecodingError.pathNotFound
    }
}

/// Applies a `type_url`-only merge onto `dst` (when `src.value` is empty),
/// materializing any `.message` or `.contentJSON` state to `.binary` if
/// `type_url` changes so `_typeURL` and `state` never disagree.
private func materializeTypeURLChangeOnly(
    newTypeURL: String,
    into dst: inout Google_Protobuf_Any
) throws {
    guard dst._storage._typeURL != newTypeURL else {
        return
    }
    switch dst._storage.state {
    case .binary:
        dst._uniqueStorage()._typeURL = newTypeURL
    case .message(let dstMsg):
        let dstBytes: Data = try dstMsg.serializedBytes(partial: true)
        let storage = dst._uniqueStorage()
        storage._typeURL = newTypeURL
        storage.state = .binary(dstBytes)
    case .contentJSON(let dstJSON, let dstOpts):
        let dstBytes = try dst._storage.serializedContentJSONBytes(
            contentJSON: dstJSON,
            options: dstOpts
        )
        let storage = dst._uniqueStorage()
        storage._typeURL = newTypeURL
        storage.state = .binary(dstBytes)
    }
}

private func hasSerializedContent(_ message: any Message) throws -> Bool {
    if let any = message as? Google_Protobuf_Any {
        return try anyHasSerializedContent(any)
    }
    var visitor = NonEmptyCheckVisitor()
    do {
        try message.traverse(visitor: &visitor)
        return false
    } catch is NonEmptyFieldFound {
        return true
    }
}

private func anyHasSerializedContent(_ any: Google_Protobuf_Any) throws -> Bool {
    if !any._storage._typeURL.isEmpty || !any.unknownFields.data.isEmpty {
        return true
    }
    switch any._storage.state {
    case .binary(let data):
        return !data.isEmpty
    case .message(let inner):
        return try hasSerializedContent(inner)
    case .contentJSON(let contentJSON, let options):
        return try
            !(any._storage.serializedContentJSONBytes(
                contentJSON: contentJSON,
                options: options
            ).isEmpty)
    }
}

/// Visitor that checks whether a message has any wire-serializable field.
private struct NonEmptyCheckVisitor: Visitor {
    internal mutating func visitSingularDoubleField(value: Double, fieldNumber: Int) throws {
        throw NonEmptyFieldFound()
    }
    internal mutating func visitSingularInt64Field(value: Int64, fieldNumber: Int) throws {
        throw NonEmptyFieldFound()
    }
    internal mutating func visitSingularUInt64Field(value: UInt64, fieldNumber: Int) throws {
        throw NonEmptyFieldFound()
    }
    internal mutating func visitSingularBoolField(value: Bool, fieldNumber: Int) throws {
        throw NonEmptyFieldFound()
    }
    internal mutating func visitSingularStringField(value: String, fieldNumber: Int) throws {
        throw NonEmptyFieldFound()
    }
    internal mutating func visitSingularBytesField(value: Data, fieldNumber: Int) throws {
        throw NonEmptyFieldFound()
    }
    internal mutating func visitSingularEnumField<E: Enum>(value: E, fieldNumber: Int) throws {
        throw NonEmptyFieldFound()
    }
    internal mutating func visitSingularMessageField<M: Message>(value: M, fieldNumber: Int) throws {
        throw NonEmptyFieldFound()
    }
    internal mutating func visitMapField<KeyType, ValueType: MapValueType>(
        fieldType: _ProtobufMap<KeyType, ValueType>.Type,
        value: _ProtobufMap<KeyType, ValueType>.BaseType,
        fieldNumber: Int
    ) throws {
        if !value.isEmpty {
            throw NonEmptyFieldFound()
        }
    }
    internal mutating func visitMapField<KeyType, ValueType>(
        fieldType: _ProtobufEnumMap<KeyType, ValueType>.Type,
        value: _ProtobufEnumMap<KeyType, ValueType>.BaseType,
        fieldNumber: Int
    ) throws where ValueType.RawValue == Int {
        if !value.isEmpty {
            throw NonEmptyFieldFound()
        }
    }
    internal mutating func visitMapField<KeyType, ValueType>(
        fieldType: _ProtobufMessageMap<KeyType, ValueType>.Type,
        value: _ProtobufMessageMap<KeyType, ValueType>.BaseType,
        fieldNumber: Int
    ) throws {
        if !value.isEmpty {
            throw NonEmptyFieldFound()
        }
    }
    internal mutating func visitUnknown(bytes: Data) throws {
        if !bytes.isEmpty {
            throw NonEmptyFieldFound()
        }
    }
}

/// Visitor that checks whether a specific singular message/group field number
/// is still present on a message without traversing into submessages or Any.
private struct MessageFieldPresenceVisitor: Visitor {
    private let targetFieldNumber: Int

    internal init(targetFieldNumber: Int) {
        self.targetFieldNumber = targetFieldNumber
    }

    internal mutating func visitSingularDoubleField(value: Double, fieldNumber: Int) throws {}
    internal mutating func visitSingularInt64Field(value: Int64, fieldNumber: Int) throws {}
    internal mutating func visitSingularUInt64Field(value: UInt64, fieldNumber: Int) throws {}
    internal mutating func visitSingularBoolField(value: Bool, fieldNumber: Int) throws {}
    internal mutating func visitSingularStringField(value: String, fieldNumber: Int) throws {}
    internal mutating func visitSingularBytesField(value: Data, fieldNumber: Int) throws {}
    internal mutating func visitSingularEnumField<E: Enum>(value: E, fieldNumber: Int) throws {}
    internal mutating func visitSingularMessageField<M: Message>(value: M, fieldNumber: Int) throws {
        if fieldNumber == targetFieldNumber {
            throw MessageFieldFound()
        }
    }

    internal mutating func visitRepeatedFloatField(value: [Float], fieldNumber: Int) throws {}
    internal mutating func visitRepeatedDoubleField(value: [Double], fieldNumber: Int) throws {}
    internal mutating func visitRepeatedInt32Field(value: [Int32], fieldNumber: Int) throws {}
    internal mutating func visitRepeatedInt64Field(value: [Int64], fieldNumber: Int) throws {}
    internal mutating func visitRepeatedUInt32Field(value: [UInt32], fieldNumber: Int) throws {}
    internal mutating func visitRepeatedUInt64Field(value: [UInt64], fieldNumber: Int) throws {}
    internal mutating func visitRepeatedSInt32Field(value: [Int32], fieldNumber: Int) throws {}
    internal mutating func visitRepeatedSInt64Field(value: [Int64], fieldNumber: Int) throws {}
    internal mutating func visitRepeatedFixed32Field(value: [UInt32], fieldNumber: Int) throws {}
    internal mutating func visitRepeatedFixed64Field(value: [UInt64], fieldNumber: Int) throws {}
    internal mutating func visitRepeatedSFixed32Field(value: [Int32], fieldNumber: Int) throws {}
    internal mutating func visitRepeatedSFixed64Field(value: [Int64], fieldNumber: Int) throws {}
    internal mutating func visitRepeatedBoolField(value: [Bool], fieldNumber: Int) throws {}
    internal mutating func visitRepeatedStringField(value: [String], fieldNumber: Int) throws {}
    internal mutating func visitRepeatedBytesField(value: [Data], fieldNumber: Int) throws {}
    internal mutating func visitRepeatedEnumField<E: Enum>(value: [E], fieldNumber: Int) throws {}
    internal mutating func visitRepeatedMessageField<M: Message>(value: [M], fieldNumber: Int) throws {}
    internal mutating func visitRepeatedGroupField<G: Message>(value: [G], fieldNumber: Int) throws {}

    internal mutating func visitMapField<KeyType, ValueType: MapValueType>(
        fieldType: _ProtobufMap<KeyType, ValueType>.Type,
        value: _ProtobufMap<KeyType, ValueType>.BaseType,
        fieldNumber: Int
    ) throws {}
    internal mutating func visitMapField<KeyType, ValueType>(
        fieldType: _ProtobufEnumMap<KeyType, ValueType>.Type,
        value: _ProtobufEnumMap<KeyType, ValueType>.BaseType,
        fieldNumber: Int
    ) throws where ValueType.RawValue == Int {}
    internal mutating func visitMapField<KeyType, ValueType>(
        fieldType: _ProtobufMessageMap<KeyType, ValueType>.Type,
        value: _ProtobufMessageMap<KeyType, ValueType>.BaseType,
        fieldNumber: Int
    ) throws {}

    internal mutating func visitExtensionFields(
        fields: ExtensionFieldValueSet,
        start: Int,
        end: Int
    ) throws {}
    internal mutating func visitExtensionFieldsAsMessageSet(
        fields: ExtensionFieldValueSet,
        start: Int,
        end: Int
    ) throws {}
    internal mutating func visitUnknown(bytes: Data) throws {}
}

/// Captures top-level present non-extension fields of a message with exact
/// Swift types for direct in-memory `MergeFrom` replay via `MessageMergeDecoder`.
internal struct MessageMergeVisitor: Visitor {
    internal private(set) var fields: [(fieldNumber: Int, value: Any)] = []
    private let excludingFieldNumber: Int?

    internal init(excludingFieldNumber: Int? = nil) {
        self.excludingFieldNumber = excludingFieldNumber
    }

    private mutating func record(_ value: Any, fieldNumber: Int) {
        if fieldNumber != excludingFieldNumber {
            fields.append((fieldNumber, value))
        }
    }

    internal mutating func visitSingularFloatField(value: Float, fieldNumber: Int) throws {
        record(value, fieldNumber: fieldNumber)
    }
    internal mutating func visitSingularDoubleField(value: Double, fieldNumber: Int) throws {
        record(value, fieldNumber: fieldNumber)
    }
    internal mutating func visitSingularInt32Field(value: Int32, fieldNumber: Int) throws {
        record(value, fieldNumber: fieldNumber)
    }
    internal mutating func visitSingularInt64Field(value: Int64, fieldNumber: Int) throws {
        record(value, fieldNumber: fieldNumber)
    }
    internal mutating func visitSingularUInt32Field(value: UInt32, fieldNumber: Int) throws {
        record(value, fieldNumber: fieldNumber)
    }
    internal mutating func visitSingularUInt64Field(value: UInt64, fieldNumber: Int) throws {
        record(value, fieldNumber: fieldNumber)
    }
    internal mutating func visitSingularSInt32Field(value: Int32, fieldNumber: Int) throws {
        record(value, fieldNumber: fieldNumber)
    }
    internal mutating func visitSingularSInt64Field(value: Int64, fieldNumber: Int) throws {
        record(value, fieldNumber: fieldNumber)
    }
    internal mutating func visitSingularFixed32Field(value: UInt32, fieldNumber: Int) throws {
        record(value, fieldNumber: fieldNumber)
    }
    internal mutating func visitSingularFixed64Field(value: UInt64, fieldNumber: Int) throws {
        record(value, fieldNumber: fieldNumber)
    }
    internal mutating func visitSingularSFixed32Field(value: Int32, fieldNumber: Int) throws {
        record(value, fieldNumber: fieldNumber)
    }
    internal mutating func visitSingularSFixed64Field(value: Int64, fieldNumber: Int) throws {
        record(value, fieldNumber: fieldNumber)
    }
    internal mutating func visitSingularBoolField(value: Bool, fieldNumber: Int) throws {
        record(value, fieldNumber: fieldNumber)
    }
    internal mutating func visitSingularStringField(value: String, fieldNumber: Int) throws {
        record(value, fieldNumber: fieldNumber)
    }
    internal mutating func visitSingularBytesField(value: Data, fieldNumber: Int) throws {
        record(value, fieldNumber: fieldNumber)
    }
    internal mutating func visitSingularEnumField<E: Enum>(value: E, fieldNumber: Int) throws {
        record(value, fieldNumber: fieldNumber)
    }
    internal mutating func visitSingularMessageField<M: Message>(value: M, fieldNumber: Int) throws {
        record(value, fieldNumber: fieldNumber)
    }
    internal mutating func visitSingularGroupField<G: Message>(value: G, fieldNumber: Int) throws {
        record(value, fieldNumber: fieldNumber)
    }

    internal mutating func visitRepeatedFloatField(value: [Float], fieldNumber: Int) throws {
        record(value, fieldNumber: fieldNumber)
    }
    internal mutating func visitRepeatedDoubleField(value: [Double], fieldNumber: Int) throws {
        record(value, fieldNumber: fieldNumber)
    }
    internal mutating func visitRepeatedInt32Field(value: [Int32], fieldNumber: Int) throws {
        record(value, fieldNumber: fieldNumber)
    }
    internal mutating func visitRepeatedInt64Field(value: [Int64], fieldNumber: Int) throws {
        record(value, fieldNumber: fieldNumber)
    }
    internal mutating func visitRepeatedUInt32Field(value: [UInt32], fieldNumber: Int) throws {
        record(value, fieldNumber: fieldNumber)
    }
    internal mutating func visitRepeatedUInt64Field(value: [UInt64], fieldNumber: Int) throws {
        record(value, fieldNumber: fieldNumber)
    }
    internal mutating func visitRepeatedSInt32Field(value: [Int32], fieldNumber: Int) throws {
        record(value, fieldNumber: fieldNumber)
    }
    internal mutating func visitRepeatedSInt64Field(value: [Int64], fieldNumber: Int) throws {
        record(value, fieldNumber: fieldNumber)
    }
    internal mutating func visitRepeatedFixed32Field(value: [UInt32], fieldNumber: Int) throws {
        record(value, fieldNumber: fieldNumber)
    }
    internal mutating func visitRepeatedFixed64Field(value: [UInt64], fieldNumber: Int) throws {
        record(value, fieldNumber: fieldNumber)
    }
    internal mutating func visitRepeatedSFixed32Field(value: [Int32], fieldNumber: Int) throws {
        record(value, fieldNumber: fieldNumber)
    }
    internal mutating func visitRepeatedSFixed64Field(value: [Int64], fieldNumber: Int) throws {
        record(value, fieldNumber: fieldNumber)
    }
    internal mutating func visitRepeatedBoolField(value: [Bool], fieldNumber: Int) throws {
        record(value, fieldNumber: fieldNumber)
    }
    internal mutating func visitRepeatedStringField(value: [String], fieldNumber: Int) throws {
        record(value, fieldNumber: fieldNumber)
    }
    internal mutating func visitRepeatedBytesField(value: [Data], fieldNumber: Int) throws {
        record(value, fieldNumber: fieldNumber)
    }
    internal mutating func visitRepeatedEnumField<E: Enum>(value: [E], fieldNumber: Int) throws {
        record(value, fieldNumber: fieldNumber)
    }
    internal mutating func visitRepeatedMessageField<M: Message>(value: [M], fieldNumber: Int) throws {
        record(value, fieldNumber: fieldNumber)
    }
    internal mutating func visitRepeatedGroupField<G: Message>(value: [G], fieldNumber: Int) throws {
        record(value, fieldNumber: fieldNumber)
    }

    internal mutating func visitMapField<KeyType, ValueType: MapValueType>(
        fieldType: _ProtobufMap<KeyType, ValueType>.Type,
        value: _ProtobufMap<KeyType, ValueType>.BaseType,
        fieldNumber: Int
    ) throws {
        record(value, fieldNumber: fieldNumber)
    }
    internal mutating func visitMapField<KeyType, ValueType>(
        fieldType: _ProtobufEnumMap<KeyType, ValueType>.Type,
        value: _ProtobufEnumMap<KeyType, ValueType>.BaseType,
        fieldNumber: Int
    ) throws where ValueType.RawValue == Int {
        record(value, fieldNumber: fieldNumber)
    }
    internal mutating func visitMapField<KeyType, ValueType>(
        fieldType: _ProtobufMessageMap<KeyType, ValueType>.Type,
        value: _ProtobufMessageMap<KeyType, ValueType>.BaseType,
        fieldNumber: Int
    ) throws {
        record(value, fieldNumber: fieldNumber)
    }

    internal mutating func visitExtensionFields(
        fields: ExtensionFieldValueSet,
        start: Int,
        end: Int
    ) throws {}
    internal mutating func visitExtensionFieldsAsMessageSet(
        fields: ExtensionFieldValueSet,
        start: Int,
        end: Int
    ) throws {}
    internal mutating func visitUnknown(bytes: Data) throws {}
}

/// Replays fields captured by `MessageMergeVisitor` into a destination message
/// with protobuf `MergeFrom` semantics.
internal struct MessageMergeDecoder: Decoder {
    private let fields: [(fieldNumber: Int, value: Any)]
    private var index = 0
    private var currentValue: Any?

    internal init(fields: [(fieldNumber: Int, value: Any)]) {
        self.fields = fields
    }

    private func setSingular<V>(_ value: inout V) throws {
        guard let casted = currentValue as? V else {
            throw PathDecodingError.typeMismatch
        }
        value = casted
    }

    private func setSingularOptional<V>(_ value: inout V?) throws {
        guard let casted = currentValue as? V else {
            throw PathDecodingError.typeMismatch
        }
        value = casted
    }

    private func appendRepeated<V>(_ value: inout [V]) throws {
        guard let casted = currentValue as? [V] else {
            throw PathDecodingError.typeMismatch
        }
        value.append(contentsOf: casted)
    }

    private func mergeMap<K, V>(_ value: inout [K: V]) throws {
        guard let casted = currentValue as? [K: V] else {
            throw PathDecodingError.typeMismatch
        }
        value.merge(casted) { _, new in
            new
        }
    }

    private func mergeSingularMessage<M: Message>(_ value: inout M?) throws {
        guard let src = currentValue as? M else {
            throw PathDecodingError.typeMismatch
        }
        if var dst = value {
            try mergeMessage(src, into: &dst)
            value = dst
        } else {
            value = src
        }
    }

    internal mutating func handleConflictingOneOf() throws {}

    internal mutating func nextFieldNumber() throws -> Int? {
        guard index < fields.count else {
            currentValue = nil
            return nil
        }
        let field = fields[index]
        index += 1
        currentValue = field.value
        return field.fieldNumber
    }

    internal mutating func decodeSingularFloatField(value: inout Float) throws {
        try setSingular(&value)
    }
    internal mutating func decodeSingularFloatField(value: inout Float?) throws {
        try setSingularOptional(&value)
    }
    internal mutating func decodeRepeatedFloatField(value: inout [Float]) throws {
        try appendRepeated(&value)
    }

    internal mutating func decodeSingularDoubleField(value: inout Double) throws {
        try setSingular(&value)
    }
    internal mutating func decodeSingularDoubleField(value: inout Double?) throws {
        try setSingularOptional(&value)
    }
    internal mutating func decodeRepeatedDoubleField(value: inout [Double]) throws {
        try appendRepeated(&value)
    }

    internal mutating func decodeSingularInt32Field(value: inout Int32) throws {
        try setSingular(&value)
    }
    internal mutating func decodeSingularInt32Field(value: inout Int32?) throws {
        try setSingularOptional(&value)
    }
    internal mutating func decodeRepeatedInt32Field(value: inout [Int32]) throws {
        try appendRepeated(&value)
    }

    internal mutating func decodeSingularInt64Field(value: inout Int64) throws {
        try setSingular(&value)
    }
    internal mutating func decodeSingularInt64Field(value: inout Int64?) throws {
        try setSingularOptional(&value)
    }
    internal mutating func decodeRepeatedInt64Field(value: inout [Int64]) throws {
        try appendRepeated(&value)
    }

    internal mutating func decodeSingularUInt32Field(value: inout UInt32) throws {
        try setSingular(&value)
    }
    internal mutating func decodeSingularUInt32Field(value: inout UInt32?) throws {
        try setSingularOptional(&value)
    }
    internal mutating func decodeRepeatedUInt32Field(value: inout [UInt32]) throws {
        try appendRepeated(&value)
    }

    internal mutating func decodeSingularUInt64Field(value: inout UInt64) throws {
        try setSingular(&value)
    }
    internal mutating func decodeSingularUInt64Field(value: inout UInt64?) throws {
        try setSingularOptional(&value)
    }
    internal mutating func decodeRepeatedUInt64Field(value: inout [UInt64]) throws {
        try appendRepeated(&value)
    }

    internal mutating func decodeSingularSInt32Field(value: inout Int32) throws {
        try setSingular(&value)
    }
    internal mutating func decodeSingularSInt32Field(value: inout Int32?) throws {
        try setSingularOptional(&value)
    }
    internal mutating func decodeRepeatedSInt32Field(value: inout [Int32]) throws {
        try appendRepeated(&value)
    }

    internal mutating func decodeSingularSInt64Field(value: inout Int64) throws {
        try setSingular(&value)
    }
    internal mutating func decodeSingularSInt64Field(value: inout Int64?) throws {
        try setSingularOptional(&value)
    }
    internal mutating func decodeRepeatedSInt64Field(value: inout [Int64]) throws {
        try appendRepeated(&value)
    }

    internal mutating func decodeSingularFixed32Field(value: inout UInt32) throws {
        try setSingular(&value)
    }
    internal mutating func decodeSingularFixed32Field(value: inout UInt32?) throws {
        try setSingularOptional(&value)
    }
    internal mutating func decodeRepeatedFixed32Field(value: inout [UInt32]) throws {
        try appendRepeated(&value)
    }

    internal mutating func decodeSingularFixed64Field(value: inout UInt64) throws {
        try setSingular(&value)
    }
    internal mutating func decodeSingularFixed64Field(value: inout UInt64?) throws {
        try setSingularOptional(&value)
    }
    internal mutating func decodeRepeatedFixed64Field(value: inout [UInt64]) throws {
        try appendRepeated(&value)
    }

    internal mutating func decodeSingularSFixed32Field(value: inout Int32) throws {
        try setSingular(&value)
    }
    internal mutating func decodeSingularSFixed32Field(value: inout Int32?) throws {
        try setSingularOptional(&value)
    }
    internal mutating func decodeRepeatedSFixed32Field(value: inout [Int32]) throws {
        try appendRepeated(&value)
    }

    internal mutating func decodeSingularSFixed64Field(value: inout Int64) throws {
        try setSingular(&value)
    }
    internal mutating func decodeSingularSFixed64Field(value: inout Int64?) throws {
        try setSingularOptional(&value)
    }
    internal mutating func decodeRepeatedSFixed64Field(value: inout [Int64]) throws {
        try appendRepeated(&value)
    }

    internal mutating func decodeSingularBoolField(value: inout Bool) throws {
        try setSingular(&value)
    }
    internal mutating func decodeSingularBoolField(value: inout Bool?) throws {
        try setSingularOptional(&value)
    }
    internal mutating func decodeRepeatedBoolField(value: inout [Bool]) throws {
        try appendRepeated(&value)
    }

    internal mutating func decodeSingularStringField(value: inout String) throws {
        try setSingular(&value)
    }
    internal mutating func decodeSingularStringField(value: inout String?) throws {
        try setSingularOptional(&value)
    }
    internal mutating func decodeRepeatedStringField(value: inout [String]) throws {
        try appendRepeated(&value)
    }

    internal mutating func decodeSingularBytesField(value: inout Data) throws {
        try setSingular(&value)
    }
    internal mutating func decodeSingularBytesField(value: inout Data?) throws {
        try setSingularOptional(&value)
    }
    internal mutating func decodeRepeatedBytesField(value: inout [Data]) throws {
        try appendRepeated(&value)
    }

    internal mutating func decodeSingularEnumField<E>(
        value: inout E
    ) throws where E: Enum, E.RawValue == Int {
        try setSingular(&value)
    }
    internal mutating func decodeSingularEnumField<E>(
        value: inout E?
    ) throws where E: Enum, E.RawValue == Int {
        try setSingularOptional(&value)
    }
    internal mutating func decodeRepeatedEnumField<E>(
        value: inout [E]
    ) throws where E: Enum, E.RawValue == Int {
        try appendRepeated(&value)
    }

    internal mutating func decodeSingularMessageField<M>(
        value: inout M?
    ) throws where M: Message {
        try mergeSingularMessage(&value)
    }
    internal mutating func decodeRepeatedMessageField<M>(
        value: inout [M]
    ) throws where M: Message {
        try appendRepeated(&value)
    }

    internal mutating func decodeSingularGroupField<G>(
        value: inout G?
    ) throws where G: Message {
        try mergeSingularMessage(&value)
    }
    internal mutating func decodeRepeatedGroupField<G>(
        value: inout [G]
    ) throws where G: Message {
        try appendRepeated(&value)
    }

    internal mutating func decodeMapField<KeyType, ValueType>(
        fieldType: _ProtobufMap<KeyType, ValueType>.Type,
        value: inout _ProtobufMap<KeyType, ValueType>.BaseType
    ) throws where KeyType: MapKeyType, ValueType: MapValueType {
        try mergeMap(&value)
    }
    internal mutating func decodeMapField<KeyType, ValueType>(
        fieldType: _ProtobufEnumMap<KeyType, ValueType>.Type,
        value: inout _ProtobufEnumMap<KeyType, ValueType>.BaseType
    ) throws where KeyType: MapKeyType, ValueType: Enum, ValueType.RawValue == Int {
        try mergeMap(&value)
    }
    internal mutating func decodeMapField<KeyType, ValueType>(
        fieldType: _ProtobufMessageMap<KeyType, ValueType>.Type,
        value: inout _ProtobufMessageMap<KeyType, ValueType>.BaseType
    ) throws where KeyType: MapKeyType, ValueType: Hashable, ValueType: Message {
        try mergeMap(&value)
    }

    internal mutating func decodeExtensionField(
        values: inout ExtensionFieldValueSet,
        messageType: any Message.Type,
        fieldNumber: Int
    ) throws {
        preconditionFailure(
            "Internal Error: MessageMergeDecoder should never decode an extension field directly"
        )
    }
}

#endif
