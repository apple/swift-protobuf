// Sources/SwiftProtobuf/BinaryEncoder.swift - Binary encoding support
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Core support for protobuf binary encoding.  Note that this is built
/// on the general traversal machinery.
///
// -----------------------------------------------------------------------------

import Foundation

/// Encoder for Binary Protocol Buffer format
internal struct BinaryEncoder {
    private var pointer: UnsafeMutableRawPointer
    private var buffer: UnsafeMutableRawBufferPointer

    init(forWritingInto buffer: UnsafeMutableRawBufferPointer) {
        self.buffer = buffer
        self.pointer = buffer.baseAddress!
    }

    private mutating func append(_ byte: UInt8) {
        pointer.storeBytes(of: byte, as: UInt8.self)
        pointer = pointer.advanced(by: 1)
    }

    private mutating func append<Bytes: SwiftProtobufContiguousBytes>(contentsOf bytes: Bytes) {
        bytes.withUnsafeBytes { dataPointer in
            if let baseAddress = dataPointer.baseAddress, dataPointer.count > 0 {
                pointer.copyMemory(from: baseAddress, byteCount: dataPointer.count)
                advance(dataPointer.count)
            }
        }
    }

    internal var used: Int {
        buffer.baseAddress!.distance(to: pointer)
    }

    internal var remainder: UnsafeMutableRawBufferPointer {
        UnsafeMutableRawBufferPointer(
            start: pointer,
            count: buffer.count - used
        )
    }

    internal mutating func advance(_ bytes: Int) {
        pointer = pointer.advanced(by: bytes)
    }

    @discardableResult
    private mutating func append(contentsOf bufferPointer: UnsafeRawBufferPointer) -> Int {
        let count = bufferPointer.count
        if let baseAddress = bufferPointer.baseAddress, count > 0 {
            pointer.copyMemory(from: baseAddress, byteCount: count)
        }
        pointer = pointer.advanced(by: count)
        return count
    }

    mutating func appendUnknown(data: Data) {
        append(contentsOf: data)
    }

    mutating func startField(fieldNumber: Int, wireFormat: WireFormat) {
        startField(tag: FieldTag(fieldNumber: fieldNumber, wireFormat: wireFormat))
    }

    mutating func startField(tag: FieldTag) {
        putVarInt(value: UInt64(tag.rawValue))
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

    mutating func putFixedUInt64(value: UInt64) {
        var v = value.littleEndian
        let n = MemoryLayout<UInt64>.size
        pointer.copyMemory(from: &v, byteCount: n)
        pointer = pointer.advanced(by: n)
    }

    mutating func putFixedUInt32(value: UInt32) {
        var v = value.littleEndian
        let n = MemoryLayout<UInt32>.size
        pointer.copyMemory(from: &v, byteCount: n)
        pointer = pointer.advanced(by: n)
    }

    mutating func putFloatValue(value: Float) {
        let n = MemoryLayout<Float>.size
        var v = value.bitPattern.littleEndian
        pointer.copyMemory(from: &v, byteCount: n)
        pointer = pointer.advanced(by: n)
    }

    mutating func putDoubleValue(value: Double) {
        let n = MemoryLayout<Double>.size
        var v = value.bitPattern.littleEndian
        pointer.copyMemory(from: &v, byteCount: n)
        pointer = pointer.advanced(by: n)
    }

    // Write a string field, including the leading index/tag value.
    mutating func putStringValue(value: String) {
        let utf8 = value.utf8
        // If the String does not support an internal representation in a form
        // of contiguous storage, body is not called and nil is returned.
        let isAvailable = utf8.withContiguousStorageIfAvailable { (body: UnsafeBufferPointer<UInt8>) -> Int in
            putVarInt(value: body.count)
            return append(contentsOf: UnsafeRawBufferPointer(body))
        }
        if isAvailable == nil {
            let count = utf8.count
            putVarInt(value: count)
            for b in utf8 {
                pointer.storeBytes(of: b, as: UInt8.self)
                pointer = pointer.advanced(by: 1)
            }
        }
    }

    mutating func putBytesValue<Bytes: SwiftProtobufContiguousBytes>(value: Bytes) {
        putVarInt(value: value.count)
        append(contentsOf: value)
    }
}

// Higher-level serialization methods shared by both `MessageStorage` and `ExtensionStorage`.
extension BinaryEncoder {
    /// Serializes the field tag and value for a singular or unpacked `bool` field.
    @inline(__always)
    mutating func serializeBoolField(_ value: Bool, for fieldNumber: Int) {
        startField(fieldNumber: fieldNumber, wireFormat: .varint)
        putVarInt(value: value ? 1 : 0)
    }

    /// Serializes the field tag and value for a singular `bytes` field.
    @inline(__always)
    mutating func serializeBytesField(_ value: Data, for fieldNumber: Int) {
        startField(fieldNumber: fieldNumber, wireFormat: .lengthDelimited)
        putBytesValue(value: value)
    }

    /// Serializes the field tag and value for a singular or unpacked `double` field.
    @inline(__always)
    mutating func serializeDoubleField(_ value: Double, for fieldNumber: Int) {
        startField(fieldNumber: fieldNumber, wireFormat: .fixed64)
        putDoubleValue(value: value)
    }

