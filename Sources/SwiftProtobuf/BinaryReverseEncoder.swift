// Sources/SwiftProtobuf/BinaryReverseEncoder.swift - Binary encoding support
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
internal struct BinaryReverseEncoder {
    private var pointer: UnsafeMutableRawPointer
    private var buffer: UnsafeMutableRawBufferPointer

    init(forWritingInto buffer: UnsafeMutableRawBufferPointer) {
        self.buffer = buffer
        self.pointer = buffer.baseAddress! + buffer.count
    }

    private mutating func prepend(_ byte: UInt8) {
        consume(1)
        pointer.storeBytes(of: byte, as: UInt8.self)
    }

    private mutating func prepend<Bytes: SwiftProtobufContiguousBytes>(contentsOf bytes: Bytes) {
        bytes.withUnsafeBytes { dataPointer in
            if let baseAddress = dataPointer.baseAddress, dataPointer.count > 0 {
		consume(dataPointer.count)
                pointer.copyMemory(from: baseAddress, byteCount: dataPointer.count)
            }
        }
    }

    internal var used: Int {
        return pointer.distance(to: buffer.baseAddress!) + buffer.count
    }

    internal var remainder: UnsafeMutableRawBufferPointer {
        return UnsafeMutableRawBufferPointer(start: buffer.baseAddress!,
	    count: buffer.count - used)
    }

    internal mutating func consume(_ bytes: Int) {
        pointer = pointer.advanced(by: -bytes)
    }

    @discardableResult
    private mutating func prepend(contentsOf bufferPointer: UnsafeRawBufferPointer) -> Int {
        let count = bufferPointer.count
	consume(count)
        if let baseAddress = bufferPointer.baseAddress, count > 0 {
            pointer.copyMemory(from: baseAddress, byteCount: count)
        }
        return count
    }

    mutating func appendUnknown(data: Data) {
        prepend(contentsOf: data)
    }

    mutating func startField(fieldNumber: Int, wireFormat: WireFormat) {
        startField(tag: FieldTag(fieldNumber: fieldNumber, wireFormat: wireFormat))
    }

    mutating func startField(tag: FieldTag) {
        putVarInt(value: UInt64(tag.rawValue))
    }

    mutating func putVarInt(value: UInt64) {
        if value > 127 {
	    putVarInt(value: value >> 7)
            prepend(UInt8(value & 0x7f | 0x80))
        } else {
            prepend(UInt8(value))
	}
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
        prepend(value ? 1 : 0)
    }

    mutating func putFixedUInt64(value: UInt64) {
        var v = value.littleEndian
        let n = MemoryLayout<UInt64>.size
	consume(n)
        pointer.copyMemory(from: &v, byteCount: n)
    }

    mutating func putFixedUInt32(value: UInt32) {
        var v = value.littleEndian
        let n = MemoryLayout<UInt32>.size
	consume(n)
        pointer.copyMemory(from: &v, byteCount: n)
    }

    mutating func putFloatValue(value: Float) {
        let n = MemoryLayout<Float>.size
        var v = value.bitPattern.littleEndian
	consume(n)
        pointer.copyMemory(from: &v, byteCount: n)
    }

    mutating func putDoubleValue(value: Double) {
        let n = MemoryLayout<Double>.size
        var v = value.bitPattern.littleEndian
	consume(n)
        pointer.copyMemory(from: &v, byteCount: n)
    }

    // Write a string field, including the leading index/tag value.
    mutating func putStringValue(value: String) {
        let utf8 = value.utf8
        // If the String does not support an internal representation in a form
        // of contiguous storage, body is not called and nil is returned.
        let isAvailable = utf8.withContiguousStorageIfAvailable { (body: UnsafeBufferPointer<UInt8>) -> Int in
            let r = prepend(contentsOf: UnsafeRawBufferPointer(body))
            putVarInt(value: body.count)
	    return r
        }
        if isAvailable == nil {
            precondition(false)
            let count = utf8.count
            putVarInt(value: count)
            for b in utf8 {
                pointer.storeBytes(of: b, as: UInt8.self)
		consume(1)
            }
        }
    }

    mutating func putBytesValue<Bytes: SwiftProtobufContiguousBytes>(value: Bytes) {
        prepend(contentsOf: value)
        putVarInt(value: value.count)
    }
}
