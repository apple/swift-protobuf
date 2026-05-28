// Tests/SwiftProtobufTests/Test_Tokenizer.swift - Test well-known wrapper types
//
// Copyright (c) 2014 - 2026 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------

import Foundation
import SwiftProtobuf
import Testing

func withTokenizer(
    for input: String,
    mode: Tokenizer.Mode = .textFormat,
    errorCode: SwiftProtobufError.Code = .textFormatDecodingError,
    _ body: (inout Tokenizer) throws -> Void
) throws {
    let bytes = Array(input.utf8)
    try bytes.withUnsafeBufferPointer { buffer in
        var tokenizer = Tokenizer(buffer: buffer, mode: mode, errorCode: errorCode)
        try body(&tokenizer)
    }
}

func expectNext(_ tokenizer: inout Tokenizer, sourceLocation: SourceLocation = #_sourceLocation) throws {
    let hasNext = try tokenizer.next()
    #expect(hasNext, sourceLocation: sourceLocation)
}

func expectNoNext(_ tokenizer: inout Tokenizer, sourceLocation: SourceLocation = #_sourceLocation) throws {
    let hasNext = try tokenizer.next()
    #expect(!hasNext, sourceLocation: sourceLocation)
}

func expectThrowsError<T>(
    _ expression: @autoclosure () throws -> T,
    matching expectedMessage: String,
    sourceLocation: SourceLocation = #_sourceLocation
) {
    do {
        _ = try expression()
        Issue.record("Expected error to be thrown", sourceLocation: sourceLocation)
    } catch let error as SwiftProtobufError {
        #expect(error.message == expectedMessage, sourceLocation: sourceLocation)
    } catch {
        Issue.record("Expected SwiftProtobufError but caught: \(error)", sourceLocation: sourceLocation)
    }
}

@Suite struct NewTokenizerTests {

    struct SimpleTokenCase {
        var input: String
        var kind: Token.Kind
        var mode: Tokenizer.Mode = .textFormat
    }

    @Test(arguments: [
        SimpleTokenCase(input: "hello", kind: .identifier),
        // Integers
        SimpleTokenCase(input: "123", kind: .integer),
        SimpleTokenCase(input: "0xab6", kind: .integer),
        SimpleTokenCase(input: "0XAB6", kind: .integer),
        SimpleTokenCase(input: "0X1234567", kind: .integer),
        SimpleTokenCase(input: "0x89abcdef", kind: .integer),
        SimpleTokenCase(input: "0x89ABCDEF", kind: .integer),
        SimpleTokenCase(input: "01234567", kind: .integer),
        // Floats
        SimpleTokenCase(input: "123.45", kind: .float),
        SimpleTokenCase(input: "1.", kind: .float),
        SimpleTokenCase(input: "1e3", kind: .float),
        SimpleTokenCase(input: "1E3", kind: .float),
        SimpleTokenCase(input: "1e-3", kind: .float),
        SimpleTokenCase(input: "1e+3", kind: .float),
        SimpleTokenCase(input: "1.e3", kind: .float),
        SimpleTokenCase(input: "1.2e3", kind: .float),
        SimpleTokenCase(input: ".1", kind: .float),
        SimpleTokenCase(input: ".1e3", kind: .float),
        SimpleTokenCase(input: ".1e-3", kind: .float),
        SimpleTokenCase(input: ".1e+3", kind: .float),
        // Strings
        SimpleTokenCase(input: "'hello'", kind: .string),
        SimpleTokenCase(input: "\"foo\"", kind: .string),
        SimpleTokenCase(input: "'a\"b'", kind: .string),
        SimpleTokenCase(input: "\"a'b\"", kind: .string),
        SimpleTokenCase(input: "'a\\'b'", kind: .stringWithEscapes),
        SimpleTokenCase(input: "\"a\\\"b\"", kind: .stringWithEscapes),
        SimpleTokenCase(input: "'\\xf'", kind: .stringWithEscapes),
        SimpleTokenCase(input: "'\\0'", kind: .stringWithEscapes),
        // Symbols
        SimpleTokenCase(input: "+", kind: .symbol(UInt8(ascii: "+"))),
        SimpleTokenCase(input: ".", kind: .symbol(UInt8(ascii: "."))),
        SimpleTokenCase(input: "{", kind: .leftBrace),
        SimpleTokenCase(input: "}", kind: .rightBrace),
        SimpleTokenCase(input: "[", kind: .leftBracket),
        SimpleTokenCase(input: "]", kind: .rightBracket),
        SimpleTokenCase(input: "<", kind: .leftAngle),
        SimpleTokenCase(input: ">", kind: .rightAngle),
        SimpleTokenCase(input: ":", kind: .colon),
        SimpleTokenCase(input: ",", kind: .comma),
        SimpleTokenCase(input: ";", kind: .semicolon),
        SimpleTokenCase(input: "-", kind: .minus),
    ])
    func simpleTokens(testCase: SimpleTokenCase) throws {
        try withTokenizer(for: testCase.input, mode: testCase.mode) { tokenizer in
            #expect(tokenizer.current.kind == .start)
            try expectNext(&tokenizer)
            #expect(tokenizer.current.kind == testCase.kind)
            #expect(tokenizer.current.exactString == testCase.input)
            #expect(tokenizer.current.line == 0)
            #expect(tokenizer.current.column == 0)
            #expect(tokenizer.current.endColumn == testCase.input.utf8.count)

            try expectNoNext(&tokenizer)
            #expect(tokenizer.current.kind == .end)
        }
    }

