// Tests/SwiftProtobufTests/Test_Any.swift - Verify well-known Any type
//
// Copyright (c) 2014 - 2019 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Any is tricky.  Some of the more interesting cases:
/// * Transcoding protobuf to/from JSON with or without the schema being known
/// * Any fields that contain well-known or user-defined types
/// * Any fields that contain Any fields
///
// -----------------------------------------------------------------------------

import Foundation
import SwiftProtobuf
import XCTest

final class Test_Any: XCTestCase {

    func test_Any() throws {
        var content = SwiftProtoTesting_TestAllTypes()
        content.optionalInt32 = 7

        var m = SwiftProtoTesting_TestAny()
        m.int32Value = 12
        m.anyValue = try Google_Protobuf_Any(packing: content)

        // The Any holding an object can be JSON serialized
        XCTAssertNotNil(try m.jsonString())

        let encoded: [UInt8] = try m.serializedBytes()
        XCTAssertEqual(
            encoded,
            [
                8, 12, 18, 58, 10, 52, 116, 121, 112, 101, 46, 103, 111, 111, 103, 108, 101, 97, 112, 105, 115, 46, 99,
                111, 109, 47, 115, 119, 105, 102, 116, 95, 112, 114, 111, 116, 111, 95, 116, 101, 115, 116, 105, 110,
                103, 46, 84, 101, 115, 116, 65, 108, 108, 84, 121, 112, 101, 115, 18, 2, 8, 7,
            ]
        )
        let decoded = try SwiftProtoTesting_TestAny(serializedBytes: encoded)
        XCTAssertEqual(decoded.anyValue.typeURL, "type.googleapis.com/swift_proto_testing.TestAllTypes")
        XCTAssertEqual(decoded.anyValue.value, Data([8, 7]))
        XCTAssertEqual(decoded.int32Value, 12)
        XCTAssertNotNil(decoded.anyValue)
        let any = decoded.anyValue
        do {
            let extracted = try SwiftProtoTesting_TestAllTypes(unpackingAny: any)
            XCTAssertEqual(extracted.optionalInt32, 7)
        } catch {
            XCTFail("Failed to unpack \(any)")
        }

        XCTAssertThrowsError(try SwiftProtoTesting_TestEmptyMessage(unpackingAny: any))
        let recoded: [UInt8] = try decoded.serializedBytes()
        XCTAssertEqual(encoded, recoded)
    }

    /// The typeURL prefix should be ignored for purposes of determining the actual type.
    /// The prefix is only used for dynamically loading type data from a remote server
    /// (There are currently no such servers, and no plans to build any.)
    ///
    /// This test verifies that we can decode an Any with a different prefix
    func test_Any_different_prefix() throws {
        let encoded: [UInt8] = [
            8, 12, 18, 42, 10, 36, 88, 47, 89, 47, 115, 119, 105, 102, 116, 95, 112, 114, 111, 116, 111, 95, 116, 101,
            115, 116, 105, 110, 103, 46, 84, 101, 115, 116, 65, 108, 108, 84, 121, 112, 101, 115, 18, 2, 8, 7,
        ]
        let decoded: SwiftProtoTesting_TestAny
        do {
            decoded = try SwiftProtoTesting_TestAny(serializedBytes: encoded)
        } catch {
            XCTFail("Failed to decode \(encoded): \(error)")
            return
        }
        XCTAssertEqual(decoded.anyValue.typeURL, "X/Y/swift_proto_testing.TestAllTypes")
        XCTAssertEqual(decoded.anyValue.value, Data([8, 7]))
        XCTAssertEqual(decoded.int32Value, 12)
        XCTAssertNotNil(decoded.anyValue)
        let any = decoded.anyValue
        do {
            let extracted = try SwiftProtoTesting_TestAllTypes(unpackingAny: any)
            XCTAssertEqual(extracted.optionalInt32, 7)
        } catch {
            XCTFail("Failed to unpack \(any)")
        }

        XCTAssertThrowsError(try SwiftProtoTesting_TestEmptyMessage(unpackingAny: any))
        let recoded: [UInt8] = try decoded.serializedBytes()
        XCTAssertEqual(encoded, recoded)
    }

    /// The typeURL prefix should be ignored for purposes of determining the actual type.
    /// The prefix is only used for dynamically loading type data from a remote server
    /// (There are currently no such servers, and no plans to build any.)
    ///
    /// This test verifies that we can decode an Any with an empty prefix
    func test_Any_noprefix() throws {
        let encoded: [UInt8] = [
            8, 12, 18, 39, 10, 33, 47, 115, 119, 105, 102, 116, 95, 112, 114, 111, 116, 111, 95, 116, 101, 115, 116,
            105, 110, 103, 46, 84, 101, 115, 116, 65, 108, 108, 84, 121, 112, 101, 115, 18, 2, 8, 7,
        ]
        let decoded: SwiftProtoTesting_TestAny
        do {
            decoded = try SwiftProtoTesting_TestAny(serializedBytes: encoded)
        } catch {
            XCTFail("Failed to decode \(encoded): \(error)")
            return
        }
        XCTAssertEqual(decoded.anyValue.typeURL, "/swift_proto_testing.TestAllTypes")
        XCTAssertEqual(decoded.anyValue.value, Data([8, 7]))
        XCTAssertEqual(decoded.int32Value, 12)
        XCTAssertNotNil(decoded.anyValue)
        let any = decoded.anyValue
        do {
            let extracted = try SwiftProtoTesting_TestAllTypes(unpackingAny: any)
            XCTAssertEqual(extracted.optionalInt32, 7)
        } catch {
            XCTFail("Failed to unpack \(any)")
        }

        XCTAssertThrowsError(try SwiftProtoTesting_TestEmptyMessage(unpackingAny: any))
        let recoded: [UInt8] = try decoded.serializedBytes()
        XCTAssertEqual(encoded, recoded)
    }

    /// Though Google discourages this, we should be able to match and decode an Any
    /// if the typeURL holds just the type name:
    func test_Any_shortesttype() throws {
        let encoded: [UInt8] = [
            8, 12, 18, 38, 10, 32, 115, 119, 105, 102, 116, 95, 112, 114, 111, 116, 111, 95, 116, 101, 115, 116, 105,
            110, 103, 46, 84, 101, 115, 116, 65, 108, 108, 84, 121, 112, 101, 115, 18, 2, 8, 7,
        ]
        let decoded: SwiftProtoTesting_TestAny
        do {
            decoded = try SwiftProtoTesting_TestAny(serializedBytes: encoded)
        } catch {
            XCTFail("Failed to decode \(encoded): \(error)")
            return
        }
        XCTAssertEqual(decoded.anyValue.typeURL, "swift_proto_testing.TestAllTypes")
        XCTAssertEqual(decoded.anyValue.value, Data([8, 7]))
        XCTAssertEqual(decoded.int32Value, 12)
        XCTAssertNotNil(decoded.anyValue)
        let any = decoded.anyValue
        do {
            let extracted = try SwiftProtoTesting_TestAllTypes(unpackingAny: any)
            XCTAssertEqual(extracted.optionalInt32, 7)
        } catch {
            XCTFail("Failed to unpack \(any)")
        }

        XCTAssertThrowsError(try SwiftProtoTesting_TestEmptyMessage(unpackingAny: any))
        let recoded: [UInt8] = try decoded.serializedBytes()
        XCTAssertEqual(encoded, recoded)
    }

    func test_Any_UserMessage() throws {
        Google_Protobuf_Any.register(messageType: SwiftProtoTesting_TestAllTypes.self)
        var content = SwiftProtoTesting_TestAllTypes()
        content.optionalInt32 = 7

        var m = SwiftProtoTesting_TestAny()
        m.int32Value = 12
        m.anyValue = try Google_Protobuf_Any(packing: content)

        let encoded = try m.jsonString()
        XCTAssertEqual(
            encoded,
            "{\"int32Value\":12,\"anyValue\":{\"@type\":\"type.googleapis.com/swift_proto_testing.TestAllTypes\",\"optionalInt32\":7}}"
        )
        do {
            let decoded = try SwiftProtoTesting_TestAny(jsonString: encoded)
            XCTAssertNotNil(decoded.anyValue)
            XCTAssertEqual(Data([8, 7]), decoded.anyValue.value)
            XCTAssertEqual(decoded.int32Value, 12)
            XCTAssertNotNil(decoded.anyValue)
            let any = decoded.anyValue
            do {
                let extracted = try SwiftProtoTesting_TestAllTypes(unpackingAny: any)
                XCTAssertEqual(extracted.optionalInt32, 7)
                XCTAssertThrowsError(try SwiftProtoTesting_TestEmptyMessage(unpackingAny: any))
            } catch {
                XCTFail("Failed to unpack \(any)")
            }
            let recoded = try decoded.jsonString()
            XCTAssertEqual(encoded, recoded)
            XCTAssertEqual(
                [
                    8, 12, 18, 58, 10, 52, 116, 121, 112, 101, 46, 103, 111, 111, 103, 108, 101, 97, 112, 105, 115, 46,
                    99, 111, 109, 47, 115, 119, 105, 102, 116, 95, 112, 114, 111, 116, 111, 95, 116, 101, 115, 116, 105,
                    110, 103, 46, 84, 101, 115, 116, 65, 108, 108, 84, 121, 112, 101, 115, 18, 2, 8, 7,
                ],
                try decoded.serializedBytes()
            )
        } catch {
            XCTFail("Failed to decode \(encoded)")
        }
    }

    func test_Any_UnknownUserMessage_JSON() throws {
        Google_Protobuf_Any.register(messageType: SwiftProtoTesting_TestAllTypes.self)
        let start = "{\"int32Value\":12,\"anyValue\":{\"@type\":\"type.googleapis.com/UNKNOWN\",\"optionalInt32\":7}}"
        XCTAssertThrowsError(try SwiftProtoTesting_TestAny(jsonString: start))
    }

    func test_Any_UnknownUserMessage_JSONStringValidation() throws {
        // Valid escapes, surrogate pairs, and nested containers decode and re-encode cleanly.
        let validInputs: [String] = [
            "{\"@type\":\"type.googleapis.com/example.Unregistered\",\"s\":\"\"}",
            "{\"@type\":\"type.googleapis.com/example.Unregistered\",\"s\":\"plain string longer than inline capacity\"}",
            "{\"@type\":\"type.googleapis.com/example.Unregistered\",\"s\":\"\\\"\\\\\\/\\b\\f\\n\\r\\t\"}",
            "{\"@type\":\"type.googleapis.com/example.Unregistered\",\"s\":\"\\u0000\\u0041\\u00e9\\uffff\"}",
            "{\"@type\":\"type.googleapis.com/example.Unregistered\",\"s\":\"\\ud83d\\ude00\\uD834\\uDD1E\"}",
            "{\"@type\":\"type.googleapis.com/example.Unregistered\",\"nested\":{\"k\\n\":[\"a\\\"b\",\"\\u00e9\",\"\\ud83d\\ude00\",{\"inner\":\"ok\\t!\"}]}}",
        ]
        for json in validInputs {
            let decoded = try Google_Protobuf_Any(jsonString: json)
            let recoded = try decoded.jsonString()
            XCTAssertEqual(recoded, json, "Round-trip mismatch for \(json)")
        }

        // Malformed escapes, broken surrogates, and unescaped C0 controls are rejected
        // in top-level values, nested arrays, nested object values, and nested object keys.
        let invalidPayloads: [String] = [
            // Malformed escapes
            "\"bad\\qescape\"",
            "\"bad\\x41hex\"",
            "\"short\\u12\"",
            "\"nonhex\\u123g\"",
            "\"upper\\U0041\"",
            // Unpaired and misordered surrogates
            "\"\\ud800\"",
            "\"\\udc00\"",
            "\"\\ude00\\ud83d\"",
            "\"\\ud800\\u0041\"",
            "\"\\ud800\\ud800\"",
            "\"\\ud800\\u123\"",
            // Unescaped C0 control characters (including immediately after backslash)
            "\"a\u{00}b\"",
            "\"a\u{01}b\"",
            "\"a\u{09}b\"",
            "\"a\u{0a}b\"",
            "\"a\u{1f}b\"",
            "\"a\\\u{01}b\"",
            "\"a\\\u{00}b\"",
            "\"a\\\\\u{01}b\"",
            // Nested array and object values
            "[\"ok\",\"bad\\q\"]",
            "[\"ok\",\"\\ud800\"]",
            "{\"inner\":\"bad\\x41\"}",
            "{\"inner\":\"a\\\u{01}b\"}",
            // Nested object keys
            "{\"bad\\q\":1}",
            "{\"\\ude00\\ud83d\":1}",
            "{\"a\u{01}b\":1}",
            "{\"a\\\u{01}b\":1}",
        ]
        for payload in invalidPayloads {
            let json = "{\"@type\":\"type.googleapis.com/example.Unregistered\",\"v\":\(payload)}"
            XCTAssertThrowsError(try Google_Protobuf_Any(jsonString: json), "Expected failure for \(json)") { error in
                guard case JSONDecodingError.malformedString = error else {
                    XCTFail("Expected JSONDecodingError.malformedString for \(json), got \(error)")
                    return
                }
            }
        }

        // Valid raw UTF-8 bytes succeed via jsonUTF8Bytes.
        let validUTF8Payloads: [[UInt8]] = [
            [0xC3, 0xA9],  // é
            [0xF0, 0x9F, 0x98, 0x80],  // 😀
        ]
        for payloadBytes in validUTF8Payloads {
            var bytes = Array("{\"@type\":\"type.googleapis.com/example.Unregistered\",\"v\":\"".utf8)
            bytes.append(contentsOf: payloadBytes)
            bytes.append(contentsOf: "\"}".utf8)
            let decoded = try Google_Protobuf_Any(jsonUTF8Bytes: bytes)
            XCTAssertEqual(try decoded.jsonUTF8Bytes(), bytes)
        }

        // Invalid raw UTF-8 bytes (0xFF, truncated 0xC3, UTF-8 surrogate 0xED 0xA0 0x80,
        // and invalid UTF-8 alongside a valid escape) are rejected in values, nested arrays,
        // nested object values, and nested object keys.
        let invalidUTF8Sequences: [[UInt8]] = [
            [0xFF],
            [0xC3],
            [0xED, 0xA0, 0x80],
            [UInt8(ascii: "\\"), UInt8(ascii: "n"), 0xFF],
        ]
        let utf8Containers: [(prefix: String, suffix: String)] = [
            ("{\"@type\":\"type.googleapis.com/example.Unregistered\",\"v\":\"", "\"}"),
            ("{\"@type\":\"type.googleapis.com/example.Unregistered\",\"v\":[\"ok\",\"", "\"]}"),
            ("{\"@type\":\"type.googleapis.com/example.Unregistered\",\"v\":{\"inner\":\"", "\"}}"),
            ("{\"@type\":\"type.googleapis.com/example.Unregistered\",\"v\":{\"", "\":1}}"),
        ]
        for badBytes in invalidUTF8Sequences {
            for container in utf8Containers {
                var bytes = Array(container.prefix.utf8)
                bytes.append(contentsOf: badBytes)
                bytes.append(contentsOf: container.suffix.utf8)
                XCTAssertThrowsError(try Google_Protobuf_Any(jsonUTF8Bytes: bytes)) { error in
                    guard case JSONDecodingError.malformedString = error else {
                        XCTFail("Expected JSONDecodingError.malformedString, got \(error)")
                        return
                    }
                }
            }
        }
    }

