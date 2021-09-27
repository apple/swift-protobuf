// Tests/SwiftProtobufTests/Test_FuzzTests.swift - Test cases from fuzz testing
//
// Copyright (c) 2014 - 2021 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt

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
    // FailCases/Binary-packed-float-double-growth
    assertBinaryFails([
      0x8a, 0x41, 0xb0, 0xb0, 0xb0, 0xb0, 0xb0, 0xb0, 0xb0, 0x8a, 0x41, 0x8d,
      0x8c,
    ])
  }

  func test_JSON() {
    // FailCases/JSON-malformed-utf8
    assertJSONFails([
      0x7b, 0x22, 0xf4, 0x7b, 0x22, 0x3a, 0x5c, 0x00, 0x2e, 0x20, 0x22, 0x3a,
      0x5c, 0x00, 0x2e, 0x20
    ])

    // FailCases/clusterfuzz-testcase-minimized-FuzzJSON_debug-4506617283477504
    // FailCases/clusterfuzz-testcase-minimized-FuzzJSON_release-5689942715006976
    assertJSONFails("{\"[fuzz.testing.singular_sint32_ext]\":null")

    // FailCases/JSON-Any
    assertJSONFails(" {\"wktAny\":{\"ny\":{")

    // FuzzTesting/FailCases/clusterfuzz-testcase-minimized-FuzzJSON_release-4929034878844928
    // This actually fails when the fuzzer was trying to write it back out again.
    let msg = try! Fuzz_Testing_Message(jsonString: "   {\"wktAny\":  {}}  ")
    XCTAssertEqual(try! msg.jsonString(), "{\"wktAny\":{}}")
  }

  func test_TextFormat() {
    // FailCases/TextFormat-map-loops-forever
    // FailCases/TextFormat-map-loops-forever2
    assertTextFormatFails("104<")
    assertTextFormatFails("104{")

    // FailCases/TextFormat-octal-out-of-range
    assertTextFormatSucceeds([
      0x34, 0x34, 0x3a, 0x27, 0x32, 0x5c, 0x35, 0x30, 0x31, 0x39, 0x31, 0x3c,
      0x31, 0x0f, 0x3a, 0x27
    ])

    // FailCases/TextFormat-ending-zero
    assertTextFormatSucceeds("    1:0    1:0      1:0")
    // FailCases/TextFormat-ending-minus
    assertTextFormatFails("    1:0    1:0      5:-")

    // FailCases/clusterfuzz-testcase-minimized-FuzzTextFormat_release-5836572361621504
    assertTextFormatFails([
      0x31, 0x35, 0x3a, 0x27, 0xa9, 0xa9, 0x5c, 0x75, 0x41, 0x62
    ])

    assertTextFormatSucceeds("500<[google.protobuf.Any]<[google.protobuf.Any]<[google.protobuf.Any]<[google.protobuf.Any]<[google.protobuf.Any]<[google.protobuf.Any]<[google.protobuf.Any]<[google.protobuf.Any]<[google.protobuf.Any]<[google.protobuf.Any]<[google.protobuf.Any]<[google.protobuf.Any]<[google.protobuf.Any]<[google.protobuf.Any]<[google.protobuf.Any]<>>>>>>>>>>>>>>>>500<1:''\n2:''>")

    assertTextFormatFails("500<[fvwzz_exobuf.Aob/google.protobuf.Any]<[oeFgb/google.protobuf.Any]<[xlob/google.protobuf.Any]<[oeee0FFFFgb/google.protobuf.Any]<[oglob/google.protobuf.Any]<[oogoFFFFFFFFRFfuzz.tebool_extFFFFFFFBFFFFegleeeeeeeeeeeeeeeeeeemeeeeeeeeeeeneeeeeeeekeeeeFFFFFFFFFIFFFFFFFgb/google.protobuf.Any]<[oglob/google.protobuf.Any]<[oogoFFFFFFFFRFfuzz.tebool_extFFFFFFFBFFFFegleeeeeeeeeeeeeeeeeeemeeeeeeeeeeeneeeeeeeekeeeeFFFFFFFFFIFFFFFFFgb/google.protobuf.Any]<[oglob/google.protobuf.Any]<[oogoFFFFFFFFRFfuzz.tebool_extFFFFFFFBFFFFegleeeeeeeeeeeeeeeeeeemeeeeeeeeeeeneeeeeeeekeeeeFFFFFFFFFIFFFFFFFgb/google.protobuf.Any]<[oglob/google.protobuf.Any]<[oogoFFFFFFFFRFfuzz.tebool_extFFFFFFFBFFFFegleeeeeeeeeeeeeeeeeeemeeeeeeeeeeeneeeeeeeekeeeeFFFFFFFFFIFFFFFFFgb/google.protobuf.Any]<[oglob/google.protobuf.Any]<[oogoFFFFFFFFRFfuzz.tebool_extFFFFFFFBFFFFegleeeeeeeeeeeeeeeeeeemeeeeeeeeeeeneeeeeeeekeeeeFFFFFFFFFIFFFFFFFgb/google.protobuf.Any]<[oglob/google.protobuf.Any]<[oogoFFFFFFFFRFfuzz.tebool_extFFFFFFFBFFFFegleeeeeeeeeeeeeeeeeeemeeeeeeeeeeeneeeeeeeekeeeeFFFFFFFFFIFFFFFFFgb/google.protobuf.Any]<>>>>>>>>>>>>>>>>>500<1:''\n1:''\n1:''\n2:''\n1:'roto")

    // FailCases/clusterfuzz-testcase-minimized-FuzzTextFormat_release-5109315292233728
    // This decodes but fails when trying to generate the TextFormat again.
    let bytes: [UInt8] = [
      0x35, 0x30, 0x30, 0x3c, 0x31, 0x3a, 0x27, 0x67, 0x6f, 0x6f, 0x67, 0x6c,
      0x65, 0x2e, 0x70, 0x72, 0x6f, 0x74, 0x6f, 0x62, 0x75, 0x66, 0x2e, 0x54,
      0x69, 0x6d, 0x65, 0x73, 0x74, 0x61, 0x6d, 0x70, 0x27, 0x32, 0x3a, 0x27,
      0x78, 0x74, 0x32, 0x31, 0x3a, 0x34, 0x37, 0x40, 0x6f, 0x67, 0x6c, 0x65,
      0x2e, 0x6d, 0x15, 0x15, 0x15, 0x15, 0x15, 0x15, 0x15, 0x15, 0x15, 0x15,
      0x15, 0x15, 0x15, 0x15, 0x15, 0x15, 0x15, 0x6d, 0x61, 0x70, 0x5f, 0x73,
      0x69, 0x6e, 0x74, 0x33, 0x32, 0x5f, 0x73, 0x66, 0x69, 0x78, 0x65, 0x64,
      0x36, 0x34, 0x3a, 0x15, 0x15, 0x15, 0x15, 0x30, 0x15, 0x15, 0x15, 0x15,
      0x1d, 0x15, 0x15, 0x15, 0x15, 0x15, 0x15, 0x15, 0x15, 0x15, 0x58, 0x58,
      0x58, 0x58, 0x58, 0x58, 0x58, 0x58, 0x58, 0x58, 0x58, 0x58, 0x58, 0x58,
      0x58, 0x58, 0x58, 0x58, 0x58, 0x58, 0x58, 0x58, 0xa9, 0xa9, 0xa9, 0xa9,
      0xa9, 0xa9, 0xa9, 0xa9, 0xa9, 0xa9, 0xa9, 0xa9, 0xa9, 0xa9, 0xa9, 0xa9,
      0xa9, 0xa9, 0xa9, 0xa9, 0xa9, 0xa9, 0xa9, 0xa9, 0xa9, 0xa9, 0xa9, 0xa9,
      0xa9, 0xa9, 0xa9, 0xa9, 0xa9, 0xa9, 0xa9, 0xa9, 0xa9, 0xa9, 0xa9, 0xa9,
      0xa9, 0xa9, 0xa9, 0xa9, 0xa9, 0xa9, 0xa9, 0xa9, 0xa9, 0xa9, 0xa9, 0xa9,
      0xa9, 0xa9, 0xa9, 0xa9, 0x31, 0x27, 0x3e,
    ]
    let str = String(data: Data(bytes), encoding: .utf8)!
    let msg = try! Fuzz_Testing_Message(textFormatString: str, extensions: Fuzz_Testing_FuzzTesting_Extensions)
    let _ = msg.textFormatString()
  }
}
