// ProtobufRuntime/Sources/Protobuf/ProtobufExtensionFields.swift - Extension support
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
/// Core protocols implemented by generated extensions.
///
// -----------------------------------------------------------------------------

import Swift

private let i_2166136261 = Int(bitPattern: 2166136261)
private let i_16777619 = Int(16777619)

//
// Type-erased Extension field implementation.
// Note that it has no "self or associated type" references, so can
// be used as a protocol type.  (In particular, although it does have
// a hashValue property, it cannot be Hashable.)
//
// This can encode, decode, return a hashValue and test for
// equality with some other extension field; but it's type-sealed
// so you can't actually access the contained value itself.
//
public protocol AnyExtensionField: CustomDebugStringConvertible {
    var hashValue: Int { get }
    func isEqual(other: AnyExtensionField) -> Bool

    /// General field decoding
    mutating func decodeField(setter: inout FieldDecoder) throws

    /// Fields know their own type, so can dispatch to a visitor
    func traverse(visitor: inout Visitor) throws
}

///
/// The regular ExtensionField type exposes the value directly.
///
public protocol ExtensionField: AnyExtensionField, Hashable {
    associatedtype ValueType
    var value: ValueType {get set}
    init(protobufExtension: MessageExtensionBase)
}

///
/// Singular field
///
public struct OptionalExtensionField<T: FieldType>: ExtensionField {
    public typealias BaseType = T.BaseType
    public typealias ValueType = BaseType?
    public var value: ValueType
    private var protobufExtension: MessageExtensionBase

    public init(protobufExtension: MessageExtensionBase) {
        self.protobufExtension = protobufExtension
    }

    public var debugDescription: String {
        get {
            if let value = value {
                return String(reflecting: value)
            }
            return ""
        }
    }

    public var hashValue: Int {
        get { return value?.hashValue ?? 0 }
    }

    public func isEqual(other: AnyExtensionField) -> Bool {
        let o = other as! OptionalExtensionField<T>
        return self == o
    }

    public mutating func decodeField(setter: inout FieldDecoder) throws {
        try setter.decodeSingularField(fieldType: T.self, value: &value)
    }

    public func traverse(visitor: inout Visitor) throws {
        if let v = value {
            try visitor.visitSingularField(fieldType: T.self, value: v, protoFieldNumber: protobufExtension.protoFieldNumber, protoFieldName: protobufExtension.protoFieldName, jsonFieldName: protobufExtension.jsonFieldName, swiftFieldName: protobufExtension.swiftFieldName)
        }
    }

}

public func ==<T: FieldType>(lhs: OptionalExtensionField<T>, rhs: OptionalExtensionField<T>) -> Bool {
    if let l = lhs.value {
        if let r = rhs.value {
            return l == r
        }
        return false
    } else if let _ = rhs.value {
        return false
    }
    return true // Both nil
}

///
/// Repeated fields
///
public struct RepeatedExtensionField<T: FieldType>: ExtensionField {
    public typealias BaseType = T.BaseType
    public typealias ValueType = [BaseType]
    public var value = ValueType()
    private var protobufExtension: MessageExtensionBase

    public init(protobufExtension: MessageExtensionBase) {
        self.protobufExtension = protobufExtension
    }

    public var hashValue: Int {
        get {
            var hash = i_2166136261
            for e in value {
                hash = (hash &* i_16777619) ^ e.hashValue
            }
            return hash
        }
    }

    public func isEqual(other: AnyExtensionField) -> Bool {
        let o = other as! RepeatedExtensionField<T>
        return self == o
    }

    public var debugDescription: String {
        return "[" + value.map{String(reflecting: $0)}.joined(separator: ",") + "]"
    }

    public mutating func decodeField(setter: inout FieldDecoder) throws {
        try setter.decodeRepeatedField(fieldType: T.self, value: &value)
    }

    public func traverse(visitor: inout Visitor) throws {
        if value.count > 0 {
            try visitor.visitRepeatedField(fieldType: T.self, value: value, protoFieldNumber: protobufExtension.protoFieldNumber, protoFieldName: protobufExtension.protoFieldName, jsonFieldName: protobufExtension.jsonFieldName, swiftFieldName: protobufExtension.swiftFieldName)
        }
    }
}

