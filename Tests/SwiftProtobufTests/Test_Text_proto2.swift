// Tests/SwiftProtobufTests/Test_Text_proto2.swift - Exercise proto3 text format coding
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

class Test_Text_proto2: XCTestCase, PBTestHelpers {
    typealias MessageTestType = ProtobufUnittest_TestAllTypes
    
    func test_group() {
        assertTextEncode("OptionalGroup {\n  a: 17\n}\n") {(o: inout MessageTestType) in
            o.optionalGroup = ProtobufUnittest_TestAllTypes.OptionalGroup.with {$0.a = 17}
        }
    }
    
    func test_repeatedGroup() {
        assertTextEncode("RepeatedGroup {\n  a: 17\n}\nRepeatedGroup {\n  a: 18\n}\n") {(o: inout MessageTestType) in
            let group17 = ProtobufUnittest_TestAllTypes.RepeatedGroup.with {$0.a = 17}
            let group18 = ProtobufUnittest_TestAllTypes.RepeatedGroup.with {$0.a = 18}
            o.repeatedGroup = [group17, group18]
        }
    }
}
