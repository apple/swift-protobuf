// Sources/SwiftProtobuf/MessageStorage.swift - Table-driven message storage
//
// Copyright (c) 2014 - 2025 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Manages the in-memory storage of the fields of a message.
///
// -----------------------------------------------------------------------------

import Foundation

/// Manages the in-memory storage for a table-driven message.
///
/// The in-memory storage of a message is a region of raw memory whose layout is determined by the
/// `MessageSchema` that it is initialized with. While fields may be laid out at different offsets
/// in different messages, all layouts share some common properties:
///
/// *   The first subregion contains the has-bits for each field. Within this subregion, the
///     has-bits for required fields are ordered first.
/// *   Following the has-bits, there is a subregion for each size-group of fields: Boolean values,
///     32-bit values, 64-bit values, pointer-sized values, and larger complex Swift values.
///
/// Even though has-bits are not strictly required for the implementation of certain fields (e.g.,
/// repeated fields), we use them anyway because the extra space is negligible and it is more
/// efficient to test has-bits to determine if a field is set instead of loading and testing
/// complex values. Furthermore, this allows us to properly track whether a field's memory is
/// initialized or not (in the Swift sense of initialized memory w.r.t. unsafe pointers), ensuring
/// that complex values are retained/released appropriately at all times.
///
/// This type is public because it needs to be referenced and initialized from generated messages.
/// Clients should not access it or its members directly.
@_spi(ForGeneratedCodeOnly) public final class MessageStorage {
    /// The schema of this instance of storage.
    @usableFromInline let schema: MessageSchema

    /// The memory buffer that contain's the data for the message's fields.
    @usableFromInline let buffer: UnsafeMutableRawBufferPointer

    /// The storage used for unknown fields.
    public var unknownFields: UnknownStorage

    /// The storage used for extension field values.
    public var extensionStorage: ExtensionStorage

    /// Creates a new message storage instance for a message with the given layout.
    public init(schema: MessageSchema) {
        self.schema = schema
        self.buffer = UnsafeMutableRawBufferPointer.allocate(
            byteCount: schema.storageSize,
            alignment: MemoryLayout<Int>.alignment
        )
        self.buffer.withMemoryRebound(to: UInt8.self) { byteBuffer in
            byteBuffer.initialize(repeating: 0)
        }
        self.unknownFields = UnknownStorage()
        self.extensionStorage = ExtensionStorage()
    }

    deinit {
        for field in schema.fields {
            deinitializeField(field)
        }
        buffer.deallocate()
    }
}

// MARK: - Low-level pointer/memory utilities

extension MessageStorage {
    /// Returns a raw pointer to the given byte offset in the storage buffer.
    @_alwaysEmitIntoClient @inline(__always)
    func rawPointer(at offset: Int) -> UnsafeMutableRawPointer {
        buffer.baseAddress! + offset
    }

    /// Returns a typed pointer to the given byte offset in the storage buffer.
    @_alwaysEmitIntoClient @inline(__always)
    func typedPointer<T>(at offset: Int, as type: T.Type) -> UnsafeMutablePointer<T> {
        rawPointer(at: offset).bindMemory(to: T.self, capacity: 1)
    }

    /// Zeros out `count` bytes starting at the given pointer.
    @_alwaysEmitIntoClient @inline(__always)
    func zeroOut(pointer: UnsafeMutableRawPointer, count: Int) {
        pointer.withMemoryRebound(to: UInt8.self, capacity: count) { bytes in
            bytes.initialize(repeating: 0, count: count)
        }
    }

    /// Zeros out `count` bytes starting at the given offset in the storage buffer.
    @_alwaysEmitIntoClient @inline(__always)
    func zeroOut(at offset: Int, count: Int) {
        zeroOut(pointer: rawPointer(at: offset), count: count)
    }

    /// Returns a raw pointer to the memory backing the given field.
    @usableFromInline
    func rawPointer(for field: MessageSchema.Field) -> UnsafeMutableRawPointer {
        let offset = schema.byteOffset(of: field)
        return buffer.baseAddress! + offset
    }

    /// Returns a typed pointer to the memory backing the given field.
    @usableFromInline
    func typedPointer<T>(
        for field: MessageSchema.Field,
        as type: T.Type
    ) -> UnsafeMutablePointer<T> {
        rawPointer(for: field).bindMemory(to: T.self, capacity: 1)
    }
}

// MARK: - Whole-message operations

extension MessageStorage {
    /// Deinitializes the given field if it is present.
    @usableFromInline func deinitializeField(_ field: MessageSchema.Field) {
        guard isPresent(field) else { return }
        deinitializeFieldForced(field)
    }

    @usableFromInline func deinitializeFieldForced(_ field: MessageSchema.Field) {
        switch field.fieldMode.cardinality {
        case .map:
            messageSchema(for: field).invokeWitness(.mapDeinitialize(pointer: rawPointer(for: field)))

        case .array:
            switch field.rawFieldType {
            case .bool: deinitializeField(field, type: [Bool].self)
            case .bytes: deinitializeField(field, type: [Data].self)
            case .double: deinitializeField(field, type: [Double].self)
            case .enum:
                enumSchema(for: field).invokeWitness(.arrayDeinitialize(pointer: rawPointer(for: field)))
            case .group, .message:
                messageSchema(for: field).invokeWitness(.arrayDeinitialize(pointer: rawPointer(for: field)))
            case .fixed32, .uint32: deinitializeField(field, type: [UInt32].self)
            case .fixed64, .uint64: deinitializeField(field, type: [UInt64].self)
            case .float: deinitializeField(field, type: [Float].self)
            case .int32, .sfixed32, .sint32: deinitializeField(field, type: [Int32].self)
            case .int64, .sfixed64, .sint64: deinitializeField(field, type: [Int64].self)
            case .string: deinitializeField(field, type: [String].self)
            default: preconditionFailure("Unreachable")
            }

        case .scalar:
            switch field.rawFieldType {
            case .bytes: deinitializeField(field, type: Data.self)
            case .string: deinitializeField(field, type: String.self)
            case .group, .message:
                messageSchema(for: field).invokeWitness(
                    .messageDeinitialize(pointer: rawPointer(for: field))
                )
            default:
                // Ignore trivial fields; no deinitialization is necessary.
                break
            }

        default:
            preconditionFailure("Unreachable")
        }
    }

    /// Deinitializes the field associated with the given concrete type information.
    private func deinitializeField<T>(_ field: MessageSchema.Field, type: T.Type) {
        typedPointer(for: field, as: T.self).deinitialize(count: 1)
    }

    /// Returns a value indicating whether the field with the given presence has been explicitly
    /// set.
    ///
    /// For oneof fields, this checks the currently set field against the field number being
    /// queried. For other fields, it checks the appropriate has-bit.
    ///
    /// Generated accessors do not use this function. Since they can encode their presence
    /// information directly, they use more efficient code paths that do not require the full
    /// field layout.
    func isPresent(_ field: MessageSchema.Field) -> Bool {
        switch field.presence {
        case .oneOfMember(let oneofOffset):
            return populatedOneofMember(at: oneofOffset) == field.fieldNumber
        case .hasBit(let byteOffset, let mask):
            return isPresent(hasBit: (byteOffset, mask))
        }
    }

