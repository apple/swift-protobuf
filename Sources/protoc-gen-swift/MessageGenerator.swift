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

        visibility = generatorOptions.visibilitySourceSnippet
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
            "\(descriptor.protoSourceCommentsWithDeprecation(generatorOptions: generatorOptions))\(visibility)struct \(swiftRelativeName): \(conformances.joined(separator: ", ")) {"
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

    func generateRuntimeSupport(printer p: inout CodePrinter, file: FileGenerator, parent: MessageGenerator?) {
        p.print(
            "",
            "extension \(swiftFullName): \(namer.swiftProtobufModulePrefix)GeneratedMessage {"
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

        // Nested enums and messages
        for e in enums {
            e.generateRuntimeSupport(printer: &p)
        }
        for m in messages {
            m.generateRuntimeSupport(printer: &p, file: file, parent: self)
        }
    }

    private func generateMessageSchema(printer p: inout CodePrinter) {
        p.print(
            #"private static let _protobuf_messageSchemaString: Swift.StaticString = "\#(messageSchemaCalculator.schemaLiteral)""#
        )
        p.print(#"private static let _protobuf_reflectionData: Swift.StaticString = "\#(compressedReflectionData)""#)

        let submessageOrEnumFields = messageSchemaCalculator.submessageOrEnumFields
        p.print()
        p.print(
            "\(visibility)static let messageSchema = SwiftProtobuf.MessageSchema(schema: _protobuf_messageSchemaString, reflection: _protobuf_reflectionData, invokeWitness: SwiftProtobuf.MessageWitnesses<Self>.perform",
            newlines: false
        )

        if submessageOrEnumFields.isEmpty {
            // If there are no submessage or enum fields, we can use the initialize that defaults it
            // to a trapping closure.
            p.print(")")
        } else {
            // Otherwise, generate the resolver.
            p.print(", submessageOrEnumResolver: _protobuf_resolveSubmessageOrEnum)")
            p.print(
                "",
                "private static func _protobuf_resolveSubmessageOrEnum(for token: SwiftProtobuf.SubmessageOrEnumToken) -> SwiftProtobuf.SubmessageOrEnumSchema {"
            )
            p.withIndentation { p in
                p.print("switch token.index {")
                for field in submessageOrEnumFields {
                    let schema: String
                    switch field.kind {
                    case .enum(let typeName):
                        schema = ".enum(\(typeName).enumSchema)"
                    case .message(let typeName):
                        schema = ".message(\(typeName).messageSchema)"
                    case .map(let schemaName):
                        schema = ".message(\(schemaName))"
                    }
                    p.print("case \(field.index): return \(schema)")
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
                if case .map(let schemaName) = field.kind, let entryGenerator = mapEntries[schemaName] {
                    entryGenerator.generateSchema(into: &p)
                }
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
