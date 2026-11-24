// Tests/SwiftProtobufTests/Test_BinaryEncodingOptions.swift - Tests for binary encoding options
//
// Copyright (c) 2014 - 2023 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Test for the use of BinaryEncodingOptions
///
// -----------------------------------------------------------------------------

import Foundation
import Testing
import XCTest

@testable import SwiftProtobuf

final class Test_BinaryEncodingOptions: XCTestCase {

    func testUseDeterministicOrdering() throws {
        var options = BinaryEncodingOptions()
        options.useDeterministicOrdering = true

        let message1 = SwiftProtoTesting_Message3.with {
            $0.mapStringString = [
                "b": "B",
                "a": "A",
                "0": "0",
                "UPPER": "v",
                "x": "X",
            ]
            $0.mapInt32Message = [
                5: .with { $0.optionalSint32 = 5 },
                1: .with { $0.optionalSint32 = 1 },
                3: .with { $0.optionalSint32 = 3 },
            ]
            $0.mapInt32Enum = [
                5: .foo,
                3: .bar,
                0: .baz,
                1: .extra3,
            ]
        }

        let message2 = SwiftProtoTesting_Message3.with {
            $0.mapStringString = [
                "UPPER": "v",
                "a": "A",
                "b": "B",
                "x": "X",
                "0": "0",
            ]
            $0.mapInt32Message = [
                1: .with { $0.optionalSint32 = 1 },
                3: .with { $0.optionalSint32 = 3 },
                5: .with { $0.optionalSint32 = 5 },
            ]
            $0.mapInt32Enum = [
                3: .bar,
                5: .foo,
                1: .extra3,
                0: .baz,
            ]
        }

        // Approximation that serializing models with the same data (but initialized with keys in
        // different orders) consistently produces the same outputs.
        let expectedOutput = try message1.serializedData(options: options)
        for _ in 0..<10 {
            XCTAssertEqual(try message2.serializedData(options: options), expectedOutput)
        }
    }
}

struct BinaryEncoderVarintTests: ~Copyable {
    /// All 1-byte through 10-byte varint boundary values (`2^(7k) - 1` and `2^(7k)`).
    static let varintBoundaries: [UInt64] = [
        0,
        1,
        0x7f,
        0x80,
        0x3fff,
        0x4000,
        0x1f_ffff,
        0x20_0000,
        0x0fff_ffff,
        0x1000_0000,
        0x07_ffff_ffff,
        0x08_0000_0000,
        0x03ff_ffff_ffff,
        0x0400_0000_0000,
        0x01_ffff_ffff_ffff,
        0x02_0000_0000_0000,
        0x00ff_ffff_ffff_ffff,
        0x0100_0000_0000_0000,
        0x7fff_ffff_ffff_ffff,
        0x8000_0000_0000_0000,
        0xffff_ffff_ffff_ffff,
    ]

    /// Field numbers spanning 1-byte through 5-byte wire tags.
    static let tagFieldNumbers: [Int] = [
        1,
        15,
        16,
        2047,
        2048,
        262_143,
        262_144,
        33_554_431,
        33_554_432,
        536_870_911,
    ]

    /// Aligned and unaligned buffer offsets used to exercise multi-byte `storeBytes` writes.
    static let alignmentOffsets: [Int] = [0, 1, 2, 3, 5, 7]

    private static func referenceEncodeVarint(_ value: UInt64) -> [UInt8] {
        var v = value
        var bytes: [UInt8] = []
        while v >= 0x80 {
            bytes.append(UInt8((v & 0x7f) | 0x80))
            v >>= 7
        }
        bytes.append(UInt8(v))
        return bytes
    }

