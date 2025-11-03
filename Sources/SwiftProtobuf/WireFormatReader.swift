// Sources/SwiftProtobuf/WireFormatReader.swift - Low-level reader for protobuf binary format
//
// Copyright (c) 2014 - 2025 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// A low-level reader for data in protobuf binary format.
///
// -----------------------------------------------------------------------------

/// Wraps a memory buffer and provides low-level APIs to read protobuf wire format values from it.
struct WireFormatReader {
    /// The pointer to the location in the buffer from which the next value will be read.
    private var pointer: UnsafeRawPointer?

    /// The pointer to the location in the buffer where the last tag was read started.
    private var lastTagPointer: UnsafeRawPointer?

    /// The number of bytes that are still available to read from the buffer.
    private var available: Int

    /// The maximum number of times that the reader can recurse via sub-readers (for message and
    /// group parsing) before throwing an error.
    private var recursionBudget: Int

    /// If non-zero, this indicates that the reader is being used to read a group with the given
    /// field number.
    ///
    /// When the corresponding end-group tag is encountered, the reader will automatically update
    /// its internal state such that `hasAvailableData` returns false.
    private var trackingGroupFieldNumber: UInt32

    /// Creates a new `WireFormatReader` that reads from the given buffer.
    ///
    /// - Parameters:
    ///   - buffer: The raw buffer from which binary-formatted data will be read.
    ///   - recursionBudget: The maximum number of times that the reader can recurse via
    ///     sub-readers (for message and group parsing) before throwing an error.
    init(buffer: UnsafeRawBufferPointer, recursionBudget: Int) {
        self.init(
            buffer: buffer,
            recursionBudget: recursionBudget,
            trackingGroupFieldNumber: 0
        )
    }

    /// Creates a new `WireFormatReader` with the given buffer and tracking information.
    ///
    /// - Parameters:
    ///   - buffer: The raw buffer from which binary-formatted data will be read.
    ///   - recursionBudget: The maximum number of times that the reader can recurse via
    ///     sub-readers (for message and group parsing) before throwing an error.
    ///   - trackingGroupFieldNumber: If non-zero, this indicates that the reader is currently
    ///     reading a group with the given field number.
    private init(
        buffer: UnsafeRawBufferPointer,
        recursionBudget: Int,
        trackingGroupFieldNumber: UInt32
    ) {
        if buffer.count > 0, let pointer = buffer.baseAddress {
            self.pointer = pointer
            self.lastTagPointer = pointer
            self.available = buffer.count
        } else {
            self.pointer = nil
            self.lastTagPointer = nil
            self.available = 0
        }
        self.recursionBudget = recursionBudget
        self.trackingGroupFieldNumber = trackingGroupFieldNumber
    }

    /// Indicates whether there is still data available to be read in the buffer.
    var hasAvailableData: Bool {
        available > 0
    }

    /// Indicates whether the reader is currently inside a group.
    var isTrackingGroup: Bool {
        trackingGroupFieldNumber != 0
    }

    /// Reads the next varint from the input and returns the equivalent `FieldTag`, updating the
    /// reader's internal state to track the pointer to this tag as the last one that was read.
    ///
    /// - Throws: `BinaryDecodingError` if an error occurred while reading from the input or while
    ///   converting to a tag.
    mutating func nextTag() throws -> FieldTag {
        self.lastTagPointer = pointer
        let tag = try nextTagWithoutUpdatingLastTagPointer()

        if tag.wireFormat == .endGroup {
            // Verify that we're tracking a group and the field number matches the same field
            // number.
            guard trackingGroupFieldNumber == UInt32(tag.fieldNumber) else {
                throw BinaryDecodingError.malformedProtobuf
            }
            available = 0
            trackingGroupFieldNumber = 0
        }

        return tag
    }

    /// Reads the next varint from the input and returns the equivalent `FieldTag` without updating
    /// the reader's state that tracks the pointer to the last tag that was read.
    ///
    /// - Throws: `BinaryDecodingError` if an error occurred while reading from the input or while
    ///   converting to a tag.
    private mutating func nextTagWithoutUpdatingLastTagPointer() throws -> FieldTag {
        let varint = try nextVarint()
        guard varint < UInt64(UInt32.max), let tag = FieldTag(rawValue: UInt32(truncatingIfNeeded: varint)) else {
            throw BinaryDecodingError.malformedProtobuf
        }
        return tag
    }

