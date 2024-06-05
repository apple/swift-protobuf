// Tests/SwiftProtobufTests/TestHelpers.swift - Test helpers
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Various helper methods to simplify repetitive testing of encoding/decoding.
///
// -----------------------------------------------------------------------------

import XCTest
import Foundation
@testable import SwiftProtobuf

typealias XCTestFileArgType = StaticString

protocol PBTestHelpers {
    associatedtype MessageTestType
}

extension PBTestHelpers where MessageTestType: SwiftProtobuf.Message & Equatable {

    private func string(from data: [UInt8]) -> String {
        return "[" + data.map { String($0) }.joined(separator: ", ") + "]"
    }

    func assertEncode(_ expected: [UInt8], file: XCTestFileArgType = #file, line: UInt = #line, configure: (inout MessageTestType) -> Void) {
        let empty = MessageTestType()
        var configured = empty
        configure(&configured)
        XCTAssert(configured != empty, "Object should not be equal to empty object", file: file, line: line)
        do {
            let encoded: [UInt8] = try configured.serializedBytes()
            XCTAssert(expected == encoded, "Did not encode correctly: got \(string(from: encoded))", file: file, line: line)
            do {
                let decoded = try MessageTestType(serializedBytes: encoded)
                XCTAssert(decoded == configured, "Encode/decode cycle should generate equal object: \(decoded) != \(configured)", file: file, line: line)
            } catch {
                XCTFail("Failed to decode protobuf: \(string(from: encoded))", file: file, line: line)
            }
        } catch let e {
            XCTFail("Failed to encode: \(e)\n    \(configured)", file: file, line: line)
        }
    }

    func baseAssertDecodeSucceeds(_ bytes: [UInt8], file: XCTestFileArgType = #file, line: UInt = #line, check: (MessageTestType) -> Bool) {
        do {
            let decoded = try MessageTestType(serializedBytes: bytes)
            XCTAssert(check(decoded), "Condition failed for \(decoded)", file: file, line: line)

            do {
                let encoded: [UInt8] = try decoded.serializedBytes()
                do {
                    let redecoded = try MessageTestType(serializedBytes: encoded)
                    XCTAssert(check(redecoded), "Condition failed for redecoded \(redecoded)", file: file, line: line)
                    XCTAssertEqual(decoded, redecoded, file: file, line: line)
                } catch let e {
                    XCTFail("Failed to redecode: \(e)", file: file, line: line)
                }
            } catch let e {
                XCTFail("Failed to encode: \(e)\n    \(decoded)", file: file, line: line)
            }
        } catch let e {
            XCTFail("Failed to decode: \(e)", file: file, line: line)
        }
    }

    func assertDecodeSucceeds(_ bytes: [UInt8], file: XCTestFileArgType = #file, line: UInt = #line, check: (MessageTestType) -> Bool) {
        baseAssertDecodeSucceeds(bytes, file: file, line: line, check: check)
    }

    // Helper to check that decode succeeds by the data ended up in unknown fields.
    // Supports an optional `check` to do additional validation.
    func assertDecodesAsUnknownFields(_ bytes: [UInt8], file: XCTestFileArgType = #file, line: UInt = #line, check: ((MessageTestType) -> Bool)? = nil) {
        assertDecodeSucceeds(bytes, file: file, line: line) {
            if $0.unknownFields.data != Data(bytes) {
                return false
            }
            if let check = check {
                return check($0)
            }
            return true
        }
    }

    func assertMergesAsUnknownFields(_ bytes: [UInt8], inTo message: MessageTestType, file: XCTestFileArgType = #file, line: UInt = #line, check: ((MessageTestType) -> Bool)? = nil) {
        var msgCopy = message
        do {
            try msgCopy.merge(serializedBytes: bytes)
        } catch let e {
            XCTFail("Failed to decode: \(e)", file: file, line: line)
        }
        XCTAssertEqual(msgCopy.unknownFields.data, Data(bytes), file: file, line: line)
        if let check = check {
            XCTAssert(check(msgCopy), "Condition failed for \(msgCopy)", file: file, line: line)
        }
    }

