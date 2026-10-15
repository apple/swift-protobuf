// Sources/SwiftProtobuf/SchemaBase128Decoding.swift - Base-128 integer decoding for schemas
//
// Copyright (c) 2014 - 2026 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Helper functions for decoding fixed-width 7-bit base-128 integers from
/// message, enum, and extension schema buffers.
///
// -----------------------------------------------------------------------------

/// Returns the up-to-14-bit unsigned integer that has been base-128 encoded at the given byte
/// offset in the buffer.
@_alwaysEmitIntoClient @inline(__always)
func fixed2ByteBase128(in buffer: UnsafeRawBufferPointer, atByteOffset byteOffset: Int) -> Int {
    let rawBits = UInt16(littleEndian: buffer.loadUnaligned(fromByteOffset: byteOffset, as: UInt16.self))
    return Int((rawBits & 0x007f) | ((rawBits & 0x7f00) >> 1))
}

/// Returns the up-to-21-bit unsigned integer that has been base-128 encoded at the given byte
/// offset in the buffer.
@_alwaysEmitIntoClient @inline(__always)
func fixed3ByteBase128(in buffer: UnsafeRawBufferPointer, atByteOffset byteOffset: Int) -> Int {
    let lowBits = UInt16(littleEndian: buffer.loadUnaligned(fromByteOffset: byteOffset, as: UInt16.self))
    let highBits = buffer.loadUnaligned(fromByteOffset: byteOffset + 2, as: UInt8.self)
    return Int((lowBits & 0x7f) | ((lowBits & 0x7f00) >> 1)) | (Int(highBits & 0x7f) << 14)
}

/// Returns the 32-bit unsigned integer that has been 5-byte base-128 encoded at the given byte
/// offset in the buffer.
@_alwaysEmitIntoClient @inline(__always)
func fixed5ByteBase128(in buffer: UnsafeRawBufferPointer, atByteOffset byteOffset: Int) -> UInt32 {
    let lowBits = UInt32(littleEndian: buffer.loadUnaligned(fromByteOffset: byteOffset, as: UInt32.self))
    let highBits = buffer.loadUnaligned(fromByteOffset: byteOffset + 4, as: UInt8.self)
    let part1 = (lowBits & 0x0000_007f)
    let part2 = ((lowBits & 0x0000_7f00) >> 1)
    let part3 = ((lowBits & 0x007f_0000) >> 2)
    let part4 = ((lowBits & 0x7f00_0000) >> 3)
    let part5 = UInt32(highBits & 0x0f) << 28
    return part1 | part2 | part3 | part4 | part5
}
