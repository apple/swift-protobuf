// Tests/SwiftProtobufTests/Test_AsyncMessageSequence.swift - 
//
// Copyright (c) 2023 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Tests the decoding of binary-delimited message streams, ensuring various invalid stream scenarios are
/// handled gracefully.
///
// -----------------------------------------------------------------------------

import Foundation
import XCTest
import SwiftProtobuf

final class Test_AsyncMessageSequence: XCTestCase {
  
  // Decode a valid binary delimited stream
  func testValidSequence() async throws {
    let expected: [Int32] = Array(1...5)
    var messages = [SwiftProtoTesting_TestAllTypes]()
    for messageNumber in expected {
      let message = SwiftProtoTesting_TestAllTypes.with {
        $0.optionalInt32 = messageNumber
      }
      messages.append(message)
    }
    let url = temporaryFileURL()
    try writeMessagesToFile(url, messages: messages)
    
    // Recreate the original array
    let decoded = AsyncMessageSequence<URL.AsyncBytes, SwiftProtoTesting_TestAllTypes>(baseSequence: url.resourceBytes)
    let observed = try await decoded.reduce(into: [Int32]()) { array, element in
      array.append(element.optionalInt32)
    }
    XCTAssertEqual(observed, expected, "The original and re-created arrays should be equal.")
  }
  
  // Decode a message from a stream, discarding unknown fields
  func testBinaryDecodingOptions() async throws {
    let url = temporaryFileURL()
    let unknownFields: [UInt8] = [
      // Field 1, 150
      0x08, 0x96, 0x01,
      // Field 2, string "testing"
      0x12, 0x07, 0x74, 0x65, 0x73, 0x74, 0x69, 0x6e, 0x67
    ]
    let message = try SwiftProtoTesting_TestEmptyMessage(serializedBytes: unknownFields)
    try writeMessagesToFile(url, messages: [message])
    
    var decodingOptions = BinaryDecodingOptions()
    let decodedWithUnknown = AsyncMessageSequence<URL.AsyncBytes, SwiftProtoTesting_TestEmptyMessage>(
      baseSequence: url.resourceBytes,
      options: decodingOptions
    )
    for try await message in decodedWithUnknown {
      XCTAssertEqual(Array(message.unknownFields.data), unknownFields)
    }
    
    decodingOptions.discardUnknownFields = true
    let decodedWithUnknownDiscarded = AsyncMessageSequence<URL.AsyncBytes, SwiftProtoTesting_TestEmptyMessage>(
      baseSequence: url.resourceBytes,
      options: decodingOptions
    )
    var count = 0;
    for try await message in decodedWithUnknownDiscarded {
      XCTAssertTrue(message.unknownFields.data.isEmpty)
      count += 1
    }
    XCTAssertEqual(count, 1, "Expected one message with unknown fields discarded.")
  }
  
  // Decode zero length messages
  func testZeroLengthMessages() async throws {
    var messages = [SwiftProtoTesting_TestAllTypes]()
    for _ in 1...5 {
      messages.append(SwiftProtoTesting_TestAllTypes())
    }
    let url = temporaryFileURL()
    try writeMessagesToFile(url, messages: messages)
    
    var count = 0
    let decoded = AsyncMessageSequence<URL.AsyncBytes, SwiftProtoTesting_TestAllTypes>(baseSequence: url.resourceBytes)
    for try await message in decoded {
      XCTAssertEqual(message, SwiftProtoTesting_TestAllTypes())
      count += 1
    }
    XCTAssertEqual(count, 5, "Expected five messages with default fields.")
  }
  
  // Stream with a single zero varint
  func testStreamZeroVarintOnly() async throws {
    let url = temporaryFileURL()
    try Data([0]).write(to: url)
    
    let decoded = AsyncMessageSequence<URL.AsyncBytes, SwiftProtoTesting_TestAllTypes>(baseSequence: url.resourceBytes)
    var count = 0
    for try await message in decoded {
      XCTAssertEqual(message, SwiftProtoTesting_TestAllTypes())
      count += 1
    }
    XCTAssertEqual(count, 1)
  }
  
  // Empty stream with zero bytes
  func testEmptyStream() async throws {
    let url = temporaryFileURL()
    try writeMessagesToFile(url, messages: [SwiftProtoTesting_TestAllTypes]())
    let decoded = AsyncMessageSequence<URL.AsyncBytes, SwiftProtoTesting_TestAllTypes>(baseSequence: url.resourceBytes)
    for try await _ in decoded {
      XCTFail("Shouldn't have returned a value for an empty stream.")
    }
  }
  
