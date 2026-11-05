// Sources/SwiftProtobuf/ExtensionSchema.swift - Extension support
//
// Copyright (c) 2014 - 2026 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Describes the schema of a particular extension field.
///
// -----------------------------------------------------------------------------

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Describes a single extension field with enough detail for it to be modified in memory and to be
/// serialized and parsed.
public class ExtensionSchema: @unchecked Sendable {
    // Using `UnsafeRawBufferPointer` requires that we declare the `Sendable` conformance as
    // `@unchecked`. Clearly this is safe because the pointer obtained from a `StaticString` is an
    // immortal compile-time constant and we only read from it, and because the resolver functions
    // do not capture mutable state.

    /// The encoded schema of the extension field.
    ///
    /// ## Encoded Schema
    ///
    /// Like the message schema, the extension schema is encoded in UTF-8-compatible form as a
    /// `StaticString`:
    ///
    /// ```
    /// +---------+--------------+----------------------------+
    /// | Bytes 0 | Bytes 1-13   | Bytes 14-variable          |
    /// | Version | Field schema | Length-prefixed field name |
    /// +---------+--------------+----------------------------+
    /// ```
    ///
    /// *   Byte 0: A `UInt8` that describes the version of the schema. Currently, this is always 0.
    ///     This value allows for future enhancements to be made to the schema but preserving backward
    ///     compatibility. **Important:** This must always match the version number of the message
    ///     schema used by the same generation.
    /// *   Bytes 1-13: The schema of the extension field. This is identical to the schema defined by
    ///     `MessageSchema.Field` for the message schema with the same version number.
    /// *   Bytes 14-variable: A 7-bit-encoded 2-byte integer indicating the length of the extension's
    ///     name followed by the UTF-8 blob that contains the name of the extension field.
    ///
    /// Note that even though extension fields use the same schema as regular fields, not all of the
    /// values are actually used. For example, presence is tracked differently and the byte offsets are
    /// always zero because extension fields are stored differently in memory that regular fields. This
    /// means that the schema string is slightly larger than it needs to be, but it is a worthwhile
    /// trade-off to let us reuse the same field schema code in the runtime and in the generator.
    private let schema: UnsafeRawBufferPointer

    @_spi(ForGeneratedCodeOnly)
    public typealias ExtendedMessageResolver = () -> MessageSchema

    @_spi(ForGeneratedCodeOnly)
    public typealias SubmessageOrEnumResolver = () -> SubmessageOrEnumSchema?

    /// The function that is invoked to retrieve the schema of the message that this
    /// extension field extends.
    let extendedMessageResolver: ExtendedMessageResolver

    /// The function that is invoked to retrieve the schema for a submessage or enum field.
    let submessageOrEnumResolver: SubmessageOrEnumResolver

    /// Creates a new extension schema for an extension field that is not a message or enum field.
    @_spi(ForGeneratedCodeOnly)
    public convenience init(schema: StaticString, extendedMessageResolver: @escaping ExtendedMessageResolver) {
        self.init(
            schema: schema,
            extendedMessageResolver: extendedMessageResolver,
            submessageOrEnumResolver: {
                preconditionFailure("submessageOrEnumResolver called on non-message/group extension field")
            }
        )
    }

    /// Creates a new extension schema and submessage operations from the given values.
    @_spi(ForGeneratedCodeOnly)
    public init(
        schema: StaticString,
        extendedMessageResolver: @escaping ExtendedMessageResolver,
        submessageOrEnumResolver: @escaping SubmessageOrEnumResolver
    ) {
        precondition(
            schema.hasPointerRepresentation,
            "The schema string should have a pointer-based representation; this is a generator bug"
        )
        self.schema = UnsafeRawBufferPointer(start: schema.utf8Start, count: schema.utf8CodeUnitCount)
        self.extendedMessageResolver = extendedMessageResolver
        self.submessageOrEnumResolver = submessageOrEnumResolver
    }
}

/// The size, in bytes, of the header the describes the overall extension schema.
private var extensionSchemaHeaderSize: Int { 1 }

