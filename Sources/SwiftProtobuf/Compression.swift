// Sources/SwiftProtobuf/Compression.swift - Compression operations
//
// Copyright (c) 2014 - 2026 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// The namespace for the LZSS-inspired algorithm used to compress reflection
/// data, and shared code used by both compression and decompression.
///
// -----------------------------------------------------------------------------

/// A namespace for a custom compression algorithm designed for short strings,
/// such as protobuf field and enum case names, and index tables (field number
/// to offset and vice versa).
///
/// The algorithm combines several techniques to achieve high compression
/// ratios on short, repetitive strings while adhering to a strict **7-bit
/// output constraint** (the most significant bit of every output byte is
/// always 0) so that the compressed data can be embedded in `StaticString`
/// literals in the generated source code.
///
/// ## Key Implementation Choices
///
/// - **LZSS-based**: The algorithm searches for repeated substrings within
///   a small sliding window. Matches are encoded as (offset, length) pairs.
/// - **Custom 6-Bit Alphabet**: Common characters in protobuf names
///   (lowercase, uppercase, digits 0-8, underscores) and the zero byte are
///   remapped to a continuous range of 6-bit values. An escape symbol
///   exists to represent any other character. This reduces the baseline cost
///   of these characters before any entropy coding is applied. (Note that the
///   digit 9 is not covered by this alphabet and must be escaped. This was
///   necessary to keep the alphabet size within 6 bits, and should be
///   acceptable since digits do not appear as frequently in field and enum
///   case names).
/// - **Range Coding**: Instead of traditional Huffman coding which assigns
///   an integral number of bits to each symbol, a range coder is used. This
///   allows symbols to take a fractional number of bits based on their
///   frequency, leading to better compression.
/// - **Adaptive Frequency Models**: The frequencies of symbols are updated
///   as they are encoded/decoded, allowing the coder to adapt to the local
///   characteristics of the text being compressed.
/// - **7-Bit Bit Packing**: All output is written using a custom bit writer
///   that packs data into 7-bit chunks, ensuring that the high bit of every
///   byte in the final output stream is always 0.
package enum Compression {
    /// The size of the main frequency model.
    package static let mainModelSize = 65

    /// The code used for escaped literals in the main model.
    package static let escapeCode = 63

    /// The code used for LZSS matches in the main model.
    package static let matchCode = 64

    /// The number of bits used to encode the match offset.
    package static let windowSizeBits = 7

    /// The number of bits used to encode the match length.
    package static let lengthBits = 4

    /// The size of the sliding window for LZSS.
    package static var windowSize: Int { 1 &<< windowSizeBits }

    /// The minimum length of a match to be encoded.
    package static let minMatchLength = 3

    /// The maximum length of a match to be encoded.
    package static var maxMatchLength: Int { (1 &<< lengthBits) &+ minMatchLength &- 1 }

    /// Encapsulates a custom encoding used for text in our compression
    /// algorithm that optimizes for regular protobuf field and enum case names
    /// and integer mapping tables.
    ///
    /// The mapping is defined as follows:
    ///
    /// | Code        | ASCII                          |
    /// | ----------- | ------------------------------ |
    /// | 0x00        | \0                             |
    /// | 0x01...0x1A | a...z                          |
    /// | 0x1B...0x34 | A...Z                          |
    /// | 0x35        | _                              |
    /// | 0x36...0x3E | 0...8                          |
    /// | 0x3F        | escape for any other character |
    ///
    /// This allows us to reduce the baseline cost of the most common characters
    /// down to 6 bits even before we start range coding.
    package struct Symbol {
        /// The underlying (i.e., remapped) numeric value of the symbol.
        package let code: UInt8

        /// Creates a new `Symbol` from an ASCII value.
        ///
        /// - Returns: `nil` if the ASCII value does not map to a
        ///   `Symbol`.
        @inline(__always)
        package init?(_ char: UInt8) {
            switch char {
            case 0:
                self.code = 0
            case UInt8(ascii: "a")...UInt8(ascii: "z"):
                self.code = char &- UInt8(ascii: "a") &+ 1
            case UInt8(ascii: "A")...UInt8(ascii: "Z"):
                self.code = char &- UInt8(ascii: "A") &+ 27
            case UInt8(ascii: "_"):
                self.code = 53
            case UInt8(ascii: "0")...UInt8(ascii: "8"):
                self.code = char &- UInt8(ascii: "0") &+ 54
            default:
                return nil
            }
        }

        /// Creates a new `Symbol` from its numeric value.
        @inline(__always)
        package init(code: UInt8) {
            precondition(code <= matchCode, "Symbol code out of range")
            self.code = code
        }

        /// The ASCII value of the represented symbol, or `nil` if it does not
        /// directly represent an ASCII character.
        @inline(__always)
        package var asciiValue: UInt8? {
            switch code {
            case 0:
                return 0
            case 1...26:
                return code &- 1 &+ UInt8(ascii: "a")
            case 27...52:
                return code &- 27 &+ UInt8(ascii: "A")
            case 53:
                return UInt8(ascii: "_")
            case 54...62:
                return code &- 54 &+ UInt8(ascii: "0")
            default:
                return nil
            }
        }
    }

    /// A model that tracks the frequencies of symbols to enable range coding.
    ///
    /// The model dynamically updates frequencies as symbols are processed, so
    /// is adaptive based on the data being processed.
    package struct FrequencyModel {
        /// The 1-indexed Fenwick tree storage.
        ///
        /// `tree[i]` stores the sum of frequencies in a specific range.
        private var tree: [UInt32]

        /// We also keep the individual frequencies to easily return them
        /// and to help with rescaling.
        private var frequencies: [UInt32]

        /// The sum of all frequencies in the model.
        package private(set) var total: UInt32

        /// Creates a new frequency model with the specified number of symbols.
        package init(count: Int) {
            tree = [UInt32](repeating: 0, count: count + 1)
            frequencies = [UInt32](repeating: 1, count: count)
            total = UInt32(count)

            // Initialize the tree with frequencies of 1
            for i in 1...count {
                var idx = i
                while idx <= count {
                    tree[idx] &+= 1
                    idx &+= idx & -idx  // Add lowest set bit
                }
            }
        }

        /// Returns the cumulative frequency of all symbols before `symbol`.
        private func cumulativeFrequency(before symbol: Int) -> UInt32 {
            var sum: UInt32 = 0
            var idx = symbol
            while idx > 0 {
                sum &+= tree[idx]
                idx &-= idx & -idx  // Remove lowest set bit
            }
            return sum
        }

        /// Returns the cumulative frequency and individual frequency of the
        /// given symbol.
        ///
        /// - Parameter symbol: The symbol whose frequency information is to be
        ///   returned.
        /// - Returns: A tuple containing two values: the cumulative frequency
        ///   for every symbol preceding but not including the given symbol, and
        ///   the individual frequency of the given symbol.
        @inline(__always)
        package func frequencyRange(for symbol: Int) -> (cumulative: UInt32, frequency: UInt32) {
            let cumulative = cumulativeFrequency(before: symbol)
            let frequency = frequencies[symbol]
            return (cumulative, frequency)
        }

        /// Returns the symbol corresponding to the given cumulative frequency
        /// count.
        ///
        /// - Parameter target: The cumulative frequency count to find the
        ///   symbol for.
        /// - Returns: The symbol corresponding to the given cumulative
        ///   frequency count.
        @inline(__always)
        package func symbol(forCumulativeFrequency target: UInt32) -> Int {
            var idx = 0
            var mask = 1 &<< (31 &- UInt32(frequencies.count).leadingZeroBitCount)
            var currentSum: UInt32 = 0

            while mask > 0 {
                let nextIdx = idx &+ mask
                if nextIdx < tree.count && currentSum &+ tree[nextIdx] <= target {
                    idx = nextIdx
                    currentSum &+= tree[idx]
                }
                mask &>>= 1
            }
            return idx
        }

        /// Increments the frequency of the given symbol and updates the total.
        ///
        /// If the total exceeds a threshold (0x10000), all frequencies are
        /// scaled down by half to prevent overflow and maintain adaptivity.
        package mutating func incrementFrequency(of symbol: Int) {
            frequencies[symbol] &+= 1
            total &+= 1

            // Update the Fenwick tree
            var idx = symbol &+ 1
            while idx < tree.count {
                tree[idx] &+= 1
                idx &+= idx & -idx
            }

            if total > 0x10000 {
                rescale()
            }
        }

        /// Rescales the frequencies and rebuilds the Fenwick tree.
        private mutating func rescale() {
            var newTotal: UInt32 = 0
            for i in 0..<frequencies.count {
                frequencies[i] = max(1, frequencies[i] / 2)
                newTotal &+= frequencies[i]
            }
            total = newTotal

            // Rebuild the tree from scratch
            for i in 0..<tree.count {
                tree[i] = 0
            }
            for i in 1...frequencies.count {
                let freq = frequencies[i &- 1]
                var idx = i
                while idx < tree.count {
                    tree[idx] &+= freq
                    idx &+= idx & -idx  // Remove lowest set bit
                }
            }
        }
    }
}
