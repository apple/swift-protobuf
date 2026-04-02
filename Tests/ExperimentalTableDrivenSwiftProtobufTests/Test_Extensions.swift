// Tests/ExperimentalTableDrivenSwiftProtobufTests/Test_Extensions.swift - Exercise table-driven extensions
//
// Copyright (c) 2014 - 2026 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Some early tests for table-driven extensions that can be built separately
/// without requiring that everything be migrated all at once.
///
// -----------------------------------------------------------------------------

import Foundation
import SwiftProtobuf
import XCTest

final class Test_Extensions: XCTestCase, PBTestHelpers {
    typealias MessageTestType = SwiftProtoTesting_TestAllExtensions
    var extensions = SwiftProtobuf.NewExtensionMap()

    func assertEncode(
        _ expected: [UInt8],
        file: XCTestFileArgType = #file,
        line: UInt = #line,
        configure: (inout MessageTestType) -> Void
    ) {
        let empty = MessageTestType()
        var configured = empty
        configure(&configured)
        XCTAssert(configured != empty, "Object should not be equal to empty object", file: file, line: line)
        do {
            let encoded: [UInt8] = try configured.serializedBytes()
            XCTAssert(expected == encoded, "Did not encode correctly: got \(encoded)", file: file, line: line)
            do {
                let decoded = try MessageTestType(serializedBytes: encoded, extensions: extensions)
                XCTAssert(
                    decoded == configured,
                    "Encode/decode cycle should generate equal object: \(decoded) != \(configured)",
                    file: file,
                    line: line
                )
            } catch {
                XCTFail("Failed to decode protobuf: \(encoded)", file: file, line: line)
            }
        } catch {
            XCTFail("Failed to encode \(configured)", file: file, line: line)
        }
    }

    func assertDecodeSucceeds(
        _ bytes: [UInt8],
        file: XCTestFileArgType = #file,
        line: UInt = #line,
        check: (MessageTestType) -> Bool
    ) {
        do {
            let decoded = try MessageTestType(serializedBytes: bytes, extensions: extensions)
            XCTAssert(check(decoded), "Condition failed for \(decoded)", file: file, line: line)

            let encoded: [UInt8] = try decoded.serializedBytes()
            do {
                let redecoded = try MessageTestType(serializedBytes: encoded, extensions: extensions)
                XCTAssert(check(redecoded), "Condition failed for redecoded \(redecoded)", file: file, line: line)
                XCTAssertEqual(decoded, redecoded, file: file, line: line)
            } catch {
                XCTFail("Failed to redecode", file: file, line: line)
            }
        } catch {
            XCTFail("Failed to decode", file: file, line: line)
        }
    }

    func assertDecodeFails(_ bytes: [UInt8], file: XCTestFileArgType = #file, line: UInt = #line) {
        do {
            let _ = try MessageTestType(serializedBytes: bytes, extensions: extensions)
            XCTFail("Swift decode should have failed: \(bytes)", file: file, line: line)
        } catch {
            // Yay!  It failed!
        }

    }

    override func setUp() {
        // Start with all the extensions from the unittest.proto file:
        extensions = SwiftProtoTesting_Unittest_Extensions
        // Append another file's worth:
        //        extensions.formUnion(SwiftProtoTesting_Extend_UnittestSwiftExtension_Extensions)
        // Append an array of extensions
        //        extensions.insert(contentsOf: [
        //            SwiftProtoTesting_Extensions_RepeatedExtensionGroup,
        //            SwiftProtoTesting_Extensions_ExtensionGroup,
        //        ]
        //        )
    }

