// Tests/SwiftProtobufTests/Test_JSONEncodingOptions.swift - Various JSON tests
//
// Copyright (c) 2014 - 2018 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Test for the use of JSONEncodingOptions
///
// -----------------------------------------------------------------------------

import Foundation
import XCTest
import SwiftProtobuf

final class Test_JSONEncodingOptions: XCTestCase {
  
  func testAlwaysPrintInt64sAsNumbers() {
    // Use explicit options (the default is false), no reason only others can be pedantic.
    var asStrings = JSONEncodingOptions()
    asStrings.alwaysPrintInt64sAsNumbers = false
    var asNumbers = JSONEncodingOptions()
    asNumbers.alwaysPrintInt64sAsNumbers = true

    // Toplevel fields.
    let msg1 = SwiftProtoTesting_Message2.with {
      $0.optionalInt64 = 1656338459803
    }
    XCTAssertEqual(try msg1.jsonString(options: asStrings), "{\"optionalInt64\":\"1656338459803\"}")
    XCTAssertEqual(try msg1.jsonString(options: asNumbers), "{\"optionalInt64\":1656338459803}")
    
    let msg2 = SwiftProtoTesting_Message2.with {
      $0.repeatedInt64 = [1656338459802, 1656338459803]
    }
    XCTAssertEqual(try msg2.jsonString(options: asStrings), "{\"repeatedInt64\":[\"1656338459802\",\"1656338459803\"]}")
    XCTAssertEqual(try msg2.jsonString(options: asNumbers), "{\"repeatedInt64\":[1656338459802,1656338459803]}")

    let msg3 = SwiftProtoTesting_Message2.with {
      $0.mapInt64Int64[1656338459803] = 1656338459802
    }
    XCTAssertEqual(try msg3.jsonString(options: asStrings), "{\"mapInt64Int64\":{\"1656338459803\":\"1656338459802\"}}")
    XCTAssertEqual(try msg3.jsonString(options: asNumbers), "{\"mapInt64Int64\":{\"1656338459803\":1656338459802}}")

    // Nested down a level.
    let msg4 = SwiftProtoTesting_Message2.with {
      $0.optionalMessage.optionalInt64 = 1656338459802
    }
    XCTAssertEqual(try msg4.jsonString(options: asStrings), "{\"optionalMessage\":{\"optionalInt64\":\"1656338459802\"}}")
    XCTAssertEqual(try msg4.jsonString(options: asNumbers), "{\"optionalMessage\":{\"optionalInt64\":1656338459802}}")

    let msg5 = SwiftProtoTesting_Message2.with {
      $0.optionalMessage.repeatedInt64 = [1656338459802, 1656338459803]
    }
    XCTAssertEqual(try msg5.jsonString(options: asStrings), "{\"optionalMessage\":{\"repeatedInt64\":[\"1656338459802\",\"1656338459803\"]}}")
    XCTAssertEqual(try msg5.jsonString(options: asNumbers), "{\"optionalMessage\":{\"repeatedInt64\":[1656338459802,1656338459803]}}")

    let msg6 = SwiftProtoTesting_Message2.with {
      $0.optionalMessage.mapInt64Int64[1656338459803] = 1656338459802
    }
    XCTAssertEqual(try msg6.jsonString(options: asStrings), "{\"optionalMessage\":{\"mapInt64Int64\":{\"1656338459803\":\"1656338459802\"}}}")
    XCTAssertEqual(try msg6.jsonString(options: asNumbers), "{\"optionalMessage\":{\"mapInt64Int64\":{\"1656338459803\":1656338459802}}}")

    // Array additions.
    let msgArray = [msg1, msg2, msg3]
    XCTAssertEqual(try SwiftProtoTesting_Message2.jsonString(from: msgArray, options: asStrings),
                   "[" +
                    "{\"optionalInt64\":\"1656338459803\"}" + "," +
                    "{\"repeatedInt64\":[\"1656338459802\",\"1656338459803\"]}" + "," +
                    "{\"mapInt64Int64\":{\"1656338459803\":\"1656338459802\"}}" +
                   "]")
    XCTAssertEqual(try SwiftProtoTesting_Message2.jsonString(from: msgArray, options: asNumbers),
                   "[" +
                    "{\"optionalInt64\":1656338459803}" + "," +
                    "{\"repeatedInt64\":[1656338459802,1656338459803]}" + "," +
                    "{\"mapInt64Int64\":{\"1656338459803\":1656338459802}}" +
                   "]")

    // Any.
    Google_Protobuf_Any.register(messageType: SwiftProtoTesting_TestAllTypes.self)
    let content = SwiftProtoTesting_TestAllTypes.with {
      $0.optionalInt64 = 1656338459803
    }
    let msg7 = try! Google_Protobuf_Any(message: content)
    XCTAssertEqual(try msg7.jsonString(options: asStrings),
                   "{\"@type\":\"type.googleapis.com/swift_proto_testing.TestAllTypes\",\"optionalInt64\":\"1656338459803\"}")
    XCTAssertEqual(try msg7.jsonString(options: asNumbers),
                   "{\"@type\":\"type.googleapis.com/swift_proto_testing.TestAllTypes\",\"optionalInt64\":1656338459803}")

    // UInt64 - Toplevel fields.
    let msg8 = SwiftProtoTesting_Message2.with {
      $0.optionalUint64 = 1656338459803
    }
    XCTAssertEqual(try msg8.jsonString(options: asStrings), "{\"optionalUint64\":\"1656338459803\"}")
    XCTAssertEqual(try msg8.jsonString(options: asNumbers), "{\"optionalUint64\":1656338459803}")
    
    let msg9 = SwiftProtoTesting_Message2.with {
      $0.repeatedUint64 = [1656338459802, 1656338459803]
    }
    XCTAssertEqual(try msg9.jsonString(options: asStrings), "{\"repeatedUint64\":[\"1656338459802\",\"1656338459803\"]}")
    XCTAssertEqual(try msg9.jsonString(options: asNumbers), "{\"repeatedUint64\":[1656338459802,1656338459803]}")

    let msg10 = SwiftProtoTesting_Message2.with {
      $0.mapUint64Uint64[1656338459803] = 1656338459802
    }
    XCTAssertEqual(try msg10.jsonString(options: asStrings), "{\"mapUint64Uint64\":{\"1656338459803\":\"1656338459802\"}}")
    XCTAssertEqual(try msg10.jsonString(options: asNumbers), "{\"mapUint64Uint64\":{\"1656338459803\":1656338459802}}")
  }

