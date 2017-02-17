// Tests/SwiftProtobufTests/Test_Wrappers.swift - Test well-known wrapper types
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Proto3 includes standard message types that wrap a single primitive value.
/// These include specialized compact JSON codings but are otherwise unremarkable.
///
// -----------------------------------------------------------------------------

import Foundation
import XCTest
import SwiftProtobuf

//TODO: Test Mirror functionality

class Test_Wrappers: XCTestCase {

    func testDoubleValue() throws {
        var m = Google_Protobuf_DoubleValue()
        XCTAssertEqual("0", try m.jsonString())
        XCTAssertEqual(m, try Google_Protobuf_DoubleValue(jsonString:"null"))
        m.value = 1.0
        XCTAssertEqual("1", try m.jsonString())
        XCTAssertNotEqual(m, try Google_Protobuf_DoubleValue(jsonString:"null"))
        XCTAssertEqual([9,0,0,0,0,0,0,240,63], try m.serializedBytes())

        // Check that we can rely on object equality
        var m2 = Google_Protobuf_DoubleValue(1.0)
        XCTAssertEqual(m, m2)
        m2.value = 2.0
        XCTAssertNotEqual(m, m2)

        let m3: Google_Protobuf_DoubleValue = 1.0
        XCTAssertEqual(m, m3)
        XCTAssertNotEqual(m2, m3)
        XCTAssertEqual(m3.value, 1.0)

        // Use object equality to verify decode
        XCTAssertEqual(m, try Google_Protobuf_DoubleValue(jsonString:"1.0"))
        XCTAssertEqual(m2, try Google_Protobuf_DoubleValue(jsonString:"2"))
        XCTAssertEqual(m, try Google_Protobuf_DoubleValue(serializedData: Data(bytes: [9,0,0,0,0,0,0,240,63])))

        // hash
        XCTAssertEqual(m.hashValue, try Google_Protobuf_DoubleValue(jsonString:"1.0").hashValue)
        XCTAssertNotEqual(m.hashValue, try Google_Protobuf_DoubleValue(jsonString:"1.1").hashValue)

        // TODO: Google documents that nulls are preserved; what does this mean?
        // TODO: Is Google_Protobuf_DoubleValue allowed to quote large numbers when serializing?
        // TODO: Should Google_Protobuf_DoubleValue parse quoted numbers?
    }

    func testFloatValue() throws {
        var m = Google_Protobuf_FloatValue()
        XCTAssertEqual("0", try m.jsonString())
        XCTAssertEqual(m, try Google_Protobuf_FloatValue(jsonString:"null"))
        m.value = 1.0
        XCTAssertEqual("1", try m.jsonString())
        XCTAssertEqual([13,0,0,128,63], try m.serializedBytes())

        // Check that we can rely on object equality
        var m2 = Google_Protobuf_FloatValue(1.0)
        XCTAssertEqual(m, m2)
        m2.value = 2.0
        XCTAssertNotEqual(m, m2)

        let m3: Google_Protobuf_DoubleValue = 3.0
        XCTAssertEqual(m3.value, 3.0)

        // Use object equality to verify decode
        XCTAssertEqual(m, try Google_Protobuf_FloatValue(jsonString:"1.0"))
        XCTAssertEqual(m2, try Google_Protobuf_FloatValue(jsonString:"2"))
        XCTAssertEqual(m, try Google_Protobuf_FloatValue(serializedData: Data(bytes: [13,0,0,128,63])))

        XCTAssertThrowsError(try Google_Protobuf_FloatValue(jsonString:"-3.502823e+38"))
        XCTAssertThrowsError(try Google_Protobuf_FloatValue(jsonString:"3.502823e+38"))

        XCTAssertEqual(try Google_Protobuf_FloatValue(jsonString:"-3.402823e+38"), -3.402823e+38)
        XCTAssertEqual(try Google_Protobuf_FloatValue(jsonString:"3.402823e+38"), 3.402823e+38)

        // hash
        XCTAssertEqual(m.hashValue, try Google_Protobuf_FloatValue(jsonString:"1.0").hashValue)
        XCTAssertNotEqual(m.hashValue, try Google_Protobuf_FloatValue(jsonString:"1.1").hashValue)

        // TODO: Google documents that nulls are preserved; what does this mean?
        // TODO: Is Google_Protobuf_FloatValue allowed to quote large numbers when serializing?
        // TODO: Should Google_Protobuf_FloatValue parse quoted numbers?
    }

    func testInt64Value() throws {
        var m = Google_Protobuf_Int64Value()
        XCTAssertEqual("\"0\"", try m.jsonString())
        XCTAssertEqual(m, try Google_Protobuf_Int64Value(jsonString: "null"))
        m.value = 777
        let j2 = try m.jsonString()
        XCTAssertEqual("\"777\"", j2)
        XCTAssertEqual([8,137,6], try m.serializedBytes())
        // TODO: More

        // hash
        XCTAssertEqual(m.hashValue, try Google_Protobuf_Int64Value(jsonString:"777").hashValue)
        XCTAssertNotEqual(m.hashValue, try Google_Protobuf_Int64Value(jsonString:"778").hashValue)
    }

