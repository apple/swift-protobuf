// Sources/SwiftProtobuf/MessageExtension.swift - Extension support
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// A 'Message Extension' is an immutable class object that describes
/// a particular extension field, including string and number
/// identifiers, serialization details, and the identity of the
/// message that is being extended.
///
// -----------------------------------------------------------------------------

/// Type-erased MessageExtension field implementation.
@preconcurrency
public protocol AnyMessageExtension: Sendable {
    var fieldNumber: Int { get }
    var fieldName: String { get }
    var messageType: any Message.Type { get }
    func _protobuf_newField<D: Decoder>(decoder: inout D) throws -> (any AnyExtensionField)?
}

/// A "Message Extension" relates a particular extension field to
/// a particular message.  The generic constraints allow
/// compile-time compatibility checks.
public final class MessageExtension<FieldType: ExtensionField, MessageType: Message>: AnyMessageExtension {
    public let fieldNumber: Int
    public let fieldName: String
    public let messageType: any Message.Type
    public init(_protobuf_fieldNumber: Int, fieldName: String) {
        self.fieldNumber = _protobuf_fieldNumber
        self.fieldName = fieldName
        self.messageType = MessageType.self
    }
    public func _protobuf_newField<D: Decoder>(decoder: inout D) throws -> (any AnyExtensionField)? {
        try FieldType(protobufExtension: self, decoder: &decoder)
    }
}
