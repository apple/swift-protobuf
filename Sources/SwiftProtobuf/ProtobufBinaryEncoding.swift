// ProtobufRuntime/Sources/Protobuf/ProtobufBinaryEncoding.swift - Binary encoding support
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

struct ProtobufBinaryEncodingVisitor: ProtobufVisitor {
    private var encoder: ProtobufBinaryEncoder

    init(message: ProtobufMessageBase, pointer: UnsafeMutablePointer<UInt8>) throws {
        encoder = ProtobufBinaryEncoder(pointer: pointer)
        try withAbstractVisitor {(visitor: inout ProtobufVisitor) in
            try message.traverse(visitor: &visitor)
        }
    }

    mutating func withAbstractVisitor(clause: (inout ProtobufVisitor) throws ->()) throws {
        var visitor: ProtobufVisitor = self
        try clause(&visitor)
        encoder = (visitor as! ProtobufBinaryEncodingVisitor).encoder
    }

    mutating func visitUnknown(bytes: [UInt8]) {
        encoder.appendUnknown(bytes: bytes)
    }

    mutating func visitSingularField<S: ProtobufTypeProperties>(fieldType: S.Type, value: S.BaseType, protoFieldNumber: Int, protoFieldName: String, jsonFieldName: String, swiftFieldName: String) throws {
        encoder.startField(tagType: protoFieldNumber * 8 + S.protobufWireType())
        try S.serializeProtobufValue(encoder: &encoder, value: value)
    }

    mutating func visitRepeatedField<S: ProtobufTypeProperties>(fieldType: S.Type, value: [S.BaseType], protoFieldNumber: Int, protoFieldName: String, jsonFieldName: String, swiftFieldName: String) throws {
        for v in value {
            encoder.startField(tagType: protoFieldNumber * 8 + S.protobufWireType())
            try S.serializeProtobufValue(encoder: &encoder, value: v)
        }
    }

    mutating func visitPackedField<S: ProtobufTypeProperties>(fieldType: S.Type, value: [S.BaseType], protoFieldNumber: Int, protoFieldName: String, jsonFieldName: String, swiftFieldName: String) throws {
        encoder.startField(tagType: protoFieldNumber * 8 + 2)
        var packedSize = 0
        for v in value {
            packedSize += try S.encodedSizeWithoutTag(of: v)
        }
        encoder.putVarInt(value: packedSize)
        for v in value {
            try S.serializeProtobufValue(encoder: &encoder, value: v)
        }
    }

    mutating func visitSingularMessageField<M: ProtobufMessage>(value: M, protoFieldNumber: Int, protoFieldName: String, jsonFieldName: String, swiftFieldName: String) throws {
        let t = try value.serializeProtobuf()
        encoder.startField(tagType: protoFieldNumber * 8 + M.protobufWireType())
        encoder.putBytesValue(value: t)
    }

    mutating func visitRepeatedMessageField<M: ProtobufMessage>(value: [M], protoFieldNumber: Int, protoFieldName: String, jsonFieldName: String, swiftFieldName: String) throws {
        for v in value {
            let t = try v.serializeProtobuf()
            encoder.startField(tagType: protoFieldNumber * 8 + M.protobufWireType())
            encoder.putBytesValue(value: t)
        }
    }

    mutating func visitSingularGroupField<G: ProtobufMessage>(value: G, protoFieldNumber: Int, protoFieldName: String, jsonFieldName: String, swiftFieldName: String) throws {
        encoder.startField(tagType: protoFieldNumber * 8 + 3) // Start of group
        try withAbstractVisitor {(visitor: inout ProtobufVisitor) in
            try value.traverse(visitor: &visitor)
        }
        encoder.startField(tagType: protoFieldNumber * 8 + 4) // End of group
    }

    mutating func visitRepeatedGroupField<G: ProtobufMessage>(value: [G], protoFieldNumber: Int, protoFieldName: String, jsonFieldName: String, swiftFieldName: String) throws {
        for v in value {
            encoder.startField(tagType: protoFieldNumber * 8 + 3) // Start of group
            try withAbstractVisitor {(visitor: inout ProtobufVisitor) in
                try v.traverse(visitor: &visitor)
            }
            encoder.startField(tagType: protoFieldNumber * 8 + 4) // End of group
        }
    }

    mutating func visitMapField<KeyType: ProtobufMapKeyType, ValueType: ProtobufMapValueType>(fieldType: ProtobufMap<KeyType, ValueType>.Type, value: ProtobufMap<KeyType, ValueType>.BaseType, protoFieldNumber: Int, protoFieldName: String, jsonFieldName: String, swiftFieldName: String) throws where KeyType.BaseType: Hashable {
        for (k,v) in value {
            encoder.startField(tagType: protoFieldNumber * 8 + 2)
            let keyTagSize = Varint.encodedSize(of: UInt32(truncatingBitPattern: 1 << 3))
            let valueTagSize = Varint.encodedSize(of: UInt32(truncatingBitPattern: 2 << 3))
            let entrySize = try keyTagSize + KeyType.encodedSizeWithoutTag(of: k) + valueTagSize + ValueType.encodedSizeWithoutTag(of: v)
            encoder.putVarInt(value: entrySize)
            encoder.startField(tagType: 8 + KeyType.protobufWireType())
            KeyType.serializeProtobufValue(encoder: &encoder, value: k)
            encoder.startField(tagType: 16 + ValueType.protobufWireType())
            // Note: ValueType could be a message, so messages need
            // static func serializeProtobufValue(...)
            // TODO: Could we traverse the valuetype instead?
            // TODO: Propagate failure out of here...
            try ValueType.serializeProtobufValue(encoder: &encoder, value: v)
        }
    }
}

