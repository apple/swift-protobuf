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

class MessageGenerator {
  private let descriptor: Descriptor
  private let generatorOptions: GeneratorOptions
  private let namer: SwiftProtobufNamer
  private let visibility: String
  private let swiftFullName: String
  private let swiftRelativeName: String
  private let fields: [FieldGenerator]
  private let fieldsSortedByNumber: [FieldGenerator]
  private let oneofs: [OneofGenerator]
  private let extensions: [ExtensionGenerator]
  private let storage: MessageStorageClassGenerator?
  private let enums: [EnumGenerator]
  private let messages: [MessageGenerator]
  private let isExtensible: Bool

  init(
    descriptor: Descriptor,
    generatorOptions: GeneratorOptions,
    namer: SwiftProtobufNamer
  ) {
    self.descriptor = descriptor
    self.generatorOptions = generatorOptions
    self.namer = namer

    visibility = generatorOptions.visibilitySourceSnippet
    isExtensible = !descriptor.extensionRanges.isEmpty
    swiftRelativeName = namer.relativeName(message: descriptor)
    swiftFullName = namer.fullName(message: descriptor)

    let isAnyMessage = descriptor.isAnyMessage
    // NOTE: This check for fields.count likely isn't completely correct
    // when the message has one or more oneof{}s. As that will efficively
    // reduce the real number of fields and the message might not need heap
    // storage yet.
    let useHeapStorage = isAnyMessage || descriptor.fields.count > 16 || hasSingleMessageField(descriptor: descriptor)

    oneofs = descriptor.oneofs.map {
      return OneofGenerator(descriptor: $0, generatorOptions: generatorOptions, namer: namer, usesHeapStorage: useHeapStorage)
    }

    let factory = MessageFieldFactory(generatorOptions: generatorOptions,
                                      namer: namer,
                                      useHeapStorage: useHeapStorage,
                                      oneofGenerators: oneofs)
    fields = descriptor.fields.map {
      return factory.make(forFieldDescriptor: $0)
    }
    fieldsSortedByNumber = fields.sorted {$0.number < $1.number}

    extensions = descriptor.extensions.map {
      return ExtensionGenerator(descriptor: $0, generatorOptions: generatorOptions, namer: namer)
    }

    enums = descriptor.enums.map {
      return EnumGenerator(descriptor: $0, generatorOptions: generatorOptions, namer: namer)
    }

    var messages = [MessageGenerator]()
    for m in descriptor.messages where !m.isMapEntry {
      messages.append(MessageGenerator(descriptor: m, generatorOptions: generatorOptions, namer: namer))
    }
    self.messages = messages

    if isAnyMessage {
      storage = AnyMessageStorageClassGenerator(fields: fields)
    } else if useHeapStorage {
      storage = MessageStorageClassGenerator(fields: fields)
    } else {
      storage = nil
    }
  }

  func generateMainStruct(printer p: inout CodePrinter, parent: MessageGenerator?) {
    var conformance: [String] = ["SwiftProtobuf.Message"]
    if isExtensible {
      conformance.append("SwiftProtobuf.ExtensibleMessage")
    }
    p.print(
        "\n",
        descriptor.protoSourceComments(),
        "\(visibility)struct \(swiftRelativeName): \(conformance.joined(separator: ", ")) {\n")
    p.indent()
    if let parent = parent {
        p.print("\(visibility)static let protoMessageName: String = \(parent.swiftFullName).protoMessageName + \".\(descriptor.name)\"\n")
    } else if !descriptor.file.package.isEmpty {
        p.print("\(visibility)static let protoMessageName: String = _protobuf_package + \".\(descriptor.name)\"\n")
    } else {
        p.print("\(visibility)static let protoMessageName: String = \"\(descriptor.name)\"\n")
    }

    for f in fields {
      f.generateInterface(printer: &p)
    }

    p.print(
        "\n",
        "\(visibility)var unknownFields = SwiftProtobuf.UnknownStorage()\n")

    for o in oneofs {
      o.generateMainEnum(printer: &p)
    }

    // Nested enums
    for e in enums {
      e.generateMainEnum(printer: &p)
    }

    // Nested messages
    for m in messages {
      m.generateMainStruct(printer: &p, parent: self)
    }

    // Generate the default initializer. If we don't, Swift seems to sometimes
    // generate it along with others that can take public proprerties. When it
    // generates the others doesn't seem to be documented.
    p.print(
        "\n",
        "\(visibility)init() {}\n")

    // isInitialized
    generateIsInitialized(printer:&p)

    p.print("\n")
    generateDecodeMessage(printer: &p)

    p.print("\n")
    generateTraverse(printer: &p)

    // Optional extension support
    if isExtensible {
      p.print(
          "\n",
          "\(visibility)var _protobuf_extensionFieldValues = SwiftProtobuf.ExtensionFieldValueSet()\n")
    }
    if let storage = storage {
      if !isExtensible {
        p.print("\n")
      }
      p.print("\(storage.storageVisibility) var _storage = _StorageClass()\n")
    } else {
      var subMessagePrinter = CodePrinter()
      for f in fields {
        f.generateStorage(printer: &subMessagePrinter)
      }
      if !subMessagePrinter.isEmpty {
        if !isExtensible {
          p.print("\n")
        }
        p.print(subMessagePrinter.content)
      }
    }

    p.outdent()
    p.print("}\n")
  }

