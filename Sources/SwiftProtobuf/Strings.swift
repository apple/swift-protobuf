// Sources/SwiftProtobuf/Strings.swift - String utility functions
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Utility functions that are generally useful...
///
// -----------------------------------------------------------------------------

import Foundation

// Convert a pointer/count that refers to a block of UTF8 bytes
// in memory into a String.
// Returns nil if UTF8 is invalid.
internal func utf8ToString(bytes: UnsafePointer<UInt8>, count: Int) -> String? {
    let s = NSString(bytes: bytes, length: count, encoding: String.Encoding.utf8.rawValue)
    if let s = s {
        return String._unconditionallyBridgeFromObjectiveC(s)
    }
    return nil
}
