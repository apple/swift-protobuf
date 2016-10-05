// SwiftProtobufRuntime/Sources/SwiftProtobuf/ProtobufBinarySizeVisitor.swift - Binary size calculation support
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
/// Visitor used during binary encoding that precalcuates the size of a
/// serialized message.
///
// -----------------------------------------------------------------------------

import Foundation

/// Visitor that calculates the binary-encoded size of a message so that a properly sized `Data` or
/// `UInt8` array can be pre-allocated before serialization.
struct ProtobufBinarySizeVisitor: ProtobufVisitor {

    /// Accumulates the required size of the message during traversal.
    var serializedSize: Int = 0

    init(message: ProtobufMessageBase) throws {
        try withAbstractVisitor {(visitor: inout ProtobufVisitor) in
            try message.traverse(visitor: &visitor)
        }
    }

    mutating func withAbstractVisitor(clause: (inout ProtobufVisitor) throws ->()) throws {
        var visitor: ProtobufVisitor = self
        try clause(&visitor)
        serializedSize = (visitor as! ProtobufBinarySizeVisitor).serializedSize
    }

    mutating func visitUnknown(bytes: [UInt8]) {
        serializedSize += bytes.count
    }

    mutating func visitSingularField<S: ProtobufTypeProperties>(fieldType: S.Type, value: S.BaseType, protoFieldNumber: Int, protoFieldName: String, jsonFieldName: String, swiftFieldName: String) throws {
        let tagSize = Varint.encodedSize(of: UInt32(
            truncatingBitPattern: protoFieldNumber << 3 | S.protobufWireType()))
        serializedSize += try tagSize + S.encodedSizeWithoutTag(of: value)
    }

    mutating func visitRepeatedField<S: ProtobufTypeProperties>(fieldType: S.Type, value: [S.BaseType], protoFieldNumber: Int, protoFieldName: String, jsonFieldName: String, swiftFieldName: String) throws {
        let tagSize = Varint.encodedSize(of: UInt32(
            truncatingBitPattern: protoFieldNumber << 3 | S.protobufWireType()))
        serializedSize += value.count * tagSize
        for v in value {
            serializedSize += try S.encodedSizeWithoutTag(of: v)
        }
    }

    mutating func visitPackedField<S: ProtobufTypeProperties>(fieldType: S.Type, value: [S.BaseType], protoFieldNumber: Int, protoFieldName: String, jsonFieldName: String, swiftFieldName: String) throws {
        guard !value.isEmpty else {
            return
        }

        let tagSize = Varint.encodedSize(of: UInt32(
            truncatingBitPattern: protoFieldNumber << 3 | S.protobufWireType()))
        var dataSize = 0
        for v in value {
            dataSize += try S.encodedSizeWithoutTag(of: v)
        }
        serializedSize += tagSize + Varint.encodedSize(of: Int64(dataSize)) + dataSize
    }

    mutating func visitSingularMessageField<M: ProtobufMessage>(value: M, protoFieldNumber: Int, protoFieldName: String, jsonFieldName: String, swiftFieldName: String) throws {
        let tagSize = Varint.encodedSize(of: UInt32(
            truncatingBitPattern: protoFieldNumber << 3 | M.protobufWireType()))
        let messageSize = try value.serializedProtobufSize()
        serializedSize += tagSize + Varint.encodedSize(of: UInt64(messageSize)) + messageSize
    }

    mutating func visitRepeatedMessageField<M: ProtobufMessage>(value: [M], protoFieldNumber: Int, protoFieldName: String, jsonFieldName: String, swiftFieldName: String) throws {
        let tagSize = Varint.encodedSize(of: UInt32(
            truncatingBitPattern: protoFieldNumber << 3 | M.protobufWireType()))
        serializedSize += value.count * tagSize
        for v in value {
            let messageSize = try v.serializedProtobufSize()
            serializedSize += Varint.encodedSize(of: UInt64(messageSize)) + messageSize
        }
    }

    mutating func visitSingularGroupField<G: ProtobufGroup>(value: G, protoFieldNumber: Int, protoFieldName: String, jsonFieldName: String, swiftFieldName: String) throws {
        // The wire format doesn't matter here because the encoded size of the integer won't change
        // based on the low three bits.
        let tagSize = Varint.encodedSize(of: UInt32(truncatingBitPattern: protoFieldNumber << 3))
        serializedSize += 2 * tagSize
        try withAbstractVisitor {(visitor: inout ProtobufVisitor) in
            try value.traverse(visitor: &visitor)
        }
    }

    mutating func visitRepeatedGroupField<G: ProtobufGroup>(value: [G], protoFieldNumber: Int, protoFieldName: String, jsonFieldName: String, swiftFieldName: String) throws {
        let tagSize = Varint.encodedSize(of: UInt32(truncatingBitPattern: protoFieldNumber << 3))
        serializedSize += 2 * value.count * tagSize
        for v in value {
            try withAbstractVisitor {(visitor: inout ProtobufVisitor) in
                try v.traverse(visitor: &visitor)
            }
        }
    }

    mutating func visitMapField<KeyType: ProtobufMapKeyType, ValueType: ProtobufMapValueType>(fieldType: ProtobufMap<KeyType, ValueType>.Type, value: ProtobufMap<KeyType, ValueType>.BaseType, protoFieldNumber: Int, protoFieldName: String, jsonFieldName: String, swiftFieldName: String) throws where KeyType.BaseType: Hashable {
        let tagSize = Varint.encodedSize(of: UInt32(truncatingBitPattern: protoFieldNumber << 3))
        let keyTagSize = Varint.encodedSize(of: UInt32(truncatingBitPattern: 1 << 3))
        let valueTagSize = Varint.encodedSize(of: UInt32(truncatingBitPattern: 2 << 3))
        for (k,v) in value {
            let entrySize = try keyTagSize + KeyType.encodedSizeWithoutTag(of: k) + valueTagSize + ValueType.encodedSizeWithoutTag(of: v)
            serializedSize += entrySize + Varint.encodedSize(of: Int64(entrySize))
        }
        serializedSize += value.count * tagSize
    }
}
