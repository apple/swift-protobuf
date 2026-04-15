// Sources/SwiftProtobuf/BinaryDecoder.swift - Binary decoding
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Protobuf binary format decoding engine.
///
/// This provides the Decoder interface that interacts directly
/// with the generated code.
///
// -----------------------------------------------------------------------------

import Foundation

internal struct BinaryDecoder {
    // Current position
    private var p: UnsafeRawPointer
    // Remaining bytes in input.
    private var available: Int
    // Position of start of field currently being parsed
    private var fieldStartP: UnsafeRawPointer
    // Position of end of field currently being parsed, nil if we don't know.
    private var fieldEndP: UnsafeRawPointer?
    // Whether or not the field value  has actually been parsed
    private var consumed = true
    // Wire format for last-examined field
    internal var fieldWireFormat = WireFormat.varint
    // Field number for last-parsed field tag
    private var fieldNumber: Int = 0

    // The options for decoding.
    private var options: BinaryDecodingOptions

    private var recursionBudget: Int

    // Collects the unknown data found while decoding a message.
    private var unknownData: Data?


    private var complete: Bool { available == 0 }

    internal init(
        forReadingFrom pointer: UnsafeRawPointer,
        count: Int,
        options: BinaryDecodingOptions
    ) {
        // Assuming baseAddress is not nil.
        p = pointer
        available = count
        fieldStartP = p
        self.options = options
        recursionBudget = options.messageDepthLimit
    }

    internal init(
        forReadingFrom pointer: UnsafeRawPointer,
        count: Int,
        parent: BinaryDecoder
    ) {
        self.init(
            forReadingFrom: pointer,
            count: count,
            options: parent.options
        )
        recursionBudget = parent.recursionBudget
    }

    private mutating func incrementRecursionDepth() throws {
        recursionBudget -= 1
        if recursionBudget < 0 {
            throw BinaryDecodingError.messageDepthLimit
        }
    }

    private mutating func decrementRecursionDepth() {
        recursionBudget += 1
        // This should never happen, if it does, something is probably corrupting memory, and
        // simply throwing doesn't make much sense.
        if recursionBudget > options.messageDepthLimit {
            fatalError("Somehow BinaryDecoding unwound more objects than it started")
        }
    }

    internal mutating func handleConflictingOneOf() throws {
        /// Protobuf simply allows conflicting oneof values to overwrite
    }

    /// Return the next field number or nil if there are no more fields.
    internal mutating func nextFieldNumber() throws -> Int? {
        // Since this is called for every field, I've taken some pains
        // to optimize it, including unrolling a tweaked version of
        // the varint parser.
        if fieldNumber > 0 {
            if !consumed {
                if options.discardUnknownFields {
                    try skip()
                } else {
                    let u = try getRawField()
                    if unknownData == nil {
                        unknownData = u
                    } else {
                        unknownData!.append(u)
                    }
                }
            }
        }

        // Quit if end of input
        if available == 0 {
            return nil
        }

        // Get the next field number
        fieldStartP = p
        fieldEndP = nil
        let start = p
        let c0 = start[0]
        if let wireFormat = WireFormat(rawValue: c0 & 7) {
            fieldWireFormat = wireFormat
        } else {
            throw BinaryDecodingError.malformedProtobuf
        }
        if (c0 & 0x80) == 0 {
            p += 1
            available -= 1
            fieldNumber = Int(c0) >> 3
        } else {
            fieldNumber = Int(c0 & 0x7f) >> 3
            if available < 2 {
                throw BinaryDecodingError.malformedProtobuf
            }
            let c1 = start[1]
            if (c1 & 0x80) == 0 {
                p += 2
                available &-= 2
                fieldNumber |= Int(c1) &<< 4
            } else {
                fieldNumber |= Int(c1 & 0x7f) &<< 4
                if available < 3 {
                    throw BinaryDecodingError.malformedProtobuf
                }
                let c2 = start[2]
                fieldNumber |= Int(c2 & 0x7f) &<< 11
                if (c2 & 0x80) == 0 {
                    p += 3
                    available &-= 3
                } else {
                    if available < 4 {
                        throw BinaryDecodingError.malformedProtobuf
                    }
                    let c3 = start[3]
                    fieldNumber |= Int(c3 & 0x7f) &<< 18
                    if (c3 & 0x80) == 0 {
                        p += 4
                        available &-= 4
                    } else {
                        if available < 5 {
                            throw BinaryDecodingError.malformedProtobuf
                        }
                        let c4 = start[4]
                        if c4 > 15 {
                            throw BinaryDecodingError.malformedProtobuf
                        }
                        fieldNumber |= Int(c4 & 0x7f) &<< 25
                        p += 5
                        available &-= 5
                    }
                }
            }
        }
        if fieldNumber != 0 {
            consumed = false
            return fieldNumber
        }
        throw BinaryDecodingError.malformedProtobuf
    }

