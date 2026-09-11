// Sources/SwiftProtobuf/FieldTypes.swift - Proto data types
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
//
// Serialization/deserialization support for each proto field type.
//
// Note that we cannot just extend the standard Int32, etc, types
// with serialization information since proto language supports
// distinct types (with different codings) that use the same
// in-memory representation.  For example, proto "sint32" and
// "sfixed32" both use Int32 as their in-memory representation.
//
// Generated code uses these types generically and also passes
// them into various coding/decoding functions to provide
// type-specific information.
//
// -----------------------------------------------------------------------------

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

// Note: The protobuf- and JSON-specific methods here are defined
// in ProtobufTypeAdditions.swift and JSONTypeAdditions.swift
/// A description of how to encode and decode a single proto field type.
@preconcurrency
public protocol FieldType: Sendable {
    // The Swift type used to store data for this field.  For example,
    // proto "sint32" fields use Swift "Int32" type.
    associatedtype BaseType: Hashable, Sendable

    // The default value for this field type before it has been set.
    // This is also used, for example, when JSON decodes a "null"
    // value for a field.
    static var proto3DefaultValue: BaseType { get }

    // Generic reflector methods for looking up the correct
    // encoding/decoding for extension fields, map keys, and map
    // values.
    static func decodeSingular<D: Decoder>(value: inout BaseType?, from decoder: inout D) throws
    static func decodeRepeated<D: Decoder>(value: inout [BaseType], from decoder: inout D) throws
    static func visitSingular<V: Visitor>(value: BaseType, fieldNumber: Int, with visitor: inout V) throws
    static func visitRepeated<V: Visitor>(value: [BaseType], fieldNumber: Int, with visitor: inout V) throws
    static func visitPacked<V: Visitor>(value: [BaseType], fieldNumber: Int, with visitor: inout V) throws
}

///
/// Marker protocol for types usable as map keys
///
@preconcurrency
public protocol MapKeyType: FieldType {
    /// A comparison function that encoders use to order map keys
    /// deterministically.  Can't use `Comparable`
    /// because `Bool` doesn't conform, and since it is `public` there is no way
    /// to add a conformance internal to SwiftProtobuf.
    static func _lessThan(lhs: BaseType, rhs: BaseType) -> Bool
}

// Default impl for anything `Comparable`
extension MapKeyType where BaseType: Comparable {
    /// Compares two values using their natural ordering.
    public static func _lessThan(lhs: BaseType, rhs: BaseType) -> Bool {
        lhs < rhs
    }
}

///
/// Marker Protocol for types usable as map values.
///
@preconcurrency
public protocol MapValueType: FieldType {
}

//
// We have a struct for every basic proto field type which provides
// serialization/deserialization support as static methods.
//

///
/// Float traits
///
public struct ProtobufFloat: FieldType, MapValueType {
    /// The type that stores a float field's value.
    public typealias BaseType = Float

    /// The default value of a proto3 float field before you set it.
    public static var proto3DefaultValue: Float { 0.0 }

    /// Decodes a singular float field's value from the decoder you provide.
    public static func decodeSingular<D: Decoder>(value: inout BaseType?, from decoder: inout D) throws {
        try decoder.decodeSingularFloatField(value: &value)
    }

    /// Decodes a repeated float field's values from the decoder you provide.
    public static func decodeRepeated<D: Decoder>(value: inout [BaseType], from decoder: inout D) throws {
        try decoder.decodeRepeatedFloatField(value: &value)
    }

    /// Visits a singular float field with the visitor you provide.
    public static func visitSingular<V: Visitor>(value: BaseType, fieldNumber: Int, with visitor: inout V) throws {
        try visitor.visitSingularFloatField(value: value, fieldNumber: fieldNumber)
    }

    /// Visits a repeated float field with the visitor you provide.
    public static func visitRepeated<V: Visitor>(value: [BaseType], fieldNumber: Int, with visitor: inout V) throws {
        try visitor.visitRepeatedFloatField(value: value, fieldNumber: fieldNumber)
    }