/*
 * Encoder for Binary Protocol Buffer format
 *
 * TODO: Should this be a class?
 */
public struct ProtobufBinaryEncoder {
    private var pointer: UnsafeMutablePointer<UInt8>

    public init(pointer: UnsafeMutablePointer<UInt8>) {
        self.pointer = pointer
    }

    private mutating func append(_ byte: UInt8) {
        pointer.pointee = byte
        pointer = pointer.successor()
    }

    private mutating func append(contentsOf bytes: [UInt8]) {
        let count = bytes.count
        bytes.withUnsafeBufferPointer { source in
            self.pointer.assign(from: source.baseAddress!, count: count)
        }
        pointer = pointer.advanced(by: count)
    }

    private mutating func append(contentsOf bufferPointer: UnsafeBufferPointer<UInt8>) {
        let count = bufferPointer.count
        pointer.assign(from: bufferPointer.baseAddress!, count: count)
        pointer = pointer.advanced(by: count)
    }

    public mutating func appendUnknown(bytes: [UInt8]) {
        append(contentsOf: bytes)
    }

    mutating func startField(tagType: Int) {
        putVarInt(value: UInt64(tagType))
    }

    mutating func putVarInt(value: UInt64) {
        var v = value
        while v > 127 {
            append(UInt8(v & 0x7f | 0x80))
            v >>= 7
        }
        append(UInt8(v))
    }

    mutating func putVarInt(value: Int64) {
        putVarInt(value: UInt64(bitPattern: value))
    }

    mutating func putVarInt(value: Int) {
        putVarInt(value: Int64(value))
    }

    mutating func putZigZagVarInt(value: Int64) {
        let coded = ZigZag.encoded(value)
        putVarInt(value: coded)
    }

    mutating func putBoolValue(value: Bool) {
        append(value ? 1 : 0)
    }

    mutating func putFixedUInt64(value : UInt64) {
        var v = value
        let n = MemoryLayout<UInt64>.size
        withUnsafePointer(to: &v) { v -> () in
            v.withMemoryRebound(to: UInt8.self, capacity: n) { p -> () in
                let buff = UnsafeBufferPointer<UInt8>(start: p, count: n)
                append(contentsOf: buff)
            }
        }
    }

    mutating func putFixedUInt32(value : UInt32) {
        var v = value
        let n = MemoryLayout<UInt32>.size
        withUnsafePointer(to: &v) { v -> () in
            v.withMemoryRebound(to: UInt8.self, capacity: n) { p -> () in
                let buff = UnsafeBufferPointer<UInt8>(start: p, count: n)
                append(contentsOf: buff)
            }
        }
    }

    mutating func putFloatValue(value: Float) {
        var v = value
        let n = MemoryLayout<Float>.size
        withUnsafePointer(to: &v) { v -> () in
            v.withMemoryRebound(to: UInt8.self, capacity: n) { p -> () in
                let buff = UnsafeBufferPointer<UInt8>(start: p, count: n)
                append(contentsOf: buff)
            }
        }
    }

    mutating func putDoubleValue(value: Double) {
        var v = value
        let n = MemoryLayout<Double>.size
        withUnsafePointer(to: &v) { v -> () in
            v.withMemoryRebound(to: UInt8.self, capacity: n) { p -> () in
                let buff = UnsafeBufferPointer<UInt8>(start: p, count: n)
                append(contentsOf: buff)
            }
        }
    }

    // Write a string field, including the leading index/tag value.
    mutating func putStringValue(value: String) {
        let stringWithNul = value.utf8CString
        let stringLength = stringWithNul.count - 1
        putVarInt(value: stringLength)
        if stringLength > 0 {
            // TODO: There has got to be a better way to do this...
            stringWithNul.withUnsafeBufferPointer { bp -> () in
                bp.baseAddress?.withMemoryRebound(to: UInt8.self, capacity: stringLength) { p -> () in
                    let stringWithoutNul = UnsafeBufferPointer<UInt8>(start: p, count: stringLength)
                    append(contentsOf: stringWithoutNul)
                }
            }
        }
    }

    mutating func putBytesValue(value: [UInt8]) {
        putVarInt(value: value.count)
        append(contentsOf: value)
    }

    mutating func putBytesValue(value: Data) {
        let bytes = [UInt8](value)
        putVarInt(value: bytes.count)
        append(contentsOf: bytes)
    }
}
