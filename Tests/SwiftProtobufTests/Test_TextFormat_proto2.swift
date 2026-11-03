// Tests/SwiftProtobufTests/Test_TextFormat_proto2.swift - Exercise proto3 text format coding
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// This is a set of tests for text format protobuf files.
///
// -----------------------------------------------------------------------------

import Foundation
import SwiftProtobuf
import XCTest

final class Test_TextFormat_proto2: XCTestCase, PBTestHelpers {
    typealias MessageTestType = SwiftProtoTesting_TestAllTypes

    func testDecoding_duplicateMessagesAndGroups() {
        assertTextFormatDecodeFails("optional_nested_message {bb: 1} optional_nested_message {}")
        assertTextFormatDecodeFails("OptionalGroup {a: 1} optionalgroup {}")
        assertTextFormatDecodeFails("optional_nested_message {bb: 0 bb: 0}")
        assertTextFormatDecodeSucceeds("optional_int32: 1 optional_nested_message {bb: 2}") {
            $0.optionalInt32 == 1 && $0.optionalNestedMessage.bb == 2
        }
        assertTextFormatDecodeSucceeds("repeated_nested_message {bb: 1} repeated_nested_message {bb: 2}") {
            $0.repeatedNestedMessage.map { $0.bb } == [1, 2]
        }
    }

    func testDecoding_duplicateSingularFields() {
        let fields = [
            "optional_int32: 0", "optional_int64: 0", "optional_uint32: 0", "optional_uint64: 0",
            "optional_sint32: 0", "optional_sint64: 0", "optional_fixed32: 0", "optional_fixed64: 0",
            "optional_sfixed32: 0", "optional_sfixed64: 0", "optional_float: 0", "optional_double: 0",
            "optional_bool: false", "optional_string: \"\"", "optional_bytes: \"\"", "optional_nested_enum: 1",
        ]
        for field in fields {
            XCTAssertThrowsError(
                try MessageTestType(textFormatString: "\(field); optional_nested_message {}; \(field)")
            ) {
                guard case TextFormatDecodingError.duplicateSingularField = $0 else {
                    return XCTFail("Unexpected error: \($0)")
                }
            }
        }
        assertTextFormatDecodeFails("optional_int32: 0, 1: 0")
        assertTextFormatDecodeSucceeds("repeated_int32: 0 repeated_int32: [0, 1]") {
            $0.repeatedInt32 == [0, 0, 1]
        }
    }

    func test_group() {
        assertTextFormatEncode("OptionalGroup {\n  a: 17\n}\n") { (o: inout MessageTestType) in
            o.optionalGroup = SwiftProtoTesting_TestAllTypes.OptionalGroup.with { $0.a = 17 }
        }
    }

    func test_group_altName() throws {
        let msg = try MessageTestType(textFormatString: "optionalgroup {a: 17}")
        XCTAssertEqual(msg.optionalGroup.a, 17)
        XCTAssertEqual(msg.textFormatString(), "OptionalGroup {\n  a: 17\n}\n")
    }

    func test_group_numbers() {
        assertTextFormatDecodeSucceeds("16 {\n  17: 17\n}\n") { (o: MessageTestType) in
            o.optionalGroup == SwiftProtoTesting_TestAllTypes.OptionalGroup.with { $0.a = 17 }
        }
    }

    func test_repeatedGroup() {
        assertTextFormatEncode("RepeatedGroup {\n  a: 17\n}\nRepeatedGroup {\n  a: 18\n}\n") {
            (o: inout MessageTestType) in
            let group17 = SwiftProtoTesting_TestAllTypes.RepeatedGroup.with { $0.a = 17 }
            let group18 = SwiftProtoTesting_TestAllTypes.RepeatedGroup.with { $0.a = 18 }
            o.repeatedGroup = [group17, group18]
        }
    }

    func test_repeatedGroup_altName() throws {
        let msg = try MessageTestType(textFormatString: "repeatedgroup {a: 17}\nrepeatedgroup {a: 18}")
        let group17 = SwiftProtoTesting_TestAllTypes.RepeatedGroup.with { $0.a = 17 }
        let group18 = SwiftProtoTesting_TestAllTypes.RepeatedGroup.with { $0.a = 18 }
        XCTAssertEqual(msg.repeatedGroup, [group17, group18])
        XCTAssertEqual(msg.textFormatString(), "RepeatedGroup {\n  a: 17\n}\nRepeatedGroup {\n  a: 18\n}\n")
    }

    func test_repeatedGroup_numbers() {
        assertTextFormatDecodeSucceeds("46 {\n  47: 17\n}\n46 {\n  47: 18\n}\n") { (o: MessageTestType) in
            let group17 = SwiftProtoTesting_TestAllTypes.RepeatedGroup.with { $0.a = 17 }
            let group18 = SwiftProtoTesting_TestAllTypes.RepeatedGroup.with { $0.a = 18 }
            return o.repeatedGroup == [group17, group18]
        }
    }
}
