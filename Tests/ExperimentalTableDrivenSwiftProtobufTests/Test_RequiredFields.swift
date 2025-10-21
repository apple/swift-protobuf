// Tests/ExperimentalTableDrivenSwiftProtobufTests/Test_RequiredFields.swift - Exercise table-driven required fields
//
// Copyright (c) 2014 - 2025 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Some early tests for required fields in table-driven protos that can be
/// built separately without requiring that everything be migrated all at once.
///
// -----------------------------------------------------------------------------

import Foundation
import SwiftProtobuf
import XCTest

final class Test_RequiredFields: XCTestCase {
    func testRequired1_isNotInitialized() {
        var msg = SwiftProtoTesting_Required1()
        XCTAssertFalse(msg.isInitialized)

        msg.opt2 = 50
        XCTAssertFalse(msg.isInitialized)
    }

    func testRequired1_isInitialized() {
        var msg = SwiftProtoTesting_Required1()
        msg.req1 = 50
        XCTAssertTrue(msg.isInitialized)
    }

    func testRequired1_isNotInitializedAfterClear() {
        var msg = SwiftProtoTesting_Required1()
        msg.req1 = 50
        msg.clearReq1()
        XCTAssertFalse(msg.isInitialized)
    }

    func testRequired8_isNotInitialized() {
        var msg = SwiftProtoTesting_Required8()
        XCTAssertFalse(msg.isInitialized)

        msg.req1 = 50
        XCTAssertFalse(msg.isInitialized)

        msg.req2 = 50
        msg.req3 = 50
        msg.req4 = 50
        msg.req5 = 50
        msg.req6 = 50
        msg.req7 = 50
        XCTAssertFalse(msg.isInitialized)
    }

    func testRequired8_isInitialized() {
        var msg = SwiftProtoTesting_Required8()
        msg.req1 = 50
        msg.req2 = 50
        msg.req3 = 50
        msg.req4 = 50
        msg.req5 = 50
        msg.req6 = 50
        msg.req7 = 50
        msg.req8 = 50
        XCTAssertTrue(msg.isInitialized)
    }

    func testRequired8_isNotInitializedAfterClear() {
        var msg = SwiftProtoTesting_Required8()
        msg.req1 = 50
        msg.req2 = 50
        msg.req3 = 50
        msg.req4 = 50
        msg.req5 = 50
        msg.req6 = 50
        msg.req7 = 50
        msg.req8 = 50
        msg.clearReq1()
        XCTAssertFalse(msg.isInitialized)
    }

    func testRequired9_isNotInitialized() {
        var msg = SwiftProtoTesting_Required9()
        XCTAssertFalse(msg.isInitialized)

        msg.req1 = 50
        XCTAssertFalse(msg.isInitialized)

        msg.req2 = 50
        msg.req3 = 50
        msg.req4 = 50
        msg.req5 = 50
        msg.req6 = 50
        msg.req7 = 50
        msg.req8 = 50
        XCTAssertFalse(msg.isInitialized)
    }

    func testRequired9_isInitialized() {
        var msg = SwiftProtoTesting_Required9()
        msg.req1 = 50
        msg.req2 = 50
        msg.req3 = 50
        msg.req4 = 50
        msg.req5 = 50
        msg.req6 = 50
        msg.req7 = 50
        msg.req8 = 50
        msg.req9 = 50
        XCTAssertTrue(msg.isInitialized)
    }

    func testRequired9_isNotInitializedAfterClear() {
        var msg = SwiftProtoTesting_Required9()
        msg.req1 = 50
        msg.req2 = 50
        msg.req3 = 50
        msg.req4 = 50
        msg.req5 = 50
        msg.req6 = 50
        msg.req7 = 50
        msg.req8 = 50
        msg.req9 = 50
        msg.clearReq9()
        XCTAssertFalse(msg.isInitialized)
    }

    func testRequiredMixedOrder_isNotInitialized() {
        var msg = SwiftProtoTesting_RequiredMixedOrder()
        XCTAssertFalse(msg.isInitialized)
        msg.req1 = 50
        msg.req3 = 50
        msg.req5 = 50
        XCTAssertFalse(msg.isInitialized)
    }

    func testRequiredMixedOrder_isInitialized() {
        var msg = SwiftProtoTesting_RequiredMixedOrder()
        msg.req1 = 50
        msg.req3 = 50
        msg.req5 = 50
        msg.req7 = 50
        XCTAssertTrue(msg.isInitialized)
    }

    func testRequiredWithSubmessage() {
        var msg = SwiftProtoTesting_RequiredWithNested()
        XCTAssertFalse(msg.isInitialized)

        msg.nested = SwiftProtoTesting_NestedRequired()
        XCTAssertFalse(msg.isInitialized)

        msg.nested.req1 = 50
        XCTAssertTrue(msg.isInitialized)
    }

    func testRequiredWithRepeatedSubmessage() {
        var msg = SwiftProtoTesting_RequiredWithRepeatedNested()
        XCTAssertFalse(msg.isInitialized)

        msg.nested = [SwiftProtoTesting_NestedRequired(), SwiftProtoTesting_NestedRequired()]
        XCTAssertFalse(msg.isInitialized)

        msg.nested[0].req1 = 50
        XCTAssertFalse(msg.isInitialized)

        msg.nested[1].req1 = 50
        XCTAssertTrue(msg.isInitialized)
    }

    func testNoneRequired() {
        let msg = SwiftProtoTesting_NoneRequired()
        XCTAssertTrue(msg.isInitialized)
    }

    func testNoneRequiredButNestedRequired() {
        var msg = SwiftProtoTesting_NoneRequiredButNestedRequired()
        XCTAssertFalse(msg.isInitialized)

        msg.opt1 = 50
        XCTAssertFalse(msg.isInitialized)

        msg.opt2 = SwiftProtoTesting_NestedRequired()
        XCTAssertFalse(msg.isInitialized)

        msg.opt2.req1 = 50
        XCTAssertTrue(msg.isInitialized)

        msg.opt2.clearReq1()
        XCTAssertFalse(msg.isInitialized)
    }
}
