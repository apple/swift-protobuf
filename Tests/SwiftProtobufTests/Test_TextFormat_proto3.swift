// Tests/SwiftProtobufTests/Test_TextFormat_proto3.swift - Exercise proto3 text format coding
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// This is a set of tests for text format protobuf files.
///
// -----------------------------------------------------------------------------

import Foundation
import XCTest
import SwiftProtobuf

class Test_TextFormat_proto3: XCTestCase, PBTestHelpers {
    typealias MessageTestType = Proto3TestAllTypes

    func testDecoding_comments() {
        assertTextFormatDecodeSucceeds("single_int32: 41#single_int32: 42\nsingle_int64: 8") {
            (o: MessageTestType) in
            return o.singleInt32 == 41 && o.singleInt64 == 8
        }
    }

    //
    // Singular types
    //

    func testEncoding_singleInt32() {
        var a = MessageTestType()
        a.singleInt32 = 41

        XCTAssertEqual("single_int32: 41\n", a.textFormatString())

        assertTextFormatEncode("single_int32: 1\n") {(o: inout MessageTestType) in o.singleInt32 = 1 }
        assertTextFormatEncode("single_int32: 12\n") {(o: inout MessageTestType) in o.singleInt32 = 12 }
        assertTextFormatEncode("single_int32: 123\n") {(o: inout MessageTestType) in o.singleInt32 = 123 }
        assertTextFormatEncode("single_int32: 1234\n") {(o: inout MessageTestType) in o.singleInt32 = 1234 }
        assertTextFormatEncode("single_int32: 12345\n") {(o: inout MessageTestType) in o.singleInt32 = 12345 }
        assertTextFormatEncode("single_int32: 123456\n") {(o: inout MessageTestType) in o.singleInt32 = 123456 }
        assertTextFormatEncode("single_int32: 1234567\n") {(o: inout MessageTestType) in o.singleInt32 = 1234567 }
        assertTextFormatEncode("single_int32: 12345678\n") {(o: inout MessageTestType) in o.singleInt32 = 12345678 }
        assertTextFormatEncode("single_int32: 123456789\n") {(o: inout MessageTestType) in o.singleInt32 = 123456789 }
        assertTextFormatEncode("single_int32: 1234567890\n") {(o: inout MessageTestType) in o.singleInt32 = 1234567890 }

        assertTextFormatEncode("single_int32: 1\n") {(o: inout MessageTestType) in o.singleInt32 = 1 }
        assertTextFormatEncode("single_int32: 10\n") {(o: inout MessageTestType) in o.singleInt32 = 10 }
        assertTextFormatEncode("single_int32: 100\n") {(o: inout MessageTestType) in o.singleInt32 = 100 }
        assertTextFormatEncode("single_int32: 1000\n") {(o: inout MessageTestType) in o.singleInt32 = 1000 }
        assertTextFormatEncode("single_int32: 10000\n") {(o: inout MessageTestType) in o.singleInt32 = 10000 }
        assertTextFormatEncode("single_int32: 100000\n") {(o: inout MessageTestType) in o.singleInt32 = 100000 }
        assertTextFormatEncode("single_int32: 1000000\n") {(o: inout MessageTestType) in o.singleInt32 = 1000000 }
        assertTextFormatEncode("single_int32: 10000000\n") {(o: inout MessageTestType) in o.singleInt32 = 10000000 }
        assertTextFormatEncode("single_int32: 100000000\n") {(o: inout MessageTestType) in o.singleInt32 = 100000000 }
        assertTextFormatEncode("single_int32: 1000000000\n") {(o: inout MessageTestType) in o.singleInt32 = 1000000000 }


        assertTextFormatEncode("single_int32: 41\n") {(o: inout MessageTestType) in
            o.singleInt32 = 41 }
        assertTextFormatEncode("single_int32: 1\n") {(o: inout MessageTestType) in
            o.singleInt32 = 1
        }
        assertTextFormatEncode("single_int32: -1\n") {(o: inout MessageTestType) in
            o.singleInt32 = -1
        }
        assertTextFormatDecodeSucceeds("single_int32:0x1234") {(o: MessageTestType) in
            return o.singleInt32 == 0x1234
        }
        assertTextFormatDecodeSucceeds("single_int32:41") {(o: MessageTestType) in
            return o.singleInt32 == 41
        }
        assertTextFormatDecodeSucceeds("single_int32: 41#single_int32: 42") {
            (o: MessageTestType) in
            return o.singleInt32 == 41
        }
        assertTextFormatDecodeSucceeds("single_int32: 41 single_int32: 42") {
            (o: MessageTestType) in
            return o.singleInt32 == 42
        }
        assertTextFormatDecodeFails("single_int32: a\n")
        assertTextFormatDecodeFails("single_int32: 999999999999999999999999999999999999\n")
        assertTextFormatDecodeFails("single_int32: 1,2\n")
        assertTextFormatDecodeFails("single_int32: 1.2\n")
        assertTextFormatDecodeFails("single_int32: { }\n")
        assertTextFormatDecodeFails("single_int32: \"hello\"\n")
        assertTextFormatDecodeFails("single_int32: true\n")
        assertTextFormatDecodeFails("single_int32: 0x80000000\n")
        assertTextFormatDecodeSucceeds("single_int32: -0x80000000\n") {(o: MessageTestType) in
            return o.singleInt32 == -0x80000000
        }
        assertTextFormatDecodeFails("single_int32: -0x80000001\n")
    }

    func testEncoding_singleInt64() {
        var a = MessageTestType()
        a.singleInt64 = 2

        XCTAssertEqual("single_int64: 2\n", a.textFormatString())

        assertTextFormatEncode("single_int64: 1\n") {(o: inout MessageTestType) in o.singleInt64 = 1 }
        assertTextFormatEncode("single_int64: 12\n") {(o: inout MessageTestType) in o.singleInt64 = 12 }
        assertTextFormatEncode("single_int64: 123\n") {(o: inout MessageTestType) in o.singleInt64 = 123 }
        assertTextFormatEncode("single_int64: 1234\n") {(o: inout MessageTestType) in o.singleInt64 = 1234 }
        assertTextFormatEncode("single_int64: 12345\n") {(o: inout MessageTestType) in o.singleInt64 = 12345 }
        assertTextFormatEncode("single_int64: 123456\n") {(o: inout MessageTestType) in o.singleInt64 = 123456 }
        assertTextFormatEncode("single_int64: 1234567\n") {(o: inout MessageTestType) in o.singleInt64 = 1234567 }
        assertTextFormatEncode("single_int64: 12345678\n") {(o: inout MessageTestType) in o.singleInt64 = 12345678 }
        assertTextFormatEncode("single_int64: 123456789\n") {(o: inout MessageTestType) in o.singleInt64 = 123456789 }
        assertTextFormatEncode("single_int64: 1234567890\n") {(o: inout MessageTestType) in o.singleInt64 = 1234567890 }

        assertTextFormatEncode("single_int64: 1\n") {(o: inout MessageTestType) in o.singleInt64 = 1 }
        assertTextFormatEncode("single_int64: 10\n") {(o: inout MessageTestType) in o.singleInt64 = 10 }
        assertTextFormatEncode("single_int64: 100\n") {(o: inout MessageTestType) in o.singleInt64 = 100 }
        assertTextFormatEncode("single_int64: 1000\n") {(o: inout MessageTestType) in o.singleInt64 = 1000 }
        assertTextFormatEncode("single_int64: 10000\n") {(o: inout MessageTestType) in o.singleInt64 = 10000 }
        assertTextFormatEncode("single_int64: 100000\n") {(o: inout MessageTestType) in o.singleInt64 = 100000 }
        assertTextFormatEncode("single_int64: 1000000\n") {(o: inout MessageTestType) in o.singleInt64 = 1000000 }
        assertTextFormatEncode("single_int64: 10000000\n") {(o: inout MessageTestType) in o.singleInt64 = 10000000 }
        assertTextFormatEncode("single_int64: 100000000\n") {(o: inout MessageTestType) in o.singleInt64 = 100000000 }
        assertTextFormatEncode("single_int64: 1000000000\n") {(o: inout MessageTestType) in o.singleInt64 = 1000000000 }

        assertTextFormatEncode("single_int64: -2\n") {(o: inout MessageTestType) in o.singleInt64 = -2 }
        assertTextFormatDecodeSucceeds("single_int64: 0x1234567812345678\n") {(o: MessageTestType) in
            return o.singleInt64 == 0x1234567812345678
        }

        assertTextFormatDecodeFails("single_int64: a\n")
        assertTextFormatDecodeFails("single_int64: 999999999999999999999999999999999999\n")
        assertTextFormatDecodeFails("single_int64: 1,2\n")
    }

