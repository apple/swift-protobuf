// Tests/SwiftProtobufTests/Test_TextFormatDecodingOptions.swift - Various TextFormat tests
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Test for the use of TextFormatDecodingOptions
///
// -----------------------------------------------------------------------------

import Foundation
import XCTest
import SwiftProtobuf

final class Test_TextFormatDecodingOptions: XCTestCase {

    func testMessageDepthLimit() {
        let textInput = "a: { a: { i: 1 } }"

        let tests: [(Int, Bool)] = [
            // Limit, success/failure
            ( 10, true ),
            ( 4, true ),
            ( 3, true ),
            ( 2, false ),
            ( 1, false ),
        ]

        for (limit, expectSuccess) in tests {
            do {
                var options = TextFormatDecodingOptions()
                options.messageDepthLimit = limit
                let _ = try SwiftProtoTesting_TestRecursiveMessage(textFormatString: textInput, options: options)
                if !expectSuccess {
                    XCTFail("Should not have succeed, limit: \(limit)")
                }
            } catch TextFormatDecodingError.messageDepthLimit {
                if expectSuccess {
                    XCTFail("Decode failed because of limit, but should *NOT* have, limit: \(limit)")
                } else {
                    // Nothing, this is what was expected.
                }
            } catch let e  {
                XCTFail("Decode failed (limit: \(limit) with unexpected error: \(e)")
            }
        }
    }

    // MARK: Ignoring unknown fields

    func testIgnoreUnknown_Fields() throws {
        let textInputField = "a:1\noptional_int32: 2\nfoo_bar_baz: 3"
        let textInputExtField = "[ext.field]: 1\noptional_int32: 2\n[other_ext]: 3"

        var options = TextFormatDecodingOptions()
        options.ignoreUnknownFields = true

        let msg = try SwiftProtoTesting_TestAllTypes(textFormatString: textInputField, options: options) // Shouldn't fail
        XCTAssertEqual(msg.textFormatString(), "optional_int32: 2\n")

        do {
            let _ = try SwiftProtoTesting_TestAllTypes(textFormatString: textInputExtField, options: options)
            XCTFail("Shouldn't get here")
        } catch TextFormatDecodingError.unknownField {
            // This is what should have happened.
        }
    }

    func testIgnoreUnknown_ExtensionFields() throws {
        let textInputField = "a:1\noptional_int32: 2\nfoo_bar_baz: 3"
        let textInputExtField = "[ext.field]: 1\noptional_int32: 2\n[other_ext]: 3"

        var options = TextFormatDecodingOptions()
        options.ignoreUnknownExtensionFields = true

        do {
            let _ = try SwiftProtoTesting_TestAllTypes(textFormatString: textInputField, options: options)
            XCTFail("Shouldn't get here")
        } catch TextFormatDecodingError.unknownField {
            // This is what should have happened.
        }

        let msg = try SwiftProtoTesting_TestAllTypes(textFormatString: textInputExtField, options: options) // Shouldn't fail
        XCTAssertEqual(msg.textFormatString(), "optional_int32: 2\n")
    }

    func testIgnoreUnknown_Both() throws {
        let textInput = "a:1\noptional_int32: 2\n[ext.field]: 3"

        var options = TextFormatDecodingOptions()
        options.ignoreUnknownFields = true
        options.ignoreUnknownExtensionFields = true

        let msg = try SwiftProtoTesting_TestAllTypes(textFormatString: textInput, options: options) // Shouldn't fail
        XCTAssertEqual(msg.textFormatString(), "optional_int32: 2\n")
    }

    private struct FieldModes: OptionSet {
        let rawValue: Int

        static let single = FieldModes(rawValue: 1 << 0)
        static let repeated = FieldModes(rawValue: 1 << 1)

        static let all: FieldModes = [.single, .repeated]
    }

