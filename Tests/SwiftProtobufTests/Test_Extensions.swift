// Tests/SwiftProtobufTests/Test_Extensions.swift - Exercise proto2 extensions
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Test support for Proto2 extensions.
///
// -----------------------------------------------------------------------------

import Foundation
import XCTest
import SwiftProtobuf

// Exercise the support for Proto2 extensions.

final class Test_Extensions: XCTestCase, PBTestHelpers {
    typealias MessageTestType = SwiftProtoTesting_TestAllExtensions
    var extensions = SwiftProtobuf.SimpleExtensionMap()

    func assertEncode(_ expected: [UInt8], file: XCTestFileArgType = #file, line: UInt = #line, configure: (inout MessageTestType) -> Void) {
        let empty = MessageTestType()
        var configured = empty
        configure(&configured)
        XCTAssert(configured != empty, "Object should not be equal to empty object", file: file, line: line)
        do {
            let encoded: [UInt8] = try configured.serializedBytes()
            XCTAssert(expected == encoded, "Did not encode correctly: got \(encoded)", file: file, line: line)
            do {
                let decoded = try MessageTestType(serializedBytes: encoded, extensions: extensions)
                XCTAssert(decoded == configured, "Encode/decode cycle should generate equal object: \(decoded) != \(configured)", file: file, line: line)
            } catch {
                XCTFail("Failed to decode protobuf: \(encoded)", file: file, line: line)
            }
        } catch {
            XCTFail("Failed to encode \(configured)", file: file, line: line)
        }
    }

    func assertDecodeSucceeds(_ bytes: [UInt8], file: XCTestFileArgType = #file, line: UInt = #line, check: (MessageTestType) -> Bool) {
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
        extensions.formUnion(SwiftProtoTesting_Extend_UnittestSwiftExtension_Extensions)
        // Append an array of extensions
        extensions.insert(contentsOf:
            [
                Extensions_RepeatedExtensionGroup,
                Extensions_ExtensionGroup
            ]
        )
    }

    func test_optionalInt32Extension() throws {
        assertEncode([8, 17]) { (o: inout MessageTestType) in
            o.SwiftProtoTesting_optionalInt32Extension = 17
        }
        assertDecodeSucceeds([8, 99]) {$0.SwiftProtoTesting_optionalInt32Extension == 99}
        assertDecodeFails([9])
        assertDecodeFails([9, 0])
        assertDecodesAsUnknownFields([9, 0, 0, 0, 0, 0, 0, 0, 0])  // Wrong wire type (fixed64), valid as an unknown field
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

        assertDebugDescription("SwiftProtobufTests.SwiftProtoTesting_TestAllExtensions:\n[swift_proto_testing.optional_int32_extension]: 18\n", m2)
        XCTAssertNotEqual(m1.hashValue, m2.hashValue)
    }

    func test_extensionMessageSpecificity() throws {
        // An extension set with two extensions for field #5, but for
        // different messages and with different types
        var extensions = SimpleExtensionMap()
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
        assertDecodeSucceeds([114, 2, 97, 98]) {$0.SwiftProtoTesting_optionalStringExtension == "ab"}

        var m1 = SwiftProtoTesting_TestAllExtensions()
        m1.SwiftProtoTesting_optionalStringExtension = "ab"
        assertDebugDescription("SwiftProtobufTests.SwiftProtoTesting_TestAllExtensions:\n[swift_proto_testing.optional_string_extension]: \"ab\"\n", m1)
    }

    func test_repeatedInt32Extension() throws {
        assertEncode([248, 1, 7, 248, 1, 8]) { (o: inout MessageTestType) in
            o.SwiftProtoTesting_repeatedInt32Extension = [7, 8]
        }
        assertDecodeSucceeds([248, 1, 7]) {$0.SwiftProtoTesting_repeatedInt32Extension == [7]}
        assertDecodeSucceeds([248, 1, 7, 248, 1, 8]) {$0.SwiftProtoTesting_repeatedInt32Extension == [7, 8]}
        assertDecodeSucceeds([250, 1, 2, 7, 8]) {$0.SwiftProtoTesting_repeatedInt32Extension == [7, 8]}

        // Verify that the usual array access/modification operations work correctly
        var m = SwiftProtoTesting_TestAllExtensions()
        m.SwiftProtoTesting_repeatedInt32Extension = [7]
        m.SwiftProtoTesting_repeatedInt32Extension.append(8)
        XCTAssertEqual(m.SwiftProtoTesting_repeatedInt32Extension, [7, 8])
        XCTAssertEqual(m.SwiftProtoTesting_repeatedInt32Extension[0], 7)
        m.SwiftProtoTesting_repeatedInt32Extension[1] = 9
        XCTAssertNotEqual(m.SwiftProtoTesting_repeatedInt32Extension, [7, 8])
        XCTAssertEqual(m.SwiftProtoTesting_repeatedInt32Extension, [7, 9])

        assertDebugDescription("SwiftProtobufTests.SwiftProtoTesting_TestAllExtensions:\n[swift_proto_testing.repeated_int32_extension]: 7\n[swift_proto_testing.repeated_int32_extension]: 9\n", m)

        XCTAssertFalse(m.SwiftProtoTesting_repeatedInt32Extension.isEmpty)
        m.SwiftProtoTesting_repeatedInt32Extension = []
        XCTAssertTrue(m.SwiftProtoTesting_repeatedInt32Extension.isEmpty)
    }