    func test_Any_UnknownUserMessage_protobuf() throws {
        Google_Protobuf_Any.register(messageType: SwiftProtoTesting_TestAllTypes.self)
        let start: [UInt8] = [
            8, 12, 18, 33, 10, 27, 116, 121, 112, 101, 46, 103, 111, 111, 103, 108, 101, 97, 112, 105, 115, 46, 99, 111,
            109, 47, 85, 78, 75, 78, 79, 87, 78, 18, 2, 8, 7,
        ]

        let decoded = try SwiftProtoTesting_TestAny(serializedBytes: start)

        // Protobuf-to-protobuf transcoding succeeds
        let recoded: [UInt8] = try decoded.serializedBytes()
        XCTAssertEqual(recoded, start)

        let anyValue = decoded.anyValue
        XCTAssertNotNil(anyValue)
        XCTAssertEqual(anyValue.typeURL, "type.googleapis.com/UNKNOWN")
        XCTAssertEqual(anyValue.value, Data([8, 7]))

        XCTAssertEqual(anyValue.textFormatString(), "type_url: \"type.googleapis.com/UNKNOWN\"\nvalue: \"\\b\\007\"\n")

        // Protobuf-to-JSON transcoding fails because the type is not registered
        XCTAssertThrowsError(try decoded.jsonString()) { error in
            XCTAssertEqual(error as? JSONEncodingError, .anyTranscodeFailure)
        }
        XCTAssertThrowsError(try decoded.jsonUTF8Bytes() as [UInt8]) { error in
            XCTAssertEqual(error as? JSONEncodingError, .anyTranscodeFailure)
        }
    }

    func test_Any_Any() throws {
        let start =
            "{\"optionalAny\":{\"@type\":\"type.googleapis.com/google.protobuf.Any\",\"value\":{\"@type\":\"type.googleapis.com/google.protobuf.Int32Value\",\"value\":1}}}"
        let decoded: SwiftProtoTesting_Test3_TestAllTypesProto3
        do {
            decoded = try SwiftProtoTesting_Test3_TestAllTypesProto3(jsonString: start)
        } catch {
            XCTFail("Failed to decode \(start)")
            return
        }
        XCTAssertNotNil(decoded.optionalAny)
        let outerAny = decoded.optionalAny
        do {
            let innerAny = try Google_Protobuf_Any(unpackingAny: outerAny)
            do {
                let value = try Google_Protobuf_Int32Value(unpackingAny: innerAny)
                XCTAssertEqual(value.value, 1)
            } catch {
                XCTFail("Failed to decode innerAny")
                return
            }
        } catch {
            XCTFail("Failed to unpack outerAny \(outerAny): \(error)")
            return
        }

        let protobuf: [UInt8]
        do {
            protobuf = try decoded.serializedBytes()
        } catch {
            XCTFail("Failed to serialize \(decoded)")
            return
        }
        XCTAssertEqual(
            protobuf,
            [
                138, 19, 95, 10, 39, 116, 121, 112, 101, 46, 103, 111, 111, 103, 108, 101, 97, 112, 105, 115, 46, 99,
                111, 109, 47, 103, 111, 111, 103, 108, 101, 46, 112, 114, 111, 116, 111, 98, 117, 102, 46, 65, 110, 121,
                18, 52, 10, 46, 116, 121, 112, 101, 46, 103, 111, 111, 103, 108, 101, 97, 112, 105, 115, 46, 99, 111,
                109, 47, 103, 111, 111, 103, 108, 101, 46, 112, 114, 111, 116, 111, 98, 117, 102, 46, 73, 110, 116, 51,
                50, 86, 97, 108, 117, 101, 18, 2, 8, 1,
            ]
        )

        let redecoded: SwiftProtoTesting_Test3_TestAllTypesProto3
        do {
            redecoded = try SwiftProtoTesting_Test3_TestAllTypesProto3(serializedBytes: protobuf)
        } catch {
            XCTFail("Failed to decode \(protobuf)")
            return
        }

        let json: String
        do {
            json = try redecoded.jsonString()
        } catch {
            XCTFail("Failed to recode \(redecoded)")
            return
        }
        XCTAssertEqual(json, start)

        do {
            let recoded = try decoded.jsonString()
            XCTAssertEqual(recoded, start)
        } catch {
            XCTFail("Failed to recode \(start)")
        }
    }

    func test_Any_recursive() throws {
        func nestedAny(_ i: Int) throws -> Google_Protobuf_Any {
            guard i > 0 else { return Google_Protobuf_Any() }
            return try Google_Protobuf_Any(packing: nestedAny(i - 1))
        }
        let any = try nestedAny(5)
        let encoded: [UInt8] = try any.serializedBytes()
        XCTAssertEqual(encoded.count, 214)
    }

    func test_Any_Duration_JSON_roundtrip() throws {
        let start =
            "{\"optionalAny\":{\"@type\":\"type.googleapis.com/google.protobuf.Duration\",\"value\":\"99.001s\"}}"
        do {
            let decoded = try SwiftProtoTesting_Test3_TestAllTypesProto3(jsonString: start)

            XCTAssertNotNil(decoded.optionalAny)
            let anyField = decoded.optionalAny
            do {
                let unpacked = try Google_Protobuf_Duration(unpackingAny: anyField)
                XCTAssertEqual(unpacked.seconds, 99)
                XCTAssertEqual(unpacked.nanos, 1_000_000)
            } catch {
                XCTFail("Failed to unpack \(anyField)")
            }

            let encoded = try decoded.jsonString()
            XCTAssertEqual(encoded, start)
        } catch {
            XCTFail("Failed to decode \(start)")
        }
    }

    func test_Any_JSONUnpackWKTDepthLimit() throws {
        // 1 Any + 1 root Value + 4 nested ListValue + 4 element Values = 10 message levels.
        let json = "{\"@type\":\"type.googleapis.com/google.protobuf.Value\",\"value\":[[[[1]]]]}"
        var options = JSONDecodingOptions()
        options.messageDepthLimit = 9
        XCTAssertThrowsError(try Google_Protobuf_Any(jsonString: json, options: options)) { error in
            if let protobufError = error as? SwiftProtobufError {
                XCTAssertTrue(
                    protobufError.message.hasSuffix(": Message is too deep"),
                    "Unexpected error message: \(protobufError.message)"
                )
            } else {
                XCTFail("Expected SwiftProtobufError, got \(error)")
            }
        }

        options.messageDepthLimit = 10
        let decodedAny = try Google_Protobuf_Any(jsonString: json, options: options)
        let unpacked = try Google_Protobuf_Value(unpackingAny: decodedAny)
        XCTAssertEqual(
            unpacked,
            .with {
                $0.listValue = .with {
                    $0.values = [
                        .with {
                            $0.listValue = .with {
                                $0.values = [
                                    .with {
                                        $0.listValue = .with {
                                            $0.values = [
                                                .with {
                                                    $0.listValue = .with {
                                                        $0.values = [.with { $0.numberValue = 1 }]
                                                    }
                                                }
                                            ]
                                        }
                                    }
                                ]
                            }
                        }
                    ]
                }
            }
        )
    }

    func test_Any_Duration_transcode() throws {
        let start =
            "{\"optionalAny\":{\"@type\":\"type.googleapis.com/google.protobuf.Duration\",\"value\":\"99.001s\"}}"
        do {
            let decoded = try SwiftProtoTesting_Test3_TestAllTypesProto3(jsonString: start)
            let protobuf: [UInt8] = try decoded.serializedBytes()
            XCTAssertEqual(
                protobuf,
                [
                    138, 19, 54, 10, 44, 116, 121, 112, 101, 46, 103, 111, 111, 103, 108, 101, 97, 112, 105, 115, 46,
                    99, 111, 109, 47, 103, 111, 111, 103, 108, 101, 46, 112, 114, 111, 116, 111, 98, 117, 102, 46, 68,
                    117, 114, 97, 116, 105, 111, 110, 18, 6, 8, 99, 16, 192, 132, 61,
                ]
            )
            do {
                let redecoded = try SwiftProtoTesting_Test3_TestAllTypesProto3(serializedBytes: protobuf)
                let json = try redecoded.jsonString()
                XCTAssertEqual(json, start)
            } catch let e {
                XCTFail("Failed to redecode \(protobuf): \(e)")
            }
        } catch let e {
            XCTFail("Failed to decode \(start): \(e)")
        }
    }

    private func makeSerializedNestedAnyBytes(wrappers: Int, leafValue: Int32 = 7) throws -> [UInt8] {
        var currentBytes: [UInt8] = try Google_Protobuf_Int32Value(leafValue).serializedBytes()
        var currentTypeURL = "type.googleapis.com/google.protobuf.Int32Value"
        for _ in 0..<wrappers {
            var outer = Google_Protobuf_Any()
            outer.typeURL = currentTypeURL
            outer.value = Data(currentBytes)
            currentBytes = try outer.serializedBytes()
            currentTypeURL = "type.googleapis.com/google.protobuf.Any"
        }
        return currentBytes
    }

    func test_Any_JSONTranscodeDepthLimit() throws {
        // 99 Any wrappers + 1 inner Int32Value = 100 messages total (within default limit of 100).
        let bytesAtLimit = try makeSerializedNestedAnyBytes(wrappers: 99)
        let decodedAtLimit = try Google_Protobuf_Any(serializedBytes: bytesAtLimit)
        let jsonAtLimit = try decodedAtLimit.jsonString()
        XCTAssertTrue(jsonAtLimit.contains("\"value\":7"))
        let utf8AtLimit: [UInt8] = try decodedAtLimit.jsonUTF8Bytes()
        XCTAssertEqual(String(decoding: utf8AtLimit, as: UTF8.self), jsonAtLimit)

        // 100 Any wrappers + 1 inner Int32Value = 101 messages total (exceeds default limit of 100).
        let bytesOverLimit = try makeSerializedNestedAnyBytes(wrappers: 100)
        let decodedOverLimit = try Google_Protobuf_Any(serializedBytes: bytesOverLimit)
        XCTAssertThrowsError(try decodedOverLimit.jsonString()) { error in
            XCTAssertEqual(error as? JSONEncodingError, .anyTranscodeFailure)
        }
        XCTAssertThrowsError(try decodedOverLimit.jsonUTF8Bytes() as [UInt8]) { error in
            XCTAssertEqual(error as? JSONEncodingError, .anyTranscodeFailure)
        }

        // Deeply nested binary Any chain also fails cleanly with anyTranscodeFailure.
        let deepBytes = try makeSerializedNestedAnyBytes(wrappers: 500)
        let decodedDeep = try Google_Protobuf_Any(serializedBytes: deepBytes)
        XCTAssertThrowsError(try decodedDeep.jsonString()) { error in
            XCTAssertEqual(error as? JSONEncodingError, .anyTranscodeFailure)
        }

        // In-memory composition of packed Any wrappers also enforces the depth limit.
        var composed = try Google_Protobuf_Any(packing: Google_Protobuf_Int32Value(7))
        for _ in 0..<98 {
            composed = try Google_Protobuf_Any(packing: composed)
        }
        // 99 Any wrappers + 1 Int32Value = 100 messages total: succeeds.
        XCTAssertNoThrow(try composed.jsonString())
        // 100 Any wrappers + 1 Int32Value = 101 messages total: throws anyTranscodeFailure.
        let composedOverLimit = try Google_Protobuf_Any(packing: composed)
        XCTAssertThrowsError(try composedOverLimit.jsonString()) { error in
            XCTAssertEqual(error as? JSONEncodingError, .anyTranscodeFailure)
        }

        // Sibling elements in a repeated message/Any field do not accumulate depth across elements.
        var repeatedHolder = SwiftProtoTesting_Test3_TestAllTypesProto3()
        let singleAny = try Google_Protobuf_Any(packing: Google_Protobuf_Int32Value(1))
        repeatedHolder.repeatedAny = Array(repeating: singleAny, count: 150)
        XCTAssertNoThrow(try repeatedHolder.jsonString())
    }

