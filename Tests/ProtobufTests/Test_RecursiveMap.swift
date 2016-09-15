// Test/Sources/TestSuite/Test_RecursiveMap.swift - Test maps within maps
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
/// Verify the behavior of maps whose values are other maps.
///
// -----------------------------------------------------------------------------

import Foundation
import XCTest

class Test_RecursiveMap: XCTestCase {
    func test_RecursiveMap() throws {
        let inner = ProtobufUnittest_TestRecursiveMapMessage()
        var mid = ProtobufUnittest_TestRecursiveMapMessage()
        mid.a = ["1": inner]
        var outer = ProtobufUnittest_TestRecursiveMapMessage()
        outer.a = ["2": mid]

        do {
            let encoded = try outer.serializeProtobuf()
            XCTAssertEqual(encoded, Data(bytes: [10, 12, 10, 1, 50, 18, 7, 10, 5, 10, 1, 49, 18, 0]))

            let decodedOuter = try ProtobufUnittest_TestRecursiveMapMessage(protobuf: encoded)
            if let decodedMid = decodedOuter.a["2"] {
                if let decodedInner = decodedMid.a["1"] {
                    XCTAssertEqual(decodedOuter.a.count, 1)
                    XCTAssertEqual(decodedMid.a.count, 1)
                    XCTAssertEqual(decodedInner.a.count, 0)
                } else {
                    XCTFail()
                }
            } else {
                XCTFail()
            }
        } catch let e {
            XCTFail("Failed with error \(e)")
        }
    }
}
