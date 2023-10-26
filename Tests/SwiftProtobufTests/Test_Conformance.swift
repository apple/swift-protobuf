// Tests/SwiftProtobufTests/Test_Conformance.swift - Various conformance issues
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// A very few tests from the conformance suite are transcribed here to simplify
/// debugging.
///
// -----------------------------------------------------------------------------

import Foundation
import XCTest
import SwiftProtobuf

final class Test_Conformance: XCTestCase, PBTestHelpers {
    typealias MessageTestType = SwiftProtoTesting_Test3_TestAllTypesProto3

    func testFieldNaming() throws {
        let json = "{\n  \"fieldname1\": 1,\n  \"fieldName2\": 2,\n   \"FieldName3\": 3\n  }"
        assertJSONDecodeSucceeds(json) { (m: MessageTestType) -> Bool in
            return (m.fieldname1 == 1) && (m.fieldName2 == 2) && (m.fieldName3 == 3)
        }
        do {
            let decoded = try SwiftProtoTesting_Test3_TestAllTypesProto3(jsonString: json)
            let recoded = try decoded.jsonString()
            XCTAssertEqual(recoded, "{\"fieldname1\":1,\"fieldName2\":2,\"FieldName3\":3}")
        } catch let e {
            XCTFail("Could not decode? Error: \(e)")
        }
    }

    func testFieldNaming_protoNames() throws {
        // Also accept the names in the .proto when decoding
        let json = "{\n  \"fieldname1\": 1,\n  \"field_name2\": 2,\n   \"_field_name3\": 3\n  }"
        assertJSONDecodeSucceeds(json) { (m: MessageTestType) -> Bool in
            return (m.fieldname1 == 1) && (m.fieldName2 == 2) && (m.fieldName3 == 3)
        }
        do {
            let decoded = try SwiftProtoTesting_Test3_TestAllTypesProto3(jsonString: json)
            let recoded = try decoded.jsonString()
            XCTAssertEqual(recoded, "{\"fieldname1\":1,\"fieldName2\":2,\"FieldName3\":3}")
        } catch let e {
            XCTFail("Could not decode? Error: \(e)")
        }
    }

    func testFieldNaming_escapeInName() throws {
        assertJSONDecodeSucceeds("{\"fieldn\\u0061me1\": 1}") {
            return $0.fieldname1 == 1
        }
    }

    func testInt32_min_roundtrip() throws {
        let json = "{\"optionalInt32\": -2147483648}"
        do {
            let decoded = try SwiftProtoTesting_Test3_TestAllTypesProto3(jsonString: json)
            let recoded = try decoded.jsonString()
            XCTAssertEqual(recoded, "{\"optionalInt32\":-2147483648}")
        } catch {
            XCTFail("Could not decode")
        }
    }

    func testInt32_toosmall() {
        assertJSONDecodeFails("{\"optionalInt32\": -2147483649}")
    }

    func testRepeatedBoolWrapper() {
        assertJSONDecodeSucceeds("{\"repeatedBoolWrapper\": [true, false]}") {
            (o: SwiftProtoTesting_Test3_TestAllTypesProto3) -> Bool in
            return o.repeatedBoolWrapper == [Google_Protobuf_BoolValue(true), Google_Protobuf_BoolValue(false)]
        }
    }

