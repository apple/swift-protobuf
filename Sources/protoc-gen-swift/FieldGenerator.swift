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
/// how well they are packed to avoid excessive padding (by keeping values with smaller alignments
/// together) and grouping all trivial fields together before non-trivial fields.
package enum FieldStorageKind: Comparable {
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

/// Information about a field that needs to be part of trampoline function generation.
package enum TrampolineFieldKind {
    /// The field is a message type or an array of a message type.
    ///
    /// The associated value is the full Swift name of that (possibly array) type.
    case message(String, isArray: Bool)

    /// The field is an enum type or an array of an enum type.
    ///
    /// The associated value is the full Swift name of that (possibly array) type.
    case `enum`(String, isArray: Bool)

    /// The field is a map type.
    ///
    /// The associated value is the full Swift name of that type and the raw field
    /// types of the key and value.
    case map(String, keyType: RawFieldType, valueType: RawFieldType)

    /// The full Swift name of the (possibly array) type of the field.
    var name: String {
        switch self {
        case .message(let name, let isArray): isArray ? "[\(name)]" : name
        case .enum(let name, let isArray): isArray ? "[\(name)]" : name
        case .map(let name, _, _): name
        }
    }

    /// The full Swift name of the type of the field, ignoring arrays.
    ///
    /// If this does correspond to a repeated array, the name returned is the element type, not the
    /// array type.
    var singularName: String {
        switch self {
        case .message(let name, _): name
        case .enum(let name, _): name
        case .map: preconditionFailure("Should never be called")
        }
    }
}

/// Uniquely identifies a field that needs to be generated into trampoline
/// functions so that multiple fields with the same Swift type and wire formats
/// can be deduplicated.
///
/// When deduplicating, just using the Swift type name alone is not enough for
/// maps because a key or value type of `Int64`, for example, could have different
/// wire formats (varint vs. zigzag varint vs. fixed) and we need to preserve
/// that information in the map entry schema.
struct TrampolineFieldKey: Equatable, Hashable {
    var name: String
    var keyType: RawFieldType? = nil
    var valueType: RawFieldType? = nil
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

    /// The kind and name of a message, group, or enum field that needs trampoline generation.
    var trampolineFieldKind: TrampolineFieldKind? { get }

    /// Additional properties that describe the layout and behavior of the field.
    var fieldMode: FieldMode { get }

    /// An abstract representation of how the field is stored in memory.
    ///
    /// Since the size of a field may be platform-specific depending on the field's type, this
    /// represents a "storage class" that can be turned into a concrete size later in a context
    /// where the platform is known.
    var storageKind: FieldStorageKind { get }

    /// The index of the `oneof` of which this field is a member, or `nil` if it is not a member of
    /// a `oneof`.
    var oneofIndex: Int? { get }

    /// The presence information for this field.
    ///
    /// This is expected to be populated during an iteration that computes the in-memory layout of
    /// the message.
    var presence: FieldPresence { get set }

    /// The offsets in bytes into in-memory storage where this field is stored, for 64-bit and
    /// 32-bit platforms.
    ///
    /// This is expected to be populated during an iteration that computes the in-memory layout of
    /// the message.
    var storageOffsets: TargetSpecificValues<Int> { get set }

    /// Indicates whether this field should cause its parent message to have `isInitialized`
    /// generated.
    var needsIsInitializedGeneration: Bool { get }

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

    var storageOffsets = TargetSpecificValues(forAllTargets: 0)

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

    /// Generates the Swift expression that will be used by the field's accessors to specify the
    /// field's offset in memory, taking into account the target platform.
    var storageOffsetExpression: String {
        // If all the values are the same, generate cleaner code by just passing the single value
        // directly.
        if let valueIfAllEqual = storageOffsets.valueIfAllEqual {
            return "\(valueIfAllEqual)"
        }

        // Otherwise, generate a call to the helper function that chooses the right value based on
        // target platform.
        let fieldOffsetArguments = TargetSpecificValueChoice.allCases.map {
            "\(storageOffsets[$0])"
        }.joined(separator: ", ")
        return "SwiftProtobuf._fieldOffset(\(fieldOffsetArguments))"
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
