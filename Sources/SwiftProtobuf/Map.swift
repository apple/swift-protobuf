// Sources/SwiftProtobuf/Map.swift - Map<> support
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Generic type representing proto map<> fields.
///
// -----------------------------------------------------------------------------

import Foundation
import Swift

public struct ProtobufMap<KeyType: MapKeyType, ValueType: FieldType>
    where KeyType.BaseType: Hashable
{
    public typealias Key = KeyType.BaseType
    public typealias Value = ValueType.BaseType
    public typealias BaseType = Dictionary<Key, Value>
}

public struct ProtobufMessageMap<KeyType: MapKeyType, ValueType: Message>
    where KeyType.BaseType: Hashable
{
    public typealias Key = KeyType.BaseType
    public typealias Value = ValueType
    public typealias BaseType = Dictionary<Key, Value>
}

public struct ProtobufEnumMap<KeyType: MapKeyType, ValueType: Enum>
    where KeyType.BaseType: Hashable
{
    public typealias Key = KeyType.BaseType
    public typealias Value = ValueType
    public typealias BaseType = Dictionary<Key, Value>
}
