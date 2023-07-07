// Tests/SwiftProtobufTests/Test_StreamDecodingIterator.swift - Delimited message tests
//
// Copyright (c) 2023 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------

import Foundation
import XCTest
import SwiftProtobuf

class Test_StreamDecodingIterator: XCTestCase, StreamErrorDelegate {
  
  var error: Error?
  var errorExpectation: XCTestExpectation?
  
  func onError(error: Error) {
    guard let expectation = errorExpectation else {
      XCTFail("Unexpected error: \(error)")
      return
    }
    self.error = error
    self.errorExpectation?.fulfill()
    self.errorExpectation = nil
  }
  
  //Decode zero length messages
  func testZeroLengthMessages() {
    var messages = [ProtobufUnittest_TestAllTypes]()
    for _ in 1...10 {
      messages.append(ProtobufUnittest_TestAllTypes())
    }
    
    let data = serializeToMemory(messages: messages)
    XCTAssertEqual(data.count, 10) //Should be 10 zero varints
    
    let inputStream = InputStream(data: data)
    inputStream.open()
    let iterator = ProtobufUnittest_TestAllTypes.streamDecodingIterator(inputStream: inputStream, errorDelegate: self)
    var count = 0
    while let message = iterator.next() {
      XCTAssertEqual(message, ProtobufUnittest_TestAllTypes())
      count += 1
    }
    XCTAssertEqual(count, 10)
    inputStream.close()
  }
  
  //Empty stream with no bytes
  func testEmptyStream() {
    let inputStream = InputStream(data: Data(count: 0))
    inputStream.open()
    let iterator = ProtobufUnittest_TestAllTypes.streamDecodingIterator(inputStream: inputStream, errorDelegate: self)
    while let _ = iterator.next() {
      XCTFail("Shouldn't have returned a value for an empty stream.")
    }
    inputStream.close()
  }
  
  //Stream with truncated varint
  func testTruncatedVarint() throws {
    errorExpectation = expectation(description: "Should encounter a BinaryDecodingError.truncated")
    
    let inputStream = InputStream(data: Data([192]))
    inputStream.open()
    let iterator = ProtobufUnittest_TestAllTypes.streamDecodingIterator(inputStream: inputStream, errorDelegate: self)
    while let _ = iterator.next() {
      XCTFail("Zero messages should be encountered.")
    }
    waitForExpectations(timeout: 1)
    XCTAssertEqual(error as! BinaryDecodingError, BinaryDecodingError.truncated)
    inputStream.close()
  }
  
  //Stream with zero varint and nothing else
  //Should yield a single default message
  func testStreamZeroVarintOnly() {
    let inputStream = InputStream(data: Data([0]))
    inputStream.open()
    let iterator = ProtobufUnittest_TestAllTypes.streamDecodingIterator(inputStream: inputStream, errorDelegate: self)
    
    let message = ProtobufUnittest_TestAllTypes()
    var count = 0
    while let m = iterator.next() {
      XCTAssertEqual(m, message)
      count += 1
    }
    XCTAssertEqual(count, 1)
    inputStream.close()
  }
  
  //A stream with legal non-zero varint but no message
  func testNonZeroVarintNoMessage() throws {
    errorExpectation = expectation(description: "Should encounter a BinaryDecodingError.truncated")
    
    let inputStream = InputStream(data: Data([192, 12])) //denotes a message length of 1600 bytes
    inputStream.open()
    let iterator = ProtobufUnittest_TestAllTypes.streamDecodingIterator(inputStream: inputStream, errorDelegate: self)
    while let _ = iterator.next() {
      XCTFail("Zero messages should be encountered.")
    }
    waitForExpectations(timeout: 1)
    XCTAssertEqual(error as! BinaryDecodingError, BinaryDecodingError.truncated)
    inputStream.close()
  }
  
