// Tests/PluginLibraryTests/Test_SwiftLangauge.swift - Test language utilities
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
/// Tests for tools to ensure identifiers are valid in Swift or protobuf{2,3}.
///
// -----------------------------------------------------------------------------

import XCTest
import PluginLibrary

class Test_SwiftLanguage: XCTestCase {
    func testIsValidSwiftIdentifier() {
        for identifier in ["_", "H9000", "\u{1f436}\u{1f431}"] {
            XCTAssert(isValidSwiftIdentifier(identifier), "Should be valid: \(identifier)")
        }
    }

    func testIsNotValidSwiftIdentifier() {
        for identifier in ["$0", "$f00", "12Hour", "This is bad"] {
            XCTAssert(!isValidSwiftIdentifier(identifier), "Should not be valid: \(identifier)")
        }
    }
}
