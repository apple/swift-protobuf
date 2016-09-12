// Test/Soures/TestSuite/Test_Unknown_proto2.swift - Exercise unknown field handling for proto2 messages
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
/// Proto2 messages preserve unknown fields when decoding and recoding binary
/// messages, but drop unknown fields when decoding and recoding JSON format.
///
// -----------------------------------------------------------------------------

import XCTest

/*
 * Verify that unknown fields are correctly preserved by
 * proto2 messages.
 */

class Test_Unknown_proto2: XCTestCase, PBTestHelpers {
    typealias MessageTestType = ProtobufUnittest_TestEmptyMessage

    /// Verify that json decode ignores the provided fields but otherwise succeeds
    func assertJSONIgnores(_ json: String, file: XCTestFileArgType = #file, line: UInt = #line) {
        do {
            let empty = try ProtobufUnittest_TestEmptyMessage(json: json)
            do {
                let json = try empty.serializeJSON()
                XCTAssertEqual("{}", json, file: file, line: line)
            } catch {
                XCTFail("Recoding empty message threw an error")
            }
        } catch {
            XCTFail("empty message threw an error")
        }
    }

    // Binary PB coding preserves unknown fields for proto2
    // (but not proto3; see Test_Unknown_proto3)
    func testBinaryPB() {
        func assertRecodes(_ protobufBytes: [UInt8], file: XCTestFileArgType = #file, line: UInt = #line) {
            do {
                let empty = try ProtobufUnittest_TestEmptyMessage(protobuf: Data(bytes: protobufBytes))
                do {
                    let pb = try empty.serializeProtobuf()
                    XCTAssertEqual(Data(bytes: protobufBytes), pb, file: file, line: line)
                } catch {
                    XCTFail()
                }
            } catch {
                XCTFail(file: file, line: line)
            }
        }
        func assertFails(_ protobufBytes: [UInt8], file: XCTestFileArgType = #file, line: UInt = #line) {
            XCTAssertThrowsError(try ProtobufUnittest_TestEmptyMessage(protobuf: Data(bytes: protobufBytes)), file: file, line: line)
        }
        // Well-formed input should decode/recode as-is; malformed input should fail to decode
        assertFails([0]) // Invalid field number
        assertFails([0, 0])
        assertFails([1]) // Invalid field number
        assertFails([2]) // Invalid field number
        assertFails([3]) // Invalid field number
        assertFails([4]) // Invalid field number
        assertFails([5]) // Invalid field number
        assertFails([6]) // Invalid field number
        assertFails([7]) // Invalid field number
        assertFails([8]) // Varint field #1 but no varint body
        assertRecodes([8, 0])
        assertFails([8, 128]) // Truncated varint
        assertRecodes([9, 0, 0, 0, 0, 0, 0, 0, 0])
        assertFails([9, 0, 0, 0, 0, 0, 0, 0]) // Truncated 64-bit field
        assertFails([9, 0, 0, 0, 0, 0, 0])
        assertFails([9, 0, 0, 0, 0, 0])
        assertFails([9, 0, 0, 0, 0])
        assertFails([9, 0, 0, 0])
        assertFails([9, 0, 0])
        assertFails([9, 0])
        assertFails([9])
        assertFails([10]) // Length-delimited field but no length
        assertRecodes([10, 0]) // Valid 0-length field
        assertFails([10, 1]) // Length 1 but truncated
        assertRecodes([10, 1, 2]) // Length 1 with 1 byte
        assertFails([10, 2, 1]) // Length 2 truncated
        assertFails([11]) // Start group #1 but no end group
        assertRecodes([11, 12]) // Start/end group #1
        assertFails([12]) // Bare end group
        assertRecodes([13, 0, 0, 0, 0])
        assertFails([13, 0, 0, 0])
        assertFails([13, 0, 0])
        assertFails([13, 0])
        assertFails([13])
        assertFails([14])
        assertFails([15])
        assertRecodes([248, 255, 255, 255, 15, 0]) // Maximum field number
        assertFails([128, 128, 128, 128, 16, 0]) // Out-of-range field number
        assertFails([248, 255, 255, 255, 127, 0]) // Out-of-range field number
    }

    // JSON coding drops unknown fields for both proto2 and proto3
    func testJSON() {
        // Unknown fields should be ignored
        assertJSONIgnores("{\"unknown\":7}")
        assertJSONIgnores("{\"unknown\":null}")
        assertJSONIgnores("{\"unknown\":false}")
        assertJSONIgnores("{\"unknown\":true}")
        assertJSONIgnores("{\"unknown\":  7.0}")
        assertJSONIgnores("{\"unknown\": \"hi!\"}")
        assertJSONIgnores("{\"unknown\": []}")
        assertJSONIgnores("{\"unknown\": [3, 4, 5]}")
        assertJSONIgnores("{\"unknown\": [[3], [4], [5, [6, [7], 8, null, \"no\"]]]}")
        assertJSONIgnores("{\"unknown\": [3, {}, \"5\"]}")
        assertJSONIgnores("{\"unknown\": {}}")
        assertJSONIgnores("{\"unknown\": {\"foo\": 1}}")
        assertJSONIgnores("{\"unknown\": 7, \"also_unknown\": 8}")
        assertJSONIgnores("{\"unknown\": 7, \"unknown\": 8}")

        // Badly formed JSON should still fail the decode
        assertJSONDecodeFails("{\"unknown\": \"hi!\"")
        assertJSONDecodeFails("{\"unknown\": \"hi!}")
        assertJSONDecodeFails("{\"unknown\": qqq }")
        assertJSONDecodeFails("{\"unknown\": { }")
    }
}
