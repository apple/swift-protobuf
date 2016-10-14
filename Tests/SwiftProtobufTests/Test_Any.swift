// Test/Sources/TestSuite/Test_Any.swift - Verify well-known Any type
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
/// Any is tricky.  Some of the more interesting cases:
/// * Transcoding protobuf to/from JSON with or without the schema being known
/// * Any fields that contain well-known or user-defined types
/// * Any fields that contain Any fields
///
// -----------------------------------------------------------------------------

import Foundation
import XCTest
import SwiftProtobuf

class Test_Any: XCTestCase {

    func test_Any() throws {
        var content = ProtobufUnittest_TestAllTypes()
        content.optionalInt32 = 7
        XCTAssertEqual(content.anyTypeURL, "type.googleapis.com/protobuf_unittest.TestAllTypes")

        var m = ProtobufUnittest_TestAny()
        m.int32Value = 12
        m.anyValue = Google_Protobuf_Any(message: content)

        // The Any holding an object can be JSON serialized
        XCTAssertNotNil(try m.serializeJSON())

        let encoded = try m.serializeProtobufBytes()
        XCTAssertEqual(encoded, [8, 12, 18, 56, 10, 50, 116, 121, 112, 101, 46, 103, 111, 111, 103, 108, 101, 97, 112, 105, 115, 46, 99, 111, 109, 47, 112, 114, 111, 116, 111, 98, 117, 102, 95, 117, 110, 105, 116, 116, 101, 115, 116, 46, 84, 101, 115, 116, 65, 108, 108, 84, 121, 112, 101, 115, 18, 2, 8, 7])
        let decoded = try ProtobufUnittest_TestAny(protobufBytes: encoded)
        XCTAssertEqual(decoded.anyValue.typeURL, "type.googleapis.com/protobuf_unittest.TestAllTypes")
        let decoded_value = decoded.anyValue.value
        if let decoded_value = decoded_value {
            XCTAssertEqual(decoded_value, Data(bytes: [8, 7]))
        }
        XCTAssertEqual(decoded.int32Value, 12)
        XCTAssertNotNil(decoded.anyValue)
        let any = decoded.anyValue
        do {
            let extracted = try ProtobufUnittest_TestAllTypes(any: any)
            XCTAssertEqual(extracted.optionalInt32, 7)
        } catch {
            XCTFail("Failed to unpack \(any)")
        }

        XCTAssertThrowsError(try ProtobufUnittest_TestEmptyMessage(any: any))
        let recoded = try decoded.serializeProtobufBytes()
        XCTAssertEqual(encoded, recoded)
    }

    /// The typeURL prefix should be ignored for purposes of determining the actual type.
    /// The prefix is only used for dynamically loading type data from a remote server
    /// (There are currently no such servers, and no plans to build any.)
    ///
    /// This test verifies that we can decode an Any with a different prefix
    func test_Any_different_prefix() throws {
        let encoded =  Data(bytes: [8, 12, 18, 40, 10, 34, 88, 47, 89, 47, 112, 114, 111, 116, 111, 98, 117, 102, 95, 117, 110, 105, 116, 116, 101, 115, 116, 46, 84, 101, 115, 116, 65, 108, 108, 84, 121, 112, 101, 115, 18, 2, 8, 7])
        let decoded: ProtobufUnittest_TestAny
        do {
            decoded = try ProtobufUnittest_TestAny(protobuf: encoded)
        } catch {
            XCTFail("Failed to decode \(encoded): \(error)")
            return
        }
        XCTAssertEqual(decoded.anyValue.typeURL, "X/Y/protobuf_unittest.TestAllTypes")
        let decoded_value = decoded.anyValue.value
        if let decoded_value = decoded_value {
            XCTAssertEqual(decoded_value, Data(bytes: [8, 7]))
        }
        XCTAssertEqual(decoded.int32Value, 12)
        XCTAssertNotNil(decoded.anyValue)
        let any = decoded.anyValue
        do {
            let extracted = try ProtobufUnittest_TestAllTypes(any: any)
            XCTAssertEqual(extracted.optionalInt32, 7)
        } catch {
            XCTFail("Failed to unpack \(any)")
        }

        XCTAssertThrowsError(try ProtobufUnittest_TestEmptyMessage(any: any))
        let recoded = try decoded.serializeProtobuf()
        XCTAssertEqual(encoded, recoded)
    }