    func testEncoding_singleUint32() {
        var a = MessageTestType()
        a.singleUint32 = 3

        XCTAssertEqual("single_uint32: 3\n", a.textFormatString())

        assertTextFormatEncode("single_uint32: 3\n") {(o: inout MessageTestType) in
            o.singleUint32 = 3
        }
        assertTextFormatDecodeSucceeds("single_uint32: 3u") {
            (o: MessageTestType) in
            return o.singleUint32 == 3
        }
        assertTextFormatDecodeSucceeds("single_uint32: 3u single_int32: 1") {
            (o: MessageTestType) in
            return o.singleUint32 == 3 && o.singleInt32 == 1
        }
        assertTextFormatDecodeFails("single_uint32: -3\n")
        assertTextFormatDecodeFails("single_uint32: 3x\n")
        assertTextFormatDecodeFails("single_uint32: 3,4\n")
        assertTextFormatDecodeFails("single_uint32: 999999999999999999999999999999999999\n")
        assertTextFormatDecodeFails("single_uint32 3\n")
        assertTextFormatDecodeFails("3u")
        assertTextFormatDecodeFails("single_uint32: a\n")
        assertTextFormatDecodeFails("single_uint32 single_uint32: 7\n")
    }

    func testEncoding_singleUint64() {
        var a = MessageTestType()
        a.singleUint64 = 4

        XCTAssertEqual("single_uint64: 4\n", a.textFormatString())

        assertTextFormatEncode("single_uint64: 4\n") {(o: inout MessageTestType) in
            o.singleUint64 = 4
        }

        assertTextFormatDecodeSucceeds("single_uint64: 0xf234567812345678\n") {(o: MessageTestType) in
            return o.singleUint64 == 0xf234567812345678
        }
        assertTextFormatDecodeFails("single_uint64: a\n")
        assertTextFormatDecodeFails("single_uint64: 999999999999999999999999999999999999\n")
        assertTextFormatDecodeFails("single_uint64: 7,8")
        assertTextFormatDecodeFails("single_uint64: [7]")
    }

    func testEncoding_singleSint32() {
        var a = MessageTestType()
        a.singleSint32 = 5

        XCTAssertEqual("single_sint32: 5\n", a.textFormatString())

        assertTextFormatEncode("single_sint32: 5\n") {(o: inout MessageTestType) in
            o.singleSint32 = 5
        }
        assertTextFormatEncode("single_sint32: -5\n") {(o: inout MessageTestType) in
            o.singleSint32 = -5
        }
        assertTextFormatDecodeSucceeds("    single_sint32:-5    ") {
            (o: MessageTestType) in
            return o.singleSint32 == -5
        }

        assertTextFormatDecodeFails("single_sint32: a\n")
    }

    func testEncoding_singleSint64() {
        var a = MessageTestType()
        a.singleSint64 = 6

        XCTAssertEqual("single_sint64: 6\n", a.textFormatString())

        assertTextFormatEncode("single_sint64: 6\n") {(o: inout MessageTestType) in
            o.singleSint64 = 6
        }
        assertTextFormatDecodeFails("single_sint64: a\n")
    }

    func testEncoding_singleFixed32() {
        var a = MessageTestType()
        a.singleFixed32 = 7

        XCTAssertEqual("single_fixed32: 7\n", a.textFormatString())

        assertTextFormatEncode("single_fixed32: 7\n") {(o: inout MessageTestType) in
            o.singleFixed32 = 7
        }

        assertTextFormatDecodeFails("single_fixed32: a\n")
    }

    func testEncoding_singleFixed64() {
        var a = MessageTestType()
        a.singleFixed64 = 8

        XCTAssertEqual("single_fixed64: 8\n", a.textFormatString())

        assertTextFormatEncode("single_fixed64: 8\n") {(o: inout MessageTestType) in
            o.singleFixed64 = 8
        }

        assertTextFormatDecodeFails("single_fixed64: a\n")
    }

    func testEncoding_singleSfixed32() {
        var a = MessageTestType()
        a.singleSfixed32 = 9

        XCTAssertEqual("single_sfixed32: 9\n", a.textFormatString())

        assertTextFormatEncode("single_sfixed32: 9\n") {(o: inout MessageTestType) in
            o.singleSfixed32 = 9
        }

        assertTextFormatDecodeFails("single_sfixed32: a\n")
    }

    func testEncoding_singleSfixed64() {
        var a = MessageTestType()
        a.singleSfixed64 = 10

        XCTAssertEqual("single_sfixed64: 10\n", a.textFormatString())

        assertTextFormatEncode("single_sfixed64: 10\n") {(o: inout MessageTestType) in
            o.singleSfixed64 = 10
        }

        assertTextFormatDecodeFails("single_sfixed64: a\n")
    }

    private func assertRoundTripText(file: XCTestFileArgType = #file, line: UInt = #line, configure: (inout MessageTestType) -> Void) {
        var original = MessageTestType()
        configure(&original)
        let text = original.textFormatString()
        do {
            let decoded = try MessageTestType(textFormatString: text)
            XCTAssertEqual(original, decoded)
        } catch let e {
            XCTFail("Failed to decode \(e): \(text)", file: file, line: line)
        }
    }

    func testEncoding_singleFloat() {
        var a = MessageTestType()
        a.singleFloat = 11

        XCTAssertEqual("single_float: 11\n", a.textFormatString())

        assertTextFormatEncode("single_float: 11\n") {(o: inout MessageTestType) in
            o.singleFloat = 11
        }
        assertTextFormatDecodeSucceeds("single_float: 1.0f") {
            (o: MessageTestType) in
            return o.singleFloat == 1.0
        }
        assertTextFormatDecodeSucceeds("single_float: 1.5e3") {
            (o: MessageTestType) in
            return o.singleFloat == 1.5e3
        }
        assertTextFormatDecodeSucceeds("single_float: -4.75") {
            (o: MessageTestType) in
            return o.singleFloat == -4.75
        }
        assertTextFormatDecodeSucceeds("single_float: 1.0f single_int32: 1") {
            (o: MessageTestType) in
            return o.singleFloat == 1.0 && o.singleInt32 == 1
        }
        assertTextFormatDecodeSucceeds("single_float: 1.0 single_int32: 1") {
            (o: MessageTestType) in
            return o.singleFloat == 1.0 && o.singleInt32 == 1
        }
        assertTextFormatDecodeSucceeds("single_float: 1.0f\n") {
            (o: MessageTestType) in
            return o.singleFloat == 1.0
        }
        assertTextFormatEncode("single_float: inf\n") {(o: inout MessageTestType) in o.singleFloat = Float.infinity}
        assertTextFormatEncode("single_float: -inf\n") {(o: inout MessageTestType) in o.singleFloat = -Float.infinity}

        let b = Proto3TestAllTypes.with {$0.singleFloat = Float.nan}
        XCTAssertEqual("single_float: nan\n", b.textFormatString())

        do {
            let nan1 = try Proto3TestAllTypes(textFormatString: "single_float: nan\n")
            XCTAssert(nan1.singleFloat.isNaN)
        } catch let e {
            XCTFail("Decoding nan failed: \(e)")
        }

        do {
            let nan2 = try Proto3TestAllTypes(textFormatString: "single_float: NaN\n")
            XCTAssert(nan2.singleFloat.isNaN)
        } catch let e {
            XCTFail("Decoding nan failed: \(e)")
        }

        assertTextFormatDecodeFails("single_float: nansingle_int32: 1\n")

        assertTextFormatDecodeSucceeds("single_float: INFINITY\n") {(o: MessageTestType) in
            return o.singleFloat == Float.infinity
        }
        assertTextFormatDecodeSucceeds("single_float: Infinity\n") {(o: MessageTestType) in
            return o.singleFloat == Float.infinity
        }
        assertTextFormatDecodeSucceeds("single_float: -INFINITY\n") {(o: MessageTestType) in
            return o.singleFloat == -Float.infinity
        }
        assertTextFormatDecodeSucceeds("single_float: -Infinity\n") {(o: MessageTestType) in
            return o.singleFloat == -Float.infinity
        }
        assertTextFormatDecodeFails("single_float: INFINITY_AND_BEYOND\n")
        assertTextFormatDecodeFails("single_float: infinitysingle_int32: 1\n")

        assertTextFormatDecodeFails("single_float: a\n")
        assertTextFormatDecodeFails("single_float: 1,2\n")
        assertTextFormatDecodeFails("single_float: 0xf\n")
        assertTextFormatDecodeFails("single_float: 012\n")

        // A wide range of numbers should exactly round-trip
        assertRoundTripText {$0.singleFloat = 0.1}
        assertRoundTripText {$0.singleFloat = 0.01}
        assertRoundTripText {$0.singleFloat = 0.001}
        assertRoundTripText {$0.singleFloat = 0.0001}
        assertRoundTripText {$0.singleFloat = 0.00001}
        assertRoundTripText {$0.singleFloat = 0.000001}
        assertRoundTripText {$0.singleFloat = 1e-10}
        assertRoundTripText {$0.singleFloat = 1e-20}
        assertRoundTripText {$0.singleFloat = 1e-30}
        assertRoundTripText {$0.singleFloat = 1e-40}
        assertRoundTripText {$0.singleFloat = 1e-50}
        assertRoundTripText {$0.singleFloat = 1e-60}
        assertRoundTripText {$0.singleFloat = 1e-100}
        assertRoundTripText {$0.singleFloat = 1e-200}
        assertRoundTripText {$0.singleFloat = Float.pi}
        assertRoundTripText {$0.singleFloat = 123456.789123456789123}
        assertRoundTripText {$0.singleFloat = 1999.9999999999}
        assertRoundTripText {$0.singleFloat = 1999.9}
        assertRoundTripText {$0.singleFloat = 1999.99}
        assertRoundTripText {$0.singleFloat = 1999.99}
        assertRoundTripText {$0.singleFloat = 3.402823567e+38}
        assertRoundTripText {$0.singleFloat = 1.1754944e-38}
    }

