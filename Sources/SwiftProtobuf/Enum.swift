// Sources/SwiftProtobuf/Enum.swift - Enum support
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
    var json: String { get }
    var rawValue: Int { get }
}

public extension Enum {
    public static func decodeProtobufMapValue(decoder: inout FieldDecoder, value: inout BaseType?) throws {
        try decoder.decodeSingularField(fieldType: Self.self, value: &value)
        assert(value != nil)
    }
}