  func generateProtobufExtensionDeclarations(printer p: inout CodePrinter) {
    if !extensions.isEmpty {
      p.print(
          "\n",
          "extension \(swiftFullName) {\n")
      p.indent()
      p.print("enum Extensions {\n")
      p.indent()
      var addNewline = false
      for e in extensions {
        if addNewline {
          p.print("\n")
        } else {
          addNewline = true
        }
        e.generateProtobufExtensionDeclarations(printer: &p)
      }
      p.outdent()
      p.print("}\n")
      p.outdent()
      p.print("}\n")
    }
    for m in messages {
      m.generateProtobufExtensionDeclarations(printer: &p)
    }
  }

  func generateMessageSwiftExtensionForProtobufExtensions(printer p: inout CodePrinter) {
    for e in extensions {
      e.generateMessageSwiftExtensionForProtobufExtensions(printer: &p)
    }
    for m in messages {
      m.generateMessageSwiftExtensionForProtobufExtensions(printer: &p)
    }
  }

  func registerExtensions(registry: inout [String]) {
    for e in extensions {
      e.register(&registry)
    }
    for m in messages {
      m.registerExtensions(registry: &registry)
    }
  }

  func generateRuntimeSupport(printer p: inout CodePrinter, file: FileGenerator, parent: MessageGenerator?) {
    p.print(
        "\n",
        "extension \(swiftFullName): SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {\n")
    p.indent()
    generateProtoNameProviding(printer: &p)
    if let storage = storage {
      p.print("\n")
      storage.generateTypeDeclaration(printer: &p)
      p.print("\n")
      storage.generateUniqueStroage(printer: &p)
    }
    p.print("\n")
    generateMessageImplementationBase(printer: &p)
    p.outdent()
    p.print("}\n")

    // Nested enums and messages
    for e in enums {
      e.generateRuntimeSupport(printer: &p)
    }
    for m in messages {
      m.generateRuntimeSupport(printer: &p, file: file, parent: self)
    }
  }

  private func generateProtoNameProviding(printer p: inout CodePrinter) {
    if fields.isEmpty {
      p.print("\(visibility)static let _protobuf_nameMap = SwiftProtobuf._NameMap()\n")
    } else {
      p.print("\(visibility)static let _protobuf_nameMap: SwiftProtobuf._NameMap = [\n")
      p.indent()
      for f in fields {
        p.print("\(f.number): \(f.fieldMapNames),\n")
      }
      p.outdent()
      p.print("]\n")
    }
  }