    // Custom assert that confirms something parsed as a know field on a message passes and also
    // parses when skipped for an unknown field (when the option is enabled).
    private func assertDecodeIgnoringUnknownsSucceeds(
        _ field: String,
        _ value: String,
        includeColon: Bool = true,
        fieldModes: FieldModes = .all,
        file: XCTestFileArgType = #file,
        line: UInt = #line
    ) {
        assert(!fieldModes.isEmpty)
        let maybeColon = includeColon ? ":" : ""
        let singleText = "optional_\(field)\(maybeColon) \(value)"
        let repeatedText = "repeated_\(field): [ \(value) ]"
        // First, make sure it decodes into a message correctly.
        if fieldModes.contains(.single) {
            do {
                let msg = try SwiftProtoTesting_TestAllTypes(textFormatString: singleText)
                XCTAssertFalse(msg.textFormatString().isEmpty, file: file, line: line)  // Should have set some field
            } catch {
                XCTFail("Shoudn't have failed to decode: \(singleText) - \(error)", file: file, line: line)
            }
        }
        if fieldModes.contains(.repeated) {
            do {
                let msg = try SwiftProtoTesting_TestAllTypes(textFormatString: repeatedText)
                // If there was a value, this something should be set (backdoor to testing
                // repeated empty arrays)
                XCTAssertEqual(value.isEmpty, msg.textFormatString().isEmpty, file: file, line: line)
            } catch {
                XCTFail("Shoudn't have failed to decode: \(repeatedText) - \(error)", file: file, line: line)
            }
        }

        var options = TextFormatDecodingOptions()
        options.ignoreUnknownFields = true
        options.ignoreUnknownExtensionFields = true

        func assertEmptyDecodeSucceeds(_ text: String) {
            do {
                let msg = try SwiftProtoTesting_TestEmptyMessage(textFormatString: text, options: options)
                XCTAssertTrue(msg.textFormatString().isEmpty, file: file, line: line)
            } catch {
                XCTFail("Ignoring unknowns shouldn't failed: \(text) - \(error)", file: file, line: line)
            }
        }

        let singleExtText = "[ext.\(field)]\(maybeColon) \(value)"
        let repeatedExtText = "[ext.\(field)]: [ \(value) ]"

        if fieldModes.contains(.single) {
            assertEmptyDecodeSucceeds(singleText)
            assertEmptyDecodeSucceeds(singleExtText)
            assertEmptyDecodeSucceeds("\(singleText) # comment")
            assertEmptyDecodeSucceeds("\(singleExtText) # comment")
            assertEmptyDecodeSucceeds("unknown_message { \(singleText) }")
            assertEmptyDecodeSucceeds("unknown_message { \(singleExtText) }")
            assertEmptyDecodeSucceeds("unknown_message {\n # comment before\n \(singleText)\n}")
            assertEmptyDecodeSucceeds("unknown_message {\n # comment before\n \(singleExtText)\n}")
            assertEmptyDecodeSucceeds("unknown_message {\n \(singleText)\n # comment after\n}")
            assertEmptyDecodeSucceeds("unknown_message {\n \(singleExtText)\n # comment after\n}")
            assertEmptyDecodeSucceeds("unknown_repeating_message: [ { \(singleText) } ]")
            assertEmptyDecodeSucceeds("unknown_repeating_message: [ { \(singleExtText) } ]")
            assertEmptyDecodeSucceeds("unknown_repeating_message: [\n # comment before\n { \(singleText) }\n]")
            assertEmptyDecodeSucceeds("unknown_repeating_message: [\n # comment before\n { \(singleExtText) }\n]")
            assertEmptyDecodeSucceeds("unknown_repeating_message: [\n { \(singleText) }\n # comment after\n]")
            assertEmptyDecodeSucceeds("unknown_repeating_message: [\n { \(singleExtText) }\n # comment after\n]")
        }
        if fieldModes.contains(.repeated) {
            assertEmptyDecodeSucceeds(repeatedText)
            assertEmptyDecodeSucceeds(repeatedExtText)
            assertEmptyDecodeSucceeds("\(repeatedText) # comment after")
            assertEmptyDecodeSucceeds("\(repeatedExtText) # comment after")
            assertEmptyDecodeSucceeds("unknown_message { \(repeatedText) }")
            assertEmptyDecodeSucceeds("unknown_message { \(repeatedExtText) }")
            assertEmptyDecodeSucceeds("unknown_message {\n # comment before\n \(repeatedText)\n}")
            assertEmptyDecodeSucceeds("unknown_message {\n # comment before\n \(repeatedExtText)\n}")
            assertEmptyDecodeSucceeds("unknown_message {\n \(repeatedText)\n # comment after\n}")
            assertEmptyDecodeSucceeds("unknown_message {\n \(repeatedExtText)\n # comment after\n}")
            assertEmptyDecodeSucceeds("unknown_repeating_message: [ { \(repeatedText) } ]")
            assertEmptyDecodeSucceeds("unknown_repeating_message: [ { \(repeatedExtText) } ]")
            assertEmptyDecodeSucceeds("unknown_repeating_message: [\n # comment before\n { \(repeatedText) }\n]")
            assertEmptyDecodeSucceeds("unknown_repeating_message: [\n # comment before\n { \(repeatedExtText) }\n]")
            assertEmptyDecodeSucceeds("unknown_repeating_message: [\n { \(repeatedText) }\n # comment after\n]")
            assertEmptyDecodeSucceeds("unknown_repeating_message: [\n { \(repeatedExtText) }\n # comment after\n]")
        }
    }

