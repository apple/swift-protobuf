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
    typealias MessageTestType = Proto3TestAllTypes

    func testEqual() {
        XCTAssertEqual(Proto3TestEnumWithDupValue.foo1, Proto3TestEnumWithDupValue.foo2)
        XCTAssertNotEqual(Proto3TestEnumWithDupValue.foo1, Proto3TestEnumWithDupValue.bar1)
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
