// Test/Sources/TestSuite/Test_BasicFields_Access_Proto3.swift
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Exercises the apis for optional & repeated fields.
///
// -----------------------------------------------------------------------------

import XCTest
import Foundation

// NOTE: The generator changes what is generated based on the number/types
// of fields (using a nested storage class or not), to be completel, all
// these tests should be done once with a message that gets that storage
// class and a second time with messages that avoid that.

class Test_BasicFields_Access_Proto3: XCTestCase {

  // Optional

  func testOptionalInt32() {
    var msg = Proto3TestAllTypes()
    XCTAssertEqual(msg.singleInt32, 0)
    msg.singleInt32 = 1
    XCTAssertEqual(msg.singleInt32, 1)
  }

  func testOptionalInt64() {
    var msg = Proto3TestAllTypes()
    XCTAssertEqual(msg.singleInt64, 0)
    msg.singleInt64 = 2
    XCTAssertEqual(msg.singleInt64, 2)
  }

  func testOptionalUint32() {
    var msg = Proto3TestAllTypes()
    XCTAssertEqual(msg.singleUint32, 0)
    msg.singleUint32 = 3
    XCTAssertEqual(msg.singleUint32, 3)
  }

  func testOptionalUint64() {
    var msg = Proto3TestAllTypes()
    XCTAssertEqual(msg.singleUint64, 0)
    msg.singleUint64 = 4
    XCTAssertEqual(msg.singleUint64, 4)
  }

  func testOptionalSint32() {
    var msg = Proto3TestAllTypes()
    XCTAssertEqual(msg.singleSint32, 0)
    msg.singleSint32 = 5
    XCTAssertEqual(msg.singleSint32, 5)
  }

  func testOptionalSint64() {
    var msg = Proto3TestAllTypes()
    XCTAssertEqual(msg.singleSint64, 0)
    msg.singleSint64 = 6
    XCTAssertEqual(msg.singleSint64, 6)
  }

  func testOptionalFixed32() {
    var msg = Proto3TestAllTypes()
    XCTAssertEqual(msg.singleFixed32, 0)
    msg.singleFixed32 = 7
    XCTAssertEqual(msg.singleFixed32, 7)
  }

  func testOptionalFixed64() {
    var msg = Proto3TestAllTypes()
    XCTAssertEqual(msg.singleFixed64, 0)
    msg.singleFixed64 = 8
    XCTAssertEqual(msg.singleFixed64, 8)
  }

  func testOptionalSfixed32() {
    var msg = Proto3TestAllTypes()
    XCTAssertEqual(msg.singleSfixed32, 0)
    msg.singleSfixed32 = 9
    XCTAssertEqual(msg.singleSfixed32, 9)
  }

  func testOptionalSfixed64() {
    var msg = Proto3TestAllTypes()
    XCTAssertEqual(msg.singleSfixed64, 0)
    msg.singleSfixed64 = 10
    XCTAssertEqual(msg.singleSfixed64, 10)
  }

  func testOptionalFloat() {
    var msg = Proto3TestAllTypes()
    XCTAssertEqual(msg.singleFloat, 0.0)
    msg.singleFloat = 11.0
    XCTAssertEqual(msg.singleFloat, 11.0)
  }

  func testOptionalDouble() {
    var msg = Proto3TestAllTypes()
    XCTAssertEqual(msg.singleDouble, 0.0)
    msg.singleDouble = 12.0
    XCTAssertEqual(msg.singleDouble, 12.0)
  }

  func testOptionalBool() {
    var msg = Proto3TestAllTypes()
    XCTAssertEqual(msg.singleBool, false)
    msg.singleBool = true
    XCTAssertEqual(msg.singleBool, true)
  }

  func testOptionalString() {
    var msg = Proto3TestAllTypes()
    XCTAssertEqual(msg.singleString, "")
    msg.singleString = "14"
    XCTAssertEqual(msg.singleString, "14")
  }

  func testOptionalBytes() {
    var msg = Proto3TestAllTypes()
    XCTAssertEqual(msg.singleBytes, Data())
    msg.singleBytes = Data([15])
    XCTAssertEqual(msg.singleBytes, Data([15]))
  }

