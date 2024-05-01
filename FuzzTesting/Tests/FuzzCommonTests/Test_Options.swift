// Copyright (c) 2014 - 2024 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------

import Foundation
import XCTest

import FuzzCommon

struct TestOptions : SupportsFuzzOptions {

    var bool1: Bool = false {
        didSet { sets.append("bool1:\(bool1)") }
    }

    var bool2: Bool = false {
        didSet { sets.append("bool2:\(bool2)") }
    }

    var int1: Int = 100 {
        didSet { sets.append("int1:\(int1)") }
    }
    var int2: Int = 1 {
        didSet { sets.append("int2:\(int2)") }
    }

    var sets: [String] = []

    static var fuzzOptionsList: [FuzzCommon.FuzzOption<Self>] = [
        .boolean(\.bool1),
        .boolean(\.bool2),
        .byte(\.int1),
        .byte(\.int2, mod: 16),
    ]

    init() {}
}

struct TestOptionsLarge : SupportsFuzzOptions {

    var bool1: Bool = false {
        didSet { sets.append("bool1:\(bool1)") }
    }
    var bool2: Bool = false {
        didSet { sets.append("bool2:\(bool2)") }
    }
    var bool3: Bool = false {
        didSet { sets.append("bool3:\(bool3)") }
    }
    var bool4: Bool = false {
        didSet { sets.append("bool4:\(bool4)") }
    }
    var int1: Int = 100 {
        didSet { sets.append("int1:\(int1)") }
    }
    var bool5: Bool = false {
        didSet { sets.append("bool5:\(bool5)") }
    }
    var bool6: Bool = false {
        didSet { sets.append("bool6:\(bool6)") }
    }
    var bool7: Bool = false {
        didSet { sets.append("bool7:\(bool7)") }
    }
    var bool8: Bool = false {
        didSet { sets.append("bool8:\(bool8)") }
    }
    var int2: Int = 1 {
        didSet { sets.append("int2:\(int2)") }
    }

    var sets: [String] = []

    static var fuzzOptionsList: [FuzzCommon.FuzzOption<Self>] = [
        .boolean(\.bool1),
        .boolean(\.bool2),
        .boolean(\.bool3),
        .boolean(\.bool4),
        .byte(\.int1),
        .boolean(\.bool5),
        .boolean(\.bool6),
        .boolean(\.bool7),
        .boolean(\.bool8),
        .byte(\.int2),
    ]

    init() {}
}

final class Test_FuzzOptions: XCTestCase {

    func testOptionBasics_noOptionsSignal() throws {
        // Claim no bytes passed.
        let bytes: [UInt8] = [ ]
        XCTAssertEqual(bytes.count, 0)
        try bytes.withUnsafeBytes { ptr in
            let result = TestOptions.extractOptions(ptr.baseAddress!, bytes.count)
            let (opts, bytes) = try XCTUnwrap(result)
            XCTAssertEqual(opts.sets, [])
            XCTAssertEqual(bytes.count, 0)
        }

        // Try with no leading zero, so no options.
        for x: UInt8 in 1...UInt8.max {
            let bytes: [UInt8] = [ x ]
            XCTAssertEqual(bytes.count, 1)
            try bytes.withUnsafeBytes { ptr in
                let result = TestOptions.extractOptions(ptr.baseAddress!, bytes.count)
                let (opts, bytes) = try XCTUnwrap(result)
                XCTAssertEqual(opts.sets, [])
                // The buffer comes through.
                XCTAssertEqual(bytes.count, 1)
                XCTAssertEqual(bytes.baseAddress, ptr.baseAddress)
            }
        }
    }

    func testOptionBasics_optionsSignalNoBytes() throws {
        let bytes: [UInt8] = [ 0 ]  // Options signal, then nothing
        XCTAssertEqual(bytes.count, 1)
        try bytes.withUnsafeBytes { ptr in
            let result = TestOptions.extractOptions(ptr.baseAddress!, bytes.count)
            let (opts, bytes) = try XCTUnwrap(result)
            XCTAssertEqual(opts.sets, [])
            // Since no following bytes, the buffer comes through.
            XCTAssertEqual(bytes.count, 1)
            XCTAssertEqual(bytes.baseAddress, ptr.baseAddress)
        }
    }

