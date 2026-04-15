// Sources/protoc-gen-swift/Compression+Compressing.swift - Compression algorithm
//
// Copyright (c) 2014 - 2026 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// The LZSS-inspired algorithm used to compress reflection data.
///
/// Since compression only needs to happen at generation time, this lives in
/// the protoc-gen-swift plugin instead of the runtime library. However, the
/// `Compression` namespace itself is imported from there.
///
// -----------------------------------------------------------------------------

import SwiftProtobuf

extension Compression {
    /// Compresses an array of 8-bit bytes using a custom LZSS and range coding
    /// algorithm, producing a stream of 7-bit encoded bytes.
    ///
    /// - Parameter data: The data to compress.
    /// - Returns: The compressed data as an array of 7-bit encoded bytes.
    package static func compress(_ data: [UInt8]) -> [UInt8] {
        // The most significant bit of the uncompressed size is reserved for
        // future expansion.
        precondition(data.count <= 0x7FFF_FFFF, "Data size exceeds 31-bit limit")

        var writer = Bit7Writer()
        let count = UInt32(data.count)
        withUnsafeBytes(of: count.littleEndian) { bytes in
            for b in bytes {
                writer.append(b)
            }
        }

        var rangeEncoder = RangeEncoder(output: writer)

        var mainModel = FrequencyModel(count: mainModelSize)
        var escapeModel = FrequencyModel(count: 256)  // one entry per possible byte value
        var offsetModel = FrequencyModel(count: windowSize)
        var lengthModel = FrequencyModel(count: 1 &<< lengthBits)

        /// Helper function for encoding a single literal byte.
        func encodeLiteral(_ byte: UInt8, rangeEncoder: inout RangeEncoder) {
            let code: Int
            let escapedByte: UInt8?
            if let c = Symbol(byte) {
                // If the byte has a direct symbol, encode it as such.
                code = Int(c.code)
                escapedByte = nil
            } else {
                // Otherwise, encode the escape symbol followed by the raw byte.
                code = escapeCode
                escapedByte = byte
            }

            let range = mainModel.frequencyRange(for: code)
            rangeEncoder.encode(
                cumulativeFrequency: range.cumulative,
                frequency: range.frequency,
                total: mainModel.total
            )
            mainModel.incrementFrequency(of: code)

            if let escapedByte {
                // If we're outputting an escaped byte, encode the byte using
                // the escape model.
                let escapeRange = escapeModel.frequencyRange(for: Int(escapedByte))
                rangeEncoder.encode(
                    cumulativeFrequency: escapeRange.cumulative,
                    frequency: escapeRange.frequency,
                    total: escapeModel.total
                )
                escapeModel.incrementFrequency(of: Int(escapedByte))
            }
        }

        /// Helper function for encoding a match that was found earlier in the
        /// data stream.
        func encodeMatch(offset: Int, length: Int, rangeEncoder: inout RangeEncoder) {
            let code = matchCode
            let range = mainModel.frequencyRange(for: code)
            rangeEncoder.encode(
                cumulativeFrequency: range.cumulative,
                frequency: range.frequency,
                total: mainModel.total
            )
            mainModel.incrementFrequency(of: code)

            let offsetRange = offsetModel.frequencyRange(for: offset)
            rangeEncoder.encode(
                cumulativeFrequency: offsetRange.cumulative,
                frequency: offsetRange.frequency,
                total: offsetModel.total
            )
            offsetModel.incrementFrequency(of: offset)

            let lengthRange = lengthModel.frequencyRange(for: length - minMatchLength)
            rangeEncoder.encode(
                cumulativeFrequency: lengthRange.cumulative,
                frequency: lengthRange.frequency,
                total: lengthModel.total
            )
            lengthModel.incrementFrequency(of: length - minMatchLength)
        }

        // If the input data is shorter than the minimum match length, no
        // matches are possible. Skip the search and encode everything as
        // literals.
        if data.count < minMatchLength {
            for byte in data {
                encodeLiteral(byte, rangeEncoder: &rangeEncoder)
            }
            return rangeEncoder.finish()
        }

        let hashSize = 4096
        /// Stores the index of the most recent occurrence of a 3-byte sequence
        /// for each hash value.
        var head = [Int](repeating: -1, count: hashSize)

        /// Stores the index of the previous occurrence of a 3-byte sequence
        /// with the same hash, forming a chain of potential matches.
        var prev = [Int](repeating: -1, count: data.count)

        @inline(__always)
        func computeHash(_ i: Int) -> Int {
            let val = (Int(data[i]) &<< 8) ^ (Int(data[i + 1]) &<< 4) ^ Int(data[i + 2])
            return val & (hashSize &- 1)
        }

        /// Inserts the 3-byte sequence starting at `index` into the hash table.
        @inline(__always)
        func insertIntoHashTable(_ index: Int) {
            if index + 2 < data.count {
                let hash = computeHash(index)
                prev[index] = head[hash]
                head[hash] = index
            }
        }

        // Main compression loop. Iterate through the input data, searching for
        // matches in the sliding window and encoding either a match or a
        // literal.
        var i = 0
        while i < data.count {
            var matchLength = 0
            var matchOffset = 0

            if i + minMatchLength <= data.count {
                let hash = computeHash(i)
                /// The index in `data` of the candidate match being examined.
                var candidate = head[hash]

                var bestLength = 0
                var bestOffset = 0
                var steps = 0

                // Search through the chain of candidates for the longest match.
                // We limit the search to the window size and a maximum number
                // of steps to avoid pathological worst-case performance.
                while candidate != -1 && i - candidate <= windowSize && steps < 64 {
                    steps += 1

                    // Determine the length of the match at this candidate
                    // position.
                    var length = 0
                    while length < maxMatchLength && i + length < data.count
                        && data[candidate + length] == data[i + length]
                    {
                        length += 1
                    }

                    // If it's a longer match, track it.
                    if length > bestLength {
                        bestLength = length
                        bestOffset = i - candidate
                    }

                    candidate = prev[candidate]
                }

                // If we found a long enough match, track it so that we can
                // encode it below.
                if bestLength >= minMatchLength {
                    matchLength = bestLength
                    matchOffset = bestOffset
                }
            }

            if matchLength >= minMatchLength {
                // Offsets are 1-based (1 is the previous byte), but we encode
                // them as 0-based to fit the frequency model.
                encodeMatch(offset: matchOffset - 1, length: matchLength, rangeEncoder: &rangeEncoder)
                for j in 0..<matchLength {
                    insertIntoHashTable(i + j)
                }
                i += matchLength
            } else {
                // No match was found, so encode the literal byte.
                encodeLiteral(data[i], rangeEncoder: &rangeEncoder)
                insertIntoHashTable(i)
                i += 1
            }
        }

        return rangeEncoder.finish()
    }

