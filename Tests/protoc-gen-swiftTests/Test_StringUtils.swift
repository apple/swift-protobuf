// Tests/protoc-gen-swiftTests/Test_StringUtils.swift - Test string handling
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
/// Tests for tools to ensure identifiers are valid in Swift or protobuf{2,3}.
///
// -----------------------------------------------------------------------------

import XCTest

@testable import protoc_gen_swift

// sample string, isValidSwift, isUsableSwift, isValidProtobuf
let testcases: [(String, Bool, Bool, Bool)] = [
  ("_",                   true,  false, true ),
  ("H9000",               true,  true,  true ),
  ("🐶🐮",                true,  true,  false),
  ("$0",                  true,  false, false),
  ("$f00",                false, false, false),
  ("12Hour",              false, false, false),
  ("This is not a pipe.", false, false, false)
]

class Test_StringUtils: XCTestCase {
  func testIsValidSwiftIdentifier() {
    for (identifier, result, _, _) in testcases {
      XCTAssertEqual(isValidSwiftIdentifier(identifier), result, "\(identifier) should \(result ? "" : "not ")have been valid")
    }
  }

  func testIsUsableSwiftIdentifier() {
    for (identifier, _, result, _) in testcases {
      XCTAssertEqual(isUsableSwiftIdentifier(identifier), result, "\(identifier) should \(result ? "" : "not ")have been valid")
    }
  }

  func testIsValidProtobufIdentifier() {
    for (identifier, _, _, result) in testcases {
      XCTAssertEqual(isValidProtobufIdentifier(identifier), result, "\(identifier) should \(result ? "" : "not ")have been valid")
    }
  }
}
