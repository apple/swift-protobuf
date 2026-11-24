// Tests/SwiftProtobufTests/Test_JSONDecodingOptions.swift - Various JSON tests
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Test for the use of JSONDecodingOptions
///
// -----------------------------------------------------------------------------

import Foundation
import SwiftProtobuf
import XCTest

final class Test_JSONDecodingOptions: XCTestCase {

    func testMessageDepthLimit() {
        let jsonInputs: [String] = [
            // Proper field names.
            "{ \"a\": { \"a\": { \"i\": 1 } } }",
            // Wrong names, causes the skipping of values to be trigger, which also should
            // honor depth limits.
            "{ \"x\": { \"x\": { \"z\": 1 } } }",
            "{ \"x\": [ [ 1 ] ] }",
            "{ \"x\": [ { \"z\": 1 } ] }",
        ]

        let tests: [(Int, Bool)] = [
            // Limit, success/failure
            (10, true),
            (4, true),
            (3, true),
            (2, false),
            (1, false),
        ]

        for (i, jsonInput) in jsonInputs.enumerated() {
            for (limit, expectSuccess) in tests {
                do {
                    var options = JSONDecodingOptions()
                    options.messageDepthLimit = limit
                    options.ignoreUnknownFields = true
                    let _ = try SwiftProtoTesting_TestRecursiveMessage(jsonString: jsonInput, options: options)
                    if !expectSuccess {
                        XCTFail("Should not have succeed, pass: \(i), limit: \(limit)")
                    }
                } catch let error as SwiftProtobufError {
                    if expectSuccess {
                        XCTFail("Decode failed because of limit, but should *NOT* have, pass: \(i), limit: \(limit)")
                    } else {
                        // This is what was expected.
                        XCTAssertTrue(error.message.hasSuffix(": Message is too deep"))
                    }
                } catch let e {
                    XCTFail("Decode failed (pass: \(i), limit: \(limit) with unexpected error: \(e)")
                }
            }
        }
    }

