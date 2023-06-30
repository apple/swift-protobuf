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

class Test_StreamDecodingIterator: XCTestCase {
  
  func testEverything() {
    //Adapted from Test_BinaryDelimited
    
    let memoryOutputStream = OutputStream.toMemory()
    memoryOutputStream.open()
    
    for testInt in 0...10 {
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
    // See https://bugs.swift.org/browse/SR-5404
    let nsData = memoryOutputStream.property(forKey: .dataWrittenToMemoryStreamKey) as! NSData
    let data = Data(referencing: nsData)
    let memoryInputStream = InputStream(data: data)
    memoryInputStream.open()
    
    let iterator = ProtobufUnittest_TestAllTypes.streamDecodingIterator(inputStream: memoryInputStream)
    var testInt: Int32 = 0
    while let message = iterator.next() {
      let msg1 = ProtobufUnittest_TestAllTypes.with {
        $0.optionalBool = true
        $0.optionalInt32 = Int32(testInt)
        $0.optionalInt64 = 123456789
        $0.optionalGroup.a = 456
        $0.optionalNestedEnum = .baz
        $0.repeatedString.append("wee")
        $0.repeatedFloat.append(1.23)
      }
      testInt += 1
      XCTAssertEqual(msg1, message)
    }
  }
}