    struct MultiTokenCase {
        var input: String
        var expected: [TokenData]
        var mode: Tokenizer.Mode = .textFormat
    }

    struct TokenData {
        var kind: Token.Kind
        var text: String
        var line: Int
        var column: Int
        var endColumn: Int
    }

    @Test(arguments: [
        MultiTokenCase(
            input: "",
            expected: [
                TokenData(kind: .end, text: "", line: 0, column: 0, endColumn: 0)
            ]
        ),
        MultiTokenCase(
            input: "foo 1 1.2 + 'bar'",
            expected: [
                TokenData(kind: .identifier, text: "foo", line: 0, column: 0, endColumn: 3),
                TokenData(kind: .integer, text: "1", line: 0, column: 4, endColumn: 5),
                TokenData(kind: .float, text: "1.2", line: 0, column: 6, endColumn: 9),
                TokenData(kind: .symbol(UInt8(ascii: "+")), text: "+", line: 0, column: 10, endColumn: 11),
                TokenData(kind: .string, text: "'bar'", line: 0, column: 12, endColumn: 17),
                TokenData(kind: .end, text: "", line: 0, column: 17, endColumn: 17),
            ]
        ),
        MultiTokenCase(
            input: "!@+%",
            expected: [
                TokenData(kind: .symbol(UInt8(ascii: "!")), text: "!", line: 0, column: 0, endColumn: 1),
                TokenData(kind: .symbol(UInt8(ascii: "@")), text: "@", line: 0, column: 1, endColumn: 2),
                TokenData(kind: .symbol(UInt8(ascii: "+")), text: "+", line: 0, column: 2, endColumn: 3),
                TokenData(kind: .symbol(UInt8(ascii: "%")), text: "%", line: 0, column: 3, endColumn: 4),
                TokenData(kind: .end, text: "", line: 0, column: 4, endColumn: 4),
            ]
        ),
        MultiTokenCase(
            input: "foo bar\nrab oof",
            expected: [
                TokenData(kind: .identifier, text: "foo", line: 0, column: 0, endColumn: 3),
                TokenData(kind: .identifier, text: "bar", line: 0, column: 4, endColumn: 7),
                TokenData(kind: .identifier, text: "rab", line: 1, column: 0, endColumn: 3),
                TokenData(kind: .identifier, text: "oof", line: 1, column: 4, endColumn: 7),
                TokenData(kind: .end, text: "", line: 1, column: 7, endColumn: 7),
            ]
        ),
        MultiTokenCase(
            input: "foo\tbar  \tbaz",
            expected: [
                TokenData(kind: .identifier, text: "foo", line: 0, column: 0, endColumn: 3),
                TokenData(kind: .identifier, text: "bar", line: 0, column: 8, endColumn: 11),
                TokenData(kind: .identifier, text: "baz", line: 0, column: 16, endColumn: 19),
                TokenData(kind: .end, text: "", line: 0, column: 19, endColumn: 19),
            ]
        ),
        MultiTokenCase(
            input: "\"foo\tbar\" baz",
            expected: [
                TokenData(kind: .string, text: "\"foo\tbar\"", line: 0, column: 0, endColumn: 12),
                TokenData(kind: .identifier, text: "baz", line: 0, column: 13, endColumn: 16),
                TokenData(kind: .end, text: "", line: 0, column: 16, endColumn: 16),
            ]
        ),
        MultiTokenCase(
            input: "foo # comment\nbar",
            expected: [
                TokenData(kind: .identifier, text: "foo", line: 0, column: 0, endColumn: 3),
                TokenData(kind: .identifier, text: "bar", line: 1, column: 0, endColumn: 3),
                TokenData(kind: .end, text: "", line: 1, column: 3, endColumn: 3),
            ]
        ),
        MultiTokenCase(
            input: "foo\n\t\r\u{B}\u{C}bar",
            expected: [
                TokenData(kind: .identifier, text: "foo", line: 0, column: 0, endColumn: 3),
                TokenData(kind: .identifier, text: "bar", line: 1, column: 11, endColumn: 14),
                TokenData(kind: .end, text: "", line: 1, column: 14, endColumn: 14),
            ]
        ),
    ])
    func multipleTokens(testCase: MultiTokenCase) throws {
        try withTokenizer(for: testCase.input, mode: testCase.mode) { tokenizer in
            for expected in testCase.expected {
                if expected.kind != .end {
                    try expectNext(&tokenizer)
                } else {
                    try expectNoNext(&tokenizer)
                }
                #expect(tokenizer.current.kind == expected.kind)
                #expect(tokenizer.current.exactString == expected.text)
                #expect(tokenizer.current.line == expected.line)
                #expect(tokenizer.current.column == expected.column)
                #expect(tokenizer.current.endColumn == expected.endColumn)
            }
        }
    }

