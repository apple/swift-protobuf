// Test/Sources/TestSuite/Test_Api.swift - Exercise API type
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
/// Since API is purely compiled (there is no hand-coding
/// in it) this is a fairly thin test just to ensure that the proto
/// does get into the runtime.
///
// -----------------------------------------------------------------------------

import Foundation
import XCTest
import SwiftProtobuf

class Test_Api: XCTestCase, PBTestHelpers {
    typealias MessageTestType = Google_Protobuf_Api

    func testExists() {
        assertEncode([10,7,97,112,105,78,97,109,101,34,1,49]) { (o: inout MessageTestType) in
            o.name = "apiName"
            o.version = "1"
        }
    }

    func testInitializer() {
        let m = MessageTestType(
            name: "apiName",
            methods: [Google_Protobuf_Method(name: "method1")],
            options: [Google_Protobuf_Option(name: "option1", value: Google_Protobuf_Any(message: Google_Protobuf_StringValue("value1")))],
            version: "1.0.0",
            syntax: .proto3)

        XCTAssertEqual(try m.serializeJSON(), "{\"name\":\"apiName\",\"methods\":[{\"name\":\"method1\"}],\"options\":[{\"name\":\"option1\",\"value\":{\"@type\":\"type.googleapis.com/google.protobuf.StringValue\",\"value\":\"value1\"}}],\"version\":\"1.0.0\",\"syntax\":\"SYNTAX_PROTO3\"}")
    }
}

