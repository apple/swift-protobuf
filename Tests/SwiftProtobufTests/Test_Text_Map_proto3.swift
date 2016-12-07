// Test/Sources/TestSuite/Test_Test_proto3.swift - Exercise proto3 text format coding
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
// -----------------------------------------------------------------------------
///
/// This is a set of tests for text format protobuf files.
///
// -----------------------------------------------------------------------------

import Foundation
import XCTest
import SwiftProtobuf

class Test_Text_Map_proto3: XCTestCase, PBTestHelpers {
    typealias MessageTestType = ProtobufUnittest_TestMap
    
    func test_Int32Int32() {
        assertTextEncode("map_int32_int32 {\n  key: 1\n  value: 2\n}\n") {(o: inout MessageTestType) in
            o.mapInt32Int32 = [1:2]
        }
        assertTextDecodeSucceeds("map_int32_int32 {key: 1, value: 2}") {(o: MessageTestType) in
            return o.mapInt32Int32 == [1:2]
        }
        assertTextDecodeSucceeds("map_int32_int32 {key: 1; value: 2}") {(o: MessageTestType) in
            return o.mapInt32Int32 == [1:2]
        }
        assertTextDecodeSucceeds("map_int32_int32 {key:1 value:2}") {(o: MessageTestType) in
            return o.mapInt32Int32 == [1:2]
        }
        assertTextDecodeSucceeds("map_int32_int32 {key:1 value:2}\nmap_int32_int32 {key:3 value:4}") {(o: MessageTestType) in
            return o.mapInt32Int32 == [1:2, 3:4]
        }
        assertTextDecodeSucceeds("map_int32_int32 [{key:1 value:2}, {key:3 value:4}]") {(o: MessageTestType) in
            return o.mapInt32Int32 == [1:2, 3:4]
        }
    }
}
