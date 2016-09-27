// Test/Sources/TestSuite/Test_JSON_Group.swift - Exercise JSON coding for groups
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
/// Google has not specified a JSON coding for groups.  But proto3 types
/// can use proto2 types and vice-versa, so it seems reasonable to support
/// JSON coding for proto2 groups.
///
/// This implementation treats groups just like messages for the purposes
/// of JSON encoding.
///
// -----------------------------------------------------------------------------

import Foundation
import XCTest

class Test_JSON_Group: XCTestCase, PBTestHelpers {
    typealias MessageTestType = ProtobufUnittest_TestAllTypes

    func testOptionalGroup() {
        assertJSONEncode("{\"optionalgroup\":{\"a\":3}}") {(o: inout MessageTestType) in
            var g = MessageTestType.OptionalGroup()
            g.a = 3
            o.optionalGroup = g
        }
    }

    func testRepeatedGroup() {
        assertJSONEncode("{\"repeatedgroup\":[{\"a\":1},{\"a\":2}]}") {(o: inout MessageTestType) in
            var g1 = MessageTestType.RepeatedGroup()
            g1.a = 1
            var g2 = MessageTestType.RepeatedGroup()
            g2.a = 2
            o.repeatedGroup = [g1, g2]
        }
    }
}