    func testCreation() {
        var msg = MessageTestType()
        msg.SwiftProtoTesting_optionalBoolExtension = true
        msg.SwiftProtoTesting_optionalInt32Extension = 50
        msg.SwiftProtoTesting_optionalStringExtension = "some string"
        msg.SwiftProtoTesting_optionalImportMessageExtension = .with { $0.d = 20 }
        msg.SwiftProtoTesting_optionalImportEnumExtension = .importBaz
        msg.SwiftProtoTesting_repeatedInt32Extension = [1, 10, 100]
        msg.SwiftProtoTesting_repeatedStringExtension = ["a", "b", "c"]
        msg.SwiftProtoTesting_repeatedImportMessageExtension = [
            .with { $0.d = 10 },
            .with { $0.d = 20 },
            .with { $0.d = 30 },
        ]
        msg.SwiftProtoTesting_repeatedImportEnumExtension = [.importBaz, .importBar]

        XCTAssertEqual(msg.SwiftProtoTesting_optionalBoolExtension, true)
        XCTAssertEqual(msg.SwiftProtoTesting_optionalInt32Extension, 50)
        XCTAssertEqual(msg.SwiftProtoTesting_optionalStringExtension, "some string")
        XCTAssertEqual(msg.SwiftProtoTesting_optionalImportMessageExtension.d, 20)
        XCTAssertEqual(msg.SwiftProtoTesting_optionalImportEnumExtension, .importBaz)
        XCTAssertEqual(msg.SwiftProtoTesting_repeatedInt32Extension, [1, 10, 100])
        XCTAssertEqual(msg.SwiftProtoTesting_repeatedStringExtension, ["a", "b", "c"])
        XCTAssertEqual(msg.SwiftProtoTesting_repeatedImportMessageExtension.count, 3)
        XCTAssertEqual(msg.SwiftProtoTesting_repeatedImportMessageExtension[0].d, 10)
        XCTAssertEqual(msg.SwiftProtoTesting_repeatedImportMessageExtension[1].d, 20)
        XCTAssertEqual(msg.SwiftProtoTesting_repeatedImportMessageExtension[2].d, 30)
        XCTAssertEqual(msg.SwiftProtoTesting_repeatedImportEnumExtension.count, 2)
        XCTAssertEqual(msg.SwiftProtoTesting_repeatedImportEnumExtension[0], .importBaz)
        XCTAssertEqual(msg.SwiftProtoTesting_repeatedImportEnumExtension[1], .importBar)
    }

    func testCopyAndModifyCopy() {
        var msg = MessageTestType()
        msg.SwiftProtoTesting_optionalBoolExtension = true
        msg.SwiftProtoTesting_optionalInt32Extension = 50
        msg.SwiftProtoTesting_optionalStringExtension = "some string"
        msg.SwiftProtoTesting_optionalImportMessageExtension = .with { $0.d = 20 }
        msg.SwiftProtoTesting_repeatedInt32Extension = [1, 10, 100]
        msg.SwiftProtoTesting_repeatedStringExtension = ["a", "b", "c"]
        msg.SwiftProtoTesting_repeatedImportMessageExtension = [
            .with { $0.d = 10 },
            .with { $0.d = 20 },
            .with { $0.d = 30 },
        ]

        var msgCopy = msg
        msgCopy.SwiftProtoTesting_optionalBoolExtension = false
        msgCopy.SwiftProtoTesting_optionalInt32Extension = 100
        msgCopy.SwiftProtoTesting_optionalStringExtension = "other string"
        msgCopy.SwiftProtoTesting_optionalImportMessageExtension.d = 99
        msgCopy.SwiftProtoTesting_repeatedInt32Extension.append(1000)
        msgCopy.SwiftProtoTesting_repeatedStringExtension.removeLast()
        msgCopy.SwiftProtoTesting_repeatedImportMessageExtension.removeLast()
        msgCopy.SwiftProtoTesting_repeatedImportMessageExtension[0].d = 99

        XCTAssertEqual(msg.SwiftProtoTesting_optionalBoolExtension, true)
        XCTAssertEqual(msg.SwiftProtoTesting_optionalInt32Extension, 50)
        XCTAssertEqual(msg.SwiftProtoTesting_optionalStringExtension, "some string")
        XCTAssertEqual(msg.SwiftProtoTesting_optionalImportMessageExtension.d, 20)
        XCTAssertEqual(msg.SwiftProtoTesting_repeatedInt32Extension, [1, 10, 100])
        XCTAssertEqual(msg.SwiftProtoTesting_repeatedStringExtension, ["a", "b", "c"])
        XCTAssertEqual(msg.SwiftProtoTesting_repeatedImportMessageExtension.count, 3)
        XCTAssertEqual(msg.SwiftProtoTesting_repeatedImportMessageExtension[0].d, 10)
        XCTAssertEqual(msg.SwiftProtoTesting_repeatedImportMessageExtension[1].d, 20)
        XCTAssertEqual(msg.SwiftProtoTesting_repeatedImportMessageExtension[2].d, 30)

        XCTAssertEqual(msgCopy.SwiftProtoTesting_optionalBoolExtension, false)
        XCTAssertEqual(msgCopy.SwiftProtoTesting_optionalInt32Extension, 100)
        XCTAssertEqual(msgCopy.SwiftProtoTesting_optionalStringExtension, "other string")
        XCTAssertEqual(msgCopy.SwiftProtoTesting_optionalImportMessageExtension.d, 99)
        XCTAssertEqual(msgCopy.SwiftProtoTesting_repeatedInt32Extension, [1, 10, 100, 1000])
        XCTAssertEqual(msgCopy.SwiftProtoTesting_repeatedStringExtension, ["a", "b"])
        XCTAssertEqual(msgCopy.SwiftProtoTesting_repeatedImportMessageExtension.count, 2)
        XCTAssertEqual(msgCopy.SwiftProtoTesting_repeatedImportMessageExtension[0].d, 99)
        XCTAssertEqual(msgCopy.SwiftProtoTesting_repeatedImportMessageExtension[1].d, 20)
    }

