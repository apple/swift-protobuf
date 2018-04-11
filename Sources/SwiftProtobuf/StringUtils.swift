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
/// Utility functions for converting UTF8 bytes into Strings.
/// These functions must:
///  * Accept any valid UTF8, including a zero byte (which is
///    a valid UTF8 encoding of U+0000)
///  * Return nil for any invalid UTF8
///  * Be fast (since they're extensively used by all decoders
///    and even some of the encoders)
///
// -----------------------------------------------------------------------------

import Foundation

// Wrapper that takes a buffer and start/end offsets
internal func utf8ToString(
  bytes: UnsafeBufferPointer<UInt8>,
  start: UnsafeBufferPointer<UInt8>.Index,
  end: UnsafeBufferPointer<UInt8>.Index
) -> String? {
  return utf8ToString(bytes: bytes.baseAddress! + start, count: end - start)
}

// Swift's support for working with UTF8 bytes directly has
// evolved over time.  The following tries to choose the
// best option depending on the version of Swift you're using.

#if swift(>=4.0)

///////////////////////////
//
// MARK: - Swift 4 (all platforms)
//
////////////////////////////

// Swift 4 introduced new faster String facilities
// that seem to work consistently across all platforms.

// Notes on performance:
//
// The pre-verification here only takes about 10% of
// the time needed for constructing the string.
// Eliminating it would provide only a very minor
// speed improvement.
//
// On macOS, this is only about 25% faster than
// the Foundation initializer used below for Swift 3.
// On Linux, the Foundation initializer is much
// slower than on macOS, so this is a much bigger
// win there.
internal func utf8ToString(bytes: UnsafePointer<UInt8>, count: Int) -> String? {
  if count == 0 {
    return String()
  }
  let codeUnits = UnsafeBufferPointer<UInt8>(start: bytes, count: count)
  let sourceEncoding = Unicode.UTF8.self

  // Verify that the UTF-8 is valid.
  var p = sourceEncoding.ForwardParser()
  var i = codeUnits.makeIterator()
  Loop:
  while true {
    switch p.parseScalar(from: &i) {
    case .valid(_):
      break
    case .error:
      return nil
    case .emptyInput:
      break Loop
    }
  }

  // This initializer is fast but does not reject broken
  // UTF-8 (which is why we validate the UTF-8 above).
  return String(decoding: codeUnits, as: sourceEncoding)
 }

#elseif os(OSX) || os(tvOS) || os(watchOS) || os(iOS)

//////////////////////////////////
//
// MARK: - Swift 3 (Apple platforms)
//
//////////////////////////////////

internal func utf8ToString(bytes: UnsafePointer<UInt8>, count: Int) -> String? {
  if count == 0 {
    return String()
  }
  // On Apple platforms, the Swift 3 version of Foundation has a String
  // initializer that works for us:
  let s = NSString(bytes: bytes, length: count, encoding: String.Encoding.utf8.rawValue)
  if let s = s {
    return String._unconditionallyBridgeFromObjectiveC(s)
  }
  return nil
}

#elseif os(Linux)

//////////////////////////////////
//
// MARK: - Swift 3 (Linux)
//
//////////////////////////////////

internal func utf8ToString(bytes: UnsafePointer<UInt8>, count: Int) -> String? {
  if count == 0 {
    return String()
  }
  // On Swift Linux 3.1, we can use Foundation as long
  // as there isn't a zero byte:
  //     https://bugs.swift.org/browse/SR-4216
  if memchr(bytes, 0, count) == nil {
    let s = NSString(bytes: bytes, length: count, encoding: String.Encoding.utf8.rawValue)
    if let s = s {
      return String._unconditionallyBridgeFromObjectiveC(s)
    }
  }

  // If we can't use the Foundation version, use a slow
  // manual conversion to get correct error handling:
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
