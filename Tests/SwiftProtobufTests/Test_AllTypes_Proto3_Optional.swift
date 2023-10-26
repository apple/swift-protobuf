// Tests/SwiftProtobufTests/Test_AllTypes.swift - Basic encoding/decoding test
//
// Copyright (c) 2014 - 2020 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// This is a thorough test of the binary protobuf encoding and decoding.
/// It attempts to verify the encoded form for every basic proto type
/// and verify correct decoding, including handling of unusual-but-valid
/// sequences and error reporting for invalid sequences.
///
// -----------------------------------------------------------------------------

import Foundation
import XCTest

final class Test_AllTypes_Proto3_Optional: XCTestCase, PBTestHelpers {
    typealias MessageTestType = SwiftProtoTesting_TestProto3Optional

    // Custom decodeSucceeds that also does a round-trip through the Empty
    // message to make sure unknown fields are consistently preserved by proto2.
    func assertDecodeSucceeds(_ bytes: [UInt8], file: XCTestFileArgType = #file, line: UInt = #line, check: (MessageTestType) -> Bool) {
        baseAssertDecodeSucceeds(bytes, file: file, line: line, check: check)
        do {
            // Make sure unknown fields are preserved by empty message decode/encode
            let empty = try SwiftProtoTesting_TestEmptyMessage(serializedBytes: bytes)
            do {
                let newBytes: [UInt8] = try empty.serializedBytes()
                XCTAssertEqual(bytes, newBytes, "Empty decode/recode did not match", file: file, line: line)
            } catch let e {
                XCTFail("Reserializing empty threw an error: \(e)", file: file, line: line)
            }
        } catch {
            XCTFail("Empty decoding threw an error", file: file, line: line)
        }
    }

    //
    // Optional Singular types
    //
    // Setting the values to zero values to ensure when encoded the values are captured.

    func testEncoding_optionalInt32() {
        assertEncode([8, 0]) {(o: inout MessageTestType) in o.optionalInt32 = 0}
        assertDecodeSucceeds([8, 0]) {$0.hasOptionalInt32 && $0.optionalInt32 == 0}
        assertDebugDescription("SwiftProtobufTests.SwiftProtoTesting_TestProto3Optional:\noptional_int32: 0\n") {(o: inout MessageTestType) in o.optionalInt32 = 0}
        assertDebugDescription("SwiftProtobufTests.SwiftProtoTesting_TestProto3Optional:\n") {(o: inout MessageTestType) in
            o.optionalInt32 = 0
            o.clearOptionalInt32()
        }

        let empty = MessageTestType()
        var a = empty
        a.optionalInt32 = 0
        XCTAssertNotEqual(a, empty)
        var b = empty
        b.optionalInt32 = 1
        XCTAssertNotEqual(a, b)
        b.clearOptionalInt32()
        XCTAssertNotEqual(a, b)
        b.optionalInt32 = 0
        XCTAssertEqual(a, b)
    }

    func testEncoding_optionalInt64() {
        assertEncode([16, 0]) {(o: inout MessageTestType) in o.optionalInt64 = 0}
        assertDecodeSucceeds([16, 0]) {$0.hasOptionalInt64 && $0.optionalInt64 == 0}
        assertDebugDescription("SwiftProtobufTests.SwiftProtoTesting_TestProto3Optional:\noptional_int64: 0\n") {(o: inout MessageTestType) in o.optionalInt64 = 0}
        assertDebugDescription("SwiftProtobufTests.SwiftProtoTesting_TestProto3Optional:\n") {(o: inout MessageTestType) in
          o.optionalInt64 = 0
          o.clearOptionalInt64()
        }

        let empty = MessageTestType()
        var a = empty
        a.optionalInt64 = 0
        XCTAssertNotEqual(a, empty)
        var b = empty
        b.optionalInt64 = 1
        XCTAssertNotEqual(a, b)
        b.clearOptionalInt64()
        XCTAssertNotEqual(a, b)
        b.optionalInt64 = 0
        XCTAssertEqual(a, b)

        // Ensure storage is uniqued for clear.
        let c = MessageTestType.with {
            $0.optionalInt64 = 1
        }
        var d = c
        XCTAssertEqual(c, d)
        XCTAssertTrue(c.hasOptionalInt64)
        XCTAssertTrue(d.hasOptionalInt64)
        d.clearOptionalInt64()
        XCTAssertNotEqual(c, d)
        XCTAssertTrue(c.hasOptionalInt64)
        XCTAssertFalse(d.hasOptionalInt64)
    }

