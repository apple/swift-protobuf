// Sources/SwiftProtobuf/ExtensionFields.swift - Extension support
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
//
// Core protocols implemented by generated extensions.
//
// -----------------------------------------------------------------------------

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
/// A type-erased extension field that can encode, decode, hash, and compare itself without
/// exposing the value it holds.
@preconcurrency
public protocol AnyExtensionField: Sendable, CustomDebugStringConvertible {
    func hash(into hasher: inout Hasher)
    var protobufExtension: any AnyMessageExtension { get }
    func isEqual(other: any AnyExtensionField) -> Bool

    /// Merging field decoding
    mutating func decodeExtensionField<T: Decoder>(decoder: inout T) throws

    /// Fields know their own type, so can dispatch to a visitor
    func traverse<V: Visitor>(visitor: inout V) throws

    /// Check if the field is initialized.
    var isInitialized: Bool { get }
}

extension AnyExtensionField {
    // Default implementation for extensions fields.  The message types below provide
    // custom versions.

    /// A Boolean value that indicates whether this extension field's required sub-fields are set.
    ///
    /// Always `true`, since scalar and enum extension field values have no nested required
    /// fields to check.
    public var isInitialized: Bool { true }
}

///
/// The regular ExtensionField type exposes the value directly.
///
@preconcurrency
public protocol ExtensionField: AnyExtensionField, Hashable {
    associatedtype ValueType
    var value: ValueType { get set }
    init(protobufExtension: any AnyMessageExtension, value: ValueType)
    init?<D: Decoder>(protobufExtension: any AnyMessageExtension, decoder: inout D) throws
}

/// The value of a singular scalar-typed extension field.
public struct OptionalExtensionField<T: FieldType>: ExtensionField {
    /// The type that represents a single value of this extension field.
    public typealias BaseType = T.BaseType

    /// The type of the value this extension field stores.
    public typealias ValueType = BaseType

    /// This extension field's current value.
    public var value: ValueType

    /// The descriptor for the extension this field's value belongs to.
    public var protobufExtension: any AnyMessageExtension

    /// Returns a Boolean value that indicates whether two extension fields hold the same value.
    public static func == (
        lhs: OptionalExtensionField,
        rhs: OptionalExtensionField
    ) -> Bool {
        lhs.value == rhs.value
    }

    /// Creates an extension field for the extension and value you provide.
    public init(protobufExtension: any AnyMessageExtension, value: ValueType) {
        self.protobufExtension = protobufExtension
        self.value = value
    }

    /// A debug-build description of this field's value; outside of debug builds, a generic type
    /// description.
    public var debugDescription: String {
        #if DEBUG
        return String(reflecting: value)
        #else
        return String(reflecting: type(of: self))
        #endif
    }

    /// A hash based on this field's value, kept consistent with this type's equality.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(value)
    }

    /// Returns a Boolean value that indicates whether another extension field holds an equal
    /// value.
    ///
    /// The type-erased comparison requires that `other` be an `OptionalExtensionField<T>`;
    /// otherwise, it traps.
    public func isEqual(other: any AnyExtensionField) -> Bool {
        let o = other as! OptionalExtensionField<T>
        return self == o
    }

    /// Decodes a new value for this extension from the decoder you provide, replacing the current
    /// value if one is present.
    public mutating func decodeExtensionField<D: Decoder>(decoder: inout D) throws {
        var v: ValueType?
        try T.decodeSingular(value: &v, from: &decoder)
        if let v = v {
            value = v
        }
    }

    /// Creates a field by decoding a value from the decoder you provide, or returns `nil` if the
    /// decoder has none.
    public init?<D: Decoder>(protobufExtension: any AnyMessageExtension, decoder: inout D) throws {
        var v: ValueType?
        try T.decodeSingular(value: &v, from: &decoder)
        if let v = v {
            self.init(protobufExtension: protobufExtension, value: v)
        } else {
            return nil
        }
    }

    /// Visits this field's value with the visitor you provide.
    public func traverse<V: Visitor>(visitor: inout V) throws {
        try T.visitSingular(value: value, fieldNumber: protobufExtension.fieldNumber, with: &visitor)
    }
}