    func assertDecodeSucceeds(inputBytes bytes: [UInt8], recodedBytes: [UInt8], file: XCTestFileArgType = #file, line: UInt = #line, check: (MessageTestType) -> Bool) {
        do {
            let decoded = try MessageTestType(serializedBytes: bytes)
            XCTAssert(check(decoded), "Condition failed for \(decoded)", file: file, line: line)

            do {
                let encoded: [UInt8] = try decoded.serializedBytes()
                XCTAssertEqual(recodedBytes, encoded, "Didn't recode as expected: \(string(from: encoded)) expected: \(recodedBytes)", file: file, line: line)
                do {
                    let redecoded = try MessageTestType(serializedBytes: encoded)
                    XCTAssert(check(redecoded), "Condition failed for redecoded \(redecoded)", file: file, line: line)
                    XCTAssertEqual(decoded, redecoded, file: file, line: line)
                } catch let e {
                    XCTFail("Failed to redecode: \(e)", file: file, line: line)
                }
            } catch let e {
                XCTFail("Failed to encode: \(e)\n    \(decoded)", file: file, line: line)
            }
        } catch let e {
            XCTFail("Failed to decode: \(e)", file: file, line: line)
        }
    }


    func assertDecodeFails(_ bytes: [UInt8], file: XCTestFileArgType = #file, line: UInt = #line) {
        do {
            let _ = try MessageTestType(serializedBytes: bytes)
            XCTFail("Swift decode should have failed: \(bytes)", file: file, line: line)
        } catch {
            // Yay!  It failed!
        }

    }

    func assertJSONEncode(_ expected: String, extensions: any ExtensionMap = SimpleExtensionMap(), encodingOptions: JSONEncodingOptions = .init(), file: XCTestFileArgType = #file, line: UInt = #line, configure: (inout MessageTestType) -> Void) {
        let empty = MessageTestType()
        var configured = empty
        configure(&configured)
        XCTAssert(configured != empty, "Object should not be equal to empty object", file: file, line: line)
        do {
            let encoded = try configured.jsonString(options: encodingOptions)
            XCTAssert(expected == encoded, "Did not encode correctly: got \(encoded) but expected \(expected)", file: file, line: line)
            do {
                let decoded = try MessageTestType(jsonString: encoded, extensions: extensions)
                XCTAssert(decoded == configured, "Encode/decode cycle should generate equal object: \(decoded) != \(configured)", file: file, line: line)
            } catch {
                XCTFail("Encode/decode cycle should not throw error decoding: \(encoded), but it threw \(error)", file: file, line: line)
            }
        } catch let e {
            XCTFail("Failed to serialize JSON: \(e)\n    \(configured)", file: file, line: line)
        }

        do {
            let encodedData: [UInt8] = try configured.jsonUTF8Bytes(options: encodingOptions)
            let encodedOptString = String(bytes: encodedData, encoding: String.Encoding.utf8)
            XCTAssertNotNil(encodedOptString)
            let encodedString = encodedOptString!
            XCTAssert(expected == encodedString, "Did not encode correctly: got \(encodedString)", file: file, line: line)
            do {
                let decoded = try MessageTestType(jsonUTF8Bytes: encodedData, extensions: extensions)
                XCTAssert(decoded == configured, "Encode/decode cycle should generate equal object: \(decoded) != \(configured)", file: file, line: line)
            } catch {
                XCTFail("Encode/decode cycle should not throw error decoding: \(encodedString), but it threw \(error)", file: file, line: line)
            }
        } catch let e {
            XCTFail("Failed to serialize JSON: \(e)\n    \(configured)", file: file, line: line)
        }
    }

    /// Verify the preferred encoding/decoding of a particular object.
    /// This uses the provided block to initialize the object, then:
    /// * Encodes the object and checks that the result is the expected result
    /// * Decodes it again and verifies that the round-trip gives an equal object
    func assertTextFormatEncode(_ expected: String, extensions: (any ExtensionMap)? = nil, file: XCTestFileArgType = #file, line: UInt = #line, configure: (inout MessageTestType) -> Void) {
        let empty = MessageTestType()
        var configured = empty
        configure(&configured)
        XCTAssert(configured != empty, "Object should not be equal to empty object", file: file, line: line)
        let encoded = configured.textFormatString()

        XCTAssertEqual(expected, encoded, "Did not encode correctly", file: file, line: line)
        do {
            let decoded = try MessageTestType(textFormatString: encoded, extensions: extensions)
            XCTAssert(decoded == configured, "Encode/decode cycle should generate equal object: \(decoded) != \(configured)", file: file, line: line)
        } catch {
            XCTFail("Encode/decode cycle should not throw error but got \(error) while decoding \(encoded)", file: file, line: line)
        }
    }