    // Custom assert that confirms something parsed as a know field on a message fails and also
    // fails when skipped for an unknown field (when the option is enabled).
    private func assertDecodeIgnoringUnknownsFails(
        _ field: String,
        _ value: String,
        includeColon: Bool = true,
        fieldModes: FieldModes = .all,
        file: XCTestFileArgType = #file,
        line: UInt = #line
    ) {
        assert(!fieldModes.isEmpty)
        let maybeColon = includeColon ? ":" : ""
        let singleText = "optional_\(field)\(maybeColon) \(value)"
        let repeatedText = "repeated_\(field)\(maybeColon) [ \(value) ]"
        // First, make sure it fails decodes.
        if fieldModes.contains(.single) {
            do {
                let _ = try SwiftProtoTesting_TestAllTypes(textFormatString: singleText)
                XCTFail("Should have failed to decode: \(singleText)", file: file, line: line)
            } catch {
                // Nothing
                // TODO: Does it make sense to compare this failure to the ones below?
            }
        }
        if fieldModes.contains(.repeated) {
            do {
                let _ = try SwiftProtoTesting_TestAllTypes(textFormatString: repeatedText)
                XCTFail("Should have failed to decode: \(repeatedText)", file: file, line: line)
            } catch {
                // Nothing
                // TODO: Does it make sense to compare this failure to the ones below?
            }
        }

        var options = TextFormatDecodingOptions()
        options.ignoreUnknownFields = true
        options.ignoreUnknownExtensionFields = true

        func assertEmptyDecodeFails(_ text: String) {
            do {
                let _ = try SwiftProtoTesting_TestEmptyMessage(textFormatString: text, options: options)
                XCTFail("Ignoring unknowns should have still failed: \(text)", file: file, line: line)
            } catch {
                // Nothing
            }
        }

        let singleExtText = "[ext.\(field)]\(maybeColon) \(value)"
        let repeatedExtText = "[ext.\(field)]\(maybeColon) [ \(value) ]"

        // Don't bother with the comment variation as we wouldn't be able to tell if it was
        // a failure for the comment or for the field itself.
        if fieldModes.contains(.single) {
            assertEmptyDecodeFails(singleText)
            assertEmptyDecodeFails(singleExtText)
            assertEmptyDecodeFails("unknown_message { \(singleText) }")
            assertEmptyDecodeFails("unknown_message { \(singleExtText) }")
            assertEmptyDecodeFails("unknown_repeating_message: [ { \(singleText) } ]")
            assertEmptyDecodeFails("unknown_repeating_message: [ { \(singleExtText) } ]")
        }
        if fieldModes.contains(.repeated) {
            assertEmptyDecodeFails(repeatedText)
            assertEmptyDecodeFails(repeatedExtText)
            assertEmptyDecodeFails("unknown_message { \(repeatedText) }")
            assertEmptyDecodeFails("unknown_message { \(repeatedExtText) }")
            assertEmptyDecodeFails("unknown_repeating_message: [ { \(repeatedText) } ]")
            assertEmptyDecodeFails("unknown_repeating_message: [ { \(repeatedExtText) } ]")
        }
    }

    func testIgnoreUnknown_String() {
        assertDecodeIgnoringUnknownsSucceeds("string", "'abc'")
        assertDecodeIgnoringUnknownsSucceeds("string", "\"abc\"")
        assertDecodeIgnoringUnknownsSucceeds("string", "'abc'\n'def'")
        assertDecodeIgnoringUnknownsSucceeds("string", "\"abc\"\n\"def\"")
        assertDecodeIgnoringUnknownsSucceeds("string", "\" !\\\"#$%&'\"\n")
        assertDecodeIgnoringUnknownsSucceeds("string", "\"øùúûüýþÿ\"\n")
        assertDecodeIgnoringUnknownsSucceeds("string", "\"\\a\\b\\f\\n\\r\\t\\v\\\"\\'\\\\\\?\"")
        assertDecodeIgnoringUnknownsSucceeds("string", "\"\\001\\002\\003\\004\\005\\006\\007\"\n")
        assertDecodeIgnoringUnknownsSucceeds("string", "\"\\b\\t\\n\\v\\f\\r\\016\\017\"\n")
        assertDecodeIgnoringUnknownsSucceeds("string", "\"\\020\\021\\022\\023\\024\\025\\026\\027\"\n")
        assertDecodeIgnoringUnknownsSucceeds("string", "\"\\030\\031\\032\\033\\034\\035\\036\\037\"\n")
        assertDecodeIgnoringUnknownsSucceeds("string", "\"☞\"\n")
        assertDecodeIgnoringUnknownsSucceeds("string", "\"\\xE2\\x98\\x9E\"")
        assertDecodeIgnoringUnknownsSucceeds("string", "\"\\342\\230\\236\"")

        assertDecodeIgnoringUnknownsFails("string", "\"\\z\"")
        assertDecodeIgnoringUnknownsFails("string", "\"hello\'")
        assertDecodeIgnoringUnknownsFails("string", "\'hello\"")
        assertDecodeIgnoringUnknownsFails("string", "\"hello")
        // Can't test invalid UTF-8 because as an unknown parse just as bytes.
    }

