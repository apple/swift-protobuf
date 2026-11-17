// Sources/SwiftProtobuf/FieldBitSet.swift - Zero-allocation seen-field tracking
//
// Copyright (c) 2014 - 2026 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Tracks which fields and extensions have been seen while decoding a single
/// message in TextFormat or JSON, avoiding heap allocations in the common case.
///
// -----------------------------------------------------------------------------

/// Tracks dense schema field indices and extension field numbers seen while decoding a message.
///
/// Regular fields (including `oneof` members) with dense schema indices in `0..<128` are tracked
/// inline in a 128-bit tuple without heap allocation. Overflow storage for messages with more than
/// 128 fields and hash-set storage for extension field numbers are allocated lazily only when
/// needed.
package struct FieldBitSet: Sendable {
    /// 128-bit inline fast path: bits `0..<64` are stored in `.0`, and bits `64..<128` in `.1`.
    private var inlineBits: (UInt64, UInt64) = (0, 0)

    /// Lazily allocated bitset words for dense schema field indices `>= 128`.
    private var overflowBits: [UInt64]? = nil

    /// Lazily allocated set of seen extension field numbers.
    private var seenExtensions: Set<UInt32>? = nil

    package init() {}

    /// Inserts the field's zero-based schema index into the set.
    ///
    /// - Parameter fieldIndex: The zero-based dense index of the field in `MessageSchema`.
    /// - Returns: `true` if `fieldIndex` was not already present; `false` if it was already seen.
    @inline(__always)
    package mutating func insert(fieldIndex: Int) -> Bool {
        let uIndex = UInt(bitPattern: fieldIndex)
        if uIndex < 64 {
            let mask: UInt64 = 1 &<< uIndex
            if (inlineBits.0 & mask) != 0 {
                return false
            }
            inlineBits.0 |= mask
            return true
        }
        if uIndex < 128 {
            let mask: UInt64 = 1 &<< (uIndex &- 64)
            if (inlineBits.1 & mask) != 0 {
                return false
            }
            inlineBits.1 |= mask
            return true
        }
        return insertOverflow(fieldIndex: fieldIndex)
    }

    @inline(never)
    private mutating func insertOverflow(fieldIndex: Int) -> Bool {
        precondition(fieldIndex >= 0, "Invalid negative field index")
        let overflowBitIndex = fieldIndex - 128
        let wordIndex = overflowBitIndex >> 6
        let mask: UInt64 = 1 &<< (overflowBitIndex & 63)

        guard var words = overflowBits else {
            var words = [UInt64](repeating: 0, count: wordIndex + 1)
            words[wordIndex] = mask
            overflowBits = words
            return true
        }

        // Clear `self.overflowBits` before mutating `words` so a uniquely-held buffer stays
        // uniquely referenced without triggering Copy-on-Write.
        overflowBits = nil
        if wordIndex >= words.count {
            words.append(contentsOf: repeatElement(0, count: wordIndex + 1 - words.count))
            words[wordIndex] = mask
            overflowBits = words
            return true
        }

        let inserted = (words[wordIndex] & mask) == 0
        words[wordIndex] |= mask
        overflowBits = words
        return inserted
    }

    /// Inserts an extension field number into the set.
    ///
    /// - Parameter extensionFieldNumber: The protobuf field number of the extension.
    /// - Returns: `true` if `extensionFieldNumber` was not already present; `false` if it was
    ///   already seen.
    package mutating func insert(extensionFieldNumber: UInt32) -> Bool {
        guard var extensions = seenExtensions else {
            seenExtensions = [extensionFieldNumber]
            return true
        }
        // Clear `self.seenExtensions` before mutating `extensions` so a uniquely-held set stays
        // uniquely referenced without triggering Copy-on-Write.
        seenExtensions = nil
        let inserted = extensions.insert(extensionFieldNumber).inserted
        seenExtensions = extensions
        return inserted
    }

    package var hasOverflowStorageForTesting: Bool {
        overflowBits != nil
    }

    package var hasExtensionStorageForTesting: Bool {
        seenExtensions != nil
    }
}
