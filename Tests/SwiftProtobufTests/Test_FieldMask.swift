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
        try message.merge(with: secondMessage, fieldMask: .init(protoPaths: "optional_nested_message.bb"))
        XCTAssertEqual(message.optionalInt32, 1)
        XCTAssertEqual(message.optionalNestedMessage.bb, 3)

        // Checks primitive type merge
        try message.merge(with: secondMessage, fieldMask: .init(protoPaths: "optional_int32"))
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
        try message.merge(with: secondMessage, fieldMask: fieldMask)
        XCTAssertEqual(message.repeatedInt32, [1, 2, 3, 4])

        // Checks with replacing repeated fields
        var options = Google_Protobuf_FieldMask.MergeOptions()
        options.replaceRepeatedFields = true
        try message.merge(with: secondMessage, fieldMask: fieldMask, mergeOption: options)
        XCTAssertEqual(message.repeatedInt32, [3, 4])
    }

    // Checks merge functionality for map field masks.
    func testMergeMapFieldsOfMessage() throws {
        var message = SwiftProtoTesting_Fuzz_Message.with { model in
            model.mapInt32String = [1: "a", 2: "c"]
        }

        let secondMessage = SwiftProtoTesting_Fuzz_Message.with { model in
            model.mapInt32String = [2: "b"]
        }

        let fieldMask = Google_Protobuf_FieldMask(protoPaths: ["map_int32_string"])

        // Checks without replacing repeated fields
        try message.merge(with: secondMessage, fieldMask: fieldMask)
        XCTAssertEqual(message.mapInt32String, [1: "a", 2: "b"])

        // Checks with replacing repeated fields
        var options = Google_Protobuf_FieldMask.MergeOptions()
        options.replaceRepeatedFields = true
        try message.merge(with: secondMessage, fieldMask: fieldMask, mergeOption: options)
        XCTAssertEqual(message.mapInt32String, [2: "b"])
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

        // Checks trim should do nothing with an empty fieldMask.
        let r2 = message.trim(fieldMask: .init())
        XCTAssertFalse(r2)

        // Checks trim should return false if nothing has been changed.
        let r3 = message.trim(fieldMask: .init(protoPaths: "optional_nested_message.bb"))
        XCTAssertFalse(r3)

        // Checks trim to be unsuccessful with an invalid fieldMask.
        let r4 = message.trim(fieldMask: .init(protoPaths: "invalid_path"))
        XCTAssertFalse(r4)
    }

    // Checks trim functionality for field masks when applies on a extensible message.
    func testTrimFieldsOfMessageWithExtension() throws {
        var message = SwiftProtoTesting_Fuzz_Message()
        message.singularInt32 = 1
        message.SwiftProtoTesting_Fuzz_singularInt32Ext = 1
        let mask = Google_Protobuf_FieldMask(protoPaths: ["singularString"])

        // Checks trim should retain extensions while removes other fields.
        let r1 = message.trim(fieldMask: mask)
        XCTAssertTrue(r1)
        XCTAssertEqual(message.SwiftProtoTesting_Fuzz_singularInt32Ext, .init(1))
        XCTAssertEqual(message.singularInt32, .init(0))

        // Checks trim should do nothing (fields are already removed) and still retain extension fields.
        let r2 = message.trim(fieldMask: mask)
        XCTAssertFalse(r2)
        XCTAssertEqual(message.SwiftProtoTesting_Fuzz_singularInt32Ext, .init(1))
    }

    // Checks `isPathValid` func
    // 1. Valid primitive path.
    // 2, 3. Valid nested path. (for message and group)
    // 4. Invalid primitive path.
    // 5, 6. Invalid nested path.
    // 7, 8. Invalid path after map and repeated.
    // 9. Invalid path after group.
    func testIsPathValid() {
        XCTAssertTrue(SwiftProtoTesting_TestAllTypes.isPathValid("optional_int32"))
        XCTAssertTrue(SwiftProtoTesting_TestAllTypes.isPathValid("optional_nested_message.bb"))
        XCTAssertTrue(SwiftProtoTesting_Fuzz_Message.isPathValid("SingularGroup.group_field"))
        XCTAssertFalse(SwiftProtoTesting_TestAllTypes.isPathValid("optional_int"))
        XCTAssertFalse(SwiftProtoTesting_TestAllTypes.isPathValid("optional_nested_message.bc"))
        XCTAssertFalse(SwiftProtoTesting_TestAllTypes.isPathValid("optional_nested_message.bb.a"))
        XCTAssertFalse(SwiftProtoTesting_TestAllTypes.isPathValid("repeatedInt32.a"))
        XCTAssertFalse(SwiftProtoTesting_Fuzz_Message.isPathValid("map_bool_int32.a"))
        XCTAssertFalse(SwiftProtoTesting_Fuzz_Message.isPathValid("SingularGroup.a"))
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

    // Checks whether all field types could be merged.
    func testMergeAllFields() throws {
        var m1 = SwiftProtoTesting_Fuzz_Message()
        let m2 = SwiftProtoTesting_Fuzz_Message.with { m in
            m.singularInt32 = 1
            m.singularInt64 = 1
            m.singularUint32 = 1
            m.singularUint64 = 1
            m.singularSint32 = 1
            m.singularSint64 = 1
            m.singularFixed32 = 1
            m.singularFixed64 = 1
            m.singularSfixed32 = 1
            m.singularSfixed64 = 1
            m.singularFloat = 1
            m.singularDouble = 1
            m.singularBool = true
            m.singularString = "str"
            m.singularBytes = "str".data(using: .utf8) ?? .init()
            m.singularEnum = .two
            m.singularGroup = .with { $0.groupField = 1 }
            m.singularMessage = .with { $0.singularInt32 = 1 }
            m.repeatedInt32 = [1]
            m.repeatedInt64 = [1]
            m.repeatedUint32 = [1]
            m.repeatedUint64 = [1]
            m.repeatedSint32 = [1]
            m.repeatedSint64 = [1]
            m.repeatedFixed32 = [1]
            m.repeatedFixed64 = [1]
            m.repeatedSfixed32 = [1]
            m.repeatedSfixed64 = [1]
            m.repeatedFloat = [1]
            m.repeatedDouble = [1]
            m.repeatedBool = [true]
            m.repeatedString = ["str"]
            m.repeatedBytes = ["str".data(using: .utf8) ?? .init()]
            m.repeatedEnum = [.two]
            m.repeatedGroup = [.with { $0.groupField = 1 }]
            m.repeatedMessage = [.with { $0.singularInt32 = 1 }]
            m.o = .oneofInt32(1)
            m.repeatedPackedInt32 = [1]
            m.repeatedPackedInt64 = [1]
            m.repeatedPackedUint32 = [1]
            m.repeatedPackedUint64 = [1]
            m.repeatedPackedSint32 = [1]
            m.repeatedPackedSint64 = [1]
            m.repeatedPackedFixed32 = [1]
            m.repeatedPackedFixed64 = [1]
            m.repeatedPackedSfixed32 = [1]
            m.repeatedPackedSfixed64 = [1]
            m.repeatedPackedFloat = [1]
            m.repeatedPackedDouble = [1]
            m.repeatedPackedBool = [true]
            m.repeatedPackedEnum = [.two]
            m.mapInt32Int32 = [1: 1]
            m.mapInt32Int64 = [1: 1]
            m.mapInt32Uint32 = [1: 1]
            m.mapInt32Uint64 = [1: 1]
            m.mapInt32Sint32 = [1: 1]
            m.mapInt32Sint64 = [1: 1]
            m.mapInt32Fixed32 = [1: 1]
            m.mapInt32Fixed64 = [1: 1]
            m.mapInt32AnEnum = [1: .one]
            m.mapInt32Message = [1: .init()]
        }
        try m1.merge(with: m2, fieldMask: .init(allFieldsOf: SwiftProtoTesting_Fuzz_Message.self))
        XCTAssertEqual(m1.singularInt32, m2.singularInt32)
        XCTAssertEqual(m1.singularInt64, m2.singularInt64)
        XCTAssertEqual(m1.singularUint32, m2.singularUint32)
        XCTAssertEqual(m1.singularUint64, m2.singularUint64)
        XCTAssertEqual(m1.singularSint32, m2.singularSint32)
        XCTAssertEqual(m1.singularSint64, m2.singularSint64)
        XCTAssertEqual(m1.singularFixed32, m2.singularFixed32)
        XCTAssertEqual(m1.singularFixed64, m2.singularFixed64)
        XCTAssertEqual(m1.singularSfixed32, m2.singularSfixed32)
        XCTAssertEqual(m1.singularSfixed64, m2.singularSfixed64)
        XCTAssertEqual(m1.singularFloat, m2.singularFloat)
        XCTAssertEqual(m1.singularDouble, m2.singularDouble)
        XCTAssertEqual(m1.singularBool, m2.singularBool)
        XCTAssertEqual(m1.singularString, m2.singularString)
        XCTAssertEqual(m1.singularBytes, m2.singularBytes)
        XCTAssertEqual(m1.singularEnum, m2.singularEnum)
        XCTAssertEqual(m1.singularGroup, m2.singularGroup)
        XCTAssertEqual(m1.singularMessage, m2.singularMessage)
        XCTAssertEqual(m1.repeatedInt32, m2.repeatedInt32)
        XCTAssertEqual(m1.repeatedInt64, m2.repeatedInt64)
        XCTAssertEqual(m1.repeatedUint32, m2.repeatedUint32)
        XCTAssertEqual(m1.repeatedUint64, m2.repeatedUint64)
        XCTAssertEqual(m1.repeatedSint32, m2.repeatedSint32)
        XCTAssertEqual(m1.repeatedSint64, m2.repeatedSint64)
        XCTAssertEqual(m1.repeatedFixed32, m2.repeatedFixed32)
        XCTAssertEqual(m1.repeatedFixed64, m2.repeatedFixed64)
        XCTAssertEqual(m1.repeatedSfixed32, m2.repeatedSfixed32)
        XCTAssertEqual(m1.repeatedSfixed64, m2.repeatedSfixed64)
        XCTAssertEqual(m1.repeatedFloat, m2.repeatedFloat)
        XCTAssertEqual(m1.repeatedDouble, m2.repeatedDouble)
        XCTAssertEqual(m1.repeatedBool, m2.repeatedBool)
        XCTAssertEqual(m1.repeatedString, m2.repeatedString)
        XCTAssertEqual(m1.repeatedBytes, m2.repeatedBytes)
        XCTAssertEqual(m1.repeatedEnum, m2.repeatedEnum)
        XCTAssertEqual(m1.repeatedGroup, m2.repeatedGroup)
        XCTAssertEqual(m1.repeatedMessage, m2.repeatedMessage)
        XCTAssertEqual(m1.o, m2.o)
        XCTAssertEqual(m1.repeatedPackedInt32, m2.repeatedPackedInt32)
        XCTAssertEqual(m1.repeatedPackedInt64, m2.repeatedPackedInt64)
        XCTAssertEqual(m1.repeatedPackedUint32, m2.repeatedPackedUint32)
        XCTAssertEqual(m1.repeatedPackedUint64, m2.repeatedPackedUint64)
        XCTAssertEqual(m1.repeatedPackedSint32, m2.repeatedPackedSint32)
        XCTAssertEqual(m1.repeatedPackedSint64, m2.repeatedPackedSint64)
        XCTAssertEqual(m1.repeatedPackedFixed32, m2.repeatedPackedFixed32)
        XCTAssertEqual(m1.repeatedPackedFixed64, m2.repeatedPackedFixed64)
        XCTAssertEqual(m1.repeatedPackedSfixed32, m2.repeatedPackedSfixed32)
        XCTAssertEqual(m1.repeatedPackedSfixed64, m2.repeatedPackedSfixed64)
        XCTAssertEqual(m1.repeatedPackedFloat, m2.repeatedPackedFloat)
        XCTAssertEqual(m1.repeatedPackedDouble, m2.repeatedPackedDouble)
        XCTAssertEqual(m1.repeatedPackedBool, m2.repeatedPackedBool)
        XCTAssertEqual(m1.repeatedPackedEnum, m2.repeatedPackedEnum)
        XCTAssertEqual(m1.mapInt32Int32, m2.mapInt32Int32)
        XCTAssertEqual(m1.mapInt32Int64, m2.mapInt32Int64)
        XCTAssertEqual(m1.mapInt32Uint32, m2.mapInt32Uint32)
        XCTAssertEqual(m1.mapInt32Uint64, m2.mapInt32Uint64)
        XCTAssertEqual(m1.mapInt32Sint32, m2.mapInt32Sint32)
        XCTAssertEqual(m1.mapInt32Sint64, m2.mapInt32Sint64)
        XCTAssertEqual(m1.mapInt32Fixed32, m2.mapInt32Fixed32)
        XCTAssertEqual(m1.mapInt32Fixed64, m2.mapInt32Fixed64)
        XCTAssertEqual(m1.mapInt32AnEnum, m2.mapInt32AnEnum)
        XCTAssertEqual(m1.mapInt32Message, m2.mapInt32Message)
    }

    // Checks whether a group of fields could be merged without merging the others.
    func testMergeFieldsPartially() throws {
        var m1 = SwiftProtoTesting_Fuzz_Message()
        let m2 = SwiftProtoTesting_Fuzz_Message.with { m in
            m.singularInt32 = 1
            m.singularInt64 = 1
            m.singularUint32 = 1
            m.singularUint64 = 1
            m.singularSint32 = 1
            m.singularSint64 = 1
            m.singularFixed32 = 1
            m.singularFixed64 = 1
            m.singularSfixed32 = 1
            m.singularSfixed64 = 1
            m.singularFloat = 1
            m.singularDouble = 1
            m.singularBool = true
            m.singularString = "str"
            m.singularBytes = "str".data(using: .utf8) ?? .init()
            m.singularEnum = .two
            m.singularGroup = .with { $0.groupField = 1 }
            m.singularMessage = .with { $0.singularInt32 = 1 }
            m.repeatedInt32 = [1]
            m.repeatedInt64 = [1]
            m.repeatedUint32 = [1]
            m.repeatedUint64 = [1]
            m.repeatedSint32 = [1]
            m.repeatedSint64 = [1]
            m.repeatedFixed32 = [1]
            m.repeatedFixed64 = [1]
            m.repeatedSfixed32 = [1]
            m.repeatedSfixed64 = [1]
            m.repeatedFloat = [1]
            m.repeatedDouble = [1]
            m.repeatedBool = [true]
            m.repeatedString = ["str"]
            m.repeatedBytes = ["str".data(using: .utf8) ?? .init()]
            m.repeatedEnum = [.two]
            m.repeatedGroup = [.with { $0.groupField = 1 }]
            m.repeatedMessage = [.with { $0.singularInt32 = 1 }]
            m.o = .oneofInt32(1)
            m.repeatedPackedInt32 = [1]
            m.repeatedPackedInt64 = [1]
            m.repeatedPackedUint32 = [1]
            m.repeatedPackedUint64 = [1]
            m.repeatedPackedSint32 = [1]
            m.repeatedPackedSint64 = [1]
            m.repeatedPackedFixed32 = [1]
            m.repeatedPackedFixed64 = [1]
            m.repeatedPackedSfixed32 = [1]
            m.repeatedPackedSfixed64 = [1]
            m.repeatedPackedFloat = [1]
            m.repeatedPackedDouble = [1]
            m.repeatedPackedBool = [true]
            m.repeatedPackedEnum = [.two]
            m.mapInt32Int32 = [1: 1]
            m.mapInt32Int64 = [1: 1]
            m.mapInt32Uint32 = [1: 1]
            m.mapInt32Uint64 = [1: 1]
            m.mapInt32Sint32 = [1: 1]
            m.mapInt32Sint64 = [1: 1]
            m.mapInt32Fixed32 = [1: 1]
            m.mapInt32Fixed64 = [1: 1]
            m.mapInt32AnEnum = [1: .one]
            m.mapInt32Message = [1: .init()]
        }
        let mask = Google_Protobuf_FieldMask(protoPaths: [
            "singular_int32",
            "singular_int64",
            "singular_uint32",
            "singular_uint64",
            "singular_sint32",
            "singular_sint64",
            "singular_fixed32",
            "singular_fixed64",
            "singular_sfixed32",
            "singular_sfixed64"
        ])
        try m1.merge(with: m2, fieldMask: mask)
        XCTAssertEqual(m1.singularInt32, m2.singularInt32)
        XCTAssertEqual(m1.singularInt64, m2.singularInt64)
        XCTAssertEqual(m1.singularUint32, m2.singularUint32)
        XCTAssertEqual(m1.singularUint64, m2.singularUint64)
        XCTAssertEqual(m1.singularSint32, m2.singularSint32)
        XCTAssertEqual(m1.singularSint64, m2.singularSint64)
        XCTAssertEqual(m1.singularFixed32, m2.singularFixed32)
        XCTAssertEqual(m1.singularFixed64, m2.singularFixed64)
        XCTAssertEqual(m1.singularSfixed32, m2.singularSfixed32)
        XCTAssertEqual(m1.singularSfixed64, m2.singularSfixed64)
        XCTAssertNotEqual(m1.singularFloat, m2.singularFloat)
        XCTAssertNotEqual(m1.singularDouble, m2.singularDouble)
        XCTAssertNotEqual(m1.singularBool, m2.singularBool)
        XCTAssertNotEqual(m1.singularString, m2.singularString)
        XCTAssertNotEqual(m1.singularBytes, m2.singularBytes)
        XCTAssertNotEqual(m1.singularEnum, m2.singularEnum)
        XCTAssertNotEqual(m1.singularGroup, m2.singularGroup)
        XCTAssertNotEqual(m1.singularMessage, m2.singularMessage)
        XCTAssertNotEqual(m1.repeatedInt32, m2.repeatedInt32)
        XCTAssertNotEqual(m1.repeatedInt64, m2.repeatedInt64)
        XCTAssertNotEqual(m1.repeatedUint32, m2.repeatedUint32)
        XCTAssertNotEqual(m1.repeatedUint64, m2.repeatedUint64)
        XCTAssertNotEqual(m1.repeatedSint32, m2.repeatedSint32)
        XCTAssertNotEqual(m1.repeatedSint64, m2.repeatedSint64)
        XCTAssertNotEqual(m1.repeatedFixed32, m2.repeatedFixed32)
        XCTAssertNotEqual(m1.repeatedFixed64, m2.repeatedFixed64)
        XCTAssertNotEqual(m1.repeatedSfixed32, m2.repeatedSfixed32)
        XCTAssertNotEqual(m1.repeatedSfixed64, m2.repeatedSfixed64)
        XCTAssertNotEqual(m1.repeatedFloat, m2.repeatedFloat)
        XCTAssertNotEqual(m1.repeatedDouble, m2.repeatedDouble)
        XCTAssertNotEqual(m1.repeatedBool, m2.repeatedBool)
        XCTAssertNotEqual(m1.repeatedString, m2.repeatedString)
        XCTAssertNotEqual(m1.repeatedBytes, m2.repeatedBytes)
        XCTAssertNotEqual(m1.repeatedEnum, m2.repeatedEnum)
        XCTAssertNotEqual(m1.repeatedGroup, m2.repeatedGroup)
        XCTAssertNotEqual(m1.repeatedMessage, m2.repeatedMessage)
        XCTAssertNotEqual(m1.o, m2.o)
        XCTAssertNotEqual(m1.repeatedPackedInt32, m2.repeatedPackedInt32)
        XCTAssertNotEqual(m1.repeatedPackedInt64, m2.repeatedPackedInt64)
        XCTAssertNotEqual(m1.repeatedPackedUint32, m2.repeatedPackedUint32)
        XCTAssertNotEqual(m1.repeatedPackedUint64, m2.repeatedPackedUint64)
        XCTAssertNotEqual(m1.repeatedPackedSint32, m2.repeatedPackedSint32)
        XCTAssertNotEqual(m1.repeatedPackedSint64, m2.repeatedPackedSint64)
        XCTAssertNotEqual(m1.repeatedPackedFixed32, m2.repeatedPackedFixed32)
        XCTAssertNotEqual(m1.repeatedPackedFixed64, m2.repeatedPackedFixed64)
        XCTAssertNotEqual(m1.repeatedPackedSfixed32, m2.repeatedPackedSfixed32)
        XCTAssertNotEqual(m1.repeatedPackedSfixed64, m2.repeatedPackedSfixed64)
        XCTAssertNotEqual(m1.repeatedPackedFloat, m2.repeatedPackedFloat)
        XCTAssertNotEqual(m1.repeatedPackedDouble, m2.repeatedPackedDouble)
        XCTAssertNotEqual(m1.repeatedPackedBool, m2.repeatedPackedBool)
        XCTAssertNotEqual(m1.repeatedPackedEnum, m2.repeatedPackedEnum)
        XCTAssertNotEqual(m1.mapInt32Int32, m2.mapInt32Int32)
        XCTAssertNotEqual(m1.mapInt32Int64, m2.mapInt32Int64)
        XCTAssertNotEqual(m1.mapInt32Uint32, m2.mapInt32Uint32)
        XCTAssertNotEqual(m1.mapInt32Uint64, m2.mapInt32Uint64)
        XCTAssertNotEqual(m1.mapInt32Sint32, m2.mapInt32Sint32)
        XCTAssertNotEqual(m1.mapInt32Sint64, m2.mapInt32Sint64)
        XCTAssertNotEqual(m1.mapInt32Fixed32, m2.mapInt32Fixed32)
        XCTAssertNotEqual(m1.mapInt32Fixed64, m2.mapInt32Fixed64)
        XCTAssertNotEqual(m1.mapInt32AnEnum, m2.mapInt32AnEnum)
        XCTAssertNotEqual(m1.mapInt32Message, m2.mapInt32Message)
    }

    // Checks merge could be done for an optional path with nil value.
    func testMergeOptionalValue() throws {
        var m1 = SwiftProtoTesting_Fuzz_Message.with { m in
            m.singularInt32 = 1
        }
        let m2 = SwiftProtoTesting_Fuzz_Message()
        try m1.merge(with: m2, fieldMask: .init(protoPaths: ["singular_int32"]))
        XCTAssertEqual(m1.singularInt32, m2.singularInt32)
    }

    // Checks merge could be done for an optional path with default value.
    func testMergeDefaultValue() throws {
        var m1 = SwiftProtoTesting_TestAllTypes.with { m in
            m.defaultInt32 = 1
        }
        let m2 = SwiftProtoTesting_TestAllTypes()
        try m1.merge(with: m2, fieldMask: .init(protoPaths: ["default_int32"]))
        XCTAssertEqual(m1.defaultInt32, m2.defaultInt32)
    }

    // Checks merge could be done for non-optional paths.
    func testMergeNonOptionalValues() throws {
        var m1 = try SwiftProtoTesting_Proto3_TestAllTypes.with { m in
            m.optionalInt32 = 1
            m.optionalInt64 = 1
            m.optionalDouble = 1
            m.optionalFloat = 1
            m.optionalString = "str"
            m.optionalBool = true
            m.optionalBytes = try XCTUnwrap("str".data(using: .utf8))
            m.optionalUint32 = 1
            m.optionalUint64 = 1
            m.optionalSint32 = 1
            m.optionalSint64 = 1
            m.optionalFixed32 = 1
            m.optionalFixed64 = 1
            m.optionalSfixed32 = 1
            m.optionalSfixed64 = 1
            m.optionalNestedEnum = .bar
        }
        let m2 = SwiftProtoTesting_Proto3_TestAllTypes()
        try m1.merge(with: m2, fieldMask: .init(protoPaths: [
            "optional_int32",
            "optional_int64",
            "optional_double",
            "optional_float",
            "optional_string",
            "optional_bool",
            "optional_bytes",
            "optional_uint32",
            "optional_uint64",
            "optional_sint32",
            "optional_sint64",
            "optional_fixed32",
            "optional_fixed64",
            "optional_sfixed32",
            "optional_sfixed64",
            "optional_nested_enum"
        ]))
        XCTAssertEqual(m1.optionalInt32, m2.optionalInt32)
        XCTAssertEqual(m1.optionalInt64, m2.optionalInt64)
        XCTAssertEqual(m1.optionalDouble, m2.optionalDouble)
        XCTAssertEqual(m1.optionalFloat, m2.optionalFloat)
        XCTAssertEqual(m1.optionalString, m2.optionalString)
        XCTAssertEqual(m1.optionalBool, m2.optionalBool)
        XCTAssertEqual(m1.optionalBytes, m2.optionalBytes)
        XCTAssertEqual(m1.optionalUint32, m2.optionalUint32)
        XCTAssertEqual(m1.optionalUint64, m2.optionalUint64)
        XCTAssertEqual(m1.optionalSint32, m2.optionalSint32)
        XCTAssertEqual(m1.optionalSint64, m2.optionalSint64)
        XCTAssertEqual(m1.optionalFixed32, m2.optionalFixed32)
        XCTAssertEqual(m1.optionalFixed64, m2.optionalFixed64)
        XCTAssertEqual(m1.optionalSfixed32, m2.optionalSfixed32)
        XCTAssertEqual(m1.optionalSfixed64, m2.optionalSfixed64)
        XCTAssertEqual(m1.optionalNestedEnum, m2.optionalNestedEnum)
        XCTAssertEqual(m1.optionalSint32, m2.optionalSint32)
    }

    // Checks if merge works with nested proto messages
    func testMergeNestedMessages() throws {
        var m1 = SwiftProtoTesting_Fuzz_Message()
        let m2 = SwiftProtoTesting_Fuzz_Message.with { m in
            m.singularMessage = .with { _m in
                _m.singularMessage = .with { __m in
                    __m.singularInt32 = 1
                }
            }
        }
        let m3 = SwiftProtoTesting_Fuzz_Message.with { m in
            m.singularMessage = .with { _m in
                _m.singularMessage = .with { __m in
                    __m.singularInt32 = 2
                }
            }
        }
        try m1.merge(with: m2, fieldMask: .init(protoPaths: ["singular_message.singular_message"]))
        XCTAssertEqual(m1.singularMessage.singularMessage.singularInt32, Int32(1))
        try m1.merge(with: m3, fieldMask: .init(protoPaths: ["singular_message.singular_message.singular_int32"]))
        XCTAssertEqual(m1.singularMessage.singularMessage.singularInt32, Int32(2))
    }

    // Checks merging nested path inside groups
    func testMergeNestedGroups() throws {
        var m1 = SwiftProtoTesting_Fuzz_Message()
        let m2 = SwiftProtoTesting_Fuzz_Message.with { m in
            m.singularGroup = .with { _m in
                _m.groupField = 1
            }
        }
        try m1.merge(with: m2, fieldMask: .init(protoPaths: ["SingularGroup.group_field"]))
        XCTAssertEqual(m1.singularGroup.groupField, m2.singularGroup.groupField)
    }
}
