// Sources/SwiftProtobuf/Varint.swift - Varint encoding/decoding helpers
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Helper functions to varint-encode and decode integers.
///
// -----------------------------------------------------------------------------

/// Contains helper methods to varint-encode and decode integers.
package enum Varint {

    /// Computes the number of bytes that would be needed to store a 32-bit varint.
    ///
    /// - Parameter value: The number whose varint size should be calculated.
    /// - Returns: The size, in bytes, of the 32-bit varint.
    @usableFromInline
    package static func encodedSize(of value: UInt32) -> Int {
        // This logic comes from the upstream C++ for CodedOutputStream::VarintSize32(uint32_t),
        // it provides a branchless calculation of the size.
        let clz = value.leadingZeroBitCount
        return ((UInt32.bitWidth &* 9 &+ 64) &- (clz &* 9)) / 64
    }

    /// Computes the number of bytes that would be needed to store a signed 32-bit varint, if it were
    /// treated as an unsigned integer with the same bit pattern.
    ///
    /// - Parameter value: The number whose varint size should be calculated.
    /// - Returns: The size, in bytes, of the 32-bit varint.
    @inline(__always)
    package static func encodedSize(of value: Int32) -> Int {
        // Must sign-extend.
        encodedSize(of: Int64(value))
    }

    /// Computes the number of bytes that would be needed to store a 64-bit varint.
    ///
    /// - Parameter value: The number whose varint size should be calculated.
    /// - Returns: The size, in bytes, of the 64-bit varint.
    @inline(__always)
    static func encodedSize(of value: Int64) -> Int {
        encodedSize(of: UInt64(bitPattern: value))
    }

    /// Computes the number of bytes that would be needed to store an unsigned 64-bit varint, if it
    /// were treated as a signed integer with the same bit pattern.
    ///
    /// - Parameter value: The number whose varint size should be calculated.
    /// - Returns: The size, in bytes, of the 64-bit varint.
    @usableFromInline
    static func encodedSize(of value: UInt64) -> Int {
        // This logic comes from the upstream C++ for CodedOutputStream::VarintSize64(uint64_t),
        // it provides a branchless calculation of the size.
        let clz = value.leadingZeroBitCount
        return ((UInt64.bitWidth &* 9 &+ 64) &- (clz &* 9)) / 64
    }

    /// Counts the number of distinct varints in a packed byte buffer.
    static func countVarintsInBuffer(start: UnsafeRawPointer, count: Int) -> Int {
        // We don't need to decode all the varints to count how many there
        // are.  Just observe that every varint has exactly one byte with
        // value < 128. So we just count those...
        var n = 0
        var ints = 0
        while n < count {
            if start.load(fromByteOffset: n, as: UInt8.self) < 128 {
                ints &+= 1
            }
            n &+= 1
        }
        return ints
    }
}