/// The values of a repeated scalar-typed extension field.
public struct RepeatedExtensionField<T: FieldType>: ExtensionField {
    /// The type that represents a single value of this extension field.
    public typealias BaseType = T.BaseType

    /// The array type that stores this extension field's values.
    public typealias ValueType = [BaseType]

    /// This extension field's current values.
    public var value: ValueType

    /// The descriptor for the extension this field's values belong to.
    public var protobufExtension: any AnyMessageExtension

    /// Returns a Boolean value that indicates whether two extension fields hold the same values.
    public static func == (
        lhs: RepeatedExtensionField,
        rhs: RepeatedExtensionField
    ) -> Bool {
        lhs.value == rhs.value
    }

    /// Creates an extension field for the extension and values you provide.
    public init(protobufExtension: any AnyMessageExtension, value: ValueType) {
        self.protobufExtension = protobufExtension
        self.value = value
    }

    /// A debug-build description of this field's values; outside of debug builds, a generic type
    /// description.
    public var debugDescription: String {
        #if DEBUG
        return "[" + value.map { String(reflecting: $0) }.joined(separator: ",") + "]"
        #else
        return String(reflecting: type(of: self))
        #endif
    }

    /// A hash based on this field's values, kept consistent with this type's equality.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(value)
    }

    /// Returns a Boolean value that indicates whether another extension field holds equal values.
    ///
    /// The type-erased comparison requires that `other` be a `RepeatedExtensionField<T>`;
    /// otherwise, it traps.
    public func isEqual(other: any AnyExtensionField) -> Bool {
        let o = other as! RepeatedExtensionField<T>
        return self == o
    }

    /// Decodes additional values for this extension from the decoder you provide, appending them
    /// to the current values.
    public mutating func decodeExtensionField<D: Decoder>(decoder: inout D) throws {
        try T.decodeRepeated(value: &value, from: &decoder)
    }

    /// Creates a field by decoding its values from the decoder you provide.
    public init?<D: Decoder>(protobufExtension: any AnyMessageExtension, decoder: inout D) throws {
        var v: ValueType = []
        try T.decodeRepeated(value: &v, from: &decoder)
        self.init(protobufExtension: protobufExtension, value: v)
    }

    /// Visits this field's values with the visitor you provide, if there are any.
    public func traverse<V: Visitor>(visitor: inout V) throws {
        if value.count > 0 {
            try T.visitRepeated(value: value, fieldNumber: protobufExtension.fieldNumber, with: &visitor)
        }
    }
}

// TODO: This is almost (but not quite) identical to RepeatedFields;
// find a way to collapse the implementations.

/// The values of a packed repeated scalar-typed extension field.
public struct PackedExtensionField<T: FieldType>: ExtensionField {
    /// The type that represents a single value of this extension field.
    public typealias BaseType = T.BaseType

    /// The array type that stores this extension field's values.
    public typealias ValueType = [BaseType]

    /// This extension field's current values.
    public var value: ValueType

    /// The descriptor for the extension this field's values belong to.
    public var protobufExtension: any AnyMessageExtension

    /// Returns a Boolean value that indicates whether two extension fields hold the same values.
    public static func == (
        lhs: PackedExtensionField,
        rhs: PackedExtensionField
    ) -> Bool {
        lhs.value == rhs.value
    }

    /// Creates an extension field for the extension and values you provide.
    public init(protobufExtension: any AnyMessageExtension, value: ValueType) {
        self.protobufExtension = protobufExtension
        self.value = value
    }

    /// A debug-build description of this field's values; outside of debug builds, a generic type
    /// description.
    public var debugDescription: String {
        #if DEBUG
        return "[" + value.map { String(reflecting: $0) }.joined(separator: ",") + "]"
        #else
        return String(reflecting: type(of: self))
        #endif
    }

