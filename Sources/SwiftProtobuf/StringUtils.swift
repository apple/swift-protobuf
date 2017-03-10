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

// This is painfully slow but seems to work correctly on every platform.
#if os(Linux)
fileprivate func slowUtf8ToString(bytes: UnsafePointer<UInt8>, count: Int) -> String? {
    var s = ""
    let buffer = UnsafeBufferPointer<UInt8>(start: bytes, count: count)
    var bytes = buffer.makeIterator()
    var utf8Decoder = UTF8()
    while true {
        switch utf8Decoder.decode(&bytes) {
        case .scalarValue(let scalar): s.append(String(scalar))
        case .emptyInput: return s
        case .error: return nil
        }
    }
}
#endif

internal func utf8ToString(bytes: UnsafePointer<UInt8>, count: Int) -> String? {
    if count == 0 {
        return ""
    }
#if os(Linux)
    // As of March, 2017, the NSString(bytes:length:encoding:)
    // initializer incorrectly stops at the first zero character for
    // Linux versions of Swift.  So test for the presence of a zero byte
    // and fall back to a slow-but-correct conversion in that case:
    if memchr(bytes, 0, count) != nil {
        return slowUtf8ToString(bytes: bytes, count: count)
    }
#endif
    let s = NSString(bytes: bytes, length: count, encoding: String.Encoding.utf8.rawValue)
    if let s = s {
        return String._unconditionallyBridgeFromObjectiveC(s)
    }
    return nil
}
