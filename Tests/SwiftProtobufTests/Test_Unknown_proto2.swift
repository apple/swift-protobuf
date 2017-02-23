// Tests/SwiftProtobufTests/Test_Unknown_proto2.swift - Exercise unknown field handling for proto2 messages
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Proto2 messages preserve unknown fields when decoding and recoding binary
/// messages, but drop unknown fields when decoding and recoding JSON format.
///
// -----------------------------------------------------------------------------

import Foundation
import XCTest
import SwiftProtobuf

/*
 * Verify that unknown fields are correctly preserved by
 * proto2 messages.
 */

class Test_Unknown_proto2: XCTestCase, PBTestHelpers {
    typealias MessageTestType = ProtobufUnittest_TestEmptyMessage

    /// Verify that json decode ignores the provided fields but otherwise succeeds
    func assertJSONIgnores(_ json: String, file: XCTestFileArgType = #file, line: UInt = #line) {
        do {
            let empty = try ProtobufUnittest_TestEmptyMessage(jsonString: json)
            do {
                let json = try empty.jsonString()
                XCTAssertEqual("{}", json, file: file, line: line)
            } catch {
                XCTFail("Recoding empty message threw an error", file: file, line: line)
            }
        } catch {
            XCTFail("empty message threw an error", file: file, line: line)
        }
    }

    // Binary PB coding preserves unknown fields for proto2
    // (but not proto3; see Test_Unknown_proto3)
    func testBinaryPB() {
        func assertRecodes(_ protobufBytes: [UInt8], file: XCTestFileArgType = #file, line: UInt = #line) {
            do {
                let empty = try ProtobufUnittest_TestEmptyMessage(serializedData: Data(bytes: protobufBytes))
                do {
                    let pb = try empty.serializedData()
                    XCTAssertEqual(Data(bytes: protobufBytes), pb, file: file, line: line)
                } catch {
                    XCTFail()
                }
            } catch {
                XCTFail(file: file, line: line)
            }
        }
        func assertFails(_ protobufBytes: [UInt8], file: XCTestFileArgType = #file, line: UInt = #line) {
            XCTAssertThrowsError(try ProtobufUnittest_TestEmptyMessage(serializedData: Data(bytes: protobufBytes)), file: file, line: line)
        }
        // Well-formed input should decode/recode as-is; malformed input should fail to decode
        assertFails([0]) // Invalid field number
        assertFails([0, 0])
        assertFails([1]) // Invalid field number
        assertFails([2]) // Invalid field number
        assertFails([3]) // Invalid field number
        assertFails([4]) // Invalid field number
        assertFails([5]) // Invalid field number
        assertFails([6]) // Invalid field number
        assertFails([7]) // Invalid field number
        assertFails([8]) // Varint field #1 but no varint body
        assertRecodes([8, 0])
        assertFails([8, 128]) // Truncated varint
        assertRecodes([9, 0, 0, 0, 0, 0, 0, 0, 0])
        assertFails([9, 0, 0, 0, 0, 0, 0, 0]) // Truncated 64-bit field
        assertFails([9, 0, 0, 0, 0, 0, 0])
        assertFails([9, 0, 0, 0, 0, 0])
        assertFails([9, 0, 0, 0, 0])
        assertFails([9, 0, 0, 0])
        assertFails([9, 0, 0])
        assertFails([9, 0])
        assertFails([9])
        assertFails([10]) // Length-delimited field but no length
        assertRecodes([10, 0]) // Valid 0-length field
        assertFails([10, 1]) // Length 1 but truncated
        assertRecodes([10, 1, 2]) // Length 1 with 1 byte
        assertFails([10, 2, 1]) // Length 2 truncated
        assertFails([11]) // Start group #1 but no end group
        assertRecodes([11, 12]) // Start/end group #1
        assertFails([12]) // Bare end group
        assertRecodes([13, 0, 0, 0, 0])
        assertFails([13, 0, 0, 0])
        assertFails([13, 0, 0])
        assertFails([13, 0])
        assertFails([13])
        assertFails([14])
        assertFails([15])
        assertRecodes([248, 255, 255, 255, 15, 0]) // Maximum field number
        assertFails([128, 128, 128, 128, 16, 0]) // Out-of-range field number
        assertFails([248, 255, 255, 255, 127, 0]) // Out-of-range field number
    }

    // JSON coding drops unknown fields for both proto2 and proto3
    func testJSON() {
        // Unknown fields should be ignored
        assertJSONIgnores("{\"unknown\":7}")
        assertJSONIgnores("{\"unknown\":null}")
        assertJSONIgnores("{\"unknown\":false}")
        assertJSONIgnores("{\"unknown\":true}")
        assertJSONIgnores("{\"unknown\":  7.0}")
        assertJSONIgnores("{\"unknown\": \"hi!\"}")
        assertJSONIgnores("{\"unknown\": []}")
        assertJSONIgnores("{\"unknown\": [3, 4, 5]}")
        assertJSONIgnores("{\"unknown\": [[3], [4], [5, [6, [7], 8, null, \"no\"]]]}")
        assertJSONIgnores("{\"unknown\": [3, {}, \"5\"]}")
        assertJSONIgnores("{\"unknown\": {}}")
        assertJSONIgnores("{\"unknown\": {\"foo\": 1}}")
        assertJSONIgnores("{\"unknown\": 7, \"also_unknown\": 8}")
        assertJSONIgnores("{\"unknown\": 7, \"unknown\": 8}")

        // Badly formed JSON should still fail the decode
        assertJSONDecodeFails("{\"unknown\": \"hi!\"")
        assertJSONDecodeFails("{\"unknown\": \"hi!}")
        assertJSONDecodeFails("{\"unknown\": qqq }")
        assertJSONDecodeFails("{\"unknown\": { }")
    }


