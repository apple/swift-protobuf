// Sources/SwiftProtobuf/MessageSchema.swift - Table-driven message schema
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

/// Describes the layout of a message with enough detail that the runtime library can serialize and
/// parse the message in all the required formats and manage its internal storage.
public struct MessageSchema: @unchecked Sendable {
    // Using `UnsafeRawBufferPointer` requires that we declare the `Sendable` conformance as
    // `@unchecked`. Clearly this is safe because the pointer obtained from a `StaticString` is an
    // immortal compile-time constant and we only read from it, and because the trampoline functions
    // do not capture mutable state.

    /// The encoded schema of the fields of the message.
    ///
    /// The message schema is encoded in UTF-8-compatible form as a `StaticString`. It is
    /// represented by a fixed size "header" followed by a sequence of fixed size field schema
    /// descriptors. This allows for fast lookup of those fields (constant time in some cases,
    /// falling back to binary search when needed).
    ///
    /// ## General integer encoding
    ///
    /// Since the string must be valid UTF-8, it is simplest to restrict all bytes in the string to
    /// 7-bit ASCII (0x00...0x7F). Therefore, we encode larger integers in a fixed base-128 format;
    /// no continuation bit is used (the MSB is always 0) and the schema specification determines
    /// the expected width of any encoded integers. For example, if we were encoding 16-bit
    /// integers, we would need 3 bytes, because 65536 would be encoded as
    /// 00000011 01111111 01111111.
    ///
    /// ## Message schema header
    ///
    /// The **message schema header** describes properties of the entire message:
    ///
    /// ```
    /// +---------+--------------+-------------+----------------+-------------------------+-------------------+
    /// | Bytes 0 | Bytes 1-3    | Bytes 4-6   | Bytes 7-9      | Bytes 10-12             | Byte 13-15        |
    /// | Version | Message size | Field count | Required count | Explicit presence count | Density threshold |
    /// +---------+--------------+-------------+----------------+-------------------------+-------------------+
    /// ```
    /// *   Byte 0: A `UInt8` that describes the version of the schema. Currently, this is always 0.
    ///     This value allows for future enhancements to be made to the schema but preserving
    ///     backward compatibility.
    /// *   Bytes 1-3: The size of the message in bytes, as a base-128 integer. 64KB is an upper
    ///     bound on message size imposed in practice by µpb, since it uses a `uint16_t` to
    ///     represent field offsets in their own mini-tables.
    /// *   Bytes 4-6: The number of fields defined by the message, as a base-128 integer.
    ///     65536 is an upper bound imposed in practice by the core protobuf implementation
    ///     (https://github.com/protocolbuffers/protobuf/commit/90824aaa69000452bff5ad8db3240215a3b9a595)
    ///     since larger messages would overflow various data structures.
    /// *   Bytes 7-9: The number of required fields defined by the message, as a base-128 integer.
    /// *   Bytes 10-12: The number of fields that have explicit presence, as a base-128 integer.
    ///     Note that this will always be greater than or equal to the required count, because
    ///     required fields also have explicit presence.
    /// *   Bytes 13-15: The largest field number `N` for which all fields in the range `1..<N` are
    ///     inhabited, as a base-128 integer. We only need three bytes to represent this because the
    ///     largest possible number is 65537; otherwise, it would imply that the message had more
    ///     than 65536 fields in violation of the bound above.
    ///
    /// ## Field schemas
    ///
    /// After the header above, starting at byte offset 16, is a sequence of encoded field schemas.
    /// Each field schema is 13 bytes long and they are written in field number order. Each entry
    /// encodes the following information:
    ///
    /// ```
    /// +---------------------+-----------+-----------+------------------+------------+
    /// | Bytes 0-4           | Bytes 5-7 | Bytes 8-9 | Bytes 10-11      | Byte 12    |
    /// | Field number & mode | Offset    | Presence  | Trampoline index | Field type |
    /// +---------------------+-----------+-----------+------------------+------------+
    /// ```
    ///
    /// *   Bytes 0-4: A packed value where the low 33-bits are a base-128 integer that encodes the
    ///     29-bit field number, and the remaining bits of byte 4 represent the field mode.
    /// *   Bytes 5-7: The byte offset of the field in in-memory storage, as a base-128 integer. To
    ///     match µpb's layout constraints, this value will never be larger than 2^16 - 1.
    /// *   Bytes 8-9: Information about the field's presence. Specifically,
    ///     *   If this field is a member of a `oneof`, then the bitwise inverse of this value is
    ///         the byte offset into in-memory storage where the field number of the populated
    ///         `oneof` field is stored.
    ///     *   Otherwise, the value is the index of the has-bit used to store the presence of the
    ///         field.
    /// *   Bytes 10-11: For message/group/enum fields, an opaque index as a base-128 integer used
    ///     to perform operations on submessage or enum fields that require the concrete type hint.
    /// *   Byte 12: The type of the field.
    ///
    /// ## Message name
    ///
    /// After the sequence of field schemas, the schema string contains the fully-qualified name of
    /// the message:
    ///
    /// ```
    /// +-------------+--------------+
    /// |  Bytes 0-1  |  Bytes 2...  |
    /// | Name length | Message name |
    /// +-------------+--------------+
    /// ```
    ///
    /// *   Bytes 0-1: The length of the message's fully-qualified name, as a 2-byte base-128 integer.
    /// *   Bytes 2...: The fully-qualified name of the message, as UTF-8 encoded bytes.
    private let schema: UnsafeRawBufferPointer

