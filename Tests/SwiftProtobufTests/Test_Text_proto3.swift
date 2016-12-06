// Test/Sources/TestSuite/Test_Test_proto3.swift - Exercise proto3 text format coding
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
/// This is a set of tests for text format protobuf files.
///
// -----------------------------------------------------------------------------

import Foundation
import XCTest
import SwiftProtobuf

class Test_Text_proto3: XCTestCase, PBTestHelpers {
    typealias MessageTestType = Proto3TestAllTypes

    //
    // Singular types
    //

    func testEncoding_singleInt32() {
        var a = MessageTestType()
        a.singleInt32 = 41

        XCTAssertEqual("single_int32: 41\n", try a.serializeText())

        assertTextEncode("single_int32: 41\n") {(o: inout MessageTestType) in
            o.singleInt32 = 41 }
        assertTextDecodeSucceeds("single_int32:41") {
            (o: MessageTestType) in
            return o.singleInt32 == 41
        }
        assertTextDecodeSucceeds("single_int32: 41#single_int32: 42") {
            (o: MessageTestType) in
            return o.singleInt32 == 41
        }
        assertTextDecodeSucceeds("single_int32: 41 single_int32: 42") {
            (o: MessageTestType) in
            return o.singleInt32 == 42
        }
        assertTextDecodeFails("single_int32: a\n")
    }

    func testEncoding_singleInt64() {
        var a = MessageTestType()
        a.singleInt64 = 2

        XCTAssertEqual("single_int64: 2\n", try a.serializeText())

        assertTextEncode("single_int64: 2\n") {(o: inout MessageTestType) in o.singleInt64 = 2 }

        assertTextDecodeFails("single_int64: a\n")
    }

    func testEncoding_singleUint32() {
        var a = MessageTestType()
        a.singleUint32 = 3

        XCTAssertEqual("single_uint32: 3\n", try a.serializeText())

        assertTextEncode("single_uint32: 3\n") {(o: inout MessageTestType) in
            o.singleUint32 = 3
        }
        assertTextDecodeSucceeds("single_uint32: 3u") {
            (o: MessageTestType) in
            return o.singleUint32 == 3
        }
        assertTextDecodeSucceeds("single_uint32: 3u single_int32: 1") {
            (o: MessageTestType) in
            return o.singleUint32 == 3 && o.singleInt32 == 1
        }
        assertTextDecodeFails("single_uint32: -3\n")
        assertTextDecodeFails("single_uint32 3\n")
        assertTextDecodeFails("3u")
        assertTextDecodeFails("single_uint32: a\n")
    }

    func testEncoding_singleUint64() {
        var a = MessageTestType()
        a.singleUint64 = 4

        XCTAssertEqual("single_uint64: 4\n", try a.serializeText())

        assertTextEncode("single_uint64: 4\n") {(o: inout MessageTestType) in o.singleUint64 = 4 }

        assertTextDecodeFails("single_uint64: a\n")
    }

    func testEncoding_singleSint32() {
        var a = MessageTestType()
        a.singleSint32 = 5

        XCTAssertEqual("single_sint32: 5\n", try a.serializeText())

        assertTextEncode("single_sint32: 5\n") {(o: inout MessageTestType) in
            o.singleSint32 = 5
        }
        assertTextEncode("single_sint32: -5\n") {(o: inout MessageTestType) in
            o.singleSint32 = -5
        }
        assertTextDecodeSucceeds("    single_sint32:-5    ") {
            (o: MessageTestType) in
            return o.singleSint32 == -5
        }

        assertTextDecodeFails("single_sint32: a\n")
    }

    func testEncoding_singleSint64() {
        var a = MessageTestType()
        a.singleSint64 = 6

        XCTAssertEqual("single_sint64: 6\n", try a.serializeText())

        assertTextEncode("single_sint64: 6\n") {(o: inout MessageTestType) in
            o.singleSint64 = 6
        }
        assertTextDecodeFails("single_sint64: a\n")
    }

    func testEncoding_singleFixed32() {
        var a = MessageTestType()
        a.singleFixed32 = 7

        XCTAssertEqual("single_fixed32: 7\n", try a.serializeText())

        assertTextEncode("single_fixed32: 7\n") {(o: inout MessageTestType) in
            o.singleFixed32 = 7
        }

        assertTextDecodeFails("single_fixed32: a\n")
    }

    func testEncoding_singleFixed64() {
        var a = MessageTestType()
        a.singleFixed64 = 8

        XCTAssertEqual("single_fixed64: 8\n", try a.serializeText())

        assertTextEncode("single_fixed64: 8\n") {(o: inout MessageTestType) in
            o.singleFixed64 = 8
        }

        assertTextDecodeFails("single_fixed64: a\n")
    }

    func testEncoding_singleSfixed32() {
        var a = MessageTestType()
        a.singleSfixed32 = 9

        XCTAssertEqual("single_sfixed32: 9\n", try a.serializeText())

        assertTextEncode("single_sfixed32: 9\n") {(o: inout MessageTestType) in
            o.singleSfixed32 = 9
        }

        assertTextDecodeFails("single_sfixed32: a\n")
    }

