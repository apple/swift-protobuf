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
        msg.oneofField = .oneofString("oneof string")

        var msgCopy = msg
        msgCopy.optionalBool = false
        msgCopy.optionalInt32 = 100
        msgCopy.optionalString = "other string"
        msgCopy.optionalImportMessage.d = 99
        msgCopy.repeatedInt32.append(1000)
        msgCopy.repeatedString.removeLast()
        msgCopy.repeatedImportMessage.removeLast()
        msgCopy.repeatedImportMessage[0].d = 99
        msgCopy.oneofUint32 = 987

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
        XCTAssertEqual(msg.oneofField, .oneofString("oneof string"))

        XCTAssertEqual(msgCopy.optionalBool, false)
        XCTAssertEqual(msgCopy.optionalInt32, 100)
        XCTAssertEqual(msgCopy.optionalString, "other string")
        XCTAssertEqual(msgCopy.optionalImportMessage.d, 99)
        XCTAssertEqual(msgCopy.repeatedInt32, [1, 10, 100, 1000])
        XCTAssertEqual(msgCopy.repeatedString, ["a", "b"])
        XCTAssertEqual(msgCopy.repeatedImportMessage.count, 2)
        XCTAssertEqual(msgCopy.repeatedImportMessage[0].d, 99)
        XCTAssertEqual(msgCopy.repeatedImportMessage[1].d, 20)
        XCTAssertEqual(msgCopy.oneofField, .oneofUint32(987))
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
        msg.oneofField = .oneofString("oneof string")

        let msgCopy = msg
        msg.optionalBool = false
        msg.optionalInt32 = 100
        msg.optionalString = "other string"
        msg.optionalImportMessage.d = 99
        msg.repeatedInt32.append(1000)
        msg.repeatedString.removeLast()
        msg.repeatedImportMessage.removeLast()
        msg.repeatedImportMessage[0].d = 99
        msg.oneofUint32 = 987

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
        XCTAssertEqual(msgCopy.oneofField, .oneofString("oneof string"))

        XCTAssertEqual(msg.optionalBool, false)
        XCTAssertEqual(msg.optionalInt32, 100)
        XCTAssertEqual(msg.optionalString, "other string")
        XCTAssertEqual(msg.optionalImportMessage.d, 99)
        XCTAssertEqual(msg.repeatedInt32, [1, 10, 100, 1000])
        XCTAssertEqual(msg.repeatedString, ["a", "b"])
        XCTAssertEqual(msg.repeatedImportMessage.count, 2)
        XCTAssertEqual(msg.repeatedImportMessage[0].d, 99)
        XCTAssertEqual(msg.repeatedImportMessage[1].d, 20)
        XCTAssertEqual(msg.oneofField, .oneofUint32(987))
    }

    func testOneofModifyMembers() {
        var msg = MessageTestType()
        XCTAssertNil(msg.oneofField)
        XCTAssertEqual(msg.oneofString, "")
        XCTAssertEqual(msg.oneofUint32, 0)
        XCTAssertEqual(msg.oneofBytes, Data())
        XCTAssertEqual(msg.oneofNestedMessage.bb, 0)

        msg.oneofString = "some string"
        if case .oneofString(let value)? = msg.oneofField {
            XCTAssertEqual(value, "some string")
        } else {
            XCTFail("""
                oneof case was wrong; expected oneofString but got \
                \(msg.oneofField.map(String.init(describing:)) ?? "nil")
                """)
        }
        XCTAssertEqual(msg.oneofString, "some string")
        XCTAssertEqual(msg.oneofUint32, 0)
        XCTAssertEqual(msg.oneofBytes, Data())
        XCTAssertEqual(msg.oneofNestedMessage.bb, 0)

        msg.oneofBytes = Data([1, 2, 3])
        if case .oneofBytes(let value)? = msg.oneofField {
            XCTAssertEqual(value, Data([1, 2, 3]))
        } else {
            XCTFail("""
                oneof case was wrong; expected oneofBytes but got \
                \(msg.oneofField.map(String.init(describing:)) ?? "nil")
                """)
        }
        XCTAssertEqual(msg.oneofString, "")
        XCTAssertEqual(msg.oneofUint32, 0)
        XCTAssertEqual(msg.oneofBytes, Data([1, 2, 3]))
        XCTAssertEqual(msg.oneofNestedMessage.bb, 0)

        var nestedMsg = MessageTestType.NestedMessage()
        nestedMsg.bb = 100
        msg.oneofNestedMessage = nestedMsg
        if case .oneofNestedMessage(let value)? = msg.oneofField {
            XCTAssertEqual(value.bb, 100)
        } else {
            XCTFail("""
                oneof case was wrong; expected oneofNestedMessage but got \
                \(msg.oneofField.map(String.init(describing:)) ?? "nil")
                """)
        }
        XCTAssertEqual(msg.oneofString, "")
        XCTAssertEqual(msg.oneofUint32, 0)
        XCTAssertEqual(msg.oneofBytes, Data())
        XCTAssertEqual(msg.oneofNestedMessage.bb, 100)

        msg.oneofUint32 = 987
        if case .oneofUint32(let value)? = msg.oneofField {
            XCTAssertEqual(value, 987)
        } else {
            XCTFail("""
                oneof case was wrong; expected oneofUint32 but got \
                \(msg.oneofField.map(String.init(describing:)) ?? "nil")
                """)
        }
        XCTAssertEqual(msg.oneofString, "")
        XCTAssertEqual(msg.oneofUint32, 987)
        XCTAssertEqual(msg.oneofBytes, Data())
        XCTAssertEqual(msg.oneofNestedMessage.bb, 0)
    }

    func testOneofModifyCaseField() {
        var msg = MessageTestType()
        XCTAssertNil(msg.oneofField)
        XCTAssertEqual(msg.oneofString, "")
        XCTAssertEqual(msg.oneofUint32, 0)
        XCTAssertEqual(msg.oneofBytes, Data())
        XCTAssertEqual(msg.oneofNestedMessage.bb, 0)

        msg.oneofField = .oneofString("some string")
        if case .oneofString(let value)? = msg.oneofField {
            XCTAssertEqual(value, "some string")
        } else {
            XCTFail("""
                oneof case was wrong; expected oneofString but got \
                \(msg.oneofField.map(String.init(describing:)) ?? "nil")
                """)
        }
        XCTAssertEqual(msg.oneofString, "some string")
        XCTAssertEqual(msg.oneofUint32, 0)
        XCTAssertEqual(msg.oneofBytes, Data())
        XCTAssertEqual(msg.oneofNestedMessage.bb, 0)

        msg.oneofField = .oneofBytes(Data([1, 2, 3]))
        if case .oneofBytes(let value)? = msg.oneofField {
            XCTAssertEqual(value, Data([1, 2, 3]))
        } else {
            XCTFail("""
                oneof case was wrong; expected oneofBytes but got \
                \(msg.oneofField.map(String.init(describing:)) ?? "nil")
                """)
        }
        XCTAssertEqual(msg.oneofString, "")
        XCTAssertEqual(msg.oneofUint32, 0)
        XCTAssertEqual(msg.oneofBytes, Data([1, 2, 3]))
        XCTAssertEqual(msg.oneofNestedMessage.bb, 0)

        var nestedMsg = MessageTestType.NestedMessage()
        nestedMsg.bb = 100
        msg.oneofField = .oneofNestedMessage(nestedMsg)
        msg.oneofNestedMessage.bb = 100
        if case .oneofNestedMessage(let value)? = msg.oneofField {
            XCTAssertEqual(value.bb, 100)
        } else {
            XCTFail("""
                oneof case was wrong; expected oneofNestedMessage but got \
                \(msg.oneofField.map(String.init(describing:)) ?? "nil")
                """)
        }
        XCTAssertEqual(msg.oneofString, "")
        XCTAssertEqual(msg.oneofUint32, 0)
        XCTAssertEqual(msg.oneofBytes, Data())
        XCTAssertEqual(msg.oneofNestedMessage.bb, 100)

        msg.oneofField = .oneofUint32(987)
        if case .oneofUint32(let value)? = msg.oneofField {
            XCTAssertEqual(value, 987)
        } else {
            XCTFail("""
                oneof case was wrong; expected oneofUint32 but got \
                \(msg.oneofField.map(String.init(describing:)) ?? "nil")
                """)
        }
        XCTAssertEqual(msg.oneofString, "")
        XCTAssertEqual(msg.oneofUint32, 987)
        XCTAssertEqual(msg.oneofBytes, Data())
        XCTAssertEqual(msg.oneofNestedMessage.bb, 0)

        // Finally, clear it.
        msg.oneofField = nil
        if let value = msg.oneofField {
            XCTFail("oneof case was wrong; expected nil but got \(value)")
        }
        XCTAssertEqual(msg.oneofString, "")
        XCTAssertEqual(msg.oneofUint32, 0)
        XCTAssertEqual(msg.oneofBytes, Data())
        XCTAssertEqual(msg.oneofNestedMessage.bb, 0)
    }
}
