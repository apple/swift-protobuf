// Sources/SwiftProtobuf/ProtobufEncodingVisitor.swift - Binary encoding support
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
/// Core support for protobuf binary encoding.  Note that this is built
/// on the general traversal machinery.
///
// -----------------------------------------------------------------------------

import Foundation
import Swift

struct ProtobufEncodingVisitor: Visitor {
    private var encoder: ProtobufEncoder
    
    init(message: Message, pointer: UnsafeMutablePointer<UInt8>) throws {
        encoder = ProtobufEncoder(pointer: pointer)
        try withAbstractVisitor {(visitor: inout Visitor) in
            try message.traverse(visitor: &visitor)
        }
    }
    
    mutating func withAbstractVisitor(clause: (inout Visitor) throws ->()) throws {
        var visitor: Visitor = self
        try clause(&visitor)
        encoder = (visitor as! ProtobufEncodingVisitor).encoder
    }
    
    mutating func visitUnknown(bytes: Data) {
        encoder.appendUnknown(data: bytes)
    }
    
    mutating func visitSingularField<S: FieldType>(fieldType: S.Type, value: S.BaseType, protoFieldNumber: Int, protoFieldName: String, jsonFieldName: String, swiftFieldName: String) throws {
        encoder.startField(fieldNumber: protoFieldNumber, wireFormat: S.protobufWireFormat)
        S.serializeProtobufValue(encoder: &encoder, value: value)
    }
    
    mutating func visitRepeatedField<S: FieldType>(fieldType: S.Type, value: [S.BaseType], protoFieldNumber: Int, protoFieldName: String, jsonFieldName: String, swiftFieldName: String) throws {
        for v in value {
            encoder.startField(fieldNumber: protoFieldNumber, wireFormat: S.protobufWireFormat)
            S.serializeProtobufValue(encoder: &encoder, value: v)
        }
    }
    
    mutating func visitPackedField<S: FieldType>(fieldType: S.Type, value: [S.BaseType], protoFieldNumber: Int, protoFieldName: String, jsonFieldName: String, swiftFieldName: String) throws {
        encoder.startField(fieldNumber: protoFieldNumber, wireFormat: .lengthDelimited)
        var packedSize = 0
        for v in value {
            packedSize += try S.encodedSizeWithoutTag(of: v)
        }
        encoder.putVarInt(value: packedSize)
        for v in value {
            S.serializeProtobufValue(encoder: &encoder, value: v)
        }
    }
    
    mutating func visitSingularMessageField<M: Message>(value: M, protoFieldNumber: Int, protoFieldName: String, jsonFieldName: String, swiftFieldName: String) throws {
        let t = try value.serializeProtobuf()
        encoder.startField(fieldNumber: protoFieldNumber, wireFormat: M.protobufWireFormat)
        encoder.putBytesValue(value: t)
    }
    
    mutating func visitRepeatedMessageField<M: Message>(value: [M], protoFieldNumber: Int, protoFieldName: String, jsonFieldName: String, swiftFieldName: String) throws {
        for v in value {
            let t = try v.serializeProtobuf()
            encoder.startField(fieldNumber: protoFieldNumber, wireFormat: M.protobufWireFormat)
            encoder.putBytesValue(value: t)
        }
    }
    
    mutating func visitSingularGroupField<G: Message>(value: G, protoFieldNumber: Int, protoFieldName: String, jsonFieldName: String, swiftFieldName: String) throws {
        encoder.startField(fieldNumber: protoFieldNumber, wireFormat: .startGroup)
        try withAbstractVisitor {(visitor: inout Visitor) in
            try value.traverse(visitor: &visitor)
        }
        encoder.startField(fieldNumber: protoFieldNumber, wireFormat: .endGroup)
    }
    
    mutating func visitRepeatedGroupField<G: Message>(value: [G], protoFieldNumber: Int, protoFieldName: String, jsonFieldName: String, swiftFieldName: String) throws {
        for v in value {
            encoder.startField(fieldNumber: protoFieldNumber, wireFormat: .startGroup)
            try withAbstractVisitor {(visitor: inout Visitor) in
                try v.traverse(visitor: &visitor)
            }
            encoder.startField(fieldNumber: protoFieldNumber, wireFormat: .endGroup)
        }
    }
    
    mutating func visitMapField<KeyType: MapKeyType, ValueType: MapValueType>(fieldType: ProtobufMap<KeyType, ValueType>.Type, value: ProtobufMap<KeyType, ValueType>.BaseType, protoFieldNumber: Int, protoFieldName: String, jsonFieldName: String, swiftFieldName: String) throws where KeyType.BaseType: Hashable {
        for (k,v) in value {
            encoder.startField(fieldNumber: protoFieldNumber, wireFormat: .lengthDelimited)
            let keyTagSize = Varint.encodedSize(of: UInt32(truncatingBitPattern: 1 << 3))
            let valueTagSize = Varint.encodedSize(of: UInt32(truncatingBitPattern: 2 << 3))
            let entrySize = try keyTagSize + KeyType.encodedSizeWithoutTag(of: k) + valueTagSize + ValueType.encodedSizeWithoutTag(of: v)
            encoder.putVarInt(value: entrySize)
            encoder.startField(fieldNumber: 1, wireFormat: KeyType.protobufWireFormat)
            KeyType.serializeProtobufValue(encoder: &encoder, value: k)
            encoder.startField(fieldNumber: 2, wireFormat: ValueType.protobufWireFormat)
            // Note: ValueType could be a message, so messages need
            // static func serializeProtobufValue(...)
            // TODO: Could we traverse the valuetype instead?
            // TODO: Propagate failure out of here...
            ValueType.serializeProtobufValue(encoder: &encoder, value: v)
        }
    }
}
