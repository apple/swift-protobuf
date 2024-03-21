// Sources/protoc-gen-swift/ExtensionSetGenerator.swift - Handle Proto2 extension
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
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
import SwiftProtobufPluginLibrary
import SwiftProtobuf

/// Provides the generation for extensions in a file.
class ExtensionSetGenerator {

    /// Private helper used for the ExtensionSetGenerator.
    private class ExtensionGenerator {
        let fieldDescriptor: FieldDescriptor
        let generatorOptions: GeneratorOptions
        let namer: SwiftProtobufNamer

        let comments: String
        let containingTypeSwiftFullName: String
        let swiftFullExtensionName: String

        var extensionFieldType: String {
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

            return "\(namer.swiftProtobufModulePrefix)\(label)\(modifier)ExtensionField"
        }

        init(descriptor: FieldDescriptor, generatorOptions: GeneratorOptions, namer: SwiftProtobufNamer) {
            self.fieldDescriptor = descriptor
            self.generatorOptions = generatorOptions
            self.namer = namer

            swiftFullExtensionName = namer.fullName(extensionField: descriptor)

            comments = descriptor.protoSourceCommentsWithDeprecation(generatorOptions: generatorOptions)
            containingTypeSwiftFullName = namer.fullName(message: fieldDescriptor.containingType)
        }

        func generateProtobufExtensionDeclarations(printer p: inout CodePrinter) {
            let visibility = generatorOptions.visibilitySourceSnippet
            let scope = fieldDescriptor.extensionScope == nil ? "" : "static "
            let traitsType = fieldDescriptor.traitsType(namer: namer)
            let swiftRelativeExtensionName = namer.relativeName(extensionField: fieldDescriptor)

            var fieldNamePath: String
            if fieldDescriptor.containingType.useMessageSetWireFormat &&
                fieldDescriptor.type == .message &&
                fieldDescriptor.label == .optional &&
                fieldDescriptor.messageType === fieldDescriptor.extensionScope {
                fieldNamePath = fieldDescriptor.messageType!.fullName
            } else {
                fieldNamePath = fieldDescriptor.fullName
            }

            p.print(
              "\(comments)\(visibility)\(scope)let \(swiftRelativeExtensionName) = \(namer.swiftProtobufModulePrefix)MessageExtension<\(extensionFieldType)<\(traitsType)>, \(containingTypeSwiftFullName)>(")
            p.printIndented(
              "_protobuf_fieldNumber: \(fieldDescriptor.number),",
              "fieldName: \"\(fieldNamePath)\"")
            p.print(")")
        }

        func generateMessageSwiftExtension(printer p: inout CodePrinter) {
            let visibility = generatorOptions.visibilitySourceSnippet
            let apiType = fieldDescriptor.swiftType(namer: namer)
            let extensionNames = namer.messagePropertyNames(extensionField: fieldDescriptor)
            let defaultValue = fieldDescriptor.swiftDefaultValue(namer: namer)

            // ExtensionSetGenerator provides the context to write out the properties.

            p.print(
              "",
              "\(comments)\(visibility)var \(extensionNames.value): \(apiType) {")
            p.printIndented(
              "get {return getExtensionValue(ext: \(swiftFullExtensionName)) ?? \(defaultValue)}",
              "set {setExtensionValue(ext: \(swiftFullExtensionName), value: newValue)}")
            p.print("}")

            // Repeated extension fields can use .isEmpty and clear by setting to the empty list.
            if fieldDescriptor.label != .repeated {
                p.print(
                    "/// Returns true if extension `\(swiftFullExtensionName)`\n/// has been explicitly set.",
                    "\(visibility)var \(extensionNames.has): Bool {")
                p.printIndented("return hasExtensionValue(ext: \(swiftFullExtensionName))")
                p.print("}")

                p.print(
                    "/// Clears the value of extension `\(swiftFullExtensionName)`.",
                    "/// Subsequent reads from it will return its default value.",
                    "\(visibility)mutating func \(extensionNames.clear)() {")
                p.printIndented("clearExtensionValue(ext: \(swiftFullExtensionName))")
                p.print("}")
            }
        }
    }

    private let fileDescriptor: FileDescriptor
    private let generatorOptions: GeneratorOptions
    private let namer: SwiftProtobufNamer

    // The order of these is as they are created, so it keeps them grouped by
    // where they were declared.
    private var extensions: [ExtensionGenerator] = []

    var isEmpty: Bool { return extensions.isEmpty }

    init(
      fileDescriptor: FileDescriptor,
      generatorOptions: GeneratorOptions,
      namer: SwiftProtobufNamer
    ) {
        self.fileDescriptor = fileDescriptor
        self.generatorOptions = generatorOptions
        self.namer = namer
    }

