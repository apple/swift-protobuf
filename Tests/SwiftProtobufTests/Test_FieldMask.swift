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
    // 2. Valid nested path.
    // 3. Invalid primitive path.
    // 4, 5. Invalid nested path.
    func testIsPathValid() {
        XCTAssertTrue(SwiftProtoTesting_TestAllTypes.isPathValid("optional_int32"))
        XCTAssertTrue(SwiftProtoTesting_TestAllTypes.isPathValid("optional_nested_message.bb"))
        XCTAssertFalse(SwiftProtoTesting_TestAllTypes.isPathValid("optional_int"))
        XCTAssertFalse(SwiftProtoTesting_TestAllTypes.isPathValid("optional_nested_message.bc"))
        XCTAssertFalse(SwiftProtoTesting_TestAllTypes.isPathValid("optional_nested_message.bb.a"))
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
        let mask = Google_Protobuf_FieldMask(protoPaths: ["value"])

        var m1 = Google_Protobuf_DoubleValue(1)
        let m2 = Google_Protobuf_DoubleValue()
        try m1.merge(with: m2, fieldMask: mask)
        XCTAssertEqual(m1.value, m2.value)

        var m3 = Google_Protobuf_FloatValue(1)
        let m4 = Google_Protobuf_FloatValue()
        try m3.merge(with: m4, fieldMask: mask)
        XCTAssertEqual(m3.value, m4.value)

        var m5 = Google_Protobuf_Int64Value(1)
        let m6 = Google_Protobuf_Int64Value()
        try m5.merge(with: m6, fieldMask: mask)
        XCTAssertEqual(m5.value, m6.value)

        var m7 = Google_Protobuf_Int32Value(1)
        let m8 = Google_Protobuf_Int32Value()
        try m7.merge(with: m8, fieldMask: mask)
        XCTAssertEqual(m7.value, m8.value)

        var m9 = Google_Protobuf_UInt64Value(1)
        let m10 = Google_Protobuf_UInt64Value()
        try m9.merge(with: m10, fieldMask: mask)
        XCTAssertEqual(m9.value, m10.value)

        var m11 = Google_Protobuf_UInt32Value(1)
        let m12 = Google_Protobuf_UInt32Value()
        try m11.merge(with: m12, fieldMask: mask)
        XCTAssertEqual(m11.value, m12.value)
        
        var m13 = Google_Protobuf_BoolValue(true)
        let m14 = Google_Protobuf_BoolValue()
        try m13.merge(with: m14, fieldMask: mask)
        XCTAssertEqual(m13.value, m14.value)

        var m15 = Google_Protobuf_StringValue("str")
        let m16 = Google_Protobuf_StringValue()
        try m15.merge(with: m16, fieldMask: mask)
        XCTAssertEqual(m15.value, m16.value)

        var m17 = Google_Protobuf_BytesValue("str".data(using: .utf8) ?? .init())
        let m18 = Google_Protobuf_BytesValue()
        try m17.merge(with: m18, fieldMask: mask)
        XCTAssertEqual(m17.value, m18.value)
    }
}
