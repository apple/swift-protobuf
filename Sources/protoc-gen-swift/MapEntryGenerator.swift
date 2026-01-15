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
    private let entryLayoutCalculator: MessageLayoutCalculator

    let keyParticipantType: String
    let valueParticipantType: String

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

        self.entryLayoutCalculator = MessageLayoutCalculator(fieldsSortedByNumber: fieldsSortedByNumber)

        keyParticipantType = participantTypeName(for: keyDescriptor, namer: namer)
        valueParticipantType = participantTypeName(for: valueDescriptor, namer: namer)
    }

    func generateLayoutReturnStatement(printer: inout CodePrinter) {
        let valueTypeArgument: String
        let layoutLabel: String
        switch descriptor.mapKeyAndValue!.value.type {
        case .message, .enum:
            valueTypeArgument = ", forMapEntryWithValueType: \(swiftValueType).self"
            layoutLabel = "layout"
        default:
            valueTypeArgument = ""
            layoutLabel = "layoutForMapEntryWithScalarValues"
        }
        if let layoutString = entryLayoutCalculator.layoutLiterals.valueIfAllEqual {
            printer.print(
                #"return SwiftProtobuf._MessageLayout(\#(layoutLabel): "\#(layoutString)"\#(valueTypeArgument))"#
            )
        } else {
            entryLayoutCalculator.layoutLiterals.printConditionalBlocks(to: &printer) { layoutString, _, printer in
                printer.print(#"let layoutString: StaticString = "\#(layoutString)""#)
            }
            printer.print(
                "return SwiftProtobuf._MessageLayout(\(layoutLabel): layoutString\(valueTypeArgument))"
            )
        }
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
