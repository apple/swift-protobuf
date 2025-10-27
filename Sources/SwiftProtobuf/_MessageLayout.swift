// Sources/SwiftProtobuf/_MessageLayout.swift - Table-driven message layout
//
// Copyright (c) 2014 - 2025 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// The in-memory layout description for the fields of a table-driven message.
///
// -----------------------------------------------------------------------------

import Foundation

/// Defines the in-memory layout of the storage for a message.
///
/// This type is public because it needs to be referenced and initialized from generated messages.
/// Clients should not access it directly.
///
/// ## Encoded Layout
///
/// The message layout is encoded in UTF-8-compatible form as a `StaticString`. Unlike `_NameMap`,
/// which uses variable-width sequences of "instructions", the message layout is represented as a
/// fixed size "header" followed by a sequence of fixed size field layout descriptors. This allows
/// for fast lookup of those fields (constant time in some cases, falling back to binary search
/// when needed).
///
/// ### General integer encoding
///
/// Since the string must be valid UTF-8, it is simplest to restrict all bytes in the string to
/// 7-bit ASCII (0x00...0x7F). Therefore, we encode larger integers in a fixed base-128 format;
/// no continuation bit is used (the MSB is always 0) and the layout specification determines the
/// expected width of any encoded integers. For example, if we were encoding 16-bit integers, we
/// would need 3 bytes, because 65536 would be encoded as 00000011 01111111 01111111.
///
/// ### Message layout header
///
/// The **message layout header** describes properties of the entire message:
///
/// ```
/// +---------+--------------+-------------+----------------+-------------------+
/// | Bytes 0 | Bytes 1-3    | Bytes 4-6   | Bytes 7-9      | Byte 10-12        |
/// | Version | Message size | Field count | Required count | Density threshold |
/// +---------+--------------+-------------+----------------+-------------------+
/// ```
/// *   Byte 0: A `UInt8` that describes the version of the layout. Currently, this is always 0.
///     This value allows for future enhancements to be made to the layout but preserving backward
///     compatibility.
/// *   Bytes 1-3: The size of the message in bytes, as a base-128 integer. 64KB is an upper bound
///     on message size imposed in practice by µpb, since it uses a `uint16_t` to represent field
///     offsets in their own mini-tables.
/// *   Bytes 4-6: The number of fields defined by the message, as a base-128 integer.
///     65536 is an upper bound imposed in practice by the core protobuf implementation
///     (https://github.com/protocolbuffers/protobuf/commit/90824aaa69000452bff5ad8db3240215a3b9a595)
///     since larger messages would overflow various data structures.
/// *   Bytes 7-9: The number of required fields defined by the message, as a base-128 integer.
/// *   Bytes 10-12: The largest field number `N` for which all fields in the range `1..<N` are
///     inhabited, as a base-128 integer. We only need three bytes to represent this because the
///     largest possible number is 65537; otherwise, it would imply that the message had more than
///     65536 fields in violation of the bound above.
///
/// ### Field layouts
///
/// After the header above, starting at byte offset 13, is a sequence of encoded field layouts.
/// Each field layout is 13 bytes long and they are written in field number order. Each entry
/// encodes the following information:
///
/// ```
/// +---------------------+-----------+-----------+------------------+------------+
/// | Bytes 0-4           | Bytes 5-7 | Bytes 8-9 | Bytes 10-11      | Byte 12    |
/// | Field number & mode | Offset    | Presence  | Submessage index | Field type |
/// +---------------------+-----------+-----------+------------------+------------+
/// ```
///
/// *   Bytes 0-4: A packed value where the low 33-bits are a base-128 integer that encodes the
///     29-bit field number, and the remaining bits of byte 4 represent the field mode.
/// *   Bytes 5-7: The byte offset of the field in in-memory storage, as a base-128 integer. To
///     match µpb's layout constraints, this value will never be larger than 2^16 - 1.
/// *   Bytes 8-9: Information about the field's presence. Specifically,
///     *   If this field is a member of a `oneof`, then the bitwise inverse of this value is the
///         byte offset into in-memory storage where the field number of the populated `oneof`
///         field is stored.
///     *   Otherwise, the value is the index of the has-bit used to store the presence of the
///         field.
/// *   Bytes 10-11: For message/group fields, an opaque index as a base-128 integer used to
///     request the metatype of the submessage from the containing message's submessage accessor.
/// *   Byte 12: The type of the field.
@_spi(ForGeneratedCodeOnly) public struct _MessageLayout: @unchecked Sendable {
    // Using `UnsafeRawBufferPointer` requires that we declare the `Sendable` conformance as
    // `@unchecked`. Clearly this is safe because the pointer obtained from a `StaticString` is an
    // immortal compile-time constant and we only read from it.