    func testEncoding_optionalUint32() {
        assertEncode([24, 0]) {(o: inout MessageTestType) in o.optionalUint32 = 0}
        assertDecodeSucceeds([24, 0]) {$0.hasOptionalUint32 && $0.optionalUint32 == 0}
        assertDebugDescription("SwiftProtobufTests.SwiftProtoTesting_TestProto3Optional:\noptional_uint32: 0\n") {(o: inout MessageTestType) in o.optionalUint32 = 0}
        assertDebugDescription("SwiftProtobufTests.SwiftProtoTesting_TestProto3Optional:\n") {(o: inout MessageTestType) in
          o.optionalUint32 = 0
          o.clearOptionalUint32()
        }

        let empty = MessageTestType()
        var a = empty
        a.optionalUint32 = 0
        XCTAssertNotEqual(a, empty)
        var b = empty
        b.optionalUint32 = 1
        XCTAssertNotEqual(a, b)
        b.clearOptionalUint32()
        XCTAssertNotEqual(a, b)
        b.optionalUint32 = 0
        XCTAssertEqual(a, b)

        // Ensure storage is uniqued for clear.
        let c = MessageTestType.with {
            $0.optionalUint32 = 1
        }
        var d = c
        XCTAssertEqual(c, d)
        XCTAssertTrue(c.hasOptionalUint32)
        XCTAssertTrue(d.hasOptionalUint32)
        d.clearOptionalUint32()
        XCTAssertNotEqual(c, d)
        XCTAssertTrue(c.hasOptionalUint32)
        XCTAssertFalse(d.hasOptionalUint32)
    }

    func testEncoding_optionalUint64() {
        assertEncode([32, 0]) {(o: inout MessageTestType) in o.optionalUint64 = 0}
        assertDecodeSucceeds([32, 0]) {$0.hasOptionalUint64 && $0.optionalUint64 == 0}
        assertDebugDescription("SwiftProtobufTests.SwiftProtoTesting_TestProto3Optional:\noptional_uint64: 0\n") {(o: inout MessageTestType) in o.optionalUint64 = 0}
        assertDebugDescription("SwiftProtobufTests.SwiftProtoTesting_TestProto3Optional:\n") {(o: inout MessageTestType) in
          o.optionalUint64 = 0
          o.clearOptionalUint64()
        }

        let empty = MessageTestType()
        var a = empty
        a.optionalUint64 = 0
        XCTAssertNotEqual(a, empty)
        var b = empty
        b.optionalUint64 = 1
        XCTAssertNotEqual(a, b)
        b.clearOptionalUint64()
        XCTAssertNotEqual(a, b)
        b.optionalUint64 = 0
        XCTAssertEqual(a, b)

        // Ensure storage is uniqued for clear.
        let c = MessageTestType.with {
            $0.optionalUint64 = 1
        }
        var d = c
        XCTAssertEqual(c, d)
        XCTAssertTrue(c.hasOptionalUint64)
        XCTAssertTrue(d.hasOptionalUint64)
        d.clearOptionalUint64()
        XCTAssertNotEqual(c, d)
        XCTAssertTrue(c.hasOptionalUint64)
        XCTAssertFalse(d.hasOptionalUint64)
    }

