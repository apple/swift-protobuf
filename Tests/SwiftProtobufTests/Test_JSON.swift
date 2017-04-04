// Tests/SwiftProtobufTests/Test_JSON.swift - Exercise JSON coding
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// JSON is a major new feature for Proto3.  This test suite exercises
/// the JSON coding for all primitive types, including boundary and error
/// cases.
///
// -----------------------------------------------------------------------------

import Foundation
import XCTest
import SwiftProtobuf

class Test_JSON: XCTestCase, PBTestHelpers {
    typealias MessageTestType = Proto3TestAllTypes

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
        let expected: String = ("{"
            + "\"singleInt32\":1,"
            + "\"singleInt64\":\"2\","
            + "\"singleUint32\":3,"
            + "\"singleUint64\":\"4\","
            + "\"singleSint32\":5,"
            + "\"singleSint64\":\"6\","
            + "\"singleFixed32\":7,"
            + "\"singleFixed64\":\"8\","
            + "\"singleSfixed32\":9,"
            + "\"singleSfixed64\":\"10\","
            + "\"singleFloat\":11,"
            + "\"singleDouble\":12,"
            + "\"singleBool\":true,"
            + "\"singleString\":\"abc\","
            + "\"singleBytes\":\"QUI=\","
            + "\"singleNestedMessage\":{\"bb\":7},"
            + "\"singleForeignMessage\":{\"c\":88},"
            + "\"singleImportMessage\":{\"d\":-9},"
            + "\"singleNestedEnum\":\"BAZ\","
            + "\"singleForeignEnum\":\"FOREIGN_BAZ\","
            + "\"singleImportEnum\":\"IMPORT_BAZ\","
            + "\"singlePublicImportMessage\":{\"e\":-999999},"
            + "\"repeatedInt32\":[1,2],"
            + "\"repeatedInt64\":[\"3\",\"4\"],"
            + "\"repeatedUint32\":[5,6],"
            + "\"repeatedUint64\":[\"7\",\"8\"],"
            + "\"repeatedSint32\":[9,10],"
            + "\"repeatedSint64\":[\"11\",\"12\"],"
            + "\"repeatedFixed32\":[13,14],"
            + "\"repeatedFixed64\":[\"15\",\"16\"],"
            + "\"repeatedSfixed32\":[17,18],"
            + "\"repeatedSfixed64\":[\"19\",\"20\"],"
            + "\"repeatedFloat\":[21,22],"
            + "\"repeatedDouble\":[23,24],"
            + "\"repeatedBool\":[true,false],"
            + "\"repeatedString\":[\"abc\",\"def\"],"
            + "\"repeatedBytes\":[\"\",\"QUI=\"],"
            + "\"repeatedNestedMessage\":[{\"bb\":7},{\"bb\":-7}],"
            + "\"repeatedForeignMessage\":[{\"c\":88},{\"c\":-88}],"
            + "\"repeatedImportMessage\":[{\"d\":-9},{\"d\":999999}],"
            + "\"repeatedNestedEnum\":[\"BAR\",\"BAZ\"],"
            + "\"repeatedForeignEnum\":[\"FOREIGN_BAR\",\"FOREIGN_BAZ\"],"
            + "\"repeatedImportEnum\":[\"IMPORT_BAR\",\"IMPORT_BAZ\"],"
            + "\"repeatedPublicImportMessage\":[{\"e\":-999999},{\"e\":999999}],"
            + "\"oneofUint32\":99"
            + "}")
        assertJSONEncode(expected, configure: configureLargeObject)
    }

    func testSingleInt32() {
        assertJSONEncode("{\"singleInt32\":1}") {(o: inout MessageTestType) in
            o.singleInt32 = 1
        }
        assertJSONEncode("{\"singleInt32\":2147483647}") {(o: inout MessageTestType) in
            o.singleInt32 = Int32.max
        }
        assertJSONEncode("{\"singleInt32\":-2147483648}") {(o: inout MessageTestType) in
            o.singleInt32 = Int32.min
        }
        // 32-bit overflow
        assertJSONDecodeFails("{\"singleInt32\":2147483648}")
        // Explicit 'null' is permitted, proto3 decodes it to default value
        assertJSONDecodeSucceeds("{\"singleInt32\":null}") {(o:MessageTestType) in
            o.singleInt32 == 0}
        // Quoted or unquoted numbers, positive, negative, or zero
        assertJSONDecodeSucceeds("{\"singleInt32\":1}") {(o:MessageTestType) in
            o.singleInt32 == 1}
        assertJSONDecodeSucceeds("{\"singleInt32\":\"1\"}") {(o:MessageTestType) in
            o.singleInt32 == 1}
        assertJSONDecodeSucceeds("{\"singleInt32\":\"\\u0030\"}") {(o:MessageTestType) in
            o.singleInt32 == 0}
        assertJSONDecodeSucceeds("{\"singleInt32\":\"\\u0031\"}") {(o:MessageTestType) in
            o.singleInt32 == 1}
        assertJSONDecodeSucceeds("{\"singleInt32\":\"\\u00310\"}") {(o:MessageTestType) in
            o.singleInt32 == 10}
        assertJSONDecodeSucceeds("{\"singleInt32\":0}") {(o:MessageTestType) in
            o.singleInt32 == 0}
        assertJSONDecodeSucceeds("{\"singleInt32\":\"0\"}") {(o:MessageTestType) in
            o.singleInt32 == 0}
        assertJSONDecodeSucceeds("{\"singleInt32\":-0}") {(o:MessageTestType) in
            o.singleInt32 == 0}
        assertJSONDecodeSucceeds("{\"singleInt32\":\"-0\"}") {(o:MessageTestType) in
            o.singleInt32 == 0}
        assertJSONDecodeSucceeds("{\"singleInt32\":-1}") {(o:MessageTestType) in
            o.singleInt32 == -1}
        assertJSONDecodeSucceeds("{\"singleInt32\":\"-1\"}") {(o:MessageTestType) in
            o.singleInt32 == -1}
        // JSON RFC does not accept leading zeros
        assertJSONDecodeFails("{\"singleInt32\":00000000000000000000001}")
        assertJSONDecodeFails("{\"singleInt32\":\"01\"}")
        assertJSONDecodeFails("{\"singleInt32\":-01}")
        assertJSONDecodeFails("{\"singleInt32\":\"-00000000000000000000001\"}")
        // Exponents are okay, as long as result is integer
        assertJSONDecodeSucceeds("{\"singleInt32\":2.147483647e9}") {(o:MessageTestType) in
            o.singleInt32 == Int32.max}
        assertJSONDecodeSucceeds("{\"singleInt32\":-2.147483648e9}") {(o:MessageTestType) in
            o.singleInt32 == Int32.min}
        assertJSONDecodeSucceeds("{\"singleInt32\":1e3}") {(o:MessageTestType) in
            o.singleInt32 == 1000}
        assertJSONDecodeSucceeds("{\"singleInt32\":100e-2}") {(o:MessageTestType) in
            o.singleInt32 == 1}
        assertJSONDecodeFails("{\"singleInt32\":1e-1}")
        // Reject malformed input
        assertJSONDecodeFails("{\"singleInt32\":\\u0031}")
        assertJSONDecodeFails("{\"singleInt32\":\"\\u0030\\u0030\"}")
        assertJSONDecodeFails("{\"singleInt32\":\" 1\"}")
        assertJSONDecodeFails("{\"singleInt32\":\"1 \"}")
        assertJSONDecodeFails("{\"singleInt32\":\"01\"}")
        assertJSONDecodeFails("{\"singleInt32\":true}")
        assertJSONDecodeFails("{\"singleInt32\":0x102}")
        assertJSONDecodeFails("{\"singleInt32\":{}}")
        assertJSONDecodeFails("{\"singleInt32\":[]}")
        // Try to get the library to access past the end of the string...
        assertJSONDecodeFails("{\"singleInt32\":0")
        assertJSONDecodeFails("{\"singleInt32\":-0")
        assertJSONDecodeFails("{\"singleInt32\":0.1")
        assertJSONDecodeFails("{\"singleInt32\":0.")
        assertJSONDecodeFails("{\"singleInt32\":1")
        assertJSONDecodeFails("{\"singleInt32\":1.")
        assertJSONDecodeFails("{\"singleInt32\":1e")
        assertJSONDecodeFails("{\"singleInt32\":1e1")
        assertJSONDecodeFails("{\"singleInt32\":-1")
        assertJSONDecodeFails("{\"singleInt32\":123e")
        assertJSONDecodeFails("{\"singleInt32\":123.")
        assertJSONDecodeFails("{\"singleInt32\":123")
    }

    func testSingleUInt32() {
        assertJSONEncode("{\"singleUint32\":1}") {(o: inout MessageTestType) in
            o.singleUint32 = 1
        }
        assertJSONEncode("{\"singleUint32\":4294967295}") {(o: inout MessageTestType) in
            o.singleUint32 = UInt32.max
        }
        assertJSONDecodeFails("{\"singleUint32\":4294967296}")
        // Explicit 'null' is permitted, decodes to default
        assertJSONDecodeSucceeds("{\"singleUint32\":null}") {$0.singleUint32 == 0}
        // Quoted or unquoted numbers, positive, negative, or zero
        assertJSONDecodeSucceeds("{\"singleUint32\":1}") {$0.singleUint32 == 1}
        assertJSONDecodeSucceeds("{\"singleUint32\":\"1\"}") {$0.singleUint32 == 1}
        assertJSONDecodeSucceeds("{\"singleUint32\":0}") {$0.singleUint32 == 0}
        assertJSONDecodeSucceeds("{\"singleUint32\":\"0\"}") {$0.singleUint32 == 0}
        // Protobuf JSON does not accept leading zeros
        assertJSONDecodeFails("{\"singleUint32\":01}")
        assertJSONDecodeFails("{\"singleUint32\":\"01\"}")
        // But it does accept exponential (as long as result is integral)
        assertJSONDecodeSucceeds("{\"singleUint32\":4.294967295e9}") {$0.singleUint32 == UInt32.max}
        assertJSONDecodeSucceeds("{\"singleUint32\":1e3}") {$0.singleUint32 == 1000}
        assertJSONDecodeSucceeds("{\"singleUint32\":1.2e3}") {$0.singleUint32 == 1200}
        assertJSONDecodeSucceeds("{\"singleUint32\":1000e-2}") {$0.singleUint32 == 10}
        assertJSONDecodeSucceeds("{\"singleUint32\":1.0}") {$0.singleUint32 == 1}
        assertJSONDecodeSucceeds("{\"singleUint32\":1.000000e2}") {$0.singleUint32 == 100}
        assertJSONDecodeFails("{\"singleUint32\":1e-3}")
        assertJSONDecodeFails("{\"singleUint32\":1.11e1}")
        // Reject malformed input
        assertJSONDecodeFails("{\"singleUint32\":true}")
        assertJSONDecodeFails("{\"singleUint32\":-1}")
        assertJSONDecodeFails("{\"singleUint32\":\"-1\"}")
        assertJSONDecodeFails("{\"singleUint32\":0x102}")
        assertJSONDecodeFails("{\"singleUint32\":{}}")
        assertJSONDecodeFails("{\"singleUint32\":[]}")
    }

    func testSingleInt64() throws {
        // Protoc JSON always quotes Int64 values
        assertJSONEncode("{\"singleInt64\":\"9007199254740992\"}") {(o: inout MessageTestType) in
            o.singleInt64 = 0x20000000000000
        }
        assertJSONEncode("{\"singleInt64\":\"9007199254740991\"}") {(o: inout MessageTestType) in
            o.singleInt64 = 0x1fffffffffffff
        }
        assertJSONEncode("{\"singleInt64\":\"-9007199254740992\"}") {(o: inout MessageTestType) in
            o.singleInt64 = -0x20000000000000
        }
        assertJSONEncode("{\"singleInt64\":\"-9007199254740991\"}") {(o: inout MessageTestType) in
            o.singleInt64 = -0x1fffffffffffff
        }
        assertJSONEncode("{\"singleInt64\":\"9223372036854775807\"}") {(o: inout MessageTestType) in
            o.singleInt64 = Int64.max
        }
        assertJSONEncode("{\"singleInt64\":\"1\"}") {(o: inout MessageTestType) in
            o.singleInt64 = 1
        }
        assertJSONEncode("{\"singleInt64\":\"-1\"}") {(o: inout MessageTestType) in
            o.singleInt64 = -1
        }

        // 0 is default, so proto3 omits it
        var a = MessageTestType()
        a.singleInt64 = 0
        XCTAssertEqual(try a.jsonString(), "{}")

        // Decode should work even with unquoted large numbers
        assertJSONDecodeSucceeds("{\"singleInt64\":9223372036854775807}") {$0.singleInt64 == Int64.max}
        assertJSONDecodeFails("{\"singleInt64\":9223372036854775808}")
        assertJSONDecodeSucceeds("{\"singleInt64\":-9223372036854775808}") {$0.singleInt64 == Int64.min}
        assertJSONDecodeFails("{\"singleInt64\":-9223372036854775809}")
        // Protobuf JSON does not accept leading zeros
        assertJSONDecodeFails("{\"singleInt64\": \"01\" }")
        assertJSONDecodeSucceeds("{\"singleInt64\": \"1\" }") {$0.singleInt64 == 1}
        assertJSONDecodeFails("{\"singleInt64\": \"-01\" }")
        assertJSONDecodeSucceeds("{\"singleInt64\": \"-1\" }") {$0.singleInt64 == -1}
        assertJSONDecodeSucceeds("{\"singleInt64\": \"0\" }") {$0.singleInt64 == 0}
        // Protobuf JSON does accept exponential format for integer fields
        assertJSONDecodeSucceeds("{\"singleInt64\":1e3}") {$0.singleInt64 == 1000}
        assertJSONDecodeSucceeds("{\"singleInt64\":\"9223372036854775807\"}") {$0.singleInt64 == Int64.max}
        assertJSONDecodeSucceeds("{\"singleInt64\":-9.223372036854775808e18}") {$0.singleInt64 == Int64.min}
        assertJSONDecodeFails("{\"singleInt64\":9.223372036854775808e18}") // Out of range
        // Explicit 'null' is permitted, decodes to default (in proto3)
        assertJSONDecodeSucceeds("{\"singleInt64\":null}") {$0.singleInt64 == 0}
        assertJSONDecodeSucceeds("{\"singleInt64\":2147483648}") {$0.singleInt64 == 2147483648}
        assertJSONDecodeSucceeds("{\"singleInt64\":2147483648}") {$0.singleInt64 == 2147483648}
    }

    private func assertRoundTripJSON(file: XCTestFileArgType = #file, line: UInt = #line, configure: (inout MessageTestType) -> Void) {
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

    func testSingleDouble() throws {
        assertJSONEncode("{\"singleDouble\":1}") {(o: inout MessageTestType) in
            o.singleDouble = 1.0
        }
        assertJSONEncode("{\"singleDouble\":\"Infinity\"}") {(o: inout MessageTestType) in
            o.singleDouble = Double.infinity
        }
        assertJSONEncode("{\"singleDouble\":\"-Infinity\"}") {(o: inout MessageTestType) in
            o.singleDouble = -Double.infinity
        }
        assertJSONDecodeSucceeds("{\"singleDouble\":\"Inf\"}") {$0.singleDouble == Double.infinity}
        assertJSONDecodeSucceeds("{\"singleDouble\":\"-Inf\"}") {$0.singleDouble == -Double.infinity}
        assertJSONDecodeSucceeds("{\"singleDouble\":\"1\"}") {$0.singleDouble == 1}
        assertJSONDecodeSucceeds("{\"singleDouble\":\"1.0\"}") {$0.singleDouble == 1.0}
        assertJSONDecodeSucceeds("{\"singleDouble\":\"1.5\"}") {$0.singleDouble == 1.5}
        assertJSONDecodeSucceeds("{\"singleDouble\":\"1.5e1\"}") {$0.singleDouble == 15}
        assertJSONDecodeSucceeds("{\"singleDouble\":\"1.5E1\"}") {$0.singleDouble == 15}
        assertJSONDecodeSucceeds("{\"singleDouble\":\"1\\u002e5e1\"}") {$0.singleDouble == 15}
        assertJSONDecodeSucceeds("{\"singleDouble\":\"1.\\u0035e1\"}") {$0.singleDouble == 15}
        assertJSONDecodeSucceeds("{\"singleDouble\":\"1.5\\u00651\"}") {$0.singleDouble == 15}
        assertJSONDecodeSucceeds("{\"singleDouble\":\"1.5e\\u002b1\"}") {$0.singleDouble == 15}
        assertJSONDecodeSucceeds("{\"singleDouble\":\"1.5e+\\u0031\"}") {$0.singleDouble == 15}
        assertJSONDecodeSucceeds("{\"singleDouble\":\"1.5e+1\"}") {$0.singleDouble == 15}
        assertJSONDecodeSucceeds("{\"singleDouble\":\"15e-1\"}") {$0.singleDouble == 1.5}
        assertJSONDecodeSucceeds("{\"singleDouble\":\"1.0e0\"}") {$0.singleDouble == 1.0}
        // Malformed numbers should fail
        assertJSONDecodeFails("{\"singleDouble\":Infinity}")
        assertJSONDecodeFails("{\"singleDouble\":-Infinity}") // Must be quoted
        assertJSONDecodeFails("{\"singleDouble\":\"inf\"}")
        assertJSONDecodeFails("{\"singleDouble\":\"-inf\"}")
        assertJSONDecodeFails("{\"singleDouble\":NaN}")
        assertJSONDecodeFails("{\"singleDouble\":\"nan\"}")
        assertJSONDecodeFails("{\"singleDouble\":\"1.0.0\"}")
        assertJSONDecodeFails("{\"singleDouble\":00.1}")
        assertJSONDecodeFails("{\"singleDouble\":\"00.1\"}")
        assertJSONDecodeFails("{\"singleDouble\":.1}")
        assertJSONDecodeFails("{\"singleDouble\":\".1\"}")
        assertJSONDecodeFails("{\"singleDouble\":1.}")
        assertJSONDecodeFails("{\"singleDouble\":\"1.\"}")
        assertJSONDecodeFails("{\"singleDouble\":1e}")
        assertJSONDecodeFails("{\"singleDouble\":\"1e\"}")
        assertJSONDecodeFails("{\"singleDouble\":1e+}")
        assertJSONDecodeFails("{\"singleDouble\":\"1e+\"}")
        assertJSONDecodeFails("{\"singleDouble\":1e3.2}")
        assertJSONDecodeFails("{\"singleDouble\":\"1e3.2\"}")
        assertJSONDecodeFails("{\"singleDouble\":1.0.0}")

        // A wide range of numbers should exactly round-trip
        assertRoundTripJSON {$0.singleDouble = 0.1}
        assertRoundTripJSON {$0.singleDouble = 0.01}
        assertRoundTripJSON {$0.singleDouble = 0.001}
        assertRoundTripJSON {$0.singleDouble = 0.0001}
        assertRoundTripJSON {$0.singleDouble = 0.00001}
        assertRoundTripJSON {$0.singleDouble = 0.000001}
        assertRoundTripJSON {$0.singleDouble = 1e-10}
        assertRoundTripJSON {$0.singleDouble = 1e-20}
        assertRoundTripJSON {$0.singleDouble = 1e-30}
        assertRoundTripJSON {$0.singleDouble = 1e-40}
        assertRoundTripJSON {$0.singleDouble = 1e-50}
        assertRoundTripJSON {$0.singleDouble = 1e-60}
        assertRoundTripJSON {$0.singleDouble = 1e-100}
        assertRoundTripJSON {$0.singleDouble = 1e-200}
        assertRoundTripJSON {$0.singleDouble = Double.pi}
        assertRoundTripJSON {$0.singleDouble = 123456.789123456789123}
        assertRoundTripJSON {$0.singleDouble = 1.7976931348623157e+308}
        assertRoundTripJSON {$0.singleDouble = 2.22507385850720138309e-308}
    }

    func testSingleFloat() {
        assertJSONEncode("{\"singleFloat\":1}") {(o: inout MessageTestType) in
            o.singleFloat = 1.0
        }
        assertJSONEncode("{\"singleFloat\":\"Infinity\"}") {(o: inout MessageTestType) in
            o.singleFloat = Float.infinity
        }
        assertJSONEncode("{\"singleFloat\":\"-Infinity\"}") {(o: inout MessageTestType) in
            o.singleFloat = -Float.infinity
        }
        assertJSONDecodeSucceeds("{\"singleFloat\":\"Inf\"}") {$0.singleFloat == Float.infinity}
        assertJSONDecodeSucceeds("{\"singleFloat\":\"-Inf\"}") {$0.singleFloat == -Float.infinity}
        assertJSONDecodeSucceeds("{\"singleFloat\":\"1\"}") {$0.singleFloat == 1}
        assertJSONDecodeSucceeds("{\"singleFloat\":\"1.0\"}") {$0.singleFloat == 1.0}
        assertJSONDecodeSucceeds("{\"singleFloat\":\"1.5\"}") {$0.singleFloat == 1.5}
        assertJSONDecodeSucceeds("{\"singleFloat\":\"1.5e1\"}") {$0.singleFloat == 15}
        assertJSONDecodeSucceeds("{\"singleFloat\":\"1\\u002e5e1\"}") {$0.singleFloat == 15}
        assertJSONDecodeSucceeds("{\"singleFloat\":\"1.\\u0035e1\"}") {$0.singleFloat == 15}
        assertJSONDecodeSucceeds("{\"singleFloat\":\"1.5\\u00651\"}") {$0.singleFloat == 15}
        assertJSONDecodeSucceeds("{\"singleFloat\":\"1.5e\\u002b1\"}") {$0.singleFloat == 15}
        assertJSONDecodeSucceeds("{\"singleFloat\":\"1.5e+\\u0031\"}") {$0.singleFloat == 15}
        assertJSONDecodeSucceeds("{\"singleFloat\":\"1.5e+1\"}") {$0.singleFloat == 15}
        assertJSONDecodeSucceeds("{\"singleFloat\":\"15e-1\"}") {$0.singleFloat == 1.5}
        assertJSONDecodeSucceeds("{\"singleFloat\":\"1.0e0\"}") {$0.singleFloat == 1.0}
        assertJSONDecodeSucceeds("{\"singleFloat\":1.0e0}") {$0.singleFloat == 1.0}
        // Malformed numbers should fail
        assertJSONDecodeFails("{\"singleFloat\":Infinity}")
        assertJSONDecodeFails("{\"singleFloat\":-Infinity}") // Must be quoted
        assertJSONDecodeFails("{\"singleFloat\":NaN}")
        assertJSONDecodeFails("{\"singleFloat\":\"nan\"}")
        assertJSONDecodeFails("{\"singleFloat\":\"1.0.0\"}")
        assertJSONDecodeFails("{\"singleFloat\":1.0.0}")
        assertJSONDecodeFails("{\"singleFloat\":00.1}")
        assertJSONDecodeFails("{\"singleFloat\":\"00.1\"}")
        assertJSONDecodeFails("{\"singleFloat\":.1}")
        assertJSONDecodeFails("{\"singleFloat\":\".1\"}")
        assertJSONDecodeFails("{\"singleFloat\":1.}")
        assertJSONDecodeFails("{\"singleFloat\":\"1.\"}")
        assertJSONDecodeFails("{\"singleFloat\":1e}")
        assertJSONDecodeFails("{\"singleFloat\":\"1e\"}")
        assertJSONDecodeFails("{\"singleFloat\":1e+}")
        assertJSONDecodeFails("{\"singleFloat\":\"1e+\"}")
        assertJSONDecodeFails("{\"singleFloat\":1e3.2}")
        assertJSONDecodeFails("{\"singleFloat\":\"1e3.2\"}")
        // Out-of-range numbers should fail
        assertJSONDecodeFails("{\"singleFloat\":1e39}")

        // A wide range of numbers should exactly round-trip
        assertRoundTripJSON {$0.singleFloat = 0.1}
        assertRoundTripJSON {$0.singleFloat = 0.01}
        assertRoundTripJSON {$0.singleFloat = 0.001}
        assertRoundTripJSON {$0.singleFloat = 0.0001}
        assertRoundTripJSON {$0.singleFloat = 0.00001}
        assertRoundTripJSON {$0.singleFloat = 0.000001}
        assertRoundTripJSON {$0.singleFloat = 1e-10}
        assertRoundTripJSON {$0.singleFloat = 1e-20}
        assertRoundTripJSON {$0.singleFloat = 1e-30}
        assertRoundTripJSON {$0.singleFloat = 1e-40}
        assertRoundTripJSON {$0.singleFloat = 1e-50}
        assertRoundTripJSON {$0.singleFloat = 1e-60}
        assertRoundTripJSON {$0.singleFloat = 1e-100}
        assertRoundTripJSON {$0.singleFloat = 1e-200}
        assertRoundTripJSON {$0.singleFloat = Float.pi}
        assertRoundTripJSON {$0.singleFloat = 123456.789123456789123}
        assertRoundTripJSON {$0.singleFloat = 1999.9999999999}
        assertRoundTripJSON {$0.singleFloat = 1999.9}
        assertRoundTripJSON {$0.singleFloat = 1999.99}
        assertRoundTripJSON {$0.singleFloat = 1999.99}
        assertRoundTripJSON {$0.singleFloat = 3.402823567e+38}
        assertRoundTripJSON {$0.singleFloat = 1.1754944e-38}
    }

    func testSingleDouble_NaN() throws {
        // The helper functions don't work with NaN because NaN != NaN
        var o = Proto3TestAllTypes()
        o.singleDouble = Double.nan
        let encoded = try o.jsonString()
        XCTAssertEqual(encoded, "{\"singleDouble\":\"NaN\"}")
        let o2 = try Proto3TestAllTypes(jsonString: encoded)
        XCTAssert(o2.singleDouble.isNaN == .some(true))
    }

    func testSingleFloat_NaN() throws {
        // The helper functions don't work with NaN because NaN != NaN
        var o = Proto3TestAllTypes()
        o.singleFloat = Float.nan
        let encoded = try o.jsonString()
        XCTAssertEqual(encoded, "{\"singleFloat\":\"NaN\"}")
        do {
            let o2 = try Proto3TestAllTypes(jsonString: encoded)
            XCTAssert(o2.singleFloat.isNaN == .some(true))
        } catch let e {
            XCTFail("Couldn't decode: \(e) -- \(encoded)")
        }
    }

    func testSingleBool() throws {
        assertJSONEncode("{\"singleBool\":true}") {(o: inout MessageTestType) in
            o.singleBool = true
        }

        // False is default, so should not serialize in proto3
        var o = MessageTestType()
        o.singleBool = false
        XCTAssertEqual(try o.jsonString(), "{}")
    }

    func testSingleString() {
        assertJSONEncode("{\"singleString\":\"hello\"}") {(o: inout MessageTestType) in
            o.singleString = "hello"
        }
        // Start of the C1 range
        assertJSONEncode("{\"singleString\":\"~\\u007F\\u0080\\u0081\"}") {(o: inout MessageTestType) in
            o.singleString = "\u{7e}\u{7f}\u{80}\u{81}"
        }
        // End of the C1 range
        assertJSONEncode("{\"singleString\":\"\\u009E\\u009F ¡¢£\"}") {(o: inout MessageTestType) in
            o.singleString = "\u{9e}\u{9f}\u{a0}\u{a1}\u{a2}\u{a3}"
        }

        // Empty string is default, so proto3 omits it
        var a = MessageTestType()
        a.singleString = ""
        XCTAssertEqual(try a.jsonString(), "{}")

        // Example from RFC 7159:  G clef coded as escaped surrogate pair
        assertJSONDecodeSucceeds("{\"singleString\":\"\\uD834\\uDD1E\"}") {$0.singleString == "𝄞"}
        // Ditto, with lowercase hex
        assertJSONDecodeSucceeds("{\"singleString\":\"\\ud834\\udd1e\"}") {$0.singleString == "𝄞"}
        // Same character represented directly
        assertJSONDecodeSucceeds("{\"singleString\":\"𝄞\"}") {$0.singleString == "𝄞"}
        // Various broken surrogate forms
        assertJSONDecodeFails("{\"singleString\":\"\\uDD1E\\uD834\"}")
        assertJSONDecodeFails("{\"singleString\":\"\\uDD1E\"}")
        assertJSONDecodeFails("{\"singleString\":\"\\uD834\"}")
        assertJSONDecodeFails("{\"singleString\":\"\\uDD1E\\u1234\"}")
    }

    func testSingleString_controlCharacters() {
        // This is known to fail on Swift Linux 3.1 and earlier,
        // so skip it there.
        // See https://bugs.swift.org/browse/SR-4218 for details.
#if !os(Linux) || swift(>=3.2)
        // Verify that all C0 controls are correctly escaped
        assertJSONEncode("{\"singleString\":\"\\u0000\\u0001\\u0002\\u0003\\u0004\\u0005\\u0006\\u0007\"}") {(o: inout MessageTestType) in
            o.singleString = "\u{00}\u{01}\u{02}\u{03}\u{04}\u{05}\u{06}\u{07}"
        }
        assertJSONEncode("{\"singleString\":\"\\b\\t\\n\\u000B\\f\\r\\u000E\\u000F\"}") {(o: inout MessageTestType) in
            o.singleString = "\u{08}\u{09}\u{0a}\u{0b}\u{0c}\u{0d}\u{0e}\u{0f}"
        }
        assertJSONEncode("{\"singleString\":\"\\u0010\\u0011\\u0012\\u0013\\u0014\\u0015\\u0016\\u0017\"}") {(o: inout MessageTestType) in
            o.singleString = "\u{10}\u{11}\u{12}\u{13}\u{14}\u{15}\u{16}\u{17}"
        }
        assertJSONEncode("{\"singleString\":\"\\u0018\\u0019\\u001A\\u001B\\u001C\\u001D\\u001E\\u001F\"}") {(o: inout MessageTestType) in
            o.singleString = "\u{18}\u{19}\u{1a}\u{1b}\u{1c}\u{1d}\u{1e}\u{1f}"
        }
#endif
    }

    func testSingleBytes() throws {
        // Empty bytes is default, so proto3 omits it
        var a = MessageTestType()
        a.singleBytes = Data()
        XCTAssertEqual(try a.jsonString(), "{}")

        assertJSONEncode("{\"singleBytes\":\"AA==\"}") {(o: inout MessageTestType) in
            o.singleBytes = Data(bytes: [0])
        }
        assertJSONEncode("{\"singleBytes\":\"AAA=\"}") {(o: inout MessageTestType) in
            o.singleBytes = Data(bytes: [0, 0])
        }
        assertJSONEncode("{\"singleBytes\":\"AAAA\"}") {(o: inout MessageTestType) in
            o.singleBytes = Data(bytes: [0, 0, 0])
        }
        assertJSONEncode("{\"singleBytes\":\"/w==\"}") {(o: inout MessageTestType) in
            o.singleBytes = Data(bytes: [255])
        }
        assertJSONEncode("{\"singleBytes\":\"//8=\"}") {(o: inout MessageTestType) in
            o.singleBytes = Data(bytes: [255, 255])
        }
        assertJSONEncode("{\"singleBytes\":\"////\"}") {(o: inout MessageTestType) in
            o.singleBytes = Data(bytes: [255, 255, 255])
        }
        assertJSONEncode("{\"singleBytes\":\"QQ==\"}") {(o: inout MessageTestType) in
            o.singleBytes = Data(bytes: [65])
        }
        assertJSONDecodeFails("{\"singleBytes\":\"QQ=\"}")
        assertJSONDecodeFails("{\"singleBytes\":\"QQ\"}")
        assertJSONEncode("{\"singleBytes\":\"QUI=\"}") {(o: inout MessageTestType) in
            o.singleBytes = Data(bytes: [65, 66])
        }
        assertJSONDecodeFails("{\"singleBytes\":\"QUI\"}")
        assertJSONEncode("{\"singleBytes\":\"QUJD\"}") {(o: inout MessageTestType) in
            o.singleBytes = Data(bytes: [65, 66, 67])
        }
        assertJSONEncode("{\"singleBytes\":\"QUJDRA==\"}") {(o: inout MessageTestType) in
            o.singleBytes = Data(bytes: [65, 66, 67, 68])
        }
        assertJSONDecodeFails("{\"singleBytes\":\"QUJDRA=\"}")
        assertJSONDecodeFails("{\"singleBytes\":\"QUJDRA\"}")
        assertJSONEncode("{\"singleBytes\":\"QUJDREU=\"}") {(o: inout MessageTestType) in
            o.singleBytes = Data(bytes: [65, 66, 67, 68, 69])
        }
        assertJSONDecodeFails("{\"singleBytes\":\"QUJDREU\"}")
        assertJSONEncode("{\"singleBytes\":\"QUJDREVG\"}") {(o: inout MessageTestType) in
            o.singleBytes = Data(bytes: [65, 66, 67, 68, 69, 70])
        }
    }

    func testSingleBytes2() {
        assertJSONDecodeSucceeds("{\"singleBytes\":\"QUJD\"}") {
            $0.singleBytes == Data(bytes: [65, 66, 67])
        }
    }

    func testSingleBytes_roundtrip() throws {
        for i in UInt8(0)...UInt8(255) {
            let d = Data(bytes: [i])
            let message = Proto3TestAllTypes.with { $0.singleBytes = d }
            let text = try message.jsonString()
            let decoded = try Proto3TestAllTypes(jsonString: text)
            XCTAssertEqual(decoded, message)
            XCTAssertEqual(message.singleBytes[0], i)
        }
    }

    func testSingleNestedMessage() {
        assertJSONEncode("{\"singleNestedMessage\":{\"bb\":1}}") {(o: inout MessageTestType) in
            var sub = Proto3TestAllTypes.NestedMessage()
            sub.bb = 1
            o.singleNestedMessage = sub
        }
    }

    func testSingleNestedEnum() {
        assertJSONEncode("{\"singleNestedEnum\":\"FOO\"}") {(o: inout MessageTestType) in
            o.singleNestedEnum = Proto3TestAllTypes.NestedEnum.foo
        }
        assertJSONDecodeSucceeds("{\"singleNestedEnum\":1}") {$0.singleNestedEnum == .foo}
        // Out-of-range values should be serialized to an int
        assertJSONEncode("{\"singleNestedEnum\":123}") {(o: inout MessageTestType) in
            o.singleNestedEnum = .UNRECOGNIZED(123)
        }
        // TODO: Check whether Google's spec agrees that unknown Enum tags
        // should fail to parse
        assertJSONDecodeFails("{\"singleNestedEnum\":\"UNKNOWN\"}")
    }

    func testRepeatedInt32() {
        assertJSONEncode("{\"repeatedInt32\":[1]}") {(o: inout MessageTestType) in
            o.repeatedInt32 = [1]
        }
        assertJSONEncode("{\"repeatedInt32\":[1,2]}") {(o: inout MessageTestType) in
            o.repeatedInt32 = [1, 2]
        }
        assertEncode([250, 1, 2, 1, 2]) {(o: inout MessageTestType) in
            // Proto3 seems to default to packed for repeated int fields
            o.repeatedInt32 = [1, 2]
        }

        assertJSONDecodeSucceeds("{\"repeatedInt32\":null}") {$0.repeatedInt32 == []}
        assertJSONDecodeSucceeds("{\"repeatedInt32\":[]}") {$0.repeatedInt32 == []}
        assertJSONDecodeSucceeds("{\"repeatedInt32\":[1]}") {$0.repeatedInt32 == [1]}
        assertJSONDecodeSucceeds("{\"repeatedInt32\":[1,2]}") {$0.repeatedInt32 == [1, 2]}
    }

    func testRepeatedString() {
        assertJSONEncode("{\"repeatedString\":[\"\"]}") {(o: inout MessageTestType) in
            o.repeatedString = [""]
        }
        assertJSONEncode("{\"repeatedString\":[\"abc\",\"\"]}") {(o: inout MessageTestType) in
            o.repeatedString = ["abc", ""]
        }
        assertJSONDecodeSucceeds("{\"repeatedString\":null}") {$0.repeatedString == []}
        assertJSONDecodeSucceeds("{\"repeatedString\":[]}") {$0.repeatedString == []}
        assertJSONDecodeSucceeds(" { \"repeatedString\" : [ \"1\" , \"2\" ] } ") {
            $0.repeatedString == ["1", "2"]
        }
    }

    func testRepeatedNestedMessage() {
        assertJSONEncode("{\"repeatedNestedMessage\":[{\"bb\":1}]}") {(o: inout MessageTestType) in
            var sub = Proto3TestAllTypes.NestedMessage()
            sub.bb = 1
            o.repeatedNestedMessage = [sub]
        }
        assertJSONEncode("{\"repeatedNestedMessage\":[{\"bb\":1},{\"bb\":2}]}") {(o: inout MessageTestType) in
            var sub1 = Proto3TestAllTypes.NestedMessage()
            sub1.bb = 1
            var sub2 = Proto3TestAllTypes.NestedMessage()
            sub2.bb = 2
            o.repeatedNestedMessage = [sub1, sub2]
        }
        assertJSONDecodeSucceeds("{\"repeatedNestedMessage\": []}") {
            $0.repeatedNestedMessage == []
        }
    }


    // TODO: Test other repeated field types

    func testOneof() {
        assertJSONEncode("{\"oneofUint32\":1}") {(o: inout MessageTestType) in
            o.oneofUint32 = 1
        }
        assertJSONEncode("{\"oneofString\":\"abc\"}") {(o: inout MessageTestType) in
            o.oneofString = "abc"
        }
        assertJSONEncode("{\"oneofNestedMessage\":{\"bb\":1}}") {(o: inout MessageTestType) in
            var sub = Proto3TestAllTypes.NestedMessage()
            sub.bb = 1
            o.oneofNestedMessage = sub
        }
        assertJSONDecodeFails("{\"oneofString\": 1}")
        assertJSONDecodeFails("{\"oneofUint32\":1,\"oneofString\":\"abc\"}")
        assertJSONDecodeFails("{\"oneofString\":\"abc\",\"oneofUint32\":1}")
    }
}