    /// Runs `encode` against an exact-sized slice positioned at `alignmentOffset`, bracketed by
    /// leading and trailing sentinel bytes to verify exact write counts and zero trailing slop.
    private static func encodeExactWithCanaries(
        exactSize: Int,
        alignmentOffset: Int,
        sourceLocation: SourceLocation = #_sourceLocation,
        _ encode: (inout BinaryEncoder) -> Void
    ) -> [UInt8] {
        let trailingCanaryCount = 16
        let leadingSentinel: UInt8 = 0xaa
        let payloadFill: UInt8 = 0x55
        let trailingSentinel: UInt8 = 0xbb

        var storage = [UInt8](repeating: trailingSentinel, count: alignmentOffset + exactSize + trailingCanaryCount)
        for i in 0..<alignmentOffset {
            storage[i] = leadingSentinel
        }
        for i in alignmentOffset..<(alignmentOffset + exactSize) {
            storage[i] = payloadFill
        }

        storage.withUnsafeMutableBytes { rawBuffer in
            let slice = UnsafeMutableRawBufferPointer(
                start: rawBuffer.baseAddress! + alignmentOffset,
                count: exactSize
            )
            var encoder = BinaryEncoder(forWritingInto: slice)
            encode(&encoder)
            #expect(encoder.used == exactSize, sourceLocation: sourceLocation)
            #expect(encoder.remainder.count == 0, sourceLocation: sourceLocation)
        }

        for i in 0..<alignmentOffset {
            #expect(storage[i] == leadingSentinel, sourceLocation: sourceLocation)
        }
        for i in (alignmentOffset + exactSize)..<storage.count {
            #expect(storage[i] == trailingSentinel, sourceLocation: sourceLocation)
        }
        return Array(storage[alignmentOffset..<(alignmentOffset + exactSize)])
    }

    @Test(arguments: Self.varintBoundaries)
    func `putVarInt matches reference bytes across 1B to 10B boundaries and unaligned offsets`(value: UInt64) {
        let expected = Self.referenceEncodeVarint(value)
        #expect(Varint.encodedSize(of: value) == expected.count)

        for offset in Self.alignmentOffsets {
            let actual = Self.encodeExactWithCanaries(exactSize: expected.count, alignmentOffset: offset) { encoder in
                encoder.putVarInt(value: value)
            }
            #expect(actual == expected)
        }
    }

    @Test(arguments: [Int64(0), 1, 127, 128, -1, -2, -128, Int64(Int32.min), Int64(Int32.max), Int64.min, Int64.max])
    func `putVarInt signed and ZigZag overloads encode exact bytes at unaligned offsets`(value: Int64) {
        let expectedSigned = Self.referenceEncodeVarint(UInt64(bitPattern: value))
        let expectedZigZag = Self.referenceEncodeVarint(UInt64(zigZagEncoded: value))

        for offset in Self.alignmentOffsets {
            let signedActual = Self.encodeExactWithCanaries(exactSize: expectedSigned.count, alignmentOffset: offset) {
                encoder in
                encoder.putVarInt(value: value)
            }
            #expect(signedActual == expectedSigned)

            let zigZagActual = Self.encodeExactWithCanaries(exactSize: expectedZigZag.count, alignmentOffset: offset) {
                encoder in
                encoder.putZigZagVarInt(value: value)
            }
            #expect(zigZagActual == expectedZigZag)
        }
    }

    @Test(arguments: Self.tagFieldNumbers)
    func `putFieldVarInt matches reference bytes across all tag and value quadrants`(fieldNumber: Int) {
        let wireFormats: [WireFormat] = [.varint, .lengthDelimited]
        let sampleValues: [UInt64] = [
            0,
            1,
            0x7f,
            0x80,
            0x3fff,
            0x4000,
            0x1f_ffff,
            0x0fff_ffff,
            0x07_ffff_ffff,
            0x03ff_ffff_ffff,
            0x01_ffff_ffff_ffff,
            0x7fff_ffff_ffff_ffff,
            0x8000_0000_0000_0000,
            0xffff_ffff_ffff_ffff,
        ]

        for wireFormat in wireFormats {
            let tag = FieldTag(fieldNumber: fieldNumber, wireFormat: wireFormat)
            let expectedTag = Self.referenceEncodeVarint(UInt64(tag.rawValue))
            #expect(tag.encodedSize == expectedTag.count)

            for value in sampleValues {
                let expected = expectedTag + Self.referenceEncodeVarint(value)
                for offset in Self.alignmentOffsets {
                    let viaFieldNumber = Self.encodeExactWithCanaries(
                        exactSize: expected.count,
                        alignmentOffset: offset
                    ) { encoder in
                        encoder.putFieldVarInt(fieldNumber: fieldNumber, wireFormat: wireFormat, value: value)
                    }
                    #expect(viaFieldNumber == expected)

                    let viaTag = Self.encodeExactWithCanaries(
                        exactSize: expected.count,
                        alignmentOffset: offset
                    ) { encoder in
                        encoder.putFieldVarInt(tag: tag, value: value)
                    }
                    #expect(viaTag == expected)
                }
            }
        }
    }

