// Tests/SwiftProtobufTests/Test_FieldMask.swift - Exercise well-known FieldMask type
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// The FieldMask type is a new standard message type in proto3.  It has a
/// specialized JSON coding.
///
// -----------------------------------------------------------------------------

import Foundation
import XCTest
import SwiftProtobuf

final class Test_FieldMask: XCTestCase, PBTestHelpers {
    typealias MessageTestType = Google_Protobuf_FieldMask

    func testJSON() {
        assertJSONEncode("\"foo\"") { (o: inout MessageTestType) in
            o.paths = ["foo"]
        }
        assertJSONEncode("\"foo,fooBar,foo.bar.baz\"") { (o: inout MessageTestType) in
            o.paths = ["foo", "foo_bar", "foo.bar.baz"]
        }
        // assertJSONEncode doesn't want an empty object, hand roll it.
        let msg = MessageTestType.with { (o: inout MessageTestType) in
            o.paths = []
        }
        XCTAssertEqual(try msg.jsonString(), "\"\"")
        assertJSONDecodeSucceeds("\"foo\"") { $0.paths == ["foo"] }
        assertJSONDecodeSucceeds("\"\"") { $0.paths == [] }
        assertJSONDecodeFails("foo")
        assertJSONDecodeFails("\"foo,\"")
        assertJSONDecodeFails("\"foo\",\"bar\"")
        assertJSONDecodeFails("\",foo\"")
        assertJSONDecodeFails("\"foo,,bar\"")
        assertJSONDecodeFails("\"foo,bar")
        assertJSONDecodeFails("foo,bar\"")
        assertJSONDecodeFails("\"H̱ܻ̻ܻ̻ܶܶAܻD\"") // Reject non-ASCII
        assertJSONDecodeFails("abc_def") // Reject underscores
    }

    func testProtobuf() {
        assertEncode([10, 3, 102, 111, 111]) { (o: inout MessageTestType) in
            o.paths = ["foo"]
        }
    }

    func testDebugDescription() {
        var m = Google_Protobuf_FieldMask()
        m.paths = ["foo", "bar"]
        assertDebugDescriptionSuffix(".Google_Protobuf_FieldMask:\npaths: \"foo\"\npaths: \"bar\"\n", m)
    }

    func testConvenienceInits() {
        var m = Google_Protobuf_FieldMask()
        m.paths = ["foo", "bar"]

        let m1 = Google_Protobuf_FieldMask(protoPaths: "foo", "bar")
        let m2 = Google_Protobuf_FieldMask(protoPaths: ["foo", "bar"])

        var other = Google_Protobuf_FieldMask()
        other.paths = ["foo", "bar", "baz"]

        XCTAssertEqual(m, m1)
        XCTAssertEqual(m, m2)
        XCTAssertEqual(m1, m2)

        XCTAssertNotEqual(m, other)
        XCTAssertNotEqual(m1, other)
        XCTAssertNotEqual(m2, other)
    }

    // Make sure field mask works correctly when stored in a field
    func testJSON_field() throws {
        do {
            let valid = try SwiftProtoTesting_Test3_TestAllTypesProto3(jsonString: "{\"optionalFieldMask\": \"foo,barBaz\"}")
            XCTAssertEqual(valid.optionalFieldMask, Google_Protobuf_FieldMask(protoPaths: "foo", "bar_baz"))
        } catch {
            XCTFail("Should have decoded correctly")
        }

        // https://github.com/protocolbuffers/protobuf/issues/4734 resulted in a new conformance
        // test to confirm an empty string works.
        do {
            let valid = try SwiftProtoTesting_Test3_TestAllTypesProto3(jsonString: "{\"optionalFieldMask\": \"\"}")
            XCTAssertEqual(valid.optionalFieldMask, Google_Protobuf_FieldMask())
        } catch {
            XCTFail("Should have decoded correctly")
        }

        XCTAssertThrowsError(try SwiftProtoTesting_Test3_TestAllTypesProto3(jsonString: "{\"optionalFieldMask\": \"foo,bar_bar\"}"))
    }

    func testSerializationFailure() {
        // If the proto fieldname can't be converted to a JSON field name,
        // then JSON serialization should fail:
        let cases = ["foo_3_bar", "foo__bar", "fooBar", "☹️", "ȟìĳ"]
        for c in cases {
            let m = Google_Protobuf_FieldMask(protoPaths: c)
            XCTAssertThrowsError(try m.jsonString())
        }
    }
    
