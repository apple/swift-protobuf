// Tests/SwiftProtobufTests/Test_TextFormat_Map_proto3.swift - Exercise proto3 text format coding
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
import XCTest
import SwiftProtobuf

final class Test_TextFormat_Map_proto3: XCTestCase, PBTestHelpers {
    typealias MessageTestType = SwiftProtoTesting_TestMap

    func test_Int32Int32() {
        assertTextFormatEncode("map_int32_int32 {\n  key: 1\n  value: 2\n}\n") {(o: inout MessageTestType) in
            o.mapInt32Int32 = [1:2]
        }
        assertTextFormatDecodeSucceeds("map_int32_int32 {key: 1, value: 2}") {(o: MessageTestType) in
            return o.mapInt32Int32 == [1:2]
        }
        assertTextFormatDecodeSucceeds("map_int32_int32 {key: 1; value: 2}") {(o: MessageTestType) in
            return o.mapInt32Int32 == [1:2]
        }
        assertTextFormatDecodeSucceeds("map_int32_int32 {key:1 value:2}") {(o: MessageTestType) in
            return o.mapInt32Int32 == [1:2]
        }
        assertTextFormatDecodeSucceeds("map_int32_int32 {key:1 value:2}\nmap_int32_int32 {key:3 value:4}") {(o: MessageTestType) in
            return o.mapInt32Int32 == [1:2, 3:4]
        }
        assertTextFormatDecodeSucceeds("map_int32_int32 [{key:1 value:2}, {key:3 value:4}]") {(o: MessageTestType) in
            return o.mapInt32Int32 == [1:2, 3:4]
        }
        assertTextFormatDecodeSucceeds("map_int32_int32 [{key:1 value:2}];map_int32_int32 {key:3 value:4}") {(o: MessageTestType) in
            return o.mapInt32Int32 == [1:2, 3:4]
        }
        assertTextFormatDecodeFails("map_int32_int32 [{key:1 value:2},]")
        assertTextFormatDecodeFails("map_int32_int32 [{key:1 value:2}")
        assertTextFormatDecodeFails("map_int32_int32 [{key:1 value:2 nonsense:3}")
        assertTextFormatDecodeFails("map_int32_int32 {key:1}")

        assertTextFormatDecodeFails("map_int32_int32<")
        assertTextFormatDecodeFails("map_int32_int32{")
        assertTextFormatDecodeFails("1<")
        assertTextFormatDecodeFails("1{")
        assertTextFormatDecodeFails("1{1:1 2:2")
        assertTextFormatDecodeFails("1{1:1 2:")
        assertTextFormatDecodeFails("1{1:1 2")
        assertTextFormatDecodeFails("1{1:1")
        assertTextFormatDecodeFails("1{1:")
        assertTextFormatDecodeFails("1{1")
    }

    func test_Int32Int32_numbers() {
        assertTextFormatDecodeSucceeds("1 {\n  key: 1\n  value: 2\n}\n") {(o: MessageTestType) in
            return o.mapInt32Int32 == [1:2]
        }
        assertTextFormatDecodeSucceeds("1 {key: 1, value: 2}") {(o: MessageTestType) in
            return o.mapInt32Int32 == [1:2]
        }
        assertTextFormatDecodeSucceeds("1 {key: 1; value: 2}") {(o: MessageTestType) in
            return o.mapInt32Int32 == [1:2]
        }
        assertTextFormatDecodeSucceeds("1 {key:1 value:2}") {(o: MessageTestType) in
            return o.mapInt32Int32 == [1:2]
        }
        assertTextFormatDecodeSucceeds("1 {key:1 value:2}\n1 {key:3 value:4}") {(o: MessageTestType) in
            return o.mapInt32Int32 == [1:2, 3:4]
        }
        assertTextFormatDecodeSucceeds("1 [{key:1 value:2}, {key:3 value:4}]") {(o: MessageTestType) in
            return o.mapInt32Int32 == [1:2, 3:4]
        }
        assertTextFormatDecodeSucceeds("1 [{key:1 value:2}];1 {key:3 value:4}") {(o: MessageTestType) in
            return o.mapInt32Int32 == [1:2, 3:4]
        }
        assertTextFormatDecodeFails("1 [{key:1 value:2},]")
        assertTextFormatDecodeFails("1 [{key:1 value:2}")
        assertTextFormatDecodeFails("1 [{key:1 value:2 nonsense:3}")
        assertTextFormatDecodeFails("1 {key:1}")

        // Using numbers for "key" and "value" in the map entries.

        assertTextFormatDecodeSucceeds("1 {\n  1: 1\n  2: 2\n}\n") {(o: MessageTestType) in
            return o.mapInt32Int32 == [1:2]
        }
        assertTextFormatDecodeSucceeds("1 {1: 1, 2: 2}") {(o: MessageTestType) in
            return o.mapInt32Int32 == [1:2]
        }
        assertTextFormatDecodeSucceeds("1 {1: 1; 2: 2}") {(o: MessageTestType) in
            return o.mapInt32Int32 == [1:2]
        }
        assertTextFormatDecodeSucceeds("1 {1:1 2:2}") {(o: MessageTestType) in
            return o.mapInt32Int32 == [1:2]
        }
        assertTextFormatDecodeSucceeds("1 {1:1 2:2}\n1 {1:3 2:4}") {(o: MessageTestType) in
            return o.mapInt32Int32 == [1:2, 3:4]
        }
        assertTextFormatDecodeSucceeds("1 [{1:1 2:2}, {1:3 2:4}]") {(o: MessageTestType) in
            return o.mapInt32Int32 == [1:2, 3:4]
        }
        assertTextFormatDecodeSucceeds("1 [{1:1 2:2}];1 {1:3 2:4}") {(o: MessageTestType) in
            return o.mapInt32Int32 == [1:2, 3:4]
        }
        assertTextFormatDecodeFails("1 [{1:1 2:2},]")
        assertTextFormatDecodeFails("1 [{1:1 2:2}")
        assertTextFormatDecodeFails("1 [{1:1 2:2 3:3}")
        assertTextFormatDecodeFails("1 {1:1}")

    }

