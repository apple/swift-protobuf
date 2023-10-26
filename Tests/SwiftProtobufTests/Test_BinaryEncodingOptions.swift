// Tests/SwiftProtobufTests/Test_BinaryEncodingOptions.swift - Tests for binary encoding options
//
// Copyright (c) 2014 - 2023 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Test for the use of BinaryEncodingOptions
///
// -----------------------------------------------------------------------------

import Foundation
import XCTest
import SwiftProtobuf

final class Test_BinaryEncodingOptions: XCTestCase {

  func testUseDeterministicOrdering() throws {
    var options = BinaryEncodingOptions()
    options.useDeterministicOrdering = true

    let message1 = SwiftProtoTesting_Message3.with {
      $0.mapStringString = [
        "b": "B",
        "a": "A",
        "0": "0",
        "UPPER": "v",
        "x": "X",
      ]
      $0.mapInt32Message = [
        5: .with { $0.optionalSint32 = 5 },
        1: .with { $0.optionalSint32 = 1 },
        3: .with { $0.optionalSint32 = 3 },
      ]
      $0.mapInt32Enum = [
        5: .foo,
        3: .bar,
        0: .baz,
        1: .extra3,
      ]
    }

    let message2 = SwiftProtoTesting_Message3.with {
      $0.mapStringString = [
        "UPPER": "v",
        "a": "A",
        "b": "B",
        "x": "X",
        "0": "0",
      ]
      $0.mapInt32Message = [
        1: .with { $0.optionalSint32 = 1 },
        3: .with { $0.optionalSint32 = 3 },
        5: .with { $0.optionalSint32 = 5 },
      ]
      $0.mapInt32Enum = [
        3: .bar,
        5: .foo,
        1: .extra3,
        0: .baz,
      ]
    }

    // Approximation that serializing models with the same data (but initialized with keys in
    // different orders) consistently produces the same outputs.
    let expectedOutput = try message1.serializedData(options: options)
    for _ in 0..<10 {
      XCTAssertEqual(try message2.serializedData(options: options), expectedOutput)
    }
  }
}
