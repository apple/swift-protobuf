// Tests/ExperimentalTableDrivenSwiftProtobufTests/Test_JSON.swift - Exercise JSON coding
//
// Copyright (c) 2014 - 2026 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// This is a set of tests for JSON protobuf files.
///
// -----------------------------------------------------------------------------

import Foundation
import SwiftProtobuf
import XCTest

final class Test_JSON: XCTestCase {
    typealias MessageTestType = SwiftProtoTesting_TestAllTypes

    func testOptionalInt32() {
        assertJSONEncode("{\"optionalInt32\":1}") { (o: inout MessageTestType) in
            o.optionalInt32 = 1
        }
        assertJSONEncode("{\"optionalInt32\":2147483647}") { (o: inout MessageTestType) in
            o.optionalInt32 = Int32.max
        }
        assertJSONEncode("{\"optionalInt32\":-2147483648}") { (o: inout MessageTestType) in
            o.optionalInt32 = Int32.min
        }
        // 32-bit overflow
        assertJSONDecodeFails("{\"optionalInt32\":2147483648}")
        // Explicit 'null' is permitted, proto3 decodes it to default value
        assertJSONDecodeSucceeds("{\"optionalInt32\":null}") { (o: MessageTestType) in
            o.optionalInt32 == 0
        }
        // Quoted or unquoted numbers, positive, negative, or zero
        assertJSONDecodeSucceeds("{\"optionalInt32\":1}") { (o: MessageTestType) in
            o.optionalInt32 == 1
        }
        assertJSONDecodeSucceeds("{\"optionalInt32\":\"1\"}") { (o: MessageTestType) in
            o.optionalInt32 == 1
        }
        assertJSONDecodeSucceeds("{\"optionalInt32\":\"\\u0030\"}") { (o: MessageTestType) in
            o.optionalInt32 == 0
        }
        assertJSONDecodeSucceeds("{\"optionalInt32\":\"\\u0031\"}") { (o: MessageTestType) in
            o.optionalInt32 == 1
        }
        assertJSONDecodeSucceeds("{\"optionalInt32\":\"\\u00310\"}") { (o: MessageTestType) in
            o.optionalInt32 == 10
        }
        assertJSONDecodeSucceeds("{\"optionalInt32\":0}") { (o: MessageTestType) in
            o.optionalInt32 == 0
        }
        assertJSONDecodeSucceeds("{\"optionalInt32\":\"0\"}") { (o: MessageTestType) in
            o.optionalInt32 == 0
        }
        assertJSONDecodeSucceeds("{\"optionalInt32\":-0}") { (o: MessageTestType) in
            o.optionalInt32 == 0
        }
        assertJSONDecodeSucceeds("{\"optionalInt32\":\"-0\"}") { (o: MessageTestType) in
            o.optionalInt32 == 0
        }
        assertJSONDecodeSucceeds("{\"optionalInt32\":-1}") { (o: MessageTestType) in
            o.optionalInt32 == -1
        }
        assertJSONDecodeSucceeds("{\"optionalInt32\":\"-1\"}") { (o: MessageTestType) in
            o.optionalInt32 == -1
        }
        // JSON RFC does not accept leading zeros
        assertJSONDecodeFails("{\"optionalInt32\":00000000000000000000001}")
        assertJSONDecodeFails("{\"optionalInt32\":\"01\"}")
        assertJSONDecodeFails("{\"optionalInt32\":-01}")
        assertJSONDecodeFails("{\"optionalInt32\":\"-00000000000000000000001\"}")
        // Exponents are okay, as long as result is integer
        assertJSONDecodeSucceeds("{\"optionalInt32\":2.147483647e9}") { (o: MessageTestType) in
            o.optionalInt32 == Int32.max
        }
        assertJSONDecodeSucceeds("{\"optionalInt32\":-2.147483648e9}") { (o: MessageTestType) in
            o.optionalInt32 == Int32.min
        }
        assertJSONDecodeSucceeds("{\"optionalInt32\":1e3}") { (o: MessageTestType) in
            o.optionalInt32 == 1000
        }
        assertJSONDecodeSucceeds("{\"optionalInt32\":100e-2}") { (o: MessageTestType) in
            o.optionalInt32 == 1
        }
        assertJSONDecodeFails("{\"optionalInt32\":1e-1}")
        // Reject malformed input
        assertJSONDecodeFails("{\"optionalInt32\":\\u0031}")
        assertJSONDecodeFails("{\"optionalInt32\":\"\\u0030\\u0030\"}")
        assertJSONDecodeFails("{\"optionalInt32\":\" 1\"}")
        assertJSONDecodeFails("{\"optionalInt32\":\"1 \"}")
        assertJSONDecodeFails("{\"optionalInt32\":\"01\"}")
        assertJSONDecodeFails("{\"optionalInt32\":true}")
        assertJSONDecodeFails("{\"optionalInt32\":0x102}")
        assertJSONDecodeFails("{\"optionalInt32\":{}}")
        assertJSONDecodeFails("{\"optionalInt32\":[]}")
        // Try to get the library to access past the end of the string...
        assertJSONDecodeFails("{\"optionalInt32\":0")
        assertJSONDecodeFails("{\"optionalInt32\":-0")
        assertJSONDecodeFails("{\"optionalInt32\":0.1")
        assertJSONDecodeFails("{\"optionalInt32\":0.")
        assertJSONDecodeFails("{\"optionalInt32\":1")
        assertJSONDecodeFails("{\"optionalInt32\":\"")
        assertJSONDecodeFails("{\"optionalInt32\":\"1")
        assertJSONDecodeFails("{\"optionalInt32\":\"1\"")
        assertJSONDecodeFails("{\"optionalInt32\":1.")
        assertJSONDecodeFails("{\"optionalInt32\":1e")
        assertJSONDecodeFails("{\"optionalInt32\":1e1")
        assertJSONDecodeFails("{\"optionalInt32\":-1")
        assertJSONDecodeFails("{\"optionalInt32\":123e")
        assertJSONDecodeFails("{\"optionalInt32\":123.")
        assertJSONDecodeFails("{\"optionalInt32\":123")
    }

