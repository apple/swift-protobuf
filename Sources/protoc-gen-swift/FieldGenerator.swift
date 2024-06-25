// Sources/protoc-gen-swift/FieldGenerator.swift - Base class for Field Generators
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
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


/// Interface for field generators.
protocol FieldGenerator {
  var number: Int { get }

  /// Name mapping entries for the field.
  var fieldMapNames: [String] { get }

  /// Generate the interface for this field, this is includes any extra methods (has/clear).
  func generateInterface(printer: inout CodePrinter)

  /// Generate any additional storage needed for this field.
  func generateStorage(printer: inout CodePrinter)

  /// Generate the line to copy this field during a _StorageClass clone.
  func generateStorageClassClone(printer: inout CodePrinter)

  /// Generate the case and decoder invoke needed for this field.
  func generateDecodeFieldCase(printer: inout CodePrinter)

  /// True/False for if the generated traverse code will need use any locals.
  /// See https://github.com/apple/swift-protobuf/issues/1034 and
  /// https://github.com/apple/swift-protobuf/issues/1182 for more information.
  var generateTraverseUsesLocals: Bool { get }

  /// Generate the support for traversing this field.
  func generateTraverse(printer: inout CodePrinter)

  /// Generate support for comparing this field's value.
  /// The generated code should return false in the current scope if the field's don't match.
  func generateFieldComparison(printer: inout CodePrinter)

  /// Generate any support needed to ensure required fields are set.
  /// The generated code should return false the field isn't set.
  func generateRequiredFieldCheck(printer: inout CodePrinter)

  /// Generate any support needed to this field's value is initialized.
  /// The generated code should return false if it isn't set.
  func generateIsInitializedCheck(printer: inout CodePrinter)
}

/// Simple base class for FieldGenerators that also provides fieldMapNames.
class FieldGeneratorBase {
  let number: Int
  let fieldDescriptor: FieldDescriptor

  var fieldMapNames: [String] {
    // Protobuf Text uses the unqualified group name for the field
    // name instead of the field name provided by protoc.  As far
    // as I can tell, no one uses the fieldname provided by protoc,
    // so let's just put the field name that Protobuf Text
    // actually uses here.
    let protoName: String
    if fieldDescriptor.internal_isGroupLike {
      protoName = fieldDescriptor.messageType!.name
    } else {
      protoName = fieldDescriptor.name
    }

    var result: String
    let jsonName = fieldDescriptor.jsonName
    if jsonName == protoName {
      /// The proto and JSON names are identical:
      result = ".same(proto: \"\(protoName)\")"
    } else {
      let libraryGeneratedJsonName = NamingUtils.toJsonFieldName(protoName)
      if jsonName == libraryGeneratedJsonName {
        /// The library will generate the same thing protoc gave, so
        /// we can let the library recompute this:
        result = ".standard(proto: \"\(protoName)\")"
      } else {
        /// The library's generation didn't match, so specify this explicitly.
        result = ".unique(proto: \"\(protoName)\", json: \"\(jsonName ?? "")\")"
      }
    }

    // TODO: When the library can take a breaking change there should be a new
    // enum for the nametable to handle the group being able to match the
    // raw fieldname or the name based on the group's name. But until then
    // we add two entries, to provide both options for TextFormat, but we add
    // the preferred one second, so when the runtime builds up the mappings,
    // it will become the default for what gets used when generating TextFormat.
    if fieldDescriptor.internal_isGroupLike &&
        protoName != fieldDescriptor.name {
      let nameLowercase = protoName.lowercased()
      if nameLowercase == jsonName {
        return [".same(proto: \"\(nameLowercase)\")", result]
      } else {
        return [".unique(proto: \"\(nameLowercase)\", json: \"\(jsonName ?? "")\")", result]
      }
    } else {
      return [result]
    }
  }

  init(descriptor: FieldDescriptor) {
    number = Int(descriptor.number)
    fieldDescriptor = descriptor
  }
}