    /// Visits a packed, repeated float field with the visitor you provide.
    public static func visitPacked<V: Visitor>(value: [BaseType], fieldNumber: Int, with visitor: inout V) throws {
        try visitor.visitPackedFloatField(value: value, fieldNumber: fieldNumber)
    }
}

///
/// Double
///
public struct ProtobufDouble: FieldType, MapValueType {
    /// The type that stores a double field's value.
    public typealias BaseType = Double

    /// The default value of a proto3 double field before you set it.
    public static var proto3DefaultValue: Double { 0.0 }

    /// Decodes a singular double field's value from the decoder you provide.
    public static func decodeSingular<D: Decoder>(value: inout BaseType?, from decoder: inout D) throws {
        try decoder.decodeSingularDoubleField(value: &value)
    }

    /// Decodes a repeated double field's values from the decoder you provide.
    public static func decodeRepeated<D: Decoder>(value: inout [BaseType], from decoder: inout D) throws {
        try decoder.decodeRepeatedDoubleField(value: &value)
    }

    /// Visits a singular double field with the visitor you provide.
    public static func visitSingular<V: Visitor>(value: BaseType, fieldNumber: Int, with visitor: inout V) throws {
        try visitor.visitSingularDoubleField(value: value, fieldNumber: fieldNumber)
    }

    /// Visits a repeated double field with the visitor you provide.
    public static func visitRepeated<V: Visitor>(value: [BaseType], fieldNumber: Int, with visitor: inout V) throws {
        try visitor.visitRepeatedDoubleField(value: value, fieldNumber: fieldNumber)
    }

    /// Visits a packed, repeated double field with the visitor you provide.
    public static func visitPacked<V: Visitor>(value: [BaseType], fieldNumber: Int, with visitor: inout V) throws {
        try visitor.visitPackedDoubleField(value: value, fieldNumber: fieldNumber)
    }
}

///
/// Int32
///
public struct ProtobufInt32: FieldType, MapKeyType, MapValueType {
    /// The type that stores a 32-bit integer field's value.
    public typealias BaseType = Int32

    /// The default value of a proto3 32-bit integer field before you set it.
    public static var proto3DefaultValue: Int32 { 0 }

    /// Decodes a singular 32-bit integer field's value from the decoder you provide.
    public static func decodeSingular<D: Decoder>(value: inout BaseType?, from decoder: inout D) throws {
        try decoder.decodeSingularInt32Field(value: &value)
    }

    /// Decodes a repeated 32-bit integer field's values from the decoder you provide.
    public static func decodeRepeated<D: Decoder>(value: inout [BaseType], from decoder: inout D) throws {
        try decoder.decodeRepeatedInt32Field(value: &value)
    }

    /// Visits a singular 32-bit integer field with the visitor you provide.
    public static func visitSingular<V: Visitor>(value: BaseType, fieldNumber: Int, with visitor: inout V) throws {
        try visitor.visitSingularInt32Field(value: value, fieldNumber: fieldNumber)
    }

    /// Visits a repeated 32-bit integer field with the visitor you provide.
    public static func visitRepeated<V: Visitor>(value: [BaseType], fieldNumber: Int, with visitor: inout V) throws {
        try visitor.visitRepeatedInt32Field(value: value, fieldNumber: fieldNumber)
    }

    /// Visits a packed, repeated 32-bit integer field with the visitor you provide.
    public static func visitPacked<V: Visitor>(value: [BaseType], fieldNumber: Int, with visitor: inout V) throws {
        try visitor.visitPackedInt32Field(value: value, fieldNumber: fieldNumber)
    }
}

///
/// Int64
///

public struct ProtobufInt64: FieldType, MapKeyType, MapValueType {
    /// The type that stores a 64-bit integer field's value.
    public typealias BaseType = Int64

    /// The default value of a proto3 64-bit integer field before you set it.
    public static var proto3DefaultValue: Int64 { 0 }

    /// Decodes a singular 64-bit integer field's value from the decoder you provide.
    public static func decodeSingular<D: Decoder>(value: inout BaseType?, from decoder: inout D) throws {
        try decoder.decodeSingularInt64Field(value: &value)
    }

    /// Decodes a repeated 64-bit integer field's values from the decoder you provide.
    public static func decodeRepeated<D: Decoder>(value: inout [BaseType], from decoder: inout D) throws {
        try decoder.decodeRepeatedInt64Field(value: &value)
    }

