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
    private let isExtensible: Bool
    private let messageLayoutCalculator: MessageLayoutCalculator

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
        isExtensible = !descriptor.messageExtensionRanges.isEmpty
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
                (
                    key: $0.swiftType(namer: namer),
                    value: MapEntryGenerator(
                        descriptor: $0.messageType,
                        generatorOptions: generatorOptions,
                        namer: namer
                    )
                )
            },
            uniquingKeysWith: { old, new in
                // It doesn't matter which one we take here, since we're not going to use any of
                // the unique information (like the synthesized name of the entry message).
                old
            }
        )

        // TODO: This is where we previously selected a specific storage class for the `Any` WKT.
        // We'll need to make sure that `Any` storage is compatible with table-driven messages
        // while also supporting the special hooks we need there.

        self.messageLayoutCalculator = MessageLayoutCalculator(fieldsSortedByNumber: fieldsSortedByNumber)
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
        if isExtensible {
            conformances.append("\(namer.swiftProtobufModulePrefix)ExtensibleMessage")
        }

        // `Sendable` conformance for generated messages is unchecked because the `_MessageStorage`
        // property is a class type with mutable state. However, the generated code ensures that
        // there are no data races because it uses `isKnownUniquelyReferenced` to implement
        // copy-on-write behavior.
        conformances.append("@unchecked Sendable")

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

            // Optional extension support
            if isExtensible {
                p.print(
                    "",
                    "\(visibility)var _protobuf_extensionFieldValues: \(namer.swiftProtobufModulePrefix)ExtensionFieldValueSet {"
                )
                p.withIndentation { p in
                    p.print("get { _storage.extensionFieldValues }")
                    p.print("_modify {")
                    p.printIndented(
                        "_ = _uniqueStorage()",
                        "yield &_storage.extensionFieldValues"
                    )
                    p.print("}")
                }
                p.print("}")
            }
            if !isExtensible {
                p.print()
            }
            p.print(
                "private var _storage = SwiftProtobuf._MessageStorage(layout: Self._protobuf_messageLayout)",
                "",
                "private mutating func _uniqueStorage() -> SwiftProtobuf._MessageStorage {"
            )
            p.withIndentation { p in
                p.print(
                    "if !isKnownUniquelyReferenced(&_storage) { _storage = _storage.copy() }",
                    "return _storage"
                )
            }
            p.print("}")
            p.print(
                "\(visibility)mutating func _protobuf_ensureUniqueStorage(accessToken: SwiftProtobuf._MessageStorageToken) {"
            )
            p.printIndented("_ = _uniqueStorage()")
            p.print("}")
        }
        p.print("}")
    }

    func generateRuntimeSupport(printer p: inout CodePrinter, file: FileGenerator, parent: MessageGenerator?) {
        p.print(
            "",
            "extension \(swiftFullName): \(namer.swiftProtobufModulePrefix)Message, \(namer.swiftProtobufModulePrefix)_MessageImplementationBase, \(namer.swiftProtobufModulePrefix)_ProtoNameProviding {"
        )
        p.withIndentation { p in
            if let parent = parent {
                p.print(
                    "\(visibility)static let protoMessageName: String = \(parent.swiftFullName).protoMessageName + \".\(descriptor.name)\""
                )
            } else if !descriptor.file.package.isEmpty {
                p.print(
                    "\(visibility)static let protoMessageName: String = _protobuf_package + \".\(descriptor.name)\""
                )
            } else {
                p.print("\(visibility)static let protoMessageName: String = \"\(descriptor.name)\"")
            }
            generateProtoNameProviding(printer: &p)
            generateMessageLayout(printer: &p)
            p.print(
                "",
                "\(visibility)func _protobuf_messageStorage(accessToken: SwiftProtobuf._MessageStorageToken) -> AnyObject { _storage }",
                ""
            )
            generateIsInitialized(printer: &p)
            // generateIsInitialized provides a blank line after itself.
            generateDecodeMessage(printer: &p)
            p.print()
            generateTraverse(printer: &p)
            p.print()

            // TODO: These only need to exist while we are in the transitional state of using
            // table-driven messages for testing but needing to support the old generated WKTs and
            // plugin protos. Remove them when everything is generated table-driven.
            p.print(
                "\(visibility)func serializedBytes<Bytes: SwiftProtobufContiguousBytes>(partial: Bool = false, options: BinaryEncodingOptions = BinaryEncodingOptions()) throws -> Bytes {"
            )
            p.withIndentation { p in
                p.print("return try _storage.serializedBytes(partial: partial, options: options)")
            }
            p.print("}")
            p.print(
                "\(visibility)mutating func _merge(rawBuffer body: UnsafeRawBufferPointer, extensions: (any ExtensionMap)?, partial: Bool, options: BinaryDecodingOptions) throws {"
            )
            p.withIndentation { p in
                p.print("try _uniqueStorage().merge(byReadingFrom: body, partial: partial, options: options)")
            }
            p.print("}")

            p.print()
            generateMessageEquality(printer: &p)
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

    private func generateMessageLayout(printer p: inout CodePrinter) {
        messageLayoutCalculator.layoutLiterals.printConditionalBlocks(to: &p) { value, _, p in
            p.print(
                "@_alwaysEmitIntoClient @inline(__always)",
                #"private static var _protobuf_messageLayoutString: StaticString { "\#(value)" }"#
            )
        }

        let trampolineFields = messageLayoutCalculator.trampolineFields
        p.print()
        p.print(
            "private static let _protobuf_messageLayout = SwiftProtobuf._MessageLayout(layout: _protobuf_messageLayoutString",
            newlines: false
        )

        if trampolineFields.isEmpty {
            // If there are no trampoline fields, we can use the layout initializer that defaults
            // the trampoline functions to trapping placeholders.
            p.print(")")
        } else {
            // Otherwise, pass the static member functions that will be generated below.
            p.print(
                """
                , deinitializeField: _protobuf_deinitializeField\
                , copyField: _protobuf_copyField\
                , areFieldsEqual: _protobuf_areFieldsEqual\
                , performOnSubmessageStorage: _protobuf_performOnSubmessageStorage\
                , performOnRawEnumValues: _protobuf_performOnRawEnumValues\
                , mapEntryLayout: _protobuf_mapEntryLayout\
                )
                """
            )
            p.print(
                "",
                "private static func _protobuf_deinitializeField(for token: SwiftProtobuf._MessageLayout.TrampolineToken, field: SwiftProtobuf.FieldLayout, storage: SwiftProtobuf._MessageStorage) {"
            )
            p.withIndentation { p in
                p.print("switch token.index {")
                for field in trampolineFields {
                    p.print(
                        "case \(field.index): storage.deinitializeField(field, type: \(field.kind.name).self)"
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
                "private static func _protobuf_copyField(for token: SwiftProtobuf._MessageLayout.TrampolineToken, field: SwiftProtobuf.FieldLayout, from source: SwiftProtobuf._MessageStorage, to destination: SwiftProtobuf._MessageStorage) {"
            )
            p.withIndentation { p in
                p.print("switch token.index {")
                for field in trampolineFields {
                    p.print(
                        "case \(field.index): source.copyField(field, to: destination, type: \(field.kind.name).self)"
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
                "private static func _protobuf_areFieldsEqual(for token: SwiftProtobuf._MessageLayout.TrampolineToken, field: SwiftProtobuf.FieldLayout, lhs: SwiftProtobuf._MessageStorage, rhs: SwiftProtobuf._MessageStorage) -> Bool {"
            )
            p.withIndentation { p in
                p.print("switch token.index {")
                for field in trampolineFields {
                    p.print(
                        "case \(field.index): return lhs.isField(field, equalToSameFieldIn: rhs, type: \(field.kind.name).self)"
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
                "private static func _protobuf_performOnSubmessageStorage(for token: SwiftProtobuf._MessageLayout.TrampolineToken, field: SwiftProtobuf.FieldLayout, storage: SwiftProtobuf._MessageStorage, operation: SwiftProtobuf.TrampolineFieldOperation, perform: (SwiftProtobuf._MessageStorage) throws -> Bool) throws -> Bool {"
            )
            p.withIndentation { p in
                p.print("switch token.index {")
                for field in trampolineFields {
                    // Only submessage fields need this storage trampoline.
                    guard case .message(let name) = field.kind else { continue }
                    p.print(
                        "case \(field.index): return try storage.performOnSubmessageStorage(of: field, operation: operation, type: \(name).self, perform: perform)"
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
                "private static func _protobuf_performOnRawEnumValues(for token: SwiftProtobuf._MessageLayout.TrampolineToken, field: SwiftProtobuf.FieldLayout, storage: SwiftProtobuf._MessageStorage, operation: SwiftProtobuf.TrampolineFieldOperation, perform: (inout Int32) throws -> Bool, onInvalidValue: (Int32) -> Void) throws {"
            )
            p.withIndentation { p in
                p.print("switch token.index {")
                for field in trampolineFields {
                    // Only enum fields need this raw value trampoline.
                    guard case .enum(let name) = field.kind else { continue }
                    p.print(
                        "case \(field.index): return try storage.performOnRawEnumValues(of: field, operation: operation, type: \(name).self, perform: perform, onInvalidValue: onInvalidValue)"
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
                "private static func _protobuf_mapEntryLayout(for token: SwiftProtobuf._MessageLayout.TrampolineToken) -> StaticString {"
            )
            p.withIndentation { p in
                p.print("switch token.index {")
                for field in trampolineFields {
                    // Only map fields need this trampoline.
                    guard case .map(let name) = field.kind else { continue }
                    p.print("case \(field.index):")
                    p.withIndentation { p in
                        let entryGenerator = mapEntries[name]
                        entryGenerator?.generateLayoutReturnStatement(printer: &p)
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
        }
    }

    private func generateProtoNameProviding(printer p: inout CodePrinter) {
        var writer = ProtoNameInstructionWriter()
        for f in fieldsSortedByNumber {
            f.writeProtoNameInstruction(to: &writer)
        }
        for name in descriptor.reservedNames {
            writer.writeReservedName(name)
        }
        for range in descriptor.reservedRanges {
            writer.writeReservedNumbers(range)
        }
        if writer.shouldUseEmptyNameMapInitializer {
            p.print("\(visibility)static let _protobuf_nameMap = \(namer.swiftProtobufModulePrefix)_NameMap()")
        } else {
            p.print(
                "\(visibility)static let _protobuf_nameMap = \(namer.swiftProtobufModulePrefix)_NameMap(bytecode: \(writer.bytecode.stringLiteral))"
            )
        }
    }

    /// Generates the `decodeMessage` method for the message.
    ///
    /// - Parameter p: The code printer.
    private func generateDecodeMessage(printer p: inout CodePrinter) {
        p.print(
            "\(visibility)mutating func decodeMessage<D: \(namer.swiftProtobufModulePrefix)Decoder>(decoder: inout D) throws {"
        )
        p.withIndentation { p in
            p.print(#"fatalError("table-driven decodeMessage not yet implemented")"#)
        }
        p.print("}")
    }

    /// Generates the `traverse` method for the message.
    ///
    /// - Parameter p: The code printer.
    private func generateTraverse(printer p: inout CodePrinter) {
        p.print("\(visibility)func traverse<V: \(namer.swiftProtobufModulePrefix)Visitor>(visitor: inout V) throws {")
        p.withIndentation { p in
            p.print(#"fatalError("table-driven traverse not yet implemented")"#)
        }
        p.print("}")
    }

    private func generateMessageEquality(printer p: inout CodePrinter) {
        p.print("\(visibility)static func ==(lhs: \(swiftFullName), rhs: \(swiftFullName)) -> Bool {")
        p.withIndentation { p in
            p.print("return lhs._storage.isEqual(to: rhs._storage)")
        }
        p.print("}")
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

        p.print("public var isInitialized: Bool {")
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
