// Tests/SwiftProtobufTests/Test_DoubleParser_Locale.swift - Locale-independent number parsing
//
// Copyright (c) 2014 - 2026 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// JSON and TextFormat number parsing must not depend on the process'
/// C numeric locale: strtod() stops at "." under a comma-decimal locale.
///
// -----------------------------------------------------------------------------

import Foundation
import SwiftProtobuf
import XCTest

#if canImport(Glibc)
import Glibc
#elseif canImport(Musl)
import Musl
#elseif canImport(Android)
import Android
#elseif canImport(WASILibc)
import WASILibc
#elseif canImport(Darwin)
import Darwin
#elseif os(Windows)
import CRT
#endif

final class Test_DoubleParser_Locale: XCTestCase {

    /// True if strtod() currently fails to consume all of "1.5", which is
    /// what happens under a locale whose decimal separator is not ".".
    private func strtodStopsAtDot() -> Bool {
        "1.5".withCString { buf in
            var end: UnsafeMutablePointer<CChar>? = nil
            let value = strtod(buf, &end)
            return value != 1.5 || end != UnsafeMutablePointer(mutating: buf) + 3
        }
    }

    func testFractionalNumbersUnderCommaDecimalLocale() throws {
        let saved = setlocale(LC_NUMERIC, nil).map { String(cString: $0) }
        defer {
            if let saved = saved {
                setlocale(LC_NUMERIC, saved)
            }
        }

        // Switch LC_NUMERIC to a locale whose decimal separator is ",".
        // Locale availability varies by platform and image, so try a few
        // spellings and skip if none of them affects strtod().
        let candidates = ["fr_FR.UTF-8", "fr_FR", "de_DE.UTF-8", "de_DE", "fr-FR", "de-DE"]
        var localeInUse: String? = nil
        for candidate in candidates {
            if setlocale(LC_NUMERIC, candidate) != nil, strtodStopsAtDot() {
                localeInUse = candidate
                break
            }
        }
        guard localeInUse != nil else {
            throw XCTSkip("No comma-decimal locale available to exercise strtod()")
        }

        // Fractional and exponent forms must decode the same as in the C locale.
        XCTAssertEqual(try Google_Protobuf_DoubleValue(jsonString: "1.5").value, 1.5)
        XCTAssertEqual(try Google_Protobuf_FloatValue(jsonString: "2.25").value, 2.25)
        XCTAssertEqual(try Google_Protobuf_DoubleValue(jsonString: "6.25e-2").value, 0.0625)
        XCTAssertEqual(try Google_Protobuf_DoubleValue(textFormatString: "value: 3.75").value, 3.75)
        XCTAssertEqual(try Google_Protobuf_FloatValue(textFormatString: "value: 1.5f").value, 1.5)

        // Malformed numbers must still be rejected.
        XCTAssertThrowsError(try Google_Protobuf_DoubleValue(textFormatString: "value: 1.2.3"))
        XCTAssertThrowsError(try Google_Protobuf_DoubleValue(jsonString: "1.5x"))
        // Configure the locale impacts of `strtod` don't let invalid input through.
        XCTAssertThrowsError(try Google_Protobuf_DoubleValue(textFormatString: "1,5"))
        XCTAssertThrowsError(try Google_Protobuf_DoubleValue(jsonString: "1,5"))
    }
}