    func testEncoding_singleSfixed64() {
        var a = MessageTestType()
        a.singleSfixed64 = 10

        XCTAssertEqual("single_sfixed64: 10\n", try a.serializeText())

        assertTextEncode("single_sfixed64: 10\n") {(o: inout MessageTestType) in
            o.singleSfixed64 = 10
        }

        assertTextDecodeFails("single_sfixed64: a\n")
    }

    func testEncoding_singleFloat() {
        var a = MessageTestType()
        a.singleFloat = 11

        XCTAssertEqual("single_float: 11\n", try a.serializeText())

        assertTextEncode("single_float: 11\n") {(o: inout MessageTestType) in
            o.singleFloat = 11
        }
        assertTextDecodeSucceeds("single_float: 1.0f") {
            (o: MessageTestType) in
            return o.singleFloat == 1.0
        }
        assertTextDecodeSucceeds("single_float: 1.0f single_int32: 1") {
            (o: MessageTestType) in
            return o.singleFloat == 1.0 && o.singleInt32 == 1
        }
        assertTextDecodeSucceeds("single_float: 1.0 single_int32: 1") {
            (o: MessageTestType) in
            return o.singleFloat == 1.0 && o.singleInt32 == 1
        }
        assertTextDecodeSucceeds("single_float: 1.0f\n") {
            (o: MessageTestType) in
            return o.singleFloat == 1.0
        }

        assertTextDecodeFails("single_float: a\n")
    }

    func testEncoding_singleDouble() {
        var a = MessageTestType()
        a.singleDouble = 12

        XCTAssertEqual("single_double: 12\n", try a.serializeText())

        assertTextEncode("single_double: 12\n") {(o: inout MessageTestType) in o.singleDouble = 12 }

        assertTextDecodeFails("single_double: a\n")
    }

    func testEncoding_singleBool() {
        var a = MessageTestType()
        a.singleBool = true
        XCTAssertEqual("single_bool: true\n", try a.serializeText())

        a.singleBool = false
        XCTAssertEqual("", try a.serializeText())

        assertTextEncode("single_bool: true\n") {(o: inout MessageTestType) in
            o.singleBool = true
        }

        assertTextDecodeFails("single_bool: 10\n")
        assertTextDecodeFails("single_bool: a\n")
    }

    func testEncoding_singleString() {
        var a = MessageTestType()
        a.singleString = "abc"

        XCTAssertEqual("single_string: \"abc\"\n", try a.serializeText())

        // Adjacent quoted strings concatenate, see
        //   google/protobuf/text_format_unittest.cc#L597
        assertTextDecodeSucceeds("single_string: \"abc\"\"def\"") {
            (o: MessageTestType) in
            return o.singleString == "abcdef"
        }
        assertTextDecodeSucceeds("single_string: \"abc\" \"def\"") {
            (o: MessageTestType) in
            return o.singleString == "abcdef"
        }
        assertTextDecodeSucceeds("single_string: \"abc\"   \"def\"") {
            (o: MessageTestType) in
            return o.singleString == "abcdef"
        }
        // Adjacent quoted strings concatenate across multiple lines
        assertTextDecodeSucceeds("single_string: \"abc\"\n\"def\"") {
            (o: MessageTestType) in
            return o.singleString == "abcdef"
        }
        assertTextDecodeSucceeds("single_string: \"abc\"\n\"def\"\n\"ghi\"\n") {
            (o: MessageTestType) in
            return o.singleString == "abcdefghi"
        }
        assertTextDecodeSucceeds("single_string: \"abc\"\n\'def\'\n\"ghi\"\n") {
            (o: MessageTestType) in
            return o.singleString == "abcdefghi"
        }
        assertTextEncode("single_string: \"abc\"\n") {(o: inout MessageTestType) in
            o.singleString = "abc"
        }
    }

    func testEncoding_singleBytes() throws {
        let o = Proto3TestAllTypes.with { $0.singleBytes = Data() }
        XCTAssertEqual("", try o.serializeText())

        assertTextEncode("single_bytes: \"AB\"\n") {(o: inout MessageTestType) in
            o.singleBytes = Data(bytes: [65, 66])
        }
        assertTextEncode("single_bytes: \"\\000\\001AB\\177\\200\\377\"\n") {(o: inout MessageTestType) in
            o.singleBytes = Data(bytes: [0, 1, 65, 66, 127, 128, 255])
        }
        assertTextDecodeSucceeds("single_bytes: \"A\" \"B\"\n") {(o: MessageTestType) in
            return o.singleBytes == Data(bytes: [65, 66])
        }
        assertTextDecodeSucceeds("single_bytes: \"\\0\\1AB\\178\\189\\x61\\xdq\\x123456789\"\n") {(o: MessageTestType) in
            return o.singleBytes == Data(bytes: [0, 1, 65, 66, 15, 56, 1, 56, 57, 97, 13, 113, 137])
        }
        assertTextDecodeSucceeds("single_bytes: \"\"\n") {(o: MessageTestType) in
            return o.singleBytes == Data()
        }
        assertTextDecodeSucceeds("single_bytes: \"\\b\\t\\n\\v\\f\\r\\\"\\'\\?'\"\n") {(o: MessageTestType) in
            return o.singleBytes == Data(bytes: [8, 9, 10, 11, 12, 13, 34, 39, 63, 39])
        }
        
        assertTextDecodeFails("single_bytes: 10\n")
        assertTextDecodeFails("single_bytes: \"\\\"\n")
        assertTextDecodeFails("single_bytes: \"\\x\"\n")
        assertTextDecodeFails("single_bytes: \"\\x&\"\n")
        assertTextDecodeFails("single_bytes: \"\\q\"\n")
    }

