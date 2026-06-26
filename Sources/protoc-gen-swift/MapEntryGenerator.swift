// Sources/protoc-gen-swift/MapEntryGenerator.swift - Map entry logic
//
// Copyright (c) 2014 - 2025 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Generates the metadata needed for messages to encode and decode
/// map entries.
///
// -----------------------------------------------------------------------------

import Foundation
import SwiftProtobuf
import SwiftProtobufPluginLibrary

/// Generates the message layout strings for map entries.
class MapEntryGenerator {
    private let descriptor: Descriptor
    private let generatorOptions: GeneratorOptions
    private let namer: SwiftProtobufNamer
    private let swiftValueType: String
    private let entrySchemaCalculator: MessageSchemaCalculator

    /// The name of the static variable of type `MessageSchema` that will be generated into the
    /// containing message for the map entry.
    let entrySchemaName: String

    private let keyParticipantType: String
    private let valueParticipantType: String

    /// Computes the name of the static variable of type `MessageSchema` that will be generated into the
    /// containing message for the map entry with the given descriptor.
    static func schemaName(for descriptor: Descriptor) -> String {
        "_protobuf_mapEntrySchema_\(descriptor.name)"
    }

    init(
        descriptor: Descriptor,
        generatorOptions: GeneratorOptions,
        namer: SwiftProtobufNamer,
    ) {
        assert(descriptor.mapKeyAndValue != nil, "should only be created for map entries")
        let keyDescriptor = descriptor.mapKeyAndValue!.key
        let valueDescriptor = descriptor.mapKeyAndValue!.value

        self.descriptor = descriptor
        self.generatorOptions = generatorOptions
        self.namer = namer
        self.swiftValueType = valueDescriptor.swiftType(namer: namer)

        let fields = descriptor.fields.map {
            MessageFieldGenerator(
                descriptor: $0,
                generatorOptions: generatorOptions,
                namer: namer
            )
        }
        let fieldsSortedByNumber = fields.sorted { $0.number < $1.number }

        self.entrySchemaCalculator = MessageSchemaCalculator(
            fullyQualifiedName: generatorOptions.experimentalHiddenNames.contains(.types) ? "" : descriptor.fullName,
            fieldsSortedByNumber: fieldsSortedByNumber,
            extensibilityMode: .mapEntry
        )

        entrySchemaName = Self.schemaName(for: descriptor)
        keyParticipantType = participantTypeName(for: keyDescriptor, namer: namer)
        valueParticipantType = participantTypeName(for: valueDescriptor, namer: namer)
    }

    func generateSchema(into printer: inout CodePrinter) {
        printer.print(
            #"private static let \#(entrySchemaName)_string: Swift.StaticString = "\#(entrySchemaCalculator.schemaLiteral)""#
        )
        printer.print(
            "private static let \(entrySchemaName) = SwiftProtobuf.MessageSchema(schema: \(entrySchemaName)_string, forMapEntryWithKeyType: \(keyParticipantType).self, valueType: \(valueParticipantType).self)"
        )
    }
}

/// Returns the name of the participant/proxy type that generalizes memory access to the key or
/// value of a map entry.
private func participantTypeName(for field: FieldDescriptor, namer: SwiftProtobufNamer) -> String {
    switch field.type {
    case .bool:
        return "ProtobufMapBoolField"
    case .bytes:
        return "ProtobufMapDataField"
    case .double:
        return "ProtobufMapDoubleField"
    case .enum:
        return "ProtobufMapEnumField<\(field.swiftType(namer: namer))>"
    case .fixed32, .uint32:
        return "ProtobufMapUInt32Field"
    case .fixed64, .uint64:
        return "ProtobufMapUInt64Field"
    case .float:
        return "ProtobufMapFloatField"
    case .group, .message:
        return "ProtobufMapMessageField<\(field.swiftType(namer: namer))>"
    case .int32, .sfixed32, .sint32:
        return "ProtobufMapInt32Field"
    case .int64, .sfixed64, .sint64:
        return "ProtobufMapInt64Field"
    case .string:
        return "ProtobufMapStringField"
    }
}