class Test_JSONPacked: XCTestCase, PBTestHelpers {
    typealias MessageTestType = Proto3TestPackedTypes

    func testPackedFloat() {
        assertJSONEncode("{\"packedFloat\":[1]}") {(o: inout MessageTestType) in
            o.packedFloat = [1]
        }
        assertJSONEncode("{\"packedFloat\":[1,0.25,0.125]}") {(o: inout MessageTestType) in
            o.packedFloat = [1, 0.25, 0.125]
        }
        assertJSONDecodeSucceeds("{\"packedFloat\":[1,0.25,125e-3]}") {
            $0.packedFloat == [1, 0.25, 0.125]
        }
        assertJSONDecodeSucceeds("{\"packedFloat\":null}") {$0.packedFloat == []}
        assertJSONDecodeSucceeds("{\"packedFloat\":[]}") {$0.packedFloat == []}
        assertJSONDecodeSucceeds("{\"packedFloat\":[\"1\"]}") {$0.packedFloat == [1]}
        assertJSONDecodeSucceeds("{\"packedFloat\":[\"1\",2]}") {$0.packedFloat == [1, 2]}
    }

    func testPackedDouble() {
        assertJSONEncode("{\"packedDouble\":[1]}") {(o: inout MessageTestType) in
            o.packedDouble = [1]
        }
        assertJSONEncode("{\"packedDouble\":[1,0.25,0.125]}") {(o: inout MessageTestType) in
            o.packedDouble = [1, 0.25, 0.125]
        }
        assertJSONDecodeSucceeds("{\"packedDouble\":[1,0.25,125e-3]}") {
            $0.packedDouble == [1, 0.25, 0.125]
        }
        assertJSONDecodeSucceeds("{\"packedDouble\":null}") {$0.packedDouble == []}
        assertJSONDecodeSucceeds("{\"packedDouble\":[]}") {$0.packedDouble == []}
        assertJSONDecodeSucceeds("{\"packedDouble\":[\"1\"]}") {$0.packedDouble == [1]}
        assertJSONDecodeSucceeds("{\"packedDouble\":[\"1\",2]}") {$0.packedDouble == [1, 2]}
    }

