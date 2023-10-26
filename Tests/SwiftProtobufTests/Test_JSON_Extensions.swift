// Tests/SwiftProtobufTests/Test_JSON_Extensions.swift - Exercise proto2 extensions
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Test support for Proto2 extensions in JSON
///
// -----------------------------------------------------------------------------

import Foundation
import XCTest
import SwiftProtobuf

final class Test_JSON_Extensions: XCTestCase, PBTestHelpers {
    typealias MessageTestType = SwiftProtoTesting_TestAllExtensions
    var extensions = SwiftProtobuf.SimpleExtensionMap()

    override func setUp() {
        // Start with all the extensions from the unittest.proto file:
        extensions = SwiftProtoTesting_Unittest_Extensions
        // Append another file's worth:
        extensions.formUnion(SwiftProtoTesting_Extend_UnittestSwiftExtension_Extensions)
        // Append an array of extensions
        extensions.insert(contentsOf:
            [
                Extensions_RepeatedExtensionGroup,
                Extensions_ExtensionGroup
            ]
        )
    }

    func test_optionalInt32Extension() throws {
        assertJSONEncode("{\"[swift_proto_testing.optional_int32_extension]\":17}",
                         extensions: extensions) {
            (o: inout MessageTestType) in
            o.SwiftProtoTesting_optionalInt32Extension = 17
        }

        assertJSONDecodeFails("{\"[swift_proto_testing.UNKNOWN_EXTENSION]\":17}",
                         extensions: extensions)
        assertJSONDecodeFails("{\"[UNKNOWN_PACKAGE.optional_int32_extension]\":17}",
                         extensions: extensions)
        assertJSONDecodeFails("{\"[swift_proto_testing.optional_int32_extension\":17}",
                         extensions: extensions)
        assertJSONDecodeFails("{\"swift_proto_testing.optional_int32_extension]\":17}",
                         extensions: extensions)
        assertJSONDecodeFails("{\"[optional_int32_extension\":17}",
                         extensions: extensions)
        assertJSONDecodeFails("{\"swift_proto_testing.optional_int32_extension\":17}",
                         extensions: extensions)

        assertJSONArrayEncode("[{\"[swift_proto_testing.optional_int32_extension]\":17}]",
                         extensions: extensions) {
            (o: inout [MessageTestType]) in
            var o1 = MessageTestType()
            o1.SwiftProtoTesting_optionalInt32Extension = 17
            o.append(o1)
        }
    }

    func test_optionalMessageExtension() throws {
        assertJSONEncode("{\"[swift_proto_testing.optional_nested_message_extension]\":{\"bb\":12}}",
            extensions: extensions)
        {
            (o: inout MessageTestType) in
            o.SwiftProtoTesting_optionalNestedMessageExtension =
                SwiftProtoTesting_TestAllTypes.NestedMessage.with {
                    $0.bb = 12
                }
        }
    }

    func test_repeatedInt32Extension() throws {
        assertJSONEncode("{\"[swift_proto_testing.repeated_int32_extension]\":[1,2,3,17]}",
                         extensions: extensions) {
            (o: inout MessageTestType) in
            o.SwiftProtoTesting_repeatedInt32Extension = [1,2,3,17]
        }
    }

    func test_repeatedMessageExtension() throws {
        assertJSONEncode("{\"[swift_proto_testing.repeated_nested_message_extension]\":[{\"bb\":12},{}]}",
            extensions: extensions)
        {
            (o: inout MessageTestType) in
            o.SwiftProtoTesting_repeatedNestedMessageExtension =
                [
                    SwiftProtoTesting_TestAllTypes.NestedMessage.with { $0.bb = 12 },
                    SwiftProtoTesting_TestAllTypes.NestedMessage()
                ]
        }
    }

    func test_optionalStringExtensionWithDefault() throws {
        assertJSONEncode("{\"[swift_proto_testing.default_string_extension]\":\"hi\"}", extensions: extensions)
        {
            (o: inout MessageTestType) in
            o.SwiftProtoTesting_defaultStringExtension = "hi"
        }

        assertJSONDecodeSucceeds("{}", extensions: extensions) {
            $0.SwiftProtoTesting_defaultStringExtension == "hello"
        }
    }

    func test_ArrayWithExtensions() throws {
        assertJSONArrayEncode(
            "["
              + "{\"[swift_proto_testing.optional_int32_extension]\":17},"
              + "{},"
              + "{\"[swift_proto_testing.optional_double_extension]\":1.23}"
            + "]",
            extensions: extensions)
        {
            (o: inout [MessageTestType]) in
            let o1 = MessageTestType.with {
                $0.SwiftProtoTesting_optionalInt32Extension = 17
            }
            o.append(o1)
            o.append(MessageTestType())
            let o3 = MessageTestType.with {
                $0.SwiftProtoTesting_optionalDoubleExtension = 1.23
            }
            o.append(o3)
        }
    }
}

final class Test_JSON_RecursiveNested_Extensions: XCTestCase, PBTestHelpers {
    typealias MessageTestType = SwiftProtoTesting_Extend_Msg1
    let extensions = SwiftProtoTesting_Extend_UnittestSwiftExtension_Extensions

    func test_nestedMessage() throws {
        assertJSONEncode("{\"[swift_proto_testing.extend.a_b]\":12}",
                         extensions: extensions) {
                            (o: inout MessageTestType) in
                            o.SwiftProtoTesting_Extend_aB = 12
        }

        assertJSONDecodeSucceeds("{\"[swift_proto_testing.extend.m2]\":{\"[swift_proto_testing.extend.aB]\":23}}", extensions: extensions) {
            $0.SwiftProtoTesting_Extend_m2.SwiftProtoTesting_Extend_aB == 23
        }
    }

}