    internal mutating func decodeSingularUInt64Field(value: inout UInt64) throws {
        guard fieldWireFormat == WireFormat.varint else {
            return
        }
        value = try decodeVarint()
        consumed = true
    }

    internal mutating func decodeSingularUInt64Field(value: inout UInt64?) throws {
        guard fieldWireFormat == WireFormat.varint else {
            return
        }
        value = try decodeVarint()
        consumed = true
    }

    internal mutating func decodeSingularFixed32Field(value: inout UInt32) throws {
        guard fieldWireFormat == WireFormat.fixed32 else {
            return
        }
        value = try decodeLittleEndianInteger()
        consumed = true
    }

    internal mutating func decodeSingularFixed32Field(value: inout UInt32?) throws {
        guard fieldWireFormat == WireFormat.fixed32 else {
            return
        }
        value = try decodeLittleEndianInteger()
        consumed = true
    }

    internal mutating func decodeSingularFixed64Field(value: inout UInt64) throws {
        guard fieldWireFormat == WireFormat.fixed64 else {
            return
        }
        value = try decodeLittleEndianInteger()
        consumed = true
    }

    internal mutating func decodeSingularFixed64Field(value: inout UInt64?) throws {
        guard fieldWireFormat == WireFormat.fixed64 else {
            return
        }
        value = try decodeLittleEndianInteger()
        consumed = true
    }

    internal mutating func decodeSingularBytesField(value: inout Data) throws {
        guard fieldWireFormat == WireFormat.lengthDelimited else {
            return
        }
        var n: Int = 0
        let p = try getFieldBodyBytes(count: &n)
        value = Data(bytes: p, count: n)
        consumed = true
    }

    internal mutating func decodeSingularBytesField(value: inout Data?) throws {
        guard fieldWireFormat == WireFormat.lengthDelimited else {
            return
        }
        var n: Int = 0
        let p = try getFieldBodyBytes(count: &n)
        value = Data(bytes: p, count: n)
        consumed = true
    }

    //
    // Private building blocks for the parsing above.
    //
    // Having these be private gives the compiler maximum latitude for
    // inlining.
    //

    /// Private:  Advance the current position.
    private mutating func consume(length: Int) {
        available -= length
        p += length
    }

    /// Private: Skip the body for the given tag.  If the given tag is
    /// a group, it parses up through the corresponding group end.
    private mutating func skipOver(tag: FieldTag) throws {
        switch tag.wireFormat {
        case .varint:
            // Don't need the value, just ensuring it is validly encoded.
            let _ = try decodeVarint()
        case .fixed64:
            if available < 8 {
                throw BinaryDecodingError.truncated
            }
            p += 8
            available -= 8
        case .lengthDelimited:
            let n = try decodeVarint()
            if n <= UInt64(available) {
                p += Int(n)
                available -= Int(n)
            } else {
                throw BinaryDecodingError.truncated
            }
        case .startGroup:
            try incrementRecursionDepth()
            while true {
                if let innerTag = try getTagWithoutUpdatingFieldStart() {
                    if innerTag.wireFormat == .endGroup {
                        if innerTag.fieldNumber == tag.fieldNumber {
                            decrementRecursionDepth()
                            break
                        } else {
                            // .endGroup for a something other than the current
                            // group is an invalid binary.
                            throw BinaryDecodingError.malformedProtobuf
                        }
                    } else {
                        try skipOver(tag: innerTag)
                    }
                } else {
                    throw BinaryDecodingError.truncated
                }
            }
        case .endGroup:
            throw BinaryDecodingError.truncated
        case .fixed32:
            if available < 4 {
                throw BinaryDecodingError.truncated
            }
            p += 4
            available -= 4
        }
    }

