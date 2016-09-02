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
public protocol ProtobufTypePropertiesBase {
    // Default here is appropriate for enums and messages
    // Other types will override this
    associatedtype BaseType = Self

    /// Hash the provided value
    /// In particular, [UInt8] is not Hashable, so we can't just
    /// use .hashValue everywhere.
    static func hash(value: BaseType) -> Int

    /// In Swift 3, [UInt8] isn't Equatable, so I've added this method
    /// to provide a consistent way to compute equality.
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
    public static func describe(value: BaseType) -> String {return value.description}
}

///
/// Double
///
public struct ProtobufDouble: ProtobufTypeProperties, ProtobufMapValueType {
    public typealias BaseType = Double
    public static func describe(value: BaseType) -> String {return value.description}
}

///
/// Int32
///
public struct ProtobufInt32: ProtobufTypeProperties, ProtobufMapKeyType, ProtobufMapValueType {
    public typealias BaseType = Int32
    public static func describe(value: BaseType) -> String {return value.description}
}

///
/// Int64
///

public struct ProtobufInt64: ProtobufTypeProperties, ProtobufMapKeyType, ProtobufMapValueType {
    public typealias BaseType = Int64
    public static func describe(value: BaseType) -> String {return value.description}
}

///
/// UInt32
///
public struct ProtobufUInt32: ProtobufTypeProperties, ProtobufMapKeyType, ProtobufMapValueType {
    public typealias BaseType = UInt32
    public static func describe(value: BaseType) -> String {return value.description}
}

///
/// UInt64
///

public struct ProtobufUInt64: ProtobufTypeProperties, ProtobufMapKeyType, ProtobufMapValueType {
    public typealias BaseType = UInt64
    public static func describe(value: BaseType) -> String {return value.description}
}

///
/// SInt32
///
public struct ProtobufSInt32: ProtobufTypeProperties, ProtobufMapKeyType, ProtobufMapValueType {
    public typealias BaseType = Int32
    public static func describe(value: BaseType) -> String {return value.description}
}

///
/// SInt64
///

public struct ProtobufSInt64: ProtobufTypeProperties, ProtobufMapKeyType, ProtobufMapValueType {
    public typealias BaseType = Int64
    public static func describe(value: BaseType) -> String {return value.description}
}

///
/// Fixed32
///
public struct ProtobufFixed32: ProtobufTypeProperties, ProtobufMapKeyType, ProtobufMapValueType {
    public typealias BaseType = UInt32
    public static func describe(value: BaseType) -> String {return value.description}
}

///
/// Fixed64
///
public struct ProtobufFixed64: ProtobufTypeProperties, ProtobufMapKeyType, ProtobufMapValueType {
    public typealias BaseType = UInt64
    public static func describe(value: BaseType) -> String {return value.description}
}

///
/// SFixed32
///
public struct ProtobufSFixed32: ProtobufTypeProperties, ProtobufMapKeyType, ProtobufMapValueType {
    public typealias BaseType = Int32
    public static func describe(value: BaseType) -> String {return value.description}
}

///
/// SFixed64
///
public struct ProtobufSFixed64: ProtobufTypeProperties, ProtobufMapKeyType, ProtobufMapValueType {
    public typealias BaseType = Int64
    public static func describe(value: BaseType) -> String {return value.description}
}

//
// ========= Bool =========
//
public struct ProtobufBool: ProtobufTypeProperties, ProtobufMapKeyType, ProtobufMapValueType {
    public typealias BaseType = Bool
    public static func describe(value: BaseType) -> String {return value.description}
}

//
// ========== String ==========
//
public struct ProtobufString: ProtobufTypeProperties, ProtobufMapKeyType, ProtobufMapValueType {
    public typealias BaseType = String
    public static func describe(value: BaseType) -> String {return value.debugDescription}
}

//
// ========== Bytes ==========
//
public struct ProtobufBytes: ProtobufTypeProperties, ProtobufMapValueType {
    public typealias BaseType = [UInt8]

    public static func hash(value: BaseType) -> Int {return ProtobufHash(bytes: value)}
    public static func describe(value: BaseType) -> String {return value.debugDescription}

    // Note:  [UInt8] isn't Equatable, so we can't rely on the default implementation above
    // But there is an == overload, so this same definition works here.
    public static func isEqual(_ lhs: BaseType, _ rhs: BaseType) -> Bool {return lhs == rhs}
}

//
// ========== Enum ==========
//
extension ProtobufEnum where RawValue == Int {
    public static func describe(value: Self) -> String {return String(reflecting: value)}
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
