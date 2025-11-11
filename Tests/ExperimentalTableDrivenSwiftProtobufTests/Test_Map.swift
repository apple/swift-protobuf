// Tests/ExperimentalTableDrivenSwiftProtobufTests/Test_Map.swift - Exercise table-driven maps
//
// Copyright (c) 2014 - 2025 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Some early tests for table-driven maps that can be built separately
/// without requiring that everything be migrated all at once.
///
// -----------------------------------------------------------------------------

import Foundation
import SwiftProtobuf
import XCTest

final class Test_Map: XCTestCase {
    typealias MessageTestType = SwiftProtoTesting_TestMap

    func testEmpty() {
        let msg = MessageTestType()
        XCTAssertTrue(msg.mapInt32Int32.isEmpty)
        XCTAssertTrue(msg.mapStringString.isEmpty)
    }

    func testAccessors() {
        var msg = MessageTestType()
        msg.mapInt32Int32[5] = 25
        msg.mapInt32Int32[10] = 100
        msg.mapStringString["foo"] = "bar"
        msg.mapStringString["baz"] = "quux"

        XCTAssertEqual(msg.mapInt32Int32.count, 2)
        XCTAssertEqual(msg.mapInt32Int32[5], 25)
        XCTAssertEqual(msg.mapInt32Int32[10], 100)
        XCTAssertNil(msg.mapInt32Int32[20])

        XCTAssertEqual(msg.mapStringString.count, 2)
        XCTAssertEqual(msg.mapStringString["foo"], "bar")
        XCTAssertEqual(msg.mapStringString["baz"], "quux")
        XCTAssertNil(msg.mapStringString["blorp"])
    }

    func testCopyAndModifyCopy() {
        var msg = MessageTestType()
        msg.mapInt32Int32[5] = 25
        msg.mapInt32Int32[10] = 100
        msg.mapStringString["foo"] = "bar"
        msg.mapStringString["baz"] = "quux"

        var msgCopy = msg
        msgCopy.mapInt32Int32.removeValue(forKey: 5)
        msgCopy.mapStringString["foo"] = "notbar"

        XCTAssertEqual(msg.mapInt32Int32.count, 2)
        XCTAssertEqual(msg.mapInt32Int32[5], 25)
        XCTAssertEqual(msg.mapInt32Int32[10], 100)
        XCTAssertNil(msg.mapInt32Int32[20])
        XCTAssertEqual(msg.mapStringString.count, 2)
        XCTAssertEqual(msg.mapStringString["foo"], "bar")
        XCTAssertEqual(msg.mapStringString["baz"], "quux")
        XCTAssertNil(msg.mapStringString["blorp"])

        XCTAssertEqual(msgCopy.mapInt32Int32.count, 1)
        XCTAssertEqual(msgCopy.mapInt32Int32[10], 100)
        XCTAssertNil(msgCopy.mapInt32Int32[5])
        XCTAssertEqual(msgCopy.mapStringString.count, 2)
        XCTAssertEqual(msgCopy.mapStringString["foo"], "notbar")
        XCTAssertEqual(msgCopy.mapStringString["baz"], "quux")
        XCTAssertNil(msgCopy.mapStringString["blorp"])
    }