    func testEncoding_singleNestedMessage() {
        var nested = MessageTestType.NestedMessage()
        nested.bb = 7

        var a = MessageTestType()
        a.singleNestedMessage = nested

        XCTAssertEqual("single_nested_message {\n  bb: 7\n}\n", try a.serializeText())

        assertTextEncode("single_nested_message {\n  bb: 7\n}\n") {(o: inout MessageTestType) in o.singleNestedMessage = nested }

        do {
            let message = try MessageTestType(text:"single_nested_message: {\n  bb: 7\n}\n")
            XCTAssertEqual(message.singleNestedMessage.bb, 7)
        } catch {
            XCTFail("Presented error: \(error)")
        }

        assertTextDecodeFails("single_nested_message: a\n")
    }

    func testEncoding_singleForeignMessage() {
        var foreign = Proto3ForeignMessage()
        foreign.c = 88

        var a = MessageTestType()
        a.singleForeignMessage = foreign

        XCTAssertEqual("single_foreign_message {\n  c: 88\n}\n", try a.serializeText())

        assertTextEncode("single_foreign_message {\n  c: 88\n}\n") {(o: inout MessageTestType) in o.singleForeignMessage = foreign }

        do {
            let message = try MessageTestType(text:"single_foreign_message: {\n  c: 88\n}\n")
            XCTAssertEqual(message.singleForeignMessage.c, 88)
        } catch {
            XCTFail("Presented error: \(error)")
        }

        assertTextDecodeFails("single_foreign_message: a\n")
    }

    func testEncoding_singleImportMessage() {
        var importMessage = Proto3ImportMessage()
        importMessage.d = -9

        var a = MessageTestType()
        a.singleImportMessage = importMessage

        XCTAssertEqual("single_import_message {\n  d: -9\n}\n", try a.serializeText())

        assertTextEncode("single_import_message {\n  d: -9\n}\n") {(o: inout MessageTestType) in o.singleImportMessage = importMessage }

        do {
            let message = try MessageTestType(text:"single_import_message: {\n  d: -9\n}\n")
            XCTAssertEqual(message.singleImportMessage.d, -9)
        } catch {
            XCTFail("Presented error: \(error)")
        }

        assertTextDecodeFails("single_import_message: a\n")
    }

    func testEncoding_singleNestedEnum() {
        var a = MessageTestType()
        a.singleNestedEnum = .baz

        XCTAssertEqual("single_nested_enum: BAZ\n", try a.serializeText())

        assertTextEncode("single_nested_enum: BAZ\n") {(o: inout MessageTestType) in o.singleNestedEnum = .baz }

        assertTextDecodeFails("single_nested_enum: a\n")
    }

    func testEncoding_singleForeignEnum() {
        var a = MessageTestType()
        a.singleForeignEnum = .foreignBaz

        XCTAssertEqual("single_foreign_enum: FOREIGN_BAZ\n", try a.serializeText())

        assertTextEncode("single_foreign_enum: FOREIGN_BAZ\n") {(o: inout MessageTestType) in o.singleForeignEnum = .foreignBaz }

        assertTextDecodeFails("single_foreign_enum: a\n")
    }

    func testEncoding_singleImportEnum() {
        var a = MessageTestType()
        a.singleImportEnum = .importBaz

        XCTAssertEqual("single_import_enum: IMPORT_BAZ\n", try a.serializeText())

        assertTextEncode("single_import_enum: IMPORT_BAZ\n") {(o: inout MessageTestType) in o.singleImportEnum = .importBaz }

        assertTextDecodeFails("single_import_enum: a\n")
    }

    func testEncoding_singlePublicImportMessage() {
        var publicImportMessage = Proto3PublicImportMessage()
        publicImportMessage.e = -999999

        var a = MessageTestType()
        a.singlePublicImportMessage = publicImportMessage

        XCTAssertEqual("single_public_import_message {\n  e: -999999\n}\n", try a.serializeText())

        assertTextEncode("single_public_import_message {\n  e: -999999\n}\n") {(o: inout MessageTestType) in o.singlePublicImportMessage = publicImportMessage }

        do {
            let message = try MessageTestType(text:"single_public_import_message: {\n  e: -999999\n}\n")
            XCTAssertEqual(message.singlePublicImportMessage.e, -999999)
        } catch {
            XCTFail("Presented error: \(error)")
        }

        assertTextDecodeFails("single_public_import_message: a\n")
    }