    /// A hash based on this field's values, kept consistent with this type's equality.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(value)
    }

    /// Returns a Boolean value that indicates whether another extension field holds equal values.
    ///
    /// The type-erased comparison requires that `other` be a `PackedExtensionField<T>`;
    /// otherwise, it traps.
    public func isEqual(other: any AnyExtensionField) -> Bool {
        let o = other as! PackedExtensionField<T>
        return self == o
    }

    /// Decodes additional values for this extension from the decoder you provide, appending them
    /// to the current values.
    public mutating func decodeExtensionField<D: Decoder>(decoder: inout D) throws {
        try T.decodeRepeated(value: &value, from: &decoder)
    }

    /// Creates a field by decoding its values from the decoder you provide.
    public init?<D: Decoder>(protobufExtension: any AnyMessageExtension, decoder: inout D) throws {
        var v: ValueType = []
        try T.decodeRepeated(value: &v, from: &decoder)
        self.init(protobufExtension: protobufExtension, value: v)
    }

    /// Visits this field's values with the visitor you provide, if there are any.
    public func traverse<V: Visitor>(visitor: inout V) throws {
        if value.count > 0 {
            try T.visitPacked(value: value, fieldNumber: protobufExtension.fieldNumber, with: &visitor)
        }
    }
}

/// The value of a singular enum-typed extension field.
public struct OptionalEnumExtensionField<E: Enum>: ExtensionField where E.RawValue == Int {
    /// The type that represents a single value of this extension field.
    public typealias BaseType = E

    /// The type of the value this extension field stores.
    public typealias ValueType = E

    /// This extension field's current value.
    public var value: ValueType

    /// The descriptor for the extension this field's value belongs to.
    public var protobufExtension: any AnyMessageExtension

    /// Returns a Boolean value that indicates whether two extension fields hold the same value.
    public static func == (
        lhs: OptionalEnumExtensionField,
        rhs: OptionalEnumExtensionField
    ) -> Bool {
        lhs.value == rhs.value
    }

    /// Creates an extension field for the extension and value you provide.
    public init(protobufExtension: any AnyMessageExtension, value: ValueType) {
        self.protobufExtension = protobufExtension
        self.value = value
    }

    /// A debug-build description of this field's value; outside of debug builds, a generic type
    /// description.
    public var debugDescription: String {
        #if DEBUG
        return String(reflecting: value)
        #else
        return String(reflecting: type(of: self))
        #endif
    }

    /// A hash based on this field's value, kept consistent with this type's equality.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(value)
    }

    /// Returns a Boolean value that indicates whether another extension field holds an equal
    /// value.
    ///
    /// The type-erased comparison requires that `other` be an `OptionalEnumExtensionField<E>`;
    /// otherwise, it traps.
    public func isEqual(other: any AnyExtensionField) -> Bool {
        let o = other as! OptionalEnumExtensionField<E>
        return self == o
    }

    /// Decodes a new value for this extension from the decoder you provide, replacing the current
    /// value if one is present.
    public mutating func decodeExtensionField<D: Decoder>(decoder: inout D) throws {
        var v: ValueType?
        try decoder.decodeSingularEnumField(value: &v)
        if let v = v {
            value = v
        }
    }

    /// Creates a field by decoding a value from the decoder you provide, or returns `nil` if the
    /// decoder has none.
    public init?<D: Decoder>(protobufExtension: any AnyMessageExtension, decoder: inout D) throws {
        var v: ValueType?
        try decoder.decodeSingularEnumField(value: &v)
        if let v = v {
            self.init(protobufExtension: protobufExtension, value: v)
        } else {
            return nil
        }
    }

    /// Visits this field's value with the visitor you provide.
    public func traverse<V: Visitor>(visitor: inout V) throws {
        try visitor.visitSingularEnumField(
            value: value,
            fieldNumber: protobufExtension.fieldNumber
        )
    }
}

/// The values of a repeated enum-typed extension field.
public struct RepeatedEnumExtensionField<E: Enum>: ExtensionField where E.RawValue == Int {
    /// The type that represents a single value of this extension field.
    public typealias BaseType = E

    /// The array type that stores this extension field's values.
    public typealias ValueType = [E]

    /// This extension field's current values.
    public var value: ValueType