    /// The typeURL prefix should be ignored for purposes of determining the actual type.
    /// The prefix is only used for dynamically loading type data from a remote server
    /// (There are currently no such servers, and no plans to build any.)
    ///
    /// This test verifies that we can decode an Any with an empty prefix
    func test_Any_noprefix() throws {
        let encoded =  Data(bytes: [8, 12, 18, 37, 10, 31, 47, 112, 114, 111, 116, 111, 98, 117, 102, 95, 117, 110, 105, 116, 116, 101, 115, 116, 46, 84, 101, 115, 116, 65, 108, 108, 84, 121, 112, 101, 115, 18, 2, 8, 7])
        let decoded: ProtobufUnittest_TestAny
        do {
            decoded = try ProtobufUnittest_TestAny(protobuf: encoded)
        } catch {
            XCTFail("Failed to decode \(encoded): \(error)")
            return
        }
        XCTAssertEqual(decoded.anyValue.typeURL, "/protobuf_unittest.TestAllTypes")
        let decoded_value = decoded.anyValue.value
        if let decoded_value = decoded_value {
            XCTAssertEqual(decoded_value, Data(bytes: [8, 7]))
        }
        XCTAssertEqual(decoded.int32Value, 12)
        XCTAssertNotNil(decoded.anyValue)
        let any = decoded.anyValue
        do {
            let extracted = try ProtobufUnittest_TestAllTypes(any: any)
            XCTAssertEqual(extracted.optionalInt32, 7)
        } catch {
            XCTFail("Failed to unpack \(any)")
        }

        XCTAssertThrowsError(try ProtobufUnittest_TestEmptyMessage(any: any))
        let recoded = try decoded.serializeProtobuf()
        XCTAssertEqual(encoded, recoded)
    }

    /// Though Google discourages this, we should be able to match and decode an Any
    /// if the typeURL holds just the type name:
    func test_Any_shortesttype() throws {
        let encoded = Data(bytes: [8, 12, 18, 36, 10, 30, 112, 114, 111, 116, 111, 98, 117, 102, 95, 117, 110, 105, 116, 116, 101, 115, 116, 46, 84, 101, 115, 116, 65, 108, 108, 84, 121, 112, 101, 115, 18, 2, 8, 7])
        let decoded: ProtobufUnittest_TestAny
        do {
            decoded = try ProtobufUnittest_TestAny(protobuf: encoded)
        } catch {
            XCTFail("Failed to decode \(encoded): \(error)")
            return
        }
        XCTAssertEqual(decoded.anyValue.typeURL, "protobuf_unittest.TestAllTypes")
        let decoded_value = decoded.anyValue.value
        if let decoded_value = decoded_value {
            XCTAssertEqual(decoded_value, Data(bytes: [8, 7]))
        }
        XCTAssertEqual(decoded.int32Value, 12)
        XCTAssertNotNil(decoded.anyValue)
        let any = decoded.anyValue
        do {
            let extracted = try ProtobufUnittest_TestAllTypes(any: any)
            XCTAssertEqual(extracted.optionalInt32, 7)
        } catch {
            XCTFail("Failed to unpack \(any)")
        }

        XCTAssertThrowsError(try ProtobufUnittest_TestEmptyMessage(any: any))
        let recoded = try decoded.serializeProtobuf()
        XCTAssertEqual(encoded, recoded)
    }

