// Sources/SwiftProtobuf/UnknownStorage.swift - Handling unknown fields
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
//
// Proto2 binary coding requires storing and recoding of unknown fields.
// This simple support class handles that requirement.  The generator adds
// a property of this type to every proto2 message.
//
// -----------------------------------------------------------------------------

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// The unknown fields in a decoded message.
///
/// These are fields that arrived on the wire but the generated message
/// implementation didn't recognize, or fields with valid field numbers but
/// mismatched wire formats -- for example, a field encoded as a varint when
/// the schema expected a fixed32 integer.
public struct UnknownStorage: Equatable, Sendable {

    /// The raw protocol buffer binary-encoded bytes that represent the unknown
    /// fields of a decoded message.
    public private(set) var data = Data()

    public init() {}

    package mutating func append(protobufData: Data) {
        data.append(protobufData)
    }

    public func traverse<V: Visitor>(visitor: inout V) throws {
        if !data.isEmpty {
            try visitor.visitUnknown(bytes: data)
        }
    }
}
