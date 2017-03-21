// Tests/SwiftProtobufTests/TestHelpers.swift - Test helpers
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Various helper methods to simplify repetitive testing of encoding/decoding.
///
// -----------------------------------------------------------------------------

import XCTest
import Foundation
import SwiftProtobuf

typealias XCTestFileArgType = StaticString

protocol PBTestHelpers {
    associatedtype MessageTestType
}

extension PBTestHelpers where MessageTestType: SwiftProtobuf.Message & Equatable {

    private func string(from data: Data) -> String {
        return "[" + data.map { String($0) }.joined(separator: ", ") + "]"
    }

    func assertEncode(_ expected: [UInt8], file: XCTestFileArgType = #file, line: UInt = #line, configure: (inout MessageTestType) -> Void) {
        let empty = MessageTestType()
        var configured = empty
        configure(&configured)
        XCTAssert(configured != empty, "Object should not be equal to empty object", file: file, line: line)
        do {
            let encoded = try configured.serializedData()
            XCTAssert(Data(bytes: expected) == encoded, "Did not encode correctly: got \(string(from: encoded))", file: file, line: line)
            do {
                let decoded = try MessageTestType(serializedData: encoded)
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
            let decoded = try MessageTestType(serializedData: Data(bytes: bytes))
            XCTAssert(check(decoded), "Condition failed for \(decoded)", file: file, line: line)

            do {
                let encoded = try decoded.serializedData()
                do {
                    let redecoded = try MessageTestType(serializedData: encoded)
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

    func assertDecodesAsUnknownFields(_ bytes: [UInt8], file: XCTestFileArgType = #file, line: UInt = #line) {
        assertDecodeSucceeds(bytes, file: file, line: line) {
            $0.unknownFields.data == Data(bytes: bytes)
        }
    }

    func assertDecodeSucceeds(inputBytes bytes: [UInt8], recodedBytes: [UInt8], file: XCTestFileArgType = #file, line: UInt = #line, check: (MessageTestType) -> Bool) {
        do {
            let decoded = try MessageTestType(serializedData: Data(bytes: bytes))
            XCTAssert(check(decoded), "Condition failed for \(decoded)", file: file, line: line)

            do {
                let encoded = try decoded.serializedData()
                XCTAssertEqual(Data(bytes: recodedBytes), encoded, "Didn't recode as expected: \(string(from: encoded)) expected: \(recodedBytes)", file: file, line: line)
                do {
                    let redecoded = try MessageTestType(serializedData: encoded)
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
            let _ = try MessageTestType(serializedData: Data(bytes: bytes))
            XCTFail("Swift decode should have failed: \(bytes)", file: file, line: line)
        } catch {
            // Yay!  It failed!
        }

    }

    func assertJSONEncode(_ expected: String, file: XCTestFileArgType = #file, line: UInt = #line, configure: (inout MessageTestType) -> Void) {
        let empty = MessageTestType()
        var configured = empty
        configure(&configured)
        XCTAssert(configured != empty, "Object should not be equal to empty object", file: file, line: line)
        do {
            let encoded = try configured.jsonString()
            XCTAssert(expected == encoded, "Did not encode correctly: got \(encoded)", file: file, line: line)
            do {
                let decoded = try MessageTestType(jsonString: encoded)
                XCTAssert(decoded == configured, "Encode/decode cycle should generate equal object: \(decoded) != \(configured)", file: file, line: line)
            } catch {
                XCTFail("Encode/decode cycle should not throw error decoding: \(encoded), but it threw \(error)", file: file, line: line)
            }
        } catch let e {
            XCTFail("Failed to serialize JSON: \(e)\n    \(configured)", file: file, line: line)
        }
    }

    /// Verify the preferred encoding/decoding of a particular object.
    /// This uses the provided block to initialize the object, then:
    /// * Encodes the object and checks that the result is the expected result
    /// * Decodes it again and verifies that the round-trip gives an equal object
    func assertTextFormatEncode(_ expected: String, extensions: SimpleExtensionMap? = nil, file: XCTestFileArgType = #file, line: UInt = #line, configure: (inout MessageTestType) -> Void) {
        let empty = MessageTestType()
        var configured = empty
        configure(&configured)
        XCTAssert(configured != empty, "Object should not be equal to empty object", file: file, line: line)
        do {
            let encoded = try configured.textFormatString()

            XCTAssert(expected == encoded, "Did not encode correctly: got \(encoded)", file: file, line: line)
            do {
                let decoded = try MessageTestType(textFormatString: encoded, extensions: extensions)
                XCTAssert(decoded == configured, "Encode/decode cycle should generate equal object: \(decoded) != \(configured)", file: file, line: line)
            } catch {
                XCTFail("Encode/decode cycle should not throw error but got \(error) while decoding \(encoded)", file: file, line: line)
            }
        } catch let e {
            XCTFail("Failed to serialize Text: \(e)\n    \(configured)", file: file, line: line)
        }
    }

    func assertJSONDecodeSucceeds(_ json: String, file: XCTestFileArgType = #file, line: UInt = #line, check: (MessageTestType) -> Bool) {
        do {
            let decoded: MessageTestType = try MessageTestType(jsonString: json)
            XCTAssert(check(decoded), "Condition failed for \(decoded)", file: file, line: line)

            do {
                let encoded = try decoded.jsonString()
                do {
                    let redecoded = try MessageTestType(jsonString: json)
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

    func assertTextFormatDecodeSucceeds(_ text: String, file: XCTestFileArgType = #file, line: UInt = #line, check: (MessageTestType) throws -> Bool) {
        do {
            let decoded: MessageTestType = try MessageTestType(textFormatString: text)
            do {
                let r = try check(decoded)
                XCTAssert(r, "Condition failed for \(decoded)", file: file, line: line)
            } catch let e {
                XCTFail("Object check failed: \(e)")
            }
            do {
                let encoded = try decoded.textFormatString()
                do {
                    let redecoded = try MessageTestType(textFormatString: text)
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
                XCTFail("Swift should have recoded without error but got \(e)\n    \(decoded)", file: file, line: line)
            }
        } catch let e {
            XCTFail("Swift should have decoded without error but got \(e) decoding: \(text)", file: file, line: line)
            return
        }
    }

    func assertJSONDecodeFails(_ json: String, file: XCTestFileArgType = #file, line: UInt = #line) {
        do {
            let _ = try MessageTestType(jsonString: json)
            XCTFail("Swift decode should have failed: \(json)", file: file, line: line)
        } catch {
            // Yay! It failed!
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
}
