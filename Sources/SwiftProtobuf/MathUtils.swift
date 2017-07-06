// Sources/SwiftProtobuf/MathUtils.swift - Generally useful mathematical functions
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Generally useful mathematical and arithmetic functions.
///
// -----------------------------------------------------------------------------

import Foundation

/// Remainder in standard modular arithmetic (modulo). This coincides with (%)
/// when a > 0.
///
/// - Parameters:
///   - a: The dividend. Can be positive, 0 or negative.
///   - b: The divisor. This must be positive, and is an error if 0 or negative.
/// - Returns: The unique value r such that 0 <= r < b and b * q + r = a for some q.
internal func mod<T : SignedInteger>(_ a: T, _ b: T) -> T {
    assert(b > 0)
    let r = a % b
    return r >= 0 ? r : r + b
}

/// Quotient in standard modular arithmetic (Euclidean division). This coincides
/// with (/) when a > 0.
///
/// - Parameters:
///   - a: The dividend. Can be positive, 0 or negative.
///   - b: The divisor. This must be positive, and is an error if 0 or negative.
/// - Returns: The unique value q such that for some 0 <= r < b, b * q + r = a.
internal func div<T : SignedInteger>(_ a: T, _ b: T) -> T {
    assert(b > 0)
    return a >= 0 ? a / b : (a + 1) / b - 1
}

// Swift's standard library changed the name of the initializer
// that truncates an integer to a narrower type.  To continue
// to support Swift 3, we've introduced these functions to
// handle that.
//
#if swift(>=4.0)
//
// Swift 4 (prerelease) changed this initializer to
// "extendingOrTruncating"
//
internal func uint8(truncating value: UInt32) -> UInt8 {
    return UInt8(extendingOrTruncating: value)
}

internal func uint8(truncating value: Int) -> UInt8 {
    return UInt8(extendingOrTruncating: value)
}

internal func uint8(truncating value: UInt64) -> UInt8 {
    return UInt8(extendingOrTruncating: value)
}

internal func uint32(truncating value: UInt64) -> UInt32 {
    return UInt32(extendingOrTruncating: value)
}

internal func uint32(truncating value: Int) -> UInt32 {
    return UInt32(extendingOrTruncating: value)
}

internal func int32(truncating value: UInt64) -> Int32 {
    return Int32(extendingOrTruncating: value)
}

internal func int32(truncating value: Int64) -> Int32 {
    return Int32(extendingOrTruncating: value)
}

internal func int32(truncating value: Int) -> Int32 {
    return Int32(extendingOrTruncating: value)
}

internal func int(truncating value: Int64) -> Int {
    return Int(extendingOrTruncating: value)
}

internal func int(truncating value: UInt64) -> Int {
    return Int(extendingOrTruncating: value)
}
#else
//
// Swift 3 called this initializer "truncatingBitPattern"
//
// TODO: When Swift 5 comes out, delete this.
internal func uint8(truncating value: UInt32) -> UInt8 {
    return UInt8(truncatingBitPattern: value)
}

internal func uint8(truncating value: Int) -> UInt8 {
    return UInt8(truncatingBitPattern: value)
}

internal func uint8(truncating value: UInt64) -> UInt8 {
    return UInt8(truncatingBitPattern: value)
}

internal func uint32(truncating value: UInt64) -> UInt32 {
    return UInt32(truncatingBitPattern: value)
}

internal func uint32(truncating value: Int) -> UInt32 {
    return UInt32(truncatingBitPattern: value)
}

internal func int32(truncating value: UInt64) -> Int32 {
    return Int32(truncatingBitPattern: value)
}

internal func int32(truncating value: Int64) -> Int32 {
    return Int32(truncatingBitPattern: value)
}

internal func int32(truncating value: Int) -> Int32 {
    return Int32(truncatingBitPattern: value)
}

internal func int(truncating value: Int64) -> Int {
    return Int(truncatingBitPattern: value)
}

internal func int(truncating value: UInt64) -> Int {
    return Int(truncatingBitPattern: value)
}
#endif
