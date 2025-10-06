// Tests/ExperimentalTableDrivenSwiftProtobufTests/Test_TableDriven.swift - Exercise table-driven protos
//
// Copyright (c) 2014 - 2025 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Some early tests for table-driven protos that can be built separately
/// without requiring that everything be migrated all at once.
///
// -----------------------------------------------------------------------------

import Foundation
import SwiftProtobuf
import XCTest

final class Test_TableDriven: XCTestCase {
    typealias MessageTestType = SwiftProtoTesting_TestAllTypes

    func testCreation() {
        var msg = MessageTestType()
        msg.optionalBool = true
        msg.optionalInt32 = 50
        msg.optionalString = "some string"
        msg.repeatedInt32 = [1, 10, 100]
        msg.repeatedString = ["a", "b", "c"]

        XCTAssertEqual(msg.optionalBool, true)
        XCTAssertEqual(msg.optionalInt32, 50)
        XCTAssertEqual(msg.optionalString, "some string")
        XCTAssertEqual(msg.repeatedInt32, [1, 10, 100])
        XCTAssertEqual(msg.repeatedString, ["a", "b", "c"])
    }
}