    func testIgnoreUnknown_Bytes() {
        assertDecodeIgnoringUnknownsSucceeds("bytes", "'abc'")
        assertDecodeIgnoringUnknownsSucceeds("bytes", "\"abc\"")
        assertDecodeIgnoringUnknownsSucceeds("bytes", "'abc'\n'def'")
        assertDecodeIgnoringUnknownsSucceeds("bytes", "\"abc\"\n\"def\"")
        assertDecodeIgnoringUnknownsSucceeds("bytes", "\" !\\\"#$%&'\"\n")
        assertDecodeIgnoringUnknownsSucceeds("bytes", "\"øùúûüýþÿ\"\n")
        assertDecodeIgnoringUnknownsSucceeds("bytes", "\"\\a\\b\\f\\n\\r\\t\\v\\\"\\'\\\\\\?\"")
        assertDecodeIgnoringUnknownsSucceeds("bytes", "\"\\001\\002\\003\\004\\005\\006\\007\"\n")
        assertDecodeIgnoringUnknownsSucceeds("bytes", "\"\\b\\t\\n\\v\\f\\r\\016\\017\"\n")
        assertDecodeIgnoringUnknownsSucceeds("bytes", "\"\\020\\021\\022\\023\\024\\025\\026\\027\"\n")
        assertDecodeIgnoringUnknownsSucceeds("bytes", "\"\\030\\031\\032\\033\\034\\035\\036\\037\"\n")
        assertDecodeIgnoringUnknownsSucceeds("bytes", "\"☞\"\n")
        assertDecodeIgnoringUnknownsSucceeds("bytes", "\"\\xE2\\x98\\x9E\"")
        assertDecodeIgnoringUnknownsSucceeds("bytes", "\"\\342\\230\\236\"")

        assertDecodeIgnoringUnknownsFails("bytes", "\"\\z\"")
        assertDecodeIgnoringUnknownsFails("bytes", "\"hello\'")
        assertDecodeIgnoringUnknownsFails("bytes", "\'hello\"")
        assertDecodeIgnoringUnknownsFails("bytes", "\"hello")
        assertDecodeIgnoringUnknownsFails("bytes", "\"\\\"\n")
        assertDecodeIgnoringUnknownsFails("bytes", "\"\\x\"\n")
        assertDecodeIgnoringUnknownsFails("bytes", "\"\\x&\"\n")
        assertDecodeIgnoringUnknownsFails("bytes", "\"\\xg\"\n")
        assertDecodeIgnoringUnknownsFails("bytes", "\"\\q\"\n")
        assertDecodeIgnoringUnknownsFails("bytes", "\"\\777\"\n") // Out-of-range octal
        assertDecodeIgnoringUnknownsFails("bytes", "\"")
        assertDecodeIgnoringUnknownsFails("bytes", "\"abcde")
        assertDecodeIgnoringUnknownsFails("bytes", "\"\\")
        assertDecodeIgnoringUnknownsFails("bytes", "\"\\3")
        assertDecodeIgnoringUnknownsFails("bytes", "\"\\32")
        assertDecodeIgnoringUnknownsFails("bytes", "\"\\232")
        assertDecodeIgnoringUnknownsFails("bytes", "\"\\x")
        assertDecodeIgnoringUnknownsFails("bytes", "\"\\x1")
        assertDecodeIgnoringUnknownsFails("bytes", "\"\\x12")
        assertDecodeIgnoringUnknownsFails("bytes", "\"\\x12q")
    }

    func testIgnoreUnknown_Enum() {
        assertDecodeIgnoringUnknownsSucceeds("nested_enum", "BAZ")
        // Made up values will pass when ignoring unknown fields
    }

