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

class MapEntryGenerator {
    private let descriptor: Descriptor
    private let generatorOptions: GeneratorOptions
    private let namer: SwiftProtobufNamer
    private let entryLayoutCalculator: MessageLayoutCalculator

    init(
        descriptor: Descriptor,
        generatorOptions: GeneratorOptions,
        namer: SwiftProtobufNamer,
    ) {
        self.descriptor = descriptor
        self.generatorOptions = generatorOptions
        self.namer = namer

        let fields = descriptor.fields.map {
            MessageFieldGenerator(
                descriptor: $0,
                generatorOptions: generatorOptions,
                namer: namer
            )
        }
        let fieldsSortedByNumber = fields.sorted { $0.number < $1.number }

        self.entryLayoutCalculator = MessageLayoutCalculator(fieldsSortedByNumber: fieldsSortedByNumber)
    }

    func generateLayoutReturnStatement(printer: inout CodePrinter) {
        // TODO: Move the all-equal behavior into printConditionalBlocks.
        if let layoutString = entryLayoutCalculator.layoutLiterals.valueIfAllEqual {
            printer.print(#"return "\#(layoutString)""#)
        } else {
            entryLayoutCalculator.layoutLiterals.printConditionalBlocks(to: &printer) { layoutString, _, printer in
                printer.print(#"return "\#(layoutString)""#)
            }
        }
    }
}
