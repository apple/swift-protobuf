// Tests/SwiftProtobufTests/Test_WeakLinkageSupport.swift - Test dynamic symbol caching
//
// Copyright (c) 2014 - 2026 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Test dynamic symbol resolution caching for weak imports.
///
// -----------------------------------------------------------------------------

import Foundation
@_spi(ForGeneratedCodeOnly) import SwiftProtobuf
import XCTest

@_silgen_name("test_weak_linkage_message_schema")
func testWeakLinkageMessageSchemaThunk(_ out: UnsafeMutableRawPointer) {
    out.assumingMemoryBound(to: (MessageSchema?).self).pointee = Google_Protobuf_Empty.messageSchema
}

@_silgen_name("test_weak_linkage_enum_schema")
func testWeakLinkageEnumSchemaThunk(_ out: UnsafeMutableRawPointer) {
    out.assumingMemoryBound(to: (EnumSchema?).self).pointee = Google_Protobuf_Syntax.enumSchema
}

final class Test_WeakLinkageSupport: XCTestCase {

    override func setUp() {
        super.setUp()
        DynamicSymbolCache.shared.resetForTesting()
    }

    override func tearDown() {
        DynamicSymbolCache.shared.resetForTesting()
        super.tearDown()
    }

    func testNegativeCaching() {
        let missingSymbol = "symbol_that_definitely_does_not_exist_\(UUID().uuidString)"
        XCTAssertEqual(DynamicSymbolCache.shared.countForTesting, 0)

        // First resolution: misses in dlsym and caches nil
        let result1 = MessageSchema.resolveLazy(named: missingSymbol)
        XCTAssertNil(result1)
        XCTAssertEqual(DynamicSymbolCache.shared.countForTesting, 1)

        // Second resolution: hits cache directly
        let result2 = MessageSchema.resolveLazy(named: missingSymbol)
        XCTAssertNil(result2)
        XCTAssertEqual(DynamicSymbolCache.shared.countForTesting, 1)

        // Enum resolution for the same symbol hits cache
        let result3 = EnumSchema.resolveLazy(named: missingSymbol)
        XCTAssertNil(result3)
        XCTAssertEqual(DynamicSymbolCache.shared.countForTesting, 1)

        // Map witness resolution for the same symbol hits cache
        let result4 = MessageSchema.resolveLazyMapWitness(named: missingSymbol, keyKind: .int32)
        XCTAssertNil(result4)
        XCTAssertEqual(DynamicSymbolCache.shared.countForTesting, 1)
    }

    func testPositiveCaching() {
        #if canImport(Darwin) || canImport(Glibc) || canImport(Musl) || canImport(Bionic)
        XCTAssertEqual(DynamicSymbolCache.shared.countForTesting, 0)

        let schema1 = MessageSchema.resolveLazy(named: "test_weak_linkage_message_schema")
        XCTAssertNotNil(schema1)
        XCTAssertEqual(DynamicSymbolCache.shared.countForTesting, 1)

        // Subsequent resolution hits cache
        let schema2 = MessageSchema.resolveLazy(named: "test_weak_linkage_message_schema")
        XCTAssertNotNil(schema2)
        XCTAssertEqual(DynamicSymbolCache.shared.countForTesting, 1)

        let enumSchema1 = EnumSchema.resolveLazy(named: "test_weak_linkage_enum_schema")
        XCTAssertNotNil(enumSchema1)
        XCTAssertEqual(DynamicSymbolCache.shared.countForTesting, 2)

        let enumSchema2 = EnumSchema.resolveLazy(named: "test_weak_linkage_enum_schema")
        XCTAssertNotNil(enumSchema2)
        XCTAssertEqual(DynamicSymbolCache.shared.countForTesting, 2)
        #endif
    }

    func testConcurrentAccess() {
        let iterations = 500
        let symbolA = "concurrent_symbol_a"
        let symbolB = "concurrent_symbol_b"

        DispatchQueue.concurrentPerform(iterations: iterations) { i in
            let symbol = (i % 2 == 0) ? symbolA : symbolB
            _ = MessageSchema.resolveLazy(named: symbol)
            _ = EnumSchema.resolveLazy(named: symbol)
            _ = MessageSchema.resolveLazyMapWitness(named: symbol, keyKind: .string)
        }

        XCTAssertEqual(DynamicSymbolCache.shared.countForTesting, 2)
    }
}
