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
import SwiftProtobufPluginLibrary
import SwiftProtobuf

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

        var isGroupOrMessage: Bool {
            switch fieldDescriptor.type {
            case .group, .message:
                return true
            default:
                return false
            }
        }

        // Only valid on message fields.
        var messageType: Descriptor { return fieldDescriptor.messageType }

        init(descriptor: FieldDescriptor, namer: SwiftProtobufNamer) {
            precondition(descriptor.oneofIndex != nil)

            // Set after creation.
            oneof = nil
            group = -1

            let names = namer.messagePropertyNames(field: descriptor,
                                                   prefixed: ".",
                                                   includeHasAndClear: false)
            swiftName = names.name
            dottedSwiftName = names.prefixed
            swiftType = descriptor.swiftType(namer: namer)
            swiftDefaultValue = descriptor.swiftDefaultValue(namer: namer)
            protoGenericType = descriptor.protoGenericType
            comments = descriptor.protoSourceComments()

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

        func generateStorage(printer p: inout CodePrinter) {
            oneof.generateStorage(printer: &p, field: self)
        }

        func generateStorageClassClone(printer p: inout CodePrinter) {
            oneof.generateStorageClassClone(printer: &p, field: self)
        }

        func generateDecodeFieldCase(printer p: inout CodePrinter) {
            oneof.generateDecodeFieldCase(printer: &p, field: self)
        }

        func generateFieldComparison(printer p: inout CodePrinter) {
            oneof.generateFieldComparison(printer: &p, field: self)
        }

        func generateRequiredFieldCheck(printer p: inout CodePrinter) {
            // Oneof members are all optional, so no need to forward this.
        }

        func generateIsInitializedCheck(printer p: inout CodePrinter) {
            oneof.generateIsInitializedCheck(printer: &p, field: self)
        }

        var generateTraverseUsesLocals: Bool {
            return oneof.generateTraverseUsesLocals
        }

        func generateTraverse(printer p: inout CodePrinter) {
            oneof.generateTraverse(printer: &p, field: self)
        }
    }

    private let oneofDescriptor: OneofDescriptor
    private let generatorOptions: GeneratorOptions
    private let namer: SwiftProtobufNamer
    private let usesHeapStorage: Bool

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

    init(descriptor: OneofDescriptor, generatorOptions: GeneratorOptions, namer: SwiftProtobufNamer, usesHeapStorage: Bool) {
        precondition(!descriptor.isSynthetic)
        self.oneofDescriptor = descriptor
        self.generatorOptions = generatorOptions
        self.namer = namer
        self.usesHeapStorage = usesHeapStorage

        comments = descriptor.protoSourceComments()

        swiftRelativeName = namer.relativeName(oneof: descriptor)
        swiftFullName = namer.fullName(oneof: descriptor)
        let names = namer.messagePropertyName(oneof: descriptor)
        swiftFieldName = names.name
        underscoreSwiftFieldName = names.prefixed

        if usesHeapStorage {
            storedProperty = "_storage.\(underscoreSwiftFieldName)"
        } else {
            storedProperty = "self.\(swiftFieldName)"
        }

        fields = descriptor.fields.map {
            return MemberFieldGenerator(descriptor: $0, namer: namer)
        }
        fieldsSortedByNumber = fields.sorted {$0.number < $1.number}

        // Bucked these fields in continuous chunks based on the other fields
        // in the parent and the parent's extension ranges. Insert the `start`
        // from each extension range as an easy way to check for them being
        // mixed in between the fields.
        var parentNumbers = descriptor.containingType.fields.map { Int($0.number) }
        parentNumbers.append(contentsOf: descriptor.containingType.normalizedExtensionRanges.map { Int($0.start) })
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

    func fieldGenerator(forFieldNumber fieldNumber: Int) -> FieldGenerator {
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
            "\n",
            comments,
            "\(visibility)enum \(swiftRelativeName): Equatable {\n")
        p.indent()

        // Oneof case for each ivar
        for f in fields {
            p.print(
                f.comments,
                "case \(f.swiftName)(\(f.swiftType))\n")
        }

        // A helper for isInitialized
        let fieldsToCheck = fields.filter {
            $0.isGroupOrMessage && $0.messageType.containsRequiredFields()
        }
        if !fieldsToCheck.isEmpty {
          p.print(
              "\n",
              "fileprivate var isInitialized: Bool {\n")
          p.indent()
          if fieldsToCheck.count == 1 {
              let f = fieldsToCheck.first!
              p.print(
                  "guard case \(f.dottedSwiftName)(let v) = self else {return true}\n",
                  "return v.isInitialized\n")
          } else if fieldsToCheck.count > 1 {
              p.print(
                  "// The use of inline closures is to circumvent an issue where the compiler\n",
                  "// allocates stack space for every case branch when no optimizations are\n",
                  "// enabled. https://github.com/apple/swift-protobuf/issues/1034\n",
                  "switch self {\n")
              for f in fieldsToCheck {
                  p.print("case \(f.dottedSwiftName): return {\n")
                  p.indent()
                  p.print("guard case \(f.dottedSwiftName)(let v) = self else { preconditionFailure() }\n")
                  p.print("return v.isInitialized\n")
                  p.outdent()
                  p.print("}()\n")
              }
              // If there were other cases, add a default.
              if fieldsToCheck.count != fields.count {
                  p.print("default: return true\n")
              }
              p.print("}\n")
          }
          p.outdent()
          p.print("}\n")
        }

        // Equatable conformance
        p.print("\n")
        p.outdent()
        p.print("#if !swift(>=4.1)\n")
        p.indent()
        p.print(
            "\(visibility)static func ==(lhs: \(swiftFullName), rhs: \(swiftFullName)) -> Bool {\n")
        p.indent()
        p.print(
            "// The use of inline closures is to circumvent an issue where the compiler\n",
            "// allocates stack space for every case branch when no optimizations are\n",
            "// enabled. https://github.com/apple/swift-protobuf/issues/1034\n",
            "switch (lhs, rhs) {\n")
        for f in fields {
            p.print(
                "case (\(f.dottedSwiftName), \(f.dottedSwiftName)): return {\n")
          p.indent()
          p.print(
                "guard case \(f.dottedSwiftName)(let l) = lhs, case \(f.dottedSwiftName)(let r) = rhs else { preconditionFailure() }\n",
                "return l == r\n")
          p.outdent()
          p.print(
                "}()\n")
        }
        if fields.count > 1 {
            // A tricky edge case: If the oneof only has a single case, then
            // the case pattern generated above is exhaustive and generating a
            // default produces a compiler error. If there is more than one
            // case, then the case patterns are not exhaustive (because we
            // don't compare mismatched pairs), and we have to include a
            // default.
            p.print("default: return false\n")
        }
        p.print("}\n")
        p.outdent()
        p.print("}\n")
        p.outdent()
        p.print("#endif\n")
        p.print("}\n")
    }

    func generateSendable(printer p: inout CodePrinter) {
        // Once our minimum supported version has Data be Sendable, @unchecked could be removed.
        p.print("extension \(swiftFullName): @unchecked Sendable {}\n")
    }

    private func gerenateOneofEnumProperty(printer p: inout CodePrinter) {
        let visibility = generatorOptions.visibilitySourceSnippet
        p.print("\n", comments)

        if usesHeapStorage {
            p.print(
              "\(visibility)var \(swiftFieldName): \(swiftRelativeName)? {\n")
            p.indent()
            p.print(
              "get {return _storage.\(underscoreSwiftFieldName)}\n",
              "set {_uniqueStorage().\(underscoreSwiftFieldName) = newValue}\n")
            p.outdent()
            p.print("}\n")
        } else {
            p.print(
              "\(visibility)var \(swiftFieldName): \(swiftFullName)? = nil\n")
        }
    }

    // MARK: Things brindged from MemberFieldGenerator

    func generateInterface(printer p: inout CodePrinter, field: MemberFieldGenerator) {
        // First field causes the oneof enum to get generated.
        if field === fields.first {
          gerenateOneofEnumProperty(printer: &p)
        }

        let getter = usesHeapStorage ? "_storage.\(underscoreSwiftFieldName)" : swiftFieldName
        // Within `set` below, if the oneof name was "newValue" then it has to
        // be qualified with `self.` to avoid the collision with the setter
        // parameter.
        let setter = usesHeapStorage ? "_uniqueStorage().\(underscoreSwiftFieldName)" : (swiftFieldName == "newValue" ? "self.newValue" : swiftFieldName)

        let visibility = generatorOptions.visibilitySourceSnippet

        p.print(
          "\n",
          field.comments,
          "\(visibility)var \(field.swiftName): \(field.swiftType) {\n")
        p.indent()
        p.print("get {\n")
        p.indent()
        p.print(
          "if case \(field.dottedSwiftName)(let v)? = \(getter) {return v}\n",
          "return \(field.swiftDefaultValue)\n")
        p.outdent()
        p.print(
          "}\n",
          "set {\(setter) = \(field.dottedSwiftName)(newValue)}\n")
        p.outdent()
        p.print("}\n")
    }

    func generateStorage(printer p: inout CodePrinter, field: MemberFieldGenerator) {
        // First field causes the output.
        guard field === fields.first else { return }

        if usesHeapStorage {
            p.print("var \(underscoreSwiftFieldName): \(swiftFullName)?\n")
        } else {
            // When not using heap stroage, no extra storage is needed because
            // the public property for the oneof is the storage.
        }
    }

    func generateStorageClassClone(printer p: inout CodePrinter, field: MemberFieldGenerator) {
        // First field causes the output.
        guard field === fields.first else { return }

        p.print("\(underscoreSwiftFieldName) = source.\(underscoreSwiftFieldName)\n")
    }

    func generateDecodeFieldCase(printer p: inout CodePrinter, field: MemberFieldGenerator) {
        p.print("case \(field.number): try {\n")
        p.indent()

        let hadValueTest: String
        if field.isGroupOrMessage {
            // Messages need to fetch the current value so new fields are merged into the existing
            // value
            p.print(
              "var v: \(field.swiftType)?\n",
              "var hadOneofValue = false\n",
              "if let current = \(storedProperty) {\n")
            p.indent()
            p.print(
              "hadOneofValue = true\n",
              "if case \(field.dottedSwiftName)(let m) = current {v = m}\n")
            p.outdent()
            p.print("}\n")
            hadValueTest = "hadOneofValue"
        } else {
            p.print("var v: \(field.swiftType)?\n")
            hadValueTest = "\(storedProperty) != nil"
        }

        p.print(
          "try decoder.decodeSingular\(field.protoGenericType)Field(value: &v)\n",
          "if let v = v {\n")
        p.indent()
        p.print(
          "if \(hadValueTest) {try decoder.handleConflictingOneOf()}\n",
          "\(storedProperty) = \(field.dottedSwiftName)(v)\n")
        p.outdent()
        p.print("}\n")
        p.outdent()
        p.print("}()\n")
    }

    var generateTraverseUsesLocals: Bool { return true }

    func generateTraverse(printer p: inout CodePrinter, field: MemberFieldGenerator) {
        // First field in the group causes the output.
        let group = fieldSortedGrouped[field.group]
        guard field === group.first else { return }

        if group.count == 1 {
            p.print("try { if case \(field.dottedSwiftName)(let v)? = \(storedProperty) {\n")
            p.indent()
            p.print("try visitor.visitSingular\(field.protoGenericType)Field(value: v, fieldNumber: \(field.number))\n")
            p.outdent()
            p.print("} }()\n")
        } else {
            p.print("switch \(storedProperty) {\n")
            for f in group {
                p.print("case \(f.dottedSwiftName)?: try {\n")
                p.indent()
                p.print("guard case \(f.dottedSwiftName)(let v)? = \(storedProperty) else { preconditionFailure() }\n")
                p.print("try visitor.visitSingular\(f.protoGenericType)Field(value: v, fieldNumber: \(f.number))\n")
                p.outdent()
                p.print("}()\n")
            }
            if fieldSortedGrouped.count == 1 {
                // Cover not being set.
                p.print("case nil: break\n")
            } else {
                // Multiple groups, cover other cases (or not being set).
                p.print("default: break\n")
            }
            p.print("}\n")
        }
    }

    func generateFieldComparison(printer p: inout CodePrinter, field: MemberFieldGenerator) {
        // First field causes the output.
        guard field === fields.first else { return }

        let lhsProperty: String
        let otherStoredProperty: String
        if usesHeapStorage {
          lhsProperty = "_storage.\(underscoreSwiftFieldName)"
          otherStoredProperty = "rhs_storage.\(underscoreSwiftFieldName)"
        } else {
          lhsProperty = "lhs.\(swiftFieldName)"
          otherStoredProperty = "rhs.\(swiftFieldName)"
        }

        p.print("if \(lhsProperty) != \(otherStoredProperty) {return false}\n")
    }

    func generateIsInitializedCheck(printer p: inout CodePrinter, field: MemberFieldGenerator) {
        // First field causes the output.
        guard field === fields.first else { return }

        // Confirm there is message field with required fields.
        let firstRequired = fields.first {
            $0.isGroupOrMessage && $0.messageType.containsRequiredFields()
        }
        guard firstRequired != nil else { return }

        p.print("if let v = \(storedProperty), !v.isInitialized {return false}\n")
    }
}