    func testIgnoreUnknown_Bool() {
        assertDecodeIgnoringUnknownsSucceeds("bool", "true")
        assertDecodeIgnoringUnknownsSucceeds("bool", "True")
        assertDecodeIgnoringUnknownsSucceeds("bool", "t")
        assertDecodeIgnoringUnknownsSucceeds("bool", "T")
        assertDecodeIgnoringUnknownsSucceeds("bool", "1")
        assertDecodeIgnoringUnknownsSucceeds("bool", "false")
        assertDecodeIgnoringUnknownsSucceeds("bool", "False")
        assertDecodeIgnoringUnknownsSucceeds("bool", "f")
        assertDecodeIgnoringUnknownsSucceeds("bool", "F")
        assertDecodeIgnoringUnknownsSucceeds("bool", "0")
        // Made up values will pass when ignoring unknown fields (as enums)
    }

    func testIgnoreUnknown_Integer() {
        assertDecodeIgnoringUnknownsSucceeds("int32", "0")
        assertDecodeIgnoringUnknownsSucceeds("int32", "-12")
        assertDecodeIgnoringUnknownsSucceeds("int32", "0x20")
        assertDecodeIgnoringUnknownsSucceeds("int32", "-0x12")
        assertDecodeIgnoringUnknownsSucceeds("int32", "01")
        assertDecodeIgnoringUnknownsSucceeds("int32", "0123")
        assertDecodeIgnoringUnknownsSucceeds("int32", "-01")
        assertDecodeIgnoringUnknownsSucceeds("int32", "-0123")

        // Can't test range values for any ints because they would work as floats

        assertDecodeIgnoringUnknownsFails("int32", "0x1g")
        assertDecodeIgnoringUnknownsFails("int32", "0x1a2g")
        assertDecodeIgnoringUnknownsFails("int32", "-0x1g")
        assertDecodeIgnoringUnknownsFails("int32", "-0x1a2g")
        assertDecodeIgnoringUnknownsFails("int32", "09")
        assertDecodeIgnoringUnknownsFails("int32", "-09")
        assertDecodeIgnoringUnknownsFails("int32", "01a")
        assertDecodeIgnoringUnknownsFails("int32", "-01a")
        assertDecodeIgnoringUnknownsFails("int32", "0128")
        assertDecodeIgnoringUnknownsFails("int32", "-0128")
    }

    func testIgnoreUnknown_FloatingPoint() {
        assertDecodeIgnoringUnknownsSucceeds("float", "0")

        assertDecodeIgnoringUnknownsSucceeds("float", "11.0")
        assertDecodeIgnoringUnknownsSucceeds("float", "1.0f")
        assertDecodeIgnoringUnknownsSucceeds("float", "12f")
        assertDecodeIgnoringUnknownsSucceeds("float", "1.0F")
        assertDecodeIgnoringUnknownsSucceeds("float", "12F")
        assertDecodeIgnoringUnknownsSucceeds("float", "0.1234")
        assertDecodeIgnoringUnknownsSucceeds("float", ".123")
        assertDecodeIgnoringUnknownsSucceeds("float", "1.5e3")
        assertDecodeIgnoringUnknownsSucceeds("float", "2.5e+3")
        assertDecodeIgnoringUnknownsSucceeds("float", "3.5e-3")

        assertDecodeIgnoringUnknownsSucceeds("float", "-11.0")
        assertDecodeIgnoringUnknownsSucceeds("float", "-1.0f")
        assertDecodeIgnoringUnknownsSucceeds("float", "-12f")
        assertDecodeIgnoringUnknownsSucceeds("float", "-1.0F")
        assertDecodeIgnoringUnknownsSucceeds("float", "-12F")
        assertDecodeIgnoringUnknownsSucceeds("float", "-0.1234")
        assertDecodeIgnoringUnknownsSucceeds("float", "-.123")
        assertDecodeIgnoringUnknownsSucceeds("float", "-1.5e3")
        assertDecodeIgnoringUnknownsSucceeds("float", "-2.5e+3")
        assertDecodeIgnoringUnknownsSucceeds("float", "-3.5e-3")

        // This would overload a int, but as a floating point value it will map to "inf".
        assertDecodeIgnoringUnknownsSucceeds("float", "999999999999999999999999999999999999")

        // Things that round to infinity or zero, but should parse ok.
        assertDecodeIgnoringUnknownsSucceeds("float", "1e50")
        assertDecodeIgnoringUnknownsSucceeds("float", "-1e50")
        assertDecodeIgnoringUnknownsSucceeds("float", "1e-50")
        assertDecodeIgnoringUnknownsSucceeds("float", "-1e-50")
        assertDecodeIgnoringUnknownsSucceeds("double", "1e9999")
        assertDecodeIgnoringUnknownsSucceeds("double", "-1e9999")
        assertDecodeIgnoringUnknownsSucceeds("double", "1e-9999")
        assertDecodeIgnoringUnknownsSucceeds("double", "-1e-9999")

        assertDecodeIgnoringUnknownsSucceeds("float", "nan")
        assertDecodeIgnoringUnknownsSucceeds("float", "-nan")
        assertDecodeIgnoringUnknownsSucceeds("float", "inf")
        assertDecodeIgnoringUnknownsSucceeds("float", "-inf")
        assertDecodeIgnoringUnknownsSucceeds("double", "nan")
        assertDecodeIgnoringUnknownsSucceeds("double", "-nan")
        assertDecodeIgnoringUnknownsSucceeds("double", "inf")
        assertDecodeIgnoringUnknownsSucceeds("double", "-inf")
    }