    func test_Any_UserMessage() throws {
        Google_Protobuf_Any.register(messageType: ProtobufUnittest_TestAllTypes.self)
        var content = ProtobufUnittest_TestAllTypes()
        content.optionalInt32 = 7

        var m = ProtobufUnittest_TestAny()
        m.int32Value = 12
        m.anyValue = Google_Protobuf_Any(message: content)

        let encoded = try m.serializeJSON()
        XCTAssertEqual(encoded, "{\"int32Value\":12,\"anyValue\":{\"@type\":\"type.googleapis.com/protobuf_unittest.TestAllTypes\",\"optionalInt32\":7}}")
        do {
            let decoded = try ProtobufUnittest_TestAny(json: encoded)
            XCTAssertNotNil(decoded.anyValue)
            let decoded_value = decoded.anyValue.value
            XCTAssertNotNil(decoded_value)
            if let decoded_value = decoded_value {
                XCTAssertEqual(Data(bytes: [8, 7]), decoded_value)
            }
            XCTAssertEqual(decoded.int32Value, 12)
            XCTAssertNotNil(decoded.anyValue)
            let any = decoded.anyValue
            do {
                let extracted = try ProtobufUnittest_TestAllTypes(any: any)
                XCTAssertEqual(extracted.optionalInt32, 7)
                XCTAssertThrowsError(try ProtobufUnittest_TestEmptyMessage(any: any))
            } catch {
                XCTFail("Failed to unpack \(any)")
            }
            let recoded = try decoded.serializeJSON()
            XCTAssertEqual(encoded, recoded)
            XCTAssertEqual([8, 12, 18, 56, 10, 50, 116, 121, 112, 101, 46, 103, 111, 111, 103, 108, 101, 97, 112, 105, 115, 46, 99, 111, 109, 47, 112, 114, 111, 116, 111, 98, 117, 102, 95, 117, 110, 105, 116, 116, 101, 115, 116, 46, 84, 101, 115, 116, 65, 108, 108, 84, 121, 112, 101, 115, 18, 2, 8, 7], try decoded.serializeProtobufBytes())
        } catch {
            XCTFail("Failed to decode \(encoded)")
        }
    }

    func test_Any_UnknownUserMessage_JSON() throws {
        Google_Protobuf_Any.register(messageType: ProtobufUnittest_TestAllTypes.self )
        let start = "{\"int32Value\":12,\"anyValue\":{\"@type\":\"type.googleapis.com/UNKNOWN\",\"optionalInt32\":7}}"
        let decoded = try ProtobufUnittest_TestAny(json: start)

        // JSON-to-JSON transcoding succeeds
        let recoded = try decoded.serializeJSON()
        XCTAssertEqual(recoded, start)

        let anyValue = decoded.anyValue
        XCTAssertNotNil(anyValue)
        XCTAssertEqual(anyValue.typeURL, "type.googleapis.com/UNKNOWN")
        XCTAssertNil(anyValue.value)

        // Verify:  JSON-to-protobuf transcoding should fail here
        // since the Any does not have type information
        XCTAssertThrowsError(try decoded.serializeProtobufBytes())
    }

    func test_Any_UnknownUserMessage_protobuf() throws {
        Google_Protobuf_Any.register(messageType: ProtobufUnittest_TestAllTypes.self)
        let start = Data(bytes: [8, 12, 18, 33, 10, 27, 116, 121, 112, 101, 46, 103, 111, 111, 103, 108, 101, 97, 112, 105, 115, 46, 99, 111, 109, 47, 85, 78, 75, 78, 79, 87, 78, 18, 2, 8, 7])

        let decoded = try ProtobufUnittest_TestAny(protobuf: start)

        // Protobuf-to-protobuf transcoding succeeds
        let recoded = try decoded.serializeProtobuf()
        XCTAssertEqual(recoded, start)

        let anyValue = decoded.anyValue
        XCTAssertNotNil(anyValue)
        XCTAssertEqual(anyValue.typeURL, "type.googleapis.com/UNKNOWN")
        XCTAssertEqual(anyValue.value!, Data(bytes: [8, 7]))

        // Protobuf-to-JSON transcoding fails
        XCTAssertThrowsError(try decoded.serializeJSON())
    }

