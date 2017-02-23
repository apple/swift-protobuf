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
    mutating func setExtensionValue<F: AnyExtensionField>(ext: MessageExtension<F, Self>, value: F.ValueType)
    mutating func getExtensionValue<F: AnyExtensionField>(ext: MessageExtension<F, Self>) -> F.ValueType
    func hasExtensionValue<F: AnyExtensionField>(ext: MessageExtension<F, Self>) -> Bool
    mutating func clearExtensionValue<F: AnyExtensionField>(ext: MessageExtension<F, Self>)
}
