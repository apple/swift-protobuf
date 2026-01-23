// Tests/SwiftProtobufTests/Test_Duration.swift - Exercise well-known Duration type
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Duration type includes custom JSON format, some hand-implemented convenience
/// methods, and arithmetic operators.
///
// -----------------------------------------------------------------------------

import Foundation
import SwiftProtobuf
import XCTest

final class Test_Duration: XCTestCase, PBTestHelpers {
    typealias MessageTestType = Google_Protobuf_Duration

    func testJSON_encode() throws {
        assertJSONEncode("\"100s\"") { (o: inout MessageTestType) in
            o.seconds = 100
            o.nanos = 0
        }
        assertJSONEncode("\"-5s\"") { (o: inout MessageTestType) in
            o.seconds = -5
            o.nanos = 0
        }
        assertJSONEncode("\"-0.500s\"") { (o: inout MessageTestType) in
            o.seconds = 0
            o.nanos = -500_000_000
        }
        // Always prints exactly 3, 6, or 9 digits
        assertJSONEncode("\"100.100s\"") { (o: inout MessageTestType) in
            o.seconds = 100
            o.nanos = 100_000_000
        }
        assertJSONEncode("\"100.001s\"") { (o: inout MessageTestType) in
            o.seconds = 100
            o.nanos = 1_000_000
        }
        assertJSONEncode("\"100.000100s\"") { (o: inout MessageTestType) in
            o.seconds = 100
            o.nanos = 100000
        }
        assertJSONEncode("\"100.000001s\"") { (o: inout MessageTestType) in
            o.seconds = 100
            o.nanos = 1000
        }
        assertJSONEncode("\"100.000000100s\"") { (o: inout MessageTestType) in
            o.seconds = 100
            o.nanos = 100
        }
        assertJSONEncode("\"100.000000001s\"") { (o: inout MessageTestType) in
            o.seconds = 100
            o.nanos = 1
        }

        // Negative durations
        assertJSONEncode("\"-100.100s\"") { (o: inout MessageTestType) in
            o.seconds = -100
            o.nanos = -100_000_000
        }
    }

    func testJSON_decode() throws {
        assertJSONDecodeSucceeds("\"1.000000000s\"") { (o: MessageTestType) in
            o.seconds == 1 && o.nanos == 0
        }

        assertJSONDecodeSucceeds("\"-5s\"") { (o: MessageTestType) in
            o.seconds == -5 && o.nanos == 0
        }
        assertJSONDecodeSucceeds("\"-0.5s\"") { (o: MessageTestType) in
            o.seconds == 0 && o.nanos == -500_000_000
        }

        assertJSONDecodeSucceeds("\"-315576000000.999999999s\"") { (o: MessageTestType) in
            o.seconds == -315_576_000_000 && o.nanos == -999_999_999
        }
        assertJSONDecodeFails("\"-315576000001s\"")
        assertJSONDecodeSucceeds("\"315576000000.999999999s\"") { (o: MessageTestType) in
            o.seconds == 315_576_000_000 && o.nanos == 999_999_999
        }
        assertJSONDecodeFails("\"315576000001s\"")

        assertJSONDecodeFails("\"999999999999999999999.999999999s\"")
        assertJSONDecodeFails("\"\"")
        assertJSONDecodeFails("100.100s")
        assertJSONDecodeFails("\"-100.-100s\"")
        assertJSONDecodeFails("\"100.001\"")
        assertJSONDecodeFails("\"100.001sXXX\"")
    }

    func testSerializationFailure() throws {
        let maxOutOfRange = Google_Protobuf_Duration(seconds: -315_576_000_001)
        XCTAssertThrowsError(try maxOutOfRange.jsonString())
        let minInRange = Google_Protobuf_Duration(seconds: -315_576_000_000, nanos: -999_999_999)
        let _ = try minInRange.jsonString()  // Assert does not throw
        let maxInRange = Google_Protobuf_Duration(seconds: 315_576_000_000, nanos: 999_999_999)
        let _ = try maxInRange.jsonString()  // Assert does not throw
        let minOutOfRange = Google_Protobuf_Duration(seconds: 315_576_000_001)
        XCTAssertThrowsError(try minOutOfRange.jsonString())
        // Signs don't match (a conformance test).
        let posNeg = Google_Protobuf_Duration(seconds: 1, nanos: -1)
        XCTAssertThrowsError(try posNeg.jsonString())
        let negPos = Google_Protobuf_Duration(seconds: -1, nanos: 1)
        XCTAssertThrowsError(try negPos.jsonString())
        // Nanos only out of range (a conformance test).
        let nanosTooSmall = Google_Protobuf_Duration(seconds: 0, nanos: -1_000_000_000)
        XCTAssertThrowsError(try nanosTooSmall.jsonString())
        let nanosTooBig = Google_Protobuf_Duration(seconds: 0, nanos: 1_000_000_001)
        XCTAssertThrowsError(try nanosTooBig.jsonString())
    }

