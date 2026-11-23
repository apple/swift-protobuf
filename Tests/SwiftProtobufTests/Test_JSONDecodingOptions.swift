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
                } catch JSONDecodingError.messageDepthLimit {
                    if expectSuccess {
                        XCTFail("Decode failed because of limit, but should *NOT* have, pass: \(i), limit: \(limit)")
                    } else {
                        // Nothing, this is what was expected.
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
            } catch JSONDecodingError.unknownField(let field) {
                XCTAssertEqual(field, "unknown", "Input \(i): got field \(field)")
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
            } catch JSONDecodingError.unknownField(let field) {
                XCTFail("Input \(i): should not have gotten unknown field \(field), input \(jsonInput)")
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

}