    //
    // Repeated types
    //

    func testEncoding_repeatedInt32() {
        var a = MessageTestType()
        a.repeatedInt32 = [1, 2]

        XCTAssertEqual("repeated_int32: 1\nrepeated_int32: 2\n", try a.serializeText())

        assertTextEncode("repeated_int32: 1\nrepeated_int32: 2\n") {(o: inout MessageTestType) in o.repeatedInt32 = [1, 2] }

        assertTextDecodeSucceeds("repeated_int32: [1, 2]\n") {
            (o: MessageTestType) in
            return o.repeatedInt32 == [1, 2]
        }
        assertTextDecodeSucceeds("repeated_int32:[1, 2]") {
            (o: MessageTestType) in
            return o.repeatedInt32 == [1, 2]
        }
        assertTextDecodeSucceeds("repeated_int32: [1] repeated_int32: 2\n") {
            (o: MessageTestType) in
            return o.repeatedInt32 == [1, 2]
        }
        assertTextDecodeSucceeds("repeated_int32: 1 repeated_int32: [2]\n") {
            (o: MessageTestType) in
            return o.repeatedInt32 == [1, 2]
        }
        assertTextDecodeSucceeds("repeated_int32:[]\nrepeated_int32: [1, 2]\nrepeated_int32:[]\n") {
            (o: MessageTestType) in
            return o.repeatedInt32 == [1, 2]
        }
        assertTextDecodeSucceeds("repeated_int32:1\nrepeated_int32:2\n") {
            (o: MessageTestType) in
            return o.repeatedInt32 == [1, 2]
        }

        assertTextDecodeFails("repeated_int32: 1\nrepeated_int32: a\n")
        assertTextDecodeFails("repeated_int32: [")
        assertTextDecodeFails("repeated_int32: [\n")
        assertTextDecodeFails("repeated_int32: [1\n")
        assertTextDecodeFails("repeated_int32: [1,\n")
        assertTextDecodeFails("repeated_int32: [1,2\n")
    }

    func testEncoding_repeatedInt64() {
        var a = MessageTestType()
        a.repeatedInt64 = [3, 4]

        XCTAssertEqual("repeated_int64: 3\nrepeated_int64: 4\n", try a.serializeText())

        assertTextEncode("repeated_int64: 3\nrepeated_int64: 4\n") {(o: inout MessageTestType) in o.repeatedInt64 = [3, 4] }

        assertTextDecodeFails("repeated_int64: 3\nrepeated_int64: a\n")
    }

    func testEncoding_repeatedUint32() {
        var a = MessageTestType()
        a.repeatedUint32 = [5, 6]

        XCTAssertEqual("repeated_uint32: 5\nrepeated_uint32: 6\n", try a.serializeText())

        assertTextEncode("repeated_uint32: 5\nrepeated_uint32: 6\n") {(o: inout MessageTestType) in o.repeatedUint32 = [5, 6] }

        assertTextDecodeFails("repeated_uint32: 5\nrepeated_uint32: a\n")
    }

    func testEncoding_repeatedUint64() {
        var a = MessageTestType()
        a.repeatedUint64 = [7, 8]

        XCTAssertEqual("repeated_uint64: 7\nrepeated_uint64: 8\n", try a.serializeText())

        assertTextEncode("repeated_uint64: 7\nrepeated_uint64: 8\n") {(o: inout MessageTestType) in o.repeatedUint64 = [7, 8] }

        assertTextDecodeFails("repeated_uint64: 7\nrepeated_uint64: a\n")
    }

    func testEncoding_repeatedSint32() {
        var a = MessageTestType()
        a.repeatedSint32 = [9, 10]

        XCTAssertEqual("repeated_sint32: 9\nrepeated_sint32: 10\n", try a.serializeText())

        assertTextEncode("repeated_sint32: 9\nrepeated_sint32: 10\n") {(o: inout MessageTestType) in o.repeatedSint32 = [9, 10] }

        assertTextDecodeFails("repeated_sint32: 9\nrepeated_sint32: a\n")
    }

    func testEncoding_repeatedSint64() {
        var a = MessageTestType()
        a.repeatedSint64 = [11, 12]

        XCTAssertEqual("repeated_sint64: 11\nrepeated_sint64: 12\n", try a.serializeText())

        assertTextEncode("repeated_sint64: 11\nrepeated_sint64: 12\n") {(o: inout MessageTestType) in o.repeatedSint64 = [11, 12] }

        assertTextDecodeFails("repeated_sint64: 11\nrepeated_sint64: a\n")
    }

    func testEncoding_repeatedFixed32() {
        var a = MessageTestType()
        a.repeatedFixed32 = [13, 14]

        XCTAssertEqual("repeated_fixed32: 13\nrepeated_fixed32: 14\n", try a.serializeText())

        assertTextEncode("repeated_fixed32: 13\nrepeated_fixed32: 14\n") {(o: inout MessageTestType) in o.repeatedFixed32 = [13, 14] }

        assertTextDecodeFails("repeated_fixed32: 13\nrepeated_fixed32: a\n")
    }

