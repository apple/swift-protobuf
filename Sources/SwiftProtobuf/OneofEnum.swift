// Sources/SwiftProtobuf/OneofEnum.swift - Oneof support
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
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