    /// A helper structure that writes full 8-bit bytes into a stream of 7-bit
    /// encoded bytes.
    ///
    /// For example, if we encode a byte like 0x84, then we write `0x04` into
    /// the first byte and then enqueue the high bit into the buffer to be
    /// written into the next byte.
    struct Bit7Writer: ~Copyable {
        /// The accumulated 7-bit bytes.
        private var output: [UInt8] = []

        /// An internal buffer to hold pending bits.
        private var buffer: UInt16 = 0

        /// The number of valid bits currently in `buffer`.
        private var bitCount: Int = 0

        /// Appends an 8-bit byte to the stream, splitting it into 7-bit chunks.
        mutating func append(_ byte: UInt8) {
            buffer |= UInt16(byte) &<< bitCount
            bitCount &+= 8
            while bitCount >= 7 {
                output.append(UInt8(buffer & 0x7F))
                buffer &>>= 7
                bitCount &-= 7
            }
        }

        /// Flushes any remaining bits and returns the final array of 7-bit
        /// bytes.
        ///
        /// The writer can no longer be used after this method is called.
        consuming func finish() -> [UInt8] {
            if bitCount > 0 {
                output.append(UInt8(buffer & 0x7F))
            }
            return output
        }
    }

    /// A range coder used to encode symbols into a compressed stream.
    ///
    /// Range coding allows us to represent symbols using fractional bits and to
    /// do so adaptively so that we achieve good compression ratios for
    /// arbitrary protos instead of trying to build static tables that may only
    /// be optimal for some specific subset.
    struct RangeEncoder: ~Copyable {
        /// The lower bound of the current range.
        private var low: UInt32 = 0

        /// The size of the current range.
        ///
        /// This is not a valid size (since we reserve the MSB for future use).
        private var size: UInt32 = 0xFFFF_FFFF

        /// The bit writer used to emit bytes to the output stream.
        private var output: Bit7Writer

        /// Initializes a new range encoder with the given bit writer.
        init(output: consuming Bit7Writer) {
            self.output = output
        }

        /// Encodes a symbol with the specified frequency range.
        ///
        /// - Parameters:
        ///   - cumulativeFrequency: The cumulative frequency of the symbol.
        ///   - frequency: The individual frequency of the symbol.
        ///   - total: The total frequency of all symbols in the model.
        mutating func encode(cumulativeFrequency: UInt32, frequency: UInt32, total: UInt32) {
            let r = size / total
            low &+= cumulativeFrequency &* r
            size = frequency &* r

            // Renormalization: If the top 8 bits of 'low' and 'low + size' are
            // identical, they are fixed. We emit them and shift.
            while (low & 0xFF000000) == ((low &+ size) & 0xFF000000) {
                output.append(UInt8(low &>> 24))
                low &<<= 8
                size &<<= 8
            }

            // Underflow prevention: If 'size' becomes too small but the top
            // bits didn't match, we force a shift to maintain precision for
            // division.
            if size < 0x10000 {
                output.append(UInt8(low &>> 24))
                low &<<= 8
                size = 0 &- low  // no unary minus for UInt32
            }
        }

        /// Flushes any remaining bytes and returns the final array of 7-bit
        /// bytes.
        ///
        /// The encoder can no longer be used after this method is called.
        consuming func finish() -> [UInt8] {
            for _ in 0..<4 {
                output.append(UInt8(low &>> 24))
                low &<<= 8
            }
            return output.finish()
        }
    }
}
