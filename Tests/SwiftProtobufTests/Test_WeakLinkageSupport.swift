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
        nonisolated(unsafe) var providerCallCount = 0
        DynamicSymbolCache.shared.resetForTesting { _ in
            providerCallCount += 1
            return nil
        }
        XCTAssertEqual(DynamicSymbolCache.shared.countForTesting, 0)

        // First resolution: misses and caches nil
        let result1 = MessageSchema.resolveLazy(named: missingSymbol)
        XCTAssertNil(result1)
        XCTAssertEqual(DynamicSymbolCache.shared.countForTesting, 1)
        XCTAssertEqual(providerCallCount, 1)

        // Second resolution: hits cache directly without calling provider
        let result2 = MessageSchema.resolveLazy(named: missingSymbol)
        XCTAssertNil(result2)
        XCTAssertEqual(DynamicSymbolCache.shared.countForTesting, 1)
        XCTAssertEqual(providerCallCount, 1)

        // Enum resolution for the same symbol hits cache
        let result3 = EnumSchema.resolveLazy(named: missingSymbol)
        XCTAssertNil(result3)
        XCTAssertEqual(DynamicSymbolCache.shared.countForTesting, 1)
        XCTAssertEqual(providerCallCount, 1)

        // Map witness resolution for the same symbol hits cache
        let result4 = MessageSchema.resolveLazyMapWitness(named: missingSymbol, keyKind: .int32)
        XCTAssertNil(result4)
        XCTAssertEqual(DynamicSymbolCache.shared.countForTesting, 1)
        XCTAssertEqual(providerCallCount, 1)
        // Message/enum witness and reflection resolution for the same symbol hits cache
        let result5 = MessageSchema.resolveLazyWitness(named: "symbol_that_definitely_does_not_exist")
        XCTAssertNil(result5)
        XCTAssertEqual(DynamicSymbolCache.shared.countForTesting, 2)
        XCTAssertEqual(providerCallCount, 2)

        let result6 = EnumSchema.resolveLazyWitness(named: "symbol_that_definitely_does_not_exist")
        XCTAssertNil(result6)
        XCTAssertEqual(DynamicSymbolCache.shared.countForTesting, 2)
        XCTAssertEqual(providerCallCount, 2)

        #if canImport(Darwin)
        let result7 = _protobuf_resolveReflection(named: "symbol_that_definitely_does_not_exist")
        XCTAssertNil(result7)
        XCTAssertEqual(DynamicSymbolCache.shared.countForTesting, 2)
        XCTAssertEqual(providerCallCount, 2)
        #endif
    }

    func testPositiveCaching() {
        let messageThunk: MessageSchema.DynamicLookupThunk = { out in
            out.assumingMemoryBound(to: (MessageSchema?).self).pointee = Google_Protobuf_Empty.messageSchema
        }
        let enumThunk: EnumSchema.DynamicLookupThunk = { out in
            out.assumingMemoryBound(to: (EnumSchema?).self).pointee = Google_Protobuf_Syntax.enumSchema
        }
        #if canImport(Darwin)
        let reflectionThunk: MessageSchema.DynamicLookupThunk = { out in
            out.assumingMemoryBound(to: (StaticString?).self).pointee = "test_reflection_data"
        }
        #endif
        nonisolated(unsafe) var providerCallCount = 0
        DynamicSymbolCache.shared.resetForTesting { symbolName in
            providerCallCount += 1
            switch symbolName {
            case "test_weak_linkage_message_schema":
                return unsafeBitCast(messageThunk, to: UnsafeMutableRawPointer.self)
            case "test_weak_linkage_enum_schema":
                return unsafeBitCast(enumThunk, to: UnsafeMutableRawPointer.self)
            #if canImport(Darwin)
            case "test_weak_linkage_reflection":
                return unsafeBitCast(reflectionThunk, to: UnsafeMutableRawPointer.self)
            #endif
            default:
                return nil
            }
        }
        XCTAssertEqual(DynamicSymbolCache.shared.countForTesting, 0)

        let schema1 = MessageSchema.resolveLazy(named: "test_weak_linkage_message_schema")
        XCTAssertNotNil(schema1)
        XCTAssertEqual(DynamicSymbolCache.shared.countForTesting, 1)
        XCTAssertEqual(providerCallCount, 1)

        // Subsequent resolution hits cache without calling provider
        let schema2 = MessageSchema.resolveLazy(named: "test_weak_linkage_message_schema")
        XCTAssertNotNil(schema2)
        XCTAssertEqual(DynamicSymbolCache.shared.countForTesting, 1)
        XCTAssertEqual(providerCallCount, 1)

        let enumSchema1 = EnumSchema.resolveLazy(named: "test_weak_linkage_enum_schema")
        XCTAssertNotNil(enumSchema1)
        XCTAssertEqual(DynamicSymbolCache.shared.countForTesting, 2)
        XCTAssertEqual(providerCallCount, 2)

        let enumSchema2 = EnumSchema.resolveLazy(named: "test_weak_linkage_enum_schema")
        XCTAssertNotNil(enumSchema2)
        XCTAssertEqual(DynamicSymbolCache.shared.countForTesting, 2)
        XCTAssertEqual(providerCallCount, 2)

        #if canImport(Darwin)
        let reflection1 = _protobuf_resolveReflection(named: "test_weak_linkage_reflection")
        XCTAssertNotNil(reflection1)
        XCTAssertEqual(DynamicSymbolCache.shared.countForTesting, 3)
        XCTAssertEqual(providerCallCount, 3)

        let reflection2 = _protobuf_resolveReflection(named: "test_weak_linkage_reflection")
        XCTAssertNotNil(reflection2)
        XCTAssertEqual(DynamicSymbolCache.shared.countForTesting, 3)
        XCTAssertEqual(providerCallCount, 3)
        #endif
    }

    func testResolveGenerated() {
        let messageGetter: MessageSchema.DynamicLookupThunk = { out in
            out.assumingMemoryBound(to: (MessageSchema?).self).pointee = Google_Protobuf_Empty.messageSchema
        }
        let messageWitness: MessageSchema.DynamicLookupThunk = { _ in }
        let mapWitness: MessageSchema.DynamicMapWitnessThunk = { _, _ in }
        let resolvedMessageSchema = MessageSchema.resolveGenerated(
            getter: messageGetter,
            witnessThunk: messageWitness,
            mapWitnessThunk: mapWitness
        )
        XCTAssertTrue(resolvedMessageSchema === Google_Protobuf_Empty.messageSchema)

        let enumGetter: EnumSchema.DynamicLookupThunk = { out in
            out.assumingMemoryBound(to: (EnumSchema?).self).pointee = Google_Protobuf_Syntax.enumSchema
        }
        let enumWitness: EnumSchema.DynamicLookupThunk = { _ in }
        let enumMapWitness: EnumSchema.DynamicMapWitnessThunk = { _, _ in }
        let resolvedEnumSchema = EnumSchema.resolveGenerated(
            getter: enumGetter,
            witnessThunk: enumWitness,
            mapWitnessThunk: enumMapWitness
        )
        XCTAssertTrue(resolvedEnumSchema === Google_Protobuf_Syntax.enumSchema)
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