    func testOptionBasics_bool() throws {
        let testCases: [(byte: UInt8, b1: Bool, b2: Bool, sets: [String])] = [
            (0x0, false, false, ["bool1:false", "bool2:false"]),
            (0x1, true, false, ["bool1:true", "bool2:false"]),
            (0x2, false, true, ["bool1:false", "bool2:true"]),
            (0x3, true, true, ["bool1:true", "bool2:true"]),
        ]
        for test in testCases {
            let bytes: [UInt8] = [ 0, test.byte]
            XCTAssertEqual(bytes.count, 2)
            try bytes.withUnsafeBytes { ptr in
                let result = TestOptions.extractOptions(ptr.baseAddress!, bytes.count)
                let (opts, bytes) = try XCTUnwrap(result)
                XCTAssertEqual(opts.sets, test.sets)
                XCTAssertEqual(bytes.count, 0)  // No bytes, the one was the options
                XCTAssertNotEqual(bytes.baseAddress, ptr.baseAddress)
                XCTAssertEqual(opts.bool1, test.b1)
                XCTAssertEqual(opts.bool2, test.b2)
            }
        }
    }

    func testOptionBasics_byte() throws {
        let testCases: [(bytes: [UInt8], i1: Int, i2: Int, sets: [String])] = [
            ([0x0], 100, 1, []),
            ([0x4, 2], 2, 1, ["int1:2"]),
            ([0x8, 7], 100, 7, ["int2:7"]),
            ([0xC, 3, 20], 3, 4, ["int1:3", "int2:4"]),  // int2 has a mod applied
        ]
        for test in testCases {
            let bytes: [UInt8] = [ 0 ] + test.bytes
            try bytes.withUnsafeBytes { ptr in
                let result = TestOptions.extractOptions(ptr.baseAddress!, bytes.count)
                let (opts, bytes) = try XCTUnwrap(result)
                XCTAssertEqual(opts.sets, ["bool1:false", "bool2:false"] + test.sets)
                XCTAssertEqual(bytes.count, 0)  // No bytes, the one was the options
                XCTAssertNotEqual(bytes.baseAddress, ptr.baseAddress)
                XCTAssertEqual(opts.int1, test.i1)
                XCTAssertEqual(opts.int2, test.i2)
            }
        }
    }

    func testOptionBasics_byteMissingData() {
        let testCases: [[UInt8]] = [
            [0x4],  // int1, no data
            [0x8],  // int2, no data
            [0xC],  // int1 & int2, no data
            [0xC, 20],  // int1 & int2, data for only int1
        ]
        for test in testCases {
            let bytes: [UInt8] = [ 0 ] + test
            bytes.withUnsafeBytes { ptr in
                XCTAssertNil(TestOptions.extractOptions(ptr.baseAddress!, bytes.count))
            }
        }
    }

    func testOptionBasics_tailingZeros() {
        // Try every value that will have at least one bit set above the valid ones
        // to ensure it causing parsing failure.
        for x: UInt8 in 0x10...UInt8.max {
            let bytes: [UInt8] = [ 0, x ]
            bytes.withUnsafeBytes { ptr in
                XCTAssertNil(TestOptions.extractOptions(ptr.baseAddress!, bytes.count))
            }
        }
    }

    func testOptionBasics_tailingMoreThan7_tailingZeros() {
        // For the first byte of optionBits, just signal that there is a second, but
        // then set all the expected zero bits to ensure it fails.
        for x: UInt8 in 0x8...UInt8.max {
            let bytes: [UInt8] = [ 0, 0x80, x ]
            bytes.withUnsafeBytes { ptr in
                XCTAssertNil(TestOptions.extractOptions(ptr.baseAddress!, bytes.count))
            }
        }
    }

