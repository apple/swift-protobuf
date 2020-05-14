// Tests/SwiftProtobufTests/Test_JSON_Extensions.swift - Exercise proto2 extensions
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Test support for Proto2 extensions in JSON
///
// -----------------------------------------------------------------------------

import Foundation
import XCTest
import SwiftProtobuf

class Test_JSON_Extensions: XCTestCase, PBTestHelpers {
    typealias MessageTestType = ProtobufUnittest_TestAllExtensions
    var extensions = SwiftProtobuf.SimpleExtensionMap()

    override func setUp() {
        // Start with all the extensions from the unittest.proto file:
        extensions = ProtobufUnittest_Unittest_Extensions
        // Append another file's worth:
        extensions.formUnion(ProtobufUnittest_UnittestCustomOptions_Extensions)
        // Append an array of extensions
        extensions.insert(contentsOf:
            [
                Extensions_RepeatedExtensionGroup,
                Extensions_ExtensionGroup
            ]
        )
    }

    func test_optionalInt32Extension() throws {
        assertJSONEncode("{\"[protobuf_unittest.optional_int32_extension]\":17}",
                         extensions: extensions) {
            (o: inout MessageTestType) in
            o.ProtobufUnittest_optionalInt32Extension = 17
        }
    }

}
