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
import XCTest
import SwiftProtobuf

final class Test_Any: XCTestCase {

    func test_Any() throws {
        var content = SwiftProtoTesting_TestAllTypes()
        content.optionalInt32 = 7

        var m = SwiftProtoTesting_TestAny()
        m.int32Value = 12
        m.anyValue = try Google_Protobuf_Any(message: content)

        // The Any holding an object can be JSON serialized
        XCTAssertNotNil(try m.jsonString())

        let encoded: [UInt8] = try m.serializedBytes()
        XCTAssertEqual(encoded, [8, 12, 18, 58, 10, 52, 116, 121, 112, 101, 46, 103, 111, 111, 103, 108, 101, 97, 112, 105, 115, 46, 99, 111, 109, 47, 115, 119, 105, 102, 116, 95, 112, 114, 111, 116, 111, 95, 116, 101, 115, 116, 105, 110, 103, 46, 84, 101, 115, 116, 65, 108, 108, 84, 121, 112, 101, 115, 18, 2, 8, 7])
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
        let encoded: [UInt8] =  [8, 12, 18, 42, 10, 36, 88, 47, 89, 47, 115, 119, 105, 102, 116, 95, 112, 114, 111, 116, 111, 95, 116, 101, 115, 116, 105, 110, 103, 46, 84, 101, 115, 116, 65, 108, 108, 84, 121, 112, 101, 115, 18, 2, 8, 7]
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
        let encoded: [UInt8] =  [8, 12, 18, 39, 10, 33, 47, 115, 119, 105, 102, 116, 95, 112, 114, 111, 116, 111, 95, 116, 101, 115, 116, 105, 110, 103, 46, 84, 101, 115, 116, 65, 108, 108, 84, 121, 112, 101, 115, 18, 2, 8, 7]
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
        let encoded: [UInt8] = [8, 12, 18, 38, 10, 32, 115, 119, 105, 102, 116, 95, 112, 114, 111, 116, 111, 95, 116, 101, 115, 116, 105, 110, 103, 46, 84, 101, 115, 116, 65, 108, 108, 84, 121, 112, 101, 115, 18, 2, 8, 7]
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
        m.anyValue = try Google_Protobuf_Any(message: content)

        let encoded = try m.jsonString()
        XCTAssertEqual(encoded, "{\"int32Value\":12,\"anyValue\":{\"@type\":\"type.googleapis.com/swift_proto_testing.TestAllTypes\",\"optionalInt32\":7}}")
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
            XCTAssertEqual([8, 12, 18, 58, 10, 52, 116, 121, 112, 101, 46, 103, 111, 111, 103, 108, 101, 97, 112, 105, 115, 46, 99, 111, 109, 47, 115, 119, 105, 102, 116, 95, 112, 114, 111, 116, 111, 95, 116, 101, 115, 116, 105, 110, 103, 46, 84, 101, 115, 116, 65, 108, 108, 84, 121, 112, 101, 115, 18, 2, 8, 7], try decoded.serializedBytes())
        } catch {
            XCTFail("Failed to decode \(encoded)")
        }
    }

    func test_Any_UnknownUserMessage_JSON() throws {
        Google_Protobuf_Any.register(messageType: SwiftProtoTesting_TestAllTypes.self)
        let start = "{\"int32Value\":12,\"anyValue\":{\"@type\":\"type.googleapis.com/UNKNOWN\",\"optionalInt32\":7}}"
        let decoded = try SwiftProtoTesting_TestAny(jsonString: start)

        // JSON-to-JSON transcoding succeeds
        let recoded = try decoded.jsonString()
        XCTAssertEqual(recoded, start)

        let anyValue = decoded.anyValue
        XCTAssertNotNil(anyValue)
        XCTAssertEqual(anyValue.typeURL, "type.googleapis.com/UNKNOWN")
        XCTAssertEqual(anyValue.value, Data())

        XCTAssertEqual(anyValue.textFormatString(), "type_url: \"type.googleapis.com/UNKNOWN\"\n#json: \"{\\\"optionalInt32\\\":7}\"\n")

        // Verify:  JSON-to-protobuf transcoding should fail here
        // since the Any does not have type information
        XCTAssertThrowsError(try decoded.serializedBytes() as [UInt8])
    }

    func test_Any_UnknownUserMessage_protobuf() throws {
        Google_Protobuf_Any.register(messageType: SwiftProtoTesting_TestAllTypes.self)
        let start: [UInt8] = [8, 12, 18, 33, 10, 27, 116, 121, 112, 101, 46, 103, 111, 111, 103, 108, 101, 97, 112, 105, 115, 46, 99, 111, 109, 47, 85, 78, 75, 78, 79, 87, 78, 18, 2, 8, 7]

        let decoded = try SwiftProtoTesting_TestAny(serializedBytes: start)

        // Protobuf-to-protobuf transcoding succeeds
        let recoded: [UInt8] = try decoded.serializedBytes()
        XCTAssertEqual(recoded, start)

        let anyValue = decoded.anyValue
        XCTAssertNotNil(anyValue)
        XCTAssertEqual(anyValue.typeURL, "type.googleapis.com/UNKNOWN")
        XCTAssertEqual(anyValue.value, Data([8, 7]))

        XCTAssertEqual(anyValue.textFormatString(), "type_url: \"type.googleapis.com/UNKNOWN\"\nvalue: \"\\b\\007\"\n")

        // Protobuf-to-JSON transcoding fails
        XCTAssertThrowsError(try decoded.jsonString())
    }

    func test_Any_Any() throws {
        let start = "{\"optionalAny\":{\"@type\":\"type.googleapis.com/google.protobuf.Any\",\"value\":{\"@type\":\"type.googleapis.com/google.protobuf.Int32Value\",\"value\":1}}}"
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
        XCTAssertEqual(protobuf, [138, 19, 95, 10, 39, 116, 121, 112, 101, 46, 103, 111, 111, 103, 108, 101, 97, 112, 105, 115, 46, 99, 111, 109, 47, 103, 111, 111, 103, 108, 101, 46, 112, 114, 111, 116, 111, 98, 117, 102, 46, 65, 110, 121, 18, 52, 10, 46, 116, 121, 112, 101, 46, 103, 111, 111, 103, 108, 101, 97, 112, 105, 115, 46, 99, 111, 109, 47, 103, 111, 111, 103, 108, 101, 46, 112, 114, 111, 116, 111, 98, 117, 102, 46, 73, 110, 116, 51, 50, 86, 97, 108, 117, 101, 18, 2, 8, 1])

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
           return try Google_Protobuf_Any(message: nestedAny(i - 1))
        }
        let any = try nestedAny(5)
        let encoded: [UInt8] = try any.serializedBytes()
        XCTAssertEqual(encoded.count, 214)
    }

    func test_Any_Duration_JSON_roundtrip() throws {
        let start = "{\"optionalAny\":{\"@type\":\"type.googleapis.com/google.protobuf.Duration\",\"value\":\"99.001s\"}}"
        do {
            let decoded = try SwiftProtoTesting_Test3_TestAllTypesProto3(jsonString: start)

            XCTAssertNotNil(decoded.optionalAny)
            let anyField = decoded.optionalAny
            do {
                let unpacked = try Google_Protobuf_Duration(unpackingAny: anyField)
                XCTAssertEqual(unpacked.seconds, 99)
                XCTAssertEqual(unpacked.nanos, 1000000)
            } catch {
                XCTFail("Failed to unpack \(anyField)")
            }

            let encoded = try decoded.jsonString()
            XCTAssertEqual(encoded, start)
        } catch {
            XCTFail("Failed to decode \(start)")
        }
    }

    func test_Any_Duration_transcode() throws {
        let start = "{\"optionalAny\":{\"@type\":\"type.googleapis.com/google.protobuf.Duration\",\"value\":\"99.001s\"}}"
        do {
            let decoded = try SwiftProtoTesting_Test3_TestAllTypesProto3(jsonString: start)
            let protobuf: [UInt8] = try decoded.serializedBytes()
            XCTAssertEqual(protobuf, [138, 19, 54, 10, 44, 116, 121, 112, 101, 46, 103, 111, 111, 103, 108, 101, 97, 112, 105, 115, 46, 99, 111, 109, 47, 103, 111, 111, 103, 108, 101, 46, 112, 114, 111, 116, 111, 98, 117, 102, 46, 68, 117, 114, 97, 116, 105, 111, 110, 18, 6, 8, 99, 16, 192, 132, 61])
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

    func test_Any_FieldMask_JSON_roundtrip() throws {
        let start = "{\"optionalAny\":{\"@type\":\"type.googleapis.com/google.protobuf.FieldMask\",\"value\":\"foo,bar.bazQuux\"}}"
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
        let start = "{\"optionalAny\":{\"@type\":\"type.googleapis.com/google.protobuf.FieldMask\",\"value\":\"foo,bar.bazQuux\"}}"
        do {
            let decoded = try SwiftProtoTesting_Test3_TestAllTypesProto3(jsonString: start)
            let protobuf: [UInt8] = try decoded.serializedBytes()
            XCTAssertEqual(protobuf, [138, 19, 68, 10, 45, 116, 121, 112, 101, 46, 103, 111, 111, 103, 108, 101, 97, 112, 105, 115, 46, 99, 111, 109, 47, 103, 111, 111, 103, 108, 101, 46, 112, 114, 111, 116, 111, 98, 117, 102, 46, 70, 105, 101, 108, 100, 77, 97, 115, 107, 18, 19, 10, 3, 102, 111, 111, 10, 12, 98, 97, 114, 46, 98, 97, 122, 95, 113, 117, 117, 120])
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
            XCTAssertEqual(protobuf, [138, 19, 52, 10, 46, 116, 121, 112, 101, 46, 103, 111, 111, 103, 108, 101, 97, 112, 105, 115, 46, 99, 111, 109, 47, 103, 111, 111, 103, 108, 101, 46, 112, 114, 111, 116, 111, 98, 117, 102, 46, 73, 110, 116, 51, 50, 86, 97, 108, 117, 101, 18, 2, 8, 1])
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
        let start = "{\"optionalAny\":{\"@type\":\"type.googleapis.com/google.protobuf.Struct\",\"value\":{\"foo\":1}}}"
        do {
            let decoded = try SwiftProtoTesting_Test3_TestAllTypesProto3(jsonString: start)
            XCTAssertNotNil(decoded.optionalAny)
            let anyField = decoded.optionalAny
            do {
                let unpacked = try Google_Protobuf_Struct(unpackingAny: anyField)
                XCTAssertEqual(unpacked.fields["foo"], Google_Protobuf_Value(numberValue:1))
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
        let start = "{\"optionalAny\":{\"@type\":\"type.googleapis.com/google.protobuf.Struct\",\"value\":{\"foo\":1.0}}}"
        do {
            let decoded = try SwiftProtoTesting_Test3_TestAllTypesProto3(jsonString: start)
            let protobuf: [UInt8] = try decoded.serializedBytes()
            XCTAssertEqual(protobuf, [138, 19, 64, 10, 42, 116, 121, 112, 101, 46, 103, 111, 111, 103, 108, 101, 97, 112, 105, 115, 46, 99, 111, 109, 47, 103, 111, 111, 103, 108, 101, 46, 112, 114, 111, 116, 111, 98, 117, 102, 46, 83, 116, 114, 117, 99, 116, 18, 18, 10, 16, 10, 3, 102, 111, 111, 18, 9, 17, 0, 0, 0, 0, 0, 0, 240, 63])
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
        let start = "{\"optionalAny\":{\"@type\":\"type.googleapis.com/google.protobuf.Timestamp\",\"value\":\"1970-01-01T00:00:01Z\"}}"
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
        let start = "{\"optionalAny\":{\"@type\":\"type.googleapis.com/google.protobuf.Timestamp\",\"value\":\"1970-01-01T00:00:01.000000001Z\"}}"
        do {
            let decoded = try SwiftProtoTesting_Test3_TestAllTypesProto3(jsonString: start)
            let protobuf: [UInt8] = try decoded.serializedBytes()
            XCTAssertEqual(protobuf, [138, 19, 53, 10, 45, 116, 121, 112, 101, 46, 103, 111, 111, 103, 108, 101, 97, 112, 105, 115, 46, 99, 111, 109, 47, 103, 111, 111, 103, 108, 101, 46, 112, 114, 111, 116, 111, 98, 117, 102, 46, 84, 105, 109, 101, 115, 116, 97, 109, 112, 18, 4, 8, 1, 16, 1])
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
        let start = "{\"optionalAny\":{\"@type\":\"type.googleapis.com/google.protobuf.ListValue\",\"value\":[\"foo\",1]}}"
        do {
            let decoded = try SwiftProtoTesting_Test3_TestAllTypesProto3(jsonString: start)
            let anyField = decoded.optionalAny
            do {
                let unpacked = try Google_Protobuf_ListValue(unpackingAny: anyField)
                XCTAssertEqual(unpacked.values, [Google_Protobuf_Value(stringValue: "foo"), Google_Protobuf_Value(numberValue: 1)])
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
        let start = "{\"optionalAny\":{\"@type\":\"type.googleapis.com/google.protobuf.ListValue\",\"value\":[1.0,\"abc\"]}}"
        do {
            let decoded = try SwiftProtoTesting_Test3_TestAllTypesProto3(jsonString: start)
            let protobuf: [UInt8] = try decoded.serializedBytes()
            XCTAssertEqual(protobuf, [138, 19, 67, 10, 45, 116, 121, 112, 101, 46, 103, 111, 111, 103, 108, 101, 97, 112, 105, 115, 46, 99, 111, 109, 47, 103, 111, 111, 103, 108, 101, 46, 112, 114, 111, 116, 111, 98, 117, 102, 46, 76, 105, 115, 116, 86, 97, 108, 117, 101, 18, 18, 10, 9, 17, 0, 0, 0, 0, 0, 0, 240, 63, 10, 5, 26, 3, 97, 98, 99])
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
        let start1 = "{\"optionalAny\":{\"@type\":\"type.googleapis.com/google.protobuf.Value\",\"value\":{\"foo\":1}}}"
        do {
            let decoded1 = try SwiftProtoTesting_Test3_TestAllTypesProto3(jsonString: start1)
            XCTAssertNotNil(decoded1.optionalAny)
            let anyField = decoded1.optionalAny
            XCTAssertThrowsError(try Google_Protobuf_Struct(unpackingAny: anyField))
            do {
                let unpacked = try Google_Protobuf_Value(unpackingAny: anyField)
                XCTAssertEqual(unpacked.structValue.fields["foo"], Google_Protobuf_Value(numberValue:1))
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
        let start = "{\"optionalAny\":{\"@type\":\"type.googleapis.com/google.protobuf.Value\",\"value\":{\"foo\":1.0}}}"
        do {
            let decoded = try SwiftProtoTesting_Test3_TestAllTypesProto3(jsonString: start)
            let protobuf: [UInt8] = try decoded.serializedBytes()
            XCTAssertEqual(protobuf, [138, 19, 65, 10, 41, 116, 121, 112, 101, 46, 103, 111, 111, 103, 108, 101, 97, 112, 105, 115, 46, 99, 111, 109, 47, 103, 111, 111, 103, 108, 101, 46, 112, 114, 111, 116, 111, 98, 117, 102, 46, 86, 97, 108, 117, 101, 18, 20, 42, 18, 10, 16, 10, 3, 102, 111, 111, 18, 9, 17, 0, 0, 0, 0, 0, 0, 240, 63])
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
        let start2 = "{\"optionalAny\":{\"@type\":\"type.googleapis.com/google.protobuf.Value\",\"value\":1}}"
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
            XCTAssertEqual(protobuf, [138, 19, 54, 10, 41, 116, 121, 112, 101, 46, 103, 111, 111, 103, 108, 101, 97, 112, 105, 115, 46, 99, 111, 109, 47, 103, 111, 111, 103, 108, 101, 46, 112, 114, 111, 116, 111, 98, 117, 102, 46, 86, 97, 108, 117, 101, 18, 9, 17, 0, 0, 0, 0, 0, 0, 240, 63])
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
            XCTAssertEqual(protobuf, [138, 19, 50, 10, 41, 116, 121, 112, 101, 46, 103, 111, 111, 103, 108, 101, 97, 112, 105, 115, 46, 99, 111, 109, 47, 103, 111, 111, 103, 108, 101, 46, 112, 114, 111, 116, 111, 98, 117, 102, 46, 86, 97, 108, 117, 101, 18, 5, 26, 3, 97, 98, 99])
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
      XCTAssertEqual(newJSON, "{\"optionalAny\":{\"@type\":\"Odd\\nType\\\" prefix/google.protobuf.Value\",\"value\":\"abc\"}}")
    }

    func test_Any_OddTypeURL_FromMessage() throws {
      let valueMsg = Google_Protobuf_Value.with {
        $0.stringValue = "abc"
      }
      var msg = SwiftProtoTesting_Test3_TestAllTypesProto3()
      msg.optionalAny = try Google_Protobuf_Any(message: valueMsg, typePrefix: "Odd\nPrefix\"")
      let newJSON = try msg.jsonString()
      XCTAssertEqual(newJSON, "{\"optionalAny\":{\"@type\":\"Odd\\nPrefix\\\"/google.protobuf.Value\",\"value\":\"abc\"}}")
    }

    func test_Any_JSON_Extensions() throws {
      var content = SwiftProtoTesting_TestAllExtensions()
      content.SwiftProtoTesting_optionalInt32Extension = 17

      var msg = SwiftProtoTesting_TestAny()
      msg.anyValue = try Google_Protobuf_Any(message: content)

      let json = try msg.jsonString()
      XCTAssertEqual(json, "{\"anyValue\":{\"@type\":\"type.googleapis.com/swift_proto_testing.TestAllExtensions\",\"[swift_proto_testing.optional_int32_extension]\":17}}")

      // Decode the outer message without any extension knowledge
      let decoded = try SwiftProtoTesting_TestAny(jsonString: json)
      // Decoding the inner content fails without extension info
      XCTAssertThrowsError(try SwiftProtoTesting_TestAllExtensions(unpackingAny: decoded.anyValue))
      // Succeeds if you do provide extension info
      let decodedContent = try SwiftProtoTesting_TestAllExtensions(unpackingAny: decoded.anyValue,
        extensions: SwiftProtoTesting_Unittest_Extensions)
      XCTAssertEqual(content, decodedContent)

      // Transcoding should fail without extension info
      XCTAssertThrowsError(try decoded.serializedBytes() as [UInt8])

      // Decode the outer message with extension information
      let decodedWithExtensions = try SwiftProtoTesting_TestAny(jsonString: json,
        extensions: SwiftProtoTesting_Unittest_Extensions)
      // Still fails; the Any doesn't record extensions that were in effect when the outer Any was decoded
      XCTAssertThrowsError(try SwiftProtoTesting_TestAllExtensions(unpackingAny: decodedWithExtensions.anyValue))
      let decodedWithExtensionsContent = try SwiftProtoTesting_TestAllExtensions(unpackingAny: decodedWithExtensions.anyValue,
        extensions: SwiftProtoTesting_Unittest_Extensions)
      XCTAssertEqual(content, decodedWithExtensionsContent)

      XCTAssertTrue(Google_Protobuf_Any.register(messageType: SwiftProtoTesting_TestAllExtensions.self))
      // Throws because the extensions can't be implicitly transcoded
      XCTAssertThrowsError(try decodedWithExtensions.serializedBytes() as [UInt8])
    }

    func test_Any_WKT_UnknownFields() throws {
      let testcases = [
        // unknown field before value
        "{\"optionalAny\":{\"@type\":\"type.googleapis.com/google.protobuf.Duration\",\"fred\":1,\"value\":\"99.001s\"}}",
        // unknown field after value
        "{\"optionalAny\":{\"@type\":\"type.googleapis.com/google.protobuf.Duration\",\"value\":\"99.001s\",\"fred\":1}}",
      ]
      for json in testcases {
        for ignoreUnknown in [false, true] {
          var options = JSONDecodingOptions()
          options.ignoreUnknownFields = ignoreUnknown
          // This may appear a little odd, since Any lazy parses, this will
          // always succeed because the Any isn't decoded until requested.
          let decoded = try! SwiftProtoTesting_Test3_TestAllTypesProto3(jsonString: json, options: options)

          XCTAssertNotNil(decoded.optionalAny)
          let anyField = decoded.optionalAny
          do {
            let unpacked = try Google_Protobuf_Duration(unpackingAny: anyField)
            XCTAssertTrue(ignoreUnknown)  // Should have throw if not ignoring unknowns.
            XCTAssertEqual(unpacked.seconds, 99)
            XCTAssertEqual(unpacked.nanos, 1000000)
          } catch {
            XCTAssertTrue(!ignoreUnknown)
          }

          // The extra field should still be there.
          let encoded = try decoded.jsonString()
          XCTAssertEqual(encoded, json)
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

    func test_Any_nestedList() throws {
      var start = "{\"optionalAny\":{\"x\":"
      for _ in 0...10000 {
        start.append("[")
      }
      XCTAssertThrowsError(
        // This should fail because the deeply-nested array is not closed
        // It should not crash from exhausting stack space
        try SwiftProtoTesting_Test3_TestAllTypesProto3(jsonString: start)
      )
      for _ in 0...10000 {
        start.append("]")
      }
      start.append("}}")
      // This should succeed because the deeply-nested array is properly closed
      // It should not crash from exhausting stack space and should
      // not fail due to recursion limits (because when skipping, those are
      // only applied to objects).
      _ = try SwiftProtoTesting_Test3_TestAllTypesProto3(jsonString: start)
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
      XCTAssertEqual(ConflictingImportMessage.protoMessageName, SwiftProtoTesting_Import_ImportMessage.protoMessageName)

      // Lookup
      XCTAssertTrue(Google_Protobuf_Any.messageType(forMessageName: SwiftProtoTesting_Import_ImportMessage.protoMessageName) == SwiftProtoTesting_Import_ImportMessage.self)
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
        XCTAssertTrue(Google_Protobuf_Any.messageType(forMessageName: t.protoMessageName) == t,
                      "Looking up \(t.protoMessageName)")
      }
    }
}

// Dummy message class to test registration conflicts, this is basically the
// generated code from SwiftProtoTesting_TestEmptyMessage.

struct ConflictingImportMessage:
    SwiftProtobuf.Message,
    SwiftProtobuf._MessageImplementationBase,
    SwiftProtobuf._ProtoNameProviding,
    @unchecked Sendable {  // Once swift(>=5.9) the '@unchecked' can be removed, it is needed for Data on linux.
  static let protoMessageName: String = "swift_proto_testing.import.ImportMessage"

  var unknownFields = SwiftProtobuf.UnknownStorage()

  init() {}

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let _ = try decoder.nextFieldNumber() {
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    try unknownFields.traverse(visitor: &visitor)
  }

  static let _protobuf_nameMap: SwiftProtobuf._NameMap = SwiftProtobuf._NameMap()

  static func ==(lhs: ConflictingImportMessage, rhs: ConflictingImportMessage) -> Bool {
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}
