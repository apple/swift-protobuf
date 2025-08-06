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

private let minDurationSeconds: Int64 = -maxDurationSeconds
private let maxDurationSeconds: Int64 = 315_576_000_000
private let minDurationNanos: Int32 = -maxDurationNanos
private let maxDurationNanos: Int32 = 999_999_999

private func parseDuration(text: String) throws -> (Int64, Int32) {
    var digits = [Character]()
    var digitCount = 0
    var total = 0
    var chars = text.makeIterator()
    var seconds: Int64?
    var nanos: Int32 = 0
    var isNegative = false
    while let c = chars.next() {
        switch c {
        case "-":
            // Only accept '-' as very first character
            if total > 0 {
                throw JSONDecodingError.malformedDuration
            }
            digits.append(c)
            isNegative = true
        case "0", "1", "2", "3", "4", "5", "6", "7", "8", "9":
            digits.append(c)
            digitCount += 1
        case ".":
            if let _ = seconds {
                throw JSONDecodingError.malformedDuration
            }
            let digitString = String(digits)
            if let s = Int64(digitString),
                s >= minDurationSeconds && s <= maxDurationSeconds
            {
                seconds = s
            } else {
                throw JSONDecodingError.malformedDuration
            }
            digits.removeAll()
            digitCount = 0
        case "s":
            if let _ = seconds {
                // Seconds already set, digits holds nanos
                while digitCount < 9 {
                    digits.append(Character("0"))
                    digitCount += 1
                }
                while digitCount > 9 {
                    digits.removeLast()
                    digitCount -= 1
                }
                let digitString = String(digits)
                if let rawNanos = Int32(digitString) {
                    if isNegative {
                        nanos = -rawNanos
                    } else {
                        nanos = rawNanos
                    }
                } else {
                    throw JSONDecodingError.malformedDuration
                }
            } else {
                // No fraction, we just have an integral number of seconds
                let digitString = String(digits)
                if let s = Int64(digitString),
                    s >= minDurationSeconds && s <= maxDurationSeconds
                {
                    seconds = s
                } else {
                    throw JSONDecodingError.malformedDuration
                }
            }
            // Fail if there are characters after 's'
            if chars.next() != nil {
                throw JSONDecodingError.malformedDuration
            }
            return (seconds!, nanos)
        default:
            throw JSONDecodingError.malformedDuration
        }
        total += 1
    }
    throw JSONDecodingError.malformedDuration
}

private func formatDuration(seconds: Int64, nanos: Int32) -> String? {
    // Upstream's json file unparse.cc:WriteDuration() for these checks for reference.

    // Range check...
    guard
        (seconds >= minDurationSeconds && seconds <= maxDurationSeconds)
            && (nanos >= minDurationNanos && nanos <= maxDurationNanos)
    else {
        return nil
    }
    // Either seconds or nanos has to be zero otherwise the signs must match.
    guard (seconds == 0) || (nanos == 0) || ((seconds < 0) == (nanos < 0)) else {
        return nil
    }
    let nanosString = nanosToString(nanos: nanos)  // Includes leading '.' if needed
    if seconds == 0 && nanos < 0 {
        return "-0\(nanosString)s"
    }
    return "\(seconds)\(nanosString)s"
}

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

extension Google_Protobuf_Duration: _CustomJSONCodable {
    mutating func decodeJSON(from decoder: inout JSONDecoder) throws {
        let s = try decoder.scanner.nextQuotedString()
        (seconds, nanos) = try parseDuration(text: s)
    }
    func encodedJSONString(options: JSONEncodingOptions) throws -> String {
        if let formatted = formatDuration(seconds: seconds, nanos: nanos) {
            return "\"\(formatted)\""
        } else {
            throw JSONEncodingError.durationRange
        }
    }
}

extension Google_Protobuf_Duration: ExpressibleByFloatLiteral {
    public typealias FloatLiteralType = Double

    /// Creates a new `Google_Protobuf_Duration` from a floating point literal
    /// that is interpreted as a duration in seconds, rounded to the nearest
    /// nanosecond.
    public init(floatLiteral value: Double) {
        self.init(rounding: value, rule: .toNearestOrAwayFromZero)
    }
}