    /// Creates and returns an independent copy of the values in this storage.
    ///
    /// This is used to implement copy-on-write behavior.
    @inline(never)
    public func copy() -> MessageStorage {
        let destination = MessageStorage(schema: schema)

        // Loops through the fields, copy-initializing any that are non-trivial types. We ignore
        // the trivial ones here, instead tracking the byte offset of the first non-trivial field
        // so that we can bitwise copy those as a block afterward.
        var firstNontrivialStorageOffset = schema.storageSize
        for field in schema.fields {
            let offset = schema.byteOffset(of: field)
            switch field.fieldMode.cardinality {
            case .map:
                if offset < firstNontrivialStorageOffset {
                    firstNontrivialStorageOffset = offset
                }
                guard isPresent(field) else { continue }
                let source = rawPointer(for: field)
                let destination = destination.rawPointer(for: field)
                messageSchema(for: field).invokeWitness(.mapCopyInitialize(source: source, destination: destination))

            case .array:
                if offset < firstNontrivialStorageOffset {
                    firstNontrivialStorageOffset = offset
                }
                switch field.rawFieldType {
                case .bool: copyField(field, to: destination, type: [Bool].self)
                case .bytes: copyField(field, to: destination, type: [Data].self)
                case .double: copyField(field, to: destination, type: [Double].self)
                case .enum:
                    guard isPresent(field) else { continue }
                    let source = rawPointer(for: field)
                    let destination = destination.rawPointer(for: field)
                    enumSchema(for: field).invokeWitness(.arrayCopyInitialize(source: source, destination: destination))

                case .group, .message:
                    guard isPresent(field) else { continue }
                    let source = rawPointer(for: field)
                    let destination = destination.rawPointer(for: field)
                    messageSchema(for: field).invokeWitness(
                        .arrayCopyInitialize(source: source, destination: destination)
                    )

                case .fixed32, .uint32: copyField(field, to: destination, type: [UInt32].self)
                case .fixed64, .uint64: copyField(field, to: destination, type: [UInt64].self)
                case .float: copyField(field, to: destination, type: [Float].self)
                case .int32, .sfixed32, .sint32: copyField(field, to: destination, type: [Int32].self)
                case .int64, .sfixed64, .sint64: copyField(field, to: destination, type: [Int64].self)
                case .string: copyField(field, to: destination, type: [String].self)
                default: preconditionFailure("Unreachable")
                }

            case .scalar:
                switch field.rawFieldType {
                case .bytes:
                    if offset < firstNontrivialStorageOffset {
                        firstNontrivialStorageOffset = offset
                    }
                    copyField(field, to: destination, type: Data.self)

                case .group, .message:
                    if offset < firstNontrivialStorageOffset {
                        firstNontrivialStorageOffset = offset
                    }
                    guard isPresent(field) else { continue }
                    let source = rawPointer(for: field)
                    let destination = destination.rawPointer(for: field)
                    messageSchema(for: field).invokeWitness(
                        .messageCopyInitialize(source: source, destination: destination)
                    )

                case .string:
                    if offset < firstNontrivialStorageOffset {
                        firstNontrivialStorageOffset = offset
                    }
                    copyField(field, to: destination, type: String.self)

                default:
                    // Do nothing. Trivial fields will be bitwise-copied as a block below.
                    break
                }

            default:
                preconditionFailure("Unreachable")
            }
        }

        // Copy all of the trivial field values, has-bits, and any oneof tracking in bitwise
        // fashion.
        destination.buffer.copyMemory(from: .init(rebasing: buffer[..<firstNontrivialStorageOffset]))

        destination.unknownFields = unknownFields
        destination.extensionStorage = extensionStorage.copy()

        return destination
    }

    /// Copy-initializes the field associated with the given layout information in the destination
    /// storage using its value from this storage.
    private func copyField<T>(_ field: MessageSchema.Field, to destination: MessageStorage, type: T.Type) {
        guard isPresent(field) else { return }

        let sourcePointer = typedPointer(for: field, as: T.self)
        let destinationPointer = destination.typedPointer(for: field, as: T.self)
        destinationPointer.initialize(from: sourcePointer, count: 1)
    }
}

// MARK: - Presence helpers

extension MessageStorage {
    /// The byte offset and bitmask of a field's has-bit in in-memory storage.
    public typealias HasBit = (offset: Int, mask: UInt8)

    /// Returns a value indicating whether the field with the given presence has been explicitly
    /// set.
    @_alwaysEmitIntoClient @inline(__always)
    public func isPresent(hasBit: HasBit) -> Bool {
        buffer.load(fromByteOffset: hasBit.offset, as: UInt8.self) & hasBit.mask != 0
    }

    /// Updates the presence of a field, returning the old presence value before it was changed.
    @_alwaysEmitIntoClient @inline(__always)
    func updatePresence(hasBit: HasBit, willBeSet: Bool) -> Bool {
        let presenceByte = buffer.load(fromByteOffset: hasBit.offset, as: UInt8.self)
        let wasSet = presenceByte & hasBit.mask != 0
        buffer.storeBytes(
            of: (presenceByte & ~hasBit.mask) | (willBeSet ? hasBit.mask : 0),
            toByteOffset: hasBit.offset,
            as: UInt8.self
        )
        return wasSet
    }
}

// MARK: - Field readers used during encoding

extension MessageStorage {
    /// Returns the value at the given offset in the storage.
    ///
    /// - Precondition: The value must already be known to be present.
    @_alwaysEmitIntoClient @inline(__always)
    func assumedPresentValue<Value>(at offset: Int, as type: Value.Type = Value.self) -> Value {
        (buffer.baseAddress! + offset).bindMemory(to: Value.self, capacity: 1).pointee
    }

    /// Returns the value at the given offset in the storage.
    ///
    /// - Precondition: The value must already be known to be present.
    @_alwaysEmitIntoClient @inline(__always)
    func assumedPresentValue<Value: Enum>(at offset: Int, as type: Value.Type = Value.self) -> Value {
        // It is always safe to force-unwrap this. For open enums, the raw value initializer never
        // fails. For closed enums, it fails if the raw value is not a valid case, but such a value
        // should never cause presence to be set. For example, during decoding such a value would be
        // placed in unknown fields.
        //
        // TODO: Change this to `Int32` when we're using that as the raw value type.
        Value(rawValue: Int((buffer.baseAddress! + offset).bindMemory(to: Int32.self, capacity: 1).pointee))!
    }
}

// MARK: - Field readers used by generated accessors

// The field reader functions have some explicit specializations (both concrete and more-constrained
// generic) for cases where we want to encode a "default default value". This reduces the amount of
// code generation that we need to do for the common case (fields without presence, where the
// default value is the zero/empty value for the field's type).
//
// Here and throughout, these functions use `@_alwaysEmitIntoClient` and `@inline(__always)` in a
// best effort to force the compiler to specialize and optimize the generated property accessors
// that call these functions into direct memory accesses. The first attribute also ensures that
// these functions do not emit symbols into the runtime itself, as they would never be used.
//
// We expect an upcoming version of Swift to formalize these two attributes with new names, at
// which point we can conditionally switch to those names to guarantee the behavior.

