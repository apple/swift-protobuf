// Sources/SwiftProtobuf/DoubleParser.swift - Generally useful mathematical functions
//
// Copyright (c) 2014 - 2019 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Numeric parsing helper for float and double strings
///
// -----------------------------------------------------------------------------

import Foundation

/// Support parsing float/double values from UTF-8
internal class DoubleParser {
    // Temporary buffer so we can null-terminate the UTF-8 string
    // before calling the C standard libray to parse it.
    // In theory, JSON writers should be able to represent any IEEE Double
    // in at most 25 bytes, but many writers will emit more digits than
    // necessary, so we size this generously.
    #if swift(>=4.1)
      private var work =
          UnsafeMutableRawBufferPointer.allocate(byteCount: 128,
                                                 alignment: MemoryLayout<UInt8>.alignment)
    #else
      private var work = UnsafeMutableRawBufferPointer.allocate(count: 128)
    #endif

    deinit {
        work.deallocate()
    }

    func utf8ToDouble(bytes: UnsafeBufferPointer<UInt8>,
                      start: UnsafeBufferPointer<UInt8>.Index,
                      end: UnsafeBufferPointer<UInt8>.Index) -> Double? {
        return utf8ToDouble(bytes: bytes.baseAddress! + start, count: end - start)
    }

    func utf8ToDouble(bytes: UnsafePointer<UInt8>, count: Int) -> Double? {
        // Reject unreasonably long or short UTF8 number
        if work.count <= count || count < 1 {
            return nil
        }
        // Copy it to the work buffer and null-terminate it
        let source = UnsafeRawBufferPointer(start: bytes, count: count)
        #if swift(>=4.1)
          work.copyMemory(from:source)
        #else
          work.copyBytes(from:source)
        #endif
        work[count] = 0

        // Use C library strtod() to parse it
        let start = work.baseAddress!.assumingMemoryBound(to: Int8.self)
        var e: UnsafeMutablePointer<Int8>? = start
        let d = strtod(start, &e)

        // Fail if strtod() did not consume everything we expected
        // or if strtod() thought the number was out of range.
        if e != start + count || !d.isFinite {
            return nil
        }
        return d
    }
}