    /// The descriptor for the extension this field's values belong to.
    public var protobufExtension: any AnyMessageExtension

    /// Returns a Boolean value that indicates whether two extension fields hold the same values.
    public static func == (
        lhs: RepeatedEnumExtensionField,
        rhs: RepeatedEnumExtensionField
    ) -> Bool {
        lhs.value == rhs.value
    }

    /// Creates an extension field for the extension and values you provide.
    public init(protobufExtension: any AnyMessageExtension, value: ValueType) {
        self.protobufExtension = protobufExtension
        self.value = value
    }

    /// A debug-build description of this field's values; outside of debug builds, a generic type
    /// description.
    public var debugDescription: String {
        #if DEBUG
        return "[" + value.map { String(reflecting: $0) }.joined(separator: ",") + "]"
        #else
        return String(reflecting: type(of: self))
        #endif
    }

    /// A hash based on this field's values, kept consistent with this type's equality.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(value)
    }

    /// Returns a Boolean value that indicates whether another extension field holds equal values.
    ///
    /// The type-erased comparison requires that `other` be a `RepeatedEnumExtensionField<E>`;
    /// otherwise, it traps.
    public func isEqual(other: any AnyExtensionField) -> Bool {
        let o = other as! RepeatedEnumExtensionField<E>
        return self == o
    }

    /// Decodes additional values for this extension from the decoder you provide, appending them
    /// to the current values.
    public mutating func decodeExtensionField<D: Decoder>(decoder: inout D) throws {
        try decoder.decodeRepeatedEnumField(value: &value)
    }

    /// Creates a field by decoding its values from the decoder you provide.
    public init?<D: Decoder>(protobufExtension: any AnyMessageExtension, decoder: inout D) throws {
        var v: ValueType = []
        try decoder.decodeRepeatedEnumField(value: &v)
        self.init(protobufExtension: protobufExtension, value: v)
    }

    /// Visits this field's values with the visitor you provide, if there are any.
    public func traverse<V: Visitor>(visitor: inout V) throws {
        if value.count > 0 {
            try visitor.visitRepeatedEnumField(
                value: value,
                fieldNumber: protobufExtension.fieldNumber
            )
        }
    }
}

// TODO: This is almost (but not quite) identical to RepeatedEnumFields;
// find a way to collapse the implementations.

/// The values of a packed repeated enum-typed extension field.
public struct PackedEnumExtensionField<E: Enum>: ExtensionField where E.RawValue == Int {
    /// The type that represents a single value of this extension field.
    public typealias BaseType = E

    /// The array type that stores this extension field's values.
    public typealias ValueType = [E]

    /// This extension field's current values.
    public var value: ValueType

    /// The descriptor for the extension this field's values belong to.
    public var protobufExtension: any AnyMessageExtension

    /// Returns a Boolean value that indicates whether two extension fields hold the same values.
    public static func == (
        lhs: PackedEnumExtensionField,
        rhs: PackedEnumExtensionField
    ) -> Bool {
        lhs.value == rhs.value
    }

    /// Creates an extension field for the extension and values you provide.
    public init(protobufExtension: any AnyMessageExtension, value: ValueType) {
        self.protobufExtension = protobufExtension
        self.value = value
    }

    /// A debug-build description of this field's values; outside of debug builds, a generic type
    /// description.
    public var debugDescription: String {
        #if DEBUG
        return "[" + value.map { String(reflecting: $0) }.joined(separator: ",") + "]"
        #else
        return String(reflecting: type(of: self))
        #endif
    }