public func ==<T: FieldType>(lhs: RepeatedExtensionField<T>, rhs: RepeatedExtensionField<T>) -> Bool {
    if lhs.value.count != rhs.value.count {
        return false
    }
    for (l, r) in zip(lhs.value, rhs.value) {
        if l != r {
            return false
        }
    }
    return true
}

///
/// Packed Repeated fields
///
/// TODO: This is almost (but not quite) identical to RepeatedFields;
/// find a way to collapse the implementations.
///
public struct PackedExtensionField<T: FieldType>: ExtensionField {

    public typealias BaseType = T.BaseType
    public typealias ValueType = [BaseType]
    public var value = ValueType()
    private var protobufExtension: MessageExtensionBase

    public init(protobufExtension: MessageExtensionBase) {
        self.protobufExtension = protobufExtension
    }

    public var hashValue: Int {
        get {
            var hash = i_2166136261
            for e in value {
                hash = (hash &* i_16777619) ^ e.hashValue
            }
            return hash
        }
    }

    public func isEqual(other: AnyExtensionField) -> Bool {
        let o = other as! PackedExtensionField<T>
        return self == o
    }

    public var debugDescription: String {
        return "[" + value.map{String(reflecting: $0)}.joined(separator: ",") + "]"
    }

    public mutating func decodeField(setter: inout FieldDecoder) throws {
        try setter.decodePackedField(fieldType: T.self, value: &value)
    }

    public func traverse(visitor: inout Visitor) throws {
        if value.count > 0 {
            try visitor.visitPackedField(fieldType: T.self, value: value, protoFieldNumber: protobufExtension.protoFieldNumber, protoFieldName: protobufExtension.protoFieldName, jsonFieldName: protobufExtension.jsonFieldName, swiftFieldName: protobufExtension.swiftFieldName)
        }
    }
}

public func ==<T: FieldType>(lhs: PackedExtensionField<T>, rhs: PackedExtensionField<T>) -> Bool {
    if lhs.value.count != rhs.value.count {
        return false
    }
    for (l, r) in zip(lhs.value, rhs.value) {
        if l != r {
            return false
        }
    }
    return true
}

//
// ========== Message ==========
//
public struct OptionalMessageExtensionField<M: Message & Equatable>: ExtensionField {
    public typealias BaseType = M
    public typealias ValueType = BaseType?
    public var value: ValueType
    private var protobufExtension: MessageExtensionBase

    public init(protobufExtension: MessageExtensionBase) {
        self.protobufExtension = protobufExtension
    }

    public var debugDescription: String {
        get {
            if let value = value {
                return String(reflecting: value)
            }
            return ""
        }
    }

    public var hashValue: Int {return value?.hashValue ?? 0}

    public func isEqual(other: AnyExtensionField) -> Bool {
        let o = other as! OptionalMessageExtensionField<M>
        return self == o
    }

    public mutating func decodeField(setter: inout FieldDecoder) throws {
        try setter.decodeSingularMessageField(fieldType: M.self, value: &value)
    }

    public func traverse(visitor: inout Visitor) throws {
        if let v = value {
            try visitor.visitSingularMessageField(value: v, protoFieldNumber: protobufExtension.protoFieldNumber, protoFieldName: protobufExtension.protoFieldName, jsonFieldName: protobufExtension.jsonFieldName, swiftFieldName: protobufExtension.swiftFieldName)
        }
    }
}

public func ==<M: Message & Equatable>(lhs: OptionalMessageExtensionField<M>, rhs: OptionalMessageExtensionField<M>) -> Bool {
    if let l = lhs.value {
        if let r = rhs.value {
            return l == r
        }
        return false
    } else if let _ = rhs.value {
        return false
    }
    return true // Both nil
}

public struct RepeatedMessageExtensionField<M: Message & Equatable>: ExtensionField {
    public typealias BaseType = M
    public typealias ValueType = [BaseType]
    public var value = ValueType()
    private var protobufExtension: MessageExtensionBase

    public init(protobufExtension: MessageExtensionBase) {
        self.protobufExtension = protobufExtension
    }

    public var hashValue: Int {
        get {
            var hash = i_2166136261
            for e in value {
                hash = (hash &* i_16777619) ^ e.hashValue
            }
            return hash
        }
    }