    func testEncoding_singleDouble() {
        var a = MessageTestType()
        a.singleDouble = 12

        XCTAssertEqual("single_double: 12\n", a.textFormatString())

        assertTextFormatEncode("single_double: 12\n") {(o: inout MessageTestType) in o.singleDouble = 12 }
        assertTextFormatEncode("single_double: inf\n") {(o: inout MessageTestType) in o.singleDouble = Double.infinity}
        assertTextFormatEncode("single_double: -inf\n") {(o: inout MessageTestType) in o.singleDouble = -Double.infinity}
        let b = Proto3TestAllTypes.with {$0.singleDouble = Double.nan}
        XCTAssertEqual("single_double: nan\n", b.textFormatString())

        assertTextFormatDecodeSucceeds("single_double: INFINITY\n") {(o: MessageTestType) in
            return o.singleDouble == Double.infinity
        }
        assertTextFormatDecodeSucceeds("single_double: Infinity\n") {(o: MessageTestType) in
            return o.singleDouble == Double.infinity
        }
        assertTextFormatDecodeSucceeds("single_double: -INFINITY\n") {(o: MessageTestType) in
            return o.singleDouble == -Double.infinity
        }
        assertTextFormatDecodeSucceeds("single_double: -Infinity\n") {(o: MessageTestType) in
            return o.singleDouble == -Double.infinity
        }
        assertTextFormatDecodeFails("single_double: INFINITY_AND_BEYOND\n")
        assertTextFormatDecodeFails("single_double: INFIN\n")
        assertTextFormatDecodeFails("single_double: a\n")
        assertTextFormatDecodeFails("single_double: 1.2.3\n")
        assertTextFormatDecodeFails("single_double: 0xf\n")
        assertTextFormatDecodeFails("single_double: 0123\n")

        // A wide range of numbers should exactly round-trip
        assertRoundTripText {$0.singleDouble = 0.1}
        assertRoundTripText {$0.singleDouble = 0.01}
        assertRoundTripText {$0.singleDouble = 0.001}
        assertRoundTripText {$0.singleDouble = 0.0001}
        assertRoundTripText {$0.singleDouble = 0.00001}
        assertRoundTripText {$0.singleDouble = 0.000001}
        assertRoundTripText {$0.singleDouble = 1e-10}
        assertRoundTripText {$0.singleDouble = 1e-20}
        assertRoundTripText {$0.singleDouble = 1e-30}
        assertRoundTripText {$0.singleDouble = 1e-40}
        assertRoundTripText {$0.singleDouble = 1e-50}
        assertRoundTripText {$0.singleDouble = 1e-60}
        assertRoundTripText {$0.singleDouble = 1e-100}
        assertRoundTripText {$0.singleDouble = 1e-200}
        assertRoundTripText {$0.singleDouble = Double.pi}
        assertRoundTripText {$0.singleDouble = 123456.789123456789123}
        assertRoundTripText {$0.singleDouble = 1.7976931348623157e+308}
        assertRoundTripText {$0.singleDouble = 2.22507385850720138309e-308}
    }

    func testEncoding_singleBool() {
        var a = MessageTestType()
        a.singleBool = true
        XCTAssertEqual("single_bool: true\n", a.textFormatString())

        a.singleBool = false
        XCTAssertEqual("", a.textFormatString())

        assertTextFormatEncode("single_bool: true\n") {(o: inout MessageTestType) in
            o.singleBool = true
        }
        assertTextFormatDecodeSucceeds("single_bool:true") {(o: MessageTestType) in
            return o.singleBool == true
        }
        assertTextFormatDecodeSucceeds("single_bool:true ") {(o: MessageTestType) in
            return o.singleBool == true
        }
        assertTextFormatDecodeSucceeds("single_bool:true\n ") {(o: MessageTestType) in
            return o.singleBool == true
        }
        assertTextFormatDecodeSucceeds("single_bool:True\n ") {(o: MessageTestType) in
            return o.singleBool == true
        }
        assertTextFormatDecodeSucceeds("single_bool:t\n ") {(o: MessageTestType) in
            return o.singleBool == true
        }
        assertTextFormatDecodeSucceeds("single_bool:1\n ") {(o: MessageTestType) in
            return o.singleBool == true
        }
        assertTextFormatDecodeSucceeds("single_bool:false\n ") {(o: MessageTestType) in
            return o.singleBool == false
        }
        assertTextFormatDecodeSucceeds("single_bool:False\n ") {(o: MessageTestType) in
            return o.singleBool == false
        }
        assertTextFormatDecodeSucceeds("single_bool:f\n ") {(o: MessageTestType) in
            return o.singleBool == false
        }
        assertTextFormatDecodeSucceeds("single_bool:0\n ") {(o: MessageTestType) in
            return o.singleBool == false
        }

        assertTextFormatDecodeFails("single_bool: 10\n")
        assertTextFormatDecodeFails("single_bool: tRue\n")
        assertTextFormatDecodeFails("single_bool: tr\n")
        assertTextFormatDecodeFails("single_bool: tru\n")
        assertTextFormatDecodeFails("single_bool: truE\n")
        assertTextFormatDecodeFails("single_bool: TRUE\n")
        assertTextFormatDecodeFails("single_bool: faLse\n")
        assertTextFormatDecodeFails("single_bool: 2\n")
        assertTextFormatDecodeFails("single_bool: -0\n")
        assertTextFormatDecodeFails("single_bool: on\n")
        assertTextFormatDecodeFails("single_bool: a\n")
    }