    /// The reference to the reflection table for the message.
    private let reflection: ReflectionTableReference

    /// The function type for the generated function that is called to perform a basic operation
    /// on certain kinds of nontrivial fields (a message, array of messages, array of enums, or map)
    /// such as deinitialization, copying, or testing for equality.
    @_spi(ForGeneratedCodeOnly)
    public typealias NontrivialFieldOperationPerformer = (
        _ token: TrampolineToken,
        _ operation: NontrivialFieldOperation,
        _ field: FieldSchema,
        _ storage: MessageStorage
    ) -> Bool

    /// The function type for the generated function that is called to perform an arbitrary
    /// operation on the storage of a field whose type is a message or array of messages.
    @_spi(ForGeneratedCodeOnly)
    public typealias SubmessageStoragePerformer = (
        _ token: TrampolineToken,
        _ field: FieldSchema,
        _ storage: MessageStorage,
        _ operation: TrampolineFieldOperation,
        _ perform: (MessageStorage) throws -> Bool
    ) throws -> Bool

    /// The function type for the generated function that is called to perform an arbitrary
    /// operation on the raw values of a singular or repeated enum field.
    @_spi(ForGeneratedCodeOnly)
    public typealias RawEnumValuesPerformer = (
        _ token: TrampolineToken,
        _ field: FieldSchema,
        _ storage: MessageStorage,
        _ operation: TrampolineFieldOperation,
        _ perform: (EnumSchema, inout Int32) throws -> Bool,
        _ onInvalidValue: (Int32) throws -> Void
    ) throws -> Void

    /// The function type for the generated function that is called to retrieve the "message" schema
    /// of a map entry.
    @_spi(ForGeneratedCodeOnly)
    public typealias MapEntrySchema = (_ token: TrampolineToken) -> MessageSchema

    /// The function type for the generated function that is called to perform an arbitrary
    /// operation on the elements of a map.
    @_spi(ForGeneratedCodeOnly)
    public typealias MapEntryPerformer = (
        _ token: TrampolineToken,
        _ field: FieldSchema,
        _ storage: MessageStorage,
        _ workingSpace: MessageStorage,
        _ operation: TrampolineFieldOperation,
        _ deterministicOrdering: Bool,
        _ perform: (MessageStorage) throws -> Bool
    ) throws -> Bool

    /// The function that is called to deinitialize a field whose type is a message (singular or
    /// repeated) or a repeated enum field.
    let performNontrivialFieldOperation: NontrivialFieldOperationPerformer

