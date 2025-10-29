// Sources/protoc-gen-swift/EnumGenerator.swift - Enum logic
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// This file handles the generation of a Swift enum for each .proto enum.
///
// -----------------------------------------------------------------------------

import Foundation
import SwiftProtobuf
import SwiftProtobufPluginLibrary

/// The name of the case used to represent unrecognized values in proto3.
/// This case has an associated value containing the raw integer value.
private let unrecognizedCaseName = "UNRECOGNIZED"

/// Generates a Swift enum from a protobuf enum descriptor.
class EnumGenerator {
    // TODO: Move these conformances back onto the `Enum` protocol when we do a major release.
    fileprivate static let requiredProtocolConformancesForEnums = ["Swift.CaseIterable"].joined(separator: ", ")

    fileprivate let enumDescriptor: EnumDescriptor
    fileprivate let generatorOptions: GeneratorOptions
    fileprivate let namer: SwiftProtobufNamer

    /// The aliasInfo for the values.
    private let aliasInfo: EnumDescriptor.ValueAliasInfo

    /// The values that aren't aliases, sorted by number.
    fileprivate let mainEnumValueDescriptorsSorted: [EnumValueDescriptor]

    fileprivate let swiftRelativeName: String
    fileprivate let swiftFullName: String

    /// The Swift expression that is equivalent to the default value of the enum (its first case).
    fileprivate var swiftDefaultValue: String

    /// The defined values in the enum, ignoring aliases.
    fileprivate var valuesIgnoringAliases: [EnumValueDescriptor] {
        aliasInfo.mainValues
    }

    /// Returns an instance of the appropriate generator subclass for the given enum descriptor.
    static func makeEnumGenerator(
        descriptor: EnumDescriptor,
        generatorOptions: GeneratorOptions,
        namer: SwiftProtobufNamer
    ) -> EnumGenerator {
        descriptor.isClosed
            ? ClosedEnumGenerator(descriptor: descriptor, generatorOptions: generatorOptions, namer: namer)
            : OpenEnumGenerator(descriptor: descriptor, generatorOptions: generatorOptions, namer: namer)
    }

    fileprivate init(
        descriptor: EnumDescriptor,
        generatorOptions: GeneratorOptions,
        namer: SwiftProtobufNamer
    ) {
        self.enumDescriptor = descriptor
        self.generatorOptions = generatorOptions
        self.namer = namer
        aliasInfo = EnumDescriptor.ValueAliasInfo(enumDescriptor: descriptor)

        mainEnumValueDescriptorsSorted = aliasInfo.mainValues.sorted(by: {
            $0.number < $1.number
        })

        swiftRelativeName = namer.relativeName(enum: descriptor)
        swiftFullName = namer.fullName(enum: descriptor)
        swiftDefaultValue = namer.dottedRelativeName(enumValue: enumDescriptor.values.first!)
    }

    /// Prints the main Swift type declaration for the protobuf enum.
    ///
    /// This method must be implemented by subclasses.
    func generateTypeDeclaration(to printer: inout CodePrinter) {
        fatalError("Must be implemented by subclass")
    }

    /// Prints the Swift declaration that corresponds to the given protobuf enum case.
    ///
    /// This method must be implemented by subclasses.
    func generateCaseDeclaration(for valueDescriptor: EnumValueDescriptor, to printer: inout CodePrinter) {
        fatalError("Must be implemented by subclass")
    }

    func generateRuntimeSupport(printer p: inout CodePrinter) {
        p.print(
            "",
            "extension \(swiftFullName): \(namer.swiftProtobufModulePrefix)_ProtoNameProviding {"
        )
        p.withIndentation { p in
            generateProtoNameProviding(printer: &p)
        }
        p.print("}")
    }

    /// Iterates over the cases in the protobuf enum and generates the appropriate cases or static
    /// properties.
    ///
    /// This default implementation simply calls either `generateCaseDeclaration` or
    /// `generateAliasDeclaration` as appropriate for each case in the enum. Subclasses can override
    /// this if they wish to print additional code immediately before or after those cases.
    func generateCaseDeclarations(to p: inout CodePrinter) {
        for enumValueDescriptor in namer.uniquelyNamedValues(valueAliasInfo: aliasInfo) {
            printComments(of: enumValueDescriptor, to: &p)
            if let aliasOf = aliasInfo.original(of: enumValueDescriptor) {
                generateAliasDeclaration(alias: enumValueDescriptor, original: aliasOf, to: &p)
            } else {
                generateCaseDeclaration(for: enumValueDescriptor, to: &p)
            }
        }
    }

