// ProtobufRuntime/Sources/Protobuf/Google_Protobuf_Timestamp_Extensions.swift - Timestamp extensions
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
/// Extend the generated Timestamp message with customized JSON coding,
/// arithmetic operations, and convenience methods.
///
// -----------------------------------------------------------------------------

import Swift

// TODO: Add convenience methods to interoperate with standard
// date/time classes:  an initializer that accepts Unix timestamp as
// Int or Double, an easy way to convert to/from Foundation's
// NSDateTime (on Apple platforms only?), others?

private func FormatInt(n: Int32, digits: Int) -> String {
    if n < 0 {
        return FormatInt(n: -n, digits: digits)
    } else if digits <= 0 {
        return ""
    } else if digits == 1 && n < 10 {
        return ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"][Int(n)]
    } else {
        return FormatInt(n: n / 10, digits: digits - 1) +  ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"][Int(n % 10)]
    }
}

private func fromAscii2(_ digit0: Int, _ digit1: Int) throws -> Int {
    let zero = Int(48)
    let nine = Int(57)

    if digit0 < zero || digit0 > nine || digit1 < zero || digit1 > nine {
        throw ProtobufDecodingError.malformedJSONTimestamp
    }
    return digit0 * 10 + digit1 - 528
}

private func fromAscii4(_ digit0: Int, _ digit1: Int, _ digit2: Int, _ digit3: Int) throws -> Int {
    let zero = Int(48)
    let nine = Int(57)

    if (digit0 < zero || digit0 > nine
        || digit1 < zero || digit1 > nine
        || digit2 < zero || digit2 > nine
        || digit3 < zero || digit3 > nine) {
        throw ProtobufDecodingError.malformedJSONTimestamp
    }
    return digit0 * 1000 + digit1 * 100 + digit2 * 10 + digit3 - 53328
}

// Parse an RFC3339 timestamp into a pair of seconds-since-1970 and nanos.
private func parseTimestamp(s: String) throws -> (Int64, Int32) {
    // Convert to an array of integer character values
    let value = s.utf8.map{Int($0)}
    if value.count < 20 {
        throw ProtobufDecodingError.malformedJSONTimestamp
    }
    // Since the format is fixed-layout, we can just decode
    // directly as follows.
    let zero = Int(48)
    let nine = Int(57)
    let dash = Int(45)
    let colon = Int(58)
    let plus = Int(43)
    let letterT = Int(84)
    let letterZ = Int(90)
    let period = Int(46)

    // Year: 4 digits followed by '-'
    let year = try fromAscii4(value[0], value[1], value[2], value[3])
    if value[4] != dash || year < Int(1) || year > Int(9999) {
        throw ProtobufDecodingError.malformedJSONTimestamp
    }

    // Month: 2 digits followed by '-'
    let month = try fromAscii2(value[5], value[6])
    if value[7] != dash || month < Int(1) || month > Int(12) {
        throw ProtobufDecodingError.malformedJSONTimestamp
    }

    // Day: 2 digits followed by 'T'
    let mday = try fromAscii2(value[8], value[9])
    if value[10] != letterT || mday < Int(1) || mday > Int(31) {
        throw ProtobufDecodingError.malformedJSONTimestamp
    }

    // Hour: 2 digits followed by ':'
    let hour = try fromAscii2(value[11], value[12])
    if value[13] != colon || hour > Int(23) {
        throw ProtobufDecodingError.malformedJSONTimestamp
    }

    // Minute: 2 digits followed by ':'
    let minute = try fromAscii2(value[14], value[15])
    if value[16] != colon || minute > Int(59) {
        throw ProtobufDecodingError.malformedJSONTimestamp
    }

    // Second: 2 digits (following char is checked below)
    let second = try fromAscii2(value[17], value[18])
    if second > Int(61) {
        throw ProtobufDecodingError.malformedJSONTimestamp
    }

    // timegm() is almost entirely useless.  It's nonexistent on
    // some platforms, broken on others.  Everything else I've tried
    // is even worse.  Hence the code below.
    // (If you have a better way to do this, try it and see if it
    // passes the test suite on both Linux and OS X.)

    // Day of year
    let mdayStart: [Int] = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334]
    var yday = Int64(mdayStart[month - 1])
    let isleap = (year % 400 == 0) || ((year % 100 != 0) && (year % 4 == 0))
    if isleap && (month > 2) {
        yday += 1
    }
    yday += Int64(mday - 1)

    // Days since start of epoch (including leap days)
    var daysSinceEpoch = yday
    daysSinceEpoch += Int64(365 * year) - Int64(719527)
    daysSinceEpoch += Int64((year - 1) / 4)
    daysSinceEpoch -= Int64((year - 1) / 100)
    daysSinceEpoch += Int64((year - 1) / 400)

    // Second within day
    var daySec = Int64(hour)
    daySec *= 60
    daySec += Int64(minute)
    daySec *= 60
    daySec += Int64(second)

    // Seconds since start of epoch
    let t = daysSinceEpoch * Int64(86400) + daySec

    // After seconds, comes various optional bits
    var pos = 19

    var nanos: Int32 = 0
    if value[pos] == period { // "." begins fractional seconds
        pos += 1
        var digitValue = 100000000
        while pos < value.count && value[pos] >= zero && value[pos] <= nine {
            nanos += digitValue * (value[pos] - zero)
            digitValue /= 10
            pos += 1
        }
    }

    var seconds: Int64 = 0
    if value[pos] == plus || value[pos] == dash { // "+" or "-" starts Timezone offset
        if pos + 6 > value.count {
            throw ProtobufDecodingError.malformedJSONTimestamp
        }
        let hourOffset = try fromAscii2(value[pos + 1], value[pos + 2])
        let minuteOffset = try fromAscii2(value[pos + 4], value[pos + 5])
        if hourOffset > Int(13) || minuteOffset > Int(59) || value[pos + 3] != colon {
            throw ProtobufDecodingError.malformedJSONTimestamp
        }
        var adjusted: Int64 = t
        if value[pos] == plus {
            adjusted -= Int64(hourOffset) * Int64(3600)
            adjusted -= Int64(minuteOffset) * Int64(60)
        } else {
            adjusted += Int64(hourOffset) * Int64(3600)
            adjusted += Int64(minuteOffset) * Int64(60)
        }
        if adjusted < -62135596800 || adjusted > 253402300799 {
            throw ProtobufDecodingError.malformedJSONTimestamp
        }
        seconds = adjusted
        pos += 6
    } else if value[pos] == letterZ { // "Z" indicator for UTC
        seconds = t
        pos += 1
    } else {
        throw ProtobufDecodingError.malformedJSONTimestamp
    }
    if pos != value.count {
        throw ProtobufDecodingError.malformedJSONTimestamp
    }
    return (seconds, nanos)
}