    func test_Any_TextFormatTranscodeDepthLimit() throws {
        // 99 Any wrappers + 1 Int32Value = 100 messages total (99 verbose "[...]" blocks): all levels use verbose form.
        let bytesVerbose = try makeSerializedNestedAnyBytes(wrappers: 99)
        let decodedVerbose = try Google_Protobuf_Any(serializedBytes: bytesVerbose)
        let textVerbose = decodedVerbose.textFormatString()
        XCTAssertTrue(textVerbose.contains("[type.googleapis.com/google.protobuf.Int32Value]"))
        XCTAssertFalse(textVerbose.contains("type_url:"))
        let reparsedVerbose = try Google_Protobuf_Any(textFormatString: textVerbose)
        XCTAssertEqual(reparsedVerbose.textFormatString(), textVerbose)

        // Beyond the recursion budget, textFormatString() and debugDescription fall back to raw
        // type_url and value fields so output remains bounded and round-trips through TextFormatDecoder.
        let deepBytes = try makeSerializedNestedAnyBytes(wrappers: 500)
        let decodedDeep = try Google_Protobuf_Any(serializedBytes: deepBytes)
        let textDeep = decodedDeep.textFormatString()
        XCTAssertTrue(textDeep.contains("type_url: \"type.googleapis.com/google.protobuf.Any\""))
        XCTAssertFalse(textDeep.contains("[type.googleapis.com/google.protobuf.Int32Value]"))
        XCTAssertFalse(decodedDeep.debugDescription.isEmpty)
        let reparsedDeep = try Google_Protobuf_Any(textFormatString: textDeep)
        XCTAssertEqual(reparsedDeep.textFormatString(), textDeep)

        // In-memory packed Any composition beyond the recursion budget also falls back to raw fields.
        var composed = try Google_Protobuf_Any(packing: Google_Protobuf_Int32Value(7))
        for _ in 0..<99 {
            composed = try Google_Protobuf_Any(packing: composed)
        }
        let composedText = composed.textFormatString()
        XCTAssertTrue(composedText.contains("type_url: \"type.googleapis.com/google.protobuf.Int32Value\""))
        XCTAssertFalse(composedText.contains("[type.googleapis.com/google.protobuf.Int32Value]"))
        let reparsedComposed = try Google_Protobuf_Any(textFormatString: composedText)
        XCTAssertEqual(reparsedComposed.textFormatString(), composedText)

        // Decoding a single top-level TextFormat Any with raw `type_url` and `value` carrying a
        // deep binary Any chain succeeds at decode time and is bounded when re-encoded to JSON or TextFormat.
        let innerDeepBytes = try makeSerializedNestedAnyBytes(wrappers: 499)
        let escapedInnerBytes = innerDeepBytes.map { String(format: "\\%03o", $0) }.joined()
        let rawFieldTextInput =
            "type_url: \"type.googleapis.com/google.protobuf.Any\"\nvalue: \"\(escapedInnerBytes)\"\n"
        let decodedFromRawText = try Google_Protobuf_Any(textFormatString: rawFieldTextInput)
        XCTAssertThrowsError(try decodedFromRawText.jsonString()) { error in
            XCTAssertEqual(error as? JSONEncodingError, .anyTranscodeFailure)
        }
        let reencodedText = decodedFromRawText.textFormatString()
        XCTAssertTrue(reencodedText.contains("type_url: \"type.googleapis.com/google.protobuf.Any\""))
        XCTAssertFalse(reencodedText.contains("[type.googleapis.com/google.protobuf.Int32Value]"))
        let reparsedFromReencodedText = try Google_Protobuf_Any(textFormatString: reencodedText)
        XCTAssertEqual(reparsedFromReencodedText.textFormatString(), reencodedText)

        // A JSON-decoded WKT Any wrapped inside 98 packed Any wrappers (99 Any wrappers + 1 Int32Value
        // = 100 messages total) uses verbose TextFormat at the leaf, whereas 99 packed Any wrappers
        // around that JSON-decoded WKT Any (100 Any wrappers + 1 Int32Value = 101 messages total)
        // exceeds the recursion budget and falls back to raw `type_url:`/`value:` fields.
        let jsonLeafAny = try Google_Protobuf_Any(
            jsonString: #"{"@type":"type.googleapis.com/google.protobuf.Int32Value","value":7}"#
        )
        var composedWithJSONWKTLeaf = jsonLeafAny
        for _ in 0..<98 {
            composedWithJSONWKTLeaf = try Google_Protobuf_Any(packing: composedWithJSONWKTLeaf)
        }
        let textWithJSONWKTLeafAtLimit = composedWithJSONWKTLeaf.textFormatString()
        XCTAssertTrue(textWithJSONWKTLeafAtLimit.contains("[type.googleapis.com/google.protobuf.Int32Value]"))
        XCTAssertFalse(textWithJSONWKTLeafAtLimit.contains("type_url:"))

        let composedWithJSONWKTLeafOverLimit = try Google_Protobuf_Any(packing: composedWithJSONWKTLeaf)
        let textWithJSONWKTLeafOverLimit = composedWithJSONWKTLeafOverLimit.textFormatString()
        XCTAssertFalse(textWithJSONWKTLeafOverLimit.contains("[type.googleapis.com/google.protobuf.Int32Value]"))
        XCTAssertTrue(
            textWithJSONWKTLeafOverLimit.contains("type_url: \"type.googleapis.com/google.protobuf.Int32Value\"")
        )

        // Nested JSON-decoded Any chain at the 100-message limit (99 Any wrappers + 1 Int32Value)
        // also expands to verbose TextFormat all the way to the leaf.
        var nestedJSONString = #"{"@type":"type.googleapis.com/google.protobuf.Int32Value","value":7}"#
        for _ in 0..<98 {
            nestedJSONString = #"{"@type":"type.googleapis.com/google.protobuf.Any","value":\#(nestedJSONString)}"#
        }
        let decodedNestedJSONAtLimit = try Google_Protobuf_Any(jsonString: nestedJSONString)
        let textNestedJSONAtLimit = decodedNestedJSONAtLimit.textFormatString()
        XCTAssertTrue(textNestedJSONAtLimit.contains("[type.googleapis.com/google.protobuf.Int32Value]"))
        XCTAssertFalse(textNestedJSONAtLimit.contains("type_url:"))
    }

    func test_Any_FieldMask_JSON_roundtrip() throws {
        let start =
            "{\"optionalAny\":{\"@type\":\"type.googleapis.com/google.protobuf.FieldMask\",\"value\":\"foo,bar.bazQuux\"}}"
        do {
            let decoded = try SwiftProtoTesting_Test3_TestAllTypesProto3(jsonString: start)
            XCTAssertNotNil(decoded.optionalAny)
            let anyField = decoded.optionalAny
            do {
                let unpacked = try Google_Protobuf_FieldMask(unpackingAny: anyField)
                XCTAssertEqual(unpacked.paths, ["foo", "bar.baz_quux"])
            } catch {
                XCTFail("Failed to unpack anyField \(anyField)")
            }

            let encoded = try decoded.jsonString()
            XCTAssertEqual(encoded, start)
        } catch {
            XCTFail("Failed to decode \(start)")
        }
    }

    func test_Any_FieldMask_transcode() throws {
        let start =
            "{\"optionalAny\":{\"@type\":\"type.googleapis.com/google.protobuf.FieldMask\",\"value\":\"foo,bar.bazQuux\"}}"
        do {
            let decoded = try SwiftProtoTesting_Test3_TestAllTypesProto3(jsonString: start)
            let protobuf: [UInt8] = try decoded.serializedBytes()
            XCTAssertEqual(
                protobuf,
                [
                    138, 19, 68, 10, 45, 116, 121, 112, 101, 46, 103, 111, 111, 103, 108, 101, 97, 112, 105, 115, 46,
                    99, 111, 109, 47, 103, 111, 111, 103, 108, 101, 46, 112, 114, 111, 116, 111, 98, 117, 102, 46, 70,
                    105, 101, 108, 100, 77, 97, 115, 107, 18, 19, 10, 3, 102, 111, 111, 10, 12, 98, 97, 114, 46, 98, 97,
                    122, 95, 113, 117, 117, 120,
                ]
            )
            do {
                let redecoded = try SwiftProtoTesting_Test3_TestAllTypesProto3(serializedBytes: protobuf)
                let json = try redecoded.jsonString()
                XCTAssertEqual(json, start)
            } catch let e {
                XCTFail("Failed to redecode \(protobuf): \(e)")
            }
        } catch let e {
            XCTFail("Failed to decode \(start): \(e)")
        }
    }

    func test_Any_Int32Value_JSON_roundtrip() throws {
        let start = "{\"optionalAny\":{\"@type\":\"type.googleapis.com/google.protobuf.Int32Value\",\"value\":1}}"
        do {
            let decoded = try SwiftProtoTesting_Test3_TestAllTypesProto3(jsonString: start)
            XCTAssertNotNil(decoded.optionalAny)
            let anyField = decoded.optionalAny
            do {
                let unpacked = try Google_Protobuf_Int32Value(unpackingAny: anyField)
                XCTAssertEqual(unpacked.value, 1)
            } catch {
                XCTFail("failed to unpack \(anyField)")
            }

            let encoded = try decoded.jsonString()
            XCTAssertEqual(encoded, start)
        } catch {
            XCTFail("Failed to decode \(start)")
        }
    }

    func test_Any_Int32Value_transcode() throws {
        let start = "{\"optionalAny\":{\"@type\":\"type.googleapis.com/google.protobuf.Int32Value\",\"value\":1}}"
        do {
            let decoded = try SwiftProtoTesting_Test3_TestAllTypesProto3(jsonString: start)
            let protobuf: [UInt8] = try decoded.serializedBytes()
            XCTAssertEqual(
                protobuf,
                [
                    138, 19, 52, 10, 46, 116, 121, 112, 101, 46, 103, 111, 111, 103, 108, 101, 97, 112, 105, 115, 46,
                    99, 111, 109, 47, 103, 111, 111, 103, 108, 101, 46, 112, 114, 111, 116, 111, 98, 117, 102, 46, 73,
                    110, 116, 51, 50, 86, 97, 108, 117, 101, 18, 2, 8, 1,
                ]
            )
            do {
                let redecoded = try SwiftProtoTesting_Test3_TestAllTypesProto3(serializedBytes: protobuf)
                let json = try redecoded.jsonString()
                XCTAssertEqual(json, start)
            } catch let e {
                XCTFail("Failed to redecode \(protobuf): \(e)")
            }
        } catch let e {
            XCTFail("Failed to decode \(start): \(e)")
        }
    }

    // TODO: Test remaining XxxValue types

    func test_Any_Struct_JSON_roundtrip() throws {
        let start =
            "{\"optionalAny\":{\"@type\":\"type.googleapis.com/google.protobuf.Struct\",\"value\":{\"foo\":1.0}}}"
        do {
            let decoded = try SwiftProtoTesting_Test3_TestAllTypesProto3(jsonString: start)
            XCTAssertNotNil(decoded.optionalAny)
            let anyField = decoded.optionalAny
            do {
                let unpacked = try Google_Protobuf_Struct(unpackingAny: anyField)
                XCTAssertEqual(unpacked.fields["foo"], Google_Protobuf_Value(numberValue: 1))
            } catch {
                XCTFail("Failed to unpack \(anyField)")
            }

            let encoded = try decoded.jsonString()
            XCTAssertEqual(encoded, start)
        } catch {
            XCTFail("Failed to decode \(start)")
        }
    }

    func test_Any_Struct_transcode() throws {
        let start =
            "{\"optionalAny\":{\"@type\":\"type.googleapis.com/google.protobuf.Struct\",\"value\":{\"foo\":1.0}}}"
        do {
            let decoded = try SwiftProtoTesting_Test3_TestAllTypesProto3(jsonString: start)
            let protobuf: [UInt8] = try decoded.serializedBytes()
            XCTAssertEqual(
                protobuf,
                [
                    138, 19, 64, 10, 42, 116, 121, 112, 101, 46, 103, 111, 111, 103, 108, 101, 97, 112, 105, 115, 46,
                    99, 111, 109, 47, 103, 111, 111, 103, 108, 101, 46, 112, 114, 111, 116, 111, 98, 117, 102, 46, 83,
                    116, 114, 117, 99, 116, 18, 18, 10, 16, 10, 3, 102, 111, 111, 18, 9, 17, 0, 0, 0, 0, 0, 0, 240, 63,
                ]
            )
            do {
                let redecoded = try SwiftProtoTesting_Test3_TestAllTypesProto3(serializedBytes: protobuf)
                let json = try redecoded.jsonString()
                XCTAssertEqual(json, start)
            } catch let e {
                XCTFail("Redecode failed for \(protobuf): \(e)")
            }
        } catch let e {
            XCTFail("Redecode failed for \(start): \(e)")
        }
    }

    func test_Any_Timestamp_JSON_roundtrip() throws {
        let start =
            "{\"optionalAny\":{\"@type\":\"type.googleapis.com/google.protobuf.Timestamp\",\"value\":\"1970-01-01T00:00:01Z\"}}"
        do {
            let decoded = try SwiftProtoTesting_Test3_TestAllTypesProto3(jsonString: start)
            XCTAssertNotNil(decoded.optionalAny)
            let anyField = decoded.optionalAny
            do {
                let unpacked = try Google_Protobuf_Timestamp(unpackingAny: anyField)
                XCTAssertEqual(unpacked.seconds, 1)
                XCTAssertEqual(unpacked.nanos, 0)
            } catch {
                XCTFail("Failed to unpack \(anyField)")
            }

            let encoded = try decoded.jsonString()
            XCTAssertEqual(encoded, start)
        } catch {
            XCTFail("Failed to decode \(start)")
        }
    }

    func test_Any_Timestamp_transcode() throws {
        let start =
            "{\"optionalAny\":{\"@type\":\"type.googleapis.com/google.protobuf.Timestamp\",\"value\":\"1970-01-01T00:00:01.000000001Z\"}}"
        do {
            let decoded = try SwiftProtoTesting_Test3_TestAllTypesProto3(jsonString: start)
            let protobuf: [UInt8] = try decoded.serializedBytes()
            XCTAssertEqual(
                protobuf,
                [
                    138, 19, 53, 10, 45, 116, 121, 112, 101, 46, 103, 111, 111, 103, 108, 101, 97, 112, 105, 115, 46,
                    99, 111, 109, 47, 103, 111, 111, 103, 108, 101, 46, 112, 114, 111, 116, 111, 98, 117, 102, 46, 84,
                    105, 109, 101, 115, 116, 97, 109, 112, 18, 4, 8, 1, 16, 1,
                ]
            )
            do {
                let redecoded = try SwiftProtoTesting_Test3_TestAllTypesProto3(serializedBytes: protobuf)
                let json = try redecoded.jsonString()
                XCTAssertEqual(json, start)
            } catch let e {
                XCTFail("Decode failed for \(start): \(e)")
            }
        } catch let e {
            XCTFail("Decode failed for \(start): \(e)")
        }
    }