    func assertJSONArrayEncode(
        _ expected: String,
        extensions: any ExtensionMap = SimpleExtensionMap(),
        file: XCTestFileArgType = #file,
        line: UInt = #line,
        configure: (inout [MessageTestType]) -> Void
    ) {
        let empty = [MessageTestType]()
        var configured = empty
        configure(&configured)
        XCTAssert(configured != empty, "Object should not be equal to empty object", file: file, line: line)
        do {
            let encoded = try MessageTestType.jsonString(from: configured)
            XCTAssert(expected == encoded, "Did not encode correctly: got \(encoded)", file: file, line: line)
            do {
                let decoded = try MessageTestType.array(fromJSONString: encoded,
                                                 extensions: extensions)
                XCTAssert(decoded == configured, "Encode/decode cycle should generate equal object: \(decoded) != \(configured)", file: file, line: line)
            } catch {
                XCTFail("Encode/decode cycle should not throw error decoding: \(encoded), but it threw \(error)", file: file, line: line)
            }
        } catch let e {
            XCTFail("Failed to serialize JSON: \(e)\n    \(configured)", file: file, line: line)
        }
    }

    func assertJSONDecodeSucceeds(
        _ json: String,
        options: JSONDecodingOptions = JSONDecodingOptions(),
        extensions: any ExtensionMap = SimpleExtensionMap(),
        file: XCTestFileArgType = #file,
        line: UInt = #line,
        check: (MessageTestType) -> Bool
    ) {
        do {
            let decoded: MessageTestType = try MessageTestType(jsonString: json, extensions: extensions, options: options)
            XCTAssert(check(decoded), "Condition failed for \(decoded)", file: file, line: line)

            do {
                let encoded = try decoded.jsonString()
                do {
                    let redecoded = try MessageTestType(jsonString: encoded, extensions: extensions, options: options)
                    XCTAssert(check(redecoded), "Condition failed for redecoded \(redecoded) from \(encoded)", file: file, line: line)
                    XCTAssertEqual(decoded, redecoded, file: file, line: line)
                } catch {
                    XCTFail("Swift should have recoded/redecoded without error: \(encoded)", file: file, line: line)
                }
            } catch let e {
                XCTFail("Swift should have recoded without error but got \(e)\n    \(decoded)", file: file, line: line)
            }
        } catch let e {
            XCTFail("Swift should have decoded without error but got \(e): \(json)", file: file, line: line)
            return
        }

        do {
            let jsonData = json.data(using: String.Encoding.utf8)!
            let decoded: MessageTestType = try MessageTestType(jsonUTF8Bytes: jsonData, extensions: extensions, options: options)
            XCTAssert(check(decoded), "Condition failed for \(decoded) from binary \(json)", file: file, line: line)

            do {
                let encoded: [UInt8] = try decoded.jsonUTF8Bytes()
                let encodedString = String(bytes: encoded, encoding: String.Encoding.utf8)!
                do {
                    let redecoded = try MessageTestType(jsonUTF8Bytes: encoded, extensions: extensions, options: options)
                    XCTAssert(check(redecoded), "Condition failed for redecoded \(redecoded) from binary \(encodedString)", file: file, line: line)
                    XCTAssertEqual(decoded, redecoded, file: file, line: line)
                } catch {
                    XCTFail("Swift should have recoded/redecoded without error: \(encodedString)", file: file, line: line)
                }
            } catch let e {
                XCTFail("Swift should have recoded without error but got \(e)\n    \(decoded)", file: file, line: line)
            }
        } catch let e {
            XCTFail("Swift should have decoded without error but got \(e): \(json)", file: file, line: line)
            return
        }
    }