extension ExtensionSchema {
    /// The `MessageSchema` of the message that this extension field extends.
    package var extendedMessage: MessageSchema { extendedMessageResolver() }

    /// The version of the schema data.
    ///
    /// Currently, the runtime only supports version 0. If the schema needs to change in a breaking
    /// way, the generator should increment the version and the runtime implementation should detect
    /// the new version while maintaining the ability to read the older schemas.
    private var version: UInt8 {
        schema.load(fromByteOffset: 0, as: UInt8.self)
    }

    /// The schema of the extension field.
    @usableFromInline var field: MessageSchema.Field {
        MessageSchema.Field(slice: schema[1..<(1 + fieldSchemaSize)])
    }

    /// The field number of the extension field.
    public var fieldNumber: Int {
        Int(field.fieldNumber)
    }

    /// The name of the extension field.
    public var fieldName: String {
        String(protobufUTF8Name: utf8FieldName)
    }

    /// The UTF-8 name of the extension field.
    var utf8FieldName: UTF8Name {
        let lengthOffset = 1 + fieldSchemaSize
        let length = fixed2ByteBase128(in: schema, atByteOffset: lengthOffset)
        let nameStart = lengthOffset + 2
        return UTF8Name(start: schema.baseAddress! + nameStart, count: length)
    }

    /// The message schema for this extension field, if it is a message or group.
    ///
    /// - Precondition: The extension field must be a message or group field.
    @usableFromInline
    var messageSchema: MessageSchema {
        switch submessageOrEnumResolver() {
        case nil:
            return SwiftProtobuf_ImplicitWeakMessage.messageSchema
        case .message(let messageSchema)?:
            return messageSchema
        case .enum?:
            fatalError("messageSchema called on non-message/group extension field")
        }
    }

    /// The enum schema for this extension field, if it is an enum.
    ///
    /// - Precondition: The extension field must be an enum field.
    @usableFromInline
    var enumSchema: EnumSchema {
        switch submessageOrEnumResolver() {
        case nil:
            return SwiftProtobuf_ImplicitWeakEnum.enumSchema
        case .enum(let enumSchema)?:
            return enumSchema
        case .message?:
            fatalError("enumSchema called on non-enum extension field")
        }
    }
}

#if !REMOVE_LEGACY_EXTENSION_APIS
/// Type-erased protocol for extension field descriptors, preserved for source compatibility.
@preconcurrency
public protocol AnyMessageExtension: Sendable {
    /// The protobuf field number of the extension field.
    var fieldNumber: Int { get }

    /// The protobuf field name of the extension field.
    var fieldName: String { get }
}

extension ExtensionSchema: AnyMessageExtension {}

/// Legacy alias for `Message`, preserved for source compatibility.
public typealias ExtensibleMessage = Message

/// Protocol describing a protobuf scalar field type for legacy extension declarations.
@preconcurrency
public protocol FieldType: Sendable {
    /// The Swift type used to store data for this field.
    associatedtype BaseType: Hashable, Sendable

    /// The default value for this field type before it has been set.
    static var proto3DefaultValue: BaseType { get }

    @_spi(ForGeneratedCodeOnly)
    static func _protobuf_getSingular(from storage: ExtensionStorage, ext: ExtensionSchema) -> BaseType?
    @_spi(ForGeneratedCodeOnly)
    static func _protobuf_setSingular(in storage: ExtensionStorage, ext: ExtensionSchema, value: BaseType)
}

extension FieldType where BaseType: BitwiseCopyable {
    @_spi(ForGeneratedCodeOnly)
    public static func _protobuf_getSingular(from storage: ExtensionStorage, ext: ExtensionSchema) -> BaseType? {
        storage.values[ext.field.fieldNumber]?.value(as: BaseType.self)
    }

    @_spi(ForGeneratedCodeOnly)
    public static func _protobuf_setSingular(in storage: ExtensionStorage, ext: ExtensionSchema, value: BaseType) {
        storage.updateValue(of: ext, to: value)
    }
}

