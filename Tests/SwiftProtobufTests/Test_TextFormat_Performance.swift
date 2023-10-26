// Tests/SwiftProtobufTests/Test_TextFormat_proto3.swift - Exercise proto3 text format coding
//
// Copyright (c) 2022 - 2022 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// This is a set of tests for text format protobuf files.
///
// -----------------------------------------------------------------------------

import XCTest
import SwiftProtobuf

final class Test_TextFormat_Performance: XCTestCase, PBTestHelpers {
    typealias MessageTestType = SwiftProtoTesting_Fuzz_Message

    // Each of the following should be under 1s on a reasonably
    // fast machine (originally developed on an M1 MacBook Pro).
    // If they are significantly slower than that, then something
    // may be amiss.

    func testEncoding_manyMapsEncoding_shouldBeUnder1s() {
        let repeats = 50000

        let child = (
            "repeated_message {\n"
            + "  map_fixed64_sint64 {\n"
            + "    key: 20\n"
            + "    value: 8\n"
            + "  }\n"
            + "  map_fixed64_sint64 {\n"
            + "    key: 30\n"
            + "    value: 4\n"
            + "  }\n"
            + "  map_fixed64_sint64 {\n"
            + "    key: 40\n"
            + "    value: 2\n"
            + "  }\n"
            + "}\n"
        )
        let expected = String(repeating: child, count: repeats)

        let msg = MessageTestType.with {
            let child = MessageTestType.with {
               $0.mapFixed64Sint64[20] = 8
               $0.mapFixed64Sint64[30] = 4
               $0.mapFixed64Sint64[40] = 2
            }
            let array = Array<MessageTestType>(repeating: child, count: repeats)
            $0.repeatedMessage = array
        }

        // Map fields used to trigger quadratic behavior, which meant
        // this encoding could take over 60s, but now it should
        // consistently take a fraction of a second. I've skipped
        // decoding here because decoding is much slower -- due to the
        // need to create a lot of objects -- which makes it much less
        // obvious when the encoding goes awry.
        let encoded = msg.textFormatString()
        XCTAssertEqual(expected, encoded)
    }

    func testEncoding_manyAnyEncoding_shouldBeUnder1s() {
        let repeats = 50000

        let child = (
            "repeated_message {\n"
            + "  wkt_any {\n"
            + "    [type.googleapis.com/google.protobuf.Duration] {\n"
            + "      seconds: 123\n"
            + "      nanos: 123456789\n"
            + "    }\n"
            + "  }\n"
            + "}\n"
        )
        let expected = String(repeating: child, count: repeats)

        let msg = MessageTestType.with {
            let child = MessageTestType.with {
                let duration = Google_Protobuf_Duration(seconds: 123, nanos: 123456789)
                $0.wktAny = try! Google_Protobuf_Any(message: duration)
            }
            let array = Array<MessageTestType>(repeating: child, count: repeats)
            $0.repeatedMessage = array
        }

        // Any fields used to trigger quadratic behavior, which meant
        // this encoding could take over 30s, but now it should
        // consistently take a fraction of a second. I've skipped
        // decoding here because decoding is much slower -- due to the
        // need to create a lot of objects -- which makes it much less
        // obvious when the encoding goes awry.
        let encoded = msg.textFormatString()
        XCTAssertEqual(expected, encoded)
    }
}
