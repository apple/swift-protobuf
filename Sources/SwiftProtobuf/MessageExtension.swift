// ProtobufRuntime/Sources/Protobuf/ProtobufExtensions.swift - Extension support
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
/// A 'Message Extension' is an immutable class object that describes
/// a particular extension field, including string and number
/// identifiers, serialization details, and the identity of the
/// message that is being extended.
///
// -----------------------------------------------------------------------------

import Swift

/// Note that the MessageExtensionBase protocol has no generic
/// pieces.
public protocol MessageExtensionBase {
    var protoFieldNumber: Int { get }
    var protoFieldName: String { get }
    var jsonFieldName: String { get }
    var swiftFieldName: String { get }
    var messageType: Message.Type { get }
    func newField() -> AnyExtensionField
}

/// A "Message Extension" relates a particular extension field to
/// a particular message.  The generic constraints allow
/// compile-time compatibility checks.
public class MessageExtension<FieldType: ExtensionField, MessageType: Message>: MessageExtensionBase {
    public let protoFieldNumber: Int
    public let protoFieldName: String
    public let jsonFieldName: String
    public let swiftFieldName: String
    public let messageType: Message.Type
    public let defaultValue: FieldType.ValueType
    public init(protoFieldNumber: Int, protoFieldName: String, jsonFieldName: String, swiftFieldName: String, defaultValue: FieldType.ValueType) {
        self.protoFieldNumber = protoFieldNumber
        self.protoFieldName = protoFieldName
        self.jsonFieldName = jsonFieldName
        self.swiftFieldName = swiftFieldName
        self.messageType = MessageType.self
        self.defaultValue = defaultValue
    }
    public func set(value: FieldType.ValueType) -> AnyExtensionField {
        var f = FieldType(protobufExtension: self)
        f.value = value
        return f
    }
    public func newField() -> AnyExtensionField {
        return FieldType(protobufExtension: self)
    }
}