  func testAlwaysPrintEnumsAsInts() {
    // Use explicit options (the default is false), just to be pedantic.
    var asStrings = JSONEncodingOptions()
    asStrings.alwaysPrintEnumsAsInts = false
    var asInts = JSONEncodingOptions()
    asInts.alwaysPrintEnumsAsInts = true

    // Toplevel fields

    let msg1 = SwiftProtoTesting_Message3.with {
      $0.optionalEnum = .bar
    }
    XCTAssertEqual(try msg1.jsonString(options: asStrings), "{\"optionalEnum\":\"BAR\"}")
    XCTAssertEqual(try msg1.jsonString(options: asInts), "{\"optionalEnum\":1}")

    let msg2 = SwiftProtoTesting_Message3.with {
      $0.repeatedEnum = [.bar, .baz]
    }
    XCTAssertEqual(try msg2.jsonString(options: asStrings), "{\"repeatedEnum\":[\"BAR\",\"BAZ\"]}")
    XCTAssertEqual(try msg2.jsonString(options: asInts), "{\"repeatedEnum\":[1,2]}")

    let msg3 = SwiftProtoTesting_Message3.with {
      $0.mapInt32Enum[42] = .baz
    }
    XCTAssertEqual(try msg3.jsonString(options: asStrings), "{\"mapInt32Enum\":{\"42\":\"BAZ\"}}")
    XCTAssertEqual(try msg3.jsonString(options: asInts), "{\"mapInt32Enum\":{\"42\":2}}")

    // The enum field nested down a level.

    let msg4 = SwiftProtoTesting_Message3.with {
      $0.optionalMessage.optionalEnum = .bar
    }
    XCTAssertEqual(try msg4.jsonString(options: asStrings),
                   "{\"optionalMessage\":{\"optionalEnum\":\"BAR\"}}")
    XCTAssertEqual(try msg4.jsonString(options: asInts),
                   "{\"optionalMessage\":{\"optionalEnum\":1}}")

    let msg5 = SwiftProtoTesting_Message3.with {
      $0.optionalMessage.repeatedEnum = [.bar, .baz]
    }
    XCTAssertEqual(try msg5.jsonString(options: asStrings),
                   "{\"optionalMessage\":{\"repeatedEnum\":[\"BAR\",\"BAZ\"]}}")
    XCTAssertEqual(try msg5.jsonString(options: asInts),
                   "{\"optionalMessage\":{\"repeatedEnum\":[1,2]}}")

    let msg6 = SwiftProtoTesting_Message3.with {
      $0.optionalMessage.mapInt32Enum[42] = .baz
    }
    XCTAssertEqual(try msg6.jsonString(options: asStrings),
                   "{\"optionalMessage\":{\"mapInt32Enum\":{\"42\":\"BAZ\"}}}")
    XCTAssertEqual(try msg6.jsonString(options: asInts),
                   "{\"optionalMessage\":{\"mapInt32Enum\":{\"42\":2}}}")

    // The array additions

    let msgArray = [msg1, msg2, msg3]
    XCTAssertEqual(try SwiftProtoTesting_Message3.jsonString(from: msgArray, options: asStrings),
                   "[" +
                    "{\"optionalEnum\":\"BAR\"}" + "," +
                    "{\"repeatedEnum\":[\"BAR\",\"BAZ\"]}" + "," +
                    "{\"mapInt32Enum\":{\"42\":\"BAZ\"}}" +
                   "]")
    XCTAssertEqual(try SwiftProtoTesting_Message3.jsonString(from: msgArray, options: asInts),
                   "[" +
                    "{\"optionalEnum\":1}" + "," +
                    "{\"repeatedEnum\":[1,2]}" + "," +
                    "{\"mapInt32Enum\":{\"42\":2}}" +
                   "]")

    // Any

    Google_Protobuf_Any.register(messageType: SwiftProtoTesting_TestAllTypes.self)
    let content = SwiftProtoTesting_TestAllTypes.with {
      $0.optionalNestedEnum = .neg
    }
    let msg7 = try! Google_Protobuf_Any(message: content)
    XCTAssertEqual(try msg7.jsonString(options: asStrings),
                   "{\"@type\":\"type.googleapis.com/swift_proto_testing.TestAllTypes\",\"optionalNestedEnum\":\"NEG\"}")
    XCTAssertEqual(try msg7.jsonString(options: asInts),
                   "{\"@type\":\"type.googleapis.com/swift_proto_testing.TestAllTypes\",\"optionalNestedEnum\":-1}")

  }