    func testPackedInt32() {
        assertJSONEncode("{\"packedInt32\":[1]}") {(o: inout MessageTestType) in
            o.packedInt32 = [1]
        }
        assertJSONEncode("{\"packedInt32\":[1,2]}") {(o: inout MessageTestType) in
            o.packedInt32 = [1, 2]
        }
        assertJSONEncode("{\"packedInt32\":[-2147483648,2147483647]}") {(o: inout MessageTestType) in
            o.packedInt32 = [Int32.min, Int32.max]
        }
        assertJSONDecodeSucceeds("{\"packedInt32\":null}") {$0.packedInt32 == []}
        assertJSONDecodeSucceeds("{\"packedInt32\":[]}") {$0.packedInt32 == []}
        assertJSONDecodeSucceeds("{\"packedInt32\":[\"1\"]}") {$0.packedInt32 == [1]}
        assertJSONDecodeSucceeds("{\"packedInt32\":[\"1\",\"2\"]}") {$0.packedInt32 == [1, 2]}
        assertJSONDecodeSucceeds(" { \"packedInt32\" : [ \"1\" , \"2\" ] } ") {$0.packedInt32 == [1, 2]}
    }

    func testPackedInt64() {
        assertJSONEncode("{\"packedInt64\":[\"1\"]}") {(o: inout MessageTestType) in
            o.packedInt64 = [1]
        }
        assertJSONEncode("{\"packedInt64\":[\"9223372036854775807\",\"-9223372036854775808\"]}") {
            (o: inout MessageTestType) in
            o.packedInt64 = [Int64.max, Int64.min]
        }
        assertJSONDecodeSucceeds("{\"packedInt64\":null}") {$0.packedInt64 == []}
        assertJSONDecodeSucceeds("{\"packedInt64\":[]}") {$0.packedInt64 == []}
        assertJSONDecodeSucceeds("{\"packedInt64\":[1]}") {$0.packedInt64 == [1]}
        assertJSONDecodeSucceeds("{\"packedInt64\":[1,2]}") {$0.packedInt64 == [1, 2]}
        assertJSONDecodeFails("{\"packedInt64\":[null]}")
    }

