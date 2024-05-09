// Sources/protoc-gen-swift/MessageFieldGenerator.swift - Facts about a single message field
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// This code mostly handles the complex mapping between proto types and
/// the types provided by the Swift Protobuf Runtime.
///
// -----------------------------------------------------------------------------
import Foundation
import SwiftProtobufPluginLibrary
import SwiftProtobuf


class MessageFieldGenerator: FieldGeneratorBase, FieldGenerator {
    private let generatorOptions: GeneratorOptions
    private let usesHeapStorage: Bool
    private let namer: SwiftProtobufNamer

    private let hasFieldPresence: Bool
    private let swiftName: String
    private let underscoreSwiftName: String
    private let storedProperty: String
    private let swiftHasName: String
    private let swiftClearName: String
    private let swiftType: String
    private let swiftStorageType: String
    private let swiftDefaultValue: String
    private let traitsType: String
    private let comments: String

    private var isMap: Bool {return fieldDescriptor.isMap}
    private var isPacked: Bool { return fieldDescriptor.isPacked }

    // Note: this could still be a map (since those are repeated message fields
    private var isRepeated: Bool {return fieldDescriptor.isRepeated}
    private var isGroupOrMessage: Bool {
      switch fieldDescriptor.type {
      case .group, .message:
        return true
      default:
        return false
      }
    }

    init(descriptor: FieldDescriptor,
         generatorOptions: GeneratorOptions,
         namer: SwiftProtobufNamer,
         usesHeapStorage: Bool)
    {
        precondition(descriptor.realContainingOneof == nil)

        self.generatorOptions = generatorOptions
        self.usesHeapStorage = usesHeapStorage
        self.namer = namer

        hasFieldPresence = descriptor.hasPresence
        let names = namer.messagePropertyNames(field: descriptor,
                                               prefixed: "_",
                                               includeHasAndClear: hasFieldPresence)
        swiftName = names.name
        underscoreSwiftName = names.prefixed
        swiftHasName = names.has
        swiftClearName = names.clear
        swiftType = descriptor.swiftType(namer: namer)
        swiftStorageType = descriptor.swiftStorageType(namer: namer)
        swiftDefaultValue = descriptor.swiftDefaultValue(namer: namer)
        traitsType = descriptor.traitsType(namer: namer)
        comments = descriptor.protoSourceCommentsWithDeprecation(generatorOptions: generatorOptions)

        if usesHeapStorage {
            storedProperty = "_storage.\(underscoreSwiftName)"
        } else {
            storedProperty = "self.\(hasFieldPresence ? underscoreSwiftName : swiftName)"
        }

        super.init(descriptor: descriptor)
    }

    func generateStorage(printer p: inout CodePrinter) {
        let defaultValue = hasFieldPresence ? "nil" : swiftDefaultValue
        if usesHeapStorage {
            p.print("var \(underscoreSwiftName): \(swiftStorageType) = \(defaultValue)")
        } else {
          // If this field has field presence, the there is a private storage variable.
          if hasFieldPresence {
              p.print("fileprivate var \(underscoreSwiftName): \(swiftStorageType) = \(defaultValue)")
          }
        }
    }

    func generateInterface(printer p: inout CodePrinter) {
        let visibility = generatorOptions.visibilitySourceSnippet

        p.print()
        if usesHeapStorage {
            p.print("\(comments)\(visibility)var \(swiftName): \(swiftType) {")
            let defaultClause = hasFieldPresence ? " ?? \(swiftDefaultValue)" : ""
            p.printIndented(
              "get {return _storage.\(underscoreSwiftName)\(defaultClause)}",
              "set {_uniqueStorage().\(underscoreSwiftName) = newValue}")
            p.print("}")
        } else {
            if hasFieldPresence {
                p.print("\(comments)\(visibility)var \(swiftName): \(swiftType) {")
                p.printIndented(
                  "get {return \(underscoreSwiftName) ?? \(swiftDefaultValue)}",
                  "set {\(underscoreSwiftName) = newValue}")
                p.print("}")
            } else {
                p.print("\(comments)\(visibility)var \(swiftName): \(swiftStorageType) = \(swiftDefaultValue)")
            }
        }

        guard hasFieldPresence else { return }

        let immutableStoragePrefix = usesHeapStorage ? "_storage." : "self."
        p.print(
            "/// Returns true if `\(swiftName)` has been explicitly set.",
            "\(visibility)var \(swiftHasName): Bool {return \(immutableStoragePrefix)\(underscoreSwiftName) != nil}")

        let mutableStoragePrefix = usesHeapStorage ? "_uniqueStorage()." : "self."
        p.print(
            "/// Clears the value of `\(swiftName)`. Subsequent reads from it will return its default value.",
            "\(visibility)mutating func \(swiftClearName)() {\(mutableStoragePrefix)\(underscoreSwiftName) = nil}")
    }

