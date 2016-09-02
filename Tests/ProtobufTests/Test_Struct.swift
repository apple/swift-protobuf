// Test/Sources/TestSuite/Test_Struct.swift - Verify Struct well-known type
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
/// Struct, Value, ListValue are standard PRoto3 message types that support
/// general ad hoc JSON parsing and serialization.
///
// -----------------------------------------------------------------------------

import XCTest
import Protobuf

class Test_Struct: XCTestCase, PBTestHelpers {
    typealias MessageTestType = Google_Protobuf_Struct

    func testStruct_pbencode() {
        assertEncode([10, 12, 10, 3, 102, 111, 111, 18, 5, 26, 3, 98, 97, 114]) {(o: inout MessageTestType) in
            var v = Google_Protobuf_Value()
            v.stringValue = "bar"
            o.fields["foo"] = v
        }
    }

    func testStruct_pbdecode() {
        assertDecodeSucceeds([10, 7, 10, 1, 97, 18, 2, 32, 1, 10, 7, 10, 1, 98, 18, 2, 8, 0]) { (m) in
            let vTrue = Google_Protobuf_Value(boolValue: true)
            let vNull = Google_Protobuf_Value(nullValue: ())
            var same = Google_Protobuf_Struct()
            same.fields = ["a": vTrue, "b": vNull]
            var different = Google_Protobuf_Struct()
            different.fields = ["a": vTrue, "b": vNull, "c": vNull]

            return (m.fields.count == 2
                && m.fields["a"] == vTrue
                && m.fields["a"] != vNull
                && m.fields["b"] == vNull
                && m.fields["b"] != vTrue
                && m == same
                && m != different)
        }
    }

    func test_JSON() {
        assertJSONDecodeSucceeds("{}") {$0.fields == [:]}
        assertJSONDecodeSucceeds("null") {$0.fields == [:]}
        assertJSONDecodeFails("false")
        assertJSONDecodeFails("true")
        assertJSONDecodeFails("[]")
        assertJSONDecodeFails("{")
        assertJSONDecodeFails("}")
        assertJSONDecodeFails("{}}")
        assertJSONDecodeFails("{]")
        assertJSONDecodeFails("1")
        assertJSONDecodeFails("\"1\"")
    }

    func test_JSON_field() throws {
        // "null" as a field value indicates the field is missing
        // (Except for Value, where "null" indicates NullValue)
        do {
            let c1 = try Conformance_TestAllTypes(json:"{\"optionalStruct\":null}")
            // null here decodes to an empty field.
            // See github.com/google/protobuf Issue #1327
            XCTAssertEqual(try c1.serializeJSON(), "{}")
        } catch {
            XCTFail("Didn't decode c1")
        }
        // But contrast the behavior when we parse a "null" directly:
        let c2 = try Google_Protobuf_Struct(json: "null")
        XCTAssertEqual(c2.fields, [:])

        do {
            let c2 = try Conformance_TestAllTypes(json:"{\"optionalStruct\":{}}")
            XCTAssertNotNil(c2.optionalStruct)
            XCTAssertEqual(c2.optionalStruct.fields, [:])
        } catch {
            XCTFail("Didn't decode c2")
        }
    }

    func test_equality() throws {
        let a1decoded: Google_Protobuf_Struct
        do {
            a1decoded = try Google_Protobuf_Struct(json: "{\"a\":1}")
        } catch {
            XCTFail("Decode failed for {\"a\":1}")
            return
        }
        let a2decoded = try Google_Protobuf_Struct(json: "{\"a\":2}")
        var a1literal = Google_Protobuf_Struct()
        a1literal.fields["a"] = Google_Protobuf_Value(numberValue: 1)
        XCTAssertEqual(a1literal, a1decoded)
        XCTAssertEqual(a1literal.hashValue, a1decoded.hashValue)
        XCTAssertNotEqual(a1decoded, a2decoded)
        // Hash inequality is not guaranteed, but a collision here would be suspicious
        let a1literalHash = a1literal.hashValue
        let a2decodedHash = a2decoded.hashValue
        XCTAssertNotEqual(a1literalHash, a2decodedHash)
    }
}

class Test_JSON_ListValue: XCTestCase, PBTestHelpers {
    typealias MessageTestType = Google_Protobuf_ListValue

    // Since ProtobufJSONList is handbuilt rather than generated,
    // we need to verify all the basic functionality, including
    // serialization, equality, hash, etc.
    func testProtobuf() {
        assertEncode([10, 9, 17, 0, 0, 0, 0, 0, 0, 240, 63, 10, 5, 26, 3, 97, 98, 99, 10, 2, 32, 1]) { (o: inout MessageTestType) in
            o.values.append(Google_Protobuf_Value(numberValue: 1))
            o.values.append(Google_Protobuf_Value(stringValue: "abc"))
            o.values.append(Google_Protobuf_Value(boolValue: true))
        }
    }

