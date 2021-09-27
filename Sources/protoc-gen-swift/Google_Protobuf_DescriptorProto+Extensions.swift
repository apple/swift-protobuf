// Sources/protoc-gen-swift/Google_Protobuf_DescriptorProto+Extensions.swift - Descriptor extensions
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Extensions to `DescriptorProto` that provide Swift-generation-specific
/// functionality.
///
// -----------------------------------------------------------------------------

import Foundation
import SwiftProtobufPluginLibrary
import SwiftProtobuf

extension Google_Protobuf_DescriptorProto.ExtensionRange {

  /// A `String` containing the Swift expression that represents this
  /// extension range to be used in a `case` statement.
  var swiftCaseExpression: String {
    if start == end - 1 {
      return "\(start)"
    }
    return "\(start)..<\(end)"
  }

  /// A `String` containing the Swift Boolean expression that tests the given
  /// variable for containment within this extension range.
  ///
  /// - Parameter variable: The name of the variable to test in the expression.
  /// - Returns: A `String` containing the Boolean expression.
  func swiftBooleanExpression(variable: String) -> String {
    if start == end - 1 {
      return "\(start) == \(variable)"
    }
    return "\(start) <= \(variable) && \(variable) < \(end)"
  }
}
