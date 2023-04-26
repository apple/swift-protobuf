// Tests/SwiftProtobufTests/Test_TextFormatDecodingOptions.swift - Various TextFormat tests
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Test for the use of TextFormatDecodingOptions
///
// -----------------------------------------------------------------------------

import Foundation
import XCTest
import SwiftProtobuf

class Test_TextFormatDecodingOptions: XCTestCase {

    func testMessageDepthLimit() {
        let textInput = "a: { a: { i: 1 } }"

        let tests: [(Int, Bool)] = [
            // Limit, success/failure
            ( 10, true ),
            ( 4, true ),
            ( 3, true ),
            ( 2, false ),
            ( 1, false ),
        ]

        for (limit, expectSuccess) in tests {
            do {
                var options = TextFormatDecodingOptions()
                options.messageDepthLimit = limit
                let _ = try ProtobufUnittest_TestRecursiveMessage(textFormatString: textInput, options: options)
                if !expectSuccess {
                    XCTFail("Should not have succeed, limit: \(limit)")
                }
            } catch TextFormatDecodingError.messageDepthLimit {
                if expectSuccess {
                    XCTFail("Decode failed because of limit, but should *NOT* have, limit: \(limit)")
                } else {
                    // Nothing, this is what was expected.
                }
            } catch let e  {
                XCTFail("Decode failed (limit: \(limit) with unexpected error: \(e)")
            }
        }
    }

}
