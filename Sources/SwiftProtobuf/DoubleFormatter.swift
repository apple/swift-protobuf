// Sources/SwiftProtobuf/DoubleFormatter.swift - Generally useful mathematical functions
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Formatting/parsing helper for float and double strings
///
// -----------------------------------------------------------------------------

import Foundation

// TODO: Experiment with other approaches for formatting float/double.
// Profiling shows that the `CVarArg` and `withVaList` glue consumes
// about 50% of the total run time just marshalling the arguments.
// If we could find a way to do this that didn't involve C `va_list`,
// we could get a big speed up.  (Note that the `utf8ToDouble` parse
// is very fast since `strtod` doesn't require `va_list` marshalling.

private func wrapped_vsnprintf(destination: UnsafeMutableRawBufferPointer,
                               format: UnsafeMutableRawBufferPointer,
                               _ arguments: CVarArg...) -> Int {
    let p = destination.baseAddress!.assumingMemoryBound(to: Int8.self)
    let n = destination.count
    let fmt = format.baseAddress!.assumingMemoryBound(to: Int8.self)
    return withVaList(arguments) {
        let printed = vsnprintf(p, n, fmt, $0)
        return Int(printed)
    }
}

/// Support parsing and formatting float/double values to/from UTF-8
internal class DoubleFormatter {
    private var doubleFormatString: UnsafeMutableRawBufferPointer
    #if swift(>=4.1)
      private var work =
          UnsafeMutableRawBufferPointer.allocate(byteCount: 128,
                                                 alignment: MemoryLayout<UInt8>.alignment)
    #else
      private var work = UnsafeMutableRawBufferPointer.allocate(count: 128)
    #endif

    init() {
        let format: StaticString = "%.*g"
        let formatBytes = UnsafeBufferPointer(start: format.utf8Start, count: format.utf8CodeUnitCount)
        #if swift(>=4.1)
          doubleFormatString =
              UnsafeMutableRawBufferPointer.allocate(byteCount: formatBytes.count + 1,
                                                     alignment: MemoryLayout<UInt8>.alignment)
        #else
          doubleFormatString = UnsafeMutableRawBufferPointer.allocate(count: formatBytes.count + 1)
        #endif
        doubleFormatString.copyBytes(from: formatBytes)
        doubleFormatString[formatBytes.count] = 0
    }

    deinit {
        work.deallocate()
        doubleFormatString.deallocate()
    }

    func utf8ToDouble(bytes: UnsafeBufferPointer<UInt8>,
                      start: UnsafeBufferPointer<UInt8>.Index,
                      end: UnsafeBufferPointer<UInt8>.Index) -> Double? {
        return utf8ToDouble(bytes: bytes.baseAddress! + start, count: end - start)
    }

    func utf8ToDouble(bytes: UnsafePointer<UInt8>, count: Int) -> Double? {
        // Reject unreasonably large UTF8 number
        if work.count <= count {
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

    func floatToUtf8(_ f: Float) -> UnsafeBufferPointer<UInt8> {
        // This many digits suffices for any IEEE754 single-precision number.
        let floatDigitsToPrint: Int32 = 9
        return _doubleToUtf8(Double(f), digits: floatDigitsToPrint)
    }

    func doubleToUtf8(_ d: Double) -> UnsafeBufferPointer<UInt8> {
        // This many digits suffices for any IEEE754 double-precision number.
        let doubleDigitsToPrint: Int32 = 17
        return _doubleToUtf8(d, digits: doubleDigitsToPrint)
    }

    private func _doubleToUtf8(_ d: Double, digits: Int32) -> UnsafeBufferPointer<UInt8> {
        // Format into the work buffer, return a UBP with the result
        let count = wrapped_vsnprintf(destination: work, format: doubleFormatString, digits, d)
        let start = work.baseAddress!.assumingMemoryBound(to: UInt8.self)
        return UnsafeBufferPointer<UInt8>(start: start, count: count)
    }
}