    func testOptionalUInt32() {
        assertJSONEncode("{\"optionalUint32\":1}") { (o: inout MessageTestType) in
            o.optionalUint32 = 1
        }
        assertJSONEncode("{\"optionalUint32\":4294967295}") { (o: inout MessageTestType) in
            o.optionalUint32 = UInt32.max
        }
        assertJSONDecodeFails("{\"optionalUint32\":4294967296}")
        // Explicit 'null' is permitted, decodes to default
        assertJSONDecodeSucceeds("{\"optionalUint32\":null}") { $0.optionalUint32 == 0 }
        // Quoted or unquoted numbers, positive, negative, or zero
        assertJSONDecodeSucceeds("{\"optionalUint32\":1}") { $0.optionalUint32 == 1 }
        assertJSONDecodeSucceeds("{\"optionalUint32\":\"1\"}") { $0.optionalUint32 == 1 }
        assertJSONDecodeSucceeds("{\"optionalUint32\":0}") { $0.optionalUint32 == 0 }
        assertJSONDecodeSucceeds("{\"optionalUint32\":\"0\"}") { $0.optionalUint32 == 0 }
        // Protobuf JSON does not accept leading zeros
        assertJSONDecodeFails("{\"optionalUint32\":01}")
        assertJSONDecodeFails("{\"optionalUint32\":\"01\"}")
        // But it does accept exponential (as long as result is integral)
        assertJSONDecodeSucceeds("{\"optionalUint32\":4.294967295e9}") { $0.optionalUint32 == UInt32.max }
        assertJSONDecodeSucceeds("{\"optionalUint32\":1e3}") { $0.optionalUint32 == 1000 }
        assertJSONDecodeSucceeds("{\"optionalUint32\":1.2e3}") { $0.optionalUint32 == 1200 }
        assertJSONDecodeSucceeds("{\"optionalUint32\":1000e-2}") { $0.optionalUint32 == 10 }
        assertJSONDecodeSucceeds("{\"optionalUint32\":1.0}") { $0.optionalUint32 == 1 }
        assertJSONDecodeSucceeds("{\"optionalUint32\":1.000000e2}") { $0.optionalUint32 == 100 }
        assertJSONDecodeFails("{\"optionalUint32\":1e-3}")
        assertJSONDecodeFails("{\"optionalUint32\":1")
        assertJSONDecodeFails("{\"optionalUint32\":\"")
        assertJSONDecodeFails("{\"optionalUint32\":\"1")
        assertJSONDecodeFails("{\"optionalUint32\":\"1\"")
        assertJSONDecodeFails("{\"optionalUint32\":1.11e1}")
        // Reject malformed input
        assertJSONDecodeFails("{\"optionalUint32\":true}")
        assertJSONDecodeFails("{\"optionalUint32\":-1}")
        assertJSONDecodeFails("{\"optionalUint32\":\"-1\"}")
        assertJSONDecodeFails("{\"optionalUint32\":0x102}")
        assertJSONDecodeFails("{\"optionalUint32\":{}}")
        assertJSONDecodeFails("{\"optionalUint32\":[]}")
    }

    func testOptionalInt64() throws {
        // Protoc JSON always quotes Int64 values
        assertJSONEncode("{\"optionalInt64\":\"9007199254740992\"}") { (o: inout MessageTestType) in
            o.optionalInt64 = 0x20_0000_0000_0000
        }
        assertJSONEncode("{\"optionalInt64\":\"9007199254740991\"}") { (o: inout MessageTestType) in
            o.optionalInt64 = 0x1f_ffff_ffff_ffff
        }
        assertJSONEncode("{\"optionalInt64\":\"-9007199254740992\"}") { (o: inout MessageTestType) in
            o.optionalInt64 = -0x20_0000_0000_0000
        }
        assertJSONEncode("{\"optionalInt64\":\"-9007199254740991\"}") { (o: inout MessageTestType) in
            o.optionalInt64 = -0x1f_ffff_ffff_ffff
        }
        assertJSONEncode("{\"optionalInt64\":\"9223372036854775807\"}") { (o: inout MessageTestType) in
            o.optionalInt64 = Int64.max
        }
        assertJSONEncode("{\"optionalInt64\":\"-9223372036854775808\"}") { (o: inout MessageTestType) in
            o.optionalInt64 = Int64.min
        }
        assertJSONEncode("{\"optionalInt64\":\"1\"}") { (o: inout MessageTestType) in
            o.optionalInt64 = 1
        }
        assertJSONEncode("{\"optionalInt64\":\"-1\"}") { (o: inout MessageTestType) in
            o.optionalInt64 = -1
        }

        // Decode should work even with unquoted large numbers
        assertJSONDecodeSucceeds("{\"optionalInt64\":9223372036854775807}") { $0.optionalInt64 == Int64.max }
        assertJSONDecodeFails("{\"optionalInt64\":9223372036854775808}")
        assertJSONDecodeSucceeds("{\"optionalInt64\":-9223372036854775808}") { $0.optionalInt64 == Int64.min }
        assertJSONDecodeFails("{\"optionalInt64\":-9223372036854775809}")
        // Protobuf JSON does not accept leading zeros
        assertJSONDecodeFails("{\"optionalInt64\": \"01\" }")
        assertJSONDecodeSucceeds("{\"optionalInt64\": \"1\" }") { $0.optionalInt64 == 1 }
        assertJSONDecodeFails("{\"optionalInt64\": \"-01\" }")
        assertJSONDecodeSucceeds("{\"optionalInt64\": \"-1\" }") { $0.optionalInt64 == -1 }
        assertJSONDecodeSucceeds("{\"optionalInt64\": \"0\" }") { $0.optionalInt64 == 0 }
        // Protobuf JSON does accept exponential format for integer fields
        assertJSONDecodeSucceeds("{\"optionalInt64\":1e3}") { $0.optionalInt64 == 1000 }
        assertJSONDecodeSucceeds("{\"optionalInt64\":\"9223372036854775807\"}") { $0.optionalInt64 == Int64.max }
        assertJSONDecodeSucceeds("{\"optionalInt64\":-9.223372036854775808e18}") { $0.optionalInt64 == Int64.min }
        assertJSONDecodeFails("{\"optionalInt64\":9.223372036854775808e18}")  // Out of range
        // Explicit 'null' is permitted, decodes to default (in proto3)
        assertJSONDecodeSucceeds("{\"optionalInt64\":null}") { $0.optionalInt64 == 0 }
        assertJSONDecodeSucceeds("{\"optionalInt64\":2147483648}") { $0.optionalInt64 == 2_147_483_648 }
        assertJSONDecodeSucceeds("{\"optionalInt64\":2147483648}") { $0.optionalInt64 == 2_147_483_648 }

        assertJSONDecodeFails("{\"optionalInt64\":1")
        assertJSONDecodeFails("{\"optionalInt64\":\"")
        assertJSONDecodeFails("{\"optionalInt64\":\"1")
        assertJSONDecodeFails("{\"optionalInt64\":\"1\"")
    }

