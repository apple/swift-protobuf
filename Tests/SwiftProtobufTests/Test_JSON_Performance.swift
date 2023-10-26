// Tests/SwiftProtobufTests/Test_JSON_Performance.swift - JSON performance checks
//
// Copyright (c) 2022 - 2022 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// This is a set of tests for JSON format protobuf files.
///
// -----------------------------------------------------------------------------

import XCTest
import SwiftProtobuf

final class Test_JSON_Performance: XCTestCase, PBTestHelpers {
    typealias MessageTestType = SwiftProtoTesting_Fuzz_Message

    // Each of the following should be under 1s on a reasonably
    // fast machine (originally developed on an M1 MacBook Pro).
    // If they are significantly slower than that, then something
    // may be amiss.

    func testEncoding_manyIntMapsEncoding_shouldBeUnder1s() {
        let rawPadding = Array<Int32>(repeating: 1000000000, count: 150000)
        let mapRepeats = 60000

        let pad = rawPadding.map({$0.description}).joined(separator: ",")
        let child = "{\"mapFixed64Sint64\":{\"30\":\"4\"}}"
        let children = Array<String>(repeating: child, count: mapRepeats).joined(separator: ",")
        let expected = (
            "{"
            + "\"repeatedInt32\":["
            + pad
            + "],"
            + "\"repeatedMessage\":["
            + children
            + "]}"
        )

        let msg = MessageTestType.with {
            $0.repeatedInt32 = rawPadding
            let child = MessageTestType.with {
               $0.mapFixed64Sint64[30] = 4
            }
            let array = Array<MessageTestType>(repeating: child, count: mapRepeats)
            $0.repeatedMessage = array
        }

        // Map fields used to trigger quadratic behavior, which meant
        // this encoding could take over 30s, but now it should
        // consistently take a fraction of a second. I've skipped
        // decoding here because decoding is much slower -- due to the
        // need to create a lot of objects -- which makes it much less
        // obvious when the encoding goes awry.
        let encoded = try! msg.jsonString()
        XCTAssertEqual(expected, encoded)
    }

    func testEncoding_manyEnumMapsEncoding_shouldBeUnder1s() {
        let rawPadding = Array<Int32>(repeating: 1000000000, count: 150000)
        let mapRepeats = 60000

        let pad = rawPadding.map({$0.description}).joined(separator: ",")
        let child = "{\"mapInt32AnEnum\":{\"30\":\"TWO\"}}"
        let children = Array<String>(repeating: child, count: mapRepeats).joined(separator: ",")
        let expected = (
            "{"
            + "\"repeatedInt32\":["
            + pad
            + "],"
            + "\"repeatedMessage\":["
            + children
            + "]}"
        )

        let msg = MessageTestType.with {
            $0.repeatedInt32 = rawPadding
            let child = MessageTestType.with {
               $0.mapInt32AnEnum[30] = SwiftProtoTesting_Fuzz_AnEnum.two
            }
            let array = Array<MessageTestType>(repeating: child, count: mapRepeats)
            $0.repeatedMessage = array
        }

        // Map fields used to trigger quadratic behavior, which meant
        // this encoding could take over 30s, but now it should
        // consistently take a fraction of a second. I've skipped
        // decoding here because decoding is much slower -- due to the
        // need to create a lot of objects -- which makes it much less
        // obvious when the encoding goes awry.
        let encoded = try! msg.jsonString()
        XCTAssertEqual(expected, encoded)
    }


    func testEncoding_manyMessageMapsEncoding_shouldBeUnder1s() {
        let rawPadding = Array<Int32>(repeating: 1000000000, count: 150000)
        let mapRepeats = 50000

        let pad = rawPadding.map({$0.description}).joined(separator: ",")
        let child = "{\"mapInt32Message\":{\"30\":{\"singularInt32\":8}}}"
        let children = Array<String>(repeating: child, count: mapRepeats).joined(separator: ",")
        let expected = (
            "{"
            + "\"repeatedInt32\":["
            + pad
            + "],"
            + "\"repeatedMessage\":["
            + children
            + "]}"
        )

        let msg = MessageTestType.with {
            $0.repeatedInt32 = rawPadding
            let child = MessageTestType.with {
               let grandchild = MessageTestType.with {
                   $0.singularInt32 = 8
               }
               $0.mapInt32Message[30] = grandchild
            }
            let array = Array<MessageTestType>(repeating: child, count: mapRepeats)
            $0.repeatedMessage = array
        }

        // Map fields used to trigger quadratic behavior, which meant
        // this encoding could take over 30s, but now it should
        // consistently take a fraction of a second. I've skipped
        // decoding here because decoding is much slower -- due to the
        // need to create a lot of objects -- which makes it much less
        // obvious when the encoding goes awry.
        let encoded = try! msg.jsonString()
        XCTAssertEqual(expected, encoded)
    }
}
