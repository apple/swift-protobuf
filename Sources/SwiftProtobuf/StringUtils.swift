// Sources/SwiftProtobuf/StringUtils.swift - String utility functions
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

#if os(Linux)
// This is painfully slow but seems to work correctly on every platform.
// We currently only use it on Linux.  See below.
fileprivate func slowUtf8ToString(bytes: UnsafePointer<UInt8>, count: Int) -> String? {
    let buffer = UnsafeBufferPointer(start: bytes, count: count)
    var it = buffer.makeIterator()
    var utf8Codec = UTF8()
    var output = String.UnicodeScalarView()
    output.reserveCapacity(count)

    while true {
        switch utf8Codec.decode(&it) {
        case .scalarValue(let scalar): output.append(scalar)
        case .emptyInput: return String(output)
        case .error: return nil
        }
    }
}
#endif

internal func utf8ToString(
  bytes: UnsafeBufferPointer<UInt8>,
  start: UnsafeBufferPointer<UInt8>.Index,
  end: UnsafeBufferPointer<UInt8>.Index
) -> String? {
  return utf8ToString(bytes: bytes.baseAddress! + start, count: end - start)
}

internal func utf8ToString(bytes: UnsafePointer<UInt8>, count: Int) -> String? {
    if count == 0 {
        return String()
    }
#if os(Linux)
    // As of March, 2017, the NSString(bytes:length:encoding:)
    // initializer incorrectly stops at the first zero character for
    // Linux versions of Swift:
    //     https://bugs.swift.org/browse/SR-4216
    //
    // On Linux, test for the presence of a zero byte
    // and fall back to a much slower conversion in that case:
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
