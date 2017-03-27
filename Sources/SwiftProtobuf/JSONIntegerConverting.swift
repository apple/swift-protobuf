// Sources/SwiftProtobuf/JSONIntegerConverting.swift - JSON integer helpers
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Helpers for converting numbers scanned from protobuf JSON into Swift integer
/// types.
///
// -----------------------------------------------------------------------------

#if swift(>=3.1)

// Nothing! init?(exactly: Double) is provided.

// NOTE: When Swift 3.1 is the required minimum for compiling the library
// sources, this whole file can go away.

#else

/// An internal protocol that the 32- and 64-bit Swift integer types conform to
/// within this compilation unit so that we can write the numeric conversions
/// in `JSONToken` more cleanly.
internal protocol JSONIntegerConverting {

  /// Creates a new instance of the conforming type by attempting to convert the
  /// given `Double`. Returns nil if the number has a fractional part, and
  /// unlike the default `IntXX(_: Double)` conversions in Swift, it also
  /// returns nil (instead of trapping) if the magnitude of the value is outside
  /// the range of the conforming type.
  ///
  /// The concrete implementations below of this method are adapted from the
  /// logic in <https://github.com/apple/swift/blob/master/utils/SwiftFloatingPointTypes.py>,
  /// which computes the allowable lower and upper bounds that are used as the
  /// preconditions for the standard library's floating-point-to-integer
  /// conversions.
  init?(exactly value: Double)
}


extension Int64: JSONIntegerConverting {

  init?(exactly value: Double) {
    let upper = Double(sign: .plus, exponent: 63, significand: 1)
    // 11 is the difference between the number of integer bits (64) and the
    // number of bits, including the implicit bit, in a Double's significand
    // (53). In other words, it is roughly the number of integers we lose the
    // ability to represent between each adjacent bit pattern, which requires a
    // small adjustment of the lower bound in order to test the correct range.
    let ulp = Double(1 << 11)
    let lower = -upper - ulp
    guard lower < value && value < upper &&
      value == value.rounded(.towardZero) else {
      return nil
    }
    self.init(value)
  }
}


extension UInt64: JSONIntegerConverting {

  init?(exactly value: Double) {
    let upper = Double(sign: .plus, exponent: 64, significand: 1)
    guard -1 < value && value < upper &&
      value == value.rounded(.towardZero) else {
      return nil
    }
    self.init(value)
  }
}

#endif  // !swift(>=3.1)
