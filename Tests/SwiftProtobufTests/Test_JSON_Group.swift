// Tests/SwiftProtobufTests/Test_JSON_Group.swift - Exercise JSON coding for groups
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
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

final class Test_JSON_Group: XCTestCase, PBTestHelpers {
    typealias MessageTestType = SwiftProtoTesting_TestAllTypes

    func testOptionalGroup() {
        assertJSONEncode("{\"optionalgroup\":{\"a\":3}}") {(o: inout MessageTestType) in
          o.optionalGroup.a = 3
        }
    }

    func testRepeatedGroup() {
        assertJSONEncode("{\"repeatedgroup\":[{\"a\":1},{\"a\":2}]}") {(o: inout MessageTestType) in
          let one = SwiftProtoTesting_TestAllTypes.RepeatedGroup.with {
            $0.a = 1
          }
          let two = SwiftProtoTesting_TestAllTypes.RepeatedGroup.with {
            $0.a = 2
          }
          o.repeatedGroup = [one, two]
        }
    }
}
