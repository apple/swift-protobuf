// ExperimentalHiddenNamesTests.swift
//
// Copyright (c) 2026 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt

import Foundation
import SwiftProtobuf
import XCTest

final class ExperimentalHiddenNamesTests: XCTestCase {
    func testFields() throws {
        var msgFields = ExperimentalHiddenNames_Fields_MessageWithFields()
        msgFields.textValue = "hello"
        msgFields.numberValue = 42

        // TextFormat will succeed without field names, printing the field numbers instead.
        XCTAssertEqual(msgFields.textFormatString(), "1: \"hello\"\n2: 42\n")

        // JSON will fail without field names.
        do {
            _ = try msgFields.jsonString()
            XCTFail("Expected jsonString() to throw due to missing field names")
        } catch JSONEncodingError.missingFieldNames {
            // Expected behavior when ExperimentalHiddenNames contains fields
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testEnumValues() throws {
        var msgEnum = ExperimentalHiddenNames_EnumValues_MessageWithEnum()
        msgEnum.value = .first

        // TextFormat and JSON both fall back to the numeric value when enum names aren't
        // available.
        XCTAssertEqual(msgEnum.textFormatString(), "value: 1\n")
        XCTAssertEqual(try msgEnum.jsonString(), "{\"value\":1}")
    }

    func testTypes() {
        _ = ExperimentalHiddenNames_Types_MessageWithTypes()
        XCTAssertEqual(ExperimentalHiddenNames_Types_MessageWithTypes.protoMessageName, "")
        XCTAssertFalse(Google_Protobuf_Any.register(messageType: ExperimentalHiddenNames_Types_MessageWithTypes.self))
    }

    func testAll() {
        var msgAll = ExperimentalHiddenNames_All_MessageWithAll()
        msgAll.fullText = "hidden"
        msgAll.enumVal = .otherValue
        XCTAssertEqual(ExperimentalHiddenNames_All_MessageWithAll.protoMessageName, "")
        XCTAssertEqual(msgAll.textFormatString(), "1: \"hidden\"\n2: 1\n")

        #if DEBUG
        let expectedDebugDesc =
            "ExperimentalHiddenNamesTests.ExperimentalHiddenNames_All_MessageWithAll:\n1: \"hidden\"\n2: 1\n"
        XCTAssertEqual(msgAll.debugDescription, expectedDebugDesc)
        #else
        XCTAssertEqual(
            msgAll.debugDescription,
            "ExperimentalHiddenNamesTests.ExperimentalHiddenNames_All_MessageWithAll"
        )
        #endif
    }
}
