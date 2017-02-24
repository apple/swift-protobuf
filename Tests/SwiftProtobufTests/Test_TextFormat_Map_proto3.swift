// Tests/SwiftProtobufTests/Test_TextFormat_Map_proto3.swift - Exercise proto3 text format coding
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// This is a set of tests for text format protobuf files.
///
// -----------------------------------------------------------------------------

import Foundation
import XCTest
import SwiftProtobuf

class Test_TextFormat_Map_proto3: XCTestCase, PBTestHelpers {
    typealias MessageTestType = ProtobufUnittest_TestMap

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
    }

    func test_StringMessage() {
        let foo = ProtobufUnittest_ForeignMessage.with {$0.c = 999}

        assertTextFormatEncode("map_string_foreign_message {\n  key: \"foo\"\n  value {\n    c: 999\n  }\n}\n") {(o: inout MessageTestType) in
            o.mapStringForeignMessage = ["foo": foo]
        }
    }
}