    /// Prints the comments for the given enum value descriptor, if it has any.
    private func printComments(of valueDescriptor: EnumValueDescriptor, to p: inout CodePrinter) {
        let comments = valueDescriptor.protoSourceCommentsWithDeprecation(generatorOptions: generatorOptions)
        if !comments.isEmpty {
            p.print()
        }
        // Suppress the final newline because the comment itself will have one.
        p.print(comments, newlines: false)
    }

    /// Prints the static property corresponding to an enum value alias.
    private func generateAliasDeclaration(
        alias aliasDescriptor: EnumValueDescriptor,
        original originalDescriptor: EnumValueDescriptor,
        to p: inout CodePrinter
    ) {
        let aliasName = namer.relativeName(enumValue: aliasDescriptor)
        let originalName = namer.relativeName(enumValue: originalDescriptor)
        p.print("\(generatorOptions.visibilitySourceSnippet)static let \(aliasName) = \(originalName)")
    }

    /// Generates the mapping from case numbers to their text/JSON names.
    ///
    /// - Parameter p: The code printer.
    private func generateProtoNameProviding(printer p: inout CodePrinter) {
        let visibility = generatorOptions.visibilitySourceSnippet

        var writer = ProtoNameInstructionWriter()
        for v in mainEnumValueDescriptorsSorted {
            if let aliases = aliasInfo.aliases(v) {
                writer.writeAliased(v, aliases: aliases)
            } else {
                writer.writeSame(number: v.number, name: v.name)
            }
        }
        p.print(
            "\(visibility)static let _protobuf_nameMap = \(namer.swiftProtobufModulePrefix)_NameMap(bytecode: \(writer.bytecode.stringLiteral))"
        )
    }
}

/// Generates an open protobuf enum as a Swift enum.
private final class OpenEnumGenerator: EnumGenerator {
    override func generateTypeDeclaration(to p: inout CodePrinter) {
        let visibility = generatorOptions.visibilitySourceSnippet

        p.print(
            "",
            "\(enumDescriptor.protoSourceCommentsWithDeprecation(generatorOptions: generatorOptions))\(visibility)enum \(swiftRelativeName): \(namer.swiftProtobufModulePrefix)Enum, \(Self.requiredProtocolConformancesForEnums) {"
        )
        p.withIndentation { p in
            p.print("\(visibility)typealias RawValue = Int")

            // Cases/aliases
            generateCaseDeclarations(to: &p)

            // Generate the default initializer.
            p.print(
                "",
                "\(visibility)init() {"
            )
            p.printIndented("self = \(swiftDefaultValue)")
            p.print(
                "}",
                ""
            )

            // Since open enums can't be declared with the raw value in their inheritance clause,
            // we have to generate the `RawRepresentable` initializer and property requirements
            // ourselves.
            generateInitRawValue(to: &p)
            p.print()
            generateRawValueProperty(to: &p)
            generateCaseIterableConformance(to: &p)

        }
        p.print(
            "",
            "}"
        )
    }

    override func generateCaseDeclarations(to p: inout CodePrinter) {
        super.generateCaseDeclarations(to: &p)
        p.print("case \(unrecognizedCaseName)(Int)")
    }

    override func generateCaseDeclaration(for enumValueDescriptor: EnumValueDescriptor, to p: inout CodePrinter) {
        let relativeName = namer.relativeName(enumValue: enumValueDescriptor)
        p.print("case \(relativeName) // = \(enumValueDescriptor.number)")
    }

    /// Generates `init?(rawValue:)` for the enum.
    ///
    /// - Parameter p: The code printer.
    private func generateInitRawValue(to p: inout CodePrinter) {
        let visibility = generatorOptions.visibilitySourceSnippet

        p.print("\(visibility)init?(rawValue: Int) {")
        p.withIndentation { p in
            p.print("switch rawValue {")
            for v in mainEnumValueDescriptorsSorted {
                let dottedName = namer.dottedRelativeName(enumValue: v)
                p.print("case \(v.number): self = \(dottedName)")
            }
            if !enumDescriptor.isClosed {
                p.print("default: self = .\(unrecognizedCaseName)(rawValue)")
            } else {
                p.print("default: return nil")
            }
            p.print("}")
        }
        p.print("}")
    }