    func testCopyAndModifyOriginal() {
        var msg = MessageTestType()
        msg.mapInt32Int32[5] = 25
        msg.mapInt32Int32[10] = 100
        msg.mapStringString["foo"] = "bar"
        msg.mapStringString["baz"] = "quux"

        let msgCopy = msg
        msg.mapInt32Int32.removeValue(forKey: 5)
        msg.mapStringString["foo"] = "notbar"

        XCTAssertEqual(msg.mapInt32Int32.count, 1)
        XCTAssertEqual(msg.mapInt32Int32[10], 100)
        XCTAssertNil(msg.mapInt32Int32[5])
        XCTAssertEqual(msg.mapStringString.count, 2)
        XCTAssertEqual(msg.mapStringString["foo"], "notbar")
        XCTAssertEqual(msg.mapStringString["baz"], "quux")
        XCTAssertNil(msg.mapStringString["blorp"])

        XCTAssertEqual(msgCopy.mapInt32Int32.count, 2)
        XCTAssertEqual(msgCopy.mapInt32Int32[5], 25)
        XCTAssertEqual(msgCopy.mapInt32Int32[10], 100)
        XCTAssertNil(msgCopy.mapInt32Int32[20])
        XCTAssertEqual(msgCopy.mapStringString.count, 2)
        XCTAssertEqual(msgCopy.mapStringString["foo"], "bar")
        XCTAssertEqual(msgCopy.mapStringString["baz"], "quux")
        XCTAssertNil(msgCopy.mapStringString["blorp"])
    }

    func testEquality() {
        let lhs = MessageTestType.with {
            $0.mapInt32Int32 = [5: 10]
        }
        XCTAssertTrue(lhs == lhs)

        let rhs = MessageTestType.with {
            $0.mapInt32Int32 = [5: 10, 10: 20]
            $0.mapInt32Int32.removeValue(forKey: 10)
        }
        XCTAssertTrue(lhs == rhs)

        let different = MessageTestType.with {
            $0.mapInt32Int32 = [5: 11]
        }
        XCTAssertFalse(lhs == different)
    }

    func test_mapInt32Int32() {
        assertMapEncode([[10, 4, 8, 1, 16, 2]]) { (o: inout MessageTestType) in
            o.mapInt32Int32 = [1: 2]
        }
        assertMapEncode([[10, 4, 8, 1, 16, 2], [10, 4, 8, 3, 16, 4]]) { (o: inout MessageTestType) in
            o.mapInt32Int32 = [1: 2, 3: 4]
        }
        assertDecodeSucceeds([10, 4, 8, 1, 16, 2]) {
            $0.mapInt32Int32 == [1: 2]
        }
        // Missing map value on the wire.
        assertDecodeSucceeds(inputBytes: [10, 2, 8, 1], recodedBytes: [10, 4, 8, 1, 16, 0]) {
            $0.mapInt32Int32 == [1: 0]
        }
        // Missing map key on the wire.
        assertDecodeSucceeds(inputBytes: [10, 2, 16, 2], recodedBytes: [10, 4, 8, 0, 16, 2]) {
            $0.mapInt32Int32 == [0: 2]
        }
        // Missing map key and value on the wire.
        assertDecodeSucceeds(inputBytes: [10, 0], recodedBytes: [10, 4, 8, 0, 16, 0]) {
            $0.mapInt32Int32 == [0: 0]
        }
        // Skip other field numbers within map entry.
        assertDecodeSucceeds(inputBytes: [10, 6, 8, 1, 24, 3, 16, 2], recodedBytes: [10, 4, 8, 1, 16, 2]) {
            $0.mapInt32Int32 == [1: 2]
        }
    }

    func test_mapInt64Int64() {
        assertMapEncode([
            [18, 4, 8, 0, 16, 0],
            [
                18, 21, 8, 255, 255, 255, 255, 255, 255, 255, 255, 127, 16, 128, 128, 128, 128, 128, 128, 128, 128, 128,
                1,
            ],
        ]) { (o: inout MessageTestType) in
            o.mapInt64Int64 = [Int64.max: Int64.min, 0: 0]
        }
        // Missing map value on the wire.
        assertDecodeSucceeds(inputBytes: [18, 2, 8, 1], recodedBytes: [18, 4, 8, 1, 16, 0]) {
            $0.mapInt64Int64 == [1: 0]
        }
        // Missing map key on the wire.
        assertDecodeSucceeds(inputBytes: [18, 2, 16, 2], recodedBytes: [18, 4, 8, 0, 16, 2]) {
            $0.mapInt64Int64 == [0: 2]
        }
        // Missing map key and value on the wire.
        assertDecodeSucceeds(inputBytes: [18, 0], recodedBytes: [18, 4, 8, 0, 16, 0]) {
            $0.mapInt64Int64 == [0: 0]
        }
        // Skip other field numbers within map entry.
        assertDecodeSucceeds(inputBytes: [18, 6, 8, 1, 24, 3, 16, 2], recodedBytes: [18, 4, 8, 1, 16, 2]) {
            $0.mapInt64Int64 == [1: 2]
        }
    }

