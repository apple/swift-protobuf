// Tests/SwiftProtobufTests/Test_Enum.swift - Exercise generated enums
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

class Test_Enum: XCTestCase, PBTestHelpers {
    typealias MessageTestType = Proto3Unittest_TestAllTypes

    func testEqual() {
        XCTAssertEqual(ProtobufUnittest_TestEnumWithDupValue.foo1, ProtobufUnittest_TestEnumWithDupValue.foo2)
        XCTAssertNotEqual(ProtobufUnittest_TestEnumWithDupValue.foo1, ProtobufUnittest_TestEnumWithDupValue.bar1)
    }

    func testJSONsingular() {
        assertJSONEncode("{\"optionalNestedEnum\":\"FOO\"}") { (m: inout MessageTestType) in
            m.optionalNestedEnum = Proto3Unittest_TestAllTypes.NestedEnum.foo
        }

        assertJSONEncode("{\"optionalNestedEnum\":777}") { (m: inout MessageTestType) in
            m.optionalNestedEnum = .UNRECOGNIZED(777)
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
        XCTAssertEqual(ProtobufUnittest_SwiftEnumTest.EnumTest2.firstValue.rawValue, 1)
        XCTAssertEqual(ProtobufUnittest_SwiftEnumTest.EnumTest2.secondValue.rawValue, 2)
    }

    func testUnknownValues() throws {
        let orig = Proto3PreserveUnknownEnumUnittest_MyMessagePlusExtra.with {
            $0.e = .eExtra
            $0.repeatedE.append(.eExtra)
            $0.repeatedPackedE.append(.eExtra)
            $0.oneofE1 = .eExtra
        }

        let origSerialized = try orig.serializedData()
        let msg = try Proto3PreserveUnknownEnumUnittest_MyMessage(serializedData: origSerialized)

        // Nothing in unknowns, they should just be unrecognized.
        XCTAssertEqual(msg.e, .UNRECOGNIZED(3))
        XCTAssertEqual(msg.repeatedE, [.UNRECOGNIZED(3)])
        XCTAssertEqual(msg.repeatedPackedE, [.UNRECOGNIZED(3)])
        XCTAssertEqual(msg.o, .oneofE1(.UNRECOGNIZED(3)))
        XCTAssertTrue(msg.unknownFields.data.isEmpty)

        let msgSerialized = try msg.serializedData()
        XCTAssertEqual(origSerialized, msgSerialized)
    }
}
