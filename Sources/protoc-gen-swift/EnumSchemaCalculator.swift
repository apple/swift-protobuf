// Sources/protoc-gen-swift/EnumSchemaCalculator.swift - Enum schema calculator
//
// Copyright (c) 2014 - 2026 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Implements the logic that computes the string representation of an enum
/// schema.
///
// -----------------------------------------------------------------------------

import SwiftProtobufPluginLibrary

/// Computes the encoded schema string that will be emitted into generated code to represent an
/// enum.
///
/// TODO: For now, the enum schema only contains the full name of the enum type, to match what we
/// do for messages. In the future, consider including a compact representation of the valid cases
/// inspired by upb.
struct EnumSchemaCalculator {
    /// Manages the generation of the Swift string literals that encode the enum schema in the
    /// generated source.
    /// 
    /// Unlike message schemas, which need different storage offsets on different platforms due to
    /// pointer sizes, enum schemas are consistent across all platforms.
    private var schemaWriter: SchemaWriter

    /// The Swift string literals (without surrounding quotes) that encode the enum schema in
    /// the generated source.
    var schemaLiteral: String { schemaWriter.schemaCode }

    /// Creates a new enum schema calculator for an enum with the given generator.
    init(fullyQualifiedName: String, enumValues: [EnumValueDescriptor]) {
        self.schemaWriter = .init()

        // Version indicator (1 byte)
        schemaWriter.writeBase128Int(0, byteWidth: 1)

        // The number of defined cases (aliases are not included).
        schemaWriter.writeBase128Int(UInt64(enumValues.count), byteWidth: 5)

        // Enum name length (2 bytes), followed by enum name
        schemaWriter.writeBase128Int(UInt64(fullyQualifiedName.utf8.count), byteWidth: 2)
        schemaWriter.writeString(fullyQualifiedName)
    }
}