    func test_defaultInt32Extension() throws {
        var m = SwiftProtoTesting_TestAllExtensions()
        XCTAssertEqual(m.SwiftProtoTesting_defaultInt32Extension, 41)
        XCTAssertEqual(try m.serializedBytes(), [])
        assertDebugDescription("SwiftProtobufTests.SwiftProtoTesting_TestAllExtensions:\n", m)
        m.SwiftProtoTesting_defaultInt32Extension = 100
        XCTAssertEqual(try m.serializedBytes(), [232, 3, 100])
        assertDebugDescription("SwiftProtobufTests.SwiftProtoTesting_TestAllExtensions:\n[swift_proto_testing.default_int32_extension]: 100\n", m)
        m.clearSwiftProtoTesting_defaultInt32Extension()
        XCTAssertEqual(try m.serializedBytes(), [])
        assertDebugDescription("SwiftProtobufTests.SwiftProtoTesting_TestAllExtensions:\n", m)
        m.SwiftProtoTesting_defaultInt32Extension = 41 // Default value
        XCTAssertEqual(try m.serializedBytes(), [232, 3, 41])
        assertDebugDescription("SwiftProtobufTests.SwiftProtoTesting_TestAllExtensions:\n[swift_proto_testing.default_int32_extension]: 41\n", m)

        assertEncode([232, 3, 17]) { (o: inout MessageTestType) in
            o.SwiftProtoTesting_defaultInt32Extension = 17
        }
    }

    ///
    /// Verify group extensions and handling of unknown groups
    ///
    func test_groupExtension() throws {
        var m = SwiftTestGroupExtensions()
        var group = ExtensionGroup()
        group.a = 7
        m.extensionGroup = group
        let coded: [UInt8] = try m.serializedBytes()

        // Deserialize into a message that lacks the group extension, then reserialize
        // Group should be preserved as an unknown field
        do {
            let m2 = try SwiftTestGroupUnextended(serializedBytes: coded)
            XCTAssert(!m2.hasA)
            let recoded: [UInt8] = try m2.serializedBytes()

            // Deserialize, check the group contents were preserved.
            do {
                let m3 = try SwiftTestGroupExtensions(serializedBytes: recoded, extensions: extensions)
                XCTAssertEqual(m3.extensionGroup.a, 7)
            } catch {
                XCTFail("Bad decode/recode/decode cycle")
            }
        } catch {
            XCTFail("Decoding into unextended message failed for \(coded)")
        }
    }


    func test_repeatedGroupExtension() throws {
        var m = SwiftTestGroupExtensions()
        var group1 = RepeatedExtensionGroup()
        group1.a = 7
        var group2 = RepeatedExtensionGroup()
        group2.a = 7
        m.repeatedExtensionGroup = [group1, group2]
        let coded: [UInt8] = try m.serializedBytes()

        // Deserialize into a message that lacks the group extension, then reserialize
        // Group should be preserved as an unknown field
        do {
            let m2 = try SwiftTestGroupUnextended(serializedBytes: coded)
            XCTAssert(!m2.hasA)
            do {
                let recoded: [UInt8] = try m2.serializedBytes()

                // Deserialize, check the group contents were preserved.
                do {
                    let m3 = try SwiftTestGroupExtensions(serializedBytes: recoded, extensions: extensions)
                    XCTAssertEqual(m3.repeatedExtensionGroup, [group1, group2])
                } catch {
                    XCTFail("Bad decode/recode/decode cycle")
                }
            } catch {
                XCTFail("Recoding failed for \(m2)")
            }
        } catch {
            XCTFail("Decoding into unextended message failed for \(coded)")
        }

        XCTAssertFalse(m.repeatedExtensionGroup.isEmpty)
        m.repeatedExtensionGroup = []
        XCTAssertTrue(m.repeatedExtensionGroup.isEmpty)
    }

