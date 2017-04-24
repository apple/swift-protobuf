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
    let protoPackageName: String
    let swiftDeclaringMessageName: String?
    let context: Context
    let comments: String
    let fieldName: String
    let fieldNamePath: String
    let apiType: String
    let swiftFieldName: String
    let swiftHasPropertyName: String
    let swiftClearMethodName: String
    let swiftExtendedMessageName: String
    let swiftRelativeExtensionName: String
    let swiftFullExtensionName: String

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
        self.protoPackageName = file.protoPackageName
        self.swiftDeclaringMessageName = swiftDeclaringMessageName
        self.swiftExtendedMessageName = context.getMessageNameForPath(path: descriptor.extendee)!
        self.context = context
        self.apiType = descriptor.getSwiftApiType(context: context, isProto3: false)
        self.comments = file.commentsFor(path: path)
        self.fieldName = descriptor.isGroup ? descriptor.bareTypeName : descriptor.name
        if let parentProtoPath = parentProtoPath, !parentProtoPath.isEmpty {
            var p = parentProtoPath
            assert(p.hasPrefix("."))
            p.remove(at: p.startIndex)
            self.fieldNamePath = p + "." + fieldName
        } else {
            self.fieldNamePath = fieldName
        }

        let baseName: String
        if descriptor.type == .group {
            let g = context.messageDescriptor(forTypeName: descriptor.typeName)
            baseName = g.name
        } else {
            baseName = descriptor.name
        }
        let fieldBaseName = toLowerCamelCase(baseName)

        if let msg = swiftDeclaringMessageName {
            // Since the name is used within the "Extensions" struct, reserved words
            // could be a problem.  When declared, we might need backticks, but when
            // using the qualified name, backticks aren't needed.
            let cleanedBaseName = sanitizeMessageScopedExtensionName(baseName)
            let cleanedBaseNameNoBackticks = sanitizeMessageScopedExtensionName(baseName, skipBackticks: true)
            self.swiftRelativeExtensionName = cleanedBaseName
            self.swiftFullExtensionName = msg + ".Extensions." + cleanedBaseNameNoBackticks
            // The rest of these have enough things put together, we assume they
            // can never run into reserved words.
            //
            // fieldBaseName is the lowerCase name even though we put more on the
            // front, this seems to help make the field name stick out a little
            // compared to the message name scoping it on the front.
            self.swiftFieldName = periodsToUnderscores(msg + "_" + fieldBaseName)
            self.swiftHasPropertyName = "has" + uppercaseFirst(swiftFieldName)
            self.swiftClearMethodName = "clear" + uppercaseFirst(swiftFieldName)
        } else {
            let swiftPrefix = file.swiftPrefix
            self.swiftRelativeExtensionName = swiftPrefix + "Extensions_" + baseName
            self.swiftFullExtensionName = self.swiftRelativeExtensionName
            // If there was no package and no prefix, fieldBaseName could be a reserved
            // word, so sanitize. These's also the slim chance the prefix plus the
            // extension name resulted in a reserved word, so the sanitize is always
            // needed.
            self.swiftFieldName = sanitizeFieldName(swiftPrefix + fieldBaseName)
            if swiftPrefix.isEmpty {
                // No prefix, so got back to UpperCamelCasing the extension name, and then
                // sanitize it like we did for the lower form.
                let upperCleaned = sanitizeFieldName(toUpperCamelCase(baseName), basedOn: fieldBaseName)
                self.swiftHasPropertyName = "has" + upperCleaned
                self.swiftClearMethodName = "clear" + upperCleaned
            } else {
                // Since there was a prefix, just add has/clear and ensure the first letter
                // was capitalized.
                self.swiftHasPropertyName = "has" + uppercaseFirst(swiftFieldName)
                self.swiftClearMethodName = "clear" + uppercaseFirst(swiftFieldName)
            }
        }
    }

    func generateProtobufExtensionDeclarations(printer p: inout CodePrinter) {
        if !comments.isEmpty {
            p.print(comments)
        }
        let scope = swiftDeclaringMessageName == nil ? "" : "static "
        let traitsType = descriptor.getTraitsType(context: context)

        p.print("\(scope)let \(swiftRelativeExtensionName) = SwiftProtobuf.MessageExtension<\(extensionFieldType)<\(traitsType)>, \(swiftExtendedMessageName)>(\n")
        p.indent()
        p.print("_protobuf_fieldNumber: \(descriptor.number),\n")
        p.print("fieldName: \"\(fieldNamePath)\",\n")
        p.print("defaultValue: \(defaultValue)\n")
        p.outdent()
        p.print(")\n")
    }

    func generateMessageSwiftExtensionForProtobufExtensions(printer p: inout CodePrinter) {
        p.print("\n")
        p.print("extension \(swiftExtendedMessageName) {\n")
        p.indent()
        if !comments.isEmpty {
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