    func testEncoding_optionalSint32() {
        assertEncode([40, 0]) {(o: inout MessageTestType) in o.optionalSint32 = 0}
        assertDecodeSucceeds([40, 0]) {$0.hasOptionalSint32 && $0.optionalSint32 == 0}
        assertDebugDescription("SwiftProtobufTests.SwiftProtoTesting_TestProto3Optional:\noptional_sint32: 0\n") {(o: inout MessageTestType) in o.optionalSint32 = 0}
        assertDebugDescription("SwiftProtobufTests.SwiftProtoTesting_TestProto3Optional:\n") {(o: inout MessageTestType) in
          o.optionalSint32 = 0
          o.clearOptionalSint32()
        }

        let empty = MessageTestType()
        var a = empty
        a.optionalSint32 = 0
        XCTAssertNotEqual(a, empty)
        var b = empty
        b.optionalSint32 = 1
        XCTAssertNotEqual(a, b)
        b.clearOptionalSint32()
        XCTAssertNotEqual(a, b)
        b.optionalSint32 = 0
        XCTAssertEqual(a, b)

        // Ensure storage is uniqued for clear.
        let c = MessageTestType.with {
            $0.optionalSint32 = 1
        }
        var d = c
        XCTAssertEqual(c, d)
        XCTAssertTrue(c.hasOptionalSint32)
        XCTAssertTrue(d.hasOptionalSint32)
        d.clearOptionalSint32()
        XCTAssertNotEqual(c, d)
        XCTAssertTrue(c.hasOptionalSint32)
        XCTAssertFalse(d.hasOptionalSint32)
    }

    func testEncoding_optionalSint64() {
        assertEncode([48, 0]) {(o: inout MessageTestType) in o.optionalSint64 = 0}
        assertDecodeSucceeds([48, 0]) {$0.hasOptionalSint64 && $0.optionalSint64 == 0}
        assertDebugDescription("SwiftProtobufTests.SwiftProtoTesting_TestProto3Optional:\noptional_sint64: 0\n") {(o: inout MessageTestType) in o.optionalSint64 = 0}
        assertDebugDescription("SwiftProtobufTests.SwiftProtoTesting_TestProto3Optional:\n") {(o: inout MessageTestType) in
          o.optionalSint64 = 0
          o.clearOptionalSint64()
        }

        let empty = MessageTestType()
        var a = empty
        a.optionalSint64 = 0
        XCTAssertNotEqual(a, empty)
        var b = empty
        b.optionalSint64 = 1
        XCTAssertNotEqual(a, b)
        b.clearOptionalSint64()
        XCTAssertNotEqual(a, b)
        b.optionalSint64 = 0
        XCTAssertEqual(a, b)

        // Ensure storage is uniqued for clear.
        let c = MessageTestType.with {
            $0.optionalSint64 = 1
        }
        var d = c
        XCTAssertEqual(c, d)
        XCTAssertTrue(c.hasOptionalSint64)
        XCTAssertTrue(d.hasOptionalSint64)
        d.clearOptionalSint64()
        XCTAssertNotEqual(c, d)
        XCTAssertTrue(c.hasOptionalSint64)
        XCTAssertFalse(d.hasOptionalSint64)
    }

    func testEncoding_optionalFixed32() {
        assertEncode([61, 0, 0, 0, 0]) {(o: inout MessageTestType) in o.optionalFixed32 = 0}
        assertDecodeSucceeds([61, 0, 0, 0, 0]) {$0.hasOptionalFixed32 && $0.optionalFixed32 == 0}
        assertDebugDescription("SwiftProtobufTests.SwiftProtoTesting_TestProto3Optional:\noptional_fixed32: 0\n") {(o: inout MessageTestType) in o.optionalFixed32 = 0}
        assertDebugDescription("SwiftProtobufTests.SwiftProtoTesting_TestProto3Optional:\n") {(o: inout MessageTestType) in
          o.optionalFixed32 = 0
          o.clearOptionalFixed32()
        }

        let empty = MessageTestType()
        var a = empty
        a.optionalFixed32 = 0
        XCTAssertNotEqual(a, empty)
        var b = empty
        b.optionalFixed32 = 1
        XCTAssertNotEqual(a, b)
        b.clearOptionalFixed32()
        XCTAssertNotEqual(a, b)
        b.optionalFixed32 = 0
        XCTAssertEqual(a, b)

        // Ensure storage is uniqued for clear.
        let c = MessageTestType.with {
            $0.optionalFixed32 = 1
        }
        var d = c
        XCTAssertEqual(c, d)
        XCTAssertTrue(c.hasOptionalFixed32)
        XCTAssertTrue(d.hasOptionalFixed32)
        d.clearOptionalFixed32()
        XCTAssertNotEqual(c, d)
        XCTAssertTrue(c.hasOptionalFixed32)
        XCTAssertFalse(d.hasOptionalFixed32)
    }

