// Sources/SwiftProtobuf/MessageExtension.swift - Extension support
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
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
    var fieldNames: FieldNameMap.Names { get }
    var messageType: Message.Type { get }
    func newField() -> AnyExtensionField
}

/// A "Message Extension" relates a particular extension field to
/// a particular message.  The generic constraints allow
/// compile-time compatibility checks.
public class MessageExtension<FieldType: ExtensionField, MessageType: Message>: MessageExtensionBase {
    public let protoFieldNumber: Int
    public var fieldNames: FieldNameMap.Names
    public let messageType: Message.Type
    public let defaultValue: FieldType.ValueType
    public init(protoFieldNumber: Int, fieldNames: FieldNameMap.Names, defaultValue: FieldType.ValueType) {
        self.protoFieldNumber = protoFieldNumber
        self.fieldNames = fieldNames
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
