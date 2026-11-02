// Sources/SwiftProtobuf/ExtensionMap.swift - Extension support
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// A set of extensions that can be passed into deserializers
/// to provide details of the particular extensions that should
/// be recognized.
///
// -----------------------------------------------------------------------------

/// A collection of extension schemas.
///
/// An `ExtensionMap` is used during decoding to look up extension schemas corresponding to
/// serialized data.
///
/// This is a protocol so that applications can implement their own extension lookup if they need
/// something more complex than the standard `SimpleExtensionMap` implementation.
@preconcurrency
public protocol ExtensionMap: Sendable {
    /// Returns the extension schema for the extension field in a message that has the given
    /// field number, or `nil` if no such extension was found.
    subscript(
        fieldNumber fieldNumber: UInt32,
        in messageSchema: MessageSchema
    ) -> ExtensionSchema? { get }

    /// Returns the extension schema for the extension field in a message that has the given
    /// field name, or `nil` if no such extension was found.
    subscript(
        fieldName fieldName: String,
        in messageSchema: MessageSchema
    ) -> ExtensionSchema? { get }
}

#if !REMOVE_LEGACY_EXTENSION_APIS
extension ExtensionMap {
    /// Returns the extension schema for the extension field in `messageType` that has the given
    /// `fieldNumber`, or `nil` if no such extension was found.
    public subscript(
        messageType: any Message.Type,
        fieldNumber: Int
    ) -> ExtensionSchema? {
        guard let generatedType = messageType as? any GeneratedMessage.Type else {
            return nil
        }
        return self[
            fieldNumber: UInt32(fieldNumber),
            in: generatedType.messageSchema
        ]
    }

    /// Returns the field number for a message extension with a specific field name, or `nil` if
    /// no such extension is registered.
    public func fieldNumberForProto(
        messageType: any Message.Type,
        protoFieldName: String
    ) -> Int? {
        guard let generatedType = messageType as? any GeneratedMessage.Type,
            let schema = self[
                fieldName: protoFieldName,
                in: generatedType.messageSchema
            ]
        else {
            return nil
        }
        return schema.fieldNumber
    }
}
#endif  // !REMOVE_LEGACY_EXTENSION_APIS

/// A default implementation of `ExtensionMap`.
///
/// You can create a `SimpleExtensionMap` using an array literal of extension schemas or by uniting
/// other `SimpleExtensionMap`s together. The code generator also emits static `SimpleExtensionMap`s
/// for each file that defines extensions.
public struct SimpleExtensionMap: ExtensionMap, Sendable, ExpressibleByArrayLiteral {
    /// The hashable key used to look up extension schemas in the registry by their field number.
    private struct FieldNumberKey: Hashable {
        let messageSchemaKey: MessageSchema.Key
        let fieldNumber: UInt32
    }

    /// The hashable key used to look up extension schemas in the registry by their field name.
    private struct FieldNameKey: Hashable {
        let messageSchemaKey: MessageSchema.Key
        let fieldName: String
    }

    /// The registered extensions, keyed by message schema and field number.
    private var registryByNumber: [FieldNumberKey: ExtensionSchema]

    /// The registered extensions, keyed by message schema and field name.
    private var registryByName: [FieldNameKey: ExtensionSchema]

    /// Creates a new empty extension map.
    public init() {
        self.registryByNumber = [:]
        self.registryByName = [:]
    }

    /// Creates a new extension map from the given sequence of extension schemas.
    public init(arrayLiteral: ExtensionSchema...) {
        self.registryByNumber = [:]
        self.registryByName = [:]
        insert(contentsOf: arrayLiteral)
    }

    /// Creates a new extension map by merging the contents of the given maps.
    public init(_ others: SimpleExtensionMap...) {
        self.init()
        for other in others {
            formUnion(other)
        }
    }

    /// Creates a new extension map containing the given sequence of extension schemas.
    public init<S: Sequence<ExtensionSchema>>(_ schemas: S) {
        self.init()
        insert(contentsOf: schemas)
    }

    /// Returns the extension schema for the extension field in a message that has the given
    /// field number, or `nil` if no such extension was found.
    public subscript(
        fieldNumber fieldNumber: UInt32,
        in messageSchema: MessageSchema
    ) -> ExtensionSchema? {
        let key = FieldNumberKey(messageSchemaKey: messageSchema.key, fieldNumber: fieldNumber)
        return registryByNumber[key]
    }

    /// Returns the extension schema for the extension field in a message that has the given
    /// field name, or `nil` if no such extension was found.
    public subscript(
        fieldName fieldName: String,
        in messageSchema: MessageSchema,
    ) -> ExtensionSchema? {
        let key = FieldNameKey(messageSchemaKey: messageSchema.key, fieldName: fieldName)
        return registryByName[key]
    }

    /// Adds an extension schema into the receiver.
    public mutating func insert(_ schema: ExtensionSchema) {
        let messageKey = schema.extendedMessage.key
        registryByNumber[FieldNumberKey(messageSchemaKey: messageKey, fieldNumber: schema.field.fieldNumber)] = schema
        registryByName[
            FieldNameKey(messageSchemaKey: messageKey, fieldName: String(protobufUTF8Name: schema.utf8FieldName))
        ] = schema
    }

    /// Adds a sequence of extension schemas into the receiver.
    public mutating func insert<S: Sequence<ExtensionSchema>>(contentsOf sequence: S) {
        for schema in sequence {
            insert(schema)
        }
    }

    /// Merges the given extension map into the receiver in-place.
    public mutating func formUnion(_ other: SimpleExtensionMap) {
        registryByNumber.merge(other.registryByNumber) { (_, new) in new }
        registryByName.merge(other.registryByName) { (_, new) in new }
    }

    /// Returns a new extension map that represents the merging of the receiver and the given
    /// extension map.
    public func union(_ other: SimpleExtensionMap) -> SimpleExtensionMap {
        var result = self
        result.formUnion(other)
        return result
    }
}