    /// Visits a singular 64-bit integer field with the visitor you provide.
    public static func visitSingular<V: Visitor>(value: BaseType, fieldNumber: Int, with visitor: inout V) throws {
        try visitor.visitSingularInt64Field(value: value, fieldNumber: fieldNumber)
    }

    /// Visits a repeated 64-bit integer field with the visitor you provide.
    public static func visitRepeated<V: Visitor>(value: [BaseType], fieldNumber: Int, with visitor: inout V) throws {
        try visitor.visitRepeatedInt64Field(value: value, fieldNumber: fieldNumber)
    }

    /// Visits a packed, repeated 64-bit integer field with the visitor you provide.
    public static func visitPacked<V: Visitor>(value: [BaseType], fieldNumber: Int, with visitor: inout V) throws {
        try visitor.visitPackedInt64Field(value: value, fieldNumber: fieldNumber)
    }
}

///
/// UInt32
///
public struct ProtobufUInt32: FieldType, MapKeyType, MapValueType {
    /// The type that stores a 32-bit unsigned integer field's value.
    public typealias BaseType = UInt32

    /// The default value of a proto3 32-bit unsigned integer field before you set it.
    public static var proto3DefaultValue: UInt32 { 0 }

    /// Decodes a singular 32-bit unsigned integer field's value from the decoder you provide.
    public static func decodeSingular<D: Decoder>(value: inout BaseType?, from decoder: inout D) throws {
        try decoder.decodeSingularUInt32Field(value: &value)
    }

    /// Decodes a repeated 32-bit unsigned integer field's values from the decoder you provide.
    public static func decodeRepeated<D: Decoder>(value: inout [BaseType], from decoder: inout D) throws {
        try decoder.decodeRepeatedUInt32Field(value: &value)
    }

    /// Visits a singular 32-bit unsigned integer field with the visitor you provide.
    public static func visitSingular<V: Visitor>(value: BaseType, fieldNumber: Int, with visitor: inout V) throws {
        try visitor.visitSingularUInt32Field(value: value, fieldNumber: fieldNumber)
    }

    /// Visits a repeated 32-bit unsigned integer field with the visitor you provide.
    public static func visitRepeated<V: Visitor>(value: [BaseType], fieldNumber: Int, with visitor: inout V) throws {
        try visitor.visitRepeatedUInt32Field(value: value, fieldNumber: fieldNumber)
    }

    /// Visits a packed, repeated 32-bit unsigned integer field with the visitor you provide.
    public static func visitPacked<V: Visitor>(value: [BaseType], fieldNumber: Int, with visitor: inout V) throws {
        try visitor.visitPackedUInt32Field(value: value, fieldNumber: fieldNumber)
    }
}

///
/// UInt64
///

public struct ProtobufUInt64: FieldType, MapKeyType, MapValueType {
    /// The type that stores a 64-bit unsigned integer field's value.
    public typealias BaseType = UInt64

    /// The default value of a proto3 64-bit unsigned integer field before you set it.
    public static var proto3DefaultValue: UInt64 { 0 }

    /// Decodes a singular 64-bit unsigned integer field's value from the decoder you provide.
    public static func decodeSingular<D: Decoder>(value: inout BaseType?, from decoder: inout D) throws {
        try decoder.decodeSingularUInt64Field(value: &value)
    }

    /// Decodes a repeated 64-bit unsigned integer field's values from the decoder you provide.
    public static func decodeRepeated<D: Decoder>(value: inout [BaseType], from decoder: inout D) throws {
        try decoder.decodeRepeatedUInt64Field(value: &value)
    }

    /// Visits a singular 64-bit unsigned integer field with the visitor you provide.
    public static func visitSingular<V: Visitor>(value: BaseType, fieldNumber: Int, with visitor: inout V) throws {
        try visitor.visitSingularUInt64Field(value: value, fieldNumber: fieldNumber)
    }

    /// Visits a repeated 64-bit unsigned integer field with the visitor you provide.
    public static func visitRepeated<V: Visitor>(value: [BaseType], fieldNumber: Int, with visitor: inout V) throws {
        try visitor.visitRepeatedUInt64Field(value: value, fieldNumber: fieldNumber)
    }

