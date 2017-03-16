// Sources/protoc-gen-swift/MessageStorageClassGenerator.swift - Message storage class logic
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Code generation for the private storage class used inside copy-on-write
/// messages.
///
// -----------------------------------------------------------------------------

import Foundation
import PluginLibrary
import SwiftProtobuf

/// Generates the `_StorageClass` used for messages that employ copy-on-write
/// logic for some of their fields.
class MessageStorageClassGenerator {
  private let fields: [MessageFieldGenerator]
  private let oneofs: [OneofGenerator]
  private let descriptor: Google_Protobuf_DescriptorProto
  private let messageSwiftName: String
  private let context: Context

  /// Creates a new `MessageStorageClassGenerator`.
  init(descriptor: Google_Protobuf_DescriptorProto,
       fields: [MessageFieldGenerator],
       oneofs: [OneofGenerator],
       file: FileGenerator,
       messageSwiftName: String,
       context: Context
  ) {
    self.descriptor = descriptor
    self.fields = fields
    self.oneofs = oneofs
    self.messageSwiftName = messageSwiftName
    self.context = context
  }

  /// The name of the storage class.
  var typeName: String {
    return "_StorageClass"
  }

  /// Visibility of the storage within the Message.
  var storageVisibility: String {
    return "private"
  }

  /// If the storage wants to manually implement equality.
  var storageProvidesEqualTo: Bool { return false }

  /// Generates the full code for the storage class.
  ///
  /// - Parameter p: The code printer.
  func generateNested(printer p: inout CodePrinter) {
    p.print("\n")
    p.print("private class \(typeName) {\n")
    p.indent()

    generateStoredProperties(printer: &p)

    // Generate the default initializer. If we don't, Swift may generate one
    // for some of the stored properties, which we will never use (so it just
    // wastes space in the final binary).
    p.print("\n")
    p.print("init() {}\n")

    p.print("\n")
    generateCopy(printer: &p)

    p.outdent()
    p.print("}\n")
    p.print("\n")
  }

  /// Generates the stored properties for the storage class.
  ///
  /// - Parameter p: The code printer.
  private func generateStoredProperties(printer p: inout CodePrinter) {
    var oneofsHandled = Set<Int32>()
    for f in fields {
      if f.descriptor.hasOneofIndex {
        let oneofIndex = f.descriptor.oneofIndex
        if !oneofsHandled.contains(oneofIndex) {
          let oneof = f.oneof!
          p.print("var \(oneof.swiftStorageFieldName): \(messageSwiftName).\(oneof.swiftRelativeType)?\n")
          oneofsHandled.insert(oneofIndex)
        }
      } else {
        p.print("var \(f.swiftStorageName): \(f.swiftStorageType) = \(f.swiftStorageDefaultValue)\n")
      }
    }
  }

  /// Generates the `copy` method of the storage class.
  ///
  /// - Parameter p: The code printer.
  private func generateCopy(printer p: inout CodePrinter) {
    p.print("func copy() -> \(typeName) {\n")
    p.indent()
    p.print("let clone = \(typeName)()\n")

    var oneofsHandled = Set<Int32>()
    for f in fields {
      if let o = f.oneof {
        if !oneofsHandled.contains(f.descriptor.oneofIndex) {
          p.print("clone.\(o.swiftStorageFieldName) = \(o.swiftStorageFieldName)\n")
          oneofsHandled.insert(f.descriptor.oneofIndex)
        }
      } else {
        p.print("clone.\(f.swiftStorageName) = \(f.swiftStorageName)\n")
      }
    }
    p.print("return clone\n")
    p.outdent()
    p.print("}\n")
  }
}

/// Cusotm generator for storage of an google.protobuf.Any.
class AnyMessageStorageClassGenerator : MessageStorageClassGenerator {

  override var typeName: String { return "AnyMessageStorage" }
  override var storageVisibility: String { return "internal" }
  override var storageProvidesEqualTo: Bool { return true }

  override func generateNested(printer p: inout CodePrinter) {
    // Nothing.  It is hand coded in another file along with
    // the extension on the message.
  }
}
