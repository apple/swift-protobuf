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

public protocol Enum: RawRepresentable, Hashable {
    init()
    init?(jsonName: String)
    init?(protoName: String)
    var rawValue: Int { get }

    /// Returns the JSON name for the enum.
    /// This is meanted to be internal to the SwiftProtobuf library and shouldn't
    /// be used by consumers of the library.
    var _protobuf_jsonName: String? { get }
}
