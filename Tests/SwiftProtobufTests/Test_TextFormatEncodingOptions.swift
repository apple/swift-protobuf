// Tests/SwiftProtobufTests/Test_TextFormatEncodingOptions.swift - Tests for text format encoding options
//
// Copyright (c) 2014 - 2026 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Test for the use of TextFormatEncodingOptions
///
// -----------------------------------------------------------------------------

import Foundation
import SwiftProtobuf
import XCTest

final class Test_TextFormatEncodingOptions: XCTestCase {

    func testDefaultOptionsUseDeterministicOrdering() {
        let options = TextFormatEncodingOptions()
        XCTAssertTrue(options.useDeterministicOrdering)

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
            stringMap.textFormatString(),
            "map_string_string {\n  key: \"0\"\n  value: \"0\"\n}\nmap_string_string {\n  key: \"UPPER\"\n  value: \"v\"\n}\nmap_string_string {\n  key: \"a\"\n  value: \"A\"\n}\nmap_string_string {\n  key: \"b\"\n  value: \"B\"\n}\nmap_string_string {\n  key: \"x\"\n  value: \"X\"\n}\n"
        )

        let messageMap = SwiftProtoTesting_Message3.with {
            $0.mapInt32Message = [
                5: .with { $0.optionalSint32 = 5 },
                1: .with { $0.optionalSint32 = 1 },
                3: .with { $0.optionalSint32 = 3 },
            ]
        }
        XCTAssertEqual(
            messageMap.textFormatString(),
            "map_int32_message {\n  key: 1\n  value {\n    optional_sint32: 1\n  }\n}\nmap_int32_message {\n  key: 3\n  value {\n    optional_sint32: 3\n  }\n}\nmap_int32_message {\n  key: 5\n  value {\n    optional_sint32: 5\n  }\n}\n"
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
            enumMap.textFormatString(),
            "map_int32_enum {\n  key: 0\n  value: BAZ\n}\nmap_int32_enum {\n  key: 1\n  value: EXTRA_3\n}\nmap_int32_enum {\n  key: 3\n  value: BAR\n}\nmap_int32_enum {\n  key: 5\n  value: FOO\n}\n"
        )
    }

    func testExplicitUseDeterministicOrdering() {
        var options = TextFormatEncodingOptions()
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
            stringMap.textFormatString(options: options),
            "map_string_string {\n  key: \"0\"\n  value: \"0\"\n}\nmap_string_string {\n  key: \"UPPER\"\n  value: \"v\"\n}\nmap_string_string {\n  key: \"a\"\n  value: \"A\"\n}\nmap_string_string {\n  key: \"b\"\n  value: \"B\"\n}\nmap_string_string {\n  key: \"x\"\n  value: \"X\"\n}\n"
        )
    }

    func testPrintUnknownFields() throws {
        var optionsWithUnknowns = TextFormatEncodingOptions()
        optionsWithUnknowns.printUnknownFields = true

        var optionsWithoutUnknowns = TextFormatEncodingOptions()
        optionsWithoutUnknowns.printUnknownFields = false

        let emptyMsg = SwiftProtoTesting_TestEmptyMessage()
        var unknownFields = UnknownStorage()
        unknownFields.append(protobufData: Data([0x08, 0x96, 0x01]))
        var msg = emptyMsg
        msg.unknownFields = unknownFields

        XCTAssertEqual(msg.textFormatString(options: optionsWithUnknowns), "1: 150\n")
        XCTAssertEqual(msg.textFormatString(options: optionsWithoutUnknowns), "")
    }
}
