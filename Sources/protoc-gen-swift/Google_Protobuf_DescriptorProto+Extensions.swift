// Sources/protoc-gen-swift/Google_Protobuf_DescriptorProto+Extensions.swift - Descriptor extensions
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Extensions to `DescriptorProto` that provide Swift-generation-specific
/// functionality.
///
// -----------------------------------------------------------------------------

import Foundation
import PluginLibrary
import SwiftProtobuf

extension Google_Protobuf_DescriptorProto {
  // Field numbers used to collect .proto file comments.
  struct FieldNumbers {
    static let field: Int32 = 2
    static let nestedType: Int32 = 3
    static let enumType: Int32 = 4
    static let `extension`: Int32 = 6
    static let oneofDecl: Int32 = 8
  }

  /// A `String` containing a comma-delimited list of Swift range expressions
  /// covering the extension ranges for this message.
  ///
  /// This expression list is suitable as a pattern match in a `case`
  /// statement. For example, `"case 5..<10, 20..<30:"`.
  var swiftExtensionRangeExpressions: String {
    return extensionRange.lazy.map {
      $0.swiftRangeExpression
    }.joined(separator: ", ")
  }

  /// A `String` containing a Swift Boolean expression that tests if the given
  /// variable is in any of the extension ranges for this message.
  ///
  /// - Parameter variable: The name of the variable to test in the expression.
  /// - Returns: A `String` containing the Boolean expression.
  func swiftExtensionRangeBooleanExpression(variable: String) -> String {
    return extensionRange.lazy.map {
      "(\($0.swiftBooleanExpression(variable: variable)))"
    }.joined(separator: " || ")
  }

  func getMessageNameForPath(path: String, parentPath: String, swiftPrefix: String) -> String? {
    for m in nestedType {
      let messagePath = parentPath + "." + m.name
      let messageSwiftPath = swiftPrefix + "." + sanitizeMessageTypeName(m.name)
      if messagePath == path {
        return messageSwiftPath
      }
      if let n = m.getMessageNameForPath(path: path, parentPath: messagePath, swiftPrefix: messageSwiftPath) {
        return n
      }
    }
    return nil
  }

  func getEnumNameForPath(path: String, parentPath: String, swiftPrefix: String) -> String? {
    for e in enumType {
      let enumPath = parentPath + "." + e.name
      if enumPath == path {
        return swiftPrefix + "." + sanitizeEnumTypeName(e.name)
      }
    }

    for m in nestedType {
      let messagePath = parentPath + "." + m.name
      let messageSwiftPath = swiftPrefix + "." + sanitizeMessageTypeName(m.name)
      if let n = m.getEnumNameForPath(path: path, parentPath: messagePath, swiftPrefix: messageSwiftPath) {
        return n
      }
    }
    return nil
  }

  func getSwiftNameForEnumCase(path: String, caseName: String, parentPath: String, swiftPrefix: String) -> String? {
    for e in enumType {
      let enumPath = parentPath + "." + e.name
      if enumPath == path {
        let enumSwiftName = swiftPrefix + "." + sanitizeEnumTypeName(e.name)
        return enumSwiftName + "." + e.getSwiftNameForEnumCase(caseName: caseName)
      }
    }

    for m in nestedType {
      let messagePath = parentPath + "." + m.name
      let messageSwiftPath = swiftPrefix + "." + sanitizeMessageTypeName(m.name)
      if let n = m.getSwiftNameForEnumCase(path: path, caseName: caseName, parentPath: messagePath, swiftPrefix: messageSwiftPath) {
        return n
      }
    }
    return nil
  }
}

extension Google_Protobuf_DescriptorProto.ExtensionRange {

  /// A `String` containing the Swift range expression that represents this
  /// extension range.
  var swiftRangeExpression: String {
    return "\(start)..<\(end)"
  }

  /// A `String` containing the Swift Boolean expression that tests the given
  /// variable for containment within this extension range.
  ///
  /// - Parameter variable: The name of the variable to test in the expression.
  /// - Returns: A `String` containing the Boolean expression.
  func swiftBooleanExpression(variable: String) -> String {
    return "\(start) <= \(variable) && \(variable) < \(end)"
  }
}