extension MessageStorage {
    /// Returns the `Bool` value at the given offset in the storage, or the default value if the
    /// value is not present.
    @_alwaysEmitIntoClient @inline(__always)
    public func value(at offset: Int, default defaultValue: Bool = false, hasBit: HasBit) -> Bool {
        guard isPresent(hasBit: hasBit) else { return defaultValue }
        return typedPointer(at: offset, as: Bool.self).pointee
    }

    /// Returns the `Int32` value at the given offset in the storage, or the default value if the
    /// value is not present.
    @_alwaysEmitIntoClient @inline(__always)
    public func value(at offset: Int, default defaultValue: Int32 = 0, hasBit: HasBit) -> Int32 {
        guard isPresent(hasBit: hasBit) else { return defaultValue }
        return typedPointer(at: offset, as: Int32.self).pointee
    }

    /// Returns the `UInt32` value at the given offset in the storage, or the default value if the
    /// value is not present.
    @_alwaysEmitIntoClient @inline(__always)
    public func value(at offset: Int, default defaultValue: UInt32 = 0, hasBit: HasBit) -> UInt32 {
        guard isPresent(hasBit: hasBit) else { return defaultValue }
        return typedPointer(at: offset, as: UInt32.self).pointee
    }

    /// Returns the `Int64` value at the given offset in the storage, or the default value if the
    /// value is not present.
    @_alwaysEmitIntoClient @inline(__always)
    public func value(at offset: Int, default defaultValue: Int64 = 0, hasBit: HasBit) -> Int64 {
        guard isPresent(hasBit: hasBit) else { return defaultValue }
        return typedPointer(at: offset, as: Int64.self).pointee
    }

    /// Returns the `UInt64` value at the given offset in the storage, or the default value if the
    /// value is not present.
    @_alwaysEmitIntoClient @inline(__always)
    public func value(at offset: Int, default defaultValue: UInt64 = 0, hasBit: HasBit) -> UInt64 {
        guard isPresent(hasBit: hasBit) else { return defaultValue }
        return typedPointer(at: offset, as: UInt64.self).pointee
    }

    /// Returns the `Float` value at the given offset in the storage, or the default value if the
    /// value is not present.
    @_alwaysEmitIntoClient @inline(__always)
    public func value(at offset: Int, default defaultValue: Float = 0, hasBit: HasBit) -> Float {
        guard isPresent(hasBit: hasBit) else { return defaultValue }
        return typedPointer(at: offset, as: Float.self).pointee
    }

    /// Returns the `Double` value at the given offset in the storage, or the default value if the
    /// value is not present.
    @_alwaysEmitIntoClient @inline(__always)
    public func value(at offset: Int, default defaultValue: Double = 0, hasBit: HasBit) -> Double {
        guard isPresent(hasBit: hasBit) else { return defaultValue }
        return typedPointer(at: offset, as: Double.self).pointee
    }

    /// Returns the string value at the given offset in the storage, or the default value if the
    /// value is not present.
    @_alwaysEmitIntoClient @inline(__always)
    public func value(at offset: Int, default defaultValue: String = "", hasBit: HasBit) -> String {
        guard isPresent(hasBit: hasBit) else { return defaultValue }
        return typedPointer(at: offset, as: String.self).pointee
    }

    /// Returns the `Data` value at the given offset in the storage, or the default value if the
    /// value is not present.
    @_alwaysEmitIntoClient @inline(__always)
    public func value(at offset: Int, default defaultValue: Data = Data(), hasBit: HasBit) -> Data {
        guard isPresent(hasBit: hasBit) else { return defaultValue }
        return typedPointer(at: offset, as: Data.self).pointee
    }

    /// Returns the `Array` value at the given offset in the storage, or the empty array if the
    /// value is not present.
    @_alwaysEmitIntoClient @inline(__always)
    public func value<Element>(at offset: Int, hasBit: HasBit) -> [Element] {
        guard isPresent(hasBit: hasBit) else { return [] }
        return typedPointer(at: offset, as: [Element].self).pointee
    }

    /// Returns the `Dictionary` value at the given offset in the storage, or the empty array if
    /// the value is not present.
    @_alwaysEmitIntoClient @inline(__always)
    public func value<Key, Value>(at offset: Int, hasBit: HasBit) -> [Key: Value] {
        guard isPresent(hasBit: hasBit) else { return [:] }
        return typedPointer(at: offset, as: [Key: Value].self).pointee
    }

    /// Returns the protobuf enum value at the given offset in the storage, or the default value if
    /// the value is not present.
    @_alwaysEmitIntoClient @inline(__always)
    public func value<T: Enum>(at offset: Int, default defaultValue: T, hasBit: HasBit) -> T {
        guard isPresent(hasBit: hasBit) else { return defaultValue }
        // It is always safe to force-unwrap this. For open enums, the raw value initializer never
        // fails. For closed enums, it fails if the raw value is not a valid case, but such a value
        // should never cause presence to be set. For example, during decoding such a value would be
        // placed in unknown fields.
        return T(rawValue: Int(typedPointer(at: offset, as: Int32.self).pointee))!
    }

    /// Returns the value at the given offset in the storage, or the default value if the value is
    /// not present.
    @_alwaysEmitIntoClient @inline(__always)
    public func value<T>(at offset: Int, default defaultValue: T, hasBit: HasBit) -> T {
        guard isPresent(hasBit: hasBit) else { return defaultValue }
        return typedPointer(at: offset, as: T.self).pointee
    }
}

// MARK: - Field mutators used by generated accessors

// As with the readers above, we have some concrete specializations of `updateValue` for trivial
// types, since they can just store the new value (whether it's zero or some other non-zero default)
// without managing any lifetimes.
//
// The generic implementation handles non-trivial cases, where we need to deinitialize an old value
// that's present and then decide what to do with the incoming state. If the field will be
// set/present, we store the new value; otherwise, we leave it uninitialized and zero it out.
//
// These APIs take the offset and has-bit directly because generating that produces more efficient
// code for accessors than one that would have to extract the same information from a
// `MessageSchema.Field`.

extension MessageStorage {
    /// Updates the `Bool` value at the given offset in the storage, along with its presence.
    @_alwaysEmitIntoClient @inline(__always)
    public func updateValue(at offset: Int, to newValue: Bool, willBeSet: Bool, hasBit: HasBit) {
        typedPointer(at: offset, as: Bool.self).pointee = newValue
        _ = updatePresence(hasBit: hasBit, willBeSet: willBeSet)
    }

    /// Updates the `Int32` value at the given offset in the storage, along with its presence.
    @_alwaysEmitIntoClient @inline(__always)
    public func updateValue(at offset: Int, to newValue: Int32, willBeSet: Bool, hasBit: HasBit) {
        typedPointer(at: offset, as: Int32.self).pointee = newValue
        _ = updatePresence(hasBit: hasBit, willBeSet: willBeSet)
    }

    /// Updates the `UInt32` value at the given offset in the storage, along with its presence.
    @_alwaysEmitIntoClient @inline(__always)
    public func updateValue(at offset: Int, to newValue: UInt32, willBeSet: Bool, hasBit: HasBit) {
        typedPointer(at: offset, as: UInt32.self).pointee = newValue
        _ = updatePresence(hasBit: hasBit, willBeSet: willBeSet)
    }

