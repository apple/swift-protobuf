// Sources/SwiftProtobuf/ProtobufEncodingSizeVisitor.swift - Binary size calculation support
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
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
struct ProtobufEncodingSizeVisitor: Visitor {

    /// Accumulates the required size of the message during traversal.
    var serializedSize: Int = 0

    init(message: Message) throws {
        try withAbstractVisitor {(visitor: inout Visitor) in
            try message.traverse(visitor: &visitor)
        }
    }

    mutating func withAbstractVisitor(clause: (inout Visitor) throws ->()) throws {
        var visitor: Visitor = self
        try clause(&visitor)
        serializedSize = (visitor as! ProtobufEncodingSizeVisitor).serializedSize
    }

    mutating func visitUnknown(bytes: Data) {
        serializedSize += bytes.count
    }

    mutating func visitSingularField<S: FieldType>(fieldType: S.Type, value: S.BaseType, protoFieldNumber: Int) throws {
        let tagSize = FieldTag(fieldNumber: protoFieldNumber, wireFormat: S.protobufWireFormat).encodedSize
        serializedSize += try tagSize + S.encodedSizeWithoutTag(of: value)
    }

    mutating func visitRepeatedField<S: FieldType>(fieldType: S.Type, value: [S.BaseType], protoFieldNumber: Int) throws {
        let tagSize = FieldTag(fieldNumber: protoFieldNumber, wireFormat: S.protobufWireFormat).encodedSize
        serializedSize += value.count * tagSize
        for v in value {
            serializedSize += try S.encodedSizeWithoutTag(of: v)
        }
    }

    mutating func visitPackedField<S: FieldType>(fieldType: S.Type, value: [S.BaseType], protoFieldNumber: Int) throws {
        guard !value.isEmpty else {
            return
        }

        let tagSize = FieldTag(fieldNumber: protoFieldNumber, wireFormat: S.protobufWireFormat).encodedSize
        var dataSize = 0
        for v in value {
            dataSize += try S.encodedSizeWithoutTag(of: v)
        }
        serializedSize += tagSize + Varint.encodedSize(of: Int64(dataSize)) + dataSize
    }

    mutating func visitSingularMessageField<M: Message>(value: M, protoFieldNumber: Int) throws {
        let tagSize = FieldTag(fieldNumber: protoFieldNumber, wireFormat: M.protobufWireFormat).encodedSize
        let messageSize = try value.serializedProtobufSize()
        serializedSize += tagSize + Varint.encodedSize(of: UInt64(messageSize)) + messageSize
    }

    mutating func visitRepeatedMessageField<M: Message>(value: [M], protoFieldNumber: Int) throws {
        let tagSize = FieldTag(fieldNumber: protoFieldNumber, wireFormat: M.protobufWireFormat).encodedSize
        serializedSize += value.count * tagSize
        for v in value {
            let messageSize = try v.serializedProtobufSize()
            serializedSize += Varint.encodedSize(of: UInt64(messageSize)) + messageSize
        }
    }

    mutating func visitSingularGroupField<G: Message>(value: G, protoFieldNumber: Int) throws {
        // The wire format doesn't matter here because the encoded size of the integer won't change
        // based on the low three bits.
        let tagSize = FieldTag(fieldNumber: protoFieldNumber, wireFormat: .startGroup).encodedSize
        serializedSize += 2 * tagSize
        try withAbstractVisitor {(visitor: inout Visitor) in
            try value.traverse(visitor: &visitor)
        }
    }

    mutating func visitRepeatedGroupField<G: Message>(value: [G], protoFieldNumber: Int) throws {
        let tagSize = FieldTag(fieldNumber: protoFieldNumber, wireFormat: .startGroup).encodedSize
        serializedSize += 2 * value.count * tagSize
        for v in value {
            try withAbstractVisitor {(visitor: inout Visitor) in
                try v.traverse(visitor: &visitor)
            }
        }
    }

    mutating func visitMapField<KeyType: MapKeyType, ValueType: MapValueType>(fieldType: ProtobufMap<KeyType, ValueType>.Type, value: ProtobufMap<KeyType, ValueType>.BaseType, protoFieldNumber: Int) throws where KeyType.BaseType: Hashable {
        let tagSize = FieldTag(fieldNumber: protoFieldNumber, wireFormat: .lengthDelimited).encodedSize
        let keyTagSize = FieldTag(fieldNumber: 1, wireFormat: KeyType.protobufWireFormat).encodedSize
        let valueTagSize = FieldTag(fieldNumber: 2, wireFormat: ValueType.protobufWireFormat).encodedSize
        for (k,v) in value {
            let entrySize = try keyTagSize + KeyType.encodedSizeWithoutTag(of: k) + valueTagSize + ValueType.encodedSizeWithoutTag(of: v)
            serializedSize += entrySize + Varint.encodedSize(of: Int64(entrySize))
        }
        serializedSize += value.count * tagSize
    }
}