    func test_mapUint32Uint32() {
        assertMapEncode([[26, 4, 8, 1, 16, 2], [26, 8, 8, 255, 255, 255, 255, 15, 16, 0]]) {
            (o: inout MessageTestType) in
            o.mapUint32Uint32 = [UInt32.max: UInt32.min, 1: 2]
        }
        // Missing map value on the wire.
        assertDecodeSucceeds(inputBytes: [26, 2, 8, 1], recodedBytes: [26, 4, 8, 1, 16, 0]) {
            $0.mapUint32Uint32 == [1: 0]
        }
        // Missing map key on the wire.
        assertDecodeSucceeds(inputBytes: [26, 2, 16, 2], recodedBytes: [26, 4, 8, 0, 16, 2]) {
            $0.mapUint32Uint32 == [0: 2]
        }
        // Missing map key and value on the wire.
        assertDecodeSucceeds(inputBytes: [26, 0], recodedBytes: [26, 4, 8, 0, 16, 0]) {
            $0.mapUint32Uint32 == [0: 0]
        }
        // Skip other field numbers within map entry.
        assertDecodeSucceeds(inputBytes: [26, 6, 8, 1, 24, 3, 16, 2], recodedBytes: [26, 4, 8, 1, 16, 2]) {
            $0.mapUint32Uint32 == [1: 2]
        }
    }

    func test_mapBoolBool() {
        assertDecodeSucceeds([106, 4, 8, 1, 16, 1]) {
            $0.mapBoolBool == [true: true]
        }
        // Missing map value on the wire.
        assertDecodeSucceeds(inputBytes: [106, 2, 8, 1], recodedBytes: [106, 4, 8, 1, 16, 0]) {
            $0.mapBoolBool == [true: false]
        }
        // Missing map key on the wire.
        assertDecodeSucceeds(inputBytes: [106, 2, 16, 1], recodedBytes: [106, 4, 8, 0, 16, 1]) {
            $0.mapBoolBool == [false: true]
        }
        // Missing map key and value on the wire.
        assertDecodeSucceeds(inputBytes: [106, 0], recodedBytes: [106, 4, 8, 0, 16, 0]) {
            $0.mapBoolBool == [false: false]
        }
        // Skip other field numbers within map entry.
        assertDecodeSucceeds(inputBytes: [106, 6, 8, 1, 24, 3, 16, 1], recodedBytes: [106, 4, 8, 1, 16, 1]) {
            $0.mapBoolBool == [true: true]
        }
    }

    func test_mapStringString() {
        assertDecodeSucceeds([114, 8, 10, 2, 65, 66, 18, 2, 97, 98]) {
            $0.mapStringString == ["AB": "ab"]
        }
        // Missing map value on the wire.
        assertDecodeSucceeds(inputBytes: [114, 4, 10, 2, 65, 66], recodedBytes: [114, 6, 10, 2, 65, 66, 18, 0]) {
            $0.mapStringString == ["AB": ""]
        }
        // Missing map key on the wire.
        assertDecodeSucceeds(inputBytes: [114, 4, 18, 2, 97, 98], recodedBytes: [114, 6, 10, 0, 18, 2, 97, 98]) {
            $0.mapStringString == ["": "ab"]
        }
        // Missing map key and value on the wire.
        assertDecodeSucceeds(inputBytes: [114, 0], recodedBytes: [114, 4, 10, 0, 18, 0]) {
            $0.mapStringString == ["": ""]
        }
        // Skip other field numbers within map entry.
        assertDecodeSucceeds(
            inputBytes: [114, 10, 10, 2, 65, 66, 24, 3, 18, 2, 97, 98],
            recodedBytes: [114, 8, 10, 2, 65, 66, 18, 2, 97, 98]
        ) {
            $0.mapStringString == ["AB": "ab"]
        }
    }

