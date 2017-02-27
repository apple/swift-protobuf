// Tests/SwiftProtobufTests/Test_Map.swift - Exercise Map handling
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Maps are a new feature for both proto2 and proto3.
///
// -----------------------------------------------------------------------------

import Foundation
import XCTest

class Test_Map: XCTestCase, PBTestHelpers {
    typealias MessageTestType = ProtobufUnittest_TestMap

    func assertMapEncode(_ expectedBlocks: [[UInt8]], file: XCTestFileArgType = #file, line: UInt = #line, configure: (inout MessageTestType) -> Void) {
        let empty = MessageTestType()
        var configured = empty
        configure(&configured)
        XCTAssert(configured != empty, "Object should not be equal to empty object", file: file, line: line)
        do {
            let encoded = try configured.serializedBytes()
            // Reorder the provided blocks to match what we were given
            var t = encoded[0..<encoded.count]
            var availableBlocks = expectedBlocks
            var matched = true // Last check found a match
            while matched && !availableBlocks.isEmpty {
                matched = false
                for n in 0..<availableBlocks.count {
                    var e = availableBlocks[n]
                    if (e.count == t.count && t == e[0..<e.count]) {
                        t = []
                        availableBlocks.remove(at:n)
                        matched = true
                        break
                    } else if (e.count < t.count && t[0..<e.count] == e[0..<e.count]) {
                        t = t[e.count..<t.count]
                        availableBlocks.remove(at:n)
                        matched = true
                        break
                    }
                }
            }
            XCTAssert(availableBlocks.isEmpty && t.isEmpty, "Did not encode correctly: got \(encoded)", file: file, line: line)
            do {
                let decoded = try MessageTestType(serializedBytes: encoded)
                XCTAssert(decoded == configured, "Encode/decode cycle should generate equal object", file: file, line: line)
            } catch let e {
                XCTFail("Encode/decode cycle should not fail: \(e)", file: file, line: line)
            }
        } catch let e {
            XCTFail("Serialization failed for \(configured): \(e)", file: file, line: line)
        }
    }

    func test_mapInt32Int32() {
        assertMapEncode([[10, 4, 8, 1, 16, 2]]) {(o: inout MessageTestType) in
            o.mapInt32Int32 = [1: 2]
        }
        assertMapEncode([[10, 4, 8, 1, 16, 2], [10, 4, 8, 3, 16, 4]]) {(o: inout MessageTestType) in
            o.mapInt32Int32 = [1: 2, 3: 4]
        }
        assertDecodeSucceeds([10, 4, 8, 1, 16, 2]) {
            $0.mapInt32Int32 == [1: 2]
        }
        // TODO: This current doens't fail -
        // 1. The comment imples it should be a bad wire type, but that doesn't
        //    appear to be true, it is a field 1 startGroup.
        // 2. The current known field support seems not to handle startGroups
        //    correctly in that they don't seem to push everything in until the
        //    endGroup.
//        assertDecodeFails([11, 4, 8, 1, 16, 2]) // Bad wire type
    }

    func test_mapInt64Int64() {
        assertMapEncode([[18, 4, 8, 0, 16, 0], [18, 21, 8, 255,255,255,255,255,255,255,255,127, 16, 128,128,128,128,128,128,128,128,128,1]]) {(o: inout MessageTestType) in
            o.mapInt64Int64 = [Int64.max: Int64.min, 0: 0]
        }
    }

    // TODO: Figure out why Swift crashes on this test
    func XXXtest_mapUint32Uint32() {
        assertMapEncode([[26, 4, 8, 1, 16, 2], [26, 8, 8, 255,255,255,255,15, 16, 0]]) {(o: inout MessageTestType) in
            o.mapUint32Uint32 = [UInt32.max: UInt32.min, 1: 2]
        }
    }

    func test_mapUint64Uint64() {
    }

    func test_mapSint32Sint32() {
    }

    func test_mapSint64Sint64() {
    }

    func test_mapFixed32Fixed32() {
    }

    func test_mapFixed64Fixed64() {
    }

    func test_mapSfixed32Sfixed32() {
    }

    func test_mapSfixed64Sfixed64() {
    }

    func test_mapInt32Float() {
    }

    func test_mapInt32Double() {
    }

    func test_mapBoolBool() {
        assertDecodeSucceeds([106, 4, 8, 0, 16, 0]) {
            $0.mapBoolBool == [false: false]
        }
    }

    func test_mapStringString() {
        assertDecodeSucceeds([114, 8, 10, 2, 65, 66, 18, 2, 97, 98]) {
            $0.mapStringString == ["AB": "ab"]
        }
    }

    func test_mapInt32Bytes() {
        assertMapEncode([[122, 5, 8, 1, 18, 1, 1], [122, 5, 8, 2, 18, 1, 2]]) {(o: inout MessageTestType) in
            o.mapInt32Bytes = [1: Data(bytes: [1]), 2: Data(bytes: [2])]
        }
        assertDecodeSucceeds([122, 7, 8, 9, 18, 3, 1, 2, 3]) {
            $0.mapInt32Bytes == [9: Data(bytes: [1, 2, 3])]
        }
        assertDecodeSucceeds([]) {
            $0.mapInt32Bytes == [:]
        }
    }

    func test_mapInt32Enum() {
        assertMapEncode([[130, 1, 4, 8, 1, 16, 2]]) {(o: inout MessageTestType) in
            o.mapInt32Enum = [1: ProtobufUnittest_MapEnum.baz]
        }
    }

    func test_mapInt32ForeignMessage() {
        assertMapEncode([[138, 1, 6, 8, 1, 18, 2, 8, 7]]) {(o: inout MessageTestType) in
            var m1 = ProtobufUnittest_ForeignMessage()
            m1.c = 7
            o.mapInt32ForeignMessage = [1: m1]
        }
    }

    func test_mapStringForeignMessage() {
        assertMapEncode([[146, 1, 7, 10, 1, 97, 18, 2, 8, 7]]) {(o: inout MessageTestType) in
            var m1 = ProtobufUnittest_ForeignMessage()
            m1.c = 7
            o.mapStringForeignMessage = ["a": m1]
        }
    }
}
