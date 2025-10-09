// Tests/SwiftProtobufTests/Test_OneofSwitchSplit.swift
//
// Copyright (c) 2014 - 2025 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Test that large oneof fields with split switch statements work correctly.
/// This proto has 508 oneof fields with 2 interleaved regular fields that
/// create chunks. With maxCasesInSwitch=500, this tests both:
/// - Chunking: regular fields at 251 and 502 split the oneof into 3 groups
/// - Each chunk is under 500 fields, so no further splitting within chunks
///
/// The primary testing is through reference file inspection (see Reference/).
/// These runtime tests are minimal smoke tests to verify basic functionality.
///
// -----------------------------------------------------------------------------

import Foundation
import XCTest
import SwiftProtobuf

final class Test_OneofSwitchSplit: XCTestCase {

    func testChunkBoundaries() throws {
        var msg = SwiftProtoTesting_SwitchSplit_SwitchSplitMessage()
        
        // Test chunk 1: fields 1-250 (before regular_field_251)
        msg.field001 = 1
        XCTAssertEqual(msg.field001, 1)
        msg.field250 = 250
        XCTAssertEqual(msg.field250, 250)
        
        // Test chunk 2: fields 252-501 (between regular fields)
        msg.field252 = 252
        XCTAssertEqual(msg.field252, 252)
        msg.field501 = 501
        XCTAssertEqual(msg.field501, 501)
        
        // Test chunk 3: fields 503-510 (after regular_field_502)
        msg.field503 = 503
        XCTAssertEqual(msg.field503, 503)
        msg.field510 = 510
        XCTAssertEqual(msg.field510, 510)
        
        // Test regular fields don't interfere with oneof
        msg.regularField251 = 999
        XCTAssertEqual(msg.regularField251, 999)
        XCTAssertEqual(msg.field510, 510) // oneof still set
    }
    
    func testSerializationAcrossChunks() throws {
        // Test serialization from each chunk
        var msg1 = SwiftProtoTesting_SwitchSplit_SwitchSplitMessage()
        msg1.field100 = 100
        let data1 = try msg1.serializedData()
        let decoded1 = try SwiftProtoTesting_SwitchSplit_SwitchSplitMessage(serializedBytes: data1)
        XCTAssertEqual(decoded1.field100, 100)
        
        var msg2 = SwiftProtoTesting_SwitchSplit_SwitchSplitMessage()
        msg2.field400 = 400
        let data2 = try msg2.serializedData()
        let decoded2 = try SwiftProtoTesting_SwitchSplit_SwitchSplitMessage(serializedBytes: data2)
        XCTAssertEqual(decoded2.field400, 400)
        
        var msg3 = SwiftProtoTesting_SwitchSplit_SwitchSplitMessage()
        msg3.field505 = 505
        let data3 = try msg3.serializedData()
        let decoded3 = try SwiftProtoTesting_SwitchSplit_SwitchSplitMessage(serializedBytes: data3)
        XCTAssertEqual(decoded3.field505, 505)
    }
}

