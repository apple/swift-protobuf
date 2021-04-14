// Tests/SwiftProtobufTests/Test_FuzzTests.swift - Test cases from fuzz testing
//
// Copyright (c) 2014 - 2021 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt

// These are input cases from fuzz testing that caused crashes/failures,
// captured as unittest to debug, watch for regressions, etc. Generally how it
// decodes doesn't matter, just that it can/can't decode without
//
// If a failure is found via manually running the binaries, the failures end
// with a summmary that shows the data output is hex pairs, an escaped string,
// written to a file, and then also as Base64. You can directly get the hex
// values from there, or can use xxd to dump from the file.
//
// For failures that get filed by oss-fuzz, the bugs will have links to detailed
// reports, those have a test case (and reduced test case) that can be download.
//
// Easily get the hex dumps via `xxd -i < _test_case_file_`

import Foundation
import XCTest

class Test_FuzzTests: XCTestCase {

  func assertBinaryFails(_ bytes: [UInt8], file: XCTestFileArgType = #file, line: UInt = #line) {
    XCTAssertThrowsError(
      try Fuzz_Testing_Message(serializedData: Data(bytes), extensions: Fuzz_Testing_FuzzTesting_Extensions),
      file: file, line: line)
  }

  func assertJSONFails(_ jsonBytes: [UInt8], file: XCTestFileArgType = #file, line: UInt = #line) {
    XCTAssertThrowsError(
      try Fuzz_Testing_Message(jsonUTF8Data: Data(jsonBytes), extensions: Fuzz_Testing_FuzzTesting_Extensions),
      file: file, line: line)
  }

  func assertJSONFails(_ json: String, file: XCTestFileArgType = #file, line: UInt = #line) {
    XCTAssertThrowsError(
      try Fuzz_Testing_Message(jsonString: json, extensions: Fuzz_Testing_FuzzTesting_Extensions),
      file: file, line: line)
  }

  func assertTextFormatFails(_ textFormat: String, file: XCTestFileArgType = #file, line: UInt = #line) {
    XCTAssertThrowsError(
      try Fuzz_Testing_Message(textFormatString: textFormat, extensions: Fuzz_Testing_FuzzTesting_Extensions),
      file: file, line: line)
  }

  func assertTextFormatFails(_ asBytes: [UInt8], file: XCTestFileArgType = #file, line: UInt = #line) {
    guard let str = String(data: Data(asBytes), encoding: .utf8) else {
      XCTFail("Failed to make a string", file: file, line: line)
      return
    }
    XCTAssertThrowsError(
      try Fuzz_Testing_Message(textFormatString: str, extensions: Fuzz_Testing_FuzzTesting_Extensions),
      file: file, line: line)
  }

  func assertTextFormatSucceeds(_ textFormat: String, file: XCTestFileArgType = #file, line: UInt = #line) {
    XCTAssertNoThrow(
      try Fuzz_Testing_Message(textFormatString: textFormat, extensions: Fuzz_Testing_FuzzTesting_Extensions),
      file: file, line: line)
  }

  func assertTextFormatSucceeds(_ asBytes: [UInt8], file: XCTestFileArgType = #file, line: UInt = #line) {
    guard let str = String(data: Data(asBytes), encoding: .utf8) else {
      XCTFail("Failed to make a string", file: file, line: line)
      return
    }
    XCTAssertNoThrow(
      try Fuzz_Testing_Message(textFormatString: str, extensions: Fuzz_Testing_FuzzTesting_Extensions),
      file: file, line: line)
  }

  func test_Binary() {
    // Float/Double repeated/packed huge count
    assertBinaryFails([
      0x8a, 0x41, 0xb0, 0xb0, 0xb0, 0xb0, 0xb0, 0xb0, 0xb0, 0x8a, 0x41, 0x8d,
      0x8c,
    ])
  }

  func test_JSON() {
    // {"Ù{":\\\x00. ":\\\x00. - malformed utf8
    assertJSONFails([
      0x7b, 0x22, 0xf4, 0x7b, 0x22, 0x3a, 0x5c, 0x00, 0x2e, 0x20, 0x22, 0x3a,
      0x5c, 0x00, 0x2e, 0x20
    ])

    assertJSONFails("{\"[fuzz.testing.singular_sint32_ext]\":null")
  }

  func test_TextFormat() {
    // parsing map<>s looping forever when truncated
    assertTextFormatFails("104<")
    assertTextFormatFails("104{")

    // 44:'2\\50191<1\x0f:' - octal out of range '\501', gets rolled in range
    assertTextFormatSucceeds([
      0x34, 0x34, 0x3a, 0x27, 0x32, 0x5c, 0x35, 0x30, 0x31, 0x39, 0x31, 0x3c,
      0x31, 0x0f, 0x3a, 0x27
    ])
  }
}
