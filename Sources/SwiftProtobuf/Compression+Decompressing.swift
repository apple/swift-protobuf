import Foundation

extension Compression {
    /// Decompresses a stream of 7-bit encoded bytes that were compressed using
    /// the custom LZSS and range coding algorithm.
    ///
    /// - Parameter compressed: A buffer pointer to the compressed data.
    /// - Returns: The decompressed data as an array of full 8-bit bytes.
    package static func decompress(_ compressed: UnsafeRawBufferPointer) -> [UInt8] {
        var reader = Bit7Reader(input: compressed)
        guard let b0 = reader.nextByte(),
            let b1 = reader.nextByte(),
            let b2 = reader.nextByte(),
            let b3 = reader.nextByte()
        else {
            preconditionFailure("Compressed data too short to contain size header")
        }

        let size = Int(UInt32(b0) | (UInt32(b1) << 8) | (UInt32(b2) << 16) | (UInt32(b3) << 24))

        // The most significant bit of the size is reserved for future
        // expansion.
        guard (size & 0x8000_0000) == 0 else {
            preconditionFailure("Reserved bit in size header is set")
        }

        var output: [UInt8] = []
        output.reserveCapacity(size)

        var rangeDecoder = RangeDecoder(input: reader)

        var mainModel = FrequencyModel(count: mainModelSize)
        var escapeModel = FrequencyModel(count: 256)  // one entry per possible byte value
        var offsetModel = FrequencyModel(count: windowSize)
        var lengthModel = FrequencyModel(count: 1 << lengthBits)

        while output.count < size {
            let count = rangeDecoder.decode(total: mainModel.total)
            let code = mainModel.symbol(forCumulativeFrequency: count)
            let range = mainModel.frequencyRange(for: code)
            rangeDecoder.remove(
                cumulativeFrequency: range.cumulative,
                frequency: range.frequency,
                total: mainModel.total
            )
            mainModel.incrementFrequency(of: code)

            if let asciiByte = Symbol(code: UInt8(code)).asciiValue {
                // If the decoded symbol directly represents an ASCII code,
                // output it. There's nothing else to do.
                output.append(asciiByte)
            } else if code == escapeCode {
                // If the decoded symbol is the escape symbol, decode the next
                // byte using the escape model and output the result.
                let escapeCount = rangeDecoder.decode(total: escapeModel.total)
                let escapedByte = escapeModel.symbol(forCumulativeFrequency: escapeCount)
                let escapeRange = escapeModel.frequencyRange(for: escapedByte)
                rangeDecoder.remove(
                    cumulativeFrequency: escapeRange.cumulative,
                    frequency: escapeRange.frequency,
                    total: escapeModel.total
                )
                escapeModel.incrementFrequency(of: escapedByte)
                output.append(UInt8(escapedByte))
            } else if code == matchCode {
                // If the decoded symbol is the match symbol, decode the
                // back-reference offset and length from the appropriate models
                // and output the bytes.
                let offsetCount = rangeDecoder.decode(total: offsetModel.total)
                let offset = offsetModel.symbol(forCumulativeFrequency: offsetCount)
                let offsetRange = offsetModel.frequencyRange(for: offset)
                rangeDecoder.remove(
                    cumulativeFrequency: offsetRange.cumulative,
                    frequency: offsetRange.frequency,
                    total: offsetModel.total
                )
                offsetModel.incrementFrequency(of: offset)

                let lengthCount = rangeDecoder.decode(total: lengthModel.total)
                let lengthSymbol = lengthModel.symbol(forCumulativeFrequency: lengthCount)
                let lengthRange = lengthModel.frequencyRange(for: lengthSymbol)
                rangeDecoder.remove(
                    cumulativeFrequency: lengthRange.cumulative,
                    frequency: lengthRange.frequency,
                    total: lengthModel.total
                )
                lengthModel.incrementFrequency(of: lengthSymbol)

                // Restore the 1-based offset from the 0-based encoded value.
                let matchOffset = offset + 1
                let matchLength = lengthSymbol + minMatchLength

                let startIndex = output.count - matchOffset
                guard startIndex >= 0 else {
                    preconditionFailure("Invalid match offset")
                }

                for i in 0..<matchLength {
                    output.append(output[startIndex + i])
                }
            } else {
                preconditionFailure("Invalid symbol code: \(code)")
            }
        }

        return output
    }

