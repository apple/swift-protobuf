// Test/Sources/TestSuite/Test_Enum.swift - Exercise generated enums
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
/// Check that proto enums are properly translated into Swift enums.  Among
/// other things, enums can have duplicate tags, the names should be correctly
/// translated into Swift lowerCamelCase conventions, etc.
///
// -----------------------------------------------------------------------------

import XCTest

class Test_Enum: XCTestCase, PBTestHelpers {
    typealias MessageTestType = Proto3TestAllTypes

    func testEqual() {
        XCTAssertEqual(Proto3TestEnumWithDupValue.foo1, Proto3TestEnumWithDupValue.foo2)
        XCTAssertNotEqual(Proto3TestEnumWithDupValue.foo1, Proto3TestEnumWithDupValue.bar1)
        XCTAssertEqual(Proto3TestEnumWithDupValue(name:"foo1"), Proto3TestEnumWithDupValue.foo2)
    }

    func testJSONsingular() {
        assertJSONEncode("{\"singleNestedEnum\":\"FOO\"}") { (m: inout MessageTestType) in
            m.singleNestedEnum = Proto3TestAllTypes.NestedEnum.foo
        }

        assertJSONEncode("{\"singleNestedEnum\":777}") { (m: inout MessageTestType) in
            m.singleNestedEnum = .UNRECOGNIZED(777)
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