    func testEncoding_optionalFixed64() {
        assertEncode([65, 0, 0, 0, 0, 0, 0, 0, 0]) {(o: inout MessageTestType) in o.optionalFixed64 = UInt64.min}
        assertDecodeSucceeds([65, 0, 0, 0, 0, 0, 0, 0, 0]) {$0.hasOptionalFixed64 && $0.optionalFixed64 == 0}
        assertDebugDescription("SwiftProtobufTests.SwiftProtoTesting_TestProto3Optional:\noptional_fixed64: 0\n") {(o: inout MessageTestType) in o.optionalFixed64 = 0}
        assertDebugDescription("SwiftProtobufTests.SwiftProtoTesting_TestProto3Optional:\n") {(o: inout MessageTestType) in
          o.optionalFixed64 = 0
          o.clearOptionalFixed64()
        }

        let empty = MessageTestType()
        var a = empty
        a.optionalFixed64 = 0
        XCTAssertNotEqual(a, empty)
        var b = empty
        b.optionalFixed64 = 1
        XCTAssertNotEqual(a, b)
        b.clearOptionalFixed64()
        XCTAssertNotEqual(a, b)
        b.optionalFixed64 = 0
        XCTAssertEqual(a, b)

        // Ensure storage is uniqued for clear.
        let c = MessageTestType.with {
            $0.optionalFixed64 = 1
        }
        var d = c
        XCTAssertEqual(c, d)
        XCTAssertTrue(c.hasOptionalFixed64)
        XCTAssertTrue(d.hasOptionalFixed64)
        d.clearOptionalFixed64()
        XCTAssertNotEqual(c, d)
        XCTAssertTrue(c.hasOptionalFixed64)
        XCTAssertFalse(d.hasOptionalFixed64)
    }

    func testEncoding_optionalSfixed32() {
        assertEncode([77, 0, 0, 0, 0]) {(o: inout MessageTestType) in o.optionalSfixed32 = 0}
        assertDecodeSucceeds([77, 0, 0, 0, 0]) {$0.hasOptionalSfixed32 && $0.optionalSfixed32 == 0}
        assertDebugDescription("SwiftProtobufTests.SwiftProtoTesting_TestProto3Optional:\noptional_sfixed32: 0\n") {(o: inout MessageTestType) in o.optionalSfixed32 = 0}
        assertDebugDescription("SwiftProtobufTests.SwiftProtoTesting_TestProto3Optional:\n") {(o: inout MessageTestType) in
          o.optionalSfixed32 = 0
          o.clearOptionalSfixed32()
        }

        let empty = MessageTestType()
        var a = empty
        a.optionalSfixed32 = 0
        XCTAssertNotEqual(a, empty)
        var b = empty
        b.optionalSfixed32 = 1
        XCTAssertNotEqual(a, b)
        b.clearOptionalSfixed32()
        XCTAssertNotEqual(a, b)
        b.optionalSfixed32 = 0
        XCTAssertEqual(a, b)

        // Ensure storage is uniqued for clear.
        let c = MessageTestType.with {
            $0.optionalSfixed32 = 1
        }
        var d = c
        XCTAssertEqual(c, d)
        XCTAssertTrue(c.hasOptionalSfixed32)
        XCTAssertTrue(d.hasOptionalSfixed32)
        d.clearOptionalSfixed32()
        XCTAssertNotEqual(c, d)
        XCTAssertTrue(c.hasOptionalSfixed32)
        XCTAssertFalse(d.hasOptionalSfixed32)
    }