/// Float traits
public struct ProtobufFloat: FieldType {
    public typealias BaseType = Float
    public static var proto3DefaultValue: Float { 0.0 }
}

/// Double traits
public struct ProtobufDouble: FieldType {
    public typealias BaseType = Double
    public static var proto3DefaultValue: Double { 0.0 }
}

/// Int32 traits
public struct ProtobufInt32: FieldType {
    public typealias BaseType = Int32
    public static var proto3DefaultValue: Int32 { 0 }
}

/// Int64 traits
public struct ProtobufInt64: FieldType {
    public typealias BaseType = Int64
    public static var proto3DefaultValue: Int64 { 0 }
}

/// UInt32 traits
public struct ProtobufUInt32: FieldType {
    public typealias BaseType = UInt32
    public static var proto3DefaultValue: UInt32 { 0 }
}

/// UInt64 traits
public struct ProtobufUInt64: FieldType {
    public typealias BaseType = UInt64
    public static var proto3DefaultValue: UInt64 { 0 }
}

/// SInt32 traits
public struct ProtobufSInt32: FieldType {
    public typealias BaseType = Int32
    public static var proto3DefaultValue: Int32 { 0 }
}

/// SInt64 traits
public struct ProtobufSInt64: FieldType {
    public typealias BaseType = Int64
    public static var proto3DefaultValue: Int64 { 0 }
}

/// Fixed32 traits
public struct ProtobufFixed32: FieldType {
    public typealias BaseType = UInt32
    public static var proto3DefaultValue: UInt32 { 0 }
}

/// Fixed64 traits
public struct ProtobufFixed64: FieldType {
    public typealias BaseType = UInt64
    public static var proto3DefaultValue: UInt64 { 0 }
}

/// SFixed32 traits
public struct ProtobufSFixed32: FieldType {
    public typealias BaseType = Int32
    public static var proto3DefaultValue: Int32 { 0 }
}

/// SFixed64 traits
public struct ProtobufSFixed64: FieldType {
    public typealias BaseType = Int64
    public static var proto3DefaultValue: Int64 { 0 }
}

/// Bool traits
public struct ProtobufBool: FieldType {
    public typealias BaseType = Bool
    public static var proto3DefaultValue: Bool { false }
}

/// String traits
public struct ProtobufString: FieldType {
    public typealias BaseType = String
    public static var proto3DefaultValue: String { String() }

    @_spi(ForGeneratedCodeOnly)
    public static func _protobuf_getSingular(from storage: ExtensionStorage, ext: ExtensionSchema) -> String? {
        storage.values[ext.field.fieldNumber]?.value(as: String.self)
    }

    @_spi(ForGeneratedCodeOnly)
    public static func _protobuf_setSingular(in storage: ExtensionStorage, ext: ExtensionSchema, value: String) {
        storage.updateValue(of: ext, to: value)
    }
}

/// Bytes traits
public struct ProtobufBytes: FieldType {
    public typealias BaseType = Data
    public static var proto3DefaultValue: Data { Data() }

    @_spi(ForGeneratedCodeOnly)
    public static func _protobuf_getSingular(from storage: ExtensionStorage, ext: ExtensionSchema) -> Data? {
        storage.values[ext.field.fieldNumber]?.value(as: Data.self)
    }

    @_spi(ForGeneratedCodeOnly)
    public static func _protobuf_setSingular(in storage: ExtensionStorage, ext: ExtensionSchema, value: Data) {
        storage.updateValue(of: ext, to: value)
    }
}

/// Type-erased extension field protocol, preserved for source compatibility.
@preconcurrency
public protocol AnyExtensionField: Sendable, CustomDebugStringConvertible {
    func hash(into hasher: inout Hasher)
    var protobufExtension: any AnyMessageExtension { get }
    func isEqual(other: any AnyExtensionField) -> Bool
    var isInitialized: Bool { get }
}

extension AnyExtensionField {
    public var isInitialized: Bool { true }
}