  func testPreserveProtoFieldNames() {
    var jsonNames = JSONEncodingOptions()
    jsonNames.preserveProtoFieldNames = false
    var protoNames = JSONEncodingOptions()
    protoNames.preserveProtoFieldNames = true

    // Toplevel fields

    let msg1 = SwiftProtoTesting_Message3.with {
      $0.optionalEnum = .bar
    }
    XCTAssertEqual(try msg1.jsonString(options: jsonNames), "{\"optionalEnum\":\"BAR\"}")
    XCTAssertEqual(try msg1.jsonString(options: protoNames), "{\"optional_enum\":\"BAR\"}")

    let msg2 = SwiftProtoTesting_Message3.with {
      $0.repeatedEnum = [.bar, .baz]
    }
    XCTAssertEqual(try msg2.jsonString(options: jsonNames), "{\"repeatedEnum\":[\"BAR\",\"BAZ\"]}")
    XCTAssertEqual(try msg2.jsonString(options: protoNames), "{\"repeated_enum\":[\"BAR\",\"BAZ\"]}")

    let msg3 = SwiftProtoTesting_Message3.with {
      $0.mapInt32Enum[42] = .baz
    }
    XCTAssertEqual(try msg3.jsonString(options: jsonNames), "{\"mapInt32Enum\":{\"42\":\"BAZ\"}}")
    XCTAssertEqual(try msg3.jsonString(options: protoNames), "{\"map_int32_enum\":{\"42\":\"BAZ\"}}")

    // The enum field nested down a level.

    let msg4 = SwiftProtoTesting_Message3.with {
      $0.optionalMessage.optionalEnum = .bar
    }
    XCTAssertEqual(try msg4.jsonString(options: jsonNames),
                   "{\"optionalMessage\":{\"optionalEnum\":\"BAR\"}}")
    XCTAssertEqual(try msg4.jsonString(options: protoNames),
                   "{\"optional_message\":{\"optional_enum\":\"BAR\"}}")

    let msg5 = SwiftProtoTesting_Message3.with {
      $0.optionalMessage.repeatedEnum = [.bar, .baz]
    }
    XCTAssertEqual(try msg5.jsonString(options: jsonNames),
                   "{\"optionalMessage\":{\"repeatedEnum\":[\"BAR\",\"BAZ\"]}}")
    XCTAssertEqual(try msg5.jsonString(options: protoNames),
                   "{\"optional_message\":{\"repeated_enum\":[\"BAR\",\"BAZ\"]}}")

    let msg6 = SwiftProtoTesting_Message3.with {
      $0.optionalMessage.mapInt32Enum[42] = .baz
    }
    XCTAssertEqual(try msg6.jsonString(options: jsonNames),
                   "{\"optionalMessage\":{\"mapInt32Enum\":{\"42\":\"BAZ\"}}}")
    XCTAssertEqual(try msg6.jsonString(options: protoNames),
                   "{\"optional_message\":{\"map_int32_enum\":{\"42\":\"BAZ\"}}}")

    // The array additions

    let msgArray = [msg1, msg2, msg3]
    XCTAssertEqual(try SwiftProtoTesting_Message3.jsonString(from: msgArray, options: jsonNames),
                   "[" +
                    "{\"optionalEnum\":\"BAR\"}" + "," +
                    "{\"repeatedEnum\":[\"BAR\",\"BAZ\"]}" + "," +
                    "{\"mapInt32Enum\":{\"42\":\"BAZ\"}}" +
                   "]")
    XCTAssertEqual(try SwiftProtoTesting_Message3.jsonString(from: msgArray, options: protoNames),
                   "[" +
                    "{\"optional_enum\":\"BAR\"}" + "," +
                    "{\"repeated_enum\":[\"BAR\",\"BAZ\"]}" + "," +
                    "{\"map_int32_enum\":{\"42\":\"BAZ\"}}" +
                   "]")

    // Any

    Google_Protobuf_Any.register(messageType: SwiftProtoTesting_TestAllTypes.self)
    let content = SwiftProtoTesting_TestAllTypes.with {
      $0.optionalNestedEnum = .neg
    }
    let msg7 = try! Google_Protobuf_Any(message: content)
    XCTAssertEqual(try msg7.jsonString(options: jsonNames),
                   "{\"@type\":\"type.googleapis.com/swift_proto_testing.TestAllTypes\",\"optionalNestedEnum\":\"NEG\"}")
    XCTAssertEqual(try msg7.jsonString(options: protoNames),
                   "{\"@type\":\"type.googleapis.com/swift_proto_testing.TestAllTypes\",\"optional_nested_enum\":\"NEG\"}")
  }

