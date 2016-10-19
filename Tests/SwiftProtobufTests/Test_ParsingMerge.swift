// Test/Sources/TestSuite/Test_ParsingMerge.swift - Exercise "parsing merge" behavior
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
/// Protobuf decoding defines specific handling when
/// a singular message field appears more than once.
/// This can happen, for example, when partial messages
/// are concatenated.
///
// -----------------------------------------------------------------------------

import Foundation
import XCTest

class Test_ParsingMerge: XCTestCase {

    func test_Merge() {
        // Repeated fields generator has field1
        var m = ProtobufUnittest_TestParsingMerge.RepeatedFieldsGenerator()

        // Populate 'field1'
        var t1 = ProtobufUnittest_TestAllTypes()
        t1.optionalInt32 = 1
        t1.optionalString = "abc"
        var t2 = ProtobufUnittest_TestAllTypes()
        t2.optionalInt32 = 2 // Should override t1.optionalInt32
        t2.optionalInt64 = 3
        m.field1 = [t1, t2]

        // Populate 'field2'
        m.field2 = [t1, t2]

        // Populate 'field3'
        m.field3 = [t1, t2]

        // Populate group1
        var g1a = ProtobufUnittest_TestParsingMerge.RepeatedFieldsGenerator.Group1()
        var g1b = g1a
        g1a.field1 = t1
        g1b.field1 = t2
        m.group1 = [g1a, g1b]

        // Populate group2
        var g2a = ProtobufUnittest_TestParsingMerge.RepeatedFieldsGenerator.Group2()
        var g2b = g2a
        g2a.field1 = t1
        g2b.field1 = t2
        m.group2 = [g2a, g2b]

        // Encode/decode should merge repeated fields into non-repeated
        do {
            let encoded = try m.serializeProtobuf()
            do {
                let decoded = try ProtobufUnittest_TestParsingMerge(protobuf: encoded)

                // requiredAllTypes <== merge of field1
                let field1 = decoded.requiredAllTypes
                XCTAssertEqual(field1.optionalInt32, 2)
                XCTAssertEqual(field1.optionalInt64, 3)
                XCTAssertEqual(field1.optionalString, "abc")

                // optionalAllTypes <== merge of field2
                let field2 = decoded.optionalAllTypes
                XCTAssertEqual(field2.optionalInt32, 2)
                XCTAssertEqual(field2.optionalInt64, 3)
                XCTAssertEqual(field2.optionalString, "abc")

                // repeatedAllTypes <== field3 without merging
                XCTAssertEqual(decoded.repeatedAllTypes, [t1, t2])
                
                // optionalGroup <== merge of repeated group1
                let group1 = decoded.optionalGroup
                XCTAssertEqual(group1.optionalGroupAllTypes.optionalInt32, 2)
                XCTAssertEqual(group1.optionalGroupAllTypes.optionalString, "abc")
                XCTAssertEqual(group1.optionalGroupAllTypes.optionalInt64, 3)

                // repeatedGroup <== no merge from repeated group2
                XCTAssertEqual(decoded.repeatedGroup.count, 2)
                XCTAssertEqual(decoded.repeatedGroup[0].repeatedGroupAllTypes, t1)
                XCTAssertEqual(decoded.repeatedGroup[1].repeatedGroupAllTypes, t2)
            } catch {
                XCTFail("Decoding failed \(encoded)")
            }
        } catch let e {
            XCTFail("Encoding failed for \(m) with error \(e)")
        }
    }
}
