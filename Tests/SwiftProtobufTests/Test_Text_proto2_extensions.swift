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

class Test_Text_proto2_extensions: XCTestCase, PBTestHelpers {
    typealias MessageTestType = ProtobufUnittest_TestAllExtensions
    
    func test_file_level_extension() {
        assertTextEncode("[protobuf_unittest.optional_int32_extension]: 789\n",
                         extensions: ProtobufUnittest_Unittest_Extensions) {
            (o: inout MessageTestType) in
            o.ProtobufUnittest_optionalInt32Extension = 789
        }
        // Fails if we don't provide the extensions to the decoder:
        assertTextDecodeFails("[protobuf_unittest.optional_int32_extension]: 789\n")
        
        assertTextEncode("[protobuf_unittest.OptionalGroup_extension] {\n  a: 789\n}\n",
                         extensions: ProtobufUnittest_Unittest_Extensions) {
            (o: inout MessageTestType) in
            o.ProtobufUnittest_optionalGroupExtension = ProtobufUnittest_OptionalGroup_extension.with {$0.a = 789}
        }
        // Fails if we don't provide the extensions to the decoder:
        assertTextDecodeFails("[protobuf_unittest.OptionalGroup_extension] {\n  a: 789\n}\n")
    }
    
    func test_nested_extension() {
        assertTextEncode("[protobuf_unittest.TestNestedExtension.test]: \"foo\"\n",
                         extensions: ProtobufUnittest_Unittest_Extensions) {
            (o: inout MessageTestType) in
            o.ProtobufUnittest_TestNestedExtension_test = "foo"
        }
        // Fails if we don't provide the extensions to the decoder:
        assertTextDecodeFails("[protobuf_unittest.TestNestedExtension.test]: \"foo\"\n")
    }
}