    /// The encoded layout of the fields of the message.
    private let layout: UnsafeRawBufferPointer

    /// The function type for the generated function that is called to deinitialize a field
    /// of a complex type.
    public typealias SubmessageDeinitializer = (
        _ token: SubmessageToken,
        _ field: FieldLayout,
        _ storage: _MessageStorage
    ) -> Void

    /// The function type for the generated function that is called to copy a field of a
    /// complex type.
    public typealias SubmessageCopier = (
        _ token: SubmessageToken,
        _ field: FieldLayout,
        _ source: _MessageStorage,
        _ destination: _MessageStorage
    ) -> Void

    /// The function type for the generated function that is called to test the values of a complex
    /// field type from two different messages for equality.
    public typealias SubmessageEquater = (
        _ token: SubmessageToken,
        _ field: FieldLayout,
        _ lhs: _MessageStorage,
        _ rhs: _MessageStorage
    ) -> Bool

    /// The function type for the generated function that is called to test if a field whose type
    /// is a submessage is initialized.
    public typealias SubmessageInitializedChecker = (
        _ token: SubmessageToken,
        _ field: FieldLayout,
        _ storage: _MessageStorage
    ) -> Bool

    /// The function type for the generated function that is called to perform an arbitrary
    /// operation on the storage of a submessage field.
    public typealias SubmessageStoragePerformer = (
        _ token: SwiftProtobuf._MessageLayout.SubmessageToken,
        _ field: FieldLayout,
        _ storage: SwiftProtobuf._MessageStorage,
        _ perform: (SwiftProtobuf._MessageStorage) throws -> Bool
    ) throws -> Bool

    /// The function that is called to deinitialize a field whose type is a message.
    let deinitializeSubmessage: SubmessageDeinitializer

    /// The function that is called to copy a field whose type is a submessage.
    let copySubmessage: SubmessageCopier

    /// The function that is called to test a field whose type is a submessage for equality.
    let areSubmessagesEqual: SubmessageEquater

    /// The function that is called to perform an arbitrary operation on the storage of a submessage
    /// field.
    let performOnSubmessageStorage: SubmessageStoragePerformer

    /// Creates a new message layout and submessage operations from the given values.
    ///
    /// This initializer is public because generated messages need to call it.
    public init(
        layout: StaticString,
        deinitializeSubmessage: @escaping SubmessageDeinitializer,
        copySubmessage: @escaping SubmessageCopier,
        areSubmessagesEqual: @escaping SubmessageEquater,
        performOnSubmessageStorage: @escaping SubmessageStoragePerformer
    ) {
        precondition(
            layout.hasPointerRepresentation,
            "The layout string should have a pointer-based representation; this is a generator bug"
        )
        self.layout = UnsafeRawBufferPointer(start: layout.utf8Start, count: layout.utf8CodeUnitCount)
        self.deinitializeSubmessage = deinitializeSubmessage
        self.copySubmessage = copySubmessage
        self.areSubmessagesEqual = areSubmessagesEqual
        self.performOnSubmessageStorage = performOnSubmessageStorage
        precondition(version == 0, "This runtime only supports version 0 message layouts")
        precondition(
            self.layout.count == messageLayoutHeaderSize + self.fieldCount * fieldLayoutSize,
            """
            The layout size in bytes was not consistent with the number of fields \
            (got \(self.layout.count), expected \(messageLayoutHeaderSize + self.fieldCount * fieldLayoutSize)); \
            this is a generator bug
            """
        )
    }

