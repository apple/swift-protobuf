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

import SwiftProtobuf

final class Test_FuzzTests: XCTestCase {

  func assertBinaryFails(_ bytes: [UInt8], file: XCTestFileArgType = #file, line: UInt = #line) {
    XCTAssertThrowsError(
      try SwiftProtoTesting_Fuzz_Message(serializedBytes: bytes, extensions: SwiftProtoTesting_Fuzz_FuzzTesting_Extensions),
      file: file, line: line)
  }

  func assertJSONFails(_ jsonBytes: [UInt8], file: XCTestFileArgType = #file, line: UInt = #line) {
    XCTAssertThrowsError(
      try SwiftProtoTesting_Fuzz_Message(jsonUTF8Bytes: jsonBytes, extensions: SwiftProtoTesting_Fuzz_FuzzTesting_Extensions),
      file: file, line: line)
  }

  func assertJSONFails(_ json: String, file: XCTestFileArgType = #file, line: UInt = #line) {
    XCTAssertThrowsError(
      try SwiftProtoTesting_Fuzz_Message(jsonString: json, extensions: SwiftProtoTesting_Fuzz_FuzzTesting_Extensions),
      file: file, line: line)
  }

  func assertTextFormatFails(_ textFormat: String, options: TextFormatDecodingOptions = TextFormatDecodingOptions(), file: XCTestFileArgType = #file, line: UInt = #line) {
    XCTAssertThrowsError(
      try SwiftProtoTesting_Fuzz_Message(textFormatString: textFormat,
                                         options: options,
                                         extensions: SwiftProtoTesting_Fuzz_FuzzTesting_Extensions),
      file: file, line: line)
  }

  func assertTextFormatFails(_ asBytes: [UInt8], options: TextFormatDecodingOptions = TextFormatDecodingOptions(), file: XCTestFileArgType = #file, line: UInt = #line) {
    guard let str = String(data: Data(asBytes), encoding: .utf8) else {
      print(
        """
        Failed to make string (at \(file):\(line)): nothing to try and decode.
        The fuzzer does not fail in this case and neither should we, skipping test.
        """
      )
      return
    }
    XCTAssertThrowsError(
      try SwiftProtoTesting_Fuzz_Message(textFormatString: str,
                                         options: options,
                                         extensions: SwiftProtoTesting_Fuzz_FuzzTesting_Extensions),
      file: file, line: line)
  }

  func assertTextFormatSucceeds(_ textFormat: String, options: TextFormatDecodingOptions = TextFormatDecodingOptions(), file: XCTestFileArgType = #file, line: UInt = #line) {
    XCTAssertNoThrow(
      try SwiftProtoTesting_Fuzz_Message(textFormatString: textFormat,
                                         options: options,
                                         extensions: SwiftProtoTesting_Fuzz_FuzzTesting_Extensions),
      file: file, line: line)
  }

  func assertTextFormatSucceeds(_ asBytes: [UInt8], options: TextFormatDecodingOptions = TextFormatDecodingOptions(), file: XCTestFileArgType = #file, line: UInt = #line) {
    guard let str = String(data: Data(asBytes), encoding: .utf8) else {
      print(
        """
        Failed to make string (at \(file):\(line)): nothing to try and decode.
        The fuzzer does not fail in this case and neither should we, skipping test.
        """
      )
      return
    }
    XCTAssertNoThrow(
      try SwiftProtoTesting_Fuzz_Message(textFormatString: str,
                                         options: options,
                                         extensions: SwiftProtoTesting_Fuzz_FuzzTesting_Extensions),
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
    let msg = try! SwiftProtoTesting_Fuzz_Message(jsonString: "   {\"wktAny\":  {}}  ")
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

    // FailCases/clusterfuzz-testcase-FuzzTextFormat_release-4619956026146816
    // FailCases/clusterfuzz-testcase-minimized-FuzzTextFormat_release-4619956026146816
    var opts = TextFormatDecodingOptions()
    opts.ignoreUnknownFields = true
    opts.ignoreUnknownExtensionFields = true
    assertTextFormatFails("rsingular_sint:-", options: opts)
    assertTextFormatFails("      l     :-", options: opts)
  }
}
