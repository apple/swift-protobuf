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

// TODO: Rename this to just `ExtensionMap` when we remove the old APIs.

/// A collection of extension schemas.
///
/// A `NewExtensionMap` is used during decoding to look up extension schemas corresponding to
/// serialized data.
public struct NewExtensionMap: Sendable, ExpressibleByArrayLiteral {
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
    private var registryByNumber: [FieldNumberKey: ExtensionSchema] = [:]

    /// The registered extensions, keyed by message schema and field name.
    private var registryByName: [FieldNameKey: ExtensionSchema] = [:]

    /// Creates a new empty extension map.
    public init() {}

    /// Creates a new extension map from the given sequence of extension schemas.
    public init(arrayLiteral: ExtensionSchema...) {
        insert(contentsOf: arrayLiteral)
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
        registryByName[FieldNameKey(messageSchemaKey: messageKey, fieldName: schema.fieldName)] = schema
    }

    /// Adds a sequence of extension schemas into the receiver.
    public mutating func insert<S: Sequence<ExtensionSchema>>(contentsOf sequence: S) {
        for schema in sequence {
            insert(schema)
        }
    }

    /// Merges the given extension map into the receiver in-place.
    public mutating func formUnion(_ other: NewExtensionMap) {
        registryByNumber.merge(other.registryByNumber) { (_, new) in new }
        registryByName.merge(other.registryByName) { (_, new) in new }
    }

    /// Returns a new extension map that represents the merging of the receiver and the given
    /// extension map.
    public func union(_ other: NewExtensionMap) -> NewExtensionMap {
        var result = self
        result.formUnion(other)
        return result
    }
}

// TODO: This conformance only exists so that we can pass a `NewExtensionMap` into the existing
// `init`/`merge` APIs on `Message` without having to specialize them all for the new type. This
// makes testing much easier. The new table-driven implementation will force-cast it to
// `NewExtensionMap` before using it, so the requirements implemented below will never actually be
// called.
extension NewExtensionMap: ExtensionMap {}

/// TODO: Delete this protocol.
@preconcurrency
public protocol ExtensionMap: Sendable {}

/// TODO: Delete this.
public typealias SimpleExtensionMap = NewExtensionMap
