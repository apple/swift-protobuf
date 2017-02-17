// Tests/SwiftProtobufTests/Test_Required.swift - Test required field handling
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// The current Swift backend implementation:
///  * Always serializes all required fields.
///  * Does not fail deserialization if a required field is missing.
///  * Getter always returns a non-nil value (even for message and group fields)
///  * Accessor uses a non-optional type
///
/// In particular, this means that you cannot clear a required field by
/// setting it to nil as you can with an optional field.  With an
/// optional field, assigning nil clears it (after which reading it
/// will return the default value or nil if no default was specified).
///
/// Note: Google's documentation says that "...  old readers will
/// consider messages without [a required] field to be incomplete".
/// This suggests that newer readers should not reject messages that
/// are missing required fields.  It also appears that Google's
/// serializers simply omit unset required fields.
///
// -----------------------------------------------------------------------------

import Foundation
import XCTest

// TODO(#98): The tests in this class are currently disabled since they are
// verifying incorrect behavior that needs to be fixed and were broken by
// another change.
class Test_Required: XCTestCase, PBTestHelpers {
    typealias MessageTestType = ProtobufUnittest_TestAllRequiredTypes

    let expected: [UInt8] = [
        8, 0,
        16, 0,
        24, 0,
        32, 0,
        40, 0,
        48, 0,
        61, 0, 0, 0, 0,
        65, 0, 0, 0, 0, 0, 0, 0, 0,
        77, 0, 0, 0, 0,
        81, 0, 0, 0, 0, 0, 0, 0, 0,
        93, 0, 0, 0, 0,
        97, 0, 0, 0, 0, 0, 0, 0, 0,
        104, 0,
        114, 0,
        122, 0,
        168, 1, 1, // required_nested_enum
        176, 1, 4,
        184, 1, 7,
        194, 1, 0, // required_string_piece
        202, 1, 0, // required_cord
        232, 3, 41, // required default_int32
        240, 3, 42,
        248, 3, 43,
        128, 4, 44,
        136, 4, 89,
        144, 4, 92,
        157, 4, 47, 0, 0, 0,
        161, 4, 48, 0, 0, 0, 0, 0, 0, 0,
        173, 4, 49, 0, 0, 0,
        177, 4, 206, 255, 255, 255, 255, 255, 255, 255,
        189, 4, 0, 0, 78, 66,
        193, 4, 0, 0, 0, 0, 0, 100, 233, 64,
        200, 4, 1,
        210, 4, 5, 104, 101, 108, 108, 111,
        218, 4, 5, 119, 111, 114, 108, 100,
        136, 5, 2,
        144, 5, 5,
        152, 5, 8,
        162, 5, 3, 97, 98, 99,
        170, 5, 3, 49, 50, 51]

    let expectedJSON = ("{"
        + "\"requiredInt32\":0,"
        + "\"requiredInt64\":\"0\","
        + "\"requiredUint32\":0,"
        + "\"requiredUint64\":\"0\","
        + "\"requiredSint32\":0,"
        + "\"requiredSint64\":\"0\","
        + "\"requiredFixed32\":0,"
        + "\"requiredFixed64\":\"0\","
        + "\"requiredSfixed32\":0,"
        + "\"requiredSfixed64\":\"0\","
        + "\"requiredFloat\":0,"
        + "\"requiredDouble\":0,"
        + "\"requiredBool\":false,"
        + "\"requiredString\":\"\","
        + "\"requiredBytes\":\"\","
        + "\"requiredNestedEnum\":\"FOO\","
        + "\"requiredForeignEnum\":\"FOREIGN_FOO\","
        + "\"requiredImportEnum\":\"IMPORT_FOO\","
        + "\"requiredStringPiece\":\"\","
        + "\"requiredCord\":\"\","
        + "\"defaultInt32\":41,"
        + "\"defaultInt64\":\"42\","
        + "\"defaultUint32\":43,"
        + "\"defaultUint64\":\"44\","
        + "\"defaultSint32\":-45,"
        + "\"defaultSint64\":\"46\","
        + "\"defaultFixed32\":47,"
        + "\"defaultFixed64\":\"48\","
        + "\"defaultSfixed32\":49,"
        + "\"defaultSfixed64\":\"-50\","
        + "\"defaultFloat\":51.5,"
        + "\"defaultDouble\":52000,"
        + "\"defaultBool\":true,"
        + "\"defaultString\":\"hello\","
        + "\"defaultBytes\":\"d29ybGQ=\","
        + "\"defaultNestedEnum\":\"BAR\","
        + "\"defaultForeignEnum\":\"FOREIGN_BAR\","
        + "\"defaultImportEnum\":\"IMPORT_BAR\","
        + "\"defaultStringPiece\":\"abc\","
        + "\"defaultCord\":\"123\""
        + "}")