/// Strongly-typed extension field protocol, preserved for source compatibility.
@preconcurrency
public protocol ExtensionField: AnyExtensionField, Hashable {
    associatedtype ValueType
    var value: ValueType { get set }
    init(protobufExtension: any AnyMessageExtension, value: ValueType)

    @_spi(ForGeneratedCodeOnly)
    static func _protobuf_get(from storage: ExtensionStorage, ext: ExtensionSchema) -> ValueType?
    @_spi(ForGeneratedCodeOnly)
    static func _protobuf_set(in storage: ExtensionStorage, ext: ExtensionSchema, value: ValueType)
}

/// Singular scalar extension field.
public struct OptionalExtensionField<T: FieldType>: ExtensionField {
    public typealias BaseType = T.BaseType
    public typealias ValueType = BaseType
    public var value: ValueType
    public var protobufExtension: any AnyMessageExtension

    public static func == (lhs: OptionalExtensionField, rhs: OptionalExtensionField) -> Bool {
        lhs.value == rhs.value
    }

    public init(protobufExtension: any AnyMessageExtension, value: ValueType) {
        self.protobufExtension = protobufExtension
        self.value = value
    }

    public var debugDescription: String {
        #if DEBUG
        return String(reflecting: value)
        #else
        return String(reflecting: type(of: self))
        #endif
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(value)
    }

    public func isEqual(other: any AnyExtensionField) -> Bool {
        let o = other as! OptionalExtensionField<T>
        return self == o
    }

    @_spi(ForGeneratedCodeOnly)
    public static func _protobuf_get(from storage: ExtensionStorage, ext: ExtensionSchema) -> ValueType? {
        T._protobuf_getSingular(from: storage, ext: ext)
    }

    @_spi(ForGeneratedCodeOnly)
    public static func _protobuf_set(in storage: ExtensionStorage, ext: ExtensionSchema, value: ValueType) {
        T._protobuf_setSingular(in: storage, ext: ext, value: value)
    }
}

/// Repeated unpacked scalar extension field.
public struct RepeatedExtensionField<T: FieldType>: ExtensionField {
    public typealias BaseType = T.BaseType
    public typealias ValueType = [BaseType]
    public var value: ValueType
    public var protobufExtension: any AnyMessageExtension

    public static func == (lhs: RepeatedExtensionField, rhs: RepeatedExtensionField) -> Bool {
        lhs.value == rhs.value
    }

    public init(protobufExtension: any AnyMessageExtension, value: ValueType) {
        self.protobufExtension = protobufExtension
        self.value = value
    }

    public var debugDescription: String {
        #if DEBUG
        return "[" + value.map { String(reflecting: $0) }.joined(separator: ",") + "]"
        #else
        return String(reflecting: type(of: self))
        #endif
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(value)
    }

    public func isEqual(other: any AnyExtensionField) -> Bool {
        let o = other as! RepeatedExtensionField<T>
        return self == o
    }

    @_spi(ForGeneratedCodeOnly)
    public static func _protobuf_get(from storage: ExtensionStorage, ext: ExtensionSchema) -> ValueType? {
        storage.values[ext.field.fieldNumber]?.value(as: ValueType.self)
    }

    @_spi(ForGeneratedCodeOnly)
    public static func _protobuf_set(in storage: ExtensionStorage, ext: ExtensionSchema, value: ValueType) {
        storage.updateValue(of: ext, to: value)
    }
}

/// Repeated packed scalar extension field.
public struct PackedExtensionField<T: FieldType>: ExtensionField {
    public typealias BaseType = T.BaseType
    public typealias ValueType = [BaseType]
    public var value: ValueType
    public var protobufExtension: any AnyMessageExtension

    public static func == (lhs: PackedExtensionField, rhs: PackedExtensionField) -> Bool {
        lhs.value == rhs.value
    }

    public init(protobufExtension: any AnyMessageExtension, value: ValueType) {
        self.protobufExtension = protobufExtension
        self.value = value
    }