    /// Private: Skip to the end of the current field.
    ///
    /// Assumes that fieldStartP was bookmarked by a previous
    /// call to getTagType().
    ///
    /// On exit, fieldStartP points to the first byte of the tag, fieldEndP points
    /// to the first byte after the field contents, and p == fieldEndP.
    private mutating func skip() throws {
        if let end = fieldEndP {
            p = end
        } else {
            // Rewind to start of current field.
            available += p - fieldStartP
            p = fieldStartP
            guard let tag = try getTagWithoutUpdatingFieldStart() else {
                throw BinaryDecodingError.truncated
            }
            try skipOver(tag: tag)
            fieldEndP = p
        }
    }

    /// Private: Parse the next raw varint from the input.
    private mutating func decodeVarint() throws -> UInt64 {
        if available < 1 {
            throw BinaryDecodingError.truncated
        }
        var start = p
        var length = available
        var c = start.load(fromByteOffset: 0, as: UInt8.self)
        start += 1
        length &-= 1
        if c & 0x80 == 0 {
            p = start
            available = length
            return UInt64(c)
        }
        var value = UInt64(c & 0x7f)
        var shift = UInt64(7)
        while true {
            if length < 1 || shift > 63 {
                throw BinaryDecodingError.malformedProtobuf
            }
            c = start.load(fromByteOffset: 0, as: UInt8.self)
            start += 1
            length &-= 1
            value |= UInt64(c & 0x7f) &<< shift
            if c & 0x80 == 0 {
                p = start
                available = length
                return value
            }
            shift &+= 7
        }
    }

    /// Private: Get the tag that starts a new field.
    /// This also bookmarks the start of field for a possible skip().
    internal mutating func getTag() throws -> FieldTag? {
        fieldStartP = p
        fieldEndP = nil
        return try getTagWithoutUpdatingFieldStart()
    }

    /// Private: Parse and validate the next tag without
    /// bookmarking the start of the field.  This is used within
    /// skip() to skip over fields within a group.
    private mutating func getTagWithoutUpdatingFieldStart() throws -> FieldTag? {
        if available < 1 {
            return nil
        }
        let t = try decodeVarint()
        if t < UInt64(UInt32.max) {
            guard let tag = FieldTag(rawValue: UInt32(truncatingIfNeeded: t)) else {
                throw BinaryDecodingError.malformedProtobuf
            }
            fieldWireFormat = tag.wireFormat
            fieldNumber = tag.fieldNumber
            return tag
        } else {
            throw BinaryDecodingError.malformedProtobuf
        }
    }

    /// Private: Return a Data containing the entirety of
    /// the current field, including tag.
    private mutating func getRawField() throws -> Data {
        try skip()
        return Data(bytes: fieldStartP, count: fieldEndP! - fieldStartP)
    }

    /// Private: decode a fixed-length number.
    private mutating func decodeLittleEndianInteger<T: FixedWidthInteger>() throws -> T {
        let size = MemoryLayout<T>.size
        assert(size == 4 || size == 8)
        guard available >= size else { throw BinaryDecodingError.truncated }
        defer { consume(length: size) }
        return T(littleEndian: p.loadUnaligned(as: T.self))
    }

    /// Private: Get the start and length for the body of
    /// a length-delimited field.
    private mutating func getFieldBodyBytes(count: inout Int) throws -> UnsafeRawPointer {
        let length = try decodeVarint()

        // Bytes and Strings have a max size of 2GB. And since messages are on
        // the wire as bytes/length delimited, they also have a 2GB size limit.
        // The upstream C++ does the same sort of enforcement (see
        // parse_context, delimited_message_util, message_lite, etc.).
        // https://protobuf.dev/programming-guides/encoding/#cheat-sheet
        //
        // This function does get called in some package decode handling, but
        // that is length delimited on the wire, so the spec would imply
        // the limit still applies.
        guard length < 0x7fff_ffff else {
            // Reuse existing error to avoid breaking change of changing thrown error
            throw BinaryDecodingError.malformedProtobuf
        }

        guard length <= UInt64(available) else {
            throw BinaryDecodingError.truncated
        }

        count = Int(length)
        let body = p
        consume(length: count)
        return body
    }
}
