// Tests/SwiftProtobufTests/Test_OpcodeCompatibility.swift
//
// Copyright (c) 2014 - 2025 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Ensures that numeric values of instructions used in runtime bytecode do not
/// change accidentally.
///
// -----------------------------------------------------------------------------

import SwiftProtobuf
import XCTest

/// WARNING: If these tests fail, you have BROKEN COMPATIBILITY with the current
/// version of the runtime!
final class Test_OpcodeCompatibility: XCTestCase {
    func testProtoNameInstruction() {
        assertOpcodes([
            (ProtoNameInstruction.sameNext, 1),
            (ProtoNameInstruction.sameDelta, 2),
            (ProtoNameInstruction.standardNext, 3),
            (ProtoNameInstruction.standardDelta, 4),
            (ProtoNameInstruction.uniqueNext, 5),
            (ProtoNameInstruction.uniqueDelta, 6),
            (ProtoNameInstruction.groupNext, 7),
            (ProtoNameInstruction.groupDelta, 8),
            (ProtoNameInstruction.aliasNext, 9),
            (ProtoNameInstruction.aliasDelta, 10),
            (ProtoNameInstruction.reservedName, 11),
            (ProtoNameInstruction.reservedNumbers, 12),
        ])
    }

    private func assertOpcodes<Instruction: RawRepresentable & CaseIterable>(
        _ pairs: [(Instruction, Int)],
        file: StaticString = #file,
        line: UInt = #line
    ) where Instruction.RawValue == UInt64 {
        for pair in pairs {
            XCTAssertEqual(
                pair.0.rawValue,
                UInt64(pair.1),
                "COMPATIBILITY BREAK: Instruction \(pair.0) expected to have opcode \(pair.1), but got \(pair.0.rawValue)"
            )
        }
        XCTAssertEqual(
            pairs.count,
            Instruction.allCases.count,
            "Not all instructions are covered by this test; please update it"
        )
    }
}
