// Tests/SwiftProtobufTests/Test_MessageSet.swift - Test MessageSet behaviors
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Test all behaviors around the message option message_set_wire_format.
///
// -----------------------------------------------------------------------------

import Foundation
import XCTest
@testable import SwiftProtobuf

extension SwiftProtoTesting_RawMessageSet.Item {
  fileprivate init(typeID: Int, message: Data) {
    self.init()
    self.typeID = Int32(typeID)
    self.message = message
  }
}

final class Test_MessageSet: XCTestCase {

  // wireformat_unittest.cc: TEST(WireFormatTest, SerializeMessageSet)
  func testSerialize() throws {
    let msg = SwiftProtoTesting_WireFormat_TestMessageSet.with {
      $0.SwiftProtoTesting_TestMessageSetExtension1_messageSetExtension.i = 123
      $0.SwiftProtoTesting_TestMessageSetExtension2_messageSetExtension.str = "foo"
    }

    let serialized: [UInt8]
    do {
      serialized = try msg.serializedBytes()
    } catch let e {
      XCTFail("Failed to serialize: \(e)")
      return
    }

    // Read it back in with the RawMessageSet to validate it.

    let raw: SwiftProtoTesting_RawMessageSet
    do {
      raw = try SwiftProtoTesting_RawMessageSet(serializedBytes: serialized)
    } catch let e {
      XCTFail("Failed to parse: \(e)")
      return
    }

    XCTAssertTrue(raw.unknownFields.data.isEmpty)

    XCTAssertEqual(raw.item.count, 2)

    XCTAssertEqual(Int(raw.item[0].typeID),
                   SwiftProtoTesting_TestMessageSetExtension1.Extensions.message_set_extension.fieldNumber)
    XCTAssertEqual(Int(raw.item[1].typeID),
                   SwiftProtoTesting_TestMessageSetExtension2.Extensions.message_set_extension.fieldNumber)

    let extMsg1 = try SwiftProtoTesting_TestMessageSetExtension1(serializedBytes: raw.item[0].message)
    XCTAssertEqual(extMsg1.i, 123)
    XCTAssertTrue(extMsg1.unknownFields.data.isEmpty)
    let extMsg2 = try SwiftProtoTesting_TestMessageSetExtension2(serializedBytes: raw.item[1].message)
    XCTAssertEqual(extMsg2.str, "foo")
    XCTAssertTrue(extMsg2.unknownFields.data.isEmpty)
  }

  // wireformat_unittest.cc: TEST(WireFormatTest, ParseMessageSet)
  func testParse() throws {
    let msg1 = SwiftProtoTesting_TestMessageSetExtension1.with { $0.i = 123 }
    let msg2 = SwiftProtoTesting_TestMessageSetExtension2.with { $0.str = "foo" }
    var raw = SwiftProtoTesting_RawMessageSet()
    raw.item = [
      // Two known extensions.
      SwiftProtoTesting_RawMessageSet.Item(
        typeID: SwiftProtoTesting_TestMessageSetExtension1.Extensions.message_set_extension.fieldNumber,
        message: try msg1.serializedBytes()),
      SwiftProtoTesting_RawMessageSet.Item(
        typeID: SwiftProtoTesting_TestMessageSetExtension2.Extensions.message_set_extension.fieldNumber,
        message: try msg2.serializedBytes()),
      // One unknown extension.
      SwiftProtoTesting_RawMessageSet.Item(typeID: 7, message: Data([1, 2, 3]))
    ]
    // Add some unknown data into one of the groups to ensure it gets stripped when parsing.
    raw.item[1].unknownFields.append(protobufData: Data([40, 2]))  // Field 5, varint of 2

    let serialized: Data
    do {
      serialized = try raw.serializedBytes()
    } catch let e {
      XCTFail("Failed to serialize: \(e)")
      return
    }

    let msg: SwiftProtoTesting_WireFormat_TestMessageSet
    do {
      msg = try SwiftProtoTesting_WireFormat_TestMessageSet(
        serializedBytes: serialized,
        extensions: SwiftProtoTesting_UnittestMset_Extensions)
    } catch let e {
      XCTFail("Failed to parse: \(e)")
      return
    }

    // Ensure the extensions showed up, but with nothing extra.
    XCTAssertEqual(
      msg.SwiftProtoTesting_TestMessageSetExtension1_messageSetExtension.i, 123)
    XCTAssertTrue(
      msg.SwiftProtoTesting_TestMessageSetExtension1_messageSetExtension.unknownFields.data.isEmpty)
    XCTAssertEqual(
      msg.SwiftProtoTesting_TestMessageSetExtension2_messageSetExtension.str, "foo")
    XCTAssertTrue(
      msg.SwiftProtoTesting_TestMessageSetExtension2_messageSetExtension.unknownFields.data.isEmpty)

    // Ensure the unknown shows up as a group.
    let expectedUnknowns = Data([
      11,  // Start group
      16, 7, // typeID = 7
      26, 3, 1, 2, 3, // message data = 3 bytes: 1, 2, 3
      12   // End Group
    ])
    XCTAssertEqual(msg.unknownFields.data, expectedUnknowns)

    var validator = ExtensionValidator()
    validator.expectedMessages = [
      (SwiftProtoTesting_TestMessageSetExtension1.Extensions.message_set_extension.fieldNumber, false),
      (SwiftProtoTesting_TestMessageSetExtension2.Extensions.message_set_extension.fieldNumber, false),
    ]
    validator.expectedUnknowns = [ expectedUnknowns ]
    validator.validate(message: msg)
  }