    /// A hash based on this field's values, kept consistent with this type's equality.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(value)
    }

    /// Returns a Boolean value that indicates whether another extension field holds equal values.
    ///
    /// The type-erased comparison requires that `other` be a `PackedEnumExtensionField<E>`;
    /// otherwise, it traps.
    public func isEqual(other: any AnyExtensionField) -> Bool {
        let o = other as! PackedEnumExtensionField<E>
        return self == o
    }

    /// Decodes additional values for this extension from the decoder you provide, appending them
    /// to the current values.
    public mutating func decodeExtensionField<D: Decoder>(decoder: inout D) throws {
        try decoder.decodeRepeatedEnumField(value: &value)
    }

    /// Creates a field by decoding its values from the decoder you provide.
    public init?<D: Decoder>(protobufExtension: any AnyMessageExtension, decoder: inout D) throws {
        var v: ValueType = []
        try decoder.decodeRepeatedEnumField(value: &v)
        self.init(protobufExtension: protobufExtension, value: v)
    }

    /// Visits this field's values with the visitor you provide, if there are any.
    public func traverse<V: Visitor>(visitor: inout V) throws {
        if value.count > 0 {
            try visitor.visitPackedEnumField(
                value: value,
                fieldNumber: protobufExtension.fieldNumber
            )
        }
    }
}

/// The value of a singular message-typed extension field.
public struct OptionalMessageExtensionField<M: Message & Equatable>:
    ExtensionField
{
    /// The type that represents a single value of this extension field.
    public typealias BaseType = M

    /// The type of the value this extension field stores.
    public typealias ValueType = BaseType

    /// This extension field's current value.
    public var value: ValueType

    /// The descriptor for the extension this field's value belongs to.
    public var protobufExtension: any AnyMessageExtension

    /// Returns a Boolean value that indicates whether two extension fields hold the same value.
    public static func == (
        lhs: OptionalMessageExtensionField,
        rhs: OptionalMessageExtensionField
    ) -> Bool {
        lhs.value == rhs.value
    }

    /// Creates an extension field for the extension and value you provide.
    public init(protobufExtension: any AnyMessageExtension, value: ValueType) {
        self.protobufExtension = protobufExtension
        self.value = value
    }

    /// A debug-build description of this field's value; outside of debug builds, a generic type
    /// description.
    public var debugDescription: String {
        #if DEBUG
        return String(reflecting: value)
        #else
        return String(reflecting: type(of: self))
        #endif
    }

    /// A hash based on this field's value, kept consistent with this type's equality.
    public func hash(into hasher: inout Hasher) {
        value.hash(into: &hasher)
    }

    /// Returns a Boolean value that indicates whether another extension field holds an equal
    /// value.
    ///
    /// The type-erased comparison requires that `other` be an `OptionalMessageExtensionField<M>`;
    /// otherwise, it traps.
    public func isEqual(other: any AnyExtensionField) -> Bool {
        let o = other as! OptionalMessageExtensionField<M>
        return self == o
    }

    /// Merges a newly decoded message into the current value, replacing or combining fields
    /// according to the decoder you provide.
    public mutating func decodeExtensionField<D: Decoder>(decoder: inout D) throws {
        var v: ValueType? = value
        try decoder.decodeSingularMessageField(value: &v)
        if let v = v {
            self.value = v
        }
    }

    /// Creates a field by decoding a value from the decoder you provide, or returns `nil` if the
    /// decoder has none.
    public init?<D: Decoder>(protobufExtension: any AnyMessageExtension, decoder: inout D) throws {
        var v: ValueType?
        try decoder.decodeSingularMessageField(value: &v)
        if let v = v {
            self.init(protobufExtension: protobufExtension, value: v)
        } else {
            return nil
        }
    }

    /// Visits this field's value with the visitor you provide.
    public func traverse<V: Visitor>(visitor: inout V) throws {
        try visitor.visitSingularMessageField(
            value: value,
            fieldNumber: protobufExtension.fieldNumber
        )
    }

    /// A Boolean value that indicates whether this field's required sub-fields are set.
    ///
    /// This delegates to the message value's own `isInitialized`.
    public var isInitialized: Bool {
        value.isInitialized
    }
}