    public func isEqual(other: AnyExtensionField) -> Bool {
        let o = other as! RepeatedMessageExtensionField<M>
        return self == o
    }

    public var debugDescription: String {
        return "[" + value.map{String(reflecting: $0)}.joined(separator: ",") + "]"
    }

    public mutating func decodeField(setter: inout FieldDecoder) throws {
        try setter.decodeRepeatedMessageField(fieldType: M.self, value: &value)
    }

    public func traverse(visitor: inout Visitor) throws {
        if value.count > 0 {
            try visitor.visitRepeatedMessageField(value: value, protoFieldNumber: protobufExtension.protoFieldNumber, protoFieldName: protobufExtension.protoFieldName, jsonFieldName: protobufExtension.jsonFieldName, swiftFieldName: protobufExtension.swiftFieldName)
        }
    }
}

public func ==<M: Message & Equatable>(lhs: RepeatedMessageExtensionField<M>, rhs: RepeatedMessageExtensionField<M>) -> Bool {
    return lhs.value == rhs.value
}

//
// ======== Groups within Messages ========
//
// Protoc internally treats groups the same as messages, but
// they serialize very differently, so we have separate serialization
// handling here...
public struct OptionalGroupExtensionField<G: Message & Hashable>: ExtensionField {
    public typealias BaseType = G
    public typealias ValueType = BaseType?
    public var value: G?
    private var protobufExtension: MessageExtensionBase

    public init(protobufExtension: MessageExtensionBase) {
        self.protobufExtension = protobufExtension
    }

    public var hashValue: Int {return value?.hashValue ?? 0}

    public var debugDescription: String { get {return value?.debugDescription ?? ""} }

    public func isEqual(other: AnyExtensionField) -> Bool {
        let o = other as! OptionalGroupExtensionField<G>
        return self == o
    }

    public mutating func decodeField(setter: inout FieldDecoder) throws {
        try setter.decodeSingularGroupField(fieldType: G.self, value: &value)
    }

    public func traverse(visitor: inout Visitor) throws {
        if let v = value {
            try visitor.visitSingularGroupField(value: v, protoFieldNumber: protobufExtension.protoFieldNumber, protoFieldName: protobufExtension.protoFieldName, jsonFieldName: protobufExtension.jsonFieldName, swiftFieldName: protobufExtension.swiftFieldName)
        }
    }
}

public func==<M: Message & Equatable>(lhs:OptionalGroupExtensionField<M>, rhs:OptionalGroupExtensionField<M>) -> Bool {
    if let l = lhs.value {
        if let r = rhs.value {
            return l == r
        }
        return false
    } else if let _ = rhs.value {
        return false
    }
    return true // Both nil
}


public struct RepeatedGroupExtensionField<G: Message & Hashable>: ExtensionField {
    public typealias BaseType = G
    public typealias ValueType = [BaseType]
    public var value = [G]()
    private var protobufExtension: MessageExtensionBase

    public init(protobufExtension: MessageExtensionBase) {
        self.protobufExtension = protobufExtension
    }

    public var hashValue: Int {
        get {
            var hash = i_2166136261
            for e in value {
                hash = (hash &* i_16777619) ^ e.hashValue
            }
            return hash
        }
    }

    public var debugDescription: String {return "[" + value.map{$0.debugDescription}.joined(separator: ",") + "]"}

    public func isEqual(other: AnyExtensionField) -> Bool {
        let o = other as! RepeatedGroupExtensionField<G>
        return self == o
    }

    public mutating func decodeField(setter: inout FieldDecoder) throws {
        try setter.decodeRepeatedGroupField(fieldType: G.self, value: &value)
    }

    public func traverse(visitor: inout Visitor) throws {
        if value.count > 0 {
            try visitor.visitRepeatedGroupField(value: value, protoFieldNumber: protobufExtension.protoFieldNumber, protoFieldName: protobufExtension.protoFieldName, jsonFieldName: protobufExtension.jsonFieldName, swiftFieldName: protobufExtension.swiftFieldName)
        }
    }
}

public func ==<G: Message & Equatable>(lhs: RepeatedGroupExtensionField<G>, rhs: RepeatedGroupExtensionField<G>) -> Bool {
    return lhs.value == rhs.value
}