  static let canonicalTextFormat: String = (
    "message_set {\n" +
      "  [swift_proto_testing.TestMessageSetExtension1] {\n" +
      "    i: 23\n" +
      "  }\n" +
      "  [swift_proto_testing.TestMessageSetExtension2] {\n" +
      "    str: \"foo\"\n" +
      "  }\n" +
    "}\n"
  )

  func testParseOrder1() throws {
    let serialized = Data([11,
        16, 176, 166, 94, // Extension ID
        26, 2, 120, 123, // Payload message
        12])

    let msg: SwiftProtoTesting_WireFormat_TestMessageSet
    do {
      msg = try SwiftProtoTesting_WireFormat_TestMessageSet(
        serializedBytes: serialized,
        extensions: SwiftProtoTesting_UnittestMset_Extensions)
    } catch let e {
      XCTFail("Failed to parse: \(e)")
      return
    }
    XCTAssertEqual(
      msg.SwiftProtoTesting_TestMessageSetExtension1_messageSetExtension.i, 123)
  }

  func testParseOrder2() throws {
    let serialized = Data([11,
        26, 2, 120, 123, // Payload message
        16, 176, 166, 94, // Extension ID
        12])

    let msg: SwiftProtoTesting_WireFormat_TestMessageSet
    do {
      msg = try SwiftProtoTesting_WireFormat_TestMessageSet(
        serializedBytes: serialized,
        extensions: SwiftProtoTesting_UnittestMset_Extensions)
    } catch let e {
      XCTFail("Failed to parse: \(e)")
      return
    }
    XCTAssertEqual(
      msg.SwiftProtoTesting_TestMessageSetExtension1_messageSetExtension.i, 123)
  }

  // text_format_unittest.cc: TEST_F(TextFormatMessageSetTest, Serialize)
  func testTextFormat_Serialize() {
    let msg = SwiftProtoTesting_TestMessageSetContainer.with {
      $0.messageSet.SwiftProtoTesting_TestMessageSetExtension1_messageSetExtension.i = 23
      $0.messageSet.SwiftProtoTesting_TestMessageSetExtension2_messageSetExtension.str = "foo"
    }

    XCTAssertEqual(msg.textFormatString(), Test_MessageSet.canonicalTextFormat)
  }

  // text_format_unittest.cc: TEST_F(TextFormatMessageSetTest, Deserialize)
  func testTextFormat_Parse() {
    let msg: SwiftProtoTesting_TestMessageSetContainer
    do {
      msg = try SwiftProtoTesting_TestMessageSetContainer(
        textFormatString: Test_MessageSet.canonicalTextFormat,
        extensions: SwiftProtoTesting_UnittestMset_Extensions)
    } catch let e {
      XCTFail("Shouldn't have failed: \(e)")
      return
    }

    XCTAssertEqual(
      msg.messageSet.SwiftProtoTesting_TestMessageSetExtension1_messageSetExtension.i, 23)
    XCTAssertEqual(
      msg.messageSet.SwiftProtoTesting_TestMessageSetExtension2_messageSetExtension.str, "foo")

    // Ensure nothing else showed up.
    XCTAssertTrue(msg.unknownFields.data.isEmpty)
    XCTAssertTrue(msg.messageSet.unknownFields.data.isEmpty)

    var validator = ExtensionValidator()
    validator.expectedMessages = [
      (1, true), // swift_proto_testing.TestMessageSetContainer.message_set (where the extensions are)
      (SwiftProtoTesting_TestMessageSetExtension1.Extensions.message_set_extension.fieldNumber, false),
      (SwiftProtoTesting_TestMessageSetExtension2.Extensions.message_set_extension.fieldNumber, false),
    ]
    validator.validate(message: msg)
  }

  fileprivate struct ExtensionValidator: PBTestVisitor {
    // Values are field number and if we should recurse.
    var expectedMessages = [(Int, Bool)]()
    var expectedUnknowns = [Data]()

    mutating func validate<M: Message>(message: M) {
      do {
        try message.traverse(visitor: &self)
      } catch let e {
        XCTFail("Error while traversing: \(e)")
      }
      XCTAssertTrue(expectedMessages.isEmpty,
                    "Expected more messages: \(expectedMessages)")
      XCTAssertTrue(expectedUnknowns.isEmpty,
                    "Expected more unknowns: \(expectedUnknowns)")
    }

    mutating func visitSingularMessageField<M: Message>(value: M, fieldNumber: Int) throws {
      guard !expectedMessages.isEmpty else {
        XCTFail("Unexpected Message: \(fieldNumber) = \(value)")
        return
      }
      let (expected, shouldRecurse) = expectedMessages.removeFirst()
      XCTAssertEqual(fieldNumber, expected)
      if shouldRecurse && expected == fieldNumber {
        try value.traverse(visitor: &self)
      }
    }

    mutating func visitUnknown(bytes: Data) throws {
      guard !expectedUnknowns.isEmpty else {
        XCTFail("Unexpected Unknown: \(bytes)")
        return
      }
      let expected = expectedUnknowns.removeFirst()
      XCTAssertEqual(bytes, expected)
    }
  }
}