    struct ErrorCase {
        var input: String
        var expectedError: String
        var mode: Tokenizer.Mode = .textFormat
    }

    @Test(arguments: [
        ErrorCase(input: "'\\l' foo", expectedError: "1:3: Invalid escape sequence in string literal"),
        ErrorCase(input: "'\\X' foo", expectedError: "1:4: Expected hex digits for escape sequence"),
        ErrorCase(input: "'\\x' foo", expectedError: "1:4: Expected hex digits for escape sequence"),
        ErrorCase(input: "'foo", expectedError: "1:5: Unexpected end of string"),
        ErrorCase(input: "'\\", expectedError: "1:3: Invalid escape sequence in string literal"),
        ErrorCase(input: "'bar\nfoo", expectedError: "1:5: Unexpected newline in string"),
        ErrorCase(input: "'\\u01' foo", expectedError: "1:6: Expected four hex digits for '\\u' escape sequence"),
        ErrorCase(input: "'\\uXYZ' foo", expectedError: "1:4: Expected four hex digits for '\\u' escape sequence"),
        ErrorCase(input: "123foo", expectedError: "1:5: Need space between number and identifier"),
        ErrorCase(input: "0x foo", expectedError: "1:3: \"0x\" must be followed by hex digits"),
        ErrorCase(input: "0541823 foo", expectedError: "1:5: Numbers starting with leading zero must be in octal"),
        ErrorCase(input: "0x123z foo", expectedError: "1:6: Need space between number and identifier"),
        ErrorCase(input: "0x123.4 foo", expectedError: "1:6: Hex and octal numbers must be integers"),
        ErrorCase(input: "0123.4 foo", expectedError: "1:5: Hex and octal numbers must be integers"),
        ErrorCase(input: "1e foo", expectedError: "1:3: \"e\" must be followed by exponent"),
        ErrorCase(input: "1e- foo", expectedError: "1:4: \"e\" must be followed by exponent"),
        ErrorCase(
            input: "1.2.3 foo",
            expectedError: "1:4: Already saw decimal point or exponent; can't have another one"
        ),
        ErrorCase(
            input: "1e2.3 foo",
            expectedError: "1:4: Already saw decimal point or exponent; can't have another one"
        ),
        ErrorCase(
            input: "a.1 foo",
            expectedError: "1:2: A space is required between an identifier and a decimal point"
        ),
        ErrorCase(input: "1.0f foo", expectedError: "1:4: Need space between number and identifier", mode: .json),
        ErrorCase(input: "\u{8} foo", expectedError: "1:1: Invalid control characters encountered in text"),
        ErrorCase(input: "\u{C0}foo", expectedError: "1:1: Non-UTF-8 code unit 195"),
    ])
    func errorReporting(testCase: ErrorCase) throws {
        expectThrowsError(
            try withTokenizer(for: testCase.input, mode: testCase.mode) { tokenizer in
                while try tokenizer.next() {}
            },
            matching: testCase.expectedError
        )
    }