    func test_Any_Any() throws {
        let start = "{\"optionalAny\":{\"@type\":\"type.googleapis.com/google.protobuf.Any\",\"value\":{\"@type\":\"type.googleapis.com/google.protobuf.Int32Value\",\"value\":1}}}"
        do {
            let decoded = try Conformance_TestAllTypes(json: start)
            XCTAssertNotNil(decoded.optionalAny)
            let outerAny = decoded.optionalAny
            do {
                let innerAny = try Google_Protobuf_Any(any: outerAny)
                do {
                    let value = try Google_Protobuf_Int32Value(any: innerAny)
                    XCTAssertEqual(value.value, 1)
                } catch {
                    XCTFail("Failed to decode innerAny")
                    return
                }
            } catch {
                XCTFail("Failed to unpack outerAny \(outerAny): \(error)")
                return
            }

            let protobuf = try decoded.serializeProtobuf()
            XCTAssertEqual(protobuf, Data(bytes: [138, 19, 95, 10, 39, 116, 121, 112, 101, 46, 103, 111, 111, 103, 108, 101, 97, 112, 105, 115, 46, 99, 111, 109, 47, 103, 111, 111, 103, 108, 101, 46, 112, 114, 111, 116, 111, 98, 117, 102, 46, 65, 110, 121, 18, 52, 10, 46, 116, 121, 112, 101, 46, 103, 111, 111, 103, 108, 101, 97, 112, 105, 115, 46, 99, 111, 109, 47, 103, 111, 111, 103, 108, 101, 46, 112, 114, 111, 116, 111, 98, 117, 102, 46, 73, 110, 116, 51, 50, 86, 97, 108, 117, 101, 18, 2, 8, 1]))
            let redecoded = try Conformance_TestAllTypes(protobuf: protobuf)
            let json = try redecoded.serializeJSON()
            XCTAssertEqual(json, start)
            let recoded = try decoded.serializeJSON()
            XCTAssertEqual(recoded, start)
        } catch {
            XCTFail("Failed to decode \(start)")
        }
    }

    func test_Any_Duration_JSON_roundtrip() throws {
        let start = "{\"optionalAny\":{\"@type\":\"type.googleapis.com/google.protobuf.Duration\",\"value\":\"99.001s\"}}"
        do {
            let decoded = try Conformance_TestAllTypes(json: start)

            XCTAssertNotNil(decoded.optionalAny)
            let anyField = decoded.optionalAny
            do {
                let unpacked = try Google_Protobuf_Duration(any: anyField)
                XCTAssertEqual(unpacked.seconds, 99)
                XCTAssertEqual(unpacked.nanos, 1000000)
            } catch {
                XCTFail("Failed to unpack \(anyField)")
            }

            let encoded = try decoded.serializeJSON()
            XCTAssertEqual(encoded, start)
        } catch {
            XCTFail("Failed to decode \(start)")
        }
    }

