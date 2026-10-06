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
    private let comments: String

    var presence: FieldPresence = .hasBit(0)

    var oneofIndex: Int? { nil }

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

    let submessageOrEnumReference: SubmessageOrEnumReference?

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
        comments = descriptor.protoSourceCommentsWithDeprecation(generatorOptions: generatorOptions)

        storedProperty = "self.\(hasFieldPresence ? underscoreSwiftName : swiftName)"

        switch descriptor.type {
        case .group:
            let swiftSingularType = descriptor.swiftSingularType(namer: namer)
            submessageOrEnumReference = .message(
                swiftTypeName: swiftSingularType,
                protoFullName: descriptor.messageType!.fullName
            )
        case .message:
            if descriptor.isMap {
                let entrySchemaName = MapEntryGenerator.schemaName(for: descriptor.messageType!)
                let valueDescriptor = descriptor.messageType!.mapKeyAndValue!.value
                let valueKind: SubmessageOrEnumReference.MapValueKind
                switch valueDescriptor.type {
                case .group, .message:
                    valueKind = .message(protoFullName: valueDescriptor.messageType!.fullName)
                case .enum:
                    valueKind = .enum(protoFullName: valueDescriptor.enumType!.fullName)
                default:
                    valueKind = .other
                }
                submessageOrEnumReference = .map(schemaName: entrySchemaName, valueKind: valueKind)
            } else {
                let swiftSingularType = descriptor.swiftSingularType(namer: namer)
                submessageOrEnumReference = .message(
                    swiftTypeName: swiftSingularType,
                    protoFullName: descriptor.messageType!.fullName
                )
            }
        case .enum:
            let swiftSingularType = descriptor.swiftSingularType(namer: namer)
            submessageOrEnumReference = .enum(
                swiftTypeName: swiftSingularType,
                protoFullName: descriptor.enumType!.fullName
            )
        default:
            submessageOrEnumReference = nil
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

        // The `willBeSet` argument to `MessageStorage.updateValue` depends on a variety of
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
                defaultValueArgument = ""
            case .enum:
                willBeSetArgument = "willBeSet: newValue != \(swiftDefaultValue), "
                defaultValueArgument = "default: \(swiftDefaultValue), "
            case .message, .group:
                preconditionFailure("message/group fields should have been handled by hasFieldPresence")
            default:
                willBeSetArgument = "willBeSet: newValue != \(swiftDefaultValue), "
                defaultValueArgument = ""
            }
        }

        let atLabel = storageBucket == .stable ? "at" : "atIndex"
        let getCall: String
        let setCall: String
        switch storageBucket {
        case .message:
            // When weak imports are enabled, we generate different accessors
            // that delegate to a witness to initialize the default value (when
            // the field is not set) and to deinitialize existing values.
            // Without weak imports, we prefer the more efficient approach of
            // passing the metatype directly to the runtime.
            if generatorOptions.experimentalWeakImports {
                getCall = "messageValue(atIndex: \(storageOffsetOrIndex), fieldNumber: \(number), \(hasBitArgument))"
                setCall =
                    "updateMessageValue(atIndex: \(storageOffsetOrIndex), fieldNumber: \(number), to: newValue, \(hasBitArgument))"
            } else {
                getCall = "messageValue(atIndex: \(storageOffsetOrIndex), \(hasBitArgument))"
                setCall =
                    "updateValue(\(atLabel): \(storageOffsetOrIndex), to: newValue, \(willBeSetArgument)\(hasBitArgument))"
            }
        case .repeated
        where generatorOptions.experimentalWeakImports
            && (fieldDescriptor.type == .message || fieldDescriptor.type == .group):
            getCall = "value(atIndex: \(storageOffsetOrIndex), \(hasBitArgument))"
            setCall =
                "updateRepeatedMessageValue(atIndex: \(storageOffsetOrIndex), fieldNumber: \(number), to: newValue, \(hasBitArgument))"
        case .repeated where generatorOptions.experimentalWeakImports && fieldDescriptor.type == .enum:
            getCall = "value(atIndex: \(storageOffsetOrIndex), \(hasBitArgument))"
            setCall =
                "updateRepeatedEnumValue(atIndex: \(storageOffsetOrIndex), fieldNumber: \(number), to: newValue, \(hasBitArgument))"
        case .map where generatorOptions.experimentalWeakImports:
            getCall = "mapValue(atIndex: \(storageOffsetOrIndex), fieldNumber: \(number), \(hasBitArgument))"
            setCall =
                "updateMapValue(atIndex: \(storageOffsetOrIndex), fieldNumber: \(number), to: newValue, \(hasBitArgument))"
        case .stable where fieldDescriptor.type == .enum && generatorOptions.experimentalWeakImports:
            // When weak imports are enabled, we generate different accessors
            // that delegate to a witness to initialize the enum from its raw
            // value and to extract the raw value in the setter.
            let hasPresenceArgument = hasFieldPresence ? "" : "hasPresence: false, "
            getCall =
                "enumValue(at: \(storageOffsetOrIndex), fieldNumber: \(number), \(defaultValueArgument)\(hasBitArgument))"
            setCall =
                "updateEnumValue(at: \(storageOffsetOrIndex), fieldNumber: \(number), to: newValue, \(hasPresenceArgument)\(hasBitArgument))"
        default:
            getCall = "value(\(atLabel): \(storageOffsetOrIndex), \(defaultValueArgument)\(hasBitArgument))"
            setCall =
                "updateValue(\(atLabel): \(storageOffsetOrIndex), to: newValue, \(willBeSetArgument)\(hasBitArgument))"
        }
        p.printIndented(
            "get { _storage.\(getCall) }",
            "set { _uniqueStorage().\(setCall) }"
        )
        p.print("}")

        guard hasFieldPresence else { return }

        p.print(
            "/// Returns true if `\(swiftName)` has been explicitly set.",
            "\(visibility)var \(swiftHasName): Swift.Bool { _storage.isPresent(\(hasBitArgument)) }"
        )

        p.print(
            "/// Clears the value of `\(swiftName)`. Subsequent reads from it will return its default value."
        )

        let clearCall: String
        switch storageBucket {
        case .message:
            // When weak imports are enabled, we generate different `clear`
            // functions that delegate to a witness to deinitialize the value.
            // Without weak imports, we prefer the more efficient approach of
            // passing the metatype directly to the runtime.
            if generatorOptions.experimentalWeakImports {
                clearCall =
                    "clearMessageValue(atIndex: \(storageOffsetOrIndex), fieldNumber: \(number), \(hasBitArgument))"
            } else {
                clearCall =
                    "clearValue(\(atLabel): \(storageOffsetOrIndex), type: \(swiftType).self, \(hasBitArgument))"
            }
        case .stable where fieldDescriptor.type == .enum:
            // All singular enum fields can use the same `clear` function
            // because we store the raw value in memory; there's nothing to
            // deinitialize.
            clearCall = "clearEnumValue(at: \(storageOffsetOrIndex), \(hasBitArgument))"
        default:
            clearCall = "clearValue(\(atLabel): \(storageOffsetOrIndex), type: \(swiftType).self, \(hasBitArgument))"
        }
        p.print(
            "\(visibility)mutating func \(swiftClearName)() { _uniqueStorage().\(clearCall) }"
        )
    }
}
