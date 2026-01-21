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
        // Verify that we clear the shared storage between map entries.
        assertDecodeSucceeds(
            inputBytes: [10, 4, 8, 1, 16, 2, 10, 0],
            recodedBytes: [10, 4, 8, 0, 16, 0, 10, 4, 8, 1, 16, 2]
        ) {
            $0.mapInt32Int32 == [0: 0, 1: 2]
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
        // Verify that we clear the shared storage between map entries.
        assertDecodeSucceeds(
            inputBytes: [18, 4, 8, 1, 16, 2, 18, 0],
            recodedBytes: [18, 4, 8, 0, 16, 0, 18, 4, 8, 1, 16, 2]
        ) {
            $0.mapInt64Int64 == [0: 0, 1: 2]
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
        // Verify that we clear the shared storage between map entries.
        assertDecodeSucceeds(
            inputBytes: [26, 4, 8, 1, 16, 2, 26, 0],
            recodedBytes: [26, 4, 8, 0, 16, 0, 26, 4, 8, 1, 16, 2]
        ) {
            $0.mapUint32Uint32 == [0: 0, 1: 2]
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
        // Verify that we clear the shared storage between map entries.
        assertDecodeSucceeds(
            inputBytes: [106, 4, 8, 1, 16, 1, 106, 0],
            recodedBytes: [106, 4, 8, 0, 16, 0, 106, 4, 8, 1, 16, 1]
        ) {
            $0.mapBoolBool == [false: false, true: true]
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
        // Verify that we clear the shared storage between map entries.
        assertDecodeSucceeds(
            inputBytes: [114, 8, 10, 2, 65, 66, 18, 2, 97, 98, 114, 0],
            recodedBytes: [114, 4, 10, 0, 18, 0, 114, 8, 10, 2, 65, 66, 18, 2, 97, 98]
        ) {
            $0.mapStringString == ["": "", "AB": "ab"]
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
        // Verify that we clear the shared storage between map entries.
        assertDecodeSucceeds(
            inputBytes: [122, 7, 8, 9, 18, 3, 1, 2, 3, 122, 0],
            recodedBytes: [122, 4, 8, 0, 18, 0, 122, 7, 8, 9, 18, 3, 1, 2, 3]
        ) {
            $0.mapInt32Bytes == [0: Data(), 9: Data([1, 2, 3])]
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
        // Verify that we clear the shared storage between map entries.
        assertDecodeSucceeds(
            inputBytes: [130, 1, 4, 8, 1, 16, 2, 130, 1, 0],
            recodedBytes: [130, 1, 4, 8, 0, 16, 0, 130, 1, 4, 8, 1, 16, 2]
        ) {
            $0.mapInt32Enum == [0: SwiftProtoTesting_MapEnum.foo, 1: SwiftProtoTesting_MapEnum.baz]
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
        // Verify that we clear the shared storage between map entries.
        assertDecodeSucceeds(
            inputBytes: [138, 1, 6, 8, 1, 18, 2, 8, 7, 138, 1, 0],
            recodedBytes: [138, 1, 4, 8, 0, 18, 0, 138, 1, 6, 8, 1, 18, 2, 8, 7]
        ) {
            var m1 = SwiftProtoTesting_ForeignMessage()
            m1.c = 7
            return $0.mapInt32ForeignMessage == [0: SwiftProtoTesting_ForeignMessage(), 1: m1]
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
        // Verify that we clear the shared storage between map entries.
        assertDecodeSucceeds(
            inputBytes: [146, 1, 7, 10, 1, 97, 18, 2, 8, 7, 146, 1, 0],
            recodedBytes: [146, 1, 4, 10, 0, 18, 0, 146, 1, 7, 10, 1, 97, 18, 2, 8, 7]
        ) {
            var m1 = SwiftProtoTesting_ForeignMessage()
            m1.c = 7
            return $0.mapStringForeignMessage == ["": SwiftProtoTesting_ForeignMessage(), "a": m1]
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

    func test_textFormat_Int32Int32() {
        assertTextFormatEncode("map_int32_int32 {\n  key: 1\n  value: 2\n}\n") { (o: inout MessageTestType) in
            o.mapInt32Int32 = [1: 2]
        }
        assertTextFormatDecodeSucceeds("map_int32_int32 {key: 1, value: 2}") { (o: MessageTestType) in
            o.mapInt32Int32 == [1: 2]
        }
        assertTextFormatDecodeSucceeds("map_int32_int32 {key: 1; value: 2}") { (o: MessageTestType) in
            o.mapInt32Int32 == [1: 2]
        }
        assertTextFormatDecodeSucceeds("map_int32_int32 {key:1 value:2}") { (o: MessageTestType) in
            o.mapInt32Int32 == [1: 2]
        }
        assertTextFormatDecodeSucceeds("map_int32_int32 {key:1 value:2}\nmap_int32_int32 {key:3 value:4}") {
            (o: MessageTestType) in
            o.mapInt32Int32 == [1: 2, 3: 4]
        }
        assertTextFormatDecodeSucceeds("map_int32_int32 [{key:1 value:2}, {key:3 value:4}]") { (o: MessageTestType) in
            o.mapInt32Int32 == [1: 2, 3: 4]
        }
        assertTextFormatDecodeSucceeds("map_int32_int32 [{key:1 value:2}];map_int32_int32 {key:3 value:4}") {
            (o: MessageTestType) in
            o.mapInt32Int32 == [1: 2, 3: 4]
        }
        assertTextFormatDecodeFails("map_int32_int32 [{key:1 value:2},]")
        assertTextFormatDecodeFails("map_int32_int32 [{key:1 value:2}")
        assertTextFormatDecodeFails("map_int32_int32 [{key:1 value:2 nonsense:3}")
        assertTextFormatDecodeFails("map_int32_int32 {key:1}")

        assertTextFormatDecodeFails("map_int32_int32<")
        assertTextFormatDecodeFails("map_int32_int32{")
        assertTextFormatDecodeFails("1<")
        assertTextFormatDecodeFails("1{")
        assertTextFormatDecodeFails("1{1:1 2:2")
        assertTextFormatDecodeFails("1{1:1 2:")
        assertTextFormatDecodeFails("1{1:1 2")
        assertTextFormatDecodeFails("1{1:1")
        assertTextFormatDecodeFails("1{1:")
        assertTextFormatDecodeFails("1{1")
    }

    func test_textFormat_Int32Int32_numbers() {
        assertTextFormatDecodeSucceeds("1 {\n  key: 1\n  value: 2\n}\n") { (o: MessageTestType) in
            o.mapInt32Int32 == [1: 2]
        }
        assertTextFormatDecodeSucceeds("1 {key: 1, value: 2}") { (o: MessageTestType) in
            o.mapInt32Int32 == [1: 2]
        }
        assertTextFormatDecodeSucceeds("1 {key: 1; value: 2}") { (o: MessageTestType) in
            o.mapInt32Int32 == [1: 2]
        }
        assertTextFormatDecodeSucceeds("1 {key:1 value:2}") { (o: MessageTestType) in
            o.mapInt32Int32 == [1: 2]
        }
        assertTextFormatDecodeSucceeds("1 {key:1 value:2}\n1 {key:3 value:4}") { (o: MessageTestType) in
            o.mapInt32Int32 == [1: 2, 3: 4]
        }
        assertTextFormatDecodeSucceeds("1 [{key:1 value:2}, {key:3 value:4}]") { (o: MessageTestType) in
            o.mapInt32Int32 == [1: 2, 3: 4]
        }
        assertTextFormatDecodeSucceeds("1 [{key:1 value:2}];1 {key:3 value:4}") { (o: MessageTestType) in
            o.mapInt32Int32 == [1: 2, 3: 4]
        }
        assertTextFormatDecodeFails("1 [{key:1 value:2},]")
        assertTextFormatDecodeFails("1 [{key:1 value:2}")
        assertTextFormatDecodeFails("1 [{key:1 value:2 nonsense:3}")
        assertTextFormatDecodeFails("1 {key:1}")

        // Using numbers for "key" and "value" in the map entries.

        assertTextFormatDecodeSucceeds("1 {\n  1: 1\n  2: 2\n}\n") { (o: MessageTestType) in
            o.mapInt32Int32 == [1: 2]
        }
        assertTextFormatDecodeSucceeds("1 {1: 1, 2: 2}") { (o: MessageTestType) in
            o.mapInt32Int32 == [1: 2]
        }
        assertTextFormatDecodeSucceeds("1 {1: 1; 2: 2}") { (o: MessageTestType) in
            o.mapInt32Int32 == [1: 2]
        }
        assertTextFormatDecodeSucceeds("1 {1:1 2:2}") { (o: MessageTestType) in
            o.mapInt32Int32 == [1: 2]
        }
        assertTextFormatDecodeSucceeds("1 {1:1 2:2}\n1 {1:3 2:4}") { (o: MessageTestType) in
            o.mapInt32Int32 == [1: 2, 3: 4]
        }
        assertTextFormatDecodeSucceeds("1 [{1:1 2:2}, {1:3 2:4}]") { (o: MessageTestType) in
            o.mapInt32Int32 == [1: 2, 3: 4]
        }
        assertTextFormatDecodeSucceeds("1 [{1:1 2:2}];1 {1:3 2:4}") { (o: MessageTestType) in
            o.mapInt32Int32 == [1: 2, 3: 4]
        }
        assertTextFormatDecodeFails("1 [{1:1 2:2},]")
        assertTextFormatDecodeFails("1 [{1:1 2:2}")
        assertTextFormatDecodeFails("1 [{1:1 2:2 3:3}")
        assertTextFormatDecodeFails("1 {1:1}")
    }

    func test_textFormat_StringMessage() {
        let foo = SwiftProtoTesting_ForeignMessage.with { $0.c = 999 }

        assertTextFormatEncode("map_string_foreign_message {\n  key: \"foo\"\n  value {\n    c: 999\n  }\n}\n") {
            (o: inout MessageTestType) in
            o.mapStringForeignMessage = ["foo": foo]
        }
    }

    func test_textFormat_StringMessage_numbers() {
        let foo = SwiftProtoTesting_ForeignMessage.with { $0.c = 999 }

        assertTextFormatDecodeSucceeds("18 {\n  key: \"foo\"\n  value {\n    1: 999\n  }\n}\n") {
            (o: MessageTestType) in
            o.mapStringForeignMessage == ["foo": foo]
        }

        // Using numbers for "key" and "value" in the map entries.

        assertTextFormatDecodeSucceeds("18 {\n  1: \"foo\"\n  2 {\n    1: 999\n  }\n}\n") { (o: MessageTestType) in
            o.mapStringForeignMessage == ["foo": foo]
        }
    }

    func test_textFormat_Int32Int32_ignore_unknown_fields() {
        var options = TextFormatDecodingOptions()
        options.ignoreUnknownFields = true

        assertTextFormatDecodeSucceeds("map_int32_int32 {\n  key: 1\n  unknown: 6\n  value: 2\n}\n", options: options) {
            (o: MessageTestType) in
            o.mapInt32Int32 == [1: 2]
        }
        do {
            let _ = try MessageTestType(
                textFormatString: "map_int32_int32 {\n  key: 1\n  [ext]: 7\n  value: 2\n}\n",
                options: options
            )
            XCTFail("Should have failed")
        } catch TextFormatDecodingError.unknownField {
            // This is what should have happened.
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        options.ignoreUnknownFields = false
        options.ignoreUnknownExtensionFields = true

        assertTextFormatDecodeSucceeds("map_int32_int32 {\n  key: 1\n  [ext]: 6\n  value: 2\n}\n", options: options) {
            (o: MessageTestType) in
            o.mapInt32Int32 == [1: 2]
        }
        do {
            let _ = try MessageTestType(
                textFormatString: "map_int32_int32 {\n  key: 1\n  unknown: 7\n  value: 2\n}\n",
                options: options
            )
            XCTFail("Should have failed")
        } catch TextFormatDecodingError.unknownField {
            // This is what should have happened.
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        options.ignoreUnknownFields = true
        options.ignoreUnknownExtensionFields = true

        assertTextFormatDecodeSucceeds(
            "map_int32_int32 {\n  key: 1\n  unknown: 6\n  [ext]: 7\n  value: 2\n}\n",
            options: options
        ) { (o: MessageTestType) in
            o.mapInt32Int32 == [1: 2]
        }
        assertTextFormatDecodeSucceeds("map_int32_int32 {unknown: 6, [ext]: 7, key: 1, value: 2}", options: options) {
            (o: MessageTestType) in
            o.mapInt32Int32 == [1: 2]
        }
        assertTextFormatDecodeSucceeds("map_int32_int32 {key: 1; value: 2; unknown: 6; [ext]: 7}", options: options) {
            (o: MessageTestType) in
            o.mapInt32Int32 == [1: 2]
        }
        assertTextFormatDecodeSucceeds("map_int32_int32 {key:1 unknown: 6 [ext]: 7 value:2}", options: options) {
            (o: MessageTestType) in
            o.mapInt32Int32 == [1: 2]
        }
    }

    func test_textFormat_StringMessage_ignore_unknown_fields() {
        var options = TextFormatDecodingOptions()
        options.ignoreUnknownFields = true

        let foo = SwiftProtoTesting_ForeignMessage.with { $0.c = 999 }

        assertTextFormatDecodeSucceeds(
            "map_string_foreign_message {\n  key: \"foo\"\n    unknown: 6\n  value { c: 999 }\n}\n",
            options: options
        ) { (o: MessageTestType) in
            o.mapStringForeignMessage == ["foo": foo]
        }
        do {
            let _ = try MessageTestType(
                textFormatString: "map_string_foreign_message {\n  key: \"foo\"\n    [ext]: 7\n  value { c: 999 }\n}\n",
                options: options
            )
            XCTFail("Should have failed")
        } catch TextFormatDecodingError.unknownField {
            // This is what should have happened.
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        options.ignoreUnknownFields = false
        options.ignoreUnknownExtensionFields = true

        assertTextFormatDecodeSucceeds(
            "map_string_foreign_message {\n  key: \"foo\"\n    [ext]: 7\n  value { c: 999 }\n}\n",
            options: options
        ) { (o: MessageTestType) in
            o.mapStringForeignMessage == ["foo": foo]
        }
        do {
            let _ = try MessageTestType(
                textFormatString:
                    "map_string_foreign_message {\n  key: \"foo\"\n    unknown: 6\n  value { c: 999 }\n}\n",
                options: options
            )
            XCTFail("Should have failed")
        } catch TextFormatDecodingError.unknownField {
            // This is what should have happened.
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        options.ignoreUnknownFields = true
        options.ignoreUnknownExtensionFields = true

        assertTextFormatDecodeSucceeds(
            "map_string_foreign_message {\n  key: \"foo\"\n    unknown: 6\n  [ext]: 7\n  value { c: 999 }\n}\n",
            options: options
        ) { (o: MessageTestType) in
            o.mapStringForeignMessage == ["foo": foo]
        }
        assertTextFormatDecodeSucceeds(
            "map_string_foreign_message { unknown: 6, [ext]: 7, key: \"foo\", value { c: 999 } }",
            options: options
        ) { (o: MessageTestType) in
            o.mapStringForeignMessage == ["foo": foo]
        }
        assertTextFormatDecodeSucceeds(
            "map_string_foreign_message { key: \"foo\"; value { c: 999 }; unknown: 6; [ext]: 7 }",
            options: options
        ) { (o: MessageTestType) in
            o.mapStringForeignMessage == ["foo": foo]
        }
        assertTextFormatDecodeSucceeds(
            "map_string_foreign_message { key: \"foo\" value { c: 999 } unknown: 6 [ext]: 7 }",
            options: options
        ) { (o: MessageTestType) in
            o.mapStringForeignMessage == ["foo": foo]
        }
    }

    func test_textFormat_Int32Enum_ignore_unknown_fields() throws {
        var options = TextFormatDecodingOptions()
        options.ignoreUnknownFields = true

        assertTextFormatDecodeSucceeds(
            "map_int32_enum {\n  key: 1\n    unknown: 6\n\n  value: MAP_ENUM_BAR\n}\n",
            options: options
        ) { (o: MessageTestType) in
            o.mapInt32Enum == [1: .bar]
        }
        do {
            let _ = try MessageTestType(
                textFormatString: "map_int32_enum {\n  key: 1\n  [ext]: 7\n  value: MAP_ENUM_BAR\n}\n",
                options: options
            )
            XCTFail("Should have failed")
        } catch TextFormatDecodingError.unknownField {
            // This is what should have happened.
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        options.ignoreUnknownFields = false
        options.ignoreUnknownExtensionFields = true

        assertTextFormatDecodeSucceeds(
            "map_int32_enum {\n  key: 1\n  [ext]: 7\n  value: MAP_ENUM_BAR\n}\n",
            options: options
        ) { (o: MessageTestType) in
            o.mapInt32Enum == [1: .bar]
        }
        do {
            let _ = try MessageTestType(
                textFormatString: "map_int32_enum {\n  key: 1\n    unknown: 6\n  value: MAP_ENUM_BAR\n}\n",
                options: options
            )
            XCTFail("Should have failed")
        } catch TextFormatDecodingError.unknownField {
            // This is what should have happened.
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        options.ignoreUnknownFields = true
        options.ignoreUnknownExtensionFields = true

        assertTextFormatDecodeSucceeds(
            "map_int32_enum {\n  key: 1\n    unknown: 6\n  [ext]: 7\n  value: MAP_ENUM_BAR\n}\n",
            options: options
        ) { (o: MessageTestType) in
            o.mapInt32Enum == [1: .bar]
        }
        assertTextFormatDecodeSucceeds(
            "map_int32_enum { unknown: 6, [ext]: 7, key: 1, value: MAP_ENUM_BAR }",
            options: options
        ) { (o: MessageTestType) in
            o.mapInt32Enum == [1: .bar]
        }
        assertTextFormatDecodeSucceeds(
            "map_int32_enum { key: 1; value: MAP_ENUM_BAR; unknown: 6; [ext]: 7 }",
            options: options
        ) { (o: MessageTestType) in
            o.mapInt32Enum == [1: .bar]
        }
        assertTextFormatDecodeSucceeds(
            "map_int32_enum { key: 1 value: MAP_ENUM_BAR unknown: 6 [ext]: 7 }",
            options: options
        ) { (o: MessageTestType) in
            o.mapInt32Enum == [1: .bar]
        }
    }

    func testJSON_MapInt32Int32() throws {
        assertJSONEncode("{\"mapInt32Int32\":{\"1\":2}}") { (o: inout MessageTestType) in
            o.mapInt32Int32 = [1: 2]
        }

        var o = MessageTestType()
        o.mapInt32Int32 = [1: 2, 3: 4]
        let json = try o.jsonString()
        // Must be in one of these two orders
        if json != "{\"mapInt32Int32\":{\"1\":2,\"3\":4}}"
            && json != "{\"mapInt32Int32\":{\"3\":4,\"1\":2}}"
        {
            XCTFail("Got:  \(json)")
        }

        // Decode should work same regardless of order
        assertJSONDecodeSucceeds("{\"mapInt32Int32\":{\"1\":2, \"3\":4}}") { $0.mapInt32Int32 == [1: 2, 3: 4] }
        assertJSONDecodeSucceeds("{\"mapInt32Int32\":{\"3\":4,\"1\":2}}") { $0.mapInt32Int32 == [1: 2, 3: 4] }
        // In range values succeed
        assertJSONDecodeSucceeds("{\"mapInt32Int32\":{\"2147483647\":2147483647}}") {
            $0.mapInt32Int32 == [2_147_483_647: 2_147_483_647]
        }
        assertJSONDecodeSucceeds("{\"mapInt32Int32\":{\"-2147483648\":-2147483648}}") {
            $0.mapInt32Int32 == [-2_147_483_648: -2_147_483_648]
        }
        // Out of range values fail
        assertJSONDecodeFails("{\"mapInt32Int32\":{\"2147483647\":2147483648}}")
        assertJSONDecodeFails("{\"mapInt32Int32\":{\"2147483648\":2147483647}}")
        assertJSONDecodeFails("{\"mapInt32Int32\":{\"-2147483649\":2147483647}}")
        assertJSONDecodeFails("{\"mapInt32Int32\":{\"2147483647\":-2147483649}}")
        // JSON RFC does not allow trailing comma
        assertJSONDecodeFails("{\"mapInt32Int32\":{\"3\":4,\"1\":2,}}")
        // Int values should support being quoted or unquoted
        assertJSONDecodeSucceeds("{\"mapInt32Int32\":{\"1\":\"2\", \"3\":4}}") { $0.mapInt32Int32 == [1: 2, 3: 4] }
        // Space should not affect result
        assertJSONDecodeSucceeds(" { \"mapInt32Int32\" : { \"1\" : \"2\" , \"3\" : 4 } } ") {
            $0.mapInt32Int32 == [1: 2, 3: 4]
        }
        // Keys must be quoted, else decode fails
        assertJSONDecodeFails("{\"mapInt32Int32\":{1:2, 3:4}}")
        // Fail on other syntax errors:
        assertJSONDecodeFails("{\"mapInt32Int32\":{\"1\":2,, \"3\":4}}")
        assertJSONDecodeFails("{\"mapInt32Int32\":{\"1\",\"4\"}}")
        assertJSONDecodeFails("{\"mapInt32Int32\":{\"1\":, \"3\":4}}")
        assertJSONDecodeFails("{\"mapInt32Int32\":{\"1\":2,,}}")
        assertJSONDecodeFails("{\"mapInt32Int32\":{\"1\":2}} X")
    }

    func testJSON_MapInt64Int64() throws {
        assertJSONEncode("{\"mapInt64Int64\":{\"1\":\"2\"}}") { (o: inout MessageTestType) in
            o.mapInt64Int64 = [1: 2]
        }
        assertJSONEncode("{\"mapInt64Int64\":{\"9223372036854775807\":\"-9223372036854775808\"}}") {
            (o: inout MessageTestType) in
            o.mapInt64Int64 = [9_223_372_036_854_775_807: -9_223_372_036_854_775_808]
        }
        assertJSONDecodeSucceeds("{\"mapInt64Int64\":{\"9223372036854775807\":-9223372036854775808}}") {
            $0.mapInt64Int64 == [9_223_372_036_854_775_807: -9_223_372_036_854_775_808]
        }
        assertJSONDecodeFails("{\"mapInt64Int64\":{\"9223372036854775807\":9223372036854775808}}")
    }

    func testJSON_MapUInt32UInt32() throws {
        assertJSONEncode("{\"mapUint32Uint32\":{\"1\":2}}") { (o: inout MessageTestType) in
            o.mapUint32Uint32 = [1: 2]
        }
        assertJSONDecodeFails("{\"mapUint32Uint32\":{\"1\":-2}}")
        assertJSONDecodeFails("{\"mapUint32Uint32\":{\"-1\":2}}")
        assertJSONDecodeFails("{\"mapUint32Uint32\":{1:2}}")
        assertJSONDecodeSucceeds("{\"mapUint32Uint32\":{\"1\":\"2\"}}") {
            $0.mapUint32Uint32 == [1: 2]
        }
    }

    func testJSON_MapUInt64UInt64() throws {
        assertJSONEncode("{\"mapUint64Uint64\":{\"1\":\"2\"}}") { (o: inout MessageTestType) in
            o.mapUint64Uint64 = [1: 2]
        }
        assertJSONEncode("{\"mapUint64Uint64\":{\"1\":\"18446744073709551615\"}}") { (o: inout MessageTestType) in
            o.mapUint64Uint64 = [1: 18_446_744_073_709_551_615 as UInt64]
        }
        assertJSONDecodeSucceeds("{\"mapUint64Uint64\":{\"1\":18446744073709551615}}") {
            $0.mapUint64Uint64 == [1: 18_446_744_073_709_551_615 as UInt64]
        }
        assertJSONDecodeFails("{\"mapUint64Uint64\":{\"1\":\"18446744073709551616\"}}")
        assertJSONDecodeFails("{\"mapUint64Uint64\":{1:\"18446744073709551615\"}}")
    }

    func testJSON_MapSInt32SInt32() throws {
        assertJSONEncode("{\"mapSint32Sint32\":{\"1\":2}}") { (o: inout MessageTestType) in
            o.mapSint32Sint32 = [1: 2]
        }
        assertJSONDecodeSucceeds("{\"mapSint32Sint32\":{\"1\":\"-2\"}}") {
            $0.mapSint32Sint32 == [1: -2]
        }
        assertJSONDecodeFails("{\"mapSint32Sint32\":{1:-2}}")
        // In range values succeed
        assertJSONDecodeSucceeds("{\"mapSint32Sint32\":{\"2147483647\":2147483647}}") {
            $0.mapSint32Sint32 == [2_147_483_647: 2_147_483_647]
        }
        assertJSONDecodeSucceeds("{\"mapSint32Sint32\":{\"-2147483648\":-2147483648}}") {
            $0.mapSint32Sint32 == [-2_147_483_648: -2_147_483_648]
        }
        // Out of range values fail
        assertJSONDecodeFails("{\"mapSint32Sint32\":{\"2147483647\":2147483648}}")
        assertJSONDecodeFails("{\"mapSint32Sint32\":{\"2147483648\":2147483647}}")
        assertJSONDecodeFails("{\"mapSint32Sint32\":{\"-2147483649\":2147483647}}")
        assertJSONDecodeFails("{\"mapSint32Sint32\":{\"2147483647\":-2147483649}}")
    }

    func testJSON_MapSInt64SInt64() throws {
        assertJSONEncode("{\"mapSint64Sint64\":{\"1\":\"2\"}}") { (o: inout MessageTestType) in
            o.mapSint64Sint64 = [1: 2]
        }
        assertJSONEncode("{\"mapSint64Sint64\":{\"9223372036854775807\":\"-9223372036854775808\"}}") {
            (o: inout MessageTestType) in
            o.mapSint64Sint64 = [9_223_372_036_854_775_807: -9_223_372_036_854_775_808]
        }
        assertJSONDecodeSucceeds("{\"mapSint64Sint64\":{\"9223372036854775807\":-9223372036854775808}}") {
            $0.mapSint64Sint64 == [9_223_372_036_854_775_807: -9_223_372_036_854_775_808]
        }
        assertJSONDecodeFails("{\"mapSint64Sint64\":{\"9223372036854775807\":9223372036854775808}}")
    }

    func testJSON_Fixed32Fixed32() throws {
        assertJSONEncode("{\"mapFixed32Fixed32\":{\"1\":2}}") { (o: inout MessageTestType) in
            o.mapFixed32Fixed32 = [1: 2]
        }
        assertJSONEncode("{\"mapFixed32Fixed32\":{\"0\":0}}") { (o: inout MessageTestType) in
            o.mapFixed32Fixed32 = [0: 0]
        }
        // In range values succeed
        assertJSONDecodeSucceeds("{\"mapFixed32Fixed32\":{\"4294967295\":4294967295}}") {
            $0.mapFixed32Fixed32 == [4_294_967_295: 4_294_967_295]
        }
        // Out of range values fail
        assertJSONDecodeFails("{\"mapFixed32Fixed32\":{\"4294967295\":4294967296}}")
        assertJSONDecodeFails("{\"mapFixed32Fixed32\":{\"4294967296\":4294967295}}")
        assertJSONDecodeFails("{\"mapFixed32Fixed32\":{\"-1\":4294967295}}")
        assertJSONDecodeFails("{\"mapFixed32Fixed32\":{\"4294967295\":-1}}")
    }

    func testJSON_Fixed64Fixed64() throws {
        assertJSONEncode("{\"mapFixed64Fixed64\":{\"1\":\"2\"}}") { (o: inout MessageTestType) in
            o.mapFixed64Fixed64 = [1: 2]
        }
        assertJSONEncode("{\"mapFixed64Fixed64\":{\"1\":\"18446744073709551615\"}}") { (o: inout MessageTestType) in
            o.mapFixed64Fixed64 = [1: 18_446_744_073_709_551_615 as UInt64]
        }
        assertJSONDecodeSucceeds("{\"mapFixed64Fixed64\":{\"1\":18446744073709551615}}") {
            $0.mapFixed64Fixed64 == [1: 18_446_744_073_709_551_615 as UInt64]
        }
        assertJSONDecodeFails("{\"mapFixed64Fixed64\":{\"1\":\"18446744073709551616\"}}")
        assertJSONDecodeFails("{\"mapFixed64Fixed64\":{1:\"18446744073709551615\"}}")
    }

    func testJSON_SFixed32SFixed32() throws {
        assertJSONEncode("{\"mapSfixed32Sfixed32\":{\"1\":2}}") { (o: inout MessageTestType) in
            o.mapSfixed32Sfixed32 = [1: 2]
        }
        // In range values succeed
        assertJSONDecodeSucceeds("{\"mapSfixed32Sfixed32\":{\"2147483647\":2147483647}}") {
            $0.mapSfixed32Sfixed32 == [2_147_483_647: 2_147_483_647]
        }
        assertJSONDecodeSucceeds("{\"mapSfixed32Sfixed32\":{\"-2147483648\":-2147483648}}") {
            $0.mapSfixed32Sfixed32 == [-2_147_483_648: -2_147_483_648]
        }
        // Out of range values fail
        assertJSONDecodeFails("{\"mapSfixed32Sfixed32\":{\"2147483647\":2147483648}}")
        assertJSONDecodeFails("{\"mapSfixed32Sfixed32\":{\"2147483648\":2147483647}}")
        assertJSONDecodeFails("{\"mapSfixed32Sfixed32\":{\"-2147483649\":2147483647}}")
        assertJSONDecodeFails("{\"mapSfixed32Sfixed32\":{\"2147483647\":-2147483649}}")
    }

    func testJSON_SFixed64SFixed64() throws {
        assertJSONEncode("{\"mapSfixed64Sfixed64\":{\"1\":\"2\"}}") { (o: inout MessageTestType) in
            o.mapSfixed64Sfixed64 = [1: 2]
        }
        assertJSONEncode("{\"mapSfixed64Sfixed64\":{\"9223372036854775807\":\"-9223372036854775808\"}}") {
            (o: inout MessageTestType) in
            o.mapSfixed64Sfixed64 = [9_223_372_036_854_775_807: -9_223_372_036_854_775_808]
        }
        assertJSONDecodeSucceeds("{\"mapSfixed64Sfixed64\":{\"9223372036854775807\":-9223372036854775808}}") {
            $0.mapSfixed64Sfixed64 == [9_223_372_036_854_775_807: -9_223_372_036_854_775_808]
        }
        assertJSONDecodeFails("{\"mapSfixed64Sfixed64\":{\"9223372036854775807\":9223372036854775808}}")
    }

    func testJSON_mapInt32Float() {
        assertJSONDecodeSucceeds("{\"mapInt32Float\":{\"1\":1}}") {
            $0.mapInt32Float == [1: Float(1.0)]
        }

        assertJSONEncode("{\"mapInt32Float\":{\"1\":1.0}}") {
            $0.mapInt32Float[1] = Float(1.0)
        }

        assertJSONDecodeSucceeds("{\"mapInt32Float\":{\"1\":3.141592}}") {
            $0.mapInt32Float[1] == 3.141592 as Float
        }
    }

    func testJSON_mapInt32Double() {
        assertJSONDecodeSucceeds("{\"mapInt32Double\":{\"1\":1}}") {
            $0.mapInt32Double == [1: Double(1.0)]
        }

        assertJSONEncode("{\"mapInt32Double\":{\"1\":1.0}}") {
            $0.mapInt32Double[1] = Double(1.0)
        }

        assertJSONDecodeSucceeds("{\"mapInt32Double\":{\"1\":3.141592}}") {
            $0.mapInt32Double[1] == 3.141592
        }
    }

    func testJSON_mapBoolBool() {
        assertJSONDecodeSucceeds("{\"mapBoolBool\": {\"true\": true, \"false\": false}}") {
            $0.mapBoolBool == [true: true, false: false]
        }
        assertJSONDecodeFails("{\"mapBoolBool\": {true: true}}")
        assertJSONDecodeFails("{\"mapBoolBool\": {false: false}}")
    }

    func testJSON_MapStringString() throws {
        assertJSONEncode("{\"mapStringString\":{\"3\":\"4\"}}") { (o: inout MessageTestType) in
            o.mapStringString = ["3": "4"]
        }

        var o = MessageTestType()
        o.mapStringString = ["foo": "bar", "baz": "quux"]
        let json = try o.jsonString()
        // Must be in one of these two orders
        if json != "{\"mapStringString\":{\"foo\":\"bar\",\"baz\":\"quux\"}}"
            && json != "{\"mapStringString\":{\"baz\":\"quux\",\"foo\":\"bar\"}}"
        {
            XCTFail("Got:  \(json)")
        }
    }

    func testJSON_MapInt32Bytes() {
        assertJSONEncode("{\"mapInt32Bytes\":{\"1\":\"\"}}") { (o: inout MessageTestType) in
            o.mapInt32Bytes = [1: Data()]
        }
        assertJSONDecodeSucceeds("{\"mapInt32Bytes\":{\"1\":\"\", \"2\":\"QUI=\", \"3\": \"AAA=\"}}") {
            $0.mapInt32Bytes == [1: Data(), 2: Data([65, 66]), 3: Data([0, 0])]
        }
    }

    func testJSON_MapInt32Enum() throws {
        assertJSONEncode("{\"mapInt32Enum\":{\"3\":\"MAP_ENUM_FOO\"}}") { (o: inout MessageTestType) in
            o.mapInt32Enum = [3: .foo]
        }

        var o = MessageTestType()
        o.mapInt32Enum = [1: .foo, 3: .baz]
        let json = try o.jsonString()
        // Must be in one of these two orders
        if json != "{\"mapInt32Enum\":{\"1\":\"MAP_ENUM_FOO\",\"3\":\"MAP_ENUM_BAZ\"}}"
            && json != "{\"mapInt32Enum\":{\"3\":\"MAP_ENUM_BAZ\",\"1\":\"MAP_ENUM_FOO\"}}"
        {
            XCTFail("Got:  \(json)")
        }

        let decoded = try MessageTestType(jsonString: json)
        XCTAssertEqual(decoded.mapInt32Enum, [1: .foo, 3: .baz])
    }

    func testJSON_MapInt32Enum_JSONdecodingOptions() {
        var options = JSONDecodingOptions()

        // Test_Enum covers the single and repeated field cases.

        let json_with_unknown_enum =
            "{\"mapInt32Enum\": {\"1\": \"MAP_ENUM_FOO\", \"2\": \"NEW_VALUE\", \"3\":\"MAP_ENUM_BAZ\"}}"

        options.ignoreUnknownFields = false
        assertJSONDecodeFails(json_with_unknown_enum)

        options.ignoreUnknownFields = true
        assertJSONDecodeSucceeds(json_with_unknown_enum, options: options) { (m: MessageTestType) -> Bool in
            m.mapInt32Enum == [1: .foo, 3: .baz]
        }
    }

    func testJSON_MapInt32Message() {
        assertJSONEncode("{\"mapInt32ForeignMessage\":{\"7\":{\"c\":999}}}") { (o: inout MessageTestType) in
            var m = SwiftProtoTesting_ForeignMessage()
            m.c = 999
            o.mapInt32ForeignMessage[7] = m
        }
        assertJSONDecodeSucceeds("{\"mapInt32ForeignMessage\":{\"7\":{\"c\":7},\"8\":{\"c\":8}}}") {
            var sub7 = SwiftProtoTesting_ForeignMessage()
            sub7.c = 7
            var sub8 = SwiftProtoTesting_ForeignMessage()
            sub8.c = 8
            return $0.mapInt32ForeignMessage == [7: sub7, 8: sub8]
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
                var options = BinaryEncodingOptions()
                options.useDeterministicOrdering = true
                let encoded: [UInt8] = try decoded.serializedBytes(options: options)
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

    /// Verify the preferred encoding/decoding of a particular object.
    /// This uses the provided block to initialize the object, then:
    /// * Encodes the object and checks that the result is the expected result
    /// * Decodes it again and verifies that the round-trip gives an equal object
    func assertTextFormatEncode(
        _ expected: String,
        extensions: (any ExtensionMap)? = nil,
        file: StaticString = #file,
        line: UInt = #line,
        configure: (inout MessageTestType) -> Void
    ) {
        let empty = MessageTestType()
        var configured = empty
        configure(&configured)
        XCTAssert(configured != empty, "Object should not be equal to empty object", file: file, line: line)
        let encoded = configured.textFormatString()

        XCTAssertEqual(expected, encoded, "Did not encode correctly", file: file, line: line)
        do {
            let decoded = try MessageTestType(textFormatString: encoded, extensions: extensions)
            XCTAssert(
                decoded == configured,
                "Encode/decode cycle should generate equal object: \(decoded) != \(configured)",
                file: file,
                line: line
            )
        } catch {
            XCTFail(
                "Encode/decode cycle should not throw error but got \(error) while decoding \(encoded)",
                file: file,
                line: line
            )
        }
    }

    func assertTextFormatDecodeSucceeds(
        _ text: String,
        options: TextFormatDecodingOptions = TextFormatDecodingOptions(),
        file: StaticString = #file,
        line: UInt = #line,
        check: (MessageTestType) throws -> Bool
    ) {
        do {
            let decoded: MessageTestType = try MessageTestType(textFormatString: text, options: options)
            do {
                let r = try check(decoded)
                XCTAssert(r, "Condition failed for \(decoded)", file: file, line: line)
            } catch let e {
                XCTFail("Object check failed: \(e)")
            }
            let encoded = decoded.textFormatString()
            do {
                let redecoded = try MessageTestType(textFormatString: encoded)
                do {
                    let r = try check(redecoded)
                    XCTAssert(r, "Condition failed for redecoded \(redecoded)", file: file, line: line)
                } catch let e {
                    XCTFail("Object check failed for redecoded: \(e)\n   \(redecoded)")
                }
                XCTAssertEqual(decoded, redecoded, file: file, line: line)
            } catch {
                XCTFail("Swift should have recoded/redecoded without error: \(encoded)", file: file, line: line)
            }
        } catch let e {
            XCTFail("Swift should have decoded without error but got \(e) decoding: \(text)", file: file, line: line)
            return
        }
    }

    func assertTextFormatDecodeFails(_ text: String, file: StaticString = #file, line: UInt = #line) {
        do {
            let _ = try MessageTestType(textFormatString: text)
            XCTFail("Swift decode should have failed: \(text)", file: file, line: line)
        } catch {
            // Yay! It failed!
        }
    }

    func assertJSONEncode(
        _ expected: String,
        extensions: any ExtensionMap = SimpleExtensionMap(),
        encodingOptions: JSONEncodingOptions = .init(),
        file: StaticString = #file,
        line: UInt = #line,
        configure: (inout MessageTestType) -> Void
    ) {
        let empty = MessageTestType()
        var configured = empty
        configure(&configured)
        XCTAssert(configured != empty, "Object should not be equal to empty object", file: file, line: line)
        do {
            let encoded = try configured.jsonString(options: encodingOptions)
            XCTAssert(
                expected == encoded,
                "Did not encode correctly: got \(encoded) but expected \(expected)",
                file: file,
                line: line
            )
            do {
                let decoded = try MessageTestType(jsonString: encoded, extensions: extensions)
                XCTAssert(
                    decoded == configured,
                    "Encode/decode cycle should generate equal object: \(decoded) != \(configured)",
                    file: file,
                    line: line
                )
            } catch {
                XCTFail(
                    "Encode/decode cycle should not throw error decoding: \(encoded), but it threw \(error)",
                    file: file,
                    line: line
                )
            }
        } catch let e {
            XCTFail("Failed to serialize JSON: \(e)\n    \(configured)", file: file, line: line)
        }

        do {
            let encodedData: [UInt8] = try configured.jsonUTF8Bytes(options: encodingOptions)
            let encodedOptString = String(bytes: encodedData, encoding: String.Encoding.utf8)
            XCTAssertNotNil(encodedOptString)
            let encodedString = encodedOptString!
            XCTAssert(
                expected == encodedString,
                "Did not encode correctly: got \(encodedString)",
                file: file,
                line: line
            )
            do {
                let decoded = try MessageTestType(jsonUTF8Bytes: encodedData, extensions: extensions)
                XCTAssert(
                    decoded == configured,
                    "Encode/decode cycle should generate equal object: \(decoded) != \(configured)",
                    file: file,
                    line: line
                )
            } catch {
                XCTFail(
                    "Encode/decode cycle should not throw error decoding: \(encodedString), but it threw \(error)",
                    file: file,
                    line: line
                )
            }
        } catch let e {
            XCTFail("Failed to serialize JSON: \(e)\n    \(configured)", file: file, line: line)
        }
    }

    func assertJSONDecodeSucceeds(
        _ json: String,
        options: JSONDecodingOptions = JSONDecodingOptions(),
        extensions: any ExtensionMap = SimpleExtensionMap(),
        file: StaticString = #file,
        line: UInt = #line,
        check: (MessageTestType) -> Bool
    ) {
        do {
            let decoded: MessageTestType = try MessageTestType(
                jsonString: json,
                extensions: extensions,
                options: options
            )
            XCTAssert(check(decoded), "Condition failed for \(decoded)", file: file, line: line)

            do {
                let encoded = try decoded.jsonString()
                do {
                    let redecoded = try MessageTestType(jsonString: encoded, extensions: extensions, options: options)
                    XCTAssert(
                        check(redecoded),
                        "Condition failed for redecoded \(redecoded) from \(encoded)",
                        file: file,
                        line: line
                    )
                    XCTAssertEqual(decoded, redecoded, file: file, line: line)
                } catch {
                    XCTFail("Swift should have recoded/redecoded without error: \(encoded)", file: file, line: line)
                }
            } catch let e {
                XCTFail("Swift should have recoded without error but got \(e)\n    \(decoded)", file: file, line: line)
            }
        } catch let e {
            XCTFail("Swift should have decoded without error but got \(e): \(json)", file: file, line: line)
            return
        }

        do {
            let jsonData = json.data(using: String.Encoding.utf8)!
            let decoded: MessageTestType = try MessageTestType(
                jsonUTF8Bytes: jsonData,
                extensions: extensions,
                options: options
            )
            XCTAssert(check(decoded), "Condition failed for \(decoded) from binary \(json)", file: file, line: line)

            do {
                let encoded: [UInt8] = try decoded.jsonUTF8Bytes()
                let encodedString = String(decoding: encoded, as: UTF8.self)
                do {
                    let redecoded = try MessageTestType(
                        jsonUTF8Bytes: encoded,
                        extensions: extensions,
                        options: options
                    )
                    XCTAssert(
                        check(redecoded),
                        "Condition failed for redecoded \(redecoded) from binary \(encodedString)",
                        file: file,
                        line: line
                    )
                    XCTAssertEqual(decoded, redecoded, file: file, line: line)
                } catch {
                    XCTFail(
                        "Swift should have recoded/redecoded without error: \(encodedString)",
                        file: file,
                        line: line
                    )
                }
            } catch let e {
                XCTFail("Swift should have recoded without error but got \(e)\n    \(decoded)", file: file, line: line)
            }
        } catch let e {
            XCTFail("Swift should have decoded without error but got \(e): \(json)", file: file, line: line)
            return
        }
    }

    func assertJSONDecodeFails(
        _ json: String,
        extensions: any ExtensionMap = SimpleExtensionMap(),
        options: JSONDecodingOptions = JSONDecodingOptions(),
        file: StaticString = #file,
        line: UInt = #line
    ) {
        //        do {
        //            let _ = try MessageTestType(jsonString: json, extensions: extensions, options: options)
        //            XCTFail("Swift decode should have failed: \(json)", file: file, line: line)
        //        } catch {
        //            // Yay! It failed!
        //        }
        //
        //        let jsonData = json.data(using: String.Encoding.utf8)!
        //        do {
        //            let _ = try MessageTestType(jsonUTF8Bytes: jsonData, extensions: extensions, options: options)
        //            XCTFail("Swift decode should have failed for binary: \(json)", file: file, line: line)
        //        } catch {
        //            // Yay! It failed again!
        //        }
    }
}
