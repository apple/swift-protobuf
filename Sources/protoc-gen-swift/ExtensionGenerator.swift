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

struct ExtensionGenerator {
    let descriptor: Google_Protobuf_FieldDescriptorProto
    let generatorOptions: GeneratorOptions
    let path: [Int32]
    let protoPath: String
    let swiftDeclaringMessageName: String?
    let context: Context
    let comments: String
    let apiType: String
    let swiftFieldName: String
    let swiftHasPropertyName: String
    let swiftClearMethodName: String
    let swiftExtendedMessageName: String
    let swiftRelativeExtensionName: String
    let swiftFullExtensionName: String
    var isProto3: Bool {return false} // Extensions are always proto2

    var extensionFieldType: String {
        let label: String
        switch descriptor.label {
        case .optional: label = "Optional"
        case .required: label = "Required"
        case .repeated:
            if descriptor.options.packed == true {
                label = "Packed"
            } else {
                label = "Repeated"
            }
        }
        let modifier: String
        switch descriptor.type {
        case .group: modifier = "Group"
        case .message: modifier = "Message"
        case .enum: modifier = "Enum"
        default: modifier = ""
        }
        return "\(label)\(modifier)ExtensionField"
    }

    var defaultValue: String {
        switch descriptor.label {
        case .repeated: return "[]"
        default:
          return descriptor.getSwiftDefaultValue(context: context, isProto3: false)
        }
    }

    init(descriptor: Google_Protobuf_FieldDescriptorProto, path: [Int32], parentProtoPath: String?, swiftDeclaringMessageName: String?, file: FileGenerator, context: Context) {
        self.descriptor = descriptor
        self.generatorOptions = file.generatorOptions
        self.path = path
        self.swiftDeclaringMessageName = swiftDeclaringMessageName
        self.swiftExtendedMessageName = context.getMessageNameForPath(path: descriptor.extendee)!
        self.context = context
        self.apiType = descriptor.getSwiftApiType(context: context, isProto3: false)
        self.comments = file.commentsFor(path: path)
        let fieldName = descriptor.isGroup ? descriptor.bareTypeName : descriptor.name
        if let parentProtoPath = parentProtoPath {
            self.protoPath = parentProtoPath + "." + fieldName
        } else {
            self.protoPath = fieldName
        }

        let baseName: String
        if descriptor.type == .group {
            let g = context.getMessageForPath(path: descriptor.typeName)!
            baseName = g.name
        } else {
            baseName = descriptor.name
        }
        let fieldBaseName = toLowerCamelCase(baseName)

        if let msg = swiftDeclaringMessageName {
            self.swiftRelativeExtensionName = baseName
            self.swiftFullExtensionName = msg + ".Extensions." + baseName
            self.swiftFieldName = periodsToUnderscores(msg + "_" + fieldBaseName)
        } else {
            let swiftPrefix = file.swiftPrefix
            self.swiftRelativeExtensionName = swiftPrefix + "Extensions_" + baseName
            self.swiftFullExtensionName = self.swiftRelativeExtensionName
            self.swiftFieldName = periodsToUnderscores(swiftPrefix + fieldBaseName)
        }
        self.swiftHasPropertyName = "has" + uppercaseFirst(swiftFieldName)
        self.swiftClearMethodName = "clear" + uppercaseFirst(swiftFieldName)
    }

    func generateNested(printer p: inout CodePrinter) {
        p.print("\n")
        if comments != "" {
            p.print(comments)
        }
        let scope = swiftDeclaringMessageName == nil ? "" : "static "
        let traitsType = descriptor.getTraitsType(context: context)

        // JSON can't support extensions, so don't bother with a JSON name here
        var protoPath = self.protoPath
        if protoPath.hasPrefix(".") {
            protoPath.remove(at: protoPath.startIndex)
        }
        let nameCase = ".same(proto: \"\(protoPath)\")"

        p.print("\(scope)let \(swiftRelativeExtensionName) = SwiftProtobuf.MessageExtension<\(extensionFieldType)<\(traitsType)>, \(swiftExtendedMessageName)>(\n")
        p.indent()
        p.print("fieldNumber: \(descriptor.number),\n")
        p.print("fieldNames: \(nameCase),\n")
        p.print("defaultValue: \(defaultValue)\n")
        p.outdent()
        p.print(")\n")
    }

    func generateTopLevel(printer p: inout CodePrinter) {
        p.print("\n")
        p.print("extension \(swiftExtendedMessageName) {\n")
        p.indent()
        if comments != "" {
            p.print(comments)
        }
        p.print("\(generatorOptions.visibilitySourceSnippet)var \(swiftFieldName): \(apiType) {\n")
        p.indent()
        if descriptor.label == .repeated {
            p.print("get {return getExtensionValue(ext: \(swiftFullExtensionName))}\n")
        } else {
            p.print("get {return getExtensionValue(ext: \(swiftFullExtensionName)) ?? \(defaultValue)}\n")
        }
        p.print("set {setExtensionValue(ext: \(swiftFullExtensionName), value: newValue)}\n")
        p.outdent()
        p.print("}\n")
        p.print("\(generatorOptions.visibilitySourceSnippet)var \(swiftHasPropertyName): Bool {\n")
        p.indent()
        p.print("return hasExtensionValue(ext: \(swiftFullExtensionName))\n")
        p.outdent()
        p.print("}\n")
        p.print("\(generatorOptions.visibilitySourceSnippet)mutating func \(swiftClearMethodName)() {\n")
        p.indent()
        p.print("clearExtensionValue(ext: \(swiftFullExtensionName))\n")
        p.outdent()
        p.print("}\n")
        p.outdent()
        p.print("}\n")
    }
}