    /// Visits a packed, repeated 64-bit unsigned integer field with the visitor you provide.
    public static func visitPacked<V: Visitor>(value: [BaseType], fieldNumber: Int, with visitor: inout V) throws {
        try visitor.visitPackedUInt64Field(value: value, fieldNumber: fieldNumber)
    }
}

///
/// SInt32
///
public struct ProtobufSInt32: FieldType, MapKeyType, MapValueType {
    /// The type that stores a zigzag-encoded 32-bit integer field's value.
    public typealias BaseType = Int32

    /// The default value of a proto3 zigzag-encoded 32-bit integer field before you set it.
    public static var proto3DefaultValue: Int32 { 0 }

    /// Decodes a singular zigzag-encoded 32-bit integer field's value from the decoder you provide.
    public static func decodeSingular<D: Decoder>(value: inout BaseType?, from decoder: inout D) throws {
        try decoder.decodeSingularSInt32Field(value: &value)
    }

    /// Decodes a repeated zigzag-encoded 32-bit integer field's values from the decoder you provide.
    public static func decodeRepeated<D: Decoder>(value: inout [BaseType], from decoder: inout D) throws {
        try decoder.decodeRepeatedSInt32Field(value: &value)
    }

    /// Visits a singular zigzag-encoded 32-bit integer field with the visitor you provide.
    public static func visitSingular<V: Visitor>(value: BaseType, fieldNumber: Int, with visitor: inout V) throws {
        try visitor.visitSingularSInt32Field(value: value, fieldNumber: fieldNumber)
    }

    /// Visits a repeated zigzag-encoded 32-bit integer field with the visitor you provide.
    public static func visitRepeated<V: Visitor>(value: [BaseType], fieldNumber: Int, with visitor: inout V) throws {
        try visitor.visitRepeatedSInt32Field(value: value, fieldNumber: fieldNumber)
    }

    /// Visits a packed, repeated zigzag-encoded 32-bit integer field with the visitor you provide.
    public static func visitPacked<V: Visitor>(value: [BaseType], fieldNumber: Int, with visitor: inout V) throws {
        try visitor.visitPackedSInt32Field(value: value, fieldNumber: fieldNumber)
    }
}

///
/// SInt64
///

public struct ProtobufSInt64: FieldType, MapKeyType, MapValueType {
    /// The type that stores a zigzag-encoded 64-bit integer field's value.
    public typealias BaseType = Int64

    /// The default value of a proto3 zigzag-encoded 64-bit integer field before you set it.
    public static var proto3DefaultValue: Int64 { 0 }

    /// Decodes a singular zigzag-encoded 64-bit integer field's value from the decoder you provide.
    public static func decodeSingular<D: Decoder>(value: inout BaseType?, from decoder: inout D) throws {
        try decoder.decodeSingularSInt64Field(value: &value)
    }

    /// Decodes a repeated zigzag-encoded 64-bit integer field's values from the decoder you provide.
    public static func decodeRepeated<D: Decoder>(value: inout [BaseType], from decoder: inout D) throws {
        try decoder.decodeRepeatedSInt64Field(value: &value)
    }

    /// Visits a singular zigzag-encoded 64-bit integer field with the visitor you provide.
    public static func visitSingular<V: Visitor>(value: BaseType, fieldNumber: Int, with visitor: inout V) throws {
        try visitor.visitSingularSInt64Field(value: value, fieldNumber: fieldNumber)
    }

    /// Visits a repeated zigzag-encoded 64-bit integer field with the visitor you provide.
    public static func visitRepeated<V: Visitor>(value: [BaseType], fieldNumber: Int, with visitor: inout V) throws {
        try visitor.visitRepeatedSInt64Field(value: value, fieldNumber: fieldNumber)
    }

    /// Visits a packed, repeated zigzag-encoded 64-bit integer field with the visitor you provide.
    public static func visitPacked<V: Visitor>(value: [BaseType], fieldNumber: Int, with visitor: inout V) throws {
        try visitor.visitPackedSInt64Field(value: value, fieldNumber: fieldNumber)
    }
}