    func testPackedUInt32() {
        assertJSONEncode("{\"packedUint32\":[1]}") {(o: inout MessageTestType) in
            o.packedUint32 = [1]
        }
        assertJSONEncode("{\"packedUint32\":[0,4294967295]}") {(o: inout MessageTestType) in
            o.packedUint32 = [UInt32.min, UInt32.max]
        }
        assertJSONDecodeSucceeds("{\"packedUint32\":null}") {$0.packedUint32 == []}
        assertJSONDecodeSucceeds("{\"packedUint32\":[]}") {$0.packedUint32 == []}
        assertJSONDecodeSucceeds("{\"packedUint32\":[1]}") {$0.packedUint32 == [1]}
        assertJSONDecodeSucceeds("{\"packedUint32\":[1,2]}") {$0.packedUint32 == [1, 2]}
        assertJSONDecodeFails("{\"packedUint32\":[null]}")
        assertJSONDecodeFails("{\"packedUint32\":[-1]}")
        assertJSONDecodeFails("{\"packedUint32\":[1.2]}")
    }

    func testPackedUInt64() {
        assertJSONEncode("{\"packedUint64\":[\"1\"]}") {(o: inout MessageTestType) in
            o.packedUint64 = [1]
        }
        assertJSONEncode("{\"packedUint64\":[\"0\",\"18446744073709551615\"]}") {
            (o: inout MessageTestType) in
            o.packedUint64 = [UInt64.min, UInt64.max]
        }
        assertJSONDecodeSucceeds("{\"packedUint64\":null}") {$0.packedUint64 == []}
        assertJSONDecodeSucceeds("{\"packedUint64\":[]}") {$0.packedUint64 == []}
        assertJSONDecodeSucceeds("{\"packedUint64\":[1]}") {$0.packedUint64 == [1]}
        assertJSONDecodeSucceeds("{\"packedUint64\":[1,2]}") {$0.packedUint64 == [1, 2]}
        assertJSONDecodeFails("{\"packedUint64\":[null]}")
        assertJSONDecodeFails("{\"packedUint64\":[-1]}")
        assertJSONDecodeFails("{\"packedUint64\":[1.2]}")
    }

