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
import SwiftProtobuf
import SwiftProtobufPluginLibrary

class MessageGenerator {
    private let descriptor: Descriptor
    private let generatorOptions: GeneratorOptions
    private let namer: SwiftProtobufNamer
    private let visibility: String
    private let swiftFullName: String
    private let swiftRelativeName: String
    private let fields: [any FieldGenerator]
    private let fieldsSortedByNumber: [any FieldGenerator]
    private let oneofs: [OneofGenerator]
    private let enums: [EnumGenerator]
    private let messages: [MessageGenerator]
    private let mapEntries: [String: MapEntryGenerator]
    private let messageSchemaCalculator: MessageSchemaCalculator
    private let compressedReflectionData: String

    init(
        descriptor: Descriptor,
        generatorOptions: GeneratorOptions,
        namer: SwiftProtobufNamer,
        extensionSet: ExtensionSetGenerator
    ) {
        self.descriptor = descriptor
        self.generatorOptions = generatorOptions
        self.namer = namer

        if descriptor.fullName == "swift_protobuf.ImplicitWeakMessage" {
            visibility = ""
        } else {
            visibility = generatorOptions.visibilitySourceSnippet
        }
        swiftRelativeName = namer.relativeName(message: descriptor)
        swiftFullName = namer.fullName(message: descriptor)

        oneofs = descriptor.realOneofs.map {
            OneofGenerator(
                descriptor: $0,
                generatorOptions: generatorOptions,
                namer: namer
            )
        }

        let factory = MessageFieldFactory(
            generatorOptions: generatorOptions,
            namer: namer,
            oneofGenerators: oneofs
        )
        fields = descriptor.fields.map {
            factory.make(forFieldDescriptor: $0)
        }
        fieldsSortedByNumber = fields.sorted { $0.number < $1.number }

        extensionSet.add(extensionFields: descriptor.extensions)

        enums = descriptor.enums.map {
            EnumGenerator.makeEnumGenerator(descriptor: $0, generatorOptions: generatorOptions, namer: namer)
        }

        messages = descriptor.messages.filter { !$0.options.mapEntry }.map {
            MessageGenerator(
                descriptor: $0,
                generatorOptions: generatorOptions,
                namer: namer,
                extensionSet: extensionSet
            )
        }

        // Since map entry schemas contain a synthesized name based on the name of the
        // field, this dictionary will always contain unique entries for the map fields
        // that were found in the descriptor.
        mapEntries = Dictionary(
            uniqueKeysWithValues: descriptor.fields.filter(\.isMap).map {
                let entryGenerator = MapEntryGenerator(
                    descriptor: $0.messageType,
                    generatorOptions: generatorOptions,
                    namer: namer
                )
                return (entryGenerator.entrySchemaName, entryGenerator)
            }
        )

        let extensibilityMode: ExtensibilityMode
        if descriptor.useMessageSetWireFormat {
            extensibilityMode = .messageSet
        } else if !descriptor.messageExtensionRanges.isEmpty {
            extensibilityMode = .extensible
        } else {
            extensibilityMode = .nonextensible
        }
        self.messageSchemaCalculator = MessageSchemaCalculator(
            fullyQualifiedName: generatorOptions.experimentalHiddenNames.contains(.types) ? "" : descriptor.fullName,
            fieldsSortedByNumber: fieldsSortedByNumber,
            extensibilityMode: extensibilityMode
        )
        // TODO: Look at using sortAndMergeContinuous like we do for extension ranges to potentially
        // shrink them further.
        self.compressedReflectionData = ReflectionTableCalculator(
            fields: fieldsSortedByNumber,
            reservedRanges: descriptor.reservedRanges,
            reservedNames: descriptor.reservedNames,
            suppressNames: generatorOptions.experimentalHiddenNames.contains(.fields)
        ).stringLiteral()
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
                errorString =
                    "\(e.containingType.fullName) has the option message_set_wire_format but \(e.fullName) is a non message extension field."
                return
            }
            guard !e.isRequired && !e.isRepeated else {
                errorString =
                    "\(e.containingType.fullName) has the option message_set_wire_format but \(e.fullName) cannot be required nor repeated extension field."
                return
            }
        }

        var conformances = [String]()

        // `Sendable` conformance for generated messages is unchecked because the `MessageStorage`
        // property is a class type with mutable state. However, the generated code ensures that
        // there are no data races because it uses `isKnownUniquelyReferenced` to implement
        // copy-on-write behavior.
        conformances.append("@unchecked Swift.Sendable")

        p.print(
            "",
            "\(descriptor.protoSourceCommentsWithDeprecation(generatorOptions: generatorOptions))\(visibility)nonisolated struct \(swiftRelativeName): \(conformances.joined(separator: ", ")) {"
        )
        p.withIndentation { p in
            p.print(
                """
                // \(namer.swiftProtobufModuleName).Message conformance is added in an extension below. See the
                // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
                // methods supported on all messages.
                """
            )

            for f in fields {
                f.generateInterface(printer: &p)
            }

            for o in oneofs {
                o.generateMainEnum(printer: &p)
            }

            // Nested enums
            for e in enums {
                e.generateTypeDeclaration(to: &p)
            }

            // Nested messages
            for m in messages {
                m.generateMainStruct(printer: &p, parent: self, errorString: &errorString)
            }

            // Generate the default initializer. If we don't, Swift seems to sometimes
            // generate it along with others that can take public proprerties. When it
            // generates the others doesn't seem to be documented.
            p.print(
                "",
                "\(visibility)init() { self._storage = SwiftProtobuf.MessageStorage(schema: Self.messageSchema) }"
            )
            if descriptor.fullName == "swift_protobuf.ImplicitWeakMessage" {
                p.print(
                    "\(visibility)init(schema: SwiftProtobuf.MessageSchema) { self._storage = SwiftProtobuf.MessageStorage(schema: schema) }"
                )
            }

            p.print(
                "",
                "private var _storage: SwiftProtobuf.MessageStorage",
                "private mutating func _uniqueStorage() -> SwiftProtobuf.MessageStorage {"
            )
            p.withIndentation { p in
                p.print(
                    "if !isKnownUniquelyReferenced(&_storage) { _storage = _storage.copy() }",
                    "return _storage"
                )
            }
            p.print("}")
            p.print(
                "\(visibility)mutating func _protobuf_ensureUniqueStorage(accessToken: SwiftProtobuf.MessageStorageToken) { _ = _uniqueStorage() }"
            )
        }
        p.print("}")
    }

    func collectDefinedProtoFullNames(into set: inout Set<String>) {
        set.insert(descriptor.fullName)
        for e in enums {
            set.insert(e.protoFullName)
        }
        for m in messages {
            m.collectDefinedProtoFullNames(into: &set)
        }
    }

    func generateRuntimeSupport(printer p: inout CodePrinter, file: FileGenerator, parent: MessageGenerator?) {
        if generatorOptions.experimentalWeakImports {
            let getterSymbol = namer.dynamicSymbolName(
                forProtoFullName: descriptor.fullName,
                suffix: "_getMessageSchema"
            )
            let witnessSymbol = namer.dynamicSymbolName(
                forProtoFullName: descriptor.fullName,
                suffix: "_getMessageWitness"
            )
            let mapWitnessSymbol = namer.dynamicSymbolName(
                forProtoFullName: descriptor.fullName,
                suffix: "_getMapWitness"
            )
            let spiSnippet = generatorOptions.visibility == .public ? "@_spi(ForGeneratedCodeOnly)\n" : ""

            p.print(
                "",
                "nonisolated extension \(swiftFullName): \(namer.swiftProtobufModulePrefix)GeneratedMessage {"
            )
            p.withIndentation { p in
                p.print(
                    "\(visibility)static let messageSchema = \(namer.swiftProtobufModulePrefix)MessageSchema.resolveGenerated(getter: __\(getterSymbol), witnessThunk: __\(witnessSymbol), mapWitnessThunk: __\(mapWitnessSymbol))",
                    "",
                    "\(visibility)func _protobuf_messageStorage(accessToken: SwiftProtobuf.MessageStorageToken) -> Swift.AnyObject { _storage }",
                    ""
                )
            }
            p.print(
                "}",
                "",
                "\(spiSnippet)@_silgen_name(\"\(witnessSymbol)\")",
                "\(visibility)func __\(witnessSymbol)(_ out: UnsafeMutableRawPointer) {",
                "    out.assumingMemoryBound(to: (\(namer.swiftProtobufModulePrefix)MessageSchema.InvokeWitnessFunction?).self).pointee = \(namer.swiftProtobufModulePrefix)MessageWitnesses<\(swiftFullName)>.perform",
                "}",
                "",
                "\(spiSnippet)@_silgen_name(\"\(mapWitnessSymbol)\")",
                "\(visibility)func __\(mapWitnessSymbol)(_ keyKindRaw: UInt8, _ out: UnsafeMutableRawPointer) {",
                "    out.assumingMemoryBound(to: (\(namer.swiftProtobufModulePrefix)MessageSchema.InvokeWitnessFunction?).self).pointee = \(swiftFullName)._protobuf_mapWitness(for: \(namer.swiftProtobufModulePrefix)ProtobufMapKeyKind(rawValue: keyKindRaw)!)",
                "}"
            )
        } else {
            p.print(
                "",
                "nonisolated extension \(swiftFullName): \(namer.swiftProtobufModulePrefix)GeneratedMessage {"
            )
            p.withIndentation { p in
                generateMessageSchema(printer: &p)
                p.print(
                    "",
                    "\(visibility)func _protobuf_messageStorage(accessToken: SwiftProtobuf.MessageStorageToken) -> Swift.AnyObject { _storage }",
                    ""
                )
            }
            p.print("}")
        }

        // Nested enums and messages
        for e in enums {
            e.generateRuntimeSupport(printer: &p)
        }
        for m in messages {
            m.generateRuntimeSupport(printer: &p, file: file, parent: self)
        }
    }

    func generateSchemaFileContent(
        printer p: inout CodePrinter,
        extensionSet: ExtensionSetGenerator,
        definedProtoFullNames: Set<String>,
        externalReflectionSymbols: inout Set<String>
    ) {
        let symbolPrefix = namer.dynamicSymbolName(forProtoFullName: descriptor.fullName, suffix: "")
        let getterSymbol = "\(symbolPrefix)_getMessageSchema"
        let witnessSymbol = "\(symbolPrefix)_getMessageWitness"
        let reflectionSymbol = "\(symbolPrefix)_getReflection"
        let liveSupportSymbol = "\(symbolPrefix)_liveSupport"
        let submessageOrEnumFields = messageSchemaCalculator.submessageOrEnumFields
        let resolverArg =
            submessageOrEnumFields.isEmpty
            ? ""
            : ", submessageOrEnumResolver: __\(symbolPrefix)_resolveSubmessageOrEnum"
        let spiSnippet = generatorOptions.visibility == .public ? "@_spi(ForGeneratedCodeOnly)\n" : ""

        p.print(
            "",
            #"private let __\#(symbolPrefix)_schemaString: Swift.StaticString = "\#(messageSchemaCalculator.schemaLiteral)""#,
            #"private let __\#(symbolPrefix)_reflectionData: Swift.StaticString = "\#(compressedReflectionData)""#,
            "",
            "#if canImport(Darwin)",
            "private let __\(symbolPrefix)_schema = \(namer.swiftProtobufModulePrefix)MessageSchema(schema: __\(symbolPrefix)_schemaString, reflectionSymbol: \"\(reflectionSymbol)\", witnessSymbol: \"\(witnessSymbol)\"\(resolverArg), dynamicLookupThunk: __\(getterSymbol))",
            "#else",
            "private let __\(symbolPrefix)_schema = \(namer.swiftProtobufModulePrefix)MessageSchema(schema: __\(symbolPrefix)_schemaString, reflection: __\(symbolPrefix)_reflectionData, witnessSymbol: \"\(witnessSymbol)\"\(resolverArg), dynamicLookupThunk: __\(getterSymbol))",
            "#endif"
        )

        if !submessageOrEnumFields.isEmpty {
            let mapPrefix = "__\(symbolPrefix)_"
            p.print(
                "",
                "private func __\(symbolPrefix)_resolveSubmessageOrEnum(for token: \(namer.swiftProtobufModulePrefix)SubmessageOrEnumToken) -> \(namer.swiftProtobufModulePrefix)SubmessageOrEnumSchema? {"
            )
            p.withIndentation { p in
                p.print("switch token.index {")
                for field in submessageOrEnumFields {
                    generateWeakSubmessageOrEnumResolverCase(for: field, mapNamePrefix: mapPrefix, printer: &p)
                }
                p.print(
                    "default: preconditionFailure(\"invalid submessage/enum token; this is a generator bug\")",
                    "}"
                )
            }
            p.print("}")

            for field in submessageOrEnumFields {
                if case .map(let schemaName, _) = field.kind, let entryGenerator = mapEntries[schemaName] {
                    p.print()
                    entryGenerator.generateSchema(into: &p, isTopLevel: true, namePrefix: mapPrefix)
                }
            }
        }

        var referencedProtoFullNames = [String]()
        var seenProtoFullNames: Set<String> = [descriptor.fullName]
        func addReferencedProtoFullName(_ name: String) {
            if seenProtoFullNames.insert(name).inserted {
                referencedProtoFullNames.append(name)
            }
        }
        for field in submessageOrEnumFields {
            switch field.kind {
            case .enum(_, let protoFullName), .message(_, let protoFullName):
                addReferencedProtoFullName(protoFullName)
            case .map(let schemaName, _):
                if let entryGenerator = mapEntries[schemaName],
                    let valueProtoFullName = entryGenerator.referencedValueProtoFullName
                {
                    addReferencedProtoFullName(valueProtoFullName)
                }
            }
        }
        for extProtoFullName in extensionSet.referencedSubmessageAndEnumProtoFullNames(
            forContainingTypeProtoFullName: descriptor.fullName
        ) {
            addReferencedProtoFullName(extProtoFullName)
        }

        p.print(
            "",
            "\(spiSnippet)@_silgen_name(\"\(getterSymbol)\")",
            "\(visibility)func __\(getterSymbol)(_ out: UnsafeMutableRawPointer) {",
            "    out.assumingMemoryBound(to: (\(namer.swiftProtobufModulePrefix)MessageSchema?).self).pointee = __\(symbolPrefix)_schema",
            "}",
            "",
            "#if canImport(Darwin)",
            "\(spiSnippet)@_silgen_name(\"\(reflectionSymbol)\")",
            "\(visibility)func __\(reflectionSymbol)(_ out: UnsafeMutableRawPointer) {",
            "    out.assumingMemoryBound(to: (Swift.StaticString?).self).pointee = __\(symbolPrefix)_reflectionData",
            "    _ = __\(symbolPrefix)_schema",
            "}",
            "",
            "\(spiSnippet)@section(\"__TEXT,__pb_refl,regular,pure_instructions+live_support\")",
            "\(visibility)func __\(liveSupportSymbol)(_ out: UnsafeMutableRawPointer) {",
            "    out.storeBytes(",
            "        of: \(namer.swiftProtobufModulePrefix)_protobuf_resolveReflection(named:),",
            "        as: (@convention(thin) (Swift.StaticString) -> Swift.StaticString?).self",
            "    )",
            "    let p = out.assumingMemoryBound(to: \(namer.swiftProtobufModulePrefix)MessageSchema.DynamicLookupThunk.self)",
            "    p[1] = __\(reflectionSymbol)"
        )
        for (idx, protoFullName) in referencedProtoFullNames.enumerated() {
            let targetSym = namer.dynamicSymbolName(forProtoFullName: protoFullName, suffix: "_getReflection")
            if definedProtoFullNames.contains(protoFullName) {
                p.print("    p[\(idx + 2)] = __\(targetSym)")
            } else {
                externalReflectionSymbols.insert(targetSym)
                p.print("    p[\(idx + 2)] = __extern_\(targetSym)")
            }
        }
        p.print(
            "}",
            "#endif"
        )

        // Nested enums and messages
        for e in enums {
            e.generateSchemaFileContent(printer: &p)
        }
        for m in messages {
            m.generateSchemaFileContent(
                printer: &p,
                extensionSet: extensionSet,
                definedProtoFullNames: definedProtoFullNames,
                externalReflectionSymbols: &externalReflectionSymbols
            )
        }
    }

    private func generateMessageSchema(printer p: inout CodePrinter) {
        p.print(
            #"private static let _protobuf_messageSchemaString: Swift.StaticString = "\#(messageSchemaCalculator.schemaLiteral)""#
        )
        p.print(
            #"private static let _protobuf_reflectionData: Swift.StaticString = "\#(compressedReflectionData)""#
        )

        let submessageOrEnumFields = messageSchemaCalculator.submessageOrEnumFields
        p.print()
        p.print(
            "\(visibility)static let messageSchema = SwiftProtobuf.MessageSchema(schema: _protobuf_messageSchemaString, reflection: _protobuf_reflectionData, invokeWitness: SwiftProtobuf.MessageWitnesses<Self>.perform",
            newlines: false
        )
        if !submessageOrEnumFields.isEmpty {
            p.print(", submessageOrEnumResolver: _protobuf_resolveSubmessageOrEnum", newlines: false)
        }
        p.print(")")

        if !submessageOrEnumFields.isEmpty {
            p.print(
                "",
                "private static func _protobuf_resolveSubmessageOrEnum(for token: SwiftProtobuf.SubmessageOrEnumToken) -> SwiftProtobuf.SubmessageOrEnumSchema? {"
            )
            p.withIndentation { p in
                p.print("switch token.index {")
                for field in submessageOrEnumFields {
                    generateStrongSubmessageOrEnumResolverCase(for: field, printer: &p)
                }
                p.print(
                    "default: preconditionFailure(\"invalid submessage/enum token; this is a generator bug\")",
                    "}"
                )
            }
            p.print(
                "}"
            )

            // Generate map entry schemas, if any.
            for field in submessageOrEnumFields {
                if case .map(let schemaName, _) = field.kind, let entryGenerator = mapEntries[schemaName] {
                    entryGenerator.generateSchema(into: &p)
                }
            }
        }
    }

    private func generateStrongSubmessageOrEnumResolverCase(
        for field: SubmessageOrEnumField,
        printer p: inout CodePrinter
    ) {
        switch field.kind {
        case .enum(let swiftTypeName, _):
            p.print("case \(field.index): return .enum(\(swiftTypeName).enumSchema)")
        case .message(let swiftTypeName, _):
            p.print("case \(field.index): return .message(\(swiftTypeName).messageSchema)")
        case .map(let schemaName, _):
            p.print("case \(field.index): return .message(\(schemaName))")
        }
    }

    private func generateWeakSubmessageOrEnumResolverCase(
        for field: SubmessageOrEnumField,
        mapNamePrefix: String,
        printer p: inout CodePrinter
    ) {
        switch field.kind {
        case .enum(_, let protoFullName):
            let symbol = namer.dynamicSymbolName(forProtoFullName: protoFullName, suffix: "_getEnumSchema")
            p.print(
                "case \(field.index): return \(namer.swiftProtobufModulePrefix)EnumSchema.resolveLazy(named: \"\(symbol)\").map(\(namer.swiftProtobufModulePrefix)SubmessageOrEnumSchema.enum)"
            )
        case .message(_, let protoFullName):
            let symbol = namer.dynamicSymbolName(forProtoFullName: protoFullName, suffix: "_getMessageSchema")
            p.print(
                "case \(field.index): return \(namer.swiftProtobufModulePrefix)MessageSchema.resolveLazy(named: \"\(symbol)\").map(\(namer.swiftProtobufModulePrefix)SubmessageOrEnumSchema.message)"
            )
        case .map(let schemaName, let valueKind):
            let fullSchemaName = "\(mapNamePrefix)\(schemaName)"
            switch valueKind {
            case .message, .enum:
                p.print(
                    "case \(field.index): return \(fullSchemaName).map(\(namer.swiftProtobufModulePrefix)SubmessageOrEnumSchema.message)"
                )
            case .other:
                p.print("case \(field.index): return .message(\(fullSchemaName))")
            }
        }
    }

}

private struct MessageFieldFactory {
    private let generatorOptions: GeneratorOptions
    private let namer: SwiftProtobufNamer
    private let oneofs: [OneofGenerator]

    init(
        generatorOptions: GeneratorOptions,
        namer: SwiftProtobufNamer,
        oneofGenerators: [OneofGenerator]
    ) {
        self.generatorOptions = generatorOptions
        self.namer = namer
        oneofs = oneofGenerators
    }

    func make(forFieldDescriptor field: FieldDescriptor) -> any FieldGenerator {
        guard field.realContainingOneof == nil else {
            return oneofs[Int(field.oneofIndex!)].fieldGenerator(forFieldNumber: Int(field.number))
        }
        return MessageFieldGenerator(
            descriptor: field,
            generatorOptions: generatorOptions,
            namer: namer
        )
    }
}
