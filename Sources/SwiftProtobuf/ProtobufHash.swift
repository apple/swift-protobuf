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


private let i_2166136261 = Int(bitPattern: 2166136261)
private let i_16777619 = Int(16777619)

/// Utility hash function for a [UInt8]
public func ProtobufHash(bytes: [UInt8]) -> Int {
    var byteHash = i_2166136261
    for b in bytes {
        byteHash = (byteHash &* i_16777619) ^ Int(b)
    }
    return byteHash
}

//
// The hashValue property is computed with a visitor that
// traverses the message tree.
//
public struct ProtobufHashVisitor: ProtobufVisitor {
    // Roughly based on FNV hash:
    // http://tools.ietf.org/html/draft-eastlake-fnv-03
    public private(set) var hashValue = i_2166136261

    private mutating func mix(_ hash: Int) {
        hashValue = (hashValue ^ hash) &* i_16777619
    }

    public init() {}

    public init(message: ProtobufMessageBase) {
        withAbstractVisitor {(visitor: inout ProtobufVisitor) in
            try message.traverse(visitor: &visitor)
        }
    }

    public init(group: ProtobufGroupBase) {
        withAbstractVisitor {(visitor: inout ProtobufVisitor) in
            try group.traverse(visitor: &visitor)
        }
    }

    public mutating func withAbstractVisitor(clause: (inout ProtobufVisitor) throws -> ()) {
        var visitor: ProtobufVisitor = self
        let _ = try? clause(&visitor)
        hashValue = (visitor as! ProtobufHashVisitor).hashValue
    }

    mutating public func visitUnknown(bytes: [UInt8]) {
        mix(ProtobufHash(bytes: bytes))
    }

    mutating public func visitSingularField<S: ProtobufTypeProperties>(fieldType: S.Type, value: S.BaseType, protoFieldNumber: Int, protoFieldName: String, jsonFieldName: String, swiftFieldName: String) throws {
        mix(protoFieldNumber)
        mix(S.hash(value: value))
    }

    mutating public func visitRepeatedField<S: ProtobufTypeProperties>(fieldType: S.Type, value: [S.BaseType], protoFieldNumber: Int, protoFieldName: String, jsonFieldName: String, swiftFieldName: String) throws {
        mix(protoFieldNumber)
        for v in value {
            mix(S.hash(value: v))
        }
    }

    mutating public func visitPackedField<S: ProtobufTypeProperties>(fieldType: S.Type, value: [S.BaseType], protoFieldNumber: Int, protoFieldName: String, jsonFieldName: String, swiftFieldName: String) throws {
        mix(protoFieldNumber)
        for v in value {
            mix(S.hash(value: v))
        }
    }

    mutating public func visitSingularMessageField<M: ProtobufMessage>(value: M, protoFieldNumber: Int, protoFieldName: String, jsonFieldName: String, swiftFieldName: String) throws {
        mix(protoFieldNumber)
        mix(value.hashValue)
    }

    mutating public func visitRepeatedMessageField<M: ProtobufMessage>(value: [M], protoFieldNumber: Int, protoFieldName: String, jsonFieldName: String, swiftFieldName: String) throws {
        mix(protoFieldNumber)
        for v in value {
            mix(v.hashValue)
        }
   }

    mutating public func visitSingularGroupField<G: ProtobufGroup>(value: G, protoFieldNumber: Int, protoFieldName: String, jsonFieldName: String, swiftFieldName: String) throws {
        mix(protoFieldNumber)
        mix(value.hashValue)
    }

    mutating public func visitRepeatedGroupField<G: ProtobufGroup>(value: [G], protoFieldNumber: Int, protoFieldName: String, jsonFieldName: String, swiftFieldName: String) throws {
        mix(protoFieldNumber)
        for v in value {
            mix(v.hashValue)
        }
    }

    mutating public func visitMapField<KeyType: ProtobufMapKeyType, ValueType: ProtobufMapValueType>(fieldType: ProtobufMap<KeyType, ValueType>.Type, value: ProtobufMap<KeyType, ValueType>.BaseType, protoFieldNumber: Int, protoFieldName: String, jsonFieldName: String, swiftFieldName: String) throws where KeyType.BaseType: Hashable {
        mix(protoFieldNumber)
        // Note: When Map<Hashable,Hashable> is Hashable, this will simplify to
        // mix(value.hashValue)
        var mapHash = 0
        for (k,v) in value {
            // Note: This calculation cannot depend on the order of the items.
            mapHash += k.hashValue ^ ValueType.hash(value: v)
        }
        mix(mapHash)
    }
}
