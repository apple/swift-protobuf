// ProtobufRuntime/Sources/Protobuf/Google_Protobuf_Duration_Extensions.swift - Extensions for Duration type
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
// -----------------------------------------------------------------------------
///
/// Extends the generated Duration struct with various custom behaviors:
/// * JSON coding and decoding
/// * Arithmetic operations
///
// -----------------------------------------------------------------------------

import Swift

private let DurationMax: Int64 = 315576000000
private let DurationMin: Int64 = -DurationMax

private func parseDuration(text: String) -> (Int64, Int32)? {
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
                return nil
            }
            digits.append(c)
        case "0", "1", "2", "3", "4", "5", "6", "7", "8", "9":
            digits.append(c)
            digitCount += 1
        case ".":
            if let _ = seconds {
                return nil
            }
            let digitString = String(digits)
            if let s = Int64(digitString), s >= DurationMin && s <= DurationMax {
                seconds = s
            } else {
                return nil
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
                    return nil
                }
            } else {
                // No fraction, we just have an integral number of seconds
                let digitString = String(digits)
                if let s = Int64(digitString), s >= DurationMin && s <= DurationMax {
                    seconds = s
                } else {
                    return nil
                }
            }
            // Fail if there are characters after 's'
            if chars.next() != nil {
                return nil
            }
            return (seconds!, nanos)
        default:
            return nil
        }
        total += 1
    }
    return nil
}

private func formatDuration(seconds: Int64, nanos: Int32) -> String? {
    if ((seconds < 0 && nanos > 0)
        || (seconds > 0 && nanos < 0)
        || (seconds < -315576000000)
        || (seconds > 315576000000)) {
        return nil
    } else if nanos == 0 {
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
    public mutating func decodeFromJSONToken(token: ProtobufJSONToken) throws {
        if case .string(let s) = token,
            let duration = parseDuration(text: s) {
            seconds = duration.0
            nanos = duration.1
        } else {
            throw ProtobufDecodingError.schemaMismatch
        }
    }

    public func serializeJSON() throws -> String {
        let s = seconds
        let n = nanos
        if let formatted = formatDuration(seconds: s, nanos: n) {
            return "\"\(formatted)\""
        } else {
            throw ProtobufEncodingError.durationJSONRange
        }
    }

    public func serializeAnyJSON() throws -> String {
        let value = try serializeJSON()
        return "{\"@type\":\"\(anyTypeURL)\",\"value\":\(value)}"
    }
}

extension Google_Protobuf_Duration: ExpressibleByFloatLiteral {
    public typealias FloatLiteralType = Double
    public init(floatLiteral: Double) {
        let seconds = Int64(floatLiteral)
        let fractionalSeconds = floatLiteral - Double(seconds)
        let nanos = Int32(fractionalSeconds * 1000000000.0)
        self.init(seconds: seconds, nanos: nanos)
    }
}

private func normalizedDuration(seconds: Int64, nanos: Int32) -> Google_Protobuf_Duration {
    var s = seconds
    var n = nanos
    if n >= 1000000000 || n <= -1000000000 {
        s += Int64(n) / 1000000000
        n = n % 1000000000
    }
    if s > 0 && n < 0 {
        n += 1000000000
        s -= 1
    } else if s < 0 && n > 0 {
        n -= 1000000000
        s += 1
    }
    return Google_Protobuf_Duration(seconds: s, nanos: n)
}

public func -(lhs: Google_Protobuf_Timestamp, rhs: Google_Protobuf_Timestamp) -> Google_Protobuf_Duration {
    return normalizedDuration(seconds: lhs.seconds - rhs.seconds, nanos: lhs.nanos - rhs.nanos)
}

public func -(lhs: Google_Protobuf_Duration, rhs: Google_Protobuf_Duration) -> Google_Protobuf_Duration {
    return normalizedDuration(seconds: lhs.seconds - rhs.seconds, nanos: lhs.nanos - rhs.nanos)
}

public func+(lhs: Google_Protobuf_Duration, rhs: Google_Protobuf_Duration) -> Google_Protobuf_Duration {
    return normalizedDuration(seconds: lhs.seconds + rhs.seconds, nanos: lhs.nanos + rhs.nanos)
}

public prefix func -(operand: Google_Protobuf_Duration) -> Google_Protobuf_Duration {
    return normalizedDuration(seconds: -operand.seconds, nanos: -operand.nanos)
}
