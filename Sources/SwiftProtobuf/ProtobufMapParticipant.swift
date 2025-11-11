// Sources/SwiftProtobuf/ProtobufMapParticipant.swift - Map<> support
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Generic types to proxy between proto map<> fields.
///
// -----------------------------------------------------------------------------

import Foundation

/// Defines the common operations for a proxy type that participates in a protobuf map (as either a
/// key or a value).
@_spi(ForGeneratedCodeOnly) public protocol ProtobufMapParticipant {
    /// The actual Swift type of the field as it is represented in memory.
    associatedtype Base

    /// Returns the value of the field based on the given offset and presence information.
    static func value(at offset: Int, in storage: _MessageStorage, hasBit: _MessageStorage.HasBit) -> Base

    /// Updates the value of the field based on the given offset and presence information.
    static func updateValue(
        at offset: Int,
        in storage: _MessageStorage,
        to newValue: Base,
        hasBit: _MessageStorage.HasBit
    )
}

/// Defines additional operations for proxy types that represent Swift types that can be used as
/// the key of a protobuf map.
@_spi(ForGeneratedCodeOnly) public protocol ProtobufMapKey: ProtobufMapParticipant where Base: Hashable {
    /// Returns whether `lhs` is less than `rhs`.
    ///
    /// This is used to implement deterministically ordered encoding for map fields.
    static func keyLessThan(lhs: Base, rhs: Base) -> Bool
}

extension ProtobufMapKey where Base: Comparable {
    public static func keyLessThan(lhs: Base, rhs: Base) -> Bool {
        lhs < rhs
    }
}

/// The proxy type for `bool` map keys and values.
@_spi(ForGeneratedCodeOnly) public struct ProtobufMapBoolField: ProtobufMapKey {
    public static func value(at offset: Int, in storage: _MessageStorage, hasBit: _MessageStorage.HasBit) -> Bool {
        storage.value(at: offset, hasBit: hasBit)
    }

    public static func updateValue(
        at offset: Int,
        in storage: _MessageStorage,
        to newValue: Bool,
        hasBit: _MessageStorage.HasBit
    ) {
        storage.updateValue(at: offset, to: newValue, willBeSet: true, hasBit: hasBit)
    }

    public static func keyLessThan(lhs: Base, rhs: Base) -> Bool {
        if !lhs {
            return rhs
        }
        return false
    }
}

/// The proxy type for `bytes` map values.
@_spi(ForGeneratedCodeOnly) public struct ProtobufMapDataField: ProtobufMapParticipant {
    public static func value(at offset: Int, in storage: _MessageStorage, hasBit: _MessageStorage.HasBit) -> Data {
        storage.value(at: offset, hasBit: hasBit)
    }

    public static func updateValue(
        at offset: Int,
        in storage: _MessageStorage,
        to newValue: Data,
        hasBit: _MessageStorage.HasBit
    ) {
        storage.updateValue(at: offset, to: newValue, willBeSet: true, hasBit: hasBit)
    }
}

/// The proxy type for `double` map keys and values.
@_spi(ForGeneratedCodeOnly) public struct ProtobufMapDoubleField: ProtobufMapKey {
    public static func value(at offset: Int, in storage: _MessageStorage, hasBit: _MessageStorage.HasBit) -> Double {
        storage.value(at: offset, hasBit: hasBit)
    }

    public static func updateValue(
        at offset: Int,
        in storage: _MessageStorage,
        to newValue: Double,
        hasBit: _MessageStorage.HasBit
    ) {
        storage.updateValue(at: offset, to: newValue, willBeSet: true, hasBit: hasBit)
    }
}

/// The proxy type for `enum` map values.
@_spi(ForGeneratedCodeOnly) public struct ProtobufMapEnumField<E: Enum>: ProtobufMapParticipant {
    public static func value(at offset: Int, in storage: _MessageStorage, hasBit: _MessageStorage.HasBit) -> E {
        storage.value(at: offset, default: E(), hasBit: hasBit)
    }

    public static func updateValue(
        at offset: Int,
        in storage: _MessageStorage,
        to newValue: E,
        hasBit: _MessageStorage.HasBit
    ) {
        storage.updateValue(at: offset, to: newValue, willBeSet: true, hasBit: hasBit)
    }
}