    func testEncoding_optionalSfixed64() {
        assertEncode([81, 0, 0, 0, 0, 0, 0, 0, 0]) {(o: inout MessageTestType) in o.optionalSfixed64 = 0}
        assertDecodeSucceeds([81, 0, 0, 0, 0, 0, 0, 0, 0]) {$0.hasOptionalSfixed64 && $0.optionalSfixed64 == 0}
        assertDebugDescription("SwiftProtobufTests.SwiftProtoTesting_TestProto3Optional:\noptional_sfixed64: 0\n") {(o: inout MessageTestType) in o.optionalSfixed64 = 0}
        assertDebugDescription("SwiftProtobufTests.SwiftProtoTesting_TestProto3Optional:\n") {(o: inout MessageTestType) in
          o.optionalSfixed64 = 0
          o.clearOptionalSfixed64()
        }

        let empty = MessageTestType()
        var a = empty
        a.optionalSfixed64 = 0
        XCTAssertNotEqual(a, empty)
        var b = empty
        b.optionalSfixed64 = 1
        XCTAssertNotEqual(a, b)
        b.clearOptionalSfixed64()
        XCTAssertNotEqual(a, b)
        b.optionalSfixed64 = 0
        XCTAssertEqual(a, b)

        // Ensure storage is uniqued for clear.
        let c = MessageTestType.with {
            $0.optionalSfixed64 = 1
        }
        var d = c
        XCTAssertEqual(c, d)
        XCTAssertTrue(c.hasOptionalSfixed64)
        XCTAssertTrue(d.hasOptionalSfixed64)
        d.clearOptionalSfixed64()
        XCTAssertNotEqual(c, d)
        XCTAssertTrue(c.hasOptionalSfixed64)
        XCTAssertFalse(d.hasOptionalSfixed64)
    }

    func testEncoding_optionalFloat() {
        assertEncode([93, 0, 0, 0, 0]) {(o: inout MessageTestType) in o.optionalFloat = 0.0}
        assertDecodeSucceeds([93, 0, 0, 0, 0]) {$0.hasOptionalFloat && $0.optionalFloat == 0}
        assertDebugDescription("SwiftProtobufTests.SwiftProtoTesting_TestProto3Optional:\noptional_float: 0.0\n") {
            (o: inout MessageTestType) in o.optionalFloat = 0.0}
        assertDebugDescription("SwiftProtobufTests.SwiftProtoTesting_TestProto3Optional:\n") { (o: inout MessageTestType) in
          o.optionalFloat = 1.0
          o.clearOptionalFloat()
        }

        let empty = MessageTestType()
        var a = empty
        a.optionalFloat = 0
        XCTAssertNotEqual(a, empty)
        var b = empty
        b.optionalFloat = 1
        XCTAssertNotEqual(a, b)
        b.clearOptionalFloat()
        XCTAssertNotEqual(a, b)
        b.optionalFloat = 0
        XCTAssertEqual(a, b)

        // Ensure storage is uniqued for clear.
        let c = MessageTestType.with {
            $0.optionalFloat = 1.0
        }
        var d = c
        XCTAssertEqual(c, d)
        XCTAssertTrue(c.hasOptionalFloat)
        XCTAssertTrue(d.hasOptionalFloat)
        d.clearOptionalFloat()
        XCTAssertNotEqual(c, d)
        XCTAssertTrue(c.hasOptionalFloat)
        XCTAssertFalse(d.hasOptionalFloat)
    }

