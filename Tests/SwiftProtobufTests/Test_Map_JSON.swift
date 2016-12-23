// Tests/SwiftProtobufTests/Test_Map_JSON.swift - Verify JSON coding for maps
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Exercise JSON map handling.  In particular, JSON requires
/// that dictionary keys are quoted, so maps keyed by numeric
/// types need some attention.
///
// -----------------------------------------------------------------------------

import Foundation
import XCTest


// TODO: Testing encoding needs some help, since the order of
// entries isn't well-defined.

class Test_Map_JSON: XCTestCase, PBTestHelpers {
    typealias MessageTestType = Proto3TestMap

    func testMapInt32Int32() {
        assertJSONEncode("{\"mapInt32Int32\":{\"1\":2}}") {(o: inout MessageTestType) in
            o.mapInt32Int32 = [1:2]
        }
        // Decode should work same regardless of order
        assertJSONDecodeSucceeds("{\"mapInt32Int32\":{\"1\":2, \"3\":4}}") {$0.mapInt32Int32 == [1:2, 3:4]}
        assertJSONDecodeSucceeds("{\"mapInt32Int32\":{\"3\":4,\"1\":2}}") {$0.mapInt32Int32 == [1:2, 3:4]}
        // JSON RFC does not allow trailing comma
        assertJSONDecodeFails("{\"mapInt32Int32\":{\"3\":4,\"1\":2,}}")
        // Int values should support being quoted or unquoted
        assertJSONDecodeSucceeds("{\"mapInt32Int32\":{\"1\":\"2\", \"3\":4}}") {$0.mapInt32Int32 == [1:2, 3:4]}
        // Space should not affect result
        assertJSONDecodeSucceeds(" { \"mapInt32Int32\" : { \"1\" : \"2\" , \"3\" : 4 } } ") {$0.mapInt32Int32 == [1:2, 3:4]}
        // Keys must be quoted, else decode fails
        assertJSONDecodeFails("{\"mapInt32Int32\":{1:2, 3:4}}")
        // Fail on other syntax errors:
        assertJSONDecodeFails("{\"mapInt32Int32\":{\"1\":2,, \"3\":4}}")
        assertJSONDecodeFails("{\"mapInt32Int32\":{\"1\",\"4\"}}")
        assertJSONDecodeFails("{\"mapInt32Int32\":{\"1\":, \"3\":4}}")
        assertJSONDecodeFails("{\"mapInt32Int32\":{\"1\":2,,}}")
        assertJSONDecodeFails("{\"mapInt32Int32\":{\"1\":2}} X")
    }

    func testMapStringString() {
        assertJSONEncode("{\"mapStringString\":{\"3\":\"4\"}}") {(o: inout MessageTestType) in
            o.mapStringString = ["3":"4"]
        }
    }

    func testMapInt32Bytes() {
        assertJSONEncode("{\"mapInt32Bytes\":{\"1\":\"\"}}") {(o: inout MessageTestType) in
            o.mapInt32Bytes = [1:Data()]
        }
        assertJSONDecodeSucceeds("{\"mapInt32Bytes\":{\"1\":\"\", \"2\":\"QUI=\", \"3\": \"AAA=\"}}") {$0.mapInt32Bytes == [1:Data(), 2: Data(bytes: [65, 66]), 3: Data(bytes: [0,0])]}
    }

    func testMapInt32Message() {
        assertJSONEncode("{\"mapInt32ForeignMessage\":{\"7\":{\"c\":999}}}") {(o: inout MessageTestType) in
            var m = Proto3ForeignMessage()
            m.c = 999
            o.mapInt32ForeignMessage[7] = m
        }
        assertJSONDecodeSucceeds("{\"mapInt32ForeignMessage\":{\"7\":{\"c\":7},\"8\":{\"c\":8}}}") {
            var sub7 = Proto3ForeignMessage()
            sub7.c = 7
            var sub8 = Proto3ForeignMessage()
            sub8.c = 8
            return $0.mapInt32ForeignMessage == [7:sub7, 8:sub8]
        }
    }

    func test_mapBoolBool() {
        assertDecodeSucceeds([106, 4, 8, 0, 16, 0]) {
            $0.mapBoolBool == [false: false]
        }
        assertJSONDecodeSucceeds("{\"mapBoolBool\": {\"true\": true, \"false\": false}}") {
            $0.mapBoolBool == [true: true, false: false]
        }
        assertJSONDecodeFails("{\"mapBoolBool\": {true: true}}")
        assertJSONDecodeFails("{\"mapBoolBool\": {false: false}}")
    }
}