    // TODO: Need to verify the behavior here with extended Unicode text
    // and UTF-8 encoded by C++ implementation
    func testEncoding_singleString() {
        var a = MessageTestType()
        a.singleString = "abc"

        XCTAssertEqual("single_string: \"abc\"\n", a.textFormatString())

        assertTextFormatEncode("single_string: \" !\\\"#$%&'\"\n") {
            (o: inout MessageTestType) in
            o.singleString = "\u{20}\u{21}\u{22}\u{23}\u{24}\u{25}\u{26}\u{27}"
        }

        assertTextFormatEncode("single_string: \"XYZ[\\\\]^_\"\n") {
            (o: inout MessageTestType) in
            o.singleString = "\u{58}\u{59}\u{5a}\u{5b}\u{5c}\u{5d}\u{5e}\u{5f}"
        }

        assertTextFormatEncode("single_string: \"xyz{|}~\\177\"\n") {
            (o: inout MessageTestType) in
            o.singleString = "\u{78}\u{79}\u{7a}\u{7b}\u{7c}\u{7d}\u{7e}\u{7f}"
        }
        assertTextFormatEncode("single_string: \"\u{80}\u{81}\u{82}\u{83}\u{84}\u{85}\"\n") {
            (o: inout MessageTestType) in
            o.singleString = "\u{80}\u{81}\u{82}\u{83}\u{84}\u{85}"
        }
        assertTextFormatEncode("single_string: \"øùúûüýþÿ\"\n") {
            (o: inout MessageTestType) in
            o.singleString = "\u{f8}\u{f9}\u{fa}\u{fb}\u{fc}\u{fd}\u{fe}\u{ff}"
        }


        // Adjacent quoted strings concatenate, see
        //   google/protobuf/text_format_unittest.cc#L597
        assertTextFormatDecodeSucceeds("single_string: \"abc\"\"def\"") {
            (o: MessageTestType) in
            return o.singleString == "abcdef"
        }
        assertTextFormatDecodeSucceeds("single_string: \"abc\" \"def\"") {
            (o: MessageTestType) in
            return o.singleString == "abcdef"
        }
        assertTextFormatDecodeSucceeds("single_string: \"abc\"   \"def\"") {
            (o: MessageTestType) in
            return o.singleString == "abcdef"
        }
        // Adjacent quoted strings concatenate across multiple lines
        assertTextFormatDecodeSucceeds("single_string: \"abc\"\n\"def\"") {
            (o: MessageTestType) in
            return o.singleString == "abcdef"
        }
        assertTextFormatDecodeSucceeds("single_string: \"abc\"\n      \t   \"def\"\n\"ghi\"\n") {
            (o: MessageTestType) in
            return o.singleString == "abcdefghi"
        }
        assertTextFormatDecodeSucceeds("single_string: \"abc\"\n\'def\'\n\"ghi\"\n") {
            (o: MessageTestType) in
            return o.singleString == "abcdefghi"
        }
        assertTextFormatDecodeSucceeds("single_string: \"abcdefghi\"") {
            (o: MessageTestType) in
            return o.singleString == "abcdefghi"
        }
        // Note: Values 0-127 are same whether viewed as Unicode code
        // points or UTF-8 bytes.
        assertTextFormatDecodeSucceeds("single_string: \"\\a\\b\\f\\n\\r\\t\\v\\\"\\'\\\\\\?\"") {
            (o: MessageTestType) in
            return o.singleString == "\u{07}\u{08}\u{0C}\u{0A}\u{0D}\u{09}\u{0B}\"'\\?"
        }
        assertTextFormatDecodeFails("single_string: \"\\z\"")
        assertTextFormatDecodeSucceeds("single_string: \"\\001\\01\\1\\0011\\010\\289\"") {
            (o: MessageTestType) in
            return o.singleString == "\u{01}\u{01}\u{01}\u{01}\u{31}\u{08}\u{02}89"
        }
        assertTextFormatDecodeSucceeds("single_string: \"\\x1\\x12\\x123\\x1234\"") {
            (o: MessageTestType) in
            return o.singleString == "\u{01}\u{12}\u{23}\u{34}"
        }
        assertTextFormatDecodeSucceeds("single_string: \"\\x0f\\x3g\"") {
            (o: MessageTestType) in
            return o.singleString == "\u{0f}\u{03}g"
        }
        assertTextFormatEncode("single_string: \"abc\"\n") {(o: inout MessageTestType) in
            o.singleString = "abc"
        }
        assertTextFormatDecodeFails("single_string:hello")
        assertTextFormatDecodeFails("single_string: \"hello\'")
        assertTextFormatDecodeFails("single_string: \'hello\"")
        assertTextFormatDecodeFails("single_string: \"hello")
    }

    func testEncoding_singleString_controlCharacters() throws {
        // This is known to fail on Swift Linux 3.1 and earlier,
        // so skip it there.
        // See https://bugs.swift.org/browse/SR-4218 for details.
#if !os(Linux) || swift(>=3.2)
        assertTextFormatEncode("single_string: \"\\001\\002\\003\\004\\005\\006\\007\"\n") {
            (o: inout MessageTestType) in
            o.singleString = "\u{01}\u{02}\u{03}\u{04}\u{05}\u{06}\u{07}"
        }
        assertTextFormatEncode("single_string: \"\\b\\t\\n\\v\\f\\r\\016\\017\"\n") {
            (o: inout MessageTestType) in
            o.singleString = "\u{08}\u{09}\u{0a}\u{0b}\u{0c}\u{0d}\u{0e}\u{0f}"
        }
        assertTextFormatEncode("single_string: \"\\020\\021\\022\\023\\024\\025\\026\\027\"\n") {
            (o: inout MessageTestType) in
            o.singleString = "\u{10}\u{11}\u{12}\u{13}\u{14}\u{15}\u{16}\u{17}"
        }
        assertTextFormatEncode("single_string: \"\\030\\031\\032\\033\\034\\035\\036\\037\"\n") {
            (o: inout MessageTestType) in
            o.singleString = "\u{18}\u{19}\u{1a}\u{1b}\u{1c}\u{1d}\u{1e}\u{1f}"
        }
#endif
    }

    func testEncoding_singleString_UTF8() throws {
        // We encode to/from a string, not a sequence of bytes, so valid
        // Unicode characters just get preserved on both encode and decode:
        assertTextFormatEncode("single_string: \"☞\"\n") {(o: inout MessageTestType) in
            o.singleString = "☞"
        }
        // Other encoders write each byte of a UTF-8 sequence, maybe in hex:
        assertTextFormatDecodeSucceeds("single_string: \"\\xE2\\x98\\x9E\"") {(o: MessageTestType) in
            return o.singleString == "☞"
        }
        // Or maybe in octal:
        assertTextFormatDecodeSucceeds("single_string: \"\\342\\230\\236\"") {(o: MessageTestType) in
            return o.singleString == "☞"
        }
        // Each string piece is decoded separately, broken UTF-8 is an error
        assertTextFormatDecodeFails("single_string: \"\\342\\230\" \"\\236\"")
    }

    func testEncoding_singleBytes() throws {
        let o = Proto3TestAllTypes.with { $0.singleBytes = Data() }
        XCTAssertEqual("", o.textFormatString())

        assertTextFormatEncode("single_bytes: \"AB\"\n") {(o: inout MessageTestType) in
            o.singleBytes = Data(bytes: [65, 66])
        }
        assertTextFormatEncode("single_bytes: \"\\000\\001AB\\177\\200\\377\"\n") {(o: inout MessageTestType) in
            o.singleBytes = Data(bytes: [0, 1, 65, 66, 127, 128, 255])
        }
        assertTextFormatEncode("single_bytes: \"\\b\\t\\n\\v\\f\\r\\\"'?\\\\\"\n") {(o: inout MessageTestType) in
            o.singleBytes = Data(bytes: [8, 9, 10, 11, 12, 13, 34, 39, 63, 92])
        }
        assertTextFormatDecodeSucceeds("single_bytes: \"A\" \"B\"\n") {(o: MessageTestType) in
            return o.singleBytes == Data(bytes: [65, 66])
        }
        assertTextFormatDecodeSucceeds("single_bytes: \"\\0\\1AB\\178\\189\\x61\\xdq\\x123456789\"\n") {(o: MessageTestType) in
            return o.singleBytes == Data(bytes: [0, 1, 65, 66, 15, 56, 1, 56, 57, 97, 13, 113, 137])
        }
        // "\1" followed by "2", not "\12"
        assertTextFormatDecodeSucceeds("single_bytes: \"\\1\" \"2\"") {(o: MessageTestType) in
            return o.singleBytes == Data(bytes: [1, 50]) // Not [10]
        }
        // "\x61" followed by "6" and "2", not "\x6162" (== "\x62")
        assertTextFormatDecodeSucceeds("single_bytes: \"\\x61\" \"62\"") {(o: MessageTestType) in
            return o.singleBytes == Data(bytes: [97, 54, 50]) // Not [98]
        }
        assertTextFormatDecodeSucceeds("single_bytes: \"\"\n") {(o: MessageTestType) in
            return o.singleBytes == Data()
        }
        assertTextFormatDecodeSucceeds("single_bytes: \"\\b\\t\\n\\v\\f\\r\\\"\\'\\?'\"\n") {(o: MessageTestType) in
            return o.singleBytes == Data(bytes: [8, 9, 10, 11, 12, 13, 34, 39, 63, 39])
        }

        assertTextFormatDecodeFails("single_bytes: 10\n")
        assertTextFormatDecodeFails("single_bytes: \"\\\"\n")
        assertTextFormatDecodeFails("single_bytes: \"\\x\"\n")
        assertTextFormatDecodeFails("single_bytes: \"\\x&\"\n")
        assertTextFormatDecodeFails("single_bytes: \"\\xg\"\n")
        assertTextFormatDecodeFails("single_bytes: \"\\q\"\n")
    }