    func test_mapInt32Bytes() {
        assertMapEncode([[122, 5, 8, 1, 18, 1, 1], [122, 5, 8, 2, 18, 1, 2]]) { (o: inout MessageTestType) in
            o.mapInt32Bytes = [1: Data([1]), 2: Data([2])]
        }
        assertDecodeSucceeds([122, 7, 8, 9, 18, 3, 1, 2, 3]) {
            $0.mapInt32Bytes == [9: Data([1, 2, 3])]
        }
        assertDecodeSucceeds([]) {
            $0.mapInt32Bytes == [:]
        }
        // Missing map value on the wire.
        assertDecodeSucceeds(inputBytes: [122, 2, 8, 1], recodedBytes: [122, 4, 8, 1, 18, 0]) {
            $0.mapInt32Bytes == [1: Data()]
        }
        // Missing map key on the wire.
        assertDecodeSucceeds(inputBytes: [122, 3, 18, 1, 1], recodedBytes: [122, 5, 8, 0, 18, 1, 1]) {
            $0.mapInt32Bytes == [0: Data([1])]
        }
        // Missing map key and value on the wire.
        assertDecodeSucceeds(inputBytes: [122, 0], recodedBytes: [122, 4, 8, 0, 18, 0]) {
            $0.mapInt32Bytes == [0: Data()]
        }
        // Skip other field numbers within map entry.
        assertDecodeSucceeds(
            inputBytes: [122, 9, 8, 9, 24, 3, 18, 3, 1, 2, 3],
            recodedBytes: [122, 7, 8, 9, 18, 3, 1, 2, 3]
        ) {
            $0.mapInt32Bytes == [9: Data([1, 2, 3])]
        }
    }

    func test_mapInt32Enum() {
        assertMapEncode([[130, 1, 4, 8, 1, 16, 2]]) { (o: inout MessageTestType) in
            o.mapInt32Enum = [1: SwiftProtoTesting_MapEnum.baz]
        }
        // Missing map value on the wire.
        assertDecodeSucceeds(inputBytes: [130, 1, 2, 8, 1], recodedBytes: [130, 1, 4, 8, 1, 16, 0]) {
            $0.mapInt32Enum == [1: SwiftProtoTesting_MapEnum.foo]
        }
        // Missing map key on the wire.
        assertDecodeSucceeds(inputBytes: [130, 1, 2, 16, 2], recodedBytes: [130, 1, 4, 8, 0, 16, 2]) {
            $0.mapInt32Enum == [0: SwiftProtoTesting_MapEnum.baz]
        }
        // Missing map key and value on the wire.
        assertDecodeSucceeds(inputBytes: [130, 1, 0], recodedBytes: [130, 1, 4, 8, 0, 16, 0]) {
            $0.mapInt32Enum == [0: SwiftProtoTesting_MapEnum.foo]
        }
        // Skip other field numbers within map entry.
        assertDecodeSucceeds(inputBytes: [130, 1, 6, 8, 1, 24, 3, 16, 2], recodedBytes: [130, 1, 4, 8, 1, 16, 2]) {
            $0.mapInt32Enum == [1: SwiftProtoTesting_MapEnum.baz]
        }
    }

