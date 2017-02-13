// Tests/SwiftProtobufTests/Test_Reserved.swift - Verify handling of reserved words
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Proto files may have fields, enum cases, or messages whose names happen
/// to be reserved in various languages.  In Swift, some of these reserved
/// words can be used if we put them in backticks.  Others must be modified
/// by appending an underscore so they don't conflict.
///
// -----------------------------------------------------------------------------

import Foundation
import XCTest
import SwiftProtobuf

class Test_Reserved: XCTestCase {
    func testEnumPrefix() {
        XCTAssertEqual(ProtobufUnittest_SwiftReservedTest.Enum.`double`.rawValue, 1)
        XCTAssertEqual(ProtobufUnittest_SwiftReservedTest.Enum.`class`.rawValue, 3)
        XCTAssertEqual(ProtobufUnittest_SwiftReservedTest.Enum.self_.rawValue, 5)
        XCTAssertEqual(ProtobufUnittest_SwiftReservedTest.Enum.json.rawValue, 2)
        XCTAssertEqual(ProtobufUnittest_SwiftReservedTest.classMessage().debugDescription, "SwiftProtobufTests.ProtobufUnittest_SwiftReservedTest.classMessage:\n")
        XCTAssertEqual(ProtobufUnittest_SwiftReservedTest.isEqualMessage().debugDescription, "SwiftProtobufTests.ProtobufUnittest_SwiftReservedTest.isEqualMessage:\n")
        XCTAssertEqual(ProtobufUnittest_SwiftReservedTest.TypeMessage().debugDescription, "SwiftProtobufTests.ProtobufUnittest_SwiftReservedTest.TypeMessage:\n")
    }
}
