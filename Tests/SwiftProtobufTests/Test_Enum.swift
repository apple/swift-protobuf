// Tests/SwiftProtobufTests/Test_Enum.swift - Exercise generated enums
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
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
import SwiftProtobuf

final class Test_Enum: XCTestCase, PBTestHelpers {
    typealias MessageTestType = SwiftProtoTesting_Proto3_TestAllTypes

    func testEqual() {
        // The message from unittest.proto doesn't exist in unittest_proto3.proto
    }

    func testJSONsingular() {
        assertJSONEncode("{\"optionalNestedEnum\":\"FOO\"}") { (m: inout MessageTestType) in
            m.optionalNestedEnum = SwiftProtoTesting_Proto3_TestAllTypes.NestedEnum.foo
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

    func testJSONdecodingOptions() {
        var options = JSONDecodingOptions()

        let json_with_unknown_enum_single = "{\"optionalNestedEnum\":\"NEW_VALUE\"}"
        let json_with_unknown_enum_repeated = "{\"repeatedNestedEnum\":[\"FOO\",\"NEW_VALUE\", \"BAR\"]}"

        options.ignoreUnknownFields = false
        assertJSONDecodeFails(json_with_unknown_enum_single)
        assertJSONDecodeFails(json_with_unknown_enum_repeated)

        options.ignoreUnknownFields = true
        assertJSONDecodeSucceeds(json_with_unknown_enum_single, options: options) { (m: MessageTestType) -> Bool in
            // proto3 syntax, so the field should have the default value.
            m.optionalNestedEnum == .zero
        }
        assertJSONDecodeSucceeds(json_with_unknown_enum_repeated, options: options) { (m: MessageTestType) -> Bool in
          m.repeatedNestedEnum == [.foo, .bar]
        }

        // SwiftProtoTesting_Proto3_TestAllTypes doesn't have a map<>, Test_Map_JSON covers this case.
    }

    func testUnknownValues() throws {
        let orig = SwiftProtoTesting_UnknownEnum_Proto3_MyMessagePlusExtra.with {
            $0.e = .eExtra
            $0.repeatedE.append(.eExtra)
            $0.repeatedPackedE.append(.eExtra)
            $0.oneofE1 = .eExtra
        }

        let origSerialized: [UInt8] = try orig.serializedBytes()
        let msg = try SwiftProtoTesting_UnknownEnum_Proto3_MyMessage(serializedBytes: origSerialized)

        // Nothing in unknowns, they should just be unrecognized.
        XCTAssertEqual(msg.e, .UNRECOGNIZED(3))
        XCTAssertEqual(msg.repeatedE, [.UNRECOGNIZED(3)])
        XCTAssertEqual(msg.repeatedPackedE, [.UNRECOGNIZED(3)])
        XCTAssertEqual(msg.o, .oneofE1(.UNRECOGNIZED(3)))
        XCTAssertTrue(msg.unknownFields.data.isEmpty)

        let msgSerialized: [UInt8] = try msg.serializedBytes()
        XCTAssertEqual(origSerialized, msgSerialized)
    }

    func testEnumPrefixStripping() {
        // This is basicly a compile tests, it is ensuring the expected names were
        // generated, and compile failures mean things didn't generate as expected.

        // Note: "firstValue" and "secondValue" on these, the enum name has been removed.
        XCTAssertEqual(SwiftProtoTesting_Enum3_SwiftEnumTest.EnumTest1.firstValue.rawValue, 0)
        XCTAssertEqual(SwiftProtoTesting_Enum3_SwiftEnumTest.EnumTest1.secondValue.rawValue, 2)
        XCTAssertEqual(SwiftProtoTesting_Enum3_SwiftEnumTest.EnumTest2.firstValue.rawValue, 0)
        XCTAssertEqual(SwiftProtoTesting_Enum3_SwiftEnumTest.EnumTest2.secondValue.rawValue, 2)
        // And these don't use the enum name in the value names, so nothing is trimmed.
        XCTAssertEqual(SwiftProtoTesting_Enum3_SwiftEnumTest.EnumTestNoStem.enumTestNoStem1.rawValue, 0)
        XCTAssertEqual(SwiftProtoTesting_Enum3_SwiftEnumTest.EnumTestNoStem.enumTestNoStem2.rawValue, 2)
        // And this checks handing of reversed words, which means backticks are needed around
        // some of the generated code.
        XCTAssertEqual(SwiftProtoTesting_Enum3_SwiftEnumTest.EnumTestReservedWord.var.rawValue, 0)
        XCTAssertEqual(SwiftProtoTesting_Enum3_SwiftEnumTest.EnumTestReservedWord.notReserved.rawValue, 2)
    }

    func testEnumPrefixStripping_TextFormat() throws {
        var txt = "values1: [ENUM_TEST_1_FIRST_VALUE, ENUM_TEST_1_SECOND_VALUE]\n"
        var msg = SwiftProtoTesting_Enum3_SwiftEnumTest.with {
            $0.values1 = [ .firstValue, .secondValue ]
        }
        XCTAssertEqual(msg.textFormatString(), txt)
        var msg2 = try SwiftProtoTesting_Enum3_SwiftEnumTest(textFormatString: txt)
        XCTAssertEqual(msg2, msg)

        txt = "values2: [ENUM_TEST_2_FIRST_VALUE, SECOND_VALUE]\n"
        msg = SwiftProtoTesting_Enum3_SwiftEnumTest.with {
            $0.values2 = [ .firstValue, .secondValue ]
        }
        XCTAssertEqual(msg.textFormatString(), txt)
        msg2 = try SwiftProtoTesting_Enum3_SwiftEnumTest(textFormatString: txt)
        XCTAssertEqual(msg2, msg)

        txt = "values3: [ENUM_TEST_NO_STEM_1, ENUM_TEST_NO_STEM_2]\n"
        msg = SwiftProtoTesting_Enum3_SwiftEnumTest.with {
            $0.values3 = [ .enumTestNoStem1, .enumTestNoStem2 ]
        }
        XCTAssertEqual(msg.textFormatString(), txt)
        msg2 = try SwiftProtoTesting_Enum3_SwiftEnumTest(textFormatString: txt)
        XCTAssertEqual(msg2, msg)

        txt = "values4: [ENUM_TEST_RESERVED_WORD_VAR, ENUM_TEST_RESERVED_WORD_NOT_RESERVED]\n"
        msg = SwiftProtoTesting_Enum3_SwiftEnumTest.with {
            $0.values4 = [ .var, .notReserved ]
        }
        XCTAssertEqual(msg.textFormatString(), txt)
        msg2 = try SwiftProtoTesting_Enum3_SwiftEnumTest(textFormatString: txt)
        XCTAssertEqual(msg2, msg)
    }

    func testEnumPrefixStripping_JSON() throws {
        var json = "{\"values1\":[\"ENUM_TEST_1_FIRST_VALUE\",\"ENUM_TEST_1_SECOND_VALUE\"]}"
        var msg = SwiftProtoTesting_Enum3_SwiftEnumTest.with {
            $0.values1 = [ .firstValue, .secondValue ]
        }
        XCTAssertEqual(try msg.jsonString(), json)
        var msg2 = try SwiftProtoTesting_Enum3_SwiftEnumTest(jsonString: json)
        XCTAssertEqual(msg2, msg)

        json = "{\"values2\":[\"ENUM_TEST_2_FIRST_VALUE\",\"SECOND_VALUE\"]}"
        msg = SwiftProtoTesting_Enum3_SwiftEnumTest.with {
            $0.values2 = [ .firstValue, .secondValue ]
        }
        XCTAssertEqual(try msg.jsonString(), json)
        msg2 = try SwiftProtoTesting_Enum3_SwiftEnumTest(jsonString: json)
        XCTAssertEqual(msg2, msg)

        json = "{\"values3\":[\"ENUM_TEST_NO_STEM_1\",\"ENUM_TEST_NO_STEM_2\"]}"
        msg = SwiftProtoTesting_Enum3_SwiftEnumTest.with {
            $0.values3 = [ .enumTestNoStem1, .enumTestNoStem2 ]
        }
        XCTAssertEqual(try msg.jsonString(), json)
        msg2 = try SwiftProtoTesting_Enum3_SwiftEnumTest(jsonString: json)
        XCTAssertEqual(msg2, msg)

        json = "{\"values4\":[\"ENUM_TEST_RESERVED_WORD_VAR\",\"ENUM_TEST_RESERVED_WORD_NOT_RESERVED\"]}"
        msg = SwiftProtoTesting_Enum3_SwiftEnumTest.with {
            $0.values4 = [ .var, .notReserved ]
        }
        XCTAssertEqual(try msg.jsonString(), json)
        msg2 = try SwiftProtoTesting_Enum3_SwiftEnumTest(jsonString: json)
        XCTAssertEqual(msg2, msg)
    }

    func testCaseIterable() {
      // Open enums require the generator to create allCases,
      // ensure it is works as expected (order of the file, no aliases).
      var i = SwiftProtoTesting_Enum3_SwiftEnumWithAliasTest.EnumWithAlias.allCases.makeIterator()
      guard let e1 = i.next() else {
          XCTFail("Couldn't get first value")
          return
      }
      guard let e2 = i.next() else {
          XCTFail("Couldn't get second value")
          return
      }
      guard let e3 = i.next() else {
          XCTFail("Couldn't get third value")
          return
      }
      // Should be the end.
      XCTAssertNil(i.next())

      XCTAssertEqual(e1, .foo1)
      XCTAssertEqual(e2, .baz1)
      XCTAssertEqual(e3, .bar1)
    }
}
