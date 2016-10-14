// Test/Sources/TestSuite/Helpers.swift - UInt8 array message helpers
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
/// Helper methods to serialize/parse messages via UInt8 arrays, to ease
/// test migration since the original methods have been removed from the
/// runtime.
///
// -----------------------------------------------------------------------------

import Foundation
import SwiftProtobuf

extension ProtobufBinaryMessageBase {

  init(protobufBytes: [UInt8]) throws {
    try self.init(protobufBytes: protobufBytes, extensions: nil)
  }

  init(protobufBytes: [UInt8], extensions: ProtobufExtensionSet?) throws {
    try self.init(protobuf: Data(protobufBytes), extensions: extensions)
  }

  func serializeProtobufBytes() throws -> [UInt8] {
    return try [UInt8](serializeProtobuf())
  }
}