    func assertTextFormatDecodeSucceeds(_ text: String, options: TextFormatDecodingOptions = TextFormatDecodingOptions(), file: XCTestFileArgType = #file, line: UInt = #line, check: (MessageTestType) throws -> Bool) {
        do {
            let decoded: MessageTestType = try MessageTestType(textFormatString: text, options: options)
            do {
                let r = try check(decoded)
                XCTAssert(r, "Condition failed for \(decoded)", file: file, line: line)
            } catch let e {
                XCTFail("Object check failed: \(e)")
            }
            let encoded = decoded.textFormatString()
            do {
                let redecoded = try MessageTestType(textFormatString: encoded)
                do {
                    let r = try check(redecoded)
                    XCTAssert(r, "Condition failed for redecoded \(redecoded)", file: file, line: line)
                } catch let e {
                    XCTFail("Object check failed for redecoded: \(e)\n   \(redecoded)")
                }
                XCTAssertEqual(decoded, redecoded, file: file, line: line)
            } catch {
                XCTFail("Swift should have recoded/redecoded without error: \(encoded)", file: file, line: line)
            }
        } catch let e {
            XCTFail("Swift should have decoded without error but got \(e) decoding: \(text)", file: file, line: line)
            return
        }
    }

    func assertJSONArrayDecodeSucceeds(
        _ json: String,
        file: XCTestFileArgType = #file,
        line: UInt = #line,
        check: ([MessageTestType]) -> Bool
    ) {
        do {
            let decoded: [MessageTestType] = try MessageTestType.array(fromJSONString: json)
            XCTAssert(check(decoded), "Condition failed for \(decoded)", file: file, line: line)

            do {
                let encoded = try MessageTestType.jsonString(from: decoded)
                do {
                    let redecoded = try MessageTestType.array(fromJSONString: json)
                    XCTAssert(check(redecoded), "Condition failed for redecoded \(redecoded)", file: file, line: line)
                    XCTAssertEqual(decoded, redecoded, file: file, line: line)
                } catch {
                    XCTFail("Swift should have recoded/redecoded without error: \(encoded)", file: file, line: line)
                }
            } catch let e {
                XCTFail("Swift should have recoded without error but got \(e)\n    \(decoded)", file: file, line: line)
            }
        } catch let e {
            XCTFail("Swift should have decoded without error but got \(e): \(json)", file: file, line: line)
            return
        }
    }

    func assertJSONDecodeFails(
        _ json: String,
        extensions: any ExtensionMap = SimpleExtensionMap(),
        options: JSONDecodingOptions = JSONDecodingOptions(),
        file: XCTestFileArgType = #file,
        line: UInt = #line
    ) {
        do {
            let _ = try MessageTestType(jsonString: json, extensions: extensions, options: options)
            XCTFail("Swift decode should have failed: \(json)", file: file, line: line)
        } catch {
            // Yay! It failed!
        }

        let jsonData = json.data(using: String.Encoding.utf8)!
        do {
            let _ = try MessageTestType(jsonUTF8Bytes: jsonData, extensions: extensions, options: options)
            XCTFail("Swift decode should have failed for binary: \(json)", file: file, line: line)
        } catch {
            // Yay! It failed again!
        }
    }

    func assertTextFormatDecodeFails(_ text: String, file: XCTestFileArgType = #file, line: UInt = #line) {
        do {
            let _ = try MessageTestType(textFormatString: text)
            XCTFail("Swift decode should have failed: \(text)", file: file, line: line)
        } catch {
            // Yay! It failed!
        }
    }

    func assertJSONArrayDecodeFails(
        _ json: String,
        extensions: any ExtensionMap = SimpleExtensionMap(),
        file: XCTestFileArgType = #file,
        line: UInt = #line
    ) {
        do {
            let _ = try MessageTestType.array(fromJSONString: json)
            XCTFail("Swift decode should have failed: \(json)", file: file, line: line)
        } catch {
            // Yay! It failed!
        }
    }

    func assertDebugDescription(_ expected: String, file: XCTestFileArgType = #file, line: UInt = #line, configure: (inout MessageTestType) -> ()) {
        // `assertDebugDescription` is a no-op in release as `debugDescription` is unavailable.
        #if DEBUG
        var m = MessageTestType()
        configure(&m)
        let actual = m.debugDescription
        XCTAssertEqual(actual, expected, file: file, line: line)
        #endif
    }
}

