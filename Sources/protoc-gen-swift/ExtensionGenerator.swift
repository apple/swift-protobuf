// Sources/ExtensionGenerator.swift - Handle Proto2 extension
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
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
    let path: [Int32]
    let declaringMessageName: String?
    let extendedMessage: Google_Protobuf_DescriptorProto
    let context: Context
    let comments: String
    let apiType: String
    let swiftFieldName: String
    let swiftExtendedMessageName: String
    let swiftRelativeExtensionName: String
    let swiftFullExtensionName: String
    var isProto3: Bool {return false} // Extensions are always proto2

    var extensionFieldType: String {
        let label: String
        switch descriptor.label! {
        case .optional: label = "Optional"
        case .required: label = "Required"
        case .repeated:
            if descriptor.options?.packed == true {
                label = "Packed"
            } else {
                label = "Repeated"
            }
        }
        let modifier: String
        switch descriptor.type! {
        case .group: modifier = "Group"
        case .message: modifier = "Message"
        default: modifier = ""
        }
        return "Protobuf\(label)\(modifier)Field"
    }

    var defaultValue: String {
        switch descriptor.label! {
        case .repeated: return "[]"
        default:
          return descriptor.getSwiftProto2DefaultValue(context: context) ?? "nil"
        }
    }

    init(descriptor: Google_Protobuf_FieldDescriptorProto, path: [Int32], declaringMessageName: String?, file: FileGenerator, context: Context) {
        self.descriptor = descriptor
        self.path = path
        self.declaringMessageName = declaringMessageName
        self.extendedMessage = context.getMessageForPath(path: descriptor.extendee!)!
        self.swiftExtendedMessageName = context.swiftNameForProtoName(protoName: descriptor.extendee!)
        self.context = context
        self.apiType = descriptor.getSwiftApiType(context: context, isProto3: false)
        self.comments = file.commentsFor(path: path)
        let baseName: String
        if descriptor.type! == .group {
            let g = context.getMessageForPath(path: descriptor.typeName!)!
            baseName = sanitizeFieldName(toLowerCamelCase(g.name!))
        } else {
            baseName = sanitizeFieldName(toLowerCamelCase(descriptor.name!))
        }
        self.swiftRelativeExtensionName = context.swiftNameForProtoName(protoName: descriptor.extendee!, separator: "_") + "_" + baseName

        let fieldBaseName: String
        if descriptor.type! == .group {
            let g = context.getMessageForPath(path: descriptor.typeName!)!
            fieldBaseName = toLowerCamelCase(g.name!)
        } else {
            fieldBaseName = toLowerCamelCase(descriptor.name!)
        }

        if let msg = declaringMessageName {
            self.swiftFullExtensionName = msg + ".Extensions." + self.swiftRelativeExtensionName
            self.swiftFieldName = sanitizeFieldName(periodsToUnderscores(msg + "_" + fieldBaseName))
        } else {
            self.swiftFullExtensionName = self.swiftRelativeExtensionName
            self.swiftFieldName = sanitizeFieldName(periodsToUnderscores(fieldBaseName))
        }
    }

    func generateNested(printer p: inout CodePrinter) {
        p.print("\n")
        if comments != "" {
            p.print(comments)
        }
        let scope = declaringMessageName == nil ? "" : "static "
        let traitsType = descriptor.getTraitsType(context: context)
        p.print("\(scope)let \(swiftRelativeExtensionName) = ProtobufGenericMessageExtension<\(extensionFieldType)<\(traitsType)>, \(swiftExtendedMessageName)>(protoFieldNumber: \(descriptor.number!), protoFieldName: \"\(descriptor.name!)\", jsonFieldName: \"\(descriptor.jsonName!)\", swiftFieldName: \"\(swiftFieldName)\", defaultValue: \(defaultValue))\n")
    }

    func generateTopLevel(printer p: inout CodePrinter) {
        p.print("\n")
        p.print("extension \(swiftExtendedMessageName) {\n")
        p.indent()
        if comments != "" {
            p.print(comments)
        }
        p.print("public var \(swiftFieldName): \(apiType) {\n")
        p.indent()
        p.print("get {return getExtensionValue(ext: \(swiftFullExtensionName))}\n")
        p.print("set {setExtensionValue(ext: \(swiftFullExtensionName), value: newValue)}\n")
        p.outdent()
        p.print("}\n")
        p.outdent()
        p.print("}\n")
    }
}