    /// The function that is called to perform an arbitrary operation on the storage of a submessage
    /// field.
    let performOnSubmessageStorage: SubmessageStoragePerformer

    /// The function that is called to perform an arbitrary operation on the raw values of an enum
    /// field.
    let performOnRawEnumValues: RawEnumValuesPerformer

    /// The function that is called to retrieve the "message" schema of a map entry.
    let mapEntrySchema: MapEntrySchema

    /// The function that is called to perform an arbitrary operation on the elements of a map.
    let performOnMapEntry: MapEntryPerformer

    /// A key that can be used to uniquely identify a message schema in a hashed collection.
    var key: Key {
        // TODO: As currently written, it's possible that the linker could fold strings representing
        // messages with identical layout. We can avoid this in the future when we merge the name
        // map and fully qualified message name into the schema string, ensuring that they'll be
        // unique.
        Key(value: schema.baseAddress!)
    }

    /// Creates a new message schema and submessage operations from the given values.
    @_spi(ForGeneratedCodeOnly)
    public init(
        schema: StaticString,
        reflection: StaticString,
        performNontrivialFieldOperation: @escaping NontrivialFieldOperationPerformer,
        performOnSubmessageStorage: @escaping SubmessageStoragePerformer,
        performOnRawEnumValues: @escaping RawEnumValuesPerformer,
        mapEntrySchema: @escaping MapEntrySchema,
        performOnMapEntry: @escaping MapEntryPerformer
    ) {
        self.init(
            schema: schema,
            // TODO: Use the `.compressed` form and lazily decompress and cache it.
            reflectionReference: .direct(ReflectionTable(
                fieldCount: Self.fieldCount(from: schema.rawBufferPointer),
                data: Compression.decompress(reflection.rawBufferPointer)
            )),
            performNontrivialFieldOperation: performNontrivialFieldOperation,
            performOnSubmessageStorage: performOnSubmessageStorage,
            performOnRawEnumValues: performOnRawEnumValues,
            mapEntrySchema: mapEntrySchema,
            performOnMapEntry: performOnMapEntry
        )
    }

    /// Creates a new message schema from the given schema string.
    ///
    /// Schemas created with this initalizer must have no submessage fields because the invalid
    /// submessage operation placeholder will be used.
    @_spi(ForGeneratedCodeOnly)
    public init(schema: StaticString, reflection: StaticString) {
        self.init(
            schema: schema,
            // TODO: Use the `.compressed` form and lazily decompress and cache it.
            reflectionReference: .direct(ReflectionTable(
                fieldCount: Self.fieldCount(from: schema.rawBufferPointer),
                data: Compression.decompress(reflection.rawBufferPointer)
            )),
            performNontrivialFieldOperation: { _, _, _, _ in
                preconditionFailure("This should have been unreachable; this is a generator bug")
            },
            performOnSubmessageStorage: { _, _, _, _, _ in
                preconditionFailure("This should have been unreachable; this is a generator bug")
            },
            performOnRawEnumValues: { _, _, _, _, _, _ in
                preconditionFailure("This should have been unreachable; this is a generator bug")
            },
            mapEntrySchema: { _ in
                preconditionFailure("This should have been unreachable; this is a generator bug")
            },
            performOnMapEntry: { _, _, _, _, _, _, _ in
                preconditionFailure("This should have been unreachable; this is a generator bug")
            }
        )
    }

    /// Creates a new message schema for the message-like storage used to encode and decode map
    /// entries where the value type is a scalar.
    @_spi(ForGeneratedCodeOnly)
    public init(schemaForMapEntryWithScalarValues schema: StaticString) {
        self.init(
            schema: schema,
            reflectionReference: .direct(.mapEntry),
            performNontrivialFieldOperation: { _, _, _, _ in
                preconditionFailure("This should have been unreachable; this is a generator bug")
            },
            performOnSubmessageStorage: { _, _, _, _, _ in
                preconditionFailure("This should have been unreachable; this is a generator bug")
            },
            performOnRawEnumValues: { _, _, _, _, _, _ in
                preconditionFailure("This should have been unreachable; this is a generator bug")
            },
            mapEntrySchema: { _ in
                preconditionFailure("This should have been unreachable; this is a generator bug")
            },
            performOnMapEntry: { _, _, _, _, _, _, _ in
                preconditionFailure("This should have been unreachable; this is a generator bug")
            }
        )
    }

