// Sources/SwiftProtobuf/ProtobufMap.swift - Map<> support
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
//
// Generic type representing proto map<> fields.
//
// -----------------------------------------------------------------------------

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// SwiftProtobuf Internal: Support for Encoding/Decoding.
public struct _ProtobufMap<KeyType: MapKeyType, ValueType: FieldType> {
    /// The type that represents a map field's key.
    public typealias Key = KeyType.BaseType

    /// The type that represents a map field's scalar value.
    public typealias Value = ValueType.BaseType

    /// The dictionary type this map field decodes to and encodes from.
    public typealias BaseType = [Key: Value]
}

/// SwiftProtobuf Internal: Support for Encoding/Decoding.
public struct _ProtobufMessageMap<KeyType: MapKeyType, ValueType: Message & Hashable> {
    /// The type that represents a map field's key.
    public typealias Key = KeyType.BaseType

    /// The message type that represents a map field's value.
    public typealias Value = ValueType

    /// The dictionary type this map field decodes to and encodes from.
    public typealias BaseType = [Key: Value]
}

/// SwiftProtobuf Internal: Support for Encoding/Decoding.
public struct _ProtobufEnumMap<KeyType: MapKeyType, ValueType: Enum> {
    /// The type that represents a map field's key.
    public typealias Key = KeyType.BaseType

    /// The enum type that represents a map field's value.
    public typealias Value = ValueType

    /// The dictionary type this map field decodes to and encodes from.
    public typealias BaseType = [Key: Value]
}