    func testEncoding_repeatedFixed64() {
        var a = MessageTestType()
        a.repeatedFixed64 = [15, 16]

        XCTAssertEqual("repeated_fixed64: 15\nrepeated_fixed64: 16\n", try a.serializeText())

        assertTextEncode("repeated_fixed64: 15\nrepeated_fixed64: 16\n") {(o: inout MessageTestType) in o.repeatedFixed64 = [15, 16] }

        assertTextDecodeFails("repeated_fixed64: 15\nrepeated_fixed64: a\n")
    }

    func testEncoding_repeatedSfixed32() {
        var a = MessageTestType()
        a.repeatedSfixed32 = [17, 18]

        XCTAssertEqual("repeated_sfixed32: 17\nrepeated_sfixed32: 18\n", try a.serializeText())

        assertTextEncode("repeated_sfixed32: 17\nrepeated_sfixed32: 18\n") {(o: inout MessageTestType) in o.repeatedSfixed32 = [17, 18] }

        assertTextDecodeFails("repeated_sfixed32: 17\nrepeated_sfixed32: a\n")
    }

    func testEncoding_repeatedSfixed64() {
        var a = MessageTestType()
        a.repeatedSfixed64 = [19, 20]

        XCTAssertEqual("repeated_sfixed64: 19\nrepeated_sfixed64: 20\n", try a.serializeText())

        assertTextEncode("repeated_sfixed64: 19\nrepeated_sfixed64: 20\n") {(o: inout MessageTestType) in o.repeatedSfixed64 = [19, 20] }

        assertTextDecodeFails("repeated_sfixed64: 19\nrepeated_sfixed64: a\n")
    }

    func testEncoding_repeatedFloat() {
        var a = MessageTestType()
        a.repeatedFloat = [21, 22]

        XCTAssertEqual("repeated_float: 21\nrepeated_float: 22\n", try a.serializeText())

        assertTextEncode("repeated_float: 21\nrepeated_float: 22\n") {(o: inout MessageTestType) in o.repeatedFloat = [21, 22] }

        assertTextDecodeFails("repeated_float: 21\nrepeated_float: a\n")
    }

    func testEncoding_repeatedDouble() {
        var a = MessageTestType()
        a.repeatedDouble = [23, 24]

        XCTAssertEqual("repeated_double: 23\nrepeated_double: 24\n", try a.serializeText())

        assertTextEncode("repeated_double: 23\nrepeated_double: 24\n") {(o: inout MessageTestType) in o.repeatedDouble = [23, 24] }

        assertTextDecodeFails("repeated_double: 23\nrepeated_double: a\n")
    }

    func testEncoding_repeatedBool() {
        var a = MessageTestType()
        a.repeatedBool = [true, false]

        XCTAssertEqual("repeated_bool: true\nrepeated_bool: false\n", try a.serializeText())

        assertTextEncode("repeated_bool: true\nrepeated_bool: false\n") {(o: inout MessageTestType) in o.repeatedBool = [true, false] }
        assertTextDecodeSucceeds("repeated_bool: [true, false, True, False, t, f, 1, 0]") {
            (o: MessageTestType) in
            return o.repeatedBool == [true, false, true, false, true, false, true, false]
        }

        assertTextDecodeFails("repeated_bool: true\nrepeated_bool: a\n")
    }

    func testEncoding_repeatedString() {
        assertTextDecodeSucceeds("repeated_string: \"abc\"\nrepeated_string: \"def\"\n") {
            (o: MessageTestType) in
            return o.repeatedString == ["abc", "def"]
        }
        assertTextDecodeSucceeds("repeated_string:[\"abc\", \"def\"]") {
            (o: MessageTestType) in
            return o.repeatedString == ["abc", "def"]
        }
        assertTextDecodeSucceeds("repeated_string:[\"abc\", 'def']") {
            (o: MessageTestType) in
            return o.repeatedString == ["abc", "def"]
        }
        assertTextDecodeSucceeds("repeated_string:[\"abc\", \"def\",]") {
            (o: MessageTestType) in
            return o.repeatedString == ["abc", "def"]
        }
        assertTextDecodeSucceeds("repeated_string:[\"abc\"] repeated_string: \"def\"") {
            (o: MessageTestType) in
            return o.repeatedString == ["abc", "def"]
        }
        assertTextDecodeFails("repeated_string:[\"abc\"")
        assertTextDecodeFails("repeated_string:[\"abc\",")
        assertTextDecodeFails("repeated_string: \"abc\"]")
        assertTextDecodeFails("repeated_string: abc")

        assertTextEncode("repeated_string: \"abc\"\nrepeated_string: \"def\"\n") {(o: inout MessageTestType) in o.repeatedString = ["abc", "def"] }
    }

