// Sources/SwiftProtobuf/BytecodeReader.swift - Internal bytecode reader
//
// Copyright (c) 2014 - 2025 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------

/// Reads values encoded in a SwiftProtobuf bytecode stream.
package struct BytecodeReader<Instruction: RawRepresentable> where Instruction.RawValue == UInt64 {
    /// The remaining slice of the program that has not yet been read.
    private var remainingProgram: UnsafeBufferPointer<UInt8>.SubSequence

    /// Indicates whether or not there is still data that hasn't yet been read in the bytecode
    /// stream.
    package var hasData: Bool {
        !remainingProgram.isEmpty
    }

    /// Creates a new bytecode reader that reads the given bytecode stream.
    package init(remainingProgram: UnsafeBufferPointer<UInt8>.SubSequence) {
        self.remainingProgram = remainingProgram

        // We reserve the first integer of the program text as a "format specifier". This
        // future-proofs us if we ever want to change the way programs themselves are encoded
        // (for example, compressing them).
        Self.checkProgramFormat(nextUInt64())
    }

    /// Checks that the given program format is valid (i.e., not greater than the runtime supports),
    /// trapping if it is invalid.
    static func checkProgramFormat(_ programFormat: UInt64) {
        if programFormat > latestBytecodeProgramFormat {
            fatalError("Unexpected bytecode program format \(programFormat)")
        }
    }

    /// Reads and returns the next instruction from the bytecode stream.
    ///
    /// - Precondition: The reader must not be at the end of the bytecode stream, and the next
    ///   opcode must not be zero.
    ///
    /// - Returns: The instruction that was read from the bytecode stream.
    package mutating func nextInstruction() -> Instruction {
        precondition(hasData, "Unexpected end of bytecode stream")

        let opcode = nextUInt64()
        precondition(opcode != 0, "Opcode 0 is reserved; do not use it in your own instructions")
        guard let instruction = Instruction(rawValue: opcode) else {
            fatalError("Unexpected opcode \(opcode) for instruction set \(Instruction.self)")
        }
        return instruction
    }

    /// Reads and returns the next signed 32-bit integer from the bytecode stream.
    ///
    /// This is provided as its own primitive operation because 32-bit values are extremely common
    /// as field numbers (0 to 2^29-1) and enum cases (-2^31 to 2^31-1). In particular for enum
    /// cases, using this function specifically for those cases avoids making mistakes involving
    /// sign- vs. zero-extension between differently-sized integers.
    ///
    /// - Precondition: The reader must not be at the end of the bytecode stream.
    ///
    /// - Returns: The signed 32-bit integer that was read from the bytecode stream.
    package mutating func nextInt32() -> Int32 {
        // `Int32`s are stored by converting them bit-wise to a `UInt32` and then zero-extended to
        // `UInt64`, since this representation is smaller than sign-extending them to 64 bits.
        let uint64Value = nextUInt64()
        assert(uint64Value < UInt64(0x1_0000_0000), "nextInt32() read a value larger than 32 bits")
        return Int32(bitPattern: UInt32(truncatingIfNeeded: uint64Value))
    }

    /// Reads and returns the next unsigned 64-bit integer from the bytecode stream.
    ///
    /// - Precondition: The reader must not be at the end of the bytecode stream.
    ///
    /// - Returns: The unsigned 64-bit integer that was read from the bytecode stream.
    package mutating func nextUInt64() -> UInt64 {
        precondition(hasData, "Unexpected end of bytecode stream")

        // We store our programs as `StaticString`s, but those are still required to be UTF-8
        // encoded. This means we can't use a standard varint encoding for integers (because we
        // cannot arbitrarily use the most significant bit), but we can use a slightly modified
        // version that always keeps the MSB clear and uses the next-to-MSB as the continuation bit.
        let byte = UInt64(remainingProgram.first!)
        remainingProgram = remainingProgram.dropFirst()
        precondition(byte & 0x80 == 0, "Invalid integer leading byte \(byte)")

        if byte & 0x40 == 0 {
            return byte
        }
        var value: UInt64 = byte & 0x3f
        var shift: UInt64 = 6
        while true {
            let byte = remainingProgram.first!
            remainingProgram = remainingProgram.dropFirst()
            value |= UInt64(byte & 0x3f) &<< shift
            precondition(byte & 0x80 == 0, "Invalid integer leading byte \(byte)")
            if byte & 0x40 == 0 {
                return value
            }
            shift &+= 6
            guard shift < 64 else {
                fatalError("Bytecode value too large to fit into UInt64")
            }
        }
    }

    /// Reads and returns the next null-terminated string from the bytecode stream.
    ///
    /// - Precondition: The reader must not be at the end of the bytecode stream.
    ///
    /// - Returns: An `UnsafeBufferPointer` containing the string that was read from the bytecode
    ///   stream. This pointer is rebased -- its base address is the start of the string that was
    ///   just read, not the start of the entire stream -- but its lifetime is still tied to that of
    ///   the original bytecode stream (which is immortal if it originated from a static string).
    package mutating func nextNullTerminatedString() -> UnsafeBufferPointer<UInt8> {
        precondition(hasData, "Unexpected end of bytecode stream")

        guard let nullIndex = remainingProgram.firstIndex(of: 0) else {
            preconditionFailure("Unexpected end of bytecode stream while looking for end of string")
        }
        let endIndex = remainingProgram.index(after: nullIndex)
        defer { remainingProgram = remainingProgram[endIndex...] }
        return .init(rebasing: remainingProgram[..<nullIndex])
    }

    /// Reads and returns the next array of length-delimited strings from the bytecode stream.
    ///
    /// - Precondition: The reader must not be at the end of the bytecode stream.
    ///
    /// - Returns: An array of `UnsafeBufferPointer`s containing the strings that were read from the
    ///   bytecode stream. See the documentation of `nextString()` for details on the lifetimes of
    ///   these pointers.
    package mutating func nextNullTerminatedStringArray() -> [UnsafeBufferPointer<UInt8>] {
        precondition(hasData, "Unexpected end of bytecode stream")

        let count = Int(nextUInt64())
        return [UnsafeBufferPointer<UInt8>](unsafeUninitializedCapacity: count) {
            (buffer, initializedCount) in
            for index in 0..<count {
                buffer.initializeElement(at: index, to: nextNullTerminatedString())
            }
            initializedCount = count
        }
    }
}

/// Indicates the latest bytecode program format supported by `BytecodeReader`.
///
/// Programs written by a `BytecodeWriter` (see protoc-gen-swift) should *only* support this
/// version; there is no reason to generate an older version than the latest that the runtime
/// supports. Readers, on the other hand, must support the latest and all previous formats (unless
/// making breaking changes).
package let latestBytecodeProgramFormat: UInt64 = 0