    func test_IsInitialized() {
        // message declared in proto2 syntax file with required fields.
        var msg = ProtobufUnittest_TestRequired()
        XCTAssertFalse(msg.isInitialized)
        msg.a = 1
        XCTAssertFalse(msg.isInitialized)
        msg.b = 2
        XCTAssertFalse(msg.isInitialized)
        msg.c = 3
        XCTAssertTrue(msg.isInitialized)
    }

    func test_OneOf_IsInitialized() {
        // message declared in proto2 syntax file with a message in a oneof where that message
        // has a required field.
        var msg = ProtobufUnittest_TestRequiredOneof()
        XCTAssertTrue(msg.isInitialized)
        msg.fooMessage = ProtobufUnittest_TestRequiredOneof.NestedMessage()
        XCTAssertFalse(msg.isInitialized)
        msg.fooInt = 1
        XCTAssertTrue(msg.isInitialized)
        msg.fooMessage = ProtobufUnittest_TestRequiredOneof.NestedMessage()
        XCTAssertFalse(msg.isInitialized)
        msg.fooMessage.requiredDouble = 1.1
        XCTAssertTrue(msg.isInitialized)
    }


    func test_NestedInProto2_IsInitialized() {
        // message declared in proto2 syntax file, with fields that are another message that has
        // required fields.
        var msg = ProtobufUnittest_TestRequiredForeign()

        XCTAssertTrue(msg.isInitialized)

        msg.optionalMessage = ProtobufUnittest_TestRequired()
        XCTAssertFalse(msg.isInitialized)
        msg.optionalMessage.a = 1
        msg.optionalMessage.b = 2
        XCTAssertFalse(msg.isInitialized)
        msg.optionalMessage.c = 3
        XCTAssertTrue(msg.isInitialized)

        msg.repeatedMessage.append(ProtobufUnittest_TestRequired())
        XCTAssertFalse(msg.isInitialized)
        msg.repeatedMessage[0].a = 1
        msg.repeatedMessage[0].b = 2
        XCTAssertFalse(msg.isInitialized)
        msg.repeatedMessage[0].c = 3
        XCTAssertTrue(msg.isInitialized)
    }

    func test_NestedInProto3_IsInitialized() {
        // message declared in proto3 syntax file, with fields that are another message that has
        // required fields.
        var msg = Proto2NofieldpresenceUnittest_TestProto2Required()

        XCTAssertTrue(msg.isInitialized)

        msg.proto2 = ProtobufUnittest_TestRequired()
        XCTAssertFalse(msg.isInitialized)
        msg.proto2.a = 1
        msg.proto2.b = 2
        XCTAssertFalse(msg.isInitialized)
        msg.proto2.c = 3
        XCTAssertTrue(msg.isInitialized)
    }

    func test_map_isInitialized() {
        var msg = ProtobufUnittest_TestRequiredMessageMap()

        XCTAssertTrue(msg.isInitialized)

        msg.mapField[0] = ProtobufUnittest_TestRequired()
        XCTAssertFalse(msg.isInitialized)

        msg.mapField[0]!.a = 1
        msg.mapField[0]!.b = 2
        XCTAssertFalse(msg.isInitialized)
        msg.mapField[0]!.c = 3
        XCTAssertTrue(msg.isInitialized)
    }