    func testPackedSInt32() {
        assertJSONEncode("{\"packedSint32\":[1]}") {(o: inout MessageTestType) in
            o.packedSint32 = [1]
        }
        assertJSONEncode("{\"packedSint32\":[-2147483648,2147483647]}") {(o: inout MessageTestType) in
            o.packedSint32 = [Int32.min, Int32.max]
        }
        assertJSONDecodeSucceeds("{\"packedSint32\":null}") {$0.packedSint32 == []}
        assertJSONDecodeSucceeds("{\"packedSint32\":[]}") {$0.packedSint32 == []}
        assertJSONDecodeSucceeds("{\"packedSint32\":[1]}") {$0.packedSint32 == [1]}
        assertJSONDecodeSucceeds("{\"packedSint32\":[1,2]}") {$0.packedSint32 == [1, 2]}
        assertJSONDecodeFails("{\"packedSint32\":[null]}")
        assertJSONDecodeFails("{\"packedSint32\":[1.2]}")
    }

    func testPackedSInt64() {
        assertJSONEncode("{\"packedSint64\":[\"1\"]}") {(o: inout MessageTestType) in
            o.packedSint64 = [1]
        }
        assertJSONEncode("{\"packedSint64\":[\"-9223372036854775808\",\"9223372036854775807\"]}") {
            (o: inout MessageTestType) in
            o.packedSint64 = [Int64.min, Int64.max]
        }
        assertJSONDecodeSucceeds("{\"packedSint64\":null}") {$0.packedSint64 == []}
        assertJSONDecodeSucceeds("{\"packedSint64\":[]}") {$0.packedSint64 == []}
        assertJSONDecodeSucceeds("{\"packedSint64\":[1]}") {$0.packedSint64 == [1]}
        assertJSONDecodeSucceeds("{\"packedSint64\":[1,2]}") {$0.packedSint64 == [1, 2]}
        assertJSONDecodeFails("{\"packedSint64\":[null]}")
        assertJSONDecodeFails("{\"packedSint64\":[1.2]}")
    }