    /// Creates a new message schema for the message-like storage used to encode and decode map
    /// entries where the value type is another message.
    @_spi(ForGeneratedCodeOnly)
    public init<T: Message>(schema: StaticString, forMapEntryWithValueType type: T.Type) {
        self.init(
            schema: schema,
            reflectionReference: .direct(.mapEntry),
            performNontrivialFieldOperation: { _, operation, field, storage in
                return storage.performNontrivialFieldOperation(operation, field: field, type: type)
            },
            performOnSubmessageStorage: { _, field, storage, operation, perform in
                try storage.performOnSubmessageStorage(of: field, operation: operation, type: type, perform: perform)
            },
            performOnRawEnumValues: { _, _, _, _, _, _ in
                preconditionFailure("This should have been unreachable; this is a generator bug")
            },
            mapEntrySchema: { _ in
                preconditionFailure("This should have been unreachable; this is a generator bug")
            },
            performOnMapEntry: { _, _, _, _, _, _, _ in
                preconditionFailure("This should have been unreachable; this is a generator bug")
            }
        )
    }

    /// Creates a new message schema for the message-like storage used to encode and decode map
    /// entries where the value type is an enum.
    @_spi(ForGeneratedCodeOnly)
    public init<T: Enum>(schema: StaticString, forMapEntryWithValueType type: T.Type, enumSchema: EnumSchema) {
        self.init(
            schema: schema,
            reflectionReference: .direct(.mapEntry),
            performNontrivialFieldOperation: { _, operation, field, storage in
                return storage.performNontrivialFieldOperation(operation, field: field, type: type)
            },
            performOnSubmessageStorage: { _, field, storage, operation, perform in
                preconditionFailure("This should have been unreachable; this is a generator bug")
            },
            performOnRawEnumValues: { _, field, storage, operation, perform, onInvalidValue in
                try storage.performOnRawEnumValues(
                    of: field,
                    operation: operation,
                    type: type,
                    enumSchema: enumSchema,
                    perform: perform,
                    onInvalidValue: onInvalidValue
                )
            },
            mapEntrySchema: { _ in
                preconditionFailure("This should have been unreachable; this is a generator bug")
            },
            performOnMapEntry: { _, _, _, _, _, _, _ in
                preconditionFailure("This should have been unreachable; this is a generator bug")
            }
        )
    }

    /// Creates a new message schema and submessage operations from the given values.
    private init(
        schema: StaticString,
        reflectionReference: ReflectionTableReference,
        performNontrivialFieldOperation: @escaping NontrivialFieldOperationPerformer,
        performOnSubmessageStorage: @escaping SubmessageStoragePerformer,
        performOnRawEnumValues: @escaping RawEnumValuesPerformer,
        mapEntrySchema: @escaping MapEntrySchema,
        performOnMapEntry: @escaping MapEntryPerformer
    ) {
        precondition(
            schema.hasPointerRepresentation,
            "The schema string should have a pointer-based representation; this is a generator bug"
        )
        self.schema = schema.rawBufferPointer
        self.reflection = reflectionReference
        self.performNontrivialFieldOperation = performNontrivialFieldOperation
        self.performOnSubmessageStorage = performOnSubmessageStorage
        self.performOnRawEnumValues = performOnRawEnumValues
        self.mapEntrySchema = mapEntrySchema
        self.performOnMapEntry = performOnMapEntry
        precondition(version == 0, "This runtime only supports version 0 message schemas")
        precondition(
            self.schema.count >= messageSchemaHeaderSize + self.fieldCount * fieldSchemaSize,
            """
            The schema size in bytes was not consistent with the number of fields \
            (got \(self.schema.count), expected at least \
            \(messageSchemaHeaderSize + self.fieldCount * fieldSchemaSize)); \
            this is a generator bug
            """
        )
    }

}