    func add(extensionFields: [FieldDescriptor]) {
        for e in extensionFields {
            let extensionGenerator = ExtensionGenerator(descriptor: e,
                                                        generatorOptions: generatorOptions,
                                                        namer: namer)
            extensions.append(extensionGenerator)
        }
    }

    func generateMessageSwiftExtensions(printer p: inout CodePrinter) {
        guard !extensions.isEmpty else { return }

        p.print("""

            // MARK: - Extension Properties

            // Swift Extensions on the extended Messages to add easy access to the declared
            // extension fields. The names are based on the extension field name from the proto
            // declaration. To avoid naming collisions, the names are prefixed with the name of
            // the scope where the extend directive occurs.
            """)

        // Reorder the list so they are grouped by the Message being extended, but
        // maintaining the order they were within the file within those groups.
        let grouped: [ExtensionGenerator] = extensions.enumerated().sorted {
            // When they extend the same Message, use the original order.
            if $0.element.containingTypeSwiftFullName == $1.element.containingTypeSwiftFullName {
                return $0.offset < $1.offset
            }
            // Otherwise, sort by the Message being extended.
            return $0.element.containingTypeSwiftFullName < $1.element.containingTypeSwiftFullName
        }.map {
            // Now strip off the original index to just get the list of ExtensionGenerators
            // again.
            return $0.element
        }

        // Loop through the group list and each time a new containing type is hit,
        // generate the Swift Extension block. This way there is only one Swift
        // Extension for each Message rather then one for every extension.  This make
        // the file a little easier to navigate.
        var currentType: String = ""
        for e in grouped {
            if currentType != e.containingTypeSwiftFullName {
                if !currentType.isEmpty {
                    p.outdent()
                    p.print("}")
                }
                currentType = e.containingTypeSwiftFullName
                p.print(
                  "",
                  "extension \(currentType) {")
                p.indent()
            }
            e.generateMessageSwiftExtension(printer: &p)
        }
        p.outdent()
        p.print(
          "",
          "}")
    }

    func generateFileProtobufExtensionRegistry(printer p: inout CodePrinter) {
        guard !extensions.isEmpty else { return }

        let pathParts = splitPath(pathname: fileDescriptor.name)
        let filenameAsIdentifier = NamingUtils.toUpperCamelCase(pathParts.base)
        let filePrefix = namer.typePrefix(forFile: fileDescriptor)
        p.print("""

          // MARK: - File's ExtensionMap: \(filePrefix)\(filenameAsIdentifier)_Extensions

          /// A `SwiftProtobuf.SimpleExtensionMap` that includes all of the extensions defined by
          /// this .proto file. It can be used any place an `SwiftProtobuf.ExtensionMap` is needed
          /// in parsing, or it can be combined with other `SwiftProtobuf.SimpleExtensionMap`s to create
          /// a larger `SwiftProtobuf.SimpleExtensionMap`.
          \(generatorOptions.visibilitySourceSnippet)let \(filePrefix)\(filenameAsIdentifier)_Extensions: \(namer.swiftProtobufModulePrefix)SimpleExtensionMap = [
          """)
        p.withIndentation { p in
          let lastIndex = extensions.count - 1
          for (i, e) in extensions.enumerated() {
            p.print("\(e.swiftFullExtensionName)\(i != lastIndex ? "," : "")")
          }
        }
        p.print("]")
    }

    func generateProtobufExtensionDeclarations(printer p: inout CodePrinter) {
      guard !extensions.isEmpty else { return }

      p.print("""

          // Extension Objects - The only reason these might be needed is when manually
          // constructing a `SimpleExtensionMap`, otherwise, use the above _Extension Properties_
          // accessors for the extension fields on the messages directly.
          """)

      func endScope() {
          p.outdent()
          p.print("}")
          p.outdent()
          p.print("}")
      }

      let visibility = generatorOptions.visibilitySourceSnippet
      var currentScope: Descriptor? = nil
      var addNewline = true
      for e in extensions {
        if currentScope !== e.fieldDescriptor.extensionScope {
          if currentScope != nil { endScope() }
          currentScope = e.fieldDescriptor.extensionScope
          let scopeSwiftFullName = namer.fullName(message: currentScope!)
          p.print(
            "",
            "extension \(scopeSwiftFullName) {")
          p.indent()
          p.print("\(visibility)enum Extensions {")
          p.indent()
          addNewline = false
        }

        if addNewline {
          p.print()
        } else {
          addNewline = true
        }
        e.generateProtobufExtensionDeclarations(printer: &p)
      }
      if currentScope != nil { endScope() }
    }
}