    func test_MessageNoStorageClass() {
        var msg1 = SwiftProtoTesting_Extend_MsgNoStorage()
        XCTAssertFalse(msg1.hasSwiftProtoTesting_Extend_extA)
        XCTAssertEqual(msg1.SwiftProtoTesting_Extend_extA, 0)
        XCTAssertFalse(msg1.hasSwiftProtoTesting_Extend_extB)
        XCTAssertEqual(msg1.SwiftProtoTesting_Extend_extB, 0)

        msg1.SwiftProtoTesting_Extend_extA = 1
        msg1.SwiftProtoTesting_Extend_extB = 2
        XCTAssertTrue(msg1.hasSwiftProtoTesting_Extend_extA)
        XCTAssertEqual(msg1.SwiftProtoTesting_Extend_extA, 1)
        XCTAssertTrue(msg1.hasSwiftProtoTesting_Extend_extB)
        XCTAssertEqual(msg1.SwiftProtoTesting_Extend_extB, 2)

        var msg2 = msg1
        XCTAssertTrue(msg2.hasSwiftProtoTesting_Extend_extA)
        XCTAssertEqual(msg2.SwiftProtoTesting_Extend_extA, 1)
        XCTAssertTrue(msg2.hasSwiftProtoTesting_Extend_extB)
        XCTAssertEqual(msg2.SwiftProtoTesting_Extend_extB, 2)

        msg2.SwiftProtoTesting_Extend_extA = 10
        XCTAssertTrue(msg2.hasSwiftProtoTesting_Extend_extA)
        XCTAssertEqual(msg2.SwiftProtoTesting_Extend_extA, 10)
        XCTAssertTrue(msg2.hasSwiftProtoTesting_Extend_extB)
        XCTAssertEqual(msg2.SwiftProtoTesting_Extend_extB, 2)
        XCTAssertTrue(msg1.hasSwiftProtoTesting_Extend_extA)
        XCTAssertEqual(msg1.SwiftProtoTesting_Extend_extA, 1)
        XCTAssertTrue(msg1.hasSwiftProtoTesting_Extend_extB)
        XCTAssertEqual(msg1.SwiftProtoTesting_Extend_extB, 2)

        msg1.SwiftProtoTesting_Extend_extB = 3
        XCTAssertTrue(msg2.hasSwiftProtoTesting_Extend_extA)
        XCTAssertEqual(msg2.SwiftProtoTesting_Extend_extA, 10)
        XCTAssertTrue(msg2.hasSwiftProtoTesting_Extend_extB)
        XCTAssertEqual(msg2.SwiftProtoTesting_Extend_extB, 2)
        XCTAssertTrue(msg1.hasSwiftProtoTesting_Extend_extA)
        XCTAssertEqual(msg1.SwiftProtoTesting_Extend_extA, 1)
        XCTAssertTrue(msg1.hasSwiftProtoTesting_Extend_extB)
        XCTAssertEqual(msg1.SwiftProtoTesting_Extend_extB, 3)

        msg2 = msg1
        XCTAssertTrue(msg2.hasSwiftProtoTesting_Extend_extA)
        XCTAssertEqual(msg2.SwiftProtoTesting_Extend_extA, 1)
        XCTAssertTrue(msg2.hasSwiftProtoTesting_Extend_extB)
        XCTAssertEqual(msg2.SwiftProtoTesting_Extend_extB, 3)

        msg2.clearSwiftProtoTesting_Extend_extA()
        XCTAssertFalse(msg2.hasSwiftProtoTesting_Extend_extA)
        XCTAssertEqual(msg2.SwiftProtoTesting_Extend_extA, 0)
        XCTAssertTrue(msg2.hasSwiftProtoTesting_Extend_extB)
        XCTAssertEqual(msg2.SwiftProtoTesting_Extend_extB, 3)
        XCTAssertTrue(msg1.hasSwiftProtoTesting_Extend_extA)
        XCTAssertEqual(msg1.SwiftProtoTesting_Extend_extA, 1)
        XCTAssertTrue(msg1.hasSwiftProtoTesting_Extend_extB)
        XCTAssertEqual(msg1.SwiftProtoTesting_Extend_extB, 3)

        msg1.clearSwiftProtoTesting_Extend_extB()
        XCTAssertFalse(msg2.hasSwiftProtoTesting_Extend_extA)
        XCTAssertEqual(msg2.SwiftProtoTesting_Extend_extA, 0)
        XCTAssertTrue(msg2.hasSwiftProtoTesting_Extend_extB)
        XCTAssertEqual(msg2.SwiftProtoTesting_Extend_extB, 3)
        XCTAssertTrue(msg1.hasSwiftProtoTesting_Extend_extA)
        XCTAssertEqual(msg1.SwiftProtoTesting_Extend_extA, 1)
        XCTAssertFalse(msg1.hasSwiftProtoTesting_Extend_extB)
        XCTAssertEqual(msg1.SwiftProtoTesting_Extend_extB, 0)
    }