extension MessageSchema {
    /// A key that can be used to uniquely identify the message schema in hashed containers.
    struct Key: Hashable, Equatable, @unchecked Sendable {
        /// The pointer to the static string data that defines the message schema.
        ///
        /// Since this is constant read-only data, it's suitable for use as a key for in-process
        /// hashed container lookups.
        private let value: UnsafeRawPointer

        init(value: UnsafeRawPointer) {
            self.value = value
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(value)
        }

        static func == (lhs: Key, rhs: Key) -> Bool {
            return lhs.value == rhs.value
        }
    }
}

extension MessageSchema {
    /// Helper function to read the field count from the given schema string.
    private static func fieldCount(from schema: UnsafeRawBufferPointer) -> Int {
        fixed3ByteBase128(in: schema, atByteOffset: 4)
    }

    /// The version of the schema data.
    ///
    /// Currently, the runtime only supports version 0. If the schema needs to change in a breaking
    /// way, the generator should increment the version and the runtime implementation should detect
    /// the new version while maintaining the ability to read the older schemas.
    private var version: UInt8 {
        schema.load(fromByteOffset: 0, as: UInt8.self)
    }

    /// The storage size of the message in bytes.
    var storageSize: Int {
        fixed3ByteBase128(in: schema, atByteOffset: 1) & ~(1 << 20)
    }

    /// Returns true if the message is a map entry pseudo-message.
    var isMapEntry: Bool {
        (schema.load(fromByteOffset: 3, as: UInt8.self) & 0x40) != 0
    }

    /// The number of non-extension fields defined by the message.
    var fieldCount: Int {
        Self.fieldCount(from: schema)
    }

    /// The number of required fields defined by the message.
    ///
    /// Required fields have their has-bits arranged first in storage so that the runtime can
    /// efficiently compute whether the message is definitely not initialized.
    var requiredCount: Int {
        fixed3ByteBase128(in: schema, atByteOffset: 7)
    }

    /// The number of fields defined by the message that have explicit presence.
    ///
    /// Fields with explicit presence have their has-bits arranged after the required has-bits but
    /// before those with implicit presence so that we can determine the nature of a field's
    /// presence without increasing the size of field schemas.
    var explicitPresenceCount: Int {
        fixed3ByteBase128(in: schema, atByteOffset: 10)
    }

    /// The largest field number `N` for which all fields in the range `1..<N` are inhabited.
    ///
    /// Looking up the field schema for a field below `N` can be done via constant-time random
    /// access; fields numbered `N` or higher must be found via binary search.
    var denseBelow: UInt32 {
        UInt32(fixed3ByteBase128(in: schema, atByteOffset: 13))
    }

    /// The fully-qualified name of the message.
    var messageName: String {
        let lengthOffset = messageSchemaHeaderSize + fieldCount * fieldSchemaSize
        let length = fixed2ByteBase128(in: schema, atByteOffset: lengthOffset)
        let nameStart = lengthOffset + 2
        return String(decoding: schema[nameStart..<(nameStart + length)], as: UTF8.self)
    }

    /// Returns a value indicating whether or not the given field is required.
    func isFieldRequired(_ field: FieldSchema) -> Bool {
        let raw = field.rawPresence
        return 0 <= raw && raw < requiredCount
    }

    /// Returns a value indicating whether ot not the given field has explicit presence.
    func fieldHasPresence(_ field: FieldSchema) -> Bool {
        let raw = field.rawPresence
        return 0 <= raw && raw < explicitPresenceCount
    }
}

extension MessageSchema {
    /// Returns the text name for the given field number.
    func textName(forFieldNumber number: UInt32) -> String? {
        reflection.table.textName(forFieldNumber: number)
    }

    /// Returns the JSON name for the given field number.
    func jsonName(forFieldNumber number: UInt32) -> String? {
        reflection.table.jsonName(forFieldNumber: number)
    }

