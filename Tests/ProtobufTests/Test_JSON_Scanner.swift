// Test/Sources/TestSuite/Test_JSON_Scanner.swift - Exercise JSON scanner
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
// -----------------------------------------------------------------------------
///
/// The JSON low-level scanner parses a string and returns a sequence of JSON
/// tokens.
///
// -----------------------------------------------------------------------------

import XCTest
import Protobuf

class Test_Scanner: XCTestCase {

    func assertTokens(json: String, expected: Array<ProtobufJSONToken>, expectFail: Bool = false, file: XCTestFileArgType = #file, line: UInt = #line) {
        var scanner = ProtobufJSONScanner(json: json, tokens: [])
        assertTokens(scanner: &scanner, expected: expected.makeIterator(), expectFail: expectFail, file: file, line: line)
    }

    func assertTokens(scanner: inout ProtobufJSONScanner, expected: Array<ProtobufJSONToken>, expectFail: Bool = false, file: XCTestFileArgType = #file, line: UInt = #line) {
        assertTokens(scanner: &scanner, expected: expected.makeIterator(), expectFail: expectFail, file: file, line: line)
    }

    func assertTokens<G: IteratorProtocol>(scanner: inout ProtobufJSONScanner, expected: G, expectFail: Bool = false, file: XCTestFileArgType = #file, line: UInt = #line) where G.Element == ProtobufJSONToken {
        var _expected = expected
        var n = 0
        while let expectedToken = _expected.next() {
            do {
                if let actualToken = try scanner.next() {
                    XCTAssertEqual(expectedToken, actualToken, "At position \(n): Expected \(expectedToken) but saw \(actualToken)", file: file, line: line)
                } else {
                    XCTFail("At position \(n): Expected \(expectedToken) but stream ended", file: file, line: line)
                    return
                }
            } catch {
                XCTFail("At position \(n): Expected \(expectedToken) but saw error", file: file, line: line)
            }
            n += 1
        }
        do {
            if let actualToken = try scanner.next() {
                XCTFail("At position \(n): Expected stream to end, but got \(actualToken)", file: file, line: line)
            }
            if expectFail {
                XCTFail("At position \(n): Expected error, but got stream end", file: file, line: line)
            }
        } catch {
            if !expectFail {
                XCTFail("At position \(n): Expected stream to end, but got error", file: file, line: line)
            }
        }
    }

    // Test a long well-formed JSON sample to verify that we can scan every kind of token as expected.
    // This also includes a mix of varying whitespace and string escapes
    func testWellFormed() throws {
        var s = ProtobufJSONScanner(json: "{\"foo\": \"bar\",\"foo2\":\"\\\"bar2\",\"tr\\u0075e\": true, \"false\": false, \"string\": \"\\b\\t\\n\\f\\r\\\"\\\\\\/\", \"array\": [null, 123, -123, -0.34E+77,{\"a\":{}}], \"b\":\n   {\n   }\n  }", tokens: [])
        assertTokens(scanner: &s, expected: [
            .beginObject,
            .string("foo"),
            .colon,
            .string("bar"),
            .comma,
            .string("foo2"),
            .colon,
            .string("\"bar2"),
            .comma,
            .string("true"),
            .colon,
            .boolean(true),
            .comma,
            .string("false"),
            .colon,
            .boolean(false),
            .comma,
            .string("string"),
            .colon,
            .string("\u{0008}\u{0009}\u{000a}\u{000c}\u{000d}\"\\/"),
            .comma,
            .string("array"),
            .colon,
            .beginArray,
            .null,
            .comma,
            .number("123"),
            .comma,
            .number("-123"),
            .comma,
            .number("-0.34E+77"),
            .comma,
            .beginObject,
            .string("a"),
            .colon,
            .beginObject,
            .endObject,
            .endObject,
            .endArray,
            .comma,
            .string("b"),
            .colon,
            .beginObject,
            .endObject,
            .endObject
            ])
        XCTAssertNil(try s.next()) // End of tokens is a sticky state
    }

    func testString() {
        assertTokens(json: "{\"valid\":\"\\u0001\"}", expected: [.beginObject, .string("valid"), .colon, .string("\u{01}"), .endObject])
    }

    // Various malformed string literals
    func testBrokenString() {
        assertTokens(json: "\"abc", expected: [], expectFail: true)
        assertTokens(json: "{\"valid\":\"abc", expected: [.beginObject, .string("valid"), .colon], expectFail: true)
        assertTokens(json: "{\"valid\":\"abc}", expected: [.beginObject, .string("valid"), .colon], expectFail: true)
        assertTokens(json: "{\"valid\":\"abc\\", expected: [.beginObject, .string("valid"), .colon], expectFail: true)
        // Endquote is escaped
        assertTokens(json: "{\"valid\":\"\\\"}", expected: [.beginObject, .string("valid"), .colon], expectFail: true)
        // Invalid hex digit
        assertTokens(json: "{\"valid\":\"\\u000Xabc", expected: [.beginObject, .string("valid"), .colon], expectFail: true)
        // Truncated hex in unicode escape
        assertTokens(json: "{\"valid\":\"\\u000\"}", expected: [.beginObject, .string("valid"), .colon], expectFail: true)
        assertTokens(json: "{\"valid\":\"\\u00\"}", expected: [.beginObject, .string("valid"), .colon], expectFail: true)
        assertTokens(json: "{\"valid\":\"\\u0\"}", expected: [.beginObject, .string("valid"), .colon], expectFail: true)
        assertTokens(json: "{\"valid\":\"\\u\"}", expected: [.beginObject, .string("valid"), .colon], expectFail: true)
        // Invalid short escape
        assertTokens(json: "{\"valid\":\"\\a\"}", expected: [.beginObject, .string("valid"), .colon], expectFail: true)
    }

    func testSingleTokens() {
        assertTokens(json: "\"abc\"", expected: [.string("abc")])
        assertTokens(json: "7", expected: [.number("7")])
        assertTokens(json: "7.3", expected: [.number("7.3")])
        assertTokens(json: "true", expected: [.boolean(true)])
        assertTokens(json: "false", expected: [.boolean(false)])
        assertTokens(json: "null", expected: [.null])
        assertTokens(json: "{", expected: [.beginObject])
        assertTokens(json: "[", expected: [.beginArray])
        assertTokens(json: "}", expected: [.endObject])
        assertTokens(json: "]", expected: [.endArray])
        assertTokens(json: ":", expected: [.colon])
        assertTokens(json: ",", expected: [.comma])
    }

    func testInvalidTokens() {
        // Invalid JSON tokens should fail
        // TODO: Error behavior here is a little funky; should "nullll" fail before it returns the .null token?
        assertTokens(json: "nulll", expected: [.null], expectFail: true)
        assertTokens(json: "{nulll", expected: [.beginObject, .null], expectFail: true)
        assertTokens(json: "{nulll}", expected: [.beginObject, .null], expectFail: true)
        assertTokens(json: "truee", expected: [.boolean(true)], expectFail: true)
        assertTokens(json: "falsee", expected: [.boolean(false)], expectFail: true)
        assertTokens(json: "*", expected: [], expectFail: true)
        assertTokens(json: "&", expected: [], expectFail: true)
    }

    // TODO: Test error handling of numbers that are slightly malformed in various ways
}