    func testOptionalUInt64() {
        assertJSONEncode("{\"optionalUint64\":\"1\"}") { (o: inout MessageTestType) in
            o.optionalUint64 = 1
        }
        assertJSONEncode("{\"optionalUint64\":\"4294967295\"}") { (o: inout MessageTestType) in
            o.optionalUint64 = UInt64(UInt32.max)
        }
        assertJSONEncode("{\"optionalUint64\":\"18446744073709551615\"}") { (o: inout MessageTestType) in
            o.optionalUint64 = UInt64.max
        }
        // Parse unquoted 64-bit integers
        assertJSONDecodeSucceeds("{\"optionalUint64\":18446744073709551615}") { $0.optionalUint64 == UInt64.max }
        // Accept quoted 64-bit integers with backslash escapes in them
        assertJSONDecodeSucceeds("{\"optionalUint64\":\"184467\\u00344073709551615\"}") {
            $0.optionalUint64 == UInt64.max
        }
        // Reject unquoted 64-bit integers with backslash escapes
        assertJSONDecodeFails("{\"optionalUint64\":184467\\u00344073709551615}")
        // Reject out-of-range integers, whether or not quoted
        assertJSONDecodeFails("{\"optionalUint64\":\"18446744073709551616\"}")
        assertJSONDecodeFails("{\"optionalUint64\":18446744073709551616}")
        assertJSONDecodeFails("{\"optionalUint64\":\"184467440737095516109\"}")
        assertJSONDecodeFails("{\"optionalUint64\":184467440737095516109}")

        // Explicit 'null' is permitted, decodes to default
        assertJSONDecodeSucceeds("{\"optionalUint64\":null}") { $0.optionalUint64 == 0 }
        // Quoted or unquoted numbers, positive or zero
        assertJSONDecodeSucceeds("{\"optionalUint64\":1}") { $0.optionalUint64 == 1 }
        assertJSONDecodeSucceeds("{\"optionalUint64\":\"1\"}") { $0.optionalUint64 == 1 }
        assertJSONDecodeSucceeds("{\"optionalUint64\":0}") { $0.optionalUint64 == 0 }
        assertJSONDecodeSucceeds("{\"optionalUint64\":\"0\"}") { $0.optionalUint64 == 0 }
        // Protobuf JSON does not accept leading zeros
        assertJSONDecodeFails("{\"optionalUint64\":01}")
        assertJSONDecodeFails("{\"optionalUint64\":\"01\"}")
        // But it does accept exponential (as long as result is integral)
        assertJSONDecodeSucceeds("{\"optionalUint64\":4.294967295e9}") { $0.optionalUint64 == UInt64(UInt32.max) }
        assertJSONDecodeSucceeds("{\"optionalUint64\":1e3}") { $0.optionalUint64 == 1000 }
        assertJSONDecodeSucceeds("{\"optionalUint64\":1.2e3}") { $0.optionalUint64 == 1200 }
        assertJSONDecodeSucceeds("{\"optionalUint64\":1000e-2}") { $0.optionalUint64 == 10 }
        assertJSONDecodeSucceeds("{\"optionalUint64\":1.0}") { $0.optionalUint64 == 1 }
        assertJSONDecodeSucceeds("{\"optionalUint64\":1.000000e2}") { $0.optionalUint64 == 100 }
        assertJSONDecodeFails("{\"optionalUint64\":1e-3}")
        assertJSONDecodeFails("{\"optionalUint64\":1.11e1}")
        // Reject truncated JSON (ending at the beginning, end, or middle of the number
        assertJSONDecodeFails("{\"optionalUint64\":")
        assertJSONDecodeFails("{\"optionalUint64\":1")
        assertJSONDecodeFails("{\"optionalUint64\":\"")
        assertJSONDecodeFails("{\"optionalUint64\":\"1")
        assertJSONDecodeFails("{\"optionalUint64\":\"1\"")
        // Reject malformed input
        assertJSONDecodeFails("{\"optionalUint64\":true}")
        assertJSONDecodeFails("{\"optionalUint64\":-1}")
        assertJSONDecodeFails("{\"optionalUint64\":\"-1\"}")
        assertJSONDecodeFails("{\"optionalUint64\":0x102}")
        assertJSONDecodeFails("{\"optionalUint64\":{}}")
        assertJSONDecodeFails("{\"optionalUint64\":[]}")
    }

    func testOptionalDouble() throws {
        assertJSONEncode("{\"optionalDouble\":1.0}") { (o: inout MessageTestType) in
            o.optionalDouble = 1.0
        }
        assertJSONEncode("{\"optionalDouble\":\"Infinity\"}") { (o: inout MessageTestType) in
            o.optionalDouble = Double.infinity
        }
        assertJSONEncode("{\"optionalDouble\":\"-Infinity\"}") { (o: inout MessageTestType) in
            o.optionalDouble = -Double.infinity
        }
        assertJSONDecodeSucceeds("{\"optionalDouble\":\"Inf\"}") { $0.optionalDouble == Double.infinity }
        assertJSONDecodeSucceeds("{\"optionalDouble\":\"-Inf\"}") { $0.optionalDouble == -Double.infinity }
        assertJSONDecodeSucceeds("{\"optionalDouble\":\"1\"}") { $0.optionalDouble == 1 }
        assertJSONDecodeSucceeds("{\"optionalDouble\":\"1.0\"}") { $0.optionalDouble == 1.0 }
        assertJSONDecodeSucceeds("{\"optionalDouble\":\"1.5\"}") { $0.optionalDouble == 1.5 }
        assertJSONDecodeSucceeds("{\"optionalDouble\":\"1.5e1\"}") { $0.optionalDouble == 15 }
        assertJSONDecodeSucceeds("{\"optionalDouble\":\"1.5E1\"}") { $0.optionalDouble == 15 }
        assertJSONDecodeSucceeds("{\"optionalDouble\":\"1\\u002e5e1\"}") { $0.optionalDouble == 15 }
        assertJSONDecodeSucceeds("{\"optionalDouble\":\"1.\\u0035e1\"}") { $0.optionalDouble == 15 }
        assertJSONDecodeSucceeds("{\"optionalDouble\":\"1.5\\u00651\"}") { $0.optionalDouble == 15 }
        assertJSONDecodeSucceeds("{\"optionalDouble\":\"1.5e\\u002b1\"}") { $0.optionalDouble == 15 }
        assertJSONDecodeSucceeds("{\"optionalDouble\":\"1.5e+\\u0031\"}") { $0.optionalDouble == 15 }
        assertJSONDecodeSucceeds("{\"optionalDouble\":\"1.5e+1\"}") { $0.optionalDouble == 15 }
        assertJSONDecodeSucceeds("{\"optionalDouble\":\"15e-1\"}") { $0.optionalDouble == 1.5 }
        assertJSONDecodeSucceeds("{\"optionalDouble\":\"1.0e0\"}") { $0.optionalDouble == 1.0 }
        assertJSONDecodeSucceeds("{\"optionalDouble\":\"0\"}") { $0.optionalDouble == 0.0 }
        assertJSONDecodeSucceeds("{\"optionalDouble\":0}") { $0.optionalDouble == 0.0 }
        // We preserve signed zero when decoding
        let d1 = try MessageTestType(jsonString: "{\"optionalDouble\":\"-0\"}")
        XCTAssertEqual(d1.optionalDouble, 0.0)
        XCTAssertEqual(d1.optionalDouble.sign, .minus)
        let d2 = try MessageTestType(jsonString: "{\"optionalDouble\":-0}")
        XCTAssertEqual(d2.optionalDouble, 0.0)
        XCTAssertEqual(d2.optionalDouble.sign, .minus)
        // But re-encoding treats the field as defaulted, so the sign gets lost
        assertJSONDecodeSucceeds("{\"optionalDouble\":\"-0\"}") { $0.optionalDouble == 0.0 }
        assertJSONDecodeSucceeds("{\"optionalDouble\":-0}") { $0.optionalDouble == 0.0 }

        // Malformed numbers should fail
        assertJSONDecodeFails("{\"optionalDouble\":Infinity}")
        assertJSONDecodeFails("{\"optionalDouble\":-Infinity}")  // Must be quoted
        assertJSONDecodeFails("{\"optionalDouble\":\"inf\"}")
        assertJSONDecodeFails("{\"optionalDouble\":\"-inf\"}")
        assertJSONDecodeFails("{\"optionalDouble\":NaN}")
        assertJSONDecodeFails("{\"optionalDouble\":\"nan\"}")
        assertJSONDecodeFails("{\"optionalDouble\":\"1.0.0\"}")
        assertJSONDecodeFails("{\"optionalDouble\":00.1}")
        assertJSONDecodeFails("{\"optionalDouble\":\"00.1\"}")
        assertJSONDecodeFails("{\"optionalDouble\":.1}")
        assertJSONDecodeFails("{\"optionalDouble\":\".1\"}")
        assertJSONDecodeFails("{\"optionalDouble\":1.}")
        assertJSONDecodeFails("{\"optionalDouble\":\"1.\"}")
        assertJSONDecodeFails("{\"optionalDouble\":1e}")
        assertJSONDecodeFails("{\"optionalDouble\":\"1e\"}")
        assertJSONDecodeFails("{\"optionalDouble\":1e+}")
        assertJSONDecodeFails("{\"optionalDouble\":\"1e+\"}")
        assertJSONDecodeFails("{\"optionalDouble\":1e3.2}")
        assertJSONDecodeFails("{\"optionalDouble\":\"1e3.2\"}")
        assertJSONDecodeFails("{\"optionalDouble\":1.0.0}")

        // A wide range of numbers should exactly round-trip
        assertRoundTripJSON { $0.optionalDouble = 0.1 }
        assertRoundTripJSON { $0.optionalDouble = 0.01 }
        assertRoundTripJSON { $0.optionalDouble = 0.001 }
        assertRoundTripJSON { $0.optionalDouble = 0.0001 }
        assertRoundTripJSON { $0.optionalDouble = 0.00001 }
        assertRoundTripJSON { $0.optionalDouble = 0.000001 }
        assertRoundTripJSON { $0.optionalDouble = 1e-10 }
        assertRoundTripJSON { $0.optionalDouble = 1e-20 }
        assertRoundTripJSON { $0.optionalDouble = 1e-30 }
        assertRoundTripJSON { $0.optionalDouble = 1e-40 }
        assertRoundTripJSON { $0.optionalDouble = 1e-50 }
        assertRoundTripJSON { $0.optionalDouble = 1e-60 }
        assertRoundTripJSON { $0.optionalDouble = 1e-100 }
        assertRoundTripJSON { $0.optionalDouble = 1e-200 }
        assertRoundTripJSON { $0.optionalDouble = Double.pi }
        assertRoundTripJSON { $0.optionalDouble = 123456.789123456789123 }
        assertRoundTripJSON { $0.optionalDouble = 1.7976931348623157e+308 }
        assertRoundTripJSON { $0.optionalDouble = 2.22507385850720138309e-308 }
    }