  /// Generates the `decodeMessage` method for the message.
  ///
  /// - Parameter p: The code printer.
  private func generateDecodeMessage(printer p: inout CodePrinter) {
    p.print(
      "/// Used by the decoding initializers in the SwiftProtobuf library, not generally\n",
      "/// used directly. `init(serializedData:)`, `init(jsonUTF8Data:)`, and other decoding\n",
      "/// initializers are defined in the SwiftProtobuf library. See the Message and\n",
      "/// Message+*Additions` files.\n")
    p.print("\(visibility)mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {\n")
    p.indent()
    if storage != nil {
      p.print("_ = _uniqueStorage()\n")
    }
    let varName: String
    if fields.isEmpty && !isExtensible {
      varName = "_"
    } else {
      varName = "fieldNumber"
    }
    generateWithLifetimeExtension(printer: &p, throws: true) { p in
      p.print("while let \(varName) = try decoder.nextFieldNumber() {\n")
      p.indent()
      if !fields.isEmpty {
        p.print("switch fieldNumber {\n")
        for f in fieldsSortedByNumber {
          f.generateDecodeFieldCase(printer: &p)
        }
        if isExtensible {
          p.print("case \(descriptor.swiftExtensionRangeExpressions):\n")
          p.indent()
          p.print("try decoder.decodeExtensionField(values: &_protobuf_extensionFieldValues, messageType: \(swiftRelativeName).self, fieldNumber: fieldNumber)\n")
          p.outdent()
        }
        p.print("default: break\n")
      } else if isExtensible {
        // Just output a simple if-statement if the message had no fields of its
        // own but we still need to generate a decode statement for extensions.
        p.print("if \(descriptor.swiftExtensionRangeBooleanExpression(variable: "fieldNumber")) {\n")
        p.indent()
        p.print("try decoder.decodeExtensionField(values: &_protobuf_extensionFieldValues, messageType: \(swiftRelativeName).self, fieldNumber: fieldNumber)\n")
        p.outdent()
        p.print("}\n")
      }
      if !fields.isEmpty {
        p.print("}\n")
      }
      p.outdent()
      p.print("}\n")
    }
    p.outdent()
    p.print("}\n")
  }

  /// Generates the `traverse` method for the message.
  ///
  /// - Parameter p: The code printer.
  private func generateTraverse(printer p: inout CodePrinter) {
    p.print(
      "/// Used by the encoding methods of the SwiftProtobuf library, not generally\n",
      "/// used directly. `Message.serializedData()`, `Message.jsonUTF8Data()`, and\n",
      "/// other serializer methods are defined in the SwiftProtobuf library. See the\n",
      "/// `Message` and `Message+*Additions` files.\n")
    p.print("\(visibility)func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {\n")
    p.indent()
    generateWithLifetimeExtension(printer: &p, throws: true) { p in
      if let storage = storage {
        storage.generatePreTraverse(printer: &p)
      }
      var ranges = descriptor.extensionRanges.makeIterator()
      var nextRange = ranges.next()
      for f in fieldsSortedByNumber {
        while nextRange != nil && Int(nextRange!.start) < f.number {
          p.print("try visitor.visitExtensionFields(fields: _protobuf_extensionFieldValues, start: \(nextRange!.start), end: \(nextRange!.end))\n")
          nextRange = ranges.next()
        }
        f.generateTraverse(printer: &p)
      }
      while nextRange != nil {
        p.print("try visitor.visitExtensionFields(fields: _protobuf_extensionFieldValues, start: \(nextRange!.start), end: \(nextRange!.end))\n")
        nextRange = ranges.next()
      }
    }
    p.print("try unknownFields.traverse(visitor: &visitor)\n")
    p.outdent()
    p.print("}\n")
  }

  private func generateMessageImplementationBase(printer p: inout CodePrinter) {
    p.print("\(visibility)func _protobuf_generated_isEqualTo(other: \(swiftFullName)) -> Bool {\n")
    p.indent()
    var compareFields = true
    if let storage = storage {
      p.print("if _storage !== other._storage {\n")
      p.indent()
      p.print("let storagesAreEqual: Bool = ")
      if storage.storageProvidesEqualTo {
        p.print("_storage.isEqualTo(other: other._storage)\n")
        compareFields = false
      }
    }
    if compareFields {
      generateWithLifetimeExtension(printer: &p,
                                    alsoCapturing: "other") { p in
        for f in fields {
          f.generateFieldComparison(printer: &p)
        }
        if storage != nil {
          p.print("return true\n")
        }
      }
    }
    if storage != nil {
      p.print("if !storagesAreEqual {return false}\n")
      p.outdent()
      p.print("}\n")
    }
    p.print("if unknownFields != other.unknownFields {return false}\n")
    if isExtensible {
      p.print("if _protobuf_extensionFieldValues != other._protobuf_extensionFieldValues {return false}\n")
    }
    p.print("return true\n")
    p.outdent()
    p.print("}\n")
  }