    func testEncoding_optionalDouble() {
        assertEncode([97, 0, 0, 0, 0, 0, 0, 0, 0]) {(o: inout MessageTestType) in o.optionalDouble = 0.0}
        assertDecodeSucceeds([97, 0, 0, 0, 0, 0, 0, 0, 0]) {$0.hasOptionalDouble && $0.optionalDouble == 0.0}
        assertDebugDescription("SwiftProtobufTests.SwiftProtoTesting_TestProto3Optional:\noptional_double: 0.0\n") {
            (o: inout MessageTestType) in o.optionalDouble = 0.0}
        assertDebugDescription("SwiftProtobufTests.SwiftProtoTesting_TestProto3Optional:\n") {
            (o: inout MessageTestType) in
          o.optionalDouble = 0.0
          o.clearOptionalDouble()
        }

        let empty = MessageTestType()
        var a = empty
        a.optionalDouble = 0
        XCTAssertNotEqual(a, empty)
        var b = empty
        b.optionalDouble = 1
        XCTAssertNotEqual(a, b)
        b.clearOptionalDouble()
        XCTAssertNotEqual(a, b)
        b.optionalDouble = 0
        XCTAssertEqual(a, b)

        // Ensure storage is uniqued for clear.
        let c = MessageTestType.with {
            $0.optionalDouble = 1.0
        }
        var d = c
        XCTAssertEqual(c, d)
        XCTAssertTrue(c.hasOptionalDouble)
        XCTAssertTrue(d.hasOptionalDouble)
        d.clearOptionalDouble()
        XCTAssertNotEqual(c, d)
        XCTAssertTrue(c.hasOptionalDouble)
        XCTAssertFalse(d.hasOptionalDouble)
    }

    func testEncoding_optionalBool() {
        assertEncode([104, 0]) {(o: inout MessageTestType) in o.optionalBool = false}
        assertDecodeSucceeds([104, 0]) { $0.hasOptionalBool && $0.optionalBool == false }
        assertDebugDescription("SwiftProtobufTests.SwiftProtoTesting_TestProto3Optional:\noptional_bool: false\n") {(o: inout MessageTestType) in o.optionalBool = false}
        assertDebugDescription("SwiftProtobufTests.SwiftProtoTesting_TestProto3Optional:\n") {(o: inout MessageTestType) in
          o.optionalBool = false
          o.clearOptionalBool()
        }

        let empty = MessageTestType()
        var a = empty
        a.optionalBool = false
        XCTAssertNotEqual(a, empty)
        var b = empty
        b.optionalBool = true
        XCTAssertNotEqual(a, b)
        b.clearOptionalBool()
        XCTAssertNotEqual(a, b)
        b.optionalBool = false
        XCTAssertEqual(a, b)

        // Ensure storage is uniqued for clear.
        let c = MessageTestType.with {
            $0.optionalBool = true
        }
        var d = c
        XCTAssertEqual(c, d)
        XCTAssertTrue(c.hasOptionalBool)
        XCTAssertTrue(d.hasOptionalBool)
        d.clearOptionalBool()
        XCTAssertNotEqual(c, d)
        XCTAssertTrue(c.hasOptionalBool)
        XCTAssertFalse(d.hasOptionalBool)
    }

    func testEncoding_optionalString() {
        assertEncode([114, 0]) {(o: inout MessageTestType) in o.optionalString = ""}
        assertDecodeSucceeds([114, 0]) { $0.hasOptionalString && $0.optionalString == "" }
        assertDebugDescription("SwiftProtobufTests.SwiftProtoTesting_TestProto3Optional:\noptional_string: \"\"\n") {(o: inout MessageTestType) in o.optionalString = ""}
        assertDebugDescription("SwiftProtobufTests.SwiftProtoTesting_TestProto3Optional:\n") {(o: inout MessageTestType) in
          o.optionalString = ""
          o.clearOptionalString()
        }

        let empty = MessageTestType()
        var a = empty
        a.optionalString = ""
        XCTAssertNotEqual(a, empty)
        var b = empty
        b.optionalString = "a"
        XCTAssertNotEqual(a, b)
        b.clearOptionalString()
        XCTAssertNotEqual(a, b)
        b.optionalString = ""
        XCTAssertEqual(a, b)

        // Ensure storage is uniqued for clear.
        let c = MessageTestType.with {
            $0.optionalString = "blah"
        }
        var d = c
        XCTAssertEqual(c, d)
        XCTAssertTrue(c.hasOptionalString)
        XCTAssertTrue(d.hasOptionalString)
        d.clearOptionalString()
        XCTAssertNotEqual(c, d)
        XCTAssertTrue(c.hasOptionalString)
        XCTAssertFalse(d.hasOptionalString)
    }