    func testEncoding_repeatedBytes() {
        var a = MessageTestType()
        a.repeatedBytes = [Data(), Data(bytes: [65, 66])]
        XCTAssertEqual("repeated_bytes: \"\"\nrepeated_bytes: \"AB\"\n", try a.serializeText())

        assertTextEncode("repeated_bytes: \"\"\nrepeated_bytes: \"AB\"\n") {(o: inout MessageTestType) in
            o.repeatedBytes = [Data(), Data(bytes: [65, 66])]
        }
    }

    func testEncoding_repeatedNestedMessage() {
        var nested = MessageTestType.NestedMessage()
        nested.bb = 7

        var nested2 = nested
        nested2.bb = -7

        var a = MessageTestType()
        a.repeatedNestedMessage = [nested, nested2]

        XCTAssertEqual("repeated_nested_message {\n  bb: 7\n}\nrepeated_nested_message {\n  bb: -7\n}\n", try a.serializeText())

        assertTextEncode("repeated_nested_message {\n  bb: 7\n}\nrepeated_nested_message {\n  bb: -7\n}\n") {(o: inout MessageTestType) in o.repeatedNestedMessage = [nested, nested2] }

        assertTextDecodeSucceeds("repeated_nested_message: {\n bb: 7\n}\nrepeated_nested_message: {\n  bb: -7\n}\n") {
            (o: MessageTestType) in
            return o.repeatedNestedMessage == [
                MessageTestType.NestedMessage.with {$0.bb = 7},
                MessageTestType.NestedMessage.with {$0.bb = -7}
            ]
        }
        assertTextDecodeSucceeds("repeated_nested_message:[{bb: 7}, {bb: -7}]") {
            (o: MessageTestType) in
            return o.repeatedNestedMessage == [
                MessageTestType.NestedMessage.with {$0.bb = 7},
                MessageTestType.NestedMessage.with {$0.bb = -7}
            ]
        }

        assertTextDecodeFails("repeated_nested_message {\n  bb: 7\n}\nrepeated_nested_message {\n  bb: a\n}\n")
    }

    func testEncoding_repeatedForeignMessage() {
        var foreign = Proto3ForeignMessage()
        foreign.c = 88

        var foreign2 = foreign
        foreign2.c = -88

        var a = MessageTestType()
        a.repeatedForeignMessage = [foreign, foreign2]

        XCTAssertEqual("repeated_foreign_message {\n  c: 88\n}\nrepeated_foreign_message {\n  c: -88\n}\n", try a.serializeText())

        assertTextEncode("repeated_foreign_message {\n  c: 88\n}\nrepeated_foreign_message {\n  c: -88\n}\n") {(o: inout MessageTestType) in o.repeatedForeignMessage = [foreign, foreign2] }

        do {
            let message = try MessageTestType(text:"repeated_foreign_message: {\n  c: 88\n}\nrepeated_foreign_message: {\n  c: -88\n}\n")
            XCTAssertEqual(message.repeatedForeignMessage[0].c, 88)
            XCTAssertEqual(message.repeatedForeignMessage[1].c, -88)
        } catch {
            XCTFail("Presented error: \(error)")
        }

        assertTextDecodeFails("repeated_foreign_message {\n  c: 88\n}\nrepeated_foreign_message {\n  c: a\n}\n")
    }


    func testEncoding_repeatedImportMessage() {
        var importMessage = Proto3ImportMessage()
        importMessage.d = -9

        var importMessage2 = importMessage
        importMessage2.d = 999999

        var a = MessageTestType()
        a.repeatedImportMessage = [importMessage, importMessage2]

        XCTAssertEqual("repeated_import_message {\n  d: -9\n}\nrepeated_import_message {\n  d: 999999\n}\n", try a.serializeText())

        assertTextEncode("repeated_import_message {\n  d: -9\n}\nrepeated_import_message {\n  d: 999999\n}\n") {(o: inout MessageTestType) in o.repeatedImportMessage = [importMessage, importMessage2] }

        do {
            let message = try MessageTestType(text:"repeated_import_message: {\n  d: -9\n}\nrepeated_import_message: {\n  d: 999999\n}\n")
            XCTAssertEqual(message.repeatedImportMessage[0].d, -9)
            XCTAssertEqual(message.repeatedImportMessage[1].d, 999999)
        } catch {
            XCTFail("Presented error: \(error)")
        }

        assertTextDecodeFails("repeated_import_message {\n  d: -9\n}\nrepeated_import_message {\n  d: a\n}\n")
    }

    func testEncoding_repeatedNestedEnum() {
        var a = MessageTestType()
        a.repeatedNestedEnum = [.bar, .baz]
        XCTAssertEqual("repeated_nested_enum: BAR\nrepeated_nested_enum: BAZ\n", try a.serializeText())

        assertTextEncode("repeated_nested_enum: BAR\nrepeated_nested_enum: BAZ\n") {(o: inout MessageTestType) in o.repeatedNestedEnum = [.bar, .baz] }

        assertTextDecodeSucceeds("repeated_nested_enum: [BAR, BAZ]") {
            (o: MessageTestType) in
            return o.repeatedNestedEnum == [.bar, .baz]
        }

        assertTextDecodeSucceeds("repeated_nested_enum: [2, BAZ]") {
            (o: MessageTestType) in
            return o.repeatedNestedEnum == [.bar, .baz]
        }
        assertTextDecodeSucceeds("repeated_nested_enum: [] repeated_nested_enum: [2] repeated_nested_enum: [BAZ] repeated_nested_enum: []") {
            (o: MessageTestType) in
            return o.repeatedNestedEnum == [.bar, .baz]
        }

        assertTextDecodeFails("repeated_nested_enum: BAR\nrepeated_nested_enum: a\n")
    }

