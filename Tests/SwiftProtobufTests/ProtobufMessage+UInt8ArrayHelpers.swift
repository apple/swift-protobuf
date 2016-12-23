// Tests/SwiftProtobufTests/ProtobufMessage+UInt8ArrayHelpers.swift - UInt8 array message helpers
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Helper methods to serialize/parse messages via UInt8 arrays, to ease
/// test migration since the original methods have been removed from the
/// runtime.
///
// -----------------------------------------------------------------------------

import Foundation
import SwiftProtobuf

extension SwiftProtobuf.Message {
    init(protobufBytes: [UInt8]) throws {
        try self.init(protobuf: Data(protobufBytes))
    }

    func serializeProtobufBytes() throws -> [UInt8] {
        return try [UInt8](serializeProtobuf())
    }
}

extension SwiftProtobuf.Message where Self: SwiftProtobuf.Proto2Message {
    init(protobufBytes: [UInt8], extensions: SwiftProtobuf.ExtensionSet?) throws {
        try self.init(protobuf: Data(protobufBytes), extensions: extensions)
    }
}