    func testEncoding_optionalBytes() {
        assertEncode([122, 0]) {(o: inout MessageTestType) in o.optionalBytes = Data()}
        assertDecodeSucceeds([122, 0]) { $0.hasOptionalBytes && $0.optionalBytes == Data() }
        assertDebugDescription("SwiftProtobufTests.SwiftProtoTesting_TestProto3Optional:\noptional_bytes: \"\"\n") {(o: inout MessageTestType) in o.optionalBytes = Data()}
        assertDebugDescription("SwiftProtobufTests.SwiftProtoTesting_TestProto3Optional:\n") {(o: inout MessageTestType) in
          o.optionalBytes = Data()
          o.clearOptionalBytes()
        }

        let empty = MessageTestType()
        var a = empty
        a.optionalBytes = Data()
        XCTAssertNotEqual(a, empty)
        var b = empty
        b.optionalBytes = Data([1])
        XCTAssertNotEqual(a, b)
        b.clearOptionalBytes()
        XCTAssertNotEqual(a, b)
        b.optionalBytes = Data()
        XCTAssertEqual(a, b)

        // Ensure storage is uniqued for clear.
        let c = MessageTestType.with {
            $0.optionalBytes = Data([1])
        }
        var d = c
        XCTAssertEqual(c, d)
        XCTAssertTrue(c.hasOptionalBytes)
        XCTAssertTrue(d.hasOptionalBytes)
        d.clearOptionalBytes()
        XCTAssertNotEqual(c, d)
        XCTAssertTrue(c.hasOptionalBytes)
        XCTAssertFalse(d.hasOptionalBytes)
    }

  func testEncoding_optionalCord() {
      // The `ctype = CORD` option has no meaning in SwiftProtobuf,
      // but test is for completeness.
      assertEncode([130, 1, 0]) {(o: inout MessageTestType) in o.optionalCord = ""}
      assertDecodeSucceeds([130, 1, 0]) { $0.hasOptionalCord && $0.optionalCord == "" }
      assertDebugDescription("SwiftProtobufTests.SwiftProtoTesting_TestProto3Optional:\noptional_cord: \"\"\n") {(o: inout MessageTestType) in o.optionalCord = ""}
      assertDebugDescription("SwiftProtobufTests.SwiftProtoTesting_TestProto3Optional:\n") {(o: inout MessageTestType) in
        o.optionalCord = ""
        o.clearOptionalCord()
      }

      let empty = MessageTestType()
      var a = empty
      a.optionalCord = ""
      XCTAssertNotEqual(a, empty)
      var b = empty
      b.optionalCord = "a"
      XCTAssertNotEqual(a, b)
      b.clearOptionalCord()
      XCTAssertNotEqual(a, b)
      b.optionalCord = ""
      XCTAssertEqual(a, b)

      // Ensure storage is uniqued for clear.
      let c = MessageTestType.with {
          $0.optionalCord = "blah"
      }
      var d = c
      XCTAssertEqual(c, d)
      XCTAssertTrue(c.hasOptionalCord)
      XCTAssertTrue(d.hasOptionalCord)
      d.clearOptionalCord()
      XCTAssertNotEqual(c, d)
      XCTAssertTrue(c.hasOptionalCord)
      XCTAssertFalse(d.hasOptionalCord)
  }