    func testOptionBasics_bytesAfterOptsComeThrough() throws {
        let bytes: [UInt8] = [ 0, 0, 1, 2, 3]
        XCTAssertEqual(bytes.count, 5)
        try bytes.withUnsafeBytes { ptr in
            let result = TestOptions.extractOptions(ptr.baseAddress!, bytes.count)
            let (opts, bytes) = try XCTUnwrap(result)
            XCTAssertEqual(opts.sets, ["bool1:false", "bool2:false"])
            XCTAssertEqual(bytes.count, 3)
            XCTAssertNotEqual(bytes.baseAddress, ptr.baseAddress)
            XCTAssertEqual(bytes.loadUnaligned(fromByteOffset: 0, as: UInt8.self), 1)
            XCTAssertEqual(bytes.loadUnaligned(fromByteOffset: 1, as: UInt8.self), 2)
            XCTAssertEqual(bytes.loadUnaligned(fromByteOffset: 2, as: UInt8.self), 3)
        }

        // Make sure data is right after a bytes value also
        let bytes2: [UInt8] = [ 0, 0x4, 20, 4, 15, 26]
        try bytes2.withUnsafeBytes { ptr in
            let result = TestOptions.extractOptions(ptr.baseAddress!, bytes2.count)
            let (opts, bytes) = try XCTUnwrap(result)
            XCTAssertEqual(opts.sets, ["bool1:false", "bool2:false", "int1:20"])
            XCTAssertEqual(bytes.count, 3)
            XCTAssertNotEqual(bytes.baseAddress, ptr.baseAddress)
            XCTAssertEqual(bytes.loadUnaligned(fromByteOffset: 0, as: UInt8.self), 4)
            XCTAssertEqual(bytes.loadUnaligned(fromByteOffset: 1, as: UInt8.self), 15)
            XCTAssertEqual(bytes.loadUnaligned(fromByteOffset: 2, as: UInt8.self), 26)
        }

        // Options that can spill to two bytes for the optionBits.

        // Only one byte of optionsBits
        let bytes3: [UInt8] = [ 0, 0, 1, 2, 3]
        XCTAssertEqual(bytes3.count, 5)
        try bytes3.withUnsafeBytes { ptr in
            let result = TestOptionsLarge.extractOptions(ptr.baseAddress!, bytes3.count)
            let (opts, bytes) = try XCTUnwrap(result)
            XCTAssertEqual(opts.sets, ["bool1:false", "bool2:false", "bool3:false", "bool4:false", "bool5:false", "bool6:false"])
            XCTAssertEqual(bytes.count, 3)
            XCTAssertNotEqual(bytes.baseAddress, ptr.baseAddress)
            XCTAssertEqual(bytes.loadUnaligned(fromByteOffset: 0, as: UInt8.self), 1)
            XCTAssertEqual(bytes.loadUnaligned(fromByteOffset: 1, as: UInt8.self), 2)
            XCTAssertEqual(bytes.loadUnaligned(fromByteOffset: 2, as: UInt8.self), 3)
        }

        // Two bytes of optionsBits with a `byte` value
        let bytes4: [UInt8] = [ 0, 0x90, 123, 0x4, 20, 81, 92, 103]
        XCTAssertEqual(bytes4.count, 8)
        try bytes4.withUnsafeBytes { ptr in
            let result = TestOptionsLarge.extractOptions(ptr.baseAddress!, bytes4.count)
            let (opts, bytes) = try XCTUnwrap(result)
            XCTAssertEqual(opts.sets, ["bool1:false", "bool2:false", "bool3:false", "bool4:false", "int1:123", "bool5:false", "bool6:false", "bool7:false", "bool8:false", "int2:20"])
            XCTAssertEqual(bytes.count, 3)
            XCTAssertNotEqual(bytes.baseAddress, ptr.baseAddress)
            XCTAssertEqual(bytes.loadUnaligned(fromByteOffset: 0, as: UInt8.self), 81)
            XCTAssertEqual(bytes.loadUnaligned(fromByteOffset: 1, as: UInt8.self), 92)
            XCTAssertEqual(bytes.loadUnaligned(fromByteOffset: 2, as: UInt8.self), 103)
        }
    }
}