    func testUInt64Value() throws {
        var m = Google_Protobuf_UInt64Value()
        XCTAssertEqual("\"0\"", try m.jsonString())
        XCTAssertEqual(m, try Google_Protobuf_UInt64Value(jsonString: "null"))
        m.value = 777
        XCTAssertEqual("\"777\"", try m.jsonString())
        XCTAssertEqual([8,137,6], try m.serializedBytes())
        // TODO: More

        // hash
        XCTAssertEqual(m.hashValue, try Google_Protobuf_UInt64Value(jsonString:"777").hashValue)
        XCTAssertNotEqual(m.hashValue, try Google_Protobuf_UInt64Value(jsonString:"778").hashValue)
    }

    func testInt32Value() throws {
        var m = Google_Protobuf_Int32Value()
        XCTAssertEqual("0", try m.jsonString())
        XCTAssertEqual(m, try Google_Protobuf_Int32Value(jsonString: "null"))
        m.value = 777
        XCTAssertEqual("777", try m.jsonString())
        XCTAssertEqual([8,137,6], try m.serializedBytes())
        // TODO: More

        // hash
        XCTAssertEqual(m.hashValue, try Google_Protobuf_Int32Value(jsonString:"777").hashValue)
        XCTAssertNotEqual(m.hashValue, try Google_Protobuf_Int32Value(jsonString:"778").hashValue)
    }

    func testUInt32Value() throws {
        var m = Google_Protobuf_UInt32Value()
        XCTAssertEqual("0", try m.jsonString())
        XCTAssertEqual(m, try Google_Protobuf_UInt32Value(jsonString: "null"))
        m.value = 777
        XCTAssertEqual("777", try m.jsonString())
        XCTAssertEqual([8,137,6], try m.serializedBytes())
        // TODO: More

        // hash
        XCTAssertEqual(m.hashValue, try Google_Protobuf_UInt32Value(jsonString:"777").hashValue)
        XCTAssertNotEqual(m.hashValue, try Google_Protobuf_UInt32Value(jsonString:"778").hashValue)
    }

    func testBoolValue() throws {
        var m = Google_Protobuf_BoolValue()
        XCTAssertEqual("false", try m.jsonString())
        XCTAssertEqual(m, try Google_Protobuf_BoolValue(jsonString: "null"))
        m.value = true
        XCTAssertEqual("true", try m.jsonString())
        XCTAssertEqual([8,1], try m.serializedBytes())
        // TODO: More

        // hash
        XCTAssertEqual(m.hashValue, try Google_Protobuf_BoolValue(jsonString:"true").hashValue)
        XCTAssertNotEqual(m.hashValue, try Google_Protobuf_BoolValue(jsonString:"false").hashValue)
    }

    func testStringValue() throws {
        var m = Google_Protobuf_StringValue()
        XCTAssertEqual("\"\"", try m.jsonString())
        XCTAssertEqual(m, try Google_Protobuf_StringValue(jsonString: "null"))
        m.value = "abc"
        XCTAssertEqual("\"abc\"", try m.jsonString())
        XCTAssertEqual([10,3,97,98,99], try m.serializedBytes())
        // TODO: More
        XCTAssertThrowsError(try Google_Protobuf_StringValue(jsonString: "\"\\UABCD\""))
        XCTAssertEqual(try Google_Protobuf_StringValue(jsonString: "\"\\uABCD\""), Google_Protobuf_StringValue("\u{ABCD}"))
        XCTAssertEqual(try Google_Protobuf_StringValue(jsonString: "\"\\\"\\\\\\/\\b\\f\\n\\r\\t\""), Google_Protobuf_StringValue("\"\\/\u{08}\u{0c}\n\r\t"))

        // hash
        XCTAssertEqual(m.hashValue, try Google_Protobuf_StringValue(jsonString:"\"abc\"").hashValue)
        XCTAssertNotEqual(m.hashValue, try Google_Protobuf_StringValue(jsonString:"\"def\"").hashValue)
    }

    func testBytesValue() throws {
        var m = Google_Protobuf_BytesValue()
        XCTAssertEqual("\"\"", try m.jsonString())
        XCTAssertEqual(m, try Google_Protobuf_BytesValue(jsonString: "null"))
        m.value = Data(bytes: [0, 1, 2])
        XCTAssertEqual("\"AAEC\"", try m.jsonString())
        XCTAssertEqual([10,3,0,1,2], try m.serializedBytes())
        // TODO: More

        // hash
        XCTAssertEqual(m.hashValue, try Google_Protobuf_BytesValue(jsonString:"\"AAEC\"").hashValue)
        XCTAssertNotEqual(m.hashValue, try Google_Protobuf_BytesValue(jsonString:"\"AAED\"").hashValue)
    }
}
