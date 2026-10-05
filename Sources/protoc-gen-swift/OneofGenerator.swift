// Sources/protoc-gen-swift/OneofGenerator.swift - Oneof handling
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// This class represents a single Oneof in the proto and generates an efficient
/// algebraic enum to store it in memory.
///
// -----------------------------------------------------------------------------
import Foundation
import SwiftProtobuf
import SwiftProtobufPluginLibrary

class OneofGenerator {
    /// Custom FieldGenerator that caches come calculated strings, and bridges
    /// all methods over to the OneofGenerator.
    class MemberFieldGenerator: FieldGeneratorBase, FieldGenerator {
        private weak var oneof: OneofGenerator!
        private(set) var group: Int

        let swiftName: String
        let dottedSwiftName: String
        let swiftType: String
        let hasExplicitDefaultValue: Bool
        let swiftDefaultValue: String
        let protoGenericType: String
        let comments: String

        var presence: FieldPresence = .oneofMember(0)

        fileprivate var oneofOffset: UInt16 {
            switch presence {
            case .hasBit:
                preconditionFailure("regular fields should be handled by MemberFieldGenerator")
            case .oneofMember(let offset):
                return offset
            }
        }

        var oneofIndex: Int? { oneof.oneofDescriptor.index }

        var isGroupOrMessage: Bool {
            switch fieldDescriptor.type {
            case .group, .message:
                return true
            default:
                return false
            }
        }

        // Only valid on message fields.
        var messageType: Descriptor? { fieldDescriptor.messageType }

        let submessageOrEnumReference: SubmessageOrEnumReference?

        init(descriptor: FieldDescriptor, generatorOptions: GeneratorOptions, namer: SwiftProtobufNamer) {
            precondition(descriptor.oneofIndex != nil)

            // Set after creation.
            oneof = nil
            group = -1

            let names = namer.messagePropertyNames(
                field: descriptor,
                prefixed: ".",
                includeHasAndClear: false
            )
            swiftName = names.name
            dottedSwiftName = names.prefixed
            swiftType = descriptor.swiftType(namer: namer)
            hasExplicitDefaultValue = descriptor.defaultValue != nil
            swiftDefaultValue = descriptor.swiftDefaultValue(namer: namer)
            protoGenericType = descriptor.protoGenericType
            comments = descriptor.protoSourceCommentsWithDeprecation(generatorOptions: generatorOptions)

            switch descriptor.type {
            case .group, .message:
                submessageOrEnumReference = .message(
                    swiftTypeName: swiftType,
                    protoFullName: descriptor.messageType!.fullName
                )
            case .enum:
                submessageOrEnumReference = .enum(
                    swiftTypeName: swiftType,
                    protoFullName: descriptor.enumType!.fullName
                )
            default:
                submessageOrEnumReference = nil
            }

            super.init(descriptor: descriptor)
        }

        func setParent(_ oneof: OneofGenerator, group: Int) {
            self.oneof = oneof
            self.group = group
        }

        // MARK: Forward all the FieldGenerator methods to the OneofGenerator

        func generateInterface(printer p: inout CodePrinter) {
            oneof.generateInterface(printer: &p, field: self)
        }
    }

    private let oneofDescriptor: OneofDescriptor
    private let generatorOptions: GeneratorOptions
    private let namer: SwiftProtobufNamer

    private let fields: [MemberFieldGenerator]
    private let fieldsSortedByNumber: [MemberFieldGenerator]
    // The fields in number order and group into ranges as they are grouped in the parent.
    private let fieldSortedGrouped: [[MemberFieldGenerator]]
    private let swiftRelativeName: String
    private let swiftFullName: String
    private let comments: String

    private let swiftFieldName: String