    func testEncoding_repeatedForeignEnum() {
        var a = MessageTestType()
        a.repeatedForeignEnum = [.foreignBar, .foreignBaz]

        XCTAssertEqual("repeated_foreign_enum: FOREIGN_BAR\nrepeated_foreign_enum: FOREIGN_BAZ\n", try a.serializeText())

        assertTextEncode("repeated_foreign_enum: FOREIGN_BAR\nrepeated_foreign_enum: FOREIGN_BAZ\n") {(o: inout MessageTestType) in o.repeatedForeignEnum = [.foreignBar, .foreignBaz] }

        assertTextDecodeFails("repeated_foreign_enum: FOREIGN_BAR\nrepeated_foreign_enum: a\n")
    }

    func testEncoding_repeatedImportEnum() {
        var a = MessageTestType()
        a.repeatedImportEnum = [.importBar, .importBaz]

        XCTAssertEqual("repeated_import_enum: IMPORT_BAR\nrepeated_import_enum: IMPORT_BAZ\n", try a.serializeText())

        assertTextEncode("repeated_import_enum: IMPORT_BAR\nrepeated_import_enum: IMPORT_BAZ\n") {(o: inout MessageTestType) in o.repeatedImportEnum = [.importBar, .importBaz] }

        assertTextDecodeFails("repeated_import_enum: IMPORT_BAR\nrepeated_import_enum: a\n")
    }

    func testEncoding_repeatedPublicImportMessage() {
        var publicImportMessage = Proto3PublicImportMessage()
        publicImportMessage.e = -999999

        var publicImportMessage2 = publicImportMessage
        publicImportMessage2.e = 999999

        var a = MessageTestType()
        a.repeatedPublicImportMessage = [publicImportMessage, publicImportMessage2]

        XCTAssertEqual("repeated_public_import_message {\n  e: -999999\n}\nrepeated_public_import_message {\n  e: 999999\n}\n", try a.serializeText())

        assertTextEncode("repeated_public_import_message {\n  e: -999999\n}\nrepeated_public_import_message {\n  e: 999999\n}\n") {(o: inout MessageTestType) in o.repeatedPublicImportMessage = [publicImportMessage, publicImportMessage2] }

        do {
            let message = try MessageTestType(text:"repeated_public_import_message: {\n  e: -999999\n}\nrepeated_public_import_message: {\n  e: 999999\n}\n")
            XCTAssertEqual(message.repeatedPublicImportMessage[0].e, -999999)
            XCTAssertEqual(message.repeatedPublicImportMessage[1].e, 999999)
        } catch {
            XCTFail("Presented error: \(error)")
        }

        assertTextDecodeFails("repeated_public_import_message: a\n")
    }

    func testEncoding_oneofUint32() {
        var a = MessageTestType()
        a.oneofUint32 = 99

        XCTAssertEqual("oneof_uint32: 99\n", try a.serializeText())

        assertTextEncode("oneof_uint32: 99\n") {(o: inout MessageTestType) in o.oneofUint32 = 99 }

        assertTextDecodeFails("oneof_uint32: a\n")
    }

    //
    // Multiple fields at once
    //