    func testEncoding_singleBytes_roundtrip() throws {
        for i in UInt8(0)...UInt8(255) {
            let d = Data(bytes: [i])
            let message = Proto3TestAllTypes.with { $0.singleBytes = d }
            let text = message.textFormatString()
            let decoded = try Proto3TestAllTypes(textFormatString: text)
            XCTAssertEqual(decoded, message)
            XCTAssertEqual(message.singleBytes[0], i)
        }
    }

    func testEncoding_singleNestedMessage() {
        var nested = MessageTestType.NestedMessage()
        nested.bb = 7

        var a = MessageTestType()
        a.singleNestedMessage = nested

        XCTAssertEqual("single_nested_message {\n  bb: 7\n}\n", a.textFormatString())

        assertTextFormatEncode("single_nested_message {\n  bb: 7\n}\n") {(o: inout MessageTestType) in
            o.singleNestedMessage = nested
        }
        // Google permits reading a message field with or without the separating ':'
        assertTextFormatDecodeSucceeds("single_nested_message: {bb:7}") {(o: MessageTestType) in
            return o.singleNestedMessage.bb == 7
        }
        // Messages can be wrapped in {...} or <...>
        assertTextFormatDecodeSucceeds("single_nested_message <bb:7>") {(o: MessageTestType) in
            return o.singleNestedMessage.bb == 7
        }
        // Google permits reading a message field with or without the separating ':'
        assertTextFormatDecodeSucceeds("single_nested_message: <bb:7>") {(o: MessageTestType) in
            return o.singleNestedMessage.bb == 7
        }

        assertTextFormatDecodeFails("single_nested_message: a\n")
    }

    func testEncoding_singleForeignMessage() {
        var foreign = Proto3ForeignMessage()
        foreign.c = 88

        var a = MessageTestType()
        a.singleForeignMessage = foreign

        XCTAssertEqual("single_foreign_message {\n  c: 88\n}\n", a.textFormatString())

        assertTextFormatEncode("single_foreign_message {\n  c: 88\n}\n") {(o: inout MessageTestType) in o.singleForeignMessage = foreign }

        do {
            let message = try MessageTestType(textFormatString:"single_foreign_message: {\n  c: 88\n}\n")
            XCTAssertEqual(message.singleForeignMessage.c, 88)
        } catch {
            XCTFail("Presented error: \(error)")
        }

        assertTextFormatDecodeFails("single_foreign_message: a\n")
    }

    func testEncoding_singleImportMessage() {
        var importMessage = Proto3ImportMessage()
        importMessage.d = -9

        var a = MessageTestType()
        a.singleImportMessage = importMessage

        XCTAssertEqual("single_import_message {\n  d: -9\n}\n", a.textFormatString())

        assertTextFormatEncode("single_import_message {\n  d: -9\n}\n") {(o: inout MessageTestType) in o.singleImportMessage = importMessage }

        do {
            let message = try MessageTestType(textFormatString:"single_import_message: {\n  d: -9\n}\n")
            XCTAssertEqual(message.singleImportMessage.d, -9)
        } catch {
            XCTFail("Presented error: \(error)")
        }

        assertTextFormatDecodeFails("single_import_message: a\n")
    }

    func testEncoding_singleNestedEnum() throws {
        var a = MessageTestType()
        a.singleNestedEnum = .baz

        XCTAssertEqual("single_nested_enum: BAZ\n", a.textFormatString())

        assertTextFormatEncode("single_nested_enum: BAZ\n") {(o: inout MessageTestType) in
            o.singleNestedEnum = .baz
        }
        assertTextFormatDecodeSucceeds("single_nested_enum:BAZ"){(o: MessageTestType) in
            return o.singleNestedEnum == .baz
        }
        assertTextFormatDecodeSucceeds("single_nested_enum:1"){(o: MessageTestType) in
            return o.singleNestedEnum == .foo
        }
        assertTextFormatDecodeSucceeds("single_nested_enum:2"){(o: MessageTestType) in
            return o.singleNestedEnum == .bar
        }
        assertTextFormatDecodeFails("single_nested_enum: a\n")
        assertTextFormatDecodeFails("single_nested_enum: FOOBAR")
        assertTextFormatDecodeFails("single_nested_enum: \"BAR\"\n")

        // Note: This implementation currently preserves numeric unknown
        // enum values, unlike Google's C++ implementation, which considers
        // it a parse error.
        let b = try Proto3TestAllTypes(textFormatString: "single_nested_enum: 999\n")
        XCTAssertEqual("single_nested_enum: 999\n", b.textFormatString())
    }

    func testEncoding_singleForeignEnum() {
        var a = MessageTestType()
        a.singleForeignEnum = .foreignBaz

        XCTAssertEqual("single_foreign_enum: FOREIGN_BAZ\n", a.textFormatString())

        assertTextFormatEncode("single_foreign_enum: FOREIGN_BAZ\n") {(o: inout MessageTestType) in o.singleForeignEnum = .foreignBaz }

        assertTextFormatDecodeFails("single_foreign_enum: a\n")
    }

    func testEncoding_singleImportEnum() {
        var a = MessageTestType()
        a.singleImportEnum = .importBaz

        XCTAssertEqual("single_import_enum: IMPORT_BAZ\n", a.textFormatString())

        assertTextFormatEncode("single_import_enum: IMPORT_BAZ\n") {(o: inout MessageTestType) in o.singleImportEnum = .importBaz }

        assertTextFormatDecodeFails("single_import_enum: a\n")
    }

    func testEncoding_singlePublicImportMessage() {
        var publicImportMessage = Proto3PublicImportMessage()
        publicImportMessage.e = -999999

        var a = MessageTestType()
        a.singlePublicImportMessage = publicImportMessage

        XCTAssertEqual("single_public_import_message {\n  e: -999999\n}\n", a.textFormatString())

        assertTextFormatEncode("single_public_import_message {\n  e: -999999\n}\n") {(o: inout MessageTestType) in o.singlePublicImportMessage = publicImportMessage }

        do {
            let message = try MessageTestType(textFormatString:"single_public_import_message: {\n  e: -999999\n}\n")
            XCTAssertEqual(message.singlePublicImportMessage.e, -999999)
        } catch {
            XCTFail("Presented error: \(error)")
        }

        assertTextFormatDecodeFails("single_public_import_message: a\n")
    }

    //
    // Repeated types
    //

    func testEncoding_repeatedInt32() {
        var a = MessageTestType()
        a.repeatedInt32 = [1, 2]
        XCTAssertEqual("repeated_int32: [1, 2]\n", a.textFormatString())

        assertTextFormatEncode("repeated_int32: [1, 2]\n") {(o: inout MessageTestType) in
            o.repeatedInt32 = [1, 2]
        }

        assertTextFormatDecodeSucceeds("repeated_int32: 1\n repeated_int32: 2\n") {
            (o: MessageTestType) in
            return o.repeatedInt32 == [1, 2]
        }
        assertTextFormatDecodeSucceeds("repeated_int32:[1, 2]") {
            (o: MessageTestType) in
            return o.repeatedInt32 == [1, 2]
        }
        assertTextFormatDecodeSucceeds("repeated_int32: [1] repeated_int32: 2\n") {
            (o: MessageTestType) in
            return o.repeatedInt32 == [1, 2]
        }
        assertTextFormatDecodeSucceeds("repeated_int32: 1 repeated_int32: [2]\n") {
            (o: MessageTestType) in
            return o.repeatedInt32 == [1, 2]
        }
        assertTextFormatDecodeSucceeds("repeated_int32:[]\nrepeated_int32: [1, 2]\nrepeated_int32:[]\n") {
            (o: MessageTestType) in
            return o.repeatedInt32 == [1, 2]
        }
        assertTextFormatDecodeSucceeds("repeated_int32:1\nrepeated_int32:2\n") {
            (o: MessageTestType) in
            return o.repeatedInt32 == [1, 2]
        }

        assertTextFormatDecodeFails("repeated_int32: 1\nrepeated_int32: a\n")
        assertTextFormatDecodeFails("repeated_int32: [")
        assertTextFormatDecodeFails("repeated_int32: [\n")
        assertTextFormatDecodeFails("repeated_int32: [,]\n")
        assertTextFormatDecodeFails("repeated_int32: [1\n")
        assertTextFormatDecodeFails("repeated_int32: [1,\n")
        assertTextFormatDecodeFails("repeated_int32: [1,]\n")
        assertTextFormatDecodeFails("repeated_int32: [1,2\n")
        assertTextFormatDecodeFails("repeated_int32: [1,2,]\n")
    }

