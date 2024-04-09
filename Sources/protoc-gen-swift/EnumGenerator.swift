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
import SwiftProtobufPluginLibrary
import SwiftProtobuf

/// The name of the case used to represent unrecognized values in proto3.
/// This case has an associated value containing the raw integer value.
private let unrecognizedCaseName = "UNRECOGNIZED"

/// Generates a Swift enum from a protobuf enum descriptor.
class EnumGenerator {
  // TODO: Move these conformances back onto the `Enum` protocol when we do a major release.
  private static let requiredProtocolConformancesForEnums = ["Swift.CaseIterable"].joined(separator: ", ")

  private let enumDescriptor: EnumDescriptor
  private let generatorOptions: GeneratorOptions
  private let namer: SwiftProtobufNamer

  /// The aliasInfo for the values.
  private let aliasInfo: EnumDescriptor.ValueAliasInfo
  /// The values that aren't aliases, sorted by number.
  private let mainEnumValueDescriptorsSorted: [EnumValueDescriptor]

  private let swiftRelativeName: String
  private let swiftFullName: String

  init(descriptor: EnumDescriptor,
       generatorOptions: GeneratorOptions,
       namer: SwiftProtobufNamer
  ) {
    self.enumDescriptor = descriptor
    self.generatorOptions = generatorOptions
    self.namer = namer
    aliasInfo = EnumDescriptor.ValueAliasInfo(enumDescriptor: descriptor)

    mainEnumValueDescriptorsSorted = aliasInfo.mainValues.sorted(by: {
      return $0.number < $1.number
    })

    swiftRelativeName = namer.relativeName(enum: descriptor)
    swiftFullName = namer.fullName(enum: descriptor)
  }

  func generateMainEnum(printer p: inout CodePrinter) {
    let visibility = generatorOptions.visibilitySourceSnippet

    p.print(
      "",
      "\(enumDescriptor.protoSourceCommentsWithDeprecation(generatorOptions: generatorOptions))\(visibility)enum \(swiftRelativeName): \(namer.swiftProtobufModulePrefix)Enum, \(Self.requiredProtocolConformancesForEnums) {")
    p.withIndentation { p in
      p.print("\(visibility)typealias RawValue = Int")

      // Cases/aliases
      generateCasesOrAliases(printer: &p)

      // Generate the default initializer.
      p.print(
        "",
        "\(visibility)init() {")
      p.printIndented("self = \(namer.dottedRelativeName(enumValue: enumDescriptor.values.first!))")
      p.print("}")

      p.print()
      generateInitRawValue(printer: &p)

      p.print()
      generateRawValueProperty(printer: &p)

      maybeGenerateCaseIterable(printer: &p)

    }
    p.print(
      "",
      "}")
  }

  func maybeGenerateCaseIterable(printer p: inout CodePrinter) {
    guard !enumDescriptor.isClosed else { return }

    let visibility = generatorOptions.visibilitySourceSnippet
    p.print(
      "",
      "// The compiler won't synthesize support with the \(unrecognizedCaseName) case.",
      "\(visibility)static let allCases: [\(swiftFullName)] = [")
    p.withIndentation { p in
      for v in aliasInfo.mainValues {
        let dottedName = namer.dottedRelativeName(enumValue: v)
        p.print("\(dottedName),")
      }
    }
    p.print("]")
  }

  func generateRuntimeSupport(printer p: inout CodePrinter) {
    p.print(
      "",
      "extension \(swiftFullName): \(namer.swiftProtobufModulePrefix)_ProtoNameProviding {")
    p.withIndentation { p in
      generateProtoNameProviding(printer: &p)
    }
    p.print("}")
  }

  /// Generates the cases or statics (for alias) for the values.
  ///
  /// - Parameter p: The code printer.
  private func generateCasesOrAliases(printer p: inout CodePrinter) {
    let visibility = generatorOptions.visibilitySourceSnippet
    for enumValueDescriptor in namer.uniquelyNamedValues(valueAliasInfo: aliasInfo) {
      let comments = enumValueDescriptor.protoSourceCommentsWithDeprecation(generatorOptions: generatorOptions)
      if !comments.isEmpty {
        p.print()
      }
      let relativeName = namer.relativeName(enumValue: enumValueDescriptor)
      if let aliasOf = aliasInfo.original(of: enumValueDescriptor) {
        let aliasOfName = namer.relativeName(enumValue: aliasOf)
        p.print("\(comments)\(visibility)static let \(relativeName) = \(aliasOfName)")
      } else {
        p.print("\(comments)case \(relativeName) // = \(enumValueDescriptor.number)")
      }
    }
    if !enumDescriptor.isClosed {
      p.print("case \(unrecognizedCaseName)(Int)")
    }
  }

  /// Generates the mapping from case numbers to their text/JSON names.
  ///
  /// - Parameter p: The code printer.
  private func generateProtoNameProviding(printer p: inout CodePrinter) {
    let visibility = generatorOptions.visibilitySourceSnippet

    p.print("\(visibility)static let _protobuf_nameMap: \(namer.swiftProtobufModulePrefix)_NameMap = [")
    p.withIndentation { p in
      for v in mainEnumValueDescriptorsSorted {
        if let aliases = aliasInfo.aliases(v) {
          let aliasNames = aliases.map({ "\"\($0.name)\"" }).joined(separator: ", ")
          p.print("\(v.number): .aliased(proto: \"\(v.name)\", aliases: [\(aliasNames)]),")
        } else {
          p.print("\(v.number): .same(proto: \"\(v.name)\"),")
        }
      }
    }
    p.print("]")
  }

  /// Generates `init?(rawValue:)` for the enum.
  ///
  /// - Parameter p: The code printer.
  private func generateInitRawValue(printer p: inout CodePrinter) {
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
  private func generateRawValueProperty(printer p: inout CodePrinter) {
    let visibility = generatorOptions.visibilitySourceSnippet

    // See https://github.com/apple/swift-protobuf/issues/904 for the full
    // details on why the default has to get added even though the switch
    // is complete.

    // This is a "magic" value, currently picked based on the Swift 5.1
    // compiler, it will need ensure the warning doesn't trigger on all
    // versions of the compiler, meaning if the error starts to show up
    // again, all one can do is lower the limit.
    let maxCasesInSwitch = 500

    let neededCases = mainEnumValueDescriptorsSorted.count +
      (enumDescriptor.isClosed ? 0 : 1)
    let useMultipleSwitches = neededCases > maxCasesInSwitch

    p.print("\(visibility)var rawValue: Int {")
    p.withIndentation { p in
      if useMultipleSwitches {
        for (i, v) in mainEnumValueDescriptorsSorted.enumerated() {
          if (i % maxCasesInSwitch) == 0 {
            if i > 0 {
              p.print(
                "default: break",
                "}")
            }
            p.print("switch self {")
          }
          let dottedName = namer.dottedRelativeName(enumValue: v)
          p.print("case \(dottedName): return \(v.number)")
        }
        if !enumDescriptor.isClosed {
          p.print("case .\(unrecognizedCaseName)(let i): return i")
        }
        p.print("""
          default: break
          }

          // Can't get here, all the cases are listed in the above switches.
          // See https://github.com/apple/swift-protobuf/issues/904 for more details.
          fatalError()
          """)
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
}
