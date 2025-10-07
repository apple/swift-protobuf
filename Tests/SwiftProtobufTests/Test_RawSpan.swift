import Foundation
import SwiftProtobuf
import XCTest

#if compiler(>=6.2)

final class Test_RawSpan: XCTestCase {
    func testEmptyRawSpan() throws {
        guard #available(macOS 10.14.4, iOS 12.2, watchOS 5.2, tvOS 12.2, visionOS 1.0, *) else {
            throw XCTSkip("Span structs not available on selected platform")
        }

        let emptyRawSpan = RawSpan()

        let decoded = try SwiftProtoTesting_TestAllTypes(serializedBytes: emptyRawSpan)
        let expected = SwiftProtoTesting_TestAllTypes()

        XCTAssertEqual(decoded, expected, "Empty span should decode to equal empty message")
    }

    func testRawSpanReencodedEmptyByteArray() throws {
        guard #available(macOS 26, iOS 26, watchOS 26, tvOS 26, visionOS 26, *) else {
            throw XCTSkip("span.bytes not available on selected platform")
        }

        let expected: [UInt8] = []
        let expectedRawSpan = expected.span.bytes

        let decoded = try SwiftProtoTesting_TestAllTypes(serializedBytes: expectedRawSpan)
        let reencoded: [UInt8] = try decoded.serializedBytes()

        XCTAssertEqual(
            reencoded,
            expected,
            "Raw span of empty array of bytes should decode and encode as empty message"
        )
    }

    func testRawSpanDataEncodeDecode() throws {
        guard #available(macOS 10.14.4, iOS 12.2, watchOS 5.2, tvOS 12.2, visionOS 1.0, *) else {
            throw XCTSkip("Span structs not available on selected platform")
        }

        let expected = SwiftProtoTesting_TestAllTypes.with {
            $0.optionalInt32 = 1
            $0.optionalInt64 = Int64.max
            $0.optionalString = "RawSpan test"
            $0.repeatedBool = [true, false]
        }

        let encoded: Data = try expected.serializedBytes()
        let encodedRawSpan: RawSpan = encoded.bytes

        let decoded = try SwiftProtoTesting_TestAllTypes(serializedBytes: encodedRawSpan)

        XCTAssertEqual(decoded, expected, "")
    }

    func testRawSpanTruncated() throws {
        guard #available(macOS 10.14.4, iOS 12.2, watchOS 5.2, tvOS 12.2, visionOS 1.0, *) else {
            throw XCTSkip("Span structs not available on selected platform")
        }

        let expected = SwiftProtoTesting_TestAllTypes.with {
            $0.optionalInt32 = 1
            $0.optionalInt64 = Int64.max
            $0.optionalString = "RawSpan test"
            $0.repeatedBool = [true, false]
        }

        let encoded: Data = try expected.serializedBytes()
        let truncatedRawSpan: RawSpan = encoded.bytes.extracting(droppingLast: 1)

        var decoded = SwiftProtoTesting_TestAllTypes()

        XCTAssertThrowsError(
            try decoded.merge(serializedBytes: truncatedRawSpan)
        ) { error in
            XCTAssertEqual(error as? BinaryDecodingError, BinaryDecodingError.truncated)
        }
    }
}

#endif