    // Checks merge functionality for field masks.
    func testMergeFieldsOfMessage() throws {
        var message = SwiftProtoTesting_TestAllTypes.with { model in
            model.optionalInt32 = 1
            model.optionalNestedMessage = .with { nested in
                nested.bb = 2
            }
        }

        let secondMessage = SwiftProtoTesting_TestAllTypes.with { model in
            model.optionalInt32 = 2
            model.optionalNestedMessage = .with { nested in
                nested.bb = 3
            }
        }

        // Checks nested message merge
        try message.merge(to: secondMessage, fieldMask: .init(protoPaths: "optional_nested_message.bb"))
        XCTAssertEqual(message.optionalInt32, 1)
        XCTAssertEqual(message.optionalNestedMessage.bb, 3)

        // Checks primitive type merge
        try message.merge(to: secondMessage, fieldMask: .init(protoPaths: "optional_int32"))
        XCTAssertEqual(message.optionalInt32, 2)
        XCTAssertEqual(message.optionalNestedMessage.bb, 3)
    }

    // Checks merge functionality for repeated field masks.
    func testMergeRepeatedFieldsOfMessage() throws {
        var message = SwiftProtoTesting_TestAllTypes.with { model in
            model.repeatedInt32 = [1, 2]
        }

        let secondMessage = SwiftProtoTesting_TestAllTypes.with { model in
            model.repeatedInt32 = [3, 4]
        }

        let fieldMask = Google_Protobuf_FieldMask(protoPaths: ["repeated_int32"])

        // Checks without replacing repeated fields
        try message.merge(to: secondMessage, fieldMask: fieldMask)
        XCTAssertEqual(message.repeatedInt32, [1, 2, 3, 4])

        // Checks with replacing repeated fields
        try message.merge(to: secondMessage, fieldMask: fieldMask, mergeOptions: [.replaceRepeatedFields])
        XCTAssertEqual(message.repeatedInt32, [3, 4])
    }

    // Checks trim functionality for field masks.
    func testTrimFieldsOfMessage() throws {
        var message = SwiftProtoTesting_TestAllTypes.with { model in
            model.optionalInt32 = 1
            model.optionalNestedMessage = .with { nested in
                nested.bb = 2
            }
        }

        // Checks trim to be successful.
        let r1 = message.trim(fieldMask: .init(protoPaths: "optional_nested_message.bb"))
        XCTAssertTrue(r1)
        XCTAssertEqual(message.optionalInt32, 0)
        XCTAssertEqual(message.optionalNestedMessage.bb, 2)

        // Checks trim should does nothing with an empty fieldMask.
        let r2 = message.trim(fieldMask: .init())
        XCTAssertFalse(r2)

        // Checks trim should return false if nothing has been changed.
        let r3 = message.trim(fieldMask: .init(protoPaths: "optional_nested_message.bb"))
        XCTAssertFalse(r3)

        // Checks trim to be unsuccessful with an invalid fieldMask.
        let r4 = message.trim(fieldMask: .init(protoPaths: "invalid_path"))
        XCTAssertFalse(r4)
    }

    // Checks `isPathValid` func
    // 1. Valid primitive path should be valid.
    // 2. Valid nested path should be valid.
    // 3. Invalid primitive path should be valid.
    // 4. Invalid nested path should be valid.
    func testIsPathValid() {
        XCTAssertTrue(SwiftProtoTesting_TestAllTypes.isPathValid("optional_int32"))
        XCTAssertTrue(SwiftProtoTesting_TestAllTypes.isPathValid("optional_nested_message.bb"))
        XCTAssertFalse(SwiftProtoTesting_TestAllTypes.isPathValid("optional_int"))
        XCTAssertFalse(SwiftProtoTesting_TestAllTypes.isPathValid("optional_nested_message.bc"))
    }