    func testOptionalFloat() throws {
        assertJSONEncode("{\"optionalFloat\":1.0}") { (o: inout MessageTestType) in
            o.optionalFloat = 1.0
        }
        assertJSONEncode("{\"optionalFloat\":-1.0}") { (o: inout MessageTestType) in
            o.optionalFloat = -1.0
        }
        assertJSONEncode("{\"optionalFloat\":\"Infinity\"}") { (o: inout MessageTestType) in
            o.optionalFloat = Float.infinity
        }
        assertJSONEncode("{\"optionalFloat\":\"-Infinity\"}") { (o: inout MessageTestType) in
            o.optionalFloat = -Float.infinity
        }
        assertJSONDecodeSucceeds("{\"optionalFloat\":\"Inf\"}") { $0.optionalFloat == Float.infinity }
        assertJSONDecodeSucceeds("{\"optionalFloat\":\"-Inf\"}") { $0.optionalFloat == -Float.infinity }
        assertJSONDecodeSucceeds("{\"optionalFloat\":\"1\"}") { $0.optionalFloat == 1 }
        assertJSONDecodeSucceeds("{\"optionalFloat\":\"-1\"}") { $0.optionalFloat == -1 }
        assertJSONDecodeSucceeds("{\"optionalFloat\":\"1.0\"}") { $0.optionalFloat == 1.0 }
        assertJSONDecodeSucceeds("{\"optionalFloat\":\"1.5\"}") { $0.optionalFloat == 1.5 }
        assertJSONDecodeSucceeds("{\"optionalFloat\":\"1.5e1\"}") { $0.optionalFloat == 15 }
        assertJSONDecodeSucceeds("{\"optionalFloat\":\"1\\u002e5e1\"}") { $0.optionalFloat == 15 }
        assertJSONDecodeSucceeds("{\"optionalFloat\":\"1.\\u0035e1\"}") { $0.optionalFloat == 15 }
        assertJSONDecodeSucceeds("{\"optionalFloat\":\"1.5\\u00651\"}") { $0.optionalFloat == 15 }
        assertJSONDecodeSucceeds("{\"optionalFloat\":\"1.5e\\u002b1\"}") { $0.optionalFloat == 15 }
        assertJSONDecodeSucceeds("{\"optionalFloat\":\"1.5e+\\u0031\"}") { $0.optionalFloat == 15 }
        assertJSONDecodeSucceeds("{\"optionalFloat\":\"1.5e+1\"}") { $0.optionalFloat == 15 }
        assertJSONDecodeSucceeds("{\"optionalFloat\":\"15e-1\"}") { $0.optionalFloat == 1.5 }
        assertJSONDecodeSucceeds("{\"optionalFloat\":\"1.0e0\"}") { $0.optionalFloat == 1.0 }
        assertJSONDecodeSucceeds("{\"optionalFloat\":1.0e0}") { $0.optionalFloat == 1.0 }
        assertJSONDecodeSucceeds("{\"optionalFloat\":\"0\"}") { $0.optionalFloat == 0.0 }
        assertJSONDecodeSucceeds("{\"optionalFloat\":0}") { $0.optionalFloat == 0.0 }
        // We preserve signed zero when decoding
        let d1 = try MessageTestType(jsonString: "{\"optionalFloat\":\"-0\"}")
        XCTAssertEqual(d1.optionalFloat, 0.0)
        XCTAssertEqual(d1.optionalFloat.sign, .minus)
        let d2 = try MessageTestType(jsonString: "{\"optionalFloat\":-0}")
        XCTAssertEqual(d2.optionalFloat, 0.0)
        XCTAssertEqual(d2.optionalFloat.sign, .minus)
        // But re-encoding treats the field as defaulted, so the sign gets lost
        assertJSONDecodeSucceeds("{\"optionalFloat\":\"-0\"}") { $0.optionalFloat == 0.0 }
        assertJSONDecodeSucceeds("{\"optionalFloat\":-0}") { $0.optionalFloat == 0.0 }
        // Malformed numbers should fail
        assertJSONDecodeFails("{\"optionalFloat\":Infinity}")
        assertJSONDecodeFails("{\"optionalFloat\":-Infinity}")  // Must be quoted
        assertJSONDecodeFails("{\"optionalFloat\":NaN}")
        assertJSONDecodeFails("{\"optionalFloat\":\"nan\"}")
        assertJSONDecodeFails("{\"optionalFloat\":\"1.0.0\"}")
        assertJSONDecodeFails("{\"optionalFloat\":1.0.0}")
        assertJSONDecodeFails("{\"optionalFloat\":00.1}")
        assertJSONDecodeFails("{\"optionalFloat\":\"00.1\"}")
        assertJSONDecodeFails("{\"optionalFloat\":.1}")
        assertJSONDecodeFails("{\"optionalFloat\":\".1\"}")
        assertJSONDecodeFails("{\"optionalFloat\":\"1")
        assertJSONDecodeFails("{\"optionalFloat\":\"")
        assertJSONDecodeFails("{\"optionalFloat\":1")
        assertJSONDecodeFails("{\"optionalFloat\":1.")
        assertJSONDecodeFails("{\"optionalFloat\":1.}")
        assertJSONDecodeFails("{\"optionalFloat\":\"1.\"}")
        assertJSONDecodeFails("{\"optionalFloat\":1e}")
        assertJSONDecodeFails("{\"optionalFloat\":\"1e\"}")
        assertJSONDecodeFails("{\"optionalFloat\":1e+}")
        assertJSONDecodeFails("{\"optionalFloat\":\"1e+\"}")
        assertJSONDecodeFails("{\"optionalFloat\":1e3.2}")
        assertJSONDecodeFails("{\"optionalFloat\":\"1e3.2\"}")
        // Out-of-range numbers should fail
        assertJSONDecodeFails("{\"optionalFloat\":1e39}")

        // A wide range of numbers should exactly round-trip
        assertRoundTripJSON { $0.optionalFloat = 0.1 }
        assertRoundTripJSON { $0.optionalFloat = 0.01 }
        assertRoundTripJSON { $0.optionalFloat = 0.001 }
        assertRoundTripJSON { $0.optionalFloat = 0.0001 }
        assertRoundTripJSON { $0.optionalFloat = 0.00001 }
        assertRoundTripJSON { $0.optionalFloat = 0.000001 }
        assertRoundTripJSON { $0.optionalFloat = 1.00000075e-36 }
        assertRoundTripJSON { $0.optionalFloat = 1e-10 }
        assertRoundTripJSON { $0.optionalFloat = 1e-20 }
        assertRoundTripJSON { $0.optionalFloat = 1e-30 }
        assertRoundTripJSON { $0.optionalFloat = Float(1e-40) }
        assertRoundTripJSON { $0.optionalFloat = Float(1e-50) }
        assertRoundTripJSON { $0.optionalFloat = Float(1e-60) }
        assertRoundTripJSON { $0.optionalFloat = Float(1e-100) }
        assertRoundTripJSON { $0.optionalFloat = Float(1e-200) }
        assertRoundTripJSON { $0.optionalFloat = Float.pi }
        assertRoundTripJSON { $0.optionalFloat = 123456.789123456789123 }
        assertRoundTripJSON { $0.optionalFloat = 1999.9999999999 }
        assertRoundTripJSON { $0.optionalFloat = 1999.9 }
        assertRoundTripJSON { $0.optionalFloat = 1999.99 }
        assertRoundTripJSON { $0.optionalFloat = 1999.99 }
        assertRoundTripJSON { $0.optionalFloat = 3.402823567e+38 }
        assertRoundTripJSON { $0.optionalFloat = 1.1754944e-38 }
    }

