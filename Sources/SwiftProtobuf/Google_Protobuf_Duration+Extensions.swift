// Sources/SwiftProtobuf/Google_Protobuf_Duration+Extensions.swift - Extensions for Duration type
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Extends the generated Duration struct with various custom behaviors:
/// * JSON coding and decoding
/// * Arithmetic operations
///
// -----------------------------------------------------------------------------

import Foundation

extension Google_Protobuf_Duration {
  /// Creates a new `Google_Protobuf_Duration` equal to the given number of
  /// seconds and nanoseconds.
  ///
  /// - Parameter seconds: The number of seconds.
  /// - Parameter nanos: The number of nanoseconds.
  public init(seconds: Int64 = 0, nanos: Int32 = 0) {
    self.init()
    self.seconds = seconds
    self.nanos = nanos
  }
}

extension Google_Protobuf_Duration: ExpressibleByFloatLiteral {
  public typealias FloatLiteralType = Double

  /// Creates a new `Google_Protobuf_Duration` from a floating point literal
  /// that is interpreted as a duration in seconds, rounded to the nearest
  /// nanosecond.
  public init(floatLiteral value: Double) {
    let sd = trunc(value)
    let nd = round((value - sd) * TimeInterval(nanosPerSecond))
    let (s, n) = normalizeForDuration(seconds: Int64(sd), nanos: Int32(nd))
    self.init(seconds: s, nanos: n)
  }
}

extension Google_Protobuf_Duration {
  /// Creates a new `Google_Protobuf_Duration` that is equal to the given
  /// `TimeInterval` (measured in seconds), rounded to the nearest nanosecond.
  ///
  /// - Parameter timeInterval: The `TimeInterval`.
  public init(timeInterval: TimeInterval) {
    let sd = trunc(timeInterval)
    let nd = round((timeInterval - sd) * TimeInterval(nanosPerSecond))
    let (s, n) = normalizeForDuration(seconds: Int64(sd), nanos: Int32(nd))
    self.init(seconds: s, nanos: n)
  }

  /// The `TimeInterval` (measured in seconds) equal to this duration.
  public var timeInterval: TimeInterval {
    return TimeInterval(self.seconds) +
      TimeInterval(self.nanos) / TimeInterval(nanosPerSecond)
  }
}

private func normalizeForDuration(
  seconds: Int64,
  nanos: Int32
) -> (seconds: Int64, nanos: Int32) {
  var s = seconds
  var n = nanos

  // If the magnitude of n exceeds a second then
  // we need to factor it into s instead.
  if n >= nanosPerSecond || n <= -nanosPerSecond {
    s += Int64(n / nanosPerSecond)
    n = n % nanosPerSecond
  }

  // The Duration spec says that when s != 0, s and
  // n must have the same sign.
  if s > 0 && n < 0 {
    n += nanosPerSecond
    s -= 1
  } else if s < 0 && n > 0 {
    n -= nanosPerSecond
    s += 1
  }

  return (seconds: s, nanos: n)
}

public prefix func - (
  operand: Google_Protobuf_Duration
) -> Google_Protobuf_Duration {
  let (s, n) = normalizeForDuration(seconds: -operand.seconds,
                                    nanos: -operand.nanos)
  return Google_Protobuf_Duration(seconds: s, nanos: n)
}

public func + (
  lhs: Google_Protobuf_Duration,
  rhs: Google_Protobuf_Duration
) -> Google_Protobuf_Duration {
  let (s, n) = normalizeForDuration(seconds: lhs.seconds + rhs.seconds,
                                    nanos: lhs.nanos + rhs.nanos)
  return Google_Protobuf_Duration(seconds: s, nanos: n)
}

public func - (
  lhs: Google_Protobuf_Duration,
  rhs: Google_Protobuf_Duration
) -> Google_Protobuf_Duration {
  let (s, n) = normalizeForDuration(seconds: lhs.seconds - rhs.seconds,
                                    nanos: lhs.nanos - rhs.nanos)
  return Google_Protobuf_Duration(seconds: s, nanos: n)
}

public func - (
  lhs: Google_Protobuf_Timestamp,
  rhs: Google_Protobuf_Timestamp
) -> Google_Protobuf_Duration {
  let (s, n) = normalizeForDuration(seconds: lhs.seconds - rhs.seconds,
                                    nanos: lhs.nanos - rhs.nanos)
  return Google_Protobuf_Duration(seconds: s, nanos: n)
}