    func testCopyAndModifyOriginal() async throws {
        var msg = MessageTestType()
        msg.SwiftProtoTesting_optionalBoolExtension = true
        msg.SwiftProtoTesting_optionalInt32Extension = 50
        msg.SwiftProtoTesting_optionalStringExtension = "some string"
        msg.SwiftProtoTesting_optionalImportMessageExtension = .with { $0.d = 20 }
        msg.SwiftProtoTesting_repeatedInt32Extension = [1, 10, 100]
        msg.SwiftProtoTesting_repeatedStringExtension = ["a", "b", "c"]
        msg.SwiftProtoTesting_repeatedImportMessageExtension = [
            .with { $0.d = 10 },
            .with { $0.d = 20 },
            .with { $0.d = 30 },
        ]

        let msgCopy = msg
        msg.SwiftProtoTesting_optionalBoolExtension = false
        msg.SwiftProtoTesting_optionalInt32Extension = 100
        msg.SwiftProtoTesting_optionalStringExtension = "other string"
        msg.SwiftProtoTesting_optionalImportMessageExtension.d = 99
        msg.SwiftProtoTesting_repeatedInt32Extension.append(1000)
        msg.SwiftProtoTesting_repeatedStringExtension.removeLast()
        msg.SwiftProtoTesting_repeatedImportMessageExtension.removeLast()
        msg.SwiftProtoTesting_repeatedImportMessageExtension[0].d = 99

        XCTAssertEqual(msgCopy.SwiftProtoTesting_optionalBoolExtension, true)
        XCTAssertEqual(msgCopy.SwiftProtoTesting_optionalInt32Extension, 50)
        XCTAssertEqual(msgCopy.SwiftProtoTesting_optionalStringExtension, "some string")
        XCTAssertEqual(msgCopy.SwiftProtoTesting_optionalImportMessageExtension.d, 20)
        XCTAssertEqual(msgCopy.SwiftProtoTesting_repeatedInt32Extension, [1, 10, 100])
        XCTAssertEqual(msgCopy.SwiftProtoTesting_repeatedStringExtension, ["a", "b", "c"])
        XCTAssertEqual(msgCopy.SwiftProtoTesting_repeatedImportMessageExtension.count, 3)
        XCTAssertEqual(msgCopy.SwiftProtoTesting_repeatedImportMessageExtension[0].d, 10)
        XCTAssertEqual(msgCopy.SwiftProtoTesting_repeatedImportMessageExtension[1].d, 20)
        XCTAssertEqual(msgCopy.SwiftProtoTesting_repeatedImportMessageExtension[2].d, 30)

        XCTAssertEqual(msg.SwiftProtoTesting_optionalBoolExtension, false)
        XCTAssertEqual(msg.SwiftProtoTesting_optionalInt32Extension, 100)
        XCTAssertEqual(msg.SwiftProtoTesting_optionalStringExtension, "other string")
        XCTAssertEqual(msg.SwiftProtoTesting_optionalImportMessageExtension.d, 99)
        XCTAssertEqual(msg.SwiftProtoTesting_repeatedInt32Extension, [1, 10, 100, 1000])
        XCTAssertEqual(msg.SwiftProtoTesting_repeatedStringExtension, ["a", "b"])
        XCTAssertEqual(msg.SwiftProtoTesting_repeatedImportMessageExtension.count, 2)
        XCTAssertEqual(msg.SwiftProtoTesting_repeatedImportMessageExtension[0].d, 99)
        XCTAssertEqual(msg.SwiftProtoTesting_repeatedImportMessageExtension[1].d, 20)
    }

