// Test/Sources/TestSuite/Test_Extensions.swift - Exercise proto2 extensions
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
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

class Test_Extensions: XCTestCase, PBTestHelpers {
    typealias MessageTestType = ProtobufUnittest_TestAllExtensions
    var extensions = SwiftProtobuf.ExtensionSet()

    func assertEncode(_ expected: [UInt8], file: XCTestFileArgType = #file, line: UInt = #line, configure: (inout MessageTestType) -> Void) {
        let empty = MessageTestType()
        var configured = empty
        configure(&configured)
        XCTAssert(configured != empty, "Object should not be equal to empty object", file: file, line: line)
        do {
            let encoded = try configured.serializeProtobuf()
            XCTAssert(Data(bytes: expected) == encoded, "Did not encode correctly: got \(encoded)", file: file, line: line)
            do {
                let decoded = try MessageTestType(protobuf: encoded, extensions: extensions)
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
            let decoded = try MessageTestType(protobuf: Data(bytes: bytes), extensions: extensions)
            XCTAssert(check(decoded), "Condition failed for \(decoded)", file: file, line: line)

            let encoded = try decoded.serializeProtobuf()
            do {
                let redecoded = try MessageTestType(protobuf: encoded, extensions: extensions)
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
            let _ = try MessageTestType(protobuf: Data(bytes: bytes), extensions: extensions)
            XCTFail("Swift decode should have failed: \(bytes)", file: file, line: line)
        } catch {
            // Yay!  It failed!
        }

    }

    func assertJSONEncode(_ expected: String, file: XCTestFileArgType = #file, line: UInt = #line, configure: (inout MessageTestType) -> Void) {
        let empty = MessageTestType()
        var configured = empty
        configure(&configured)
        XCTAssert(configured != empty, "Object should not be equal to empty object", file: file, line: line)
        do {
            let encoded = try configured.serializeJSON()
            XCTAssert(expected == encoded, "Did not encode correctly: got \(encoded)", file: file, line: line)
            do {
                let decoded = try MessageTestType(json: encoded, extensions: extensions)
                XCTAssert(decoded == configured, "Encode/decode cycle should generate equal object: \(decoded) != \(configured)", file: file, line: line)
            } catch {
                XCTFail("Encode/decode cycle should not throw error, decoding: \(encoded)", file: file, line: line)
            }
        } catch {
            XCTFail("Failed to serialize JSON: \(configured)")
        }
    }

    func assertJSONDecodeSucceeds(_ json: String, file: XCTestFileArgType = #file, line: UInt = #line, check: (MessageTestType) -> Bool) {
        do {
            let decoded = try MessageTestType(json: json)
            XCTAssert(check(decoded), "Condition failed for \(decoded)", file: file, line: line)

            do {
                let encoded = try decoded.serializeJSON()
                do {
                    let redecoded = try MessageTestType(json: json)
                    XCTAssert(check(redecoded), "Condition failed for redecoded \(redecoded)", file: file, line: line)
                    XCTAssertEqual(decoded, redecoded, file: file, line: line)
                } catch {
                    XCTFail("Swift should have recoded/redecoded without error: \(encoded)", file: file, line: line)
                }
            } catch {
                XCTFail("Swift should have recoded without error: \(decoded)", file: file, line: line)
            }
        } catch {
            XCTFail("Swift should have decoded without error: \(json)", file: file, line: line)
            return
        }
    }

    func assertJSONDecodeFails(_ json: String, file: XCTestFileArgType = #file, line: UInt = #line) {
        do {
            let _ = try MessageTestType(json: json)
            XCTFail("Swift decode should have failed: \(json)", file: file, line: line)
        } catch {
            // Yay! It failed!
        }
    }


    override func setUp() {
        // Start with all the extensions from the unittest.proto file:
        extensions = ProtobufUnittest_Unittest_Extensions
        // Append another file's worth:
        extensions = extensions.union(ProtobufUnittest_UnittestCustomOptions_Extensions)
        // Append an array of extensions
        extensions.insert(contentsOf:
            [
                SwiftTestGroupExtensions_repeatedExtensionGroup,
                SwiftTestGroupExtensions_extensionGroup
            ]
        )
    }

    func test_optionalInt32Extension() throws {
        assertEncode([8, 17]) { (o: inout MessageTestType) in
            o.optionalInt32Extension = 17
        }
        assertDecodeSucceeds([8, 99]) {$0.optionalInt32Extension == 99}
        assertDecodeFails([9])
        assertDecodeFails([9, 0])
        assertDecodeFails([9, 0, 0, 0, 0, 0, 0, 0, 0])
        assertDecodeFails([10])
        assertDecodeFails([10, 0])
        assertDecodeFails([11])
        assertDecodeFails([11, 0])
        assertDecodeFails([11, 12])
        assertDecodeFails([12])
        assertDecodeFails([12, 0])
        assertDecodeFails([13])
        assertDecodeFails([13, 0])
        assertDecodeFails([13, 0, 0, 0, 0])
        assertDecodeFails([14])
        assertDecodeFails([14, 0])
        assertDecodeFails([15])
        assertDecodeFails([15, 0])

        // Decoded extension should correctly compare to a manually-set extension
        let m1 = try ProtobufUnittest_TestAllExtensions(protobuf: Data(bytes: [8, 17]), extensions: extensions)
        var m2 = ProtobufUnittest_TestAllExtensions()
        m2.optionalInt32Extension = 17
        XCTAssertEqual(m1, m2)
        m2.optionalInt32Extension = 18
        XCTAssertNotEqual(m1, m2)

        XCTAssertEqual(m2.debugDescription, "ProtobufUnittest_TestAllExtensions(optionalInt32Extension:18)")
        XCTAssertNotEqual(m1.hashValue, m2.hashValue)
    }

    // TODO: Test more types of fields with JSON encoding and fix them...
    // TODO: Verify that JSON extensions work with proto field names as well.
    func test_optionalInt32Extension_JSON() throws {
        var m = MessageTestType()
        m.optionalInt32Extension = 18
        let json = try m.serializeJSON()
        XCTAssertEqual("{\"optionalInt32Extension\":18}", json)

        assertJSONEncode("{\"optionalInt32Extension\":18}") {(o: inout MessageTestType) in o.optionalInt32Extension = 18}
    }

    func test_extensionMessageSpecificity() throws {
        // An extension set with two extensions for field #5, but for
        // different messages and with different types
        var extensions = ExtensionSet()
        extensions.insert(ProtobufUnittest_TestAllExtensions_optionalSint32Extension)
        extensions.insert(ProtobufUnittest_TestFieldOrderings_myExtensionInt)

        // This should decode with optionalSint32Extension
        let m1 = try ProtobufUnittest_TestAllExtensions(protobuf: Data(bytes: [40, 1]), extensions: extensions)
        XCTAssertEqual(m1.optionalSint32Extension, -1)

        // This should decode with myExtensionInt
        let m2 = try ProtobufUnittest_TestFieldOrderings(protobuf: Data(bytes: [40, 1]), extensions: extensions)
        XCTAssertEqual(m2.myExtensionInt, 1)
    }

    func test_optionalStringExtension() throws {
        assertEncode([114, 5, 104, 101, 108, 108, 111]) { (o: inout MessageTestType) in
            o.optionalStringExtension = "hello"
        }
        assertDecodeSucceeds([114, 2, 97, 98]) {$0.optionalStringExtension == "ab"}

        var m1 = ProtobufUnittest_TestAllExtensions()
        m1.optionalStringExtension = "ab"
        XCTAssertEqual(m1.debugDescription, "ProtobufUnittest_TestAllExtensions(optionalStringExtension:\"ab\")")
    }

    func test_repeatedInt32Extension() throws {
        assertEncode([248, 1, 7, 248, 1, 8]) { (o: inout MessageTestType) in
            o.repeatedInt32Extension = [7, 8]
        }
        assertDecodeSucceeds([248, 1, 7]) {$0.repeatedInt32Extension == [7]}
        assertDecodeSucceeds([248, 1, 7, 248, 1, 8]) {$0.repeatedInt32Extension == [7, 8]}
        assertDecodeSucceeds([250, 1, 2, 7, 8]) {$0.repeatedInt32Extension == [7, 8]}

        // Verify that the usual array access/modification operations work correctly
        var m = ProtobufUnittest_TestAllExtensions()
        m.repeatedInt32Extension = [7]
        m.repeatedInt32Extension.append(8)
        XCTAssertEqual(m.repeatedInt32Extension, [7, 8])
        XCTAssertEqual(m.repeatedInt32Extension[0], 7)
        m.repeatedInt32Extension[1] = 9
        XCTAssertNotEqual(m.repeatedInt32Extension, [7, 8])
        XCTAssertEqual(m.repeatedInt32Extension, [7, 9])

        XCTAssertEqual(m.debugDescription, "ProtobufUnittest_TestAllExtensions(repeatedInt32Extension:[7,9])")
    }

    func test_defaultInt32Extension() throws {
        var m = ProtobufUnittest_TestAllExtensions()
        XCTAssertEqual(m.defaultInt32Extension, 41)
        XCTAssertEqual(try m.serializeProtobufBytes(), [])
        XCTAssertEqual(m.debugDescription, "ProtobufUnittest_TestAllExtensions()")
        m.defaultInt32Extension = 100
        XCTAssertEqual(try m.serializeProtobufBytes(), [232, 3, 100])
        XCTAssertEqual(m.debugDescription, "ProtobufUnittest_TestAllExtensions(defaultInt32Extension:100)")
        m.clearDefaultInt32Extension()
        XCTAssertEqual(try m.serializeProtobufBytes(), [])
        XCTAssertEqual(m.debugDescription, "ProtobufUnittest_TestAllExtensions()")
        m.defaultInt32Extension = 41 // Default value
        XCTAssertEqual(try m.serializeProtobufBytes(), [232, 3, 41])
        XCTAssertEqual(m.debugDescription, "ProtobufUnittest_TestAllExtensions(defaultInt32Extension:41)")

        assertEncode([232, 3, 17]) { (o: inout MessageTestType) in
            o.defaultInt32Extension = 17
        }
    }

    func test_reflection() throws {
        var m = ProtobufUnittest_TestAllExtensions()
        m.defaultInt32Extension = 1
        let mirror1 = Mirror(reflecting: m)

        XCTAssertEqual(mirror1.children.count, 1)
        if let (name, value) = mirror1.children.first {
            XCTAssertEqual(name!, "defaultInt32Extension")
            XCTAssertEqual((value as! Int32), 1)
        }

        m.repeatedInt32Extension = [1, 2, 3]
        let mirror2 = Mirror(reflecting: m)

        XCTAssertEqual(mirror2.children.count, 2)

        for (name, value) in mirror2.children {
            switch name! {
            case "defaultInt32Extension":
                XCTAssertEqual((value as! Int32), 1)
            case "repeatedInt32Extension":
                XCTAssertEqual((value as! [Int32]), [1, 2, 3])
            default:
                XCTFail("Unexpected child element \(name)")
            }
        }
    }

    ///
    /// Verify group extensions and handling of unknown groups
    ///
    func test_groupExtension() throws {
        var m = SwiftTestGroupExtensions()
        var group = ExtensionGroup() // Bug: This should be in SwiftTestGroupExtensions
        group.a = 7
        m.extensionGroup = group
        let coded = try m.serializeProtobuf()

        // Deserialize into a message that lacks the group extension, then reserialize
        // Group should be preserved as an unknown field
        do {
            let m2 = try SwiftTestGroupUnextended(protobuf: coded)
            XCTAssert(!m2.hasA)
            let recoded = try m2.serializeProtobuf()

            // Deserialize, check the group contents were preserved.
            do {
                let m3 = try SwiftTestGroupExtensions(protobuf: recoded, extensions: extensions)
                XCTAssertEqual(m3.extensionGroup.a, 7)
            } catch {
                XCTFail("Bad decode/recode/decode cycle")
            }
        } catch {
            XCTFail("Decoding into unextended message failed for \(coded)")
        }
    }


    func test_groupExtension_JSON() throws {
        var m = SwiftTestGroupExtensions()
        var group = ExtensionGroup()
        group.a = 7
        m.extensionGroup = group
        let json = try m.serializeJSON()

        XCTAssertEqual(json, "{\"extensiongroup\":{\"a\":7}}")

        let m2 = try SwiftTestGroupExtensions(json: json, extensions: [SwiftTestGroupExtensions_extensionGroup])
        XCTAssertNotNil(m2.extensionGroup)
        if m.hasExtensionGroup {
            XCTAssertEqual(m.extensionGroup.a, 7)
        }
    }

    func test_repeatedGroupExtension() throws {
        var m = SwiftTestGroupExtensions()
        var group1 = RepeatedExtensionGroup() // Bug: This should be in SwiftTestGroupExtensions
        group1.a = 7
        var group2 = RepeatedExtensionGroup() // Bug: This should be in SwiftTestGroupExtensions
        group2.a = 7
        m.repeatedExtensionGroup = [group1, group2]
        let coded = try m.serializeProtobuf()

        // Deserialize into a message that lacks the group extension, then reserialize
        // Group should be preserved as an unknown field
        do {
            let m2 = try SwiftTestGroupUnextended(protobuf: coded)
            XCTAssert(!m2.hasA)
            do {
                let recoded = try m2.serializeProtobuf()

                // Deserialize, check the group contents were preserved.
                do {
                    let m3 = try SwiftTestGroupExtensions(protobuf: recoded, extensions: extensions)
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
    }

    func test_repeatedGroupExtension_JSON() throws {
        var m = SwiftTestGroupExtensions()
        var group1 = RepeatedExtensionGroup()
        group1.a = 7
        var group2 = RepeatedExtensionGroup()
        group2.a = 8
        m.repeatedExtensionGroup = [group1, group2]
        let json = try m.serializeJSON()

        XCTAssertEqual(json, "{\"repeatedextensiongroup\":[{\"a\":7},{\"a\":8}]}")

        let m2 = try SwiftTestGroupExtensions(json: json, extensions: [SwiftTestGroupExtensions_repeatedExtensionGroup])
        XCTAssertEqual(m2.repeatedExtensionGroup.count, 2)
        if m2.repeatedExtensionGroup.count == 2 {
            XCTAssertEqual(m2.repeatedExtensionGroup[0].a, 7)
            XCTAssertEqual(m2.repeatedExtensionGroup[1].a, 8)
        }
    }
}