    @Test func `putFieldVarInt signed Int64 and Int overloads sign-extend negative values`() {
        let cases: [(Int, Int64)] = [
            (1, -1),
            (15, Int64(Int32.min)),
            (16, -1),
            (2048, Int64.min),
            (1, 0),
            (1, 0x7f),
            (1, 0x80),
            (16, 0x7f),
        ]

        for (fieldNumber, value) in cases {
            let tag = FieldTag(fieldNumber: fieldNumber, wireFormat: .varint)
            let expected =
                Self.referenceEncodeVarint(UInt64(tag.rawValue))
                + Self.referenceEncodeVarint(UInt64(bitPattern: value))

            for offset in Self.alignmentOffsets {
                let actualInt64 = Self.encodeExactWithCanaries(exactSize: expected.count, alignmentOffset: offset) {
                    encoder in
                    encoder.putFieldVarInt(fieldNumber: fieldNumber, wireFormat: .varint, value: value)
                }
                #expect(actualInt64 == expected)

                if let intValue = Int(exactly: value) {
                    let actualInt = Self.encodeExactWithCanaries(exactSize: expected.count, alignmentOffset: offset) {
                        encoder in
                        encoder.putFieldVarInt(fieldNumber: fieldNumber, wireFormat: .varint, value: intValue)
                    }
                    #expect(actualInt == expected)

                    let actualTagInt = Self.encodeExactWithCanaries(exactSize: expected.count, alignmentOffset: offset)
                    {
                        encoder in
                        encoder.putFieldVarInt(tag: tag, value: intValue)
                    }
                    #expect(actualTagInt == expected)
                }
            }
        }
    }

    @Test func `scalar varint fields serialize exact wire bytes across tag and value boundaries`() throws {
        var msg = SwiftProtoTesting_TestAllTypes()
        msg.optionalInt32 = -1
        msg.optionalInt64 = Int64.min
        msg.optionalUint32 = 0x7f
        msg.optionalUint64 = UInt64.max
        msg.optionalSint32 = -64
        msg.optionalSint64 = Int64.max
        msg.optionalBool = true
        msg.optionalNestedEnum = .neg

        let encoded: [UInt8] = try msg.serializedBytes()
        var expected: [UInt8] = []
        expected += Self.referenceEncodeVarint(UInt64(FieldTag(fieldNumber: 1, wireFormat: .varint).rawValue))
        expected += Self.referenceEncodeVarint(UInt64(bitPattern: Int64(-1)))
        expected += Self.referenceEncodeVarint(UInt64(FieldTag(fieldNumber: 2, wireFormat: .varint).rawValue))
        expected += Self.referenceEncodeVarint(UInt64(bitPattern: Int64.min))
        expected += Self.referenceEncodeVarint(UInt64(FieldTag(fieldNumber: 3, wireFormat: .varint).rawValue))
        expected += [0x7f]
        expected += Self.referenceEncodeVarint(UInt64(FieldTag(fieldNumber: 4, wireFormat: .varint).rawValue))
        expected += Self.referenceEncodeVarint(UInt64.max)
        expected += Self.referenceEncodeVarint(UInt64(FieldTag(fieldNumber: 5, wireFormat: .varint).rawValue))
        expected += Self.referenceEncodeVarint(UInt64(UInt32(zigZagEncoded: Int32(-64))))
        expected += Self.referenceEncodeVarint(UInt64(FieldTag(fieldNumber: 6, wireFormat: .varint).rawValue))
        expected += Self.referenceEncodeVarint(UInt64(zigZagEncoded: Int64.max))
        expected += Self.referenceEncodeVarint(UInt64(FieldTag(fieldNumber: 13, wireFormat: .varint).rawValue))
        expected += [1]
        expected += Self.referenceEncodeVarint(UInt64(FieldTag(fieldNumber: 21, wireFormat: .varint).rawValue))
        expected += Self.referenceEncodeVarint(UInt64(bitPattern: Int64(-1)))
        #expect(encoded == expected)

        let decoded = try SwiftProtoTesting_TestAllTypes(serializedBytes: encoded)
        #expect(decoded == msg)

        // Exercise 5-byte tag with both small (< 0x80) and negative (10-byte) values.
        for bbValue: Int32 in [0, 127, 128, -1] {
            var large = SwiftProtoTesting_TestReallyLargeTagNumber()
            large.a = 127
            large.bb = bbValue
            let largeBytes: [UInt8] = try large.serializedBytes()
            let largeDecoded = try SwiftProtoTesting_TestReallyLargeTagNumber(serializedBytes: largeBytes)
            #expect(largeDecoded == large)
        }
    }