    func testEncoding_repeatedInt64() {
        assertTextFormatEncode("repeated_int64: [3, 4]\n") {(o: inout MessageTestType) in
            o.repeatedInt64 = [3, 4]
        }

        assertTextFormatDecodeSucceeds("repeated_int64: 3\nrepeated_int64: 4\n") {(o: MessageTestType) in
            return o.repeatedInt64 == [3, 4]
        }
        assertTextFormatDecodeFails("repeated_int64: 3\nrepeated_int64: a\n")
    }

    func testEncoding_repeatedUint32() {
        assertTextFormatEncode("repeated_uint32: [5, 6]\n") {(o: inout MessageTestType) in
            o.repeatedUint32 = [5, 6]
        }

        assertTextFormatDecodeFails("repeated_uint32: 5\nrepeated_uint32: a\n")
    }

    func testEncoding_repeatedUint64() {
        assertTextFormatEncode("repeated_uint64: [7, 8]\n") {(o: inout MessageTestType) in
            o.repeatedUint64 = [7, 8]
        }

        assertTextFormatDecodeSucceeds("repeated_uint64: 7\nrepeated_uint64: 8\n") {
            $0.repeatedUint64 == [7, 8]
        }

        assertTextFormatDecodeFails("repeated_uint64: 7\nrepeated_uint64: a\n")
    }

    func testEncoding_repeatedSint32() {
        assertTextFormatEncode("repeated_sint32: [9, 10]\n") {(o: inout MessageTestType) in
            o.repeatedSint32 = [9, 10]
        }

        assertTextFormatDecodeFails("repeated_sint32: 9\nrepeated_sint32: a\n")
    }

    func testEncoding_repeatedSint64() {
        assertTextFormatEncode("repeated_sint64: [11, 12]\n") {(o: inout MessageTestType) in
            o.repeatedSint64 = [11, 12]
        }

        assertTextFormatDecodeFails("repeated_sint64: 11\nrepeated_sint64: a\n")
    }

    func testEncoding_repeatedFixed32() {
        assertTextFormatEncode("repeated_fixed32: [13, 14]\n") {(o: inout MessageTestType) in
            o.repeatedFixed32 = [13, 14]
        }

        assertTextFormatDecodeFails("repeated_fixed32: 13\nrepeated_fixed32: a\n")
    }

    func testEncoding_repeatedFixed64() {
        assertTextFormatEncode("repeated_fixed64: [15, 16]\n") {(o: inout MessageTestType) in
            o.repeatedFixed64 = [15, 16]
        }

        assertTextFormatDecodeFails("repeated_fixed64: 15\nrepeated_fixed64: a\n")
    }

    func testEncoding_repeatedSfixed32() {
        assertTextFormatEncode("repeated_sfixed32: [17, 18]\n") {(o: inout MessageTestType) in
            o.repeatedSfixed32 = [17, 18]
        }

        assertTextFormatDecodeFails("repeated_sfixed32: 17\nrepeated_sfixed32: a\n")
    }

    func testEncoding_repeatedSfixed64() {
        assertTextFormatEncode("repeated_sfixed64: [19, 20]\n") {(o: inout MessageTestType) in
            o.repeatedSfixed64 = [19, 20]
        }

        assertTextFormatDecodeFails("repeated_sfixed64: 19\nrepeated_sfixed64: a\n")
    }

    func testEncoding_repeatedFloat() {
        assertTextFormatEncode("repeated_float: [21, 22]\n") {(o: inout MessageTestType) in
            o.repeatedFloat = [21, 22]
        }

        assertTextFormatDecodeFails("repeated_float: 21\nrepeated_float: a\n")
    }

    func testEncoding_repeatedDouble() {
        assertTextFormatEncode("repeated_double: [23, 24]\n") {(o: inout MessageTestType) in
            o.repeatedDouble = [23, 24]
        }
        assertTextFormatEncode("repeated_double: [2.25, 2.5]\n") {(o: inout MessageTestType) in
            o.repeatedDouble = [2.25, 2.5]
        }

        assertTextFormatDecodeFails("repeated_double: 23\nrepeated_double: a\n")
    }

    func testEncoding_repeatedBool() {
        assertTextFormatEncode("repeated_bool: [true, false]\n") {(o: inout MessageTestType) in
            o.repeatedBool = [true, false]
        }
        assertTextFormatDecodeSucceeds("repeated_bool: [true, false, True, False, t, f, 1, 0]") {
            (o: MessageTestType) in
            return o.repeatedBool == [true, false, true, false, true, false, true, false]
        }

        assertTextFormatDecodeFails("repeated_bool: true\nrepeated_bool: a\n")
    }

    func testEncoding_repeatedString() {
        assertTextFormatDecodeSucceeds("repeated_string: \"abc\"\nrepeated_string: \"def\"\n") {
            (o: MessageTestType) in
            return o.repeatedString == ["abc", "def"]
        }
        assertTextFormatDecodeSucceeds("repeated_string: \"a\" \"bc\"\nrepeated_string: 'd' \"e\" \"f\"\n") {
            (o: MessageTestType) in
            return o.repeatedString == ["abc", "def"]
        }
        assertTextFormatDecodeSucceeds("repeated_string:[\"abc\", \"def\"]") {
            (o: MessageTestType) in
            return o.repeatedString == ["abc", "def"]
        }
        assertTextFormatDecodeSucceeds("repeated_string:[\"a\"\"bc\", \"d\" 'e' \"f\"]") {
            (o: MessageTestType) in
            return o.repeatedString == ["abc", "def"]
        }
        assertTextFormatDecodeSucceeds("repeated_string:[\"abc\", 'def']") {
            (o: MessageTestType) in
            return o.repeatedString == ["abc", "def"]
        }
        assertTextFormatDecodeSucceeds("repeated_string:[\"abc\"] repeated_string: \"def\"") {
            (o: MessageTestType) in
            return o.repeatedString == ["abc", "def"]
        }
        assertTextFormatDecodeFails("repeated_string:[\"abc\", \"def\",]")
        assertTextFormatDecodeFails("repeated_string:[\"abc\"")
        assertTextFormatDecodeFails("repeated_string:[\"abc\",")
        assertTextFormatDecodeFails("repeated_string:[\"abc\",]")
        assertTextFormatDecodeFails("repeated_string: \"abc\"]")
        assertTextFormatDecodeFails("repeated_string: abc")

        assertTextFormatEncode("repeated_string: \"abc\"\nrepeated_string: \"def\"\n") {(o: inout MessageTestType) in o.repeatedString = ["abc", "def"] }
    }

    func testEncoding_repeatedBytes() {
        var a = MessageTestType()
        a.repeatedBytes = [Data(), Data(bytes: [65, 66])]
        XCTAssertEqual("repeated_bytes: \"\"\nrepeated_bytes: \"AB\"\n", a.textFormatString())

        assertTextFormatEncode("repeated_bytes: \"\"\nrepeated_bytes: \"AB\"\n") {(o: inout MessageTestType) in
            o.repeatedBytes = [Data(), Data(bytes: [65, 66])]
        }
        assertTextFormatDecodeSucceeds("repeated_bytes: \"\"\nrepeated_bytes: \"A\" \"B\"\n") {(o: MessageTestType) in
            return o.repeatedBytes == [Data(), Data(bytes: [65, 66])]
        }
        assertTextFormatDecodeSucceeds("repeated_bytes: [\"\", \"AB\"]\n") {(o: MessageTestType) in
            return o.repeatedBytes == [Data(), Data(bytes: [65, 66])]
        }
        assertTextFormatDecodeSucceeds("repeated_bytes: [\"\", \"A\" \"B\"]\n") {(o: MessageTestType) in
            return o.repeatedBytes == [Data(), Data(bytes: [65, 66])]
        }
    }

