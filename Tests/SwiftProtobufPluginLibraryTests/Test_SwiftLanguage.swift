// Tests/SwiftProtobufPluginLibraryTests/Test_SwiftLanguage.swift - Test language utilities
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Tests for tools to ensure identifiers are valid in Swift or protobuf{2,3}.
///
// -----------------------------------------------------------------------------

import XCTest
import SwiftProtobufPluginLibrary

final class Test_SwiftLanguage: XCTestCase {
    func testIsValidSwiftIdentifier() {
        let cases = [
            "H9000",
            "\u{1f436}\u{1f431}",
        ]
        for identifier in cases {
            XCTAssertTrue(isValidSwiftIdentifier(identifier, allowQuoted: false),
                          "Should be valid: \(identifier)")
        }
        let quotedCases = cases.map {return "`\($0)`"}
        for identifier in quotedCases {
            XCTAssertFalse(isValidSwiftIdentifier(identifier, allowQuoted: false),
                          "Should NOT be valid: \(identifier)")
        }
        for identifier in cases + quotedCases {
            XCTAssertTrue(isValidSwiftIdentifier(identifier, allowQuoted: true),
                          "Should be valid: \(identifier)")
        }
    }

    func testIsNotValidSwiftIdentifier() {
        let cases = [
            "_",
            "$0",
            "$f00",
            "12Hour",
            "This is bad",
        ]
        for identifier in cases {
            XCTAssertFalse(isValidSwiftIdentifier(identifier, allowQuoted: false),
                           "Should NOT be valid: \(identifier)")
        }
        let quotedCases = cases.map {return "`\($0)`"}
        for identifier in cases + quotedCases {
            XCTAssertFalse(isValidSwiftIdentifier(identifier, allowQuoted: false),
                           "Should NOT be valid: \(identifier)")
        }
        for identifier in cases + quotedCases {
            XCTAssertFalse(isValidSwiftIdentifier(identifier, allowQuoted: true),
                           "Should NOT be valid: \(identifier)")
        }

        let badQuotes = [
            "`H9000",
            "H9000`",
            "``H9000",
            "H9000``",
            "``H9000`",
            "``H9000``",
        ]
        for identifier in badQuotes {
            XCTAssertFalse(isValidSwiftIdentifier(identifier, allowQuoted: true),
                           "Should NOT be valid: \(identifier)")
        }
    }
}