    /// Updates the `Int64` value at the given offset in the storage, along with its presence.
    @_alwaysEmitIntoClient @inline(__always)
    public func updateValue(at offset: Int, to newValue: Int64, willBeSet: Bool, hasBit: HasBit) {
        typedPointer(at: offset, as: Int64.self).pointee = newValue
        _ = updatePresence(hasBit: hasBit, willBeSet: willBeSet)
    }

    /// Updates the `UInt64` value at the given offset in the storage, along with its presence.
    @_alwaysEmitIntoClient @inline(__always)
    public func updateValue(at offset: Int, to newValue: UInt64, willBeSet: Bool, hasBit: HasBit) {
        typedPointer(at: offset, as: UInt64.self).pointee = newValue
        _ = updatePresence(hasBit: hasBit, willBeSet: willBeSet)
    }

    /// Updates the `Float` value at the given offset in the storage, along with its presence.
    @_alwaysEmitIntoClient @inline(__always)
    public func updateValue(at offset: Int, to newValue: Float, willBeSet: Bool, hasBit: HasBit) {
        typedPointer(at: offset, as: Float.self).pointee = newValue
        _ = updatePresence(hasBit: hasBit, willBeSet: willBeSet)
    }

    /// Updates the `Double` value at the given offset in the storage, along with its presence.
    @_alwaysEmitIntoClient @inline(__always)
    public func updateValue(at offset: Int, to newValue: Double, willBeSet: Bool, hasBit: HasBit) {
        typedPointer(at: offset, as: Double.self).pointee = newValue
        _ = updatePresence(hasBit: hasBit, willBeSet: willBeSet)
    }

    /// Updates the protobuf enum value at the given offset in the storage, along with its presence.
    @_alwaysEmitIntoClient @inline(__always)
    public func updateValue<T: Enum>(at offset: Int, to newValue: T, willBeSet: Bool, hasBit: HasBit) {
        typedPointer(at: offset, as: Int32.self).pointee = Int32(newValue.rawValue)
        _ = updatePresence(hasBit: hasBit, willBeSet: willBeSet)
    }

    /// Updates the value at the given offset in the storage, along with its presence.
    @_alwaysEmitIntoClient @inline(__always)
    public func updateValue<T>(at offset: Int, to newValue: T, willBeSet: Bool, hasBit: HasBit) {
        let pointer = typedPointer(at: offset, as: T.self)
        let wasSet = updatePresence(hasBit: hasBit, willBeSet: willBeSet)
        if wasSet {
            pointer.deinitialize(count: 1)
        }
        if willBeSet {
            pointer.initialize(to: newValue)
        } else {
            zeroOut(at: offset, count: MemoryLayout<T>.stride)
        }
    }

    /// Clears the value at the given offset in the storage, along with its presence.
    @_alwaysEmitIntoClient @inline(__always)
    public func clearValue<T>(at offset: Int, type: T.Type, hasBit: HasBit) {
        let pointer = typedPointer(at: offset, as: T.self)
        let wasSet = updatePresence(hasBit: hasBit, willBeSet: false)
        if wasSet {
            pointer.deinitialize(count: 1)
        }
        zeroOut(at: offset, count: MemoryLayout<T>.stride)
    }

    /// Clears the value at the given offset in the storage, along with its presence.
    ///
    /// This specialization is necessary since enums are stored as their raw values in memory.
    @_alwaysEmitIntoClient @inline(__always)
    public func clearValue<T: Enum>(at offset: Int, type: T.Type, hasBit: HasBit) {
        let pointer = typedPointer(at: offset, as: Int32.self)
        _ = updatePresence(hasBit: hasBit, willBeSet: false)
        pointer.pointee = 0
    }
}

// MARK: - Field accessors and mutators used for parsing and reflection APIs

// Unlike the above APIs, these only take a `MessageSchema.Field` as an argument. These are used
// when parsing messages and in reflection APIs, where we don't know the nature of an arbitrary
// field's explicit presence (or lack of it) as we do when we generate accessors directly.

extension MessageStorage {
    /// Returns the `Bool` value of the given field, or the default value if it is not present.
    func value(of field: MessageSchema.Field, default: Bool = false) -> Bool {
        guard isPresent(field) else { return `default` }
        let offset = schema.byteOffset(of: field)
        switch field.presence {
        case .hasBit(let hasByteOffset, let hasMask):
            return value(at: offset, hasBit: (hasByteOffset, hasMask))
        case .oneOfMember(let oneofOffset):
            return value(at: offset, oneofPresence: (oneofOffset, field.fieldNumber))
        }
    }

    /// Returns the `Int32` value of the given field, or the default value if it is not present.
    func value(of field: MessageSchema.Field, default: Int32 = 0) -> Int32 {
        guard isPresent(field) else { return `default` }
        let offset = schema.byteOffset(of: field)
        switch field.presence {
        case .hasBit(let hasByteOffset, let hasMask):
            return value(at: offset, hasBit: (hasByteOffset, hasMask))
        case .oneOfMember(let oneofOffset):
            return value(at: offset, oneofPresence: (oneofOffset, field.fieldNumber))
        }
    }

    /// Returns the `UInt32` value of the given field, or the default value if it is not present.
    func value(of field: MessageSchema.Field, default: UInt32 = 0) -> UInt32 {
        guard isPresent(field) else { return `default` }
        let offset = schema.byteOffset(of: field)
        switch field.presence {
        case .hasBit(let hasByteOffset, let hasMask):
            return value(at: offset, hasBit: (hasByteOffset, hasMask))
        case .oneOfMember(let oneofOffset):
            return value(at: offset, oneofPresence: (oneofOffset, field.fieldNumber))
        }
    }

    /// Returns the `Int64` value of the given field, or the default value if it is not present.
    func value(of field: MessageSchema.Field, default: Int64 = 0) -> Int64 {
        guard isPresent(field) else { return `default` }
        let offset = schema.byteOffset(of: field)
        switch field.presence {
        case .hasBit(let hasByteOffset, let hasMask):
            return value(at: offset, hasBit: (hasByteOffset, hasMask))
        case .oneOfMember(let oneofOffset):
            return value(at: offset, oneofPresence: (oneofOffset, field.fieldNumber))
        }
    }

    /// Returns the `UInt64` value of the given field, or the default value if it is not present.
    func value(of field: MessageSchema.Field, default: UInt64 = 0) -> UInt64 {
        guard isPresent(field) else { return `default` }
        let offset = schema.byteOffset(of: field)
        switch field.presence {
        case .hasBit(let hasByteOffset, let hasMask):
            return value(at: offset, hasBit: (hasByteOffset, hasMask))
        case .oneOfMember(let oneofOffset):
            return value(at: offset, oneofPresence: (oneofOffset, field.fieldNumber))
        }
    }

    /// Returns the `Float` value of the given field, or the default value if it is not present.
    func value(of field: MessageSchema.Field, default: Float = 0) -> Float {
        guard isPresent(field) else { return `default` }
        let offset = schema.byteOffset(of: field)
        switch field.presence {
        case .hasBit(let hasByteOffset, let hasMask):
            return value(at: offset, hasBit: (hasByteOffset, hasMask))
        case .oneOfMember(let oneofOffset):
            return value(at: offset, oneofPresence: (oneofOffset, field.fieldNumber))
        }
    }