  func testOptionalNestedMessage() {
    var msg = Proto3TestAllTypes()
    XCTAssertEqual(msg.singleNestedMessage.bb, 0)
    var nestedMsg = Proto3TestAllTypes.NestedMessage()
    nestedMsg.bb = 18
    msg.singleNestedMessage = nestedMsg
    XCTAssertEqual(msg.singleNestedMessage.bb, 18)
    XCTAssertEqual(msg.singleNestedMessage, nestedMsg)
  }

  func testOptionalForeignMessage() {
    var msg = Proto3TestAllTypes()
    XCTAssertEqual(msg.singleForeignMessage.c, 0)
    var foreignMsg = Proto3ForeignMessage()
    foreignMsg.c = 19
    msg.singleForeignMessage = foreignMsg
    XCTAssertEqual(msg.singleForeignMessage.c, 19)
    XCTAssertEqual(msg.singleForeignMessage, foreignMsg)
  }

  func testOptionalImportMessage() {
    var msg = Proto3TestAllTypes()
    XCTAssertEqual(msg.singleImportMessage.d, 0)
    var importedMsg = Proto3ImportMessage()
    importedMsg.d = 20
    msg.singleImportMessage = importedMsg
    XCTAssertEqual(msg.singleImportMessage.d, 20)
    XCTAssertEqual(msg.singleImportMessage, importedMsg)
  }

  func testOptionalNestedEnum() {
    var msg = Proto3TestAllTypes()
    XCTAssertEqual(msg.singleNestedEnum, .unspecified)
    msg.singleNestedEnum = .bar
    XCTAssertEqual(msg.singleNestedEnum, .bar)
  }

  func testOptionalForeignEnum() {
    var msg = Proto3TestAllTypes()
    XCTAssertEqual(msg.singleForeignEnum, .foreignUnspecified)
    msg.singleForeignEnum = .foreignBar
    XCTAssertEqual(msg.singleForeignEnum, .foreignBar)
  }

  func testOptionalImportEnum() {
    var msg = Proto3TestAllTypes()
    XCTAssertEqual(msg.singleImportEnum, .unspecified)
    msg.singleImportEnum = .importBar
    XCTAssertEqual(msg.singleImportEnum, .importBar)
  }

  func testOptionalPublicImportMessage() {
    var msg = Proto3TestAllTypes()
    XCTAssertEqual(msg.singlePublicImportMessage.e, 0)
    var pubImportedMsg = Proto3PublicImportMessage()
    pubImportedMsg.e = 26
    msg.singlePublicImportMessage = pubImportedMsg
    XCTAssertEqual(msg.singlePublicImportMessage.e, 26)
    XCTAssertEqual(msg.singlePublicImportMessage, pubImportedMsg)
  }

  // Repeated

  func testRepeatedInt32() {
    var msg = Proto3TestAllTypes()
    XCTAssertEqual(msg.repeatedInt32, [])
    msg.repeatedInt32 = [31]
    XCTAssertEqual(msg.repeatedInt32, [31])
    msg.repeatedInt32.append(131)
    XCTAssertEqual(msg.repeatedInt32, [31, 131])
  }

  func testRepeatedInt64() {
    var msg = Proto3TestAllTypes()
    XCTAssertEqual(msg.repeatedInt64, [])
    msg.repeatedInt64 = [32]
    XCTAssertEqual(msg.repeatedInt64, [32])
    msg.repeatedInt64.append(132)
    XCTAssertEqual(msg.repeatedInt64, [32, 132])
  }

  func testRepeatedUint32() {
    var msg = Proto3TestAllTypes()
    XCTAssertEqual(msg.repeatedUint32, [])
    msg.repeatedUint32 = [33]
    XCTAssertEqual(msg.repeatedUint32, [33])
    msg.repeatedUint32.append(133)
    XCTAssertEqual(msg.repeatedUint32, [33, 133])
  }

  func testRepeatedUint64() {
    var msg = Proto3TestAllTypes()
    XCTAssertEqual(msg.repeatedUint64, [])
    msg.repeatedUint64 = [34]
    XCTAssertEqual(msg.repeatedUint64, [34])
    msg.repeatedUint64.append(134)
    XCTAssertEqual(msg.repeatedUint64, [34, 134])
  }

  func testRepeatedSint32() {
    var msg = Proto3TestAllTypes()
    XCTAssertEqual(msg.repeatedSint32, [])
    msg.repeatedSint32 = [35]
    XCTAssertEqual(msg.repeatedSint32, [35])
    msg.repeatedSint32.append(135)
    XCTAssertEqual(msg.repeatedSint32, [35, 135])
  }