    public var debugDescription: String {
        #if DEBUG
        return "[" + value.map { String(reflecting: $0) }.joined(separator: ",") + "]"
        #else
        return String(reflecting: type(of: self))
        #endif
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(value)
    }

    public func isEqual(other: any AnyExtensionField) -> Bool {
        let o = other as! PackedExtensionField<T>
        return self == o
    }

    @_spi(ForGeneratedCodeOnly)
    public static func _protobuf_get(from storage: ExtensionStorage, ext: ExtensionSchema) -> ValueType? {
        storage.values[ext.field.fieldNumber]?.value(as: ValueType.self)
    }

    @_spi(ForGeneratedCodeOnly)
    public static func _protobuf_set(in storage: ExtensionStorage, ext: ExtensionSchema, value: ValueType) {
        storage.updateValue(of: ext, to: value)
    }
}

/// Singular enum extension field.
public struct OptionalEnumExtensionField<E: Enum>: ExtensionField where E.RawValue == Int {
    public typealias BaseType = E
    public typealias ValueType = E
    public var value: ValueType
    public var protobufExtension: any AnyMessageExtension

    public static func == (lhs: OptionalEnumExtensionField, rhs: OptionalEnumExtensionField) -> Bool {
        lhs.value == rhs.value
    }

    public init(protobufExtension: any AnyMessageExtension, value: ValueType) {
        self.protobufExtension = protobufExtension
        self.value = value
    }

    public var debugDescription: String {
        #if DEBUG
        return String(reflecting: value)
        #else
        return String(reflecting: type(of: self))
        #endif
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(value)
    }

    public func isEqual(other: any AnyExtensionField) -> Bool {
        let o = other as! OptionalEnumExtensionField<E>
        return self == o
    }

    @_spi(ForGeneratedCodeOnly)
    public static func _protobuf_get(from storage: ExtensionStorage, ext: ExtensionSchema) -> ValueType? {
        guard let stored = storage.values[ext.field.fieldNumber] else {
            return nil
        }
        return E(rawValue: Int(stored.value(as: Int32.self)))
    }

    @_spi(ForGeneratedCodeOnly)
    public static func _protobuf_set(in storage: ExtensionStorage, ext: ExtensionSchema, value: ValueType) {
        storage.updateValue(of: ext, to: value)
    }
}

/// Repeated unpacked enum extension field.
public struct RepeatedEnumExtensionField<E: Enum>: ExtensionField where E.RawValue == Int {
    public typealias BaseType = E
    public typealias ValueType = [E]
    public var value: ValueType
    public var protobufExtension: any AnyMessageExtension

    public static func == (lhs: RepeatedEnumExtensionField, rhs: RepeatedEnumExtensionField) -> Bool {
        lhs.value == rhs.value
    }

    public init(protobufExtension: any AnyMessageExtension, value: ValueType) {
        self.protobufExtension = protobufExtension
        self.value = value
    }

    public var debugDescription: String {
        #if DEBUG
        return "[" + value.map { String(reflecting: $0) }.joined(separator: ",") + "]"
        #else
        return String(reflecting: type(of: self))
        #endif
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(value)
    }

    public func isEqual(other: any AnyExtensionField) -> Bool {
        let o = other as! RepeatedEnumExtensionField<E>
        return self == o
    }

    @_spi(ForGeneratedCodeOnly)
    public static func _protobuf_get(from storage: ExtensionStorage, ext: ExtensionSchema) -> ValueType? {
        storage.values[ext.field.fieldNumber]?.value(as: ValueType.self)
    }

    @_spi(ForGeneratedCodeOnly)
    public static func _protobuf_set(in storage: ExtensionStorage, ext: ExtensionSchema, value: ValueType) {
        storage.updateValue(of: ext, to: value)
    }
}

/// Repeated packed enum extension field.
public struct PackedEnumExtensionField<E: Enum>: ExtensionField where E.RawValue == Int {
    public typealias BaseType = E
    public typealias ValueType = [E]
    public var value: ValueType
    public var protobufExtension: any AnyMessageExtension