    func testPackedFixed32() {
        assertJSONEncode("{\"packedFixed32\":[1]}") {(o: inout MessageTestType) in
            o.packedFixed32 = [1]
        }
        assertJSONEncode("{\"packedFixed32\":[0,4294967295]}") {(o: inout MessageTestType) in
            o.packedFixed32 = [UInt32.min, UInt32.max]
        }
        assertJSONDecodeSucceeds("{\"packedFixed32\":null}") {$0.packedFixed32 == []}
        assertJSONDecodeSucceeds("{\"packedFixed32\":[]}") {$0.packedFixed32 == []}
        assertJSONDecodeSucceeds("{\"packedFixed32\":[1]}") {$0.packedFixed32 == [1]}
        assertJSONDecodeSucceeds("{\"packedFixed32\":[1,2]}") {$0.packedFixed32 == [1, 2]}
        assertJSONDecodeFails("{\"packedFixed32\":[null]}")
        assertJSONDecodeFails("{\"packedFixed32\":[-1]}")
        assertJSONDecodeFails("{\"packedFixed32\":[1.2]}")
    }

    func testPackedFixed64() {
        assertJSONEncode("{\"packedFixed64\":[\"1\"]}") {(o: inout MessageTestType) in
            o.packedFixed64 = [1]
        }
        assertJSONEncode("{\"packedFixed64\":[\"0\",\"18446744073709551615\"]}") {
            (o: inout MessageTestType) in
            o.packedFixed64 = [UInt64.min, UInt64.max]
        }
        assertJSONDecodeSucceeds("{\"packedFixed64\":null}") {$0.packedFixed64 == []}
        assertJSONDecodeSucceeds("{\"packedFixed64\":[]}") {$0.packedFixed64 == []}
        assertJSONDecodeSucceeds("{\"packedFixed64\":[1]}") {$0.packedFixed64 == [1]}
        assertJSONDecodeSucceeds("{\"packedFixed64\":[1,2]}") {$0.packedFixed64 == [1, 2]}
        assertJSONDecodeFails("{\"packedFixed64\":[null]}")
        assertJSONDecodeFails("{\"packedFixed64\":[-1]}")
        assertJSONDecodeFails("{\"packedFixed64\":[1.2]}")
    }

