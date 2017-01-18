// Sources/SwiftProtobuf/Enum.swift - Enum support
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Generated enums conform to SwiftProtobuf.Enum
///
/// See ProtobufTypes and JSONTypes for extension
/// methods to support binary and JSON coding.
///
// -----------------------------------------------------------------------------

import Swift

public protocol Enum: RawRepresentable, Hashable, CustomDebugStringConvertible, FieldType, MapValueType {
    init?(name: String)
    init?(jsonName: String)
    init?(protoName: String)
    var json: String { get }
    var rawValue: Int { get }
}

public extension Enum {
    public static func decodeProtobufMapValue(decoder: inout ProtobufDecoder, value: inout BaseType?) throws {
        try decoder.decodeSingularField(fieldType: Self.self, value: &value)
        assert(value != nil)
    }
}