    /// Returns the `Double` value of the given field, or the default value if it is not present.
    func value(of field: MessageSchema.Field, default: Double = 0) -> Double {
        guard isPresent(field) else { return `default` }
        let offset = schema.byteOffset(of: field)
        switch field.presence {
        case .hasBit(let hasByteOffset, let hasMask):
            return value(at: offset, hasBit: (hasByteOffset, hasMask))
        case .oneOfMember(let oneofOffset):
            return value(at: offset, oneofPresence: (oneofOffset, field.fieldNumber))
        }
    }

    /// Returns the `String` value of the given field, or the default value if it is not present.
    func value(of field: MessageSchema.Field, default: String = "") -> String {
        guard isPresent(field) else { return `default` }
        let offset = schema.byteOffset(of: field)
        switch field.presence {
        case .hasBit(let hasByteOffset, let hasMask):
            return value(at: offset, hasBit: (hasByteOffset, hasMask))
        case .oneOfMember(let oneofOffset):
            return value(at: offset, oneofPresence: (oneofOffset, field.fieldNumber))
        }
    }

    /// Returns the `Data` value of the given field, or the default value if it is not present.
    func value(of field: MessageSchema.Field, default: Data = Data()) -> Data {
        guard isPresent(field) else { return `default` }
        let offset = schema.byteOffset(of: field)
        switch field.presence {
        case .hasBit(let hasByteOffset, let hasMask):
            return value(at: offset, hasBit: (hasByteOffset, hasMask))
        case .oneOfMember(let oneofOffset):
            return value(at: offset, oneofPresence: (oneofOffset, field.fieldNumber))
        }
    }

    /// Returns the enum value of the given field, or the default value if it is not present.
    func value<T: Enum>(of field: MessageSchema.Field, default: T = .init()) -> T {
        guard isPresent(field) else { return `default` }
        let offset = schema.byteOffset(of: field)
        switch field.presence {
        case .hasBit(let hasByteOffset, let hasMask):
            return value(at: offset, default: `default`, hasBit: (hasByteOffset, hasMask))
        case .oneOfMember(let oneofOffset):
            return value(at: offset, default: `default`, oneofPresence: (oneofOffset, field.fieldNumber))
        }
    }

    /// Returns the array value of the given field, or the default value if it is not present.
    func value<T>(of field: MessageSchema.Field, default: [T] = []) -> [T] {
        guard isPresent(field) else { return `default` }
        let offset = schema.byteOffset(of: field)
        switch field.presence {
        case .hasBit(let hasByteOffset, let hasMask):
            return value(at: offset, hasBit: (hasByteOffset, hasMask))
        case .oneOfMember:
            preconditionFailure("Unreachable")
        }
    }

    /// Returns the field number of the oneof member that is populated, using the given field to
    /// look up its containing oneof.
    func populatedOneofMember(of field: MessageSchema.Field) -> UInt32 {
        switch field.presence {
        case .hasBit:
            preconditionFailure("field was not a member of a oneof")
        case .oneOfMember(let oneofOffset):
            return populatedOneofMember(at: oneofOffset)
        }
    }

    /// Updates the `Bool` value of the given field, tracking its presence accordingly.
    func updateValue(of field: MessageSchema.Field, to newValue: Bool) {
        let offset = schema.byteOffset(of: field)
        switch field.presence {
        case .hasBit(let hasByteOffset, let hasMask):
            updateValue(
                at: offset,
                to: newValue,
                willBeSet: schema.fieldHasPresence(field) ? true : newValue,
                hasBit: (hasByteOffset, hasMask)
            )
        case .oneOfMember(let oneofOffset):
            updateValue(at: offset, to: newValue, oneofPresence: (oneofOffset, field.fieldNumber))
        }
    }

    /// Updates the `Int32` value of the given field, tracking its presence accordingly.
    func updateValue(of field: MessageSchema.Field, to newValue: Int32) {
        let offset = schema.byteOffset(of: field)
        switch field.presence {
        case .hasBit(let hasByteOffset, let hasMask):
            updateValue(
                at: offset,
                to: newValue,
                willBeSet: schema.fieldHasPresence(field) ? true : (newValue != 0),
                hasBit: (hasByteOffset, hasMask)
            )
        case .oneOfMember(let oneofOffset):
            updateValue(at: offset, to: newValue, oneofPresence: (oneofOffset, field.fieldNumber))
        }
    }

    /// Updates the `UInt32` value of the given field, tracking its presence accordingly.
    func updateValue(of field: MessageSchema.Field, to newValue: UInt32) {
        let offset = schema.byteOffset(of: field)
        switch field.presence {
        case .hasBit(let hasByteOffset, let hasMask):
            updateValue(
                at: offset,
                to: newValue,
                willBeSet: schema.fieldHasPresence(field) ? true : (newValue != 0),
                hasBit: (hasByteOffset, hasMask)
            )
        case .oneOfMember(let oneofOffset):
            updateValue(at: offset, to: newValue, oneofPresence: (oneofOffset, field.fieldNumber))
        }
    }

    /// Updates the `Int64` value of the given field, tracking its presence accordingly.
    func updateValue(of field: MessageSchema.Field, to newValue: Int64) {
        let offset = schema.byteOffset(of: field)
        switch field.presence {
        case .hasBit(let hasByteOffset, let hasMask):
            updateValue(
                at: offset,
                to: newValue,
                willBeSet: schema.fieldHasPresence(field) ? true : (newValue != 0),
                hasBit: (hasByteOffset, hasMask)
            )
        case .oneOfMember(let oneofOffset):
            updateValue(at: offset, to: newValue, oneofPresence: (oneofOffset, field.fieldNumber))
        }
    }

    /// Updates the `UInt64` value of the given field, tracking its presence accordingly.
    func updateValue(of field: MessageSchema.Field, to newValue: UInt64) {
        let offset = schema.byteOffset(of: field)
        switch field.presence {
        case .hasBit(let hasByteOffset, let hasMask):
            updateValue(
                at: offset,
                to: newValue,
                willBeSet: schema.fieldHasPresence(field) ? true : (newValue != 0),
                hasBit: (hasByteOffset, hasMask)
            )
        case .oneOfMember(let oneofOffset):
            updateValue(at: offset, to: newValue, oneofPresence: (oneofOffset, field.fieldNumber))
        }
    }

    /// Updates the `Float` value of the given field, tracking its presence accordingly.
    func updateValue(of field: MessageSchema.Field, to newValue: Float) {
        let offset = schema.byteOffset(of: field)
        switch field.presence {
        case .hasBit(let hasByteOffset, let hasMask):
            updateValue(
                at: offset,
                to: newValue,
                willBeSet: schema.fieldHasPresence(field) ? true : (newValue != 0),
                hasBit: (hasByteOffset, hasMask)
            )
        case .oneOfMember(let oneofOffset):
            updateValue(at: offset, to: newValue, oneofPresence: (oneofOffset, field.fieldNumber))
        }
    }

    /// Updates the `Double` value of the given field, tracking its presence accordingly.
    func updateValue(of field: MessageSchema.Field, to newValue: Double) {
        let offset = schema.byteOffset(of: field)
        switch field.presence {
        case .hasBit(let hasByteOffset, let hasMask):
            updateValue(
                at: offset,
                to: newValue,
                willBeSet: schema.fieldHasPresence(field) ? true : (newValue != 0),
                hasBit: (hasByteOffset, hasMask)
            )
        case .oneOfMember(let oneofOffset):
            updateValue(at: offset, to: newValue, oneofPresence: (oneofOffset, field.fieldNumber))
        }
    }