    func generateStorageClassClone(printer p: inout CodePrinter) {
        p.print("\(underscoreSwiftName) = source.\(underscoreSwiftName)")
    }

    func generateFieldComparison(printer p: inout CodePrinter) {
        let lhsProperty: String
        let otherStoredProperty: String
        if usesHeapStorage {
            lhsProperty = "_storage.\(underscoreSwiftName)"
            otherStoredProperty = "rhs_storage.\(underscoreSwiftName)"
        } else {
            lhsProperty = "lhs.\(hasFieldPresence ? underscoreSwiftName : swiftName)"
            otherStoredProperty = "rhs.\(hasFieldPresence ? underscoreSwiftName : swiftName)"
        }

        p.print("if \(lhsProperty) != \(otherStoredProperty) {return false}")
    }

   func generateRequiredFieldCheck(printer p: inout CodePrinter) {
       guard fieldDescriptor.isRequired else { return }
       p.print("if \(storedProperty) == nil {return false}")
    }

    func generateIsInitializedCheck(printer p: inout CodePrinter) {
        guard isGroupOrMessage && fieldDescriptor.messageType!.containsRequiredFields() else { return }

        if isRepeated {  // Map or Array
            p.print("if !\(namer.swiftProtobufModulePrefix)Internal.areAllInitialized(\(storedProperty)) {return false}")
        } else {
            p.print("if let v = \(storedProperty), !v.isInitialized {return false}")
        }
    }

    func generateDecodeFieldCase(printer p: inout CodePrinter) {
        let decoderMethod: String
        let traitsArg: String
        if isMap {
            decoderMethod = "decodeMapField"
            traitsArg = "fieldType: \(traitsType).self, "
        } else {
            let modifier = isRepeated ? "Repeated" : "Singular"
            decoderMethod = "decode\(modifier)\(fieldDescriptor.protoGenericType)Field"
            traitsArg = ""
        }

        p.print("case \(number): try { try decoder.\(decoderMethod)(\(traitsArg)value: &\(storedProperty)) }()")
    }

    var generateTraverseUsesLocals: Bool {
        return !isRepeated && hasFieldPresence
    }

    func generateTraverse(printer p: inout CodePrinter) {
        let visitMethod: String
        let traitsArg: String
        if isMap {
            visitMethod = "visitMapField"
            traitsArg = "fieldType: \(traitsType).self, "
        } else {
            let modifier = isPacked ? "Packed" : isRepeated ? "Repeated" : "Singular"
            visitMethod = "visit\(modifier)\(fieldDescriptor.protoGenericType)Field"
            traitsArg = ""
        }

        let varName = hasFieldPresence ? "v" : storedProperty

        var usesLocals = false
        let conditional: String
        if isRepeated {  // Also covers maps
            conditional = "!\(varName).isEmpty"
        } else if hasFieldPresence {
            conditional = "let v = \(storedProperty)"
            usesLocals = true
        } else {
            // At this point, the fields would be a primitive type, and should only
            // be visted if it is the non default value.
            switch fieldDescriptor.type {
            case .string, .bytes:
                conditional = "!\(varName).isEmpty"
            case .float, .double:
                // https://protobuf.dev/programming-guides/proto3/#default ends with:
                //    If a float or double value is set to +0 it will not be serialized,
                //    but -0 is considered distinct and will be serialized.
                // Editions still ensures that implicit presence doesn't get a default
                // value so the hardcoded zero here is safe and mirrors the upstream
                // C++ generator:
                // https://github.com/protocolbuffers/protobuf/blob/1b06cefe337f73ca8c78c855c02f15caf6210c9b/src/google/protobuf/compiler/cpp/message.cc#L204-L209
                conditional = "\(varName).bitPattern != 0"
            default:
                conditional = "\(varName) != \(swiftDefaultValue)"
            }
        }
        assert(usesLocals == generateTraverseUsesLocals)
        let prefix = usesLocals ? "try { " : ""
        let suffix = usesLocals ? " }()" : ""

        p.print("\(prefix)if \(conditional) {")
        p.printIndented("try visitor.\(visitMethod)(\(traitsArg)value: \(varName), fieldNumber: \(number))")
        p.print("}\(suffix)")
    }
}