    func testIgnoreUnknownFields() {
        // (isValidJSON, jsonInput)
        //   isValidJSON - if the input is otherwise valid protobuf JSON, and
        //                 hence should parse when ignoring unknown fields.
        //   jsonInput - The JSON string to parse.
        let jsonInputs: [(Bool, String)] = [
            // Try all the data types.
            (true, "{\"unknown\":7}"),
            (true, "{\"unknown\":null}"),
            (true, "{\"unknown\":false}"),
            (true, "{\"unknown\":true}"),
            (true, "{\"unknown\":  7.0}"),
            (true, "{\"unknown\": -3.04}"),
            (true, "{\"unknown\":  -7.0e-55}"),
            (true, "{\"unknown\":  7.308e+8}"),
            (true, "{\"unknown\":  18446744073709551616}"),
            (true, "{\"unknown\":  -18446744073709551616}"),
            (true, "{\"unknown\": \"hi!\"}"),
            (true, "{\"unknown\": []}"),
            (true, "{\"unknown\": [[]]}"),
            (true, "{\"unknown\": [[[]]]}"),
            (true, "{\"unknown\": [[],[[]],[[[]],[]],[],7]}"),
            (true, "{\"unknown\": [1,[2,[3,4],5],6]}"),
            (true, "{\"unknown\": [3, 4, 5]}"),
            (true, "{\"unknown\": [[3], [4], [5, [6, [7], 8, null, \"no\"]]]}"),
            (true, "{\"unknown\": [3, {}, \"5\"]}"),
            (true, "{\"unknown\": {}}"),
            (true, "{\"unknown\": {\"foo\": 1}}"),
            // multiple fields, fails on first.
            (true, "{\"unknown\": 7, \"also_unknown\": 8}"),
            (true, "{\"unknown\": 7, \"zz_unknown\": 8}"),
            // Malformed fields, fails on the field, without trying to parse the value.
            (false, "{\"unknown\":  1e999}"),
            (false, "{\"unknown\": -null}"),
            (false, "{\"unknown\": -true}"),
            (false, "{\"unknown\": -false}"),
            (false, "{\"unknown\": \"hi!\""),
            (false, "{\"unknown\": \"hi!}"),
            (false, "{\"unknown\": qqq }"),
            (false, "{\"unknown\": [ }"),
            (false, "{\"unknown\": { ]}"),
            (false, "{\"unknown\": ]}"),
            (false, "{\"unknown\": nulll }"),
            (false, "{\"unknown\": nul }"),
            (false, "{\"unknown\": Null }"),
            (false, "{\"unknown\": NULL }"),
            (false, "{\"unknown\": True }"),
            (false, "{\"unknown\": False }"),
            (false, "{\"unknown\": nan }"),
            (false, "{\"unknown\": NaN }"),
            (false, "{\"unknown\": Infinity }"),
            (false, "{\"unknown\": infinity }"),
            (false, "{\"unknown\": Inf }"),
            (false, "{\"unknown\": inf }"),
            (false, "{\"unknown\": {1, 2}}"),
            (false, "{\"unknown\": 1.2.3.4.5}"),
            (false, "{\"unknown\": -.04}"),
            (false, "{\"unknown\": -19.}"),
            (false, "{\"unknown\": -9.3e+}"),
            (false, "{\"unknown\": 1 2 3}"),
            (false, "{\"unknown\": { true false }}"),
            (false, "{\"unknown\": [,[2,[3,4],5],6]}"),
            (false, "{\"unknown\": [1,[2[3,4],5],6]}"),
            (false, "{\"unknown\": [1,[2,[3,4],5],]}"),
            (false, "{\"unknown\": [[[[[[[[[[[[[[[[[[[[[[]]]]]]]]]]]]]]]]]]]]]}"),
            (false, "{\"unknown\": [[[[[[[[[[[[[[[[[[[[[]]]]]]]]]]]]]]]]]]]]]]}"),
            (false, "{\"unknown\": [[[[[[[[[[[[[[[[[[[[[[,]]]]]]]]]]]]]]]]]]]]]]}"),
            // Generally malformed JSON still errors on the field name
            (false, "{\"unknown\": }"),
            (false, "{\"unknown\": null true}"),
            (false, "{\"unknown\": 1}}"),
            (false, "{\"unknown\": { }"),
        ]

        var options = JSONDecodingOptions()
        options.ignoreUnknownFields = true

        for (i, (isValidJSON, jsonInput)) in jsonInputs.enumerated() {
            // Default options (error on unknown fields)
            do {
                let _ = try SwiftProtoTesting_TestEmptyMessage(jsonString: jsonInput)
                XCTFail("Input \(i): Should not have gotten here! Input: \(jsonInput)")
            } catch let error as SwiftProtobufError {
                XCTAssertTrue(
                    error.message.hasSuffix(": Unknown field 'unknown' on 'swift_proto_testing.TestEmptyMessage'")
                )
            } catch let e {
                XCTFail("Input \(i): Error \(e) decoding into an empty message \(jsonInput)")
            }

            // Ignoring unknown fields
            do {
                let _ = try SwiftProtoTesting_TestEmptyMessage(
                    jsonString: jsonInput,
                    options: options
                )
                XCTAssertTrue(
                    isValidJSON,
                    "Input \(i): Should not have been able to parse: \(jsonInput)"
                )
            } catch let e {
                XCTAssertFalse(
                    isValidJSON,
                    "Input \(i): Error \(e): Should have been able to parse: \(jsonInput)"
                )
            }
        }
    }

