// Tests/SwiftProtobufTests/Test_BinaryDelimited.swift - Delimited message tests
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------

import Foundation
import XCTest
import SwiftProtobuf

fileprivate func openInputStream(_ bytes: [UInt8]) -> InputStream {
  let istream = InputStream(data: Data(bytes))
  istream.open()
  return istream
}

final class Test_BinaryDelimited: XCTestCase {

  /// Helper to assert the next message read matches and expected one.
  func assertParse<M: Message & Equatable>(expected: M, onStream istream: InputStream) {
    do {
      let msg = try BinaryDelimited.parse(
        messageType: M.self,
        from: istream)
      XCTAssertEqual(msg, expected)
    } catch let e {
      XCTFail("Unexpected failure: \(e)")
    }
  }

  /// Helper to assert we're at the end of the stream.
  ///
  /// `hasBytesAvailable` is documented as maybe returning True and a read
  /// has to happen to really know if ones at the end. This is especially
  /// true with file based streams.
  func assertParseFails(atEndOfStream istream: InputStream) {
    XCTAssertThrowsError(try BinaryDelimited.parse(messageType: SwiftProtoTesting_TestAllTypes.self,
                                                   from: istream)) { error in
      XCTAssertTrue(self.isSwiftProtobufErrorEqual(error as! SwiftProtobufError, .BinaryStreamDecoding.noBytesAvailable()))
    }
  }

  func assertParsing(failsWithTruncatedStream istream: InputStream) {
    XCTAssertThrowsError(try BinaryDelimited.parse(messageType: SwiftProtoTesting_TestAllTypes.self,
                                                   from: istream)) { error in
      XCTAssertEqual(error as? BinaryDelimited.Error, BinaryDelimited.Error.truncated)
    }
  }

  func testNoData() {
    let istream = openInputStream([])

    assertParseFails(atEndOfStream: istream)
  }

  func testZeroLengthMessage() {
    let istream = openInputStream([0])

    assertParse(expected: SwiftProtoTesting_TestAllTypes(), onStream: istream)

    assertParseFails(atEndOfStream: istream)
  }

  func testNoDataForMessage() {
    let istream = openInputStream([0x96, 0x01])

    // Length will be read, then the no data for the message, so .truncated.
    assertParsing(failsWithTruncatedStream: istream)
  }

  func testNotEnoughDataForMessage() {
    let istream = openInputStream([0x96, 0x01, 0x01, 0x02, 0x03])

    // Length will be read, but not enought data, so .truncated
    assertParsing(failsWithTruncatedStream: istream)
  }

  func testTruncatedLength() {
    let istream = openInputStream([0x96]) // Needs something like `, 0x01`

    assertParsing(failsWithTruncatedStream: istream)
  }

  func testTooLarge() {
    let istream = openInputStream([0x80, 0x80, 0x80, 0x80, 0x08]) // 2GB

    XCTAssertThrowsError(try BinaryDelimited.parse(messageType: SwiftProtoTesting_TestAllTypes.self,
                                                   from: istream)) { error in
      XCTAssertEqual(error as! BinaryDecodingError, .malformedProtobuf)
    }
  }

  func testOverEncodedLength() {
    let istream = openInputStream([0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80 ,0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x08])

    XCTAssertThrowsError(try BinaryDelimited.parse(messageType: SwiftProtoTesting_TestAllTypes.self,
                                                   from: istream)) { error in
      XCTAssertEqual(error as! BinaryDecodingError, .malformedProtobuf)
    }
  }

  func testTwoMessages() {
    let stream1 = OutputStream.toMemory()
    stream1.open()

    let msg1 = SwiftProtoTesting_TestAllTypes.with {
      $0.optionalBool = true
      $0.optionalInt32 = 123
      $0.optionalInt64 = 123456789
      $0.optionalGroup.a = 456
      $0.optionalNestedEnum = .baz
      $0.repeatedString.append("wee")
      $0.repeatedFloat.append(1.23)
    }

    XCTAssertNoThrow(try BinaryDelimited.serialize(message: msg1, to: stream1))

    let msg2 = SwiftProtoTesting_TestPackedTypes.with {
      $0.packedBool.append(true)
      $0.packedInt32.append(234)
      $0.packedDouble.append(345.67)
    }

    XCTAssertNoThrow(try BinaryDelimited.serialize(message: msg2, to: stream1))

    stream1.close()
    // See https://bugs.swift.org/browse/SR-5404
    let nsData = stream1.property(forKey: .dataWrittenToMemoryStreamKey) as! NSData
    let data = Data(referencing: nsData)
    let stream2 = InputStream(data: data)
    stream2.open()

    // Test using `merge`
    var msg1a = SwiftProtoTesting_TestAllTypes()
    XCTAssertNoThrow(try BinaryDelimited.merge(into: &msg1a, from: stream2))
    XCTAssertEqual(msg1, msg1a)

    // Test using `parse`
    assertParse(expected: msg2, onStream: stream2)

    assertParseFails(atEndOfStream: stream2)
  }

  // oss-fuzz found this case that runs slowly for AsyncMessageSequence
  // Copied here as well for comparison.
  func testLargeExample() throws {
    let messageCount = 100_000
    let bytes = [UInt8](repeating: 0, count: messageCount)
    let istream = openInputStream(bytes)

    for _ in 0..<messageCount {
      let msg = try BinaryDelimited.parse(
	messageType: SwiftProtoTesting_TestAllTypes.self,
	from: istream)
      XCTAssertEqual(msg, SwiftProtoTesting_TestAllTypes())
    }
    XCTAssertThrowsError(try BinaryDelimited.parse(
	messageType: SwiftProtoTesting_TestAllTypes.self,
	from: istream))
  }
}
