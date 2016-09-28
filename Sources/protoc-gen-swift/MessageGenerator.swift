// Sources/MessageGenerator.swift - Per-message logic
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
/// This provides the overall support for building Swift structs to represent
/// a proto message.  In particular, this handles the copy-on-write deferred
/// for messages that require it.
///
// -----------------------------------------------------------------------------
import Foundation
import PluginLibrary
import SwiftProtobuf

extension Google_Protobuf_DescriptorProto {
    func getMessageForPath(path: String, parentPath: String) -> Google_Protobuf_DescriptorProto? {
        for m in nestedType {
            let messagePath = parentPath + "." + m.name!
            if messagePath == path {
                return m
            }
            if let n = m.getMessageForPath(path: path, parentPath: messagePath) {
                return n
            }
        }
        return nil
    }

    func getMessageNameForPath(path: String, parentPath: String, swiftPrefix: String) -> String? {
        for m in nestedType {
            let messagePath = parentPath + "." + m.name!
            let messageSwiftPath = swiftPrefix + "." + sanitizeMessageTypeName(m.name!)
            if messagePath == path {
                return messageSwiftPath
            }
            if let n = m.getMessageNameForPath(path: path, parentPath: messagePath, swiftPrefix: messageSwiftPath) {
                return n
            }
        }
        return nil
    }

    func getEnumNameForPath(path: String, parentPath: String, swiftPrefix: String) -> String? {
        for e in enumType {
            let enumPath = parentPath + "." + e.name!
            if enumPath == path {
                return swiftPrefix + "." + sanitizeEnumTypeName(e.name!)
            }
        }

        for m in nestedType {
            let messagePath = parentPath + "." + m.name!
            let messageSwiftPath = swiftPrefix + "." + sanitizeMessageTypeName(m.name!)
            if let n = m.getEnumNameForPath(path: path, parentPath: messagePath, swiftPrefix: messageSwiftPath) {
                return n
            }
        }
        return nil
    }

    func getSwiftNameForEnumCase(path: String, caseName: String, parentPath: String, swiftPrefix: String) -> String? {
        for e in enumType {
            let enumPath = parentPath + "." + e.name!
            if enumPath == path {
                let enumSwiftName = swiftPrefix + "." + sanitizeEnumTypeName(e.name!)
                return enumSwiftName + "." + e.getSwiftNameForEnumCase(caseName: caseName)
            }
        }

        for m in nestedType {
            let messagePath = parentPath + "." + m.name!
            let messageSwiftPath = swiftPrefix + "." + sanitizeMessageTypeName(m.name!)
            if let n = m.getSwiftNameForEnumCase(path: path, caseName: caseName, parentPath: messagePath, swiftPrefix: messageSwiftPath) {
                return n
            }
        }
        return nil
    }
}

func hasMessageField(descriptor: Google_Protobuf_DescriptorProto, context: Context) -> Bool {
    let hasMessageField = descriptor.field.contains {
        $0.type == .message
        && $0.label != .repeated
        && (context.getMessageForPath(path: $0.typeName!)?.options?.mapEntry != .some(true))
    }
    return hasMessageField
}

class StorageClassGenerator {
    private let fields: [MessageFieldGenerator]
    private let descriptor: Google_Protobuf_DescriptorProto
    private let messageSwiftName: String
    private let isProto3: Bool
    private let isExtensible: Bool

    init(descriptor: Google_Protobuf_DescriptorProto, fields: [MessageFieldGenerator], file: FileGenerator, messageSwiftName: String, isExtensible: Bool) {
        self.descriptor = descriptor
        self.fields = fields
        self.messageSwiftName = messageSwiftName
        self.isProto3 = file.isProto3
        self.isExtensible = isExtensible
    }