    func testString_unicodeEscape() {
        assertTextFormatDecodeSucceeds("optional_string: \"\\u1234\"") {
            return $0.optionalString == "\u{1234}"
        }
        assertTextFormatDecodeSucceeds("optional_string: \"\\U0001F601\"") {
            return $0.optionalString == "\u{1F601}"
        }

        assertTextFormatDecodeFails("optional_string: \"\\u")
        assertTextFormatDecodeFails("optional_string: \"\\uDC\"")
        assertTextFormatDecodeFails("optional_string: \"\\uDCXY\"")
        assertTextFormatDecodeFails("optional_string: \"\\U")
        assertTextFormatDecodeFails("optional_string: \"\\UDC\"")
        assertTextFormatDecodeFails("optional_string: \"\\UDCXY\"")
        assertTextFormatDecodeFails("optional_string: \"\\U1234DC\"")
        assertTextFormatDecodeFails("optional_string: \"\\U1234DCXY\"")

        assertJSONDecodeSucceeds("{\"optional_string\": \"\\u1234\"}") {
            return $0.optionalString == "\u{1234}"
        }

        assertJSONDecodeFails("{\"optionalString\": \"\\u")
        assertJSONDecodeFails("{\"optionalString\": \"\\uDC\"}")
        assertJSONDecodeFails("{\"optionalString\": \"\\uDCXY\"}")
    }

    func testString_surrogates() {
        // Unpaired low surrogate
        assertTextFormatDecodeFails("optional_string: \"\\uDC00\"")
        assertTextFormatDecodeFails("optional_string: \"\\uDC00x\"")
        assertTextFormatDecodeFails("optional_string: \"\\uDC00\\b\"")
        assertTextFormatDecodeFails("optional_string: \"\\U0000DC00\"")
        assertTextFormatDecodeFails("optional_string: \"\\U0000DC00x\"")
        assertTextFormatDecodeFails("optional_string: \"\\U0000DC00\\b\"")
        // Unpaired high surrogate
        assertTextFormatDecodeFails("optional_string: \"\\uD800\"")
        assertTextFormatDecodeFails("optional_string: \"\\uD800\\u0061\"")
        assertTextFormatDecodeFails("optional_string: \"\\uD800abcdefghijkl\"")
        assertTextFormatDecodeFails("optional_string: \"\\U0000D800\"")
        assertTextFormatDecodeFails("optional_string: \"\\U0000D800\\u0061\"")
        assertTextFormatDecodeFails("optional_string: \"\\U0000D800abcdefghijkl\"")
        // Mis-ordered surrogate
        assertTextFormatDecodeFails("optional_string: \"\\uDE01\\uD83D\"")
        assertTextFormatDecodeFails("optional_string: \"\\U0000DE01\\uD83D\"")
        // Correct surrogate
        // NOTE: This differs from JSON at the moment in that surrogates fail
        // there is a conformance test that recommends this even though the
        // C++ impl accepts it.
        assertTextFormatDecodeFails("optional_string: \"\\uD83D\\uDE01\"")
        assertTextFormatDecodeFails("optional_string: \"\\U0000D83D\\uDE01\"")

        // Unpaired low surrogate
        assertJSONDecodeFails("{\"optionalString\": \"\\uDC00\"}")
        assertJSONDecodeFails("{\"optionalString\": \"\\uDC00x\"}")
        assertJSONDecodeFails("{\"optionalString\": \"\\uDC00\\b\"}")
        // Unpaired high surrogate
        assertJSONDecodeFails("{\"optionalString\": \"\\uD800\"}")
        assertJSONDecodeFails("{\"optionalString\": \"\\uD800\\u0061\"}")
        assertJSONDecodeFails("{\"optionalString\": \"\\uD800abcdefghijkl\"}")
        // Mis-ordered surrogate
        assertJSONDecodeFails("{\"optionalString\": \"\\uDE01\\uD83D\"}")
        // Correct surrogate
        assertJSONDecodeSucceeds("{\"optionalString\": \"\\uD83D\\uDE01\"}") {
            return $0.optionalString == "\u{1F601}"
        }
    }