  func testRepeatedSint64() {
    var msg = Proto3TestAllTypes()
    XCTAssertEqual(msg.repeatedSint64, [])
    msg.repeatedSint64 = [36]
    XCTAssertEqual(msg.repeatedSint64, [36])
    msg.repeatedSint64.append(136)
    XCTAssertEqual(msg.repeatedSint64, [36, 136])
  }

  func testRepeatedFixed32() {
    var msg = Proto3TestAllTypes()
    XCTAssertEqual(msg.repeatedFixed32, [])
    msg.repeatedFixed32 = [37]
    XCTAssertEqual(msg.repeatedFixed32, [37])
    msg.repeatedFixed32.append(137)
    XCTAssertEqual(msg.repeatedFixed32, [37, 137])
  }

  func testRepeatedFixed64() {
    var msg = Proto3TestAllTypes()
    XCTAssertEqual(msg.repeatedFixed64, [])
    msg.repeatedFixed64 = [38]
    XCTAssertEqual(msg.repeatedFixed64, [38])
    msg.repeatedFixed64.append(138)
    XCTAssertEqual(msg.repeatedFixed64, [38, 138])
  }

  func testRepeatedSfixed32() {
    var msg = Proto3TestAllTypes()
    XCTAssertEqual(msg.repeatedSfixed32, [])
    msg.repeatedSfixed32 = [39]
    XCTAssertEqual(msg.repeatedSfixed32, [39])
    msg.repeatedSfixed32.append(139)
    XCTAssertEqual(msg.repeatedSfixed32, [39, 139])
  }

  func testRepeatedSfixed64() {
    var msg = Proto3TestAllTypes()
    XCTAssertEqual(msg.repeatedSfixed64, [])
    msg.repeatedSfixed64 = [40]
    XCTAssertEqual(msg.repeatedSfixed64, [40])
    msg.repeatedSfixed64.append(140)
    XCTAssertEqual(msg.repeatedSfixed64, [40, 140])
  }

  func testRepeatedFloat() {
    var msg = Proto3TestAllTypes()
    XCTAssertEqual(msg.repeatedFloat, [])
    msg.repeatedFloat = [41.0]
    XCTAssertEqual(msg.repeatedFloat, [41.0])
    msg.repeatedFloat.append(141.0)
    XCTAssertEqual(msg.repeatedFloat, [41.0, 141.0])
  }

  func testRepeatedDouble() {
    var msg = Proto3TestAllTypes()
    XCTAssertEqual(msg.repeatedDouble, [])
    msg.repeatedDouble = [42.0]
    XCTAssertEqual(msg.repeatedDouble, [42.0])
    msg.repeatedDouble.append(142.0)
    XCTAssertEqual(msg.repeatedDouble, [42.0, 142.0])
  }

  func testRepeatedBool() {
    var msg = Proto3TestAllTypes()
    XCTAssertEqual(msg.repeatedBool, [])
    msg.repeatedBool = [true]
    XCTAssertEqual(msg.repeatedBool, [true])
    msg.repeatedBool.append(false)
    XCTAssertEqual(msg.repeatedBool, [true, false])
  }

  func testRepeatedString() {
    var msg = Proto3TestAllTypes()
    XCTAssertEqual(msg.repeatedString, [])
    msg.repeatedString = ["44"]
    XCTAssertEqual(msg.repeatedString, ["44"])
    msg.repeatedString.append("144")
    XCTAssertEqual(msg.repeatedString, ["44", "144"])
  }

  func testRepeatedBytes() {
    var msg = Proto3TestAllTypes()
    XCTAssertEqual(msg.repeatedBytes, [])
    msg.repeatedBytes = [Data([45])]
    XCTAssertEqual(msg.repeatedBytes, [Data([45])])
    msg.repeatedBytes.append(Data([145]))
    XCTAssertEqual(msg.repeatedBytes, [Data([45]), Data([145])])
  }

