// Sources/SwiftProtobuf/Map.swift - Map<> support
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
/// Generic type representing proto map<> fields.
///
// -----------------------------------------------------------------------------

import Foundation
import Swift

public struct ProtobufMap<KeyType: MapKeyType, ValueType: MapValueType>
    where KeyType.BaseType: Hashable
{
    typealias Key = KeyType.BaseType
    typealias Value = ValueType.BaseType
    public typealias BaseType = Dictionary<Key, Value>
}