  func testUseDeterministicOrdering() {
    var options = JSONEncodingOptions()
    options.useDeterministicOrdering = true

    let stringMap = SwiftProtoTesting_Message3.with {
      $0.mapStringString = [
        "b": "B",
        "a": "A",
        "0": "0",
        "UPPER": "v",
        "x": "X",
      ]
    }
    XCTAssertEqual(
      try stringMap.jsonString(options: options),
      "{\"mapStringString\":{\"0\":\"0\",\"UPPER\":\"v\",\"a\":\"A\",\"b\":\"B\",\"x\":\"X\"}}"
    )

    let messageMap = SwiftProtoTesting_Message3.with {
      $0.mapInt32Message = [
        5: .with { $0.optionalSint32 = 5 },
        1: .with { $0.optionalSint32 = 1 },
        3: .with { $0.optionalSint32 = 3 },
      ]
    }
    XCTAssertEqual(
      try messageMap.jsonString(options: options),
      "{\"mapInt32Message\":{\"1\":{\"optionalSint32\":1},\"3\":{\"optionalSint32\":3},\"5\":{\"optionalSint32\":5}}}"
    )

    let enumMap = SwiftProtoTesting_Message3.with {
      $0.mapInt32Enum = [
        5: .foo,
        3: .bar,
        0: .baz,
        1: .extra3,
      ]
    }
    XCTAssertEqual(
      try enumMap.jsonString(options: options),
      "{\"mapInt32Enum\":{\"0\":\"BAZ\",\"1\":\"EXTRA_3\",\"3\":\"BAR\",\"5\":\"FOO\"}}"
    )
  }
}