    /// Generates the `rawValue` property of the enum.
    ///
    /// - Parameter p: The code printer.
    private func generateRawValueProperty(to p: inout CodePrinter) {
        let visibility = generatorOptions.visibilitySourceSnippet

        // See https://github.com/apple/swift-protobuf/issues/904 for the full
        // details on why the default has to get added even though the switch
        // is complete.

        // This is a "magic" value, currently picked based on the Swift 5.1
        // compiler, it will need ensure the warning doesn't trigger on all
        // versions of the compiler, meaning if the error starts to show up
        // again, all one can do is lower the limit.
        let maxCasesInSwitch = 500

        let neededCases = mainEnumValueDescriptorsSorted.count + (enumDescriptor.isClosed ? 0 : 1)
        let useMultipleSwitches = neededCases > maxCasesInSwitch

        p.print("\(visibility)var rawValue: Int {")
        p.withIndentation { p in
            if useMultipleSwitches {
                for (i, v) in mainEnumValueDescriptorsSorted.enumerated() {
                    if (i % maxCasesInSwitch) == 0 {
                        if i > 0 {
                            p.print(
                                "default: break",
                                "}"
                            )
                        }
                        p.print("switch self {")
                    }
                    let dottedName = namer.dottedRelativeName(enumValue: v)
                    p.print("case \(dottedName): return \(v.number)")
                }
                if !enumDescriptor.isClosed {
                    p.print("case .\(unrecognizedCaseName)(let i): return i")
                }
                p.print(
                    """
                    default: break
                    }

                    // Can't get here, all the cases are listed in the above switches.
                    // See https://github.com/apple/swift-protobuf/issues/904 for more details.
                    fatalError()
                    """
                )
            } else {
                p.print("switch self {")
                for v in mainEnumValueDescriptorsSorted {
                    let dottedName = namer.dottedRelativeName(enumValue: v)
                    p.print("case \(dottedName): return \(v.number)")
                }
                if !enumDescriptor.isClosed {
                    p.print("case .\(unrecognizedCaseName)(let i): return i")
                }
                p.print("}")
            }

        }
        p.print("}")
    }

    private func generateCaseIterableConformance(to p: inout CodePrinter) {
        guard !enumDescriptor.isClosed else { return }

        let visibility = generatorOptions.visibilitySourceSnippet
        p.print(
            "",
            "// The compiler won't synthesize support with the \(unrecognizedCaseName) case.",
            "\(visibility)static let allCases: [\(swiftFullName)] = ["
        )
        p.withIndentation { p in
            for v in valuesIgnoringAliases {
                let dottedName = namer.dottedRelativeName(enumValue: v)
                p.print("\(dottedName),")
            }
        }
        p.print("]")
    }

}

/// Generates a closed protobuf enum as a Swift enum.
private final class ClosedEnumGenerator: EnumGenerator {
    override func generateTypeDeclaration(to p: inout CodePrinter) {
        let visibility = generatorOptions.visibilitySourceSnippet

        p.print(
            "",
            "\(enumDescriptor.protoSourceCommentsWithDeprecation(generatorOptions: generatorOptions))\(visibility)enum \(swiftRelativeName): Int, \(namer.swiftProtobufModulePrefix)Enum, \(Self.requiredProtocolConformancesForEnums) {"
        )
        p.withIndentation { p in
            // Cases/aliases
            generateCaseDeclarations(to: &p)

            // Generate the default initializer.
            p.print(
                "",
                "\(visibility)init() {"
            )
            p.printIndented("self = \(swiftDefaultValue)")
            p.print("}")
        }
        p.print(
            "",
            "}"
        )

    }

    override func generateCaseDeclaration(for enumValueDescriptor: EnumValueDescriptor, to p: inout CodePrinter) {
        let relativeName = namer.relativeName(enumValue: enumValueDescriptor)
        p.print("case \(relativeName) = \(enumValueDescriptor.number)")
    }
}
