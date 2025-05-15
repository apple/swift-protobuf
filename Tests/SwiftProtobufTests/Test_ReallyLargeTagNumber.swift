// Tests/SwiftProtobufTests/Test_ReallyLargeTagNumber.swift - Exercise extreme tag values
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Check that a message with the largest possible tag number encodes correctly.
///
// -----------------------------------------------------------------------------

import Foundation
import XCTest

final class Test_ReallyLargeTagNumber: XCTestCase {

    func test_ReallyLargeTagNumber() {
        var m = SwiftProtoTesting_TestReallyLargeTagNumber()
        m.a = 1
        m.bb = 2

        do {
            let encoded: [UInt8] = try m.serializedBytes()
            XCTAssertEqual(encoded, [8, 1, 248, 255, 255, 255, 7, 2])

            do {
                let decoded = try SwiftProtoTesting_TestReallyLargeTagNumber(serializedBytes: encoded)
                XCTAssertEqual(2, decoded.bb)
                XCTAssertEqual(1, decoded.a)
                XCTAssertEqual(m, decoded)
            } catch {
                XCTFail("Decode should not fail")
            }
        } catch let e {
            XCTFail("Could not encode \(m): Got error \(e)")
        }
    }
}
