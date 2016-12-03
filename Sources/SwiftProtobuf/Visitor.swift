// ProtobufRuntime/Sources/Protobuf/ProtobufTraversal.swift - Basic serialization machinery
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
/// Protocol for traversing the object tree.
///
/// This is used by:
/// = Protobuf serialization
/// = JSON serialization (with some twists to account for specialty JSON encodings)
/// = hashValue computation
/// = mirror generation
///
/// Conceptually, serializers create visitor objects that are
/// then passed recursively to every message and field via generated
/// 'traverse' methods.  The details get a little involved due to
/// the need to allow particular messages to override particular
/// behaviors for specific encodings, but the general idea is quite simple.
///
// -----------------------------------------------------------------------------

import Swift
import Foundation

public protocol Visitor {
    /// For proto2, visitors get to see the raw bytes for any unknown fields
    mutating func visitUnknown(bytes: Data)
    mutating func visitSingularField<S: FieldType>(fieldType: S.Type, value: S.BaseType, protoFieldNumber: Int) throws
    mutating func visitRepeatedField<S: FieldType>(fieldType: S.Type, value: [S.BaseType], protoFieldNumber: Int) throws
    mutating func visitPackedField<S: FieldType>(fieldType: S.Type, value: [S.BaseType], protoFieldNumber: Int) throws
    mutating func visitSingularMessageField<M: Message>(value: M, protoFieldNumber: Int) throws
    mutating func visitRepeatedMessageField<M: Message>(value: [M], protoFieldNumber: Int) throws
    mutating func visitSingularGroupField<G: Message>(value: G, protoFieldNumber: Int) throws
    mutating func visitRepeatedGroupField<G: Message>(value: [G], protoFieldNumber: Int) throws
    mutating func visitMapField<KeyType: MapKeyType, ValueType: MapValueType>(fieldType: Map<KeyType, ValueType>.Type, value: Map<KeyType, ValueType>.BaseType, protoFieldNumber: Int) throws where KeyType.BaseType: Hashable
}
