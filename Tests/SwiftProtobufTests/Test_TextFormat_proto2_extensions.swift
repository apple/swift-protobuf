// Tests/SwiftProtobufTests/Test_TextFormat_proto2_extensions.swift - Exercise proto3 text format coding
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// This is a set of tests for text format protobuf files.
///
// -----------------------------------------------------------------------------

import Foundation
import XCTest
import SwiftProtobuf

final class Test_TextFormat_proto2_extensions: XCTestCase, PBTestHelpers {
    typealias MessageTestType = SwiftProtoTesting_TestAllExtensions

    func test_file_level_extension() {
        assertTextFormatEncode("[swift_proto_testing.optional_int32_extension]: 789\n",
                         extensions: SwiftProtoTesting_Unittest_Extensions) {
            (o: inout MessageTestType) in
            o.SwiftProtoTesting_optionalInt32Extension = 789
        }
        // Fails if we don't provide the extensions to the decoder:
        assertTextFormatDecodeFails("[swift_proto_testing.optional_int32_extension]: 789\n")

        assertTextFormatEncode("[swift_proto_testing.optionalgroup_extension] {\n  a: 789\n}\n",
                         extensions: SwiftProtoTesting_Unittest_Extensions) {
            (o: inout MessageTestType) in
            o.SwiftProtoTesting_optionalGroupExtension.a = 789
        }
        // Fails if we don't provide the extensions to the decoder:
        assertTextFormatDecodeFails("[swift_proto_testing.optionalgroup_extension] {\n  a: 789\n}\n")
    }

    func test_nested_extension() {
        assertTextFormatEncode("[swift_proto_testing.TestNestedExtension.test]: \"foo\"\n",
                         extensions: SwiftProtoTesting_Unittest_Extensions) {
            (o: inout MessageTestType) in
            o.SwiftProtoTesting_TestNestedExtension_test = "foo"
        }
        // Fails if we don't provide the extensions to the decoder:
        assertTextFormatDecodeFails("[swift_proto_testing.TestNestedExtension.test]: \"foo\"\n")
    }
}
