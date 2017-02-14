// Sources/SwiftProtobuf/TimeUtils.swift - Generally useful time/calendar functions
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Generally useful time/calendar functions and constants
///
// -----------------------------------------------------------------------------

import Swift

let minutesPerDay: Int32 = 1440
let minutesPerHour: Int32 = 60
let secondsPerDay: Int32 = 86400
let secondsPerHour: Int32 = 3600
let secondsPerMinute: Int32 = 60
let nanosPerSecond: Int32 = 1000000000

func timeOfDayFromSecondsSince1970(seconds: Int64) -> (hh: Int32, mm: Int32, ss: Int32) {
    let secondsSinceMidnight = Int32(mod(seconds, 86400))
    let ss = mod(secondsSinceMidnight, 60)
    let mm = mod(div(secondsSinceMidnight, 60), 60)
    let hh = div(secondsSinceMidnight, 3600)
    
    return (hh: hh, mm: mm, ss: ss)
}

func julianDayNumberFromSecondsSince1970(seconds: Int64) -> Int64 {
    return div(seconds + 210866803200, 86400)
}

func gregorianDateFromSecondsSince1970(seconds: Int64) -> (YY: Int32, MM: Int32, DD: Int32) {
    // The following implements Richards' algorithm (see the Wikipedia article
    // for "Julian day").
    // If you touch this code, please test it exhaustively by playing with
    // Test_Timestamp.testJSON_range.

    let JJ = julianDayNumberFromSecondsSince1970(seconds: seconds)
    let f = JJ + 1401 + div(div(4 * JJ + 274277, 146097) * 3, 4) - 38
    let e = 4 * f + 3
    let g = div(mod(e, 1461), 4)
    let h = 5 * g + 2
    let DD = div(mod(h, 153), 5) + 1
    let MM = mod(div(h, 153) + 2, 12) + 1
    let YY = div(e, 1461) - 4716 + div(12 + 2 - MM, 12)
    
    return (YY: Int32(YY), MM: Int32(MM), DD: Int32(DD))
}