    func generateNested(printer p: inout CodePrinter) {
        p.print("\n")
        if isExtensible {
            p.print("private class _StorageClass: ProtobufExtensibleMessageStorage {\n")
        } else {
            p.print("private class _StorageClass {\n")
        }
        p.indent()

        p.print("typealias ProtobufExtendedMessage = \(messageSwiftName)\n")
        if isExtensible {
            p.print("var extensionFieldValues = ProtobufExtensionFieldValueSet()\n")
        }
        if !isProto3 {
            p.print("var unknown = ProtobufUnknownStorage()\n")
        }

        // ivars
        var oneofHandled = Set<Int32>()
        for f in fields {
            if let oneofIndex = f.descriptor.oneofIndex {
                if !oneofHandled.contains(oneofIndex) {
                    let oneof = f.oneof!
                    p.print("var \(oneof.swiftStorageFieldName) = \(messageSwiftName).\(oneof.swiftRelativeType)()\n")
                    oneofHandled.insert(oneofIndex)
                }
            } else {
                p.print("var \(f.swiftStorageName): \(f.swiftStorageType) = \(f.swiftStorageDefaultValue)\n")
            }
        }

        p.print("\n")
        p.print("init() {}\n")

        // decodeField
        p.print("\n")
        p.print("func decodeField(setter: inout ProtobufFieldDecoder, protoFieldNumber: Int) throws -> Bool {\n")
        p.indent()
        p.print("let handled: Bool\n")
        p.print("switch protoFieldNumber {\n")
        oneofHandled.removeAll(keepingCapacity: true)
        for f in fields {
            if let oneofIndex = f.descriptor.oneofIndex {
                if !oneofHandled.contains(oneofIndex) {
                    p.print("case \(f.number)")
                    for other in fields {
                        if other.descriptor.oneofIndex == oneofIndex && other.number != f.number {
                            p.print(", \(other.number)")
                        }
                    }
                    p.print(":\n")
                    p.indent()
                    let oneof = f.oneof!
                    p.print("handled = try \(oneof.swiftStorageFieldName).decodeField(setter: &setter, protoFieldNumber: protoFieldNumber)\n")
                    oneofHandled.insert(oneofIndex)
                    p.outdent()
                }
            } else {
                f.generateDecodeFieldCase(printer: &p, prefix: "_")
            }
        }
        p.print("default:\n")
        p.indent()
        if isExtensible {
            p.print("if ")
            var separator = ""
            for range in descriptor.extensionRange {
                p.print(separator)
                p.print("(\(range.start!) <= protoFieldNumber && protoFieldNumber < \(range.end!))")
                separator = " || "
            }
            p.print(" {\n")
            p.print("  handled = try setter.decodeExtensionField(values: &extensionFieldValues, messageType: \(messageSwiftName).self, protoFieldNumber: protoFieldNumber)\n")
            p.print("} else {\n")
            p.print("  handled = false\n")
            p.print("}\n")
        } else {
            p.print("handled = false\n")
        }
        p.outdent()
        p.print("}\n")
        if !isProto3 {
            p.print("if handled {\n")
            p.print("    return true\n")
            p.print("} else {\n")
            p.print("    return try unknown.decodeField(setter: &setter)\n")
            p.print("}\n")
        } else {
            p.print("return handled\n")
        }
        p.outdent()
        p.print("}\n")

        // traverse
        p.print("\n")
        p.print("func traverse(visitor: inout ProtobufVisitor) throws {\n")
        p.indent()
        var currentOneof: Google_Protobuf_OneofDescriptorProto?
        var oneofStart = 0
        var oneofEnd = 0
        var ranges = descriptor.extensionRange.makeIterator()
        var nextRange = ranges.next()
        for f in (fields.sorted {$0.number < $1.number}) {
            while nextRange != nil && Int(nextRange!.start!) < f.number {
                p.print("try extensionFieldValues.traverse(visitor: &visitor, start: \(nextRange!.start!), end: \(nextRange!.end!))\n")
                nextRange = ranges.next()
            }
            if let c = currentOneof, let n = f.oneof, n.name! == c.name! {
                oneofEnd = f.number + 1
            } else {
                if let oneof = currentOneof {
                    p.print("try \(oneof.swiftStorageFieldName).traverse(visitor: &visitor, start: \(oneofStart), end: \(oneofEnd))\n")
                    currentOneof = nil
                }
                if let newOneof = f.oneof {
                    oneofStart = f.number
                    oneofEnd = f.number + 1
                    currentOneof = newOneof
                } else {
                    f.generateTraverse(printer: &p, prefix: "_")
                }
            }
        }
        if let oneof = currentOneof {
            p.print("try \(oneof.swiftStorageFieldName).traverse(visitor: &visitor, start: \(oneofStart), end: \(oneofEnd))\n")
        }
        while nextRange != nil {
            p.print("try extensionFieldValues.traverse(visitor: &visitor, start: \(nextRange!.start!), end: \(nextRange!.end!))\n")
            nextRange = ranges.next()
        }
        if !isProto3 {
            p.print("unknown.traverse(visitor: &visitor)\n")
        }
        p.outdent()
        p.print("}\n")

        // isEmpty helper
        p.print("\n")
        p.print("var isEmpty: Bool {\n")
        p.indent()
        oneofHandled.removeAll(keepingCapacity: true)
        for f in fields {
            if let o = f.oneof {
                if !oneofHandled.contains(f.descriptor.oneofIndex!) {
                    p.print("if !\(o.swiftStorageFieldName).isEmpty {return false}\n")
                    oneofHandled.insert(f.descriptor.oneofIndex!)
                }
            } else {
                let test = f.isNotEmptyTest()
                p.print("if \(test) {return false}\n")
            }
        }
        if !isProto3 {
            p.print("if !unknown.isEmpty {return false}\n")
        }
        if isExtensible {
            p.print("if !extensionFieldValues.isEmpty {return false}\n")
        }
        p.print("return true\n")
        p.outdent()
        p.print("}\n")

        // isEqual helper
        p.print("\n")
        p.print("func isEqualTo(other: _StorageClass) -> Bool {\n")
        p.indent()
        oneofHandled.removeAll(keepingCapacity: true)
        for f in fields {
            if let o = f.oneof {
                if !oneofHandled.contains(f.descriptor.oneofIndex!) {
                    p.print("if \(o.swiftStorageFieldName) != other.\(o.swiftStorageFieldName) {return false}\n")
                    oneofHandled.insert(f.descriptor.oneofIndex!)
                }
            } else {
                let notEqualClause = f.generateNotEqual(name: f.swiftStorageName)
                p.print("if \(notEqualClause) {return false}\n")
            }
        }
        if !isProto3 {
            p.print("if unknown != other.unknown {return false}\n")
        }
        if isExtensible {
            p.print("if extensionFieldValues != other.extensionFieldValues {return false}\n")
        }
        p.print("return true\n")
        p.outdent()
        p.print("}\n")

        // copy helper
        p.print("\n")
        p.print("func copy() -> _StorageClass {\n")
        p.indent()
        p.print("let clone = _StorageClass()\n")
        if !isProto3 {
            p.print("clone.unknown = unknown\n")
        }
        if isExtensible {
            p.print("clone.extensionFieldValues = extensionFieldValues\n")
        }
        oneofHandled.removeAll(keepingCapacity: true)
        for f in fields {
            if let o = f.oneof {
                if !oneofHandled.contains(f.descriptor.oneofIndex!) {
                    p.print("clone.\(o.swiftStorageFieldName) = \(o.swiftStorageFieldName)\n")
                    oneofHandled.insert(f.descriptor.oneofIndex!)
                }
            } else {
                p.print("clone.\(f.swiftStorageName) = \(f.swiftStorageName)\n")
            }
        }
        p.print("return clone\n")
        p.outdent()
        p.print("}\n")

        p.outdent()
        p.print("}\n")
    }
}

