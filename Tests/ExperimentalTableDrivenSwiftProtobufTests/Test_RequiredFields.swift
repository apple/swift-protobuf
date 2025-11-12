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
        // True because the submessage field is optional.
        XCTAssertTrue(msg.isInitialized)

        msg.nested = [SwiftProtoTesting_NestedRequired(), SwiftProtoTesting_NestedRequired()]
        // Now false because we've explicitly set the submessage field but it's missing required
        // fields.
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
        // True because the submessage field is optional.
        XCTAssertTrue(msg.isInitialized)

        msg.opt1 = 50
        // Still true because the submessage field is optional.
        XCTAssertTrue(msg.isInitialized)

        msg.opt2 = SwiftProtoTesting_NestedRequired()
        // Now false because we've explicitly set the submessage field but it's missing required
        // fields.
        XCTAssertFalse(msg.isInitialized)

        msg.opt2.req1 = 50
        XCTAssertTrue(msg.isInitialized)

        msg.opt2.clearReq1()
        XCTAssertFalse(msg.isInitialized)
    }

    func testMapWithRequiredFieldsInValues() {
        var msg = SwiftProtoTesting_MapWithNestedRequiredValues()
        XCTAssertTrue(msg.isInitialized)

        msg.map1[0] = SwiftProtoTesting_NestedRequired()
        XCTAssertFalse(msg.isInitialized)

        msg.map1[0]!.req1 = 50
        XCTAssertTrue(msg.isInitialized)

        msg.map1[0] = nil
        XCTAssertTrue(msg.isInitialized)
    }

    // Helper to assert encoding fails with a not initialized error.
    fileprivate func assertEncodeFailsNotInitialized(
        _ message: SwiftProtoTesting_TestAllRequiredTypes,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        do {
            let _: [UInt8] = try message.serializedBytes()
            XCTFail("Swift encode should have failed", file: file, line: line)
        } catch BinaryEncodingError.missingRequiredFields {
            // Correct error!
        } catch let e {
            XCTFail("Encoding got wrong error: \(e)", file: file, line: line)
        }
    }

    // Helper to assert encoding partial succeeds.
    fileprivate func assertPartialEncodeSucceeds(
        _ message: SwiftProtoTesting_TestAllRequiredTypes,
        _ expectedBytes: [UInt8],
        file: StaticString = #file,
        line: UInt = #line
    ) {
        do {
            let data: [UInt8] = try message.serializedBytes(partial: true)
            XCTAssertEqual(data, expectedBytes, "While encoding", file: file, line: line)
        } catch let e {
            XCTFail("Encoding failed with error: \(e)", file: file, line: line)
        }
    }

    func test_encodeRequired() throws {
        let msg = SwiftProtoTesting_TestAllRequiredTypes()

        // Empty message.
        assertEncodeFailsNotInitialized(msg)
        assertPartialEncodeSucceeds(msg, [])

        typealias ConfigurationBlock = (inout SwiftProtoTesting_TestAllRequiredTypes) -> Void

        // Test every field on its own.
        let testInputs: [([UInt8], ConfigurationBlock)] = [
            ([8, 1], { (m) in m.requiredInt32 = 1 }),
            ([16, 2], { (m) in m.requiredInt64 = 2 }),
            ([24, 3], { (m) in m.requiredUint32 = 3 }),
            ([32, 4], { (m) in m.requiredUint64 = 4 }),
            ([40, 10], { (m) in m.requiredSint32 = 5 }),
            ([48, 12], { (m) in m.requiredSint64 = 6 }),
            ([61, 7, 0, 0, 0], { (m) in m.requiredFixed32 = 7 }),
            ([65, 8, 0, 0, 0, 0, 0, 0, 0], { (m) in m.requiredFixed64 = 8 }),
            ([77, 9, 0, 0, 0], { (m) in m.requiredSfixed32 = 9 }),
            ([81, 10, 0, 0, 0, 0, 0, 0, 0], { (m) in m.requiredSfixed64 = 10 }),
            ([93, 0, 0, 48, 65], { (m) in m.requiredFloat = 11 }),
            ([97, 0, 0, 0, 0, 0, 0, 40, 64], { (m) in m.requiredDouble = 12 }),
            ([104, 1], { (m) in m.requiredBool = true }),
            ([114, 2, 49, 52], { (m) in m.requiredString = "14" }),
            ([122, 1, 15], { (m) in m.requiredBytes = Data([15]) }),
            ([131, 1, 136, 1, 16, 132, 1], { (m) in m.requiredGroup.a = 16 }),
            ([146, 1, 2, 8, 18], { (m) in m.requiredNestedMessage.bb = 18 }),
            ([154, 1, 2, 8, 19], { (m) in m.requiredForeignMessage.c = 19 }),
            ([162, 1, 2, 8, 20], { (m) in m.requiredImportMessage.d = 20 }),
            ([210, 1, 2, 8, 26], { (m) in m.requiredPublicImportMessage.e = 26 }),
            ([232, 3, 61], { (m) in m.defaultInt32 = 61 }),
            ([240, 3, 62], { (m) in m.defaultInt64 = 62 }),
            ([248, 3, 63], { (m) in m.defaultUint32 = 63 }),
            ([128, 4, 64], { (m) in m.defaultUint64 = 64 }),
            ([136, 4, 130, 1], { (m) in m.defaultSint32 = 65 }),
            ([144, 4, 132, 1], { (m) in m.defaultSint64 = 66 }),
            ([157, 4, 67, 0, 0, 0], { (m) in m.defaultFixed32 = 67 }),
            ([161, 4, 68, 0, 0, 0, 0, 0, 0, 0], { (m) in m.defaultFixed64 = 68 }),
            ([173, 4, 69, 0, 0, 0], { (m) in m.defaultSfixed32 = 69 }),
            ([177, 4, 70, 0, 0, 0, 0, 0, 0, 0], { (m) in m.defaultSfixed64 = 70 }),
            ([189, 4, 0, 0, 142, 66], { (m) in m.defaultFloat = 71 }),
            ([193, 4, 0, 0, 0, 0, 0, 0, 82, 64], { (m) in m.defaultDouble = 72 }),
            ([200, 4, 0], { (m) in m.defaultBool = false }),
            ([210, 4, 2, 55, 52], { (m) in m.defaultString = "74" }),
            ([218, 4, 1, 75], { (m) in m.defaultBytes = Data([75]) }),
        ]
        for (expected, configure) in testInputs {
            var message = SwiftProtoTesting_TestAllRequiredTypes()
            configure(&message)
            assertEncodeFailsNotInitialized(message)
            assertPartialEncodeSucceeds(message, expected)
        }

        // TODO: The part of the test that glues all the messages above together won't work until
        // we support enums.
    }
}
