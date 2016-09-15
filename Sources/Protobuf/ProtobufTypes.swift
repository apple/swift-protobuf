// ProtobufRuntime/Sources/Protobuf/ProtobufTypes.swift - Proto data types
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
// -----------------------------------------------------------------------------
///
/// Since proto types do not 1:1 map to Swift types, we need a way to
/// specify encoding, hash, equality, and other common abilities.
/// These types are extended in the Binary and JSON portions of the runtime
/// with additional coding and decoding details.
///
// -----------------------------------------------------------------------------

import Foundation
import Swift

///
/// Core support for each proto data type.
///
/// Note that we cannot just extend the standard Int32, etc, types
/// with serialization information since proto language supports
/// distinct types (with different codings) that use the same
/// in-memory representation.  For example, proto "sint32" and
/// "sfixed32" both are represented in-memory as Int32.
///
/// These types are used generically and also passed into
/// various coding/decoding functions to provide type-specific
/// information.
///
/// The types defined here are extended in ProtobufBinaryTypes.swift
/// with serialization support for binary protobuf encoding, and in
/// ProtobufJSONTypes.swift with serialization support for JSON encoding.
///
public protocol ProtobufTypePropertiesBase {
    // Default here is appropriate for enums and messages
    // Other types will override this
    associatedtype BaseType = Self

    /// Hash the provided value
    /// TODO: Can we just replace this with .hashValue everywhere?
    static func hash(value: BaseType) -> Int

    /// Test if two values are equal
    /// TODO: Can we just replace this with == everywhere?
    static func isEqual(_ lhs: BaseType, _ rhs: BaseType) -> Bool
}

public extension ProtobufTypePropertiesBase where BaseType: Hashable {
    public static func hash(value: BaseType) -> Int {return value.hashValue}
    public static func isEqual(_ lhs: BaseType, _ rhs: BaseType) -> Bool {return lhs == rhs}
}


public protocol ProtobufTypeProperties: ProtobufJSONCodableType, ProtobufBinaryCodableType {
}

///
/// Protocol for types that can be used as map keys
///
public protocol ProtobufMapKeyType: ProtobufJSONCodableMapKeyType, ProtobufBinaryCodableMapKeyType {
}

///
/// Marker protocol for types that can be used as map values.
///
public protocol ProtobufMapValueType: ProtobufTypeProperties {
}

//
// We have a protocol for every wire type defining the base serialization for that type.
//

///
/// Float traits
///
public struct ProtobufFloat: ProtobufTypeProperties, ProtobufMapValueType {
    public typealias BaseType = Float
}

///
/// Double
///
public struct ProtobufDouble: ProtobufTypeProperties, ProtobufMapValueType {
    public typealias BaseType = Double
}

///
/// Int32
///
public struct ProtobufInt32: ProtobufTypeProperties, ProtobufMapKeyType, ProtobufMapValueType {
    public typealias BaseType = Int32
}

///
/// Int64
///

public struct ProtobufInt64: ProtobufTypeProperties, ProtobufMapKeyType, ProtobufMapValueType {
    public typealias BaseType = Int64
}

///
/// UInt32
///
public struct ProtobufUInt32: ProtobufTypeProperties, ProtobufMapKeyType, ProtobufMapValueType {
    public typealias BaseType = UInt32
}

///
/// UInt64
///

public struct ProtobufUInt64: ProtobufTypeProperties, ProtobufMapKeyType, ProtobufMapValueType {
    public typealias BaseType = UInt64
}

///
/// SInt32
///
public struct ProtobufSInt32: ProtobufTypeProperties, ProtobufMapKeyType, ProtobufMapValueType {
    public typealias BaseType = Int32
}

///
/// SInt64
///

public struct ProtobufSInt64: ProtobufTypeProperties, ProtobufMapKeyType, ProtobufMapValueType {
    public typealias BaseType = Int64
}

///
/// Fixed32
///
public struct ProtobufFixed32: ProtobufTypeProperties, ProtobufMapKeyType, ProtobufMapValueType {
    public typealias BaseType = UInt32
}

///
/// Fixed64
///
public struct ProtobufFixed64: ProtobufTypeProperties, ProtobufMapKeyType, ProtobufMapValueType {
    public typealias BaseType = UInt64
}

///
/// SFixed32
///
public struct ProtobufSFixed32: ProtobufTypeProperties, ProtobufMapKeyType, ProtobufMapValueType {
    public typealias BaseType = Int32
}

///
/// SFixed64
///
public struct ProtobufSFixed64: ProtobufTypeProperties, ProtobufMapKeyType, ProtobufMapValueType {
    public typealias BaseType = Int64
}

//
// ========= Bool =========
//
public struct ProtobufBool: ProtobufTypeProperties, ProtobufMapKeyType, ProtobufMapValueType {
    public typealias BaseType = Bool
}

//
// ========== String ==========
//
public struct ProtobufString: ProtobufTypeProperties, ProtobufMapKeyType, ProtobufMapValueType {
    public typealias BaseType = String
}

//
// ========== Bytes ==========
//
public struct ProtobufBytes: ProtobufTypeProperties, ProtobufMapValueType {
    public typealias BaseType = Data
}

//
// ========== Enum ==========
//
extension ProtobufEnum where RawValue == Int {
}

//
// ========== Maps ===========
//
// Not a full ProtobufTypeProperties, just a generic marker
// for propagating the key/value types.
//
public struct ProtobufMap<MapKeyType: ProtobufMapKeyType, MapValueType: ProtobufMapValueType>
    where MapKeyType.BaseType: Hashable
{
    typealias Key = MapKeyType.BaseType
    typealias Value = MapValueType.BaseType
    public typealias BaseType = Dictionary<Key, Value>
}