class MessageGenerator {
    private let descriptor: Google_Protobuf_DescriptorProto
    private let protoFullName: String
    private let swiftFullName: String
    private let swiftRelativeName: String
    private let swiftMessageConformance: String
    private let protoMessageName: String
    private let protoPackageName: String
    private let fields: [MessageFieldGenerator]
    private let oneofs: [OneofGenerator]
    private let extensions: [ExtensionGenerator]
    private let storage: StorageClassGenerator?
    private let enums: [EnumGenerator]
    private let messages: [MessageGenerator]
    private let isProto3: Bool
    private let isExtensible: Bool
    private let isGroup: Bool

    private let path: [Int32]
    private let comments: String

    init(descriptor: Google_Protobuf_DescriptorProto, path: [Int32], parentSwiftName: String?, parentProtoPath: String?, file: FileGenerator, context: Context) {
        self.protoMessageName = descriptor.name!
        self.protoFullName = (parentProtoPath == nil ? "" : (parentProtoPath! + ".")) + self.protoMessageName
        self.descriptor = descriptor
        self.isProto3 = file.isProto3
        self.isGroup = context.protoNameIsGroup.contains(protoFullName)
        self.isExtensible = descriptor.extensionRange.count > 0
        self.protoPackageName = file.protoPackageName
        if let parentSwiftName = parentSwiftName {
            swiftRelativeName = sanitizeMessageTypeName(descriptor.name!)
            swiftFullName = parentSwiftName + "." + swiftRelativeName
        } else {
            swiftRelativeName = sanitizeMessageTypeName(file.swiftPrefix + descriptor.name!)
            swiftFullName = swiftRelativeName
        }
        var conformance = isGroup ? "ProtobufGeneratedGroup" : "ProtobufGeneratedMessage"
        if isExtensible {
            conformance += ", ProtobufExtensibleMessage"
        }
        self.swiftMessageConformance = conformance

        var i: Int32 = 0
        var fields = [MessageFieldGenerator]()
        for f in descriptor.field {
            var fieldPath = path
            fieldPath.append(2)
            fieldPath.append(i)
            i += 1
            fields.append(MessageFieldGenerator(descriptor: f, path: fieldPath, messageDescriptor: descriptor, file: file, context: context))
        }
        self.fields = fields

        i = 0
        var extensions = [ExtensionGenerator]()
        for e in descriptor.extension_p {
            var extPath = path
            extPath.append(6)
            extPath.append(i)
            i += 1
            extensions.append(ExtensionGenerator(descriptor: e, path: extPath, declaringMessageName: swiftFullName, file: file, context: context))
        }
        self.extensions = extensions

        var oneofs = [OneofGenerator]()
        for oneofIndex in (0..<descriptor.oneofDecl.count) {
            let oneofFields = fields.filter {$0.descriptor.oneofIndex == Int32(oneofIndex)}
            let oneof = OneofGenerator(descriptor: descriptor.oneofDecl[oneofIndex], fields: oneofFields, swiftMessageFullName: swiftFullName, isProto3: isProto3)
            oneofs.append(oneof)
        }
        self.oneofs = oneofs

        i = 0
        var enums = [EnumGenerator]()
        for e in descriptor.enumType {
            var enumPath = path
            enumPath.append(4)
            enumPath.append(i)
            i += 1
            enums.append(EnumGenerator(descriptor: e, path: enumPath, parentSwiftName: swiftFullName, file: file))
        }
        self.enums = enums

        i = 0
        var messages = [MessageGenerator]()
        for m in descriptor.nestedType where m.options?.mapEntry != true {
            var msgPath = path
            msgPath.append(3)
            msgPath.append(i)
            i += 1
            messages.append(MessageGenerator(descriptor: m, path: msgPath, parentSwiftName: swiftFullName, parentProtoPath: protoFullName, file: file, context: context))
        }
        self.messages = messages

        self.path = path
        self.comments = file.commentsFor(path: path)

        let useHeapStorage = !isGroup && (hasMessageField(descriptor: descriptor, context: context) || fields.count > 16)
        if useHeapStorage {
            self.storage = StorageClassGenerator(descriptor: descriptor, fields: fields, file: file, messageSwiftName: self.swiftFullName, isExtensible: isExtensible)
        } else {
            self.storage = nil
        }
    }

