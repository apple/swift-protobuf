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
    }

    func testEncoding_optionalInt64() {
        assertEncode([16, 1]) { (o: inout MessageTestType) in o.optionalInt64 = 1 }
        assertEncode([16, 255, 255, 255, 255, 255, 255, 255, 255, 127]) { (o: inout MessageTestType) in
            o.optionalInt64 = Int64.max
        }
        assertEncode([16, 128, 128, 128, 128, 128, 128, 128, 128, 128, 1]) { (o: inout MessageTestType) in
            o.optionalInt64 = Int64.min
        }
    }

    func testEncoding_optionalUint32() {
        assertEncode([24, 255, 255, 255, 255, 15]) { (o: inout MessageTestType) in o.optionalUint32 = UInt32.max }
        assertEncode([24, 0]) { (o: inout MessageTestType) in o.optionalUint32 = UInt32.min }
    }

    func testEncoding_optionalUint64() {
        assertEncode([32, 255, 255, 255, 255, 255, 255, 255, 255, 255, 1]) { (o: inout MessageTestType) in
            o.optionalUint64 = UInt64.max
        }
        assertEncode([32, 0]) { (o: inout MessageTestType) in o.optionalUint64 = UInt64.min }
    }

    func testEncoding_optionalSint32() {
        assertEncode([40, 254, 255, 255, 255, 15]) { (o: inout MessageTestType) in o.optionalSint32 = Int32.max }
        assertEncode([40, 255, 255, 255, 255, 15]) { (o: inout MessageTestType) in o.optionalSint32 = Int32.min }
    }

    func testEncoding_optionalSint64() {
        assertEncode([48, 254, 255, 255, 255, 255, 255, 255, 255, 255, 1]) { (o: inout MessageTestType) in
            o.optionalSint64 = Int64.max
        }
        assertEncode([48, 255, 255, 255, 255, 255, 255, 255, 255, 255, 1]) { (o: inout MessageTestType) in
            o.optionalSint64 = Int64.min
        }
    }

    func testEncoding_optionalFixed32() {
        assertEncode([61, 255, 255, 255, 255]) { (o: inout MessageTestType) in o.optionalFixed32 = UInt32.max }
        assertEncode([61, 0, 0, 0, 0]) { (o: inout MessageTestType) in o.optionalFixed32 = UInt32.min }
    }

    func testEncoding_optionalFixed64() {
        assertEncode([65, 255, 255, 255, 255, 255, 255, 255, 255]) { (o: inout MessageTestType) in
            o.optionalFixed64 = UInt64.max
        }
        assertEncode([65, 0, 0, 0, 0, 0, 0, 0, 0]) { (o: inout MessageTestType) in o.optionalFixed64 = UInt64.min }
    }

    func testEncoding_optionalSfixed32() {
        assertEncode([77, 255, 255, 255, 127]) { (o: inout MessageTestType) in o.optionalSfixed32 = Int32.max }
        assertEncode([77, 0, 0, 0, 128]) { (o: inout MessageTestType) in o.optionalSfixed32 = Int32.min }
    }

    func testEncoding_optionalSfixed64() {
        assertEncode([81, 255, 255, 255, 255, 255, 255, 255, 127]) { (o: inout MessageTestType) in
            o.optionalSfixed64 = Int64.max
        }
        assertEncode([81, 0, 0, 0, 0, 0, 0, 0, 128]) { (o: inout MessageTestType) in o.optionalSfixed64 = Int64.min }
    }

    func testEncoding_optionalFloat() {
        assertEncode([93, 0, 0, 0, 0]) { (o: inout MessageTestType) in o.optionalFloat = 0.0 }
        assertEncode([93, 0, 0, 0, 63]) { (o: inout MessageTestType) in o.optionalFloat = 0.5 }
        assertEncode([93, 0, 0, 0, 64]) { (o: inout MessageTestType) in o.optionalFloat = 2.0 }
    }

    func testEncoding_optionalDouble() {
        assertEncode([97, 0, 0, 0, 0, 0, 0, 0, 0]) { (o: inout MessageTestType) in o.optionalDouble = 0.0 }
        assertEncode([97, 0, 0, 0, 0, 0, 0, 224, 63]) { (o: inout MessageTestType) in o.optionalDouble = 0.5 }
        assertEncode([97, 0, 0, 0, 0, 0, 0, 0, 64]) { (o: inout MessageTestType) in o.optionalDouble = 2.0 }
    }

    func testEncoding_optionalBool() {
        assertEncode([104, 0]) { (o: inout MessageTestType) in o.optionalBool = false }
        assertEncode([104, 1]) { (o: inout MessageTestType) in o.optionalBool = true }
    }

    func testEncoding_optionalString() {
        assertEncode([114, 0]) { (o: inout MessageTestType) in o.optionalString = "" }
        assertEncode([114, 1, 65]) { (o: inout MessageTestType) in o.optionalString = "A" }
        assertEncode([114, 4, 0xf0, 0x9f, 0x98, 0x84]) { (o: inout MessageTestType) in o.optionalString = "😄" }
        assertEncode([114, 11, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]) { (o: inout MessageTestType) in
            o.optionalString = "\u{00}\u{01}\u{02}\u{03}\u{04}\u{05}\u{06}\u{07}\u{08}\u{09}\u{0a}"
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
    }

    func testEncoding_oneofUint32() throws {
        assertEncode([248, 6, 0]) { (o: inout MessageTestType) in o.oneofUint32 = 0 }
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
    }

    func testEncoding_oneofBytes() {
        assertEncode([146, 7, 1, 1]) { (o: inout MessageTestType) in o.oneofBytes = Data([1]) }
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
}
