// Tests/SwiftProtobufTests/Test_Merge.swift - Verify merging messages
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

final class Test_Merge: XCTestCase, PBTestHelpers {
  typealias MessageTestType = SwiftProtoTesting_Proto3_TestAllTypes

  func testMergeSimple() throws {
    var m1 = SwiftProtoTesting_Proto3_TestAllTypes()
    m1.optionalInt32 = 100

    var m2 = SwiftProtoTesting_Proto3_TestAllTypes()
    m2.optionalInt64 = 1000

    do {
      try m1.merge(serializedBytes: m2.serializedBytes() as [UInt8])
      XCTAssertEqual(m1.optionalInt32, 100)
      XCTAssertEqual(m1.optionalInt64, 1000)
    } catch let e {
      XCTFail("Merge should not have thrown, but it did: \(e)")
    }
  }

  func testMergePreservesValueSemantics() throws {
    var original = SwiftProtoTesting_Proto3_TestAllTypes()
    original.optionalInt32 = 100
    let copied = original

    var toMerge = SwiftProtoTesting_Proto3_TestAllTypes()
    toMerge.optionalInt64 = 1000

    do {
      try original.merge(serializedBytes: toMerge.serializedBytes() as [UInt8])

      // The original should have the value from the merged message...
      XCTAssertEqual(original.optionalInt32, 100)
      XCTAssertEqual(original.optionalInt64, 1000)
      // ...but the older copy should not be affected.
      XCTAssertEqual(copied.optionalInt32, 100)
      XCTAssertEqual(copied.optionalInt64, 0)
    } catch let e {
      XCTFail("Merge should not have thrown, but it did: \(e)")
    }
  }
}
