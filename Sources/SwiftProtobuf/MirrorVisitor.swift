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
import Foundation

struct MirrorVisitor: Visitor {
    private var mirrorChildren: [Mirror.Child] = []
    private var message: Message

    mutating func fail() {}

    var mirror: Mirror {
        get {
            return Mirror(message, children: mirrorChildren /* displayStyle: .Struct */)
        }
    }

    init(message: Message) {
        self.message = message
        withAbstractVisitor {(visitor: inout Visitor) in
            try message.traverse(visitor: &visitor)
        }
    }

    mutating func withAbstractVisitor(clause: (inout Visitor) throws -> ()) {
        var visitor: Visitor = self
        let _ = try? clause(&visitor)
        mirrorChildren.append(contentsOf: (visitor as! MirrorVisitor).mirrorChildren)
    }

    mutating func visitUnknown(bytes: Data) {}

    mutating func visitSingularField<S: FieldType>(fieldType: S.Type, value: S.BaseType, protoFieldNumber: Int, protoFieldName: String, jsonFieldName: String, swiftFieldName: String) throws {
        mirrorChildren.append((label: swiftFieldName, value: value))
    }

    mutating func visitRepeatedField<S: FieldType>(fieldType: S.Type, value: [S.BaseType], protoFieldNumber: Int, protoFieldName: String, jsonFieldName: String, swiftFieldName: String) throws {
        mirrorChildren.append((label: swiftFieldName, value: value))
    }

    mutating func visitPackedField<S: FieldType>(fieldType: S.Type, value: [S.BaseType], protoFieldNumber: Int, protoFieldName: String, jsonFieldName: String, swiftFieldName: String) throws {
        mirrorChildren.append((label: swiftFieldName, value: value))
    }

    mutating func visitSingularMessageField<M: Message>(value: M, protoFieldNumber: Int, protoFieldName: String, jsonFieldName: String, swiftFieldName: String) throws {
        mirrorChildren.append((label: swiftFieldName, value: value))
    }

    mutating func visitRepeatedMessageField<M: Message>(value:[M], protoFieldNumber: Int, protoFieldName: String, jsonFieldName: String, swiftFieldName: String) throws {
        mirrorChildren.append((label: swiftFieldName, value: value))
   }

    mutating func visitSingularGroupField<G: Message>(value: G, protoFieldNumber: Int, protoFieldName: String, jsonFieldName: String, swiftFieldName: String) throws {
        mirrorChildren.append((label: swiftFieldName, value: value))
    }

    mutating func visitRepeatedGroupField<G: Message>(value: [G], protoFieldNumber: Int, protoFieldName: String, jsonFieldName: String, swiftFieldName: String) throws {
        mirrorChildren.append((label: swiftFieldName, value: value))
    }

    mutating func visitMapField<KeyType: MapKeyType, ValueType: MapValueType>(fieldType: Map<KeyType, ValueType>.Type, value: Map<KeyType, ValueType>.BaseType, protoFieldNumber: Int, protoFieldName: String, jsonFieldName: String, swiftFieldName: String) throws where KeyType.BaseType: Hashable {
        mirrorChildren.append((label: swiftFieldName, value: value))
    }
}
