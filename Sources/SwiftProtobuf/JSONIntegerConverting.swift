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


/// An internal protocol that the 32- and 64-bit Swift integer types conform to
/// within this compilation unit so that we can write the numeric conversions
/// in `JSONToken` more cleanly.
internal protocol JSONIntegerConverting {

  // These conversions are already provided by the conforming types.
  init?(exactly value: UInt64)
  init?(exactly value: Int64)
  init?(_ text: String, radix: Int)

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
  ///
  /// TODO: At the time of this writing, `init?(exactly: Double)` is implemented
  /// in Swift HEAD but not yet available in an Xcode GM release. Once it is,
  /// we can use it, though we would still need a language version check to
  /// support Swift 3.0, which means our custom implementation will still have
  /// to exist. As such, we don't give it the same `exactly` name yet because we
  /// don't want users who upgrade Swift to get errors from colliding
  /// definitions before we can update this library.
  init?(safely value: Double)
}


extension Int32: JSONIntegerConverting {

  init?(safely value: Double) {
    let upper = Double(sign: .plus, exponent: 31, significand: 1)
    let lower = -upper - 1
    guard lower < value && value < upper &&
      value == value.rounded(.towardZero) else {
      return nil
    }
    self.init(value)
  }
}


extension Int64: JSONIntegerConverting {

  init?(safely value: Double) {
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


extension UInt32: JSONIntegerConverting {

  init?(safely value: Double) {
    let upper = Double(sign: .plus, exponent: 32, significand: 1)
    guard -1 < value && value < upper &&
      value == value.rounded(.towardZero) else {
      return nil
    }
    self.init(value)
  }
}


extension UInt64: JSONIntegerConverting {

  init?(safely value: Double) {
    let upper = Double(sign: .plus, exponent: 64, significand: 1)
    guard -1 < value && value < upper &&
      value == value.rounded(.towardZero) else {
      return nil
    }
    self.init(value)
  }
}