///
/// Fixed32
///
public struct ProtobufFixed32: FieldType, MapKeyType, MapValueType {
    /// The type that stores a fixed-width 32-bit unsigned integer field's value.
    public typealias BaseType = UInt32

    /// The default value of a proto3 fixed-width 32-bit unsigned integer field before you set it.
    public static var proto3DefaultValue: UInt32 { 0 }

    /// Decodes a singular fixed-width 32-bit unsigned integer field's value from the decoder you provide.
    public static func decodeSingular<D: Decoder>(value: inout BaseType?, from decoder: inout D) throws {
        try decoder.decodeSingularFixed32Field(value: &value)
    }

    /// Decodes a repeated fixed-width 32-bit unsigned integer field's values from the decoder you provide.
    public static func decodeRepeated<D: Decoder>(value: inout [BaseType], from decoder: inout D) throws {
        try decoder.decodeRepeatedFixed32Field(value: &value)
    }

    /// Visits a singular fixed-width 32-bit unsigned integer field with the visitor you provide.
    public static func visitSingular<V: Visitor>(value: BaseType, fieldNumber: Int, with visitor: inout V) throws {
        try visitor.visitSingularFixed32Field(value: value, fieldNumber: fieldNumber)
    }

    /// Visits a repeated fixed-width 32-bit unsigned integer field with the visitor you provide.
    public static func visitRepeated<V: Visitor>(value: [BaseType], fieldNumber: Int, with visitor: inout V) throws {
        try visitor.visitRepeatedFixed32Field(value: value, fieldNumber: fieldNumber)
    }

    /// Visits a packed, repeated fixed-width 32-bit unsigned integer field with the visitor you provide.
    public static func visitPacked<V: Visitor>(value: [BaseType], fieldNumber: Int, with visitor: inout V) throws {
        try visitor.visitPackedFixed32Field(value: value, fieldNumber: fieldNumber)
    }
}

///
/// Fixed64
///
public struct ProtobufFixed64: FieldType, MapKeyType, MapValueType {
    /// The type that stores a fixed-width 64-bit unsigned integer field's value.
    public typealias BaseType = UInt64

    /// The default value of a proto3 fixed-width 64-bit unsigned integer field before you set it.
    public static var proto3DefaultValue: UInt64 { 0 }

    /// Decodes a singular fixed-width 64-bit unsigned integer field's value from the decoder you provide.
    public static func decodeSingular<D: Decoder>(value: inout BaseType?, from decoder: inout D) throws {
        try decoder.decodeSingularFixed64Field(value: &value)
    }

    /// Decodes a repeated fixed-width 64-bit unsigned integer field's values from the decoder you provide.
    public static func decodeRepeated<D: Decoder>(value: inout [BaseType], from decoder: inout D) throws {
        try decoder.decodeRepeatedFixed64Field(value: &value)
    }

    /// Visits a singular fixed-width 64-bit unsigned integer field with the visitor you provide.
    public static func visitSingular<V: Visitor>(value: BaseType, fieldNumber: Int, with visitor: inout V) throws {
        try visitor.visitSingularFixed64Field(value: value, fieldNumber: fieldNumber)
    }

    /// Visits a repeated fixed-width 64-bit unsigned integer field with the visitor you provide.
    public static func visitRepeated<V: Visitor>(value: [BaseType], fieldNumber: Int, with visitor: inout V) throws {
        try visitor.visitRepeatedFixed64Field(value: value, fieldNumber: fieldNumber)
    }

    /// Visits a packed, repeated fixed-width 64-bit unsigned integer field with the visitor you provide.
    public static func visitPacked<V: Visitor>(value: [BaseType], fieldNumber: Int, with visitor: inout V) throws {
        try visitor.visitPackedFixed64Field(value: value, fieldNumber: fieldNumber)
    }
}

///
/// SFixed32
///
public struct ProtobufSFixed32: FieldType, MapKeyType, MapValueType {
    /// The type that stores a fixed-width 32-bit integer field's value.
    public typealias BaseType = Int32

    /// The default value of a proto3 fixed-width 32-bit integer field before you set it.
    public static var proto3DefaultValue: Int32 { 0 }