    func test_MessageUsingStorageClass() {
        var msg1 = SwiftProtoTesting_Extend_MsgUsesStorage()
        XCTAssertFalse(msg1.hasSwiftProtoTesting_Extend_extC)
        XCTAssertEqual(msg1.SwiftProtoTesting_Extend_extC, 0)
        XCTAssertFalse(msg1.hasSwiftProtoTesting_Extend_extD)
        XCTAssertEqual(msg1.SwiftProtoTesting_Extend_extD, 0)

        msg1.SwiftProtoTesting_Extend_extC = 1
        msg1.SwiftProtoTesting_Extend_extD = 2
        XCTAssertTrue(msg1.hasSwiftProtoTesting_Extend_extC)
        XCTAssertEqual(msg1.SwiftProtoTesting_Extend_extC, 1)
        XCTAssertTrue(msg1.hasSwiftProtoTesting_Extend_extD)
        XCTAssertEqual(msg1.SwiftProtoTesting_Extend_extD, 2)

        var msg2 = msg1
        XCTAssertTrue(msg2.hasSwiftProtoTesting_Extend_extC)
        XCTAssertEqual(msg2.SwiftProtoTesting_Extend_extC, 1)
        XCTAssertTrue(msg2.hasSwiftProtoTesting_Extend_extD)
        XCTAssertEqual(msg2.SwiftProtoTesting_Extend_extD, 2)

        msg2.SwiftProtoTesting_Extend_extC = 10
        XCTAssertTrue(msg2.hasSwiftProtoTesting_Extend_extC)
        XCTAssertEqual(msg2.SwiftProtoTesting_Extend_extC, 10)
        XCTAssertTrue(msg2.hasSwiftProtoTesting_Extend_extD)
        XCTAssertEqual(msg2.SwiftProtoTesting_Extend_extD, 2)
        XCTAssertTrue(msg1.hasSwiftProtoTesting_Extend_extC)
        XCTAssertEqual(msg1.SwiftProtoTesting_Extend_extC, 1)
        XCTAssertTrue(msg1.hasSwiftProtoTesting_Extend_extD)
        XCTAssertEqual(msg1.SwiftProtoTesting_Extend_extD, 2)

        msg1.SwiftProtoTesting_Extend_extD = 3
        XCTAssertTrue(msg2.hasSwiftProtoTesting_Extend_extC)
        XCTAssertEqual(msg2.SwiftProtoTesting_Extend_extC, 10)
        XCTAssertTrue(msg2.hasSwiftProtoTesting_Extend_extD)
        XCTAssertEqual(msg2.SwiftProtoTesting_Extend_extD, 2)
        XCTAssertTrue(msg1.hasSwiftProtoTesting_Extend_extC)
        XCTAssertEqual(msg1.SwiftProtoTesting_Extend_extC, 1)
        XCTAssertTrue(msg1.hasSwiftProtoTesting_Extend_extD)
        XCTAssertEqual(msg1.SwiftProtoTesting_Extend_extD, 3)

        msg2 = msg1
        XCTAssertTrue(msg2.hasSwiftProtoTesting_Extend_extC)
        XCTAssertEqual(msg2.SwiftProtoTesting_Extend_extC, 1)
        XCTAssertTrue(msg2.hasSwiftProtoTesting_Extend_extD)
        XCTAssertEqual(msg2.SwiftProtoTesting_Extend_extD, 3)

        msg2.clearSwiftProtoTesting_Extend_extC()
        XCTAssertFalse(msg2.hasSwiftProtoTesting_Extend_extC)
        XCTAssertEqual(msg2.SwiftProtoTesting_Extend_extC, 0)
        XCTAssertTrue(msg2.hasSwiftProtoTesting_Extend_extD)
        XCTAssertEqual(msg2.SwiftProtoTesting_Extend_extD, 3)
        XCTAssertTrue(msg1.hasSwiftProtoTesting_Extend_extC)
        XCTAssertEqual(msg1.SwiftProtoTesting_Extend_extC, 1)
        XCTAssertTrue(msg1.hasSwiftProtoTesting_Extend_extD)
        XCTAssertEqual(msg1.SwiftProtoTesting_Extend_extD, 3)

        msg1.clearSwiftProtoTesting_Extend_extD()
        XCTAssertFalse(msg2.hasSwiftProtoTesting_Extend_extC)
        XCTAssertEqual(msg2.SwiftProtoTesting_Extend_extC, 0)
        XCTAssertTrue(msg2.hasSwiftProtoTesting_Extend_extD)
        XCTAssertEqual(msg2.SwiftProtoTesting_Extend_extD, 3)
        XCTAssertTrue(msg1.hasSwiftProtoTesting_Extend_extC)
        XCTAssertEqual(msg1.SwiftProtoTesting_Extend_extC, 1)
        XCTAssertFalse(msg1.hasSwiftProtoTesting_Extend_extD)
        XCTAssertEqual(msg1.SwiftProtoTesting_Extend_extD, 0)
    }
}