  //Stream with a valid varint and message, but the following varint is truncated
  func testValidMessageThenTruncatedVarint() {
    errorExpectation = expectation(description: "Should encounter a BinaryDecodingError.truncated")
    
    let msg = ProtobufUnittest_TestAllTypes.with {
      $0.optionalBool = true
      $0.optionalInt32 = 54321
      $0.optionalInt64 = 123456789
      $0.optionalGroup.a = 456
      $0.optionalNestedEnum = .baz
      $0.repeatedString.append("wee")
      $0.repeatedFloat.append(1.23)
    }
    
    var data = serializeToMemory(messages: [msg])
    let truncatedVarint: [UInt8] = [224, 216]
    data += truncatedVarint
    
    let memoryInputStream = InputStream(data: data)
    memoryInputStream.open()
    let iterator = ProtobufUnittest_TestAllTypes.streamDecodingIterator(inputStream: memoryInputStream, errorDelegate: self)
    
    var count = 0
    while let message = iterator.next() {
      XCTAssertEqual(msg, message)
      count += 1
    }
    XCTAssertEqual(count, 1)
    
    waitForExpectations(timeout: 1)
    XCTAssertEqual(error as! BinaryDecodingError, BinaryDecodingError.truncated)
    memoryInputStream.close()
  }
  
  //write 10 messages to memory and ensure they are rehydrated correctly
  //the small buffer ensures messages are recreated using multiple buffer reads
  func testNormalExecutionSmallBuffer() {
    
    var messages = [ProtobufUnittest_TestAllTypes]()
    for testInt in 1...10 {
      let message = ProtobufUnittest_TestAllTypes.with {
        $0.optionalBool = true
        $0.optionalInt32 = Int32(testInt)
        $0.optionalInt64 = 123456789
        $0.optionalGroup.a = 456
        $0.optionalNestedEnum = .baz
        $0.repeatedString.append("wee")
        $0.repeatedFloat.append(1.23)
      }
      messages.append(message)
    }
    
    let data = serializeToMemory(messages: messages)
    
    let inputStream = InputStream(data: data)
    inputStream.open()
    
    let iterator = ProtobufUnittest_TestAllTypes.streamDecodingIterator(inputStream: inputStream, bufferLength: 8, errorDelegate: self)
    var messageCount: Int32 = 0
    while let message = iterator.next() {
      messageCount += 1
      let msg1 = ProtobufUnittest_TestAllTypes.with {
        $0.optionalBool = true
        $0.optionalInt32 = Int32(messageCount)
        $0.optionalInt64 = 123456789
        $0.optionalGroup.a = 456
        $0.optionalNestedEnum = .baz
        $0.repeatedString.append("wee")
        $0.repeatedFloat.append(1.23)
      }
      XCTAssertEqual(msg1, message)
    }
    XCTAssertEqual(messageCount, 10)
    inputStream.close()
  }
  
  //write 10 messages to memory and ensure they are rehydrated correctly
  func testNormalExecution() {
    var messages = [ProtobufUnittest_TestAllTypes]()
    for testInt in 1...10 {
      let message = ProtobufUnittest_TestAllTypes.with {
        $0.optionalBool = true
        $0.optionalInt32 = Int32(testInt)
        $0.optionalInt64 = 123456789
        $0.optionalGroup.a = 456
        $0.optionalNestedEnum = .baz
        $0.repeatedString.append("wee")
        $0.repeatedFloat.append(1.23)
      }
      messages.append(message)
    }
    
    let data = serializeToMemory(messages: messages)
    
    let inputStream = InputStream(data: data)
    inputStream.open()
    let iterator = ProtobufUnittest_TestAllTypes.streamDecodingIterator(inputStream: inputStream, errorDelegate: self)
    var messageCount: Int32 = 0
    while let message = iterator.next() {
      messageCount += 1
      let msg1 = ProtobufUnittest_TestAllTypes.with {
        $0.optionalBool = true
        $0.optionalInt32 = Int32(messageCount)
        $0.optionalInt64 = 123456789
        $0.optionalGroup.a = 456
        $0.optionalNestedEnum = .baz
        $0.repeatedString.append("wee")
        $0.repeatedFloat.append(1.23)
      }
      XCTAssertEqual(msg1, message)
    }
    XCTAssertEqual(messageCount, 10)
    inputStream.close()
  }
  
  fileprivate func serializeToMemory(messages: [Message]) -> Data {
    let memoryOutputStream = OutputStream.toMemory()
    memoryOutputStream.open()
    for message in messages {
      XCTAssertNoThrow(try BinaryDelimited.serialize(message: message, to: memoryOutputStream))
    }
    memoryOutputStream.close()
    // See https://bugs.swift.org/browse/SR-5404
    let nsData = memoryOutputStream.property(forKey: .dataWrittenToMemoryStreamKey) as! NSData
    return Data(referencing: nsData)
  }
}
