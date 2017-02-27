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
  private let descriptor: Google_Protobuf_DescriptorProto
  private let context: Context
  private let generatorOptions: GeneratorOptions
  private let visibility: String
  private let protoFullName: String
  private let swiftFullName: String
  private let swiftRelativeName: String
  private let swiftMessageConformance: String
  private let protoMessageName: String
  private let protoPackageName: String
  private let fields: [MessageFieldGenerator]
  private let oneofs: [OneofGenerator]
  private let extensions: [ExtensionGenerator]
  private let storage: MessageStorageClassGenerator?
  private let enums: [EnumGenerator]
  private let messages: [MessageGenerator]
  private let isProto3: Bool
  private let isExtensible: Bool
  private let isGroup: Bool

  private let path: [Int32]
  private let comments: String

  init(
    descriptor: Google_Protobuf_DescriptorProto,
    path: [Int32],
    parentSwiftName: String?,
    parentProtoPath: String?,
    file: FileGenerator,
    context: Context
  ) {
    self.protoMessageName = descriptor.name
    self.context = context
    self.generatorOptions = context.options
    self.visibility = generatorOptions.visibilitySourceSnippet
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
    var conformance: [String] = []
    if isProto3 {
      conformance.append("SwiftProtobuf.Proto3Message")
    } else {
      conformance.append("SwiftProtobuf.Proto2Message")
    }
    if isExtensible {
      conformance.append("SwiftProtobuf.ExtensibleMessage")
    }
    conformance.append("SwiftProtobuf._MessageImplementationBase")
    // TODO: Move this conformance into an extension in a separate file.
    conformance.append("SwiftProtobuf._ProtoNameProviding")
    self.swiftMessageConformance = conformance.joined(separator: ", ")

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
    let useHeapStorage = fields.count > 16 ||
      hasMessageField(descriptor: descriptor, context: context)
    if useHeapStorage {
      self.storage = MessageStorageClassGenerator(
        descriptor: descriptor,
        fields: fields,
        oneofs: oneofs,
        file: file,
        messageSwiftName: swiftFullName,
        context: context)
    } else {
        self.storage = nil
    }
  }

  func generateNested(printer p: inout CodePrinter, file: FileGenerator, parent: MessageGenerator?) {
    p.print("\n")
    if comments != "" {
      p.print(comments)
    }

    p.print("\(visibility)struct \(swiftRelativeName): \(swiftMessageConformance) {\n")
    p.indent()
    p.print("\(visibility)static let protoMessageName: String = \"\(protoMessageName)\"\n")
    p.print("\(visibility)static let protoPackageName: String = \"\(protoPackageName)\"\n")

    // Map proto field names to field number
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

    if let storage = storage {
      // Storage class, if needed
      storage.generateNested(printer: &p)
      p.print("\n")
      p.print("private var _storage = _StorageClass()\n")
      p.print("\n")
      p.print("private mutating func _uniqueStorage() -> _StorageClass {\n")
      p.print("  if !isKnownUniquelyReferenced(&_storage) {\n")
      p.print("    _storage = _storage.copy()\n")
      p.print("  }\n")
      p.print("  return _storage\n")
      p.print("}\n")

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

    if !file.isProto3 {
      p.print("\n")
      p.print("\(visibility)var unknownFields = SwiftProtobuf.UnknownStorage()\n")
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

    // Generate the default initializer. If we don't, Swift seems to sometimes
    // generate it along with others that can take public proprerties. When it
    // generates the others doesn't seem to be documented.
    p.print("\n")
    p.print("\(visibility)init() {}\n")

    // isInitialized
    generateIsInitialized(printer:&p)

    p.print("\n")
    generateDecodeMessage(printer: &p)

    p.print("\n")
    generateDecodeField(printer: &p)

    p.print("\n")
    generateTraverse(printer: &p)

    p.print("\n")
    generateIsEqualTo(printer: &p)

    // Optional extension support
    if isExtensible {
      p.print("\n")
      p.print("private var _extensionFieldValues = SwiftProtobuf.ExtensionFieldValueSet()\n")
      p.print("\n")
      p.print("\(visibility)mutating func setExtensionValue<F: SwiftProtobuf.ExtensionField>(ext: SwiftProtobuf.MessageExtension<F, \(swiftRelativeName)>, value: F.ValueType) {\n")
      p.print("  _extensionFieldValues[ext.fieldNumber] = ext.set(value: value)\n")
      p.print("}\n")
      p.print("\n")
      p.print("\(visibility)mutating func clearExtensionValue<F: SwiftProtobuf.ExtensionField>(ext: SwiftProtobuf.MessageExtension<F, \(swiftRelativeName)>) {\n")
      p.print("  _extensionFieldValues[ext.fieldNumber] = nil\n")
      p.print("}\n")
      p.print("\n")
      p.print("\(visibility)func getExtensionValue<F: SwiftProtobuf.ExtensionField>(ext: SwiftProtobuf.MessageExtension<F, \(swiftRelativeName)>) -> F.ValueType {\n")
      p.print("  if let fieldValue = _extensionFieldValues[ext.fieldNumber] as? F {\n")
      p.print("    return fieldValue.value\n")
      p.print("  }\n")
      p.print("  return ext.defaultValue\n")
      p.print("}\n")
      p.print("\n")
      p.print("\(visibility)func hasExtensionValue<F: SwiftProtobuf.ExtensionField>(ext: SwiftProtobuf.MessageExtension<F, \(swiftRelativeName)>) -> Bool {\n")
      p.print("  return _extensionFieldValues[ext.fieldNumber] is F\n")
      p.print("}\n")
      p.print("\(visibility)func _protobuf_names(for number: Int) -> _NameMap.Names? {\n")
      p.print("  return \(swiftRelativeName)._protobuf_nameMap.names(for: number) ?? _extensionFieldValues._protobuf_fieldNames(for: number)\n")
      p.print("}\n")
    }

    p.outdent()
    p.print("}\n")
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

  /// Generates the `_protobuf_generated_decodeMessage` method for the message.
  ///
  /// - Parameter p: The code printer.
  private func generateDecodeMessage(printer p: inout CodePrinter) {
    p.print("\(visibility)mutating func _protobuf_generated_decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {\n")
    p.indent()
    if storage != nil {
      p.print("_ = _uniqueStorage()\n")
    }
    // We can't extend the lifetime of _storage in decodeField because it will
    // get executed for every field, instead of once per message, canceling out
    // all the benefits. Fortunately the optimizer is able to recognize that
    // this lifetime applies to the same _storage used within decodeField (even
    // though it's not passed directly in) and we avoid the extra
    // retains/releases.
    generateWithLifetimeExtension(printer: &p, throws: true) { p in
      p.print("while let fieldNumber = try decoder.nextFieldNumber() {\n")
      p.indent()
      p.print("try decodeField(decoder: &decoder, fieldNumber: fieldNumber)\n")
      p.outdent()
      p.print("}\n")
    }
    p.outdent()
    p.print("}\n")
  }

  /// Generates the `_protobuf_generated_decodeField` method for the message.
  ///
  /// - Parameter p: The code printer.
  private func generateDecodeField(printer p: inout CodePrinter) {
    p.print("\(visibility)mutating func _protobuf_generated_decodeField<D: SwiftProtobuf.Decoder>(decoder: inout D, fieldNumber: Int) throws {\n")
    p.indent()

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
            p.print("if \(storedProperty(forOneof: oneof)) != nil {\n")
            p.print("  try decoder.handleConflictingOneOf()\n")
            p.print("}\n")
            p.print("\(storedProperty(forOneof: oneof)) = try \(swiftFullName).\(oneof.swiftRelativeType)(byDecodingFrom: &decoder, fieldNumber: fieldNumber)\n")
            p.outdent()
            oneofHandled.insert(oneofIndex)
          }
        } else {
          f.generateDecodeFieldCase(printer: &p, usesStorage: storage != nil)
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

    p.outdent()
    p.print("}\n")
  }

  /// Generates the `_protobuf_generated_traverse` method for the message.
  ///
  /// - Parameter p: The code printer.
  private func generateTraverse(printer p: inout CodePrinter) {
    p.print("\(visibility)func _protobuf_generated_traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {\n")
    p.indent()
    generateWithLifetimeExtension(printer: &p, throws: true) { p in
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
            p.print("try \(storedProperty(forOneof: oneof))?.traverse(visitor: &visitor, start: \(oneofStart), end: \(oneofEnd))\n")
            currentOneof = nil
          }
          if let newOneof = f.oneof {
            oneofStart = f.number
            oneofEnd = f.number + 1
            currentOneof = newOneof
          } else {
            f.generateTraverse(printer: &p, usesStorage: storage != nil)
          }
        }
      }
      if let oneof = currentOneof {
        p.print("try \(storedProperty(forOneof: oneof))?.traverse(visitor: &visitor, start: \(oneofStart), end: \(oneofEnd))\n")
      }
      while nextRange != nil {
        p.print("try visitor.visitExtensionFields(fields: _extensionFieldValues, start: \(nextRange!.start), end: \(nextRange!.end))\n")
        nextRange = ranges.next()
      }
      if !isProto3 {
        p.print("try unknownFields.traverse(visitor: &visitor)\n")
      }
    }
    p.outdent()
    p.print("}\n")
  }

  /// Generates the `isEqualTo` method for the message.
  ///
  /// - Parameter p: The code printer.
  private func generateIsEqualTo(printer p: inout CodePrinter) {
    p.print("\(visibility)func _protobuf_generated_isEqualTo(other: \(swiftFullName)) -> Bool {\n")
    p.indent()
    generateWithLifetimeExtension(printer: &p,
                                  returns: true,
                                  alsoCapturing: "other") { p in
      // We can't short-circuit the entire equality test if the storage objects
      // have the same identity because the unknown fields and extension values
      // might still be different, but we can at least save some time by only
      // testing the individual fields in storage when they're different.
      if storage != nil {
        p.print("if _storage !== other_storage {\n")
        p.indent()
      }

      var oneofHandled = Set<Int32>()
      for f in fields {
        if let o = f.oneof {
          if !oneofHandled.contains(f.descriptor.oneofIndex) {
            p.print("if \(storedProperty(forOneof: o)) != \(storedProperty(forOneof: o, in: "other")) {return false}\n")
            oneofHandled.insert(f.descriptor.oneofIndex)
          }
        } else {
          let notEqualClause: String
          if isProto3 || f.isRepeated {
            notEqualClause = "\(storedProperty(forField: f)) != \(storedProperty(forField: f, in: "other"))"
          } else {
            notEqualClause = "\(storedProperty(forField: f)) != \(storedProperty(forField: f, in: "other"))"
          }
          p.print("if \(notEqualClause) {return false}\n")
        }
      }

      if storage != nil {
        p.outdent()
        p.print("}\n")
      }

      if !isProto3 {
        p.print("if unknownFields != other.unknownFields {return false}\n")
      }
      if isExtensible {
        p.print("if _extensionFieldValues != other._extensionFieldValues {return false}\n")
      }
      p.print("return true\n")
    }
    p.outdent()
    p.print("}\n")
  }

  /// Examines the message's members and returns a value indicating whether
  /// an `isInitialized` property needs to be printed, or if the default in
  /// the runtime library (which returns `true` unconditionally) is
  /// sufficient.
  ///
  /// - Returns: `true` if an `isInitialized` property needs to be generated.
  private func needsIsInitialized() -> Bool {
    if isExtensible {
      // Extensible messages need to generate isInitialized.
      return true
    }
    if !isProto3 {
      // Only proto2 syntax can have field presence (required fields); if any
      // fields are required, we need to generate isInitialized.
      for f in fields {
        if f.descriptor.label == .required {
          return true
        }
      }
    }
    // If any nested messages have required fields, we need to generate
    // isInitialized.
    for f in fields {
      if f.fieldHoldsMessage &&
        messageHasRequiredFields(msgTypeName:f.descriptor.typeName, context: context) {
        return true
      }
    }
    // If none of the above conditions were true, the default isInitialized,
    // which just returns true, is sufficient.
    return false
  }

  /// Generates the `isInitialized` property for the message, if needed.
  ///
  /// This may generate nothing, if the `isInitialized` property is not
  /// needed.
  ///
  /// - Parameter printer: The code printer.
  private func generateIsInitialized(printer p: inout CodePrinter) {
    guard needsIsInitialized() else {
      return
    }

    p.print("\npublic var isInitialized: Bool {\n")
    p.indent()
    generateWithLifetimeExtension(printer: &p, returns: true) { p in
      if isExtensible {
        p.print("if !_extensionFieldValues.isInitialized {return false}\n")
      }

      if !isProto3 {
        // Only proto2 syntax can have field presence (required fields); ensure required
        // fields have values.
        for f in fields {
          if f.descriptor.label == .required {
            p.print("if \(storedProperty(forField: f)) == nil {return false}\n")
          }
        }
      }

      // Check that all non-oneof embedded messages are initialized.
      for f in fields {
        if f.fieldHoldsMessage && f.oneof == nil &&
          messageHasRequiredFields(msgTypeName:f.descriptor.typeName, context: context) {
          if f.isRepeated {
            p.print("if !SwiftProtobuf.Internal.areAllInitialized(\(f.swiftName)) {return false}\n")
          } else {
            p.print("if let v = \(storedProperty(forField: f)), !v.isInitialized {return false}\n")
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

      p.print("return true\n")
    }
    p.outdent()
    p.print("}\n")
  }

  /// Returns the Swift expression used to access the actual stored property
  /// for the given field.
  ///
  /// This method has knowledge of the lifetime extension logic implemented
  /// by `generateWithLifetimeExtension` such that if the stored property is
  /// in a storage object, the proper dot-expression is returned.
  ///
  /// - Parameter field: The `MessageFieldGenerator` corresponding to the
  ///   field.
  /// - Parameter variable: The name of the variable representing the message
  ///   whose stored property should be accessed. The default value if
  ///   omitted is the empty string, which represents implicit `self`.
  /// - Returns: The Swift expression used to access the actual stored
  ///   property for the field.
  private func storedProperty(
    forField field: MessageFieldGenerator,
    in variable: String = ""
  ) -> String {
    if storage != nil {
      return "\(variable)_storage.\(field.swiftStorageName)"
    }
    let prefix = variable.isEmpty ? "" : "\(variable)."
    if field.isRepeated || field.isMap {
      return "\(prefix)\(field.swiftName)"
    }
    if !isProto3 {
      return "\(prefix)\(field.swiftStorageName)"
    }
    return "\(prefix)\(field.swiftName)"
  }

  /// Returns the Swift expression used to access the actual stored property
  /// for the given oneof.
  ///
  /// This method has knowledge of the lifetime extension logic implemented
  /// by `generateWithLifetimeExtension` such that if the stored property is
  /// in a storage object, the proper dot-expression is returned.
  ///
  /// - Parameter oneof: The oneof descriptor.
  /// - Parameter variable: The name of the variable representing the message
  ///   whose stored property should be accessed. The default value if
  ///   omitted is the empty string, which represents implicit `self`.
  /// - Returns: The Swift expression used to access the actual stored
  ///   property for the oneof.
  private func storedProperty(
    forOneof oneof: Google_Protobuf_OneofDescriptorProto,
    in variable: String = ""
  ) -> String {
    if storage != nil {
      return "\(variable)_storage._\(oneof.swiftFieldName)"
    }
    let prefix = variable.isEmpty ? "" : "\(variable)."
    return "\(prefix)\(oneof.swiftFieldName)"
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

fileprivate func hasMessageField(
  descriptor: Google_Protobuf_DescriptorProto,
  context: Context
) -> Bool {
  let hasMessageField = descriptor.field.contains {
    ($0.type == .message || $0.type == .group)
    && $0.label != .repeated
    && (context.getMessageForPath(path: $0.typeName)?.options.mapEntry != true)
  }
  return hasMessageField
}

// The logic for this check comes from google/protobuf; the C++ and Java
// generators specificly.
//
// This is a helper for generating isInitialized methods.
fileprivate func messageHasRequiredFields(
  descriptor: Google_Protobuf_DescriptorProto,
  context: Context
) -> Bool {
  var alreadySeen = Set<Google_Protobuf_DescriptorProto>()

  func hasRequiredFieldsInner(
    _ descriptor: Google_Protobuf_DescriptorProto
  ) -> Bool {
    if alreadySeen.contains(descriptor) {
      // First required thing found causes this to return true, so one can
      // assume if it is already visited, it didn't have required fields.
      return false
    }
    alreadySeen.insert(descriptor)

    // If it can support extesions, and extension could be a message with
    // required fields.
    if descriptor.extensionRange.count > 0 {
      return true
    }

    for f in descriptor.field {
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

  return hasRequiredFieldsInner(descriptor)
}

fileprivate func messageHasRequiredFields(
  msgTypeName: String,
  context: Context
) -> Bool {
  let msgDesc = context.getMessageForPath(path: msgTypeName)!
  return messageHasRequiredFields(descriptor: msgDesc, context: context)
}