/// The values of a repeated message-typed extension field.
public struct RepeatedMessageExtensionField<M: Message & Equatable>:
    ExtensionField
{
    /// The type that represents a single value of this extension field.
    public typealias BaseType = M

    /// The array type that stores this extension field's values.
    public typealias ValueType = [BaseType]

    /// This extension field's current values.
    public var value: ValueType

    /// The descriptor for the extension this field's values belong to.
    public var protobufExtension: any AnyMessageExtension

    /// Returns a Boolean value that indicates whether two extension fields hold the same values.
    public static func == (
        lhs: RepeatedMessageExtensionField,
        rhs: RepeatedMessageExtensionField
    ) -> Bool {
        lhs.value == rhs.value
    }

    /// Creates an extension field for the extension and values you provide.
    public init(protobufExtension: any AnyMessageExtension, value: ValueType) {
        self.protobufExtension = protobufExtension
        self.value = value
    }

    /// A debug-build description of this field's values; outside of debug builds, a generic type
    /// description.
    public var debugDescription: String {
        #if DEBUG
        return "[" + value.map { String(reflecting: $0) }.joined(separator: ",") + "]"
        #else
        return String(reflecting: type(of: self))
        #endif
    }

    /// A hash based on this field's values, kept consistent with this type's equality.
    public func hash(into hasher: inout Hasher) {
        for e in value {
            e.hash(into: &hasher)
        }
    }

    /// Returns a Boolean value that indicates whether another extension field holds equal values.
    ///
    /// The type-erased comparison requires that `other` be a `RepeatedMessageExtensionField<M>`;
    /// otherwise, it traps.
    public func isEqual(other: any AnyExtensionField) -> Bool {
        let o = other as! RepeatedMessageExtensionField<M>
        return self == o
    }

    /// Decodes additional messages for this extension from the decoder you provide, appending them
    /// to the current values.
    public mutating func decodeExtensionField<D: Decoder>(decoder: inout D) throws {
        try decoder.decodeRepeatedMessageField(value: &value)
    }

    /// Creates a field by decoding its values from the decoder you provide.
    public init?<D: Decoder>(protobufExtension: any AnyMessageExtension, decoder: inout D) throws {
        var v: ValueType = []
        try decoder.decodeRepeatedMessageField(value: &v)
        self.init(protobufExtension: protobufExtension, value: v)
    }

    /// Visits this field's values with the visitor you provide, if there are any.
    public func traverse<V: Visitor>(visitor: inout V) throws {
        if value.count > 0 {
            try visitor.visitRepeatedMessageField(
                value: value,
                fieldNumber: protobufExtension.fieldNumber
            )
        }
    }

    /// A Boolean value that indicates whether this field's required sub-fields are set.
    ///
    /// This checks every message in the array.
    public var isInitialized: Bool {
        Internal.areAllInitialized(value)
    }
}

// Protoc internally treats groups the same as messages, but
// they serialize very differently, so we have separate serialization
// handling here...
/// The value of a singular group-typed extension field.
public struct OptionalGroupExtensionField<G: Message & Hashable>:
    ExtensionField
{
    /// The type that represents a single value of this extension field.
    public typealias BaseType = G

    /// The type of the value this extension field stores.
    public typealias ValueType = BaseType

    /// This extension field's current value.
    public var value: G

    /// The descriptor for the extension this field's value belongs to.
    public var protobufExtension: any AnyMessageExtension

    /// Returns a Boolean value that indicates whether two extension fields hold the same value.
    public static func == (
        lhs: OptionalGroupExtensionField,
        rhs: OptionalGroupExtensionField
    ) -> Bool {
        lhs.value == rhs.value
    }

    /// Creates an extension field for the extension and value you provide.
    public init(protobufExtension: any AnyMessageExtension, value: ValueType) {
        self.protobufExtension = protobufExtension
        self.value = value
    }

    /// A debug-build description of this field's value; outside of debug builds, a generic type
    /// description.
    public var debugDescription: String {
        #if DEBUG
        return value.debugDescription
        #else
        return String(reflecting: type(of: self))
        #endif
    }

    /// A hash based on this field's value, kept consistent with this type's equality.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(value)
    }

    /// Returns a Boolean value that indicates whether another extension field holds an equal
    /// value.
    ///
    /// The type-erased comparison requires that `other` be an `OptionalGroupExtensionField<G>`;
    /// otherwise, it traps.
    public func isEqual(other: any AnyExtensionField) -> Bool {
        let o = other as! OptionalGroupExtensionField<G>
        return self == o
    }

    /// Merges a newly decoded group into the current value, replacing or combining fields
    /// according to the decoder you provide.
    public mutating func decodeExtensionField<D: Decoder>(decoder: inout D) throws {
        var v: ValueType? = value
        try decoder.decodeSingularGroupField(value: &v)
        if let v = v {
            value = v
        }
    }

    /// Creates a field by decoding a value from the decoder you provide, or returns `nil` if the
    /// decoder has none.
    public init?<D: Decoder>(protobufExtension: any AnyMessageExtension, decoder: inout D) throws {
        var v: ValueType?
        try decoder.decodeSingularGroupField(value: &v)
        if let v = v {
            self.init(protobufExtension: protobufExtension, value: v)
        } else {
            return nil
        }
    }

    /// Visits this field's value with the visitor you provide.
    public func traverse<V: Visitor>(visitor: inout V) throws {
        try visitor.visitSingularGroupField(
            value: value,
            fieldNumber: protobufExtension.fieldNumber
        )
    }

    /// A Boolean value that indicates whether this field's required sub-fields are set.
    ///
    /// This delegates to the group value's own `isInitialized`.
    public var isInitialized: Bool {
        value.isInitialized
    }
}