    func testJSON() {
        assertJSONEncode("[1,\"abc\",true]") { (o: inout MessageTestType) in
            o.values.append(Google_Protobuf_Value(numberValue: 1))
            o.values.append(Google_Protobuf_Value(stringValue: "abc"))
            o.values.append(Google_Protobuf_Value(boolValue: true))
        }
        assertJSONEncode("[1,\"abc\",true,[1,null],[]]") { (o: inout MessageTestType) in
            o.values.append(Google_Protobuf_Value(numberValue: 1))
            o.values.append(Google_Protobuf_Value(stringValue: "abc"))
            o.values.append(Google_Protobuf_Value(boolValue: true))
            o.values.append(Google_Protobuf_Value(anyArray: [1, Google_Protobuf_NullValue()]))
            o.values.append(Google_Protobuf_Value(anyArray: []))
        }
        assertJSONDecodeSucceeds("[]") {$0.values == []}
        assertJSONDecodeSucceeds("null") {$0.values == []}
        assertJSONDecodeFails("")
        assertJSONDecodeFails("true")
        assertJSONDecodeFails("false")
        assertJSONDecodeFails("{}")
        assertJSONDecodeFails("1.0")
        assertJSONDecodeFails("\"a\"")
        assertJSONDecodeFails("[}")
        assertJSONDecodeFails("[,]")
        assertJSONDecodeFails("[true,]")
        assertJSONDecodeSucceeds("[true]") {$0.values == [Google_Protobuf_Value(boolValue: true)]}
    }

    func test_equality() throws {
        let a1decoded = try Google_Protobuf_ListValue(json: "[1]")
        let a2decoded = try Google_Protobuf_ListValue(json: "[2]")
        var a1literal = Google_Protobuf_ListValue()
        a1literal.values.append(Google_Protobuf_Value(numberValue: 1))
        XCTAssertEqual(a1literal, a1decoded)
        XCTAssertEqual(a1literal.hashValue, a1decoded.hashValue)
        XCTAssertNotEqual(a1decoded, a2decoded)
        // Hash inequality is not guaranteed, but a collision here would be suspicious
        XCTAssertNotEqual(a1literal.hashValue, a2decoded.hashValue)
        XCTAssertNotEqual(a1literal, a2decoded)
    }
}


// TODO: Should have convenience initializers on Google_Protobuf_Value
class Test_JSON_Value: XCTestCase, PBTestHelpers {
    typealias MessageTestType = Google_Protobuf_Value

    func testValue_default() throws {
        let empty = Google_Protobuf_Value()
        let emptyJSON = try empty.serializeJSON()
        XCTAssertEqual("null", emptyJSON)

        XCTAssertEqual(empty, Google_Protobuf_Value(nullValue: ()))
        XCTAssertNotEqual(empty, Google_Protobuf_Value(numberValue: 1))
    }

    func testValue_null() throws {
        let nullFromLiteral: Google_Protobuf_Value = nil
        let null = Google_Protobuf_Value(nullValue: ())
        XCTAssertEqual("null", try null.serializeJSON())
        XCTAssertEqual([8, 0], try null.serializeProtobuf())
        XCTAssertEqual(nullFromLiteral, null)
        XCTAssertNotEqual(nullFromLiteral, Google_Protobuf_Value(numberValue: 1))
        assertJSONDecodeSucceeds("null") {$0.nullValue == .nullValue}
        assertJSONDecodeSucceeds("  null  ") {$0.nullValue == .nullValue}
        assertJSONDecodeFails("numb")

        do {
            let m1 = try Conformance_TestAllTypes(json: "{\"optionalValue\": null}")
            XCTAssertEqual(try m1.serializeJSON(), "{\"optionalValue\":null}")
            XCTAssertEqual(try m1.serializeProtobuf(), [146, 19, 2, 8, 0])
        } catch {
            XCTFail()
        }

        XCTAssertEqual(null.debugDescription, "Google_Protobuf_Value(null)")
    }