    func parseInteger(_ input: String, upperBound: UInt64 = .max) throws -> UInt64 {
        var result: UInt64 = 0
        try withTokenizer(for: input) { tokenizer in
            try expectNext(&tokenizer)
            result = try tokenizer.current.integerValue(upperBound: upperBound, errorCode: .textFormatDecodingError)
        }
        return result
    }

    func parseFloat(_ input: String) throws -> Double {
        var result: Double = 0
        try withTokenizer(for: input) { tokenizer in
            try expectNext(&tokenizer)
            result = try tokenizer.current.floatValue(errorCode: .textFormatDecodingError)
        }
        return result
    }

    func parseString(_ input: String, allowSurrogates: Bool = true) throws -> String {
        var result: String = ""
        try withTokenizer(for: input) { tokenizer in
            try expectNext(&tokenizer)
            result = try tokenizer.current.stringValue(
                allowSurrogates: allowSurrogates,
                errorCode: .textFormatDecodingError
            )
        }
        return result
    }

    func parseBytes(_ input: String, allowSurrogates: Bool = true) throws -> Data {
        var result = Data()
        try withTokenizer(for: input) { tokenizer in
            try expectNext(&tokenizer)
            result = try tokenizer.current.bytesValue(
                allowSurrogates: allowSurrogates,
                errorCode: .textFormatDecodingError
            )
        }
        return result
    }

    struct IntegerTestCase {
        var input: String
        var upperBound: UInt64 = .max
        var expected: UInt64?
    }