    func testCopyAndMergeIntoCopy() throws {
        let msg = try MessageTestType(serializedBytes: [8, 1, 146, 1, 2, 8, 1], extensions: extensions)

        var msgCopy = msg
        try msgCopy.merge(serializedBytes: [16, 2, 146, 1, 2, 8, 3], extensions: extensions)

        XCTAssertEqual(msg.SwiftProtoTesting_optionalInt32Extension, 1)
        XCTAssertEqual(msg.SwiftProtoTesting_optionalInt64Extension, 0)
        XCTAssertEqual(msg.SwiftProtoTesting_optionalNestedMessageExtension.bb, 1)

        XCTAssertEqual(msgCopy.SwiftProtoTesting_optionalInt32Extension, 1)
        XCTAssertEqual(msgCopy.SwiftProtoTesting_optionalInt64Extension, 2)
        XCTAssertEqual(msgCopy.SwiftProtoTesting_optionalNestedMessageExtension.bb, 3)
    }

    func testCopyAndMergeIntoOriginal() throws {
        var msg = try MessageTestType(serializedBytes: [8, 1, 146, 1, 2, 8, 1], extensions: extensions)

        let msgCopy = msg
        try msg.merge(serializedBytes: [16, 2, 146, 1, 2, 8, 3], extensions: extensions)

        XCTAssertEqual(msg.SwiftProtoTesting_optionalInt32Extension, 1)
        XCTAssertEqual(msg.SwiftProtoTesting_optionalInt64Extension, 2)
        XCTAssertEqual(msg.SwiftProtoTesting_optionalNestedMessageExtension.bb, 3)

        XCTAssertEqual(msgCopy.SwiftProtoTesting_optionalInt32Extension, 1)
        XCTAssertEqual(msgCopy.SwiftProtoTesting_optionalInt64Extension, 0)
        XCTAssertEqual(msgCopy.SwiftProtoTesting_optionalNestedMessageExtension.bb, 1)
    }

    func testEquality() {
        let lhs = MessageTestType.with {
            $0.SwiftProtoTesting_optionalInt32Extension = 50
            $0.SwiftProtoTesting_repeatedInt64Extension = [1, 2, 3]
        }
        XCTAssertTrue(lhs == lhs)

        let rhs = MessageTestType.with {
            $0.SwiftProtoTesting_optionalInt32Extension = 50
            $0.SwiftProtoTesting_repeatedInt64Extension = [1, 2, 3]
        }
        XCTAssertTrue(lhs == rhs)

        let different = MessageTestType.with {
            $0.SwiftProtoTesting_optionalInt32Extension = 90
            $0.SwiftProtoTesting_repeatedInt64Extension = [3, 2, 1]
        }
        XCTAssertFalse(lhs == different)
    }

    func test_optionalInt32Extension() throws {
        assertEncode([8, 17]) { (o: inout MessageTestType) in
            o.SwiftProtoTesting_optionalInt32Extension = 17
        }
        assertDecodeSucceeds([8, 99]) { $0.SwiftProtoTesting_optionalInt32Extension == 99 }
        assertDecodeFails([9])
        assertDecodeFails([9, 0])
        assertDecodesAsUnknownFields([
            9,  // Wrong wire type (fixed64), valid as an unknown field
            0, 0, 0, 0, 0, 0, 0, 0,
        ])
        assertDecodeFails([10])
        assertDecodesAsUnknownFields([10, 0])  // Wrong wire type (length delimited), valid as an unknown field
        assertDecodeFails([11])
        assertDecodeFails([11, 0])
        assertDecodesAsUnknownFields([11, 12])  // Wrong wire type (startGroup, endGroup), valid as an unknown field
        assertDecodeFails([12])
        assertDecodeFails([12, 0])
        assertDecodeFails([13])
        assertDecodeFails([13, 0])
        assertDecodesAsUnknownFields([13, 0, 0, 0, 0])  // Wrong wire type (fixed32), valid as an unknown field
        assertDecodeFails([14])
        assertDecodeFails([14, 0])
        assertDecodeFails([15])
        assertDecodeFails([15, 0])

        // Decoded extension should correctly compare to a manually-set extension
        let m1 = try SwiftProtoTesting_TestAllExtensions(serializedBytes: [8, 17], extensions: extensions)
        var m2 = SwiftProtoTesting_TestAllExtensions()
        m2.SwiftProtoTesting_optionalInt32Extension = 17
        XCTAssertEqual(m1, m2)
        m2.SwiftProtoTesting_optionalInt32Extension = 18
        XCTAssertNotEqual(m1, m2)
    }