    func test_StringMessage() {
        let foo = SwiftProtoTesting_ForeignMessage.with {$0.c = 999}

        assertTextFormatEncode("map_string_foreign_message {\n  key: \"foo\"\n  value {\n    c: 999\n  }\n}\n") {(o: inout MessageTestType) in
            o.mapStringForeignMessage = ["foo": foo]
        }
    }

    func test_StringMessage_numbers() {
        let foo = SwiftProtoTesting_ForeignMessage.with {$0.c = 999}

        assertTextFormatDecodeSucceeds("18 {\n  key: \"foo\"\n  value {\n    1: 999\n  }\n}\n") {(o: MessageTestType) in
            o.mapStringForeignMessage == ["foo": foo]
        }

        // Using numbers for "key" and "value" in the map entries.

        assertTextFormatDecodeSucceeds("18 {\n  1: \"foo\"\n  2 {\n    1: 999\n  }\n}\n") {(o: MessageTestType) in
            o.mapStringForeignMessage == ["foo": foo]
        }
    }

    func test_Int32Int32_ignore_unknown_fields() {
        var options = TextFormatDecodingOptions()
        options.ignoreUnknownFields = true

        assertTextFormatDecodeSucceeds("map_int32_int32 {\n  key: 1\n  unknown: 6\n  value: 2\n}\n", options: options) {(o: MessageTestType) in
            return o.mapInt32Int32 == [1:2]
        }
        do {
            let _ = try MessageTestType(textFormatString: "map_int32_int32 {\n  key: 1\n  [ext]: 7\n  value: 2\n}\n", options: options)
            XCTFail("Should have failed")
        } catch TextFormatDecodingError.unknownField {
            // This is what should have happened.
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        options.ignoreUnknownFields = false
        options.ignoreUnknownExtensionFields = true

        assertTextFormatDecodeSucceeds("map_int32_int32 {\n  key: 1\n  [ext]: 6\n  value: 2\n}\n", options: options) {(o: MessageTestType) in
            return o.mapInt32Int32 == [1:2]
        }
        do {
            let _ = try MessageTestType(textFormatString: "map_int32_int32 {\n  key: 1\n  unknown: 7\n  value: 2\n}\n", options: options)
            XCTFail("Should have failed")
        } catch TextFormatDecodingError.unknownField {
            // This is what should have happened.
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        options.ignoreUnknownFields = true
        options.ignoreUnknownExtensionFields = true

        assertTextFormatDecodeSucceeds("map_int32_int32 {\n  key: 1\n  unknown: 6\n  [ext]: 7\n  value: 2\n}\n", options: options) {(o: MessageTestType) in
            return o.mapInt32Int32 == [1:2]
        }
        assertTextFormatDecodeSucceeds("map_int32_int32 {unknown: 6, [ext]: 7, key: 1, value: 2}", options: options) {(o: MessageTestType) in
            return o.mapInt32Int32 == [1:2]
        }
        assertTextFormatDecodeSucceeds("map_int32_int32 {key: 1; value: 2; unknown: 6; [ext]: 7}", options: options) {(o: MessageTestType) in
            return o.mapInt32Int32 == [1:2]
        }
        assertTextFormatDecodeSucceeds("map_int32_int32 {key:1 unknown: 6 [ext]: 7 value:2}", options: options) {(o: MessageTestType) in
            return o.mapInt32Int32 == [1:2]
        }
    }

    func test_StringMessage_ignore_unknown_fields() {
        var options = TextFormatDecodingOptions()
        options.ignoreUnknownFields = true

        let foo = SwiftProtoTesting_ForeignMessage.with {$0.c = 999}

        assertTextFormatDecodeSucceeds("map_string_foreign_message {\n  key: \"foo\"\n    unknown: 6\n  value { c: 999 }\n}\n", options: options) {(o: MessageTestType) in
            o.mapStringForeignMessage == ["foo": foo]
        }
        do {
            let _ = try MessageTestType(textFormatString: "map_string_foreign_message {\n  key: \"foo\"\n    [ext]: 7\n  value { c: 999 }\n}\n", options: options)
            XCTFail("Should have failed")
        } catch TextFormatDecodingError.unknownField {
            // This is what should have happened.
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        options.ignoreUnknownFields = false
        options.ignoreUnknownExtensionFields = true

        assertTextFormatDecodeSucceeds("map_string_foreign_message {\n  key: \"foo\"\n    [ext]: 7\n  value { c: 999 }\n}\n", options: options) {(o: MessageTestType) in
            o.mapStringForeignMessage == ["foo": foo]
        }
        do {
            let _ = try MessageTestType(textFormatString: "map_string_foreign_message {\n  key: \"foo\"\n    unknown: 6\n  value { c: 999 }\n}\n", options: options)
            XCTFail("Should have failed")
        } catch TextFormatDecodingError.unknownField {
            // This is what should have happened.
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        options.ignoreUnknownFields = true
        options.ignoreUnknownExtensionFields = true

        assertTextFormatDecodeSucceeds("map_string_foreign_message {\n  key: \"foo\"\n    unknown: 6\n  [ext]: 7\n  value { c: 999 }\n}\n", options: options) {(o: MessageTestType) in
            o.mapStringForeignMessage == ["foo": foo]
        }
        assertTextFormatDecodeSucceeds("map_string_foreign_message { unknown: 6, [ext]: 7, key: \"foo\", value { c: 999 } }", options: options) {(o: MessageTestType) in
            o.mapStringForeignMessage == ["foo": foo]
        }
        assertTextFormatDecodeSucceeds("map_string_foreign_message { key: \"foo\"; value { c: 999 }; unknown: 6; [ext]: 7 }", options: options) {(o: MessageTestType) in
            o.mapStringForeignMessage == ["foo": foo]
        }
        assertTextFormatDecodeSucceeds("map_string_foreign_message { key: \"foo\" value { c: 999 } unknown: 6 [ext]: 7 }", options: options) {(o: MessageTestType) in
            o.mapStringForeignMessage == ["foo": foo]
        }
    }

    func test_Int32Enum_ignore_unknown_fields() {
        var options = TextFormatDecodingOptions()
        options.ignoreUnknownFields = true

        assertTextFormatDecodeSucceeds("map_int32_enum {\n  key: 1\n    unknown: 6\n\n  value: MAP_ENUM_BAR\n}\n", options: options) {(o: MessageTestType) in
            o.mapInt32Enum == [1: .bar]
        }
        do {
            let _ = try MessageTestType(textFormatString: "map_int32_enum {\n  key: 1\n  [ext]: 7\n  value: MAP_ENUM_BAR\n}\n", options: options)
            XCTFail("Should have failed")
        } catch TextFormatDecodingError.unknownField {
            // This is what should have happened.
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        options.ignoreUnknownFields = false
        options.ignoreUnknownExtensionFields = true

        assertTextFormatDecodeSucceeds("map_int32_enum {\n  key: 1\n  [ext]: 7\n  value: MAP_ENUM_BAR\n}\n", options: options) {(o: MessageTestType) in
            o.mapInt32Enum == [1: .bar]
        }
        do {
            let _ = try MessageTestType(textFormatString: "map_int32_enum {\n  key: 1\n    unknown: 6\n  value: MAP_ENUM_BAR\n}\n", options: options)
            XCTFail("Should have failed")
        } catch TextFormatDecodingError.unknownField {
            // This is what should have happened.
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        options.ignoreUnknownFields = true
        options.ignoreUnknownExtensionFields = true

        assertTextFormatDecodeSucceeds("map_int32_enum {\n  key: 1\n    unknown: 6\n  [ext]: 7\n  value: MAP_ENUM_BAR\n}\n", options: options) {(o: MessageTestType) in
            o.mapInt32Enum == [1: .bar]
        }
        assertTextFormatDecodeSucceeds("map_int32_enum { unknown: 6, [ext]: 7, key: 1, value: MAP_ENUM_BAR }", options: options) {(o: MessageTestType) in
            o.mapInt32Enum == [1: .bar]
        }
        assertTextFormatDecodeSucceeds("map_int32_enum { key: 1; value: MAP_ENUM_BAR; unknown: 6; [ext]: 7 }", options: options) {(o: MessageTestType) in
            o.mapInt32Enum == [1: .bar]
        }
        assertTextFormatDecodeSucceeds("map_int32_enum { key: 1 value: MAP_ENUM_BAR unknown: 6 [ext]: 7 }", options: options) {(o: MessageTestType) in
            o.mapInt32Enum == [1: .bar]
        }
    }
}