    /// Decodes a singular fixed-width 32-bit integer field's value from the decoder you provide.
    public static func decodeSingular<D: Decoder>(value: inout BaseType?, from decoder: inout D) throws {
        try decoder.decodeSingularSFixed32Field(value: &value)
    }

    /// Decodes a repeated fixed-width 32-bit integer field's values from the decoder you provide.
    public static func decodeRepeated<D: Decoder>(value: inout [BaseType], from decoder: inout D) throws {
        try decoder.decodeRepeatedSFixed32Field(value: &value)
    }

    /// Visits a singular fixed-width 32-bit integer field with the visitor you provide.
    public static func visitSingular<V: Visitor>(value: BaseType, fieldNumber: Int, with visitor: inout V) throws {
        try visitor.visitSingularSFixed32Field(value: value, fieldNumber: fieldNumber)
    }

    /// Visits a repeated fixed-width 32-bit integer field with the visitor you provide.
    public static func visitRepeated<V: Visitor>(value: [BaseType], fieldNumber: Int, with visitor: inout V) throws {
        try visitor.visitRepeatedSFixed32Field(value: value, fieldNumber: fieldNumber)
    }

    /// Visits a packed, repeated fixed-width 32-bit integer field with the visitor you provide.
    public static func visitPacked<V: Visitor>(value: [BaseType], fieldNumber: Int, with visitor: inout V) throws {
        try visitor.visitPackedSFixed32Field(value: value, fieldNumber: fieldNumber)
    }
}

///
/// SFixed64
///
public struct ProtobufSFixed64: FieldType, MapKeyType, MapValueType {
    /// The type that stores a fixed-width 64-bit integer field's value.
    public typealias BaseType = Int64

    /// The default value of a proto3 fixed-width 64-bit integer field before you set it.
    public static var proto3DefaultValue: Int64 { 0 }

    /// Decodes a singular fixed-width 64-bit integer field's value from the decoder you provide.
    public static func decodeSingular<D: Decoder>(value: inout BaseType?, from decoder: inout D) throws {
        try decoder.decodeSingularSFixed64Field(value: &value)
    }

    /// Decodes a repeated fixed-width 64-bit integer field's values from the decoder you provide.
    public static func decodeRepeated<D: Decoder>(value: inout [BaseType], from decoder: inout D) throws {
        try decoder.decodeRepeatedSFixed64Field(value: &value)
    }

    /// Visits a singular fixed-width 64-bit integer field with the visitor you provide.
    public static func visitSingular<V: Visitor>(value: BaseType, fieldNumber: Int, with visitor: inout V) throws {
        try visitor.visitSingularSFixed64Field(value: value, fieldNumber: fieldNumber)
    }

    /// Visits a repeated fixed-width 64-bit integer field with the visitor you provide.
    public static func visitRepeated<V: Visitor>(value: [BaseType], fieldNumber: Int, with visitor: inout V) throws {
        try visitor.visitRepeatedSFixed64Field(value: value, fieldNumber: fieldNumber)
    }

    /// Visits a packed, repeated fixed-width 64-bit integer field with the visitor you provide.
    public static func visitPacked<V: Visitor>(value: [BaseType], fieldNumber: Int, with visitor: inout V) throws {
        try visitor.visitPackedSFixed64Field(value: value, fieldNumber: fieldNumber)
    }
}

///
/// Bool
///
public struct ProtobufBool: FieldType, MapKeyType, MapValueType {
    /// The type that stores a Boolean field's value.
    public typealias BaseType = Bool

    /// The default value of a proto3 Boolean field before you set it.
    public static var proto3DefaultValue: Bool { false }

    /// Decodes a singular Boolean field's value from the decoder you provide.
    public static func decodeSingular<D: Decoder>(value: inout BaseType?, from decoder: inout D) throws {
        try decoder.decodeSingularBoolField(value: &value)
    }

    /// Decodes a repeated Boolean field's values from the decoder you provide.
    public static func decodeRepeated<D: Decoder>(value: inout [BaseType], from decoder: inout D) throws {
        try decoder.decodeRepeatedBoolField(value: &value)
    }