    func testBytes_unicodeEscape() {
        assertTextFormatDecodeSucceeds("optional_bytes: \"\\u1234\"") {
          return $0.optionalBytes == Data("\u{1234}".utf8)
        }
        assertTextFormatDecodeSucceeds("optional_bytes: \"\\U0001F601\"") {
          return $0.optionalBytes == Data("\u{1F601}".utf8)
        }

        assertTextFormatDecodeFails("optional_bytes: \"\\u")
        assertTextFormatDecodeFails("optional_bytes: \"\\uDC\"")
        assertTextFormatDecodeFails("optional_bytes: \"\\uDCXY\"")
        assertTextFormatDecodeFails("optional_bytes: \"\\U")
        assertTextFormatDecodeFails("optional_bytes: \"\\UDC\"")
        assertTextFormatDecodeFails("optional_bytes: \"\\UDCXY\"")
        assertTextFormatDecodeFails("optional_bytes: \"\\U1234DC\"")
        assertTextFormatDecodeFails("optional_bytes: \"\\U1234DCXY\"")
    }

    func testBytes_surrogates() {
        // Unpaired low surrogate
        assertTextFormatDecodeFails("optional_bytes: \"\\uDC00\"")
        assertTextFormatDecodeFails("optional_bytes: \"\\uDC00x\"")
        assertTextFormatDecodeFails("optional_bytes: \"\\uDC00\\b\"")
        assertTextFormatDecodeFails("optional_bytes: \"\\U0000DC00\"")
        assertTextFormatDecodeFails("optional_bytes: \"\\U0000DC00x\"")
        assertTextFormatDecodeFails("optional_bytes: \"\\U0000DC00\\b\"")
        // Unpaired high surrogate
        assertTextFormatDecodeFails("optional_bytes: \"\\uD800\"")
        assertTextFormatDecodeFails("optional_bytes: \"\\uD800\\u0061\"")
        assertTextFormatDecodeFails("optional_bytes: \"\\uD800abcdefghijkl\"")
        assertTextFormatDecodeFails("optional_bytes: \"\\U0000D800\"")
        assertTextFormatDecodeFails("optional_bytes: \"\\U0000D800\\u0061\"")
        assertTextFormatDecodeFails("optional_bytes: \"\\U0000D800abcdefghijkl\"")
        // Mis-ordered surrogate
        assertTextFormatDecodeFails("optional_bytes: \"\\uDE01\\uD83D\"")
        assertTextFormatDecodeFails("optional_bytes: \"\\U0000DE01\\uD83D\"")
        // Correct surrogate
        // NOTE: Conformance test recommends this even though the C++ impl
        // accepts it.
        assertTextFormatDecodeFails("optional_bytes: \"\\uD83D\\uDE01\"")
        assertTextFormatDecodeFails("optional_bytes: \"\\U0000D83D\\uDE01\"")
    }

    func test_LiteralIncludeLF() {
        assertTextFormatDecodeFails("optional_string: 'first line\nsecond line'")
        assertTextFormatDecodeFails("optional_string: 'first line\rsecond line'")
        assertTextFormatDecodeFails("optional_bytes: 'first line\nsecond line'")
        assertTextFormatDecodeFails("optional_bytes: 'first line\rsecond line'")
    }

    func testMaps_TextFormatKeysSorted() {
        assertTextFormatEncode("map_string_string {\n  key: \"a\"\n  value: \"value\"\n}\nmap_string_string {\n  key: \"b\"\n  value: \"value\"\n}\nmap_string_string {\n  key: \"c\"\n  value: \"value\"\n}\n") {(o: inout MessageTestType) in
            o.mapStringString = ["c":"value", "b":"value", "a":"value"]
        }
        assertTextFormatEncode("map_int32_int32 {\n  key: 1\n  value: 0\n}\nmap_int32_int32 {\n  key: 2\n  value: 0\n}\nmap_int32_int32 {\n  key: 3\n  value: 0\n}\n") {(o: inout MessageTestType) in
            o.mapInt32Int32 = [3:0, 2:0, 1:0]
        }
        assertTextFormatEncode("map_bool_bool {\n  key: false\n  value: false\n}\nmap_bool_bool {\n  key: true\n  value: false\n}\n") {(o: inout MessageTestType) in
            o.mapBoolBool = [true: false, false: false]
        }
    }
}
