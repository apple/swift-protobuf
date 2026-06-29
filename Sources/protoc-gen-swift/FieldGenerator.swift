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

/// Represents the presence information for a field in memory.
package enum FieldPresence {
    /// The field is not a member of a `oneof` and this is the index of its has-bit.
    case hasBit(UInt16)

    /// The field is a member of a `oneof` and this is the offset of the `UInt32` that records
    /// the field number of its currently set field.
    case oneofMember(UInt16)

    /// The raw unsigned integer that should be stored as the presence field in the memory layout
    /// descriptor.
    var rawPresence: UInt16 {
        switch self {
        case .hasBit(let index): return index
        case .oneofMember(let offset): return ~offset
        }
    }
}

/// References to submessage and enum schemas that are generated into the resolver function.
package enum SubmessageOrEnumReference: Equatable, Hashable {
    /// The field is a singular or repeated message or group type.
    ///
    /// The associated value is the full Swift name of that type.
    case message(String)

    /// The field is a singular or repeated enum type.
    ///
    /// The associated value is the full Swift name of that type.
    case `enum`(String)

    /// The field is a map type.
    ///
    /// The associated value is the name of the schema variable in the containing message that
    /// represents the `MessageSchema` for the map entries.
    case map(String)
}

/// Interface for field generators.
package protocol FieldGenerator: AnyObject {
    /// The field number of the field.
    var number: Int { get }

    /// Indicates whether or not the field is a required field.
    var isRequired: Bool { get }

    /// Indicates whether or not the field has explicit presence.
    var hasPresence: Bool { get }

    /// The raw type of the field.
    var rawFieldType: RawFieldType { get }

    /// The name of the message, group, or enum used by this field, if it's one of those types.
    var submessageOrEnumReference: SubmessageOrEnumReference? { get }

    /// Additional properties that describe the layout and behavior of the field.
    var fieldMode: FieldMode { get }

    /// The stride (and alignment) in bytes that this stable-size field occupies in storage.
    var stableStride: Int { get }

    /// The index of the `oneof` of which this field is a member, or `nil` if it is not a member of
    /// a `oneof`.
    var oneofIndex: Int? { get }

    /// The presence information for this field.
    ///
    /// This is expected to be populated during an iteration that computes the in-memory layout of
    /// the message.
    var presence: FieldPresence { get set }

    /// The offset in bytes into in-memory storage where this field is stored (stable absolute offset
    /// or zero-based unstable index).
    var storageOffsetOrIndex: Int { get set }

    /// The text format name of the field.
    var name: String { get }

    /// The JSON name of the field.
    var jsonName: String { get }

    /// Generate the interface for this field, this is includes any extra methods (has/clear).
    func generateInterface(printer: inout CodePrinter)
}

/// Simple base class for FieldGenerators.
class FieldGeneratorBase {
    let number: Int
    let fieldDescriptor: FieldDescriptor

    var storageOffsetOrIndex = 0

    var isRequired: Bool {
        fieldDescriptor.isRequired
    }

    var hasPresence: Bool {
        fieldDescriptor.hasPresence
    }

    var rawFieldType: RawFieldType {
        RawFieldType(fieldDescriptorType: fieldDescriptor.type)
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

    var name: String {
        if fieldDescriptor.isGroupLike {
            fieldDescriptor.messageType!.name
        } else {
            fieldDescriptor.name
        }
    }

    var jsonName: String {
        // This is guaranteed to be present by an assertion when we build the
        // descriptor objects.
        fieldDescriptor.jsonName!
    }

    init(descriptor: FieldDescriptor) {
        number = Int(descriptor.number)
        fieldDescriptor = descriptor
    }
}

extension RawFieldType {
    /// Creates a new `RawFieldType` from the given field descriptor type enum value.
    init(fieldDescriptorType: Google_Protobuf_FieldDescriptorProto.TypeEnum) {
        switch fieldDescriptorType {
        case .bool: self = .bool
        case .bytes: self = .bytes
        case .double: self = .double
        case .enum: self = .enum
        case .fixed32: self = .fixed32
        case .fixed64: self = .fixed64
        case .float: self = .float
        case .group: self = .group
        case .int32: self = .int32
        case .int64: self = .int64
        case .message: self = .message
        case .sfixed32: self = .sfixed32
        case .sfixed64: self = .sfixed64
        case .sint32: self = .sint32
        case .sint64: self = .sint64
        case .string: self = .string
        case .uint32: self = .uint32
        case .uint64: self = .uint64
        }
    }
}

extension FieldGenerator {
    /// Determines the storage bucket where this field's offset or index is stored.
    package var storageBucket: StorageBucket {
        switch fieldMode.cardinality {
        case .map:
            return .map
        case .array:
            return .repeated
        case .scalar:
            switch rawFieldType {
            case .message, .group:
                return .message
            case .string:
                return .string
            case .bytes:
                return .bytes
            default:
                return .stable
            }
        default:
            preconditionFailure("Unreachable")
        }
    }

    /// The stride (and alignment) in bytes that this stable-size field occupies in storage.
    ///
    /// - Precondition: The field's storage bucket must be `.stable`.
    package var stableStride: Int {
        precondition(storageBucket == .stable)
        switch rawFieldType {
        case .bool:
            return 1
        case .int32, .uint32, .sint32, .fixed32, .sfixed32, .float, .enum:
            return 4
        case .int64, .uint64, .sint64, .fixed64, .sfixed64, .double:
            return 8
        default:
            preconditionFailure("Unexpected stable field type: \(rawFieldType)")
        }
    }
}