    func testIgnoreUnknownFields_stringValidation() throws {
        var options = JSONDecodingOptions()
        options.ignoreUnknownFields = true

        // Valid skipped strings (unescaped, escaped, surrogate pairs, nested arrays/objects)
        let validInputs: [String] = [
            "{\"unknown\":\"\"}",
            "{\"unknown\":\"unescaped string exceeding inline small string capacity\"}",
            "{\"unknown\":\"\\\"\\\\\\/\\b\\f\\n\\r\\t\"}",
            "{\"unknown\":\"\\u0000\\u0041\\u00e9\\uffff\"}",
            "{\"unknown\":\"\\ud83d\\ude00\\uD834\\uDD1E\\udbff\\udfff\"}",
            "{\"unknown\":\"prefix café \\n \\u00e9 \\ud83d\\ude00 suffix\"}",
            "{\"unknown\":[\"ok\",\"\\t\\n\",\"\\ud83d\\ude00\",{\"k\\n\":\"v\\u0041\"}]}",
            "{\"unknown\":{\"nested\\tkey\":{\"deep\":[\"\\b\\f\\r\",\"𝄞\"]}}}",
        ]
        for json in validInputs {
            XCTAssertNoThrow(
                try SwiftProtoTesting_TestEmptyMessage(jsonString: json, options: options),
                "Expected valid skipped string to parse: \(json)"
            )
        }

        // Malformed escapes, broken surrogates, and unescaped C0 controls must fail
        // with malformedString even when ignoreUnknownFields is true.
        let invalidPayloads: [String] = [
            // Malformed escapes
            "\"bad\\qescape\"",
            "\"bad\\x41hex\"",
            "\"short\\u12\"",
            "\"nonhex\\u123g\"",
            "\"upper\\U0041\"",
            // Unpaired and misordered surrogates
            "\"\\ud800\"",
            "\"\\udc00\"",
            "\"\\ude00\\ud83d\"",
            "\"\\ud800\\u0041\"",
            "\"\\ud800\\ud800\"",
            "\"\\ud800\\u123\"",
            // Unescaped C0 control characters (including after backslash)
            "\"a\u{00}b\"",
            "\"a\u{01}b\"",
            "\"a\u{09}b\"",
            "\"a\u{0a}b\"",
            "\"a\u{1f}b\"",
            "\"a\\\u{01}b\"",
            "\"a\\\u{00}b\"",
            "\"a\\\\\u{01}b\"",
            // Nested arrays and objects (values and keys)
            "[\"ok\",\"bad\\q\"]",
            "[\"ok\",\"\\udc00\"]",
            "{\"nested\":\"bad\\u12\"}",
            "{\"nested\":\"a\\\u{01}b\"}",
            "{\"bad\\q\":1}",
            "{\"\\ud800\":1}",
            "{\"a\u{01}b\":1}",
            "{\"a\\\u{01}b\":1}",
        ]
        for payload in invalidPayloads {
            let json = "{\"unknown\":\(payload)}"
            XCTAssertThrowsError(
                try SwiftProtoTesting_TestEmptyMessage(jsonString: json, options: options),
                "Expected failure for \(json)"
            ) { error in
                guard case JSONDecodingError.malformedString = error else {
                    XCTFail("Expected JSONDecodingError.malformedString for \(json), got \(error)")
                    return
                }
            }
        }

        // Truncated input before opening quote of a nested object key stays `.truncated`,
        // while an unterminated skipped string throws `.malformedString`.
        XCTAssertThrowsError(
            try SwiftProtoTesting_TestEmptyMessage(jsonString: "{\"unknown\":{", options: options)
        ) { error in
            guard case JSONDecodingError.truncated = error else {
                XCTFail("Expected JSONDecodingError.truncated, got \(error)")
                return
            }
        }
        XCTAssertThrowsError(
            try SwiftProtoTesting_TestEmptyMessage(jsonString: "{\"unknown\":\"unterminated", options: options)
        ) { error in
            guard case JSONDecodingError.malformedString = error else {
                XCTFail("Expected JSONDecodingError.malformedString, got \(error)")
                return
            }
        }

        // Valid raw UTF-8 bytes succeed via jsonUTF8Bytes.
        let validUTF8Payloads: [[UInt8]] = [
            [0xC3, 0xA9],  // é
            [0xF0, 0x9F, 0x98, 0x80],  // 😀
        ]
        for payloadBytes in validUTF8Payloads {
            var bytes = Array("{\"unknown\":\"".utf8)
            bytes.append(contentsOf: payloadBytes)
            bytes.append(contentsOf: "\"}".utf8)
            XCTAssertNoThrow(
                try SwiftProtoTesting_TestEmptyMessage(jsonUTF8Bytes: bytes, options: options)
            )
        }

        // Invalid raw UTF-8 bytes are rejected even with ignoreUnknownFields = true.
        let invalidUTF8Sequences: [[UInt8]] = [
            [0xFF],
            [0xC3],
            [0xED, 0xA0, 0x80],
            [UInt8(ascii: "\\"), UInt8(ascii: "n"), 0xFF],
        ]
        let utf8Containers: [(prefix: String, suffix: String)] = [
            ("{\"unknown\":\"", "\"}"),
            ("{\"unknown\":[\"ok\",\"", "\"]}"),
            ("{\"unknown\":{\"nested\":\"", "\"}}"),
            ("{\"unknown\":{\"", "\":1}}"),
        ]
        for badBytes in invalidUTF8Sequences {
            for container in utf8Containers {
                var bytes = Array(container.prefix.utf8)
                bytes.append(contentsOf: badBytes)
                bytes.append(contentsOf: container.suffix.utf8)
                XCTAssertThrowsError(
                    try SwiftProtoTesting_TestEmptyMessage(jsonUTF8Bytes: bytes, options: options)
                ) { error in
                    guard case JSONDecodingError.malformedString = error else {
                        XCTFail("Expected JSONDecodingError.malformedString, got \(error)")
                        return
                    }
                }
            }
        }
    }

