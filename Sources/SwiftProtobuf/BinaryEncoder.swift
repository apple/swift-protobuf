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

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

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

    @inline(__always)
    mutating func putVarInt(value: UInt64) {
        if value < 0x80 {
            pointer.storeBytes(of: UInt8(truncatingIfNeeded: value), as: UInt8.self)
            pointer += 1
        } else {
            pointer = Self.putVarIntSlow(value, to: pointer)
        }
    }

    mutating func putVarInt(value: Int64) {
        putVarInt(value: UInt64(bitPattern: value))
    }

    mutating func putVarInt(value: Int) {
        putVarInt(value: Int64(value))
    }

    mutating func putZigZagVarInt(value: Int64) {
        let coded = UInt64(zigZagEncoded: value)
        putVarInt(value: coded)
    }

    /// Writes a field tag followed by a varint value (or length-delimited byte count).
    ///
    /// Fusing the common 1-byte tag and 1-byte value case into a single `(rawTag | value) < 0x80`
    /// check, one 2-byte store, and one cold fallback avoids back-to-back branches, duplicate cold
    /// calls, and callee-saved register spills across `MessageStorage` and `ExtensionStorage`.
    @inline(__always)
    internal mutating func putFieldVarInt(tag: FieldTag, value: UInt64) {
        let rawTag = UInt64(tag.rawValue)
        if (rawTag | value) < 0x80 {
            let pair = UInt16(truncatingIfNeeded: rawTag | (value << 8))
            pointer.storeBytes(of: pair.littleEndian, as: UInt16.self)
            pointer += 2
        } else {
            pointer = Self.putTagAndVarIntSlow(rawTag, value, to: pointer)
        }
    }

    internal mutating func putFieldVarInt(tag: FieldTag, value: Int) {
        putFieldVarInt(tag: tag, value: UInt64(bitPattern: Int64(value)))
    }

    @inline(__always)
    internal mutating func putFieldVarInt(fieldNumber: Int, wireFormat: WireFormat, value: UInt64) {
        putFieldVarInt(tag: FieldTag(fieldNumber: fieldNumber, wireFormat: wireFormat), value: value)
    }

    internal mutating func putFieldVarInt(fieldNumber: Int, wireFormat: WireFormat, value: Int64) {
        putFieldVarInt(
            fieldNumber: fieldNumber,
            wireFormat: wireFormat,
            value: UInt64(bitPattern: value)
        )
    }

    internal mutating func putFieldVarInt(fieldNumber: Int, wireFormat: WireFormat, value: Int) {
        putFieldVarInt(
            fieldNumber: fieldNumber,
            wireFormat: wireFormat,
            value: UInt64(bitPattern: Int64(value))
        )
    }

    /// Outlined slow path for multi-byte varints (`value >= 0x80`).
    ///
    /// Taking and returning the write pointer via a `private static` function rather than a
    /// `mutating` method preserves caller SROA on `BinaryEncoder` and avoids `inout self`
    /// pointer-alias reloads across the cold call. Encodes two 7-bit groups per iteration and
    /// writes exact `Varint.encodedSize` bytes because `MessageStorage.serializedBytes` allocates
    /// exact `requiredSize` bytes with zero trailing slop.
    @inline(never)
    private static func putVarIntSlow(
        _ value: UInt64,
        to pointer: UnsafeMutableRawPointer
    ) -> UnsafeMutableRawPointer {
        var v = value
        var p = pointer
        while v >= 0x4000 {
            let pair = UInt16(truncatingIfNeeded: (v & 0x7f) | ((v & 0x3f80) << 1) | 0x8080)
            p.storeBytes(of: pair.littleEndian, as: UInt16.self)
            p += 2
            v >>= 14
        }
        if v >= 0x80 {
            let pair = UInt16(truncatingIfNeeded: (v & 0x7f) | ((v & 0x3f80) << 1) | 0x0080)
            p.storeBytes(of: pair.littleEndian, as: UInt16.self)
            return p + 2
        }
        p.storeBytes(of: UInt8(truncatingIfNeeded: v), as: UInt8.self)
        return p + 1
    }

    @inline(never)
    private static func putTagAndVarIntSlow(
        _ rawTag: UInt64,
        _ value: UInt64,
        to pointer: UnsafeMutableRawPointer
    ) -> UnsafeMutableRawPointer {
        let p: UnsafeMutableRawPointer
        if rawTag < 0x80 {
            pointer.storeBytes(of: UInt8(truncatingIfNeeded: rawTag), as: UInt8.self)
            p = pointer + 1
        } else {
            p = putVarIntSlow(rawTag, to: pointer)
        }
        if value < 0x80 {
            p.storeBytes(of: UInt8(truncatingIfNeeded: value), as: UInt8.self)
            return p + 1
        }
        return putVarIntSlow(value, to: p)
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

    private mutating func putFieldStringValue(fieldNumber: Int, value: String) {
        let utf8 = value.utf8
        // If the String does not support an internal representation in a form
        // of contiguous storage, body is not called and nil is returned.
        let isAvailable = utf8.withContiguousStorageIfAvailable { (body: UnsafeBufferPointer<UInt8>) -> Int in
            putFieldVarInt(fieldNumber: fieldNumber, wireFormat: .lengthDelimited, value: body.count)
            return append(contentsOf: UnsafeRawBufferPointer(body))
        }
        if isAvailable == nil {
            let count = utf8.count
            putFieldVarInt(fieldNumber: fieldNumber, wireFormat: .lengthDelimited, value: count)
            for b in utf8 {
                pointer.storeBytes(of: b, as: UInt8.self)
                pointer += 1
            }
        }
    }

    mutating func putBytesValue<Bytes: SwiftProtobufContiguousBytes>(value: Bytes) {
        putVarInt(value: value.count)
        append(contentsOf: value)
    }

    private mutating func putFieldBytesValue<Bytes: SwiftProtobufContiguousBytes>(
        fieldNumber: Int,
        value: Bytes
    ) {
        putFieldVarInt(fieldNumber: fieldNumber, wireFormat: .lengthDelimited, value: value.count)
        append(contentsOf: value)
    }
}

