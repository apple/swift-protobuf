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
    private let mapEntries: [TrampolineFieldKey: MapEntryGenerator]
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

        // The layout calculator will distinguish trampoline indices by the type name of the field.
        // Even though the original descriptors for map entries will be one-per-field (even if a
        // particular map type occurs multiple times in the message), we key these generators by
        // type name to ensure that we coalesce them if a particular type occur multiple times.
        mapEntries = Dictionary(
            descriptor.fields.filter { $0.isMap }.map {
                let keyType = RawFieldType(fieldDescriptorType: $0.messageType!.mapKeyAndValue!.key.type)
                let valueType = RawFieldType(fieldDescriptorType: $0.messageType!.mapKeyAndValue!.value.type)
                return (
                    key: TrampolineFieldKey(
                        name: $0.swiftType(namer: namer),
                        keyType: keyType,
                        valueType: valueType
                    ),
                    value: MapEntryGenerator(
                        descriptor: $0.messageType,
                        generatorOptions: generatorOptions,
                        namer: namer
                    )
                )
            },
            uniquingKeysWith: { old, new in
                // We deduplicate if they have the same key (the same Swift dictionary type and
                // same wire formats).
                old
            }
        )

        self.messageSchemaCalculator = MessageSchemaCalculator(
            fullyQualifiedName: descriptor.fullName, fieldsSortedByNumber: fieldsSortedByNumber)
        // TODO: Look at using sortAndMergeContinuous like we do for extension ranges to potentially
        // shrink them further.
        self.compressedReflectionData = ReflectionTableCalculator(
            fields: fieldsSortedByNumber,
            reservedRanges: descriptor.reservedRanges,
            reservedNames: descriptor.reservedNames
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

            p.print(
                "",
                "\(visibility)var unknownFields: \(namer.swiftProtobufModulePrefix)UnknownStorage {"
            )
            p.withIndentation { p in
                p.print("get { _storage.unknownFields }")
                p.print("_modify {")
                p.printIndented(
                    "_ = _uniqueStorage()",
                    "yield &_storage.unknownFields"
                )
                p.print("}")
            }
            p.print("}")

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
                "\(visibility)init() {}"
            )

            p.print(
                "",
                "private var _storage = SwiftProtobuf.MessageStorage(schema: Self.messageSchema)",
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
            p.print(
                "\(visibility)func _protobuf_extensionStorageImpl() -> Swift.AnyObject { _storage.extensionStorage }"
            )
            p.print(
                "\(visibility)mutating func _protobuf_uniqueExtensionStorageImpl() -> Swift.AnyObject { _uniqueStorage().extensionStorage }"
            )
        }
        p.print("}")
    }

    func generateRuntimeSupport(printer p: inout CodePrinter, file: FileGenerator, parent: MessageGenerator?) {
        p.print(
            "",
            "extension \(swiftFullName): \(namer.swiftProtobufModulePrefix)Message {"
        )
        p.withIndentation { p in
            if let parent = parent {
                p.print(
                    "\(visibility)static let protoMessageName: Swift.String = \(parent.swiftFullName).protoMessageName + \".\(descriptor.name)\""
                )
            } else if !descriptor.file.package.isEmpty {
                p.print(
                    "\(visibility)static let protoMessageName: Swift.String = _protobuf_package + \".\(descriptor.name)\""
                )
            } else {
                p.print("\(visibility)static let protoMessageName: Swift.String = \"\(descriptor.name)\"")
            }
            generateMessageSchema(printer: &p)
            p.print(
                "",
                "\(visibility)func _protobuf_messageStorage(accessToken: SwiftProtobuf.MessageStorageToken) -> Swift.AnyObject { _storage }",
                ""
            )
            generateIsInitialized(printer: &p)
            // generateIsInitialized provides a blank line after itself.
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
        messageSchemaCalculator.schemaLiterals.printConditionalBlocks(to: &p) { value, _, p in
            p.print(
                "@_alwaysEmitIntoClient @inline(__always)",
                #"private static var _protobuf_messageSchemaString: Swift.StaticString { "\#(value)" }"#
            )
        }
        p.print(
            "@_alwaysEmitIntoClient @inline(__always)",
            #"private static var _protobuf_reflectionData: Swift.StaticString { "\#(compressedReflectionData)" }"#
        )

        let trampolineFields = messageSchemaCalculator.trampolineFields
        p.print()
        p.print(
            "\(visibility)static let messageSchema = SwiftProtobuf.MessageSchema(schema: _protobuf_messageSchemaString, reflection: _protobuf_reflectionData",
            newlines: false
        )

        if trampolineFields.isEmpty {
            // If there are no trampoline fields, we can use the schema initializer that defaults
            // the trampoline functions to trapping placeholders.
            p.print(")")
        } else {
            // Otherwise, pass the static member functions that will be generated below.
            p.print(
                """
                , performNontrivialFieldOperation: _protobuf_performNontrivialFieldOperation\
                , performOnSubmessageStorage: _protobuf_performOnSubmessageStorage\
                , performOnRawEnumValues: _protobuf_performOnRawEnumValues\
                , mapEntrySchema: _protobuf_mapEntrySchema\
                , performOnMapEntry: _protobuf_performOnMapEntry\
                )
                """
            )
            p.print(
                "",
                "private static func _protobuf_performNontrivialFieldOperation(for token: SwiftProtobuf.MessageSchema.TrampolineToken, operation: SwiftProtobuf.NontrivialFieldOperation, field: SwiftProtobuf.FieldSchema, storage: SwiftProtobuf.MessageStorage) -> Swift.Bool {"
            )
            p.withIndentation { p in
                p.print("switch token.index {")
                for field in trampolineFields {
                    p.print(
                        "case \(field.index): return storage.performNontrivialFieldOperation(operation, field: field, type: \(field.kind.name).self)"
                    )
                }
                p.print(
                    "default: preconditionFailure(\"invalid trampoline token; this is a generator bug\")",
                    "}"
                )
            }
            p.print(
                "}"
            )

            p.print(
                "",
                "private static func _protobuf_performOnSubmessageStorage(for token: SwiftProtobuf.MessageSchema.TrampolineToken, field: SwiftProtobuf.FieldSchema, storage: SwiftProtobuf.MessageStorage, operation: SwiftProtobuf.TrampolineFieldOperation, perform: (SwiftProtobuf.MessageStorage) throws -> Swift.Bool) throws -> Swift.Bool {"
            )
            p.withIndentation { p in
                p.print("switch token.index {")
                var nonMessageMapFieldIndices = [Int]()
                for field in trampolineFields {
                    // Only submessage fields and map fields with message values need this storage
                    // trampoline.
                    switch field.kind {
                    case .message, .map(_, _, valueType: .message):
                        p.print(
                            "case \(field.index): return try storage.performOnSubmessageStorage(of: field, operation: operation, type: \(field.kind.name).self, perform: perform)"
                        )
                    case .map(_, _, _):
                        nonMessageMapFieldIndices.append(field.index)
                    default:
                        break
                    }
                }
                if !nonMessageMapFieldIndices.isEmpty {
                    // This will be hit when checking isInitialized for map fields with non-message
                    // values, because that part of the runtime doesn't know what the value type of
                    // the map is. We can trivially return true in that case, and we collapse all of
                    // those cases together to shrink codegen.
                    p.print(
                        "case \(nonMessageMapFieldIndices.map(String.init).joined(separator: ", ")): return true"
                    )
                }
                p.print(
                    "default: preconditionFailure(\"invalid trampoline token; this is a generator bug\")",
                    "}"
                )
            }
            p.print(
                "}"
            )

            p.print(
                "",
                "private static func _protobuf_performOnRawEnumValues(for token: SwiftProtobuf.MessageSchema.TrampolineToken, field: SwiftProtobuf.FieldSchema, storage: SwiftProtobuf.MessageStorage, operation: SwiftProtobuf.TrampolineFieldOperation, perform: (SwiftProtobuf.EnumSchema, inout Swift.Int32) throws -> Swift.Bool, onInvalidValue: (Swift.Int32) throws -> Swift.Void) throws {"
            )
            p.withIndentation { p in
                p.print("switch token.index {")
                for field in trampolineFields {
                    // Only enum fields need this raw value trampoline.
                    guard case .enum(let singularName, _) = field.kind else { continue }
                    p.print(
                        "case \(field.index): return try storage.performOnRawEnumValues(of: field, operation: operation, type: \(field.kind.name).self, enumSchema: \(singularName).enumSchema, perform: perform, onInvalidValue: onInvalidValue)"
                    )
                }
                p.print(
                    "default: preconditionFailure(\"invalid trampoline token; this is a generator bug\")",
                    "}"
                )
            }
            p.print(
                "}"
            )

            p.print(
                "",
                "private static func _protobuf_mapEntrySchema(for token: SwiftProtobuf.MessageSchema.TrampolineToken) -> SwiftProtobuf.MessageSchema {"
            )
            p.withIndentation { p in
                p.print("switch token.index {")
                for field in trampolineFields {
                    // Only map fields need this trampoline.
                    guard case .map(let name, let keyType, let valueType) = field.kind else { continue }
                    p.print("case \(field.index):")
                    p.withIndentation { p in
                        let key = TrampolineFieldKey(
                            name: name,
                            keyType: keyType,
                            valueType: valueType
                        )
                        let entryGenerator = mapEntries[key]
                        entryGenerator?.generateSchemaReturnStatement(printer: &p)
                    }
                }
                p.print(
                    "default: preconditionFailure(\"invalid trampoline token; this is a generator bug\")",
                    "}"
                )
            }
            p.print(
                "}"
            )

            p.print(
                "",
                "private static func _protobuf_performOnMapEntry(for token: SwiftProtobuf.MessageSchema.TrampolineToken, field: SwiftProtobuf.FieldSchema, storage: SwiftProtobuf.MessageStorage, workingSpace: SwiftProtobuf.MessageStorage, operation: SwiftProtobuf.TrampolineFieldOperation, deterministicOrdering: Swift.Bool, perform: (SwiftProtobuf.MessageStorage) throws -> Swift.Bool) throws -> Swift.Bool {"
            )
            p.withIndentation { p in
                p.print("switch token.index {")
                for field in trampolineFields {
                    // Only map fields need this storage trampoline.
                    guard case .map(let name, let keyType, let valueType) = field.kind else { continue }
                    let key = TrampolineFieldKey(
                        name: name,
                        keyType: keyType,
                        valueType: valueType
                    )
                    guard let entryGenerator = mapEntries[key] else { continue }
                    p.print(
                        "case \(field.index): return try storage.performOnMapEntry(of: field, operation: operation, workingSpace: workingSpace, keyType: \(entryGenerator.keyParticipantType).self, valueType: \(entryGenerator.valueParticipantType).self, deterministicOrdering: deterministicOrdering, perform: perform)"
                    )
                }
                p.print(
                    "default: preconditionFailure(\"invalid trampoline token; this is a generator bug\")",
                    "}"
                )
            }
            p.print(
                "}"
            )
        }
        p.print("\(visibility)var messageSchema: SwiftProtobuf.MessageSchema { Self.messageSchema }")
    }

    /// Generates the `isInitialized` property for the message, if needed.
    ///
    /// This may generate nothing, if the `isInitialized` property is not
    /// needed.
    ///
    /// - Parameter printer: The code printer.
    private func generateIsInitialized(printer p: inout CodePrinter) {
        // If the message does not have any fields that need this check, don't generate it; we'll
        // use the protocol extension default.
        guard descriptor.containsRequiredFields() else {
            return
        }

        p.print("public var isInitialized: Swift.Bool {")
        p.withIndentation { p in
            p.print("return _storage.isInitialized")
        }
        p.print(
            "}",
            ""
        )
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
