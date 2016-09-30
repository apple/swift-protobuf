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
// All extension field implementations build on this basic protocol.
// Note that it has no "self or associated type" references, so can
// be used as a protocol type.
//
// This also provides type-sealed serialization methods that use the
// contained value.
//
public protocol ProtobufExtensionField: CustomDebugStringConvertible {
    init(protobufExtension: ProtobufMessageExtension)
    var hashValue: Int { get }
    func isEqual(other: ProtobufExtensionField) -> Bool

    /// General field decoding
    mutating func decodeField(setter: inout ProtobufFieldDecoder) throws -> Bool

    /// Fields know their own type, so can dispatch to a visitor
    func traverse(visitor: inout ProtobufVisitor) throws
}

// Backwards compatibility; Remove in August 2016
public typealias ProtobufExtensionFieldType = ProtobufExtensionField

///
/// A "typed" FieldType includes all the necessary generic information
/// needed to work with the contained value.
///
/// In particular, it can expose typed accessors and serialization methods
/// that can accept or return a typed value.
///
public protocol ProtobufTypedExtensionField: ProtobufExtensionField, Hashable {
    // Only used in Map to fetch the base type; we can eliminate this by
    // restoring BaseType here
    associatedtype ValueType
    var value: ValueType {get set}
}

///
/// Singular field
///
public struct ProtobufOptionalField<T: ProtobufTypeProperties>: ProtobufTypedExtensionField {
    public typealias BaseType = T.BaseType
    public typealias ValueType = BaseType?
    public var value: ValueType
    public var protobufExtension: ProtobufMessageExtension

    public init(protobufExtension: ProtobufMessageExtension) {
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
        get {
            if let value = value {
                return T.hash(value: value)
            }
            return 0
        }
    }

    public func isEqual(other: ProtobufExtensionField) -> Bool {
        let o = other as! ProtobufOptionalField<T>
        return self == o
    }

    public mutating func decodeField(setter: inout ProtobufFieldDecoder) throws -> Bool {
        return try setter.decodeOptionalField(fieldType: T.self, value: &value)
    }

    public func traverse(visitor: inout ProtobufVisitor) throws {
        if let v = value {
            try visitor.visitSingularField(fieldType: T.self, value: v, protoFieldNumber: protobufExtension.protoFieldNumber, protoFieldName: protobufExtension.protoFieldName, jsonFieldName: protobufExtension.jsonFieldName, swiftFieldName: protobufExtension.swiftFieldName)
        }
    }

}