    func test_Extensions_isInitialized() {
        var msg = ProtobufUnittest_TestAllExtensions()

        XCTAssertTrue(msg.isInitialized)

        msg.ProtobufUnittest_TestRequired_single = ProtobufUnittest_TestRequired()
        XCTAssertFalse(msg.isInitialized)
        msg.ProtobufUnittest_TestRequired_single.a = 1
        msg.ProtobufUnittest_TestRequired_single.b = 2
        XCTAssertFalse(msg.isInitialized)
        msg.ProtobufUnittest_TestRequired_single.c = 3
        XCTAssertTrue(msg.isInitialized)

        msg.ProtobufUnittest_TestRequired_multi.append(ProtobufUnittest_TestRequired())
        XCTAssertFalse(msg.isInitialized)
        msg.ProtobufUnittest_TestRequired_multi[0].a = 1
        msg.ProtobufUnittest_TestRequired_multi[0].b = 2
        XCTAssertFalse(msg.isInitialized)
        msg.ProtobufUnittest_TestRequired_multi[0].c = 3
        XCTAssertTrue(msg.isInitialized)
    }

    func DISABLED_test_bare() throws {
        // Because we always encode required fields, we get a non-trivial
        // output even for a bare object.
        let o = MessageTestType()
        XCTAssertEqual(try o.serializedBytes(), expected)
        XCTAssertEqual(try o.jsonString(), expectedJSON)
    }

    func DISABLED_test_requiredInt32() {
        var a = expected
        a[1] = 1
        assertEncode(a) {(o: inout MessageTestType) in
            o.requiredInt32 = 1
        }
        assertDecodeSucceeds([8, 2]) {
            let val: Int32 = $0.requiredInt32  // Verify non-optional
            return val == 2
        }
    }

    func DISABLED_test_requiredFloat() {
        var a = expected
        a[44] = 63 // float value is 0, 0, 0, 63
        assertEncode(a) {(o: inout MessageTestType) in
            o.requiredFloat = 0.5
        }
        assertDecodeSucceeds([93, 0, 0, 0, 0]) {
            let val: Float = $0.requiredFloat  // Verify non-optional
            return val == 0.0
        }
    }

    func DISABLED_test_requiredString() {
        // Splice the expected value for this field
        let prefix = expected[0..<56]
        let field: [UInt8] = [114, 1, 97]
        let suffix = expected[58..<expected.count]
        let a = [UInt8](prefix + field + suffix)
        assertEncode(a) {(o: inout MessageTestType) in
            o.requiredString = "a"
        }
        assertDecodeSucceeds([114, 1, 98]) {
            let val: String = $0.requiredString  // Verify non-optional
            return val == "b"
        }
    }

    // TODO: Check required group

    // TODO: Check required submessage (and its fields)

    // TODO: Check defaults on required fields

}

class Test_SmallRequired: XCTestCase, PBTestHelpers {
    typealias MessageTestType = ProtobufUnittest_TestSomeRequiredTypes
    // Check behavior of a small message (non-heap-stored) with required fields

// These are all disabled pending:
//    https://github.com/apple/swift-protobuf/issues/98
// The problem is the current code serializae the required fields even if they
// aren't set (instead of checking that they were set. That means when
// assertDecodeSucceeds serializes the message and reloads it, more fields end
// up set and equality is no longer true. The original form of this test was
// dependent on https://github.com/apple/swift-protobuf/issues/97 so fixing that
// breaks these due to the bad behaviors for required fields.
//    func testRequiredInt32() {
//        assertDecodeSucceeds([8, 2]) {
//            let val: Int32 = $0.requiredInt32  // Verify non-optional
//            return val == 2
//        }
//    }
//
//    func testRequiredFloat() {
//        assertDecodeSucceeds([21, 0, 0, 0, 63]) {
//            let val: Float = $0.requiredFloat  // Verify non-optional
//            return val == 0.5
//        }
//    }
//
//    func testRequiredBool() {
//        assertDecodeSucceeds([24, 1]) {
//            let val: Bool = $0.requiredBool  // Verify non-optional
//            return val == true
//        }
//    }
//
//    func testRequiredString() {
//        assertDecodeSucceeds([34, 1, 97]) {
//            let val: String = $0.requiredString  // Verify non-optional
//            return val == "a"
//        }
//    }
//
//    func testRequiredBytes() {
//        assertDecodeSucceeds([42, 1, 1]) {
//            let val: Data = $0.requiredBytes  // Verify non-optional
//            return val == Data(bytes: [1])
//        }
//    }
//
//    func testRequiredNestedEnum() {
//        assertDecodeSucceeds([48, 1]) {
//            let val: ProtobufUnittest_TestSomeRequiredTypes.NestedEnum = $0.requiredNestedEnum
//            return val == .foo
//        }
//    }

}
