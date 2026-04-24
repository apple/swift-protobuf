// Tests/SwiftProtobufTests/Test_Map_Binary.swift - Verify binary coding for maps
//
// Copyright (c) 2014 - 2019 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Exercise binary coding for maps with the same dictionary types but different
/// wire encodings. These tests ensure that, for example, `map<int64, int64>`
/// and `map<fixed64, fixed64>` are encoded differently in binary.
///
// -----------------------------------------------------------------------------

import XCTest
import Foundation
@testable import SwiftProtobuf

final class Test_Map_Binary: XCTestCase, PBTestHelpers {
    typealias MessageTestType = SwiftProtoTesting_TestMap

    func testMapInt64Int64() throws {
        let bytes: [UInt8] = [
            (2 << 3) | 2,  // mapInt64Int64, length delimited
            4,             // length of map entry
            (1 << 3) | 0, 1,  // key = 1, wire type 0
            (2 << 3) | 0, 2   // value = 2, wire type 0
        ]
        let m = try SwiftProtoTesting_TestMap(serializedBytes: bytes)
        
        XCTAssertEqual(m.mapInt64Int64.count, 1)
        XCTAssertEqual(m.mapInt64Int64[1], 2)
    }

    func testMapFixed64Fixed64() throws {
        let bytes: [UInt8] = [
            (8 << 3) | 2,  // mapFixed64Fixed64, length delimited
            18,            // length of map entry
            (1 << 3) | 1, 1, 0, 0, 0, 0, 0, 0, 0,  // key = 1, wire type 1
            (2 << 3) | 1, 2, 0, 0, 0, 0, 0, 0, 0   // value = 2, wire type 1
        ]
        let m = try SwiftProtoTesting_TestMap(serializedBytes: bytes)
        
        XCTAssertEqual(m.mapFixed64Fixed64.count, 1)
        XCTAssertEqual(m.mapFixed64Fixed64[1], 2)
    }
}