    @Test func `string and bytes fields fuse tag and length across UTF-8 and multi-byte length boundaries`() throws {
        let multiByteUTF8 = "héllo 🌍 日本語"
        #expect(multiByteUTF8.count < multiByteUTF8.utf8.count)
        let boundaryUTF8 = String(repeating: "é", count: 64)  // 128 UTF-8 bytes
        #expect(boundaryUTF8.utf8.count == 128)

        let strings: [String] = [
            "",
            "a",
            String(repeating: "x", count: 127),
            String(repeating: "y", count: 128),
            String(repeating: "z", count: 16_384),
            multiByteUTF8,
            boundaryUTF8,
        ]

        for stringValue in strings {
            var msg = SwiftProtoTesting_TestAllTypes()
            msg.optionalString = stringValue  // field 14 (1-byte tag)
            msg.repeatedString = [stringValue, ""]  // field 44 (2-byte tag)
            let bytes: [UInt8] = try msg.serializedBytes()
            let decoded = try SwiftProtoTesting_TestAllTypes(serializedBytes: bytes)
            #expect(decoded == msg)
        }

        let bytePayloads: [Data] = [
            Data(),
            Data([0x42]),
            Data(repeating: 0x11, count: 127),
            Data(repeating: 0x22, count: 128),
            Data(repeating: 0x33, count: 16_384),
        ]
        for payload in bytePayloads {
            var msg = SwiftProtoTesting_TestAllTypes()
            msg.optionalBytes = payload  // field 15 (1-byte tag)
            msg.repeatedBytes = [payload, Data()]  // field 45 (2-byte tag)
            let bytes: [UInt8] = try msg.serializedBytes()
            let decoded = try SwiftProtoTesting_TestAllTypes(serializedBytes: bytes)
            #expect(decoded == msg)
        }

        #if canImport(ObjectiveC)
        // Exercise the non-contiguous String.UTF8View fallback path on Apple platforms.
        for base in ["", multiByteUTF8, boundaryUTF8] {
            let mutable = NSMutableString(string: base)
            let bridged = mutable as String
            #expect(bridged.utf8.withContiguousStorageIfAvailable { _ in true } == nil)
            var msg = SwiftProtoTesting_TestAllTypes()
            msg.optionalString = bridged
            msg.repeatedString = [bridged]
            let bytes: [UInt8] = try msg.serializedBytes()
            let decoded = try SwiftProtoTesting_TestAllTypes(serializedBytes: bytes)
            #expect(decoded.optionalString == base)
            #expect(decoded.repeatedString == [base])
        }
        #endif
    }

    @Test func `maps and submessages serialize exact bytes across 1-byte and multi-byte tags and lengths`() throws {
        var options = BinaryEncodingOptions()
        options.useDeterministicOrdering = true

        var mapMsg = SwiftProtoTesting_TestMap()
        // 1-byte map field tags (fields 1, 2, 14) with short (< 0x80) and long (>= 0x80) entries.
        mapMsg.mapInt32Int32 = [-1: Int32.min, 1: 2, 127: 128]
        mapMsg.mapInt64Int64 = [Int64.min: Int64.max, 0: 127]
        mapMsg.mapStringString = [
            "k": "v",
            "long": String(repeating: "m", count: 140),
        ]
        // 2-byte map field tags (fields 16, 17, 19) with short and long submessage values.
        mapMsg.mapInt32Enum = [1: .foo, 2: .bar]
        mapMsg.mapInt32ForeignMessage = [1: .with { $0.c = 42 }, 2: .with { $0.c = -1 }]
        mapMsg.mapInt32AllTypes = [
            1: .with { $0.optionalInt32 = 1 },
            2: .with { $0.optionalString = String(repeating: "s", count: 140) },
        ]

        let mapBytes: [UInt8] = try mapMsg.serializedBytes(options: options)
        let decodedMap = try SwiftProtoTesting_TestMap(serializedBytes: mapBytes)
        #expect(decodedMap == mapMsg)

        // Submessages: 1-byte tag (TestRecursiveMessage.a = field 1) across empty, small, and >= 0x80 lengths.
        var deep = SwiftProtoTesting_TestRecursiveMessage()
        deep.i = -1
        for i: Int32 in 0..<35 {
            var outer = SwiftProtoTesting_TestRecursiveMessage()
            outer.i = i
            outer.a = deep
            deep = outer
        }
        let recursiveBytes: [UInt8] = try deep.serializedBytes()
        #expect(recursiveBytes.count >= 128)
        let decodedRecursive = try SwiftProtoTesting_TestRecursiveMessage(serializedBytes: recursiveBytes)
        #expect(decodedRecursive == deep)

        // Submessages: 2-byte tag singular (field 18) and repeated (field 48) including empty submessage.
        var nested = SwiftProtoTesting_TestAllTypes()
        nested.optionalNestedMessage = SwiftProtoTesting_TestAllTypes.NestedMessage()
        nested.repeatedNestedMessage = [
            SwiftProtoTesting_TestAllTypes.NestedMessage(),
            .with { $0.bb = 127 },
            .with { $0.bb = -1 },
        ]
        let nestedBytes: [UInt8] = try nested.serializedBytes()
        let decodedNested = try SwiftProtoTesting_TestAllTypes(serializedBytes: nestedBytes)
        #expect(decodedNested == nested)
    }