/// The proxy type for `float` map keys and values.
@_spi(ForGeneratedCodeOnly) public struct ProtobufMapFloatField: ProtobufMapKey {
    public static func value(at offset: Int, in storage: _MessageStorage, hasBit: _MessageStorage.HasBit) -> Float {
        storage.value(at: offset, hasBit: hasBit)
    }

    public static func updateValue(
        at offset: Int,
        in storage: _MessageStorage,
        to newValue: Float,
        hasBit: _MessageStorage.HasBit
    ) {
        storage.updateValue(at: offset, to: newValue, willBeSet: true, hasBit: hasBit)
    }
}

/// The proxy type for `int32`, `sfixed32`, and `sint32` map keys and values.
@_spi(ForGeneratedCodeOnly) public struct ProtobufMapInt32Field: ProtobufMapKey {
    public static func value(at offset: Int, in storage: _MessageStorage, hasBit: _MessageStorage.HasBit) -> Int32 {
        storage.value(at: offset, hasBit: hasBit)
    }

    public static func updateValue(
        at offset: Int,
        in storage: _MessageStorage,
        to newValue: Int32,
        hasBit: _MessageStorage.HasBit
    ) {
        storage.updateValue(at: offset, to: newValue, willBeSet: true, hasBit: hasBit)
    }
}

/// The proxy type for `int64`, `sfixed64` and `sint64` map keys and values.
@_spi(ForGeneratedCodeOnly) public struct ProtobufMapInt64Field: ProtobufMapKey {
    public static func value(at offset: Int, in storage: _MessageStorage, hasBit: _MessageStorage.HasBit) -> Int64 {
        storage.value(at: offset, hasBit: hasBit)
    }

    public static func updateValue(
        at offset: Int,
        in storage: _MessageStorage,
        to newValue: Int64,
        hasBit: _MessageStorage.HasBit
    ) {
        storage.updateValue(at: offset, to: newValue, willBeSet: true, hasBit: hasBit)
    }
}

/// The proxy type for submessage map values.
@_spi(ForGeneratedCodeOnly) public struct ProtobufMapMessageField<M: _MessageImplementationBase>: ProtobufMapParticipant
{
    public static func value(at offset: Int, in storage: _MessageStorage, hasBit: _MessageStorage.HasBit) -> M {
        storage.value(at: offset, default: M(), hasBit: hasBit)
    }

    public static func updateValue(
        at offset: Int,
        in storage: _MessageStorage,
        to newValue: M,
        hasBit: _MessageStorage.HasBit
    ) {
        storage.updateValue(at: offset, to: newValue, willBeSet: true, hasBit: hasBit)
    }
}

/// The proxy type for `string` map keys and values.
@_spi(ForGeneratedCodeOnly) public struct ProtobufMapStringField: ProtobufMapKey {
    public static func value(at offset: Int, in storage: _MessageStorage, hasBit: _MessageStorage.HasBit) -> String {
        storage.value(at: offset, hasBit: hasBit)
    }

    public static func updateValue(
        at offset: Int,
        in storage: _MessageStorage,
        to newValue: String,
        hasBit: _MessageStorage.HasBit
    ) {
        storage.updateValue(at: offset, to: newValue, willBeSet: true, hasBit: hasBit)
    }
}

/// The proxy type for `fixed32` and `uint32` map keys and values.
@_spi(ForGeneratedCodeOnly) public struct ProtobufMapUInt32Field: ProtobufMapKey {
    public static func value(at offset: Int, in storage: _MessageStorage, hasBit: _MessageStorage.HasBit) -> UInt32 {
        storage.value(at: offset, hasBit: hasBit)
    }

    public static func updateValue(
        at offset: Int,
        in storage: _MessageStorage,
        to newValue: UInt32,
        hasBit: _MessageStorage.HasBit
    ) {
        storage.updateValue(at: offset, to: newValue, willBeSet: true, hasBit: hasBit)
    }
}

/// The proxy type for `fixed64` and `uint64` map keys and values.
@_spi(ForGeneratedCodeOnly) public struct ProtobufMapUInt64Field: ProtobufMapKey {
    public static func value(at offset: Int, in storage: _MessageStorage, hasBit: _MessageStorage.HasBit) -> UInt64 {
        storage.value(at: offset, hasBit: hasBit)
    }

    public static func updateValue(
        at offset: Int,
        in storage: _MessageStorage,
        to newValue: UInt64,
        hasBit: _MessageStorage.HasBit
    ) {
        storage.updateValue(at: offset, to: newValue, willBeSet: true, hasBit: hasBit)
    }
}
