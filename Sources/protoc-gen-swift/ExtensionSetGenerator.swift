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
import SwiftProtobuf
import SwiftProtobufPluginLibrary

/// Provides the generation for extensions in a file.
class ExtensionSetGenerator {

    /// Private helper used for the ExtensionSetGenerator.
    private class ExtensionGenerator: FieldGeneratorBase, FieldGenerator {
        let generatorOptions: GeneratorOptions
        let namer: SwiftProtobufNamer

        let comments: String
        let containingTypeSwiftFullName: String
        let swiftFullExtensionName: String

        var submessageOrEnumReference: SubmessageOrEnumReference?

        // For `FieldGenerator` conformance; extension fields are never oneof members.
        var oneofIndex: Int? { nil }

        // For `FieldGenerator` conformance; extension fields track presence differently so we
        // just zero it out in the field layout.
        var presence: FieldPresence {
            get { .hasBit(0) }
            set { preconditionFailure("this should be unreachable; it is a generator bug") }
        }

        init(descriptor: FieldDescriptor, generatorOptions: GeneratorOptions, namer: SwiftProtobufNamer) {
            self.generatorOptions = generatorOptions
            self.namer = namer

            swiftFullExtensionName = namer.fullName(extensionField: descriptor)

            comments = descriptor.protoSourceCommentsWithDeprecation(generatorOptions: generatorOptions)
            containingTypeSwiftFullName = namer.fullName(message: descriptor.containingType)

            switch descriptor.type {
            case .group:
                let swiftSingularType = descriptor.swiftSingularType(namer: namer)
                submessageOrEnumReference = .message(swiftSingularType)
            case .message:
                if descriptor.isMap {
                    let entrySchemaName = MapEntryGenerator.schemaName(for: descriptor.messageType!)
                    submessageOrEnumReference = .map(entrySchemaName)
                } else {
                    let swiftSingularType = descriptor.swiftSingularType(namer: namer)
                    submessageOrEnumReference = .message(swiftSingularType)
                }
            case .enum:
                let swiftSingularType = descriptor.swiftSingularType(namer: namer)
                submessageOrEnumReference = .enum(swiftSingularType)
            default:
                submessageOrEnumReference = nil
            }

            super.init(descriptor: descriptor)
        }

