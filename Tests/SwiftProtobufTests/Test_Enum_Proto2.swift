// Tests/SwiftProtobufTests/Test_Enum_Proto2.swift - Exercise generated enums
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Check that proto enums are properly translated into Swift enums.  Among
/// other things, enums can have duplicate tags, the names should be correctly
/// translated into Swift lowerCamelCase conventions, etc.
///
// -----------------------------------------------------------------------------

import Foundation
import XCTest

class Test_Enum_Proto2: XCTestCase, PBTestHelpers {
    typealias MessageTestType = ProtobufUnittest_TestAllTypes

    func testEqual() {
        XCTAssertEqual(ProtobufUnittest_TestEnumWithDupValue.foo1, ProtobufUnittest_TestEnumWithDupValue.foo2)
        XCTAssertNotEqual(ProtobufUnittest_TestEnumWithDupValue.foo1, ProtobufUnittest_TestEnumWithDupValue.bar1)
    }

    func testUnknownIgnored() {
        // Proto2 requires that unknown enum values be dropped or ignored.
        assertJSONDecodeSucceeds("{\"optionalNestedEnum\":\"FOO\"}") { (m: MessageTestType) -> Bool in
            // If this compiles, then it includes all cases.
            // If it fails to compile because it's missing an "UNRECOGNIZED" case,
            // the code generator has created an UNRECOGNIZED case that should not be there.
            switch m.optionalNestedEnum {
            case .foo: return true
            case .bar: return false
            case .baz: return false
            case .neg: return false
            // DO NOT ADD A DEFAULT CASE TO THIS SWITCH!!!
            }
        }
    }

    func testJSONsingular() {
        assertJSONEncode("{\"optionalNestedEnum\":\"FOO\"}") { (m: inout MessageTestType) in
            m.optionalNestedEnum = ProtobufUnittest_TestAllTypes.NestedEnum.foo
        }
    }

    func testJSONrepeated() {
        assertJSONEncode("{\"repeatedNestedEnum\":[\"FOO\",\"BAR\"]}") { (m: inout MessageTestType) in
            m.repeatedNestedEnum = [.foo, .bar]
        }
    }

    func testEnumPrefix() {
        XCTAssertEqual(ProtobufUnittest_SwiftEnumTest.EnumTest1.firstValue.rawValue, 1)
        XCTAssertEqual(ProtobufUnittest_SwiftEnumTest.EnumTest1.secondValue.rawValue, 2)
        XCTAssertEqual(ProtobufUnittest_SwiftEnumTest.EnumTest2.enumTest2FirstValue.rawValue, 1)
        XCTAssertEqual(ProtobufUnittest_SwiftEnumTest.EnumTest2.secondValue.rawValue, 2)
    }
}
