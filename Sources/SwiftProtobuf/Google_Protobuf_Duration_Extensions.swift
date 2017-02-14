// Sources/SwiftProtobuf/Google_Protobuf_Duration_Extensions.swift - Extensions for Duration type
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Extends the generated Duration struct with various custom behaviors:
/// * JSON coding and decoding
/// * Arithmetic operations
///
// -----------------------------------------------------------------------------

import Swift

private let minDurationSeconds: Int64 = -maxDurationSeconds
private let maxDurationSeconds: Int64 = 315576000000
private let nanosPerSecond: Int32 = 1000000000

private func parseDuration(text: String) throws -> (Int64, Int32) {
    var digits = [Character]()
    var digitCount = 0
    var total = 0
    var chars = text.characters.makeIterator()
    var seconds: Int64?
    var nanos: Int32 = 0
    while let c = chars.next() {
        switch c {
        case "-":
            // Only accept '-' as very first character
            if total > 0 {
                throw JSONDecodingError.malformedDuration
            }
            digits.append(c)
        case "0", "1", "2", "3", "4", "5", "6", "7", "8", "9":
            digits.append(c)
            digitCount += 1
        case ".":
            if let _ = seconds {
                throw JSONDecodingError.malformedDuration
            }
            let digitString = String(digits)
            if let s = Int64(digitString), s >= minDurationSeconds && s <= maxDurationSeconds {
                seconds = s
            } else {
                throw JSONDecodingError.malformedDuration
            }
            digits.removeAll()
            digitCount = 0
        case "s":
            if let seconds = seconds {
                // Seconds already set, digits holds nanos
                while (digitCount < 9) {
                    digits.append(Character("0"))
                    digitCount += 1
                }
                while digitCount > 9 {
                    digits.removeLast()
                    digitCount -= 1
                }
                let digitString = String(digits)
                if let rawNanos = Int32(digitString) {
                    if seconds < 0 {
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
                if let s = Int64(digitString), s >= minDurationSeconds && s <= maxDurationSeconds {
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
    let (seconds, nanos) = normalizeForDuration(seconds: seconds, nanos: nanos)
    guard seconds >= minDurationSeconds && seconds <= maxDurationSeconds else {
        return nil
    }

    if nanos == 0 {
        return "\(seconds)s"
    } else {
        // String(format:...) is broken on Swift 2.2/Linux
        // So we do this the hard way...
        var digits: Int
        var fraction: Int
        let n = abs(nanos)
        if n % 1000000 == 0 {
            fraction = Int(n) / 1000000
            digits = 3
        } else if n % 1000 == 0 {
            fraction = Int(n) / 1000
            digits = 6
        } else {
            fraction = Int(n)
            digits = 9
        }
        var formatted_fraction = ""
        while digits > 0 {
            formatted_fraction = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"][fraction % 10] + formatted_fraction
            fraction /= 10
            digits -= 1
        }
        return "\(seconds).\(formatted_fraction)s"
    }
}

public extension Google_Protobuf_Duration {
    public init(seconds: Int64 = 0, nanos: Int32 = 0) {
        self.init()
        self.seconds = seconds
        self.nanos = nanos
    }

    public mutating func decodeJSON(from decoder: inout JSONDecoder) throws {
        let s = try decoder.scanner.nextQuotedString()
        (seconds, nanos) = try parseDuration(text: s)
    }

    public func serializeJSON() throws -> String {
        if let formatted = formatDuration(seconds: seconds, nanos: nanos) {
            return "\"\(formatted)\""
        } else {
            throw EncodingError.durationJSONRange
        }
    }

    public func serializeAnyJSON() throws -> String {
        let value = try serializeJSON()
        return "{\"@type\":\"\(anyTypeURL)\",\"value\":\(value)}"
    }
}

extension Google_Protobuf_Duration: ExpressibleByFloatLiteral {
    public typealias FloatLiteralType = Double

    public init(floatLiteral value: Double) {
        let seconds = Int64(value)  // rounded towards zero
        let fractionalSeconds = value - Double(seconds)
        let nanos = Int32(fractionalSeconds * Double(nanosPerSecond))
        self.init(seconds: seconds, nanos: nanos)
    }
}

private func normalizeForDuration(seconds: Int64, nanos: Int32) -> (seconds: Int64, nanos: Int32) {
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

public prefix func -(operand: Google_Protobuf_Duration) -> Google_Protobuf_Duration {
    let (s, n) = normalizeForDuration(seconds: -operand.seconds, nanos: -operand.nanos)
    return Google_Protobuf_Duration(seconds: s, nanos: n)
}

public func+(lhs: Google_Protobuf_Duration, rhs: Google_Protobuf_Duration) -> Google_Protobuf_Duration {
    let (s, n) = normalizeForDuration(seconds: lhs.seconds + rhs.seconds, nanos: lhs.nanos + rhs.nanos)
    return Google_Protobuf_Duration(seconds: s, nanos: n)
}

public func -(lhs: Google_Protobuf_Duration, rhs: Google_Protobuf_Duration) -> Google_Protobuf_Duration {
    let (s, n) = normalizeForDuration(seconds: lhs.seconds - rhs.seconds, nanos: lhs.nanos - rhs.nanos)
    return Google_Protobuf_Duration(seconds: s, nanos: n)
}

public func -(lhs: Google_Protobuf_Timestamp, rhs: Google_Protobuf_Timestamp) -> Google_Protobuf_Duration {
    let (s, n) = normalizeForDuration(seconds: lhs.seconds - rhs.seconds, nanos: lhs.nanos - rhs.nanos)
    return Google_Protobuf_Duration(seconds: s, nanos: n)
}
