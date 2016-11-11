// Test/Sources/TestSuite/Test_Performance.swift - Performance tests
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
/// Various tests that can be used to measure the performance impact of
/// proposed changes.
///
// -----------------------------------------------------------------------------

import Foundation
import XCTest

// TODO: Extend these with some of the sample data from the benchmarks folder.

// TODO: Get this to actually build in Release mode, since performance
// should be measured with optimized builds.

class Test_Performance: XCTestCase {

    func testSingularSerialize() {
        // Serialize a message with various singular fields set
        var m = Swift_Performance_TestAllTypes();
        m.optionalInt32 = Int32.min
        m.optionalInt64 = Int64.max
        m.optionalUint32 = UInt32.max
        m.optionalUint64 = UInt64.max
        m.optionalSint32 = 1
        m.optionalSint64 = 1
        m.optionalFixed32 = 1
        m.optionalFixed64 = 1
        m.optionalSfixed32 = 1
        m.optionalSfixed64 = 1
        m.optionalFloat = 51.5
        m.optionalDouble = 777.777
        m.optionalBool = true
        m.optionalString = "abcdefghijklmnopqrstuvwxyz"
        m.optionalBytes = Data(bytes: Array<UInt8>(repeating:255, count:255))

        self.measure {
            do {
                for _ in 0..<10000 {
                    let _ = try m.serializeProtobufBytes()
                }
            } catch {
            }
        }
    }

}
