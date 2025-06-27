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
import SwiftProtobuf
import SwiftProtobufPluginLibrary

/// Interface for field generators.
protocol FieldGenerator {
    var number: Int { get }

    /// Writes the field's name information to the given bytecode stream.
    func writeProtoNameInstruction(to writer: inout ProtoNameInstructionWriter)

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

/// Simple base class for FieldGenerators that also provides `writeProtoNameInstruction(to:)`.
class FieldGeneratorBase {
    let number: Int
    let fieldDescriptor: FieldDescriptor

    func writeProtoNameInstruction(to writer: inout ProtoNameInstructionWriter) {
        // Protobuf Text uses the unqualified group name for the field
        // name instead of the field name provided by protoc.  As far
        // as I can tell, no one uses the fieldname provided by protoc,
        // so let's just put the field name that Protobuf Text
        // actually uses here.
        let protoName: String
        if fieldDescriptor.isGroupLike {
            protoName = fieldDescriptor.messageType!.name
        } else {
            protoName = fieldDescriptor.name
        }
        let jsonName = fieldDescriptor.jsonName

        if fieldDescriptor.isGroupLike {
            // This behavior is guaranteed by the spec/proto compiler, so we
            // rely on it. Fail if this is ever not the case.
            assert(
                jsonName == protoName.lowercased(),
                "The JSON name of a group should always be the lowercased message name"
            )
            writer.writeGroup(number: Int32(number), name: protoName)
        } else if jsonName == protoName {
            // The proto and JSON names are identical.
            writer.writeSame(number: Int32(number), name: protoName)
        } else {
            let libraryGeneratedJsonName = NamingUtils.toJsonFieldName(protoName)
            if jsonName == libraryGeneratedJsonName {
                // The library will generate the same thing protoc gave, so
                // we can let the library recompute this.
                writer.writeStandard(number: Int32(number), name: protoName)
            } else {
                // The library's generation didn't match, so specify this explicitly.
                writer.writeUnique(number: Int32(number), protoName: protoName, jsonName: jsonName)
            }
        }
    }

    init(descriptor: FieldDescriptor) {
        number = Int(descriptor.number)
        fieldDescriptor = descriptor
    }
}
