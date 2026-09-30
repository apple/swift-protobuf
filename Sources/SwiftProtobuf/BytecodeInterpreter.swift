// Sources/SwiftProtobuf/BytecodeInterpreter.swift - Internal bytecode interpreter
//
// Copyright (c) 2014 - 2025 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------

/// Interprets SwiftProtobuf bytecode that is a stream of "instructions" and "operands".
///
/// Bytecode interpreters are generic over an `Instruction` type, which must be something (typically
/// an `enum`) that has `UInt64` raw values. The only restriction on these values is that the
/// bytecode format reserves raw value zero, so all instructions must have raw values of one or
/// greater.
///
/// A `BytecodeWriter` represents the current version of the bytecode stream (program format 0) as
/// a `StaticString`, binary-encoding non-textual information in a way that still guarantees valid
/// UTF-8. Specifically,
///
/// - The writer encodes integers in a varint-like format similar to protobuf, using only the low
///   7 bits. The most-significant bit is always clear, and the second-most-significant bit serves
///   as the continuation bit.
/// - For strings, an integer length (see above) precedes the string content, which is standard
///   UTF-8. There is no null termination.
/// - The stream always begins with an integer that indicates the "program format" for the stream.
///   Currently, the only valid value is zero.
package struct BytecodeInterpreter<Instruction: RawRepresentable>
where Instruction.RawValue == UInt64 {
    /// The bytecode program being executed.
    private let program: StaticString

    /// Creates a new bytecode interpreter that will execute the program you provide.
    package init(program: StaticString) {
        self.program = program
    }

    /// Executes the program by translating its opcodes into instructions of the `Instruction` type,
    /// invoking the `handleInstruction` function you provide on each instruction until the
    /// interpreter has completely read the program.
    ///
    /// - Parameter handleInstruction: The function this method invokes for each instruction it
    ///   reads from the bytecode stream. The function takes two arguments: the `Instruction` it
    ///   read, and an `inout BytecodeReader` that the function should use to read operands and
    ///   advance the stream.
    package func execute(handleInstruction: (Instruction, inout BytecodeReader<Instruction>) -> Void) {
        guard program.hasPointerRepresentation else {
            // The only way this could happen is if the program were a single byte, meaning that it
            // only has a 6-bits-or-fewer format specifier and nothing else. In other words, there
            // are no instructions, and we can simply return as there is nothing to execute. We
            // should still verify that the program format is valid, however.
            BytecodeReader<Instruction>.checkProgramFormat(UInt64(program.unicodeScalar.value))
            return
        }
        program.withUTF8Buffer { programBuffer in
            var reader = BytecodeReader<Instruction>(remainingProgram: programBuffer[...])
            while reader.hasData {
                let instruction = reader.nextInstruction()
                handleInstruction(instruction, &reader)
            }
        }
    }
}
