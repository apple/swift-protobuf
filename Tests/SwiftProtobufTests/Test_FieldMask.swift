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
import SwiftProtobuf
import XCTest

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
        assertJSONDecodeFails("\"H̱ܻ̻ܻ̻ܶܶAܻD\"")  // Reject non-ASCII
        assertJSONDecodeFails("abc_def")  // Reject underscores
        // Reject characters outside [A-Za-z0-9.] in a path segment, matching the
        // upstream parser ("unexpected character in FieldMask").
        assertJSONDecodeFails("\"foo-bar\"")
        assertJSONDecodeFails("\"foo/bar\"")
        assertJSONDecodeFails("\"foo!bar\"")
        assertJSONDecodeFails("\"foo~bar\"")
        assertJSONDecodeFails("\"foo@bar\"")
        assertJSONDecodeFails("\"foo bar\"")
        assertJSONDecodeFails("\"foo(bar)\"")
        assertJSONDecodeFails("\"(foo.bar)\"")
        assertJSONDecodeFails("\"foo(\"")
        assertJSONDecodeFails("\"foo)\"")
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

    #if FieldMaskUtilities

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

        let j1 = Google_Protobuf_FieldMask(jsonPaths: "foo", "barBaz", "foo.barBaz")
        XCTAssertEqual(j1, Google_Protobuf_FieldMask(protoPaths: "foo", "bar_baz", "foo.bar_baz"))

        let jEmpty = Google_Protobuf_FieldMask.init(jsonPaths:)()
        XCTAssertEqual(jEmpty, Google_Protobuf_FieldMask())

        XCTAssertNil(Google_Protobuf_FieldMask(jsonPaths: "foo_bar"))
        XCTAssertNil(Google_Protobuf_FieldMask(jsonPaths: "foo(bar)"))
        XCTAssertNil(Google_Protobuf_FieldMask(jsonPaths: "(foo.bar)"))
        XCTAssertNil(Google_Protobuf_FieldMask(jsonPaths: "foo("))
        XCTAssertNil(Google_Protobuf_FieldMask(jsonPaths: "foo)"))
        XCTAssertNil(Google_Protobuf_FieldMask(jsonPaths: "foo-bar"))
        XCTAssertNil(Google_Protobuf_FieldMask(jsonPaths: "foo,bar"))
        XCTAssertNil(Google_Protobuf_FieldMask(jsonPaths: ""))
        XCTAssertNil(Google_Protobuf_FieldMask(jsonPaths: "foo", "bar_baz"))
        XCTAssertNil(Google_Protobuf_FieldMask(jsonPaths: "foo_bar", "baz"))
    }

    // Make sure field mask works correctly when stored in a field
    func testJSON_field() throws {
        do {
            let valid = try SwiftProtoTesting_Test3_TestAllTypesProto3(
                jsonString: "{\"optionalFieldMask\": \"foo,barBaz\"}"
            )
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

        XCTAssertThrowsError(
            try SwiftProtoTesting_Test3_TestAllTypesProto3(jsonString: "{\"optionalFieldMask\": \"foo,bar_bar\"}")
        )
    }

    func testSerializationFailure() {
        // If the proto fieldname can't be converted to a JSON field name,
        // then JSON serialization should fail. This includes a path holding the
        // ',' separator, which otherwise round-trips into two separate paths.
        let cases = [
            "foo_3_bar",
            "foo__bar",
            "fooBar",
            "☹️",
            "ȟìĳ",
            "foo,bar",
            "foo-bar",
            "foo/bar",
            "foo(bar)",
            "(foo.bar)",
            "foo(",
            "foo)",
            "",
        ]
        for c in cases {
            let m = Google_Protobuf_FieldMask(protoPaths: c)
            XCTAssertThrowsError(try m.jsonString())
        }
        // An empty path element alongside valid paths must also fail to serialize.
        let mixedEmpty = Google_Protobuf_FieldMask(protoPaths: "foo", "")
        XCTAssertThrowsError(try mixedEmpty.jsonString())
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
        try message.merge(from: secondMessage, fieldMask: .init(protoPaths: "optional_nested_message.bb"))
        XCTAssertEqual(message.optionalInt32, 1)
        XCTAssertEqual(message.optionalNestedMessage.bb, 3)

        // Checks primitive type merge
        try message.merge(from: secondMessage, fieldMask: .init(protoPaths: "optional_int32"))
        XCTAssertEqual(message.optionalInt32, 2)
        XCTAssertEqual(message.optionalNestedMessage.bb, 3)
    }

    // A singular message field named directly by the mask should not be
    // cleared when the source does not set it. The default merge behavior
    // skips an unset singular message field, leaving the destination intact.
    func testMergeUnsetMessageFieldOfMessage() throws {
        var message = SwiftProtoTesting_TestAllTypes.with { model in
            model.optionalInt32 = 1
            model.optionalNestedMessage = .with { nested in
                nested.bb = 2
            }
        }

        let secondMessage = SwiftProtoTesting_TestAllTypes.with { model in
            model.optionalInt32 = 5
        }

        // The mask covers the message field, but the source leaves it unset,
        // so the destination keeps its existing value.
        try message.merge(
            from: secondMessage,
            fieldMask: .init(protoPaths: "optional_int32", "optional_nested_message")
        )
        XCTAssertEqual(message.optionalInt32, 5)
        XCTAssertTrue(message.hasOptionalNestedMessage)
        XCTAssertEqual(message.optionalNestedMessage.bb, 2)

        // When the source does set the message field, it merges into the
        // destination value.
        let thirdMessage = SwiftProtoTesting_TestAllTypes.with { model in
            model.optionalNestedMessage = .with { nested in
                nested.bb = 7
            }
        }
        try message.merge(from: thirdMessage, fieldMask: .init(protoPaths: "optional_nested_message"))
        XCTAssertEqual(message.optionalNestedMessage.bb, 7)
    }

    // Mirrors C++ FieldMaskUtilTest.MergeMessage MergeOptions checks.
    func testMergeMessageFieldOptions() throws {
        var nestedSrc = SwiftProtoTesting_NestedTestAllTypes.with {
            $0.child.payload.optionalInt32 = 1234
        }
        var nestedDst = SwiftProtoTesting_NestedTestAllTypes.with {
            $0.child.payload.optionalInt64 = 4321
        }
        var options = Google_Protobuf_FieldMask.MergeOptions()

        // Message fields are merged by default, preserving destination-only fields.
        let childPayloadMask = Google_Protobuf_FieldMask(protoPaths: "child.payload")
        try nestedDst.merge(from: nestedSrc, fieldMask: childPayloadMask, mergeOption: options)
        XCTAssertEqual(nestedDst.child.payload.optionalInt32, 1234)
        XCTAssertEqual(nestedDst.child.payload.optionalInt64, 4321)
        XCTAssertTrue(nestedDst.child.payload.hasOptionalInt64)

        // Setting replaceMessageFields replaces the destination submessage instead.
        options.replaceMessageFields = true
        try nestedDst.merge(from: nestedSrc, fieldMask: childPayloadMask, mergeOption: options)
        XCTAssertEqual(nestedDst.child.payload.optionalInt32, 1234)
        XCTAssertEqual(nestedDst.child.payload.optionalInt64, 0)
        XCTAssertFalse(nestedDst.child.payload.hasOptionalInt64)

        // By default, message fields missing in source are not cleared in destination.
        let payloadMask = Google_Protobuf_FieldMask(protoPaths: "payload")
        options.replaceMessageFields = false
        nestedDst.payload = .with { $0.optionalInt64 = 4321 }
        XCTAssertTrue(nestedDst.hasPayload)
        try nestedDst.merge(from: nestedSrc, fieldMask: payloadMask, mergeOption: options)
        XCTAssertTrue(nestedDst.hasPayload)
        XCTAssertEqual(nestedDst.payload.optionalInt64, 4321)

        // Unset message fields in source are cleared when replaceMessageFields is true.
        options.replaceMessageFields = true
        nestedDst = SwiftProtoTesting_NestedTestAllTypes()
        nestedDst.payload = .with { $0.optionalInt64 = 4321 }
        try nestedDst.merge(from: nestedSrc, fieldMask: payloadMask, mergeOption: options)
        XCTAssertFalse(nestedDst.hasPayload)

        // A present empty source submessage preserves destination fields by default,
        // and replaces with a present empty submessage when replaceMessageFields is true.
        let emptyPayloadSrc = SwiftProtoTesting_NestedTestAllTypes.with {
            $0.payload = SwiftProtoTesting_TestAllTypes()
        }
        nestedDst = SwiftProtoTesting_NestedTestAllTypes.with {
            $0.payload.optionalInt64 = 4321
        }
        options.replaceMessageFields = false
        try nestedDst.merge(from: emptyPayloadSrc, fieldMask: payloadMask, mergeOption: options)
        XCTAssertTrue(nestedDst.hasPayload)
        XCTAssertEqual(nestedDst.payload.optionalInt64, 4321)

        options.replaceMessageFields = true
        try nestedDst.merge(from: emptyPayloadSrc, fieldMask: payloadMask, mergeOption: options)
        XCTAssertTrue(nestedDst.hasPayload)
        XCTAssertFalse(nestedDst.payload.hasOptionalInt64)
        XCTAssertEqual(nestedDst.payload.optionalInt64, 0)

        // Explicit repeated field paths append by default (even with replaceMessageFields)
        // and replace when replaceRepeatedFields is true.
        nestedSrc.payload.repeatedInt32 = [1234]
        nestedDst = SwiftProtoTesting_NestedTestAllTypes.with {
            $0.payload.repeatedInt32 = [5678]
        }
        let repeatedMask = Google_Protobuf_FieldMask(protoPaths: "payload.repeated_int32")
        try nestedDst.merge(from: nestedSrc, fieldMask: repeatedMask, mergeOption: options)
        XCTAssertEqual(nestedDst.payload.repeatedInt32, [5678, 1234])

        options.replaceRepeatedFields = true
        try nestedDst.merge(from: nestedSrc, fieldMask: repeatedMask, mergeOption: options)
        XCTAssertEqual(nestedDst.payload.repeatedInt32, [1234])
    }

    // Inner repeated and map fields inside a masked leaf submessage follow
    // protobuf MergeFrom semantics (appending repeated fields and merging maps)
    // unless replaceMessageFields replaces the whole submessage.
    func testMergeLeafMessageInnerRepeatedAndMapFields() throws {
        let src = SwiftProtoTesting_Fuzz_Message.with {
            $0.singularMessage = .with {
                $0.singularInt32 = 20
                $0.repeatedInt32 = [3, 4]
                $0.mapInt32String = [2: "src", 3: "c"]
            }
        }
        let initialDst = SwiftProtoTesting_Fuzz_Message.with {
            $0.singularMessage = .with {
                $0.singularInt64 = 10
                $0.repeatedInt32 = [1, 2]
                $0.mapInt32String = [1: "a", 2: "dst"]
            }
        }
        let mask = Google_Protobuf_FieldMask(protoPaths: "singular_message")

        var defaultDst = initialDst
        try defaultDst.merge(from: src, fieldMask: mask)
        XCTAssertEqual(defaultDst.singularMessage.singularInt32, 20)
        XCTAssertEqual(defaultDst.singularMessage.singularInt64, 10)
        XCTAssertEqual(defaultDst.singularMessage.repeatedInt32, [1, 2, 3, 4])
        XCTAssertEqual(defaultDst.singularMessage.mapInt32String, [1: "a", 2: "src", 3: "c"])

        // replaceRepeatedFields does not override MergeFrom on inner fields of
        // an unmasked leaf submessage (matching C++ FieldMaskUtil::MergeMessageTo).
        var replaceRepeatedDst = initialDst
        var replaceRepeatedOptions = Google_Protobuf_FieldMask.MergeOptions()
        replaceRepeatedOptions.replaceRepeatedFields = true
        try replaceRepeatedDst.merge(
            from: src,
            fieldMask: mask,
            mergeOption: replaceRepeatedOptions
        )
        XCTAssertEqual(replaceRepeatedDst.singularMessage.singularInt32, 20)
        XCTAssertEqual(replaceRepeatedDst.singularMessage.singularInt64, 10)
        XCTAssertEqual(replaceRepeatedDst.singularMessage.repeatedInt32, [1, 2, 3, 4])
        XCTAssertEqual(replaceRepeatedDst.singularMessage.mapInt32String, [1: "a", 2: "src", 3: "c"])

        // replaceMessageFields replaces the entire leaf submessage.
        var replaceMessageDst = initialDst
        var replaceMessageOptions = Google_Protobuf_FieldMask.MergeOptions()
        replaceMessageOptions.replaceMessageFields = true
        try replaceMessageDst.merge(
            from: src,
            fieldMask: mask,
            mergeOption: replaceMessageOptions
        )
        XCTAssertEqual(replaceMessageDst.singularMessage.singularInt32, 20)
        XCTAssertFalse(replaceMessageDst.singularMessage.hasSingularInt64)
        XCTAssertEqual(replaceMessageDst.singularMessage.repeatedInt32, [3, 4])
        XCTAssertEqual(replaceMessageDst.singularMessage.mapInt32String, [2: "src", 3: "c"])
    }

    // Decoded extensions on leaf submessages (and nested submessages / MessageSets)
    // must remain decoded extensions rather than turning into unknown fields.
    func testMergeLeafMessagePreservesDecodedExtensions() throws {
        let src = SwiftProtoTesting_Fuzz_Message.with {
            $0.singularMessage = .with {
                $0.SwiftProtoTesting_Fuzz_singularInt32Ext = 2
                $0.SwiftProtoTesting_Fuzz_singularInt64Ext = 3
                $0.SwiftProtoTesting_Fuzz_repeatedInt32Ext = [20]
                $0.SwiftProtoTesting_Fuzz_singularMessageExt = .with {
                    $0.singularInt32 = 200
                    $0.SwiftProtoTesting_Fuzz_singularStringExt = "nested"
                }
                $0.mapInt32Message[1] = .with {
                    $0.SwiftProtoTesting_Fuzz_singularInt32Ext = 99
                }
                $0.singularMessageSet = .with {
                    $0.SwiftProtoTesting_Fuzz_AMessageSetMessageExtension2_messageSetExtension.anInt32 = 42
                }
            }
        }
        let initialDst = SwiftProtoTesting_Fuzz_Message.with {
            $0.singularMessage = .with {
                $0.SwiftProtoTesting_Fuzz_singularInt32Ext = 1
                $0.SwiftProtoTesting_Fuzz_singularStringExt = "dst"
                $0.SwiftProtoTesting_Fuzz_repeatedInt32Ext = [10]
                $0.SwiftProtoTesting_Fuzz_singularMessageExt = .with {
                    $0.singularInt64 = 100
                }
                $0.singularMessageSet = .with {
                    $0.SwiftProtoTesting_Fuzz_AMessageSetMessageExtension1_messageSetExtension.aString = "dst"
                }
            }
        }
        let mask = Google_Protobuf_FieldMask(protoPaths: "singular_message")

        var mergedDst = initialDst
        try mergedDst.merge(from: src, fieldMask: mask)
        let mergedSub = mergedDst.singularMessage
        XCTAssertEqual(mergedSub.SwiftProtoTesting_Fuzz_singularInt32Ext, 2)
        XCTAssertEqual(mergedSub.SwiftProtoTesting_Fuzz_singularInt64Ext, 3)
        XCTAssertEqual(mergedSub.SwiftProtoTesting_Fuzz_singularStringExt, "dst")
        XCTAssertEqual(mergedSub.SwiftProtoTesting_Fuzz_repeatedInt32Ext, [10, 20])
        XCTAssertEqual(mergedSub.SwiftProtoTesting_Fuzz_singularMessageExt.singularInt64, 100)
        XCTAssertEqual(mergedSub.SwiftProtoTesting_Fuzz_singularMessageExt.singularInt32, 200)
        XCTAssertEqual(
            mergedSub.SwiftProtoTesting_Fuzz_singularMessageExt.SwiftProtoTesting_Fuzz_singularStringExt,
            "nested"
        )
        XCTAssertEqual(mergedSub.mapInt32Message[1]?.SwiftProtoTesting_Fuzz_singularInt32Ext, 99)
        XCTAssertEqual(
            mergedSub.singularMessageSet.SwiftProtoTesting_Fuzz_AMessageSetMessageExtension1_messageSetExtension
                .aString,
            "dst"
        )
        XCTAssertEqual(
            mergedSub.singularMessageSet.SwiftProtoTesting_Fuzz_AMessageSetMessageExtension2_messageSetExtension
                .anInt32,
            42
        )
        XCTAssertTrue(mergedSub.unknownFields.data.isEmpty)
        XCTAssertTrue(mergedSub.SwiftProtoTesting_Fuzz_singularMessageExt.unknownFields.data.isEmpty)
        XCTAssertTrue(mergedSub.mapInt32Message[1]?.unknownFields.data.isEmpty ?? false)
        XCTAssertTrue(mergedSub.singularMessageSet.unknownFields.data.isEmpty)

        var replacedDst = initialDst
        var replaceOptions = Google_Protobuf_FieldMask.MergeOptions()
        replaceOptions.replaceMessageFields = true
        try replacedDst.merge(from: src, fieldMask: mask, mergeOption: replaceOptions)
        let replacedSub = replacedDst.singularMessage
        XCTAssertEqual(replacedSub.SwiftProtoTesting_Fuzz_singularInt32Ext, 2)
        XCTAssertEqual(replacedSub.SwiftProtoTesting_Fuzz_singularInt64Ext, 3)
        XCTAssertFalse(replacedSub.hasSwiftProtoTesting_Fuzz_singularStringExt)
        XCTAssertEqual(replacedSub.SwiftProtoTesting_Fuzz_repeatedInt32Ext, [20])
        XCTAssertFalse(replacedSub.SwiftProtoTesting_Fuzz_singularMessageExt.hasSingularInt64)
        XCTAssertEqual(replacedSub.SwiftProtoTesting_Fuzz_singularMessageExt.singularInt32, 200)
        XCTAssertEqual(
            replacedSub.SwiftProtoTesting_Fuzz_singularMessageExt.SwiftProtoTesting_Fuzz_singularStringExt,
            "nested"
        )
        XCTAssertFalse(
            replacedSub.singularMessageSet.hasSwiftProtoTesting_Fuzz_AMessageSetMessageExtension1_messageSetExtension
        )
        XCTAssertEqual(
            replacedSub.singularMessageSet.SwiftProtoTesting_Fuzz_AMessageSetMessageExtension2_messageSetExtension
                .anInt32,
            42
        )
    }

    // replaceMessageFields must clear oneof message and group branches when
    // unset in source without clearing unrelated oneof branches or sibling data.
    func testMergeReplaceMessageFieldsClearsOneofMessagesAndGroups() throws {
        var replaceOptions = Google_Protobuf_FieldMask.MergeOptions()
        replaceOptions.replaceMessageFields = true

        // Google_Protobuf_Value oneof struct_value / list_value.
        let emptyValue = Google_Protobuf_Value()
        var structVal = Google_Protobuf_Value(
            structValue: Google_Protobuf_Struct(fields: ["k": Google_Protobuf_Value(stringValue: "v")])
        )
        let structMask = Google_Protobuf_FieldMask(protoPaths: "struct_value")
        try structVal.merge(from: emptyValue, fieldMask: structMask)
        if case .structValue? = structVal.kind {
            // Preserved by default when unset in source.
        } else {
            XCTFail("Expected structValue to be preserved by default, got \(String(describing: structVal.kind))")
        }
        try structVal.merge(from: emptyValue, fieldMask: structMask, mergeOption: replaceOptions)
        XCTAssertNil(structVal.kind)

        // Unrelated active oneof branch is not cleared.
        var stringVal = Google_Protobuf_Value(stringValue: "keep")
        try stringVal.merge(from: emptyValue, fieldMask: structMask, mergeOption: replaceOptions)
        XCTAssertEqual(stringVal.kind, .stringValue("keep"))

        // Top-level oneof message and oneof group on Fuzz_Message preserve sibling
        // fields, extensions, and unknownFields when cleared.
        let unknownBytes = Data([0x98, 0x3E, 0x01])  // field 995 varint = 1
        let emptyFuzz = SwiftProtoTesting_Fuzz_Message()
        var msgWithOneof = SwiftProtoTesting_Fuzz_Message.with {
            $0.singularInt32 = 7
            $0.SwiftProtoTesting_Fuzz_singularInt32Ext = 11
            $0.o = .oneofMessage(.with { $0.singularInt64 = 99 })
        }
        msgWithOneof.unknownFields.append(protobufData: unknownBytes)

        try msgWithOneof.merge(
            from: emptyFuzz,
            fieldMask: .init(protoPaths: "oneof_message"),
            mergeOption: replaceOptions
        )
        XCTAssertNil(msgWithOneof.o)
        XCTAssertEqual(msgWithOneof.singularInt32, 7)
        XCTAssertEqual(msgWithOneof.SwiftProtoTesting_Fuzz_singularInt32Ext, 11)
        XCTAssertEqual(msgWithOneof.unknownFields.data, unknownBytes)

        // Same-case oneof_message merges by default and replaces when requested.
        var sameBranchDst = SwiftProtoTesting_Fuzz_Message.with {
            $0.o = .oneofMessage(.with { $0.singularInt64 = 10 })
        }
        let sameBranchSrc = SwiftProtoTesting_Fuzz_Message.with {
            $0.o = .oneofMessage(.with { $0.singularInt32 = 20 })
        }
        try sameBranchDst.merge(from: sameBranchSrc, fieldMask: .init(protoPaths: "oneof_message"))
        XCTAssertEqual(sameBranchDst.oneofMessage.singularInt64, 10)
        XCTAssertEqual(sameBranchDst.oneofMessage.singularInt32, 20)
        try sameBranchDst.merge(
            from: sameBranchSrc,
            fieldMask: .init(protoPaths: "oneof_message"),
            mergeOption: replaceOptions
        )
        XCTAssertFalse(sameBranchDst.oneofMessage.hasSingularInt64)
        XCTAssertEqual(sameBranchDst.oneofMessage.singularInt32, 20)

        // Unrelated active oneof branch on Fuzz_Message is untouched.
        var intOneofDst = SwiftProtoTesting_Fuzz_Message.with {
            $0.o = .oneofInt32(77)
        }
        try intOneofDst.merge(
            from: emptyFuzz,
            fieldMask: .init(protoPaths: "oneof_message"),
            mergeOption: replaceOptions
        )
        XCTAssertEqual(intOneofDst.o, .oneofInt32(77))

        // Nested oneof message and oneof group clearing inside singular_message.
        var nestedOneofDst = SwiftProtoTesting_Fuzz_Message.with {
            $0.singularMessage = .with {
                $0.singularInt32 = 5
                $0.o = .oneofMessage(.with { $0.singularInt32 = 1 })
            }
        }
        try nestedOneofDst.merge(
            from: emptyFuzz,
            fieldMask: .init(protoPaths: "singular_message.oneof_message"),
            mergeOption: replaceOptions
        )
        XCTAssertEqual(nestedOneofDst.singularMessage.singularInt32, 5)
        XCTAssertNil(nestedOneofDst.singularMessage.o)

        var nestedGroupDst = SwiftProtoTesting_Fuzz_Message.with {
            $0.singularMessage = .with {
                $0.singularInt32 = 6
                $0.o = .oneofGroup(.with { $0.groupField = 3 })
            }
        }
        try nestedGroupDst.merge(
            from: emptyFuzz,
            fieldMask: .init(protoPaths: "singular_message.OneofGroup"),
            mergeOption: replaceOptions
        )
        XCTAssertEqual(nestedGroupDst.singularMessage.singularInt32, 6)
        XCTAssertNil(nestedGroupDst.singularMessage.o)
    }

    // Non-canonical masks with duplicate or parent-covered child paths must not
    // duplicate repeated or unknown fields during merge or trim.
    func testMergeAndTrimDeduplicateOverlappingPaths() throws {
        let srcUnknown = Data([0x98, 0x3E, 0x02])  // field 995 varint = 2
        let dstUnknown = Data([0x98, 0x3E, 0x01])  // field 995 varint = 1
        var src = SwiftProtoTesting_Fuzz_Message.with {
            $0.singularMessage = .with {
                $0.repeatedInt32 = [2, 3]
            }
        }
        src.singularMessage.unknownFields.append(protobufData: srcUnknown)

        let overlappingMasks = [
            Google_Protobuf_FieldMask(protoPaths: ["singular_message", "singular_message"]),
            Google_Protobuf_FieldMask(protoPaths: ["singular_message.repeated_int32", "singular_message"]),
            Google_Protobuf_FieldMask(protoPaths: ["singular_message", "singular_message.repeated_int32"]),
        ]
        for mask in overlappingMasks {
            var dst = SwiftProtoTesting_Fuzz_Message.with {
                $0.singularMessage = .with {
                    $0.repeatedInt32 = [1]
                }
            }
            dst.singularMessage.unknownFields.append(protobufData: dstUnknown)
            try dst.merge(from: src, fieldMask: mask)
            XCTAssertEqual(dst.singularMessage.repeatedInt32, [1, 2, 3])
            XCTAssertEqual(dst.singularMessage.unknownFields.data, dstUnknown + srcUnknown)
        }

        var trimmed = src
        trimmed.singularInt32 = 99
        let changed = trimmed.trim(
            keeping: .init(protoPaths: ["singular_message.repeated_int32", "singular_message"])
        )
        XCTAssertTrue(changed)
        XCTAssertFalse(trimmed.hasSingularInt32)
        XCTAssertEqual(trimmed.singularMessage.repeatedInt32, [2, 3])
        XCTAssertEqual(trimmed.singularMessage.unknownFields.data, srcUnknown)

        let secondChanged = trimmed.trim(
            keeping: .init(protoPaths: ["singular_message.repeated_int32", "singular_message"])
        )
        XCTAssertFalse(secondChanged)
        XCTAssertEqual(trimmed.singularMessage.repeatedInt32, [2, 3])
        XCTAssertEqual(trimmed.singularMessage.unknownFields.data, srcUnknown)
    }

    // Leaf message merge must preserve unknown fields directly without invoking
    // binary decoding depth limits on deeply nested unknown groups.
    func testMergeLeafMessagePreservesDeepUnknownGroups() throws {
        var deepUnknownGroup = Data()
        // 110 nested unknown groups on field 999 (start-group tag 0xBB 0x3E, end-group 0xBC 0x3E).
        for _ in 0..<110 {
            deepUnknownGroup.append(contentsOf: [0xBB, 0x3E])
        }
        for _ in 0..<110 {
            deepUnknownGroup.append(contentsOf: [0xBC, 0x3E])
        }
        var src = SwiftProtoTesting_Fuzz_Message.with {
            $0.singularMessage = .with {
                $0.singularInt32 = 42
            }
        }
        src.singularMessage.unknownFields.append(protobufData: deepUnknownGroup)

        var dst = SwiftProtoTesting_Fuzz_Message.with {
            $0.singularMessage = .with {
                $0.singularInt64 = 7
            }
        }
        try dst.merge(from: src, fieldMask: .init(protoPaths: "singular_message"))
        XCTAssertEqual(dst.singularMessage.singularInt32, 42)
        XCTAssertEqual(dst.singularMessage.singularInt64, 7)
        XCTAssertEqual(dst.singularMessage.unknownFields.data, deepUnknownGroup)
    }

    // Merging leaf submessages must preserve remaining binary decode depth
    // budgets recorded on Google_Protobuf_Any fields.
    func testMergeLeafMessagePreservesAnyBinaryDepthBudget() throws {
        let deepInner = SwiftProtoTesting_Test3_TestAllTypesProto3.with {
            $0.optionalNestedMessage.corecursive.optionalNestedMessage.corecursive.optionalInt32 = 77
        }
        let outerOriginal = try SwiftProtoTesting_Test3_TestAllTypesProto3.with {
            $0.optionalNestedMessage.corecursive.optionalAny = try Google_Protobuf_Any(message: deepInner)
        }
        let wireBytes: Data = try outerOriginal.serializedBytes()
        var tightOptions = BinaryDecodingOptions()
        // Outer -> optionalNestedMessage (3) -> corecursive (2) -> optionalAny (1).
        tightOptions.messageDepthLimit = 4
        let src = try SwiftProtoTesting_Test3_TestAllTypesProto3(
            serializedBytes: wireBytes,
            options: tightOptions
        )

        // Precondition: unpacking fails with messageDepthLimit due to budget 1.
        XCTAssertThrowsError(
            try SwiftProtoTesting_Test3_TestAllTypesProto3(
                unpackingAny: src.optionalNestedMessage.corecursive.optionalAny
            )
        ) { error in
            XCTAssertEqual(error as? BinaryDecodingError, .messageDepthLimit)
        }

        let mask = Google_Protobuf_FieldMask(protoPaths: "optional_nested_message")

        // Merging into a destination without optionalAny preserves the budget.
        var dstWithoutAny = SwiftProtoTesting_Test3_TestAllTypesProto3.with {
            $0.optionalNestedMessage.corecursive.optionalInt32 = 1
        }
        try dstWithoutAny.merge(from: src, fieldMask: mask)
        XCTAssertEqual(dstWithoutAny.optionalNestedMessage.corecursive.optionalInt32, 1)
        XCTAssertThrowsError(
            try SwiftProtoTesting_Test3_TestAllTypesProto3(
                unpackingAny: dstWithoutAny.optionalNestedMessage.corecursive.optionalAny
            )
        ) { error in
            XCTAssertEqual(error as? BinaryDecodingError, .messageDepthLimit)
        }

        // Merging into a destination that already has optionalAny also preserves src's budget.
        var dstWithAny = try SwiftProtoTesting_Test3_TestAllTypesProto3.with {
            $0.optionalNestedMessage.corecursive.optionalAny = try Google_Protobuf_Any(
                message: Google_Protobuf_Int32Value(1)
            )
        }
        try dstWithAny.merge(from: src, fieldMask: mask)
        XCTAssertThrowsError(
            try SwiftProtoTesting_Test3_TestAllTypesProto3(
                unpackingAny: dstWithAny.optionalNestedMessage.corecursive.optionalAny
            )
        ) { error in
            XCTAssertEqual(error as? BinaryDecodingError, .messageDepthLimit)
        }

        // A type_url-only merge onto a tight-budget binary Any keeps its budget.
        let typeURLOnlySrc = SwiftProtoTesting_Test3_TestAllTypesProto3.with {
            $0.optionalNestedMessage.corecursive.optionalAny.typeURL =
                "type.googleapis.com/\(SwiftProtoTesting_Test3_TestAllTypesProto3.protoMessageName)"
        }
        try dstWithAny.merge(from: typeURLOnlySrc, fieldMask: mask)
        XCTAssertThrowsError(
            try SwiftProtoTesting_Test3_TestAllTypesProto3(
                unpackingAny: dstWithAny.optionalNestedMessage.corecursive.optionalAny
            )
        ) { error in
            XCTAssertEqual(error as? BinaryDecodingError, .messageDepthLimit)
        }
    }

    // Decoded extensions on one submessage must not cause unknown fields with
    // the same field number on sibling/child submessages to be decoded.
    func testMergeLeafMessageDoesNotPromoteUnknownFieldsToExtensions() throws {
        // Field 1014 (SwiftProtoTesting_Fuzz_singularStringExt) wire type 2 with invalid UTF-8.
        let invalidUTF8ExtBytes = Data([0xB2, 0x3F, 0x02, 0xFF, 0xFE])
        var childWithUnknown = SwiftProtoTesting_Fuzz_Message()
        childWithUnknown.unknownFields.append(protobufData: invalidUTF8ExtBytes)

        let src = SwiftProtoTesting_Fuzz_Message.with {
            $0.singularMessage = .with {
                $0.SwiftProtoTesting_Fuzz_singularStringExt = "parent"
                $0.singularMessage = childWithUnknown
                $0.mapInt32Message[1] = .with {
                    $0.SwiftProtoTesting_Fuzz_singularStringExt = "valid"
                }
                $0.mapInt32Message[2] = childWithUnknown
            }
        }
        var dst = SwiftProtoTesting_Fuzz_Message.with {
            $0.singularMessage = .with {
                $0.singularInt64 = 10
            }
        }

        try dst.merge(from: src, fieldMask: .init(protoPaths: "singular_message"))
        XCTAssertEqual(dst.singularMessage.singularInt64, 10)
        XCTAssertEqual(dst.singularMessage.SwiftProtoTesting_Fuzz_singularStringExt, "parent")
        XCTAssertFalse(dst.singularMessage.singularMessage.hasSwiftProtoTesting_Fuzz_singularStringExt)
        XCTAssertEqual(dst.singularMessage.singularMessage.unknownFields.data, invalidUTF8ExtBytes)
        XCTAssertEqual(dst.singularMessage.mapInt32Message[1]?.SwiftProtoTesting_Fuzz_singularStringExt, "valid")
        XCTAssertEqual(dst.singularMessage.mapInt32Message[2]?.unknownFields.data, invalidUTF8ExtBytes)
    }

    // Merging a Google_Protobuf_Any with a different type_url and empty value
    // onto a destination holding a .message Any must materialize the existing
    // value bytes so type_url and storage state never disagree.
    func testMergeLeafAnyCrossTypeEmptySourceValue() throws {
        let originalInner = SwiftProtoTesting_TestAllTypes.with { $0.optionalInt32 = 42 }
        let expectedBytes: Data = try originalInner.serializedBytes()

        var dst = try SwiftProtoTesting_Fuzz_Message.with {
            $0.wktAny = try Google_Protobuf_Any(message: originalInner)
            $0.singularMessage.wktAny = try Google_Protobuf_Any(message: originalInner)
        }
        let src = try SwiftProtoTesting_Fuzz_Message.with {
            $0.wktAny = try Google_Protobuf_Any(message: Google_Protobuf_Empty())
            $0.singularMessage.wktAny = try Google_Protobuf_Any(message: Google_Protobuf_Empty())
        }

        try dst.merge(from: src, fieldMask: .init(protoPaths: ["wkt_any", "singular_message"]))

        for mergedAny in [dst.wktAny, dst.singularMessage.wktAny] {
            XCTAssertEqual(mergedAny.typeURL, "type.googleapis.com/google.protobuf.Empty")
            XCTAssertEqual(mergedAny.value, expectedBytes)
            let text = mergedAny.textFormatString()
            XCTAssertFalse(text.contains("optional_int32"), "Unexpected stale message text format: \(text)")
        }
    }

    // Deeply nested .message Google_Protobuf_Any chains inside leaf submessages
    // must merge without exponential serialization blowup.
    func testMergeLeafMessageWithDeeplyNestedMessageAnyChain() throws {
        var nested = try Google_Protobuf_Any(message: Google_Protobuf_Int32Value(7))
        for _ in 0..<20 {
            nested = try Google_Protobuf_Any(message: nested)
        }
        let src = SwiftProtoTesting_Test3_TestAllTypesProto3.with {
            $0.optionalNestedMessage.corecursive.optionalAny = nested
            $0.optionalNestedMessage.corecursive.repeatedAny = [nested]
        }
        var dst = try SwiftProtoTesting_Test3_TestAllTypesProto3.with {
            $0.optionalNestedMessage.corecursive.optionalInt32 = 99
            $0.optionalNestedMessage.corecursive.optionalAny = try Google_Protobuf_Any(
                message: Google_Protobuf_Int32Value(1)
            )
        }

        try dst.merge(from: src, fieldMask: .init(protoPaths: "optional_nested_message"))
        XCTAssertEqual(dst.optionalNestedMessage.corecursive.optionalInt32, 99)
        XCTAssertEqual(dst.optionalNestedMessage.corecursive.repeatedAny.count, 1)

        var current = dst.optionalNestedMessage.corecursive.optionalAny
        for _ in 0..<20 {
            current = try Google_Protobuf_Any(unpackingAny: current)
        }
        let leaf = try Google_Protobuf_Int32Value(unpackingAny: current)
        XCTAssertEqual(leaf.value, 7)
    }

    // Large dotted FieldMask paths (e.g. untrusted inputs with tens of thousands
    // of components) must be canonicalized and rejected in linear time/memory
    // without quadratic prefix expansion.
    func testMergeLargeDottedFieldMaskPaths() throws {
        let src = SwiftProtoTesting_TestAllTypes.with {
            $0.optionalString = "kept"
            $0.optionalNestedMessage.bb = 42
        }
        var dst = SwiftProtoTesting_TestAllTypes()

        let mask = Google_Protobuf_FieldMask(protoPaths: [
            String(repeating: ".", count: 100_000),
            String(repeating: "a.", count: 50_000),
            String(repeating: "a.", count: 50_000) + "a",
            "optional_int32." + String(repeating: "a.", count: 50_000),
            "optional_int32." + String(repeating: "a.", count: 10_000) + "a",
            "optional_nested_message." + String(repeating: "a.", count: 10_000) + "a",
            "optional_nested_message",
            "optional_string",
        ])

        try dst.merge(from: src, fieldMask: mask)
        XCTAssertEqual(dst.optionalString, "kept")
        XCTAssertEqual(dst.optionalNestedMessage.bb, 42)
        XCTAssertFalse(dst.hasOptionalInt32)
    }

    // Sub-path merges on Google_Protobuf_Any ("type_url" and "value", nested or
    // top-level) must keep AnyMessageStorage invariants intact and preserve
    // decoded binary depth budgets.
    func testMergeAnySubPathsPreserveStorageInvariants() throws {
        let originalInner = SwiftProtoTesting_TestAllTypes.with { $0.optionalInt32 = 42 }
        let expectedBytes: Data = try originalInner.serializedBytes()

        // Changing or clearing type_url on a .message destination must materialize
        // the payload to .binary so type_url and state never disagree or resurrect
        // the old type URL.
        var dstNested = try SwiftProtoTesting_Test3_TestAllTypesProto3.with {
            $0.optionalAny = try Google_Protobuf_Any(message: originalInner)
        }
        let srcChangedType = SwiftProtoTesting_Test3_TestAllTypesProto3.with {
            $0.optionalAny.typeURL = "type.googleapis.com/google.protobuf.Empty"
        }
        try dstNested.merge(
            from: srcChangedType,
            fieldMask: .init(protoPaths: "optional_any.type_url")
        )
        XCTAssertEqual(dstNested.optionalAny.typeURL, "type.googleapis.com/google.protobuf.Empty")
        XCTAssertEqual(dstNested.optionalAny.value, expectedBytes)
        XCTAssertFalse(dstNested.optionalAny.textFormatString().contains("optional_int32"))

        // Clearing type_url to "" on a .message destination must not resurrect the
        // old type URL in text or JSON output.
        var dstTopAny = try Google_Protobuf_Any(message: originalInner)
        let emptyAny = Google_Protobuf_Any()
        try dstTopAny.merge(from: emptyAny, fieldMask: .init(protoPaths: "type_url"))
        XCTAssertEqual(dstTopAny.typeURL, "")
        XCTAssertEqual(dstTopAny.value, expectedBytes)
        XCTAssertFalse(dstTopAny.textFormatString().contains(SwiftProtoTesting_TestAllTypes.protoMessageName))

        // Invalid sub-paths under Google_Protobuf_Any are rejected cleanly.
        XCTAssertTrue(Google_Protobuf_Any.isPathValid("type_url"))
        XCTAssertTrue(Google_Protobuf_Any.isPathValid("value"))
        XCTAssertFalse(Google_Protobuf_Any.isPathValid("unknown"))
        XCTAssertFalse(Google_Protobuf_Any.isPathValid("type_url.extra"))
        XCTAssertFalse(Google_Protobuf_Any.isPathValid("value.extra"))

        // Merging "value" (alone or alongside "type_url") from a binary-decoded Any
        // must preserve its decoded recursion budget.
        let deepInner = SwiftProtoTesting_Test3_TestAllTypesProto3.with {
            $0.optionalNestedMessage.corecursive.optionalInt32 = 123
        }
        let outerOriginal = try SwiftProtoTesting_Test3_TestAllTypesProto3.with {
            $0.optionalNestedMessage.corecursive.optionalAny = try Google_Protobuf_Any(message: deepInner)
        }
        let wireBytes: Data = try outerOriginal.serializedBytes()
        var tightOptions = BinaryDecodingOptions()
        // Outer -> optionalNestedMessage (3) -> corecursive (2) -> optionalAny (1).
        tightOptions.messageDepthLimit = 4
        let tightSrc = try SwiftProtoTesting_Test3_TestAllTypesProto3(
            serializedBytes: wireBytes,
            options: tightOptions
        )

        // Nested "value" sub-path preserves budget.
        var dstValueOnly = SwiftProtoTesting_Test3_TestAllTypesProto3.with {
            $0.optionalNestedMessage.corecursive.optionalAny.typeURL =
                "type.googleapis.com/\(SwiftProtoTesting_Test3_TestAllTypesProto3.protoMessageName)"
        }
        try dstValueOnly.merge(
            from: tightSrc,
            fieldMask: .init(protoPaths: "optional_nested_message.corecursive.optional_any.value")
        )
        XCTAssertThrowsError(
            try SwiftProtoTesting_Test3_TestAllTypesProto3(
                unpackingAny: dstValueOnly.optionalNestedMessage.corecursive.optionalAny
            )
        ) { error in
            XCTAssertEqual(error as? BinaryDecodingError, .messageDepthLimit)
        }

        // Nested ["type_url", "value"] preserves budget regardless of mask order.
        var dstBothSubPaths = try SwiftProtoTesting_Test3_TestAllTypesProto3.with {
            $0.optionalNestedMessage.corecursive.optionalAny = try Google_Protobuf_Any(
                message: Google_Protobuf_Int32Value(1)
            )
        }
        try dstBothSubPaths.merge(
            from: tightSrc,
            fieldMask: .init(protoPaths: [
                "optional_nested_message.corecursive.optional_any.type_url",
                "optional_nested_message.corecursive.optional_any.value",
            ])
        )
        XCTAssertThrowsError(
            try SwiftProtoTesting_Test3_TestAllTypesProto3(
                unpackingAny: dstBothSubPaths.optionalNestedMessage.corecursive.optionalAny
            )
        ) { error in
            XCTAssertEqual(error as? BinaryDecodingError, .messageDepthLimit)
        }

        // Top-level Google_Protobuf_Any sub-path merge preserves budget on both
        // value write and subsequent type_url update.
        var dstRootAny = Google_Protobuf_Any()
        try dstRootAny.merge(
            from: tightSrc.optionalNestedMessage.corecursive.optionalAny,
            fieldMask: .init(protoPaths: ["type_url", "value"])
        )
        XCTAssertThrowsError(
            try SwiftProtoTesting_Test3_TestAllTypesProto3(unpackingAny: dstRootAny)
        ) { error in
            XCTAssertEqual(error as? BinaryDecodingError, .messageDepthLimit)
        }
        let sameTypeOnly = Google_Protobuf_Any.with {
            $0.typeURL = "type.googleapis.com/\(SwiftProtoTesting_Test3_TestAllTypesProto3.protoMessageName)"
        }
        var dstRootBinary = tightSrc.optionalNestedMessage.corecursive.optionalAny
        dstRootBinary.typeURL = "type.googleapis.com/example.Other"
        try dstRootBinary.merge(from: sameTypeOnly, fieldMask: .init(protoPaths: "type_url"))
        XCTAssertThrowsError(
            try SwiftProtoTesting_Test3_TestAllTypesProto3(unpackingAny: dstRootBinary)
        ) { error in
            XCTAssertEqual(error as? BinaryDecodingError, .messageDepthLimit)
        }
    }

    // Deferred JSON-decoded Any payloads with unregistered types must survive
    // leaf merges when no transcoding is needed and propagate
    // BinaryEncodingError.anyTranscodeFailure when merging onto a non-empty Any.
    func testMergeLeafMessageWithDeferredJSONAny() throws {
        let json = """
            {
              "optionalInt32": 999,
              "optionalNestedMessage": {
                "corecursive": {
                  "optionalAny": {
                    "@type": "type.googleapis.com/example.UnregisteredType",
                    "foo": 1
                  },
                  "repeatedAny": [
                    {
                      "@type": "type.googleapis.com/example.UnregisteredType",
                      "bar": 2
                    }
                  ]
                }
              },
              "optionalAny": {
                "@type": "type.googleapis.com/example.UnregisteredType",
                "baz": 3
              }
            }
            """
        let src = try SwiftProtoTesting_Test3_TestAllTypesProto3(jsonString: json)
        let mask = Google_Protobuf_FieldMask(protoPaths: "optional_nested_message")

        // Destination lacks optionalAny: deferred .contentJSON is preserved cleanly.
        var dstEmptyAny = SwiftProtoTesting_Test3_TestAllTypesProto3.with {
            $0.optionalNestedMessage.corecursive.optionalInt32 = 10
        }
        try dstEmptyAny.merge(from: src, fieldMask: mask)
        XCTAssertEqual(dstEmptyAny.optionalNestedMessage.corecursive.optionalInt32, 10)
        XCTAssertEqual(
            dstEmptyAny.optionalNestedMessage.corecursive.optionalAny.typeURL,
            "type.googleapis.com/example.UnregisteredType"
        )
        XCTAssertEqual(dstEmptyAny.optionalNestedMessage.corecursive.repeatedAny.count, 1)
        let encoded = try dstEmptyAny.jsonString()
        XCTAssertTrue(encoded.contains("\"foo\":1"))
        XCTAssertTrue(encoded.contains("\"bar\":2"))

        // Destination already has a non-empty optionalAny: transcoding failure must
        // propagate instead of being swallowed, and destination must stay intact
        // even when earlier paths in a multi-path mask already mutated the working copy.
        var dstNonEmptyAny = try SwiftProtoTesting_Test3_TestAllTypesProto3.with {
            $0.optionalInt32 = 1
            $0.optionalNestedMessage.corecursive.optionalInt32 = 10
            $0.optionalNestedMessage.corecursive.optionalAny = try Google_Protobuf_Any(
                message: Google_Protobuf_Int32Value(5)
            )
        }
        let snapshot = dstNonEmptyAny
        let multiPathMask = Google_Protobuf_FieldMask(protoPaths: [
            "optional_int32",
            "optional_nested_message",
        ])
        XCTAssertThrowsError(try dstNonEmptyAny.merge(from: src, fieldMask: multiPathMask)) { error in
            XCTAssertEqual(error as? BinaryEncodingError, .anyTranscodeFailure)
        }
        XCTAssertEqual(dstNonEmptyAny, snapshot)
        XCTAssertEqual(dstNonEmptyAny.optionalInt32, 1)

        // Sub-path optional_any.type_url avoids transcoding source while materializing
        // a .message destination; optional_any.value propagates source transcode error.
        let intVal = Google_Protobuf_Int32Value(42)
        let intValBytes: Data = try intVal.serializedBytes()
        var dstSubPath = try SwiftProtoTesting_Test3_TestAllTypesProto3.with {
            $0.optionalAny = try Google_Protobuf_Any(message: intVal)
        }
        try dstSubPath.merge(from: src, fieldMask: .init(protoPaths: "optional_any.type_url"))
        XCTAssertEqual(dstSubPath.optionalAny.typeURL, "type.googleapis.com/example.UnregisteredType")
        XCTAssertEqual(dstSubPath.optionalAny.value, intValBytes)
        XCTAssertThrowsError(
            try dstSubPath.merge(from: src, fieldMask: .init(protoPaths: "optional_any.value"))
        ) { error in
            XCTAssertEqual(error as? BinaryEncodingError, .anyTranscodeFailure)
        }

        // Changing type_url on a destination holding unregistered .contentJSON fails
        // atomically without committing earlier paths in the mask.
        var dstUnregisteredJSON = src
        dstUnregisteredJSON.optionalInt32 = 7
        let dstUnregisteredSnapshot = dstUnregisteredJSON
        let validSrc = try SwiftProtoTesting_Test3_TestAllTypesProto3.with {
            $0.optionalInt32 = 88
            $0.optionalAny = try Google_Protobuf_Any(message: Google_Protobuf_Int32Value(9))
        }
        XCTAssertThrowsError(
            try dstUnregisteredJSON.merge(
                from: validSrc,
                fieldMask: .init(protoPaths: ["optional_int32", "optional_any.type_url"])
            )
        ) { error in
            XCTAssertEqual(error as? BinaryEncodingError, .anyTranscodeFailure)
        }
        XCTAssertEqual(dstUnregisteredJSON, dstUnregisteredSnapshot)
        XCTAssertEqual(dstUnregisteredJSON.optionalInt32, 7)

        // Overwriting both type_url and value on a destination holding unregistered
        // .contentJSON succeeds without attempting to transcode the discarded JSON.
        try dstUnregisteredJSON.merge(
            from: validSrc,
            fieldMask: .init(protoPaths: ["optional_any.type_url", "optional_any.value"])
        )
        XCTAssertEqual(dstUnregisteredJSON.optionalAny.typeURL, validSrc.optionalAny.typeURL)
        XCTAssertEqual(
            try Google_Protobuf_Int32Value(unpackingAny: dstUnregisteredJSON.optionalAny).value,
            9
        )

        // Changing type_url on a destination holding registered .contentJSON
        // materializes its binary payload under the new type_url.
        let registeredJSON = """
            {
              "optionalAny": {
                "@type": "type.googleapis.com/google.protobuf.Int32Value",
                "value": 42
              }
            }
            """
        var dstRegisteredJSON = try SwiftProtoTesting_Test3_TestAllTypesProto3(jsonString: registeredJSON)
        let newTypeOnly = SwiftProtoTesting_Test3_TestAllTypesProto3.with {
            $0.optionalAny.typeURL = "type.googleapis.com/google.protobuf.Empty"
        }
        try dstRegisteredJSON.merge(
            from: newTypeOnly,
            fieldMask: .init(protoPaths: "optional_any.type_url")
        )
        XCTAssertEqual(dstRegisteredJSON.optionalAny.typeURL, "type.googleapis.com/google.protobuf.Empty")
        XCTAssertEqual(dstRegisteredJSON.optionalAny.value, intValBytes)
    }

    // Reproduces the report in issue #1875: merging with a mask that covers
    // every field should not drop fields of the destination that the source
    // leaves unset. Singular primitives still follow the default of copying
    // the source value (its default when unset), while the message field is
    // preserved.
    func testMergeAllFieldsKeepsUnsetSourceFields() throws {
        var message = SwiftProtoTesting_TestAllTypes.with { model in
            model.optionalInt64 = 1
            model.optionalString = "blah"
            model.repeatedInt32 = [3, 4]
            model.optionalNestedMessage = .with { nested in
                nested.bb = 9
            }
        }

        let secondMessage = SwiftProtoTesting_TestAllTypes.with { model in
            model.optionalInt64 = 2
        }

        let fieldMask = Google_Protobuf_FieldMask(allFieldsOf: SwiftProtoTesting_TestAllTypes.self)
        try message.merge(from: secondMessage, fieldMask: fieldMask)

        XCTAssertEqual(message.optionalInt64, 2)
        XCTAssertEqual(message.repeatedInt32, [3, 4])
        XCTAssertTrue(message.hasOptionalNestedMessage)
        XCTAssertEqual(message.optionalNestedMessage.bb, 9)
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
        try message.merge(from: secondMessage, fieldMask: fieldMask)
        XCTAssertEqual(message.repeatedInt32, [1, 2, 3, 4])

        // Checks with replacing repeated fields
        var options = Google_Protobuf_FieldMask.MergeOptions()
        options.replaceRepeatedFields = true
        try message.merge(from: secondMessage, fieldMask: fieldMask, mergeOption: options)
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
        try message.merge(from: secondMessage, fieldMask: fieldMask)
        XCTAssertEqual(message.mapInt32String, [1: "a", 2: "b"])

        // Checks with replacing repeated fields
        var options = Google_Protobuf_FieldMask.MergeOptions()
        options.replaceRepeatedFields = true
        try message.merge(from: secondMessage, fieldMask: fieldMask, mergeOption: options)
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
        let r1 = message.trim(keeping: .init(protoPaths: "optional_nested_message.bb"))
        XCTAssertTrue(r1)
        XCTAssertEqual(message.optionalInt32, 0)
        XCTAssertEqual(message.optionalNestedMessage.bb, 2)

        // Checks trim should do nothing with an empty fieldMask.
        let r2 = message.trim(keeping: .init())
        XCTAssertFalse(r2)

        // Checks trim should return false if nothing has been changed.
        let r3 = message.trim(keeping: .init(protoPaths: "optional_nested_message.bb"))
        XCTAssertFalse(r3)

        // Checks trim to be unsuccessful with an invalid fieldMask.
        let r4 = message.trim(keeping: .init(protoPaths: "invalid_path"))
        XCTAssertFalse(r4)
    }

    // Checks trim functionality for field masks when applies on a extensible message.
    func testTrimFieldsOfMessageWithExtension() throws {
        var message = SwiftProtoTesting_Fuzz_Message()
        message.singularInt32 = 1
        message.SwiftProtoTesting_Fuzz_singularInt32Ext = 1
        let mask = Google_Protobuf_FieldMask(protoPaths: ["singular_string"])

        // Checks trim should retain extensions while removes other fields.
        let r1 = message.trim(keeping: mask)
        XCTAssertTrue(r1)
        XCTAssertEqual(message.SwiftProtoTesting_Fuzz_singularInt32Ext, .init(1))
        XCTAssertEqual(message.singularInt32, .init(0))

        // Checks trim should do nothing (fields are already removed) and still retain extension fields.
        let r2 = message.trim(keeping: mask)
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
            "optional_nested_message.bb",
        ])
        let m3 = Google_Protobuf_FieldMask(protoPaths: [
            "optional_int32",
            "optional_nested_message",
        ])
        let m4 = Google_Protobuf_FieldMask(protoPaths: [
            "optional_int32",
            "optional_nested_message.bc",
        ])
        let m5 = Google_Protobuf_FieldMask(protoPaths: [
            "optional_int",
            "optional_nested_message.bb",
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

    // Checks that json names of paths should not be contained in mask field with allFieldsOf init.
    func testFieldMaskAllPathsWithUniqueName() {
        let mask = Google_Protobuf_FieldMask(allFieldsOf: SwiftProtoTesting_Fuzz_Message.self)
        // proto name is included
        XCTAssertTrue(mask.paths.contains("SingularGroup"))
        // json name is not included
        XCTAssertFalse(mask.paths.contains("singulargroup"))
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

    // Checks `intersect` and `subtract` when one path covers another
    // ("a" covers "a.b", same as `contains`). Cases from upstream
    // field_mask_util_test.cc TestIntersect and TestSubtract.
    func testIntersectAndSubtractWithSubPaths() throws {
        let m1 = Google_Protobuf_FieldMask(protoPaths: ["foo.bar.baz", "quz"])
        let m2 = Google_Protobuf_FieldMask(protoPaths: ["foo.bar", "bar"])
        XCTAssertEqual(m1.intersect(m2).paths, ["foo.bar.baz"])
        XCTAssertEqual(m2.intersect(m1).paths, ["foo.bar.baz"])

        // Upstream regression test for b/72727550.
        let m3 = Google_Protobuf_FieldMask(protoPaths: ["optional_foreign_message.c"])
        let m4 = Google_Protobuf_FieldMask(protoPaths: ["optional_foreign_message", "optional_nested_message"])
        XCTAssertEqual(m3.subtract(m4).paths, [])

        let m5 = Google_Protobuf_FieldMask(protoPaths: ["optional_nested_message"])
        let m6 = Google_Protobuf_FieldMask(protoPaths: ["optional_nested_message.nonexist_field"])
        XCTAssertEqual(m5.subtract(m6).paths, ["optional_nested_message"])

        // Only whole path components count.
        let m7 = Google_Protobuf_FieldMask(protoPaths: ["ab", "a.b"])
        let m8 = Google_Protobuf_FieldMask(protoPaths: ["a"])
        XCTAssertEqual(m7.intersect(m8).paths, ["a.b"])
        XCTAssertEqual(m7.subtract(m8).paths, ["ab"])

        // A parent and its sub-path collapse to the parent, even when one
        // input isn't canonical (matches C++ FieldMaskUtil::Intersect).
        let m9 = Google_Protobuf_FieldMask(protoPaths: ["foo"])
        let m10 = Google_Protobuf_FieldMask(protoPaths: ["foo.bar", "foo"])
        XCTAssertEqual(m9.intersect(m10).paths, ["foo"])
        XCTAssertEqual(m10.intersect(m9).paths, ["foo"])

        // Removing a field from a mask has to remove its sub-paths too, or
        // merging with the result still writes into that field.
        let source = SwiftProtoTesting_TestAllTypes.with {
            $0.optionalInt32 = 1
            $0.optionalForeignMessage.c = 2
        }
        let requested = Google_Protobuf_FieldMask(protoPaths: ["optional_int32", "optional_foreign_message.c"])
        let allowed = requested.subtract(.init(protoPaths: ["optional_foreign_message"]))
        XCTAssertEqual(allowed.paths, ["optional_int32"])
        var message = SwiftProtoTesting_TestAllTypes()
        try message.merge(from: source, fieldMask: allowed)
        XCTAssertEqual(message.optionalInt32, 1)
        XCTAssertFalse(message.hasOptionalForeignMessage)
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
        try m1.merge(from: m2, fieldMask: .init(allFieldsOf: SwiftProtoTesting_Fuzz_Message.self))
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
            "singular_sfixed64",
        ])
        try m1.merge(from: m2, fieldMask: mask)
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
        try m1.merge(from: m2, fieldMask: .init(protoPaths: ["singular_int32"]))
        XCTAssertEqual(m1.singularInt32, m2.singularInt32)
    }

    // Checks merge could be done for an optional path with default value.
    func testMergeDefaultValue() throws {
        var m1 = SwiftProtoTesting_TestAllTypes.with { m in
            m.defaultInt32 = 1
        }
        let m2 = SwiftProtoTesting_TestAllTypes()
        try m1.merge(from: m2, fieldMask: .init(protoPaths: ["default_int32"]))
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
        try m1.merge(
            from: m2,
            fieldMask: .init(protoPaths: [
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
                "optional_nested_enum",
            ])
        )
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
        try m1.merge(from: m2, fieldMask: .init(protoPaths: ["singular_message.singular_message"]))
        XCTAssertEqual(m1.singularMessage.singularMessage.singularInt32, Int32(1))
        try m1.merge(from: m3, fieldMask: .init(protoPaths: ["singular_message.singular_message.singular_int32"]))
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
        try m1.merge(from: m2, fieldMask: .init(protoPaths: ["SingularGroup.group_field"]))
        XCTAssertEqual(m1.singularGroup.groupField, m2.singularGroup.groupField)
    }

    // Checks that merging with json path should do nothing. Path should only be merged using proto names.
    func testMergeFieldWithJSONName() throws {
        var m1 = SwiftProtoTesting_Fuzz_Message()
        let m2 = SwiftProtoTesting_Fuzz_Message.with { m in
            m.singularGroup = .with { $0.groupField = 1 }
        }
        // should do nothing with json path (should not merge)
        try m1.merge(from: m2, fieldMask: .with({ $0.paths = ["singulargroup"] }))
        XCTAssertNotEqual(m1.singularGroup, m2.singularGroup)
        // should merge with proto path
        try m1.merge(from: m2, fieldMask: .with({ $0.paths = ["SingularGroup"] }))
        XCTAssertEqual(m1.singularGroup, m2.singularGroup)
        // should do nothing with json path (do not clear field)
        try m1.merge(from: m2, fieldMask: .with({ $0.paths = ["singulargroup"] }))
        XCTAssertEqual(m1.singularGroup, m2.singularGroup)
    }

    #endif
}