    func testOptionalDouble_NaN() throws {
        // The helper functions don't work with NaN because NaN != NaN
        var o = SwiftProtoTesting_TestAllTypes()
        o.optionalDouble = Double.nan
        let encoded = try o.jsonString()
        XCTAssertEqual(encoded, "{\"optionalDouble\":\"NaN\"}")
        let o2 = try SwiftProtoTesting_TestAllTypes(jsonString: encoded)
        XCTAssert(o2.optionalDouble.isNaN == .some(true))
    }

    func testOptionalFloat_NaN() throws {
        // The helper functions don't work with NaN because NaN != NaN
        var o = SwiftProtoTesting_TestAllTypes()
        o.optionalFloat = Float.nan
        let encoded = try o.jsonString()
        XCTAssertEqual(encoded, "{\"optionalFloat\":\"NaN\"}")
        do {
            let o2 = try SwiftProtoTesting_TestAllTypes(jsonString: encoded)
            XCTAssert(o2.optionalFloat.isNaN == .some(true))
        } catch let e {
            XCTFail("Couldn't decode: \(e) -- \(encoded)")
        }
    }

    func testOptionalDouble_roundtrip() throws {
        for _ in 0..<10000 {
            let d = drand48()
            assertRoundTripJSON { $0.optionalDouble = d }
        }
    }

    func testOptionalFloat_roundtrip() throws {
        for _ in 0..<10000 {
            let f = Float(drand48())
            assertRoundTripJSON { $0.optionalFloat = f }
        }
    }

    func testOptionalBool() throws {
        assertJSONEncode("{\"optionalBool\":true}") { (o: inout MessageTestType) in
            o.optionalBool = true
        }
        assertJSONEncode("{\"optionalBool\":false}") { (o: inout MessageTestType) in
            o.optionalBool = false
        }
    }

    func testOptionalString() {
        assertJSONEncode("{\"optionalString\":\"hello\"}") { (o: inout MessageTestType) in
            o.optionalString = "hello"
        }
        // Start of the C1 range
        assertJSONEncode("{\"optionalString\":\"~\\u007F\\u0080\\u0081\"}") { (o: inout MessageTestType) in
            o.optionalString = "\u{7e}\u{7f}\u{80}\u{81}"
        }
        // End of the C1 range
        assertJSONEncode("{\"optionalString\":\"\\u009E\\u009F ¡¢£\"}") { (o: inout MessageTestType) in
            o.optionalString = "\u{9e}\u{9f}\u{a0}\u{a1}\u{a2}\u{a3}"
        }

        assertJSONEncode("{\"optionalString\":\"\"}") { (o: inout MessageTestType) in
            o.optionalString = ""
        }

        // Example from RFC 7159:  G clef coded as escaped surrogate pair
        assertJSONDecodeSucceeds("{\"optionalString\":\"\\uD834\\uDD1E\"}") { $0.optionalString == "𝄞" }
        // Ditto, with lowercase hex
        assertJSONDecodeSucceeds("{\"optionalString\":\"\\ud834\\udd1e\"}") { $0.optionalString == "𝄞" }
        // Same character represented directly
        assertJSONDecodeSucceeds("{\"optionalString\":\"𝄞\"}") { $0.optionalString == "𝄞" }
        // Various broken surrogate forms
        assertJSONDecodeFails("{\"optionalString\":\"\\uDD1E\\uD834\"}")
        assertJSONDecodeFails("{\"optionalString\":\"\\uDD1E\"}")
        assertJSONDecodeFails("{\"optionalString\":\"\\uD834\"}")
        assertJSONDecodeFails("{\"optionalString\":\"\\uDD1E\\u1234\"}")
    }