    func testIgnoreUnknownFields_enumStringUTF8Validation() throws {
        var ignoreOptions = JSONDecodingOptions()
        ignoreOptions.ignoreUnknownFields = true
        let strictOptions = JSONDecodingOptions()

        // Valid unknown UTF-8 enum strings are ignored when ignoreUnknownFields = true
        // and rejected with unrecognizedEnumValue when ignoreUnknownFields = false.
        let validUnknownEnumBytes: [[UInt8]] = [
            Array("UNKNOWN_ENUM_VALUE".utf8),
            Array("UNKNOWN_".utf8) + [0xC3, 0xA9],  // é
            Array("UNKNOWN_".utf8) + [0xF0, 0x9F, 0x98, 0x80],  // 😀
        ]
        for unknownName in validUnknownEnumBytes {
            // Singular enum field
            var singularBytes = Array("{\"optionalNestedEnum\":\"".utf8)
            singularBytes.append(contentsOf: unknownName)
            singularBytes.append(contentsOf: "\"}".utf8)
            let singularMsg = try SwiftProtoTesting_Test3_TestAllTypesProto3(
                jsonUTF8Bytes: singularBytes,
                options: ignoreOptions
            )
            XCTAssertEqual(singularMsg.optionalNestedEnum, .foo)
            XCTAssertThrowsError(
                try SwiftProtoTesting_Test3_TestAllTypesProto3(
                    jsonUTF8Bytes: singularBytes,
                    options: strictOptions
                )
            ) { error in
                guard case JSONDecodingError.unrecognizedEnumValue = error else {
                    XCTFail("Expected JSONDecodingError.unrecognizedEnumValue, got \(error)")
                    return
                }
            }

            // Repeated enum field
            var repeatedBytes = Array("{\"repeatedNestedEnum\":[\"BAR\",\"".utf8)
            repeatedBytes.append(contentsOf: unknownName)
            repeatedBytes.append(contentsOf: "\",\"BAZ\"]}".utf8)
            let repeatedMsg = try SwiftProtoTesting_Test3_TestAllTypesProto3(
                jsonUTF8Bytes: repeatedBytes,
                options: ignoreOptions
            )
            XCTAssertEqual(repeatedMsg.repeatedNestedEnum, [.bar, .baz])
            XCTAssertThrowsError(
                try SwiftProtoTesting_Test3_TestAllTypesProto3(
                    jsonUTF8Bytes: repeatedBytes,
                    options: strictOptions
                )
            ) { error in
                guard case JSONDecodingError.unrecognizedEnumValue = error else {
                    XCTFail("Expected JSONDecodingError.unrecognizedEnumValue, got \(error)")
                    return
                }
            }

            // Map enum value
            var mapBytes = Array("{\"mapStringNestedEnum\":{\"a\":\"BAR\",\"b\":\"".utf8)
            mapBytes.append(contentsOf: unknownName)
            mapBytes.append(contentsOf: "\"}}".utf8)
            let mapMsg = try SwiftProtoTesting_Test3_TestAllTypesProto3(
                jsonUTF8Bytes: mapBytes,
                options: ignoreOptions
            )
            XCTAssertEqual(mapMsg.mapStringNestedEnum, ["a": .bar])
            XCTAssertThrowsError(
                try SwiftProtoTesting_Test3_TestAllTypesProto3(
                    jsonUTF8Bytes: mapBytes,
                    options: strictOptions
                )
            ) { error in
                guard case JSONDecodingError.unrecognizedEnumValue = error else {
                    XCTFail("Expected JSONDecodingError.unrecognizedEnumValue, got \(error)")
                    return
                }
            }
        }

        // Invalid UTF-8 bytes in an unrecognized enum string must throw malformedString
        // on singular, repeated, and map enum fields regardless of ignoreUnknownFields.
        let invalidUTF8Sequences: [[UInt8]] = [
            [0xFF],
            [0xC3],
            [0xED, 0xA0, 0x80],
        ]
        let enumContainers: [(prefix: String, suffix: String)] = [
            ("{\"optionalNestedEnum\":\"", "\"}"),
            ("{\"repeatedNestedEnum\":[\"", "\"]}"),
            ("{\"repeatedNestedEnum\":[\"BAR\",\"", "\",\"BAZ\"]}"),
            ("{\"mapStringNestedEnum\":{\"a\":\"BAR\",\"b\":\"", "\"}}"),
        ]
        for badBytes in invalidUTF8Sequences {
            for container in enumContainers {
                var bytes = Array(container.prefix.utf8)
                bytes.append(contentsOf: badBytes)
                bytes.append(contentsOf: container.suffix.utf8)
                for options in [ignoreOptions, strictOptions] {
                    XCTAssertThrowsError(
                        try SwiftProtoTesting_Test3_TestAllTypesProto3(
                            jsonUTF8Bytes: bytes,
                            options: options
                        )
                    ) { error in
                        guard case JSONDecodingError.malformedString = error else {
                            XCTFail("Expected JSONDecodingError.malformedString, got \(error)")
                            return
                        }
                    }
                }
            }
        }

        // Recognized enum values (both fast-path unescaped and escaped) continue to decode cleanly.
        let knownMsg = try SwiftProtoTesting_Test3_TestAllTypesProto3(
            jsonString:
                "{\"optionalNestedEnum\":\"BAR\",\"repeatedNestedEnum\":[\"BA\\u0052\",\"BAZ\"],\"mapStringNestedEnum\":{\"k\":\"BAR\"}}",
            options: ignoreOptions
        )
        XCTAssertEqual(knownMsg.optionalNestedEnum, .bar)
        XCTAssertEqual(knownMsg.repeatedNestedEnum, [.bar, .baz])
        XCTAssertEqual(knownMsg.mapStringNestedEnum, ["k": .bar])
    }

}