    /// Returns the field number for the given text name.
    func fieldNumber(forTextName name: String) -> UInt32? {
        // Fast path: Binary search in the reflection table.
        if let number = reflection.table.fieldNumber(forTextName: name) {
            return number
        }
        // Slow path: If it wasn't found, check if it's a group name spelled in
        // lowercase form.
        let lowercaseName = name.lowercased()
        for field in fields where field.rawFieldType == .group {
            if let textName = reflection.table.textName(forFieldNumber: field.fieldNumber),
                textName.lowercased() == lowercaseName
            {
                return field.fieldNumber
            }
        }
        return nil
    }

    /// Returns the field number for the given JSON name.
    func fieldNumber(forJSONName name: String) -> UInt32? {
        reflection.table.fieldNumber(forJSONName: name)
    }

    /// Returns a value indicating whether or not the given field name is reserved.
    func isFieldNameReserved(_ name: String) -> Bool {
        reflection.table.isNameReserved(name)
    }

    /// Returns a value indicating whether or not the given field number is reserved.
    func isFieldNumberReserved(_ number: UInt32) -> Bool {
        reflection.table.isNumberReserved(number)
    }
}

/// The size, in bytes, of the header the describes the overall message schema.
private var messageSchemaHeaderSize: Int { 16 }

/// The size, in bytes, of an encoded field schema in the static string representation.
var fieldSchemaSize: Int { 13 }

extension MessageSchema {
    /// Iterates over the field schemas in the schema string.
    struct FieldIterator: IteratorProtocol {
        var current: Slice<UnsafeRawBufferPointer>

        init(fields: Slice<UnsafeRawBufferPointer>) {
            self.current = fields
        }

        mutating func next() -> FieldSchema? {
            guard !current.isEmpty else { return nil }
            defer { current = current.dropFirst(fieldSchemaSize) }
            return FieldSchema(slice: current.prefix(fieldSchemaSize))
        }
    }

    /// Returns a sequence that represents the schemas of the fields in the message, in field number
    /// order.
    var fields: some Sequence<FieldSchema> {
        // For ease of iteration, we strip off the message schema header at the beginning and the
        // message name at the end, leaving only the slice containing the fixed-size field schemas.
        let endOffset = messageSchemaHeaderSize + fieldCount * fieldSchemaSize
        return IteratorSequence(FieldIterator(fields: self.schema[messageSchemaHeaderSize..<endOffset]))
    }

    /// Returns the schema for the field with the given number in the message, or nil if the field
    /// is not defined.
    @usableFromInline subscript(fieldNumber number: UInt32) -> FieldSchema? {
        if number < denseBelow {
            let index = messageSchemaHeaderSize + (Int(number) - 1) * fieldSchemaSize
            return FieldSchema(slice: schema[index..<(index + fieldSchemaSize)])
        }

        var low = Int(denseBelow - 1)
        var high = fieldCount - 1
        while high >= low {
            let mid = (high + low) / 2
            let index = messageSchemaHeaderSize + mid * fieldSchemaSize
            let field = FieldSchema(slice: schema[index..<(index + fieldSchemaSize)])
            if number == field.fieldNumber {
                return field
            }
            if field.fieldNumber < number {
                low = mid + 1
            } else {
                high = mid - 1
            }
        }
        return nil
    }
}

extension MessageSchema {
    /// An opaque token that is used to ask a message for the metatype of one of its submessage
    /// or enum fields.
    @_spi(ForGeneratedCodeOnly)
    public struct TrampolineToken: Sendable, Equatable {
        /// The index that identifies the submessage or enum type being requested.
        public let index: Int
    }
}

/// The nature of the operation that is being performed by `performOnSubmessageStorage` or
/// `performOnEnumRawValues`.
@_spi(ForGeneratedCodeOnly)
public enum TrampolineFieldOperation {
    /// The submessage's storage or enum's raw value is being read.
    case read

    /// The submessage's storage or enum's raw value is being mutated.
    ///
    /// For submessages, the value should be created if it is not already present. If already
    /// present, the storage should be made unique before the mutation.
    case mutate