    func testIgnoreUnknown_Messages() {
        // Both bracing types
        assertDecodeIgnoringUnknownsSucceeds("nested_message", "{ bb: 7 }")
        assertDecodeIgnoringUnknownsSucceeds("nested_message", "{}")
        assertDecodeIgnoringUnknownsSucceeds("nested_message", "< bb: 7 >")
        assertDecodeIgnoringUnknownsSucceeds("nested_message", "<>")
        // Without the colon after the field name
        assertDecodeIgnoringUnknownsSucceeds("nested_message", "{ bb: 7 }", includeColon: false)
        assertDecodeIgnoringUnknownsSucceeds("nested_message", "{}", includeColon: false)
        assertDecodeIgnoringUnknownsSucceeds("nested_message", "< bb: 7 >", includeColon: false)
        assertDecodeIgnoringUnknownsSucceeds("nested_message", "<>", includeColon: false)

        assertDecodeIgnoringUnknownsFails("nested_message", "{ >")
        assertDecodeIgnoringUnknownsFails("nested_message", "< }")
        assertDecodeIgnoringUnknownsFails("nested_message", "{ bb: 7 >")
        assertDecodeIgnoringUnknownsFails("nested_message", "< bb: 7 }")
        assertDecodeIgnoringUnknownsFails("nested_message", "{ >", includeColon: false)
        assertDecodeIgnoringUnknownsFails("nested_message", "< }", includeColon: false)
        assertDecodeIgnoringUnknownsFails("nested_message", "{ bb: 7 >", includeColon: false)
        assertDecodeIgnoringUnknownsFails("nested_message", "< bb: 7 }", includeColon: false)
    }

