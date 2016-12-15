// Tests/SwiftProtobufTests/Test_Conformance.swift - Various conformance issues
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
/// A very few tests from the conformance suite are transcribed here to simplify
/// debugging.
///
// -----------------------------------------------------------------------------

import Foundation
import XCTest
import SwiftProtobuf

class Test_Conformance: XCTestCase, PBTestHelpers {
    typealias MessageTestType = Conformance_TestAllTypes

    func testFieldNaming() throws {
        let json = "{\n  \"fieldname1\": 1,\n  \"fieldName2\": 2,\n   \"FieldName3\": 3\n  }"
        assertJSONDecodeSucceeds(json) { (m: MessageTestType) -> Bool in
            return (m.fieldname1 == 1) && (m.fieldName2 == 2) && (m.fieldName3 == 3)
        }
        do {
            let decoded = try Conformance_TestAllTypes(json: json)
            let recoded = try decoded.serializeJSON()
            XCTAssertEqual(recoded, "{\"fieldname1\":1,\"fieldName2\":2,\"FieldName3\":3}")
        } catch {
            XCTFail("Could not decode?")
        }
    }

    func testFieldNaming_protoNames() throws {
        // Also accept the names in the .proto when decoding
        let json = "{\n  \"fieldname1\": 1,\n  \"field_name2\": 2,\n   \"_field_name3\": 3\n  }"
        assertJSONDecodeSucceeds(json) { (m: MessageTestType) -> Bool in
            return (m.fieldname1 == 1) && (m.fieldName2 == 2) && (m.fieldName3 == 3)
        }
        do {
            let decoded = try Conformance_TestAllTypes(json: json)
            let recoded = try decoded.serializeJSON()
            XCTAssertEqual(recoded, "{\"fieldname1\":1,\"fieldName2\":2,\"FieldName3\":3}")
        } catch {
            XCTFail("Could not decode?")
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
            let decoded = try Conformance_TestAllTypes(json: json)
            let recoded = try decoded.serializeJSON()
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
            (o: Conformance_TestAllTypes) -> Bool in
            let a = o.repeatedBoolWrapper.count == 2
            let b = o.repeatedBoolWrapper[0] == Google_Protobuf_BoolValue(true)
            let c = o.repeatedBoolWrapper[1] == Google_Protobuf_BoolValue(false)
            return a && b && c
        }

        // Google doesn't mention this, but the current Swift
        // architecture handles it through the general case
        assertJSONDecodeSucceeds("{\"repeatedBoolWrapper\": [{\"value\":true}, {\"value\":false}]}") {
            (o: Conformance_TestAllTypes) -> Bool in
            let a = o.repeatedBoolWrapper.count == 2
            let b = o.repeatedBoolWrapper[0] == Google_Protobuf_BoolValue(true)
            let c = o.repeatedBoolWrapper[1] == Google_Protobuf_BoolValue(false)
            return a && b && c
        }
    }

    func testString_badUnicodeEscape() {
        assertJSONDecodeFails("{\"optionalString\": \"\\u")
        assertJSONDecodeFails("{\"optionalString\": \"\\uDC\"}")
        assertJSONDecodeFails("{\"optionalString\": \"\\uDCXY\"}")
    }

    func testString_surrogates() {
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
}