    /// Reads and returns the next varint from the input.
    ///
    /// - Throws: `BinaryDecodingError` if an error occurred while reading from the input or if the
    ///   varint was malformed.
    mutating func nextVarint() throws -> UInt64 {
        if available < 1 {
            throw BinaryDecodingError.truncated
        }
        var start = pointer!
        var length = available
        var byte = start.load(fromByteOffset: 0, as: UInt8.self)
        start += 1
        length &-= 1
        if byte & 0x80 == 0 {
            pointer = start
            available = length
            return UInt64(byte)
        }

        var value = UInt64(byte & 0x7f)
        var shift = UInt64(7)
        while true {
            if length < 1 || shift > 63 {
                throw BinaryDecodingError.malformedProtobuf
            }
            byte = start.load(fromByteOffset: 0, as: UInt8.self)
            start += 1
            length &-= 1
            value |= UInt64(byte & 0x7f) &<< shift
            if byte & 0x80 == 0 {
                pointer = start
                available = length
                return value
            }
            shift &+= 7
        }
    }

    /// Reads and returns the next 32-bit little endian integer from the input.
    ///
    /// - Throws: `BinaryDecodingError` if an error occurred while reading from the input.
    mutating func nextLittleEndianUInt32() throws -> UInt32 {
        let size = MemoryLayout<UInt32>.size
        guard available >= size else { throw BinaryDecodingError.truncated }
        defer { advance(by: size) }
        return UInt32(littleEndian: pointer!.loadUnaligned(as: UInt32.self))
    }

    /// Reads and returns the next 64-bit little endian integer from the input.
    ///
    /// - Throws: `BinaryDecodingError` if an error occurred while reading from the input.
    mutating func nextLittleEndianUInt64() throws -> UInt64 {
        let size = MemoryLayout<UInt64>.size
        guard available >= size else { throw BinaryDecodingError.truncated }
        defer { advance(by: size) }
        return UInt64(littleEndian: pointer!.loadUnaligned(as: UInt64.self))
    }

    /// Reads the next varint from the input and validates that it falls within the permitted range
    /// for length delimited fields.
    ///
    /// - Throws: `BinaryDecodingError` if an error occurred while reading from the input or if the
    ///   value read was greater than 2GB.
    mutating func nextVarintAsValidatedDelimitedLength() throws -> Int {
        let length = try nextVarint()

        // Length-delimited fields (bytes, strings, and messages) have a maximum size of 2GB. The
        // upstream C++ implementation does the same sort of enforcement (see `parse_context`,
        // `delimited_message_util`, `message_lite`, etc.).
        // https://protobuf.dev/programming-guides/encoding/#cheat-sheet
        //
        // This function also gets called for some packed repeated fields
        // that is length delimited on the wire, so the spec would imply
        // the limit still applies.
        guard length < 0x7fff_ffff else {
            // Reuse existing error to avoid breaking change of changing thrown error
            throw BinaryDecodingError.malformedProtobuf
        }
        guard length <= UInt64(available) else {
            throw BinaryDecodingError.truncated
        }
        return Int(length)
    }

    /// Reads the next varint from the input that indicates the length of the subsequent data and
    /// then returns a rebased `UnsafeRawBufferPointer` representing that slice of the buffer,
    /// advancing the reader past it.
    ///
    /// - Throws: `BinaryDecodingError` if an error occurred while reading from the input.
    mutating func nextLengthDelimitedSlice() throws -> UnsafeRawBufferPointer {
        let length = try nextVarintAsValidatedDelimitedLength()
        defer { advance(by: length) }
        return UnsafeRawBufferPointer(start: pointer, count: length)
    }