    // Checks `isValid` func of FieldMask.
    // 1. Empty field mask is always valid.
    // 2, 3. Valid field masks.
    // 4, 5. Invalid field masks.
    func testIsFieldMaskValid() {
        let m1 = Google_Protobuf_FieldMask()
        let m2 = Google_Protobuf_FieldMask(protoPaths: [
            "optional_int32",
            "optional_nested_message.bb"
        ])
        let m3 = Google_Protobuf_FieldMask(protoPaths: [
            "optional_int32",
            "optional_nested_message"
        ])
        let m4 = Google_Protobuf_FieldMask(protoPaths: [
            "optional_int32",
            "optional_nested_message.bc"
        ])
        let m5 = Google_Protobuf_FieldMask(protoPaths: [
            "optional_int",
            "optional_nested_message.bb"
        ])
        XCTAssertTrue(m1.isValid(for: SwiftProtoTesting_TestAllTypes.self))
        XCTAssertTrue(m2.isValid(for: SwiftProtoTesting_TestAllTypes.self))
        XCTAssertTrue(m3.isValid(for: SwiftProtoTesting_TestAllTypes.self))
        XCTAssertFalse(m4.isValid(for: SwiftProtoTesting_TestAllTypes.self))
        XCTAssertFalse(m5.isValid(for: SwiftProtoTesting_TestAllTypes.self))
    }

    // Checks canonincal form of field mask.
    // 1. Sub-message with parent in the paths should be excluded.
    // 2. Canonincal form should be sorted.
    // 3. More nested levels of paths with duplicates.
    // 4. Two siblings with their parent should be excluded.
    func testCanonicalFieldMask() {
        let m1 = Google_Protobuf_FieldMask(protoPaths: ["a.b", "a", "b"])
        XCTAssertEqual(m1.canonical.paths, ["a", "b"])
        let m2 = Google_Protobuf_FieldMask(protoPaths: ["b", "a"])
        XCTAssertEqual(m2.canonical.paths, ["a", "b"])
        let m3 = Google_Protobuf_FieldMask(protoPaths: ["c", "a.b.c", "a.b", "a.b", "a.b.c.d"])
        XCTAssertEqual(m3.canonical.paths, ["a.b", "c"])
        let m4 = Google_Protobuf_FieldMask(protoPaths: ["a.c", "a", "a.b"])
        XCTAssertEqual(m4.canonical.paths, ["a"])
    }

    // Checks `addPath` func of fieldMask with:
    //  - Valid primitive path should be added.
    //  - Valid nested path should be added.
    //  - Invalid path should throw error.
    func testAddPathToFieldMask() throws {
        var mask = Google_Protobuf_FieldMask()
        XCTAssertNoThrow(try mask.addPath("optional_int32", of: SwiftProtoTesting_TestAllTypes.self))
        XCTAssertEqual(mask.paths, ["optional_int32"])
        XCTAssertNoThrow(try mask.addPath("optional_nested_message.bb", of: SwiftProtoTesting_TestAllTypes.self))
        XCTAssertEqual(mask.paths, ["optional_int32", "optional_nested_message.bb"])
        XCTAssertThrowsError(try mask.addPath("optional_int", of: SwiftProtoTesting_TestAllTypes.self))
    }

    // Check `contains` func of fieldMask.
    // 1. Parent contains sub-message.
    // 2. Path contains itself.
    // 3. Sub-message does not contain its parent.
    // 4. Two different paths does not contain each other.
    // 5. Two different sub-paths does not contain each other.
    func testPathContainsInFieldMask() {
        let m1 = Google_Protobuf_FieldMask(protoPaths: ["a"])
        XCTAssertTrue(m1.contains("a.b"))
        let m2 = Google_Protobuf_FieldMask(protoPaths: ["a"])
        XCTAssertTrue(m2.contains("a"))
        let m3 = Google_Protobuf_FieldMask(protoPaths: ["a.b"])
        XCTAssertFalse(m3.contains("a"))
        let m4 = Google_Protobuf_FieldMask(protoPaths: ["a"])
        XCTAssertFalse(m4.contains("b"))
        let m5 = Google_Protobuf_FieldMask(protoPaths: ["a.b"])
        XCTAssertFalse(m5.contains("a.c"))
    }

    // Checks inits of fieldMask with:
    //  - All fields of a message type.
    //  - Particular field numbers of a message type.
    func testFieldPathMessageInits() throws {
        let m1 = Google_Protobuf_FieldMask(allFieldsOf: SwiftProtoTesting_TestAny.self)
        XCTAssertEqual(m1.paths.sorted(), ["any_value", "int32_value", "repeated_any_value", "text"])
        let m2 = try Google_Protobuf_FieldMask(fieldNumbers: [1, 2], of: SwiftProtoTesting_TestAny.self)
        XCTAssertEqual(m2.paths.sorted(), ["any_value", "int32_value"])
        XCTAssertThrowsError(try Google_Protobuf_FieldMask(fieldNumbers: [10], of: SwiftProtoTesting_TestAny.self))
    }