    func testValue_number() throws {
        let oneFromIntegerLiteral: Google_Protobuf_Value = 1
        let oneFromFloatLiteral: Google_Protobuf_Value = 1.0
        let twoFromFloatLiteral: Google_Protobuf_Value = 2.0
        XCTAssertEqual(oneFromIntegerLiteral, oneFromFloatLiteral)
        XCTAssertNotEqual(oneFromIntegerLiteral, twoFromFloatLiteral)
        XCTAssertEqual("1", try oneFromIntegerLiteral.serializeJSON())
        XCTAssertEqual([17, 0, 0, 0, 0, 0, 0, 240, 63], try oneFromIntegerLiteral.serializeProtobuf())
        assertJSONEncode("3.25") {(o: inout MessageTestType) in
            o.numberValue = 3.25
        }
        assertJSONDecodeSucceeds("3.25") {$0.numberValue == 3.25}
        assertJSONDecodeSucceeds("  3.25  ") {$0.numberValue == 3.25}
        assertJSONDecodeFails("3.2.5")

        XCTAssertEqual(oneFromIntegerLiteral.debugDescription, "Google_Protobuf_Value(numberValue:1)")
    }

    func testValue_string() throws {
        // Literals and equality testing
        let fromStringLiteral: Google_Protobuf_Value = "abcd"
        XCTAssertEqual(fromStringLiteral, Google_Protobuf_Value(stringValue: "abcd"))
        XCTAssertNotEqual(fromStringLiteral, Google_Protobuf_Value(stringValue: "abc"))
        XCTAssertNotEqual(fromStringLiteral, Google_Protobuf_Value())

        // JSON serialization
        assertJSONEncode("\"abcd\"") {(o: inout MessageTestType) in
            o.stringValue = "abcd"
        }
        assertJSONEncode("\"\"") {(o: inout MessageTestType) in
            o.stringValue = ""
        }
        assertJSONDecodeSucceeds("\"abcd\"") {$0.stringValue == "abcd"}
        assertJSONDecodeSucceeds("  \"abcd\"  ") {$0.stringValue == "abcd"}
        assertJSONDecodeFails("\"abcd\"  XXX")
        assertJSONDecodeFails("\"abcd")

        // JSON serializing special characters
        XCTAssertEqual("\"a\\\"b\"", try Google_Protobuf_Value(stringValue: "a\"b").serializeJSON())
        let valueWithEscapes = Google_Protobuf_Value(stringValue: "a\u{0008}\u{0009}\u{000a}\u{000c}\u{000d}b")
        let serializedValueWithEscapes = try valueWithEscapes.serializeJSON()
        XCTAssertEqual("\"a\\b\\t\\n\\f\\rb\"", serializedValueWithEscapes)
        do {
            let parsedValueWithEscapes = try Google_Protobuf_Value(json: serializedValueWithEscapes)
            XCTAssertEqual(valueWithEscapes.stringValue, parsedValueWithEscapes.stringValue)
        } catch {
            XCTFail("Failed to decode \(serializedValueWithEscapes)")
        }

        // PB serialization
        XCTAssertEqual([26, 3, 97, 34, 98], try Google_Protobuf_Value(stringValue: "a\"b").serializeProtobuf())

        XCTAssertEqual(fromStringLiteral.debugDescription, "Google_Protobuf_Value(stringValue:\"abcd\")")
    }

    func testValue_bool() {
        let trueFromLiteral: Google_Protobuf_Value = true
        let falseFromLiteral: Google_Protobuf_Value = false
        XCTAssertEqual(trueFromLiteral, Google_Protobuf_Value(boolValue: true))
        XCTAssertEqual(falseFromLiteral, Google_Protobuf_Value(boolValue: false))
        XCTAssertNotEqual(falseFromLiteral, trueFromLiteral)
        assertJSONEncode("true") {(o: inout MessageTestType) in
            o.boolValue = true
        }
        assertJSONEncode("false") {(o: inout MessageTestType) in
            o.boolValue = false
        }
        assertJSONDecodeSucceeds("true") {$0.boolValue == true}
        assertJSONDecodeSucceeds("  false  ") {$0.boolValue == false}
        assertJSONDecodeFails("yes")
        assertJSONDecodeFails("  true false   ")

        XCTAssertEqual(trueFromLiteral.debugDescription, "Google_Protobuf_Value(boolValue:true)")
    }

    func testValue_struct() throws {
        assertJSONEncode("{\"a\":1}") {(o: inout MessageTestType) in
            o.structValue = Google_Protobuf_Struct(fields:["a": Google_Protobuf_Value(numberValue: 1)])
        }

        let structValue = try Google_Protobuf_Value(json: "{\"a\":1.0}")
        let d = structValue.debugDescription
        XCTAssertEqual(d, "Google_Protobuf_Value(structValue:{\"a\":1})")
    }

