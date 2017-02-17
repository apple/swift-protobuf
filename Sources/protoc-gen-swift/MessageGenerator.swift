// Sources/protoc-gen-swift/MessageGenerator.swift - Per-message logic
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
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
            let messagePath = parentPath + "." + m.name
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
            let messagePath = parentPath + "." + m.name
            let messageSwiftPath = swiftPrefix + "." + sanitizeMessageTypeName(m.name)
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
            let enumPath = parentPath + "." + e.name
            if enumPath == path {
                return swiftPrefix + "." + sanitizeEnumTypeName(e.name)
            }
        }

        for m in nestedType {
            let messagePath = parentPath + "." + m.name
            let messageSwiftPath = swiftPrefix + "." + sanitizeMessageTypeName(m.name)
            if let n = m.getEnumNameForPath(path: path, parentPath: messagePath, swiftPrefix: messageSwiftPath) {
                return n
            }
        }
        return nil
    }

    func getSwiftNameForEnumCase(path: String, caseName: String, parentPath: String, swiftPrefix: String) -> String? {
        for e in enumType {
            let enumPath = parentPath + "." + e.name
            if enumPath == path {
                let enumSwiftName = swiftPrefix + "." + sanitizeEnumTypeName(e.name)
                return enumSwiftName + "." + e.getSwiftNameForEnumCase(caseName: caseName)
            }
        }

        for m in nestedType {
            let messagePath = parentPath + "." + m.name
            let messageSwiftPath = swiftPrefix + "." + sanitizeMessageTypeName(m.name)
            if let n = m.getSwiftNameForEnumCase(path: path, caseName: caseName, parentPath: messagePath, swiftPrefix: messageSwiftPath) {
                return n
            }
        }
        return nil
    }
}

func hasMessageField(descriptor: Google_Protobuf_DescriptorProto, context: Context) -> Bool {
    let hasMessageField = descriptor.field.contains {
        ($0.type == .message || $0.type == .group)
        && $0.label != .repeated
        && (context.getMessageForPath(path: $0.typeName)?.options.mapEntry != true)
    }
    return hasMessageField
}

class StorageClassGenerator {
    private let fields: [MessageFieldGenerator]
    private let oneofs: [OneofGenerator]
    private let descriptor: Google_Protobuf_DescriptorProto
    private let messageSwiftName: String
    private let isProto3: Bool
    private let isExtensible: Bool
    private let context: Context

    init(descriptor: Google_Protobuf_DescriptorProto, fields: [MessageFieldGenerator], oneofs: [OneofGenerator], file: FileGenerator, messageSwiftName: String, isExtensible: Bool, context: Context) {
        self.descriptor = descriptor
        self.fields = fields
        self.oneofs = oneofs
        self.messageSwiftName = messageSwiftName
        self.isProto3 = file.isProto3
        self.isExtensible = isExtensible
        self.context = context
    }

