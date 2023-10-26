// Tests/SwiftProtobufTests/Test_Reserved.swift - Verify handling of reserved words
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Proto files may have fields, enum cases, or messages whose names happen
/// to be reserved in various languages.  In Swift, some of these reserved
/// words can be used if we put them in backticks.  Others must be modified
/// by appending an underscore so they don't conflict.
///
// -----------------------------------------------------------------------------

import Foundation
import XCTest
@testable import SwiftProtobuf

final class Test_Reserved: XCTestCase {
    func testEnumNaming() {
        XCTAssertEqual(SwiftProtoTesting_SwiftReservedTest.Enum.double.rawValue, 1)
        XCTAssertEqual(String(describing: SwiftProtoTesting_SwiftReservedTest.Enum.double.name!), "DOUBLE")
        XCTAssertEqual(SwiftProtoTesting_SwiftReservedTest.Enum.json.rawValue, 2)
        XCTAssertEqual(String(describing: SwiftProtoTesting_SwiftReservedTest.Enum.json.name!), "JSON")
        XCTAssertEqual(SwiftProtoTesting_SwiftReservedTest.Enum.`class`.rawValue, 3)
        XCTAssertEqual(String(describing: SwiftProtoTesting_SwiftReservedTest.Enum.`class`.name!), "CLASS")
        XCTAssertEqual(SwiftProtoTesting_SwiftReservedTest.Enum.___.rawValue, 4)
        XCTAssertEqual(String(describing: SwiftProtoTesting_SwiftReservedTest.Enum.___.name!), "_")
        XCTAssertEqual(SwiftProtoTesting_SwiftReservedTest.Enum.self_.rawValue, 5)
        XCTAssertEqual(String(describing: SwiftProtoTesting_SwiftReservedTest.Enum.self_.name!), "SELF")
        XCTAssertEqual(SwiftProtoTesting_SwiftReservedTest.Enum.type.rawValue, 6)
        XCTAssertEqual(String(describing: SwiftProtoTesting_SwiftReservedTest.Enum.type.name!), "TYPE")
    }

    func testMessageNames() {
        XCTAssertEqual(SwiftProtoTesting_SwiftReservedTest.classMessage.protoMessageName, "swift_proto_testing.SwiftReservedTest.class")
        XCTAssertEqual(SwiftProtoTesting_SwiftReservedTest.isEqual.protoMessageName, "swift_proto_testing.SwiftReservedTest.isEqual")
        XCTAssertEqual(SwiftProtoTesting_SwiftReservedTest.TypeMessage.protoMessageName, "swift_proto_testing.SwiftReservedTest.Type")
    }

    func testFieldNamesMatchingMetadata() {
        // A chunk of this test is just that things compile because it is calling the names
        // we expect to have generated.

        var msg = SwiftProtoTesting_SwiftReservedTest()

        msg.protoMessageName = 1
        msg.protoPackageName = 2
        msg.anyTypePrefix = 3
        msg.anyTypeURL = 4

        msg.isInitialized_p = "foo"
        msg.hashValue_p = "bar"
        msg.debugDescription_p = 5

        assertDebugDescription("SwiftProtobufTests.SwiftProtoTesting_SwiftReservedTest:\nproto_message_name: 1\nproto_package_name: 2\nany_type_prefix: 3\nany_type_url: 4\nis_initialized: \"foo\"\nhash_value: \"bar\"\ndebug_description: 5\n", msg)

        msg.clearIsInitialized_p()
        msg.clearHashValue_p()
        msg.clearDebugDescription_p()
        XCTAssertFalse(msg.hasIsInitialized_p)
        XCTAssertFalse(msg.hasHashValue_p)
        XCTAssertFalse(msg.hasDebugDescription_p)
    }

    func testExtensionNamesMatching() {
        // This is really just a compile test, if things don't compile, check that the
        // new names really make sense.

        var msg = SwiftProtoTesting_SwiftReservedTest.TypeMessage()

        msg.debugDescription_p = true
        XCTAssertTrue(msg.hasDebugDescription_p)
        msg.clearDebugDescription_p()

        msg.SwiftReservedTestExt2_hashValue = true
        XCTAssertTrue(msg.hasSwiftReservedTestExt2_hashValue)
        msg.clearSwiftReservedTestExt2_hashValue()
    }
}