    public static func == (lhs: PackedEnumExtensionField, rhs: PackedEnumExtensionField) -> Bool {
        lhs.value == rhs.value
    }

    public init(protobufExtension: any AnyMessageExtension, value: ValueType) {
        self.protobufExtension = protobufExtension
        self.value = value
    }

    public var debugDescription: String {
        #if DEBUG
        return "[" + value.map { String(reflecting: $0) }.joined(separator: ",") + "]"
        #else
        return String(reflecting: type(of: self))
        #endif
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(value)
    }

    public func isEqual(other: any AnyExtensionField) -> Bool {
        let o = other as! PackedEnumExtensionField<E>
        return self == o
    }

    @_spi(ForGeneratedCodeOnly)
    public static func _protobuf_get(from storage: ExtensionStorage, ext: ExtensionSchema) -> ValueType? {
        storage.values[ext.field.fieldNumber]?.value(as: ValueType.self)
    }

    @_spi(ForGeneratedCodeOnly)
    public static func _protobuf_set(in storage: ExtensionStorage, ext: ExtensionSchema, value: ValueType) {
        storage.updateValue(of: ext, to: value)
    }
}

/// Singular message extension field.
public struct OptionalMessageExtensionField<M: Message & Equatable>: ExtensionField {
    public typealias BaseType = M
    public typealias ValueType = BaseType
    public var value: ValueType
    public var protobufExtension: any AnyMessageExtension

    public static func == (lhs: OptionalMessageExtensionField, rhs: OptionalMessageExtensionField) -> Bool {
        lhs.value == rhs.value
    }

    public init(protobufExtension: any AnyMessageExtension, value: ValueType) {
        self.protobufExtension = protobufExtension
        self.value = value
    }

    public var debugDescription: String {
        #if DEBUG
        return String(reflecting: value)
        #else
        return String(reflecting: type(of: self))
        #endif
    }

    public func hash(into hasher: inout Hasher) {
        value.hash(into: &hasher)
    }

    public func isEqual(other: any AnyExtensionField) -> Bool {
        let o = other as! OptionalMessageExtensionField<M>
        return self == o
    }

    public var isInitialized: Bool {
        value.isInitialized
    }

    @_spi(ForGeneratedCodeOnly)
    public static func _protobuf_get(from storage: ExtensionStorage, ext: ExtensionSchema) -> ValueType? {
        storage.values[ext.field.fieldNumber]?.value(as: ValueType.self)
    }

    @_spi(ForGeneratedCodeOnly)
    public static func _protobuf_set(in storage: ExtensionStorage, ext: ExtensionSchema, value: ValueType) {
        storage.updateValue(of: ext, to: value)
    }
}

/// Repeated message extension field.
public struct RepeatedMessageExtensionField<M: Message & Equatable>: ExtensionField {
    public typealias BaseType = M
    public typealias ValueType = [BaseType]
    public var value: ValueType
    public var protobufExtension: any AnyMessageExtension

    public static func == (lhs: RepeatedMessageExtensionField, rhs: RepeatedMessageExtensionField) -> Bool {
        lhs.value == rhs.value
    }

    public init(protobufExtension: any AnyMessageExtension, value: ValueType) {
        self.protobufExtension = protobufExtension
        self.value = value
    }

    public var debugDescription: String {
        #if DEBUG
        return "[" + value.map { String(reflecting: $0) }.joined(separator: ",") + "]"
        #else
        return String(reflecting: type(of: self))
        #endif
    }

    public func hash(into hasher: inout Hasher) {
        for e in value {
            e.hash(into: &hasher)
        }
    }

    public func isEqual(other: any AnyExtensionField) -> Bool {
        let o = other as! RepeatedMessageExtensionField<M>
        return self == o
    }

    public var isInitialized: Bool {
        value.allSatisfy(\.isInitialized)
    }

