// Tests/SwiftProtobufTests/Test_Applying.swift - Applying method
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------

import Foundation
import XCTest
import SwiftProtobuf

final class Test_Applying: XCTestCase {

  func testApplying() throws {
    let message = SwiftProtoTesting_TestAny()
    let newMessage = try message.applying(Int32(2), for: 1)
    XCTAssertEqual(newMessage.int32Value, 2)
  }

  func testApply() throws {
    var message = SwiftProtoTesting_TestAny()
    try message.apply(Int32(2), for: 1)
    XCTAssertEqual(message.int32Value, 2)
  }

  func testApplyingSequentially() throws {
    let message = SwiftProtoTesting_TestAny()
    let newMessage = try message
      .applying(Int32(2), for: 1)
      .applying("test", for: 4)
    XCTAssertEqual(newMessage.int32Value, 2)
    XCTAssertEqual(newMessage.text, "test")
  }

  func testApplyingMismatchType() throws {
    let message = SwiftProtoTesting_TestAny()
    XCTAssertThrowsError(try message.applying("", for: 1))
  }

  func testApplyMismatchType() throws {
    var message = SwiftProtoTesting_TestAny()
    XCTAssertThrowsError(try message.apply("", for: 1))
  }

  func testApplyingOneof() throws {
    let message = SwiftProtoTesting_TestOneof.with { oneof in
      oneof.foo = .fooInt(1)
    }
    let newMessage = try message.applying("oneof", for: 2)
    XCTAssertEqual(newMessage.foo, .fooString("oneof"))
  }

  func testApplyOneof() throws {
    var message = SwiftProtoTesting_TestOneof.with { oneof in
      oneof.foo = .fooInt(1)
    }
    try message.apply("oneof", for: 2)
    XCTAssertEqual(message.foo, .fooString("oneof"))
  }

  func testApplyingExtension() throws {
    var message = SwiftProtoTesting_Extend_Msg1()
    message.SwiftProtoTesting_Extend_aB = 0
    let newMessage = try message.applying(Int32(2), for: 1)
    XCTAssertEqual(newMessage.SwiftProtoTesting_Extend_aB, 2)
  }

  func testApplyExtension() throws {
    var message = SwiftProtoTesting_Extend_Msg1()
    message.SwiftProtoTesting_Extend_aB = 0
    try message.apply(Int32(2), for: 1)
    XCTAssertEqual(message.SwiftProtoTesting_Extend_aB, 2)
  }

}
