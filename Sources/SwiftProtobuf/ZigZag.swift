// Sources/SwiftProtobuf/ZigZag.swift - ZigZag encoding/decoding helpers
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Helper functions to ZigZag encode and decode signed integers.
///
// -----------------------------------------------------------------------------

extension UInt32 {
    /// Creates an unsigned 32-bit integer by ZigZag encoding a signed 32-bit integer.
    ///
    /// ZigZag encodes signed integers into values that can be efficiently encoded with varint.
    /// (Otherwise, negative values must be sign-extended to 64 bits to be varint encoded, always
    /// taking 10 bytes on the wire.)
    ///
    /// - Parameter value: A signed 32-bit integer.
    init(zigZagEncoded value: Int32) {
        self.init(bitPattern: (value << 1) ^ (value >> 31))
    }
}

extension UInt64 {
    /// Creates an unsigned 64-bit integer by ZigZag encoding a signed 64-bit integer.
    ///
    /// ZigZag encodes signed integers into values that can be efficiently encoded with varint.
    /// (Otherwise, negative values must be sign-extended to 64 bits to be varint encoded, always
    /// taking 10 bytes on the wire.)
    ///
    /// - Parameter value: A signed 64-bit integer.
    init(zigZagEncoded value: Int64) {
        self.init(bitPattern: (value << 1) ^ (value >> 63))
    }
}

extension Int32 {
    /// Creates a signed 32-bit integer by decoding a 32-bit ZigZag-encoded value.
    ///
    /// ZigZag enocdes signed integers into values that can be efficiently encoded with varint.
    /// (Otherwise, negative values must be sign-extended to 64 bits to be varint encoded, always
    /// taking 10 bytes on the wire.)
    ///
    /// - Parameter value: An unsigned 32-bit ZagZag-encoded integer.
    init(zigZagDecoded value: UInt32) {
        self = Int32(value >> 1) ^ -Int32(value & 1)
    }
}

extension Int64 {
    /// Creates a signed 64-bit integer by decoding a 64-bit ZigZag-encoded value.
    ///
    /// ZigZag enocdes signed integers into values that can be efficiently encoded with varint.
    /// (Otherwise, negative values must be sign-extended to 64 bits to be varint encoded, always
    /// taking 10 bytes on the wire.)
    ///
    /// - Parameter value: An unsigned 64-bit ZigZag-encoded integer.
    init(zigZagDecoded value: UInt64) {
        self = Int64(value >> 1) ^ -Int64(value & 1)
    }
}
