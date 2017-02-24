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

  internal var protoName: String {
    return descriptor.name
  }

  internal var number: Int {
    return Int(descriptor.number)
  }

  init(descriptor: Google_Protobuf_EnumValueDescriptorProto,
       path: [Int32],
       file: FileGenerator,
       stripLength: Int
  ) {
    self.descriptor = descriptor
    self.swiftName = descriptor.getSwiftName(stripLength: stripLength)
    self.path = path
    self.comments = file.commentsFor(path: path)
  }

  /// Generates the `case` for the enum value.
  ///
  /// - Parameter p: The code printer.
  func generateCase(printer p: inout CodePrinter) {
    if !comments.isEmpty {
      p.print("\n")
      p.print(comments)
    }
    p.print("case \(swiftName) // = \(number)\n")
  }
}