    /// Creates a new message layout from the given layout string.
    ///
    /// Layouts created with this initalizer must have no submessage fields because the invalid
    /// submessage operation placeholder will be used.
    ///
    /// This initializer is public because generated messages need to call it.
    public init(layout: StaticString) {
        self.init(
            layout: layout,
            deinitializeSubmessage: { _, _, _ in
                preconditionFailure("This should have been unreachable; this is a generator bug")
            },
            copySubmessage: { _, _, _, _ in
                preconditionFailure("This should have been unreachable; this is a generator bug")
            },
            areSubmessagesEqual: { _, _, _, _ in
                preconditionFailure("This should have been unreachable; this is a generator bug")
            },
            performOnSubmessageStorage: { _, _, _, _ in
                preconditionFailure("This should have been unreachable; this is a generator bug")
            }
        )
    }
}

extension _MessageLayout {
    /// The version of the layout data.
    ///
    /// Currently, the runtime only supports version 0. If the layout needs to change in a breaking
    /// way, the generator should increment the version and the runtime implementation should detect
    /// the new version while maintaining the ability to read the older layouts.
    private var version: UInt8 {
        layout.load(fromByteOffset: 0, as: UInt8.self)
    }

    /// The size of the message in bytes.
    var size: Int {
        fixed3ByteBase128(in: layout, atByteOffset: 1)
    }

    /// The number of non-extension fields defined by the message.
    var fieldCount: Int {
        fixed3ByteBase128(in: layout, atByteOffset: 4)
    }

    /// The number of required fields defined by the message.
    ///
    /// Required fields have their has-bits arranged first in storage so that the runtime can
    /// efficiently compute whether the message is definitely not initialized.
    var requiredCount: Int {
        fixed3ByteBase128(in: layout, atByteOffset: 7)
    }

    /// The largest field number `N` for which all fields in the range `1..<N` are inhabited.
    ///
    /// Looking up the field layout for a field below `N` can be done via constant-time random
    /// access; fields numbered `N` or higher must be found via binary search.
    var denseBelow: UInt32 {
        UInt32(fixed3ByteBase128(in: layout, atByteOffset: 10))
    }
}

/// The size, in bytes, of the header the describes the overall message layout.
private var messageLayoutHeaderSize: Int { 13 }

/// The size, in bytes, of an encoded field layout in the static string representation.
private var fieldLayoutSize: Int { 13 }

extension _MessageLayout {
    /// Iterates over the field layouts in the layout string.
    struct FieldIterator: IteratorProtocol {
        var current: Slice<UnsafeRawBufferPointer>

        init(layout: UnsafeRawBufferPointer) {
            self.current = layout.dropFirst(messageLayoutHeaderSize)
        }

        mutating func next() -> FieldLayout? {
            guard !current.isEmpty else { return nil }
            defer { current = current.dropFirst(fieldLayoutSize) }
            return FieldLayout(slice: current.prefix(fieldLayoutSize))
        }
    }

    /// Returns a sequence that represents the layout descriptions of the fields in the message,
    /// in field number order.
    var fields: some Sequence<FieldLayout> { IteratorSequence(FieldIterator(layout: self.layout)) }

    /// Returns the layout for the field with the given number in the message.
    ///
    /// - Precondition: The field must be defined.
    @usableFromInline subscript(fieldNumber number: UInt32) -> FieldLayout {
        if number < denseBelow {
            let index = messageLayoutHeaderSize + (Int(number) - 1) * fieldLayoutSize
            return FieldLayout(slice: layout[index..<(index + fieldLayoutSize)])
        }

        var low = Int(denseBelow)
        var high = fieldCount - 1
        while high >= low {
            let mid = (high + low) / 2
            let index = messageLayoutHeaderSize + mid * fieldLayoutSize
            let field = FieldLayout(slice: layout[index..<(index + fieldLayoutSize)])
            if number == field.fieldNumber {
                return field
            }
            if field.fieldNumber < number {
                low = mid + 1
            } else {
                high = mid - 1
            }
        }
        preconditionFailure("No field number \(number)")
    }
}

extension _MessageLayout {
    /// An opaque token that is used to ask a message for the metatype of one of its submessage
    /// fields.
    public struct SubmessageToken: Sendable, Equatable {
        /// The index that identifies the submessage type being requested.
        public let index: Int
    }
}