    func assertUnknownFields(_ message: Proto2Message, _ bytes: [UInt8], line: UInt = #line) {
        var collector = UnknownCollector()
        do {
            try message.unknownFields.traverse(visitor: &collector)
        } catch let e {
            XCTFail("Throw why walking unknowns: \(e)", line: line)
        }
        XCTAssertEqual(collector.collected, [Data(bytes: bytes)], line: line)
    }

    func test_MessageNoStorageClass() throws {
        // Reusing message class from unittest_swift_extension.proto that were crafted
        // for forcing/avoiding _StorageClass usage.
        var msg1 = ProtobufUnittest_Extend_MsgNoStorage()
        assertUnknownFields(msg1, [])

        try msg1.merge(serializedData: Data(bytes: [24, 1]))  // Field 3, varint
        assertUnknownFields(msg1, [24, 1])

        var msg2 = msg1
        assertUnknownFields(msg2, [24, 1])
        assertUnknownFields(msg1, [24, 1])

        try msg2.merge(serializedData: Data([34, 1, 52]))   // Field 4, length delimted
        assertUnknownFields(msg2, [24, 1, 34, 1, 52])
        assertUnknownFields(msg1, [24, 1])

        try msg1.merge(serializedData: Data([61, 7, 0, 0, 0]))  // Field 7, 32-bit value
        assertUnknownFields(msg2, [24, 1, 34, 1, 52])
        assertUnknownFields(msg1, [24, 1, 61, 7, 0, 0, 0])
    }

    func test_MessageUsingStorageClass() throws {
        // Reusing message class from unittest_swift_extension.proto that were crafted
        // for forcing/avoiding _StorageClass usage.
        var msg1 = ProtobufUnittest_Extend_MsgUsesStorage()
        assertUnknownFields(msg1, [])

        try msg1.merge(serializedData: Data(bytes: [24, 1]))  // Field 3, varint
        assertUnknownFields(msg1, [24, 1])

        var msg2 = msg1
        assertUnknownFields(msg2, [24, 1])
        assertUnknownFields(msg1, [24, 1])

        try msg2.merge(serializedData: Data([34, 1, 52]))   // Field 4, length delimted
        assertUnknownFields(msg2, [24, 1, 34, 1, 52])
        assertUnknownFields(msg1, [24, 1])

        try msg1.merge(serializedData: Data([61, 7, 0, 0, 0]))  // Field 7, 32-bit value
        assertUnknownFields(msg2, [24, 1, 34, 1, 52])
        assertUnknownFields(msg1, [24, 1, 61, 7, 0, 0, 0])
    }
}

// Helper visitor class that ignores everything, but collects the
// things passed to visitUnknown.
struct UnknownCollector: Visitor {
    var collected: [Data] = []

    mutating func visitUnknown(bytes: Data) {
        collected.append(bytes)
    }

    mutating func visitSingularDoubleField(value: Double, fieldNumber: Int) throws {}

    mutating func visitSingularInt64Field(value: Int64, fieldNumber: Int) throws {}

    mutating func visitSingularUInt64Field(value: UInt64, fieldNumber: Int) throws {}

    mutating func visitSingularBoolField(value: Bool, fieldNumber: Int) throws {}

    mutating func visitSingularStringField(value: String, fieldNumber: Int) throws {}

    mutating func visitSingularBytesField(value: Data, fieldNumber: Int) throws {}

    mutating func visitSingularEnumField<E: Enum>(value: E, fieldNumber: Int) throws {}

    mutating func visitSingularMessageField<M: Message>(value: M, fieldNumber: Int) throws {}

    mutating func visitMapField<KeyType: MapKeyType, ValueType: MapValueType>(
      fieldType: ProtobufMap<KeyType, ValueType>.Type,
      value: ProtobufMap<KeyType, ValueType>.BaseType,
      fieldNumber: Int) throws where KeyType.BaseType: Hashable {}

    mutating func visitMapField<KeyType: MapKeyType, ValueType: Enum>(
      fieldType: ProtobufEnumMap<KeyType, ValueType>.Type,
      value: ProtobufEnumMap<KeyType, ValueType>.BaseType,
      fieldNumber: Int) throws where KeyType.BaseType: Hashable, ValueType.RawValue == Int {}

    mutating func visitMapField<KeyType: MapKeyType, ValueType: Message>(
      fieldType: ProtobufMessageMap<KeyType, ValueType>.Type,
      value: ProtobufMessageMap<KeyType, ValueType>.BaseType,
      fieldNumber: Int) throws where KeyType.BaseType: Hashable {}

    mutating func visitExtensionFields(fields: ExtensionFieldValueSet, start: Int, end: Int) throws {}
}