    @_spi(ForGeneratedCodeOnly)
    public static func _protobuf_get(from storage: ExtensionStorage, ext: ExtensionSchema) -> ValueType? {
        storage.values[ext.field.fieldNumber]?.value(as: ValueType.self)
    }

    @_spi(ForGeneratedCodeOnly)
    public static func _protobuf_set(in storage: ExtensionStorage, ext: ExtensionSchema, value: ValueType) {
        storage.updateValue(of: ext, to: value)
    }
}

/// Singular group extension field.
public struct OptionalGroupExtensionField<G: Message & Hashable>: ExtensionField {
    public typealias BaseType = G
    public typealias ValueType = G
    public var value: ValueType
    public var protobufExtension: any AnyMessageExtension

    public static func == (lhs: OptionalGroupExtensionField, rhs: OptionalGroupExtensionField) -> Bool {
        lhs.value == rhs.value
    }

    public init(protobufExtension: any AnyMessageExtension, value: G) {
        self.protobufExtension = protobufExtension
        self.value = value
    }

    public var debugDescription: String {
        #if DEBUG
        return value.debugDescription
        #else
        return String(reflecting: type(of: self))
        #endif
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(value)
    }

    public func isEqual(other: any AnyExtensionField) -> Bool {
        let o = other as! OptionalGroupExtensionField<G>
        return self == o
    }

    public var isInitialized: Bool {
        value.isInitialized
    }

    @_spi(ForGeneratedCodeOnly)
    public static func _protobuf_get(from storage: ExtensionStorage, ext: ExtensionSchema) -> ValueType? {
        storage.values[ext.field.fieldNumber]?.value(as: ValueType.self)
    }

    @_spi(ForGeneratedCodeOnly)
    public static func _protobuf_set(in storage: ExtensionStorage, ext: ExtensionSchema, value: ValueType) {
        storage.updateValue(of: ext, to: value)
    }
}

/// Repeated group extension field.
public struct RepeatedGroupExtensionField<G: Message & Hashable>: ExtensionField {
    public typealias BaseType = G
    public typealias ValueType = [BaseType]
    public var value: ValueType
    public var protobufExtension: any AnyMessageExtension

    public static func == (lhs: RepeatedGroupExtensionField, rhs: RepeatedGroupExtensionField) -> Bool {
        lhs.value == rhs.value
    }

    public init(protobufExtension: any AnyMessageExtension, value: ValueType) {
        self.protobufExtension = protobufExtension
        self.value = value
    }

    public var debugDescription: String {
        #if DEBUG
        return "[" + value.map { $0.debugDescription }.joined(separator: ",") + "]"
        #else
        return String(reflecting: type(of: self))
        #endif
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(value)
    }

    public func isEqual(other: any AnyExtensionField) -> Bool {
        let o = other as! RepeatedGroupExtensionField<G>
        return self == o
    }

    public var isInitialized: Bool {
        value.allSatisfy(\.isInitialized)
    }

    @_spi(ForGeneratedCodeOnly)
    public static func _protobuf_get(from storage: ExtensionStorage, ext: ExtensionSchema) -> ValueType? {
        storage.values[ext.field.fieldNumber]?.value(as: ValueType.self)
    }

    @_spi(ForGeneratedCodeOnly)
    public static func _protobuf_set(in storage: ExtensionStorage, ext: ExtensionSchema, value: ValueType) {
        storage.updateValue(of: ext, to: value)
    }
}

/// Strongly-typed extension field descriptor that relates a particular extension field to a
/// particular extended message type, preserved for source compatibility.
public final class MessageExtension<FieldType: ExtensionField, MessageType: Message>:
    ExtensionSchema, @unchecked Sendable
{
    /// The message type that this extension extends.
    public var messageType: any Message.Type {
        MessageType.self
    }
}

extension Message {
    /// Returns the value of the given strongly-typed extension field on this message, or `nil` if
    /// the extension is not set.
    public func getExtensionValue<F: ExtensionField>(ext: MessageExtension<F, Self>) -> F.ValueType? {
        F._protobuf_get(from: storageForRuntime.extensionStorage, ext: ext)
    }