    // Make sure durations work correctly when stored in a field
    func testJSON_durationField() throws {
        do {
            let valid = try SwiftProtoTesting_Test3_TestAllTypesProto3(jsonString: "{\"optionalDuration\": \"1.001s\"}")
            XCTAssertEqual(valid.optionalDuration, Google_Protobuf_Duration(seconds: 1, nanos: 1_000_000))
        } catch {
            XCTFail("Should have decoded correctly")
        }

        XCTAssertThrowsError(
            try SwiftProtoTesting_Test3_TestAllTypesProto3(
                jsonString: "{\"optionalDuration\": \"-315576000001.000000000s\"}"
            )
        )

        XCTAssertThrowsError(
            try SwiftProtoTesting_Test3_TestAllTypesProto3(
                jsonString: "{\"optionalDuration\": \"315576000001.000000000s\"}"
            )
        )
        XCTAssertThrowsError(
            try SwiftProtoTesting_Test3_TestAllTypesProto3(jsonString: "{\"optionalDuration\": \"1.001\"}")
        )
    }

    func testFieldMember() throws {
        // Verify behavior when a duration appears as a field on a larger object
        let json1 = "{\"optionalDuration\": \"-315576000000.999999999s\"}"
        let m1 = try SwiftProtoTesting_Test3_TestAllTypesProto3(jsonString: json1)
        XCTAssertEqual(m1.optionalDuration.seconds, -315_576_000_000)
        XCTAssertEqual(m1.optionalDuration.nanos, -999_999_999)

        let json2 = "{\"repeatedDuration\": [\"1.5s\", \"-1.5s\"]}"
        let expected2 = [
            Google_Protobuf_Duration(seconds: 1, nanos: 500_000_000),
            Google_Protobuf_Duration(seconds: -1, nanos: -500_000_000),
        ]
        let actual2 = try SwiftProtoTesting_Test3_TestAllTypesProto3(jsonString: json2)
        XCTAssertEqual(actual2.repeatedDuration, expected2)
    }

    func testTranscode() throws {
        let jsonMax = "{\"optionalDuration\": \"315576000000.999999999s\"}"
        let parsedMax = try SwiftProtoTesting_Test3_TestAllTypesProto3(jsonString: jsonMax)
        XCTAssertEqual(parsedMax.optionalDuration.seconds, 315_576_000_000)
        XCTAssertEqual(parsedMax.optionalDuration.nanos, 999_999_999)
        XCTAssertEqual(
            try parsedMax.serializedBytes(),
            [234, 18, 13, 8, 128, 188, 174, 206, 151, 9, 16, 255, 147, 235, 220, 3]
        )
        let jsonMin = "{\"optionalDuration\": \"-315576000000.999999999s\"}"
        let parsedMin = try SwiftProtoTesting_Test3_TestAllTypesProto3(jsonString: jsonMin)
        XCTAssertEqual(parsedMin.optionalDuration.seconds, -315_576_000_000)
        XCTAssertEqual(parsedMin.optionalDuration.nanos, -999_999_999)
        XCTAssertEqual(
            try parsedMin.serializedBytes(),
            [
                234, 18, 22, 8, 128, 196, 209, 177, 232, 246, 255, 255, 255, 1, 16, 129, 236, 148, 163, 252, 255, 255,
                255, 255, 1,
            ]
        )
    }

    func testConformance() throws {
        let tooSmall = try SwiftProtoTesting_Test3_TestAllTypesProto3(serializedBytes: [
            234, 18, 11, 8, 255, 195, 209, 177, 232, 246, 255, 255, 255, 1,
        ])
        XCTAssertEqual(tooSmall.optionalDuration.seconds, -315_576_000_001)
        XCTAssertEqual(tooSmall.optionalDuration.nanos, 0)
        XCTAssertThrowsError(try tooSmall.jsonString())

        let tooBig = try SwiftProtoTesting_Test3_TestAllTypesProto3(serializedBytes: [
            234, 18, 7, 8, 129, 188, 174, 206, 151, 9,
        ])
        XCTAssertEqual(tooBig.optionalDuration.seconds, 315_576_000_001)
        XCTAssertEqual(tooBig.optionalDuration.nanos, 0)
        XCTAssertThrowsError(try tooBig.jsonString())
    }