/// The values of a repeated group-typed extension field.
public struct RepeatedGroupExtensionField<G: Message & Hashable>:
    ExtensionField
{
    /// The type that represents a single value of this extension field.
    public typealias BaseType = G

    /// The array type that stores this extension field's values.
    public typealias ValueType = [BaseType]

    /// This extension field's current values.
    public var value: ValueType

    /// The descriptor for the extension this field's values belong to.
    public var protobufExtension: any AnyMessageExtension

    /// Returns a Boolean value that indicates whether two extension fields hold the same values.
    public static func == (
        lhs: RepeatedGroupExtensionField,
        rhs: RepeatedGroupExtensionField
    ) -> Bool {
        lhs.value == rhs.value
    }

    /// Creates an extension field for the extension and values you provide.
    public init(protobufExtension: any AnyMessageExtension, value: ValueType) {
        self.protobufExtension = protobufExtension
        self.value = value
    }

    /// A debug-build description of this field's values; outside of debug builds, a generic type
    /// description.
    public var debugDescription: String {
        #if DEBUG
        return "[" + value.map { $0.debugDescription }.joined(separator: ",") + "]"
        #else
        return String(reflecting: type(of: self))
        #endif
    }

    /// A hash based on this field's values, kept consistent with this type's equality.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(value)
    }

    /// Returns a Boolean value that indicates whether another extension field holds equal values.
    ///
    /// The type-erased comparison requires that `other` be a `RepeatedGroupExtensionField<G>`;
    /// otherwise, it traps.
    public func isEqual(other: any AnyExtensionField) -> Bool {
        let o = other as! RepeatedGroupExtensionField<G>
        return self == o
    }

    /// Decodes additional groups for this extension from the decoder you provide, appending them
    /// to the current values.
    public mutating func decodeExtensionField<D: Decoder>(decoder: inout D) throws {
        try decoder.decodeRepeatedGroupField(value: &value)
    }

    /// Creates a field by decoding its values from the decoder you provide.
    public init?<D: Decoder>(protobufExtension: any AnyMessageExtension, decoder: inout D) throws {
        var v: ValueType = []
        try decoder.decodeRepeatedGroupField(value: &v)
        self.init(protobufExtension: protobufExtension, value: v)
    }

    /// Visits this field's values with the visitor you provide, if there are any.
    public func traverse<V: Visitor>(visitor: inout V) throws {
        if value.count > 0 {
            try visitor.visitRepeatedGroupField(
                value: value,
                fieldNumber: protobufExtension.fieldNumber
            )
        }
    }

    /// A Boolean value that indicates whether this field's required sub-fields are set.
    ///
    /// This checks every group in the array.
    public var isInitialized: Bool {
        Internal.areAllInitialized(value)
    }
}