    /// Calls the given function, passing it a reader that is configured only to read the slice of
    /// the buffer whose length is defined by reading the next varint.
    ///
    /// After the function returns, this reader is advanced past that length to continue reading.
    ///
    /// - Throws: `BinaryDecodingError` if an error occurred while reading from the input.
    mutating func withReaderForNextLengthDelimitedSlice(perform: (inout WireFormatReader) throws -> Void) throws {
        guard recursionBudget > 0 else {
            throw BinaryDecodingError.messageDepthLimit
        }
        let length = try nextVarintAsValidatedDelimitedLength()
        let subBuffer = UnsafeRawBufferPointer(start: pointer, count: length)
        var subReader = WireFormatReader(
            buffer: subBuffer,
            recursionBudget: recursionBudget &- 1,
            trackingGroupFieldNumber: 0
        )
        try perform(&subReader)
        advance(by: length)
    }

    /// Calls the given function, passing it a reader that is configured only to read the slice of
    /// the buffer up to the next end-group tag that has the same field number.
    ///
    /// After the function returns, this reader is advanced past that end-group tag to continue
    /// reading.
    ///
    /// - Throws: `BinaryDecodingError` if an error occurred while reading from the input.
    mutating func withReaderForNextGroup(
        withFieldNumber fieldNumber: UInt32,
        perform: (inout WireFormatReader) throws -> Void
    ) throws {
        guard recursionBudget > 0 else {
            throw BinaryDecodingError.messageDepthLimit
        }
        // Unlike a length-delimited field, we don't know exactly where the group will end. Have
        // the sub-reader start with the rest of the buffer, and after the the closure returns,
        // we'll know how far to advance ourselves.
        let subBuffer = UnsafeRawBufferPointer(start: pointer, count: available)
        var subReader = WireFormatReader(
            buffer: subBuffer,
            recursionBudget: recursionBudget &- 1,
            trackingGroupFieldNumber: fieldNumber
        )
        try perform(&subReader)

        guard let subPointer = subReader.pointer else {
            throw BinaryDecodingError.truncated
        }
        advance(by: subPointer - pointer!)
    }

    /// Advances the reader past the field at the current location, assuming it had the given tag,
    /// and returns a rebased `UnsafeRawBufferPointer` representing the slice of the buffer that
    /// includes the tag and subsequent data for that field.
    ///
    /// - Throws: `BinaryDecodingError` if an error occurred while reading from the input.
    mutating func sliceBySkippingField(tag: FieldTag) throws -> UnsafeRawBufferPointer {
        switch tag.wireFormat {
        case .varint:
            _ = try nextVarint()

        case .lengthDelimited:
            advance(by: try nextVarintAsValidatedDelimitedLength())

        case .fixed32:
            let size = MemoryLayout<UInt32>.size
            guard available >= size else { throw BinaryDecodingError.truncated }
            advance(by: size)

        case .fixed64:
            let size = MemoryLayout<UInt64>.size
            guard available >= size else { throw BinaryDecodingError.truncated }
            advance(by: size)

        case .startGroup:
            guard recursionBudget > 0 else {
                throw BinaryDecodingError.messageDepthLimit
            }
            recursionBudget &-= 1
            while hasAvailableData {
                let innerTag = try nextTagWithoutUpdatingLastTagPointer()
                if innerTag.wireFormat == .endGroup {
                    guard innerTag.fieldNumber == tag.fieldNumber else {
                        // The binary data is invalid if the startGroup/endGroup field numbers are
                        // not balanced.
                        throw BinaryDecodingError.malformedProtobuf
                    }
                    recursionBudget &+= 1
                    break
                } else {
                    _ = try sliceBySkippingField(tag: innerTag)
                }
            }
            if !hasAvailableData {
                throw BinaryDecodingError.truncated
            }

        case .endGroup:
            throw BinaryDecodingError.truncated
        }

        return UnsafeRawBufferPointer(start: lastTagPointer, count: pointer! - lastTagPointer!)
    }

    /// Advances the input the given number of bytes.
    ///
    /// - Precondition: There must be at least `length` amount of data in the buffer. It is the
    ///   caller's responsibility to verify this and throw if there is not.
    private mutating func advance(by length: Int) {
        precondition(
            available >= length,
            "Internal error: tried to advance \(length) bytes with only \(available) available"
        )
        available &-= length
        pointer! += length
    }
}