    init(
        descriptor: OneofDescriptor,
        generatorOptions: GeneratorOptions,
        namer: SwiftProtobufNamer
    ) {
        self.oneofDescriptor = descriptor
        self.generatorOptions = generatorOptions
        self.namer = namer

        comments = descriptor.protoSourceComments(generatorOptions: generatorOptions)

        swiftRelativeName = namer.relativeName(oneof: descriptor)
        swiftFullName = namer.fullName(oneof: descriptor)
        let names = namer.messagePropertyName(oneof: descriptor)
        swiftFieldName = names.name

        fields = descriptor.fields.map {
            MemberFieldGenerator(
                descriptor: $0,
                generatorOptions: generatorOptions,
                namer: namer
            )
        }
        fieldsSortedByNumber = fields.sorted { $0.number < $1.number }

        // Bucked these fields in continuous chunks based on the other fields
        // in the parent and the parent's extension ranges. Insert the `start`
        // from each extension range as an easy way to check for them being
        // mixed in between the fields.
        var parentNumbers = descriptor.containingType.fields.map { Int($0.number) }
        parentNumbers.append(
            contentsOf: descriptor.containingType._normalizedExtensionRanges.map { Int($0.lowerBound) }
        )
        var parentNumbersIterator = parentNumbers.sorted(by: { $0 < $1 }).makeIterator()
        var nextParentFieldNumber = parentNumbersIterator.next()
        var grouped = [[MemberFieldGenerator]]()
        var currentGroup = [MemberFieldGenerator]()
        for f in fieldsSortedByNumber {
            let nextFieldNumber = f.number
            if nextParentFieldNumber != nextFieldNumber {
                if !currentGroup.isEmpty {
                    grouped.append(currentGroup)
                    currentGroup.removeAll()
                }
                while nextParentFieldNumber != nextFieldNumber {
                    nextParentFieldNumber = parentNumbersIterator.next()
                }
            }
            currentGroup.append(f)
            nextParentFieldNumber = parentNumbersIterator.next()
        }
        if !currentGroup.isEmpty {
            grouped.append(currentGroup)
        }
        self.fieldSortedGrouped = grouped

        // Now that self is fully initialized, set the parent references.
        var group = 0
        for g in fieldSortedGrouped {
            for f in g {
                f.setParent(self, group: group)
            }
            group += 1
        }
    }

    func fieldGenerator(forFieldNumber fieldNumber: Int) -> any FieldGenerator {
        for f in fields {
            if f.number == fieldNumber {
                return f
            }
        }
        fatalError("Can't happen")
    }

    func generateMainEnum(printer p: inout CodePrinter) {
        let visibility = generatorOptions.visibilitySourceSnippet

        // Repeat the comment from the oneof to provide some context
        // to this enum we generated.
        p.print(
            "",
            "\(comments)\(visibility)nonisolated enum \(swiftRelativeName): Swift.Equatable, Swift.Sendable {"
        )
        p.withIndentation { p in
            // Oneof case for each ivar
            for f in fields {
                p.print("\(f.comments)case \(f.swiftName)(\(f.swiftType))")
            }

            if generatorOptions.experimentalWeakImports {
                generateWeakImportEquality(printer: &p)
            }
        }
        p.print("}")
    }

    private func generateWeakImportEquality(printer p: inout CodePrinter) {
        let parentMessage = namer.fullName(message: oneofDescriptor.containingType)
        let visibility = generatorOptions.visibilitySourceSnippet
        p.print(
            "",
            "\(visibility)static func == (lhs: \(swiftRelativeName), rhs: \(swiftRelativeName)) -> Bool {"
        )
        p.withIndentation { p in
            if fields.isEmpty {
                p.print("return true")
            } else {
                p.print("switch (lhs, rhs) {")
                for f in fields {
                    let comparison: String
                    switch f.rawFieldType {
                    case .group, .message:
                        comparison = "withUnsafePointer(to: l) { lPtr in withUnsafePointer(to: r) { rPtr in \(parentMessage).messageSchema.submessageSchema(for: \(f.number)).areEqual(lPtr, rPtr) } }"
                    case .enum:
                        comparison = "withUnsafePointer(to: l) { lPtr in withUnsafePointer(to: r) { rPtr in \(parentMessage).messageSchema.enumSchema(for: \(f.number)).areEqual(lPtr, rPtr) } }"
                    default:
                        comparison = "l == r"
                    }
                    p.print("case (.\(f.swiftName)(let l), .\(f.swiftName)(let r)): return \(comparison)")
                }
                if fields.count > 1 {
                    p.print("default: return false")
                }
                p.print("}")
            }
        }
        p.print("}")
    }

