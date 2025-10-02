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

/// Abstractly represents the amount of memory needed to store a field's value in memory.
///
/// The order of these cases is important, because the fields in a message will be ordered such
/// that their layout in-memory is in these groups. This allows us to optimize across two factors:
/// how well they are packed (by keeping values with smaller alignments together) and grouping all
/// trivial fields together before non-trivial fields.
enum FieldStorageKind: Comparable {
    /// The field occupies 1 byte in memory, regardless of target architecture.
    case oneByteScalar

    /// The field occupies 4 bytes in memory, regardless of target architecture.
    case fourByteScalar

    /// The field occupies 8 bytes in memory, regardless of target architecture.
    case eightByteScalar

    /// The field occupies a pointer's width in memory; 8 bytes on 64-bit and 4 bytes on 32-bit.
    case pointer

    /// The field is a Swift `String` or a Foundation `Data` value, which have a 16 byte stride on
    /// 64-bit and a 12 byte stride on 32-bit.
    case stringOrData

    /// Returns the number of bytes that a field with this storage kind occupies in memory,
    /// including alignment padding.
    var strides: TargetSpecificValues<Int> {
        switch self {
        case .oneByteScalar: return .init(forAllTargets: 1)
        case .fourByteScalar: return .init(forAllTargets: 4)
        case .eightByteScalar: return .init(forAllTargets: 8)
        case .pointer: return .init([.pointerWidth64: 8, .pointerWidth32: 4])
        case .stringOrData: return .init([.pointerWidth64: 16, .pointerWidth32: 12])
        }
    }
}

/// Interface for field generators.
protocol FieldGenerator: AnyObject {
    /// The field number of the field.
    var number: Int { get }

    /// Indicates whether or not the field is a required field.
    var isRequired: Bool { get }

    /// The raw type of the field.
    var rawFieldType: RawFieldType { get }

    /// The fully-qualified name of the Swift message type for this field, if it is a message or
    /// group field.
    var submessageTypeName: String? { get }

    /// Additional properties that describe the layout and behavior of the field.
    var fieldMode: FieldMode { get }

    /// An abstract representation of how the field is stored in memory.
    ///
    /// Since the size of a field may be platform-specific depending on the field's type, this
    /// represents a "storage class" that can be turned into a concrete size later in a context
    /// where the platform is known.
    var storageKind: FieldStorageKind { get }

    /// The presence information for this field.
    ///
    /// The presence of a `oneof` is the bitwise inverse of the byte offset of the location in
    /// memory where the field number of the inhabited `oneof` member is stored. For other fields,
    /// it is the index of the field's has-bit.
    ///
    /// This is expected to be populated during an iteration that computes the in-memory layout of
    /// the message.
    var presence: Int { get set }

    /// The offsets in bytes into in-memory storage where this field is stored, for 64-bit and
    /// 32-bit platforms.
    ///
    /// This is expected to be populated during an iteration that computes the in-memory layout of
    /// the message.
    var storageOffsets: TargetSpecificValues<Int> { get set }

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

    var hasBitIndex: Int = 0

    var storageOffsets = TargetSpecificValues(forAllTargets: 0)

    var isRequired: Bool {
        fieldDescriptor.isRequired
    }

    var rawFieldType: RawFieldType {
        switch fieldDescriptor.type {
        case .bool: return .bool
        case .bytes: return .bytes
        case .double: return .double
        case .enum: return .enum
        case .fixed32: return .fixed32
        case .fixed64: return .fixed64
        case .float: return .float
        case .group: return .group
        case .int32: return .int32
        case .int64: return .int64
        case .message: return .message
        case .sfixed32: return .sfixed32
        case .sfixed64: return .sfixed64
        case .sint32: return .sint32
        case .sint64: return .sint64
        case .string: return .string
        case .uint32: return .uint32
        case .uint64: return .uint64
        }
    }

    var fieldMode: FieldMode {
        var result: FieldMode = .init(rawValue: 0)
        result.isPacked = fieldDescriptor.isPacked
        result.isExtension = fieldDescriptor.isExtension
        if fieldDescriptor.isMap {
            result.cardinality = .map
        } else if fieldDescriptor.isRepeated {
            result.cardinality = .array
        } else {
            result.cardinality = .scalar
        }
        return result
    }

    var storageKind: FieldStorageKind {
        if fieldDescriptor.isRepeated || fieldDescriptor.isMap {
            return .pointer
        }
        switch fieldDescriptor.type {
        case .int64, .uint64, .sint64, .fixed64, .sfixed64, .double:
            return .eightByteScalar
        case .int32, .uint32, .sint32, .fixed32, .sfixed32, .float, .enum:
            return .fourByteScalar
        case .bool:
            return .oneByteScalar
        case .message, .group:
            return .pointer
        case .string, .bytes:
            return .stringOrData
        }
    }

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
