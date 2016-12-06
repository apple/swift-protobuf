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
/// OneOf fields generate enums that conform to OneofEnum
///
// -----------------------------------------------------------------------------

import Swift

public protocol OneofEnum: Equatable {
    init()
    func traverse(visitor: inout Visitor, start: Int, end: Int) throws
    mutating func decodeField(setter: inout FieldDecoder, protoFieldNumber: Int) throws
}
