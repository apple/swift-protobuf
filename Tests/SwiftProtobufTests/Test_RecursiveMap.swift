// Tests/SwiftProtobufTests/Test_RecursiveMap.swift - Test maps within maps
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Verify the behavior of maps whose values are other maps.
///
// -----------------------------------------------------------------------------

import Foundation
import XCTest

final class Test_RecursiveMap: XCTestCase {
    func test_RecursiveMap() throws {
        let inner = SwiftProtoTesting_TestRecursiveMapMessage()
        var mid = SwiftProtoTesting_TestRecursiveMapMessage()
        mid.a = ["1": inner]
        var outer = SwiftProtoTesting_TestRecursiveMapMessage()
        outer.a = ["2": mid]

        do {
            let encoded: [UInt8] = try outer.serializedBytes()
            XCTAssertEqual(encoded, [10, 12, 10, 1, 50, 18, 7, 10, 5, 10, 1, 49, 18, 0])

            let decodedOuter = try SwiftProtoTesting_TestRecursiveMapMessage(serializedBytes: encoded)
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