    func testBasicArithmetic() throws {
        let an2_n2 = Google_Protobuf_Duration(seconds: -2, nanos: -2)
        let an1_n1 = Google_Protobuf_Duration(seconds: -1, nanos: -1)
        let a0 = Google_Protobuf_Duration()
        let a1_1 = Google_Protobuf_Duration(seconds: 1, nanos: 1)
        let a2_2 = Google_Protobuf_Duration(seconds: 2, nanos: 2)
        let a3_3 = Google_Protobuf_Duration(seconds: 3, nanos: 3)
        let a4_4 = Google_Protobuf_Duration(seconds: 4, nanos: 4)
        XCTAssertEqual(a1_1, a0 + a1_1)
        XCTAssertEqual(a1_1, a1_1 + a0)
        XCTAssertEqual(a2_2, a1_1 + a1_1)
        XCTAssertEqual(a3_3, a1_1 + a2_2)
        XCTAssertEqual(a1_1, a4_4 - a3_3)
        XCTAssertEqual(an1_n1, a3_3 - a4_4)
        XCTAssertEqual(an1_n1, a3_3 + -a4_4)
        XCTAssertEqual(an1_n1, -a1_1)
        XCTAssertEqual(a2_2, -an2_n2)
        XCTAssertEqual(a2_2, -an2_n2)
    }

    func testArithmeticNormalizes() throws {
        // Addition normalizes the result
        XCTAssertEqual(
            Google_Protobuf_Duration(seconds: 1, nanos: 500_000_000)
                + Google_Protobuf_Duration(seconds: 1, nanos: 500_000_001),
            Google_Protobuf_Duration(seconds: 3, nanos: 1)
        )
        XCTAssertEqual(
            Google_Protobuf_Duration(seconds: -1, nanos: -500_000_000)
                + Google_Protobuf_Duration(seconds: -1, nanos: -500_000_001),
            Google_Protobuf_Duration(seconds: -3, nanos: -1)
        )
        // Subtraction normalizes the result
        XCTAssertEqual(
            Google_Protobuf_Duration(seconds: 0, nanos: -700_000_000)
                - Google_Protobuf_Duration(seconds: 1, nanos: 500_000_000),
            Google_Protobuf_Duration(seconds: -2, nanos: -200_000_000)
        )
        XCTAssertEqual(
            Google_Protobuf_Duration(seconds: 5, nanos: 0) - Google_Protobuf_Duration(seconds: 2, nanos: 1),
            Google_Protobuf_Duration(seconds: 2, nanos: 999_999_999)
        )
        XCTAssertEqual(
            Google_Protobuf_Duration(seconds: 0, nanos: 0) - Google_Protobuf_Duration(seconds: 2, nanos: 1),
            Google_Protobuf_Duration(seconds: -2, nanos: -1)
        )
        // Unary minus normalizes the result (because it should match doing `Duration(0,0) - operand`.
        XCTAssertEqual(
            -Google_Protobuf_Duration(seconds: 0, nanos: 2_000_000_001),
            Google_Protobuf_Duration(seconds: -2, nanos: -1)
        )
        XCTAssertEqual(
            -Google_Protobuf_Duration(seconds: 0, nanos: -2_000_000_001),
            Google_Protobuf_Duration(seconds: 2, nanos: 1)
        )
        XCTAssertEqual(
            -Google_Protobuf_Duration(seconds: 1, nanos: -2_000_000_001),
            Google_Protobuf_Duration(seconds: 1, nanos: 1)
        )
        XCTAssertEqual(
            -Google_Protobuf_Duration(seconds: -1, nanos: 2_000_000_001),
            Google_Protobuf_Duration(seconds: -1, nanos: -1)
        )
        XCTAssertEqual(
            -Google_Protobuf_Duration(seconds: -1, nanos: -2_000_000_001),
            Google_Protobuf_Duration(seconds: 3, nanos: 1)
        )
        XCTAssertEqual(
            -Google_Protobuf_Duration(seconds: 1, nanos: 2_000_000_001),
            Google_Protobuf_Duration(seconds: -3, nanos: -1)
        )
    }