    func test_Any_ListValue_JSON_roundtrip() throws {
        let start =
            "{\"optionalAny\":{\"@type\":\"type.googleapis.com/google.protobuf.ListValue\",\"value\":[\"foo\",1.0]}}"
        do {
            let decoded = try SwiftProtoTesting_Test3_TestAllTypesProto3(jsonString: start)
            let anyField = decoded.optionalAny
            do {
                let unpacked = try Google_Protobuf_ListValue(unpackingAny: anyField)
                XCTAssertEqual(
                    unpacked.values,
                    [Google_Protobuf_Value(stringValue: "foo"), Google_Protobuf_Value(numberValue: 1)]
                )
            } catch {
                XCTFail("Failed to unpack \(anyField)")
            }

            let encoded = try decoded.jsonString()
            XCTAssertEqual(encoded, start)
        } catch {
            XCTFail("Failed to decode \(start)")
        }
    }

    func test_Any_ListValue_transcode() throws {
        let start =
            "{\"optionalAny\":{\"@type\":\"type.googleapis.com/google.protobuf.ListValue\",\"value\":[1.0,\"abc\"]}}"
        do {
            let decoded = try SwiftProtoTesting_Test3_TestAllTypesProto3(jsonString: start)
            let protobuf: [UInt8] = try decoded.serializedBytes()
            XCTAssertEqual(
                protobuf,
                [
                    138, 19, 67, 10, 45, 116, 121, 112, 101, 46, 103, 111, 111, 103, 108, 101, 97, 112, 105, 115, 46,
                    99, 111, 109, 47, 103, 111, 111, 103, 108, 101, 46, 112, 114, 111, 116, 111, 98, 117, 102, 46, 76,
                    105, 115, 116, 86, 97, 108, 117, 101, 18, 18, 10, 9, 17, 0, 0, 0, 0, 0, 0, 240, 63, 10, 5, 26, 3,
                    97, 98, 99,
                ]
            )
            do {
                let redecoded = try SwiftProtoTesting_Test3_TestAllTypesProto3(serializedBytes: protobuf)
                let json = try redecoded.jsonString()
                XCTAssertEqual(json, start)
            } catch let e {
                XCTFail("Redecode failed for \(protobuf): \(e)")
            }
        } catch let e {
            XCTFail("Decode failed for \(start): \(e)")
        }
    }

    func test_Any_Value_struct_JSON_roundtrip() throws {
        // Value holding a JSON Struct
        let start1 =
            "{\"optionalAny\":{\"@type\":\"type.googleapis.com/google.protobuf.Value\",\"value\":{\"foo\":1.0}}}"
        do {
            let decoded1 = try SwiftProtoTesting_Test3_TestAllTypesProto3(jsonString: start1)
            XCTAssertNotNil(decoded1.optionalAny)
            let anyField = decoded1.optionalAny
            XCTAssertThrowsError(try Google_Protobuf_Struct(unpackingAny: anyField))
            do {
                let unpacked = try Google_Protobuf_Value(unpackingAny: anyField)
                XCTAssertEqual(unpacked.structValue.fields["foo"], Google_Protobuf_Value(numberValue: 1))
            } catch {
                XCTFail("failed to unpack \(anyField)")
            }

            let encoded1 = try decoded1.jsonString()
            XCTAssertEqual(encoded1, start1)
        } catch {
            XCTFail("Failed to decode \(start1)")
        }
    }

    func test_Any_Value_struct_transcode() throws {
        let start =
            "{\"optionalAny\":{\"@type\":\"type.googleapis.com/google.protobuf.Value\",\"value\":{\"foo\":1.0}}}"
        do {
            let decoded = try SwiftProtoTesting_Test3_TestAllTypesProto3(jsonString: start)
            let protobuf: [UInt8] = try decoded.serializedBytes()
            XCTAssertEqual(
                protobuf,
                [
                    138, 19, 65, 10, 41, 116, 121, 112, 101, 46, 103, 111, 111, 103, 108, 101, 97, 112, 105, 115, 46,
                    99, 111, 109, 47, 103, 111, 111, 103, 108, 101, 46, 112, 114, 111, 116, 111, 98, 117, 102, 46, 86,
                    97, 108, 117, 101, 18, 20, 42, 18, 10, 16, 10, 3, 102, 111, 111, 18, 9, 17, 0, 0, 0, 0, 0, 0, 240,
                    63,
                ]
            )
            do {
                let redecoded = try SwiftProtoTesting_Test3_TestAllTypesProto3(serializedBytes: protobuf)
                let json = try redecoded.jsonString()
                XCTAssertEqual(json, start)
            } catch let e {
                XCTFail("Decode failed for \(protobuf): \(e)")
            }
        } catch let e {
            XCTFail("Decode failed for \(start): \(e)")
        }
    }

    func test_Any_Value_int_JSON_roundtrip() throws {
        // Value holding an Int
        let start2 = "{\"optionalAny\":{\"@type\":\"type.googleapis.com/google.protobuf.Value\",\"value\":1.0}}"
        do {
            let decoded2 = try SwiftProtoTesting_Test3_TestAllTypesProto3(jsonString: start2)
            XCTAssertNotNil(decoded2.optionalAny)
            let anyField = decoded2.optionalAny
            XCTAssertThrowsError(try Google_Protobuf_Struct(unpackingAny: anyField))
            do {
                let unpacked = try Google_Protobuf_Value(unpackingAny: anyField)
                XCTAssertEqual(unpacked.numberValue, 1)
            } catch {
                XCTFail("Failed to unpack \(anyField)")
            }

            let encoded2 = try decoded2.jsonString()
            XCTAssertEqual(encoded2, start2)
        } catch let e {
            XCTFail("Failed to decode \(start2): \(e)")
        }
    }

    func test_Any_Value_int_transcode() throws {
        let start = "{\"optionalAny\":{\"@type\":\"type.googleapis.com/google.protobuf.Value\",\"value\":1.0}}"
        do {
            let decoded = try SwiftProtoTesting_Test3_TestAllTypesProto3(jsonString: start)
            let protobuf: [UInt8] = try decoded.serializedBytes()
            XCTAssertEqual(
                protobuf,
                [
                    138, 19, 54, 10, 41, 116, 121, 112, 101, 46, 103, 111, 111, 103, 108, 101, 97, 112, 105, 115, 46,
                    99, 111, 109, 47, 103, 111, 111, 103, 108, 101, 46, 112, 114, 111, 116, 111, 98, 117, 102, 46, 86,
                    97, 108, 117, 101, 18, 9, 17, 0, 0, 0, 0, 0, 0, 240, 63,
                ]
            )
            do {
                let redecoded = try SwiftProtoTesting_Test3_TestAllTypesProto3(serializedBytes: protobuf)
                let json = try redecoded.jsonString()
                XCTAssertEqual(json, start)
            } catch {
                XCTFail("Redecode failed for \(protobuf)")
            }
        } catch {
            XCTFail("Decode failed for \(start)")
        }
    }

    func test_Any_Value_string_JSON_roundtrip() throws {
        // Value holding a String
        let start3 = "{\"optionalAny\":{\"@type\":\"type.googleapis.com/google.protobuf.Value\",\"value\":\"abc\"}}"
        do {
            let decoded3 = try SwiftProtoTesting_Test3_TestAllTypesProto3(jsonString: start3)
            let anyField = decoded3.optionalAny
            XCTAssertThrowsError(try Google_Protobuf_Struct(unpackingAny: anyField))
            do {
                let unpacked = try Google_Protobuf_Value(unpackingAny: anyField)
                XCTAssertEqual(unpacked.stringValue, "abc")
            } catch {
                XCTFail("Failed to unpack \(anyField)")
            }

            let encoded3 = try decoded3.jsonString()
            XCTAssertEqual(encoded3, start3)
        } catch {
            XCTFail("Failed to decode \(start3)")
        }
    }

    func test_Any_Value_string_transcode() throws {
        let start = "{\"optionalAny\":{\"@type\":\"type.googleapis.com/google.protobuf.Value\",\"value\":\"abc\"}}"
        do {
            let decoded = try SwiftProtoTesting_Test3_TestAllTypesProto3(jsonString: start)
            let protobuf: [UInt8] = try decoded.serializedBytes()
            XCTAssertEqual(
                protobuf,
                [
                    138, 19, 50, 10, 41, 116, 121, 112, 101, 46, 103, 111, 111, 103, 108, 101, 97, 112, 105, 115, 46,
                    99, 111, 109, 47, 103, 111, 111, 103, 108, 101, 46, 112, 114, 111, 116, 111, 98, 117, 102, 46, 86,
                    97, 108, 117, 101, 18, 5, 26, 3, 97, 98, 99,
                ]
            )
            do {
                let redecoded = try SwiftProtoTesting_Test3_TestAllTypesProto3(serializedBytes: protobuf)
                let json = try redecoded.jsonString()
                XCTAssertEqual(json, start)
            } catch {
                XCTFail("Redecode failed for \(protobuf)")
            }
        } catch {
            XCTFail("Decode failed for \(start)")
        }
    }

    func test_Any_OddTypeURL_FromValue() throws {
        var msg = SwiftProtoTesting_Test3_TestAllTypesProto3()
        msg.optionalAny.value = Data([0x1a, 0x03, 0x61, 0x62, 0x63])
        msg.optionalAny.typeURL = "Odd\nType\" prefix/google.protobuf.Value"
        let newJSON = try msg.jsonString()
        XCTAssertEqual(
            newJSON,
            "{\"optionalAny\":{\"@type\":\"Odd\\nType\\\" prefix/google.protobuf.Value\",\"value\":\"abc\"}}"
        )
    }

    func test_Any_OddTypeURL_FromMessage() throws {
        let valueMsg = Google_Protobuf_Value.with {
            $0.stringValue = "abc"
        }
        var msg = SwiftProtoTesting_Test3_TestAllTypesProto3()
        msg.optionalAny = try Google_Protobuf_Any(packing: valueMsg, typeURLPrefix: "Odd\nPrefix\"")
        let newJSON = try msg.jsonString()
        XCTAssertEqual(
            newJSON,
            "{\"optionalAny\":{\"@type\":\"Odd\\nPrefix\\\"/google.protobuf.Value\",\"value\":\"abc\"}}"
        )
    }

    func test_Any_OddTypeURL_TextFormat() throws {
        // The verbose text form writes the type URL unquoted inside "[...]", so a URL
        // that would end the name early must use the type_url/value fields instead.
        let url =
            "x/google.protobuf.Int32Value] {} } int32_value: 666 any_value { [type.googleapis.com/google.protobuf.Int32Value"
        let expected = "any_value {\n  type_url: \"\(url)\"\n  value: \"\\b\\007\"\n}\n"

        var msg = SwiftProtoTesting_TestAny()
        msg.anyValue.typeURL = url
        msg.anyValue.value = Data([8, 7])
        let fromBinary = try SwiftProtoTesting_TestAny(serializedBytes: try msg.serializedBytes() as [UInt8])
        XCTAssertEqual(fromBinary.textFormatString(), expected)
        let redecoded = try SwiftProtoTesting_TestAny(textFormatString: fromBinary.textFormatString())
        XCTAssertEqual(redecoded.int32Value, 0)
        XCTAssertEqual(redecoded, fromBinary)

        let fromJSON = try SwiftProtoTesting_TestAny(jsonString: "{\"anyValue\":{\"@type\":\"\(url)\",\"value\":7}}")
        let redecodedJSON = try SwiftProtoTesting_TestAny(textFormatString: fromJSON.textFormatString())
        XCTAssertEqual(redecodedJSON.int32Value, 0)
        XCTAssertEqual(redecodedJSON.anyValue.typeURL, url)

        var packed = SwiftProtoTesting_TestAny()
        packed.anyValue = try Google_Protobuf_Any(packing: Google_Protobuf_Int32Value(7))
        packed.anyValue.typeURL = url
        XCTAssertEqual(packed.textFormatString(), expected)

        // URLs the parser accepts as written still use the verbose form.
        msg.anyValue.typeURL = "example.com/a%2Fb/google.protobuf.Int32Value"
        XCTAssertEqual(
            msg.textFormatString(),
            "any_value {\n  [example.com/a%2Fb/google.protobuf.Int32Value] {\n    value: 7\n  }\n}\n"
        )
        let reparsed = try SwiftProtoTesting_TestAny(textFormatString: msg.textFormatString())
        XCTAssertEqual(reparsed.anyValue.typeURL, msg.anyValue.typeURL)
    }

    func test_Any_JSON_Extensions() throws {
        var content = SwiftProtoTesting_TestAllExtensions()
        content.SwiftProtoTesting_optionalInt32Extension = 17

        var msg = SwiftProtoTesting_TestAny()
        msg.anyValue = try Google_Protobuf_Any(packing: content)

        var options = JSONEncodingOptions()
        options.extensions = SwiftProtoTesting_Unittest_Extensions
        let json = try msg.jsonString(options: options)
        XCTAssertEqual(
            json,
            "{\"anyValue\":{\"@type\":\"type.googleapis.com/swift_proto_testing.TestAllExtensions\",\"[swift_proto_testing.optional_int32_extension]\":17}}"
        )

        // Fails if we don't provide the extension registry.
        XCTAssertThrowsError(try SwiftProtoTesting_TestAny(jsonString: json))

        // Succeeds if we provide the extension registry.
        let decodedMsg = try SwiftProtoTesting_TestAny(
            jsonString: json,
            extensions: SwiftProtoTesting_Unittest_Extensions
        )
        let decodedContent = try SwiftProtoTesting_TestAllExtensions(
            unpackingAny: decodedMsg.anyValue,
            extensions: SwiftProtoTesting_Unittest_Extensions
        )
        XCTAssertEqual(decodedContent.SwiftProtoTesting_optionalInt32Extension, 17)
    }