    func testIgnoreUnknown_FieldSeparators() {
        assertDecodeIgnoringUnknownsSucceeds("foreign_message", "{ c: 1, d: 2 }")
        assertDecodeIgnoringUnknownsSucceeds("foreign_message", "{ c: 1; d: 2 }")
        assertDecodeIgnoringUnknownsSucceeds("foreign_message", "{ c: 1 d: 2 }")

        // Valid parsing accepts separators after a single field, validate that for unknowns also.

        assertDecodeIgnoringUnknownsSucceeds("string", "'abc',", fieldModes: .single)
        assertDecodeIgnoringUnknownsSucceeds("nested_enum", "BAZ,", fieldModes: .single)
        assertDecodeIgnoringUnknownsSucceeds("bool", "true,", fieldModes: .single)
        assertDecodeIgnoringUnknownsSucceeds("int32", "0,", fieldModes: .single)
        assertDecodeIgnoringUnknownsSucceeds("float", "nan,", fieldModes: .single)
        assertDecodeIgnoringUnknownsSucceeds("foreign_message", "{ },", fieldModes: .single)

        assertDecodeIgnoringUnknownsSucceeds("string", "'abc';", fieldModes: .single)
        assertDecodeIgnoringUnknownsSucceeds("nested_enum", "BAZ;", fieldModes: .single)
        assertDecodeIgnoringUnknownsSucceeds("bool", "true;", fieldModes: .single)
        assertDecodeIgnoringUnknownsSucceeds("int32", "0;", fieldModes: .single)
        assertDecodeIgnoringUnknownsSucceeds("float", "nan;", fieldModes: .single)
        assertDecodeIgnoringUnknownsSucceeds("foreign_message", "{ };", fieldModes: .single)
        // And now within an a sub message.
        assertDecodeIgnoringUnknownsSucceeds("foreign_message", "{ c: 1, }", fieldModes: .single)
        assertDecodeIgnoringUnknownsSucceeds("foreign_message", "{ c: 1; }", fieldModes: .single)

        // Extra separators fails.
        assertDecodeIgnoringUnknownsFails("string", "'abc',,", fieldModes: .single)
        assertDecodeIgnoringUnknownsFails("nested_enum", "BAZ,,", fieldModes: .single)
        assertDecodeIgnoringUnknownsFails("bool", "true,,", fieldModes: .single)
        assertDecodeIgnoringUnknownsFails("int32", "0,,", fieldModes: .single)
        assertDecodeIgnoringUnknownsFails("float", "nan,,", fieldModes: .single)
        assertDecodeIgnoringUnknownsFails("foreign_message", "{ },,", fieldModes: .single)

        assertDecodeIgnoringUnknownsFails("string", "'abc';;", fieldModes: .single)
        assertDecodeIgnoringUnknownsFails("nested_enum", "BAZ;;", fieldModes: .single)
        assertDecodeIgnoringUnknownsFails("bool", "true;;", fieldModes: .single)
        assertDecodeIgnoringUnknownsFails("int32", "0;;", fieldModes: .single)
        assertDecodeIgnoringUnknownsFails("float", "nan;;", fieldModes: .single)
        assertDecodeIgnoringUnknownsFails("foreign_message", "{ };;", fieldModes: .single)
        // And now within an a sub message.
        assertDecodeIgnoringUnknownsFails("foreign_message", "{ c: 1,, }", fieldModes: .single)
        assertDecodeIgnoringUnknownsFails("foreign_message", "{ c: 1;; }", fieldModes: .single)

        // Test a few depths of nesting and separators along the way and unknown fields at the
        // start and end of each scope along the way.

        let text = """
          unknown_first_outer: "first",
          child {
            repeated_child {
              unknown_first_inner: [0],
              payload {
                unknown_first_inner_inner: "test",
                optional_int32: 1,
                unknown_inner_inner: 2f,
              },
              unknown_inner: 3.0,
            },
            repeated_child {
              unknown_first_inner: 0;
              payload {
                unknown_first_inner_inner: "test";
                optional_int32: 1;
                unknown_inner_inner: 2f;
              },
              unknown_inner: [3.0];
            };
            unknown: "nope",
            unknown: 12;
          },
          unknown_outer: [END];
          unknown_outer_final: "last";
          """

        var options = TextFormatDecodingOptions()
        options.ignoreUnknownFields = true
        options.ignoreUnknownExtensionFields = true

        do {
            let msg = try SwiftProtoTesting_NestedTestAllTypes(textFormatString: text, options: options)
            XCTAssertFalse(msg.textFormatString().isEmpty)
        } catch {
            XCTFail("Shoudn't have failed to decode: \(error)")
        }

    }

    func testIgnoreUnknown_ListSeparators() {
        // "repeated_int32: []" - good
        assertDecodeIgnoringUnknownsSucceeds("int32", "", fieldModes: .repeated)

        // "repeated_int32: [1 2]" - bad, no commas
        assertDecodeIgnoringUnknownsFails("int32", "1 2", fieldModes: .repeated)
        // "repeated_int32: [1, 2,]" - bad extra trailing comma with no value
        assertDecodeIgnoringUnknownsFails("int32", "1, 2,", fieldModes: .repeated)
    }

    func testIgnoreUnknown_Comments() throws {
        // Stress test to unknown field parsing deals with comments correctly.
        let text = """
          does_not_exist: true # comment
          something_else {  # comment
            # comment
            optional_string: "still unknown"
          } # comment

          optional_int32: 1  # !!! real field

          does_not_exist: true # comment
          something_else {  # comment
            # comment
            optional_string: "still unknown" # comment
            optional_string: "still unknown" # comment
              # comment
              "continued" # comment
            # comment
            some_int : 0x12  # comment
            a_float: #comment
               0.2 # comment
            repeat: [
               # comment
               -123 # comment
               # comment
               , # comment
               # comment
               0222 # comment
               # comment
               , # comment
               # comment
               012  # comment
               # comment
            ] # comment
          } # comment

          optional_uint32: 2  # !!! real field

          does_not_exist: true # comment
          something_else {  # comment
            # comment
            optional_string: "still unknown"
          } # comment

          """

        let expected = SwiftProtoTesting_TestAllTypes.with {
            $0.optionalInt32 = 1
            $0.optionalUint32 = 2
        }

        var options = TextFormatDecodingOptions()
        options.ignoreUnknownFields = true

        let msg = try SwiftProtoTesting_TestAllTypes(textFormatString: text, options: options)
        XCTAssertEqual(expected, msg)
    }