    func testFloatLiteralConvertible() throws {
        var a: Google_Protobuf_Duration = 1.5
        XCTAssertEqual(a, Google_Protobuf_Duration(seconds: 1, nanos: 500_000_000))
        a = 100.000000001
        XCTAssertEqual(a, Google_Protobuf_Duration(seconds: 100, nanos: 1))
        a = 1.9999999991
        XCTAssertEqual(a, Google_Protobuf_Duration(seconds: 1, nanos: 999_999_999))
        a = 1.9999999999
        XCTAssertEqual(a, Google_Protobuf_Duration(seconds: 2, nanos: 0))

        var c = SwiftProtoTesting_Test3_TestAllTypesProto3()
        c.optionalDuration = 100.000000001
        XCTAssertEqual([234, 18, 4, 8, 100, 16, 1], try c.serializedBytes())
        XCTAssertEqual("{\"optionalDuration\":\"100.000000001s\"}", try c.jsonString())
    }

    func testInitializationRoundingTimeIntervals() throws {
        // Negative interval
        let t1 = Google_Protobuf_Duration(rounding: -123.456)
        XCTAssertEqual(t1.seconds, -123)
        XCTAssertEqual(t1.nanos, -456_000_000)

        // Full precision
        let t2 = Google_Protobuf_Duration(rounding: -123.999999999)
        XCTAssertEqual(t2.seconds, -123)
        XCTAssertEqual(t2.nanos, -999_999_999)

        // Value past percision, default and some explicit rules
        let t3 = Google_Protobuf_Duration(rounding: -123.9999999994)
        XCTAssertEqual(t3.seconds, -123)
        XCTAssertEqual(t3.nanos, -999_999_999)
        let t3u = Google_Protobuf_Duration(rounding: -123.9999999994, rule: .up)
        XCTAssertEqual(t3u.seconds, -123)
        XCTAssertEqual(t3u.nanos, -999_999_999)
        let t3d = Google_Protobuf_Duration(rounding: -123.9999999994, rule: .down)
        XCTAssertEqual(t3d.seconds, -124)
        XCTAssertEqual(t3d.nanos, 0)

        // Value past percision, default and some explicit rules
        let t4 = Google_Protobuf_Duration(rounding: -123.9999999996)
        XCTAssertEqual(t4.seconds, -124)
        XCTAssertEqual(t4.nanos, 0)
        let t4u = Google_Protobuf_Duration(rounding: -123.9999999996, rule: .up)
        XCTAssertEqual(t4u.seconds, -123)
        XCTAssertEqual(t4u.nanos, -999_999_999)
        let t4d = Google_Protobuf_Duration(rounding: -123.9999999996, rule: .down)
        XCTAssertEqual(t4d.seconds, -124)
        XCTAssertEqual(t4d.nanos, 0)

        let t5 = Google_Protobuf_Duration(rounding: 0)
        XCTAssertEqual(t5.seconds, 0)
        XCTAssertEqual(t5.nanos, 0)

        // Positive interval
        let t6 = Google_Protobuf_Duration(rounding: 123.456)
        XCTAssertEqual(t6.seconds, 123)
        XCTAssertEqual(t6.nanos, 456_000_000)

        // Full precision
        let t7 = Google_Protobuf_Duration(rounding: 123.999999999)
        XCTAssertEqual(t7.seconds, 123)
        XCTAssertEqual(t7.nanos, 999_999_999)

        // Value past percision, default and some explicit rules
        let t8 = Google_Protobuf_Duration(rounding: 123.9999999994)
        XCTAssertEqual(t8.seconds, 123)
        XCTAssertEqual(t8.nanos, 999_999_999)
        let t8u = Google_Protobuf_Duration(rounding: 123.9999999994, rule: .up)
        XCTAssertEqual(t8u.seconds, 124)
        XCTAssertEqual(t8u.nanos, 0)
        let t8d = Google_Protobuf_Duration(rounding: 123.9999999994, rule: .down)
        XCTAssertEqual(t8d.seconds, 123)
        XCTAssertEqual(t8d.nanos, 999_999_999)

        // Value past percision, default and some explicit rules
        let t9 = Google_Protobuf_Duration(rounding: 123.9999999996)
        XCTAssertEqual(t9.seconds, 124)
        XCTAssertEqual(t9.nanos, 0)
        let t9u = Google_Protobuf_Duration(rounding: 123.9999999996, rule: .up)
        XCTAssertEqual(t9u.seconds, 124)
        XCTAssertEqual(t9u.nanos, 0)
        let t9d = Google_Protobuf_Duration(rounding: 123.9999999996, rule: .down)
        XCTAssertEqual(t9d.seconds, 123)
        XCTAssertEqual(t9d.nanos, 999_999_999)
    }