    func testOptionalString_controlCharacters() {
        // Verify that all C0 controls are correctly escaped
        assertJSONEncode("{\"optionalString\":\"\\u0000\\u0001\\u0002\\u0003\\u0004\\u0005\\u0006\\u0007\"}") {
            (o: inout MessageTestType) in
            o.optionalString = "\u{00}\u{01}\u{02}\u{03}\u{04}\u{05}\u{06}\u{07}"
        }
        assertJSONEncode("{\"optionalString\":\"\\b\\t\\n\\u000B\\f\\r\\u000E\\u000F\"}") {
            (o: inout MessageTestType) in
            o.optionalString = "\u{08}\u{09}\u{0a}\u{0b}\u{0c}\u{0d}\u{0e}\u{0f}"
        }
        assertJSONEncode("{\"optionalString\":\"\\u0010\\u0011\\u0012\\u0013\\u0014\\u0015\\u0016\\u0017\"}") {
            (o: inout MessageTestType) in
            o.optionalString = "\u{10}\u{11}\u{12}\u{13}\u{14}\u{15}\u{16}\u{17}"
        }
        assertJSONEncode("{\"optionalString\":\"\\u0018\\u0019\\u001A\\u001B\\u001C\\u001D\\u001E\\u001F\"}") {
            (o: inout MessageTestType) in
            o.optionalString = "\u{18}\u{19}\u{1a}\u{1b}\u{1c}\u{1d}\u{1e}\u{1f}"
        }
    }

    func testOptionalBytes() throws {
        assertJSONEncode("{\"optionalBytes\":\"\"}") { (o: inout MessageTestType) in
            o.optionalBytes = Data()
        }
        assertJSONEncode("{\"optionalBytes\":\"AA==\"}") { (o: inout MessageTestType) in
            o.optionalBytes = Data([0])
        }
        assertJSONEncode("{\"optionalBytes\":\"AAA=\"}") { (o: inout MessageTestType) in
            o.optionalBytes = Data([0, 0])
        }
        assertJSONEncode("{\"optionalBytes\":\"AAAA\"}") { (o: inout MessageTestType) in
            o.optionalBytes = Data([0, 0, 0])
        }
        assertJSONEncode("{\"optionalBytes\":\"/w==\"}") { (o: inout MessageTestType) in
            o.optionalBytes = Data([255])
        }
        assertJSONEncode("{\"optionalBytes\":\"//8=\"}") { (o: inout MessageTestType) in
            o.optionalBytes = Data([255, 255])
        }
        assertJSONEncode("{\"optionalBytes\":\"////\"}") { (o: inout MessageTestType) in
            o.optionalBytes = Data([255, 255, 255])
        }
        assertJSONEncode("{\"optionalBytes\":\"QQ==\"}") { (o: inout MessageTestType) in
            o.optionalBytes = Data([65])
        }
        assertJSONDecodeFails("{\"optionalBytes\":\"QQ=\"}")
        assertJSONDecodeSucceeds("{\"optionalBytes\":\"QQ\"}") {
            $0.optionalBytes == Data([65])
        }
        assertJSONEncode("{\"optionalBytes\":\"QUI=\"}") { (o: inout MessageTestType) in
            o.optionalBytes = Data([65, 66])
        }
        assertJSONDecodeSucceeds("{\"optionalBytes\":\"QUI\"}") {
            $0.optionalBytes == Data([65, 66])
        }
        assertJSONEncode("{\"optionalBytes\":\"QUJD\"}") { (o: inout MessageTestType) in
            o.optionalBytes = Data([65, 66, 67])
        }
        assertJSONEncode("{\"optionalBytes\":\"QUJDRA==\"}") { (o: inout MessageTestType) in
            o.optionalBytes = Data([65, 66, 67, 68])
        }
        assertJSONDecodeFails("{\"optionalBytes\":\"QUJDRA===\"}")
        assertJSONDecodeFails("{\"optionalBytes\":\"QUJDRA=\"}")
        assertJSONDecodeSucceeds("{\"optionalBytes\":\"QUJDRA\"}") {
            $0.optionalBytes == Data([65, 66, 67, 68])
        }
        assertJSONEncode("{\"optionalBytes\":\"QUJDREU=\"}") { (o: inout MessageTestType) in
            o.optionalBytes = Data([65, 66, 67, 68, 69])
        }
        assertJSONDecodeFails("{\"optionalBytes\":\"QUJDREU==\"}")
        assertJSONDecodeSucceeds("{\"optionalBytes\":\"QUJDREU\"}") {
            $0.optionalBytes == Data([65, 66, 67, 68, 69])
        }
        assertJSONEncode("{\"optionalBytes\":\"QUJDREVG\"}") { (o: inout MessageTestType) in
            o.optionalBytes = Data([65, 66, 67, 68, 69, 70])
        }
        assertJSONDecodeFails("{\"optionalBytes\":\"QUJDREVG=\"}")
        assertJSONDecodeFails("{\"optionalBytes\":\"QUJDREVG==\"}")
        assertJSONDecodeFails("{\"optionalBytes\":\"QUJDREVG===\"}")
        assertJSONDecodeFails("{\"optionalBytes\":\"QUJDREVG====\"}")
        // Google's parser accepts and ignores spaces:
        assertJSONDecodeSucceeds("{\"optionalBytes\":\" Q U J D R E U \"}") {
            $0.optionalBytes == Data([65, 66, 67, 68, 69])
        }
        // Accept both RFC4648 Section 4 "base64" and Section 5
        // "URL-safe base64" variants, but reject mixed coding:
        assertJSONDecodeSucceeds("{\"optionalBytes\":\"-_-_\"}") {
            $0.optionalBytes == Data([251, 255, 191])
        }
        assertJSONDecodeSucceeds("{\"optionalBytes\":\"+/+/\"}") {
            $0.optionalBytes == Data([251, 255, 191])
        }
        assertJSONDecodeFails("{\"optionalBytes\":\"-_+/\"}")
        assertJSONDecodeFails("{\"optionalBytes\":\"-_+\\/\"}")
    }

