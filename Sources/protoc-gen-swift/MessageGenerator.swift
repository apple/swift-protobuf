// Sources/protoc-gen-swift/MessageGenerator.swift - Per-message logic
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// This provides the overall support for building Swift structs to represent
/// a proto message.  In particular, this handles the copy-on-write deferred
/// for messages that require it.
///
// -----------------------------------------------------------------------------

import Foundation
import SwiftProtobufPluginLibrary
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
  private let storage: MessageStorageClassGenerator?
  private let enums: [EnumGenerator]
  private let messages: [MessageGenerator]
  private let isExtensible: Bool

  init(
    descriptor: Descriptor,
    generatorOptions: GeneratorOptions,
    namer: SwiftProtobufNamer,
    extensionSet: ExtensionSetGenerator
  ) {
    self.descriptor = descriptor
    self.generatorOptions = generatorOptions
    self.namer = namer

    visibility = generatorOptions.visibilitySourceSnippet
    isExtensible = !descriptor.extensionRanges.isEmpty
    swiftRelativeName = namer.relativeName(message: descriptor)
    swiftFullName = namer.fullName(message: descriptor)

    let useHeapStorage =
      MessageStorageDecision.shouldUseHeapStorage(descriptor: descriptor)

    oneofs = descriptor.realOneofs.map {
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

    extensionSet.add(extensionFields: descriptor.extensions)

    enums = descriptor.enums.map {
      return EnumGenerator(descriptor: $0, generatorOptions: generatorOptions, namer: namer)
    }

    messages = descriptor.messages.filter { return !$0.options.mapEntry }.map {
      return MessageGenerator(descriptor: $0,
                              generatorOptions: generatorOptions,
                              namer: namer,
                              extensionSet: extensionSet)
    }

    if descriptor.wellKnownType == .any {
      precondition(useHeapStorage)
      storage = AnyMessageStorageClassGenerator(fields: fields)
    } else if useHeapStorage {
      storage = MessageStorageClassGenerator(fields: fields)
    } else {
      storage = nil
    }
  }

  func generateMainStruct(
    printer p: inout CodePrinter,
    parent: MessageGenerator?,
    errorString: inout String?
  ) {
    // protoc does this validation; this is just here as a safety net because what is
    // generated and how the runtime works assumes this.
    if descriptor.useMessageSetWireFormat {
      guard fields.isEmpty else {
        errorString = "\(descriptor.fullName) has the option message_set_wire_format but it also has fields."
        return
      }
    }
    for e in descriptor.extensions {
      guard e.containingType.useMessageSetWireFormat else { continue }

      guard e.type == .message else {
        errorString = "\(e.containingType.fullName) has the option message_set_wire_format but \(e.fullName) is a non message extension field."
        return
      }
      guard e.isOptional else {
        errorString = "\(e.containingType.fullName) has the option message_set_wire_format but \(e.fullName) is not a \"optional\" extension field."
        return
      }
    }

    let conformances: String
    if isExtensible {
      conformances = ": \(namer.swiftProtobufModuleName).ExtensibleMessage"
    } else {
      conformances = ""
    }
    p.println(
        "",
        "\(descriptor.protoSourceComments())\(visibility)struct \(swiftRelativeName)\(conformances) {")
    p.indent()
    p.println("""
            // \(namer.swiftProtobufModuleName).Message conformance is added in an extension below. See the
            // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
            // methods supported on all messages.
            """)

    for f in fields {
      f.generateInterface(printer: &p)
    }

    p.println(
        "",
        "\(visibility)var unknownFields = \(namer.swiftProtobufModuleName).UnknownStorage()")

    for o in oneofs {
      o.generateMainEnum(printer: &p)
    }

    // Nested enums
    for e in enums {
      e.generateMainEnum(printer: &p)
    }

    // Nested messages
    for m in messages {
      m.generateMainStruct(printer: &p, parent: self, errorString: &errorString)
    }

    // Generate the default initializer. If we don't, Swift seems to sometimes
    // generate it along with others that can take public proprerties. When it
    // generates the others doesn't seem to be documented.
    p.println(
        "",
        "\(visibility)init() {}")

    // Optional extension support
    if isExtensible {
      p.println(
          "",
          "\(visibility)var _protobuf_extensionFieldValues = \(namer.swiftProtobufModuleName).ExtensionFieldValueSet()")
    }
    if let storage = storage {
      if !isExtensible {
        p.println()
      }
      p.println("\(storage.storageVisibility) var _storage = _StorageClass.defaultInstance")
    } else {
      var subMessagePrinter = CodePrinter()
      for f in fields {
        f.generateStorage(printer: &subMessagePrinter)
      }
      if !subMessagePrinter.isEmpty {
        if !isExtensible {
          p.println()
        }
        p.print(subMessagePrinter.content)
      }
    }

    p.outdent()
    p.println("}")
  }

  func generateSendable(printer p: inout CodePrinter) {
    // Once our minimum supported version has Data be Sendable, @unchecked
    // will not be needed for all messages, provided that the extension types
    // in the library are marked Sendable.
    //
    // Messages that have a storage class will always need @unchecked.
    p.println("extension \(swiftFullName): @unchecked Sendable {}")

    for o in oneofs {
      o.generateSendable(printer: &p)
    }

    for m in messages {
      m.generateSendable(printer: &p)
    }
  }

  func generateRuntimeSupport(printer p: inout CodePrinter, file: FileGenerator, parent: MessageGenerator?) {
    p.println(
        "",
        "extension \(swiftFullName): \(namer.swiftProtobufModuleName).Message, \(namer.swiftProtobufModuleName)._MessageImplementationBase, \(namer.swiftProtobufModuleName)._ProtoNameProviding {")
    p.indent()

    if let parent = parent {
      p.println("\(visibility)static let protoMessageName: String = \(parent.swiftFullName).protoMessageName + \".\(descriptor.name)\"")
    } else if !descriptor.file.package.isEmpty {
      p.println("\(visibility)static let protoMessageName: String = _protobuf_package + \".\(descriptor.name)\"")
    } else {
      p.println("\(visibility)static let protoMessageName: String = \"\(descriptor.name)\"")
    }
    generateProtoNameProviding(printer: &p)
    if let storage = storage {
      p.println()
      storage.generateTypeDeclaration(printer: &p)
      p.println()
      storage.generateUniqueStorage(printer: &p)
    }
    p.println()
    generateIsInitialized(printer:&p)
    // generateIsInitialized provides a blank line after itself.
    generateDecodeMessage(printer: &p)
    p.println()
    generateTraverse(printer: &p)
    p.println()
    generateMessageEquality(printer: &p)
    p.outdent()
    p.println("}")

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
      p.println("\(visibility)static let _protobuf_nameMap = \(namer.swiftProtobufModuleName)._NameMap()")
    } else {
      p.println("\(visibility)static let _protobuf_nameMap: \(namer.swiftProtobufModuleName)._NameMap = [")
      p.indent()
      for f in fields {
        p.println("\(f.number): \(f.fieldMapNames),")
      }
      p.outdent()
      p.println("]")
    }
  }


  /// Generates the `decodeMessage` method for the message.
  ///
  /// - Parameter p: The code printer.
  private func generateDecodeMessage(printer p: inout CodePrinter) {
    p.println("\(visibility)mutating func decodeMessage<D: \(namer.swiftProtobufModuleName).Decoder>(decoder: inout D) throws {")
    p.indent()
    if storage != nil {
      p.println("_ = _uniqueStorage()")
    }

    // protoc allows message_set_wire_format without any extension ranges; no clue what that
    // actually would mean (since message_set_wire_format can't have fields), but make sure
    // there are extensions ranges as that is what provides the extension support in the
    // rest of the generation.
    if descriptor.useMessageSetWireFormat && isExtensible {

      // MessageSet hands off the decode to the decoder to do the custom logic into the extensions.
      p.println("try decoder.decodeExtensionFieldsAsMessageSet(values: &_protobuf_extensionFieldValues, messageType: \(swiftFullName).self)")

    } else {

      let varName: String
      if fields.isEmpty && !isExtensible {
        varName = "_"
      } else {
        varName = "fieldNumber"
      }
      generateWithLifetimeExtension(printer: &p, throws: true) { p in
        p.println("while let \(varName) = try decoder.nextFieldNumber() {")
        p.indent()
        // If a message only has extensions and there are multiple extension
        // ranges, get more compact source gen by still using the `switch..case`
        // code. This also avoids typechecking performance issues if there are
        // dozens of ranges because we aren't constructing a single large
        // expression containing untyped integer literals.
        if !fields.isEmpty || descriptor.extensionRanges.count > 3 {
          p.println("""
              // The use of inline closures is to circumvent an issue where the compiler
              // allocates stack space for every case branch when no optimizations are
              // enabled. https://github.com/apple/swift-protobuf/issues/1034
              switch fieldNumber {
              """)
          for f in fieldsSortedByNumber {
            f.generateDecodeFieldCase(printer: &p)
          }
          if isExtensible {
            p.println("case \(descriptor.swiftExtensionRangeCaseExpressions):")
            p.printlnIndented("try { try decoder.decodeExtensionField(values: &_protobuf_extensionFieldValues, messageType: \(swiftFullName).self, fieldNumber: fieldNumber) }()")
          }
          p.println(
              "default: break",
              "}")
        } else if isExtensible {
          // Just output a simple if-statement if the message had no fields of its
          // own but we still need to generate a decode statement for extensions.
          p.println("if \(descriptor.swiftExtensionRangeBooleanExpression(variable: "fieldNumber")) {")
          p.printlnIndented("try decoder.decodeExtensionField(values: &_protobuf_extensionFieldValues, messageType: \(swiftFullName).self, fieldNumber: fieldNumber)")
          p.println("}")
        }
        p.outdent()
        p.println("}")
      }

    }
    p.outdent()
    p.println("}")
  }

  /// Generates the `traverse` method for the message.
  ///
  /// - Parameter p: The code printer.
  private func generateTraverse(printer p: inout CodePrinter) {
    p.println("\(visibility)func traverse<V: \(namer.swiftProtobufModuleName).Visitor>(visitor: inout V) throws {")
    p.indent()
    generateWithLifetimeExtension(printer: &p, throws: true) { p in
      if let storage = storage {
        storage.generatePreTraverse(printer: &p)
      }

      let visitExtensionsName =
        descriptor.useMessageSetWireFormat ? "visitExtensionFieldsAsMessageSet" : "visitExtensionFields"

      let usesLocals = fields.reduce(false) { $0 || $1.generateTraverseUsesLocals }
      if usesLocals {
        p.println("""
          // The use of inline closures is to circumvent an issue where the compiler
          // allocates stack space for every if/case branch local when no optimizations
          // are enabled. https://github.com/apple/swift-protobuf/issues/1034 and
          // https://github.com/apple/swift-protobuf/issues/1182
          """)
      }

      // Use the "ambitious" ranges because for visit because subranges with no
      // intermixed fields can be merged to reduce the number of calls for
      // extension visitation.
      var ranges = descriptor.ambitiousExtensionRanges.makeIterator()
      var nextRange = ranges.next()
      for f in fieldsSortedByNumber {
        while nextRange != nil && Int(nextRange!.lowerBound) < f.number {
          p.println("try visitor.\(visitExtensionsName)(fields: _protobuf_extensionFieldValues, start: \(nextRange!.lowerBound), end: \(nextRange!.upperBound))")
          nextRange = ranges.next()
        }
        f.generateTraverse(printer: &p)
      }
      while nextRange != nil {
        p.println("try visitor.\(visitExtensionsName)(fields: _protobuf_extensionFieldValues, start: \(nextRange!.lowerBound), end: \(nextRange!.upperBound))")
        nextRange = ranges.next()
      }
    }
    p.println("try unknownFields.traverse(visitor: &visitor)")
    p.outdent()
    p.println("}")
  }

  private func generateMessageEquality(printer p: inout CodePrinter) {
    p.println("\(visibility)static func ==(lhs: \(swiftFullName), rhs: \(swiftFullName)) -> Bool {")
    p.indent()
    var compareFields = true
    if let storage = storage {
      p.println("if lhs._storage !== rhs._storage {")
      p.indent()
      p.print("let storagesAreEqual: Bool = ")
      if storage.storageProvidesEqualTo {
        p.println("lhs._storage.isEqualTo(other: rhs._storage)")
        compareFields = false
      }
    }
    if compareFields {
      generateWithLifetimeExtension(printer: &p,
                                    alsoCapturing: "rhs",
                                    selfQualifier: "lhs") { p in
        for f in fields {
          f.generateFieldComparison(printer: &p)
        }
        if storage != nil {
          p.println("return true")
        }
      }
    }
    if storage != nil {
      p.println("if !storagesAreEqual {return false}")
      p.outdent()
      p.println("}")
    }
    p.println("if lhs.unknownFields != rhs.unknownFields {return false}")
    if isExtensible {
      p.println("if lhs._protobuf_extensionFieldValues != rhs._protobuf_extensionFieldValues {return false}")
    }
    p.println("return true")
    p.outdent()
    p.println("}")
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
      // Only proto2 syntax can have required fields; ensure required fields
      // have values.
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

    p.println("public var isInitialized: Bool {")
    p.indent()
    if isExtensible {
      p.println("if !_protobuf_extensionFieldValues.isInitialized {return false}")
    }
    if generatedChecks {
      generateWithLifetimeExtension(printer: &p, returns: true) { p in
        p.print(fieldCheckPrinter.content)
        p.println("return true")
      }
    } else {
      p.println("return true")
    }
    p.outdent()
    p.println(
      "}",
      "")
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
    selfQualifier qualifier: String? = nil,
    body: (inout CodePrinter) -> Void
  ) {
    if storage != nil {
      let prefixKeywords = "\(returns ? "return " : "")\(canThrow ? "try " : "")"

      let selfQualifier: String
      if let qualifier = qualifier {
        selfQualifier = "\(qualifier)."
      } else {
        selfQualifier = ""
      }

      if let capturedVariable = capturedVariable {
        // withExtendedLifetime can only pass a single argument,
        // so we have to build and deconstruct a tuple in this case:
        let actualArgs = "(\(selfQualifier)_storage, \(capturedVariable)._storage)"
        let formalArgs = "(_args: (_StorageClass, _StorageClass))"
        p.println("\(prefixKeywords)withExtendedLifetime(\(actualArgs)) { \(formalArgs) in")
        p.indent()
        p.println("let _storage = _args.0")
        p.println("let \(capturedVariable)_storage = _args.1")
      } else {
        // Single argument can be passed directly:
        p.println("\(prefixKeywords)withExtendedLifetime(\(selfQualifier)_storage) { (_storage: _StorageClass) in")
        p.indent()
      }
    }

    body(&p)

    if storage != nil {
      p.outdent()
      p.println("}")
    }
  }
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
    guard field.realContainingOneof == nil else {
      return oneofs[Int(field.oneofIndex!)].fieldGenerator(forFieldNumber: Int(field.number))
    }
    return MessageFieldGenerator(descriptor: field,
                                 generatorOptions: generatorOptions,
                                 namer: namer,
                                 usesHeapStorage: useHeapStorage)
  }
}