  func testRepeatedNestedMessage() {
    var msg = Proto3TestAllTypes()
    XCTAssertEqual(msg.repeatedNestedMessage, [])
    var nestedMsg = Proto3TestAllTypes.NestedMessage()
    nestedMsg.bb = 48
    msg.repeatedNestedMessage = [nestedMsg]
    XCTAssertEqual(msg.repeatedNestedMessage.count, 1)
    XCTAssertEqual(msg.repeatedNestedMessage[0].bb, 48)
    XCTAssertEqual(msg.repeatedNestedMessage, [nestedMsg])
    var nestedMsg2 = Proto3TestAllTypes.NestedMessage()
    nestedMsg2.bb = 148
    msg.repeatedNestedMessage.append(nestedMsg2)
    XCTAssertEqual(msg.repeatedNestedMessage.count, 2)
    XCTAssertEqual(msg.repeatedNestedMessage[0].bb, 48)
    XCTAssertEqual(msg.repeatedNestedMessage[1].bb, 148)
    XCTAssertEqual(msg.repeatedNestedMessage, [nestedMsg, nestedMsg2])
  }

  func testRepeatedForeignMessage() {
    var msg = Proto3TestAllTypes()
    XCTAssertEqual(msg.repeatedForeignMessage, [])
    var foreignMsg = Proto3ForeignMessage()
    foreignMsg.c = 49
    msg.repeatedForeignMessage = [foreignMsg]
    XCTAssertEqual(msg.repeatedForeignMessage.count, 1)
    XCTAssertEqual(msg.repeatedForeignMessage[0].c, 49)
    XCTAssertEqual(msg.repeatedForeignMessage, [foreignMsg])
    var foreignMsg2 = Proto3ForeignMessage()
    foreignMsg2.c = 149
    msg.repeatedForeignMessage.append(foreignMsg2)
    XCTAssertEqual(msg.repeatedForeignMessage.count, 2)
    XCTAssertEqual(msg.repeatedForeignMessage[0].c, 49)
    XCTAssertEqual(msg.repeatedForeignMessage[1].c, 149)
    XCTAssertEqual(msg.repeatedForeignMessage, [foreignMsg, foreignMsg2])
  }

  func testRepeatedImportMessage() {
    var msg = Proto3TestAllTypes()
    XCTAssertEqual(msg.repeatedImportMessage, [])
    var importedMsg = Proto3ImportMessage()
    importedMsg.d = 50
    msg.repeatedImportMessage = [importedMsg]
    XCTAssertEqual(msg.repeatedImportMessage.count, 1)
    XCTAssertEqual(msg.repeatedImportMessage[0].d, 50)
    XCTAssertEqual(msg.repeatedImportMessage, [importedMsg])
    var importedMsg2 = Proto3ImportMessage()
    importedMsg2.d = 150
    msg.repeatedImportMessage.append(importedMsg2)
    XCTAssertEqual(msg.repeatedImportMessage.count, 2)
    XCTAssertEqual(msg.repeatedImportMessage[0].d, 50)
    XCTAssertEqual(msg.repeatedImportMessage[1].d, 150)
    XCTAssertEqual(msg.repeatedImportMessage, [importedMsg, importedMsg2])
  }

  func testRepeatedNestedEnum() {
    var msg = Proto3TestAllTypes()
    XCTAssertEqual(msg.repeatedNestedEnum, [])
    msg.repeatedNestedEnum = [.bar]
    XCTAssertEqual(msg.repeatedNestedEnum, [.bar])
    msg.repeatedNestedEnum.append(.baz)
    XCTAssertEqual(msg.repeatedNestedEnum, [.bar, .baz])
  }

  func testRepeatedForeignEnum() {
    var msg = Proto3TestAllTypes()
    XCTAssertEqual(msg.repeatedForeignEnum, [])
    msg.repeatedForeignEnum = [.foreignBar]
    XCTAssertEqual(msg.repeatedForeignEnum, [.foreignBar])
    msg.repeatedForeignEnum.append(.foreignBaz)
    XCTAssertEqual(msg.repeatedForeignEnum, [.foreignBar, .foreignBaz])
  }

  func testRepeatedImportEnum() {
    var msg = Proto3TestAllTypes()
    XCTAssertEqual(msg.repeatedImportEnum, [])
    msg.repeatedImportEnum = [.importBar]
    XCTAssertEqual(msg.repeatedImportEnum, [.importBar])
    msg.repeatedImportEnum.append(.importBaz)
    XCTAssertEqual(msg.repeatedImportEnum, [.importBar, .importBaz])
  }

}