    func testEncoding_repeatedNestedMessage() {
        var nested = MessageTestType.NestedMessage()
        nested.bb = 7

        var nested2 = nested
        nested2.bb = -7

        var a = MessageTestType()
        a.repeatedNestedMessage = [nested, nested2]

        XCTAssertEqual("repeated_nested_message {\n  bb: 7\n}\nrepeated_nested_message {\n  bb: -7\n}\n", a.textFormatString())

        assertTextFormatEncode("repeated_nested_message {\n  bb: 7\n}\nrepeated_nested_message {\n  bb: -7\n}\n") {(o: inout MessageTestType) in o.repeatedNestedMessage = [nested, nested2] }

        assertTextFormatDecodeSucceeds("repeated_nested_message: {\n bb: 7\n}\nrepeated_nested_message: {\n  bb: -7\n}\n") {
            (o: MessageTestType) in
            return o.repeatedNestedMessage == [
                MessageTestType.NestedMessage.with {$0.bb = 7},
                MessageTestType.NestedMessage.with {$0.bb = -7}
            ]
        }
        assertTextFormatDecodeSucceeds("repeated_nested_message:[{bb: 7}, {bb: -7}]") {
            (o: MessageTestType) in
            return o.repeatedNestedMessage == [
                MessageTestType.NestedMessage.with {$0.bb = 7},
                MessageTestType.NestedMessage.with {$0.bb = -7}
            ]
        }

        assertTextFormatDecodeFails("repeated_nested_message {\n  bb: 7\n}\nrepeated_nested_message {\n  bb: a\n}\n")
    }

    func testEncoding_repeatedForeignMessage() {
        var foreign = Proto3ForeignMessage()
        foreign.c = 88

        var foreign2 = foreign
        foreign2.c = -88

        var a = MessageTestType()
        a.repeatedForeignMessage = [foreign, foreign2]

        XCTAssertEqual("repeated_foreign_message {\n  c: 88\n}\nrepeated_foreign_message {\n  c: -88\n}\n", a.textFormatString())

        assertTextFormatEncode("repeated_foreign_message {\n  c: 88\n}\nrepeated_foreign_message {\n  c: -88\n}\n") {(o: inout MessageTestType) in o.repeatedForeignMessage = [foreign, foreign2] }

        do {
            let message = try MessageTestType(textFormatString:"repeated_foreign_message: {\n  c: 88\n}\nrepeated_foreign_message: {\n  c: -88\n}\n")
            XCTAssertEqual(message.repeatedForeignMessage[0].c, 88)
            XCTAssertEqual(message.repeatedForeignMessage[1].c, -88)
        } catch {
            XCTFail("Presented error: \(error)")
        }

        assertTextFormatDecodeFails("repeated_foreign_message {\n  c: 88\n}\nrepeated_foreign_message {\n  c: a\n}\n")
    }


    func testEncoding_repeatedImportMessage() {
        var importMessage = Proto3ImportMessage()
        importMessage.d = -9

        var importMessage2 = importMessage
        importMessage2.d = 999999

        var a = MessageTestType()
        a.repeatedImportMessage = [importMessage, importMessage2]

        XCTAssertEqual("repeated_import_message {\n  d: -9\n}\nrepeated_import_message {\n  d: 999999\n}\n", a.textFormatString())

        assertTextFormatEncode("repeated_import_message {\n  d: -9\n}\nrepeated_import_message {\n  d: 999999\n}\n") {(o: inout MessageTestType) in o.repeatedImportMessage = [importMessage, importMessage2] }

        do {
            let message = try MessageTestType(textFormatString:"repeated_import_message: {\n  d: -9\n}\nrepeated_import_message: {\n  d: 999999\n}\n")
            XCTAssertEqual(message.repeatedImportMessage[0].d, -9)
            XCTAssertEqual(message.repeatedImportMessage[1].d, 999999)
        } catch {
            XCTFail("Presented error: \(error)")
        }

        assertTextFormatDecodeFails("repeated_import_message {\n  d: -9\n}\nrepeated_import_message {\n  d: a\n}\n")
    }

    func testEncoding_repeatedNestedEnum() {
        assertTextFormatEncode("repeated_nested_enum: [BAR, BAZ]\n") {(o: inout MessageTestType) in
            o.repeatedNestedEnum = [.bar, .baz]
        }

        assertTextFormatDecodeSucceeds("repeated_nested_enum: BAR repeated_nested_enum: BAZ") {
            (o: MessageTestType) in
            return o.repeatedNestedEnum == [.bar, .baz]
        }

        assertTextFormatDecodeSucceeds("repeated_nested_enum: [2, BAZ]") {
            (o: MessageTestType) in
            return o.repeatedNestedEnum == [.bar, .baz]
        }
        assertTextFormatDecodeSucceeds("repeated_nested_enum: [] repeated_nested_enum: [2] repeated_nested_enum: [BAZ] repeated_nested_enum: []") {
            (o: MessageTestType) in
            return o.repeatedNestedEnum == [.bar, .baz]
        }

        assertTextFormatDecodeFails("repeated_nested_enum: BAR\nrepeated_nested_enum: a\n")
    }

    func testEncoding_repeatedForeignEnum() {
        assertTextFormatEncode("repeated_foreign_enum: [FOREIGN_BAR, FOREIGN_BAZ]\n") {(o: inout MessageTestType) in
            o.repeatedForeignEnum = [.foreignBar, .foreignBaz]
        }

        assertTextFormatDecodeFails("repeated_foreign_enum: FOREIGN_BAR\nrepeated_foreign_enum: a\n")
    }

    func testEncoding_repeatedImportEnum() {
        assertTextFormatEncode("repeated_import_enum: [IMPORT_BAR, IMPORT_BAZ]\n") {(o: inout MessageTestType) in
            o.repeatedImportEnum = [.importBar, .importBaz]
        }

        assertTextFormatDecodeFails("repeated_import_enum: IMPORT_BAR\nrepeated_import_enum: a\n")
    }

    func testEncoding_repeatedPublicImportMessage() {
        var publicImportMessage = Proto3PublicImportMessage()
        publicImportMessage.e = -999999

        var publicImportMessage2 = publicImportMessage
        publicImportMessage2.e = 999999

        var a = MessageTestType()
        a.repeatedPublicImportMessage = [publicImportMessage, publicImportMessage2]

        XCTAssertEqual("repeated_public_import_message {\n  e: -999999\n}\nrepeated_public_import_message {\n  e: 999999\n}\n", a.textFormatString())

        assertTextFormatEncode("repeated_public_import_message {\n  e: -999999\n}\nrepeated_public_import_message {\n  e: 999999\n}\n") {(o: inout MessageTestType) in o.repeatedPublicImportMessage = [publicImportMessage, publicImportMessage2] }
        assertTextFormatDecodeSucceeds("repeated_public_import_message <e: -999999> repeated_public_import_message <\n  e: 999999\n>\n") {
            (o: MessageTestType) in
            return o.repeatedPublicImportMessage == [publicImportMessage, publicImportMessage2]
        }
        assertTextFormatDecodeSucceeds("repeated_public_import_message {e: -999999} repeated_public_import_message {\n  e: 999999\n}\n") {
            (o: MessageTestType) in
            return o.repeatedPublicImportMessage == [publicImportMessage, publicImportMessage2]
        }
        assertTextFormatDecodeSucceeds("repeated_public_import_message [{e: -999999}, <e: 999999>]") {
            (o: MessageTestType) in
            return o.repeatedPublicImportMessage == [publicImportMessage, publicImportMessage2]
        }
        assertTextFormatDecodeSucceeds("repeated_public_import_message:[{e:999999},{e:-999999}]") {
            (o: MessageTestType) in
            return o.repeatedPublicImportMessage == [publicImportMessage2, publicImportMessage]
        }
        assertTextFormatDecodeFails("repeated_public_import_message:[{e:999999},{e:-999999},]")

        do {
            let message = try MessageTestType(textFormatString:"repeated_public_import_message: {\n  e: -999999\n}\nrepeated_public_import_message: {\n  e: 999999\n}\n")
            XCTAssertEqual(message.repeatedPublicImportMessage[0].e, -999999)
            XCTAssertEqual(message.repeatedPublicImportMessage[1].e, 999999)
        } catch {
            XCTFail("Presented error: \(error)")
        }

        assertTextFormatDecodeFails("repeated_public_import_message: a\n")
        assertTextFormatDecodeFails("repeated_public_import_message: <e:99999}\n")
        assertTextFormatDecodeFails("repeated_public_import_message:[{e:99999}")
        assertTextFormatDecodeFails("repeated_public_import_message: {e:99999>\n")
    }

