// Tests/SwiftProtobufTests/Test_JSONEncodingOptions.swift - Various JSON tests
//
// Copyright (c) 2014 - 2018 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Test for the use of JSONEncodingOptions
///
// -----------------------------------------------------------------------------

import Foundation
import XCTest
import SwiftProtobuf

class Test_JSONEncodingOptions: XCTestCase {

  func testAlwaysPrintEnumsAsInts() {
    // Use explict options (the default is false), just to be pedantic.
    var asStrings = JSONEncodingOptions()
    asStrings.alwaysPrintEnumsAsInts = false
    var asInts = JSONEncodingOptions()
    asInts.alwaysPrintEnumsAsInts = true

    // Toplevel fields

    let msg1 = ProtobufUnittest_Message3.with {
      $0.optionalEnum = .bar
    }
    XCTAssertEqual(try msg1.jsonString(options: asStrings), "{\"optionalEnum\":\"BAR\"}")
    XCTAssertEqual(try msg1.jsonString(options: asInts), "{\"optionalEnum\":1}")

    let msg2 = ProtobufUnittest_Message3.with {
      $0.repeatedEnum = [.bar, .baz]
    }
    XCTAssertEqual(try msg2.jsonString(options: asStrings), "{\"repeatedEnum\":[\"BAR\",\"BAZ\"]}")
    XCTAssertEqual(try msg2.jsonString(options: asInts), "{\"repeatedEnum\":[1,2]}")

    let msg3 = ProtobufUnittest_Message3.with {
      $0.mapInt32Enum[42] = .baz
    }
    XCTAssertEqual(try msg3.jsonString(options: asStrings), "{\"mapInt32Enum\":{\"42\":\"BAZ\"}}")
    XCTAssertEqual(try msg3.jsonString(options: asInts), "{\"mapInt32Enum\":{\"42\":2}}")

    // The enum field nested down a level.

    let msg4 = ProtobufUnittest_Message3.with {
      $0.optionalMessage.optionalEnum = .bar
    }
    XCTAssertEqual(try msg4.jsonString(options: asStrings),
                   "{\"optionalMessage\":{\"optionalEnum\":\"BAR\"}}")
    XCTAssertEqual(try msg4.jsonString(options: asInts),
                   "{\"optionalMessage\":{\"optionalEnum\":1}}")

    let msg5 = ProtobufUnittest_Message3.with {
      $0.optionalMessage.repeatedEnum = [.bar, .baz]
    }
    XCTAssertEqual(try msg5.jsonString(options: asStrings),
                   "{\"optionalMessage\":{\"repeatedEnum\":[\"BAR\",\"BAZ\"]}}")
    XCTAssertEqual(try msg5.jsonString(options: asInts),
                   "{\"optionalMessage\":{\"repeatedEnum\":[1,2]}}")

    let msg6 = ProtobufUnittest_Message3.with {
      $0.optionalMessage.mapInt32Enum[42] = .baz
    }
    XCTAssertEqual(try msg6.jsonString(options: asStrings),
                   "{\"optionalMessage\":{\"mapInt32Enum\":{\"42\":\"BAZ\"}}}")
    XCTAssertEqual(try msg6.jsonString(options: asInts),
                   "{\"optionalMessage\":{\"mapInt32Enum\":{\"42\":2}}}")

    // The array additions

    let msgArray = [msg1, msg2, msg3]
    XCTAssertEqual(try ProtobufUnittest_Message3.jsonString(from: msgArray, options: asStrings),
                   "[" +
                    "{\"optionalEnum\":\"BAR\"}" + "," +
                    "{\"repeatedEnum\":[\"BAR\",\"BAZ\"]}" + "," +
                    "{\"mapInt32Enum\":{\"42\":\"BAZ\"}}" +
                   "]")
    XCTAssertEqual(try ProtobufUnittest_Message3.jsonString(from: msgArray, options: asInts),
                   "[" +
                    "{\"optionalEnum\":1}" + "," +
                    "{\"repeatedEnum\":[1,2]}" + "," +
                    "{\"mapInt32Enum\":{\"42\":2}}" +
                   "]")

    // Any

    Google_Protobuf_Any.register(messageType: ProtobufUnittest_TestAllTypes.self)
    let content = ProtobufUnittest_TestAllTypes.with {
      $0.optionalNestedEnum = .neg
    }
    let msg7 = try! Google_Protobuf_Any(message: content)
    XCTAssertEqual(try msg7.jsonString(options: asStrings),
                   "{\"@type\":\"type.googleapis.com/protobuf_unittest.TestAllTypes\",\"optionalNestedEnum\":\"NEG\"}")
    XCTAssertEqual(try msg7.jsonString(options: asInts),
                   "{\"@type\":\"type.googleapis.com/protobuf_unittest.TestAllTypes\",\"optionalNestedEnum\":-1}")

  }

}