    func test_mapInt32ForeignMessage() {
        assertMapEncode([[138, 1, 6, 8, 1, 18, 2, 8, 7]]) { (o: inout MessageTestType) in
            var m1 = SwiftProtoTesting_ForeignMessage()
            m1.c = 7
            o.mapInt32ForeignMessage = [1: m1]
        }
        // Missing map value on the wire.
        assertDecodeSucceeds(inputBytes: [138, 1, 2, 8, 1], recodedBytes: [138, 1, 4, 8, 1, 18, 0]) {
            $0.mapInt32ForeignMessage == [1: SwiftProtoTesting_ForeignMessage()]
        }
        // Missing map key on the wire.
        assertDecodeSucceeds(inputBytes: [138, 1, 4, 18, 2, 8, 7], recodedBytes: [138, 1, 6, 8, 0, 18, 2, 8, 7]) {
            var m1 = SwiftProtoTesting_ForeignMessage()
            m1.c = 7
            return $0.mapInt32ForeignMessage == [0: m1]
        }
        // Missing map key and value on the wire.
        assertDecodeSucceeds(inputBytes: [138, 1, 0], recodedBytes: [138, 1, 4, 8, 0, 18, 0]) {
            $0.mapInt32ForeignMessage == [0: SwiftProtoTesting_ForeignMessage()]
        }
        // Skip other field numbers within map entry.
        assertDecodeSucceeds(
            inputBytes: [138, 1, 8, 8, 1, 24, 3, 18, 2, 8, 7],
            recodedBytes: [138, 1, 6, 8, 1, 18, 2, 8, 7]
        ) {
            var m1 = SwiftProtoTesting_ForeignMessage()
            m1.c = 7
            return $0.mapInt32ForeignMessage == [1: m1]
        }
    }

    func test_mapStringForeignMessage() {
        assertMapEncode([[146, 1, 7, 10, 1, 97, 18, 2, 8, 7]]) { (o: inout MessageTestType) in
            var m1 = SwiftProtoTesting_ForeignMessage()
            m1.c = 7
            o.mapStringForeignMessage = ["a": m1]
        }
        // Missing map value on the wire.
        assertDecodeSucceeds(inputBytes: [146, 1, 3, 10, 1, 97], recodedBytes: [146, 1, 5, 10, 1, 97, 18, 0]) {
            $0.mapStringForeignMessage == ["a": SwiftProtoTesting_ForeignMessage()]
        }
        // Missing map key on the wire.
        assertDecodeSucceeds(inputBytes: [146, 1, 4, 18, 2, 8, 7], recodedBytes: [146, 1, 6, 10, 0, 18, 2, 8, 7]) {
            var m1 = SwiftProtoTesting_ForeignMessage()
            m1.c = 7
            return $0.mapStringForeignMessage == ["": m1]
        }
        // Missing map key and value on the wire.
        assertDecodeSucceeds(inputBytes: [146, 1, 0], recodedBytes: [146, 1, 4, 10, 0, 18, 0]) {
            $0.mapStringForeignMessage == ["": SwiftProtoTesting_ForeignMessage()]
        }
        // Skip other field numbers within map entry.
        assertDecodeSucceeds(
            inputBytes: [146, 1, 9, 10, 1, 97, 24, 3, 18, 2, 8, 7],
            recodedBytes: [146, 1, 7, 10, 1, 97, 18, 2, 8, 7]
        ) {
            var m1 = SwiftProtoTesting_ForeignMessage()
            m1.c = 7
            return $0.mapStringForeignMessage == ["a": m1]
        }
    }