// Higher-level serialization methods shared by both `MessageStorage` and `ExtensionStorage`.
extension BinaryEncoder {
    /// Serializes the field tag and value for a singular or unpacked `bool` field.
    @inline(__always)
    mutating func serializeBoolField(_ value: Bool, for fieldNumber: Int) {
        putFieldVarInt(fieldNumber: fieldNumber, wireFormat: .varint, value: UInt64(value ? 1 : 0))
    }

    /// Serializes the field tag and value for a singular `bytes` field.
    @inline(__always)
    mutating func serializeBytesField(_ value: Data, for fieldNumber: Int) {
        putFieldBytesValue(fieldNumber: fieldNumber, value: value)
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
        putFieldVarInt(fieldNumber: fieldNumber, wireFormat: .varint, value: UInt64(bitPattern: Int64(value)))
    }

    /// Serializes the field tag and value for a singular or unpacked `int64` field.
    @inline(__always)
    mutating func serializeInt64Field(_ value: Int64, for fieldNumber: Int) {
        putFieldVarInt(fieldNumber: fieldNumber, wireFormat: .varint, value: UInt64(bitPattern: value))
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
        putFieldVarInt(fieldNumber: fieldNumber, wireFormat: .varint, value: UInt64(UInt32(zigZagEncoded: value)))
    }

    /// Serializes the field tag and value for a singular or unpacked `sint64` field.
    @inline(__always)
    mutating func serializeSInt64Field(_ value: Int64, for fieldNumber: Int) {
        putFieldVarInt(fieldNumber: fieldNumber, wireFormat: .varint, value: UInt64(zigZagEncoded: value))
    }

    /// Serializes the field tag and value for a singular `string` field.
    @inline(__always)
    mutating func serializeStringField(_ value: String, for fieldNumber: Int) {
        putFieldStringValue(fieldNumber: fieldNumber, value: value)
    }

    /// Serializes the field tag and value for a singular or unpacked `uint32` field.
    @inline(__always)
    mutating func serializeUInt32Field(_ value: UInt32, for fieldNumber: Int) {
        putFieldVarInt(fieldNumber: fieldNumber, wireFormat: .varint, value: UInt64(value))
    }

    /// Serializes the field tag and value for a singular or unpacked `uint64` field.
    @inline(__always)
    mutating func serializeUInt64Field(_ value: UInt64, for fieldNumber: Int) {
        putFieldVarInt(fieldNumber: fieldNumber, wireFormat: .varint, value: value)
    }

    /// Serializes a packed repeated field of fixed-size values by writing the tag and
    /// length-delimited prefix, then calls the given closure to encode the individual values
    /// themselves.
    mutating func serializePackedFixedField<T>(
        _ values: [T],
        for fieldNumber: Int,
        encode: (T, inout BinaryEncoder) -> Void
    ) {
        putFieldVarInt(
            fieldNumber: fieldNumber,
            wireFormat: .lengthDelimited,
            value: values.count * MemoryLayout<T>.size
        )
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
        var length = 0
        for value in values {
            length += lengthOfElement(value)
        }
        putFieldVarInt(fieldNumber: fieldNumber, wireFormat: .lengthDelimited, value: length)
        for value in values {
            encode(value, &self)
        }
    }
}
