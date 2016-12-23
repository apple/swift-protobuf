// Sources/SwiftProtobuf/ExtensibleMessage.swift - Extension support
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Additional capabilities needed by messages that allow extensions.
///
// -----------------------------------------------------------------------------

import Swift

// Messages that support extensions implement this protocol
public protocol ExtensibleMessage: Message {
    mutating func setExtensionValue<F: AnyExtensionField>(ext: MessageExtension<F, Self>, value: F.ValueType)
    mutating func getExtensionValue<F: AnyExtensionField>(ext: MessageExtension<F, Self>) -> F.ValueType
    func hasExtensionValue<F: AnyExtensionField>(ext: MessageExtension<F, Self>) -> Bool
    mutating func clearExtensionValue<F: AnyExtensionField>(ext: MessageExtension<F, Self>)
}

// Common support for storage classes to handle extension fields
public protocol ExtensibleMessageStorage: class {
    associatedtype ExtendedMessage: Message
    var extensionFieldValues: ExtensionFieldValueSet {get set}
    func setExtensionValue<F: AnyExtensionField>(ext: MessageExtension<F, ExtendedMessage>, value: F.ValueType)
    func getExtensionValue<F: AnyExtensionField>(ext: MessageExtension<F, ExtendedMessage>) -> F.ValueType
}

public extension ExtensibleMessageStorage {
    public func setExtensionValue<F: AnyExtensionField>(ext: MessageExtension<F, ExtendedMessage>, value: F.ValueType) {
        extensionFieldValues[ext.protoFieldNumber] = ext.set(value: value)
    }
    
    public func clearExtensionValue<F: AnyExtensionField>(ext: MessageExtension<F, ExtendedMessage>) {
        extensionFieldValues[ext.protoFieldNumber] = nil
    }
    
    public func getExtensionValue<F: AnyExtensionField>(ext: MessageExtension<F, ExtendedMessage>) -> F.ValueType {
        if let fieldValue = extensionFieldValues[ext.protoFieldNumber] as? F {
            return fieldValue.value
        }
        return ext.defaultValue
    }
    
    public func hasExtensionValue<F: AnyExtensionField>(ext: MessageExtension<F, ExtendedMessage>) -> Bool {
        return extensionFieldValues[ext.protoFieldNumber] is F
    }
}