    func assertMapEncode(
        _ expectedBlocks: [[UInt8]],
        file: StaticString = #file,
        line: UInt = #line,
        configure: (inout MessageTestType) -> Void
    ) {
        let empty = MessageTestType()
        var configured = empty
        configure(&configured)
        XCTAssert(configured != empty, "Object should not be equal to empty object", file: file, line: line)
        do {
            let encoded: [UInt8] = try configured.serializedBytes()
            // Reorder the provided blocks to match what we were given
            var t = encoded[0..<encoded.count]
            var availableBlocks = expectedBlocks
            var matched = true  // Last check found a match
            while matched && !availableBlocks.isEmpty {
                matched = false
                for n in 0..<availableBlocks.count {
                    let e = availableBlocks[n]
                    if e.count == t.count && t == e[0..<e.count] {
                        t = []
                        availableBlocks.remove(at: n)
                        matched = true
                        break
                    } else if e.count < t.count && t[0..<e.count] == e[0..<e.count] {
                        t = t[e.count..<t.count]
                        availableBlocks.remove(at: n)
                        matched = true
                        break
                    }
                }
            }
            XCTAssert(
                availableBlocks.isEmpty && t.isEmpty,
                "Did not encode correctly: got \(encoded)",
                file: file,
                line: line
            )
            do {
                let decoded = try MessageTestType(serializedBytes: encoded)
                XCTAssert(
                    decoded == configured,
                    "Encode/decode cycle should generate equal object",
                    file: file,
                    line: line
                )
            } catch let e {
                XCTFail("Encode/decode cycle should not fail: \(e)", file: file, line: line)
            }
        } catch let e {
            XCTFail("Serialization failed: \(e)", file: file, line: line)
        }
    }

    func assertDecodeSucceeds(
        _ bytes: [UInt8],
        file: StaticString = #file,
        line: UInt = #line,
        check: (MessageTestType) -> Bool
    ) {
        do {
            let decoded = try MessageTestType(serializedBytes: bytes)
            XCTAssert(check(decoded), "Condition failed for decode", file: file, line: line)

            do {
                let encoded: [UInt8] = try decoded.serializedBytes()
                do {
                    let redecoded = try MessageTestType(serializedBytes: encoded)
                    XCTAssert(check(redecoded), "Condition failed for redecoded", file: file, line: line)
                    XCTAssertEqual(decoded, redecoded, file: file, line: line)
                } catch let e {
                    XCTFail("Failed to redecode: \(e)", file: file, line: line)
                }
            } catch let e {
                XCTFail("Failed to encode: \(e)", file: file, line: line)
            }
        } catch let e {
            XCTFail("Failed to decode: \(e)", file: file, line: line)
        }

        do {
            // Make sure unknown fields are preserved by empty message decode/encode
            let empty = try SwiftProtoTesting_TestEmptyMessage(serializedBytes: bytes)
            do {
                let newBytes: [UInt8] = try empty.serializedBytes()
                XCTAssertEqual(
                    bytes,
                    newBytes,
                    "Empty decode/recode did not match; \(bytes) != \(newBytes)",
                    file: file,
                    line: line
                )
            } catch let e {
                XCTFail("Reserializing empty threw an error: \(e)", file: file, line: line)
            }
        } catch {
            XCTFail("Empty decoding threw an error: \(error)", file: file, line: line)
        }
    }

    func assertDecodeSucceeds(
        inputBytes bytes: [UInt8],
        recodedBytes: [UInt8],
        file: StaticString = #file,
        line: UInt = #line,
        check: (MessageTestType) -> Bool
    ) {
        do {
            let decoded = try MessageTestType(serializedBytes: bytes)
            XCTAssert(check(decoded), "Condition failed for \(decoded)", file: file, line: line)

            do {
                let encoded: [UInt8] = try decoded.serializedBytes()
                XCTAssertEqual(
                    recodedBytes,
                    encoded,
                    "Didn't recode as expected: \(encoded) expected: \(recodedBytes)",
                    file: file,
                    line: line
                )
                do {
                    let redecoded = try MessageTestType(serializedBytes: encoded)
                    XCTAssert(check(redecoded), "Condition failed for redecoded", file: file, line: line)
                    XCTAssertEqual(decoded, redecoded, file: file, line: line)
                } catch let e {
                    XCTFail("Failed to redecode: \(e)", file: file, line: line)
                }
            } catch let e {
                XCTFail("Failed to encode: \(e)", file: file, line: line)
            }
        } catch let e {
            XCTFail("Failed to decode: \(e)", file: file, line: line)
        }
    }
}