    func testEncoding_oneofUint32() {
        var a = MessageTestType()
        a.oneofUint32 = 99

        XCTAssertEqual("oneof_uint32: 99\n", a.textFormatString())

        assertTextFormatEncode("oneof_uint32: 99\n") {(o: inout MessageTestType) in o.oneofUint32 = 99 }

        assertTextFormatDecodeFails("oneof_uint32: a\n")
    }

    //
    // Various odd cases...
    //
    func testInvalidToken() {
        assertTextFormatDecodeFails("optional_bool: true\n-5\n")
        assertTextFormatDecodeFails("optional_bool: true!\n")
        assertTextFormatDecodeFails("\"optional_bool\": true\n")
    }

    func testInvalidFieldName() {
        assertTextFormatDecodeFails("invalid_field: value\n")
    }

    func testInvalidCapitalization() {
        assertTextFormatDecodeFails("optionalgroup {\na: 15\n}\n")
        assertTextFormatDecodeFails("OPTIONALgroup {\na: 15\n}\n")
        assertTextFormatDecodeFails("Optional_Bool: true\n")
    }

    func testExplicitDelimiters() {
        assertTextFormatDecodeSucceeds("single_int32:1,single_int64:3;single_uint32:4") {(o: MessageTestType) in
            return o.singleInt32 == 1 && o.singleInt64 == 3 && o.singleUint32 == 4
        }
        assertTextFormatDecodeSucceeds("single_int32:1,\n") {(o: MessageTestType) in
            return o.singleInt32 == 1
        }
        assertTextFormatDecodeSucceeds("single_int32:1;\n") {(o: MessageTestType) in
            return o.singleInt32 == 1
        }
    }

    //
    // Multiple fields at once
    //

    private func configureLargeObject(_ o: inout MessageTestType) {
        o.singleInt32 = 1
        o.singleInt64 = 2
        o.singleUint32 = 3
        o.singleUint64 = 4
        o.singleSint32 = 5
        o.singleSint64 = 6
        o.singleFixed32 = 7
        o.singleFixed64 = 8
        o.singleSfixed32 = 9
        o.singleSfixed64 = 10
        o.singleFloat = 11
        o.singleDouble = 12
        o.singleBool = true
        o.singleString = "abc"
        o.singleBytes = Data(bytes: [65, 66])
        var nested = MessageTestType.NestedMessage()
        nested.bb = 7
        o.singleNestedMessage = nested
        var foreign = Proto3ForeignMessage()
        foreign.c = 88
        o.singleForeignMessage = foreign
        var importMessage = Proto3ImportMessage()
        importMessage.d = -9
        o.singleImportMessage = importMessage
        o.singleNestedEnum = .baz
        o.singleForeignEnum = .foreignBaz
        o.singleImportEnum = .importBaz
        var publicImportMessage = Proto3PublicImportMessage()
        publicImportMessage.e = -999999
        o.singlePublicImportMessage = publicImportMessage
        o.repeatedInt32 = [1, 2]
        o.repeatedInt64 = [3, 4]
        o.repeatedUint32 = [5, 6]
        o.repeatedUint64 = [7, 8]
        o.repeatedSint32 = [9, 10]
        o.repeatedSint64 = [11, 12]
        o.repeatedFixed32 = [13, 14]
        o.repeatedFixed64 = [15, 16]
        o.repeatedSfixed32 = [17, 18]
        o.repeatedSfixed64 = [19, 20]
        o.repeatedFloat = [21, 22]
        o.repeatedDouble = [23, 24]
        o.repeatedBool = [true, false]
        o.repeatedString = ["abc", "def"]
        o.repeatedBytes = [Data(), Data(bytes: [65, 66])]
        var nested2 = nested
        nested2.bb = -7
        o.repeatedNestedMessage = [nested, nested2]
        var foreign2 = foreign
        foreign2.c = -88
        o.repeatedForeignMessage = [foreign, foreign2]
        var importMessage2 = importMessage
        importMessage2.d = 999999
        o.repeatedImportMessage = [importMessage, importMessage2]
        o.repeatedNestedEnum = [.bar, .baz]
        o.repeatedForeignEnum = [.foreignBar, .foreignBaz]
        o.repeatedImportEnum = [.importBar, .importBaz]
        var publicImportMessage2 = publicImportMessage
        publicImportMessage2.e = 999999
        o.repeatedPublicImportMessage = [publicImportMessage, publicImportMessage2]
        o.oneofUint32 = 99
    }

    func testMultipleFields() {
        let expected: String = ("single_int32: 1\n"
            + "single_int64: 2\n"
            + "single_uint32: 3\n"
            + "single_uint64: 4\n"
            + "single_sint32: 5\n"
            + "single_sint64: 6\n"
            + "single_fixed32: 7\n"
            + "single_fixed64: 8\n"
            + "single_sfixed32: 9\n"
            + "single_sfixed64: 10\n"
            + "single_float: 11\n"
            + "single_double: 12\n"
            + "single_bool: true\n"
            + "single_string: \"abc\"\n"
            + "single_bytes: \"AB\"\n"
            + "single_nested_message {\n"
            + "  bb: 7\n"
            + "}\n"
            + "single_foreign_message {\n"
            + "  c: 88\n"
            + "}\n"
            + "single_import_message {\n"
            + "  d: -9\n"
            + "}\n"
            + "single_nested_enum: BAZ\n"
            + "single_foreign_enum: FOREIGN_BAZ\n"
            + "single_import_enum: IMPORT_BAZ\n"
            + "single_public_import_message {\n"
            + "  e: -999999\n"
            + "}\n"
            + "repeated_int32: [1, 2]\n"
            + "repeated_int64: [3, 4]\n"
            + "repeated_uint32: [5, 6]\n"
            + "repeated_uint64: [7, 8]\n"
            + "repeated_sint32: [9, 10]\n"
            + "repeated_sint64: [11, 12]\n"
            + "repeated_fixed32: [13, 14]\n"
            + "repeated_fixed64: [15, 16]\n"
            + "repeated_sfixed32: [17, 18]\n"
            + "repeated_sfixed64: [19, 20]\n"
            + "repeated_float: [21, 22]\n"
            + "repeated_double: [23, 24]\n"
            + "repeated_bool: [true, false]\n"
            + "repeated_string: \"abc\"\n"
            + "repeated_string: \"def\"\n"
            + "repeated_bytes: \"\"\n"
            + "repeated_bytes: \"AB\"\n"
            + "repeated_nested_message {\n"
            + "  bb: 7\n"
            + "}\n"
            + "repeated_nested_message {\n"
            + "  bb: -7\n"
            + "}\n"
            + "repeated_foreign_message {\n"
            + "  c: 88\n"
            + "}\n"
            + "repeated_foreign_message {\n"
            + "  c: -88\n"
            + "}\n"
            + "repeated_import_message {\n"
            + "  d: -9\n"
            + "}\n"
            + "repeated_import_message {\n"
            + "  d: 999999\n"
            + "}\n"
            + "repeated_nested_enum: [BAR, BAZ]\n"
            + "repeated_foreign_enum: [FOREIGN_BAR, FOREIGN_BAZ]\n"
            + "repeated_import_enum: [IMPORT_BAR, IMPORT_BAZ]\n"
            + "repeated_public_import_message {\n"
            + "  e: -999999\n"
            + "}\n"
            + "repeated_public_import_message {\n"
            + "  e: 999999\n"
            + "}\n"
            + "oneof_uint32: 99\n")

        assertTextFormatEncode(expected, configure: configureLargeObject)
    }
}
