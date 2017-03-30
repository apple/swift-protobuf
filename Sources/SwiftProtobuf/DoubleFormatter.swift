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

#if os(Linux)
// Linux doesn't seem to define these by default.
// https://bugs.swift.org/browse/SR-4198
internal let FLT_DIG: Int32 = 6
internal let DBL_DIG: Int32 = 15
#endif

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
    private var work = UnsafeMutableRawBufferPointer.allocate(count: 128)

    init() {
        let format: StaticString = "%.*g"
        let formatBytes = UnsafeBufferPointer(start: format.utf8Start, count: format.utf8CodeUnitCount)
        doubleFormatString = UnsafeMutableRawBufferPointer.allocate(count: formatBytes.count + 1)
        doubleFormatString.copyBytes(from: formatBytes)
        doubleFormatString[formatBytes.count] = 0
    }

    deinit {
        work.deallocate()
        doubleFormatString.deallocate()
    }

    func utf8ToDouble(bytes: UnsafePointer<UInt8>, count: Int) -> Double? {
        // Reject unreasonably large UTF8 number
        if work.count <= count {
            return nil
        }
        // Copy it to the work buffer and null-terminate it
        let source = UnsafeRawBufferPointer(start: bytes, count: count)
        work.copyBytes(from:source)
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
        return _doubleToUtf8(Double(f), digits: FLT_DIG + 2)
    }

    func doubleToUtf8(_ d: Double) -> UnsafeBufferPointer<UInt8> {
        return _doubleToUtf8(d, digits: DBL_DIG + 2)
    }

    private func _doubleToUtf8(_ d: Double, digits: Int32) -> UnsafeBufferPointer<UInt8> {
        // Format into the work buffer, return a UBP with the result
        let count = wrapped_vsnprintf(destination: work, format: doubleFormatString, digits, d)
        let start = work.baseAddress!.assumingMemoryBound(to: UInt8.self)
        return UnsafeBufferPointer<UInt8>(start: start, count: count)
    }
}