    func test_Any_JSON_Extensions_noRegistry() throws {
        var content = SwiftProtoTesting_TestAllExtensions()
        content.SwiftProtoTesting_optionalInt32Extension = 17

        var msg = SwiftProtoTesting_TestAny()
        msg.anyValue = try Google_Protobuf_Any(packing: content)

        // Extensions are lost if we don't provide an extension registry. This is not treated as
        // an error; the Java implementation also does this.
        let json = try msg.jsonString()
        XCTAssertEqual(
            json,
            "{\"anyValue\":{\"@type\":\"type.googleapis.com/swift_proto_testing.TestAllExtensions\"}}"
        )
    }

    func test_Any_Text_Extensions() throws {
        var content = SwiftProtoTesting_TestAllExtensions()
        content.SwiftProtoTesting_optionalInt32Extension = 17

        var msg = SwiftProtoTesting_TestAny()
        msg.anyValue = try Google_Protobuf_Any(packing: content)

        var options = TextFormatEncodingOptions()
        options.extensions = SwiftProtoTesting_Unittest_Extensions
        let text = msg.textFormatString(options: options)
        XCTAssertEqual(
            text,
            """
            any_value {
              [type.googleapis.com/swift_proto_testing.TestAllExtensions] {
                [swift_proto_testing.optional_int32_extension]: 17
              }
            }

            """
        )

        // Fails if we don't provide the extension registry.
        XCTAssertThrowsError(try SwiftProtoTesting_TestAny(textFormatString: text))

        // Succeeds if we provide the extension registry.
        let decodedMsg = try SwiftProtoTesting_TestAny(
            textFormatString: text,
            extensions: SwiftProtoTesting_Unittest_Extensions
        )
        let decodedContent = try SwiftProtoTesting_TestAllExtensions(
            unpackingAny: decodedMsg.anyValue,
            extensions: SwiftProtoTesting_Unittest_Extensions
        )
        XCTAssertEqual(decodedContent.SwiftProtoTesting_optionalInt32Extension, 17)
    }

