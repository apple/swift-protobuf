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
}
