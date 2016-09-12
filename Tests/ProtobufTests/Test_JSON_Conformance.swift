// Test/Sources/TestSuite/Test_JSON_Conformance.swift - Various JSON tests
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
/// A very few of the conformance tests have been transcribed here to
/// ease debugging of these cases.
///
// -----------------------------------------------------------------------------

import XCTest
import Protobuf

class Test_JSON_Conformance: XCTestCase {
    func assertEmptyDecode(_ json: String, file: XCTestFileArgType = #file, line: UInt = #line) -> () {
        do {
            let decoded = try Conformance_TestAllTypes(json: json)
            XCTAssert(decoded.isEmpty, "Decoded object should be empty \(decoded)", file: file, line: line)
            let recoded = try decoded.serializeJSON()
            XCTAssertEqual(recoded, "{}", file: file, line: line)
            let protobuf = try decoded.serializeProtobufBytes()
            XCTAssertEqual(protobuf, [], file: file, line: line)
        } catch let e {
            XCTFail("Decode failed with error \(e)", file: file, line: line)
        }
    }

    func testNullSupport_regularTypes() throws {
        // All types should permit explicit 'null'
        // 'null' for (almost) any field behaves as though the field had been omitted
        // (But see 'Value' below)
        assertEmptyDecode("{\"optionalInt32\": null}")
        /*
        assertEmptyDecode("{\"optionalInt64\": null}")
        assertEmptyDecode("{\"optionalUint32\": null}")
        assertEmptyDecode("{\"optionalUint64\": null}")
        assertEmptyDecode("{\"optionalBool\": null}")
        assertEmptyDecode("{\"optionalString\": null}")
        assertEmptyDecode("{\"optionalBytes\": null}")
        assertEmptyDecode("{\"optionalNestedEnum\": null}")
        assertEmptyDecode("{\"optionalNestedMessage\": null}")
        assertEmptyDecode("{\"repeatedInt32\": null}")
        assertEmptyDecode("{\"repeatedInt64\": null}")
        assertEmptyDecode("{\"repeatedUint32\": null}")
        assertEmptyDecode("{\"repeatedUint64\": null}")
        assertEmptyDecode("{\"repeatedBool\": null}")
        assertEmptyDecode("{\"repeatedString\": null}")
        assertEmptyDecode("{\"repeatedBytes\": null}")
        assertEmptyDecode("{\"repeatedNestedEnum\": null}")
        assertEmptyDecode("{\"repeatedNestedMessage\": null}")
        assertEmptyDecode("{\"mapInt32Int32\": null}")
        assertEmptyDecode("{\"mapBoolBool\": null}")
        assertEmptyDecode("{\"mapStringNestedMessage\": null}")
 */
    }
    
    func testNullSupport_wellKnownTypes() throws {
        // Including well-known types
        // (But see 'Value' below)
        assertEmptyDecode("{\"optionalFieldMask\": null}")
        assertEmptyDecode("{\"optionalTimestamp\": null}")
        assertEmptyDecode("{\"optionalDuration\": null}")
        assertEmptyDecode("{\"optionalBoolWrapper\": null}")
        assertEmptyDecode("{\"optionalInt32Wrapper\": null}")
        assertEmptyDecode("{\"optionalUint32Wrapper\": null}")
        assertEmptyDecode("{\"optionalInt64Wrapper\": null}")
        assertEmptyDecode("{\"optionalUint64Wrapper\": null}")
        assertEmptyDecode("{\"optionalFloatWrapper\": null}")
        assertEmptyDecode("{\"optionalDoubleWrapper\": null}")
        assertEmptyDecode("{\"optionalStringWrapper\": null}")
        assertEmptyDecode("{\"optionalBytesWrapper\": null}")
        assertEmptyDecode("{\"repeatedBoolWrapper\": null}")
        assertEmptyDecode("{\"repeatedInt32Wrapper\": null}")
        assertEmptyDecode("{\"repeatedUint32Wrapper\": null}")
        assertEmptyDecode("{\"repeatedInt64Wrapper\": null}")
        assertEmptyDecode("{\"repeatedUint64Wrapper\": null}")
        assertEmptyDecode("{\"repeatedFloatWrapper\": null}")
        assertEmptyDecode("{\"repeatedDoubleWrapper\": null}")
        assertEmptyDecode("{\"repeatedStringWrapper\": null}")
        assertEmptyDecode("{\"repeatedBytesWrapper\": null}")
    }
    
