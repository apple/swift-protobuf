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
  private let enumDescriptor: EnumDescriptor
  private let generatorOptions: GeneratorOptions
  private let namer: SwiftProtobufNamer

  /// The values that aren't aliases, as ordered in the .proto.
  private let mainEnumValueDescriptors: [EnumValueDescriptor]
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

    mainEnumValueDescriptors = descriptor.values.filter({
      return $0.aliasOf == nil
    })
    mainEnumValueDescriptorsSorted = mainEnumValueDescriptors.sorted(by: {
      return $0.number < $1.number
    })

    swiftRelativeName = namer.relativeName(enum: descriptor)
    swiftFullName = namer.fullName(enum: descriptor)
  }

  func generateMainEnum(printer p: inout CodePrinter) {
    let visibility = generatorOptions.visibilitySourceSnippet

    p.println(
      "",
      "\(enumDescriptor.protoSourceComments())\(visibility)enum \(swiftRelativeName): \(namer.swiftProtobufModuleName).Enum {")
    p.withIndentation { p in
      p.println("\(visibility)typealias RawValue = Int")

      // Cases/aliases
      generateCasesOrAliases(printer: &p)

      // Generate the default initializer.
      p.println(
        "",
        "\(visibility)init() {")
      p.printlnIndented("self = \(namer.dottedRelativeName(enumValue: enumDescriptor.values.first!))")
      p.println("}")

      p.println()
      generateInitRawValue(printer: &p)

      p.println()
      generateRawValueProperty(printer: &p)

      maybeGenerateCaseIterable(printer: &p)

    }
    p.println(
      "",
      "}")
  }

  func maybeGenerateCaseIterable(printer p: inout CodePrinter) {
    guard enumDescriptor.hasUnknownPreservingSemantics else { return }

    let visibility = generatorOptions.visibilitySourceSnippet
    p.println(
      "",
      "// The compiler won't synthesize support with the \(unrecognizedCaseName) case.",
      "\(visibility)static let allCases: [\(swiftFullName)] = [")
    p.withIndentation { p in
      for v in mainEnumValueDescriptors {
        let dottedName = namer.dottedRelativeName(enumValue: v)
        p.println("\(dottedName),")
      }
    }
    p.println("]")
  }

  func generateRuntimeSupport(printer p: inout CodePrinter) {
    p.println(
      "",
      "extension \(swiftFullName): \(namer.swiftProtobufModuleName)._ProtoNameProviding {")
    p.withIndentation { p in
      generateProtoNameProviding(printer: &p)
    }
    p.println("}")
  }

  /// Generates the cases or statics (for alias) for the values.
  ///
  /// - Parameter p: The code printer.
  private func generateCasesOrAliases(printer p: inout CodePrinter) {
    let visibility = generatorOptions.visibilitySourceSnippet
    for enumValueDescriptor in namer.uniquelyNamedValues(enum: enumDescriptor) {
      let comments = enumValueDescriptor.protoSourceComments()
      if !comments.isEmpty {
        p.println()
      }
      let relativeName = namer.relativeName(enumValue: enumValueDescriptor)
      if let aliasOf = enumValueDescriptor.aliasOf {
        let aliasOfName = namer.relativeName(enumValue: aliasOf)
        p.println("\(comments)\(visibility)static let \(relativeName) = \(aliasOfName)")
      } else {
        p.println("\(comments)case \(relativeName) // = \(enumValueDescriptor.number)")
      }
    }
    if enumDescriptor.hasUnknownPreservingSemantics {
      p.println("case \(unrecognizedCaseName)(Int)")
    }
  }

  /// Generates the mapping from case numbers to their text/JSON names.
  ///
  /// - Parameter p: The code printer.
  private func generateProtoNameProviding(printer p: inout CodePrinter) {
    let visibility = generatorOptions.visibilitySourceSnippet

    p.println("\(visibility)static let _protobuf_nameMap: \(namer.swiftProtobufModuleName)._NameMap = [")
    p.withIndentation { p in
      for v in mainEnumValueDescriptorsSorted {
        if v.aliases.isEmpty {
          p.println("\(v.number): .same(proto: \"\(v.name)\"),")
        } else {
          let aliasNames = v.aliases.map({ "\"\($0.name)\"" }).joined(separator: ", ")
          p.println("\(v.number): .aliased(proto: \"\(v.name)\", aliases: [\(aliasNames)]),")
        }
      }
    }
    p.println("]")
  }

  /// Generates `init?(rawValue:)` for the enum.
  ///
  /// - Parameter p: The code printer.
  private func generateInitRawValue(printer p: inout CodePrinter) {
    let visibility = generatorOptions.visibilitySourceSnippet

    p.println("\(visibility)init?(rawValue: Int) {")
    p.withIndentation { p in
      p.println("switch rawValue {")
      for v in mainEnumValueDescriptorsSorted {
        let dottedName = namer.dottedRelativeName(enumValue: v)
        p.println("case \(v.number): self = \(dottedName)")
      }
      if enumDescriptor.hasUnknownPreservingSemantics {
        p.println("default: self = .\(unrecognizedCaseName)(rawValue)")
      } else {
        p.println("default: return nil")
      }
      p.println("}")
    }
    p.println("}")
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
      (enumDescriptor.hasUnknownPreservingSemantics ? 1 : 0)
    let useMultipleSwitches = neededCases > maxCasesInSwitch

    p.println("\(visibility)var rawValue: Int {")
    p.withIndentation { p in
      if useMultipleSwitches {
        for (i, v) in mainEnumValueDescriptorsSorted.enumerated() {
          if (i % maxCasesInSwitch) == 0 {
            if i > 0 {
              p.println(
                "default: break",
                "}")
            }
            p.println("switch self {")
          }
          let dottedName = namer.dottedRelativeName(enumValue: v)
          p.println("case \(dottedName): return \(v.number)")
        }
        if enumDescriptor.hasUnknownPreservingSemantics {
          p.println("case .\(unrecognizedCaseName)(let i): return i")
        }
        p.println("""
          default: break
          }

          // Can't get here, all the cases are listed in the above switches.
          // See https://github.com/apple/swift-protobuf/issues/904 for more details.
          fatalError()
          """)
      } else {
        p.println("switch self {")
        for v in mainEnumValueDescriptorsSorted {
          let dottedName = namer.dottedRelativeName(enumValue: v)
          p.println("case \(dottedName): return \(v.number)")
        }
        if enumDescriptor.hasUnknownPreservingSemantics {
          p.println("case .\(unrecognizedCaseName)(let i): return i")
        }
        p.println("}")
      }

    }
    p.println("}")
  }
}
