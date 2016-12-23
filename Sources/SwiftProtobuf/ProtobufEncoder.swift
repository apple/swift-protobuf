// Sources/SwiftProtobuf/ProtobufEncoder.swift - Binary encoding support
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Core support for protobuf binary encoding.  Note that this is built
/// on the general traversal machinery.
///
// -----------------------------------------------------------------------------

import Foundation
import Swift

/*
 * Encoder for Binary Protocol Buffer format
 *
 * TODO: Should this be a class?
 */
public struct ProtobufEncoder {
    private var pointer: UnsafeMutablePointer<UInt8>

    public init(pointer: UnsafeMutablePointer<UInt8>) {
        self.pointer = pointer
    }

    private mutating func append(_ byte: UInt8) {
        pointer.pointee = byte
        pointer = pointer.successor()
    }

    private mutating func append(contentsOf data: Data) {
        let count = data.count
        data.copyBytes(to: pointer, count: count)
        pointer = pointer.advanced(by: count)
    }

    private mutating func append(contentsOf bufferPointer: UnsafeBufferPointer<UInt8>) {
        let count = bufferPointer.count
        pointer.assign(from: bufferPointer.baseAddress!, count: count)
        pointer = pointer.advanced(by: count)
    }

    public mutating func appendUnknown(data: Data) {
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

    mutating func putBytesValue(value: Data) {
        putVarInt(value: value.count)
        append(contentsOf: value)
    }
}