/// Provides access to the properties of a field's layout based on a slice of the raw message
/// layout string.
@_spi(ForGeneratedCodeOnly) public struct FieldLayout {
    /// Describes the presence information of a field, translated from its raw bytecode
    /// representation.
    enum Presence: Sendable, Equatable {
        /// The byte offset and mask of the has-bit for this field that is not a oneof member.
        case hasBit(byteOffset: Int, mask: UInt8)

        /// The byte offset of the 32-bit integer that holds the field number of the currently set
        /// oneof member.
        case oneOfMember(Int)

        fileprivate init(rawValue: Int) {
            // The raw value needs to be treated as a 14-bit signed integer where the MSB (bit 13)
            // acts as the sign bit. Therefore, we need to check the range of the value to
            // determine if it's a oneof (0x2000...0x3fff) or not (0x0000...0x1fff), then
            // sign-extend it to 16 bits so that we can correctly take its inverse.
            if rawValue >= 0x2000 {
                self = .oneOfMember(Int(~(UInt16(rawValue) | 0xc000)))
            } else {
                self = .hasBit(byteOffset: rawValue >> 3, mask: 1 << UInt8(rawValue & 7))
            }
        }
    }

    /// The rebased slice of `_MessageLayout.fields` that describes the layout of this field.
    private let buffer: UnsafeRawBufferPointer

    /// The number of the field whose layout is being described.
    var fieldNumber: UInt32 {
        // The layout ensures that there will always be at least 8 bytes that we can read here, so
        // we can do a single memory read and mask off what we don't need.
        let rawBits = UInt64(littleEndian: buffer.loadUnaligned(fromByteOffset: 0, as: UInt64.self))
        return UInt32(
            truncatingIfNeeded: (rawBits & 0x00_0000_007f)
                | ((rawBits & 0x00_0000_7f00) >> 1)
                | ((rawBits & 0x00_007f_0000) >> 2)
                | ((rawBits & 0x00_7f00_0000) >> 3)
                | ((rawBits & 0x01_0000_0000) >> 4)
        )
    }

    /// The offset, in bytes, where this field's value is stored in in-memory storage.
    @usableFromInline var offset: Int {
        fixed3ByteBase128(in: buffer, atByteOffset: 5)
    }

    /// The offset, in bytes, where this field's presence is stored in in-memory storage.
    ///
    /// For one-of fields, this is the _byte_ offset in storage where the one-of index is stored.
    /// For scalar fields, this is the index of the has-bit for this field.
    var presence: Presence {
        Presence(rawValue: fixed2ByteBase128(in: buffer, atByteOffset: 8))
    }

    /// The index that is used when requesting the metatype of this field from its containing
    /// message.
    var submessageIndex: Int {
        fixed2ByteBase128(in: buffer, atByteOffset: 10)
    }

    /// The raw type of the field as it is represented on the wire.
    var rawFieldType: RawFieldType {
        RawFieldType(rawValue: buffer.load(fromByteOffset: 12, as: UInt8.self))
    }

    /// Mode properties of the field.
    var fieldMode: FieldMode {
        FieldMode(rawValue: buffer.load(fromByteOffset: 4, as: UInt8.self) & 0x1e)
    }

    /// The in-memory stride of a value of this field's type on the current platform.
    @usableFromInline var scalarStride: Int {
        switch rawFieldType {
        case .double: return MemoryLayout<Double>.stride
        case .float: return MemoryLayout<Float>.stride
        case .int64, .sfixed64, .sint64: return MemoryLayout<Int64>.stride
        case .uint64, .fixed64: return MemoryLayout<UInt64>.stride
        case .int32, .sfixed32, .sint32, .enum: return MemoryLayout<Int32>.stride
        case .fixed32, .uint32: return MemoryLayout<UInt32>.stride
        case .bool: return MemoryLayout<Bool>.stride
        case .string: return MemoryLayout<String>.stride
        case .group, .message: return MemoryLayout<_MessageStorage>.stride
        case .bytes: return MemoryLayout<Data>.stride
        default: preconditionFailure("Unreachable")
        }
    }

