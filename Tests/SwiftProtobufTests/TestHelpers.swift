// Test/Sources/TestSuite/TestHelpers.swift - Test helpers
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
            let encoded = try configured.serializeProtobuf()
            XCTAssert(Data(bytes: expected) == encoded, "Did not encode correctly: got \(string(from: encoded))", file: file, line: line)
            do {
                let decoded = try MessageTestType(protobuf: encoded)
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
            let decoded = try MessageTestType(protobuf: Data(bytes: bytes))
            XCTAssert(check(decoded), "Condition failed for \(decoded)", file: file, line: line)

            do {
                let encoded = try decoded.serializeProtobuf()
                do {
                    let redecoded = try MessageTestType(protobuf: encoded)
                    XCTAssert(check(redecoded), "Condition failed for redecoded \(redecoded)", file: file, line: line)
                    XCTAssertEqual(decoded, redecoded, file: file, line: line)
                } catch {
                    XCTFail("Failed to redecode", file: file, line: line)
                }
            } catch let e {
                XCTFail("Failed to encode: \(e)\n    \(decoded)", file: file, line: line)
            }
        } catch {
            XCTFail("Failed to decode", file: file, line: line)
        }
    }

    func assertDecodeSucceeds(_ bytes: [UInt8], file: XCTestFileArgType = #file, line: UInt = #line, check: (MessageTestType) -> Bool) {
        baseAssertDecodeSucceeds(bytes, file: file, line: line, check: check)
    }

    func assertDecodeFails(_ bytes: [UInt8], file: XCTestFileArgType = #file, line: UInt = #line) {
        do {
            let _ = try MessageTestType(protobuf: Data(bytes: bytes))
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
            let encoded = try configured.serializeJSON()
            XCTAssert(expected == encoded, "Did not encode correctly: got \(encoded)", file: file, line: line)
            do {
                let decoded = try MessageTestType(json: encoded)
                XCTAssert(decoded == configured, "Encode/decode cycle should generate equal object: \(decoded) != \(configured)", file: file, line: line)
            } catch {
                XCTFail("Encode/decode cycle should not throw error, decoding: \(encoded)", file: file, line: line)
            }
        } catch let e {
            XCTFail("Failed to serialize JSON: \(e)\n    \(configured)", file: file, line: line)
        }
    }

    func assertTextEncode(_ expected: String, file: XCTestFileArgType = #file, line: UInt = #line, configure: (inout MessageTestType) -> Void) {
        let empty = MessageTestType()
        var configured = empty
        configure(&configured)
        XCTAssert(configured != empty, "Object should not be equal to empty object", file: file, line: line)
        do {
            let encoded = try configured.serializeText()

            XCTAssert(expected == encoded, "Did not encode correctly: got \(encoded)", file: file, line: line)
            do {
                let decoded = try MessageTestType(text: encoded)
                XCTAssert(decoded == configured, "Encode/decode cycle should generate equal object: \(decoded) != \(configured)", file: file, line: line)
            } catch {
                XCTFail("Encode/decode cycle should not throw error, decoding: \(error)", file: file, line: line)
            }
        } catch let e {
            XCTFail("Failed to serialize JSON: \(e)\n    \(configured)", file: file, line: line)
        }
    }

    func assertJSONDecodeSucceeds(_ json: String, file: XCTestFileArgType = #file, line: UInt = #line, check: (MessageTestType) -> Bool) {
        do {
            let decoded: MessageTestType = try MessageTestType(json: json)
            XCTAssert(check(decoded), "Condition failed for \(decoded)", file: file, line: line)

            do {
                let encoded = try decoded.serializeJSON()
                do {
                    let redecoded = try MessageTestType(json: json)
                    XCTAssert(check(redecoded), "Condition failed for redecoded \(redecoded)", file: file, line: line)
                    XCTAssertEqual(decoded, redecoded, file: file, line: line)
                } catch {
                    XCTFail("Swift should have recoded/redecoded without error: \(encoded)", file: file, line: line)
                }
            } catch let e {
                XCTFail("Swift should have recoded without error but got \(e)\n    \(decoded)", file: file, line: line)
            }
        } catch {
            XCTFail("Swift should have decoded without error: \(json)", file: file, line: line)
            return
        }
    }

    func assertTextDecodeSucceeds(_ text: String, file: XCTestFileArgType = #file, line: UInt = #line, check: (MessageTestType) -> Bool) {
        do {
            let decoded: MessageTestType = try MessageTestType(text: text)
            XCTAssert(check(decoded), "Condition failed for \(decoded)", file: file, line: line)

            do {
                let encoded = try decoded.serializeText()
                do {
                    let redecoded = try MessageTestType(text: text)
                    XCTAssert(check(redecoded), "Condition failed for redecoded \(redecoded)", file: file, line: line)
                    XCTAssertEqual(decoded, redecoded, file: file, line: line)
                } catch {
                    XCTFail("Swift should have recoded/redecoded without error: \(encoded)", file: file, line: line)
                }
            } catch let e {
                XCTFail("Swift should have recoded without error but got \(e)\n    \(decoded)", file: file, line: line)
            }
        } catch {
            XCTFail("Swift should have decoded without error: \(text)", file: file, line: line)
            return
        }
    }

    func assertJSONDecodeFails(_ json: String, file: XCTestFileArgType = #file, line: UInt = #line) {
        do {
            let _ = try MessageTestType(json: json)
            XCTFail("Swift decode should have failed: \(json)", file: file, line: line)
        } catch {
            // Yay! It failed!
        }
    }

    func assertTextDecodeFails(_ text: String, file: XCTestFileArgType = #file, line: UInt = #line) {
        do {
            let _ = try MessageTestType(text: text)
            XCTFail("Swift decode should have failed: \(text)", file: file, line: line)
        } catch {
            // Yay! It failed!
        }
    }
}