    func testGetters() throws {
        let t1 = Google_Protobuf_Duration(seconds: -123, nanos: -123_456_789)
        XCTAssertEqual(t1.timeInterval, -123.123456789)

        let t2 = Google_Protobuf_Duration(seconds: 123, nanos: 123_456_789)
        XCTAssertEqual(t2.timeInterval, 123.123456789)
    }

    func testConvertFromStdlibDuration() throws {
        guard #available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *) else {
            throw XCTSkip("Duration is not supported on this platform")
        }

        // Full precision
        do {
            let sd = Duration.seconds(123) + .nanoseconds(123_456_789)
            let pd = Google_Protobuf_Duration(rounding: sd)
            XCTAssertEqual(pd.seconds, 123)
            XCTAssertEqual(pd.nanos, 123_456_789)
        }

        // Default rounding (toNearestAwayFromZero)
        do {
            let sd = Duration(secondsComponent: 123, attosecondsComponent: 123_456_789_499_999_999)
            let pd = Google_Protobuf_Duration(rounding: sd)
            XCTAssertEqual(pd.seconds, 123)
            XCTAssertEqual(pd.nanos, 123_456_789)
        }
        do {
            let sd = Duration(secondsComponent: 123, attosecondsComponent: 123_456_789_500_000_000)
            let pd = Google_Protobuf_Duration(rounding: sd)
            XCTAssertEqual(pd.seconds, 123)
            XCTAssertEqual(pd.nanos, 123_456_790)
        }

        // Other rounding rules
        do {
            let sd = Duration(secondsComponent: 123, attosecondsComponent: 123_456_789_499_999_999)
            let pd = Google_Protobuf_Duration(rounding: sd, rule: .awayFromZero)
            XCTAssertEqual(pd.seconds, 123)
            XCTAssertEqual(pd.nanos, 123_456_790)
        }
        do {
            let sd = Duration(secondsComponent: 123, attosecondsComponent: 123_456_789_999_999_999)
            let pd = Google_Protobuf_Duration(rounding: sd, rule: .towardZero)
            XCTAssertEqual(pd.seconds, 123)
            XCTAssertEqual(pd.nanos, 123_456_789)
        }

        // Negative duration
        do {
            let sd = Duration.zero - .seconds(123) - .nanoseconds(123_456_789)
            let pd = Google_Protobuf_Duration(rounding: sd)
            XCTAssertEqual(pd.seconds, -123)
            XCTAssertEqual(pd.nanos, -123_456_789)
        }
        do {
            let sd = .zero - Duration(secondsComponent: 123, attosecondsComponent: 123_456_789_000_000_001)
            let pd = Google_Protobuf_Duration(rounding: sd, rule: .towardZero)
            XCTAssertEqual(pd.seconds, -123)
            XCTAssertEqual(pd.nanos, -123_456_789)
        }
        do {
            let sd = .zero - Duration(secondsComponent: 123, attosecondsComponent: 123_456_789_000_000_001)
            let pd = Google_Protobuf_Duration(rounding: sd, rule: .awayFromZero)
            XCTAssertEqual(pd.seconds, -123)
            XCTAssertEqual(pd.nanos, -123_456_790)
        }
    }

    func testConvertToStdlibDuration() throws {
        guard #available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *) else {
            throw XCTSkip("Duration is not supported on this platform")
        }

        do {
            let pd = Google_Protobuf_Duration(seconds: 123, nanos: 123_456_789)
            let sd = Duration(pd)
            XCTAssertEqual(sd, .seconds(123) + .nanoseconds(123_456_789))
        }
        // Negative duration
        do {
            let pd = Google_Protobuf_Duration(seconds: -123, nanos: -123_456_789)
            let sd = Duration(pd)
            XCTAssertEqual(sd, .zero - (.seconds(123) + .nanoseconds(123_456_789)))
        }
    }
}
