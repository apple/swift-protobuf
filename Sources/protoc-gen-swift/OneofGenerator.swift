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
        let swiftDefaultValue: String
        let protoGenericType: String
        let comments: String

        var presence: FieldPresence = .oneofMember(0)

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

        var submessageTypeName: String? {
            // TODO: Implement this.
            return nil
        }

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
            swiftDefaultValue = descriptor.swiftDefaultValue(namer: namer)
            protoGenericType = descriptor.protoGenericType
            comments = descriptor.protoSourceCommentsWithDeprecation(generatorOptions: generatorOptions)

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
    private let underscoreSwiftFieldName: String
    private let storedProperty: String

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
        underscoreSwiftFieldName = names.prefixed

        storedProperty = "self.\(swiftFieldName)"

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
            "\(comments)\(visibility)enum \(swiftRelativeName): Equatable, Sendable {"
        )
        p.withIndentation { p in
            // Oneof case for each ivar
            for f in fields {
                p.print("\(f.comments)case \(f.swiftName)(\(f.swiftType))")
            }

            // A helper for isInitialized
            let fieldsToCheck = fields.filter {
                $0.isGroupOrMessage && $0.messageType!.containsRequiredFields()
            }
            if !fieldsToCheck.isEmpty {
                p.print(
                    "",
                    "fileprivate var isInitialized: Bool {"
                )
                p.withIndentation { p in
                    if fieldsToCheck.count == 1 {
                        let f = fieldsToCheck.first!
                        p.print(
                            "guard case \(f.dottedSwiftName)(let v) = self else {return true}",
                            "return v.isInitialized"
                        )
                    } else if fieldsToCheck.count > 1 {
                        p.print(
                            """
                            // The use of inline closures is to circumvent an issue where the compiler
                            // allocates stack space for every case branch when no optimizations are
                            // enabled. https://github.com/apple/swift-protobuf/issues/1034
                            switch self {
                            """
                        )
                        for f in fieldsToCheck {
                            p.print("case \(f.dottedSwiftName): return {")
                            p.printIndented(
                                "guard case \(f.dottedSwiftName)(let v) = self else { preconditionFailure() }",
                                "return v.isInitialized"
                            )
                            p.print("}()")
                        }
                        // If there were other cases, add a default.
                        if fieldsToCheck.count != fields.count {
                            p.print("default: return true")
                        }
                        p.print("}")
                    }
                }
                p.print("}")
            }
            p.print()
        }
        p.print("}")
    }

    private func gerenateOneofEnumProperty(printer p: inout CodePrinter) {
        let visibility = generatorOptions.visibilitySourceSnippet
        p.print()
        p.print(
            "\(comments)\(visibility)var \(swiftFieldName): \(swiftFullName)? = nil"
        )
    }

    // MARK: Things brindged from MemberFieldGenerator

    func generateInterface(printer p: inout CodePrinter, field: MemberFieldGenerator) {
        // First field causes the oneof enum to get generated.
        if field === fields.first {
            gerenateOneofEnumProperty(printer: &p)
        }

        let getter = swiftFieldName
        // Within `set` below, if the oneof name was "newValue" then it has to
        // be qualified with `self.` to avoid the collision with the setter
        // parameter.
        let setter = (swiftFieldName == "newValue" ? "self.newValue" : swiftFieldName)

        let visibility = generatorOptions.visibilitySourceSnippet

        p.print(
            "",
            "\(field.comments)\(visibility)var \(field.swiftName): \(field.swiftType) {"
        )
        p.withIndentation { p in
            p.print("get {")
            p.printIndented(
                "if case \(field.dottedSwiftName)(let v)? = \(getter) {return v}",
                "return \(field.swiftDefaultValue)"
            )
            p.print(
                "}",
                "set {\(setter) = \(field.dottedSwiftName)(newValue)}"
            )
        }
        p.print("}")
    }
}