    func generateNested(printer p: inout CodePrinter) {
        p.print("\n")
        if isExtensible {
            p.print("private class _StorageClass: SwiftProtobuf.ExtensibleMessageStorage {\n")
        } else {
            p.print("private class _StorageClass {\n")
        }
        p.indent()

        p.print("typealias ExtendedMessage = \(messageSwiftName)\n")
        if isExtensible {
            p.print("var extensionFieldValues = SwiftProtobuf.ExtensionFieldValueSet()\n")
        }
        if !isProto3 {
            p.print("var unknownFields = SwiftProtobuf.UnknownStorage()\n")
        }

        // ivars
        var oneofHandled = Set<Int32>()
        for f in fields {
            if f.descriptor.hasOneofIndex {
                let oneofIndex = f.descriptor.oneofIndex
                if !oneofHandled.contains(oneofIndex) {
                    let oneof = f.oneof!
                    p.print("var \(oneof.swiftStorageFieldName): \(messageSwiftName).\(oneof.swiftRelativeType)?\n")
                    oneofHandled.insert(oneofIndex)
                }
            } else {
                p.print("var \(f.swiftStorageName): \(f.swiftStorageType) = \(f.swiftStorageDefaultValue)\n")
            }
        }

        generateIsInitialized(printer: &p)

        // decodeField
        p.print("\n")
        p.print("func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {\n")
        p.indent()
        p.print("while let fieldNumber = try decoder.nextFieldNumber() {\n")
        p.indent()
        p.print("try decodeField(decoder: &decoder, fieldNumber: fieldNumber)\n")
        p.outdent()
        p.print("}\n")
        p.outdent()
        p.print("}\n")

        p.print("\n")
        p.print("func decodeField<D: SwiftProtobuf.Decoder>(decoder: inout D, fieldNumber: Int) throws {\n")
        p.indent()
        p.print("switch fieldNumber {\n")
        oneofHandled.removeAll(keepingCapacity: true)
        for f in fields {
            if f.descriptor.hasOneofIndex {
                let oneofIndex = f.descriptor.oneofIndex
                if !oneofHandled.contains(oneofIndex) {
                    p.print("case \(f.number)")
                    for other in fields {
                        if other.descriptor.hasOneofIndex && other.descriptor.oneofIndex == oneofIndex && other.number != f.number {
                            p.print(", \(other.number)")
                        }
                    }
                    let oneof = f.oneof!
                    p.print(":\n")
                    p.indent()
                    p.print("if \(oneof.swiftStorageFieldName) != nil {\n")
                    p.print("  try decoder.handleConflictingOneOf()\n")
                    p.print("}\n")
                    p.print("\(oneof.swiftStorageFieldName) = try \(messageSwiftName).\(oneof.swiftRelativeType)(byDecodingFrom: &decoder, fieldNumber: fieldNumber)\n")
                    p.outdent()
                    oneofHandled.insert(oneofIndex)
                }
            } else {
                f.generateDecodeFieldCase(printer: &p, prefix: "_")
            }
        }
        if isExtensible {
            p.print("default: if ")
            var separator = ""
            for range in descriptor.extensionRange {
                p.print(separator)
                p.print("(\(range.start) <= fieldNumber && fieldNumber < \(range.end))")
                separator = " || "
            }
            p.print(" {\n")
            p.indent()
            p.indent()
            p.print("try decoder.decodeExtensionField(values: &extensionFieldValues, messageType: \(messageSwiftName).self, fieldNumber: fieldNumber)\n")
            p.outdent()
            p.print("}\n")
            p.outdent()
        } else {
            p.print("default: break\n")
        }
        p.print("}\n")
        p.outdent()
        p.print("}\n")

        // traverse
        p.print("\n")
        p.print("func traverse(visitor: SwiftProtobuf.Visitor) throws {\n")
        p.indent()
        var currentOneof: Google_Protobuf_OneofDescriptorProto?
        var oneofStart = 0
        var oneofEnd = 0
        var ranges = descriptor.extensionRange.makeIterator()
        var nextRange = ranges.next()
        for f in (fields.sorted {$0.number < $1.number}) {
            while nextRange != nil && Int(nextRange!.start) < f.number {
                p.print("try visitor.visitExtensionFields(fields: extensionFieldValues, start: \(nextRange!.start), end: \(nextRange!.end))\n")
                nextRange = ranges.next()
            }
            if let c = currentOneof, let n = f.oneof, n.name == c.name {
                oneofEnd = f.number + 1
            } else {
                if let oneof = currentOneof {
                    p.print("try \(oneof.swiftStorageFieldName)?.traverse(visitor: visitor, start: \(oneofStart), end: \(oneofEnd))\n")
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
            p.print("try \(oneof.swiftStorageFieldName)?.traverse(visitor: visitor, start: \(oneofStart), end: \(oneofEnd))\n")
        }
        while nextRange != nil {
            p.print("try visitor.visitExtensionFields(fields: extensionFieldValues, start: \(nextRange!.start), end: \(nextRange!.end))\n")
            nextRange = ranges.next()
        }
        if !isProto3 {
            p.print("unknownFields.traverse(visitor: visitor)\n")
        }
        p.outdent()
        p.print("}\n")

        // isEqual helper
        p.print("\n")
        p.print("func isEqualTo(other: _StorageClass) -> Bool {\n")
        p.indent()
        oneofHandled.removeAll(keepingCapacity: true)
        for f in fields {
            if let o = f.oneof {
                if !oneofHandled.contains(f.descriptor.oneofIndex) {
                    p.print("if \(o.swiftStorageFieldName) != other.\(o.swiftStorageFieldName) {return false}\n")
                    oneofHandled.insert(f.descriptor.oneofIndex)
                }
            } else {
                let notEqualClause = f.generateNotEqual(name: f.swiftStorageName, usesHeapStorage: true)
                p.print("if \(notEqualClause) {return false}\n")
            }
        }
        if !isProto3 {
            p.print("if unknownFields != other.unknownFields {return false}\n")
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
            p.print("clone.unknownFields = unknownFields\n")
        }
        if isExtensible {
            p.print("clone.extensionFieldValues = extensionFieldValues\n")
        }
        oneofHandled.removeAll(keepingCapacity: true)
        for f in fields {
            if let o = f.oneof {
                if !oneofHandled.contains(f.descriptor.oneofIndex) {
                    p.print("clone.\(o.swiftStorageFieldName) = \(o.swiftStorageFieldName)\n")
                    oneofHandled.insert(f.descriptor.oneofIndex)
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

    func generateIsInitialized(printer p: inout CodePrinter) {
      var functionStarted = false;
      func ensureFunctionStarted() {
        if functionStarted { return }
        functionStarted = true
        p.print("\nvar isInitialized: Bool {\n")
        p.indent()
      }

      if isExtensible {
        ensureFunctionStarted()
        p.print("if !extensionFieldValues.isInitialized {return false}\n")
      }

      if !isProto3 {
        // Only proto2 syntax can have field presence (required fields); ensure required
        // fields have values.
        for f in fields {
          if f.descriptor.label != .required {
            continue
          }
          ensureFunctionStarted()
          p.print("if \(f.swiftStorageName) == nil {return false}\n")
        }
      }

      // Check that all non-oneof embedded messages are initialized.
      for f in fields {
        if f.fieldHoldsMessage && f.oneof == nil &&
          messageHasRequiredFields(msgTypeName:f.descriptor.typeName, context: context) {
          ensureFunctionStarted()
          if f.isRepeated {
            p.print("if !SwiftProtobuf.Internal.areAllInitialized(\(f.swiftStorageName)) {return false}\n")
          } else {
            p.print("if let v = \(f.swiftStorageName), !v.isInitialized {return false}\n")
          }
        }
      }

      // Check the oneofs using a switch so we can be more efficent.
      for oneofField in oneofs {
        var hasRequiredFields = false
        for f in oneofField.fields {
          if f.descriptor.isMessage &&
            messageHasRequiredFields(msgTypeName:f.descriptor.typeName, context: context) {
            hasRequiredFields = true
            break
          }
        }
        if !hasRequiredFields {
          continue
        }

        ensureFunctionStarted()
        p.print("switch \(oneofField.descriptor.swiftStorageFieldName) {\n")
        var needsDefault = false
        for f in oneofField.fields {
          if f.descriptor.isMessage &&
            messageHasRequiredFields(msgTypeName:f.descriptor.typeName, context: context) {
            p.print("case .\(f.swiftName)(let v)?:\n")
            p.indent()
            p.print("if !v.isInitialized {return false}\n")
            p.outdent()
          } else {
            needsDefault = true
          }
        }
        if needsDefault {
          p.print("default:\n")
          p.indent()
          p.print("break\n")
          p.outdent()
        }
        p.print("}\n")
      }

      if functionStarted {
        p.print("return true\n")
        p.outdent()
        p.print("}\n")
      }
    }
}

class MessageGenerator {
    private let descriptor: Google_Protobuf_DescriptorProto
    private let context: Context
    private let generatorOptions: GeneratorOptions
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
        self.protoMessageName = descriptor.name
        self.context = context
        self.generatorOptions = context.options
        self.protoFullName = (parentProtoPath == nil ? "" : (parentProtoPath! + ".")) + self.protoMessageName
        self.descriptor = descriptor
        self.isProto3 = file.isProto3
        self.isGroup = context.protoNameIsGroup.contains(protoFullName)
        self.isExtensible = descriptor.extensionRange.count > 0
        self.protoPackageName = file.protoPackageName
        if let parentSwiftName = parentSwiftName {
            swiftRelativeName = sanitizeMessageTypeName(descriptor.name)
            swiftFullName = parentSwiftName + "." + swiftRelativeName
        } else {
            swiftRelativeName = sanitizeMessageTypeName(file.swiftPrefix + descriptor.name)
            swiftFullName = swiftRelativeName
        }
        var conformance = "SwiftProtobuf.Message"
        if isProto3 {
            conformance += ", SwiftProtobuf.Proto3Message"
        } else {
            conformance += ", SwiftProtobuf.Proto2Message"
        }
        if isExtensible {
            conformance += ", SwiftProtobuf.ExtensibleMessage"
        }
        conformance += ", SwiftProtobuf._MessageImplementationBase"
        // TODO: Move this conformance into an extension in a separate file.
        conformance += ", SwiftProtobuf.ProtoNameProviding"
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
            extensions.append(ExtensionGenerator(descriptor: e, path: extPath, parentProtoPath: protoFullName, swiftDeclaringMessageName: swiftFullName, file: file, context: context))
        }
        self.extensions = extensions

        var oneofs = [OneofGenerator]()
        for oneofIndex in (0..<descriptor.oneofDecl.count) {
            let oneofFields = fields.filter {
                $0.descriptor.hasOneofIndex && $0.descriptor.oneofIndex == Int32(oneofIndex)
            }
            let oneof = OneofGenerator(descriptor: descriptor.oneofDecl[oneofIndex], generatorOptions: generatorOptions, fields: oneofFields, swiftMessageFullName: swiftFullName, isProto3: isProto3)
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
        for m in descriptor.nestedType where m.options.mapEntry != true {
            var msgPath = path
            msgPath.append(3)
            msgPath.append(i)
            i += 1
            messages.append(MessageGenerator(descriptor: m, path: msgPath, parentSwiftName: swiftFullName, parentProtoPath: protoFullName, file: file, context: context))
        }
        self.messages = messages

        self.path = path
        self.comments = file.commentsFor(path: path)

        // NOTE: This check for fields.count likely isn't completely correct
        // when the message has one or more oneof{}s. As that will efficively
        // reduce the real number of fields and the message might not need heap
        // storage yet.
        let useHeapStorage = fields.count > 16 || hasMessageField(descriptor: descriptor, context: context)
        if useHeapStorage {
          self.storage = StorageClassGenerator(descriptor: descriptor, fields: fields, oneofs: oneofs, file: file, messageSwiftName: self.swiftFullName, isExtensible: isExtensible, context: context)
        } else {
            self.storage = nil
        }
    }

    func generateNested(printer p: inout CodePrinter, file: FileGenerator, parent: MessageGenerator?) {
        p.print("\n")
        if comments != "" {
            p.print(comments)
        }

        p.print("\(generatorOptions.visibilitySourceSnippet)struct \(swiftRelativeName): \(swiftMessageConformance) {\n")
        p.indent()
        p.print("\(generatorOptions.visibilitySourceSnippet)static let protoMessageName: String = \"\(protoMessageName)\"\n")
        p.print("\(generatorOptions.visibilitySourceSnippet)static let protoPackageName: String = \"\(protoPackageName)\"\n")

        // Map proto field names to field number
        if fields.isEmpty {
            p.print("\(generatorOptions.visibilitySourceSnippet)static let _protobuf_fieldNames = FieldNameMap()\n")
        } else {
            p.print("\(generatorOptions.visibilitySourceSnippet)static let _protobuf_fieldNames: FieldNameMap = [\n")
            p.indent()
            for f in fields {
                p.print("\(f.number): \(f.fieldMapNames),\n")
            }
            p.outdent()
            p.print("]\n")
        }

        if let storage = storage {
            // Storage class, if needed
            storage.generateNested(printer: &p)
            p.print("\n")
            p.print("private var _storage = _StorageClass()\n")
        }

        p.print("\n")
        if !file.isProto3 {
            if storage == nil {
                p.print("\(generatorOptions.visibilitySourceSnippet)var unknownFields = SwiftProtobuf.UnknownStorage()\n")
            } else {
                p.print("\(generatorOptions.visibilitySourceSnippet)var unknownFields: SwiftProtobuf.UnknownStorage {\n")
                p.print("  get {return _storage.unknownFields}\n")
                p.print("  set {_storage.unknownFields = newValue}\n")
                p.print("}\n")
            }
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
                f.generateHasProperty(printer: &p, usesHeapStorage: true)
                f.generateClearMethod(printer: &p, usesHeapStorage: true)
            }
            for o in oneofs {
                o.generateProxyIvar(printer: &p)
            }
        } else {
            // Local ivars if no storage class
            var oneofHandled = Set<Int32>()
            for f in fields {
                f.generateTopIvar(printer: &p)
                f.generateHasProperty(printer: &p, usesHeapStorage: false)
                f.generateClearMethod(printer: &p, usesHeapStorage: false)
                if f.descriptor.hasOneofIndex {
                    let oneofIndex = f.descriptor.oneofIndex
                    if !oneofHandled.contains(oneofIndex) {
                        let oneof = oneofs[Int(oneofIndex)]
                        oneof.generateTopIvar(printer: &p)
                        oneofHandled.insert(oneofIndex)
                    }
                }
            }
        }

        // Every property is defaulted and Swift's Default Initializers are internal by
        // default, so there is no need to explicity generate the code (the compiler will
        // still do its checks, so only generated the Default Initializer when it needs
        // an explicit visibility.
        if generatorOptions.visibility != .Internal {
            p.print("\n")
            p.print("\(generatorOptions.visibilitySourceSnippet)init() {}\n")
        }

        // isInitialized
        generateIsInitialized(printer:&p)

        // Field-addressable decoding
        p.print("\n")
        p.print("\(generatorOptions.visibilitySourceSnippet)mutating func _protoc_generated_decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {\n")
        p.indent()
        if storage != nil {
            p.print("try _uniqueStorage().decodeMessage(decoder: &decoder)\n")
        } else {
            p.print("while let fieldNumber = try decoder.nextFieldNumber() {\n")
            p.indent()
            p.print("try decodeField(decoder: &decoder, fieldNumber: fieldNumber)\n")
            p.outdent()
            p.print("}\n")
        }
        p.outdent()
        p.print("}\n")

        p.print("\n")
        p.print("\(generatorOptions.visibilitySourceSnippet)mutating func _protoc_generated_decodeField<D: SwiftProtobuf.Decoder>(decoder: inout D, fieldNumber: Int) throws {\n")
        p.indent()
        if storage != nil {
            p.print("try _uniqueStorage().decodeField(decoder: &decoder, fieldNumber: fieldNumber)\n")
        } else {
            if !fields.isEmpty {
                p.print("switch fieldNumber {\n")
                var oneofHandled = Set<Int32>()
                for f in fields {
                    if f.descriptor.hasOneofIndex {
                        let oneofIndex = f.descriptor.oneofIndex
                        if !oneofHandled.contains(oneofIndex) {
                            p.print("case \(f.number)")
                            for other in fields {
                                if other.descriptor.hasOneofIndex && other.descriptor.oneofIndex == oneofIndex && other.number != f.number {
                                    p.print(", \(other.number)")
                                }
                            }
                            let oneof = f.oneof!
                            p.print(":\n")
                            p.indent()
                            p.print("if \(oneof.swiftFieldName) != nil {\n")
                            p.print("  try decoder.handleConflictingOneOf()\n")
                            p.print("}\n")
                            p.print("\(oneof.swiftFieldName) = try \(swiftFullName).\(oneof.swiftRelativeType)(byDecodingFrom: &decoder, fieldNumber: fieldNumber)\n")
                            p.outdent()
                            oneofHandled.insert(oneofIndex)
                        }
                    } else {
                        f.generateDecodeFieldCase(printer: &p)
                    }
                }
                p.print("default: ")
                if isProto3 || !isExtensible {
                    p.print("break\n")
                }
                p.indent()
            }
            if isExtensible {
                p.print("if ")
                var separator = ""
                for range in descriptor.extensionRange {
                    p.print(separator)
                    p.print("(\(range.start) <= fieldNumber && fieldNumber < \(range.end))")
                    separator = " || "
                }
                p.print(" {\n")
                p.indent()
                p.print("try decoder.decodeExtensionField(values: &_extensionFieldValues, messageType: \(swiftRelativeName).self, fieldNumber: fieldNumber)\n")
                p.outdent()
                p.print("}\n")
            }
            if !fields.isEmpty {
                p.outdent()
                p.print("}\n")
            }
        }
        p.outdent()
        p.print("}\n")

        // Traversal method
        p.print("\n")
        p.print("\(generatorOptions.visibilitySourceSnippet)func _protoc_generated_traverse(visitor: SwiftProtobuf.Visitor) throws {\n")
        p.indent()
        if storage != nil {
            p.print("try _storage.traverse(visitor: visitor)\n")
        } else {
            var ranges = descriptor.extensionRange.makeIterator()
            var nextRange = ranges.next()
            var currentOneof: Google_Protobuf_OneofDescriptorProto?
            var oneofStart = 0
            var oneofEnd = 0
            for f in (fields.sorted {$0.number < $1.number}) {
                while nextRange != nil && Int(nextRange!.start) < f.number {
                    p.print("try visitor.visitExtensionFields(fields: _extensionFieldValues, start: \(nextRange!.start), end: \(nextRange!.end))\n")
                    nextRange = ranges.next()
                }
                if let c = currentOneof, let n = f.oneof, n.name == c.name {
                    oneofEnd = f.number + 1
                } else {
                    if let oneof = currentOneof {
                        p.print("try \(oneof.swiftFieldName)?.traverse(visitor: visitor, start: \(oneofStart), end: \(oneofEnd))\n")
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
                p.print("try \(oneof.swiftFieldName)?.traverse(visitor: visitor, start: \(oneofStart), end: \(oneofEnd))\n")
            }
            while nextRange != nil {
                p.print("try visitor.visitExtensionFields(fields: _extensionFieldValues, start: \(nextRange!.start), end: \(nextRange!.end))\n")
                nextRange = ranges.next()
            }
            if !file.isProto3 {
                p.print("unknownFields.traverse(visitor: visitor)\n")
            }
        }
        p.outdent()
        p.print("}\n")

        // isEqualTo method
        p.print("\n")
        p.print("\(generatorOptions.visibilitySourceSnippet)func _protoc_generated_isEqualTo(other: \(swiftFullName)) -> Bool {\n")
        p.indent()
        if fields.isEmpty {
            if !isProto3 {
                p.print("if unknownFields != other.unknownFields {return false}\n")
            }
            if isExtensible {
                p.print("if _extensionFieldValues != other._extensionFieldValues {return false}\n")
            }
            p.print("return true\n")
        } else {
            if storage != nil {
                p.print("return _storage === other._storage || _storage.isEqualTo(other: other._storage)\n")
            } else {
                var oneofHandled = Set<Int32>()
                for f in fields {
                    if let o = f.oneof {
                        if !oneofHandled.contains(f.descriptor.oneofIndex) {
                            p.print("if \(o.swiftFieldName) != other.\(o.swiftFieldName) {return false}\n")
                            oneofHandled.insert(f.descriptor.oneofIndex)
                        }
                    } else {
                        let notEqualClause = f.generateNotEqual(name: f.swiftName, usesHeapStorage: false)
                        p.print("if \(notEqualClause) {return false}\n")
                    }
                }
                if !isProto3 {
                    p.print("if unknownFields != other.unknownFields {return false}\n")
                }
                if isExtensible {
                    p.print("if _extensionFieldValues != other._extensionFieldValues {return false}\n")
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
            p.print("  if !isKnownUniquelyReferenced(&_storage) {\n")
            p.print("    _storage = _storage.copy()\n")
            p.print("  }\n")
            p.print("  return _storage\n")
            p.print("}\n")
        }

        // Optional extension support
        if isExtensible {
            if storage != nil {
                p.print("\n")
                p.print("\(generatorOptions.visibilitySourceSnippet)mutating func setExtensionValue<F: SwiftProtobuf.ExtensionField>(ext: SwiftProtobuf.MessageExtension<F, \(swiftRelativeName)>, value: F.ValueType) {\n")
                p.print("  return _uniqueStorage().setExtensionValue(ext: ext, value: value)\n")
                p.print("}\n")
                p.print("\n")
                p.print("\(generatorOptions.visibilitySourceSnippet)mutating func clearExtensionValue<F: SwiftProtobuf.ExtensionField>(ext: SwiftProtobuf.MessageExtension<F, \(swiftRelativeName)>) {\n")
                p.print("  return _storage.clearExtensionValue(ext: ext)\n")
                p.print("}\n")
                p.print("\n")
                p.print("\(generatorOptions.visibilitySourceSnippet)func getExtensionValue<F: SwiftProtobuf.ExtensionField>(ext: SwiftProtobuf.MessageExtension<F, \(swiftRelativeName)>) -> F.ValueType {\n")
                p.print("  return _storage.getExtensionValue(ext: ext)\n")
                p.print("}\n")
                p.print("\n")
                p.print("\(generatorOptions.visibilitySourceSnippet)func hasExtensionValue<F: SwiftProtobuf.ExtensionField>(ext: SwiftProtobuf.MessageExtension<F, \(swiftRelativeName)>) -> Bool {\n")
                p.print("  return _storage.hasExtensionValue(ext: ext)\n")
                p.print("}\n")
                p.print("\(generatorOptions.visibilitySourceSnippet)func _protobuf_fieldNames(for number: Int) -> FieldNameMap.Names? {\n")
                p.print("  return \(swiftRelativeName)._protobuf_fieldNames.fieldNames(for: number) ?? _storage.extensionFieldValues.fieldNames(for: number)\n")
                p.print("}\n")
            } else {
                p.print("\n")
                p.print("private var _extensionFieldValues = SwiftProtobuf.ExtensionFieldValueSet()\n")
                p.print("\n")
                p.print("\(generatorOptions.visibilitySourceSnippet)mutating func setExtensionValue<F: SwiftProtobuf.ExtensionField>(ext: SwiftProtobuf.MessageExtension<F, \(swiftRelativeName)>, value: F.ValueType) {\n")
                p.print("  _extensionFieldValues[ext.fieldNumber] = ext.set(value: value)\n")
                p.print("}\n")
                p.print("\n")
                p.print("\(generatorOptions.visibilitySourceSnippet)mutating func clearExtensionValue<F: SwiftProtobuf.ExtensionField>(ext: SwiftProtobuf.MessageExtension<F, \(swiftRelativeName)>) {\n")
                p.print("  _extensionFieldValues[ext.fieldNumber] = nil\n")
                p.print("}\n")
                p.print("\n")
                p.print("\(generatorOptions.visibilitySourceSnippet)func getExtensionValue<F: SwiftProtobuf.ExtensionField>(ext: SwiftProtobuf.MessageExtension<F, \(swiftRelativeName)>) -> F.ValueType {\n")
                p.print("  if let fieldValue = _extensionFieldValues[ext.fieldNumber] as? F {\n")
                p.print("    return fieldValue.value\n")
                p.print("  }\n")
                p.print("  return ext.defaultValue\n")
                p.print("}\n")
                p.print("\n")
                p.print("\(generatorOptions.visibilitySourceSnippet)func hasExtensionValue<F: SwiftProtobuf.ExtensionField>(ext: SwiftProtobuf.MessageExtension<F, \(swiftRelativeName)>) -> Bool {\n")
                p.print("  return _extensionFieldValues[ext.fieldNumber] is F\n")
                p.print("}\n")
                p.print("\(generatorOptions.visibilitySourceSnippet)func _protobuf_fieldNames(for number: Int) -> FieldNameMap.Names? {\n")
                p.print("  return \(swiftRelativeName)._protobuf_fieldNames.fieldNames(for: number) ?? _extensionFieldValues.fieldNames(for: number)\n")
                p.print("}\n")
            }
        }

        p.outdent()
        p.print("}\n")
    }

    func generateIsInitialized(printer p: inout CodePrinter) {
      var functionStarted = false;
      func ensureFunctionStarted() {
        if functionStarted { return }
        functionStarted = true
        p.print("\npublic var isInitialized: Bool {\n")
        p.indent()
        if storage != nil {
          p.print("return _storage.isInitialized\n")
        }
      }

      if isExtensible {
        ensureFunctionStarted()
        if storage == nil {
          p.print("if !_extensionFieldValues.isInitialized {return false}\n")
        }
      }

      if !isProto3 {
        // Only proto2 syntax can have field presence (required fields); ensure required
        // fields have values.
        for f in fields {
          if f.descriptor.label != .required {
            continue
          }
          ensureFunctionStarted()
          if storage != nil {
            // No need to check other fields, using storage deferred to the
            // storage_.isInitialized.
            break
          } else {
            p.print("if \(f.swiftStorageName) == nil {return false}\n")
          }
        }
      }

      // Check that all non-oneof embedded messages are initialized.
      for f in fields {
        if f.fieldHoldsMessage && f.oneof == nil &&
          messageHasRequiredFields(msgTypeName:f.descriptor.typeName, context: context) {
          ensureFunctionStarted()
          if storage != nil {
            // No need to check other fields, using storage deferred to the
            // storage_.isInitialized.
            break
          } else {
            if f.isRepeated {
              p.print("if !SwiftProtobuf.Internal.areAllInitialized(\(f.swiftName)) {return false}\n")
            } else {
              p.print("if let v = \(f.swiftName), !v.isInitialized {return false}\n")
            }
          }
        }
      }

      // Check the oneofs using a switch so we can be more efficent.
      for oneofField in oneofs {
        var hasRequiredFields = false
        for f in oneofField.fields {
          if f.descriptor.isMessage &&
            messageHasRequiredFields(msgTypeName:f.descriptor.typeName, context: context) {
            hasRequiredFields = true
            break
          }
        }
        if !hasRequiredFields {
          continue
        }

        ensureFunctionStarted()
        if storage != nil {
          // No need to check other fields, using storage deferred to the
          // storage_.isInitialized.
          break;
        }

        p.print("switch \(oneofField.descriptor.swiftFieldName) {\n")
        var needsDefault = false
        for f in oneofField.fields {
          if f.descriptor.isMessage &&
            messageHasRequiredFields(msgTypeName:f.descriptor.typeName, context: context) {
            p.print("case .\(f.swiftName)(let v)?:\n")
            p.indent()
            p.print("if !v.isInitialized {return false}\n")
            p.outdent()
          } else {
            needsDefault = true
          }
        }
        if needsDefault {
          p.print("default:\n")
          p.indent()
          p.print("break\n")
          p.outdent()
        }
        p.print("}\n")
      }

      if functionStarted {
        if storage == nil {
          p.print("return true\n")
        }
        p.outdent()
        p.print("}\n")
      }
    }

    func generateTopLevel(printer p: inout CodePrinter) {
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

// The logic for this check comes from google/protobuf; the C++ and Java generators specificly.
//
// This is a helper for generating isInitialized methods.
fileprivate func messageHasRequiredFields(descriptor msgDesc: Google_Protobuf_DescriptorProto, context: Context) -> Bool {
  var alreadySeen = Set<Google_Protobuf_DescriptorProto>()

  func hasRequiredFieldsInner(_ msgDesc: Google_Protobuf_DescriptorProto) -> Bool {
    if alreadySeen.contains(msgDesc) {
      // First required thing found causes this to return true, so one can assume if it is already
      // visited, it didn't have required fields.
      return false
    }
    alreadySeen.insert(msgDesc)

    // If it can support extesions, and extension could be a message with required fields.
    if msgDesc.extensionRange.count > 0 {
      return true
    }

    for f in msgDesc.field {
      if f.label == .required {
        return true
      }
      if (f.isMessage || f.isGroup) &&
        hasRequiredFieldsInner(context.getMessageForPath(path: f.typeName)!) {
        return true
      }
    }

    return false
  }

  return hasRequiredFieldsInner(msgDesc);
}

fileprivate func messageHasRequiredFields(msgTypeName: String, context: Context) -> Bool {
  let msgDesc = context.getMessageForPath(path: msgTypeName)!
  return messageHasRequiredFields(descriptor: msgDesc, context: context)
}
