// ProtobufRuntime/Sources/Protobuf/ProtobufOneof.swift - Oneof support
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
/// OneOf fields generate enums that conform to ProtobufOneofEnum
///
// -----------------------------------------------------------------------------

import Swift

public protocol ProtobufOneofEnum: Equatable {
    init()
    func traverse(visitor: inout ProtobufVisitor, start: Int, end: Int) throws
    mutating func decodeField(setter: inout ProtobufFieldDecoder, protoFieldNumber: Int) throws -> Bool
}

// TODO: This is a transition aid, remove this in August 2016.
public typealias ProtobufOneofEnumType = ProtobufOneofEnum