    func testOptionalBytes_escapes() {
        // Many JSON encoders escape "/":
        assertJSONDecodeSucceeds("{\"optionalBytes\":\"\\/w==\"}") {
            $0.optionalBytes == Data([255])
        }
        assertJSONDecodeSucceeds("{\"optionalBytes\":\"\\/w\"}") {
            $0.optionalBytes == Data([255])
        }
        assertJSONDecodeSucceeds("{\"optionalBytes\":\"\\/\\/\"}") {
            $0.optionalBytes == Data([255])
        }
        assertJSONDecodeSucceeds("{\"optionalBytes\":\"a\\/\"}") {
            $0.optionalBytes == Data([107])
        }
        assertJSONDecodeSucceeds("{\"optionalBytes\":\"ab\\/\"}") {
            $0.optionalBytes == Data([105, 191])
        }
        assertJSONDecodeSucceeds("{\"optionalBytes\":\"abc\\/\"}") {
            $0.optionalBytes == Data([105, 183, 63])
        }
        assertJSONDecodeSucceeds("{\"optionalBytes\":\"\\/a\"}") {
            $0.optionalBytes == Data([253])
        }
        assertJSONDecodeSucceeds("{\"optionalBytes\":\"\\/\\/\\/\\/\"}") {
            $0.optionalBytes == Data([255, 255, 255])
        }
        // Most backslash escapes decode to values that are
        // not legal in base-64 encoded strings
        assertJSONDecodeFails("{\"optionalBytes\":\"a\\b\"}")
        assertJSONDecodeFails("{\"optionalBytes\":\"a\\f\"}")
        assertJSONDecodeFails("{\"optionalBytes\":\"a\\n\"}")
        assertJSONDecodeFails("{\"optionalBytes\":\"a\\r\"}")
        assertJSONDecodeFails("{\"optionalBytes\":\"a\\t\"}")
        assertJSONDecodeFails("{\"optionalBytes\":\"a\\\"\"}")

        // TODO: For completeness, we should support \u1234 escapes
        // assertJSONDecodeSucceeds("{\"optionalBytes\":\"\u0061\u0062\"}")
        // assertJSONDecodeFails("{\"optionalBytes\":\"\u1234\u5678\"}")
    }

    func testOptionalBytes_roundtrip() throws {
        for i in UInt8(0)...UInt8(255) {
            let d = Data([i])
            let message = SwiftProtoTesting_TestAllTypes.with { $0.optionalBytes = d }
            let text = try message.jsonString()
            let decoded = try SwiftProtoTesting_TestAllTypes(jsonString: text)
            XCTAssertEqual(decoded, message)
            XCTAssertEqual(message.optionalBytes[0], i)
        }
    }

    func testOptionalNestedMessage() {
        assertJSONEncode("{\"optionalNestedMessage\":{\"bb\":1}}") { (o: inout MessageTestType) in
            var sub = SwiftProtoTesting_TestAllTypes.NestedMessage()
            sub.bb = 1
            o.optionalNestedMessage = sub
        }
    }

    func testOptionalNestedEnum() {
        assertJSONEncode("{\"optionalNestedEnum\":\"FOO\"}") { (o: inout MessageTestType) in
            o.optionalNestedEnum = SwiftProtoTesting_TestAllTypes.NestedEnum.foo
        }
        assertJSONDecodeSucceeds("{\"optionalNestedEnum\":1}") { $0.optionalNestedEnum == .foo }
        // TODO: Check whether Google's spec agrees that unknown Enum tags
        // should fail to parse
        assertJSONDecodeFails("{\"optionalNestedEnum\":\"UNKNOWN\"}")
    }

    func testRepeatedInt32() {
        assertJSONEncode("{\"repeatedInt32\":[1]}") { (o: inout MessageTestType) in
            o.repeatedInt32 = [1]
        }
        assertJSONEncode("{\"repeatedInt32\":[1,2]}") { (o: inout MessageTestType) in
            o.repeatedInt32 = [1, 2]
        }

        assertJSONDecodeSucceeds("{\"repeatedInt32\":null}") { $0.repeatedInt32 == [] }
        assertJSONDecodeSucceeds("{\"repeatedInt32\":[]}") { $0.repeatedInt32 == [] }
        assertJSONDecodeSucceeds("{\"repeatedInt32\":[1]}") { $0.repeatedInt32 == [1] }
        assertJSONDecodeSucceeds("{\"repeatedInt32\":[1,2]}") { $0.repeatedInt32 == [1, 2] }
    }

    func testRepeatedString() {
        assertJSONEncode("{\"repeatedString\":[\"\"]}") { (o: inout MessageTestType) in
            o.repeatedString = [""]
        }
        assertJSONEncode("{\"repeatedString\":[\"abc\",\"\"]}") { (o: inout MessageTestType) in
            o.repeatedString = ["abc", ""]
        }
        assertJSONDecodeSucceeds("{\"repeatedString\":null}") { $0.repeatedString == [] }
        assertJSONDecodeSucceeds("{\"repeatedString\":[]}") { $0.repeatedString == [] }
        assertJSONDecodeSucceeds(" { \"repeatedString\" : [ \"1\" , \"2\" ] } ") {
            $0.repeatedString == ["1", "2"]
        }
    }

    func testRepeatedNestedMessage() {
        assertJSONEncode("{\"repeatedNestedMessage\":[{\"bb\":1}]}") { (o: inout MessageTestType) in
            var sub = SwiftProtoTesting_TestAllTypes.NestedMessage()
            sub.bb = 1
            o.repeatedNestedMessage = [sub]
        }
        assertJSONEncode("{\"repeatedNestedMessage\":[{\"bb\":1},{\"bb\":2}]}") { (o: inout MessageTestType) in
            var sub1 = SwiftProtoTesting_TestAllTypes.NestedMessage()
            sub1.bb = 1
            var sub2 = SwiftProtoTesting_TestAllTypes.NestedMessage()
            sub2.bb = 2
            o.repeatedNestedMessage = [sub1, sub2]
        }
        assertJSONDecodeSucceeds("{\"repeatedNestedMessage\": []}") {
            $0.repeatedNestedMessage == []
        }
    }

    func testRepeatedEnum() {
        assertJSONEncode("{\"repeatedNestedEnum\":[\"FOO\"]}") { (o: inout MessageTestType) in
            o.repeatedNestedEnum = [.foo]
        }
        assertJSONEncode("{\"repeatedNestedEnum\":[\"FOO\",\"BAR\"]}") { (o: inout MessageTestType) in
            o.repeatedNestedEnum = [.foo, .bar]
        }
        assertJSONDecodeSucceeds("{\"repeatedNestedEnum\":[\"FOO\",1,\"BAR\",-1]}") { (o: MessageTestType) in
            o.repeatedNestedEnum == [.foo, .foo, .bar, .neg]
        }
        assertJSONDecodeFails("{\"repeatedNestedEnum\":[null]}")
        assertJSONDecodeFails("{\"repeatedNestedEnum\":\"FOO\"}")
        assertJSONDecodeFails("{\"repeatedNestedEnum\":0}")
        assertJSONDecodeSucceeds("{\"repeatedNestedEnum\":null}") { (o: MessageTestType) in
            o.repeatedNestedEnum == []
        }
        assertJSONDecodeSucceeds("{\"repeatedNestedEnum\":[]}") { (o: MessageTestType) in
            o.repeatedNestedEnum == []
        }
    }

    // TODO: Test other repeated field types