    /// Sets the value of the given strongly-typed extension field on this message.
    public mutating func setExtensionValue<F: ExtensionField>(ext: MessageExtension<F, Self>, value: F.ValueType) {
        F._protobuf_set(in: _protobuf_uniqueExtensionStorage(), ext: ext, value: value)
    }

    /// Returns true if the given strongly-typed extension field is set on this message.
    public func hasExtensionValue<F: ExtensionField>(ext: MessageExtension<F, Self>) -> Bool {
        _protobuf_extensionStorage().hasValue(for: ext)
    }

    /// Clears the value of the given strongly-typed extension field on this message.
    public mutating func clearExtensionValue<F: ExtensionField>(ext: MessageExtension<F, Self>) {
        _protobuf_uniqueExtensionStorage().clearValue(of: ext)
    }

    /// Returns the value of the given extension field on this message, or `nil` if the extension
    /// is not set.
    public func getExtensionValue<T: BitwiseCopyable>(ext: ExtensionSchema) -> T? {
        storageForRuntime.extensionStorage.values[ext.field.fieldNumber]?.value(as: T.self)
    }

    /// Returns the protobuf enum value of the given extension field on this message, or `nil` if
    /// the extension is not set.
    public func getExtensionValue<T: Enum>(ext: ExtensionSchema) -> T? {
        guard let stored = storageForRuntime.extensionStorage.values[ext.field.fieldNumber] else {
            return nil
        }
        return T(rawValue: Int(stored.value(as: Int32.self)))
    }

    /// Returns the protobuf enum value of the given extension field on this message, or `nil` if
    /// the extension is not set.
    public func getExtensionValue<T: Enum & BitwiseCopyable>(ext: ExtensionSchema) -> T? {
        guard let stored = storageForRuntime.extensionStorage.values[ext.field.fieldNumber] else {
            return nil
        }
        return T(rawValue: Int(stored.value(as: Int32.self)))
    }

    /// Returns the value of the given extension field on this message, or `nil` if the extension
    /// is not set.
    public func getExtensionValue<T>(ext: ExtensionSchema) -> T? {
        storageForRuntime.extensionStorage.values[ext.field.fieldNumber]?.value(as: T.self)
    }

    /// Sets the value of the given extension field on this message.
    public mutating func setExtensionValue<T: BitwiseCopyable>(ext: ExtensionSchema, value: T) {
        _protobuf_uniqueExtensionStorage().updateValue(of: ext, to: value)
    }

    /// Sets the protobuf enum value of the given extension field on this message.
    public mutating func setExtensionValue<T: Enum>(ext: ExtensionSchema, value: T) {
        _protobuf_uniqueExtensionStorage().updateValue(of: ext, to: value)
    }

    /// Sets the protobuf enum value of the given extension field on this message.
    public mutating func setExtensionValue<T: Enum & BitwiseCopyable>(ext: ExtensionSchema, value: T) {
        _protobuf_uniqueExtensionStorage().updateValue(of: ext, to: value)
    }

    /// Sets the repeated value of the given extension field on this message.
    public mutating func setExtensionValue<Element>(ext: ExtensionSchema, value: [Element]) {
        _protobuf_uniqueExtensionStorage().updateValue(of: ext, to: value)
    }

    /// Sets the value of the given extension field on this message.
    public mutating func setExtensionValue<T>(ext: ExtensionSchema, value: T) {
        _protobuf_uniqueExtensionStorage().updateValue(of: ext, to: value)
    }

    /// Returns true if the given extension field is set on this message.
    public func hasExtensionValue(ext: ExtensionSchema) -> Bool {
        _protobuf_extensionStorage().hasValue(for: ext)
    }

    /// Clears the value of the given extension field on this message.
    public mutating func clearExtensionValue(ext: ExtensionSchema) {
        _protobuf_uniqueExtensionStorage().clearValue(of: ext)
    }
}
#endif  // !REMOVE_LEGACY_EXTENSION_APIS
