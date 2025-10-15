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
        msg.optionalImportMessage = .with { $0.d = 20 }
        msg.repeatedInt32 = [1, 10, 100]
        msg.repeatedString = ["a", "b", "c"]
        msg.repeatedImportMessage = [
            .with { $0.d = 10 },
            .with { $0.d = 20 },
            .with { $0.d = 30 },
        ]

        XCTAssertEqual(msg.optionalBool, true)
        XCTAssertEqual(msg.optionalInt32, 50)
        XCTAssertEqual(msg.optionalString, "some string")
        XCTAssertEqual(msg.optionalImportMessage.d, 20)
        XCTAssertEqual(msg.repeatedInt32, [1, 10, 100])
        XCTAssertEqual(msg.repeatedString, ["a", "b", "c"])
        XCTAssertEqual(msg.repeatedImportMessage.count, 3)
        XCTAssertEqual(msg.repeatedImportMessage[0].d, 10)
        XCTAssertEqual(msg.repeatedImportMessage[1].d, 20)
        XCTAssertEqual(msg.repeatedImportMessage[2].d, 30)
    }

    func testCopyAndModifyCopy() {
        var msg = MessageTestType()
        msg.optionalBool = true
        msg.optionalInt32 = 50
        msg.optionalString = "some string"
        msg.optionalImportMessage = .with { $0.d = 20 }
        msg.repeatedInt32 = [1, 10, 100]
        msg.repeatedString = ["a", "b", "c"]
        msg.repeatedImportMessage = [
            .with { $0.d = 10 },
            .with { $0.d = 20 },
            .with { $0.d = 30 },
        ]

        var msgCopy = msg
        msgCopy.optionalBool = false
        msgCopy.optionalInt32 = 100
        msgCopy.optionalString = "other string"
        msgCopy.optionalImportMessage.d = 99
        msgCopy.repeatedInt32.append(1000)
        msgCopy.repeatedString.removeLast()
        msgCopy.repeatedImportMessage.removeLast()
        msgCopy.repeatedImportMessage[0].d = 99

        XCTAssertEqual(msg.optionalBool, true)
        XCTAssertEqual(msg.optionalInt32, 50)
        XCTAssertEqual(msg.optionalString, "some string")
        XCTAssertEqual(msg.optionalImportMessage.d, 20)
        XCTAssertEqual(msg.repeatedInt32, [1, 10, 100])
        XCTAssertEqual(msg.repeatedString, ["a", "b", "c"])
        XCTAssertEqual(msg.repeatedImportMessage.count, 3)
        XCTAssertEqual(msg.repeatedImportMessage[0].d, 10)
        XCTAssertEqual(msg.repeatedImportMessage[1].d, 20)
        XCTAssertEqual(msg.repeatedImportMessage[2].d, 30)

        XCTAssertEqual(msgCopy.optionalBool, false)
        XCTAssertEqual(msgCopy.optionalInt32, 100)
        XCTAssertEqual(msgCopy.optionalString, "other string")
        XCTAssertEqual(msgCopy.optionalImportMessage.d, 99)
        XCTAssertEqual(msgCopy.repeatedInt32, [1, 10, 100, 1000])
        XCTAssertEqual(msgCopy.repeatedString, ["a", "b"])
        XCTAssertEqual(msgCopy.repeatedImportMessage.count, 2)
        XCTAssertEqual(msgCopy.repeatedImportMessage[0].d, 99)
        XCTAssertEqual(msgCopy.repeatedImportMessage[1].d, 20)
    }

    func testCopyAndModifyOriginal() async throws {
        var msg = MessageTestType()
        msg.optionalBool = true
        msg.optionalInt32 = 50
        msg.optionalString = "some string"
        msg.optionalImportMessage = .with { $0.d = 20 }
        msg.repeatedInt32 = [1, 10, 100]
        msg.repeatedString = ["a", "b", "c"]
        msg.repeatedImportMessage = [
            .with { $0.d = 10 },
            .with { $0.d = 20 },
            .with { $0.d = 30 },
        ]

        let msgCopy = msg
        msg.optionalBool = false
        msg.optionalInt32 = 100
        msg.optionalString = "other string"
        msg.optionalImportMessage.d = 99
        msg.repeatedInt32.append(1000)
        msg.repeatedString.removeLast()
        msg.repeatedImportMessage.removeLast()
        msg.repeatedImportMessage[0].d = 99

        XCTAssertEqual(msgCopy.optionalBool, true)
        XCTAssertEqual(msgCopy.optionalInt32, 50)
        XCTAssertEqual(msgCopy.optionalString, "some string")
        XCTAssertEqual(msgCopy.optionalImportMessage.d, 20)
        XCTAssertEqual(msgCopy.repeatedInt32, [1, 10, 100])
        XCTAssertEqual(msgCopy.repeatedString, ["a", "b", "c"])
        XCTAssertEqual(msgCopy.repeatedImportMessage.count, 3)
        XCTAssertEqual(msgCopy.repeatedImportMessage[0].d, 10)
        XCTAssertEqual(msgCopy.repeatedImportMessage[1].d, 20)
        XCTAssertEqual(msgCopy.repeatedImportMessage[2].d, 30)

        XCTAssertEqual(msg.optionalBool, false)
        XCTAssertEqual(msg.optionalInt32, 100)
        XCTAssertEqual(msg.optionalString, "other string")
        XCTAssertEqual(msg.optionalImportMessage.d, 99)
        XCTAssertEqual(msg.repeatedInt32, [1, 10, 100, 1000])
        XCTAssertEqual(msg.repeatedString, ["a", "b"])
        XCTAssertEqual(msg.repeatedImportMessage.count, 2)
        XCTAssertEqual(msg.repeatedImportMessage[0].d, 99)
        XCTAssertEqual(msg.repeatedImportMessage[1].d, 20)
    }
}