    @Test func `packed and unpacked varints and enums preserve boundaries and negative sign-extension`() throws {
        var packed = SwiftProtoTesting_TestPackedTypes()
        packed.packedInt32 = [0, 1, 0x7f, 0x80, 0x3fff, 0x4000, Int32.max, -1, Int32.min]
        packed.packedInt64 = [
            0, 1, 0x7f, 0x80, 0x3fff, 0x4000, 0x1f_ffff, 0x0fff_ffff, 0x07_ffff_ffff, 0x03ff_ffff_ffff,
            0x01_ffff_ffff_ffff, Int64.max, -1, Int64.min,
        ]
        packed.packedUint32 = [0, 1, 0x7f, 0x80, 0x3fff, 0x4000, 0x1f_ffff, 0x0fff_ffff, UInt32.max]
        packed.packedUint64 = Self.varintBoundaries
        packed.packedSint32 = [0, -1, 1, -64, 64, -8192, 8192, Int32.min, Int32.max]
        packed.packedSint64 = [0, -1, 1, -64, 64, -8192, 8192, Int64.min, Int64.max]
        // Also push a packed fixed field past 128 bytes to exercise multi-byte packed fixed lengths.
        packed.packedFixed32 = (0..<40).map(UInt32.init)

        let packedBytes: [UInt8] = try packed.serializedBytes()
        let decodedPacked = try SwiftProtoTesting_TestPackedTypes(serializedBytes: packedBytes)
        #expect(decodedPacked == packed)

        // Packed open enums (proto3) with negative and multi-byte unknown enum raw values,
        // plus total packed length >= 0x80.
        var proto3 = SwiftProtoTesting_Test3_TestAllTypesProto3()
        let enumSample: [SwiftProtoTesting_Test3_TestAllTypesProto3.NestedEnum] = [
            .foo,
            .bar,
            .baz,
            .neg,
            .UNRECOGNIZED(0x7f),
            .UNRECOGNIZED(0x80),
            .UNRECOGNIZED(0x3fff),
            .UNRECOGNIZED(0x4000),
            .UNRECOGNIZED(Int(Int32.max)),
            .UNRECOGNIZED(Int(Int32.min)),
        ]
        proto3.repeatedNestedEnum = Array(repeating: enumSample, count: 4).flatMap { $0 }
        let proto3Bytes: [UInt8] = try proto3.serializedBytes()
        let decodedProto3 = try SwiftProtoTesting_Test3_TestAllTypesProto3(serializedBytes: proto3Bytes)
        #expect(decodedProto3 == proto3)

        // Unpacked proto2 enum field with negative raw value (.neg = -1) must sign-extend to 10 bytes.
        var unpackedEnumMsg = SwiftProtoTesting_TestAllTypes()
        unpackedEnumMsg.repeatedNestedEnum = [.foo, .neg, .baz]
        let unpackedBytes: [UInt8] = try unpackedEnumMsg.serializedBytes()
        let enumTag = Self.referenceEncodeVarint(UInt64(FieldTag(fieldNumber: 51, wireFormat: .varint).rawValue))
        var expectedUnpacked: [UInt8] = []
        expectedUnpacked += enumTag + [1]
        expectedUnpacked += enumTag + Self.referenceEncodeVarint(UInt64(bitPattern: Int64(-1)))
        expectedUnpacked += enumTag + [3]
        #expect(unpackedBytes == expectedUnpacked)
        let decodedUnpacked = try SwiftProtoTesting_TestAllTypes(serializedBytes: unpackedBytes)
        #expect(decodedUnpacked == unpackedEnumMsg)
    }