    func testMultipleFields() {
        let expected: String = ("single_int32: 1\n"
            + "single_int64: 2\n"
            + "single_uint32: 3\n"
            + "single_uint64: 4\n"
            + "single_sint32: 5\n"
            + "single_sint64: 6\n"
            + "single_fixed32: 7\n"
            + "single_fixed64: 8\n"
            + "single_sfixed32: 9\n"
            + "single_sfixed64: 10\n"
            + "single_float: 11\n"
            + "single_double: 12\n"
            + "single_bool: true\n"
            + "single_string: \"abc\"\n"
            + "single_bytes: \"AB\"\n"
            + "single_nested_message {\n"
            + "  bb: 7\n"
            + "}\n"
            + "single_foreign_message {\n"
            + "  c: 88\n"
            + "}\n"
            + "single_import_message {\n"
            + "  d: -9\n"
            + "}\n"
            + "single_nested_enum: BAZ\n"
            + "single_foreign_enum: FOREIGN_BAZ\n"
            + "single_import_enum: IMPORT_BAZ\n"
            + "single_public_import_message {\n"
            + "  e: -999999\n"
            + "}\n"
            + "repeated_int32: 1\n"
            + "repeated_int32: 2\n"
            + "repeated_int64: 3\n"
            + "repeated_int64: 4\n"
            + "repeated_uint32: 5\n"
            + "repeated_uint32: 6\n"
            + "repeated_uint64: 7\n"
            + "repeated_uint64: 8\n"
            + "repeated_sint32: 9\n"
            + "repeated_sint32: 10\n"
            + "repeated_sint64: 11\n"
            + "repeated_sint64: 12\n"
            + "repeated_fixed32: 13\n"
            + "repeated_fixed32: 14\n"
            + "repeated_fixed64: 15\n"
            + "repeated_fixed64: 16\n"
            + "repeated_sfixed32: 17\n"
            + "repeated_sfixed32: 18\n"
            + "repeated_sfixed64: 19\n"
            + "repeated_sfixed64: 20\n"
            + "repeated_float: 21\n"
            + "repeated_float: 22\n"
            + "repeated_double: 23\n"
            + "repeated_double: 24\n"
            + "repeated_bool: true\n"
            + "repeated_bool: false\n"
            + "repeated_string: \"abc\"\n"
            + "repeated_string: \"def\"\n"
            + "repeated_bytes: \"\"\n"
            + "repeated_bytes: \"AB\"\n"
            + "repeated_nested_message {\n"
            + "  bb: 7\n"
            + "}\n"
            + "repeated_nested_message {\n"
            + "  bb: -7\n"
            + "}\n"
            + "repeated_foreign_message {\n"
            + "  c: 88\n"
            + "}\n"
            + "repeated_foreign_message {\n"
            + "  c: -88\n"
            + "}\n"
            + "repeated_import_message {\n"
            + "  d: -9\n"
            + "}\n"
            + "repeated_import_message {\n"
            + "  d: 999999\n"
            + "}\n"
            + "repeated_nested_enum: BAR\n"
            + "repeated_nested_enum: BAZ\n"
            + "repeated_foreign_enum: FOREIGN_BAR\n"
            + "repeated_foreign_enum: FOREIGN_BAZ\n"
            + "repeated_import_enum: IMPORT_BAR\n"
            + "repeated_import_enum: IMPORT_BAZ\n"
            + "repeated_public_import_message {\n"
            + "  e: -999999\n"
            + "}\n"
            + "repeated_public_import_message {\n"
            + "  e: 999999\n"
            + "}\n"
            + "oneof_uint32: 99\n")

        assertTextEncode(expected) {(o: inout MessageTestType) in
            o.singleInt32 = 1
            o.singleInt64 = 2
            o.singleUint32 = 3
            o.singleUint64 = 4
            o.singleSint32 = 5
            o.singleSint64 = 6
            o.singleFixed32 = 7
            o.singleFixed64 = 8
            o.singleSfixed32 = 9
            o.singleSfixed64 = 10
            o.singleFloat = 11
            o.singleDouble = 12
            o.singleBool = true
            o.singleString = "abc"
            o.singleBytes = Data(bytes: [65, 66])
            var nested = MessageTestType.NestedMessage()
            nested.bb = 7
            o.singleNestedMessage = nested
            var foreign = Proto3ForeignMessage()
            foreign.c = 88
            o.singleForeignMessage = foreign
            var importMessage = Proto3ImportMessage()
            importMessage.d = -9
            o.singleImportMessage = importMessage
            o.singleNestedEnum = .baz
            o.singleForeignEnum = .foreignBaz
            o.singleImportEnum = .importBaz
            var publicImportMessage = Proto3PublicImportMessage()
            publicImportMessage.e = -999999
            o.singlePublicImportMessage = publicImportMessage
            o.repeatedInt32 = [1, 2]
            o.repeatedInt64 = [3, 4]
            o.repeatedUint32 = [5, 6]
            o.repeatedUint64 = [7, 8]
            o.repeatedSint32 = [9, 10]
            o.repeatedSint64 = [11, 12]
            o.repeatedFixed32 = [13, 14]
            o.repeatedFixed64 = [15, 16]
            o.repeatedSfixed32 = [17, 18]
            o.repeatedSfixed64 = [19, 20]
            o.repeatedFloat = [21, 22]
            o.repeatedDouble = [23, 24]
            o.repeatedBool = [true, false]
            o.repeatedString = ["abc", "def"]
            o.repeatedBytes = [Data(), Data(bytes: [65, 66])]
            var nested2 = nested
            nested2.bb = -7
            o.repeatedNestedMessage = [nested, nested2]
            var foreign2 = foreign
            foreign2.c = -88
            o.repeatedForeignMessage = [foreign, foreign2]
            var importMessage2 = importMessage
            importMessage2.d = 999999
            o.repeatedImportMessage = [importMessage, importMessage2]
            o.repeatedNestedEnum = [.bar, .baz]
            o.repeatedForeignEnum = [.foreignBar, .foreignBaz]
            o.repeatedImportEnum = [.importBar, .importBaz]
            var publicImportMessage2 = publicImportMessage
            publicImportMessage2.e = 999999
            o.repeatedPublicImportMessage = [publicImportMessage, publicImportMessage2]
            o.oneofUint32 = 99
        }
    }
}
