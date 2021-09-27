// Sources/SwiftProtobuf/ExtensibleMessage.swift - Extension support
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
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

extension ExtensibleMessage {
    public mutating func setExtensionValue<F: ExtensionField>(ext: MessageExtension<F, Self>, value: F.ValueType) {
        _protobuf_extensionFieldValues[ext.fieldNumber] = F(protobufExtension: ext, value: value)
    }

    public func getExtensionValue<F: ExtensionField>(ext: MessageExtension<F, Self>) -> F.ValueType? {
        if let fieldValue = _protobuf_extensionFieldValues[ext.fieldNumber] as? F {
          return fieldValue.value
        }
        return nil
    }

    public func hasExtensionValue<F: ExtensionField>(ext: MessageExtension<F, Self>) -> Bool {
        return _protobuf_extensionFieldValues[ext.fieldNumber] is F
    }

    public mutating func clearExtensionValue<F: ExtensionField>(ext: MessageExtension<F, Self>) {
        _protobuf_extensionFieldValues[ext.fieldNumber] = nil
    }
}

// Additional specializations for the different types of repeated fields so
// setting them to an empty array clears them from the map.
extension ExtensibleMessage {
    public mutating func setExtensionValue<T>(ext: MessageExtension<RepeatedExtensionField<T>, Self>, value: [T.BaseType]) {
        _protobuf_extensionFieldValues[ext.fieldNumber] =
            value.isEmpty ? nil : RepeatedExtensionField<T>(protobufExtension: ext, value: value)
    }

    public mutating func setExtensionValue<T>(ext: MessageExtension<PackedExtensionField<T>, Self>, value: [T.BaseType]) {
        _protobuf_extensionFieldValues[ext.fieldNumber] =
            value.isEmpty ? nil : PackedExtensionField<T>(protobufExtension: ext, value: value)
    }

    public mutating func setExtensionValue<E>(ext: MessageExtension<RepeatedEnumExtensionField<E>, Self>, value: [E]) {
        _protobuf_extensionFieldValues[ext.fieldNumber] =
            value.isEmpty ? nil : RepeatedEnumExtensionField<E>(protobufExtension: ext, value: value)
    }

    public mutating func setExtensionValue<E>(ext: MessageExtension<PackedEnumExtensionField<E>, Self>, value: [E]) {
        _protobuf_extensionFieldValues[ext.fieldNumber] =
            value.isEmpty ? nil : PackedEnumExtensionField<E>(protobufExtension: ext, value: value)
    }

    public mutating func setExtensionValue<M>(ext: MessageExtension<RepeatedMessageExtensionField<M>, Self>, value: [M]) {
        _protobuf_extensionFieldValues[ext.fieldNumber] =
            value.isEmpty ? nil : RepeatedMessageExtensionField<M>(protobufExtension: ext, value: value)
    }

    public mutating func setExtensionValue<M>(ext: MessageExtension<RepeatedGroupExtensionField<M>, Self>, value: [M]) {
        _protobuf_extensionFieldValues[ext.fieldNumber] =
            value.isEmpty ? nil : RepeatedGroupExtensionField<M>(protobufExtension: ext, value: value)
    }
}
