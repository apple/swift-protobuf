// Tests/ExperimentalTableDrivenSwiftProtobufTests/Test_TableDriven.swift - Exercise table-driven protos
//
// Copyright (c) 2014 - 2025 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Some early tests for table-driven protos that can be built separately
/// without requiring that everything be migrated all at once.
///
// -----------------------------------------------------------------------------

import Foundation
import SwiftProtobuf
import XCTest

final class Test_TableDriven: XCTestCase {
    typealias MessageTestType = SwiftProtoTesting_TestAllTypes

    func testCreation() {
        var msg = MessageTestType()
        msg.optionalBool = true
        msg.optionalInt32 = 50
        msg.optionalString = "some string"
        msg.repeatedInt32 = [1, 10, 100]
        msg.repeatedString = ["a", "b", "c"]

        XCTAssertEqual(msg.optionalBool, true)
        XCTAssertEqual(msg.optionalInt32, 50)
        XCTAssertEqual(msg.optionalString, "some string")
        XCTAssertEqual(msg.repeatedInt32, [1, 10, 100])
        XCTAssertEqual(msg.repeatedString, ["a", "b", "c"])
    }

    func testCopyAndModifyCopy() {
        var msg = MessageTestType()
        msg.optionalBool = true
        msg.optionalInt32 = 50
        msg.optionalString = "some string"
        msg.repeatedInt32 = [1, 10, 100]
        msg.repeatedString = ["a", "b", "c"]

        var msgCopy = msg
        msgCopy.optionalBool = false
        msgCopy.optionalInt32 = 100
        msgCopy.optionalString = "other string"
        msgCopy.repeatedInt32.append(1000)
        msgCopy.repeatedString.removeLast()

        XCTAssertEqual(msg.optionalBool, true)
        XCTAssertEqual(msg.optionalInt32, 50)
        XCTAssertEqual(msg.optionalString, "some string")
        XCTAssertEqual(msg.repeatedInt32, [1, 10, 100])
        XCTAssertEqual(msg.repeatedString, ["a", "b", "c"])

        XCTAssertEqual(msgCopy.optionalBool, false)
        XCTAssertEqual(msgCopy.optionalInt32, 100)
        XCTAssertEqual(msgCopy.optionalString, "other string")
        XCTAssertEqual(msgCopy.repeatedInt32, [1, 10, 100, 1000])
        XCTAssertEqual(msgCopy.repeatedString, ["a", "b"])
    }

    func testCopyAndModifyOriginal() async throws {
        var msg = MessageTestType()
        msg.optionalBool = true
        msg.optionalInt32 = 50
        msg.optionalString = "some string"
        msg.repeatedInt32 = [1, 10, 100]
        msg.repeatedString = ["a", "b", "c"]

        let msgCopy = msg
        msg.optionalBool = false
        msg.optionalInt32 = 100
        msg.optionalString = "other string"
        msg.repeatedInt32.append(1000)
        msg.repeatedString.removeLast()

        XCTAssertEqual(msgCopy.optionalBool, true)
        XCTAssertEqual(msgCopy.optionalInt32, 50)
        XCTAssertEqual(msgCopy.optionalString, "some string")
        XCTAssertEqual(msgCopy.repeatedInt32, [1, 10, 100])
        XCTAssertEqual(msgCopy.repeatedString, ["a", "b", "c"])

        XCTAssertEqual(msg.optionalBool, false)
        XCTAssertEqual(msg.optionalInt32, 100)
        XCTAssertEqual(msg.optionalString, "other string")
        XCTAssertEqual(msg.repeatedInt32, [1, 10, 100, 1000])
        XCTAssertEqual(msg.repeatedString, ["a", "b"])
    }
}
