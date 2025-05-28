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

    mutating func writeSame(number: Int32, name: String) {
        bytecode.writeOpcode(of: .same)
        bytecode.writeInt32(number)
        bytecode.writeNullTerminatedString(name)
    }

    mutating func writeStandard(number: Int32, name: String) {
        bytecode.writeOpcode(of: .standard)
        bytecode.writeInt32(number)
        bytecode.writeNullTerminatedString(name)
    }

    mutating func writeUnique(number: Int32, protoName: String, jsonName: String?) {
        bytecode.writeOpcode(of: .unique)
        bytecode.writeInt32(number)
        bytecode.writeNullTerminatedString(protoName)
        bytecode.writeNullTerminatedString(jsonName ?? "")
    }

    mutating func writeAliased(_ descriptor: EnumValueDescriptor, aliases: [EnumValueDescriptor]) {
        bytecode.writeOpcode(of: .alias)
        bytecode.writeInt32(descriptor.number)
        bytecode.writeNullTerminatedString(descriptor.name)
        bytecode.writeNullTerminatedStringArray(aliases.map(\.name))
    }

    mutating func writeReservedName(_ name: String) {
        bytecode.writeOpcode(of: .reservedName)
        bytecode.writeNullTerminatedString(name)
    }

    mutating func writeReservedFields(_ range: Range<Int32>) {
        bytecode.writeOpcode(of: .reservedFields)
        bytecode.writeInt32(range.lowerBound)
        bytecode.writeInt32(range.upperBound)
    }
}
