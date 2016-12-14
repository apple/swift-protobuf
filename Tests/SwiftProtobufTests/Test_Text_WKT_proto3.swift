// Test/Sources/TestSuite/Test_Text_WKT_proto3.swift - Exercise proto3 text format coding
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
/// This is a set of tests for text format protobuf files.
///
// -----------------------------------------------------------------------------

import Foundation
import XCTest
import SwiftProtobuf

class Test_Text_WKT_proto3: XCTestCase, PBTestHelpers {
    typealias MessageTestType = ProtobufUnittest_TestWellKnownTypes

    func assertAnyTest<M: Message & Equatable>(_ message: M, expected: String, file: XCTestFileArgType = #file, line: UInt = #line) {
        let empty = MessageTestType()
        var configured = empty
        configured.anyField = Google_Protobuf_Any(message: message)
        XCTAssert(configured != empty, "Object should not be equal to empty object", file: file, line: line)
        do {
            let encoded = try configured.serializeText()
            XCTAssert(expected == encoded, "Did not encode correctly: got \(encoded)", file: file, line: line)
            do {
                let decoded = try MessageTestType(text: encoded)
                let decodedMessage = try M(any: decoded.anyField)
                let r = (message == decodedMessage)
                XCTAssert(r, "Encode/decode cycle should generate equal object: \(decoded) != \(configured)", file: file, line: line)
            } catch {
                XCTFail("Encode/decode cycle should not throw error, decoding: \(error)", file: file, line: line)
            }
        } catch let e {
            XCTFail("Failed to serialize Text: \(e)\n    \(configured)", file: file, line: line)
        }
    }

    // Any equality is a little tricky, so this tests the contained object
    // after unpacking the Any
    func testAny() {
        assertAnyTest(Google_Protobuf_Duration(seconds: 123, nanos: 123456789),
                      expected: "any_field {\n  type_url: \"type.googleapis.com/google.protobuf.Duration\"\n  value: \"\\b{\\020\\225\\232\\357:\"\n}\n")
        assertAnyTest(Google_Protobuf_Empty(),
                      expected: "any_field {\n  type_url: \"type.googleapis.com/google.protobuf.Empty\"\n  value: \"\"\n}\n")
        assertTextDecodeSucceeds("any_field {[type.googleapis.com/google.protobuf.Duration] {seconds:77,nanos:123456789}}") {(o: MessageTestType) in
            let duration = try Google_Protobuf_Duration(any: o.anyField)
            return duration.seconds == 77 && duration.nanos == 123456789
        }

    }

    func testApi() {
    }

    func testDuration() {
        assertTextEncode(
            "duration_field {\n  seconds: 123\n  nanos: 123456789\n}\n"
        ) {
            (o: inout MessageTestType) in
            o.durationField = Google_Protobuf_Duration(seconds: 123, nanos: 123456789)
        }
    }

    func testEmpty() {
        assertTextEncode(
            "empty_field {\n}\n"
        ) {
            (o: inout MessageTestType) in
            o.emptyField = Google_Protobuf_Empty()
        }
    }

    func testFieldMask() {
        assertTextEncode(
            "field_mask_field {\n  paths: \"foo\"\n  paths: \"bar.baz\"\n}\n"
        ) {
            (o: inout MessageTestType) in
            o.fieldMaskField = Google_Protobuf_FieldMask(protoPaths: "foo", "bar.baz")
        }
    }

    func tesetSourceContext() {
    }

    func testStruct() {
    }

    func testTimestamp() {
        assertTextEncode(
            "timestamp_field {\n  seconds: 123\n  nanos: 123456789\n}\n"
        ) {
            (o: inout MessageTestType) in
            o.timestampField = Google_Protobuf_Timestamp(seconds: 123, nanos: 123456789)
        }
    }

    func testType() {
    }

    func testDoubleValue() {
        assertTextEncode(
            "double_field {\n  value: 1.125\n}\n"
        ) {
            (o: inout MessageTestType) in
            o.doubleField = Google_Protobuf_DoubleValue(1.125)
        }
        assertTextEncode(
            "double_field {\n  value: inf\n}\n"
        ) {
            (o: inout MessageTestType) in
            o.doubleField = Google_Protobuf_DoubleValue(Double.infinity)
        }
        assertTextEncode(
            "double_field {\n  value: -inf\n}\n"
        ) {
            (o: inout MessageTestType) in
            o.doubleField = Google_Protobuf_DoubleValue(-Double.infinity)
        }
    }

    func testFloatValue() {
        assertTextEncode(
            "float_field {\n  value: 1.125\n}\n"
        ) {
            (o: inout MessageTestType) in
            o.floatField = Google_Protobuf_FloatValue(1.125)
        }
        assertTextEncode(
            "float_field {\n  value: inf\n}\n"
        ) {
            (o: inout MessageTestType) in
            o.floatField = Google_Protobuf_FloatValue(Float.infinity)
        }
        assertTextEncode(
            "float_field {\n  value: -inf\n}\n"
        ) {
            (o: inout MessageTestType) in
            o.floatField = Google_Protobuf_FloatValue(-Float.infinity)
        }
    }

    func testInt64Value() {
        assertTextEncode(
            "int64_field {\n  value: 9223372036854775807\n}\n"
        ) {
            (o: inout MessageTestType) in
            o.int64Field = Google_Protobuf_Int64Value(Int64.max)
        }
        assertTextEncode(
            "int64_field {\n  value: -9223372036854775808\n}\n"
        ) {
            (o: inout MessageTestType) in
            o.int64Field = Google_Protobuf_Int64Value(Int64.min)
        }
    }

    func testUInt64Value() {
        assertTextEncode(
            "uint64_field {\n  value: 18446744073709551615\n}\n"
        ) {
            (o: inout MessageTestType) in
            o.uint64Field = Google_Protobuf_UInt64Value(UInt64.max)
        }
    }

    func testInt32Value() {
        assertTextEncode(
            "int32_field {\n  value: 2147483647\n}\n"
        ) {
            (o: inout MessageTestType) in
            o.int32Field = Google_Protobuf_Int32Value(Int32.max)
        }
        assertTextEncode(
            "int32_field {\n  value: -2147483648\n}\n"
        ) {
            (o: inout MessageTestType) in
            o.int32Field = Google_Protobuf_Int32Value(Int32.min)
        }
    }

    func testUInt32Value() {
        assertTextEncode(
            "uint32_field {\n  value: 4294967295\n}\n"
        ) {
            (o: inout MessageTestType) in
            o.uint32Field = Google_Protobuf_UInt32Value(UInt32.max)
        }
    }

    func testBoolValue() {
        assertTextEncode(
            "bool_field {\n  value: true\n}\n"
        ) {
            (o: inout MessageTestType) in
            o.boolField = Google_Protobuf_BoolValue(true)
        }
        // false is the default, so encodes as empty (verified against C++ implementation)
        assertTextEncode(
            "bool_field {\n}\n"
        ) {
            (o: inout MessageTestType) in
            o.boolField = Google_Protobuf_BoolValue(false)
        }
    }

    func testStringValue() {
        assertTextEncode(
            "string_field {\n  value: \"abc\"\n}\n"
        ) {
            (o: inout MessageTestType) in
            o.stringField = Google_Protobuf_StringValue("abc")
        }
    }

    func testBytesValue() {
        assertTextEncode(
            "bytes_field {\n  value: \"abc\"\n}\n"
        ) {
            (o: inout MessageTestType) in
            o.bytesField = Google_Protobuf_BytesValue(Data(bytes: [97, 98, 99]))
        }
    }

    func testValue() {
    }
}