    /// Updates the `String` value of the given field, tracking its presence accordingly.
    func updateValue(of field: MessageSchema.Field, to newValue: String) {
        let offset = schema.byteOffset(of: field)
        switch field.presence {
        case .hasBit(let hasByteOffset, let hasMask):
            updateValue(
                at: offset,
                to: newValue,
                willBeSet: schema.fieldHasPresence(field) ? true : !newValue.isEmpty,
                hasBit: (hasByteOffset, hasMask)
            )
        case .oneOfMember(let oneofOffset):
            updateValue(at: offset, to: newValue, oneofPresence: (oneofOffset, field.fieldNumber))
        }
    }

    /// Updates the `Data` value of the given field, tracking its presence accordingly.
    func updateValue(of field: MessageSchema.Field, to newValue: Data) {
        let offset = schema.byteOffset(of: field)
        switch field.presence {
        case .hasBit(let hasByteOffset, let hasMask):
            updateValue(
                at: offset,
                to: newValue,
                willBeSet: schema.fieldHasPresence(field) ? true : !newValue.isEmpty,
                hasBit: (hasByteOffset, hasMask)
            )
        case .oneOfMember(let oneofOffset):
            updateValue(at: offset, to: newValue, oneofPresence: (oneofOffset, field.fieldNumber))
        }
    }

    /// Updates the protobuf enum value of the given field, tracking its presence accordingly.
    func updateValue<T: Enum>(of field: MessageSchema.Field, to newValue: T) {
        let offset = schema.byteOffset(of: field)
        switch field.presence {
        case .hasBit(let hasByteOffset, let hasMask):
            updateValue(
                at: offset,
                to: newValue,
                willBeSet: schema.fieldHasPresence(field) ? true : newValue != T(),
                hasBit: (hasByteOffset, hasMask)
            )
        case .oneOfMember(let oneofOffset):
            updateValue(at: offset, to: newValue, oneofPresence: (oneofOffset, field.fieldNumber))
        }
    }

    /// Appends the given value to the values already present in the field, initializing the field
    /// if necessary.
    func appendValue<T>(_ value: T, to field: MessageSchema.Field) {
        // If the field isn't already present, we need to initialize a new array first.
        let pointer = typedPointer(for: field, as: [T].self)
        if !isPresent(field) {
            pointer.initialize(to: [value])
            switch field.presence {
            case .hasBit(let hasByteOffset, let hasMask):
                _ = updatePresence(hasBit: (hasByteOffset, hasMask), willBeSet: true)
            case .oneOfMember(let oneofOffset):
                _ = updatePopulatedOneofMember((oneofOffset, field.fieldNumber))
            }
        } else {
            pointer.pointee.append(value)
        }
    }

    /// Clears the given non-enum field, tracking its presence accordingly.
    func clearValue<T>(of field: MessageSchema.Field, type: T.Type = T.self) {
        let offset = schema.byteOffset(of: field)
        switch field.presence {
        case .hasBit(let hasByteOffset, let hasMask):
            clearValue(at: offset, type: T.self, hasBit: (hasByteOffset, hasMask))
        case .oneOfMember(let oneofOffset):
            clearPopulatedOneofMember(at: oneofOffset)
        }
    }

    /// Clears the given enum field, tracking its presence accordingly.
    ///
    /// This specialization is necessary since enums are stored as their raw values in memory.
    func clearValue<T: Enum>(of field: MessageSchema.Field, type: T.Type = T.self) {
        let offset = schema.byteOffset(of: field)
        switch field.presence {
        case .hasBit(let hasByteOffset, let hasMask):
            clearValue(at: offset, type: T.self, hasBit: (hasByteOffset, hasMask))
        case .oneOfMember(let oneofOffset):
            clearPopulatedOneofMember(at: oneofOffset)
        }
    }
}

// MARK: - Oneof support

extension MessageStorage {
    /// Describes presence information that is used when getting or setting oneof members.
    public typealias OneofPresence = (offset: Int, fieldNumber: UInt32)

    /// Returns the field number of the oneof member that is populated, given the oneof offset into
    /// the storage buffer.
    @_alwaysEmitIntoClient @inline(__always)
    public func populatedOneofMember(at oneofOffset: Int) -> UInt32 {
        typedPointer(at: oneofOffset, as: UInt32.self).pointee
    }

    /// Updates the field number of the oneof member that is populated, given the oneof offset into
    /// the storage buffer, and returns the field number of the previously set member (or zero if
    /// none was set).
    @_alwaysEmitIntoClient @inline(__always)
    public func updatePopulatedOneofMember(_ presence: OneofPresence) -> UInt32 {
        let offsetPointer = typedPointer(at: presence.offset, as: UInt32.self)
        let oldFieldNumber = offsetPointer.pointee
        offsetPointer.pointee = presence.fieldNumber
        return oldFieldNumber
    }

    /// Returns the `Bool` value at the given offset in the storage if it is the currently
    /// populated member of its containing oneof, or the default value otherwise.
    @_alwaysEmitIntoClient @inline(__always)
    public func value(at offset: Int, default defaultValue: Bool = false, oneofPresence: OneofPresence) -> Bool {
        guard populatedOneofMember(at: oneofPresence.offset) == oneofPresence.fieldNumber else {
            return defaultValue
        }
        return typedPointer(at: offset, as: Bool.self).pointee
    }

    /// Returns the `Int32` value at the given offset in the storage if it is the currently
    /// populated member of its containing oneof, or the default value otherwise.
    @_alwaysEmitIntoClient @inline(__always)
    public func value(at offset: Int, default defaultValue: Int32 = 0, oneofPresence: OneofPresence) -> Int32 {
        guard populatedOneofMember(at: oneofPresence.offset) == oneofPresence.fieldNumber else {
            return defaultValue
        }
        return typedPointer(at: offset, as: Int32.self).pointee
    }

    /// Returns the `UInt32` value at the given offset in the storage if it is the currently
    /// populated member of its containing oneof, or the default value otherwise.
    @_alwaysEmitIntoClient @inline(__always)
    public func value(at offset: Int, default defaultValue: UInt32 = 0, oneofPresence: OneofPresence) -> UInt32 {
        guard populatedOneofMember(at: oneofPresence.offset) == oneofPresence.fieldNumber else {
            return defaultValue
        }
        return typedPointer(at: offset, as: UInt32.self).pointee
    }

    /// Returns the `Int64` value at the given offset in the storage if it is the currently
    /// populated member of its containing oneof, or the default value otherwise.
    @_alwaysEmitIntoClient @inline(__always)
    public func value(at offset: Int, default defaultValue: Int64 = 0, oneofPresence: OneofPresence) -> Int64 {
        guard populatedOneofMember(at: oneofPresence.offset) == oneofPresence.fieldNumber else {
            return defaultValue
        }
        return typedPointer(at: offset, as: Int64.self).pointee
    }

    /// Returns the `UInt64` value at the given offset in the storage if it is the currently
    /// populated member of its containing oneof, or the default value otherwise.
    @_alwaysEmitIntoClient @inline(__always)
    public func value(at offset: Int, default defaultValue: UInt64 = 0, oneofPresence: OneofPresence) -> UInt64 {
        guard populatedOneofMember(at: oneofPresence.offset) == oneofPresence.fieldNumber else {
            return defaultValue
        }
        return typedPointer(at: offset, as: UInt64.self).pointee
    }