    func testIgnoreUnknown_Whitespace() throws {
        // Blanket test to unknown field parsing deals with comments correctly.
        let text = """
          optional_int32: 1  # !!! real field

          does_not_exist
            :
              1

          something_else          {

            optional_string: "still unknown"

              " continued value"

            repeated:   [
              1   ,
                0x1
            ,
              3,  012
            ]

          }

          repeated_strs:   [
              "ab"  "cd" ,
                "de"
            ,
              "xyz"
            ]

          an_int:1some_bytes:"abc"msg_field:{a:true}repeated:[1]another_int:3

          optional_uint32: 2  # !!! real field
          """

        let expected = SwiftProtoTesting_TestAllTypes.with {
            $0.optionalInt32 = 1
            $0.optionalUint32 = 2
        }

        var options = TextFormatDecodingOptions()
        options.ignoreUnknownFields = true

        let msg = try SwiftProtoTesting_TestAllTypes(textFormatString: text, options: options)
        XCTAssertEqual(expected, msg)
    }

    func testIgnoreUnknown_fieldnumTooBig() {
        let expected = SwiftProtoTesting_TestAllTypes.with {
            $0.optionalInt32 = 1
            $0.optionalUint32 = 2
        }
        var options = TextFormatDecodingOptions()
        options.ignoreUnknownFields = true

        // The max field number is 536,870,911, so anything that takes more digits, should
        // fail as malformed.

        let testCases: [(field: String, parses: Bool)] = [
            ("536870911", true),
            ("1536870911", false)
        ]

        for testCase in testCases {
            let text = """
              optional_int32: 1  # !!! real field

              # Unknown field that's a message to test parsing of field numbers
              # nested within a unknown message.
              does_not_exist {
                \(testCase.field): 1
              }

              optional_uint32: 2  # !!! real field
              """

            do {
                let msg = try SwiftProtoTesting_TestAllTypes(textFormatString: text,
                                                             options: options)
                // If we get here, it should be the expected message.
                XCTAssertTrue(testCase.parses)
                XCTAssertEqual(msg, expected)
            } catch TextFormatDecodingError.malformedText {
                if testCase.parses {
                    XCTFail("Unexpected malformedText - input: \(testCase.field)")
                } else {
                    // Nothing, was the expected error
                }
            } catch {
                XCTFail("Unexpected error: \(error) - input: \(testCase.field)")
            }
        }
    }

    func testIgnoreUnknown_FailListWithinList() {
        // The C++ TextFormat parse doesn't directly block this, but it calculates
        // recusion depth differently (it counts each field as a +1/-1 while parsing
        // it, that makes an array count as depth); so this got flagged by the fuzz
        // testing as a way would could end up with stack overflow.

        var options = TextFormatDecodingOptions()
        options.ignoreUnknownFields = true
        options.ignoreUnknownExtensionFields = true

        let testCases: [String] = [
            // fields
            "f:[[]]",
            "f:[1, [], 2]",
            "f <g:[[]]>",
            "f <g:[1, [], 2]]",
            // extensions
            "[e]:[[]]",
            "[e]:[1, [], 2]",
            "[e] <g:[[]]>",
            "[e] <g:[1, [], 2]]",
        ]

        for testCase in testCases {
            do {
                let _ = try SwiftProtoTesting_TestEmptyMessage(textFormatString: testCase,
                                                               options: options)
                XCTFail("Should have failed - input: \(testCase)")
            } catch TextFormatDecodingError.malformedText {
                // Nothing, was the expected error
            } catch {
                XCTFail("Unexpected error: \(error) - input: \(testCase)")
            }
        }
    }

    func testIgnoreUnknownWithMessageDepthLimit() {
        let textInput = "a: { a: { i: 1 } }"

        let tests: [(Int, Bool)] = [
            // Limit, success/failure
            ( 10, true ),
            ( 4, true ),
            ( 3, true ),
            ( 2, false ),
            ( 1, false ),
        ]

        for (limit, expectSuccess) in tests {
            do {
                var options = TextFormatDecodingOptions()
                options.messageDepthLimit = limit
                options.ignoreUnknownFields = true
                let _ = try SwiftProtoTesting_TestEmptyMessage(textFormatString: textInput, options: options)
                if !expectSuccess {
                    XCTFail("Should not have succeed, limit: \(limit)")
                }
            } catch TextFormatDecodingError.messageDepthLimit {
                if expectSuccess {
                    XCTFail("Decode failed because of limit, but should *NOT* have, limit: \(limit)")
                } else {
                    // Nothing, this is what was expected.
                }
            } catch let e  {
                XCTFail("Decode failed (limit: \(limit) with unexpected error: \(e)")
            }
        }
    }

}