    func test_Any_Text_Extensions_notExpanded() throws {
        let text = #"""
            any_value {
              type_url: "type.googleapis.com/swift_proto_testing.TestAllExtensions"
              value: "\x08\x11"
            }

            """#

        // Succeeds if we don't provide the extension registry during parsing, because we don't
        // need to look up names.
        let decodedMsg = try SwiftProtoTesting_TestAny(textFormatString: text)
        let decodedContent = try SwiftProtoTesting_TestAllExtensions(
            unpackingAny: decodedMsg.anyValue,
            extensions: SwiftProtoTesting_Unittest_Extensions
        )
        XCTAssertEqual(decodedContent.SwiftProtoTesting_optionalInt32Extension, 17)
    }

    func test_Any_Text_Extensions_noRegistry() throws {
        var content = SwiftProtoTesting_TestAllExtensions()
        content.SwiftProtoTesting_optionalInt32Extension = 17

        var msg = SwiftProtoTesting_TestAny()
        msg.anyValue = try Google_Protobuf_Any(packing: content)

        // Extensions are printed like unknown fields if we don't provide an extension registry,
        // because we need to transcode during encoding and that requires name lookup.
        let text = msg.textFormatString()
        XCTAssertEqual(
            text,
            """
            any_value {
              [type.googleapis.com/swift_proto_testing.TestAllExtensions] {
                1: 17
              }
            }

            """
        )
    }

    func test_Any_WKT_UnknownFields() throws {
        let testcases = [
            // unknown field after @type, before value
            "{\"optionalAny\":{\"@type\":\"type.googleapis.com/google.protobuf.Duration\",\"fred\":1,\"value\":\"99.001s\"}}",
            // unknown field after @type, after value
            "{\"optionalAny\":{\"@type\":\"type.googleapis.com/google.protobuf.Duration\",\"value\":\"99.001s\",\"fred\":1}}",
            // unknown field before @type, value after @type
            "{\"optionalAny\":{\"fred\":1,\"@type\":\"type.googleapis.com/google.protobuf.Duration\",\"value\":\"99.001s\"}}",
            // unknown field and value both before @type
            "{\"optionalAny\":{\"fred\":1,\"value\":\"99.001s\",\"@type\":\"type.googleapis.com/google.protobuf.Duration\"}}",
            // unknown fields before and after @type, value before @type
            "{\"optionalAny\":{\"value\":\"99.001s\",\"fred\":{\"nested\":[1,2]},\"@type\":\"type.googleapis.com/google.protobuf.Duration\",\"barney\":true}}",
            // unknown fields before and after @type, value after @type
            "{\"optionalAny\":{\"fred\":1,\"@type\":\"type.googleapis.com/google.protobuf.Duration\",\"barney\":2,\"value\":\"99.001s\"}}",
        ]
        for json in testcases {
            for ignoreUnknown in [false, true] {
                do {
                    var options = JSONDecodingOptions()
                    options.ignoreUnknownFields = ignoreUnknown

                    let decoded = try SwiftProtoTesting_Test3_TestAllTypesProto3(jsonString: json, options: options)
                    // The previous operation should have thrown if we're not ignoring unknowns.
                    XCTAssertTrue(ignoreUnknown, json)

                    XCTAssertNotNil(decoded.optionalAny)
                    let anyField = decoded.optionalAny

                    let unpacked = try Google_Protobuf_Duration(unpackingAny: anyField)
                    XCTAssertEqual(unpacked.seconds, 99, json)
                    XCTAssertEqual(unpacked.nanos, 1_000_000, json)
                } catch {
                    // We should get here if we're not ignoring unknowns.
                    XCTAssertTrue(!ignoreUnknown, "Unexpected error for \(json): \(error)")
                    XCTAssertEqual(error as? AnyUnpackError, .malformedWellKnownTypeJSON, json)
                }
            }
        }
    }

    func test_Any_empty() throws {
        let start = "{\"optionalAny\":{}}"
        let decoded = try SwiftProtoTesting_Test3_TestAllTypesProto3(jsonString: start)
        let protobuf: [UInt8] = try decoded.serializedBytes()
        XCTAssertEqual(protobuf, [138, 19, 0])
        let redecoded = try SwiftProtoTesting_Test3_TestAllTypesProto3(serializedBytes: protobuf)
        let retext = redecoded.textFormatString()
        XCTAssertEqual(retext, "optional_any {\n}\n")
        let reredecoded = try SwiftProtoTesting_Test3_TestAllTypesProto3(textFormatString: retext)
        let rejson = try reredecoded.jsonString()
        XCTAssertEqual(rejson, start)
    }

    func test_Any_typeURLValidations() throws {
        // Upstream most langauges end up validating the type_url during encoding as well
        // as during decoding. Basically to do things, they end up looking up the type
        // in their global registries to use reflection to do things. SwiftProtobuf doesn't
        // have a registry we can rely on being complete. So instead during encoding we
        // do the most basic of checks. These tests help ensure those checks are working as
        // expected.
        //
        // The inspiration for the tests and the errors comes from editing upstream's
        // json_test.cc and observing a few things:
        //
        // TEST_P(JsonTest, HackingTypeURLs) {
        //   google::protobuf::Any any;
        //   any.set_type_url("not_valid");
        //   // INVALID_ARGUMENT: @type must contain at least one / and a nonempty host; got: not_valid
        //   EXPECT_THAT(ToJson(any), StatusIs(absl::StatusCode::kInvalidArgument));
        //
        //   // This works because the message counts as empty
        //   any.set_type_url("type.googleapis.com/proto3.TestMessage");
        //   EXPECT_THAT(ToJson(any),
        //               IsOkAndHolds(R"({"@type":"type.googleapis.com/proto3.TestMessage"})"));
        //   INVALID_ARGUMENT: @type must contain at least one / and a nonempty host; got:
        //
        //   EXPECT_THAT(ToProto<google::protobuf::Any>(R"json(
        //     {
        //       "@type": ""
        //     }
        //   )json"),
        //               StatusIs(absl::StatusCode::kInvalidArgument));
        // }
        //
        // TEST_P(JsonTest, HackingValues) {
        //   google::protobuf::Any any;
        //   any.set_value("abc");
        //   std::string blob = any.SerializeAsString();
        //   EXPECT_FALSE(blob.empty());  // It didn't fail to serialize
        //   // INVALID_ARGUMENT: broken Any: missing type URL
        //   EXPECT_THAT(ToJson(any), StatusIs(absl::StatusCode::kInvalidArgument));
        //
        //   // INVALID_ARGUMENT: invalid JSON  in  google.protobuf.Any,  near 2:5 (offset 5):   in legacy   mode,
        //   missing @type in Any  is  only  allowed for an   empty object
        //   EXPECT_THAT(ToProto<google::protobuf::Any>(R"json(
        //     {
        //       "value": "abc"
        //     }
        //   )json"),
        //               StatusIs(absl::StatusCode::kInvalidArgument));
        // }

        do {
            // No payload, no type_url
            var any = Google_Protobuf_Any()
            any.value = Data()
            XCTAssertEqual(try any.jsonString(), "{}")
            // No payload, valid type_url
            any.typeURL = "type.googleapis.com/SomeMessage"
            XCTAssertEqual(
                try any.jsonString(),
                "{\"@type\":\"type.googleapis.com/SomeMessage\"}"
            )
            // No payload, invalid type url.
            any.typeURL = "not_valid"
            XCTAssertThrowsError(
                try any.jsonString()
            ) { error in
                XCTAssertTrue(
                    self.isSwiftProtobufErrorEqual(
                        error as! SwiftProtobufError,
                        .JSONEncoding.invalidAnyTypeURL(type_url: "not_valid")
                    )
                )
            }

            // Has payload, no type_url
            any = Google_Protobuf_Any()
            any.value = Data([8, 1])  // SwiftProtoTesting_TestAllTypes.optionalInt32 = 1
            XCTAssertThrowsError(
                try any.jsonString()
            ) { error in
                XCTAssertTrue(
                    self.isSwiftProtobufErrorEqual(
                        error as! SwiftProtobufError,
                        .JSONEncoding.emptyAnyTypeURL()
                    )
                )
            }
            // Has payload, valid type_url (gets lazy decoded)
            Google_Protobuf_Any.register(messageType: SwiftProtoTesting_TestAllTypes.self)
            any.typeURL = "type.googleapis.com/swift_proto_testing.TestAllTypes"
            XCTAssertEqual(
                try any.jsonString(),
                "{\"@type\":\"type.googleapis.com/swift_proto_testing.TestAllTypes\",\"optionalInt32\":1}"
            )
            // Has payload, unregistered type url.
            any.typeURL = "type.googleapis.com/SomeMessage"
            XCTAssertThrowsError(
                try any.jsonString()
            ) { error in
                XCTAssertEqual(error as? JSONEncodingError, .anyTranscodeFailure)
            }
            // Has payload, invalid type url.
            any.typeURL = "not_valid"
            XCTAssertThrowsError(
                try any.jsonString()
            ) { error in
                XCTAssertTrue(
                    self.isSwiftProtobufErrorEqual(
                        error as! SwiftProtobufError,
                        .JSONEncoding.invalidAnyTypeURL(type_url: "not_valid")
                    )
                )
            }
        }

        // ---- Decoding JSON Any directly:

        do {
            // Empty, round trips.
            let json = "{}"
            let any = try Google_Protobuf_Any(jsonString: json)
            XCTAssertEqual(json, try any.jsonString())

            // Empty with invalid type_url
            XCTAssertThrowsError(
                try Google_Protobuf_Any(jsonString: "{\"@type\":\"not_valid\"}")
            ) { error in
                XCTAssertTrue(
                    self.isSwiftProtobufErrorEqual(
                        error as! SwiftProtobufError,
                        .JSONDecoding.invalidAnyTypeURL(type_url: "not_valid")
                    )
                )
            }

            // Unregistered type_url
            XCTAssertThrowsError(
                try Google_Protobuf_Any(jsonString: "{\"@type\":\"type.googleapis.com/SomeMessage\"}")
            ) { error in
                XCTAssertTrue(
                    self.isSwiftProtobufErrorEqual(
                        error as! SwiftProtobufError,
                        .JSONDecoding.unknownAnyTypeURL(type_url: "type.googleapis.com/SomeMessage")
                    )
                )
            }

            // Field but no type_url won't decode.
            XCTAssertThrowsError(
                try Google_Protobuf_Any(jsonString: "{\"value\":1}")
            ) { error in
                XCTAssertTrue(
                    self.isSwiftProtobufErrorEqual(
                        error as! SwiftProtobufError,
                        .JSONDecoding.emptyAnyTypeURL()
                    )
                )
            }
        }

        // ---- Decoding TextFormat expanded Any:

        do {
            // Invalid type_url (no slash)
            XCTAssertThrowsError(
                try Google_Protobuf_Any(textFormatString: "[not_a_url] {}")
            ) { error in
                XCTAssertTrue(
                    self.isSwiftProtobufErrorEqual(
                        error as! SwiftProtobufError,
                        .TextFormatDecoding.invalidAnyTypeURL(type_url: "not_a_url")
                    )
                )
            }

            // Invalid type_url (registered message name, but missing URL prefix/slash)
            XCTAssertThrowsError(
                try Google_Protobuf_Any(textFormatString: "[google.protobuf.Int32Value] { value: 1 }")
            ) { error in
                XCTAssertTrue(
                    self.isSwiftProtobufErrorEqual(
                        error as! SwiftProtobufError,
                        .TextFormatDecoding.invalidAnyTypeURL(type_url: "google.protobuf.Int32Value")
                    )
                )
            }

            // Unregistered type_url
            XCTAssertThrowsError(
                try Google_Protobuf_Any(textFormatString: "[type.googleapis.com/SomeMessage] {}")
            ) { error in
                XCTAssertTrue(
                    self.isSwiftProtobufErrorEqual(
                        error as! SwiftProtobufError,
                        .TextFormatDecoding.unknownAnyTypeURL(type_url: "type.googleapis.com/SomeMessage")
                    )
                )
            }
        }

        // ---- These come from the upstream conformace tests:

        do {
            // AnyWktRepresentationWithEmptyTypeAndValue
            let emptyTypeAndValue = "{\"optional_any\":{\"@type\":\"\",\"value\":\"\"}}"
            XCTAssertThrowsError(
                try SwiftProtoTesting_Test3_TestAllTypesProto3(jsonString: emptyTypeAndValue)
            ) { error in
                XCTAssertTrue(
                    self.isSwiftProtobufErrorEqual(
                        error as! SwiftProtobufError,
                        .JSONDecoding.invalidAnyTypeURL(type_url: "")
                    )
                )
            }

            // AnyWktRepresentationWithBadType
            let notAType = "{\"optional_any\":{\"@type\":\"not_a_url\",\"value\":\"\"}}"
            XCTAssertThrowsError(
                try SwiftProtoTesting_Test3_TestAllTypesProto3(jsonString: notAType)
            ) { error in
                XCTAssertTrue(
                    self.isSwiftProtobufErrorEqual(
                        error as! SwiftProtobufError,
                        .JSONDecoding.invalidAnyTypeURL(type_url: "not_a_url")
                    )
                )
            }

            // ---- Variant of AnyWktRepresentationWithEmptyTypeAndValue above with no value.
            let emptyType = "{\"optional_any\":{\"@type\":\"\"}}"
            XCTAssertThrowsError(
                try SwiftProtoTesting_Test3_TestAllTypesProto3(jsonString: emptyType)
            ) { error in
                XCTAssertTrue(
                    self.isSwiftProtobufErrorEqual(
                        error as! SwiftProtobufError,
                        .JSONDecoding.invalidAnyTypeURL(type_url: "")
                    )
                )
            }
        }
    }

    func test_Any_duplicateTypeURL() throws {
        Google_Protobuf_Any.register(messageType: SwiftProtoTesting_TestAllTypes.self)

        // Upstream rejects a repeated @type ("repeated @type in Any"), regardless
        // of where it appears, whether the values match, and whether ignoreUnknownFields is set.
        let inputs: [(String, String, String)] = [
            (
                "{\"@type\":\"type.googleapis.com/google.protobuf.Int32Value\",\"@type\":\"type.googleapis.com/google.protobuf.StringValue\",\"value\":\"x\"}",
                "type.googleapis.com/google.protobuf.Int32Value",
                "type.googleapis.com/google.protobuf.StringValue"
            ),
            (
                "{\"@type\":\"type.googleapis.com/google.protobuf.Int32Value\",\"value\":1,\"@type\":\"type.googleapis.com/google.protobuf.Int32Value\"}",
                "type.googleapis.com/google.protobuf.Int32Value",
                "type.googleapis.com/google.protobuf.Int32Value"
            ),
            (
                "{\"value\":1,\"@type\":\"type.googleapis.com/google.protobuf.Int32Value\",\"@type\":\"type.googleapis.com/google.protobuf.Int32Value\"}",
                "type.googleapis.com/google.protobuf.Int32Value",
                "type.googleapis.com/google.protobuf.Int32Value"
            ),
            (
                "{\"@type\":\"type.googleapis.com/swift_proto_testing.TestAllTypes\",\"optionalInt32\":1,\"@type\":\"type.googleapis.com/swift_proto_testing.TestAllTypes\"}",
                "type.googleapis.com/swift_proto_testing.TestAllTypes",
                "type.googleapis.com/swift_proto_testing.TestAllTypes"
            ),
            (
                "{\"optionalInt32\":1,\"@type\":\"type.googleapis.com/swift_proto_testing.TestAllTypes\",\"\\u0040type\":\"type.googleapis.com/swift_proto_testing.TestAllTypes\"}",
                "type.googleapis.com/swift_proto_testing.TestAllTypes",
                "type.googleapis.com/swift_proto_testing.TestAllTypes"
            ),
            (
                "{\"@type\":\"type.googleapis.com/SomeMessage\",\"\\u0040type\":\"type.googleapis.com/AnotherMessage\"}",
                "type.googleapis.com/SomeMessage",
                "type.googleapis.com/AnotherMessage"
            ),
            (
                "{\"a\":1,\"@type\":\"type.googleapis.com/SomeMessage\",\"b\":[2,3],\"@type\":\"type.googleapis.com/AnotherMessage\"}",
                "type.googleapis.com/SomeMessage",
                "type.googleapis.com/AnotherMessage"
            ),
        ]
        for (json, first, second) in inputs {
            for ignoreUnknown in [false, true] {
                var options = JSONDecodingOptions()
                options.ignoreUnknownFields = ignoreUnknown
                XCTAssertThrowsError(try Google_Protobuf_Any(jsonString: json, options: options), json) { error in
                    XCTAssertTrue(
                        self.isSwiftProtobufErrorEqual(
                            error as! SwiftProtobufError,
                            .JSONDecoding.duplicateAnyTypeURL(type_url: first, duplicate_type_url: second)
                        ),
                        "ignoreUnknown=\(ignoreUnknown), json=\(json), error=\(error)"
                    )
                }
            }
        }

        // Also when nested in a message.
        let nested =
            "{\"optionalAny\":{\"@type\":\"type.googleapis.com/google.protobuf.Int32Value\",\"@type\":\"type.googleapis.com/google.protobuf.StringValue\",\"value\":\"x\"}}"
        XCTAssertThrowsError(try SwiftProtoTesting_Test3_TestAllTypesProto3(jsonString: nested)) { error in
            XCTAssertTrue(
                self.isSwiftProtobufErrorEqual(
                    error as! SwiftProtobufError,
                    .JSONDecoding.duplicateAnyTypeURL(
                        type_url: "type.googleapis.com/google.protobuf.Int32Value",
                        duplicate_type_url: "type.googleapis.com/google.protobuf.StringValue"
                    )
                )
            )
        }
    }

    func test_Any_WKT_duplicateValue() throws {
        let inputs = [
            "{\"@type\":\"type.googleapis.com/google.protobuf.Int32Value\",\"value\":1,\"value\":2}",
            "{\"value\":1,\"@type\":\"type.googleapis.com/google.protobuf.Int32Value\",\"value\":2}",
            "{\"value\":1,\"value\":2,\"@type\":\"type.googleapis.com/google.protobuf.Int32Value\"}",
            "{\"@type\":\"type.googleapis.com/google.protobuf.Duration\",\"value\":\"1s\",\"\\u0076alue\":\"2s\"}",
            "{\"value\":\"1s\",\"@type\":\"type.googleapis.com/google.protobuf.Duration\",\"\\u0076alue\":\"2s\"}",
        ]
        for json in inputs {
            for ignoreUnknown in [false, true] {
                var options = JSONDecodingOptions()
                options.ignoreUnknownFields = ignoreUnknown
                XCTAssertThrowsError(try Google_Protobuf_Any(jsonString: json, options: options), json) { error in
                    let pbError = error as? SwiftProtobufError
                    XCTAssertEqual(pbError?.code, .jsonDecodingError)
                    XCTAssertTrue(
                        pbError?.message.hasSuffix(": Field 'value' specified more than once") == true,
                        "Unexpected error message: \(String(describing: pbError?.message))"
                    )
                }
            }
        }
    }

    func test_Any_typeURLOrdering() throws {
        Google_Protobuf_Any.register(messageType: SwiftProtoTesting_TestAllTypes.self)
        Google_Protobuf_Any.register(messageType: SwiftProtoTesting_Test3_TestAllTypesProto3.self)
        Google_Protobuf_Any.register(messageType: SwiftProtoTesting_TestAllExtensions.self)

        // Regular message with @type first, middle, and last (including nested message,
        // repeated field, and finite doubles larger than UInt64.max).
        let regularInputs = [
            #"{"@type":"type.googleapis.com/swift_proto_testing.TestAllTypes","optionalInt32":42,"optionalString":"hi","optionalDouble":18446744073709551616,"optionalNestedMessage":{"bb":7},"repeatedInt32":[1,2,3]}"#,
            #"{"optionalInt32":42,"optionalDouble":18446744073709551616,"@type":"type.googleapis.com/swift_proto_testing.TestAllTypes","optionalString":"hi","optionalNestedMessage":{"bb":7},"repeatedInt32":[1,2,3]}"#,
            #"{"optionalInt32":42,"optionalString":"hi","optionalDouble":18446744073709551616,"optionalNestedMessage":{"bb":7},"repeatedInt32":[1,2,3],"@type":"type.googleapis.com/swift_proto_testing.TestAllTypes"}"#,
        ]
        for json in regularInputs {
            let decodedAny = try Google_Protobuf_Any(jsonString: json)
            let unpacked = try SwiftProtoTesting_TestAllTypes(unpackingAny: decodedAny)
            XCTAssertEqual(unpacked.optionalInt32, 42, json)
            XCTAssertEqual(unpacked.optionalString, "hi", json)
            XCTAssertEqual(unpacked.optionalDouble, 18446744073709551616.0, json)
            XCTAssertEqual(unpacked.optionalNestedMessage.bb, 7, json)
            XCTAssertEqual(unpacked.repeatedInt32, [1, 2, 3], json)
        }

        // Map fields with @type first, middle, and last.
        let mapInputs = [
            #"{"@type":"type.googleapis.com/swift_proto_testing.test3.TestAllTypesProto3","mapInt32Int32":{"1":10,"2":20},"mapStringString":{"a":"x","b":"y"}}"#,
            #"{"mapInt32Int32":{"1":10,"2":20},"@type":"type.googleapis.com/swift_proto_testing.test3.TestAllTypesProto3","mapStringString":{"a":"x","b":"y"}}"#,
            #"{"mapInt32Int32":{"1":10,"2":20},"mapStringString":{"a":"x","b":"y"},"@type":"type.googleapis.com/swift_proto_testing.test3.TestAllTypesProto3"}"#,
        ]
        for json in mapInputs {
            let decodedAny = try Google_Protobuf_Any(jsonString: json)
            let unpacked = try SwiftProtoTesting_Test3_TestAllTypesProto3(unpackingAny: decodedAny)
            XCTAssertEqual(unpacked.mapInt32Int32, [1: 10, 2: 20], json)
            XCTAssertEqual(unpacked.mapStringString, ["a": "x", "b": "y"], json)
        }

        // Oneof members split across @type: null secondary member is allowed, conflicting non-null fails.
        for json in [
            #"{"oneofUint32":42,"@type":"type.googleapis.com/swift_proto_testing.TestAllTypes","oneofString":null}"#,
            #"{"oneofString":null,"@type":"type.googleapis.com/swift_proto_testing.TestAllTypes","oneofUint32":42}"#,
        ] {
            let decodedAny = try Google_Protobuf_Any(jsonString: json)
            let unpacked = try SwiftProtoTesting_TestAllTypes(unpackingAny: decodedAny)
            XCTAssertEqual(unpacked.oneofField, .oneofUint32(42), json)
        }
        for json in [
            #"{"oneofUint32":42,"@type":"type.googleapis.com/swift_proto_testing.TestAllTypes","oneofString":"abc"}"#,
            #"{"oneofUint32":42,"oneofString":"abc","@type":"type.googleapis.com/swift_proto_testing.TestAllTypes"}"#,
        ] {
            XCTAssertThrowsError(try Google_Protobuf_Any(jsonString: json), json) { error in
                XCTAssertEqual((error as? SwiftProtobufError)?.code, .jsonDecodingError)
            }
        }

        // Extensions with @type first, middle, and last.
        let extInputs = [
            #"{"@type":"type.googleapis.com/swift_proto_testing.TestAllExtensions","[swift_proto_testing.optional_int32_extension]":17,"[swift_proto_testing.optional_string_extension]":"ext"}"#,
            #"{"[swift_proto_testing.optional_int32_extension]":17,"@type":"type.googleapis.com/swift_proto_testing.TestAllExtensions","[swift_proto_testing.optional_string_extension]":"ext"}"#,
            #"{"[swift_proto_testing.optional_int32_extension]":17,"[swift_proto_testing.optional_string_extension]":"ext","@type":"type.googleapis.com/swift_proto_testing.TestAllExtensions"}"#,
        ]
        for json in extInputs {
            let decodedAny = try Google_Protobuf_Any(
                jsonString: json,
                extensions: SwiftProtoTesting_Unittest_Extensions
            )
            let unpacked = try SwiftProtoTesting_TestAllExtensions(
                unpackingAny: decodedAny,
                extensions: SwiftProtoTesting_Unittest_Extensions
            )
            XCTAssertEqual(unpacked.SwiftProtoTesting_optionalInt32Extension, 17, json)
            XCTAssertEqual(unpacked.SwiftProtoTesting_optionalStringExtension, "ext", json)
        }

        // WKTs with "value" before @type.
        do {
            let intAny = try Google_Protobuf_Any(
                jsonString: #"{"value":42,"@type":"type.googleapis.com/google.protobuf.Int32Value"}"#
            )
            XCTAssertEqual(try Google_Protobuf_Int32Value(unpackingAny: intAny).value, 42)

            let durationAny = try Google_Protobuf_Any(
                jsonString: #"{"value":"99.001s","@type":"type.googleapis.com/google.protobuf.Duration"}"#
            )
            let duration = try Google_Protobuf_Duration(unpackingAny: durationAny)
            XCTAssertEqual(duration.seconds, 99)
            XCTAssertEqual(duration.nanos, 1_000_000)

            let structAny = try Google_Protobuf_Any(
                jsonString: #"{"value":{"a":1,"b":"two"},"@type":"type.googleapis.com/google.protobuf.Struct"}"#
            )
            let structVal = try Google_Protobuf_Struct(unpackingAny: structAny)
            XCTAssertEqual(structVal.fields["a"]?.numberValue, 1)
            XCTAssertEqual(structVal.fields["b"]?.stringValue, "two")

            let valueAny = try Google_Protobuf_Any(
                jsonString: #"{"value":[1,"x",null,{"k":true}],"@type":"type.googleapis.com/google.protobuf.Value"}"#
            )
            let valueVal = try Google_Protobuf_Value(unpackingAny: valueAny)
            XCTAssertEqual(valueVal.listValue.values.count, 4)
            XCTAssertEqual(valueVal.listValue.values[0].numberValue, 1)
            XCTAssertEqual(valueVal.listValue.values[1].stringValue, "x")
            XCTAssertEqual(valueVal.listValue.values[2].kind, .nullValue(.nullValue))
            XCTAssertEqual(valueVal.listValue.values[3].structValue.fields["k"]?.boolValue, true)

            // Large negative finite integer value before @type in google.protobuf.Value.
            let largeNumAny = try Google_Protobuf_Any(
                jsonString: #"{"value":-18446744073709551616,"@type":"type.googleapis.com/google.protobuf.Value"}"#
            )
            XCTAssertEqual(try Google_Protobuf_Value(unpackingAny: largeNumAny).numberValue, -18446744073709551616.0)

            // Nested Any inside Any with out-of-order @type at both levels.
            let nestedAny = try Google_Protobuf_Any(
                jsonString:
                    #"{"value":{"optionalInt32":7,"@type":"type.googleapis.com/swift_proto_testing.TestAllTypes"},"@type":"type.googleapis.com/google.protobuf.Any"}"#
            )
            let innerAny = try Google_Protobuf_Any(unpackingAny: nestedAny)
            let innerMsg = try SwiftProtoTesting_TestAllTypes(unpackingAny: innerAny)
            XCTAssertEqual(innerMsg.optionalInt32, 7)
        }
    }

    func test_Any_duplicateFieldsSplitAcrossTypeURL() throws {
        Google_Protobuf_Any.register(messageType: SwiftProtoTesting_TestAllTypes.self)
        Google_Protobuf_Any.register(messageType: SwiftProtoTesting_Test3_TestAllTypesProto3.self)
        Google_Protobuf_Any.register(messageType: SwiftProtoTesting_TestAllExtensions.self)

        let regularDuplicates = [
            // Same field before and after @type.
            #"{"optionalInt32":1,"@type":"type.googleapis.com/swift_proto_testing.TestAllTypes","optionalInt32":2}"#,
            // Snake_case and camelCase alias split across @type.
            #"{"optional_int32":1,"@type":"type.googleapis.com/swift_proto_testing.TestAllTypes","optionalInt32":2}"#,
            // Duplicate both before @type.
            #"{"optionalInt32":1,"optionalInt32":2,"@type":"type.googleapis.com/swift_proto_testing.TestAllTypes"}"#,
            // Map field split before and after @type.
            #"{"mapInt32Int32":{"1":10},"@type":"type.googleapis.com/swift_proto_testing.test3.TestAllTypesProto3","mapInt32Int32":{"2":20}}"#,
        ]
        for json in regularDuplicates {
            XCTAssertThrowsError(try Google_Protobuf_Any(jsonString: json), json) { error in
                let pbError = error as? SwiftProtobufError
                XCTAssertEqual(pbError?.code, .jsonDecodingError, json)
                XCTAssertTrue(
                    pbError?.message.contains("specified more than once") == true,
                    "Unexpected error message for \(json): \(String(describing: pbError?.message))"
                )
            }
        }

        let extensionDuplicates = [
            #"{"[swift_proto_testing.optional_int32_extension]":1,"@type":"type.googleapis.com/swift_proto_testing.TestAllExtensions","[swift_proto_testing.optional_int32_extension]":2}"#,
            #"{"[swift_proto_testing.optional_int32_extension]":1,"[swift_proto_testing.optional_int32_extension]":2,"@type":"type.googleapis.com/swift_proto_testing.TestAllExtensions"}"#,
        ]
        for json in extensionDuplicates {
            XCTAssertThrowsError(
                try Google_Protobuf_Any(jsonString: json, extensions: SwiftProtoTesting_Unittest_Extensions),
                json
            ) { error in
                let pbError = error as? SwiftProtobufError
                XCTAssertEqual(pbError?.code, .jsonDecodingError, json)
                XCTAssertTrue(
                    pbError?.message.contains("specified more than once") == true,
                    "Unexpected error message for \(json): \(String(describing: pbError?.message))"
                )
            }
        }
    }

    func test_Any_WKT_omittedValue() throws {
        // An empty Google_Protobuf_Value encodes in Any without a "value" field and must round-trip.
        let emptyValueAny = try Google_Protobuf_Any(packing: Google_Protobuf_Value())
        let encoded = try emptyValueAny.jsonString()
        XCTAssertEqual(encoded, #"{"@type":"type.googleapis.com/google.protobuf.Value"}"#)

        let decodedValueAny = try Google_Protobuf_Any(jsonString: encoded)
        XCTAssertEqual(decodedValueAny.typeURL, "type.googleapis.com/google.protobuf.Value")
        XCTAssertTrue(decodedValueAny.value.isEmpty)
        let unpackedValue = try Google_Protobuf_Value(unpackingAny: decodedValueAny)
        XCTAssertNil(unpackedValue.kind)
        XCTAssertEqual(try decodedValueAny.jsonString(), encoded)

        // Other custom-JSON WKTs with omitted "value" decode to their default-initialized message.
        let omittedIntAny = try Google_Protobuf_Any(
            jsonString: #"{"@type":"type.googleapis.com/google.protobuf.Int32Value"}"#
        )
        XCTAssertEqual(try Google_Protobuf_Int32Value(unpackingAny: omittedIntAny), Google_Protobuf_Int32Value())

        let omittedDurationAny = try Google_Protobuf_Any(
            jsonString: #"{"@type":"type.googleapis.com/google.protobuf.Duration"}"#
        )
        XCTAssertEqual(try Google_Protobuf_Duration(unpackingAny: omittedDurationAny), Google_Protobuf_Duration())

        let omittedStructAny = try Google_Protobuf_Any(
            jsonString: #"{"@type":"type.googleapis.com/google.protobuf.Struct"}"#
        )
        XCTAssertEqual(try Google_Protobuf_Struct(unpackingAny: omittedStructAny), Google_Protobuf_Struct())

        let omittedListAny = try Google_Protobuf_Any(
            jsonString: #"{"@type":"type.googleapis.com/google.protobuf.ListValue"}"#
        )
        XCTAssertEqual(try Google_Protobuf_ListValue(unpackingAny: omittedListAny), Google_Protobuf_ListValue())

        let omittedNestedAny = try Google_Protobuf_Any(
            jsonString: #"{"@type":"type.googleapis.com/google.protobuf.Any"}"#
        )
        XCTAssertEqual(try Google_Protobuf_Any(unpackingAny: omittedNestedAny), Google_Protobuf_Any())

        // Omitted "value" alongside unknown fields respects ignoreUnknownFields.
        for json in [
            #"{"fred":1,"@type":"type.googleapis.com/google.protobuf.Duration"}"#,
            #"{"@type":"type.googleapis.com/google.protobuf.Duration","fred":1}"#,
        ] {
            XCTAssertThrowsError(try Google_Protobuf_Any(jsonString: json), json) { error in
                XCTAssertEqual(error as? AnyUnpackError, .malformedWellKnownTypeJSON, json)
            }
            var options = JSONDecodingOptions()
            options.ignoreUnknownFields = true
            let anyWithIgnored = try Google_Protobuf_Any(jsonString: json, options: options)
            XCTAssertEqual(try Google_Protobuf_Duration(unpackingAny: anyWithIgnored), Google_Protobuf_Duration())
        }
    }

    func test_Any_outOfOrderDepthLimits() throws {
        Google_Protobuf_Any.register(messageType: SwiftProtoTesting_TestAllTypes.self)

        // WKT Value with "value" before @type enforces the exact same depth limit as @type first
        // (1 Any + 1 root Value + 4 nested ListValue + 4 element Values = 10 message levels).
        do {
            let json = #"{"value":[[[[1]]]],"@type":"type.googleapis.com/google.protobuf.Value"}"#
            var options = JSONDecodingOptions()
            options.messageDepthLimit = 9
            XCTAssertThrowsError(try Google_Protobuf_Any(jsonString: json, options: options)) { error in
                let pbError = error as? SwiftProtobufError
                XCTAssertTrue(
                    pbError?.message.hasSuffix(": Message is too deep") == true,
                    "Unexpected error: \(error)"
                )
            }

            options.messageDepthLimit = 10
            let decodedAny = try Google_Protobuf_Any(jsonString: json, options: options)
            let unpacked = try Google_Protobuf_Value(unpackingAny: decodedAny)
            XCTAssertEqual(
                unpacked.listValue.values.first?.listValue.values.first?.listValue.values.first?.listValue.values.first?
                    .numberValue,
                1
            )
        }

        // Regular message with nested message before @type enforces depth limit:
        // 1 Any + 1 TestAllTypes + 1 NestedMessage = 3 messages.
        do {
            let json =
                #"{"optionalNestedMessage":{"bb":42},"@type":"type.googleapis.com/swift_proto_testing.TestAllTypes"}"#
            var options = JSONDecodingOptions()
            options.messageDepthLimit = 2
            XCTAssertThrowsError(try Google_Protobuf_Any(jsonString: json, options: options)) { error in
                let pbError = error as? SwiftProtobufError
                XCTAssertTrue(
                    pbError?.message.hasSuffix(": Message is too deep") == true,
                    "Unexpected error: \(error)"
                )
            }

            options.messageDepthLimit = 3
            let decodedAny = try Google_Protobuf_Any(jsonString: json, options: options)
            let unpacked = try SwiftProtoTesting_TestAllTypes(unpackingAny: decodedAny)
            XCTAssertEqual(unpacked.optionalNestedMessage.bb, 42)
            XCTAssertNoThrow(try decodedAny.jsonString())
        }

        // Nested out-of-order Any chain enforces depth limit at the exact boundary:
        // 3 Any + 1 Int32Value = 4 messages.
        do {
            let nestedThree =
                #"{"value":{"value":{"value":7,"@type":"type.googleapis.com/google.protobuf.Int32Value"},"@type":"type.googleapis.com/google.protobuf.Any"},"@type":"type.googleapis.com/google.protobuf.Any"}"#
            var options = JSONDecodingOptions()
            options.messageDepthLimit = 3
            XCTAssertThrowsError(try Google_Protobuf_Any(jsonString: nestedThree, options: options)) { error in
                let pbError = error as? SwiftProtobufError
                XCTAssertTrue(
                    pbError?.message.hasSuffix(": Message is too deep") == true,
                    "Unexpected error: \(error)"
                )
            }

            options.messageDepthLimit = 4
            let outer = try Google_Protobuf_Any(jsonString: nestedThree, options: options)
            let middle = try Google_Protobuf_Any(unpackingAny: outer)
            let inner = try Google_Protobuf_Any(unpackingAny: middle)
            XCTAssertEqual(try Google_Protobuf_Int32Value(unpackingAny: inner).value, 7)

            // 99 out-of-order Any wrappers + 1 Int32Value = 100 messages total succeeds at default limit 100.
            var deepOutOfOrder = #"{"value":7,"@type":"type.googleapis.com/google.protobuf.Int32Value"}"#
            for _ in 0..<98 {
                deepOutOfOrder = #"{"value":\#(deepOutOfOrder),"@type":"type.googleapis.com/google.protobuf.Any"}"#
            }
            let decodedDeep = try Google_Protobuf_Any(jsonString: deepOutOfOrder)
            XCTAssertTrue(decodedDeep.textFormatString().contains("[type.googleapis.com/google.protobuf.Int32Value]"))
            XCTAssertNoThrow(try decodedDeep.jsonString())

            // 100 out-of-order Any wrappers + 1 Int32Value = 101 messages exceeds default limit 100.
            let tooDeepOutOfOrder = #"{"value":\#(deepOutOfOrder),"@type":"type.googleapis.com/google.protobuf.Any"}"#
            XCTAssertThrowsError(try Google_Protobuf_Any(jsonString: tooDeepOutOfOrder)) { error in
                let pbError = error as? SwiftProtobufError
                XCTAssertTrue(
                    pbError?.message.hasSuffix(": Message is too deep") == true,
                    "Unexpected error: \(error)"
                )
            }
        }
    }

    func test_Any_JSONDepthAccounting() throws {
        Google_Protobuf_Any.register(messageType: SwiftProtoTesting_TestAllTypes.self)
        Google_Protobuf_Any.register(messageType: SwiftProtoTesting_Test3_TestAllTypesProto3.self)
        Google_Protobuf_Any.register(messageType: SwiftProtoTesting_Fuzz_Message.self)

        func wrapInFuzzMessages(outerCount: Int, leafField: String) -> String {
            precondition(outerCount >= 1)
            let nestedCount = outerCount - 1
            return String(repeating: #"{"singularMessage":"#, count: nestedCount)
                + #"{"wktAny":\#(leafField)}"#
                + String(repeating: "}", count: nestedCount)
        }

        // 98 outer messages + 1 Any + 1 packed message = 100 messages: decodes and transcodes cleanly.
        // 99 outer messages + 1 Any + 1 packed message = 101 messages: rejected during JSON decoding.
        let leafAnys = [
            #"{"@type":"type.googleapis.com/google.protobuf.Int32Value","value":7}"#,
            #"{"@type":"type.googleapis.com/swift_proto_testing.TestAllTypes","optionalInt32":7}"#,
        ]
        for leaf in leafAnys {
            let atLimit = wrapInFuzzMessages(outerCount: 98, leafField: leaf)
            let decoded = try SwiftProtoTesting_Fuzz_Message(jsonString: atLimit)
            XCTAssertNoThrow(try decoded.jsonString(), "Failed to re-encode depth-100 Any: \(leaf)")

            let overLimit = wrapInFuzzMessages(outerCount: 99, leafField: leaf)
            XCTAssertThrowsError(try SwiftProtoTesting_Fuzz_Message(jsonString: overLimit), leaf) { error in
                let pbError = error as? SwiftProtobufError
                XCTAssertTrue(
                    pbError?.message.hasSuffix(": Message is too deep") == true,
                    "Unexpected error for \(leaf): \(error)"
                )
            }
        }

        // Omitted `"value"` on a WKT Any and `ListValue` with `"value": null` still count the packed WKT
        // message level (1 Any + 1 WKT = 2 messages).
        for wktAnyJSON in [
            #"{"@type":"type.googleapis.com/google.protobuf.Int32Value"}"#,
            #"{"@type":"type.googleapis.com/google.protobuf.ListValue","value":null}"#,
        ] {
            var options = JSONDecodingOptions()
            options.messageDepthLimit = 1
            XCTAssertThrowsError(try Google_Protobuf_Any(jsonString: wktAnyJSON, options: options), wktAnyJSON) {
                error in
                let pbError = error as? SwiftProtobufError
                XCTAssertTrue(
                    pbError?.message.hasSuffix(": Message is too deep") == true,
                    "Unexpected error for \(wktAnyJSON): \(error)"
                )
            }

            options.messageDepthLimit = 2
            let decoded = try Google_Protobuf_Any(jsonString: wktAnyJSON, options: options)
            XCTAssertNoThrow(try decoded.jsonString(), wktAnyJSON)
        }

        // Alternating Any -> TestAllTypesProto3 -> Any -> ... chains enforce the exact 100-message depth
        // limit in both JSON decoding and JSON encoding.
        var alternatingJSON =
            #"{"@type":"type.googleapis.com/swift_proto_testing.test3.TestAllTypesProto3","optionalInt32":7}"#
        for _ in 0..<49 {
            alternatingJSON =
                #"{"@type":"type.googleapis.com/swift_proto_testing.test3.TestAllTypesProto3","optionalAny":\#(alternatingJSON)}"#
        }
        // 50 Any + 50 TestAllTypesProto3 = 100 messages total: succeeds in both decode and encode.
        let decodedAlternating = try Google_Protobuf_Any(jsonString: alternatingJSON)
        let reencodedAlternating = try decodedAlternating.jsonString()
        XCTAssertTrue(reencodedAlternating.contains(#""optionalInt32":7"#))

        // 50 Any + 50 TestAllTypesProto3 + 1 NestedMessage = 101 messages: fails JSON decode.
        var alternatingOverLimitJSON =
            #"{"@type":"type.googleapis.com/swift_proto_testing.test3.TestAllTypesProto3","optionalNestedMessage":{"a":7}}"#
        for _ in 0..<49 {
            alternatingOverLimitJSON =
                #"{"@type":"type.googleapis.com/swift_proto_testing.test3.TestAllTypesProto3","optionalAny":\#(alternatingOverLimitJSON)}"#
        }
        XCTAssertThrowsError(try Google_Protobuf_Any(jsonString: alternatingOverLimitJSON)) { error in
            let pbError = error as? SwiftProtobufError
            XCTAssertTrue(
                pbError?.message.hasSuffix(": Message is too deep") == true,
                "Unexpected error: \(error)"
            )
        }

        // Binary-constructed alternating chain enforces the same 100-message boundary during JSON encoding.
        var leafProto = SwiftProtoTesting_Test3_TestAllTypesProto3()
        leafProto.optionalInt32 = 7
        var packedAlternating = try Google_Protobuf_Any(packing: leafProto)
        for _ in 0..<49 {
            var holder = SwiftProtoTesting_Test3_TestAllTypesProto3()
            holder.optionalAny = packedAlternating
            packedAlternating = try Google_Protobuf_Any(packing: holder)
        }
        // 50 Any + 50 TestAllTypesProto3 = 100 messages: succeeds.
        XCTAssertNoThrow(try packedAlternating.jsonString())

        // 50 Any + 50 TestAllTypesProto3 + 1 NestedMessage = 101 messages: fails JSON encode.
        var leafWithNested = SwiftProtoTesting_Test3_TestAllTypesProto3()
        leafWithNested.optionalNestedMessage.a = 7
        var packedOverLimit = try Google_Protobuf_Any(packing: leafWithNested)
        for _ in 0..<49 {
            var holder = SwiftProtoTesting_Test3_TestAllTypesProto3()
            holder.optionalAny = packedOverLimit
            packedOverLimit = try Google_Protobuf_Any(packing: holder)
        }
        XCTAssertThrowsError(try packedOverLimit.jsonString()) { error in
            XCTAssertEqual(error as? JSONEncodingError, .anyTranscodeFailure)
        }

        // Scalar-JSON well-known types still materialize a protobuf message and must count
        // toward the recursion budget both directly and when nested inside a regular message
        // packed in `Any` (otherwise depth-101 payloads decode and fail `jsonString()` with
        // `anyTranscodeFailure`).
        let scalarWKTFields = [
            #""wktBoolValue":true"#,
            #""wktBytesValue":"AA==""#,
            #""wktDoubleValue":1.5"#,
            #""wktDuration":"1s""#,
            #""wktFieldMask":"a""#,
            #""wktFloatValue":1.5"#,
            #""wktInt32Value":1"#,
            #""wktInt64Value":"1""#,
            #""wktStringValue":"a""#,
            #""wktTimestamp":"1970-01-01T00:00:00Z""#,
            #""wktUint32Value":1"#,
            #""wktUint64Value":"1""#,
        ]
        var limit1 = JSONDecodingOptions()
        limit1.messageDepthLimit = 1
        var limit2 = JSONDecodingOptions()
        limit2.messageDepthLimit = 2
        XCTAssertEqual(try Google_Protobuf_Int32Value(jsonString: "1", options: limit1).value, 1)

        func nestedScalarWKTInsideAny(nestedCount: Int, fieldJSON: String) -> String {
            #"{"wktAny":{"@type":"type.googleapis.com/swift_proto_testing.fuzz.Message","#
                + String(repeating: #""singularMessage":{"#, count: nestedCount)
                + fieldJSON
                + String(repeating: "}", count: nestedCount)
                + "}}"
        }

        for fieldJSON in scalarWKTFields {
            // Direct field: root message (1) + scalar WKT message (1) = 2 messages.
            let directJSON = "{\(fieldJSON)}"
            XCTAssertThrowsError(try SwiftProtoTesting_Fuzz_Message(jsonString: directJSON, options: limit1)) { error in
                let pbError = error as? SwiftProtobufError
                XCTAssertTrue(
                    pbError?.message.hasSuffix(": Message is too deep") == true,
                    "Unexpected error for \(directJSON): \(error)"
                )
            }
            let decodedDirect = try SwiftProtoTesting_Fuzz_Message(jsonString: directJSON, options: limit2)
            XCTAssertNoThrow(try decodedDirect.jsonString(), directJSON)

            // Root (1) + wktAny (1) + packed Message (1) + 96 singularMessage + scalar WKT (1) = 100.
            let atLimit = nestedScalarWKTInsideAny(nestedCount: 96, fieldJSON: fieldJSON)
            let decodedAtLimit = try SwiftProtoTesting_Fuzz_Message(jsonString: atLimit)
            XCTAssertNoThrow(try decodedAtLimit.jsonString(), "Failed to re-encode depth-100 nested WKT: \(fieldJSON)")

            // Root (1) + wktAny (1) + packed Message (1) + 97 singularMessage + scalar WKT (1) = 101.
            let overLimit = nestedScalarWKTInsideAny(nestedCount: 97, fieldJSON: fieldJSON)
            XCTAssertThrowsError(try SwiftProtoTesting_Fuzz_Message(jsonString: overLimit), fieldJSON) { error in
                let pbError = error as? SwiftProtobufError
                XCTAssertTrue(
                    pbError?.message.hasSuffix(": Message is too deep") == true,
                    "Unexpected error for depth-101 nested WKT \(fieldJSON): \(error)"
                )
            }
        }
    }

    func test_Any_JSONTranscodeMissingRequiredFields() throws {
        Google_Protobuf_Any.register(messageType: SwiftProtoTesting_TestRequired.self)

        // Decoding JSON into Any packs partial binary bytes (missing required fields `b` and `c`);
        // transcoding back to JSON should succeed rather than failing with anyTranscodeFailure.
        let json = #"{"@type":"type.googleapis.com/swift_proto_testing.TestRequired","a":1}"#
        let decoded = try Google_Protobuf_Any(jsonString: json)
        XCTAssertEqual(try decoded.jsonString(), json)

        var partial = SwiftProtoTesting_TestRequired()
        partial.a = 42
        var encodingOptions = BinaryEncodingOptions()
        encodingOptions.allowPartial = true
        let packed = try Google_Protobuf_Any(packing: partial, options: encodingOptions)
        XCTAssertEqual(
            try packed.jsonString(),
            #"{"@type":"type.googleapis.com/swift_proto_testing.TestRequired","a":42}"#
        )
    }

    func test_Any_unregisteredTypeURLWithFields() throws {
        // Fields before and/or after an unregistered @type report unknownAnyTypeURL once syntax is valid.
        for json in [
            #"{"a":1,"@type":"type.googleapis.com/SomeMessage"}"#,
            #"{"@type":"type.googleapis.com/SomeMessage","b":[1,2,3],"c":{"d":true}}"#,
            #"{"a":1,"@type":"type.googleapis.com/SomeMessage","b":"hi"}"#,
        ] {
            XCTAssertThrowsError(try Google_Protobuf_Any(jsonString: json), json) { error in
                XCTAssertTrue(
                    self.isSwiftProtobufErrorEqual(
                        error as! SwiftProtobufError,
                        .JSONDecoding.unknownAnyTypeURL(type_url: "type.googleapis.com/SomeMessage")
                    ),
                    "Unexpected error for \(json): \(error)"
                )
            }
        }

        // Trailing syntax errors after an unregistered @type still throw jsonDecodingError.
        for malformed in [
            #"{"@type":"type.googleapis.com/SomeMessage","b":}"#,
            #"{"@type":"type.googleapis.com/SomeMessage",}"#,
        ] {
            XCTAssertThrowsError(try Google_Protobuf_Any(jsonString: malformed), malformed) { error in
                XCTAssertEqual((error as? SwiftProtobufError)?.code, .jsonDecodingError, malformed)
            }
        }
    }

    func test_IsA() {
        var msg = Google_Protobuf_Any()

        msg.typeURL = "type.googleapis.com/swift_proto_testing.TestAllTypes"
        XCTAssertTrue(msg.isA(SwiftProtoTesting_TestAllTypes.self))
        XCTAssertFalse(msg.isA(Google_Protobuf_Empty.self))
        msg.typeURL = "random.site.org/swift_proto_testing.TestAllTypes"
        XCTAssertTrue(msg.isA(SwiftProtoTesting_TestAllTypes.self))
        XCTAssertFalse(msg.isA(Google_Protobuf_Empty.self))
        msg.typeURL = "/swift_proto_testing.TestAllTypes"
        XCTAssertTrue(msg.isA(SwiftProtoTesting_TestAllTypes.self))
        XCTAssertFalse(msg.isA(Google_Protobuf_Empty.self))
        msg.typeURL = "swift_proto_testing.TestAllTypes"
        XCTAssertTrue(msg.isA(SwiftProtoTesting_TestAllTypes.self))
        XCTAssertFalse(msg.isA(Google_Protobuf_Empty.self))

        msg.typeURL = ""
        XCTAssertFalse(msg.isA(SwiftProtoTesting_TestAllTypes.self))
        XCTAssertFalse(msg.isA(Google_Protobuf_Empty.self))
    }

    func test_Any_Registry() {
        // Registering the same type multiple times is ok.
        XCTAssertTrue(Google_Protobuf_Any.register(messageType: SwiftProtoTesting_Import_ImportMessage.self))
        XCTAssertTrue(Google_Protobuf_Any.register(messageType: SwiftProtoTesting_Import_ImportMessage.self))

        // Registering a different type with the same messageName will fail.
        XCTAssertFalse(Google_Protobuf_Any.register(messageType: ConflictingImportMessage.self))

        // Sanity check that the .proto files weren't changed, and they do have the same name.
        XCTAssertEqual(
            ConflictingImportMessage.protoMessageName,
            SwiftProtoTesting_Import_ImportMessage.protoMessageName
        )

        // Lookup
        XCTAssertTrue(
            Google_Protobuf_Any.messageType(forMessageName: SwiftProtoTesting_Import_ImportMessage.protoMessageName)
                == SwiftProtoTesting_Import_ImportMessage.self
        )
        XCTAssertNil(Google_Protobuf_Any.messageType(forMessageName: SwiftProtoTesting_TestMap.protoMessageName))

        // All the WKTs should be registered.
        let wkts: [any Message.Type] = [
            Google_Protobuf_Any.self,
            Google_Protobuf_BoolValue.self,
            Google_Protobuf_BytesValue.self,
            Google_Protobuf_DoubleValue.self,
            Google_Protobuf_Duration.self,
            Google_Protobuf_Empty.self,
            Google_Protobuf_FieldMask.self,
            Google_Protobuf_FloatValue.self,
            Google_Protobuf_Int32Value.self,
            Google_Protobuf_Int64Value.self,
            Google_Protobuf_ListValue.self,
            Google_Protobuf_StringValue.self,
            Google_Protobuf_Struct.self,
            Google_Protobuf_Timestamp.self,
            Google_Protobuf_UInt32Value.self,
            Google_Protobuf_UInt64Value.self,
            Google_Protobuf_Value.self,
        ]
        for t in wkts {
            XCTAssertTrue(
                Google_Protobuf_Any.messageType(forMessageName: t.protoMessageName) == t,
                "Looking up \(t.protoMessageName)"
            )
        }
    }
}

// Dummy message class to test registration conflicts, this is basically the
// generated code from SwiftProtoTesting_TestEmptyMessage.

struct ConflictingImportMessage: SwiftProtobuf.Message, Sendable {
    static let protoMessageName: String = "swift_proto_testing.import.ImportMessage"

    var messageSchema: MessageSchema { fatalError() }

    var unknownFields = SwiftProtobuf.UnknownStorage()

    init() {}

    func _protobuf_messageStorage(accessToken: MessageStorageToken) -> AnyObject { fatalError() }

    mutating func _protobuf_ensureUniqueStorage(accessToken: MessageStorageToken) {}

    func _protobuf_extensionStorageImpl() -> AnyObject { fatalError() }

    mutating func _protobuf_uniqueExtensionStorageImpl() -> AnyObject { fatalError() }
}
