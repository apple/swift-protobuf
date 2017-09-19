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

#if !swift(>=4.0)
//
// Swift 3 called this initializer "truncatingBitPattern";
// Swift 4 changed this initializer to "truncatingIfNeeded".
//
extension UInt8 {
     internal init(truncatingIfNeeded value: UInt32) {
         self.init(truncatingBitPattern: value)
     }
     internal init(truncatingIfNeeded value: Int) {
         self.init(truncatingBitPattern: value)
     }
     internal init(truncatingIfNeeded value: UInt64) {
         self.init(truncatingBitPattern: value)
     }
}

extension UInt32 {
     internal init(truncatingIfNeeded value: UInt64) {
         self.init(truncatingBitPattern: value)
     }
     internal init(truncatingIfNeeded value: Int) {
         self.init(truncatingBitPattern: value)
     }
}

extension Int32 {
     internal init(truncatingIfNeeded value: UInt64) {
         self.init(truncatingBitPattern: value)
     }
     internal init(truncatingIfNeeded value: Int64) {
         self.init(truncatingBitPattern: value)
     }
     internal init(truncatingIfNeeded value: Int) {
         self.init(truncatingBitPattern: value)
     }
}

extension Int {
     internal init(truncatingIfNeeded value: Int64) {
         self.init(truncatingBitPattern: value)
     }
     internal init(truncatingIfNeeded value: UInt64) {
         self.init(truncatingBitPattern: value)
     }
}
#endif