    func testEncoding_optionalNestedMessage() {
        assertEncode([146, 1, 0]) {(o: inout MessageTestType) in
            o.optionalNestedMessage = MessageTestType.NestedMessage()
        }
        assertDecodeSucceeds([146, 1, 0]) {$0.hasOptionalNestedMessage && $0.optionalNestedMessage == MessageTestType.NestedMessage()}
        assertDebugDescription("SwiftProtobufTests.SwiftProtoTesting_TestProto3Optional:\noptional_nested_message {\n}\n") {(o: inout MessageTestType) in
            o.optionalNestedMessage = MessageTestType.NestedMessage()
        }
        assertDebugDescription("SwiftProtobufTests.SwiftProtoTesting_TestProto3Optional:\n") {(o: inout MessageTestType) in
            o.optionalNestedMessage = MessageTestType.NestedMessage()
            o.clearOptionalNestedMessage()
        }

        // Ensure storage is uniqued for clear.
        let c = MessageTestType.with {
            $0.optionalNestedMessage.bb = 1
        }
        var d = c
        XCTAssertEqual(c, d)
        XCTAssertTrue(c.hasOptionalNestedMessage)
        XCTAssertTrue(d.hasOptionalNestedMessage)
        d.clearOptionalNestedMessage()
        XCTAssertNotEqual(c, d)
        XCTAssertTrue(c.hasOptionalNestedMessage)
        XCTAssertFalse(d.hasOptionalNestedMessage)
    }

  func testEncoding_lazyNestedMessage() {
      // The `lazy = true` option has no meaning in SwiftProtobuf,
      // but test is for completeness.
      assertEncode([154, 1, 0]) {(o: inout MessageTestType) in
          o.lazyNestedMessage = MessageTestType.NestedMessage()
      }
      assertDecodeSucceeds([154, 1, 0]) {$0.hasLazyNestedMessage && $0.lazyNestedMessage == MessageTestType.NestedMessage()}
      assertDebugDescription("SwiftProtobufTests.SwiftProtoTesting_TestProto3Optional:\nlazy_nested_message {\n}\n") {(o: inout MessageTestType) in
          o.lazyNestedMessage = MessageTestType.NestedMessage()
      }
      assertDebugDescription("SwiftProtobufTests.SwiftProtoTesting_TestProto3Optional:\n") {(o: inout MessageTestType) in
          o.lazyNestedMessage = MessageTestType.NestedMessage()
          o.clearLazyNestedMessage()
      }

      // Ensure storage is uniqued for clear.
      let c = MessageTestType.with {
          $0.lazyNestedMessage.bb = 1
      }
      var d = c
      XCTAssertEqual(c, d)
      XCTAssertTrue(c.hasLazyNestedMessage)
      XCTAssertTrue(d.hasLazyNestedMessage)
      d.clearLazyNestedMessage()
      XCTAssertNotEqual(c, d)
      XCTAssertTrue(c.hasLazyNestedMessage)
      XCTAssertFalse(d.hasLazyNestedMessage)
  }

    func testEncoding_optionalNestedEnum() throws {
        assertEncode([168, 1, 0]) {(o: inout MessageTestType) in
            o.optionalNestedEnum = .unspecified
        }
        assertDecodeSucceeds([168, 1, 0]) {
            $0.hasOptionalNestedEnum && $0.optionalNestedEnum == .unspecified
        }
        assertDebugDescription("SwiftProtobufTests.SwiftProtoTesting_TestProto3Optional:\noptional_nested_enum: UNSPECIFIED\n") {(o: inout MessageTestType) in
            o.optionalNestedEnum = .unspecified
        }
        assertDebugDescription("SwiftProtobufTests.SwiftProtoTesting_TestProto3Optional:\n") {(o: inout MessageTestType) in
            o.optionalNestedEnum = .unspecified
            o.clearOptionalNestedEnum()
        }

        // Ensure storage is uniqued for clear.
        let c = MessageTestType.with {
            $0.optionalNestedEnum = .bar
        }
        var d = c
        XCTAssertEqual(c, d)
        XCTAssertTrue(c.hasOptionalNestedEnum)
        XCTAssertTrue(d.hasOptionalNestedEnum)
        d.clearOptionalNestedEnum()
        XCTAssertNotEqual(c, d)
        XCTAssertTrue(c.hasOptionalNestedEnum)
        XCTAssertFalse(d.hasOptionalNestedEnum)
    }

    //
    // Optionally doesn't apply to Repeated types
    //
}
