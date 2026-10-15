// Tests/protoc-gen-swiftTests/Test_EnumSchema.swift - Tests for EnumSchema encoding and lookup
//
// Copyright (c) 2014 - 2026 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------

import SwiftProtobuf
import Testing
import protoc_gen_swift

private func withEnumSchema(
    fullyQualifiedName: String = "pkg.MyEnum",
    isClosed: Bool = true,
    rawValues: [Int32],
    body: (EnumSchema) -> Void
) {
    let calculator = EnumSchemaCalculator(
        fullyQualifiedName: fullyQualifiedName,
        isClosed: isClosed,
        rawValues: rawValues
    )
    // Verify that every byte in the encoded schema is valid 7-bit ASCII.
    for byte in calculator.schemaBytes {
        #expect(byte < 0x80)
    }
    calculator.schemaBytes.withUnsafeBytes { buffer in
        let schema = EnumSchema(schemaBuffer: buffer)
        body(schema)
    }
}

@Test func denseSmallEnum() {
    withEnumSchema(fullyQualifiedName: "pkg.DenseEnum", isClosed: true, rawValues: [0, 1, 2]) { schema in
        #expect(schema.isClosed == true)
        #expect(schema.maskByteCount == 1)
        #expect(schema.sparseCount == 0)
        #expect(schema.valueCount == 3)
        #expect(schema.enumName.utf8CodeUnitsEqual("pkg.DenseEnum"))

        for v: Int32 in [0, 1, 2] {
            #expect(schema.isValidValue(v) == true)
        }
        for v: Int32 in [-100, -1, 3, 4, 6, 7, 100, .min, .max] {
            #expect(schema.isValidValue(v) == false)
        }
    }
}

@Test func smallGapStaysInBitmask() {
    // Values 0, 1, 10, 11 fit in 2 bitmask bytes (covering 0..<14), which is smaller than
    // 1 bitmask byte + 2 sparse entries (1 + 10 = 11 bytes).
    withEnumSchema(isClosed: true, rawValues: [0, 1, 10, 11]) { schema in
        #expect(schema.maskByteCount == 2)
        #expect(schema.sparseCount == 0)
        #expect(schema.valueCount == 4)

        let defined: Set<Int32> = [0, 1, 10, 11]
        for v: Int32 in -5...20 {
            #expect(schema.isValidValue(v) == defined.contains(v))
        }
    }
}

@Test func largeGapSplitsBitmaskAndSparse() {
    // Values 0, 1 go in 1 bitmask byte; 1000 goes in the sparse array.
    withEnumSchema(isClosed: true, rawValues: [0, 1, 1000]) { schema in
        #expect(schema.maskByteCount == 1)
        #expect(schema.sparseCount == 1)
        #expect(schema.valueCount == 3)

        #expect(schema.isValidValue(0) == true)
        #expect(schema.isValidValue(1) == true)
        #expect(schema.isValidValue(1000) == true)

        for v: Int32 in [-1, 2, 6, 7, 999, 1001] {
            #expect(schema.isValidValue(v) == false)
        }
    }
}

@Test func multiByteSparseValuesAndBoundaries() {
    // Exercise all 5 bytes of the fixed5ByteBase128 encoding:
    // - 0, 1, 2 (in bitmask)
    // - 100 (1-byte base-128: < 2^7)
    // - 900, 9999 (2-byte base-128: < 2^14)
    // - 99997, 99998, 99999 (3-byte base-128: < 2^21)
    // - 50_000_000 (4-byte base-128: < 2^28)
    // - Int32.max (5-byte base-128: 0x7fff_ffff)
    // - Int32.min, -100, -1 (5-byte base-128 with bit 31 set)
    let values: [Int32] = [
        .min, -100, -1, 0, 1, 2, 100, 900, 9999, 99997, 99998, 99999, 50_000_000, .max,
    ]
    let valueSet = Set(values)

    withEnumSchema(isClosed: true, rawValues: values) { schema in
        #expect(schema.maskByteCount == 1)
        #expect(schema.sparseCount == 11)
        #expect(schema.valueCount == values.count)

        for v in values {
            #expect(schema.isValidValue(v) == true, "Expected \(v) to be valid")
        }

        let probes: [Int32] = [
            .min + 1, -101, -99, -2, 3, 6, 7, 99, 101, 899, 901,
            9998, 10000, 99996, 100000, 49_999_999, 50_000_001, .max - 1,
        ]
        for v in probes {
            #expect(!valueSet.contains(v))
            #expect(schema.isValidValue(v) == false, "Expected \(v) not to be valid")
        }
    }
}

@Test func sparseOnlyEnum() {
    withEnumSchema(isClosed: true, rawValues: [-10, -1, 500, 1000]) { schema in
        #expect(schema.maskByteCount == 0)
        #expect(schema.sparseCount == 4)
        #expect(schema.valueCount == 4)

        for v: Int32 in [-10, -1, 500, 1000] {
            #expect(schema.isValidValue(v) == true)
        }
        for v: Int32 in [-11, -9, -2, 0, 1, 499, 501, 999, 1001] {
            #expect(schema.isValidValue(v) == false)
        }
    }
}

@Test func duplicateRawValuesAliases() {
    withEnumSchema(isClosed: true, rawValues: [0, 1, 1, 2, 100, 100]) { schema in
        #expect(schema.maskByteCount == 1)
        #expect(schema.sparseCount == 1)
        #expect(schema.valueCount == 4)

        for v: Int32 in [0, 1, 2, 100] {
            #expect(schema.isValidValue(v) == true)
        }
        #expect(schema.isValidValue(3) == false)
        #expect(schema.isValidValue(99) == false)
    }
}

@Test func unsortedRawValues() {
    let unsorted: [Int32] = [1000, -1, 2, 500, -10, 0, 100, 1]
    let sortedCalculator = EnumSchemaCalculator(
        fullyQualifiedName: "pkg.MyEnum",
        isClosed: true,
        rawValues: unsorted.sorted()
    )
    let unsortedCalculator = EnumSchemaCalculator(
        fullyQualifiedName: "pkg.MyEnum",
        isClosed: true,
        rawValues: unsorted
    )
    #expect(unsortedCalculator.schemaBytes == sortedCalculator.schemaBytes)

    withEnumSchema(isClosed: true, rawValues: unsorted) { schema in
        #expect(schema.maskByteCount == 1)
        #expect(schema.sparseCount == 5)
        #expect(schema.valueCount == 8)

        for v in unsorted {
            #expect(schema.isValidValue(v) == true)
        }
        for v: Int32 in [-11, -9, -2, 3, 99, 101, 499, 501, 999, 1001] {
            #expect(schema.isValidValue(v) == false)
        }
    }
}

@Test func openEnumSemantics() {
    withEnumSchema(fullyQualifiedName: "pkg.OpenEnum", isClosed: false, rawValues: [0, 1, 100, -1]) { schema in
        #expect(schema.isClosed == false)
        #expect(schema.maskByteCount == 0)
        #expect(schema.sparseCount == 0)
        #expect(schema.valueCount == 4)
        #expect(schema.enumName.utf8CodeUnitsEqual("pkg.OpenEnum"))

        // All values are valid for an open enum.
        for v: Int32 in [-100, -2, -1, 0, 1, 2, 3, 50, 100, 101, 9999, .min, .max] {
            #expect(schema.isValidValue(v) == true)
        }
    }
}
