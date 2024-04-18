// Test/Sources/TestSuite/Test_OneofFields_Decoding.swift
//
// Copyright (c) 2014 - 2024 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Exercises the dedcode for primitive fields within a oneof.
///
// -----------------------------------------------------------------------------

import Foundation
import XCTest
import SwiftProtobuf

final class Test_OneofFields_Decoding: XCTestCase {
  func testDecodeOneofCaptureField() throws {
    var m = SwiftProtoTesting_Fuzz_Message()

    m.oneofInt32 = 1
    var d1 = PBTestDecoder(fieldNumber: 61)
    try m.decodeMessage(decoder: &d1)
    XCTAssertEqual(d1.value as? Int32, Int32(1))

    m.oneofInt64 = 1
    var d2 = PBTestDecoder(fieldNumber: 62)
    try m.decodeMessage(decoder: &d2)
    XCTAssertEqual(d2.value as? Int64, Int64(1))

    m.oneofString = "message"
    var d3 = PBTestDecoder(fieldNumber: 74)
    try m.decodeMessage(decoder: &d3)
    XCTAssertEqual(d3.value as? String, "message")

    m.oneofBytes = "message".data(using: .utf8)!
    var d4 = PBTestDecoder(fieldNumber: 75)
    try m.decodeMessage(decoder: &d4)
    XCTAssertEqual(d4.value as? Data, "message".data(using: .utf8)!)

    m.oneofEnum = .two
    var d5 = PBTestDecoder(fieldNumber: 76)
    try m.decodeMessage(decoder: &d5)
    XCTAssertEqual(d5.value as? SwiftProtoTesting_Fuzz_AnEnum, .two)
  }

  func testDecodeOneofModifyField() throws {
    var m = SwiftProtoTesting_Fuzz_Message()

    var d1 = PBTestDecoder(fieldNumber: 61, decodingMode: .set(Int32(1)))
    try m.decodeMessage(decoder: &d1)
    XCTAssertEqual(m.oneofInt32, Int32(1))

    var d2 = PBTestDecoder(fieldNumber: 62, decodingMode: .set(Int64(1)))
    try m.decodeMessage(decoder: &d2)
    XCTAssertEqual(m.oneofInt64, Int64(1))

    var d3 = PBTestDecoder(fieldNumber: 74, decodingMode: .set("message"))
    try m.decodeMessage(decoder: &d3)
    XCTAssertEqual(m.oneofString, "message")

    var d4 = PBTestDecoder(fieldNumber: 75, decodingMode: .set("message".data(using: .utf8)!))
    try m.decodeMessage(decoder: &d4)
    XCTAssertEqual(m.oneofBytes, "message".data(using: .utf8)!)

    var d5 = PBTestDecoder(fieldNumber: 76, decodingMode: .set(SwiftProtoTesting_Fuzz_AnEnum.two))
    try m.decodeMessage(decoder: &d5)
    XCTAssertEqual(m.oneofEnum, .two)
  }
}
