// Sources/protoc-gen-swift/EnumCaseGenerator.swift - Enum case logic
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// This file handles the generation of a Swift enum case for each value in a
/// .proto enum.
///
// -----------------------------------------------------------------------------

import Foundation
import PluginLibrary
import SwiftProtobuf

/// Generates the Swift code for a single enum case.
class EnumCaseGenerator {
  internal let descriptor: Google_Protobuf_EnumValueDescriptorProto
  internal let swiftName: String
  internal let path: [Int32]
  internal let comments: String
  internal let aliasOfGenerator: EnumCaseGenerator?

  private let visibility: String
  private var aliases = [Weak<EnumCaseGenerator>]()

  internal var protoName: String {
    return descriptor.name
  }

  internal var number: Int {
    return Int(descriptor.number)
  }

  /// True if the enum case is an alias for a case defined earlier, or false if
  /// it is not an alias.
  internal var isAlias: Bool {
    return aliasOfGenerator != nil
  }

  init(descriptor: Google_Protobuf_EnumValueDescriptorProto,
    path: [Int32],
    file: FileGenerator,
    stripLength: Int,
    aliasing aliasOfGenerator: EnumCaseGenerator?
  ) {
    self.descriptor = descriptor
    self.swiftName = descriptor.getSwiftName(stripLength: stripLength)
    self.path = path
    self.comments = file.commentsFor(path: path)
    self.aliasOfGenerator = aliasOfGenerator

    self.visibility = file.generatorOptions.visibilitySourceSnippet
  }

  /// Registers the given enum case generator as an alias of the receiver.
  ///
  /// - Precondition: `generator.descriptor.number == self.descriptor.number`.
  ///
  /// - Parameter generator: The `EnumCaseGenerator` that is an alias of this
  ///   one.
  func registerAlias(_ generator: EnumCaseGenerator) {
    precondition(generator.descriptor.number == descriptor.number,
                 "Aliases must have matching numbers.")

    aliases.append(Weak(generator))
  }

  /// Generates the `case` for the enum value, or a static read-only property
  /// if it is an alias for another value.
  ///
  /// - Parameter p: The code printer.
  func generateCaseOrAlias(printer p: inout CodePrinter) {
    if !comments.isEmpty {
      p.print("\n")
      p.print(comments)
    }
    if let aliasOf = aliasOfGenerator {
      p.print("\(visibility)static let \(swiftName) = \(aliasOf.swiftName)\n")
    } else {
      p.print("case \(swiftName) // = \(number)\n")
    }
  }

  /// Generates the `key: value` entry in the name map for the enum case and
  /// its aliases.
  ///
  /// - Precondition: `self.isAlias == false`.
  ///
  /// - Parameter p: The code printer.
  func generateNameMapEntry(printer p: inout CodePrinter) {
    precondition(!isAlias, "Only supported for non-alias generators.")

    if aliases.isEmpty {
      p.print("\(number): .same(proto: \"\(protoName)\"),\n")
    } else {
      // The force-unwrap here on the weak wrapped reference is safe because if
      // the generator got released, a lot of other things would have gone
      // wrong.
      let aliasNames = aliases.map {
        "\"\($0.wrapped!.protoName)\""
      }.joined(separator: ", ")

      p.print("\(number): .aliased(primary: \"\(protoName)\", aliases: [\(aliasNames)]),\n")
    }
  }
}
