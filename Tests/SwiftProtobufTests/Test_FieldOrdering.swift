// Tests/SwiftProtobufTests/Test_FieldOrdering.swift - Check ordering of binary fields
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Verify that binary protobuf serialization correctly emits fields
/// in order by field number.  This is especially interesting when there
/// are extensions and/or unknown fields involved.
///
/// Proper ordering is recommended but not critical for writers since all
/// readers are required to accept fields out of order.
///
// -----------------------------------------------------------------------------

import Foundation
import XCTest

final class Test_FieldOrdering: XCTestCase {
    typealias MessageTestType = SwiftProtoTesting_Order_TestFieldOrderings

    func test_FieldOrdering() throws {
        var m = MessageTestType()
        m.myString = "abc"
        m.myInt = 1
        m.myFloat = 1.0
        var nest = MessageTestType.NestedMessage()
        nest.oo = 1
        nest.bb = 2
        m.optionalNestedMessage = nest
        m.SwiftProtoTesting_Order_myExtensionInt = 12
        m.SwiftProtoTesting_Order_myExtensionString = "def"
        m.oneofInt32 = 7

        let encoded1: [UInt8] = try m.serializedBytes()
        XCTAssertEqual([8, 1, 40, 12, 80, 7, 90, 3, 97, 98, 99, 146, 3, 3, 100, 101, 102, 173, 6, 0, 0, 128, 63, 194, 12, 4, 8, 2, 16, 1], encoded1)

        m.oneofInt64 = 8
        let encoded2: [UInt8] = try m.serializedBytes()
        XCTAssertEqual([8, 1, 40, 12, 90, 3, 97, 98, 99, 146, 3, 3, 100, 101, 102, 224, 3, 8, 173, 6, 0, 0, 128, 63, 194, 12, 4, 8, 2, 16, 1], encoded2)
    }
}