  // A stream with legal non-zero varint but no message
  func testNonZeroVarintNoMessage() async throws {
    let expectation = expectation(description: "Should throw a BinaryDecodingError.truncated")
    let url = temporaryFileURL()
    try Data([0x96, 0x01]).write(to: url) //150 in decimal
    let decoded = AsyncMessageSequence<URL.AsyncBytes, SwiftProtoTesting_TestAllTypes>(baseSequence: url.resourceBytes)
    do {
      for try await _ in decoded {
        XCTFail("Shouldn't have returned a value for an empty stream.")
      }
    } catch {
      if error as! BinaryDecodingError == .truncated {
        expectation.fulfill()
      }
    }
    await fulfillment(of: [expectation], timeout: 1)
  }
  
  // Single varint describing a 2GB message
  func testTooLarge() async throws {
    let expectation = expectation(description: "Should throw a BinaryDecodingError.tooLarge")
    let url = temporaryFileURL()
    let varInt: [UInt8] = [128, 128, 128, 128, 8]
    try Data(varInt).write(to: url)
    let decoded = AsyncMessageSequence<URL.AsyncBytes, SwiftProtoTesting_TestAllTypes>(baseSequence: url.resourceBytes)
    do {
      for try await _ in decoded {
        XCTFail("Shouldn't have returned a value for an invalid stream.")
      }
    } catch {
      if error as! BinaryDecodingError == .tooLarge {
        expectation.fulfill()
      }
    }
    await fulfillment(of: [expectation], timeout: 1)
  }
  
  // Stream with truncated varint
  func testTruncatedVarint() async throws {
    let expectation = expectation(description: "Should throw a BinaryDecodingError.truncated")
    let url = temporaryFileURL()
    try Data([192]).write(to: url)
    let decoded = AsyncMessageSequence<URL.AsyncBytes, SwiftProtoTesting_TestAllTypes>(baseSequence: url.resourceBytes)
    do {
      for try await _ in decoded {
        XCTFail("Shouldn't have returned a value for an empty stream.")
      }
    } catch {
      if error as! BinaryDecodingError == .truncated {
        expectation.fulfill()
      }
    }
    await fulfillment(of: [expectation], timeout: 1)
  }
  
  // Stream with a valid varint and message, but the following varint is truncated
  func testValidMessageThenTruncatedVarint() async throws {
    let expectSingleMessage = expectation(description: "One message should be deserialized")
    let expectTruncated = expectation(description: "Should encounter a BinaryDecodingError.truncated")
    let url = temporaryFileURL()
    let msg = SwiftProtoTesting_TestAllTypes.with {
      $0.optionalInt64 = 123456789
    }
    
    let truncatedVarint: [UInt8] = [224, 216]
    try writeMessagesToFile(url, messages: [msg], trailingData: truncatedVarint)
    
    do {
      var count = 0
      let decoded = AsyncMessageSequence<URL.AsyncBytes, SwiftProtoTesting_TestAllTypes>(baseSequence: url.resourceBytes)
      for try await message in decoded {
        XCTAssertEqual(message, SwiftProtoTesting_TestAllTypes.with {
          $0.optionalInt64 = 123456789
        })
        count += 1
        if count == 1 {
          expectSingleMessage.fulfill()
        } else {
          XCTFail("Expected one message only.")
        }
      }
    } catch {
      if error as! BinaryDecodingError == .truncated {
        expectTruncated.fulfill()
      }
    }
    await fulfillment(of: [expectSingleMessage, expectTruncated], timeout: 1)
  }
  
  // Creates a URL for a temporary file on disk. Registers a teardown block to
  // delete a file at that URL (if one exists) during test teardown.
  fileprivate func temporaryFileURL() -> URL {
    let directory = NSTemporaryDirectory()
    let filename = UUID().uuidString
    let fileURL = URL(fileURLWithPath: directory).appendingPathComponent(filename)
    
    addTeardownBlock {
      do {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: fileURL.path) {
          try fileManager.removeItem(at: fileURL)
          XCTAssertFalse(fileManager.fileExists(atPath: fileURL.path))
        }
      } catch {
        XCTFail("Error while deleting temporary file: \(error)")
      }
    }
    return fileURL
  }
  
  // Writes messages to the provided URL
  fileprivate func writeMessagesToFile(_ fileURL: URL, messages: [Message], trailingData: [UInt8]? = nil) throws {
    let outputStream = OutputStream(url: fileURL, append: false)!
    outputStream.open()
    for message in messages {
      try BinaryDelimited.serialize(message: message, to: outputStream)
    }
    if let trailingData {
      outputStream.write(trailingData, maxLength: trailingData.count)
    }
    outputStream.close()
  }
}