    /// Creates a new field layout from the given slice of a message's field layout string.
    fileprivate init(slice: Slice<UnsafeRawBufferPointer>) {
        self.buffer = UnsafeRawBufferPointer(rebasing: slice)
    }
}

/// The type of a field as it is represented on the wire.
package struct RawFieldType: RawRepresentable, Equatable, Hashable, Sendable {
    package static let double = Self(rawValue: 1)
    package static let float = Self(rawValue: 2)
    package static let int64 = Self(rawValue: 3)
    package static let uint64 = Self(rawValue: 4)
    package static let int32 = Self(rawValue: 5)
    package static let fixed64 = Self(rawValue: 6)
    package static let fixed32 = Self(rawValue: 7)
    package static let bool = Self(rawValue: 8)
    package static let string = Self(rawValue: 9)
    package static let group = Self(rawValue: 10)
    package static let message = Self(rawValue: 11)
    package static let bytes = Self(rawValue: 12)
    package static let uint32 = Self(rawValue: 13)
    package static let `enum` = Self(rawValue: 14)
    package static let sfixed32 = Self(rawValue: 15)
    package static let sfixed64 = Self(rawValue: 16)
    package static let sint32 = Self(rawValue: 17)
    package static let sint64 = Self(rawValue: 18)

    package let rawValue: UInt8

    package init(rawValue: UInt8) {
        self.rawValue = rawValue
    }
}

/// Note that the least-significant bit of this value is not used because this value is packed
/// into the high byte of the field number, which uses that bit.
package struct FieldMode: RawRepresentable, Equatable, Hashable, Sendable {
    /// Describes the cardinality of a field (whether it represents a scalar value, an array of
    /// values, or a mapping between values).
    package struct Cardinality: RawRepresentable, Equatable, Hashable, Sendable {
        package static let scalar = Self(rawValue: 0b000_0000)
        package static let array = Self(rawValue: 0b000_0010)
        package static let map = Self(rawValue: 0b000_0100)

        package let rawValue: UInt8

        package init(rawValue: UInt8) {
            self.rawValue = rawValue
        }
    }

    /// The cardinality of a field.
    package var cardinality: Cardinality {
        get { .init(rawValue: rawValue & 0b000_0110) }
        set { self = .init(rawValue: rawValue & ~0b000_0110 | newValue.rawValue) }
    }

    /// Indicates whether or not the field uses packed representation on the wire by default.
    package var isPacked: Bool {
        get { rawValue & 0b000_1000 != 0 }
        set { self = .init(rawValue: rawValue & ~0b000_1000 | (newValue ? 0b000_1000 : 0)) }
    }

    /// Indicates whether or not the field is an extension field.
    package var isExtension: Bool {
        get { rawValue & 0b001_0000 != 0 }
        set { self = .init(rawValue: rawValue & ~0b001_0000 | (newValue ? 0b001_0000 : 0)) }
    }

    package let rawValue: UInt8

    package init(rawValue: UInt8) {
        self.rawValue = rawValue
    }
}

/// Returns the up-to-14-bit unsigned integer that has been base-128 encoded at the given byte
/// offset in the buffer.
@_alwaysEmitIntoClient @inline(__always)
private func fixed2ByteBase128(in buffer: UnsafeRawBufferPointer, atByteOffset byteOffset: Int) -> Int {
    let rawBits = UInt16(littleEndian: buffer.loadUnaligned(fromByteOffset: byteOffset, as: UInt16.self))
    return Int((rawBits & 0x007f) | ((rawBits & 0x7f00) >> 1))
}

/// Returns the up-to-21-bit unsigned integer that has been base-128 encoded at the given byte
/// offset in the buffer.
@_alwaysEmitIntoClient @inline(__always)
private func fixed3ByteBase128(in buffer: UnsafeRawBufferPointer, atByteOffset byteOffset: Int) -> Int {
    let rawBits = UInt32(littleEndian: buffer.loadUnaligned(fromByteOffset: byteOffset, as: UInt32.self))
    return Int((rawBits & 0x00007f) | ((rawBits & 0x007f00) >> 1) | ((rawBits & 0x7f0000) >> 2))
}
