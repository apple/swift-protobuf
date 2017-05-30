// Tests/SwiftProtobufTests/Test_BinaryDecodingOptions.swift - Various Binary tests
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Test for the use of BinaryDecodingOptions
///
// -----------------------------------------------------------------------------

import Foundation
import XCTest
import SwiftProtobuf

class Test_BinaryDecodingOptions: XCTestCase {

    func testMessageDepthLimit() throws {  // ####

        let tests: [([UInt8], [(Int, Bool)])] = [
            // Input, (Limit, success/failure)

            // Messages within messages:     // outer is msg 1
            //     child {                   // sub msg 2
            //       child {                 // sub msg 3
            //         payload {             // sub msg 4
            //           optional_int32: 99
            //         }
            //       }
            //     }
            ([10, 6, 10, 4, 18, 2, 8, 99],
             [( 10, true ),
              ( 4, true ),
              ( 3, false ),
              ( 2, false )]),

            // Group within messages:        // outer is msg 1
            //     child {                   // sub msg 2
            //       child {                 // sub msg 3
            //         payload {             // sub msg 4
            //           OptionalGroup {     // sub msg 5
            //             a: 98
            //           }
            //         }
            //       }
            //     }
            ([10, 11, 10, 9, 18, 7, 131, 1, 136, 1, 98, 132, 1],
             [( 10, true ),
              ( 5, true ),
              ( 4, false ),
              ( 3, false )]),

            // Nesting of unknown groups:    // outer is msg 1
            //     4 {                       // sub msg 2
            //       4 {                     // sub msg 3
            //         4 {                   // sub msg 4
            //           1: 1
            //         }
            //       }
            //     }
            // 35 = 0b100011 -> field 4/start group
            // 8, 1 -> field 1/varint, value of 1
            // 36 = 0b100100 -> field 4/end group
            ([35, 35, 35, 8, 1, 36, 36, 36],
             [( 10, true ),
              ( 4, true ),
              ( 3, false ),
              ( 2, false )]),

            // Nested message are on the wire as length delimited, so no depth comes into
            // play when they are unknown.
        ]

        for (i, (binaryInput, testCases)) in tests.enumerated() {
            for (limit, expectSuccess) in testCases {
                do {
                    var options = BinaryDecodingOptions()
                    options.messageDepthLimit = limit
                    let a =
                        try ProtobufUnittest_NestedTestAllTypes(serializedData: Data(binaryInput),
                                                                options: options)
                  print("TVL: \(a)")
                    if !expectSuccess {
                        XCTFail("Should not have succeed, pass: \(i), limit: \(limit)")
                    }
                } catch BinaryDecodingError.messageDepthLimit {
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