    /// The submessage's array storage or enum's array value is having a new value appended to it.
    ///
    /// The array should be created if it is not already present.
    case append

    /// The (singular/repeated) submessage or (repeated) enum field is parsed as `null` from JSON.
    ///
    /// JSON `null` values have special treatment; most of the time they clear the underlying
    /// storage, but for the `Value` well-known type, it's actually populated by a non-empty
    /// instance. Note that for this operation, the closure passed into the trampoline function is
    /// never called.`
    case jsonNull
}

/// Provides access to the properties of a field's schema based on a slice of the raw message
/// schema string.
public struct FieldSchema {
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

    /// The rebased slice of `MessageSchema.schema` that describes the schema of this field.
    private let buffer: UnsafeRawBufferPointer

    /// The number of the field whose schema is being described.
    @usableFromInline var fieldNumber: UInt32 {
        // The schema ensures that there will always be at least 8 bytes that we can read here, so
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

    /// The raw presence value.
    ///
    /// For `oneof` fields, this is the bitwise inverse of the _byte_ offset in storage where the
    /// populated `oneof` member's field number is stored. For non-`oneof` fields, this is the index
    /// of the has-bit for this field.
    var rawPresence: Int {
        fixed2ByteBase128(in: buffer, atByteOffset: 8)
    }

    /// The presence information for this field.
    ///
    /// This value is an enum that provides structured access to the information based on whether it
    /// is a `oneof` member or a regular field.
    var presence: Presence {
        Presence(rawValue: rawPresence)
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

    /// The wire format used by this field.
    var wireFormat: WireFormat {
        switch rawFieldType {
        case .bool: return .varint
        case .bytes: return .lengthDelimited
        case .double: return .fixed64
        case .enum: return .varint
        case .fixed32: return .fixed32
        case .fixed64: return .fixed64
        case .float: return .fixed32
        case .group: return .startGroup
        case .int32: return .varint
        case .int64: return .varint
        case .message: return .lengthDelimited
        case .sfixed32: return .fixed32
        case .sfixed64: return .fixed64
        case .sint32: return .varint
        case .sint64: return .varint
        case .string: return .lengthDelimited
        case .uint32: return .varint
        case .uint64: return .varint
        default: preconditionFailure("Unreachable")
        }
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
        case .group, .message: return MemoryLayout<MessageStorage>.stride
        case .bytes: return MemoryLayout<Data>.stride
        default: preconditionFailure("Unreachable")
        }
    }

    /// Creates a new field schema from the given slice of a message's field schema string.
    init(slice: Slice<UnsafeRawBufferPointer>) {
        self.buffer = UnsafeRawBufferPointer(rebasing: slice)
    }

    /// Creates a new field layout from the given string that describes exactly one field.
    ///
    /// This initializer is used by generated code to represent extension fields.
    public init(layout: StaticString) {
        self.buffer = UnsafeRawBufferPointer(start: layout.utf8Start, count: layout.utf8CodeUnitCount)
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
func fixed2ByteBase128(in buffer: UnsafeRawBufferPointer, atByteOffset byteOffset: Int) -> Int {
    let rawBits = UInt16(littleEndian: buffer.loadUnaligned(fromByteOffset: byteOffset, as: UInt16.self))
    return Int((rawBits & 0x007f) | ((rawBits & 0x7f00) >> 1))
}

/// Returns the up-to-21-bit unsigned integer that has been base-128 encoded at the given byte
/// offset in the buffer.
@_alwaysEmitIntoClient @inline(__always)
func fixed3ByteBase128(in buffer: UnsafeRawBufferPointer, atByteOffset byteOffset: Int) -> Int {
    let lowBits = UInt16(littleEndian: buffer.loadUnaligned(fromByteOffset: byteOffset, as: UInt16.self))
    let highBits = buffer.loadUnaligned(fromByteOffset: byteOffset + 2, as: UInt8.self)
    return Int((lowBits & 0x7f) | ((lowBits & 0x7f00) >> 1)) | (Int(highBits & 0x7f) << 14)
}