    func testValue_list() throws {
        XCTAssertEqual(Google_Protobuf_ListValue(any: [1]),
            Google_Protobuf_ListValue(values: [Google_Protobuf_Value(numberValue: 1)]))
        XCTAssertNotEqual(Google_Protobuf_ListValue(any: [1]),
            Google_Protobuf_ListValue(values: [Google_Protobuf_Value(numberValue: 2)]))
        assertJSONEncode("[true,1]") {(o: inout MessageTestType) in
            o.listValue = Google_Protobuf_ListValue(any:[true, 1])
        }
        assertJSONDecodeSucceeds("[1, 2, \"abc\"]") {
            return ($0 == Google_Protobuf_Value(anyArray:[1, 2, "abc"])
                && $0 != Google_Protobuf_Value(anyArray:[1, 3, "def"]))
        }

        let listValue = try Google_Protobuf_Value(json: "[1, true, \"abc\"]")
        let d = listValue.debugDescription
        XCTAssertEqual(d, "Google_Protobuf_Value(listValue:[1,true,\"abc\"])")

    }

    func testValue_complex() {
        assertJSONDecodeSucceeds("{\"a\": {\"b\": 1.0}, \"c\": [ 7, true, null, {\"d\": false}]}") {
            let outer = $0.structValue?.fields ?? [:]
            let a = outer["a"]?.structValue?.fields ?? [:]
            let c = outer["c"]?.listValue?.values ?? []
            return (a["b"]?.numberValue == 1.0
                && c.count == 4
                && c[0].numberValue == 7
                && c[1].boolValue == true
                && c[2].nullValue == Google_Protobuf_NullValue()
                && c[3].structValue?.fields["d"]?.boolValue == false)
        }
    }

    func testStruct_conformance() throws {
        let json = ("{\n"
            + "  \"optionalStruct\": {\n"
            + "    \"nullValue\": null,\n"
            + "    \"intValue\": 1234,\n"
            + "    \"boolValue\": true,\n"
            + "    \"doubleValue\": 1234.5678,\n"
            + "    \"stringValue\": \"Hello world!\",\n"
            + "    \"listValue\": [1234, \"5678\"],\n"
            + "    \"objectValue\": {\n"
            + "      \"value\": 0\n"
            + "    }\n"
            + "  }\n"
            + "}\n")
        let m: Conformance_TestAllTypes
        do {
            m = try Conformance_TestAllTypes(json: json)
        } catch {
            XCTFail("Decoding failed: \(json)")
            return
        }
        XCTAssertNotNil(m.optionalStruct)
        let s = m.optionalStruct
        XCTAssertNotNil(s.fields["nullValue"])
        if let nv = s.fields["nullValue"] {
            XCTAssertEqual(nv.nullValue, Google_Protobuf_NullValue())
        }
        XCTAssertNotNil(s.fields["intValue"])
        if let iv = s.fields["intValue"] {
            XCTAssertEqual(iv, Google_Protobuf_Value(numberValue: 1234))
            XCTAssertEqual(iv.numberValue, 1234)
        }
        XCTAssertNotNil(s.fields["boolValue"])
        if let bv = s.fields["boolValue"] {
            XCTAssertEqual(bv, Google_Protobuf_Value(boolValue: true))
            XCTAssertEqual(bv.boolValue, true)
        }
        XCTAssertNotNil(s.fields["doubleValue"])
        if let dv = s.fields["doubleValue"] {
            XCTAssertEqual(dv, Google_Protobuf_Value(numberValue: 1234.5678))
            XCTAssertEqual(dv.numberValue, 1234.5678)
        }
        XCTAssertNotNil(s.fields["stringValue"])
        if let sv = s.fields["stringValue"] {
            XCTAssertEqual(sv, Google_Protobuf_Value(stringValue: "Hello world!"))
            XCTAssertEqual(sv.stringValue, "Hello world!")
        }
        XCTAssertNotNil(s.fields["listValue"])
        if let lv = s.fields["listValue"] {
            XCTAssertEqual(lv.listValue,
                           [Google_Protobuf_Value(numberValue: 1234),
                            Google_Protobuf_Value(stringValue: "5678")])
        }
        XCTAssertNotNil(s.fields["objectValue"])
        if let ov = s.fields["objectValue"] {
            XCTAssertNotNil(ov.structValue?.fields["value"])
            if let inner = s.fields["objectValue"]?.structValue?.fields["value"] {
                XCTAssertEqual(inner, Google_Protobuf_Value(numberValue: 0))
                XCTAssertEqual(inner.numberValue, 0)
            }
        }
    }

    func testStruct_null() throws {
        let json = ("{\n"
            + "  \"optionalStruct\": null\n"
            + "}\n")
        do {
            let decoded = try Conformance_TestAllTypes(json: json)
            let recoded = try decoded.serializeJSON()
            XCTAssertEqual(recoded, "{}")
        } catch {
            XCTFail("Should have decoded")
        }
    }
}
