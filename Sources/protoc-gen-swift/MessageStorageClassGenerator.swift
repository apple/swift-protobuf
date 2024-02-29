// Sources/protoc-gen-swift/MessageStorageClassGenerator.swift - Message storage class logic
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Code generation for the private storage class used inside copy-on-write
/// messages.
///
// -----------------------------------------------------------------------------

import Foundation
import SwiftProtobufPluginLibrary
import SwiftProtobuf

/// Generates the `_StorageClass` used for messages that employ copy-on-write
/// logic for some of their fields.
class MessageStorageClassGenerator {
  private let fields: [any FieldGenerator]

  /// Creates a new `MessageStorageClassGenerator`.
  init(fields: [any FieldGenerator]) {
    self.fields = fields
  }

  /// Visibility of the storage within the Message.
  var storageVisibility: String {
    return "fileprivate"
  }

  /// If the storage wants to manually implement equality.
  var storageProvidesEqualTo: Bool { return false }

  /// Generates the full code for the storage class.
  ///
  /// - Parameter p: The code printer.
  func generateTypeDeclaration(printer p: inout CodePrinter) {
    p.print("fileprivate class _StorageClass {")
    p.withIndentation { p in
      generateStoredProperties(printer: &p)
      // Generate a default instance to be used so the heap allocation is
      // delayed until mutation is needed. This is the largest savings when
      // the message is used as a field in another message as it causes
      // returning the default to not require that heap allocation, i.e. -
      // readonly usage never causes the allocation.
      p.print("""

          #if swift(>=5.10)
            // This property is used as the initial default value for new instances of the type.
            // The type itself is protecting the reference to its storage via CoW semantics.
            // This will force a copy to be made of this reference when the first mutation occurs;
            // hence, it is safe to mark this as `nonisolated(unsafe)`.
            static nonisolated(unsafe) let defaultInstance = _StorageClass()
          #else
            static let defaultInstance = _StorageClass()
          #endif

          private init() {}

          """)
      generateClone(printer: &p)
    }
    p.print("}")
  }

  /// Generated the uniqueStorage() implementation.
  func generateUniqueStorage(printer p: inout CodePrinter) {
    p.print("\(storageVisibility) mutating func _uniqueStorage() -> _StorageClass {")
    p.withIndentation { p in
      p.print("if !isKnownUniquelyReferenced(&_storage) {")
      p.printIndented("_storage = _StorageClass(copying: _storage)")
      p.print(
        "}",
        "return _storage")
    }
    p.print("}")
  }

  func generatePreTraverse(printer p: inout CodePrinter) {
    // Nothing
  }

  /// Generates the stored properties for the storage class.
  ///
  /// - Parameter p: The code printer.
  private func generateStoredProperties(printer p: inout CodePrinter) {
    for f in fields {
      f.generateStorage(printer: &p)
    }
  }

  /// Generates the `init(copying:)` method of the storage class.
  ///
  /// - Parameter p: The code printer.
  private func generateClone(printer p: inout CodePrinter) {
    p.print("init(copying source: _StorageClass) {")
    p.withIndentation { p in
      for f in fields {
        f.generateStorageClassClone(printer: &p)
      }
    }
    p.print("}")
  }
}

/// Custom generator for storage of an google.protobuf.Any.
class AnyMessageStorageClassGenerator : MessageStorageClassGenerator {
  override var storageVisibility: String { return "internal" }
  override var storageProvidesEqualTo: Bool { return true }

  override func generateTypeDeclaration(printer p: inout CodePrinter) {
    // Just need an alias to the hand coded Storage.
    p.print("typealias _StorageClass = AnyMessageStorage")
  }

  override func generatePreTraverse(printer p: inout CodePrinter) {
    p.print("try _storage.preTraverse()")
  }
}
