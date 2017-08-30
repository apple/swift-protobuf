// Tests/SwiftProtobufTests/Test_JSONDecodingOptions.swift - Various JSON tests
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Test for the use of JSONDecodingOptions
///
// -----------------------------------------------------------------------------

import Foundation
import XCTest
import SwiftProtobuf

class Test_JSONDecodingOptions: XCTestCase {

    func testMessageDepthLimit() {
        let jsonInputs: [String] = [
            // Proper field names.
            "{ \"a\": { \"a\": { \"i\": 1 } } }",
            // Wrong names, causes the skipping of values to be trigger, which also should
            // honor depth limits.
            "{ \"x\": { \"x\": { \"z\": 1 } } }",
        ]

        let tests: [(Int, Bool)] = [
            // Limit, success/failure
            ( 10, true ),
            ( 4, true ),
            ( 3, true ),
            ( 2, false ),
            ( 1, false ),
        ]

        for (i, jsonInput) in jsonInputs.enumerated() {
            for (limit, expectSuccess) in tests {
                do {
                    var options = JSONDecodingOptions()
                    options.messageDepthLimit = limit
                    let _ = try ProtobufUnittest_TestRecursiveMessage(jsonString: jsonInput, options: options)
                    if !expectSuccess {
                        XCTFail("Should not have succeed, pass: \(i), limit: \(limit)")
                    }
                } catch JSONDecodingError.messageDepthLimit {
                    if expectSuccess {
                        XCTFail("Decode failed because of limit, but should *NOT* have, pass: \(i), limit: \(limit)")
                    } else {
                        // Nothing, this is what was expected.
                    }
                } catch let e  {
                    XCTFail("Decode failed (pass: \(i), limit: \(limit) with unexpected error: \(e)")
                }
            }
        }
    }
}
