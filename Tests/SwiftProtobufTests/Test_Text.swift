// Test/Sources/TestSuite/Test_Test.swift - Exercise text format coding
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

class Test_Text: XCTestCase, PBTestHelpers {
    typealias MessageTestType = Proto3TestAllTypes

    func testSerialization() {
        var a = MessageTestType()
        a.singleInt32 = 41

        XCTAssertEqual("{\"singleInt32\":41}", try a.serializeJSON())
        XCTAssertEqual("single_int32: 41\n", try a.serializeText())

        a.singleFloat = 11

        XCTAssertEqual("{\"singleInt32\":41,\"singleFloat\":11}", try a.serializeJSON())
        XCTAssertEqual("single_int32: 41\n" + "single_float: 11\n", try a.serializeText())
        
        var nested = MessageTestType.NestedMessage()
        nested.bb = 7
        a.singleNestedMessage = nested

        XCTAssertEqual("single_int32: 41\n" + "single_float: 11\n" + "single_nested_message {\n" + "  bb: 7\n" + "}\n", try a.serializeText())
    }

    func testDeserialization() {
        do {
            let messageTest1 = try MessageTestType(json:"{\"singleInt32\":41}")
            XCTAssertEqual(messageTest1.singleInt32, 41)
            
            let messageTest2 = try MessageTestType(json:"{\"singleInt32\":41,\"singleFloat\":11}")
            XCTAssertEqual(messageTest2.singleInt32, 41)
            XCTAssertEqualWithAccuracy(messageTest2.singleFloat, 11.0, accuracy:0.01)
        } catch {
            XCTFail("Parsing should not have failed, error: \(error)")
        }

        do {
            let messageTest1 = try MessageTestType(text:"single_int32: 41\n")
            XCTAssertEqual(messageTest1.singleInt32, 41)
            
            let messageTest2 = try MessageTestType(text:"single_int32: 41\n" + "single_float: 11\n")
            XCTAssertEqual(messageTest2.singleInt32, 41)
            XCTAssertEqualWithAccuracy(messageTest2.singleFloat, 11.0, accuracy:0.01)
            
            let messageTest3 = try MessageTestType(text:"single_int32: 41\n" + "single_nested_message {\n" + "  bb: 7\n" + "}\n" + "single_float: 11\n")
            print("MESSAGE: \n\(try messageTest3.serializeText())")

            XCTAssertEqual(messageTest3.singleInt32, 41)
            XCTAssertEqualWithAccuracy(messageTest3.singleFloat, 11.0, accuracy:0.01)
            XCTAssertEqual(messageTest3.singleNestedMessage.bb, 7)
        } catch {
            XCTFail("Parsing should not have failed, error: \(error)")
        }

    }

    

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
            + "single_bytes: \"QUI=\"\n" // TODO: Not sure if this part is correct
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
            + "repeated_bytes: \"QUI=\"\n" // TODO: Not sure if this is correct
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
