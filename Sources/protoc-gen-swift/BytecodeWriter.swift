// Sources/SwiftProtobufPluginLibrary/BytecodeCompiler.swift - Internal bytecode compiler
//
// Copyright (c) 2014 - 2025 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------

import Foundation
import SwiftProtobuf

/// Writes bytecode into a string that is suitable for use as a Swift string literal (i.e., for
/// appending to generated code).
///
/// See `SwiftProtobuf.BytecodeInterpreter` for more information on the format used here.
package struct BytecodeWriter<Instruction: RawRepresentable> where Instruction.RawValue == UInt64 {
    /// The Swift string literal that represents the written bytecode, including the delimiting
    /// quotes.
    package var stringLiteral: String { #""\#(code)""# }

    /// The contents of the Swift string literal representing the written bytecode, without the
    /// delimiting quotes.
    private var code: String = "" {
        didSet {
            hasData = true
        }
    }

    /// Indicates whether any data other than the program format identifier has been written to the
    /// bytecode stream.
    package var hasData: Bool = false

    /// Creates a new bytecode writer, writing the program format as the first value in the stream.
    package init() {
        writeUInt64(latestBytecodeProgramFormat)

        // Clear this back out, because we only want to track writes that come after the program
        // format.
        self.hasData = false
    }

    /// Writes the integer opcode corresponding to the given instruction to the bytecode stream.
    package mutating func writeOpcode(of instruction: Instruction) {
        writeUInt64(instruction.rawValue)
    }

    /// Writes a signed 32-bit integer to the bytecode stream.
    ///
    /// This is provided as its own primitive operation because 32-bit values are extremely common
    /// as field numbers (0 to 2^29-1) and enum cases (-2^31 to 2^31-1). In particular for enum
    /// cases, using this function specifically for those cases avoids making mistakes involving
    /// sign- vs. zero-extension between differently-sized integers.
    package mutating func writeInt32(_ value: Int32) {
        // `Int32`s are stored by converting them bit-wise to a `UInt32` and then zero-extended to
        // `UInt64`, since this representation is smaller than sign-extending them to 64 bits.
        writeUInt64(UInt64(UInt32(bitPattern: value)))
    }

    /// Writes an unsigned 64-bit integer to the bytecode stream.
    package mutating func writeUInt64(_ value: UInt64) {
        func append(_ value: UInt64) {
            // Print the normal scalar if it's ASCII-printable so that we only use longer `\u{...}`
            // sequences for those that are not.
            if value == 0 {
                code.append("\\0")
            } else if isprint(Int32(truncatingIfNeeded: value)) != 0 {
                self.append(escapingIfNecessary: UnicodeScalar(UInt32(truncatingIfNeeded: value))!)
            } else {
                code.append(String(format: "\\u{%x}", value))
            }
        }
        var v = value
        while v > 0x3f {
            append(v & 0x3f | 0x40)
            v &>>= 6
        }
        append(v)
    }

    /// Writes the given string literal into the bytecode stream with null termination.
    ///
    /// - Precondition: `string` must not have any embedded zero code points.
    package mutating func writeNullTerminatedString(_ string: String) {
        for scalar in string.unicodeScalars {
            append(escapingIfNecessary: scalar)
        }
        writeUInt64(0)
    }

    /// Writes the given collection of null-terminated strings to the bytecode stream.
    ///
    /// The format of a string collection is to write the number of strings first as an integer,
    /// then write that many null-terminated strings without delimiters.
    package mutating func writeNullTerminatedStringArray(_ strings: some Collection<String>) {
        writeUInt64(UInt64(strings.count))
        for string in strings {
            writeNullTerminatedString(string)
        }
    }

    /// Appends the given Unicode scalar to the bytecode literal, escaping it if necessary for use
    /// in Swift code.
    private mutating func append(escapingIfNecessary scalar: Unicode.Scalar) {
        switch scalar {
        case "\\", "\"":
            code.unicodeScalars.append("\\")
            code.unicodeScalars.append(scalar)
        default:
            code.unicodeScalars.append(scalar)
        }
    }
}