    func generateNested(printer p: inout CodePrinter, file: FileGenerator, parent: MessageGenerator?) {
        p.print("\n")
        if comments != "" {
            p.print(comments)
        }

        p.print("public struct \(swiftRelativeName): \(swiftMessageConformance) {\n")
        p.indent()
        p.print("public var swiftClassName: String {return \"\(swiftFullName)\"}\n")
        p.print("public var protoMessageName: String {return \"\(protoMessageName)\"}\n")
        p.print("public var protoPackageName: String {return \"\(protoPackageName)\"}\n")

        // Map JSON field names to field number
        if fields.isEmpty {
            p.print("public var jsonFieldNames: [String: Int] {return [:]}\n")
        } else {
            p.print("public var jsonFieldNames: [String: Int] {return [\n")
            p.indent()
            for f in fields {
                p.print("\"\(f.jsonName)\": \(f.number),\n")
            }
            p.outdent()
            p.print("]}\n")
        }

        // Map proto field names to field number
        if fields.isEmpty {
            p.print("public var protoFieldNames: [String: Int] {return [:]}\n")
        } else {
            p.print("public var protoFieldNames: [String: Int] {return [\n")
            p.indent()
            for f in fields {
                p.print("\"\(f.protoName)\": \(f.number),\n")
            }
            p.outdent()
            p.print("]}\n")
        }

        if let storage = storage {
            // Storage class, if needed
            storage.generateNested(printer: &p)
            p.print("\n")
            p.print("private var _storage: _StorageClass?\n")
        }

        if storage == nil && !file.isProto3 {
            p.print("\n")
            p.print("var unknown = ProtobufUnknownStorage()\n")
        }

        for o in oneofs {
            o.generateNested(printer: &p)
        }

        // Nested enums
        for e in enums {
            e.generateNested(printer: &p)
        }

        // Nested messages
        for m in messages {
            m.generateNested(printer: &p, file: file, parent: self)
        }

        // Nested extension declarations
        if !extensions.isEmpty {
            p.print("\n")
            p.print("struct Extensions {\n")
            p.indent()
            for e in extensions {
                e.generateNested(printer: &p)
            }
            p.outdent()
            p.print("}\n")
        }

        // ivars
        if storage != nil {
            for f in fields {
                f.generateProxyIvar(printer: &p)
            }
            for o in oneofs {
                o.generateProxyIvar(printer: &p)
            }
        } else {
            // Local ivars if no storage class
            var oneofHandled = Set<Int32>()
            for f in fields {
                f.generateTopIvar(printer: &p)
                if let oneofIndex = f.descriptor.oneofIndex {
                    if !oneofHandled.contains(oneofIndex) {
                        let oneof = oneofs[Int(oneofIndex)]
                        oneof.generateTopIvar(printer: &p)
                        oneofHandled.insert(oneofIndex)
                    }
                }
            }
        }

        // Default init
        p.print("\n")
        p.print("public init() {}\n")

        // Convenience init
        if !fields.isEmpty {
            p.print("\n")
            p.print("public init(")
            p.indent()
            var separator = ""
            for f in fields {
                p.print(separator)
                separator = ",\n"
                p.print("\(f.swiftName): \(f.convenienceInitType) = \(f.convenienceInitDefault)")
            }
            p.print(")\n")
            p.outdent()
            p.print("{\n")
            p.indent()
            if storage != nil {
                p.print("let storage = _uniqueStorage()\n")
            }
            for f in fields {
                let varName: String
                if storage == nil {
                    varName = "self." + f.swiftName
                } else {
                    varName = "storage." + f.swiftStorageName
                }
                if let oneof = f.oneof {
                    let oneofVarName: String
                    if storage == nil {
                        oneofVarName = "self." + oneof.swiftFieldName
                    } else {
                        oneofVarName = "storage." + oneof.swiftStorageFieldName
                    }
                    p.print("if let v = \(f.swiftName) {\n")
                    p.print("  \(oneofVarName) = .\(f.swiftName)(v)\n")
                    p.print("}\n")
                } else if f.isRepeated || f.isMap {
                    p.print("if !\(f.swiftName).isEmpty {\n")
                    p.print("  \(varName) = \(f.swiftName)\n")
                    p.print("}\n")
                } else if f.isGroup || f.isMessage {
                    p.print("\(varName) = \(f.swiftName)\n")
                } else if isProto3 {
                    p.print("if let v = \(f.swiftName) {\n")
                    p.print("  \(varName) = v\n")
                    p.print("}\n")
                } else {
                    p.print("\(varName) = \(f.swiftName)\n")
                }
            }
            p.outdent()
            p.print("}\n")
        }

        // Field-addressable decoding
        p.print("\n")
        p.print("public mutating func _protoc_generated_decodeField(setter: inout ProtobufFieldDecoder, protoFieldNumber: Int) throws -> Bool {\n")
        p.indent()
        if storage != nil {
            p.print("return try _uniqueStorage().decodeField(setter: &setter, protoFieldNumber: protoFieldNumber)\n")
        } else if fields.isEmpty {
            if isProto3 {
                p.print("return false // Proto3 ignores unknown fields\n")
            } else if isExtensible {
                p.print("var handled = false\n")
                p.print("if ")
                var separator = ""
                for range in descriptor.extensionRange {
                    p.print(separator)
                    p.print("(\(range.start!) <= protoFieldNumber && protoFieldNumber < \(range.end!))")
                    separator = " || "
                }
                p.print(" {\n")
                p.print("  handled = try setter.decodeExtensionField(values: &extensionFieldValues, messageType: \(swiftRelativeName).self, protoFieldNumber: protoFieldNumber)\n")
                p.print("} else {\n")
                p.print("  handled = false\n")
                p.print("}\n")
                p.print("if handled {\n")
                p.print("    return true\n")
                p.print("} else {\n")
                p.print("    return try unknown.decodeField(setter: &setter)\n")
                p.print("}\n")
            } else {
                p.print("return try unknown.decodeField(setter: &setter)\n")
            }
        } else {
            p.print("let handled: Bool\n")
            p.print("switch protoFieldNumber {\n")
            var oneofHandled = Set<Int32>()
            for f in fields {
                if let oneofIndex = f.descriptor.oneofIndex {
                    if !oneofHandled.contains(oneofIndex) {
                        p.print("case \(f.number)")
                        for other in fields {
                            if other.descriptor.oneofIndex == oneofIndex && other.number != f.number {
                                p.print(", \(other.number)")
                            }
                        }
                        p.print(":\n")
                        p.indent()
                        let oneof = f.oneof!
                        p.print("handled = try \(oneof.swiftFieldName).decodeField(setter: &setter, protoFieldNumber: protoFieldNumber)\n")
                        oneofHandled.insert(oneofIndex)
                        p.outdent()
                    }
                } else {
                    f.generateDecodeFieldCase(printer: &p)
                }
            }
            p.print("default:\n")
            p.indent()
            if isExtensible {
                p.print("if ")
                var separator = ""
                for range in descriptor.extensionRange {
                    p.print(separator)
                    p.print("(\(range.start!) <= protoFieldNumber && protoFieldNumber < \(range.end!))")
                    separator = " || "
                }
                p.print(" {\n")
                p.print("  handled = try setter.decodeExtensionField(values: &extensionFieldValues, messageType: \(swiftRelativeName).self, protoFieldNumber: protoFieldNumber)\n")
                p.print("} else {\n")
                p.print("  handled = false\n")
                p.print("}\n")
            } else {
                p.print("handled = false\n")
            }
            p.outdent()
            p.print("}\n")
            if !isProto3 {
                p.print("if handled {\n")
                p.print("    return true\n")
                p.print("} else {\n")
                p.print("    return try unknown.decodeField(setter: &setter)\n")
                p.print("}\n")
            } else {
                p.print("return handled\n")
            }
        }
        p.outdent()
        p.print("}\n")

        // Traversal method
        p.print("\n")
        p.print("public func _protoc_generated_traverse(visitor: inout ProtobufVisitor) throws {\n")
        p.indent()
        if storage != nil {
            let hasRequired = descriptor.field.contains {$0.label == .required}
            if hasRequired {
                p.print("try (_storage ?? _StorageClass()).traverse(visitor: &visitor)\n")
            } else {
                p.print("try _storage?.traverse(visitor: &visitor)\n")
            }
        } else {
            var ranges = descriptor.extensionRange.makeIterator()
            var nextRange = ranges.next()
            var currentOneof: Google_Protobuf_OneofDescriptorProto?
            var oneofStart = 0
            var oneofEnd = 0
            for f in (fields.sorted {$0.number < $1.number}) {
                while nextRange != nil && Int(nextRange!.start!) < f.number {
                    p.print("try extensionFieldValues.traverse(visitor: &visitor, start: \(nextRange!.start!), end: \(nextRange!.end!))\n")
                    nextRange = ranges.next()
                }
                if let c = currentOneof, let n = f.oneof, n.name! == c.name! {
                    oneofEnd = f.number + 1
                } else {
                    if let oneof = currentOneof {
                        p.print("try \(oneof.swiftFieldName).traverse(visitor: &visitor, start: \(oneofStart), end: \(oneofEnd))\n")
                        currentOneof = nil
                    }
                    if let newOneof = f.oneof {
                        oneofStart = f.number
                        oneofEnd = f.number + 1
                        currentOneof = newOneof
                    } else {
                        f.generateTraverse(printer: &p)
                    }
                }
            }
            if let oneof = currentOneof {
                p.print("try \(oneof.swiftFieldName).traverse(visitor: &visitor, start: \(oneofStart), end: \(oneofEnd))\n")
            }
            while nextRange != nil {
                p.print("try extensionFieldValues.traverse(visitor: &visitor, start: \(nextRange!.start!), end: \(nextRange!.end!))\n")
                nextRange = ranges.next()
            }
            if !file.isProto3 {
                p.print("unknown.traverse(visitor: &visitor)\n")
            }
        }
        p.outdent()
        p.print("}\n")

        // isEmpty property
        p.print("\n")
        if fields.isEmpty && isProto3 {
            p.print("public let _protoc_generated_isEmpty: Bool = true\n")
        } else if storage != nil {
            p.print("public var _protoc_generated_isEmpty: Bool {return _storage?.isEmpty ?? true}\n")
        } else {
            p.print("public var _protoc_generated_isEmpty: Bool {\n")
            p.indent()
            var oneofHandled = Set<Int32>()
            for f in fields {
                if let o = f.oneof {
                    if !oneofHandled.contains(f.descriptor.oneofIndex!) {
                        p.print("if !\(o.swiftFieldName).isEmpty {return false}\n")
                        oneofHandled.insert(f.descriptor.oneofIndex!)
                    }
                } else if f.isRepeated {
                    p.print("if !\(f.swiftName).isEmpty {return false}\n")
                } else if isProto3 {
                    p.print("if \(f.swiftName) != \(f.swiftDefaultValue) {return false}\n")
                } else if f.isOptional {
                    if let def = f.swiftProto2DefaultValue {
                        p.print("if \(f.swiftName) != nil && \(f.swiftName)! != \(def) {return false}\n")
                    } else {
                        p.print("if \(f.swiftName) != nil {return false}\n")
                    }
                } else {
                    p.print("if \(f.swiftName) != \(f.swiftDefaultValue) {return false}\n")
                }
            }
            if !file.isProto3 {
                p.print("if !unknown.isEmpty {return false}\n")
            }
            if isExtensible {
                p.print("if !extensionFieldValues.isEmpty {return false}\n")
            }
            p.print("return true\n")
            p.outdent()
            p.print("}\n")
        }

        // isEqualTo method
        p.print("\n")
        p.print("public func _protoc_generated_isEqualTo(other: \(swiftFullName)) -> Bool {\n")
        p.indent()
        if fields.isEmpty {
            if !isProto3 {
                p.print("if unknown != other.unknown {return false}\n")
            }
            if isExtensible {
                p.print("if extensionFieldValues != other.extensionFieldValues {return false}\n")
            }
            p.print("return true\n")
        } else {
            if storage != nil {
                p.print("if let s = _storage {\n")
                p.print("  if let os = other._storage {\n")
                p.print("    return s === os || s.isEqualTo(other: os)\n")
                p.print("  }\n")
                p.print("  return isEmpty // empty storage == nil storage\n")
                p.print("} else if let os = other._storage {\n")
                p.print("  return os.isEmpty // nil storage == empty storage\n")
                p.print("}\n")
                p.print("return true // Both nil, both empty\n")
            } else {
                var oneofHandled = Set<Int32>()
                for f in fields {
                    if let o = f.oneof {
                        if !oneofHandled.contains(f.descriptor.oneofIndex!) {
                            p.print("if \(o.swiftFieldName) != other.\(o.swiftFieldName) {return false}\n")
                            oneofHandled.insert(f.descriptor.oneofIndex!)
                        }
                    } else {
                        let notEqualClause = f.generateNotEqual(name: f.swiftName)
                        p.print("if \(notEqualClause) {return false}\n")
                    }
                }
                if !isProto3 {
                    p.print("if unknown != other.unknown {return false}\n")
                }
                if isExtensible {
                    p.print("if extensionFieldValues != other.extensionFieldValues {return false}\n")
                }
                p.print("return true\n")
            }
        }
        p.outdent()
        p.print("}\n")

        // uniqueStorage for copy-on-write
        if storage != nil {
            p.print("\n")
            p.print("private mutating func _uniqueStorage() -> _StorageClass {\n")
            p.print("  if _storage == nil {\n")
            p.print("    _storage = _StorageClass()\n")
            p.print("  } else if !isKnownUniquelyReferenced(&_storage) {\n")
            p.print("    _storage = _storage!.copy()\n")
            p.print("  }\n")
            p.print("  return _storage!\n")
            p.print("}\n")
        }

        // Optional extension support
        if isExtensible {
            if storage != nil {
                p.print("\n")
                p.print("public mutating func setExtensionValue<F: ProtobufExtensionField>(ext: ProtobufGenericMessageExtension<F, \(swiftRelativeName)>, value: F.ValueType) {\n")
                p.print("  return _uniqueStorage().setExtensionValue(ext: ext, value: value)\n")
                p.print("}\n")
                p.print("\n")
                p.print("public func getExtensionValue<F: ProtobufExtensionField>(ext: ProtobufGenericMessageExtension<F, \(swiftRelativeName)>) -> F.ValueType {\n")
                p.print("  return _storage?.getExtensionValue(ext: ext) ?? ext.defaultValue\n")
                p.print("}\n")
            } else {
                p.print("\n")
                p.print("private var extensionFieldValues = ProtobufExtensionFieldValueSet()\n")
                p.print("\n")
                p.print("public mutating func setExtensionValue<F: ProtobufExtensionField>(ext: ProtobufGenericMessageExtension<F, \(swiftRelativeName)>, value: F.ValueType) {\n")
                p.print("  extensionFieldValues[ext.protoFieldNumber] = ext.set(value: value)\n")
                p.print("}\n")
                p.print("\n")
                p.print("public func getExtensionValue<F: ProtobufExtensionField>(ext: ProtobufGenericMessageExtension<F, \(swiftRelativeName)>) -> F.ValueType {\n")
                p.print("  if let fieldValue = extensionFieldValues[ext.protoFieldNumber] as? F {\n")
                p.print("    return fieldValue.value\n")
                p.print("  }\n")
                p.print("  return ext.defaultValue\n")
                p.print("}\n")
            }
        }

        p.outdent()
        p.print("}\n")
    }

    func generateTopLevel(printer p: inout CodePrinter) {
        // nested oneofs
        for o in oneofs {
            o.generateTopLevel(printer: &p)
        }

        // nested messages
        for m in messages {
            m.generateTopLevel(printer: &p)
        }

        // nested extensions
        for e in extensions {
            e.generateTopLevel(printer: &p)
        }
    }

    func registerExtensions(registry: inout [String]) {
        for e in extensions {
            registry.append(e.swiftFullExtensionName)
        }
        for m in messages {
            m.registerExtensions(registry: &registry)
        }
    }
}