    /// A helper structure that reads 7-bit encoded bytes from a stream and
    /// reconstructs full 8-bit bytes.
    struct Bit7Reader: ~Copyable {
        /// The input data stream.
        var input: UnsafeRawBufferPointer

        /// An internal buffer to hold pending bits.
        var buffer: UInt64 = 0

        /// The number of valid bits currently in `buffer`.
        var bitCount: Int = 0

        /// Initializes a new reader with the given input buffer.
        init(input: UnsafeRawBufferPointer) {
            self.input = input
        }

        /// Reads the next 8-bit byte from the stream.
        ///
        /// - Returns: The next decoded 8-bit byte, or `nil` if the end of the
        ///   stream is reached and not enough bits are available.
        mutating func nextByte() -> UInt8? {
            while bitCount < 8 {
                guard let byte = input.first else {
                    return nil
                }
                input = UnsafeRawBufferPointer(rebasing: input.dropFirst())
                buffer |= UInt64(byte & 0x7F) << bitCount
                bitCount &+= 7
            }
            let result = UInt8(buffer & 0xFF)
            buffer >>= 8
            bitCount &-= 8
            return result
        }
    }

    /// A reverse range coder used to decode symbols from a compressed stream.
    ///
    /// Range coding allows us to represent symbols using fractional bits and to
    /// do so adaptively so that we achieve good compression ratios for
    /// arbitrary protos instead of trying to build static tables that may only
    /// be optimal for some specific subset.
    struct RangeDecoder: ~Copyable {
        /// The lower bound of the current range.
        private var low: UInt32 = 0

        /// The size of the current range.
        private var size: UInt32 = 0xFFFF_FFFF

        /// The current code value being decoded.
        private var code: UInt32 = 0

        /// The bit reader used to fetch bytes from the input stream.
        var input: Bit7Reader

        /// Initializes a new range decoder and preloads the first 4 bytes of
        /// code.
        init(input: consuming Bit7Reader) {
            self.input = input

            for _ in 0..<4 {
                if let byte = self.input.nextByte() {
                    code = (code << 8) | UInt32(byte)
                } else {
                    code = code << 8
                }
            }
        }

        /// Decodes the next symbol's cumulative frequency.
        ///
        /// - Parameter total: The total frequency of all symbols in the model.
        /// - Returns: The cumulative frequency of the decoded symbol.
        mutating func decode(total: UInt32) -> UInt32 {
            code / (size / total)
        }

        /// Removes the effects of the decoded symbol from the range coder
        /// state.
        ///
        /// - Parameters:
        ///   - cumulativeFrequency: The cumulative frequency of the decoded
        ///     symbol.
        ///   - frequency: The individual frequency of the decoded symbol.
        ///   - total: The total frequency of all symbols in the model.
        mutating func remove(cumulativeFrequency: UInt32, frequency: UInt32, total: UInt32) {
            let r = size / total
            low += cumulativeFrequency * r
            code -= cumulativeFrequency * r
            size = frequency * r

            // Renormalization: If the top 8 bits of 'low' and 'low + size' are
            // identical, they are fixed. We shift them out and read a new byte.
            while (low ^ (low + size)) < 0x1000000 {
                low <<= 8
                size <<= 8
                if let byte = input.nextByte() {
                    code = (code << 8) | UInt32(byte)
                } else {
                    code = code << 8
                }
            }

            // Underflow prevention: If 'size' becomes too small but the top
            // bits didn't match, we force a shift to maintain precision for
            // division.
            if size < 0x10000 {
                low <<= 8
                if let byte = input.nextByte() {
                    code = (code << 8) | UInt32(byte)
                } else {
                    code = code << 8
                }
                size = 0 &- low  // no unary minus for UInt32
            }
        }
    }
}