    /// Returns the `Float` value at the given offset in the storage if it is the currently
    /// populated member of its containing oneof, or the default value otherwise.
    @_alwaysEmitIntoClient @inline(__always)
    public func value(at offset: Int, default defaultValue: Float = 0, oneofPresence: OneofPresence) -> Float {
        guard populatedOneofMember(at: oneofPresence.offset) == oneofPresence.fieldNumber else {
            return defaultValue
        }
        return typedPointer(at: offset, as: Float.self).pointee
    }

    /// Returns the `Double` value at the given offset in the storage if it is the currently
    /// populated member of its containing oneof, or the default value otherwise.
    @_alwaysEmitIntoClient @inline(__always)
    public func value(at offset: Int, default defaultValue: Double = 0, oneofPresence: OneofPresence) -> Double {
        guard populatedOneofMember(at: oneofPresence.offset) == oneofPresence.fieldNumber else {
            return defaultValue
        }
        return typedPointer(at: offset, as: Double.self).pointee
    }

    /// Returns the `String` value at the given offset in the storage if it is the currently
    /// populated member of its containing oneof, or the default value otherwise.
    @_alwaysEmitIntoClient @inline(__always)
    public func value(at offset: Int, default defaultValue: String = "", oneofPresence: OneofPresence) -> String {
        guard populatedOneofMember(at: oneofPresence.offset) == oneofPresence.fieldNumber else {
            return defaultValue
        }
        return typedPointer(at: offset, as: String.self).pointee
    }

    /// Returns the `Data` value at the given offset in the storage if it is the currently
    /// populated member of its containing oneof, or the default value otherwise.
    @_alwaysEmitIntoClient @inline(__always)
    public func value(at offset: Int, default defaultValue: Data = Data(), oneofPresence: OneofPresence) -> Data {
        guard populatedOneofMember(at: oneofPresence.offset) == oneofPresence.fieldNumber else {
            return defaultValue
        }
        return typedPointer(at: offset, as: Data.self).pointee
    }

    /// Returns the protobuf enum value at the given offset in the storage if it is the currently
    /// populated member of its containing oneof, or the default value otherwise.
    @_alwaysEmitIntoClient @inline(__always)
    public func value<T: Enum>(at offset: Int, default defaultValue: T, oneofPresence: OneofPresence) -> T {
        guard populatedOneofMember(at: oneofPresence.offset) == oneofPresence.fieldNumber else {
            return defaultValue
        }
        // It is always safe to force-unwrap this. For open enums, the raw value initializer never
        // fails. For closed enums, it fails if the raw value is not a valid case, but such a value
        // should never cause presence to be set. For example, during decoding such a value would be
        // placed in unknown fields.
        //
        // TODO: Change this to `Int32` when we're using that as the raw value type.
        return T(rawValue: Int(typedPointer(at: offset, as: Int32.self).pointee))!
    }

    /// Returns the value at the given offset in the storage if it is the currently populated
    /// member of its containing oneof, or the default value otherwise.
    @_alwaysEmitIntoClient @inline(__always)
    public func value<T>(at offset: Int, default defaultValue: T, oneofPresence: OneofPresence) -> T {
        guard populatedOneofMember(at: oneofPresence.offset) == oneofPresence.fieldNumber else {
            return defaultValue
        }
        return typedPointer(at: offset, as: T.self).pointee
    }

    /// Updates the `Bool` value at the given offset in the storage, along with its presence.
    @_alwaysEmitIntoClient @inline(__always)
    public func updateValue(at offset: Int, to newValue: Bool, oneofPresence: OneofPresence) {
        let oldFieldNumber = updatePopulatedOneofMember(oneofPresence)
        if oldFieldNumber != 0 {
            // We can force-unwrap this because the field must exist or it would be a generator bug.
            deinitializeOneofMember(schema[fieldNumber: oldFieldNumber]!)
        }
        typedPointer(at: offset, as: Bool.self).pointee = newValue
    }

    /// Updates the `Int32` value at the given offset in the storage, along with its presence.
    @_alwaysEmitIntoClient @inline(__always)
    public func updateValue(at offset: Int, to newValue: Int32, oneofPresence: OneofPresence) {
        let oldFieldNumber = updatePopulatedOneofMember(oneofPresence)
        if oldFieldNumber != 0 {
            // We can force-unwrap this because the field must exist or it would be a generator bug.
            deinitializeOneofMember(schema[fieldNumber: oldFieldNumber]!)
        }
        typedPointer(at: offset, as: Int32.self).pointee = newValue
    }

    /// Updates the `UInt32` value at the given offset in the storage, along with its presence.
    @_alwaysEmitIntoClient @inline(__always)
    public func updateValue(at offset: Int, to newValue: UInt32, oneofPresence: OneofPresence) {
        let oldFieldNumber = updatePopulatedOneofMember(oneofPresence)
        if oldFieldNumber != 0 {
            // We can force-unwrap this because the field must exist or it would be a generator bug.
            deinitializeOneofMember(schema[fieldNumber: oldFieldNumber]!)
        }
        typedPointer(at: offset, as: UInt32.self).pointee = newValue
    }

    /// Updates the `Int64` value at the given offset in the storage, along with its presence.
    @_alwaysEmitIntoClient @inline(__always)
    public func updateValue(at offset: Int, to newValue: Int64, oneofPresence: OneofPresence) {
        let oldFieldNumber = updatePopulatedOneofMember(oneofPresence)
        if oldFieldNumber != 0 {
            // We can force-unwrap this because the field must exist or it would be a generator bug.
            deinitializeOneofMember(schema[fieldNumber: oldFieldNumber]!)
        }
        typedPointer(at: offset, as: Int64.self).pointee = newValue
    }

    /// Updates the `UInt64` value at the given offset in the storage, along with its presence.
    @_alwaysEmitIntoClient @inline(__always)
    public func updateValue(at offset: Int, to newValue: UInt64, oneofPresence: OneofPresence) {
        let oldFieldNumber = updatePopulatedOneofMember(oneofPresence)
        if oldFieldNumber != 0 {
            // We can force-unwrap this because the field must exist or it would be a generator bug.
            deinitializeOneofMember(schema[fieldNumber: oldFieldNumber]!)
        }
        typedPointer(at: offset, as: UInt64.self).pointee = newValue
    }

    /// Updates the `Float` value at the given offset in the storage, along with its presence.
    @_alwaysEmitIntoClient @inline(__always)
    public func updateValue(at offset: Int, to newValue: Float, oneofPresence: OneofPresence) {
        let oldFieldNumber = updatePopulatedOneofMember(oneofPresence)
        if oldFieldNumber != 0 {
            // We can force-unwrap this because the field must exist or it would be a generator bug.
            deinitializeOneofMember(schema[fieldNumber: oldFieldNumber]!)
        }
        typedPointer(at: offset, as: Float.self).pointee = newValue
    }

