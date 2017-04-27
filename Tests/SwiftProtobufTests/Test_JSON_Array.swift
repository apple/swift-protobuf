// Tests/SwiftProtobufTests/Test_JSON_Array.swift - Exercise JSON flat array coding
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// JSON is a major new feature for Proto3.  This test suite exercises
/// the JSON coding for all primitive types, including boundary and error
/// cases.
///
// -----------------------------------------------------------------------------

import Foundation
import XCTest
import SwiftProtobuf

class Test_JSON_Array: XCTestCase, PBTestHelpers {
    typealias MessageTestType = Proto3TestAllTypes

    private func configureTwoObjects(_ o: inout [MessageTestType]) {
        var o1 = MessageTestType()
        o1.singleInt32 = 1
        o1.singleInt64 = 2
        o1.singleUint32 = 3
        o1.singleUint64 = 4
        o1.singleSint32 = 5
        o1.singleSint64 = 6
        o1.singleFixed32 = 7
        o1.singleFixed64 = 8
        o1.singleSfixed32 = 9
        o1.singleSfixed64 = 10
        o1.singleFloat = 11
        o1.singleDouble = 12
        o1.singleBool = true
        o1.singleString = "abc"
        o1.singleBytes = Data(bytes: [65, 66])
        var nested = MessageTestType.NestedMessage()
        nested.bb = 7
        o1.singleNestedMessage = nested
        var foreign = Proto3ForeignMessage()
        foreign.c = 88
        o1.singleForeignMessage = foreign
        var importMessage = Proto3ImportMessage()
        importMessage.d = -9
        o1.singleImportMessage = importMessage
        o1.singleNestedEnum = .baz
        o1.singleForeignEnum = .foreignBaz
        o1.singleImportEnum = .importBaz
        var publicImportMessage = Proto3PublicImportMessage()
        publicImportMessage.e = -999999
        o1.singlePublicImportMessage = publicImportMessage
        o1.repeatedInt32 = [1, 2]
        o1.repeatedInt64 = [3, 4]
        o1.repeatedUint32 = [5, 6]
        o1.repeatedUint64 = [7, 8]
        o1.repeatedSint32 = [9, 10]
        o1.repeatedSint64 = [11, 12]
        o1.repeatedFixed32 = [13, 14]
        o1.repeatedFixed64 = [15, 16]
        o1.repeatedSfixed32 = [17, 18]
        o1.repeatedSfixed64 = [19, 20]
        o1.repeatedFloat = [21, 22]
        o1.repeatedDouble = [23, 24]
        o1.repeatedBool = [true, false]
        o1.repeatedString = ["abc", "def"]
        o1.repeatedBytes = [Data(), Data(bytes: [65, 66])]
        var nested2 = nested
        nested2.bb = -7
        o1.repeatedNestedMessage = [nested, nested2]
        var foreign2 = foreign
        foreign2.c = -88
        o1.repeatedForeignMessage = [foreign, foreign2]
        var importMessage2 = importMessage
        importMessage2.d = 999999
        o1.repeatedImportMessage = [importMessage, importMessage2]
        o1.repeatedNestedEnum = [.bar, .baz]
        o1.repeatedForeignEnum = [.foreignBar, .foreignBaz]
        o1.repeatedImportEnum = [.importBar, .importBaz]
        var publicImportMessage2 = publicImportMessage
        publicImportMessage2.e = 999999
        o1.repeatedPublicImportMessage = [publicImportMessage, publicImportMessage2]
        o1.oneofUint32 = 99
        o.append(o1)

        let o2 = MessageTestType()
        o.append(o2)
    }

    func testTwoObjectsWithMultipleFields() {
        let expected: String = ("[{"
            + "\"singleInt32\":1,"
            + "\"singleInt64\":\"2\","
            + "\"singleUint32\":3,"
            + "\"singleUint64\":\"4\","
            + "\"singleSint32\":5,"
            + "\"singleSint64\":\"6\","
            + "\"singleFixed32\":7,"
            + "\"singleFixed64\":\"8\","
            + "\"singleSfixed32\":9,"
            + "\"singleSfixed64\":\"10\","
            + "\"singleFloat\":11,"
            + "\"singleDouble\":12,"
            + "\"singleBool\":true,"
            + "\"singleString\":\"abc\","
            + "\"singleBytes\":\"QUI=\","
            + "\"singleNestedMessage\":{\"bb\":7},"
            + "\"singleForeignMessage\":{\"c\":88},"
            + "\"singleImportMessage\":{\"d\":-9},"
            + "\"singleNestedEnum\":\"BAZ\","
            + "\"singleForeignEnum\":\"FOREIGN_BAZ\","
            + "\"singleImportEnum\":\"IMPORT_BAZ\","
            + "\"singlePublicImportMessage\":{\"e\":-999999},"
            + "\"repeatedInt32\":[1,2],"
            + "\"repeatedInt64\":[\"3\",\"4\"],"
            + "\"repeatedUint32\":[5,6],"
            + "\"repeatedUint64\":[\"7\",\"8\"],"
            + "\"repeatedSint32\":[9,10],"
            + "\"repeatedSint64\":[\"11\",\"12\"],"
            + "\"repeatedFixed32\":[13,14],"
            + "\"repeatedFixed64\":[\"15\",\"16\"],"
            + "\"repeatedSfixed32\":[17,18],"
            + "\"repeatedSfixed64\":[\"19\",\"20\"],"
            + "\"repeatedFloat\":[21,22],"
            + "\"repeatedDouble\":[23,24],"
            + "\"repeatedBool\":[true,false],"
            + "\"repeatedString\":[\"abc\",\"def\"],"
            + "\"repeatedBytes\":[\"\",\"QUI=\"],"
            + "\"repeatedNestedMessage\":[{\"bb\":7},{\"bb\":-7}],"
            + "\"repeatedForeignMessage\":[{\"c\":88},{\"c\":-88}],"
            + "\"repeatedImportMessage\":[{\"d\":-9},{\"d\":999999}],"
            + "\"repeatedNestedEnum\":[\"BAR\",\"BAZ\"],"
            + "\"repeatedForeignEnum\":[\"FOREIGN_BAR\",\"FOREIGN_BAZ\"],"
            + "\"repeatedImportEnum\":[\"IMPORT_BAR\",\"IMPORT_BAZ\"],"
            + "\"repeatedPublicImportMessage\":[{\"e\":-999999},{\"e\":999999}],"
            + "\"oneofUint32\":99"
            + "},{}]")
        assertJSONArrayEncode(expected, configure: configureTwoObjects)
    }

    func testRepeatedNestedMessage() {
        assertJSONArrayEncode("[{\"repeatedNestedMessage\":[{\"bb\":1}]},{\"repeatedNestedMessage\":[{\"bb\":1},{\"bb\":2}]}]") {(o: inout [MessageTestType]) in
            var o1 = MessageTestType()
            var sub1 = Proto3TestAllTypes.NestedMessage()
            sub1.bb = 1
            o1.repeatedNestedMessage = [sub1]
            o.append(o1)

            var o2 = MessageTestType()
            var sub2 = Proto3TestAllTypes.NestedMessage()
            sub2.bb = 1
            var sub3 = Proto3TestAllTypes.NestedMessage()
            sub3.bb = 2
            o2.repeatedNestedMessage = [sub2, sub3]
            o.append(o2)
        }

        assertJSONArrayDecodeSucceeds("[{\"repeatedNestedMessage\": []}]") {
            $0[0].repeatedNestedMessage == []
        }

        assertJSONArrayDecodeFails("{\"repeatedNestedMessage\": []}")
    }
}
