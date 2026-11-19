// Copyright (c) 2014 - 2026 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------

import FuzzCommon
import SwiftProtobuf
import XCTest

final class Test_AnyRegistration: XCTestCase {
    func testRegisterTypes() {
        FuzzAnyRegistry.registerTypes()
        // Calling a second time should be idempotent.
        FuzzAnyRegistry.registerTypes()

        XCTAssertTrue(
            Google_Protobuf_Any.messageType(
                forMessageName: SwiftProtoTesting_Fuzz_Message.protoMessageName
            ) == SwiftProtoTesting_Fuzz_Message.self
        )
        XCTAssertTrue(
            Google_Protobuf_Any.messageType(
                forMessageName: SwiftProtoTesting_Fuzz_AMessageSetMessage.protoMessageName
            ) == SwiftProtoTesting_Fuzz_AMessageSetMessage.self
        )
        XCTAssertTrue(
            Google_Protobuf_Any.messageType(
                forMessageName: SwiftProtoTesting_Fuzz_MessageWithRequired.protoMessageName
            ) == SwiftProtoTesting_Fuzz_MessageWithRequired.self
        )
    }
}
