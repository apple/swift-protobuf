// Test/Sources/TestSuite/Test_Empty.swift - Verify well-known empty message
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
/// Since Empty is purely compiled (there is no hand-coding
/// in it) this is a fairly thin test just to ensure that the proto
/// does get into the runtime.
///
// -----------------------------------------------------------------------------

import XCTest
import Protobuf

class Test_Empty: XCTestCase, PBTestHelpers {
    typealias MessageTestType = Google_Protobuf_Empty

    func testExists() throws {
        let e = Google_Protobuf_Empty()
        XCTAssertEqual(Data(), try e.serializeProtobuf())
    }
}
