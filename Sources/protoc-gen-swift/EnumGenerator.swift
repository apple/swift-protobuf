// Sources/protoc-gen-swift/EnumGenerator.swift - Enum logic
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// This file handles the generation of a Swift enum for each .proto enum.
///
// -----------------------------------------------------------------------------

import Foundation
import PluginLibrary
import SwiftProtobuf

/// The name of the case used to represent unrecognized values in proto3.
/// This case has an associated value containing the raw integer value.
private let unrecognizedCaseName = "UNRECOGNIZED"

/// Generates a Swift enum from a protobuf enum descriptor.
class EnumGenerator {
  private let descriptor: Google_Protobuf_EnumDescriptorProto
  private let generatorOptions: GeneratorOptions
  private let visibility: String
  private let swiftRelativeName: String
  private let swiftFullName: String
  private let enumCases: [EnumCaseGenerator]
  private let enumCasesSortedByNumber: [EnumCaseGenerator]
  private let defaultCase: EnumCaseGenerator
  private let path: [Int32]
  private let comments: String
  private let isProto3: Bool

  init(descriptor: Google_Protobuf_EnumDescriptorProto,
       path: [Int32],
       parentSwiftName: String?,
       file: FileGenerator
  ) {
    self.descriptor = descriptor
    self.generatorOptions = file.generatorOptions
    self.visibility = generatorOptions.visibilitySourceSnippet
    self.isProto3 = file.isProto3
    if parentSwiftName == nil {
      swiftRelativeName = sanitizeEnumTypeName(file.swiftPrefix + descriptor.name)
      swiftFullName = swiftRelativeName
    } else {
      swiftRelativeName = sanitizeEnumTypeName(descriptor.name)
      swiftFullName = parentSwiftName! + "." + swiftRelativeName
    }

    let stripLength: Int = descriptor.stripPrefixLength
    var i: Int32 = 0
    var firstCases = [Int32: EnumCaseGenerator]()
    var enumCases = [EnumCaseGenerator]()
    for v in descriptor.value {
      var casePath = path
      casePath.append(Google_Protobuf_EnumValueDescriptorProto.FieldNumbers.number)
      casePath.append(i)
      i += 1

      // Keep track of aliases by recording them as we build the generators.
      let firstCase = firstCases[v.number]
      let generator = EnumCaseGenerator(descriptor: v,
                                        path: casePath,
                                        file: file,
                                        stripLength: stripLength,
                                        aliasing: firstCase)
      enumCases.append(generator)

      if let firstCase = firstCase {
        firstCase.registerAlias(generator)
      } else {
        firstCases[v.number] = generator
      }
    }
    self.enumCases = enumCases
    enumCasesSortedByNumber = enumCases.sorted {$0.number < $1.number}
    self.defaultCase = self.enumCases[0]
    self.path = path
    self.comments = file.commentsFor(path: path)
  }

  func generateNested(printer p: inout CodePrinter) {
    p.print("\n")
    p.print(comments)
    p.print("\(visibility)enum \(swiftRelativeName): SwiftProtobuf.Enum, SwiftProtobuf._ProtoNameProviding {\n")
    p.indent()
    p.print("\(visibility)typealias RawValue = Int\n")

    // Cases
    for c in enumCases {
      c.generateCaseOrAlias(printer: &p)
    }
    if isProto3 {
      p.print("case \(unrecognizedCaseName)(Int)\n")
    }

    // Map the enum case names to their numbers.
    p.print("\n")
    generateNameMap(printer: &p)

    // Generate the default initializer.
    p.print("\n")
    p.print("\(visibility)init() {\n")
    p.indent()
    p.print("self = .\(defaultCase.swiftName)\n")
    p.outdent()
    p.print("}\n")

    p.print("\n")
    generateInitRawValue(printer: &p)

    p.print("\n")
    generateRawValueProperty(printer: &p)

    p.outdent()
    p.print("\n")
    p.print("}\n")
  }

  /// Generates the mapping from case numbers to their text/JSON names.
  ///
  /// - Parameter p: The code printer.
  private func generateNameMap(printer p: inout CodePrinter) {
    if enumCases.isEmpty {
      p.print("\(visibility)static let _protobuf_nameMap = SwiftProtobuf._NameMap()\n")
    } else {
      p.print("\(visibility)static let _protobuf_nameMap: SwiftProtobuf._NameMap = [\n")
      p.indent()
      for c in enumCasesSortedByNumber where !c.isAlias {
        c.generateNameMapEntry(printer: &p)
      }
      p.outdent()
      p.print("]\n")
    }
  }

  /// Generates `init?(rawValue:)` for the enum.
  ///
  /// - Parameter p: The code printer.
  private func generateInitRawValue(printer p: inout CodePrinter) {
    p.print("\(visibility)init?(rawValue: Int) {\n")
    p.indent()
    p.print("switch rawValue {\n")
    for c in enumCasesSortedByNumber where !c.isAlias {
      p.print("case \(c.number): self = .\(c.swiftName)\n")
    }
    if isProto3 {
      p.print("default: self = .\(unrecognizedCaseName)(rawValue)\n")
    } else {
      p.print("default: return nil\n")
    }
    p.print("}\n")
    p.outdent()
    p.print("}\n")
  }

  /// Generates the `rawValue` property of the enum.
  ///
  /// - Parameter p: The code printer.
  private func generateRawValueProperty(printer p: inout CodePrinter) {
    p.print("\(visibility)var rawValue: Int {\n")
    p.indent()
    p.print("switch self {\n")
    for c in enumCasesSortedByNumber where !c.isAlias {
      p.print("case .\(c.swiftName): return \(c.number)\n")
    }
    if isProto3 {
      p.print("case .\(unrecognizedCaseName)(let i): return i\n")
    }
    p.print("}\n")
    p.outdent()
    p.print("}\n")
  }
}
