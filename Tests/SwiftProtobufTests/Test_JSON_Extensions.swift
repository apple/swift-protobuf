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

        assertJSONDecodeFails("{\"[protobuf_unittest.UNKNOWN_EXTENSION]\":17}",
                         extensions: extensions)
        assertJSONDecodeFails("{\"[UNKNOWN_PACKAGE.optional_int32_extension]\":17}",
                         extensions: extensions)
        assertJSONDecodeFails("{\"[protobuf_unittest.optional_int32_extension\":17}",
                         extensions: extensions)
        assertJSONDecodeFails("{\"protobuf_unittest.optional_int32_extension]\":17}",
                         extensions: extensions)
        assertJSONDecodeFails("{\"[optional_int32_extension\":17}",
                         extensions: extensions)
        assertJSONDecodeFails("{\"protobuf_unittest.optional_int32_extension\":17}",
                         extensions: extensions)

        assertJSONArrayEncode("[{\"[protobuf_unittest.optional_int32_extension]\":17}]",
                         extensions: extensions) {
            (o: inout [MessageTestType]) in
            var o1 = MessageTestType()
            o1.ProtobufUnittest_optionalInt32Extension = 17
            o.append(o1)
        }
    }

    func test_optionalMessageExtension() throws {
        assertJSONEncode("{\"[protobuf_unittest.optional_nested_message_extension]\":{\"bb\":12}}",
            extensions: extensions)
        {
            (o: inout MessageTestType) in
            o.ProtobufUnittest_optionalNestedMessageExtension =
                ProtobufUnittest_TestAllTypes.NestedMessage.with {
                    $0.bb = 12
                }
        }
    }

    func test_repeatedInt32Extension() throws {
        assertJSONEncode("{\"[protobuf_unittest.repeated_int32_extension]\":[1,2,3,17]}",
                         extensions: extensions) {
            (o: inout MessageTestType) in
            o.ProtobufUnittest_repeatedInt32Extension = [1,2,3,17]
        }
    }

    func test_repeatedMessageExtension() throws {
        assertJSONEncode("{\"[protobuf_unittest.repeated_nested_message_extension]\":[{\"bb\":12},{}]}",
            extensions: extensions)
        {
            (o: inout MessageTestType) in
            o.ProtobufUnittest_repeatedNestedMessageExtension =
                [
                    ProtobufUnittest_TestAllTypes.NestedMessage.with { $0.bb = 12 },
                    ProtobufUnittest_TestAllTypes.NestedMessage()
                ]
        }
    }

    func test_optionalStringExtensionWithDefault() throws {
        assertJSONEncode("{\"[protobuf_unittest.default_string_extension]\":\"hi\"}", extensions: extensions)
        {
            (o: inout MessageTestType) in
            o.ProtobufUnittest_defaultStringExtension = "hi"
        }

        assertJSONDecodeSucceeds("{}", extensions: extensions) {
            $0.ProtobufUnittest_defaultStringExtension == "hello"
        }
    }

    func test_ArrayWithExtensions() throws {
        assertJSONArrayEncode(
            "["
              + "{\"[protobuf_unittest.optional_int32_extension]\":17},"
              + "{},"
              + "{\"[protobuf_unittest.optional_double_extension]\":1.23}"
            + "]",
            extensions: extensions)
        {
            (o: inout [MessageTestType]) in
            let o1 = MessageTestType.with {
                $0.ProtobufUnittest_optionalInt32Extension = 17
            }
            o.append(o1)
            o.append(MessageTestType())
            let o3 = MessageTestType.with {
                $0.ProtobufUnittest_optionalDoubleExtension = 1.23
            }
            o.append(o3)
        }
    }
}

class Test_JSON_RecursiveNested_Extensions: XCTestCase, PBTestHelpers {
    typealias MessageTestType = ProtobufUnittest_Extend_Msg1
    let extensions = ProtobufUnittest_Extend_UnittestSwiftExtension_Extensions
    
    func test_nestedMessage() throws {
        assertJSONEncode("{\"[protobuf_unittest.extend.a_b]\":12}",
                         extensions: extensions) {
                            (o: inout MessageTestType) in
                            o.ProtobufUnittest_Extend_aB = 12
        }
        
        assertJSONDecodeSucceeds("{\"[protobuf_unittest.extend.m2]\":{\"[protobuf_unittest.extend.aB]\":23}}", extensions: extensions) {
            $0.ProtobufUnittest_Extend_m2.ProtobufUnittest_Extend_aB == 23
        }
    }
    
}