  /// Generates the `isInitialized` property for the message, if needed.
  ///
  /// This may generate nothing, if the `isInitialized` property is not
  /// needed.
  ///
  /// - Parameter printer: The code printer.
  private func generateIsInitialized(printer p: inout CodePrinter) {

    var fieldCheckPrinter = CodePrinter()

    // The check is done in two passes, so a missing required field can fail
    // faster without recursing through the message fields to ensure they are
    // initialized.

    if descriptor.file.syntax == .proto2 {
      // Only proto2 syntax can have field presence (required fields); ensure required
      // fields have values.
      for f in fields {
        f.generateRequiredFieldCheck(printer: &fieldCheckPrinter)
      }
    }

    for f in fields {
      f.generateIsInitializedCheck(printer: &fieldCheckPrinter)
    }

    let generatedChecks = !fieldCheckPrinter.isEmpty

    if !isExtensible && !generatedChecks {
      // No need to generate isInitialized.
      return
    }

    p.print(
        "\n",
        "public var isInitialized: Bool {\n")
    p.indent()
    if isExtensible {
      p.print("if !_protobuf_extensionFieldValues.isInitialized {return false}\n")
    }
    if generatedChecks {
      generateWithLifetimeExtension(printer: &p, returns: true) { p in
        p.print(fieldCheckPrinter.content)
        p.print("return true\n")
      }
    } else {
      p.print("return true\n")
    }
    p.outdent()
    p.print("}\n")
  }

  /// Executes the given closure, wrapping the code that it prints in a call
  /// to `withExtendedLifetime` for the storage object if the message uses
  /// one.
  ///
  /// - Parameter p: The code printer.
  /// - Parameter canThrow: Indicates whether the code that will be printed
  ///   inside the block can throw; if so, the printed call to
  ///   `withExtendedLifetime` will be preceded by `try`.
  /// - Parameter returns: Indicates whether the code that will be printed
  ///   inside the block returns a value; if so, the printed call to
  ///   `withExtendedLifetime` will be preceded by `return`.
  /// - Parameter capturedVariable: The name of another variable (which is
  ///   assumed to be the same type as `self`) whose storage should also be
  ///   captured (used for equality testing, where two messages are operated
  ///   on simultaneously).
  /// - Parameter body: A closure that takes the code printer as its sole
  ///   `inout` argument.
  private func generateWithLifetimeExtension(
    printer p: inout CodePrinter,
    throws canThrow: Bool = false,
    returns: Bool = false,
    alsoCapturing capturedVariable: String? = nil,
    body: (inout CodePrinter) -> Void
  ) {
    if storage != nil {
      let prefixKeywords = "\(returns ? "return " : "")" +
        "\(canThrow ? "try " : "")"

      let actualArgs: String
      let formalArgs: String
      if let capturedVariable = capturedVariable {
        actualArgs = "(_storage, \(capturedVariable)._storage)"
        formalArgs = "(_storage, \(capturedVariable)_storage)"
      } else {
        actualArgs = "_storage"
        // The way withExtendedLifetime is defined causes ambiguities in the
        // singleton argument case, which we have to resolve by writing out
        // the explicit type of the closure argument.
        formalArgs = "(_storage: _StorageClass)"
      }
      p.print(prefixKeywords +
        "withExtendedLifetime(\(actualArgs)) { \(formalArgs) in\n")
      p.indent()
    }

    body(&p)

    if storage != nil {
      p.outdent()
      p.print("}\n")
    }
  }
}

fileprivate func hasSingleMessageField(descriptor: Descriptor) -> Bool {
  let result = descriptor.fields.contains {
    // Repeated check also rules out maps.
    ($0.type == .message || $0.type == .group) && $0.label != .repeated
  }
  return result
}

fileprivate struct MessageFieldFactory {
  private let generatorOptions: GeneratorOptions
  private let namer: SwiftProtobufNamer
  private let useHeapStorage: Bool
  private let oneofs: [OneofGenerator]

  init(
    generatorOptions: GeneratorOptions,
    namer: SwiftProtobufNamer,
    useHeapStorage: Bool,
    oneofGenerators: [OneofGenerator]
  ) {
    self.generatorOptions = generatorOptions
    self.namer = namer
    self.useHeapStorage = useHeapStorage
    oneofs = oneofGenerators
  }

  func make(forFieldDescriptor field: FieldDescriptor) -> FieldGenerator {
    if let oneofIndex = field.oneofIndex {
      return oneofs[Int(oneofIndex)].fieldGenerator(forFieldNumber: Int(field.number))
    } else {
      return MessageFieldGenerator(descriptor: field,
                                   generatorOptions: generatorOptions,
                                   namer: namer,
                                   usesHeapStorage: useHeapStorage)
    }
  }
}
