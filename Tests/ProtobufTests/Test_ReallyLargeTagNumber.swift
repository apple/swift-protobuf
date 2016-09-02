// Test/Sources/TestSuite/Test_ReallyLargeTagNumber.swift - Exercise extreme tag values
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
/// Check that a message with the largest possible tag number encodes correctly.
///
// -----------------------------------------------------------------------------

import XCTest

class Test_ReallyLargeTagNumber: XCTestCase {

    func test_ReallyLargeTagNumber() {
        var m = ProtobufUnittest_TestReallyLargeTagNumber()
        m.a = 1
        m.bb = 2

        do {
            let encoded = try m.serializeProtobuf()
            XCTAssertEqual(encoded, [8, 1, 248, 255, 255, 255, 7, 2])

            do {
                let decoded = try ProtobufUnittest_TestReallyLargeTagNumber(protobuf: encoded)
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