private func formatTimestamp(seconds: Int64, nanos: Int32) -> String? {
    if ((seconds < 0 && nanos > 0)
        || (seconds > 0 && nanos < 0)
        || (seconds < -62135596800)
        || (seconds == -62135596800 && nanos < 0)
        || (seconds >= 253402300800)) {
            return nil
    }

    // Can't just use gmtime() here because time_t is sometimes 32 bits. Ugh.
    let secondsSinceStartOfDay = (Int32(seconds % 86400) + 86400) % 86400
    let sec = secondsSinceStartOfDay % 60
    let min = (secondsSinceStartOfDay / 60) % 60
    let hour = secondsSinceStartOfDay / 3600

    // The following implements Richards' algorithm (see the Wikipedia article
    // for "Julian day").
    // If you touch this code, please test it exhaustively by playing with
    // Test_Timestamp.testJSON_range.
    let julian = (seconds + 210866803200) / 86400
    let f = julian + 1401 + (((4 * julian + 274277) / 146097) * 3) / 4 - 38
    let e = 4 * f + 3
    let g = e % 1461 / 4
    let h = 5 * g + 2
    let mday = Int32(h % 153 / 5 + 1)
    let month = (h / 153 + 2) % 12 + 1
    let year = e / 1461 - 4716 + (12 + 2 - month) / 12

    // We can't use strftime here (it varies with locale)
    // We can't use strftime_l here (it's not portable)
    // The following is crude, but it works.
    // TODO: If String(format:) works, that might be even better
    // (it was broken on Linux a while back...)
    let result = (FormatInt(n: Int32(year), digits: 4)
        + "-"
        + FormatInt(n: Int32(month), digits: 2)
        + "-"
        + FormatInt(n: mday, digits: 2)
        + "T"
        + FormatInt(n: hour, digits: 2)
        + ":"
        + FormatInt(n: min, digits: 2)
        + ":"
        + FormatInt(n: sec, digits: 2))
    if nanos == 0 {
        return "\(result)Z"
    } else {
        var digits: Int
        var fraction: Int
        if nanos % 1000000 == 0 {
            fraction = Int(nanos) / 1000000
            digits = 3
        } else if nanos % 1000 == 0 {
            fraction = Int(nanos) / 1000
            digits = 6
        } else {
            fraction = Int(nanos)
            digits = 9
        }
        var formatted_fraction = ""
        while digits > 0 {
            formatted_fraction = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"][fraction % 10] + formatted_fraction
            fraction /= 10
            digits -= 1
        }
        return "\(result).\(formatted_fraction)Z"
    }
}


public extension Google_Protobuf_Timestamp {
    public init(secondsSinceEpoch: Int64, nanos: Int32 = 0) {
        self.init()
        self.seconds = secondsSinceEpoch
        self.nanos = nanos
    }

    public mutating func decodeFromJSONToken(token: ProtobufJSONToken) throws {
        if case .string(let s) = token {
            let timestamp = try parseTimestamp(s: s)
            seconds = timestamp.0
            nanos = timestamp.1
        } else {
            throw ProtobufDecodingError.schemaMismatch
        }
    }

    public func serializeJSON() throws -> String {
        let s = seconds
        let n = nanos
        if let formatted = formatTimestamp(seconds: s, nanos: n) {
            return "\"\(formatted)\""
        } else {
            throw ProtobufEncodingError.timestampJSONRange
        }
    }

    func serializeAnyJSON() throws -> String {
        let value = try serializeJSON()
        return "{\"@type\":\"\(anyTypeURL)\",\"value\":\(value)}"
    }
}

private func normalizedTimestamp(seconds: Int64, nanos: Int32) -> Google_Protobuf_Timestamp {
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
    return Google_Protobuf_Timestamp(seconds: s, nanos: n)
}

public func -(lhs: Google_Protobuf_Timestamp, rhs: Google_Protobuf_Duration) -> Google_Protobuf_Timestamp {
    return normalizedTimestamp(seconds: lhs.seconds - rhs.seconds, nanos: lhs.nanos - rhs.nanos)
}

public func+(lhs: Google_Protobuf_Timestamp, rhs: Google_Protobuf_Duration) -> Google_Protobuf_Timestamp {
    return normalizedTimestamp(seconds: lhs.seconds + rhs.seconds, nanos: lhs.nanos + rhs.nanos)
}