    func testPackedSFixed32() {
        assertJSONEncode("{\"packedSfixed32\":[1]}") {(o: inout MessageTestType) in
            o.packedSfixed32 = [1]
        }
        assertJSONEncode("{\"packedSfixed32\":[-2147483648,2147483647]}") {(o: inout MessageTestType) in
            o.packedSfixed32 = [Int32.min, Int32.max]
        }
        assertJSONDecodeSucceeds("{\"packedSfixed32\":null}") {$0.packedSfixed32 == []}
        assertJSONDecodeSucceeds("{\"packedSfixed32\":[]}") {$0.packedSfixed32 == []}
        assertJSONDecodeSucceeds("{\"packedSfixed32\":[1]}") {$0.packedSfixed32 == [1]}
        assertJSONDecodeSucceeds("{\"packedSfixed32\":[1,2]}") {$0.packedSfixed32 == [1, 2]}
        assertJSONDecodeFails("{\"packedSfixed32\":[null]}")
        assertJSONDecodeFails("{\"packedSfixed32\":[1.2]}")
    }

    func testPackedSFixed64() {
        assertJSONEncode("{\"packedSfixed64\":[\"1\"]}") {(o: inout MessageTestType) in
            o.packedSfixed64 = [1]
        }
        assertJSONEncode("{\"packedSfixed64\":[\"-9223372036854775808\",\"9223372036854775807\"]}") {
            (o: inout MessageTestType) in
            o.packedSfixed64 = [Int64.min, Int64.max]
        }
        assertJSONDecodeSucceeds("{\"packedSfixed64\":null}") {$0.packedSfixed64 == []}
        assertJSONDecodeSucceeds("{\"packedSfixed64\":[]}") {$0.packedSfixed64 == []}
        assertJSONDecodeSucceeds("{\"packedSfixed64\":[1]}") {$0.packedSfixed64 == [1]}
        assertJSONDecodeSucceeds("{\"packedSfixed64\":[1,2]}") {$0.packedSfixed64 == [1, 2]}
        assertJSONDecodeFails("{\"packedSfixed64\":[null]}")
        assertJSONDecodeFails("{\"packedSfixed64\":[1.2]}")
    }