public func ==<T: ProtobufTypeProperties>(lhs: ProtobufOptionalField<T>, rhs: ProtobufOptionalField<T>) -> Bool {
    if let l = lhs.value {
        if let r = rhs.value {
            return T.isEqual(l, r)
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
public struct ProtobufRepeatedField<T: ProtobufTypeProperties>: ProtobufTypedExtensionField {
    public typealias BaseType = T.BaseType
    public typealias ValueType = [BaseType]
    public var value = ValueType()
    public var protobufExtension: ProtobufMessageExtension

    public init(protobufExtension: ProtobufMessageExtension) {
        self.protobufExtension = protobufExtension
    }

    public var hashValue: Int {
        get {
            var hash = i_2166136261
            for e in value {
                hash = (hash &* i_16777619) ^ T.hash(value: e)
            }
            return hash
        }
    }

    public func isEqual(other: ProtobufExtensionField) -> Bool {
        let o = other as! ProtobufRepeatedField<T>
        return self == o
    }

    public var debugDescription: String {
        return "[" + value.map{String(reflecting: $0)}.joined(separator: ",") + "]"
    }

    public mutating func decodeField(setter: inout ProtobufFieldDecoder) throws -> Bool {
        return try setter.decodeRepeatedField(fieldType: T.self, value: &value)
    }

    public func traverse(visitor: inout ProtobufVisitor) throws {
        if value.count > 0 {
            try visitor.visitRepeatedField(fieldType: T.self, value: value, protoFieldNumber: protobufExtension.protoFieldNumber, protoFieldName: protobufExtension.protoFieldName, jsonFieldName: protobufExtension.jsonFieldName, swiftFieldName: protobufExtension.swiftFieldName)
        }
    }
}

public func ==<T: ProtobufTypeProperties>(lhs: ProtobufRepeatedField<T>, rhs: ProtobufRepeatedField<T>) -> Bool {
    if lhs.value.count != rhs.value.count {
        return false
    }
    for (l, r) in zip(lhs.value, rhs.value) {
        if !T.isEqual(l, r) {
            return false
        }
    }
    return true
}

///
/// Packed Repeated fields
///
/// TODO: This is almost (but not quite) identical to ProtobufRepeatedFields;
/// find a way to collapse the implementations.
///
public struct ProtobufPackedField<T: ProtobufTypeProperties>: ProtobufTypedExtensionField {

    public typealias BaseType = T.BaseType
    public typealias ValueType = [BaseType]
    public var value = ValueType()
    public var protobufExtension: ProtobufMessageExtension

    public init(protobufExtension: ProtobufMessageExtension) {
        self.protobufExtension = protobufExtension
    }

    public var hashValue: Int {
        get {
            var hash = i_2166136261
            for e in value {
                hash = (hash &* i_16777619) ^ T.hash(value: e)
            }
            return hash
        }
    }

    public func isEqual(other: ProtobufExtensionField) -> Bool {
        let o = other as! ProtobufPackedField<T>
        return self == o
    }

    public var debugDescription: String {
        return "[" + value.map{String(reflecting: $0)}.joined(separator: ",") + "]"
    }

    public mutating func decodeField(setter: inout ProtobufFieldDecoder) throws -> Bool {
        return try setter.decodePackedField(fieldType: T.self, value: &value)
    }

    public func traverse(visitor: inout ProtobufVisitor) throws {
        if value.count > 0 {
            try visitor.visitPackedField(fieldType: T.self, value: value, protoFieldNumber: protobufExtension.protoFieldNumber, protoFieldName: protobufExtension.protoFieldName, jsonFieldName: protobufExtension.jsonFieldName, swiftFieldName: protobufExtension.swiftFieldName)
        }
    }
}

public func ==<T: ProtobufTypeProperties>(lhs: ProtobufPackedField<T>, rhs: ProtobufPackedField<T>) -> Bool {
    if lhs.value.count != rhs.value.count {
        return false
    }
    for (l, r) in zip(lhs.value, rhs.value) {
        if !T.isEqual(l, r) {
            return false
        }
    }
    return true
}

//
// ========== Message ==========
//
public struct ProtobufOptionalMessageField<M: ProtobufAbstractMessage>: ProtobufTypedExtensionField {
    public typealias BaseType = M
    public typealias ValueType = BaseType?
    public var value: ValueType
    public var protobufExtension: ProtobufMessageExtension

    public init(protobufExtension: ProtobufMessageExtension) {
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

    public static func hash(value: BaseType) -> Int {return value.hashValue}

    public var hashValue: Int {return value?.hashValue ?? 0}

    public func isEqual(other: ProtobufExtensionField) -> Bool {
        let o = other as! ProtobufOptionalMessageField<M>
        return self == o
    }

    public mutating func decodeField(setter: inout ProtobufFieldDecoder) throws -> Bool {
        return try setter.decodeOptionalMessageField(fieldType: M.self, value: &value)
    }

    public func traverse(visitor: inout ProtobufVisitor) throws {
        if let v = value {
            try visitor.visitSingularMessageField(value: v, protoFieldNumber: protobufExtension.protoFieldNumber, protoFieldName: protobufExtension.protoFieldName, jsonFieldName: protobufExtension.jsonFieldName, swiftFieldName: protobufExtension.swiftFieldName)
        }
    }
}

public func ==<M: ProtobufAbstractMessage>(lhs: ProtobufOptionalMessageField<M>, rhs: ProtobufOptionalMessageField<M>) -> Bool {
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

public struct ProtobufRepeatedMessageField<M: ProtobufAbstractMessage>: ProtobufTypedExtensionField {
    public typealias BaseType = M
    public typealias ValueType = [BaseType]
    public var value = ValueType()
    public var protobufExtension: ProtobufMessageExtension

    public init(protobufExtension: ProtobufMessageExtension) {
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

    public func isEqual(other: ProtobufExtensionField) -> Bool {
        let o = other as! ProtobufRepeatedMessageField<M>
        return self == o
    }

    public var debugDescription: String {
        return "[" + value.map{String(reflecting: $0)}.joined(separator: ",") + "]"
    }

    public mutating func decodeField(setter: inout ProtobufFieldDecoder) throws -> Bool {
        return try setter.decodeRepeatedMessageField(fieldType: M.self, value: &value)
    }

    public func traverse(visitor: inout ProtobufVisitor) throws {
        if value.count > 0 {
            try visitor.visitRepeatedMessageField(value: value, protoFieldNumber: protobufExtension.protoFieldNumber, protoFieldName: protobufExtension.protoFieldName, jsonFieldName: protobufExtension.jsonFieldName, swiftFieldName: protobufExtension.swiftFieldName)
        }
    }
}

public func ==<M: ProtobufAbstractMessage>(lhs: ProtobufRepeatedMessageField<M>, rhs: ProtobufRepeatedMessageField<M>) -> Bool {
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
// ======== Groups within Messages ========
//
// Protoc internally treats groups the same as messages, but
// they serialize very differently, so we have separate serialization
// handling here...
public struct ProtobufOptionalGroupField<G: ProtobufGroup & Hashable>: ProtobufTypedExtensionField {
    public typealias BaseType = G
    public typealias ValueType = BaseType?
    public var value: G?
    public var protobufExtension: ProtobufMessageExtension

    public init(protobufExtension: ProtobufMessageExtension) {
        self.protobufExtension = protobufExtension
    }

    public var hashValue: Int {return value?.hashValue ?? 0}

    public var debugDescription: String { get {return value?.debugDescription ?? ""} }

    public func isEqual(other: ProtobufExtensionField) -> Bool {
        let o = other as! ProtobufOptionalGroupField<G>
        return self == o
    }

    public mutating func decodeField(setter: inout ProtobufFieldDecoder) throws -> Bool {
        return try setter.decodeOptionalGroupField(fieldType: G.self, value: &value)
    }

    public func traverse(visitor: inout ProtobufVisitor) throws {
        if let v = value {
            try visitor.visitSingularGroupField(value: v, protoFieldNumber: protobufExtension.protoFieldNumber, protoFieldName: protobufExtension.protoFieldName, jsonFieldName: protobufExtension.jsonFieldName, swiftFieldName: protobufExtension.swiftFieldName)
        }
    }
}

public func==<M: ProtobufGroup>(lhs:ProtobufOptionalGroupField<M>, rhs:ProtobufOptionalGroupField<M>) -> Bool {
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


public struct ProtobufRepeatedGroupField<G: ProtobufGroup & Hashable>: ProtobufTypedExtensionField {
    public typealias BaseType = G
    public typealias ValueType = [BaseType]
    public var value = [G]()
    public var protobufExtension: ProtobufMessageExtension

    public init(protobufExtension: ProtobufMessageExtension) {
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

    public func isEqual(other: ProtobufExtensionField) -> Bool {
        let o = other as! ProtobufRepeatedGroupField<G>
        return self == o
    }

    public mutating func decodeField(setter: inout ProtobufFieldDecoder) throws -> Bool {
        return try setter.decodeRepeatedGroupField(fieldType: G.self, value: &value)
    }

    public func traverse(visitor: inout ProtobufVisitor) throws {
        if value.count > 0 {
            try visitor.visitRepeatedGroupField(value: value, protoFieldNumber: protobufExtension.protoFieldNumber, protoFieldName: protobufExtension.protoFieldName, jsonFieldName: protobufExtension.jsonFieldName, swiftFieldName: protobufExtension.swiftFieldName)
        }
    }
}

public func ==<G: ProtobufGroup>(lhs: ProtobufRepeatedGroupField<G>, rhs: ProtobufRepeatedGroupField<G>) -> Bool {
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