    func test_extensionMessageSpecificity() throws {
        // An extension set with two extensions for field #5, but for
        // different messages and with different types
        var extensions = NewExtensionMap()
        extensions.insert(SwiftProtoTesting_Extensions_optional_sint32_extension)
        extensions.insert(SwiftProtoTesting_Extensions_my_extension_int)

        // This should decode with optionalSint32Extension
        let m1 = try SwiftProtoTesting_TestAllExtensions(serializedBytes: [40, 1], extensions: extensions)
        XCTAssertEqual(m1.SwiftProtoTesting_optionalSint32Extension, -1)

        // This should decode with myExtensionInt
        let m2 = try SwiftProtoTesting_TestFieldOrderings(serializedBytes: [40, 1], extensions: extensions)
        XCTAssertEqual(m2.SwiftProtoTesting_myExtensionInt, 1)
    }

    func test_optionalStringExtension() throws {
        assertEncode([114, 5, 104, 101, 108, 108, 111]) { (o: inout MessageTestType) in
            o.SwiftProtoTesting_optionalStringExtension = "hello"
        }
        assertDecodeSucceeds([114, 2, 97, 98]) { $0.SwiftProtoTesting_optionalStringExtension == "ab" }

        var m1 = SwiftProtoTesting_TestAllExtensions()
        m1.SwiftProtoTesting_optionalStringExtension = "ab"
    }

    func test_repeatedInt32Extension() throws {
        assertEncode([248, 1, 7, 248, 1, 8]) { (o: inout MessageTestType) in
            o.SwiftProtoTesting_repeatedInt32Extension = [7, 8]
        }
        assertDecodeSucceeds([248, 1, 7]) { $0.SwiftProtoTesting_repeatedInt32Extension == [7] }
        assertDecodeSucceeds([248, 1, 7, 248, 1, 8]) { $0.SwiftProtoTesting_repeatedInt32Extension == [7, 8] }
        assertDecodeSucceeds([250, 1, 2, 7, 8]) { $0.SwiftProtoTesting_repeatedInt32Extension == [7, 8] }

        // Verify that the usual array access/modification operations work correctly
        var m = SwiftProtoTesting_TestAllExtensions()
        m.SwiftProtoTesting_repeatedInt32Extension = [7]
        m.SwiftProtoTesting_repeatedInt32Extension.append(8)
        XCTAssertEqual(m.SwiftProtoTesting_repeatedInt32Extension, [7, 8])
        XCTAssertEqual(m.SwiftProtoTesting_repeatedInt32Extension[0], 7)
        m.SwiftProtoTesting_repeatedInt32Extension[1] = 9
        XCTAssertNotEqual(m.SwiftProtoTesting_repeatedInt32Extension, [7, 8])
        XCTAssertEqual(m.SwiftProtoTesting_repeatedInt32Extension, [7, 9])

        XCTAssertFalse(m.SwiftProtoTesting_repeatedInt32Extension.isEmpty)
        m.SwiftProtoTesting_repeatedInt32Extension = []
        XCTAssertTrue(m.SwiftProtoTesting_repeatedInt32Extension.isEmpty)
    }

    func test_defaultInt32Extension() throws {
        var m = SwiftProtoTesting_TestAllExtensions()
        XCTAssertEqual(m.SwiftProtoTesting_defaultInt32Extension, 41)
        XCTAssertEqual(try m.serializedBytes(), [])

        m.SwiftProtoTesting_defaultInt32Extension = 100
        XCTAssertEqual(try m.serializedBytes(), [232, 3, 100])

        m.clearSwiftProtoTesting_defaultInt32Extension()
        XCTAssertEqual(try m.serializedBytes(), [])

        m.SwiftProtoTesting_defaultInt32Extension = 41  // Default value
        XCTAssertEqual(try m.serializedBytes(), [232, 3, 41])

        assertEncode([232, 3, 17]) { (o: inout MessageTestType) in
            o.SwiftProtoTesting_defaultInt32Extension = 17
        }
    }

