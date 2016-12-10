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
/// Google has not specified a JSON coding for groups. The C++ implementation
/// fails when decoding a JSON string that contains a group, so we verify that
/// we do the same for consistency.
///
// -----------------------------------------------------------------------------

import Foundation
import XCTest

class Test_JSON_Group: XCTestCase, PBTestHelpers {
    typealias MessageTestType = ProtobufUnittest_TestAllTypes

    func testOptionalGroup() {
        assertJSONDecodeFails("{\"optionalgroup\":{\"a\":3}}")
    }

    func testRepeatedGroup() {
        assertJSONDecodeFails("{\"repeatedgroup\":[{\"a\":1},{\"a\":2}]}")
    }
}