    func testOneof() {
        assertJSONEncode("{\"oneofUint32\":1}") { (o: inout MessageTestType) in
            o.oneofUint32 = 1
        }
        assertJSONEncode("{\"oneofString\":\"abc\"}") { (o: inout MessageTestType) in
            o.oneofString = "abc"
        }
        assertJSONEncode("{\"oneofNestedMessage\":{\"bb\":1}}") { (o: inout MessageTestType) in
            var sub = SwiftProtoTesting_TestAllTypes.NestedMessage()
            sub.bb = 1
            o.oneofNestedMessage = sub
        }
        assertJSONDecodeFails("{\"oneofString\": 1}")
        assertJSONDecodeFails("{\"oneofUint32\":1,\"oneofString\":\"abc\"}")
        assertJSONDecodeFails("{\"oneofString\":\"abc\",\"oneofUint32\":1}")
    }

    func testEmptyMessage() {
        assertJSONDecodeSucceeds("{}") { MessageTestType -> Bool in true }
        assertJSONDecodeFails("")
        assertJSONDecodeFails("{")
        assertJSONDecodeFails("}")
    }

    func assertJSONEncode(
        _ expected: String,
        extensions: any ExtensionMap = SimpleExtensionMap(),
        encodingOptions: JSONEncodingOptions = .init(),
        file: StaticString = #file,
        line: UInt = #line,
        configure: (inout MessageTestType) -> Void
    ) {
        let empty = MessageTestType()
        var configured = empty
        configure(&configured)
        XCTAssert(configured != empty, "Object should not be equal to empty object", file: file, line: line)
        do {
            let encoded = try configured.jsonString(options: encodingOptions)
            XCTAssert(
                expected == encoded,
                "Did not encode correctly: got \(encoded) but expected \(expected)",
                file: file,
                line: line
            )
            do {
                let decoded = try MessageTestType(jsonString: encoded, extensions: extensions)
                XCTAssert(
                    decoded == configured,
                    "Encode/decode cycle should generate equal object: \(decoded) != \(configured)",
                    file: file,
                    line: line
                )
            } catch {
                XCTFail(
                    "Encode/decode cycle should not throw error decoding: \(encoded), but it threw \(error)",
                    file: file,
                    line: line
                )
            }
        } catch let e {
            XCTFail("Failed to serialize JSON: \(e)\n    \(configured)", file: file, line: line)
        }

        do {
            let encodedData: [UInt8] = try configured.jsonUTF8Bytes(options: encodingOptions)
            let encodedOptString = String(bytes: encodedData, encoding: String.Encoding.utf8)
            XCTAssertNotNil(encodedOptString)
            let encodedString = encodedOptString!
            XCTAssert(
                expected == encodedString,
                "Did not encode correctly: got \(encodedString)",
                file: file,
                line: line
            )
            do {
                let decoded = try MessageTestType(jsonUTF8Bytes: encodedData, extensions: extensions)
                XCTAssert(
                    decoded == configured,
                    "Encode/decode cycle should generate equal object: \(decoded) != \(configured)",
                    file: file,
                    line: line
                )
            } catch {
                XCTFail(
                    "Encode/decode cycle should not throw error decoding: \(encodedString), but it threw \(error)",
                    file: file,
                    line: line
                )
            }
        } catch let e {
            XCTFail("Failed to serialize JSON: \(e)\n    \(configured)", file: file, line: line)
        }
    }

    func assertJSONDecodeSucceeds(
        _ json: String,
        options: JSONDecodingOptions = JSONDecodingOptions(),
        extensions: any ExtensionMap = SimpleExtensionMap(),
        file: StaticString = #file,
        line: UInt = #line,
        check: (MessageTestType) -> Bool
    ) {
        do {
            let decoded: MessageTestType = try MessageTestType(
                jsonString: json,
                extensions: extensions,
                options: options
            )
            XCTAssert(check(decoded), "Condition failed for \(decoded)", file: file, line: line)

            do {
                let encoded = try decoded.jsonString()
                do {
                    let redecoded = try MessageTestType(jsonString: encoded, extensions: extensions, options: options)
                    XCTAssert(
                        check(redecoded),
                        "Condition failed for redecoded \(redecoded) from \(encoded)",
                        file: file,
                        line: line
                    )
                    XCTAssertEqual(decoded, redecoded, file: file, line: line)
                } catch {
                    XCTFail("Swift should have recoded/redecoded without error: \(encoded)", file: file, line: line)
                }
            } catch let e {
                XCTFail("Swift should have recoded without error but got \(e)\n    \(decoded)", file: file, line: line)
            }
        } catch let e {
            XCTFail("Swift should have decoded without error but got \(e): \(json)", file: file, line: line)
            return
        }

        do {
            let jsonData = json.data(using: String.Encoding.utf8)!
            let decoded: MessageTestType = try MessageTestType(
                jsonUTF8Bytes: jsonData,
                extensions: extensions,
                options: options
            )
            XCTAssert(check(decoded), "Condition failed for \(decoded) from binary \(json)", file: file, line: line)

            do {
                let encoded: [UInt8] = try decoded.jsonUTF8Bytes()
                let encodedString = String(decoding: encoded, as: UTF8.self)
                do {
                    let redecoded = try MessageTestType(
                        jsonUTF8Bytes: encoded,
                        extensions: extensions,
                        options: options
                    )
                    XCTAssert(
                        check(redecoded),
                        "Condition failed for redecoded \(redecoded) from binary \(encodedString)",
                        file: file,
                        line: line
                    )
                    XCTAssertEqual(decoded, redecoded, file: file, line: line)
                } catch {
                    XCTFail(
                        "Swift should have recoded/redecoded without error: \(encodedString)",
                        file: file,
                        line: line
                    )
                }
            } catch let e {
                XCTFail("Swift should have recoded without error but got \(e)\n    \(decoded)", file: file, line: line)
            }
        } catch let e {
            XCTFail("Swift should have decoded without error but got \(e): \(json)", file: file, line: line)
            return
        }
    }

    func assertJSONDecodeFails(
        _ json: String,
        extensions: any ExtensionMap = SimpleExtensionMap(),
        options: JSONDecodingOptions = JSONDecodingOptions(),
        file: StaticString = #file,
        line: UInt = #line
    ) {
        do {
            let _ = try MessageTestType(jsonString: json, extensions: extensions, options: options)
            XCTFail("Swift decode should have failed: \(json)", file: file, line: line)
        } catch {
            // Yay! It failed!
        }

        let jsonData = json.data(using: String.Encoding.utf8)!
        do {
            let _ = try MessageTestType(jsonUTF8Bytes: jsonData, extensions: extensions, options: options)
            XCTFail("Swift decode should have failed for binary: \(json)", file: file, line: line)
        } catch {
            // Yay! It failed again!
        }
    }

    private func assertRoundTripJSON(
        file: StaticString = #file,
        line: UInt = #line,
        configure: (inout MessageTestType) -> Void
    ) {
        var original = MessageTestType()
        configure(&original)
        do {
            let json = try original.jsonString()
            do {
                let decoded = try MessageTestType(jsonString: json)
                XCTAssertEqual(original, decoded, file: file, line: line)
            } catch let e {
                XCTFail("Failed to decode \(e): \(json)", file: file, line: line)
            }
        } catch let e {
            XCTFail("Failed to encode \(e)", file: file, line: line)
        }
    }
}
