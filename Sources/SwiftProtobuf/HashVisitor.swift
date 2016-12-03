// ProtobufRuntime/Sources/Protobuf/ProtobufHash.swift - Hashing support
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
/// Hashing is basically a serialization problem, so we can leverage the
/// generated traversal methods for that.
///
// -----------------------------------------------------------------------------

import Swift
import Foundation

private let i_2166136261 = Int(bitPattern: 2166136261)
private let i_16777619 = Int(16777619)

//
// The hashValue property is computed with a visitor that
// traverses the message tree.
//
struct HashVisitor: Visitor {
    // Roughly based on FNV hash:
    // http://tools.ietf.org/html/draft-eastlake-fnv-03
    private(set) var hashValue = i_2166136261

    private mutating func mix(_ hash: Int) {
        hashValue = (hashValue ^ hash) &* i_16777619
    }

    init() {}

    init(message: Message) {
        withAbstractVisitor {(visitor: inout Visitor) in
            try message.traverse(visitor: &visitor)
        }
    }

    mutating func withAbstractVisitor(clause: (inout Visitor) throws -> ()) {
        var visitor: Visitor = self
        let _ = try? clause(&visitor)
        hashValue = (visitor as! HashVisitor).hashValue
    }

    mutating func visitUnknown(bytes: Data) {
        mix(bytes.hashValue)
    }

    mutating func visitSingularField<S: FieldType>(fieldType: S.Type, value: S.BaseType, protoFieldNumber: Int) throws {
        mix(protoFieldNumber)
        mix(value.hashValue)
    }

    mutating func visitRepeatedField<S: FieldType>(fieldType: S.Type, value: [S.BaseType], protoFieldNumber: Int) throws {
        mix(protoFieldNumber)
        for v in value {
            mix(v.hashValue)
        }
    }

    mutating func visitPackedField<S: FieldType>(fieldType: S.Type, value: [S.BaseType], protoFieldNumber: Int) throws {
        mix(protoFieldNumber)
        for v in value {
            mix(v.hashValue)
        }
    }

    mutating func visitSingularMessageField<M: Message>(value: M, protoFieldNumber: Int) throws {
        mix(protoFieldNumber)
        mix(value.hashValue)
    }

    mutating func visitRepeatedMessageField<M: Message>(value: [M], protoFieldNumber: Int) throws {
        mix(protoFieldNumber)
        for v in value {
            mix(v.hashValue)
        }
   }

    mutating func visitSingularGroupField<G: Message>(value: G, protoFieldNumber: Int) throws {
        mix(protoFieldNumber)
        mix(value.hashValue)
    }

    mutating func visitRepeatedGroupField<G: Message>(value: [G], protoFieldNumber: Int) throws {
        mix(protoFieldNumber)
        for v in value {
            mix(v.hashValue)
        }
    }

    mutating func visitMapField<KeyType: MapKeyType, ValueType: MapValueType>(fieldType: Map<KeyType, ValueType>.Type, value: Map<KeyType, ValueType>.BaseType, protoFieldNumber: Int) throws where KeyType.BaseType: Hashable {
        mix(protoFieldNumber)
        // Note: When Map<Hashable,Hashable> is Hashable, this will simplify to
        // mix(value.hashValue)
        var mapHash = 0
        for (k,v) in value {
            // Note: This calculation cannot depend on the order of the items.
            mapHash += k.hashValue ^ v.hashValue
        }
        mix(mapHash)
    }
}
