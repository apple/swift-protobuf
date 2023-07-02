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
    self.error = error
    self.errorExpectation?.fulfill()
    self.errorExpectation = nil
  }
  
  //Empty stream with no bytes
  func testEmptyStream() {
    let inputStream = InputStream(data: Data(count: 0))
    inputStream.open()
    let iterator = ProtobufUnittest_TestAllTypes.streamDecodingIterator(inputStream: inputStream)
    while let _ = iterator.next() {
      XCTFail("Stream was empty")
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
    XCTAssert(error as! BinaryDecodingError == BinaryDecodingError.truncated)
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
    XCTAssert(count == 1)
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
    XCTAssert(error as! BinaryDecodingError == BinaryDecodingError.truncated)
    inputStream.close()
  }
  
  //Stream with a valid varint and message, but the following varint is truncated
  func testValidMessageThenTruncatedVarint() {
    errorExpectation = expectation(description: "Should encounter a BinaryDecodingError.truncated")
    
    let memoryOutputStream = OutputStream.toMemory()
    memoryOutputStream.open()
    let msg = ProtobufUnittest_TestAllTypes.with {
      $0.optionalBool = true
      $0.optionalInt32 = 54321
      $0.optionalInt64 = 123456789
      $0.optionalGroup.a = 456
      $0.optionalNestedEnum = .baz
      $0.repeatedString.append("wee")
      $0.repeatedFloat.append(1.23)
    }
    XCTAssertNoThrow(try BinaryDelimited.serialize(message: msg, to: memoryOutputStream))
    let truncatedVarint: [UInt8] = [224, 216]
    
    truncatedVarint.withUnsafeBytes {
      guard let pointer = $0.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
        return
      }
      memoryOutputStream.write(pointer, maxLength: truncatedVarint.count)
    }
    
    memoryOutputStream.close()
    let nsData = memoryOutputStream.property(forKey: .dataWrittenToMemoryStreamKey) as! NSData
    
    let data = Data(referencing: nsData)
    let memoryInputStream = InputStream(data: data)
    memoryInputStream.open()
    let iterator = ProtobufUnittest_TestAllTypes.streamDecodingIterator(inputStream: memoryInputStream, errorDelegate: self)
    
    var count = 0
    while let message = iterator.next() {
      XCTAssertEqual(msg, message)
      count += 1
    }
    XCTAssert(count == 1)
    
    waitForExpectations(timeout: 1)
    XCTAssert(error as! BinaryDecodingError == BinaryDecodingError.truncated)
    memoryInputStream.close()
  }
  
  //write 10 messages to memory and ensure they are rehydrated correctly
  //the small buffer ensures messages are recreated using multiple buffer reads
  func testNormalExecutionSmallBuffer() {
    let memoryOutputStream = OutputStream.toMemory()
    writeTestMessages(memoryOutputStream)
    // See https://bugs.swift.org/browse/SR-5404
    let nsData = memoryOutputStream.property(forKey: .dataWrittenToMemoryStreamKey) as! NSData
    let data = Data(referencing: nsData)
    let memoryInputStream = InputStream(data: data)
    memoryInputStream.open()
    
    let iterator = ProtobufUnittest_TestAllTypes.streamDecodingIterator(inputStream: memoryInputStream, bufferLength: 8)
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
    memoryInputStream.close()
  }
  
  //write 10 messages to memory and ensure they are rehydrated correctly
  func testNormalExecution() {
    let memoryOutputStream = OutputStream.toMemory()
    writeTestMessages(memoryOutputStream)
    
    // See https://bugs.swift.org/browse/SR-5404
    let nsData = memoryOutputStream.property(forKey: .dataWrittenToMemoryStreamKey) as! NSData
    let data = Data(referencing: nsData)
    let memoryInputStream = InputStream(data: data)
    memoryInputStream.open()
    
    let iterator = ProtobufUnittest_TestAllTypes.streamDecodingIterator(inputStream: memoryInputStream)
    var testInt: Int32 = 0
    while let message = iterator.next() {
      testInt += 1
      let msg1 = ProtobufUnittest_TestAllTypes.with {
        $0.optionalBool = true
        $0.optionalInt32 = Int32(testInt)
        $0.optionalInt64 = 123456789
        $0.optionalGroup.a = 456
        $0.optionalNestedEnum = .baz
        $0.repeatedString.append("wee")
        $0.repeatedFloat.append(1.23)
      }
      XCTAssertEqual(msg1, message)
    }
    XCTAssertEqual(testInt, 10)
    memoryInputStream.close()
  }
  
  fileprivate func writeTestMessages(_ memoryOutputStream: OutputStream)  {
    memoryOutputStream.open()
    
    for testInt in 1...10 {
      let msg1 = ProtobufUnittest_TestAllTypes.with {
        $0.optionalBool = true
        $0.optionalInt32 = Int32(testInt)
        $0.optionalInt64 = 123456789
        $0.optionalGroup.a = 456
        $0.optionalNestedEnum = .baz
        $0.repeatedString.append("wee")
        $0.repeatedFloat.append(1.23)
      }
      XCTAssertNoThrow(try BinaryDelimited.serialize(message: msg1, to: memoryOutputStream))
    }
    memoryOutputStream.close()
  }
}
