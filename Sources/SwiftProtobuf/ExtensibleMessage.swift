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

// Messages that support extensions implement this protocol
public protocol ExtensibleMessage: Message {
    var _protobuf_extensionFieldValues: ExtensionFieldValueSet { get set }
}

public extension ExtensibleMessage {
    mutating func setExtensionValue<F: AnyExtensionField>(ext: MessageExtension<F, Self>, value: F.ValueType) {
        _protobuf_extensionFieldValues[ext.fieldNumber] = ext._protobuf_set(value: value)
    }

    func getExtensionValue<F: AnyExtensionField>(ext: MessageExtension<F, Self>) -> F.ValueType {
     if let fieldValue = _protobuf_extensionFieldValues[ext.fieldNumber] as? F {
       return fieldValue.value
     }
     return ext.defaultValue
    }

    func hasExtensionValue<F: AnyExtensionField>(ext: MessageExtension<F, Self>) -> Bool {
      return _protobuf_extensionFieldValues[ext.fieldNumber] is F
    }

    mutating func clearExtensionValue<F: AnyExtensionField>(ext: MessageExtension<F, Self>) {
        _protobuf_extensionFieldValues[ext.fieldNumber] = nil
    }
}