    /// Visits a singular Boolean field with the visitor you provide.
    public static func visitSingular<V: Visitor>(value: BaseType, fieldNumber: Int, with visitor: inout V) throws {
        try visitor.visitSingularBoolField(value: value, fieldNumber: fieldNumber)
    }

    /// Visits a repeated Boolean field with the visitor you provide.
    public static func visitRepeated<V: Visitor>(value: [BaseType], fieldNumber: Int, with visitor: inout V) throws {
        try visitor.visitRepeatedBoolField(value: value, fieldNumber: fieldNumber)
    }

    /// Visits a packed, repeated Boolean field with the visitor you provide.
    public static func visitPacked<V: Visitor>(value: [BaseType], fieldNumber: Int, with visitor: inout V) throws {
        try visitor.visitPackedBoolField(value: value, fieldNumber: fieldNumber)
    }

    /// Provides the ordering encoders use when boolean values are map keys.
    ///
    /// Bool doesn't conform to Comparable, so this custom comparison stands in for it.
    public static func _lessThan(lhs: BaseType, rhs: BaseType) -> Bool {
        if !lhs {
            return rhs
        }
        return false
    }
}

///
/// String
///
public struct ProtobufString: FieldType, MapKeyType, MapValueType {
    /// The type that stores a string field's value.
    public typealias BaseType = String

    /// The default value of a proto3 string field before you set it.
    public static var proto3DefaultValue: String { String() }

    /// Decodes a singular string field's value from the decoder you provide.
    public static func decodeSingular<D: Decoder>(value: inout BaseType?, from decoder: inout D) throws {
        try decoder.decodeSingularStringField(value: &value)
    }

    /// Decodes a repeated string field's values from the decoder you provide.
    public static func decodeRepeated<D: Decoder>(value: inout [BaseType], from decoder: inout D) throws {
        try decoder.decodeRepeatedStringField(value: &value)
    }

    /// Visits a singular string field with the visitor you provide.
    public static func visitSingular<V: Visitor>(value: BaseType, fieldNumber: Int, with visitor: inout V) throws {
        try visitor.visitSingularStringField(value: value, fieldNumber: fieldNumber)
    }

    /// Visits a repeated string field with the visitor you provide.
    public static func visitRepeated<V: Visitor>(value: [BaseType], fieldNumber: Int, with visitor: inout V) throws {
        try visitor.visitRepeatedStringField(value: value, fieldNumber: fieldNumber)
    }

    /// Never called, since string fields can't use packed encoding.
    public static func visitPacked<V: Visitor>(value: [BaseType], fieldNumber: Int, with visitor: inout V) throws {
        assert(false)
    }
}

///
/// Bytes
///
public struct ProtobufBytes: FieldType, MapValueType {
    /// The type that stores a bytes field's value.
    public typealias BaseType = Data

    /// The default value of a proto3 bytes field before you set it.
    public static var proto3DefaultValue: Data { Data() }

    /// Decodes a singular bytes field's value from the decoder you provide.
    public static func decodeSingular<D: Decoder>(value: inout BaseType?, from decoder: inout D) throws {
        try decoder.decodeSingularBytesField(value: &value)
    }

    /// Decodes a repeated bytes field's values from the decoder you provide.
    public static func decodeRepeated<D: Decoder>(value: inout [BaseType], from decoder: inout D) throws {
        try decoder.decodeRepeatedBytesField(value: &value)
    }

    /// Visits a singular bytes field with the visitor you provide.
    public static func visitSingular<V: Visitor>(value: BaseType, fieldNumber: Int, with visitor: inout V) throws {
        try visitor.visitSingularBytesField(value: value, fieldNumber: fieldNumber)
    }

    /// Visits a repeated bytes field with the visitor you provide.
    public static func visitRepeated<V: Visitor>(value: [BaseType], fieldNumber: Int, with visitor: inout V) throws {
        try visitor.visitRepeatedBytesField(value: value, fieldNumber: fieldNumber)
    }

    /// Never called, since bytes fields can't use packed encoding.
    public static func visitPacked<V: Visitor>(value: [BaseType], fieldNumber: Int, with visitor: inout V) throws {
        assert(false)
    }
}
