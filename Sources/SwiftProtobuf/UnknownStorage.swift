// ProtobufRuntime/Sources/Protobuf/ProtobufUnknown.swift - Handling unknown fields
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
/// Proto2 binary coding requires storing and recoding of unknown fields.
/// This simple support class handles that requirement.  A property of this type
/// is compiled into every proto2 message.
///
// -----------------------------------------------------------------------------

import Swift
import Foundation

public struct UnknownStorage: Equatable {
    internal var data = Data()
    public init() {}

    public mutating func append(protobufData: Data) {
        data.append(protobufData)
    }

    public func traverse(visitor: inout Visitor) {
        visitor.visitUnknown(bytes: data)
    }
}

public func ==(lhs: UnknownStorage, rhs: UnknownStorage) -> Bool {
    return lhs.data == rhs.data
}