    @Test func `extensions and MessageSet serialize exact bytes across varint and length boundaries`() throws {
        // Singular, repeated message, and unpacked negative enum extensions.
        var extMsg = SwiftProtoTesting_TestAllExtensions()
        extMsg.SwiftProtoTesting_optionalInt32Extension = -1
        extMsg.SwiftProtoTesting_optionalInt64Extension = Int64.min
        extMsg.SwiftProtoTesting_optionalStringExtension = String(repeating: "e", count: 130)
        extMsg.SwiftProtoTesting_optionalBytesExtension = Data(repeating: 0x7a, count: 128)
        extMsg.SwiftProtoTesting_optionalNestedMessageExtension = .with { $0.bb = 127 }
        extMsg.SwiftProtoTesting_repeatedNestedMessageExtension = [
            SwiftProtoTesting_TestAllTypes.NestedMessage(),
            .with { $0.bb = -1 },
        ]
        extMsg.SwiftProtoTesting_repeatedNestedEnumExtension = [.foo, .neg, .bar]

        let extBytes: [UInt8] = try extMsg.serializedBytes()
        let decodedExt = try SwiftProtoTesting_TestAllExtensions(
            serializedBytes: extBytes,
            extensions: SwiftProtoTesting_Unittest_Extensions
        )
        #expect(decodedExt == extMsg)

        // Verify unpacked repeated negative enum extension encodes .neg (-1) as 10 bytes.
        var negEnumExt = SwiftProtoTesting_TestAllExtensions()
        negEnumExt.SwiftProtoTesting_repeatedNestedEnumExtension = [.neg]
        let negEnumExtBytes: [UInt8] = try negEnumExt.serializedBytes()
        let expectedNegExt =
            Self.referenceEncodeVarint(UInt64(FieldTag(fieldNumber: 51, wireFormat: .varint).rawValue))
            + Self.referenceEncodeVarint(UInt64(bitPattern: Int64(-1)))
        #expect(negEnumExtBytes == expectedNegExt)

        // Packed varint and packed enum extensions across 1B..10B boundaries and >= 0x80 total length.
        var packedExt = SwiftProtoTesting_TestPackedExtensions()
        packedExt.SwiftProtoTesting_packedInt32Extension = [0, 0x7f, 0x80, 0x3fff, 0x4000, Int32.max, -1, Int32.min]
        packedExt.SwiftProtoTesting_packedInt64Extension = [0, 0x7f, 0x80, 0x3fff, 0x4000, Int64.max, -1, Int64.min]
        packedExt.SwiftProtoTesting_packedUint32Extension = [0, 0x7f, 0x80, 0x3fff, 0x4000, UInt32.max]
        packedExt.SwiftProtoTesting_packedUint64Extension = Self.varintBoundaries
        packedExt.SwiftProtoTesting_packedSint32Extension = [0, -1, 1, -64, 64, Int32.min, Int32.max]
        packedExt.SwiftProtoTesting_packedSint64Extension = [0, -1, 1, -64, 64, Int64.min, Int64.max]
        packedExt.SwiftProtoTesting_packedEnumExtension = Array(
            repeating: [SwiftProtoTesting_ForeignEnum.foreignFoo, .foreignBar, .foreignBaz],
            count: 50
        ).flatMap { $0 }

        let packedExtBytes: [UInt8] = try packedExt.serializedBytes()
        let decodedPackedExt = try SwiftProtoTesting_TestPackedExtensions(
            serializedBytes: packedExtBytes,
            extensions: SwiftProtoTesting_Unittest_Extensions
        )
        #expect(decodedPackedExt == packedExt)

        // MessageSet extensions exercising both < 0x80 and >= 0x80 payload lengths.
        var messageSet = SwiftProtoTesting_WireFormat_TestMessageSet()
        messageSet.SwiftProtoTesting_TestMessageSetExtension1_messageSetExtension.i = 123
        messageSet.SwiftProtoTesting_TestMessageSetExtension2_messageSetExtension.str = String(
            repeating: "m",
            count: 140
        )

        let messageSetBytes: [UInt8] = try messageSet.serializedBytes()
        let rawMessageSet = try SwiftProtoTesting_RawMessageSet(serializedBytes: messageSetBytes)
        #expect(rawMessageSet.item.count == 2)
        #expect(rawMessageSet.item[0].message.count < 128)
        #expect(rawMessageSet.item[1].message.count >= 128)

        let decodedMessageSet = try SwiftProtoTesting_WireFormat_TestMessageSet(
            serializedBytes: messageSetBytes,
            extensions: SwiftProtoTesting_UnittestMset_Extensions
        )
        #expect(decodedMessageSet == messageSet)
    }
}
