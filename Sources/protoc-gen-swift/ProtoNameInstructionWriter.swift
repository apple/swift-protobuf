// Sources/protoc-gen-swift/ProtoNameInstructionWriter.swift - Name instruction writing helpers
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

/// A convenience wrapper that adds operations to write `ProtoNameInstruction`s and their operands
/// into bytecode streams.
struct ProtoNameInstructionWriter {
    private(set) var bytecode = BytecodeWriter<ProtoNameInstruction>()

    /// The previous field or case number written to the stream, which is used to compute deltas.
    private var previousNumber: Int32? = nil

    /// Indicates whether the parameterless `NameMap` initializer can be use because no instructions
    /// were written to the bytecode stream.
    var shouldUseEmptyNameMapInitializer: Bool {
        !bytecode.hasData
    }

    mutating func writeSame(number: Int32, name: String) {
        let delta = delta(updatingToNextNumber: number)
        if delta == 1 {
            bytecode.writeOpcode(of: .sameNext)
        } else {
            bytecode.writeOpcode(of: .sameDelta)
            bytecode.writeInt32(delta)
        }
        bytecode.writeNullTerminatedString(name)
    }

    mutating func writeStandard(number: Int32, name: String) {
        let delta = delta(updatingToNextNumber: number)
        if delta == 1 {
            bytecode.writeOpcode(of: .standardNext)
        } else {
            bytecode.writeOpcode(of: .standardDelta)
            bytecode.writeInt32(delta)
        }
        bytecode.writeNullTerminatedString(name)
    }

    mutating func writeUnique(number: Int32, protoName: String, jsonName: String?) {
        let delta = delta(updatingToNextNumber: number)
        if delta == 1 {
            bytecode.writeOpcode(of: .uniqueNext)
        } else {
            bytecode.writeOpcode(of: .uniqueDelta)
            bytecode.writeInt32(delta)
        }
        bytecode.writeNullTerminatedString(protoName)
        bytecode.writeNullTerminatedString(jsonName ?? "")
    }

    mutating func writeGroup(number: Int32, name: String) {
        let delta = delta(updatingToNextNumber: number)
        if delta == 1 {
            bytecode.writeOpcode(of: .groupNext)
        } else {
            bytecode.writeOpcode(of: .groupDelta)
            bytecode.writeInt32(delta)
        }
        bytecode.writeNullTerminatedString(name)
    }

    mutating func writeAliased(_ descriptor: EnumValueDescriptor, aliases: [EnumValueDescriptor]) {
        let delta = delta(updatingToNextNumber: descriptor.number)
        if delta == 1 {
            bytecode.writeOpcode(of: .aliasNext)
        } else {
            bytecode.writeOpcode(of: .aliasDelta)
            bytecode.writeInt32(delta)
        }
        bytecode.writeNullTerminatedString(descriptor.name)
        bytecode.writeNullTerminatedStringArray(aliases.map(\.name))
    }

    mutating func writeReservedName(_ name: String) {
        bytecode.writeOpcode(of: .reservedName)
        bytecode.writeNullTerminatedString(name)
    }

    mutating func writeReservedNumbers(_ range: Range<Int32>) {
        bytecode.writeOpcode(of: .reservedNumbers)
        bytecode.writeInt32(range.lowerBound)
        bytecode.writeInt32(range.upperBound - range.lowerBound)
    }

    /// Returns the delta between the given field/case number and the previous number, updating the
    /// previous number afterwards to the new value.
    private mutating func delta(updatingToNextNumber number: Int32) -> Int32 {
        guard let previousNumber else {
            previousNumber = number
            return number
        }
        precondition(number >= previousNumber, "field/case numbers must be written in ascending order")
        let delta = number - previousNumber
        self.previousNumber = number
        return delta
    }
}
