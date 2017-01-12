// Tests/SwiftProtobufTests/Test_Unknown_proto3.swift - Unknown field handling for proto3
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Proto3 discards unknown fields for both binary and JSON codings.
///
// -----------------------------------------------------------------------------

import Foundation
import XCTest

// Note: This uses the 'Proto3Arena' version of the empty message.
// 'Arena' just indicates that this empty proto3 message
// happens to be defined in a .proto that is also used for testing
// C++ arena support.

class Test_Unknown_proto3: XCTestCase, PBTestHelpers {
    typealias MessageTestType = Proto3ArenaUnittest_TestEmptyMessage

    /// Verify that json decode ignores the provided fields but otherwise succeeds
    func assertJSONIgnores(_ json: String, file: XCTestFileArgType = #file, line: UInt = #line) {
        do {
            let empty = try Proto3ArenaUnittest_TestEmptyMessage(json: json)
            do {
                let json = try empty.serializeJSON()
                XCTAssertEqual("{}", json, file: file, line: line)
            } catch let e {
                XCTFail("Recoding empty threw error \(e)", file: file, line: line)
            }
        } catch {
                XCTFail("Error decoding into an empty message \(json)", file: file, line: line)
        }
    }

    // Binary PB coding drops unknown fields for proto3
    // (but not proto2; see Test_Unknown_proto2)
    func testBinaryPB() {
        func assertIgnores(_ protobufBytes: [UInt8], file: XCTestFileArgType = #file, line: UInt = #line) {
            do {
                let empty = try Proto3ArenaUnittest_TestEmptyMessage(protobuf: Data(bytes: protobufBytes))
                do {
                    let pb = try empty.serializeProtobuf()
                    XCTAssertEqual(Data(), pb, file: file, line: line)
                } catch {
                    XCTFail("Recoding empty failed", file: file, line: line)
                }
            } catch {
                XCTFail("Decoding threw error \(protobufBytes)", file: file, line: line)
            }
        }
        func assertFails(_ protobufBytes: [UInt8], file: XCTestFileArgType = #file, line: UInt = #line) {
            XCTAssertThrowsError(try Proto3ArenaUnittest_TestEmptyMessage(protobuf: Data(bytes: protobufBytes)), file: file, line: line)
        }
        // Well-formed input should ignore the field on decode, recode without it
        // Malformed input should fail to decode
        assertFails([0])
        assertFails([0, 0])
        assertFails([1])
        assertFails([2])
        assertFails([3])
        assertFails([4])
        assertFails([5])
        assertFails([6])
        assertFails([7])
        assertFails([8])
        assertIgnores([8, 0])
        assertFails([8, 128])
        assertIgnores([9, 0, 0, 0, 0, 0, 0, 0, 0])
        assertFails([9, 0, 0, 0, 0, 0, 0, 0])
        assertFails([9, 0, 0, 0, 0, 0, 0])
        assertFails([9, 0, 0, 0, 0, 0])
        assertFails([9, 0, 0, 0, 0])
        assertFails([9, 0, 0, 0])
        assertFails([9, 0, 0])
        assertFails([9, 0])
        assertFails([9])
        assertFails([10])
        assertIgnores([10, 0])
        assertFails([10, 1])
        assertFails([10, 2, 1])
        assertFails([11]) // Start group #1 but no end group
        assertIgnores([11, 12]) // Start/end group #1
        assertFails([12])
        assertIgnores([13, 0, 0, 0, 0])
        assertFails([13, 0, 0, 0])
        assertFails([13, 0, 0])
        assertFails([13, 0])
        assertFails([13])
        assertFails([14])
        assertFails([15])
        assertIgnores([248, 255, 255, 255, 15, 0]) // Maximum field number
        assertFails([128, 128, 128, 128, 16, 0]) // Out-of-range field number
        assertFails([248, 255, 255, 255, 127, 0]) // Out-of-range field number
    }

    func testJSON() {
        // Unknown fields should be ignored if they are well-formed JSON
        assertJSONIgnores("{\"unknown\":7}")
        assertJSONIgnores("{\"unknown\":null}")
        assertJSONIgnores("{\"unknown\":false}")
        assertJSONIgnores("{\"unknown\":true}")
        assertJSONIgnores("{\"unknown\":  7.0}")
        assertJSONIgnores("{\"unknown\": -3.04}")
        assertJSONIgnores("{\"unknown\":  -7.0e-55}")
        assertJSONIgnores("{\"unknown\":  7.308e+8}")
        assertJSONIgnores("{\"unknown\": \"hi!\"}")
        assertJSONIgnores("{\"unknown\": []}")
        assertJSONIgnores("{\"unknown\": [3, 4, 5]}")
        assertJSONIgnores("{\"unknown\": [[3], [4], [5, [6, [7], 8, null, \"no\"]]]}")
        assertJSONIgnores("{\"unknown\": [3, {}, \"5\"]}")
        assertJSONIgnores("{\"unknown\": {}}")
        assertJSONIgnores("{\"unknown\": {\"foo\": 1}}")
        assertJSONIgnores("{\"unknown\": 7, \"also_unknown\": 8}")
        assertJSONIgnores("{\"unknown\": 7, \"unknown\": 8}") // ???

        // Badly formed JSON should fail to decode, even in unknown sections
        assertJSONDecodeFails("{\"unknown\":  1e999}")
        assertJSONDecodeFails("{\"unknown\": \"hi!\"")
        assertJSONDecodeFails("{\"unknown\": \"hi!}")
        assertJSONDecodeFails("{\"unknown\": qqq }")
        assertJSONDecodeFails("{\"unknown\": { }")
        assertJSONDecodeFails("{\"unknown\": [ }")
        assertJSONDecodeFails("{\"unknown\": { ]}")
        assertJSONDecodeFails("{\"unknown\": ]}")
        assertJSONDecodeFails("{\"unknown\": null true}")
        assertJSONDecodeFails("{\"unknown\": nulll }")
        assertJSONDecodeFails("{\"unknown\": nul }")
        assertJSONDecodeFails("{\"unknown\": Null }")
        assertJSONDecodeFails("{\"unknown\": NULL }")
        assertJSONDecodeFails("{\"unknown\": True }")
        assertJSONDecodeFails("{\"unknown\": False }")
        assertJSONDecodeFails("{\"unknown\": nan }")
        assertJSONDecodeFails("{\"unknown\": NaN }")
        assertJSONDecodeFails("{\"unknown\": Infinity }")
        assertJSONDecodeFails("{\"unknown\": infinity }")
        assertJSONDecodeFails("{\"unknown\": Inf }")
        assertJSONDecodeFails("{\"unknown\": inf }")
        assertJSONDecodeFails("{\"unknown\": 1}}")
        assertJSONDecodeFails("{\"unknown\": {1, 2}}")
        assertJSONDecodeFails("{\"unknown\": 1.2.3.4.5}")
        assertJSONDecodeFails("{\"unknown\": -.04}")
        assertJSONDecodeFails("{\"unknown\": -19.}")
        assertJSONDecodeFails("{\"unknown\": -9.3e+}")
        assertJSONDecodeFails("{\"unknown\": 1 2 3}")
        assertJSONDecodeFails("{\"unknown\": { true false }}")
        assertJSONDecodeFails("{\"unknown\"}")
        assertJSONDecodeFails("{\"unknown\": }")
        assertJSONDecodeFails("{\"unknown\", \"a\": 1}")
    }
}