    private func gerenateOneofEnumProperty(printer p: inout CodePrinter, oneofOffset: UInt16) {
        let visibility = generatorOptions.visibilitySourceSnippet
        p.print(
            "",
            "\(comments)\(visibility)var \(swiftFieldName): \(swiftFullName)? {"
        )
        // TODO: Investigate whether we need to split any of these switches up for very large oneofs
        // (see https://github.com/apple/swift-protobuf/pull/1866 and other related issues).
        p.withIndentation { p in
            p.print("get {")
            p.withIndentation { p in
                p.print("let populatedField = _storage.populatedOneofMember(at: \(oneofOffset))")
                p.print("switch populatedField {")
                p.print("case 0: return nil")
                for f in fields {
                    p.print("case \(f.number): return .\(f.swiftName)(\(f.swiftName))")
                }
                p.print(
                    #"default: preconditionFailure("Internal logic error; populated oneof field \(populatedField) is not a member of this oneof")"#
                )
                p.print("}")
            }
            p.print("}")
            p.print("set {")
            p.withIndentation { p in
                p.print("switch newValue {")
                p.print("case nil: _storage.clearPopulatedOneofMember(at: \(oneofOffset))")
                for f in fields {
                    p.print("case .\(f.swiftName)(let value)?: self.\(f.swiftName) = value")
                }
                p.print("}")
            }
            p.print("}")
        }
        p.print("}")
    }

    // MARK: Things brindged from MemberFieldGenerator

    func generateInterface(printer p: inout CodePrinter, field: MemberFieldGenerator) {
        // First field causes the oneof enum to get generated.
        if field === fields.first {
            gerenateOneofEnumProperty(printer: &p, oneofOffset: field.oneofOffset)
        }

        let visibility = generatorOptions.visibilitySourceSnippet
        let oneofPresence = "(\(field.oneofOffset), \(field.number))"

        // Only generate a default value expression for the getter if the proto contained an
        // explicitly written default value (or if it is an enum field, since we don't have a
        // suitable default value in that overload).
        let defaultValueArgument: String
        switch field.rawFieldType {
        case .enum:
            defaultValueArgument = "default: \(field.swiftDefaultValue), "
        default:
            defaultValueArgument = field.hasExplicitDefaultValue ? "default: \(field.swiftDefaultValue), " : ""
        }

        // The individual member accessors manipulate the underlying storage directly.
        p.print(
            "",
            "\(field.comments)\(visibility)var \(field.swiftName): \(field.swiftType) {"
        )
        let atLabel = field.storageBucket == .stable ? "at" : "atIndex"
        let getCall: String
        let setCall: String
        switch field.storageBucket {
        case .message:
            // When weak imports are enabled, we generate different accessors
            // that delegate to a witness to initialize the default value (when
            // the field is not set). Without weak imports, we prefer the more
            // efficient approach of passing the metatype directly to the
            // runtime.
            //
            // Unlike regular message fields, setters of oneof fields already
            // delegate to the message witness to deinitialize the old value,
            // because the type of the currently populated oneof case can only
            // be known at runtime (it may be different than the field being
            // set).
            if generatorOptions.experimentalWeakImports {
                getCall = "messageValue(atIndex: \(field.storageOffsetOrIndex), fieldNumber: \(field.number), oneofPresence: \(oneofPresence))"
            } else {
                getCall = "messageValue(atIndex: \(field.storageOffsetOrIndex), oneofPresence: \(oneofPresence))"
            }
            setCall = "updateValue(\(atLabel): \(field.storageOffsetOrIndex), to: newValue, oneofPresence: \(oneofPresence))"
        case .stable where field.rawFieldType == .enum && generatorOptions.experimentalWeakImports:
            // When weak imports are enabled, we generate different accessors
            // that delegate to a witness to initialize the enum from its raw
            // value and to extract the raw value in the setter.
            getCall = "enumValue(at: \(field.storageOffsetOrIndex), fieldNumber: \(field.number), \(defaultValueArgument)oneofPresence: \(oneofPresence))"
            setCall = "updateEnumValue(at: \(field.storageOffsetOrIndex), fieldNumber: \(field.number), to: newValue, oneofPresence: \(oneofPresence))"
        default:
            getCall = "value(\(atLabel): \(field.storageOffsetOrIndex), \(defaultValueArgument)oneofPresence: \(oneofPresence))"
            setCall = "updateValue(\(atLabel): \(field.storageOffsetOrIndex), to: newValue, oneofPresence: \(oneofPresence))"
        }
        p.printIndented(
            "get { return _storage.\(getCall) }",
            "set { _uniqueStorage().\(setCall) }"
        )
        p.print("}")
    }
}
