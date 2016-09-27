// ProtobufRuntime/Sources/Protobuf/ProtobufEnum.swift - Enum support
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
/// Generated enums conform to ProtobufEnum
///
/// See ProtobufBinaryTypes and ProtobufJSONTypes for extension
/// methods to support binary and JSON coding.
///
// -----------------------------------------------------------------------------

import Swift

public protocol ProtobufEnum: RawRepresentable, Hashable, CustomDebugStringConvertible, ProtobufTypeProperties, ProtobufMapValueType {
    init?(name: String)
    init?(jsonName: String)
    var json: String { get }
    var rawValue: Int { get }
}

// TODO: This is a transition aid, remove this in August 2016.
public typealias ProtobufEnumType = ProtobufEnum
