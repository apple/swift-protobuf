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
    let serialized = try serializedMessageData(messages: messages)
    let asyncBytes = asyncByteStream(bytes: serialized)
    
    // Recreate the original array
    let decoded = asyncBytes.binaryProtobufDelimitedMessages(of: SwiftProtoTesting_TestAllTypes.self)
    let observed = try await decoded.reduce(into: [Int32]()) { array, element in
      array.append(element.optionalInt32)
    }
    XCTAssertEqual(observed, expected, "The original and re-created arrays should be equal.")
  }
  
  // Decode a message from a stream, discarding unknown fields
  func testBinaryDecodingOptions() async throws {
    let unknownFields: [UInt8] = [
      // Field 1, 150
      0x08, 0x96, 0x01,
      // Field 2, string "testing"
      0x12, 0x07, 0x74, 0x65, 0x73, 0x74, 0x69, 0x6e, 0x67
    ]
    let message = try SwiftProtoTesting_TestEmptyMessage(serializedBytes: unknownFields)
    let serialized = try serializedMessageData(messages: [message])
    var asyncBytes = asyncByteStream(bytes: serialized)
    var decodingOptions = BinaryDecodingOptions()
    let decodedWithUnknown = asyncBytes.binaryProtobufDelimitedMessages(
      of: SwiftProtoTesting_TestEmptyMessage.self,
      options: decodingOptions
    )
    
    // First ensure unknown fields are decoded
    for try await message in decodedWithUnknown {
      XCTAssertEqual(Array(message.unknownFields.data), unknownFields)
    }
    asyncBytes = asyncByteStream(bytes: serialized)
    // Then re-run ensuring unknowh fields are discarded
    decodingOptions.discardUnknownFields = true
    let decodedWithUnknownDiscarded = asyncBytes.binaryProtobufDelimitedMessages(
      of: SwiftProtoTesting_TestEmptyMessage.self,
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
    let serialized = try serializedMessageData(messages: messages)
    let asyncBytes = asyncByteStream(bytes: serialized)
    
    var count = 0
    let decoded = AsyncMessageSequence<AsyncStream<UInt8>, SwiftProtoTesting_TestAllTypes>(base: asyncBytes)
    for try await message in decoded {
      XCTAssertEqual(message, SwiftProtoTesting_TestAllTypes())
      count += 1
    }
    XCTAssertEqual(count, 5, "Expected five messages with default fields.")
  }
  
  // Stream with a single zero varint
  func testStreamZeroVarintOnly() async throws {
    let seq = asyncByteStream(bytes: [0])
    let decoded = seq.binaryProtobufDelimitedMessages(of: SwiftProtoTesting_TestAllTypes.self)
    
    var count = 0
    for try await message in decoded {
      XCTAssertEqual(message, SwiftProtoTesting_TestAllTypes())
      count += 1
    }
    XCTAssertEqual(count, 1)
  }
  
  // Empty stream with zero bytes
  func testEmptyStream() async throws {
    let asyncBytes = asyncByteStream(bytes: [])
    let messages = asyncBytes.binaryProtobufDelimitedMessages(of: SwiftProtoTesting_TestAllTypes.self)
    for try await _ in messages {
      XCTFail("Shouldn't have returned a value for an empty stream.")
    }
  }
  
  // A stream with legal non-zero varint but no message
  func testNonZeroVarintNoMessage() async throws {
    let asyncBytes = asyncByteStream(bytes: [0x96, 0x01])
    let decoded = asyncBytes.binaryProtobufDelimitedMessages(of: SwiftProtoTesting_TestAllTypes.self)
    var truncatedThrown = false
    do {
      for try await _ in decoded {
        XCTFail("Shouldn't have returned a value for an empty stream.")
      }
    } catch {
      if error as! BinaryDelimited.Error == .truncated {
        truncatedThrown = true
      }
    }
    XCTAssertTrue(truncatedThrown, "Should throw a SwiftProtobufError.BinaryStreamDecoding.truncated")
  }
  
  // Single varint describing a 2GB message
  func testTooLarge() async throws {
    let asyncBytes = asyncByteStream(bytes: [128, 128, 128, 128, 8])
    let decoded = asyncBytes.binaryProtobufDelimitedMessages(of: SwiftProtoTesting_TestAllTypes.self)
    do {
      for try await _ in decoded {
        XCTFail("Shouldn't have returned a value for an invalid stream.")
      }
    } catch {
      XCTAssertTrue(self.isSwiftProtobufErrorEqual(error as! SwiftProtobufError, .BinaryDecoding.tooLarge()))
    }
  }
  
  // Stream with truncated varint
  func testTruncatedVarint() async throws {
    let asyncBytes = asyncByteStream(bytes: [192])
    
    let decoded = asyncBytes.binaryProtobufDelimitedMessages(of: SwiftProtoTesting_TestAllTypes.self)
    var truncatedThrown = false
    do {
      for try await _ in decoded {
        XCTFail("Shouldn't have returned a value for an empty stream.")
      }
    } catch {
      if error as! BinaryDelimited.Error == .truncated {
        truncatedThrown = true
      }
    }
    XCTAssertTrue(truncatedThrown, "Should throw a SwiftProtobufError.BinaryStreamDecoding.truncated")
  }
  
  // Stream with a valid varint and message, but the following varint is truncated
  func testValidMessageThenTruncatedVarint() async throws {
    var truncatedThrown = false
    let msg = SwiftProtoTesting_TestAllTypes.with {
      $0.optionalInt64 = 123456789
    }
    let truncatedVarint: [UInt8] = [224, 216]
    var serialized = try serializedMessageData(messages: [msg])
    serialized += truncatedVarint
    let asyncBytes = asyncByteStream(bytes: serialized)
    
    do {
      var count = 0
      let decoded = asyncBytes.binaryProtobufDelimitedMessages(of: SwiftProtoTesting_TestAllTypes.self)
      for try await message in decoded {
        XCTAssertEqual(message, SwiftProtoTesting_TestAllTypes.with {
          $0.optionalInt64 = 123456789
        })
        count += 1
        if count > 1 {
          XCTFail("Expected one message only.")
        }
      }
      XCTAssertEqual(count, 1, "One message should be deserialized")
    } catch {
      if error as! BinaryDelimited.Error == .truncated {
        truncatedThrown = true
      }
    }
    XCTAssertTrue(truncatedThrown, "Should throw a SwiftProtobuf.BinaryStreamDecoding.truncated")
  }

  // Slow test case found by oss-fuzz: 1 million zero-sized messages
  // A similar test with BinaryDelimited is about 4x faster, showing
  // that we have some room for improvement here.
  // (Note this currently only tests 100,000 zero-sized messages,
  // but the constant below is easy to edit if you want to experiment.)
  func testLargeExample() async throws {
    let messageCount = 100_000
    let bytes = [UInt8](repeating: 0, count: messageCount)
    let byteStream = asyncByteStream(bytes: bytes)
    let decodedStream = byteStream.binaryProtobufDelimitedMessages(
                    of: SwiftProtoTesting_TestAllTypes.self,
                    extensions: SwiftProtoTesting_Fuzz_FuzzTesting_Extensions)
    var count = 0
    for try await message in decodedStream {
      XCTAssertEqual(message, SwiftProtoTesting_TestAllTypes())
      count += 1
    }
    XCTAssertEqual(count, messageCount)
  }
  
  fileprivate func asyncByteStream(bytes: [UInt8]) -> AsyncStream<UInt8> {
      AsyncStream(UInt8.self) { continuation in
        for byte in bytes {
          continuation.yield(byte)
        }
        continuation.finish()
      }
  }

  fileprivate func serializedMessageData(messages: [any Message]) throws -> [UInt8] {
    let memoryOutputStream = OutputStream.toMemory()
    memoryOutputStream.open()
    for message in messages {
      XCTAssertNoThrow(try BinaryDelimited.serialize(message: message, to: memoryOutputStream))
    }
    memoryOutputStream.close()
    let nsData = memoryOutputStream.property(forKey: .dataWrittenToMemoryStreamKey) as! NSData
    let data = Data(referencing: nsData)
    return [UInt8](data)
  }
}