extension Google_Protobuf_Duration {
    #if !REMOVE_DEPRECATED_APIS
    /// Creates a new `Google_Protobuf_Duration` that is equal to the given
    /// `TimeInterval` (measured in seconds), rounded to the nearest nanosecond.
    ///
    /// - Parameter timeInterval: The `TimeInterval`.
    @available(*, deprecated, renamed: "init(rounding:rule:)")
    public init(timeInterval: TimeInterval) {
        self.init(rounding: timeInterval, rule: .toNearestOrAwayFromZero)
    }
    #endif  // !REMOVE_DEPRECATED_APIS

    /// Creates a new `Google_Protobuf_Duration` that is equal to the given
    /// `TimeInterval` (measured in seconds), rounded to the nearest nanosecond
    /// according to the given rounding rule.
    ///
    /// - Parameters:
    ///   - timeInterval: The `TimeInterval`.
    ///   - rule: The rounding rule to use.
    public init(
        rounding timeInterval: TimeInterval,
        rule: FloatingPointRoundingRule = .toNearestOrAwayFromZero
    ) {
        let sd = Int64(timeInterval)
        let nd = ((timeInterval - Double(sd)) * TimeInterval(nanosPerSecond)).rounded(rule)
        // Normalize is here incase things round up to a full second worth of nanos.
        let (s, n) = normalizeForDuration(seconds: sd, nanos: Int32(nd))
        self.init(seconds: s, nanos: n)
    }

    /// The `TimeInterval` (measured in seconds) equal to this duration.
    public var timeInterval: TimeInterval {
        TimeInterval(self.seconds) + TimeInterval(self.nanos) / TimeInterval(nanosPerSecond)
    }
}

@available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
extension Google_Protobuf_Duration {
    /// Creates a new `Google_Protobuf_Duration` by rounding a `Duration` to
    /// the nearest nanosecond according to the given rounding rule.
    ///
    /// - Parameters:
    ///   - duration: The `Duration`.
    ///   - rule: The rounding rule to use.
    public init(
        rounding duration: Duration,
        rule: FloatingPointRoundingRule = .toNearestOrAwayFromZero
    ) {
        let secs = duration.components.seconds
        let attos = duration.components.attoseconds
        let fracNanos =
            (Double(attos % attosPerNanosecond) / Double(attosPerNanosecond)).rounded(rule)
        let nanos = Int32(attos / attosPerNanosecond) + Int32(fracNanos)
        // Normalize is here incase things round up to a full second worth of nanos.
        let (s, n) = normalizeForDuration(seconds: secs, nanos: nanos)
        self.init(seconds: s, nanos: n)
    }
}

@available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
extension Duration {
    /// Creates a new `Duration` that is equal to the given duration.
    ///
    /// Swift `Duration` has a strictly higher precision than `Google_Protobuf_Duration`
    /// (attoseconds vs. nanoseconds, respectively), so this conversion is always
    /// value-preserving.
    ///
    /// - Parameters:
    ///   - duration: The `Google_Protobuf_Duration`.
    public init(_ duration: Google_Protobuf_Duration) {
        self.init(
            secondsComponent: duration.seconds,
            attosecondsComponent: Int64(duration.nanos) * attosPerNanosecond
        )
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
    // This gets normalized (thus allowing an otherwise non-logical input) so it matches what would
    // happen if doing `Duration(0,0) - operand` because that has to normalize to handle roll
    // over/under.
    let (s, n) = normalizeForDuration(
        seconds: -operand.seconds,
        nanos: -operand.nanos
    )
    return Google_Protobuf_Duration(seconds: s, nanos: n)
}

public func + (
    lhs: Google_Protobuf_Duration,
    rhs: Google_Protobuf_Duration
) -> Google_Protobuf_Duration {
    let (s, n) = normalizeForDuration(
        seconds: lhs.seconds + rhs.seconds,
        nanos: lhs.nanos + rhs.nanos
    )
    return Google_Protobuf_Duration(seconds: s, nanos: n)
}

public func - (
    lhs: Google_Protobuf_Duration,
    rhs: Google_Protobuf_Duration
) -> Google_Protobuf_Duration {
    let (s, n) = normalizeForDuration(
        seconds: lhs.seconds - rhs.seconds,
        nanos: lhs.nanos - rhs.nanos
    )
    return Google_Protobuf_Duration(seconds: s, nanos: n)
}

public func - (
    lhs: Google_Protobuf_Timestamp,
    rhs: Google_Protobuf_Timestamp
) -> Google_Protobuf_Duration {
    let (s, n) = normalizeForDuration(
        seconds: lhs.seconds - rhs.seconds,
        nanos: lhs.nanos - rhs.nanos
    )
    return Google_Protobuf_Duration(seconds: s, nanos: n)
}
