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
import SwiftProtobuf
import SwiftProtobufPluginLibrary

class MessageFieldGenerator: FieldGeneratorBase, FieldGenerator {
    private let generatorOptions: GeneratorOptions
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

    var presence: FieldPresence = .hasBit(0)

    var oneofIndex: Int? { nil }

    var needsIsInitializedGeneration: Bool {
        isRequired || (isGroupOrMessage && fieldDescriptor.messageType!.containsRequiredFields())
    }

    private var hasBitIndex: Int {
        switch presence {
        case .hasBit(let index):
            return Int(index)
        case .oneofMember:
            preconditionFailure("oneof members should be handled by OneofGenerator.MemberFieldGenerator")
        }
    }

    private var isMap: Bool { fieldDescriptor.isMap }
    private var isPacked: Bool { fieldDescriptor.isPacked }

    // Note: this could still be a map (since those are repeated message fields
    private var isRepeated: Bool { fieldDescriptor.isRepeated }
    private var isGroupOrMessage: Bool {
        switch fieldDescriptor.type {
        case .group, .message:
            return true
        default:
            return false
        }
    }

    let trampolineFieldKind: TrampolineFieldKind?

    init(
        descriptor: FieldDescriptor,
        generatorOptions: GeneratorOptions,
        namer: SwiftProtobufNamer
    ) {
        precondition(descriptor.realContainingOneof == nil)

        self.generatorOptions = generatorOptions
        self.namer = namer

        hasFieldPresence = descriptor.hasPresence
        let names = namer.messagePropertyNames(
            field: descriptor,
            prefixed: "_",
            includeHasAndClear: hasFieldPresence
        )
        swiftName = names.name
        underscoreSwiftName = names.prefixed
        swiftHasName = names.has
        swiftClearName = names.clear
        swiftType = descriptor.swiftType(namer: namer)
        swiftStorageType = descriptor.swiftStorageType(namer: namer)
        swiftDefaultValue = descriptor.swiftDefaultValue(namer: namer)
        traitsType = descriptor.traitsType(namer: namer)
        comments = descriptor.protoSourceCommentsWithDeprecation(generatorOptions: generatorOptions)

        storedProperty = "self.\(hasFieldPresence ? underscoreSwiftName : swiftName)"

        switch descriptor.type {
        case .group:
            trampolineFieldKind = .message(swiftType)
        case .message:
            if let mapKeyAndValue = descriptor.messageType!.mapKeyAndValue {
                trampolineFieldKind = .map(swiftType, valueIsMessage: mapKeyAndValue.value.type == .message)
            } else {
                trampolineFieldKind = .message(swiftType)
            }
        case .enum:
            trampolineFieldKind = .enum(swiftType)
        default:
            trampolineFieldKind = nil
        }

        super.init(descriptor: descriptor)
    }

    func generateInterface(printer p: inout CodePrinter) {
        let visibility = generatorOptions.visibilitySourceSnippet
        p.print()

        // Compute the byte offset and mask for the field's has-bit.
        let hasByte = hasBitIndex / 8
        let hasMask = 1 << (hasBitIndex & 7)
        let hasBitArgument = "hasBit: (\(hasByte), \(hasMask))"

        p.print("\(comments)\(visibility)var \(swiftName): \(swiftType) {")

        // The `willBeSet` argument to `_MessageStorage.updateValue` depends on a variety of
        // factors, such as the field's presence (or lack thereof) or whether it is a repeated
        // field.
        let willBeSetArgument: String
        let defaultValueArgument: String
        if hasFieldPresence {
            // When a field has presence, setting it *always* updates it, regardless of its value.
            willBeSetArgument = "willBeSet: true, "
            defaultValueArgument = "default: \(swiftDefaultValue), "
        } else if isMap {
            willBeSetArgument = "willBeSet: !newValue.isEmpty, "
            // For simplicity, the collection form of `value(at:...)` doesn't take a default value
            // argument because it would always be an empty collection.
            defaultValueArgument = ""
        } else if isRepeated {
            willBeSetArgument = "willBeSet: !newValue.isEmpty, "
            // For simplicity, the collection form of `value(at:...)` doesn't take a default value
            // argument because it would always be an empty collection.
            defaultValueArgument = ""
        } else {
            switch fieldDescriptor.type {
            case .string, .bytes:
                willBeSetArgument = "willBeSet: !newValue.isEmpty, "
            case .message, .group:
                preconditionFailure("message/group fields should have been handled by hasFieldPresence")
            default:
                willBeSetArgument = "willBeSet: newValue != \(swiftDefaultValue), "
            }
            defaultValueArgument = ""
        }

        p.printIndented(
            "get { _storage.value(at: \(storageOffsetExpression), \(defaultValueArgument)\(hasBitArgument)) }",
            "set { _uniqueStorage().updateValue(at: \(storageOffsetExpression), to: newValue, \(willBeSetArgument)\(hasBitArgument)) }"
        )
        p.print("}")

        guard hasFieldPresence else { return }

        p.print(
            "/// Returns true if `\(swiftName)` has been explicitly set.",
            "\(visibility)var \(swiftHasName): Bool { _storage.isPresent(\(hasBitArgument)) }"
        )

        p.print(
            "/// Clears the value of `\(swiftName)`. Subsequent reads from it will return its default value."
        )
        p.print(
            "\(visibility)mutating func \(swiftClearName)() { _uniqueStorage().clearValue(at: \(storageOffsetExpression), type: \(swiftType).self, \(hasBitArgument)) }"
        )
    }
}
