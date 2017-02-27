// Tests/SwiftProtobufTests/Test_Merge.swift - Verify merging messages
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------

import Foundation
import XCTest
import SwiftProtobuf

class Test_Merge: XCTestCase, PBTestHelpers {
  typealias MessageTestType = Proto3TestAllTypes

  func testMergeSimple() throws {
    var m1 = Proto3TestAllTypes()
    m1.singleInt32 = 100

    var m2 = Proto3TestAllTypes()
    m2.singleInt64 = 1000

    do {
      try m1.merge(serializedData: m2.serializedData())
      XCTAssertEqual(m1.singleInt32, 100)
      XCTAssertEqual(m1.singleInt64, 1000)
    } catch let e {
      XCTFail("Merge should not have thrown, but it did: \(e)")
    }
  }

  func testMergePreservesValueSemantics() throws {
    var original = Proto3TestAllTypes()
    original.singleInt32 = 100
    let copied = original

    var toMerge = Proto3TestAllTypes()
    toMerge.singleInt64 = 1000

    do {
      try original.merge(serializedData: toMerge.serializedData())

      // The original should have the value from the merged message...
      XCTAssertEqual(original.singleInt32, 100)
      XCTAssertEqual(original.singleInt64, 1000)
      // ...but the older copy should not be affected.
      XCTAssertEqual(copied.singleInt32, 100)
      XCTAssertEqual(copied.singleInt64, 0)
    } catch let e {
      XCTFail("Merge should not have thrown, but it did: \(e)")
    }
  }
}
