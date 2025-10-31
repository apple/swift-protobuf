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

    func testCopyAndMergeIntoCopy() throws {
        let msg = try MessageTestType(serializedBytes: [8, 1])

        var msgCopy = msg
        try msgCopy.merge(serializedBytes: [16, 2])

        XCTAssertEqual(msg.optionalInt32, 1)
        XCTAssertEqual(msg.optionalInt64, 0)

        XCTAssertEqual(msgCopy.optionalInt32, 1)
        XCTAssertEqual(msgCopy.optionalInt64, 2)
    }

    func testCopyAndMergeIntoOriginal() throws {
        var msg = try MessageTestType(serializedBytes: [8, 1])

        let msgCopy = msg
        try msg.merge(serializedBytes: [16, 2])

        XCTAssertEqual(msg.optionalInt32, 1)
        XCTAssertEqual(msg.optionalInt64, 2)

        XCTAssertEqual(msgCopy.optionalInt32, 1)
        XCTAssertEqual(msgCopy.optionalInt64, 0)
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

    func testEquality() {
        let lhs = MessageTestType.with {
            $0.optionalInt32 = 50
            $0.repeatedInt64 = [1, 2, 3]
            $0.oneofString = "hello"
        }
        XCTAssertTrue(lhs == lhs)

        let rhs = MessageTestType.with {
            $0.optionalInt32 = 50
            $0.repeatedInt64 = [1, 2, 3]
            $0.oneofString = "hello"
        }
        XCTAssertTrue(lhs == rhs)

        let different = MessageTestType.with {
            $0.optionalInt32 = 90
            $0.repeatedInt64 = [3, 2, 1]
            $0.oneofString = "goodbye"
        }
        XCTAssertFalse(lhs == different)
    }

    //
    // Singular types
    //
    func testEncoding_optionalInt32() {
        assertEncode([8, 1]) { (o: inout MessageTestType) in o.optionalInt32 = 1 }
        assertEncode([8, 255, 255, 255, 255, 7]) { (o: inout MessageTestType) in o.optionalInt32 = Int32.max }
        assertEncode([8, 128, 128, 128, 128, 248, 255, 255, 255, 255, 1]) { (o: inout MessageTestType) in
            o.optionalInt32 = Int32.min
        }
        assertDecodeSucceeds([8, 1]) { $0.optionalInt32 == 1 }

        // Technically, this overflows Int32, but we truncate and accept it.
        assertDecodeSucceeds([8, 255, 255, 255, 255, 255, 255, 1]) {
            if $0.hasOptionalInt32 {
                return $0.optionalInt32 == -1
            } else {
                XCTFail("Nonexistent value")
                return false
            }
        }

        // We should recognize a valid field after an unknown field:
        assertDecodeSucceeds([208, 41, 0, 8, 1]) { $0.optionalInt32 == 1 }

        assertDecodeFails([8])
        assertDecodeFails([9, 57])  // Cannot use wire type 1
        assertDecodeFails([10, 58])  // Cannot use wire type 2
        assertDecodeFails([11, 59])  // Cannot use wire type 3
        assertDecodeFails([12, 60])  // Cannot use wire type 4
        assertDecodeFails([13, 61])  // Cannot use wire type 5
        assertDecodeFails([14, 62])  // Cannot use wire type 6
        assertDecodeFails([15, 63])  // Cannot use wire type 7
        assertDecodeFails([8, 188])
        assertDecodeFails([8])
    }

    func testEncoding_optionalInt64() {
        assertEncode([16, 1]) { (o: inout MessageTestType) in o.optionalInt64 = 1 }
        assertEncode([16, 255, 255, 255, 255, 255, 255, 255, 255, 127]) { (o: inout MessageTestType) in
            o.optionalInt64 = Int64.max
        }
        assertEncode([16, 128, 128, 128, 128, 128, 128, 128, 128, 128, 1]) { (o: inout MessageTestType) in
            o.optionalInt64 = Int64.min
        }

        assertDecodeSucceeds([16, 184, 156, 195, 145, 203, 1]) { $0.optionalInt64 == 54_529_150_520 }

        assertDecodeFails([16])
        assertDecodeFails([16, 184, 156, 195, 145, 203])
        assertDecodeFails([17, 81])
        assertDecodeFails([18, 82])
        assertDecodeFails([19, 83])
        assertDecodeFails([20, 84])
        assertDecodeFails([21, 85])
        assertDecodeFails([22, 86])
        assertDecodeFails([23, 87])
    }

    func testEncoding_optionalUint32() {
        assertEncode([24, 255, 255, 255, 255, 15]) { (o: inout MessageTestType) in o.optionalUint32 = UInt32.max }
        assertEncode([24, 0]) { (o: inout MessageTestType) in o.optionalUint32 = UInt32.min }

        assertDecodeSucceeds([24, 149, 88]) { $0.optionalUint32 == 11285 }

        assertDecodeFails([24])
        assertDecodeFails([24, 149])
        assertDecodeFails([25, 105])
        assertDecodeFails([26, 106])
        assertDecodeFails([27, 107])
        assertDecodeFails([28, 108])
        assertDecodeFails([29, 109])
        assertDecodeFails([30, 110])
        assertDecodeFails([31, 111])
    }

    func testEncoding_optionalUint64() {
        assertEncode([32, 255, 255, 255, 255, 255, 255, 255, 255, 255, 1]) { (o: inout MessageTestType) in
            o.optionalUint64 = UInt64.max
        }
        assertEncode([32, 0]) { (o: inout MessageTestType) in o.optionalUint64 = UInt64.min }

        assertDecodeSucceeds([32, 149, 7]) { $0.optionalUint64 == 917 }
        assertDecodeFails([32])
        assertDecodeFails([32, 149])
        assertDecodeFails([32, 149, 190, 193, 230, 186, 233, 166, 219])
        assertDecodeFails([33])
        assertDecodeFails([33, 0])
        assertDecodeFails([33, 8, 0])
        assertDecodeFails([34])
        assertDecodeFails([34, 8, 0])
        assertDecodeFails([35])
        assertDecodeFails([35, 0])
        assertDecodeFails([35, 8, 0])
        assertDecodeFails([36])
        assertDecodeFails([36, 0])
        assertDecodeFails([36, 8, 0])
        assertDecodeFails([37])
        assertDecodeFails([37, 0])
        assertDecodeFails([37, 8, 0])
        assertDecodeFails([38])
        assertDecodeFails([38, 0])
        assertDecodeFails([38, 8, 0])
        assertDecodeFails([39])
        assertDecodeFails([39, 0])
        assertDecodeFails([39, 8, 0])
    }

    func testEncoding_optionalSint32() {
        assertEncode([40, 254, 255, 255, 255, 15]) { (o: inout MessageTestType) in o.optionalSint32 = Int32.max }
        assertEncode([40, 255, 255, 255, 255, 15]) { (o: inout MessageTestType) in o.optionalSint32 = Int32.min }

        assertDecodeSucceeds([40, 0x81, 0x82, 0x80, 0x00]) { $0.optionalSint32 == -129 }
        assertDecodeSucceeds([40, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x00]) {
            $0.optionalSint32 == 0
        }

        // Truncate on overflow
        assertDecodeSucceeds([40, 0xff, 0xff, 0xff, 0xff, 0xff, 0x7f]) { $0.optionalSint32 == -2_147_483_648 }
        assertDecodeSucceeds([40, 0xfe, 0xff, 0xff, 0xff, 0xff, 0x7f]) { $0.optionalSint32 == 2_147_483_647 }

        assertDecodeFails([40])
        assertDecodeFails([
            40, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0x00,
        ])
        assertDecodeFails([41])
        assertDecodeFails([41, 0])
        assertDecodeFails([42])
        assertDecodeFails([43])
        assertDecodeFails([43, 0])
        assertDecodeFails([44])
        assertDecodeFails([44, 0])
        assertDecodeFails([45])
        assertDecodeFails([45, 0])
        assertDecodeFails([46])
        assertDecodeFails([46, 0])
        assertDecodeFails([47])
        assertDecodeFails([47, 0])
    }

    func testEncoding_optionalSint64() {
        assertEncode([48, 254, 255, 255, 255, 255, 255, 255, 255, 255, 1]) { (o: inout MessageTestType) in
            o.optionalSint64 = Int64.max
        }
        assertEncode([48, 255, 255, 255, 255, 255, 255, 255, 255, 255, 1]) { (o: inout MessageTestType) in
            o.optionalSint64 = Int64.min
        }

        assertDecodeSucceeds([48, 139, 94]) { $0.optionalSint64 == -6022 }

        assertDecodeFails([48])
        assertDecodeFails([48, 139])
        assertDecodeFails([49])
        assertDecodeFails([49, 0])
        assertDecodeFails([50])
        assertDecodeFails([51])
        assertDecodeFails([51, 0])
        assertDecodeFails([52])
        assertDecodeFails([52, 0])
        assertDecodeFails([53])
        assertDecodeFails([53, 0])
        assertDecodeFails([54])
        assertDecodeFails([54, 0])
        assertDecodeFails([55])
        assertDecodeFails([55, 0])
    }

    func testEncoding_optionalFixed32() {
        assertEncode([61, 255, 255, 255, 255]) { (o: inout MessageTestType) in o.optionalFixed32 = UInt32.max }
        assertEncode([61, 0, 0, 0, 0]) { (o: inout MessageTestType) in o.optionalFixed32 = UInt32.min }

        assertDecodeSucceeds([61, 8, 12, 108, 1]) { $0.optionalFixed32 == 23_858_184 }

        assertDecodeFails([61])
        assertDecodeFails([61, 255])
        assertDecodeFails([61, 255, 255])
        assertDecodeFails([61, 255, 255, 255])
        assertDecodeFails([56])
        assertDecodeFails([56, 0, 0, 0, 0])
        assertDecodeFails([57])
        assertDecodeFails([57, 0])
        assertDecodeFails([57, 0, 0, 0, 0])
        assertDecodeFails([58])
        assertDecodeFails([58, 0, 0, 0, 0])
        assertDecodeFails([59])
        assertDecodeFails([59, 0])
        assertDecodeFails([59, 0, 0, 0, 0])
        assertDecodeFails([60])
        assertDecodeFails([60, 0])
        assertDecodeFails([60, 0, 0, 0, 0])
        assertDecodeFails([62])
        assertDecodeFails([62, 0])
        assertDecodeFails([62, 0, 0, 0, 0])
        assertDecodeFails([63])
        assertDecodeFails([63, 0])
        assertDecodeFails([63, 0, 0, 0, 0])
    }

    func testEncoding_optionalFixed64() {
        assertEncode([65, 255, 255, 255, 255, 255, 255, 255, 255]) { (o: inout MessageTestType) in
            o.optionalFixed64 = UInt64.max
        }
        assertEncode([65, 0, 0, 0, 0, 0, 0, 0, 0]) { (o: inout MessageTestType) in o.optionalFixed64 = UInt64.min }

        assertDecodeSucceeds([65, 255, 255, 255, 255, 255, 255, 255, 255]) {
            $0.optionalFixed64 == 18_446_744_073_709_551_615
        }
        assertDecodeFails([65])
        assertDecodeFails([65, 255])
        assertDecodeFails([65, 255, 255])
        assertDecodeFails([65, 255, 255, 255])
        assertDecodeFails([65, 255, 255, 255, 255])
        assertDecodeFails([65, 255, 255, 255, 255, 255])
        assertDecodeFails([65, 255, 255, 255, 255, 255, 255])
        assertDecodeFails([65, 255, 255, 255, 255, 255, 255, 255])
        assertDecodeFails([64])
        assertDecodeFails([64, 0, 0, 0, 0, 0, 0, 0, 0])
        assertDecodeFails([66])
        assertDecodeFails([66, 0, 0, 0, 0, 0, 0, 0, 0])
        assertDecodeFails([67])
        assertDecodeFails([67, 0])
        assertDecodeFails([67, 0, 0, 0, 0, 0, 0, 0, 0])
        assertDecodeFails([68])
        assertDecodeFails([68, 0])
        assertDecodeFails([68, 0, 0, 0, 0, 0, 0, 0, 0])
        assertDecodeFails([69])
        assertDecodeFails([69, 0])
        assertDecodeFails([69, 0, 0, 0, 0, 0, 0, 0, 0])
        assertDecodeFails([69])
        assertDecodeFails([69, 0])
        assertDecodeFails([70, 0, 0, 0, 0, 0, 0, 0, 0])
        assertDecodeFails([71])
        assertDecodeFails([71, 0])
        assertDecodeFails([71, 0, 0, 0, 0, 0, 0, 0, 0])
    }

    func testEncoding_optionalSfixed32() {
        assertEncode([77, 255, 255, 255, 127]) { (o: inout MessageTestType) in o.optionalSfixed32 = Int32.max }
        assertEncode([77, 0, 0, 0, 128]) { (o: inout MessageTestType) in o.optionalSfixed32 = Int32.min }

        assertDecodeSucceeds([77, 0, 0, 0, 0]) { $0.optionalSfixed32 == 0 }
        assertDecodeSucceeds([77, 255, 255, 255, 255]) { $0.optionalSfixed32 == -1 }

        assertDecodeFails([77])
        assertDecodeFails([77])
        assertDecodeFails([77, 0])
        assertDecodeFails([77, 0, 0])
        assertDecodeFails([77, 0, 0, 0])
        assertDecodeFails([72])
        assertDecodeFails([72, 0, 0, 0, 0])
        assertDecodeFails([73])
        assertDecodeFails([73, 0])
        assertDecodeFails([73, 0, 0, 0, 0])
        assertDecodeFails([74])
        assertDecodeFails([74, 0, 0, 0, 0])
        assertDecodeFails([75])
        assertDecodeFails([75, 0])
        assertDecodeFails([75, 0, 0, 0, 0])
        assertDecodeFails([76])
        assertDecodeFails([76, 0])
        assertDecodeFails([76, 0, 0, 0, 0])
        assertDecodeFails([78])
        assertDecodeFails([78, 0])
        assertDecodeFails([78, 0, 0, 0, 0])
        assertDecodeFails([79])
        assertDecodeFails([79, 0])
        assertDecodeFails([79, 0, 0, 0, 0])
    }

    func testEncoding_optionalSfixed64() {
        assertEncode([81, 255, 255, 255, 255, 255, 255, 255, 127]) { (o: inout MessageTestType) in
            o.optionalSfixed64 = Int64.max
        }
        assertEncode([81, 0, 0, 0, 0, 0, 0, 0, 128]) { (o: inout MessageTestType) in o.optionalSfixed64 = Int64.min }

        assertDecodeSucceeds([81, 0, 0, 0, 0, 0, 0, 0, 128]) { $0.optionalSfixed64 == -9_223_372_036_854_775_808 }

        assertDecodeFails([81])
        assertDecodeFails([81, 0])
        assertDecodeFails([81, 0, 0])
        assertDecodeFails([81, 0, 0, 0])
        assertDecodeFails([81, 0, 0, 0, 0])
        assertDecodeFails([81, 0, 0, 0, 0, 0, 0, 0])
        assertDecodeFails([80])
        assertDecodeFails([80, 0, 0, 0, 0, 0, 0, 0, 0])
        assertDecodeFails([82])
        assertDecodeFails([82, 0, 0, 0, 0, 0, 0, 0, 0])
        assertDecodeFails([83])
        assertDecodeFails([83, 0])
        assertDecodeFails([83, 0, 0, 0, 0, 0, 0, 0, 0])
        assertDecodeFails([84])
        assertDecodeFails([84, 0])
        assertDecodeFails([84, 0, 0, 0, 0, 0, 0, 0, 0])
        assertDecodeFails([85])
        assertDecodeFails([85, 0])
        assertDecodeFails([85, 0, 0, 0, 0, 0, 0, 0, 0])
        assertDecodeFails([86])
        assertDecodeFails([86, 0])
        assertDecodeFails([86, 0, 0, 0, 0, 0, 0, 0, 0])
        assertDecodeFails([87])
        assertDecodeFails([87, 0])
        assertDecodeFails([87, 0, 0, 0, 0, 0, 0, 0, 0])
    }

    func testEncoding_optionalFloat() {
        assertEncode([93, 0, 0, 0, 0]) { (o: inout MessageTestType) in o.optionalFloat = 0.0 }
        assertEncode([93, 0, 0, 0, 63]) { (o: inout MessageTestType) in o.optionalFloat = 0.5 }
        assertEncode([93, 0, 0, 0, 64]) { (o: inout MessageTestType) in o.optionalFloat = 2.0 }

        assertDecodeSucceeds([93, 0, 0, 0, 0]) {
            if $0.hasOptionalFloat {
                return $0.optionalFloat == 0
            } else {
                XCTFail("Nonexistent value")
                return false
            }
        }

        assertDecodeFails([93, 0, 0, 0])
        assertDecodeFails([93, 0, 0])
        assertDecodeFails([93, 0])
        assertDecodeFails([93])
        assertDecodeFails([88])  // Float cannot use wire type 0
        assertDecodeFails([89])  // Float cannot use wire type 1
        assertDecodeFails([89, 0, 0, 0, 0])  // Float cannot use wire type 1
        assertDecodeFails([90])  // Float cannot use wire type 2
        assertDecodeFails([91])  // Float cannot use wire type 3
        assertDecodeFails([91, 0, 0, 0, 0])  // Float cannot use wire type 3
        assertDecodeFails([92])  // Float cannot use wire type 4
        assertDecodeFails([92, 0, 0, 0, 0])  // Float cannot use wire type 4
        assertDecodeFails([94])  // Float cannot use wire type 6
        assertDecodeFails([94, 0, 0, 0, 0])  // Float cannot use wire type 6
        assertDecodeFails([95])  // Float cannot use wire type 7
        assertDecodeFails([95, 0, 0, 0, 0])  // Float cannot use wire type 7
    }

    func testEncoding_optionalDouble() {
        assertEncode([97, 0, 0, 0, 0, 0, 0, 0, 0]) { (o: inout MessageTestType) in o.optionalDouble = 0.0 }
        assertEncode([97, 0, 0, 0, 0, 0, 0, 224, 63]) { (o: inout MessageTestType) in o.optionalDouble = 0.5 }
        assertEncode([97, 0, 0, 0, 0, 0, 0, 0, 64]) { (o: inout MessageTestType) in o.optionalDouble = 2.0 }

        assertDecodeSucceeds([97, 0, 0, 0, 0, 0, 0, 224, 63]) { $0.optionalDouble == 0.5 }

        assertDecodeFails([97, 0, 0, 0, 0, 0, 0, 224])
        assertDecodeFails([97])
        assertDecodeFails([96])
        assertDecodeFails([96, 10, 10, 10, 10, 10, 10, 10, 10])
        assertDecodeFails([98])
        assertDecodeFails([98, 10, 10, 10, 10, 10, 10, 10, 10])
        assertDecodeFails([99])
        assertDecodeFails([99, 0])
        assertDecodeFails([99, 10, 10, 10, 10, 10, 10, 10, 10])
        assertDecodeFails([100])
        assertDecodeFails([100, 0])
        assertDecodeFails([100, 10, 10, 10, 10, 10, 10, 10, 10])
        assertDecodeFails([101])
        assertDecodeFails([101, 0])
        assertDecodeFails([101, 10, 10, 10, 10, 10, 10, 10, 10])
        assertDecodeFails([101])
        assertDecodeFails([102, 0])
        assertDecodeFails([102, 10, 10, 10, 10, 10, 10, 10, 10])
        assertDecodeFails([103])
        assertDecodeFails([103, 0])
        assertDecodeFails([103, 10, 10, 10, 10, 10, 10, 10, 10])
    }

    func testEncoding_optionalBool() {
        assertEncode([104, 0]) { (o: inout MessageTestType) in o.optionalBool = false }
        assertEncode([104, 1]) { (o: inout MessageTestType) in o.optionalBool = true }

        assertDecodeSucceeds([104, 1]) {
            if $0.hasOptionalBool {
                return $0.optionalBool == true
            } else {
                XCTFail("Nonexistent value")
                return false
            }
        }
        assertDecodeFails([104])
        assertDecodeFails([104, 255])
        assertDecodeFails([105])
        assertDecodeFails([105, 0])
        assertDecodeFails([106])
        assertDecodeFails([107])
        assertDecodeFails([107, 0])
        assertDecodeFails([108])
        assertDecodeFails([108, 0])
        assertDecodeFails([109])
        assertDecodeFails([109, 0])
        assertDecodeFails([110])
        assertDecodeFails([110, 0])
        assertDecodeFails([111])
        assertDecodeFails([111, 0])
    }

    func testEncoding_optionalString() {
        assertEncode([114, 0]) { (o: inout MessageTestType) in o.optionalString = "" }
        assertEncode([114, 1, 65]) { (o: inout MessageTestType) in o.optionalString = "A" }
        assertEncode([114, 4, 0xf0, 0x9f, 0x98, 0x84]) { (o: inout MessageTestType) in o.optionalString = "😄" }
        assertEncode([114, 11, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]) { (o: inout MessageTestType) in
            o.optionalString = "\u{00}\u{01}\u{02}\u{03}\u{04}\u{05}\u{06}\u{07}\u{08}\u{09}\u{0a}"
        }

        assertDecodeSucceeds([114, 5, 72, 101, 108, 108, 111]) {
            if $0.hasOptionalString {
                return $0.optionalString == "Hello"
            } else {
                XCTFail("Nonexistent value")
                return false
            }
        }
        assertDecodeSucceeds([114, 4, 97, 0, 98, 99]) {
            $0.optionalString == "a\0bc"
        }
        assertDecodeSucceeds([114, 16, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]) {
            $0.optionalString
                == "\u{00}\u{01}\u{02}\u{03}\u{04}\u{05}\u{06}\u{07}\u{08}\u{09}\u{0a}\u{0b}\u{0c}\u{0d}\u{0e}\u{0f}"
        }
        assertDecodeSucceeds([114, 16, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31]) {
            $0.optionalString
                == "\u{10}\u{11}\u{12}\u{13}\u{14}\u{15}\u{16}\u{17}\u{18}\u{19}\u{1a}\u{1b}\u{1c}\u{1d}\u{1e}\u{1f}"
        }
        assertDecodeFails([114])
        assertDecodeFails([114, 1])
        assertDecodeFails([114, 2, 65])
        assertDecodeFails([114, 1, 193])  // Invalid UTF-8
        assertDecodeFails([112])
        assertDecodeFails([113])
        assertDecodeFails([113, 0])
        assertDecodeFails([115])
        assertDecodeFails([115, 0])
        assertDecodeFails([116])
        assertDecodeFails([116, 0])
        assertDecodeFails([117])
        assertDecodeFails([117, 0])
        assertDecodeFails([118])
        assertDecodeFails([118, 0])
        assertDecodeFails([119])
        assertDecodeFails([119, 0])

        // Ensure strings over 2GB fail to decode according to spec.
        XCTAssertThrowsError(
            try MessageTestType(serializedBytes: [
                114, 0xFF, 0xFF, 0xFF, 0xFF, 0x0F,
                // Don't need all the bytes, want some to let the length issue trigger.
                0x01, 0x02, 0x03,
            ])
        ) {
            XCTAssertEqual($0 as! BinaryDecodingError, .malformedProtobuf)
        }
    }

    func testEncoding_optionalGroup() {
        assertEncode([131, 1, 136, 1, 159, 141, 6, 132, 1]) { (o: inout MessageTestType) in
            var g = MessageTestType.OptionalGroup()
            g.a = 99999
            o.optionalGroup = g
        }
    }

    func testEncoding_optionalBytes() {
        assertEncode([122, 0]) { (o: inout MessageTestType) in o.optionalBytes = Data() }
        assertEncode([122, 1, 1]) { (o: inout MessageTestType) in o.optionalBytes = Data([1]) }
        assertEncode([122, 2, 1, 2]) { (o: inout MessageTestType) in o.optionalBytes = Data([1, 2]) }

        assertDecodeSucceeds([122, 4, 0, 1, 2, 255]) {
            if $0.hasOptionalBytes {
                return $0.optionalBytes == Data([0, 1, 2, 255])
            } else {
                XCTFail("Nonexistent value")
                return false
            }
        }

        assertDecodeFails([122])
        assertDecodeFails([122, 1])
        assertDecodeFails([122, 2, 0])
        assertDecodeFails([122, 3, 0, 0])
        assertDecodeFails([120])
        assertDecodeFails([121])
        assertDecodeFails([121, 0])
        assertDecodeFails([123])
        assertDecodeFails([123, 0])
        assertDecodeFails([124])
        assertDecodeFails([124, 0])
        assertDecodeFails([125])
        assertDecodeFails([125, 0])
        assertDecodeFails([126])
        assertDecodeFails([126, 0])
        assertDecodeFails([127])
        assertDecodeFails([127, 0])

        // Ensure bytes over 2GB fail to decode according to spec.
        XCTAssertThrowsError(
            try MessageTestType(serializedBytes: [
                122, 0xFF, 0xFF, 0xFF, 0xFF, 0x0F,
                // Don't need all the bytes, want some to let the length issue trigger.
                0x01, 0x02, 0x03,
            ])
        ) {
            XCTAssertEqual($0 as! BinaryDecodingError, .malformedProtobuf)
        }
    }

    func testEncoding_optionalNestedMessage() {
        assertEncode([146, 1, 2, 8, 1]) { (o: inout MessageTestType) in
            var nested = MessageTestType.NestedMessage()
            nested.bb = 1
            o.optionalNestedMessage = nested
        }
    }

    func testEncoding_optionalForeignMessage() {
        assertEncode([154, 1, 2, 8, 1]) { (o: inout MessageTestType) in
            var foreign = SwiftProtoTesting_ForeignMessage()
            foreign.c = 1
            o.optionalForeignMessage = foreign
        }
    }

    func testEncoding_optionalImportMessage() {
        assertEncode([162, 1, 2, 8, 1]) { (o: inout MessageTestType) in
            var imp = SwiftProtoTesting_Import_ImportMessage()
            imp.d = 1
            o.optionalImportMessage = imp
        }
    }

    func testEncoding_optionalPublicImportMessage() {
        assertEncode([210, 1, 2, 8, 12]) { (o: inout MessageTestType) in
            var sub = SwiftProtoTesting_Import_PublicImportMessage()
            sub.e = 12
            o.optionalPublicImportMessage = sub
        }
    }

    //
    // Repeated types
    //
    func testEncoding_repeatedInt32() {
        assertEncode([248, 1, 255, 255, 255, 255, 7, 248, 1, 128, 128, 128, 128, 248, 255, 255, 255, 255, 1]) {
            (o: inout MessageTestType) in o.repeatedInt32 = [Int32.max, Int32.min]
        }
    }

    func testEncoding_repeatedInt64() {
        assertEncode([
            128, 2, 255, 255, 255, 255, 255, 255, 255, 255, 127, 128, 2, 128, 128, 128, 128, 128, 128, 128, 128, 128, 1,
        ]) { (o: inout MessageTestType) in o.repeatedInt64 = [Int64.max, Int64.min] }
    }

    func testEncoding_repeatedUint32() {
        assertEncode([136, 2, 255, 255, 255, 255, 15, 136, 2, 0]) { (o: inout MessageTestType) in
            o.repeatedUint32 = [UInt32.max, UInt32.min]
        }
    }

    func testEncoding_repeatedUint64() {
        assertEncode([144, 2, 255, 255, 255, 255, 255, 255, 255, 255, 255, 1, 144, 2, 0]) {
            (o: inout MessageTestType) in o.repeatedUint64 = [UInt64.max, UInt64.min]
        }
    }

    func testEncoding_repeatedSint32() {
        assertEncode([152, 2, 254, 255, 255, 255, 15, 152, 2, 255, 255, 255, 255, 15]) { (o: inout MessageTestType) in
            o.repeatedSint32 = [Int32.max, Int32.min]
        }
    }

    func testEncoding_repeatedSint64() {
        assertEncode([
            160, 2, 254, 255, 255, 255, 255, 255, 255, 255, 255, 1, 160, 2, 255, 255, 255, 255, 255, 255, 255, 255, 255,
            1,
        ]) { (o: inout MessageTestType) in o.repeatedSint64 = [Int64.max, Int64.min] }
    }

    func testEncoding_repeatedFixed32() {
        assertEncode([173, 2, 255, 255, 255, 255, 173, 2, 0, 0, 0, 0]) { (o: inout MessageTestType) in
            o.repeatedFixed32 = [UInt32.max, UInt32.min]
        }
    }

    func testEncoding_repeatedFixed64() {
        assertEncode([177, 2, 255, 255, 255, 255, 255, 255, 255, 255, 177, 2, 0, 0, 0, 0, 0, 0, 0, 0]) {
            (o: inout MessageTestType) in o.repeatedFixed64 = [UInt64.max, UInt64.min]
        }
    }

    func testEncoding_repeatedSfixed32() {
        assertEncode([189, 2, 255, 255, 255, 127, 189, 2, 0, 0, 0, 128]) { (o: inout MessageTestType) in
            o.repeatedSfixed32 = [Int32.max, Int32.min]
        }
    }

    func testEncoding_repeatedSfixed64() {
        assertEncode([193, 2, 255, 255, 255, 255, 255, 255, 255, 127, 193, 2, 0, 0, 0, 0, 0, 0, 0, 128]) {
            (o: inout MessageTestType) in o.repeatedSfixed64 = [Int64.max, Int64.min]
        }
    }

    func testEncoding_repeatedFloat() {
        assertEncode([205, 2, 0, 0, 0, 63, 205, 2, 0, 0, 0, 0]) { (o: inout MessageTestType) in
            o.repeatedFloat = [0.5, 0.0]
        }
    }

    func testEncoding_repeatedDouble() {
        assertEncode([209, 2, 0, 0, 0, 0, 0, 0, 224, 63, 209, 2, 0, 0, 0, 0, 0, 0, 0, 0]) {
            (o: inout MessageTestType) in o.repeatedDouble = [0.5, 0.0]
        }
    }

    func testEncoding_repeatedBool() {
        assertEncode([216, 2, 1, 216, 2, 0, 216, 2, 1]) { (o: inout MessageTestType) in
            o.repeatedBool = [true, false, true]
        }
    }

    func testEncoding_repeatedString() {
        assertEncode([226, 2, 1, 65, 226, 2, 1, 66]) { (o: inout MessageTestType) in o.repeatedString = ["A", "B"] }
    }

    func testEncoding_repeatedBytes() {
        assertEncode([234, 2, 1, 1, 234, 2, 0, 234, 2, 1, 2]) { (o: inout MessageTestType) in
            o.repeatedBytes = [Data([1]), Data(), Data([2])]
        }
    }

    func testEncoding_repeatedGroup() {
        assertEncode([243, 2, 248, 2, 1, 244, 2, 243, 2, 244, 2]) { (o: inout MessageTestType) in
            var g1 = MessageTestType.RepeatedGroup()
            g1.a = 1
            let g2 = MessageTestType.RepeatedGroup()
            // g2 has nothing set.
            o.repeatedGroup = [g1, g2]
        }
    }

    func testEncoding_repeatedNestedMessage() {
        assertEncode([130, 3, 2, 8, 1, 130, 3, 2, 8, 2]) { (o: inout MessageTestType) in
            var m1 = MessageTestType.NestedMessage()
            m1.bb = 1
            var m2 = MessageTestType.NestedMessage()
            m2.bb = 2
            o.repeatedNestedMessage = [m1, m2]
        }
    }

    //
    // Singular with Defaults
    //
    func testEncoding_defaultInt32() throws {
        let empty = MessageTestType()
        XCTAssertEqual(empty.defaultInt32, 41)

        // Writing a value equal to the default compares as not equal to an unset field
        var a = MessageTestType()
        a.defaultInt32 = 41
        XCTAssertNotEqual(a, empty)

        XCTAssertEqual([232, 3, 41], try a.serializedBytes())

        // Calling clear* restores the default
        var t = MessageTestType()
        t.defaultInt32 = 4
        t.clearDefaultInt32()
        XCTAssertEqual(t.defaultInt32, 41)

        // The default is still not serialized
        let s: [UInt8] = try t.serializedBytes()
        XCTAssertEqual([], s)

        assertDecodeSucceeds([]) { $0.defaultInt32 == 41 }
        assertDecodeSucceeds([232, 3, 4]) { $0.defaultInt32 == 4 }
    }

    func testEncoding_defaultInt64() throws {
        let empty = MessageTestType()
        XCTAssertEqual(empty.defaultInt64, 42)
        XCTAssertEqual(try empty.serializedBytes(), [])
        var m = MessageTestType()
        m.defaultInt64 = 1
        XCTAssertEqual(m.defaultInt64, 1)
        XCTAssertEqual(try m.serializedBytes(), [240, 3, 1])

        // Writing a value equal to the default compares as not equal to an unset field
        // But it gets serialized since it was explicitly set
        var a = MessageTestType()
        a.defaultInt64 = 42
        XCTAssertNotEqual(a, empty)

        XCTAssertEqual([240, 3, 42], try a.serializedBytes())

        var b = MessageTestType()
        a.optionalInt32 = 1
        b.optionalInt32 = 1
        XCTAssertNotEqual(a, b)

        assertDecodeSucceeds([]) { $0.defaultInt64 == 42 }
        assertDecodeSucceeds([240, 3, 42]) { $0.defaultInt64 == 42 }
    }

    func testEncoding_defaultUint32() throws {
        let empty = MessageTestType()
        XCTAssertEqual(empty.defaultUint32, 43)
        XCTAssertEqual(try empty.serializedBytes(), [UInt8]())

        // Writing a value equal to the default compares as not equal to an unset field
        var a = MessageTestType()
        a.defaultUint32 = 43
        XCTAssertNotEqual(a, empty)

        XCTAssertEqual([248, 3, 43], try a.serializedBytes())

        var b = MessageTestType()
        a.optionalInt32 = 1
        b.optionalInt32 = 1
        XCTAssertNotEqual(a, b)

        assertDecodeSucceeds([]) { $0.defaultUint32 == 43 }
        assertDecodeSucceeds([248, 3, 43]) { $0.defaultUint32 == 43 }
    }

    func testEncoding_defaultUint64() throws {
        let empty = MessageTestType()
        XCTAssertEqual(empty.defaultUint64, 44)
        XCTAssertEqual(try empty.serializedBytes(), [])

        // Writing a value equal to the default compares as not equal to an unset field
        var a = MessageTestType()
        a.defaultUint64 = 44
        XCTAssertNotEqual(a, empty)

        XCTAssertEqual([128, 4, 44], try a.serializedBytes())

        var b = MessageTestType()
        a.optionalInt32 = 1
        b.optionalInt32 = 1
        XCTAssertNotEqual(a, b)

        assertDecodeSucceeds([]) { $0.defaultUint64 == 44 }
        assertDecodeSucceeds([128, 4, 44]) { $0.defaultUint64 == 44 }
    }

    func testEncoding_defaultSint32() throws {
        let empty = MessageTestType()
        XCTAssertEqual(empty.defaultSint32, -45)
        XCTAssertEqual(try empty.serializedBytes(), [])

        // Writing a value equal to the default compares as not equal to an unset field
        var a = MessageTestType()
        a.defaultSint32 = -45
        XCTAssertNotEqual(a, empty)

        XCTAssertEqual([136, 4, 89], try a.serializedBytes())

        var b = MessageTestType()
        a.optionalInt32 = 1
        b.optionalInt32 = 1
        XCTAssertNotEqual(a, b)

        assertDecodeSucceeds([]) { $0.defaultSint32 == -45 }
        assertDecodeSucceeds([136, 4, 89]) { $0.defaultSint32 == -45 }
        assertDecodeSucceeds([136, 4, 0]) { $0.defaultSint32 == 0 }
    }

    func testEncoding_defaultSint64() throws {
        let empty = MessageTestType()
        XCTAssertEqual(empty.defaultSint64, 46)
        XCTAssertEqual(try empty.serializedBytes(), [])

        // Writing a value equal to the default compares as not equal to an unset field
        var a = MessageTestType()
        a.defaultSint64 = 46
        XCTAssertNotEqual(a, empty)

        XCTAssertEqual([144, 4, 92], try a.serializedBytes())

        var b = MessageTestType()
        a.optionalInt32 = 1
        b.optionalInt32 = 1
        XCTAssertNotEqual(a, b)

        assertDecodeSucceeds([]) { $0.defaultSint64 == 46 }
        assertDecodeSucceeds([144, 4, 92]) { $0.defaultSint64 == 46 }
        assertDecodeSucceeds([144, 4, 0]) { $0.defaultSint64 == 0 }
    }

    func testEncoding_defaultFixed32() throws {
        let empty = MessageTestType()
        XCTAssertEqual(empty.defaultFixed32, 47)
        XCTAssertEqual(try empty.serializedBytes(), [])

        // Writing a value equal to the default compares as not equal to an unset field
        var a = MessageTestType()
        a.defaultFixed32 = 47
        XCTAssertNotEqual(a, empty)

        XCTAssertEqual([157, 4, 47, 0, 0, 0], try a.serializedBytes())

        var b = MessageTestType()
        a.optionalInt32 = 1
        b.optionalInt32 = 1
        XCTAssertNotEqual(a, b)

        assertDecodeSucceeds([]) { $0.defaultFixed32 == 47 }
        assertDecodeSucceeds([157, 4, 47, 0, 0, 0]) { $0.defaultFixed32 == 47 }
        assertDecodeSucceeds([157, 4, 0, 0, 0, 0]) { $0.defaultFixed32 == 0 }
    }

    func testEncoding_defaultFixed64() throws {
        let empty = MessageTestType()
        XCTAssertEqual(empty.defaultFixed64, 48)
        XCTAssertEqual(try empty.serializedBytes(), [])

        // Writing a value equal to the default compares as not equal to an unset field
        var a = MessageTestType()
        a.defaultFixed64 = 48
        XCTAssertNotEqual(a, empty)

        XCTAssertEqual([161, 4, 48, 0, 0, 0, 0, 0, 0, 0], try a.serializedBytes())

        var b = MessageTestType()
        a.optionalInt32 = 1
        b.optionalInt32 = 1
        XCTAssertNotEqual(a, b)

        assertDecodeSucceeds([]) { $0.defaultFixed64 == 48 }
        assertDecodeSucceeds([161, 4, 48, 0, 0, 0, 0, 0, 0, 0]) { $0.defaultFixed64 == 48 }
        assertDecodeSucceeds([161, 4, 0, 0, 0, 0, 0, 0, 0, 0]) { $0.defaultFixed64 == 0 }
    }

    func testEncoding_defaultSfixed32() throws {
        let empty = MessageTestType()
        XCTAssertEqual(empty.defaultSfixed32, 49)
        XCTAssertEqual(try empty.serializedBytes(), [])

        // Writing a value equal to the default compares as not equal to an unset field
        var a = MessageTestType()
        a.defaultSfixed32 = 49
        XCTAssertNotEqual(a, empty)

        XCTAssertEqual([173, 4, 49, 0, 0, 0], try a.serializedBytes())

        var b = MessageTestType()
        a.optionalInt32 = 1
        b.optionalInt32 = 1
        XCTAssertNotEqual(a, b)

        assertDecodeSucceeds([]) { $0.defaultSfixed32 == 49 }
        assertDecodeSucceeds([173, 4, 49, 0, 0, 0]) { $0.defaultSfixed32 == 49 }
        assertDecodeSucceeds([173, 4, 0, 0, 0, 0]) { $0.defaultSfixed32 == 0 }
    }

    func testEncoding_defaultSfixed64() throws {
        let empty = MessageTestType()
        XCTAssertEqual(empty.defaultSfixed64, -50)
        XCTAssertEqual(try empty.serializedBytes(), [])

        // Writing a value equal to the default compares as not equal to an unset field
        var a = MessageTestType()
        a.defaultSfixed64 = -50
        XCTAssertNotEqual(a, empty)

        XCTAssertEqual([177, 4, 206, 255, 255, 255, 255, 255, 255, 255], try a.serializedBytes())

        var b = MessageTestType()
        a.optionalInt32 = 1
        b.optionalInt32 = 1
        XCTAssertNotEqual(a, b)

        assertDecodeSucceeds([]) { $0.defaultSfixed64 == -50 }
        assertDecodeSucceeds([177, 4, 206, 255, 255, 255, 255, 255, 255, 255]) { $0.defaultSfixed64 == -50 }
        assertDecodeSucceeds([177, 4, 0, 0, 0, 0, 0, 0, 0, 0]) { $0.defaultSfixed64 == 0 }
    }

    func testEncoding_defaultFloat() throws {
        let empty = MessageTestType()
        XCTAssertEqual(empty.defaultFloat, 51.5)
        XCTAssertEqual(try empty.serializedBytes(), [])

        // Writing a value equal to the default compares as not equal to an unset field
        var a = MessageTestType()
        a.defaultFloat = 51.5
        XCTAssertNotEqual(a, empty)

        XCTAssertEqual([189, 4, 0, 0, 78, 66], try a.serializedBytes())

        var b = MessageTestType()
        a.optionalInt32 = 1
        b.optionalInt32 = 1
        XCTAssertNotEqual(a, b)

        assertDecodeSucceeds([]) { $0.defaultFloat == 51.5 }
        assertDecodeSucceeds([189, 4, 0, 0, 0, 0]) { $0.defaultFloat == 0 }
        assertDecodeSucceeds([189, 4, 0, 0, 78, 66]) { $0.defaultFloat == 51.5 }
    }

    func testEncoding_defaultDouble() throws {
        let empty = MessageTestType()
        XCTAssertEqual(empty.defaultDouble, 52e3)

        // Writing a value equal to the default compares as not equal to an unset field
        var a = MessageTestType()
        a.defaultDouble = 52e3
        XCTAssertNotEqual(a, empty)

        XCTAssertEqual([193, 4, 0, 0, 0, 0, 0, 100, 233, 64], try a.serializedBytes())

        var b = MessageTestType()
        b.optionalInt32 = 1
        a.optionalInt32 = 1
        XCTAssertNotEqual(a, b)

        assertDecodeSucceeds([]) { $0.defaultDouble == 52e3 }
        assertDecodeSucceeds([193, 4, 0, 0, 0, 0, 0, 0, 0, 0]) { $0.defaultDouble == 0 }
        assertDecodeSucceeds([193, 4, 0, 0, 0, 0, 0, 100, 233, 64]) { $0.defaultDouble == 52e3 }
    }

    func testEncoding_defaultBool() throws {
        let empty = MessageTestType()
        //XCTAssertEqual(empty.defaultBool!, true)

        // Writing a value equal to the default compares as not equal to an unset field
        var a = MessageTestType()
        a.defaultBool = true
        XCTAssertNotEqual(a, empty)

        XCTAssertEqual(try a.serializedBytes(), [200, 4, 1])

        var b = MessageTestType()
        a.optionalInt32 = 1
        b.optionalInt32 = 1
        XCTAssertNotEqual(a, b)

        assertEncode([200, 4, 0]) { (o: inout MessageTestType) in o.defaultBool = false }

        assertDecodeSucceeds([]) { $0.defaultBool == true }
        assertDecodeSucceeds([200, 4, 0]) { $0.defaultBool == false }
        assertDecodeSucceeds([200, 4, 1]) { $0.defaultBool == true }
    }

    func testEncoding_defaultString() throws {
        let empty = MessageTestType()
        XCTAssertEqual(empty.defaultString, "hello")

        // Writing a value equal to the default compares as not equal to an unset field
        var a = MessageTestType()
        a.defaultString = "hello"
        XCTAssertNotEqual(a, empty)

        XCTAssertEqual([210, 4, 5, 104, 101, 108, 108, 111], try a.serializedBytes())

        var b = MessageTestType()
        a.optionalInt32 = 1
        b.optionalInt32 = 1
        XCTAssertNotEqual(a, b)

        assertDecodeSucceeds([]) { $0.defaultString == "hello" }
        assertDecodeSucceeds([210, 4, 1, 97]) { $0.defaultString == "a" }
    }

    func testEncoding_defaultBytes() throws {
        let empty = MessageTestType()
        XCTAssertEqual(empty.defaultBytes, Data([119, 111, 114, 108, 100]))

        // Writing a value equal to the default compares as not equal to an unset field
        var a = MessageTestType()
        a.defaultBytes = Data([119, 111, 114, 108, 100])
        XCTAssertNotEqual(a, empty)

        XCTAssertEqual([218, 4, 5, 119, 111, 114, 108, 100], try a.serializedBytes())

        var b = MessageTestType()
        b.optionalInt32 = 1
        a.optionalInt32 = 1
        XCTAssertNotEqual(a, b)

        assertDecodeSucceeds([]) { $0.defaultBytes == Data([119, 111, 114, 108, 100]) }
        assertDecodeSucceeds([218, 4, 1, 1]) { $0.defaultBytes == Data([1]) }
    }

    func testEncoding_oneofUint32() throws {
        assertEncode([248, 6, 0]) { (o: inout MessageTestType) in o.oneofUint32 = 0 }

        assertDecodeSucceeds([248, 6, 255, 255, 255, 255, 15]) { $0.oneofUint32 == UInt32.max }
        assertDecodeSucceeds([138, 7, 1, 97, 248, 6, 1]) { (o: MessageTestType) in
            if case .oneofUint32? = o.oneofField, o.oneofUint32 == UInt32(1) {
                return true
            }
            return false
        }

        assertDecodeFails([248, 6, 128])  // Bad varint
        // Bad wire types:
        assertDecodeFails([249, 6])
        assertDecodeFails([249, 6, 0])
        assertDecodeFails([250, 6])
        assertDecodeFails([251, 6])
        assertDecodeFails([251, 6, 0])
        assertDecodeFails([252, 6])
        assertDecodeFails([252, 6, 0])
        assertDecodeFails([253, 6])
        assertDecodeFails([253, 6, 0])
        assertDecodeFails([254, 6])
        assertDecodeFails([254, 6, 0])
        assertDecodeFails([255, 6])
        assertDecodeFails([255, 6, 0])
    }

    func testEncoding_oneofNestedMessage() {
        assertEncode([130, 7, 2, 8, 1]) { (o: inout MessageTestType) in
            var nested = MessageTestType.NestedMessage()
            nested.bb = 1
            o.oneofNestedMessage = nested
        }
    }

    func testEncoding_oneofString() {
        assertEncode([138, 7, 1, 97]) { (o: inout MessageTestType) in o.oneofString = "a" }

        assertDecodeSucceeds([138, 7, 1, 97]) { $0.oneofString == "a" }
        assertDecodeSucceeds([138, 7, 0]) { $0.oneofString == "" }
        assertDecodeSucceeds([146, 7, 0, 138, 7, 1, 97]) { (o: MessageTestType) in
            if case .oneofString? = o.oneofField, o.oneofString == "a" {
                return true
            }
            return false
        }
        assertDecodeFails([138, 7, 1])  // Truncated body
        assertDecodeFails([138, 7, 1, 192])  // Malformed UTF-8
        // Bad wire types:
        assertDecodeFails([139, 7])  // Wire type 3
        assertDecodeFails([140, 7])  // Wire type 4
        assertDecodeFails([141, 7, 0])  // Wire type 5
        assertDecodeFails([142, 7])  // Wire type 6
        assertDecodeFails([142, 7, 0])  // Wire type 6
        assertDecodeFails([143, 7])  // Wire type 7
        assertDecodeFails([143, 7, 0])  // Wire type 7
    }

    func testEncoding_oneofBytes() {
        assertEncode([146, 7, 1, 1]) { (o: inout MessageTestType) in o.oneofBytes = Data([1]) }
    }

    func testEncoding_oneofBytes2() {
        assertDecodeSucceeds([146, 7, 1, 1]) { (o: MessageTestType) in
            let expectedB = Data([1])
            if case .oneofBytes(let b)? = o.oneofField {
                let s = o.oneofString
                return b == expectedB && s == ""
            }
            return false
        }
    }
    func testEncoding_oneofBytes3() {
        assertDecodeSucceeds([146, 7, 0]) { (o: MessageTestType) in
            let expectedB = Data()
            if case .oneofBytes(let b)? = o.oneofField {
                let s = o.oneofString
                return b == expectedB && s == ""
            }
            return false
        }
    }
    func testEncoding_oneofBytes4() {
        assertDecodeSucceeds([138, 7, 1, 97, 146, 7, 0]) { (o: MessageTestType) in
            let expectedB = Data()
            if case .oneofBytes(let b)? = o.oneofField {
                let s = o.oneofString
                return b == expectedB && s == ""
            }
            return false
        }
    }

    func testEncoding_oneofBytes5() {
        // Setting string and then bytes ends up with bytes but no string
        assertDecodeFails([146, 7])
    }

    func testEncoding_oneofBytes_failures() {
        assertDecodeFails([146, 7, 1])
        // Bad wire types:
        assertDecodeFails([144, 7])
        assertDecodeFails([145, 7])
        assertDecodeFails([145, 7, 0])
        assertDecodeFails([147, 7])
        assertDecodeFails([147, 7, 0])
        assertDecodeFails([148, 7])
        assertDecodeFails([148, 7, 0])
        assertDecodeFails([149, 7])
        assertDecodeFails([149, 7, 0])
        assertDecodeFails([150, 7])
        assertDecodeFails([150, 7, 0])
        assertDecodeFails([151, 7])
        assertDecodeFails([151, 7, 0])
    }

    func assertEncode(
        _ expected: [UInt8],
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
            XCTAssert(
                expected == encoded,
                "Did not encode correctly: got \(encoded)",
                file: file,
                line: line
            )
        } catch let e {
            XCTFail("Failed to encode: \(e)", file: file, line: line)
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
    }

    func assertDecodeFails(_ bytes: [UInt8], file: StaticString = #file, line: UInt = #line) {
        do {
            let _ = try MessageTestType(serializedBytes: bytes)
            XCTFail("Swift decode should have failed: \(bytes)", file: file, line: line)
        } catch {
            // Yay!  It failed!
        }

    }
}
