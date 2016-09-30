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

public struct ProtobufUnknownStorage: Equatable {
    fileprivate var data: [UInt8] = []
    public init() {}

    public mutating func decodeField(setter: inout ProtobufFieldDecoder) throws -> Bool {
        if let u = try setter.asProtobufUnknown() {
            data.append(contentsOf: u)
            return true
        } else {
            return false
        }
    }

    public func traverse(visitor: inout ProtobufVisitor) {
        visitor.visitUnknown(bytes: data)
    }
}

public func ==(lhs: ProtobufUnknownStorage, rhs: ProtobufUnknownStorage) -> Bool {
    return lhs.data == rhs.data
}