extension XCTestCase {
    func assertDebugDescription(_ expected: String, _ m: any SwiftProtobuf.Message, fmt: String? = nil, file: XCTestFileArgType = #file, line: UInt = #line) {
        // `assertDebugDescription` is a no-op in release as `debugDescription` is unavailable.
        #if DEBUG
        let actual = m.debugDescription
        XCTAssertEqual(actual, expected, fmt ?? "debugDescription did not match", file: file, line: line)
        #endif
    }
    /// Like ``assertDebugDescription``, but only checks the the ``debugDescription`` ends with
    /// ``expectedSuffix``, mainly useful where you want to be agnotics to some preable like
    /// the module name.
    func assertDebugDescriptionSuffix(_ expectedSuffix: String, _ m: any SwiftProtobuf.Message, fmt: String? = nil, file: XCTestFileArgType = #file, line: UInt = #line) {
        // `assertDebugDescriptionSuffix` is a no-op in release as `debugDescription` is unavailable.
#if DEBUG
        let actual = m.debugDescription
        XCTAssertTrue(actual.hasSuffix(expectedSuffix), fmt ?? "debugDescription did not match", file: file, line: line)
#endif
    }
    
    func isSwiftProtobufErrorEqual(_ actual: SwiftProtobufError, _ expected: SwiftProtobufError) -> Bool {
        (actual.code == expected.code) && (actual.message == expected.message)
    }
}

/// Protocol to help write visitor for testing.  It provides default implementations
/// that will cause a failure if anything gets called.  This way specific tests can
/// just hook the methods they intend to validate.
protocol PBTestVisitor: Visitor {
  // Adds nothing.
}

extension PBTestVisitor {
  mutating func visitUnknown(bytes: Data) throws {
    XCTFail("Unexpected unknowns: \(bytes)")
  }

  mutating func visitSingularBoolField(value: Bool, fieldNumber: Int) throws {
    XCTFail("Unexpected bool: \(fieldNumber) = \(value)")
  }

  mutating func visitSingularBytesField(value: Data, fieldNumber: Int) throws {
    XCTFail("Unexpected bytes: \(fieldNumber) = \(value)")
  }

  mutating func visitSingularDoubleField(value: Double, fieldNumber: Int) throws {
    XCTFail("Unexpected Int64: \(fieldNumber) = \(value)")
  }

  mutating func visitSingularEnumField<E: Enum>(value: E, fieldNumber: Int) throws {
    XCTFail("Unexpected Enum: \(fieldNumber) = \(value)")
  }

  mutating func visitSingularInt64Field(value: Int64, fieldNumber: Int) throws {
    XCTFail("Unexpected Int64: \(fieldNumber) = \(value)")
  }

  mutating func visitSingularMessageField<M: Message>(value: M, fieldNumber: Int) throws {
    XCTFail("Unexpected Message: \(fieldNumber) = \(value)")
  }

  mutating func visitSingularStringField(value: String, fieldNumber: Int) throws {
    XCTFail("Unexpected String: \(fieldNumber) = \(value)")
  }

  mutating func visitSingularUInt64Field(value: UInt64, fieldNumber: Int) throws {
    XCTFail("Unexpected UInt64: \(fieldNumber) = \(value)")
  }

  mutating func visitMapField<KeyType, ValueType: MapValueType>(
    fieldType: _ProtobufMap<KeyType, ValueType>.Type,
    value: _ProtobufMap<KeyType, ValueType>.BaseType,
    fieldNumber: Int
  ) throws {
    XCTFail("Unexpected map<*, *>: \(fieldNumber) = \(value)")
  }

  mutating func visitMapField<KeyType, ValueType>(
    fieldType: _ProtobufEnumMap<KeyType, ValueType>.Type,
    value: _ProtobufEnumMap<KeyType, ValueType>.BaseType,
    fieldNumber: Int
  ) throws where ValueType.RawValue == Int {
    XCTFail("Unexpected map<*, Enum>: \(fieldNumber) = \(value)")
  }

  mutating func visitMapField<KeyType, ValueType>(
    fieldType: _ProtobufMessageMap<KeyType, ValueType>.Type,
    value: _ProtobufMessageMap<KeyType, ValueType>.BaseType,
    fieldNumber: Int
  ) throws {
    XCTFail("Unexpected map<*, Message>: \(fieldNumber) = \(value)")
  }
}
