// ProtobufRuntime/Sources/Protobuf/ProtobufMirror.swift - Mirror generation
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
/// Visitor implementation for constructing custom Swift Mirrors
/// for generated message types.  This is a pretty straightforward
/// example of the traversal idiom; the only wrinkle being that
/// the visitor does not recurse into child messages.
///
// -----------------------------------------------------------------------------

import Swift

public struct ProtobufMirrorVisitor: ProtobufVisitor {
    private var mirrorChildren: [Mirror.Child] = []
    private var message: ProtobufMessageBase

    public mutating func fail() {}

    public var mirror: Mirror {
        get {
            return Mirror(message, children: mirrorChildren /* displayStyle: .Struct */)
        }
    }

    public init(message: ProtobufMessageBase) {
        self.message = message
        withAbstractVisitor {(visitor: inout ProtobufVisitor) in
            try message.traverse(visitor: &visitor)
        }
    }

    public mutating func withAbstractVisitor(clause: (inout ProtobufVisitor) throws -> ()) {
        var visitor: ProtobufVisitor = self
        let _ = try? clause(&visitor)
        mirrorChildren.append(contentsOf: (visitor as! ProtobufMirrorVisitor).mirrorChildren)
    }

    mutating public func visitUnknown(bytes: [UInt8]) {}

    mutating public func visitSingularField<S: ProtobufTypeProperties>(fieldType: S.Type, value: S.BaseType, protoFieldNumber: Int, protoFieldName: String, jsonFieldName: String, swiftFieldName: String) throws {
        mirrorChildren.append((label: swiftFieldName, value: value))
    }

    mutating public func visitRepeatedField<S: ProtobufTypeProperties>(fieldType: S.Type, value: [S.BaseType], protoFieldNumber: Int, protoFieldName: String, jsonFieldName: String, swiftFieldName: String) throws {
        mirrorChildren.append((label: swiftFieldName, value: value))
    }

    mutating public func visitPackedField<S: ProtobufTypeProperties>(fieldType: S.Type, value: [S.BaseType], protoFieldNumber: Int, protoFieldName: String, jsonFieldName: String, swiftFieldName: String) throws {
        mirrorChildren.append((label: swiftFieldName, value: value))
    }

    mutating public func visitSingularMessageField<M: ProtobufMessage>(value: M, protoFieldNumber: Int, protoFieldName: String, jsonFieldName: String, swiftFieldName: String) throws {
        mirrorChildren.append((label: swiftFieldName, value: value))
    }

    mutating public func visitRepeatedMessageField<M: ProtobufMessage>(value:[M], protoFieldNumber: Int, protoFieldName: String, jsonFieldName: String, swiftFieldName: String) throws {
        mirrorChildren.append((label: swiftFieldName, value: value))
   }

    mutating public func visitSingularGroupField<G: ProtobufGroup>(value: G, protoFieldNumber: Int, protoFieldName: String, jsonFieldName: String, swiftFieldName: String) throws {
        mirrorChildren.append((label: swiftFieldName, value: value))
    }

    mutating public func visitRepeatedGroupField<G: ProtobufGroup>(value: [G], protoFieldNumber: Int, protoFieldName: String, jsonFieldName: String, swiftFieldName: String) throws {
        mirrorChildren.append((label: swiftFieldName, value: value))
    }

    mutating public func visitMapField<KeyType: ProtobufMapKeyType, ValueType: ProtobufMapValueType>(fieldType: ProtobufMap<KeyType, ValueType>.Type, value: ProtobufMap<KeyType, ValueType>.BaseType, protoFieldNumber: Int, protoFieldName: String, jsonFieldName: String, swiftFieldName: String) throws where KeyType.BaseType: Hashable {
        mirrorChildren.append((label: swiftFieldName, value: value))
    }
}