    func testPackedBool() {
        assertJSONEncode("{\"packedBool\":[true]}") {(o: inout MessageTestType) in
            o.packedBool = [true]
        }
        assertJSONEncode("{\"packedBool\":[true,false]}") {
            (o: inout MessageTestType) in
            o.packedBool = [true,false]
        }
        assertJSONDecodeSucceeds("{\"packedBool\":null}") {$0.packedBool == []}
        assertJSONDecodeSucceeds("{\"packedBool\":[]}") {$0.packedBool == []}
        assertJSONDecodeFails("{\"packedBool\":[null]}")
        assertJSONDecodeFails("{\"packedBool\":[1,0]}")
        assertJSONDecodeFails("{\"packedBool\":[\"true\"]}")
        assertJSONDecodeFails("{\"packedBool\":[\"false\"]}")
    }
}

class Test_JSONUnpacked: XCTestCase, PBTestHelpers {
    typealias MessageTestType = Proto3TestUnpackedTypes

    func testPackedInt32() {
        assertJSONEncode("{\"unpackedInt32\":[1]}") {(o: inout MessageTestType) in
            o.unpackedInt32 = [1]
        }
        assertJSONEncode("{\"unpackedInt32\":[1,2]}") {(o: inout MessageTestType) in
            o.unpackedInt32 = [1, 2]
        }
        assertEncode([208, 5, 1, 208, 5, 2]) {(o: inout MessageTestType) in
            o.unpackedInt32 = [1, 2]
        }

        assertJSONDecodeSucceeds("{\"unpackedInt32\":null}") {$0.unpackedInt32 == []}
        assertJSONDecodeSucceeds("{\"unpackedInt32\":[]}") {$0.unpackedInt32 == []}
        assertJSONDecodeSucceeds("{\"unpackedInt32\":[1]}") {$0.unpackedInt32 == [1]}
        assertJSONDecodeSucceeds("{\"unpackedInt32\":[1,2]}") {$0.unpackedInt32 == [1, 2]}
    }
}