    @Test(arguments: [
        // Basic
        IntegerTestCase(input: "0", expected: 0),
        IntegerTestCase(input: "123", expected: 123),
        IntegerTestCase(input: "0xabcdef12", expected: 0xabcd_ef12),
        IntegerTestCase(input: "01234567", expected: 0o1234567),
        IntegerTestCase(input: "0xFFFFFFFFFFFFFFFF", expected: UInt64.max),
        // Boundary
        IntegerTestCase(input: "9223372036854775807", upperBound: UInt64(Int64.max), expected: UInt64(Int64.max)),
        IntegerTestCase(input: "9223372036854775808", upperBound: UInt64(Int64.max), expected: nil),
        IntegerTestCase(input: "18446744073709551615", expected: UInt64.max),
        IntegerTestCase(input: "18446744073709551616", expected: nil),
        // Upper Bound
        IntegerTestCase(input: "10", upperBound: 15, expected: 10),
        IntegerTestCase(input: "16", upperBound: 15, expected: nil),
        IntegerTestCase(input: "010", upperBound: 15, expected: 8),
        IntegerTestCase(input: "020", upperBound: 15, expected: nil),
        IntegerTestCase(input: "0xf", upperBound: 15, expected: 15),
        IntegerTestCase(input: "0x10", upperBound: 15, expected: nil),
    ])
    func integerParsing(testCase: IntegerTestCase) throws {
        if let expected = testCase.expected {
            #expect(try parseInteger(testCase.input, upperBound: testCase.upperBound) == expected)
        } else {
            #expect(throws: SwiftProtobufError.self) {
                try _ = parseInteger(testCase.input, upperBound: testCase.upperBound)
            }
        }
    }

    struct FloatTestCase {
        var input: String
        var expected: Double
    }

    @Test(arguments: [
        FloatTestCase(input: "1.2", expected: 1.2),
        FloatTestCase(input: "1.2f", expected: 1.2),
        FloatTestCase(input: "1e3", expected: 1000.0),
        FloatTestCase(input: ".1", expected: 0.1),
        FloatTestCase(input: "1.", expected: 1.0),
        FloatTestCase(input: "1.e2", expected: 100.0),
        FloatTestCase(input: "1e9999999999", expected: .infinity),
        FloatTestCase(input: "1e-9999999999", expected: 0.0),
        FloatTestCase(input: "5", expected: 5.0),
    ])
    func floatParsing(testCase: FloatTestCase) throws {
        #expect(try parseFloat(testCase.input) == testCase.expected)
    }

    struct StringTestCase {
        var input: String
        var expected: String
    }

    @Test(arguments: [
        StringTestCase(input: "\"hello\"", expected: "hello"),
        StringTestCase(input: "\"\\n\"", expected: "\n"),
        StringTestCase(input: "\"\\x41\"", expected: "A"),
        StringTestCase(input: "\"\\u0041\"", expected: "A"),
        StringTestCase(input: "'\\101'", expected: "A"),
        StringTestCase(input: "'\\u0024\\u00a2\\u20ac\\U00024b62XX'", expected: "$¢€𤭢XX"),
        StringTestCase(input: "'\\u0024\\u00a2\\u20ac\\ud852\\udf62XX'", expected: "$¢€𤭢XX"),
    ])
    func stringParsing(testCase: StringTestCase) throws {
        #expect(try parseString(testCase.input) == testCase.expected)
    }

    @Test func bytesParsing() throws {
        let expectedBytes = Data([0x01, 0x78, 0x01, 0x53, 0x3B, 0x39, 0x2A, 0xDC, 0x6E, 0x03])
        #expect(try parseBytes("'\\1x\\1\\123\\739\\52\\334n\\3'") == expectedBytes)
    }

    @Test func urlCharsMode() throws {
        let input = "foo\n1 1.2\t+\r'bar' foo\n1 1.2\t+\r'bar'\u{B}!&[=* foo\n1 1.2\t+\r'bar'"

        try withTokenizer(for: input) { tokenizer in
            // Regular mode
            try expectNext(&tokenizer)
            #expect(tokenizer.current.kind == .identifier)
            #expect(tokenizer.current.exactString == "foo")

            try expectNext(&tokenizer)
            #expect(tokenizer.current.kind == .integer)
            #expect(tokenizer.current.exactString == "1")

            try expectNext(&tokenizer)
            #expect(tokenizer.current.kind == .float)
            #expect(tokenizer.current.exactString == "1.2")

            try expectNext(&tokenizer)
            #expect(tokenizer.current.kind == .symbol(UInt8(ascii: "+")))
            #expect(tokenizer.current.exactString == "+")

            try expectNext(&tokenizer)
            #expect(tokenizer.current.kind == .string)
            #expect(tokenizer.current.exactString == "'bar'")

            // URL mode
            tokenizer.allowURLCharacters = true
            try expectNext(&tokenizer)
            #expect(tokenizer.current.kind == .urlCharacters)
            #expect(tokenizer.current.exactString == "foo")

            try expectNext(&tokenizer)
            #expect(tokenizer.current.kind == .urlCharacters)
            #expect(tokenizer.current.exactString == "1")

            try expectNext(&tokenizer)
            #expect(tokenizer.current.kind == .urlCharacters)
            #expect(tokenizer.current.exactString == "1.2")

            try expectNext(&tokenizer)
            #expect(tokenizer.current.kind == .urlCharacters)
            #expect(tokenizer.current.exactString == "+")

            try expectNext(&tokenizer)
            #expect(tokenizer.current.kind == .symbol(UInt8(ascii: "'")))
            #expect(tokenizer.current.exactString == "'")

            try expectNext(&tokenizer)
            #expect(tokenizer.current.kind == .urlCharacters)
            #expect(tokenizer.current.exactString == "bar")

            try expectNext(&tokenizer)
            #expect(tokenizer.current.kind == .symbol(UInt8(ascii: "'")))
            #expect(tokenizer.current.exactString == "'")

            try expectNext(&tokenizer)
            #expect(tokenizer.current.kind == .urlCharacters)
            #expect(tokenizer.current.exactString == "!&")

            try expectNext(&tokenizer)
            #expect(tokenizer.current.kind == .leftBracket)
            #expect(tokenizer.current.exactString == "[")

            try expectNext(&tokenizer)
            #expect(tokenizer.current.kind == .urlCharacters)
            #expect(tokenizer.current.exactString == "=*")

            // Regular mode again
            tokenizer.allowURLCharacters = false
            try expectNext(&tokenizer)
            #expect(tokenizer.current.kind == .identifier)
            #expect(tokenizer.current.exactString == "foo")

            try expectNext(&tokenizer)
            #expect(tokenizer.current.kind == .integer)
            #expect(tokenizer.current.exactString == "1")

            try expectNext(&tokenizer)
            #expect(tokenizer.current.kind == .float)
            #expect(tokenizer.current.exactString == "1.2")

            try expectNext(&tokenizer)
            #expect(tokenizer.current.kind == .symbol(UInt8(ascii: "+")))
            #expect(tokenizer.current.exactString == "+")

            try expectNext(&tokenizer)
            #expect(tokenizer.current.kind == .string)
            #expect(tokenizer.current.exactString == "'bar'")

            try expectNoNext(&tokenizer)
        }
    }

    @Test func urlCharsModeAcceptedChars() throws {
        let input = "azAZ09_  -.~!$&()*+,;=%/  [}:@"
        try withTokenizer(for: input) { tokenizer in
            tokenizer.allowURLCharacters = true

            try expectNext(&tokenizer)
            #expect(tokenizer.current.kind == .urlCharacters)
            #expect(tokenizer.current.exactString == "azAZ09_")

            try expectNext(&tokenizer)
            #expect(tokenizer.current.kind == .urlCharacters)
            #expect(tokenizer.current.exactString == "-.~!$&()*+,;=%/")

            try expectNext(&tokenizer)
            #expect(tokenizer.current.kind == .leftBracket)
            #expect(tokenizer.current.exactString == "[")

            try expectNext(&tokenizer)
            #expect(tokenizer.current.kind == .rightBrace)
            #expect(tokenizer.current.exactString == "}")

            try expectNext(&tokenizer)
            #expect(tokenizer.current.kind == .colon)
            #expect(tokenizer.current.exactString == ":")

            try expectNext(&tokenizer)
            #expect(tokenizer.current.kind == .symbol(UInt8(ascii: "@")))
            #expect(tokenizer.current.exactString == "@")

            try expectNoNext(&tokenizer)
        }
    }

    @Test(arguments: [
        ("foo", true),
        ("foo_bar", true),
        ("foo123", true),
        ("_foo", true),
        ("A", true),
        ("_", true),
        ("", false),
        ("123foo", false),
        ("foo.bar", false),
        ("foo-bar", false),
        ("foo bar", false),
        ("foo!", false),
    ])
    func externalIsIdentifier(input: String, expected: Bool) {
        #expect(Tokenizer.isIdentifier(input) == expected)
    }

    @Test func jsonMode() throws {
        let input = """
            {
              "string": "hello\\u0020world",
              "number": \t -12.34,
              "bool":\ntrue,
              "otherBool": false,
              "nothing": null
            }
            """
        try withTokenizer(for: input, mode: .json) { tokenizer in
            let expected: [(String, Token.Kind)] = [
                ("{", .leftBrace),
                ("\"string\"", .string), (":", .colon), ("\"hello\\u0020world\"", .stringWithEscapes), (",", .comma),
                ("\"number\"", .string), (":", .colon),
                ("-", .minus), ("12.34", .float), (",", .comma),
                ("\"bool\"", .string), (":", .colon), ("true", .identifier), (",", .comma),
                ("\"otherBool\"", .string), (":", .colon), ("false", .identifier), (",", .comma),
                ("\"nothing\"", .string), (":", .colon), ("null", .identifier),
                ("}", .rightBrace),
            ]

            for (text, kind) in expected {
                try expectNext(&tokenizer)
                #expect(tokenizer.current.exactString == text)
                #expect(tokenizer.current.kind == kind)
            }
            try expectNoNext(&tokenizer)
        }
    }

    struct JsonErrorCase {
        var input: String
        var expectedError: String
    }

    @Test(arguments: [
        JsonErrorCase(input: "'hello'", expectedError: "1:1: Single quoted strings are not allowed in JSON"),
        JsonErrorCase(input: "05", expectedError: "1:2: Leading zeros are not allowed in JSON"),
        JsonErrorCase(input: "0x1A", expectedError: "1:3: Hex numbers are not allowed in JSON"),
        JsonErrorCase(input: ".5", expectedError: "1:3: Numbers cannot start with a decimal point in JSON"),
        JsonErrorCase(input: "\"\\xXX\"", expectedError: "1:3: Invalid escape sequence in string literal"),
        JsonErrorCase(input: "\"\\v\"", expectedError: "1:3: Invalid escape sequence in string literal"),
        JsonErrorCase(input: "\"\\U00000020\"", expectedError: "1:3: Invalid escape sequence in string literal"),
        JsonErrorCase(input: "@", expectedError: "1:2: Invalid symbol '@' in JSON"),
        JsonErrorCase(input: "#", expectedError: "1:2: Invalid symbol '#' in JSON"),
        JsonErrorCase(input: "\"\\", expectedError: "1:3: Invalid escape sequence in string literal"),
        JsonErrorCase(input: "\"\\uXYZ\"", expectedError: "1:4: Expected four hex digits for '\\u' escape sequence"),
    ])
    func jsonModeErrors(testCase: JsonErrorCase) throws {
        expectThrowsError(
            try withTokenizer(for: testCase.input, mode: .json) { tokenizer in
                while try tokenizer.next() {}
            },
            matching: testCase.expectedError
        )
    }

    @Test func unicodeBMPCodes() throws {
        for codePoint in 0..<UInt32(0x10000) {
            guard let scalar = UnicodeScalar(codePoint) else { continue }
            let expected = String(scalar)

            func expectFormat(_ formatted: String) throws {
                #expect(try parseString(formatted) == expected)
            }

            try expectFormat(String(format: "'\\u%04x'", codePoint))
            try expectFormat(String(format: "'\\u%04X'", codePoint))
            try expectFormat(String(format: "'\\U%08x'", codePoint))
            try expectFormat(String(format: "'\\U%08X'", codePoint))
        }
    }

    @Test func unicodeNonBMPCodes() throws {
        // Non-BMP: 0x10000 to 0x10FFFF
        for codePoint in UInt32(0x10000)...UInt32(0x10FFFF) {
            guard let scalar = UnicodeScalar(codePoint) else { continue }
            let expected = String(scalar)

            func expectFormat(_ formatted: String) throws {
                #expect(try parseString(formatted) == expected)
            }

            try expectFormat(String(format: "'\\U%08x'", codePoint))
            try expectFormat(String(format: "'\\U%08X'", codePoint))

            // surrogate pairs
            let high = 0xD800 + ((codePoint - 0x10000) >> 10)
            let low = 0xDC00 + ((codePoint - 0x10000) & 0x3FF)
            try expectFormat(String(format: "'\\u%04x\\u%04x'", high, low))
        }
    }

    @Test func currentOffset() throws {
        let input = "foo 123"
        try withTokenizer(for: input) { tokenizer in
            #expect(tokenizer.currentOffset == 0)  // at start

            try expectNext(&tokenizer)
            #expect(tokenizer.current.kind == .identifier)
            #expect(tokenizer.currentOffset == 0)  // "foo" starts at 0

            try expectNext(&tokenizer)
            #expect(tokenizer.current.kind == .integer)
            #expect(tokenizer.currentOffset == 4)  // "123" starts at 4

            try expectNoNext(&tokenizer)
            #expect(tokenizer.currentOffset == 7)  // at end
        }
    }

    struct TokenPropCase {
        var input: String
        var isHex: Bool
        var isOctal: Bool
    }

    @Test(arguments: [
        TokenPropCase(input: "0x12", isHex: true, isOctal: false),
        TokenPropCase(input: "012", isHex: false, isOctal: true),
        TokenPropCase(input: "12", isHex: false, isOctal: false),
    ])
    func tokenProperties(testCase: TokenPropCase) throws {
        try withTokenizer(for: testCase.input) { tokenizer in
            try expectNext(&tokenizer)
            #expect(tokenizer.current.isHexNumber == testCase.isHex)
            #expect(tokenizer.current.isOctalNumber == testCase.isOctal)
        }
    }

    struct ErrorDescCase {
        var kind: Token.Kind
        var expected: String
    }

    @Test(arguments: [
        ErrorDescCase(kind: .start, expected: "start of input"),
        ErrorDescCase(kind: .end, expected: "end of input"),
        ErrorDescCase(kind: .identifier, expected: "an identifier"),
        ErrorDescCase(kind: .integer, expected: "an integer"),
        ErrorDescCase(kind: .float, expected: "a floating point number"),
        ErrorDescCase(kind: .string, expected: "a string"),
        ErrorDescCase(kind: .stringWithEscapes, expected: "a string"),
        ErrorDescCase(kind: .urlCharacters, expected: "a sequence of URL characters"),
        ErrorDescCase(kind: .leftBrace, expected: "'{'"),
        ErrorDescCase(kind: .rightBrace, expected: "'}'"),
        ErrorDescCase(kind: .leftBracket, expected: "'['"),
        ErrorDescCase(kind: .rightBracket, expected: "']'"),
        ErrorDescCase(kind: .leftAngle, expected: "'<'"),
        ErrorDescCase(kind: .rightAngle, expected: "'>'"),
        ErrorDescCase(kind: .colon, expected: "':'"),
        ErrorDescCase(kind: .comma, expected: "','"),
        ErrorDescCase(kind: .semicolon, expected: "';'"),
        ErrorDescCase(kind: .minus, expected: "'-'"),
        ErrorDescCase(kind: .symbol(UInt8(ascii: "+")), expected: "'+'"),
    ])
    func tokenErrorDescriptions(testCase: ErrorDescCase) {
        #expect(testCase.kind.errorDescription == testCase.expected)
    }

    struct SurrogateErrorCase {
        var input: String
        var expectedError: String
    }

    @Test(arguments: [
        SurrogateErrorCase(input: "'\\uD834\\uD834'", expectedError: "1:1: Invalid surrogate pairing"),
        SurrogateErrorCase(input: "'\\uDD1E'", expectedError: "1:1: Invalid surrogate pairing"),
        SurrogateErrorCase(input: "'\\uD834\\u0041'", expectedError: "1:1: Invalid surrogate pairing"),
        SurrogateErrorCase(input: "'\\uD834A'", expectedError: "1:1: Invalid surrogate pairing"),
        SurrogateErrorCase(input: "'\\uD834'", expectedError: "1:1: Invalid surrogate pairing"),
    ])
    func surrogatePairsValidation(testCase: SurrogateErrorCase) throws {
        expectThrowsError(
            try parseString(testCase.input),
            matching: testCase.expectedError
        )
    }

    @Test(arguments: [
        SurrogateErrorCase(input: "'\\uD834'", expectedError: "1:1: Surrogate code points are not allowed here"),
        SurrogateErrorCase(input: "'\\uDD1E'", expectedError: "1:1: Surrogate code points are not allowed here"),
    ])
    func allowSurrogatesFalse(testCase: SurrogateErrorCase) throws {
        expectThrowsError(
            try parseString(testCase.input, allowSurrogates: false),
            matching: testCase.expectedError
        )
    }

    struct CharClassTestCase: Sendable {
        var name: String
        var classifier: @Sendable (UInt8) -> Bool
        var allowedCharacters: String
        var allowedControlChars: [UInt8] = []
    }

    @Test(arguments: [
        CharClassTestCase(
            name: "isWhitespace",
            classifier: Tokenizer.isWhitespace,
            allowedCharacters: " \t\n\r",
            allowedControlChars: [11, 12]
        ),
        CharClassTestCase(
            name: "isDigit",
            classifier: Tokenizer.isDigit,
            allowedCharacters: "0123456789"
        ),
        CharClassTestCase(
            name: "isOctalDigit",
            classifier: Tokenizer.isOctalDigit,
            allowedCharacters: "01234567"
        ),
        CharClassTestCase(
            name: "isHexDigit",
            classifier: Tokenizer.isHexDigit,
            allowedCharacters: "0123456789abcdefABCDEF"
        ),
        CharClassTestCase(
            name: "isLetter",
            classifier: Tokenizer.isLetter,
            allowedCharacters: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_"
        ),
        CharClassTestCase(
            name: "isAlphanumeric",
            classifier: Tokenizer.isAlphanumeric,
            allowedCharacters: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_0123456789"
        ),
        CharClassTestCase(
            name: "isEscape",
            classifier: Tokenizer.isEscape,
            allowedCharacters: "abfnrtv\\?'\""
        ),
        CharClassTestCase(
            name: "isJSONEscape",
            classifier: Tokenizer.isJSONEscape,
            allowedCharacters: "bfnrt\\/\""
        ),
        CharClassTestCase(
            name: "isJSONSymbol",
            classifier: Tokenizer.isJSONSymbol,
            allowedCharacters: "{}[]:,-"
        ),
        CharClassTestCase(
            name: "isURLCharacter",
            classifier: Tokenizer.isURLCharacter,
            allowedCharacters: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_0123456789-.~!$&()*+,;=%/"
        ),
        CharClassTestCase(
            name: "isUnprintable",
            classifier: Tokenizer.isUnprintable,
            allowedCharacters: "",
            allowedControlChars: Array(1...8) + Array(14...31)
        ),
    ])
    func characterClassification(testCase: CharClassTestCase) {
        let allowedBytes = Set(testCase.allowedCharacters.utf8)
        let allowedControlBytes = Set(testCase.allowedControlChars)

        for byte in 0...255 {
            let isAllowed = allowedBytes.contains(UInt8(byte)) || allowedControlBytes.contains(UInt8(byte))
            let result = testCase.classifier(UInt8(byte))
            #expect(
                result == isAllowed,
                "Classifier '\(testCase.name)' failed for byte \(byte) ('\(UnicodeScalar(UInt8(byte)))'). Expected \(isAllowed) but got \(result)."
            )
        }
    }
}