    /// Serializes the field tag and value for a singular or unpacked `fixed32` field.
    @inline(__always)
    mutating func serializeFixed32Field(_ value: UInt32, for fieldNumber: Int) {
        startField(fieldNumber: fieldNumber, wireFormat: .fixed32)
        putFixedUInt32(value: value)
    }

    /// Serializes the field tag and value for a singular or unpacked `fixed64` field.
    @inline(__always)
    mutating func serializeFixed64Field(_ value: UInt64, for fieldNumber: Int) {
        startField(fieldNumber: fieldNumber, wireFormat: .fixed64)
        putFixedUInt64(value: value)
    }

    /// Serializes the field tag and value for a singular or unpacked `float` field.
    @inline(__always)
    mutating func serializeFloatField(_ value: Float, for fieldNumber: Int) {
        startField(fieldNumber: fieldNumber, wireFormat: .fixed32)
        putFloatValue(value: value)
    }

    /// Serializes the field tag and value for a singular or unpacked `int32` field.
    @inline(__always)
    mutating func serializeInt32Field(_ value: Int32, for fieldNumber: Int) {
        startField(fieldNumber: fieldNumber, wireFormat: .varint)
        putVarInt(value: UInt64(bitPattern: Int64(value)))
    }

    /// Serializes the field tag and value for a singular or unpacked `int64` field.
    @inline(__always)
    mutating func serializeInt64Field(_ value: Int64, for fieldNumber: Int) {
        startField(fieldNumber: fieldNumber, wireFormat: .varint)
        putVarInt(value: UInt64(bitPattern: value))
    }

    /// Serializes the field tag and value for a singular or unpacked `sfixed32` field.
    @inline(__always)
    mutating func serializeSFixed32Field(_ value: Int32, for fieldNumber: Int) {
        startField(fieldNumber: fieldNumber, wireFormat: .fixed32)
        putFixedUInt32(value: UInt32(bitPattern: value))
    }

    /// Serializes the field tag and value for a singular or unpacked `sfixed64` field.
    @inline(__always)
    mutating func serializeSFixed64Field(_ value: Int64, for fieldNumber: Int) {
        startField(fieldNumber: fieldNumber, wireFormat: .fixed64)
        putFixedUInt64(value: UInt64(bitPattern: value))
    }

    /// Serializes the field tag and value for a singular or unpacked `sint32` field.
    @inline(__always)
    mutating func serializeSInt32Field(_ value: Int32, for fieldNumber: Int) {
        startField(fieldNumber: fieldNumber, wireFormat: .varint)
        putVarInt(value: UInt64(ZigZag.encoded(value)))
    }

    /// Serializes the field tag and value for a singular or unpacked `sint64` field.
    @inline(__always)
    mutating func serializeSInt64Field(_ value: Int64, for fieldNumber: Int) {
        startField(fieldNumber: fieldNumber, wireFormat: .varint)
        putVarInt(value: ZigZag.encoded(value))
    }

    /// Serializes the field tag and value for a singular `string` field.
    @inline(__always)
    mutating func serializeStringField(_ value: String, for fieldNumber: Int) {
        startField(fieldNumber: fieldNumber, wireFormat: .lengthDelimited)
        putStringValue(value: value)
    }

    /// Serializes the field tag and value for a singular or unpacked `uint32` field.
    @inline(__always)
    mutating func serializeUInt32Field(_ value: UInt32, for fieldNumber: Int) {
        startField(fieldNumber: fieldNumber, wireFormat: .varint)
        putVarInt(value: UInt64(value))
    }

    /// Serializes the field tag and value for a singular or unpacked `uint64` field.
    @inline(__always)
    mutating func serializeUInt64Field(_ value: UInt64, for fieldNumber: Int) {
        startField(fieldNumber: fieldNumber, wireFormat: .varint)
        putVarInt(value: value)
    }

    /// Serializes a packed repeated field of fixed-size values by writing the tag and
    /// length-delimited prefix, then calls the given closure to encode the individual values
    /// themselves.
    mutating func serializePackedFixedField<T>(
        _ values: [T],
        for fieldNumber: Int,
        encode: (T, inout BinaryEncoder) -> Void
    ) {
        startField(fieldNumber: fieldNumber, wireFormat: .lengthDelimited)
        putVarInt(value: values.count * MemoryLayout<T>.size)
        for value in values {
            encode(value, &self)
        }
    }

    /// Serializes a packed repeated field of varints by writing the tag and length-delimited
    /// prefix, then calls the given closure to encode the individual values themselves.
    mutating func serializePackedVarintsField<T>(
        _ values: [T],
        for fieldNumber: Int,
        encode: (T, inout BinaryEncoder) -> Void,
        lengthOfElement: (T) -> Int
    ) {
        startField(fieldNumber: fieldNumber, wireFormat: .lengthDelimited)
        var length = 0
        for value in values {
            length += lengthOfElement(value)
        }
        putVarInt(value: length)
        for value in values {
            encode(value, &self)
        }
    }
}