    /// Updates the `Double` value at the given offset in the storage, along with its presence.
    @_alwaysEmitIntoClient @inline(__always)
    public func updateValue(at offset: Int, to newValue: Double, oneofPresence: OneofPresence) {
        let oldFieldNumber = updatePopulatedOneofMember(oneofPresence)
        if oldFieldNumber != 0 {
            // We can force-unwrap this because the field must exist or it would be a generator bug.
            deinitializeOneofMember(schema[fieldNumber: oldFieldNumber]!)
        }
        typedPointer(at: offset, as: Double.self).pointee = newValue
    }

    /// Updates the protobuf enum value at the given offset in the storage, along with its presence.
    @_alwaysEmitIntoClient @inline(__always)
    public func updateValue<T: Enum>(at offset: Int, to newValue: T, oneofPresence: OneofPresence) {
        let oldFieldNumber = updatePopulatedOneofMember(oneofPresence)
        if oldFieldNumber != 0 {
            // We can force-unwrap this because the field must exist or it would be a generator bug.
            deinitializeOneofMember(schema[fieldNumber: oldFieldNumber]!)
        }
        typedPointer(at: offset, as: Int32.self).initialize(to: Int32(newValue.rawValue))
    }

    /// Updates the value at the given offset in the storage, along with its presence.
    @_alwaysEmitIntoClient @inline(__always)
    public func updateValue<T>(at offset: Int, to newValue: T, oneofPresence: OneofPresence) {
        let oldFieldNumber = updatePopulatedOneofMember(oneofPresence)
        if oldFieldNumber != 0 {
            // We can force-unwrap this because the field must exist or it would be a generator bug.
            deinitializeOneofMember(schema[fieldNumber: oldFieldNumber]!)
        }
        typedPointer(at: offset, as: T.self).initialize(to: newValue)
    }

    /// Clears the populated oneof member give the oneof offset into the storage buffer,
    /// deinitializing any existing value if necessary.
    @_alwaysEmitIntoClient @inline(__always)
    public func clearPopulatedOneofMember(at oneofOffset: Int) {
        let oldFieldNumber = updatePopulatedOneofMember((offset: oneofOffset, fieldNumber: 0))
        guard oldFieldNumber != 0 else { return }
        // We can force-unwrap this because the field must exist or it would be a generator bug.
        deinitializeOneofMember(schema[fieldNumber: oldFieldNumber]!)
    }

    /// Deinitializes the value for the given field that is a oneof member and zeros out the
    /// storage slot.
    ///
    /// - Precondition: The value associated with this field must be initialized.
    @_alwaysEmitIntoClient @inline(__always)
    private func deinitializeOneofMember(_ field: MessageSchema.Field) {
        // If this is being called when a value is being updated, we will have already updated the
        // presence of the field, so we have to use `deinitializeFieldForced` to avoid an incorrect
        // presence check.
        deinitializeFieldForced(field)

        // TODO: We could skip zeroing out the backing storage if this is part of a mutation that
        // is setting the same member that's being deinitialized. Determine if that's a worthwhile
        // optimization.
        let stride = field.scalarStride
        zeroOut(pointer: rawPointer(for: field), count: stride)
    }
}

// MARK: - Message equality

// MARK: - Message initialized (i.e., required fields) check

extension MessageStorage {
    /// Indicates whether all required fields are present in this message.
    ///
    /// This is a shallow check; it does not recurse into submessages to check their initialized
    /// state.
    @inline(never)
    var isMessageInitializedShallow: Bool {
        // A message with no required fields is trivially considered initialized.
        guard schema.requiredCount > 0 else { return true }

        // The has-bits for the required fields have been ordered first in storage, so we can
        // quickly determine whether a message is initialzed using a simple `memcmp` (with at most
        // one additional masked byte comparison for overflow bits).
        let requiredByteCount = schema.requiredCount / 8
        if requiredByteCount > 0 {
            let requiredBytesAllSet = withUnsafeTemporaryAllocation(of: UInt8.self, capacity: requiredByteCount) {
                allSetBuffer in
                allSetBuffer.initialize(repeating: 0xff)
                return memcmp(buffer.baseAddress!, allSetBuffer.baseAddress!, requiredByteCount) == 0
            }
            guard requiredBytesAllSet else { return false }
        }

        // If the number of required has-bits is not a multiple of 8, check the remaining bits.
        // These may be followed immediately by has-bits for non-required fields so we need to mask
        // off just the required ones.
        let remainingBits = UInt8(schema.requiredCount & 7)
        guard remainingBits != 0 else { return true }

        let remainingMask: UInt8 = (1 << remainingBits) - 1
        return buffer[requiredByteCount] & remainingMask == remainingMask
    }

    /// Indicates whether all required fields are present in this message, recursively checking
    /// submessages.
    public var isMessageInitializedRecursive: Bool {
        // Quickly check all required local fields
        guard isMessageInitializedShallow else { return false }

        // Now recurse through any field type that could hold Messages.
        var mapEntryWorkingSpace = MapEntryWorkingSpace(ownerSchema: schema)
        for field in schema.fields {
            switch field.rawFieldType {
            case .message, .group:
                // The shallow check above already catches if this was required but not set, here
                // all that has to be done is check if it was set before recursing through it.
                guard isPresent(field) else {
                    continue
                }
                switch field.fieldMode.cardinality {
                case .map:
                    let workingSpace = mapEntryWorkingSpace.storage(for: field.submessageIndex)
                    var areAllInitialized = true
                    forEachMapEntry(in: field, useDeterministicOrdering: false, workingSpace: workingSpace) {
                        if !$0.isMessageInitializedRecursive {
                            areAllInitialized = false
                            return .stop
                        }
                        return .continue
                    }
                    guard areAllInitialized else {
                        return false
                    }

                case .array:
                    var areAllInitialized = true
                    forEachMessage(inAssumedPresentRepeatedMessageField: field) {
                        guard $0.isMessageInitializedRecursive else {
                            areAllInitialized = false
                            return .stop
                        }
                        return .continue
                    }
                    return areAllInitialized

                case .scalar:
                    let storage = messageStorage(forAssumedPresentSingularMessageField: field)
                    guard storage.isMessageInitializedRecursive else {
                        return false
                    }

                default:
                    preconditionFailure("Unreachable")
                }

            default:
                // Nothing to do for other types of fields; they've already been considered by
                // the shallow check.
                break
            }
        }

        // If any extension fields are groups or messages, we need to check their initialization
        // state.
        guard extensionStorage.allSubmessagesAreInitialized else { return false }

        return true
    }
}

/// A token that allows the runtime to access the underlying storage of a message.
///
/// This type is public because the runtime must be able to generically access the underlying
/// storage of a message, so a protocol requirement on `Message` is provided that takes a value of
/// this type as an argument. However, only the runtime may create instances of it.
public struct MessageStorageToken {
    init() {}
}

/// A macro-like helper function used in generated code to simplify writing platform-specific
/// offsets in field accessors.
///
/// By virtue of being declared transparent, the compiler will always be able to reduce this down
/// to a single integer load depending on the target platform, so this function has no real
/// overhead and we are able to keep the generated code more compact than if we had to express the
/// `#if` blocks directly inside each accessor.
@_transparent
public func _fieldOffset(_ pointerWidth64: Int, _ pointerWidth32: Int) -> Int {
    #if _pointerBitWidth(_64)
    pointerWidth64
    #elseif _pointerBitWidth(_32)
    pointerWidth32
    #else
    #error("Unsupported platform")
    #endif
}
