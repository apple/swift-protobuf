// Sources/SwiftProtobuf/StringUtils.swift - String utility functions
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
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

// Note: Once our minimum support version is at least Swift 5.3, we should
// probably recast the following to use String(unsafeUninitializedCapacity:)

// Note: We're trying to avoid Foundation's String(format:) since that's not
// universally available.

private func formatZeroPaddedInt(_ value: Int32, digits: Int) -> String {
    precondition(value >= 0)
    let s = String(value)
    if s.count >= digits {
        return s
    } else {
        let pad = String(repeating: "0", count: digits - s.count)
        return pad + s
    }
}

internal func twoDigit(_ value: Int32) -> String {
    formatZeroPaddedInt(value, digits: 2)
}
internal func threeDigit(_ value: Int32) -> String {
    formatZeroPaddedInt(value, digits: 3)
}
internal func fourDigit(_ value: Int32) -> String {
    formatZeroPaddedInt(value, digits: 4)
}
internal func sixDigit(_ value: Int32) -> String {
    formatZeroPaddedInt(value, digits: 6)
}
internal func nineDigit(_ value: Int32) -> String {
    formatZeroPaddedInt(value, digits: 9)
}

// Wrapper that takes a buffer and start/end offsets
internal func utf8ToString(
    bytes: UnsafeRawBufferPointer,
    start: UnsafeRawBufferPointer.Index,
    end: UnsafeRawBufferPointer.Index
) -> String? {
    utf8ToString(bytes: bytes.baseAddress! + start, count: end - start)
}

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
internal func utf8ToString(bytes: UnsafeRawPointer, count: Int) -> String? {
    if count == 0 {
        return String()
    }
    let codeUnits = UnsafeRawBufferPointer(start: bytes, count: count)
    let sourceEncoding = Unicode.UTF8.self

    // Verify that the UTF-8 is valid.
    var p = sourceEncoding.ForwardParser()
    var i = codeUnits.makeIterator()
    Loop: while true {
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
