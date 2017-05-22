// Sources/protoc-gen-swift/ExtensionGenerator.swift - Handle Proto2 extension
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Each instance of ExtensionGenerator represents a single Proto2 extension
/// and contains the logic necessary to emit the various required sources.
/// Note that this wraps the same FieldDescriptorProto used by MessageFieldGenerator,
/// even though the Swift source emitted is very, very different.
///
// -----------------------------------------------------------------------------
import Foundation
import PluginLibrary
import SwiftProtobuf

class ExtensionGenerator {
    private let fieldDescriptor: FieldDescriptor
    private let generatorOptions: GeneratorOptions
    private let namer: SwiftProtobufNamer

    private let comments: String
    private let containingTypeSwiftFullName: String
    private let swiftFullExtensionName: String

    private var extensionFieldType: String {
        let label: String
        switch fieldDescriptor.label {
        case .optional: label = "Optional"
        case .required: label = "Required"
        case .repeated: label = fieldDescriptor.isPacked ? "Packed" : "Repeated"
        }

        let modifier: String
        switch fieldDescriptor.type {
        case .group: modifier = "Group"
        case .message: modifier = "Message"
        case .enum: modifier = "Enum"
        default: modifier = ""
        }

        return "SwiftProtobuf.\(label)\(modifier)ExtensionField"
    }

    init(descriptor: FieldDescriptor, generatorOptions: GeneratorOptions, namer: SwiftProtobufNamer) {
        self.fieldDescriptor = descriptor
        self.generatorOptions = generatorOptions
        self.namer = namer

        swiftFullExtensionName = namer.fullName(extensionField: descriptor)

        comments = descriptor.protoSourceComments()
        containingTypeSwiftFullName = namer.fullName(message: fieldDescriptor.containingType)
    }

    func register(_ registry: inout [String]) {
        registry.append(swiftFullExtensionName)
    }

    func generateProtobufExtensionDeclarations(printer p: inout CodePrinter) {
        let scope = fieldDescriptor.extensionScope == nil ? "" : "static "
        let traitsType = fieldDescriptor.traitsType(namer: namer)
        let swiftRelativeExtensionName = namer.relativeName(extensionField: fieldDescriptor)
        let defaultValue = fieldDescriptor.swiftDefaultValue(namer: namer)

        var fieldNamePath = fieldDescriptor.fullName
        assert(fieldNamePath.hasPrefix("."))
        fieldNamePath.remove(at: fieldNamePath.startIndex)  // Remove the leading '.'

        p.print(
          comments,
          "\(scope)let \(swiftRelativeExtensionName) = SwiftProtobuf.MessageExtension<\(extensionFieldType)<\(traitsType)>, \(containingTypeSwiftFullName)>(\n")
        p.indent()
        p.print(
          "_protobuf_fieldNumber: \(fieldDescriptor.number),\n",
          "fieldName: \"\(fieldNamePath)\",\n",
          "defaultValue: \(defaultValue)\n")
        p.outdent()
        p.print(")\n")
    }

    func generateMessageSwiftExtensionForProtobufExtensions(printer p: inout CodePrinter) {
        let visibility = generatorOptions.visibilitySourceSnippet
        let apiType = fieldDescriptor.swiftType(namer: namer)
        let extensionNames = namer.messagePropertyNames(extensionField: fieldDescriptor)

        p.print("\n")
        p.print("extension \(containingTypeSwiftFullName) {\n")
        p.indent()
        p.print(
          comments,
          "\(visibility)var \(extensionNames.value): \(apiType) {\n")
        p.indent()
        p.print(
          "get {return getExtensionValue(ext: \(swiftFullExtensionName))}\n",
          "set {setExtensionValue(ext: \(swiftFullExtensionName), value: newValue)}\n")
        p.outdent()
        p.print("}\n")

        p.print(
            "/// Returns true if extension `\(swiftFullExtensionName)`\n/// has been explicitly set.\n",
            "\(visibility)var \(extensionNames.has): Bool {\n")
        p.indent()
        p.print("return hasExtensionValue(ext: \(swiftFullExtensionName))\n")
        p.outdent()
        p.print("}\n")

        p.print(
            "/// Clears the value of extension `\(swiftFullExtensionName)`.\n/// Subsequent reads from it will return its default value.\n",
            "\(visibility)mutating func \(extensionNames.clear)() {\n")
        p.indent()
        p.print("clearExtensionValue(ext: \(swiftFullExtensionName))\n")
        p.outdent()
        p.print("}\n")
        p.outdent()
        p.print("}\n")
    }
}