    func testNullSupport_Value() throws {
        // BUT: Value fields treat null as a regular value
        let valueNull = "{\"optionalValue\": null}"
        do {
            let decoded = try Conformance_TestAllTypes(json: valueNull)
            XCTAssertFalse(decoded.isEmpty)
            let recoded = try decoded.serializeJSON()
            XCTAssertEqual(recoded, "{\"optionalValue\":null}")
            let protobuf = try decoded.serializeProtobufBytes()
            XCTAssertEqual(protobuf, [146, 19, 2, 8, 0])
        } catch {
            XCTFail("Decode failed with error: \(valueNull)")
        }
    }
    
    func testNullSupport_Repeated() throws {
        // Nulls within repeated lists are errors
        let json1 = "{\"repeatedBoolWrapper\":[true, null, false]}"
        XCTAssertThrowsError(try Conformance_TestAllTypes(json: json1))
        let json2 = "{\"repeatedNestedMessage\":[{}, null]}"
        XCTAssertThrowsError(try Conformance_TestAllTypes(json: json2))
        // Make sure the above is failing for the right reason:
        let json3 = "{\"repeatedNestedMessage\":[{}]}"
        let _ = try Conformance_TestAllTypes(json: json3)
        let json4 = "{\"repeatedNestedMessage\":[null]}"
        XCTAssertThrowsError(try Conformance_TestAllTypes(json: json4))
    }
    
    func testNullSupport_RepeatedValue() throws {
        // BUT: null is valid within repeated Value fields
        let repeatedValueWithNull = "{\"repeatedValue\": [1, null]}"
        do {
            let decoded = try Conformance_TestAllTypes(json: repeatedValueWithNull)
            XCTAssertFalse(decoded.isEmpty)
            XCTAssertEqual(decoded.repeatedValue, [Google_Protobuf_Value(numberValue:1), Google_Protobuf_Value()])
            let recoded = try decoded.serializeJSON()
            XCTAssertEqual(recoded, "{\"repeatedValue\":[1,null]}")
            let protobuf = try decoded.serializeProtobufBytes()
            XCTAssertEqual(protobuf, [226, 19, 9, 17, 0, 0, 0, 0, 0, 0, 240, 63, 226, 19, 2, 8, 0])
        } catch {
            XCTFail("Decode failed with error: \(repeatedValueWithNull)")
        }
    }
    
    func testNullConformance() {
        let start = "{\n        \"optionalBoolWrapper\": null,\n        \"optionalInt32Wrapper\": null,\n        \"optionalUint32Wrapper\": null,\n        \"optionalInt64Wrapper\": null,\n        \"optionalUint64Wrapper\": null,\n        \"optionalFloatWrapper\": null,\n        \"optionalDoubleWrapper\": null,\n        \"optionalStringWrapper\": null,\n        \"optionalBytesWrapper\": null,\n        \"repeatedBoolWrapper\": null,\n        \"repeatedInt32Wrapper\": null,\n        \"repeatedUint32Wrapper\": null,\n        \"repeatedInt64Wrapper\": null,\n        \"repeatedUint64Wrapper\": null,\n        \"repeatedFloatWrapper\": null,\n        \"repeatedDoubleWrapper\": null,\n        \"repeatedStringWrapper\": null,\n        \"repeatedBytesWrapper\": null\n      }"
        do {
            let t = try Conformance_TestAllTypes(json: start)
            XCTAssertEqual(try t.serializeJSON(), "{}")
        } catch {
            XCTFail()
        }
    }

    func testValueList() {
        let start = "{\"optionalValue\":[0,\"hello\"]}"
        do {
            let t = try Conformance_TestAllTypes(json: start)
            XCTAssertEqual(try t.serializeJSON(), start)
        } catch {
            XCTFail()
        }
    }
}
