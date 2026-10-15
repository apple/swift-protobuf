// Sources/protoc-gen-swift/EnumSchemaCalculator.swift - Enum schema calculator
//
// Copyright (c) 2014 - 2026 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Implements the logic that computes the string representation of an enum
/// schema.
///
// -----------------------------------------------------------------------------

import SwiftProtobufPluginLibrary

/// Computes the encoded schema string that will be emitted into generated code to represent an
/// enum.
package struct EnumSchemaCalculator {
    /// Manages the generation of the Swift string literals that encode the enum schema in the
    /// generated source.
    ///
    /// Unlike message schemas, which need different storage offsets on different platforms due to
    /// pointer sizes, enum schemas are consistent across all platforms.
    private var schemaWriter: SchemaWriter

    /// The Swift string literals (without surrounding quotes) that encode the enum schema in
    /// the generated source.
    package var schemaLiteral: String { schemaWriter.schemaCode }

    /// The raw UTF-8 bytes of the encoded enum schema, exposed for testing.
    package var schemaBytes: [UInt8] { schemaWriter.bytes }

    /// Creates a new enum schema calculator for an enum with the given descriptor values.
    init(fullyQualifiedName: String, isClosed: Bool, enumValues: [EnumValueDescriptor]) {
        self.init(
            fullyQualifiedName: fullyQualifiedName,
            isClosed: isClosed,
            rawValues: enumValues.map(\.number)
        )
    }

    /// Creates a new enum schema calculator for an enum with the given raw values.
    package init(fullyQualifiedName: String, isClosed: Bool, rawValues: [Int32]) {
        self.schemaWriter = .init()

        // Byte 0: Version indicator (1 byte).
        schemaWriter.writeBase128Int(0, byteWidth: 1)

        if isClosed {
            // Sort all unique defined values as unsigned 32-bit integers (`UInt32(bitPattern:)`).
            // Non-negative `Int32` values (`0 ... Int32.max`) sort first in ascending order
            // (`0x0000_0000 ... 0x7fff_ffff`), followed by negative `Int32` values
            // (`Int32.min ... -1` -> `0x8000_0000 ... 0xffff_ffff`).
            let sortedUnsignedValues = Set(rawValues.map { UInt32(bitPattern: $0) }).sorted()
            let totalCount = sortedUnsignedValues.count
            let nonNegativeCount =
                sortedUnsignedValues.firstIndex { $0 >= 0x8000_0000 } ?? totalCount

            // Choose the prefix of `0...nonNegativeCount` non-negative values to place in the
            // 7-bit-per-byte bitmask vs. the 5-byte-per-entry sorted sparse list to minimize the
            // total encoded byte size (breaking ties in favor of placing more values in the O(1)
            // bitmask).
            var bestBitmaskValueCount = 0
            var bestMaskByteCount = 0
            var bestTotalBytes = 5 * totalCount

            for i in 0..<nonNegativeCount {
                let bitmaskValueCount = i + 1
                let maxBitmaskValue = sortedUnsignedValues[i]
                let maskBytes = Int(maxBitmaskValue / 7) + 1
                // Cap `maskByteCount` at the 20-bit limit of the header field.
                guard maskBytes < (1 << 20) else { break }
                let sparseBytes = 5 * (totalCount - bitmaskValueCount)
                let totalBytes = maskBytes + sparseBytes
                if totalBytes <= bestTotalBytes {
                    bestTotalBytes = totalBytes
                    bestBitmaskValueCount = bitmaskValueCount
                    bestMaskByteCount = maskBytes
                }
            }

            let sparseValues = sortedUnsignedValues[bestBitmaskValueCount...]
            let sparseCount = sparseValues.count

            // Bytes 1-3: Bitmask byte count (bits 0-19) and `isClosed = 1` flag (bit 20).
            let maskByteCountAndClosedFlag =
                UInt64(bestMaskByteCount) | (UInt64(0x40) << 14)
            schemaWriter.writeBase128Int(maskByteCountAndClosedFlag, byteWidth: 3)

            // Bytes 4-6: Sparse value count (3 bytes).
            schemaWriter.writeBase128Int(UInt64(sparseCount), byteWidth: 3)

            // Bitmask bytes (7 bits per byte).
            if bestMaskByteCount > 0 {
                var maskBuffer = [UInt8](repeating: 0, count: bestMaskByteCount)
                for i in 0..<bestBitmaskValueCount {
                    let unsignedValue = sortedUnsignedValues[i]
                    let byteIndex = Int(unsignedValue / 7)
                    let bitIndex = unsignedValue % 7
                    maskBuffer[byteIndex] |= (1 &<< bitIndex)
                }
                for byte in maskBuffer {
                    schemaWriter.writeBase128Int(UInt64(byte), byteWidth: 1)
                }
            }

            // Sparse values (5-byte base-128 `UInt32` each, in ascending unsigned order).
            for unsignedValue in sparseValues {
                schemaWriter.writeBase128Int(UInt64(unsignedValue), byteWidth: 5)
            }
        } else {
            // Bytes 1-3: Value count (bits 0-19) with `isClosed = 0` (bit 20).
            let uniqueValueCount = Set(rawValues).count
            schemaWriter.writeBase128Int(UInt64(uniqueValueCount), byteWidth: 3)
        }

        // Enum name length (2 bytes), followed by enum name.
        schemaWriter.writeBase128Int(UInt64(fullyQualifiedName.utf8.count), byteWidth: 2)
        schemaWriter.writeString(fullyQualifiedName)
    }
}