    func test_Text_file_level_extension() {
        assertTextFormatEncode(
            "[swift_proto_testing.optional_int32_extension]: 789\n",
            extensions: SwiftProtoTesting_Unittest_Extensions
        ) {
            (o: inout MessageTestType) in
            o.SwiftProtoTesting_optionalInt32Extension = 789
        }
        // Fails if we don't provide the extensions to the decoder:
        assertTextFormatDecodeFails("[swift_proto_testing.optional_int32_extension]: 789\n")

        assertTextFormatEncode(
            "[swift_proto_testing.optionalgroup_extension] {\n  a: 789\n}\n",
            extensions: SwiftProtoTesting_Unittest_Extensions
        ) {
            (o: inout MessageTestType) in
            o.SwiftProtoTesting_optionalGroupExtension.a = 789
        }
        // Fails if we don't provide the extensions to the decoder:
        assertTextFormatDecodeFails("[swift_proto_testing.optionalgroup_extension] {\n  a: 789\n}\n")
    }

    func test_Text_nested_extension() {
        assertTextFormatEncode(
            "[swift_proto_testing.TestNestedExtension.test]: \"foo\"\n",
            extensions: SwiftProtoTesting_Unittest_Extensions
        ) {
            (o: inout MessageTestType) in
            o.SwiftProtoTesting_TestNestedExtension_test = "foo"
        }
        // Fails if we don't provide the extensions to the decoder:
        assertTextFormatDecodeFails("[swift_proto_testing.TestNestedExtension.test]: \"foo\"\n")
    }


    func test_JSON_optionalInt32Extension() throws {
        assertJSONEncode(
            "{\"[swift_proto_testing.optional_int32_extension]\":17}",
            extensions: extensions
        ) {
            (o: inout MessageTestType) in
            o.SwiftProtoTesting_optionalInt32Extension = 17
        }

        assertJSONDecodeFails(
            "{\"[swift_proto_testing.UNKNOWN_EXTENSION]\":17}",
            extensions: extensions
        )
        assertJSONDecodeFails(
            "{\"[UNKNOWN_PACKAGE.optional_int32_extension]\":17}",
            extensions: extensions
        )
        assertJSONDecodeFails(
            "{\"[swift_proto_testing.optional_int32_extension\":17}",
            extensions: extensions
        )
        assertJSONDecodeFails(
            "{\"swift_proto_testing.optional_int32_extension]\":17}",
            extensions: extensions
        )
        assertJSONDecodeFails(
            "{\"[optional_int32_extension\":17}",
            extensions: extensions
        )
        assertJSONDecodeFails(
            "{\"swift_proto_testing.optional_int32_extension\":17}",
            extensions: extensions
        )
    }

    func test_JSON_optionalMessageExtension() throws {
        assertJSONEncode(
            "{\"[swift_proto_testing.optional_nested_message_extension]\":{\"bb\":12}}",
            extensions: extensions
        ) {
            (o: inout MessageTestType) in
            o.SwiftProtoTesting_optionalNestedMessageExtension =
            SwiftProtoTesting_TestAllTypes.NestedMessage.with {
                $0.bb = 12
            }
        }
    }

    func test_JSON_repeatedInt32Extension() throws {
        assertJSONEncode(
            "{\"[swift_proto_testing.repeated_int32_extension]\":[1,2,3,17]}",
            extensions: extensions
        ) {
            (o: inout MessageTestType) in
            o.SwiftProtoTesting_repeatedInt32Extension = [1, 2, 3, 17]
        }
    }

    func test_JSON_repeatedMessageExtension() throws {
        assertJSONEncode(
            "{\"[swift_proto_testing.repeated_nested_message_extension]\":[{\"bb\":12},{}]}",
            extensions: extensions
        ) {
            (o: inout MessageTestType) in
            o.SwiftProtoTesting_repeatedNestedMessageExtension =
            [
                SwiftProtoTesting_TestAllTypes.NestedMessage.with { $0.bb = 12 },
                SwiftProtoTesting_TestAllTypes.NestedMessage(),
            ]
        }
    }

    func test_JSON_optionalStringExtensionWithDefault() throws {
        assertJSONEncode("{\"[swift_proto_testing.default_string_extension]\":\"hi\"}", extensions: extensions) {
            (o: inout MessageTestType) in
            o.SwiftProtoTesting_defaultStringExtension = "hi"
        }

        assertJSONDecodeSucceeds("{}", extensions: extensions) {
            $0.SwiftProtoTesting_defaultStringExtension == "hello"
        }
    }
}