    // Checks `union` func of fieldMask.
    func testUnionFieldMasks() throws {
        let m1 = Google_Protobuf_FieldMask(protoPaths: ["a", "b"])
        let m2 = Google_Protobuf_FieldMask(protoPaths: ["b", "c"])
        XCTAssertEqual(m1.union(m2).paths, ["a", "b", "c"])

        let m3 = Google_Protobuf_FieldMask(protoPaths: ["a", "b"])
        let m4 = Google_Protobuf_FieldMask(protoPaths: ["c", "d"])
        XCTAssertEqual(m3.union(m4).paths, ["a", "b", "c", "d"])

        let m5 = Google_Protobuf_FieldMask()
        let m6 = Google_Protobuf_FieldMask(protoPaths: ["c", "d"])
        XCTAssertEqual(m5.union(m6).paths, ["c", "d"])

        let m7 = Google_Protobuf_FieldMask(protoPaths: ["a", "b"])
        let m8 = Google_Protobuf_FieldMask(protoPaths: ["a", "b"])
        XCTAssertEqual(m7.union(m8).paths, ["a", "b"])

        let m9 = Google_Protobuf_FieldMask(protoPaths: ["a", "a"])
        let m10 = Google_Protobuf_FieldMask(protoPaths: ["a", "b"])
        XCTAssertEqual(m9.union(m10).paths, ["a", "b"])
    }

    // Checks `intersect` func of fieldMask.
    func testIntersectFieldMasks() throws {
        let m1 = Google_Protobuf_FieldMask(protoPaths: ["a", "b"])
        let m2 = Google_Protobuf_FieldMask(protoPaths: ["b", "c"])
        XCTAssertEqual(m1.intersect(m2).paths, ["b"])

        let m3 = Google_Protobuf_FieldMask(protoPaths: ["a", "b"])
        let m4 = Google_Protobuf_FieldMask(protoPaths: ["c", "d"])
        XCTAssertEqual(m3.intersect(m4).paths, [])

        let m5 = Google_Protobuf_FieldMask()
        let m6 = Google_Protobuf_FieldMask(protoPaths: ["c", "d"])
        XCTAssertEqual(m5.intersect(m6).paths, [])

        let m7 = Google_Protobuf_FieldMask(protoPaths: ["a", "b"])
        let m8 = Google_Protobuf_FieldMask(protoPaths: ["a", "b"])
        XCTAssertEqual(m7.intersect(m8).paths, ["a", "b"])

        let m9 = Google_Protobuf_FieldMask(protoPaths: ["a", "a"])
        let m10 = Google_Protobuf_FieldMask(protoPaths: ["a", "b"])
        XCTAssertEqual(m9.intersect(m10).paths, ["a"])
    }

    // Checks `substract` func of fieldMask.
    func testSubtractFieldMasks() throws {
        let m1 = Google_Protobuf_FieldMask(protoPaths: ["a", "b"])
        let m2 = Google_Protobuf_FieldMask(protoPaths: ["b", "c"])
        XCTAssertEqual(m1.subtract(m2).paths, ["a"])

        let m3 = Google_Protobuf_FieldMask(protoPaths: ["a", "b"])
        let m4 = Google_Protobuf_FieldMask(protoPaths: ["c", "d"])
        XCTAssertEqual(m3.subtract(m4).paths, ["a", "b"])

        let m5 = Google_Protobuf_FieldMask()
        let m6 = Google_Protobuf_FieldMask(protoPaths: ["c", "d"])
        XCTAssertEqual(m5.subtract(m6).paths, [])

        let m7 = Google_Protobuf_FieldMask(protoPaths: ["a", "b"])
        let m8 = Google_Protobuf_FieldMask(protoPaths: ["a", "b"])
        XCTAssertEqual(m7.subtract(m8).paths, [])

        let m9 = Google_Protobuf_FieldMask(protoPaths: ["a", "a"])
        let m10 = Google_Protobuf_FieldMask(protoPaths: ["b"])
        XCTAssertEqual(m9.subtract(m10).paths, ["a"])
    }

}
