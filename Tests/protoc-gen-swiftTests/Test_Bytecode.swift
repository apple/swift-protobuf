// Tests/SwiftProtobufPluginLibraryTests/Test_Bytecode.swift - Test Bytecode
//
// Copyright (c) 2014 - 2025 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------

import SwiftProtobuf
import SwiftProtobufPluginLibrary
import XCTest
import protoc_gen_swift

/// All tests for the bytecode are in this test target even though the interpreter and reader are
/// defined in the SwiftProtobuf module so that we can test everything end-to-end in one place.
final class Test_Bytecode: XCTestCase {
    private enum TestInstruction: UInt64 {
        case first = 1
        case second = 2
    }

    /// In the writer and reader tests, each line of the multi-line string corresponds to the value
    /// of a single `writer.write*` call (where the first line is the always-written open-quote and
    /// program format integer and the last is the close-quote.
    func testWriter_opcodes() {
        var writer = BytecodeWriter<TestInstruction>()
        writer.writeOpcode(of: .first)
        writer.writeOpcode(of: .second)
        XCTAssertEqual(
            writer.stringLiteral,
            """
            "\\0\
            \\u{1}\
            \\u{2}\
            "
            """
        )
    }

    func testWriter_integers() {
        var writer = BytecodeWriter<TestInstruction>()
        writer.writeUInt64(0)
        writer.writeUInt64(63)
        writer.writeUInt64(64)
        writer.writeUInt64(123_456_789)
        writer.writeInt32(0)
        writer.writeInt32(-1)
        XCTAssertEqual(
            writer.stringLiteral,
            """
            "\\0\
            \\0\
            ?\
            @\\u{1}\
            Ut|V\\u{7}\
            \\0\
            \\u{7f}\\u{7f}\\u{7f}\\u{7f}\\u{7f}\\u{3}\
            "
            """
        )
    }

    func testWriter_strings() {
        var writer = BytecodeWriter<TestInstruction>()
        writer.writeNullTerminatedString("hello")
        writer.writeNullTerminatedString("ütf-èíght")
        XCTAssertEqual(
            writer.stringLiteral,
            """
            "\\0\
            hello\\0\
            ütf-èíght\\0\
            "
            """
        )
    }

    func testWriter_stringArray() {
        var writer = BytecodeWriter<TestInstruction>()
        writer.writeNullTerminatedStringArray(["hello", "ütf-èíght", "world"])
        XCTAssertEqual(
            writer.stringLiteral,
            """
            "\\0\
            \\u{3}\
            hello\\0\
            ütf-èíght\\0\
            world\\0\
            "
            """
        )
    }

    func testWriter_hasInstructions() {
        var writer = BytecodeWriter<TestInstruction>()
        XCTAssertFalse(writer.hasData)
        writer.writeUInt64(10)
        XCTAssertTrue(writer.hasData)
    }

    func testReader_opcodes() {
        let program: StaticString = """
            \0\
            \u{1}\
            \u{2}
            """
        program.withUTF8Buffer { buffer in
            var reader = BytecodeReader<TestInstruction>(remainingProgram: buffer[...])
            XCTAssertTrue(reader.hasData)
            XCTAssertEqual(reader.nextInstruction(), .first)
            XCTAssertTrue(reader.hasData)
            XCTAssertEqual(reader.nextInstruction(), .second)
            XCTAssertFalse(reader.hasData)
        }
    }

    func testReader_integers() {
        let program: StaticString = """
            \0\
            \0\
            ?\
            @\u{1}\
            Ut|V\u{7}\
            \0\
            \u{7f}\u{7f}\u{7f}\u{7f}\u{7f}\u{3}
            """
        program.withUTF8Buffer { buffer in
            var reader = BytecodeReader<TestInstruction>(remainingProgram: buffer[...])
            XCTAssertTrue(reader.hasData)
            XCTAssertEqual(reader.nextUInt64(), 0)
            XCTAssertTrue(reader.hasData)
            XCTAssertEqual(reader.nextUInt64(), 63)
            XCTAssertTrue(reader.hasData)
            XCTAssertEqual(reader.nextUInt64(), 64)
            XCTAssertTrue(reader.hasData)
            XCTAssertEqual(reader.nextUInt64(), 123_456_789)
            XCTAssertTrue(reader.hasData)
            XCTAssertEqual(reader.nextInt32(), 0)
            XCTAssertTrue(reader.hasData)
            XCTAssertEqual(reader.nextInt32(), -1)
            XCTAssertFalse(reader.hasData)
        }
    }

    func testReader_strings() {
        let program: StaticString = """
            \0\
            hello\0\
            ütf-èíght\0
            """
        program.withUTF8Buffer { buffer in
            var reader = BytecodeReader<TestInstruction>(remainingProgram: buffer[...])
            XCTAssertTrue(reader.hasData)
            XCTAssertEqual(
                String(decoding: reader.nextNullTerminatedString(), as: UTF8.self),
                "hello"
            )
            XCTAssertTrue(reader.hasData)
            XCTAssertEqual(
                String(decoding: reader.nextNullTerminatedString(), as: UTF8.self),
                "ütf-èíght"
            )
            XCTAssertFalse(reader.hasData)
        }
    }

    func testReader_stringArray() {
        let program: StaticString = """
            \0\
            \u{3}\
            hello\0\
            ütf-èíght\0\
            world\0
            """
        program.withUTF8Buffer { buffer in
            var reader = BytecodeReader<TestInstruction>(remainingProgram: buffer[...])
            XCTAssertTrue(reader.hasData)
            XCTAssertEqual(
                reader.nextNullTerminatedStringArray().map { String(decoding: $0, as: UTF8.self) },
                ["hello", "ütf-èíght", "world"]
            )
            XCTAssertFalse(reader.hasData)
        }
    }

    func testExecution() {
        enum CalculatorInstruction: UInt64 {
            // Push the integer operand onto the stack.
            case push = 1
            // Pops the top two integers off the stack and pushes their sum.
            case add = 2
            // Pop an integer off the stack and concatenate it to the output.
            case print = 3
        }
        var stack = [UInt64]()
        var output = ""

        // The program below contains the following instructions:
        // push(integer 1), push(integer 37), add, print
        let interpreter = BytecodeInterpreter<CalculatorInstruction>(
            program: """
                \0\
                \u{1}\u{5}\
                \u{1}!\
                \u{2}\
                \u{3}
                """
        )
        interpreter.execute { instruction, reader in
            switch instruction {
            case .push:
                stack.append(reader.nextUInt64())
            case .add:
                let first = stack.removeLast()
                let second = stack.removeLast()
                stack.append(first + second)
            case .print:
                let value = stack.removeLast()
                output.append(String(value))
            }
        }
        XCTAssertEqual(output, "38")
    }
}