    func test_Any_Duration_transcode() throws {
        let start = "{\"optionalAny\":{\"@type\":\"type.googleapis.com/google.protobuf.Duration\",\"value\":\"99.001s\"}}"
        do {
            let decoded = try Conformance_TestAllTypes(json: start)
            let protobuf = try decoded.serializeProtobuf()
            XCTAssertEqual(protobuf, Data(bytes: [138, 19, 54, 10, 44, 116, 121, 112, 101, 46, 103, 111, 111, 103, 108, 101, 97, 112, 105, 115, 46, 99, 111, 109, 47, 103, 111, 111, 103, 108, 101, 46, 112, 114, 111, 116, 111, 98, 117, 102, 46, 68, 117, 114, 97, 116, 105, 111, 110, 18, 6, 8, 99, 16, 192, 132, 61]))
            do {
                let redecoded = try Conformance_TestAllTypes(protobuf: protobuf)
                let json = try redecoded.serializeJSON()
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
            let decoded = try Conformance_TestAllTypes(json: start)
            XCTAssertNotNil(decoded.optionalAny)
            let anyField = decoded.optionalAny
            do {
                let unpacked = try Google_Protobuf_FieldMask(any: anyField)
                XCTAssertEqual(unpacked.paths, ["foo", "bar.baz_quux"])
            } catch {
                XCTFail("Failed to unpack anyField \(anyField)")
            }

            let encoded = try decoded.serializeJSON()
            XCTAssertEqual(encoded, start)
        } catch {
            XCTFail("Failed to decode \(start)")
        }
    }

    func test_Any_FieldMask_transcode() throws {
        let start = "{\"optionalAny\":{\"@type\":\"type.googleapis.com/google.protobuf.FieldMask\",\"value\":\"foo,bar.bazQuux\"}}"
        do {
            let decoded = try Conformance_TestAllTypes(json: start)
            let protobuf = try decoded.serializeProtobuf()
            XCTAssertEqual(protobuf, Data(bytes: [138, 19, 68, 10, 45, 116, 121, 112, 101, 46, 103, 111, 111, 103, 108, 101, 97, 112, 105, 115, 46, 99, 111, 109, 47, 103, 111, 111, 103, 108, 101, 46, 112, 114, 111, 116, 111, 98, 117, 102, 46, 70, 105, 101, 108, 100, 77, 97, 115, 107, 18, 19, 10, 3, 102, 111, 111, 10, 12, 98, 97, 114, 46, 98, 97, 122, 95, 113, 117, 117, 120]))
            do {
                let redecoded = try Conformance_TestAllTypes(protobuf: protobuf)
                let json = try redecoded.serializeJSON()
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
            let decoded = try Conformance_TestAllTypes(json: start)
            XCTAssertNotNil(decoded.optionalAny)
            let anyField = decoded.optionalAny
            do {
                let unpacked = try Google_Protobuf_Int32Value(any: anyField)
                XCTAssertEqual(unpacked.value, 1)
            } catch {
                XCTFail("failed to unpack \(anyField)")
            }

            let encoded = try decoded.serializeJSON()
            XCTAssertEqual(encoded, start)
        } catch {
            XCTFail("Failed to decode \(start)")
        }
    }

    func test_Any_Int32Value_transcode() throws {
        let start = "{\"optionalAny\":{\"@type\":\"type.googleapis.com/google.protobuf.Int32Value\",\"value\":1}}"
        do {
            let decoded = try Conformance_TestAllTypes(json: start)
            let protobuf = try decoded.serializeProtobuf()
            XCTAssertEqual(protobuf, Data(bytes: [138, 19, 52, 10, 46, 116, 121, 112, 101, 46, 103, 111, 111, 103, 108, 101, 97, 112, 105, 115, 46, 99, 111, 109, 47, 103, 111, 111, 103, 108, 101, 46, 112, 114, 111, 116, 111, 98, 117, 102, 46, 73, 110, 116, 51, 50, 86, 97, 108, 117, 101, 18, 2, 8, 1]))
            do {
                let redecoded = try Conformance_TestAllTypes(protobuf: protobuf)
                let json = try redecoded.serializeJSON()
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
            let decoded = try Conformance_TestAllTypes(json: start)
            XCTAssertNotNil(decoded.optionalAny)
            let anyField = decoded.optionalAny
            do {
                let unpacked = try Google_Protobuf_Struct(any: anyField)
                XCTAssertEqual(unpacked.fields["foo"], Google_Protobuf_Value(numberValue:1))
            } catch {
                XCTFail("Failed to unpack \(anyField)")
            }

            let encoded = try decoded.serializeJSON()
            XCTAssertEqual(encoded, start)
        } catch {
            XCTFail("Failed to decode \(start)")
        }
    }

    func test_Any_Struct_transcode() throws {
        let start = "{\"optionalAny\":{\"@type\":\"type.googleapis.com/google.protobuf.Struct\",\"value\":{\"foo\":1}}}"
        do {
            let decoded = try Conformance_TestAllTypes(json: start)
            let protobuf = try decoded.serializeProtobuf()
            XCTAssertEqual(protobuf, Data(bytes: [138, 19, 64, 10, 42, 116, 121, 112, 101, 46, 103, 111, 111, 103, 108, 101, 97, 112, 105, 115, 46, 99, 111, 109, 47, 103, 111, 111, 103, 108, 101, 46, 112, 114, 111, 116, 111, 98, 117, 102, 46, 83, 116, 114, 117, 99, 116, 18, 18, 10, 16, 10, 3, 102, 111, 111, 18, 9, 17, 0, 0, 0, 0, 0, 0, 240, 63]))
            do {
                let redecoded = try Conformance_TestAllTypes(protobuf: protobuf)
                let json = try redecoded.serializeJSON()
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
            let decoded = try Conformance_TestAllTypes(json: start)
            XCTAssertNotNil(decoded.optionalAny)
            let anyField = decoded.optionalAny
            do {
                let unpacked = try Google_Protobuf_Timestamp(any: anyField)
                XCTAssertEqual(unpacked.seconds, 1)
                XCTAssertEqual(unpacked.nanos, 0)
            } catch {
                XCTFail("Failed to unpack \(anyField)")
            }

            let encoded = try decoded.serializeJSON()
            XCTAssertEqual(encoded, start)
        } catch {
            XCTFail("Failed to decode \(start)")
        }
    }

    func test_Any_Timestamp_transcode() throws {
        let start = "{\"optionalAny\":{\"@type\":\"type.googleapis.com/google.protobuf.Timestamp\",\"value\":\"1970-01-01T00:00:01.000000001Z\"}}"
        do {
            let decoded = try Conformance_TestAllTypes(json: start)
            let protobuf = try decoded.serializeProtobuf()
            XCTAssertEqual(protobuf, Data(bytes: [138, 19, 53, 10, 45, 116, 121, 112, 101, 46, 103, 111, 111, 103, 108, 101, 97, 112, 105, 115, 46, 99, 111, 109, 47, 103, 111, 111, 103, 108, 101, 46, 112, 114, 111, 116, 111, 98, 117, 102, 46, 84, 105, 109, 101, 115, 116, 97, 109, 112, 18, 4, 8, 1, 16, 1]))
            do {
                let redecoded = try Conformance_TestAllTypes(protobuf: protobuf)
                let json = try redecoded.serializeJSON()
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
            let decoded = try Conformance_TestAllTypes(json: start)
            let anyField = decoded.optionalAny
            do {
                let unpacked = try Google_Protobuf_ListValue(any: anyField)
                XCTAssertEqual(unpacked.values, [Google_Protobuf_Value(stringValue: "foo"), Google_Protobuf_Value(numberValue: 1)])
            } catch {
                XCTFail("Failed to unpack \(anyField)")
            }

            let encoded = try decoded.serializeJSON()
            XCTAssertEqual(encoded, start)
        } catch {
            XCTFail("Failed to decode \(start)")
        }
    }

    func test_Any_ListValue_transcode() throws {
        let start = "{\"optionalAny\":{\"@type\":\"type.googleapis.com/google.protobuf.ListValue\",\"value\":[1,\"abc\"]}}"
        do {
            let decoded = try Conformance_TestAllTypes(json: start)
            let protobuf = try decoded.serializeProtobuf()
            XCTAssertEqual(protobuf, Data(bytes: [138, 19, 67, 10, 45, 116, 121, 112, 101, 46, 103, 111, 111, 103, 108, 101, 97, 112, 105, 115, 46, 99, 111, 109, 47, 103, 111, 111, 103, 108, 101, 46, 112, 114, 111, 116, 111, 98, 117, 102, 46, 76, 105, 115, 116, 86, 97, 108, 117, 101, 18, 18, 10, 9, 17, 0, 0, 0, 0, 0, 0, 240, 63, 10, 5, 26, 3, 97, 98, 99]))
            do {
                let redecoded = try Conformance_TestAllTypes(protobuf: protobuf)
                let json = try redecoded.serializeJSON()
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
            let decoded1 = try Conformance_TestAllTypes(json: start1)
            XCTAssertNotNil(decoded1.optionalAny)
            let anyField = decoded1.optionalAny
            XCTAssertThrowsError(try Google_Protobuf_Struct(any: anyField))
            do {
                let unpacked = try Google_Protobuf_Value(any: anyField)
                if let structValue = unpacked.structValue {
                    XCTAssertEqual(structValue.fields["foo"], Google_Protobuf_Value(numberValue:1))
                }
            } catch {
                XCTFail("failed to unpack \(anyField)")
            }

            let encoded1 = try decoded1.serializeJSON()
            XCTAssertEqual(encoded1, start1)
        } catch {
            XCTFail("Failed to decode \(start1)")
        }
    }

    func test_Any_Value_struct_transcode() throws {
        let start = "{\"optionalAny\":{\"@type\":\"type.googleapis.com/google.protobuf.Value\",\"value\":{\"foo\":1}}}"
        do {
            let decoded = try Conformance_TestAllTypes(json: start)
            let protobuf = try decoded.serializeProtobuf()
            XCTAssertEqual(protobuf, Data(bytes: [138, 19, 65, 10, 41, 116, 121, 112, 101, 46, 103, 111, 111, 103, 108, 101, 97, 112, 105, 115, 46, 99, 111, 109, 47, 103, 111, 111, 103, 108, 101, 46, 112, 114, 111, 116, 111, 98, 117, 102, 46, 86, 97, 108, 117, 101, 18, 20, 42, 18, 10, 16, 10, 3, 102, 111, 111, 18, 9, 17, 0, 0, 0, 0, 0, 0, 240, 63]))
            do {
                let redecoded = try Conformance_TestAllTypes(protobuf: protobuf)
                let json = try redecoded.serializeJSON()
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
            let decoded2 = try Conformance_TestAllTypes(json: start2)
            XCTAssertNotNil(decoded2.optionalAny)
            let anyField = decoded2.optionalAny
            XCTAssertThrowsError(try Google_Protobuf_Struct(any: anyField))
            do {
                let unpacked = try Google_Protobuf_Value(any: anyField)
                XCTAssertEqual(unpacked.numberValue, 1)
            } catch {
                XCTFail("Failed to unpack \(anyField)")
            }

            let encoded2 = try decoded2.serializeJSON()
            XCTAssertEqual(encoded2, start2)
        } catch let e {
            XCTFail("Failed to decode \(start2): \(e)")
        }
    }

    func test_Any_Value_int_transcode() throws {
        let start = "{\"optionalAny\":{\"@type\":\"type.googleapis.com/google.protobuf.Value\",\"value\":1}}"
        do {
            let decoded = try Conformance_TestAllTypes(json: start)
            let protobuf = try decoded.serializeProtobuf()
            XCTAssertEqual(protobuf, Data(bytes: [138, 19, 54, 10, 41, 116, 121, 112, 101, 46, 103, 111, 111, 103, 108, 101, 97, 112, 105, 115, 46, 99, 111, 109, 47, 103, 111, 111, 103, 108, 101, 46, 112, 114, 111, 116, 111, 98, 117, 102, 46, 86, 97, 108, 117, 101, 18, 9, 17, 0, 0, 0, 0, 0, 0, 240, 63]))
            do {
                let redecoded = try Conformance_TestAllTypes(protobuf: protobuf)
                let json = try redecoded.serializeJSON()
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
            let decoded3 = try Conformance_TestAllTypes(json: start3)
            let anyField = decoded3.optionalAny
            XCTAssertThrowsError(try Google_Protobuf_Struct(any: anyField))
            do {
                let unpacked = try Google_Protobuf_Value(any: anyField)
                XCTAssertEqual(unpacked.stringValue, "abc")
            } catch {
                XCTFail("Failed to unpack \(anyField)")
            }

            let encoded3 = try decoded3.serializeJSON()
            XCTAssertEqual(encoded3, start3)
        } catch {
            XCTFail("Failed to decode \(start3)")
        }
    }

    func test_Any_Value_string_transcode() throws {
        let start = "{\"optionalAny\":{\"@type\":\"type.googleapis.com/google.protobuf.Value\",\"value\":\"abc\"}}"
        do {
            let decoded = try Conformance_TestAllTypes(json: start)
            let protobuf = try decoded.serializeProtobuf()
            XCTAssertEqual(protobuf, Data(bytes: [138, 19, 50, 10, 41, 116, 121, 112, 101, 46, 103, 111, 111, 103, 108, 101, 97, 112, 105, 115, 46, 99, 111, 109, 47, 103, 111, 111, 103, 108, 101, 46, 112, 114, 111, 116, 111, 98, 117, 102, 46, 86, 97, 108, 117, 101, 18, 5, 26, 3, 97, 98, 99]))
            do {
                let redecoded = try Conformance_TestAllTypes(protobuf: protobuf)
                let json = try redecoded.serializeJSON()
                XCTAssertEqual(json, start)
            } catch {
                XCTFail("Redecode failed for \(protobuf)")
            }
        } catch {
            XCTFail("Decode failed for \(start)")
        }
    }
}