        func generateProtobufExtensionDeclarations(printer p: inout CodePrinter) {
            let extensionName: String
            if fieldDescriptor.containingType.useMessageSetWireFormat && fieldDescriptor.type == .message
                && (!fieldDescriptor.isRepeated && !fieldDescriptor.isRequired)
                && fieldDescriptor.messageType === fieldDescriptor.extensionScope
            {
                extensionName = fieldDescriptor.messageType!.fullName
            } else {
                extensionName = fieldDescriptor.fullName
            }

            let extensionSchemaCalculator = MessageSchemaCalculator(
                extensionField: self,
                extensionName: generatorOptions.experimentalHiddenNames.contains(.fields) ? "" : extensionName
            )
            guard let schemaLiteral = extensionSchemaCalculator.schemaLiterals.valueIfAllEqual else {
                preconditionFailure("extension field schemas should not be target-sensitive")
            }

            let visibility = generatorOptions.visibilitySourceSnippet
            let scope = fieldDescriptor.extensionScope == nil ? "" : "static "
            let swiftRelativeExtensionName = namer.relativeName(extensionField: fieldDescriptor)

            p.print(
                "\(comments)\(visibility)\(scope)let \(swiftRelativeExtensionName) = \(namer.swiftProtobufModulePrefix)ExtensionSchema("
            )
            p.withIndentation { p in
                p.print(#"schema: "\#(schemaLiteral)","#)

                // We generate these as separate functions because it increases the compiler's
                // ability to do identical function folding. For example, all extension fields that
                // extend the same message will generate identical `extendedMessageResolver`
                // closures, and the compiler/linker can merge them.
                p.print(#"extendedMessageResolver: { \#(containingTypeSwiftFullName).messageSchema }"#, newlines: false)

                // Since an extension is just a single field, there will be either zero or one of
                // these.
                if let field = extensionSchemaCalculator.submessageOrEnumFields.first {
                    let resolver: String
                    switch field.kind {
                    case .message(let name):
                        resolver = ".message(\(name).messageSchema)"
                    case .enum(let name):
                        resolver = ".enum(\(name).enumSchema)"
                    case .map:
                        preconditionFailure("unreachable; extensions cannot be map fields")
                    }
                    p.print(
                        ",",
                        "submessageOrEnumResolver: { \(resolver) }",
                        newlines: false
                    )
                }
                p.print(
                    "",
                    ")"
                )
            }
        }

        func generateInterface(printer p: inout CodePrinter) {
            let visibility = generatorOptions.visibilitySourceSnippet
            let apiType = fieldDescriptor.swiftType(namer: namer)
            let extensionNames = namer.messagePropertyNames(extensionField: fieldDescriptor)
            let defaultValue = fieldDescriptor.swiftDefaultValue(namer: namer)

            // ExtensionSetGenerator provides the context to write out the properties.
            p.print(
                "",
                "\(comments)\(visibility)var \(extensionNames.value): \(apiType) {"
            )
            p.printIndented(
                "get { _protobuf_extensionStorage().value(of: \(swiftFullExtensionName), default: \(defaultValue)) }",
                "set { _protobuf_uniqueExtensionStorage().updateValue(of: \(swiftFullExtensionName), to: newValue) }"
            )
            p.print("}")

            // Repeated extension fields can use .isEmpty and clear by setting to the empty list.
            // Everything else gets a "has" helper.
            if !fieldDescriptor.isRepeated {
                p.print(
                    "/// Returns true if extension `\(swiftFullExtensionName)`\n/// has been explicitly set.",
                    "\(visibility)var \(extensionNames.has): Bool { _protobuf_extensionStorage().hasValue(for: \(swiftFullExtensionName)) }"
                )
                p.print(
                    "/// Clears the value of extension `\(swiftFullExtensionName)`.",
                    "/// Subsequent reads from it will return its default value.",
                    "\(visibility)mutating func \(extensionNames.clear)() { _protobuf_uniqueExtensionStorage().clearValue(of: \(swiftFullExtensionName), type: \(apiType).self) }"
                )
            }
        }
    }

    private let fileDescriptor: FileDescriptor
    private let generatorOptions: GeneratorOptions
    private let namer: SwiftProtobufNamer

    // The order of these is as they are created, so it keeps them grouped by
    // where they were declared.
    private var extensions: [ExtensionGenerator] = []

    var isEmpty: Bool { extensions.isEmpty }

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
            let extensionGenerator = ExtensionGenerator(
                descriptor: e,
                generatorOptions: generatorOptions,
                namer: namer
            )
            extensions.append(extensionGenerator)
        }
    }

    func generateMessageSwiftExtensions(printer p: inout CodePrinter) {
        guard !extensions.isEmpty else { return }

        p.print(
            """

            // MARK: - Extension Properties

            // Swift Extensions on the extended Messages to add easy access to the declared
            // extension fields. The names are based on the extension field name from the proto
            // declaration. To avoid naming collisions, the names are prefixed with the name of
            // the scope where the extend directive occurs.
            """
        )

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
            $0.element
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
                    "extension \(currentType) {"
                )
                p.indent()
            }
            e.generateInterface(printer: &p)
        }
        p.outdent()
        p.print(
            "",
            "}"
        )
    }

    func generateFileProtobufExtensionRegistry(printer p: inout CodePrinter) {
        guard !extensions.isEmpty else { return }

        let pathParts = splitPath(pathname: fileDescriptor.name)
        let filenameAsIdentifier = NamingUtils.toUpperCamelCase(pathParts.base)
        let filePrefix = namer.typePrefix(forFile: fileDescriptor)
        p.print(
            """

            // MARK: - File's ExtensionMap: \(filePrefix)\(filenameAsIdentifier)_Extensions

            /// A `SwiftProtobuf.ExtensionMap` that includes all of the extensions defined by
            /// this .proto file. It can be used in parsing, or it can be combined with other
            /// `SwiftProtobuf.ExtensionMap`s to create a larger `SwiftProtobuf.ExtensionMap`.
            \(generatorOptions.visibilitySourceSnippet)let \(filePrefix)\(filenameAsIdentifier)_Extensions: \(namer.swiftProtobufModulePrefix)ExtensionMap = [
            """
        )
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

        p.print(
            """

            // Extension Objects - The only reason these might be needed is when manually
            // constructing an `ExtensionMap`. Otherwise, use the above _Extension Properties_
            // accessors for the extension fields on the messages directly.
            """
        )

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
                    "extension \(scopeSwiftFullName) {"
                )
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
