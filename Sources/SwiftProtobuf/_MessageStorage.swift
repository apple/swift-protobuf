// Sources/SwiftProtobuf/_MessageStorage.swift - Table-driven message storage
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
/// `_MessageLayout` that it is initialized with. While fields may be laid out at different offsets
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
@_spi(ForGeneratedCodeOnly) public final class _MessageStorage {
    /// The layout of this instance of storage.
    private let layout: _MessageLayout

    /// The memory buffer that contain's the data for the message's fields.
    @usableFromInline internal let buffer: UnsafeMutableRawBufferPointer

    /// The storage used for unknown fields.
    public var unknownFields: UnknownStorage

    /// The storage used for extension field values.
    /// TODO: This will very likely change as the table-driven implementation evolves.
    public var extensionFieldValues: ExtensionFieldValueSet

    /// Creates a new message storage instance for a message with the given layout.
    public init(layout: _MessageLayout) {
        self.layout = layout
        self.buffer = UnsafeMutableRawBufferPointer.allocate(
            byteCount: layout.size,
            alignment: MemoryLayout<Int>.alignment
        )
        self.buffer.withMemoryRebound(to: UInt8.self) { byteBuffer in
            byteBuffer.initialize(repeating: 0)
        }
        self.unknownFields = UnknownStorage()
        self.extensionFieldValues = ExtensionFieldValueSet()
    }

    deinit {
        for field in layout.fields {
            switch field.fieldMode.cardinality {
            case .map:
                // TODO: Support map fields.
                break

            case .array:
                switch field.rawFieldType {
                case .bool: deinitializeField(field, type: [Bool].self)
                case .bytes: deinitializeField(field, type: [Data].self)
                case .double: deinitializeField(field, type: [Double].self)
                case .enum:
                    // TODO: Figure out how we represent enums (open vs. closed).
                    break
                case .fixed32, .uint32: deinitializeField(field, type: [UInt32].self)
                case .fixed64, .uint64: deinitializeField(field, type: [UInt64].self)
                case .float: deinitializeField(field, type: [Float].self)
                case .group, .message:
                    layout.deinitializeSubmessage(
                        _MessageLayout.SubmessageToken(index: field.submessageIndex),
                        field,
                        self
                    )
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
                    layout.deinitializeSubmessage(
                        _MessageLayout.SubmessageToken(index: field.submessageIndex),
                        field,
                        self
                    )
                default:
                    // Ignore trivial fields; no deinitialization is necessary.
                    break
                }

            default:
                preconditionFailure("Unreachable")
            }
        }
        buffer.deallocate()
    }

    /// Deinitializes the field associated with the given layout information.
    public func deinitializeField<T>(_ field: FieldLayout, type: T.Type) {
        switch field.presence {
        case .oneOfMember:
            // TODO: Support oneof fields.
            break

        case .hasBit(let byteOffset, let mask):
            guard isPresent(hasBit: (byteOffset, mask)) else {
                return
            }
            (buffer.baseAddress! + field.offset).bindMemory(to: T.self, capacity: 1).deinitialize(count: 1)
        }
    }
}

// MARK: - Whole-message operations

extension _MessageStorage {
    /// Creates and returns an independent copy of the values in this storage.
    ///
    /// This is used to implement copy-on-write behavior.
    @inline(never)
    public func copy() -> _MessageStorage {
        let destination = _MessageStorage(layout: layout)

        // Loops through the fields, copy-initializing any that are non-trivial types. We ignore
        // the trivial ones here, instead ttracking the byte offset of the first non-trivial field
        // so that we can bitwise copy those as a block afterward.
        var firstNontrivialStorageOffset = 0
        for field in layout.fields {
            switch field.fieldMode.cardinality {
            case .map:
                if firstNontrivialStorageOffset == 0 {
                    firstNontrivialStorageOffset = field.offset
                }
                // TODO: Support map fields.
                break

            case .array:
                if firstNontrivialStorageOffset == 0 {
                    firstNontrivialStorageOffset = field.offset
                }
                switch field.rawFieldType {
                case .bool: copyField(field, to: destination, type: [Bool].self)
                case .bytes: copyField(field, to: destination, type: [Data].self)
                case .double: copyField(field, to: destination, type: [Double].self)
                case .enum:
                    // TODO: Figure out how we represent enums (open vs. closed).
                    break
                case .fixed32, .uint32: copyField(field, to: destination, type: [UInt32].self)
                case .fixed64, .uint64: copyField(field, to: destination, type: [UInt64].self)
                case .float: copyField(field, to: destination, type: [Float].self)
                case .group, .message:
                    layout.copySubmessage(
                        _MessageLayout.SubmessageToken(index: field.submessageIndex),
                        field,
                        self,
                        destination
                    )
                case .int32, .sfixed32, .sint32: copyField(field, to: destination, type: [Int32].self)
                case .int64, .sfixed64, .sint64: copyField(field, to: destination, type: [Int64].self)
                case .string: copyField(field, to: destination, type: [String].self)
                default: preconditionFailure("Unreachable")
                }

            case .scalar:
                switch field.rawFieldType {
                case .bytes:
                    if firstNontrivialStorageOffset == 0 {
                        firstNontrivialStorageOffset = field.offset
                    }
                    copyField(field, to: destination, type: Data.self)

                case .group, .message:
                    if firstNontrivialStorageOffset == 0 {
                        firstNontrivialStorageOffset = field.offset
                    }
                    layout.copySubmessage(
                        _MessageLayout.SubmessageToken(index: field.submessageIndex),
                        field,
                        self,
                        destination
                    )

                case .string:
                    if firstNontrivialStorageOffset == 0 {
                        firstNontrivialStorageOffset = field.offset
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

        // Copy all of the trivial values (including has-bits) in bitwise fashion. Note that if we
        // never set `firstNontrivialStorageOffset`, then the whole message must have been trivial
        // fields. (This also works if the message is empty; that is, zero bytes.)
        if firstNontrivialStorageOffset == 0 {
            firstNontrivialStorageOffset = layout.size
        }
        if firstNontrivialStorageOffset != 0 {
            destination.buffer.copyMemory(from: .init(rebasing: buffer[..<firstNontrivialStorageOffset]))
        }
        return destination
    }

    /// Copy-initializes the field associated with the given layout information in the destination
    /// storage using its value from this storage.
    public func copyField<T>(_ field: FieldLayout, to destination: _MessageStorage, type: T.Type) {
        switch field.presence {
        case .oneOfMember:
            // TODO: Support oneof fields.
            break

        case .hasBit(let byteOffset, let mask):
            guard isPresent(hasBit: (byteOffset, mask)) else {
                return
            }
            let sourcePointer = (buffer.baseAddress! + field.offset).bindMemory(to: T.self, capacity: 1)
            let destinationPointer = (destination.buffer.baseAddress! + field.offset).bindMemory(
                to: T.self,
                capacity: 1
            )
            destinationPointer.initialize(from: sourcePointer, count: 1)
        }
    }
}

// MARK: - Presence helpers

extension _MessageStorage {
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
    private func updatePresence(hasBit: HasBit, willBeSet: Bool) -> Bool {
        let oldValue = buffer.load(fromByteOffset: hasBit.offset, as: UInt8.self) & ~hasBit.mask
        buffer.storeBytes(of: oldValue | (willBeSet ? hasBit.mask : 0), toByteOffset: hasBit.offset, as: UInt8.self)
        return oldValue != 0
    }
}

// MARK: - Field readers

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

extension _MessageStorage {
    /// Returns the `Bool` value at the given offset in the storage, or the default value if the
    /// value is not present.
    @_alwaysEmitIntoClient @inline(__always)
    public func value(at offset: Int, default defaultValue: Bool = false, hasBit: HasBit) -> Bool {
        guard isPresent(hasBit: hasBit) else { return defaultValue }
        return (buffer.baseAddress! + offset).bindMemory(to: Bool.self, capacity: 1).pointee
    }

    /// Returns the `Int32` value at the given offset in the storage, or the default value if the
    /// value is not present.
    @_alwaysEmitIntoClient @inline(__always)
    public func value(at offset: Int, default defaultValue: Int32 = 0, hasBit: HasBit) -> Int32 {
        guard isPresent(hasBit: hasBit) else { return defaultValue }
        return (buffer.baseAddress! + offset).bindMemory(to: Int32.self, capacity: 1).pointee
    }

    /// Returns the `UInt32` value at the given offset in the storage, or the default value if the
    /// value is not present.
    @_alwaysEmitIntoClient @inline(__always)
    public func value(at offset: Int, default defaultValue: UInt32 = 0, hasBit: HasBit) -> UInt32 {
        guard isPresent(hasBit: hasBit) else { return defaultValue }
        return (buffer.baseAddress! + offset).bindMemory(to: UInt32.self, capacity: 1).pointee
    }

    /// Returns the `Int64` value at the given offset in the storage, or the default value if the
    /// value is not present.
    @_alwaysEmitIntoClient @inline(__always)
    public func value(at offset: Int, default defaultValue: Int64 = 0, hasBit: HasBit) -> Int64 {
        guard isPresent(hasBit: hasBit) else { return defaultValue }
        return (buffer.baseAddress! + offset).bindMemory(to: Int64.self, capacity: 1).pointee
    }

    /// Returns the `UInt64` value at the given offset in the storage, or the default value if the
    /// value is not present.
    @_alwaysEmitIntoClient @inline(__always)
    public func value(at offset: Int, default defaultValue: UInt64 = 0, hasBit: HasBit) -> UInt64 {
        guard isPresent(hasBit: hasBit) else { return defaultValue }
        return (buffer.baseAddress! + offset).bindMemory(to: UInt64.self, capacity: 1).pointee
    }

    /// Returns the `Float` value at the given offset in the storage, or the default value if the
    /// value is not present.
    @_alwaysEmitIntoClient @inline(__always)
    public func value(at offset: Int, default defaultValue: Float = 0, hasBit: HasBit) -> Float {
        guard isPresent(hasBit: hasBit) else { return defaultValue }
        return (buffer.baseAddress! + offset).bindMemory(to: Float.self, capacity: 1).pointee
    }

    /// Returns the `Double` value at the given offset in the storage, or the default value if the
    /// value is not present.
    @_alwaysEmitIntoClient @inline(__always)
    public func value(at offset: Int, default defaultValue: Double = 0, hasBit: HasBit) -> Double {
        guard isPresent(hasBit: hasBit) else { return defaultValue }
        return (buffer.baseAddress! + offset).bindMemory(to: Double.self, capacity: 1).pointee
    }

    /// Returns the string value at the given offset in the storage, or the default value if the
    /// value is not present.
    @_alwaysEmitIntoClient @inline(__always)
    public func value(at offset: Int, default defaultValue: String = "", hasBit: HasBit) -> String {
        guard isPresent(hasBit: hasBit) else { return defaultValue }
        return (buffer.baseAddress! + offset).bindMemory(to: String.self, capacity: 1).pointee
    }

    /// Returns the `Data` value at the given offset in the storage, or the default value if the
    /// value is not present.
    @_alwaysEmitIntoClient @inline(__always)
    public func value(at offset: Int, default defaultValue: Data = Data(), hasBit: HasBit) -> Data {
        guard isPresent(hasBit: hasBit) else { return defaultValue }
        return (buffer.baseAddress! + offset).bindMemory(to: Data.self, capacity: 1).pointee
    }

    /// Returns the `Array` value at the given offset in the storage, or the empty array if the
    /// value is not present.
    @_alwaysEmitIntoClient @inline(__always)
    public func value<Element>(at offset: Int, hasBit: HasBit) -> [Element] {
        guard isPresent(hasBit: hasBit) else { return [] }
        return (buffer.baseAddress! + offset).bindMemory(to: [Element].self, capacity: 1).pointee
    }

    /// Returns the `Dictionary` value at the given offset in the storage, or the empty array if
    /// the value is not present.
    @_alwaysEmitIntoClient @inline(__always)
    public func value<Key, Value>(at offset: Int, hasBit: HasBit) -> [Key: Value] {
        guard isPresent(hasBit: hasBit) else { return [:] }
        return (buffer.baseAddress! + offset).bindMemory(to: [Key: Value].self, capacity: 1).pointee
    }

    /// Returns the value at the given offset in the storage, or the default value if the value is
    /// not present.
    @_alwaysEmitIntoClient @inline(__always)
    public func value<T>(at offset: Int, default defaultValue: T, hasBit: HasBit) -> T {
        guard isPresent(hasBit: hasBit) else { return defaultValue }
        return (buffer.baseAddress! + offset).bindMemory(to: T.self, capacity: 1).pointee
    }
}

// MARK: - Field mutators

// As with the readers above, we have some concrete specializations of `updateValue` for trivial
// types, since they can just store the new value (whether it's zero or some other non-zero default)
// without managing any lifetimes.
//
// The generic implementation handles non-trivial cases, where we need to deinitialize an old value
// that's present and then decide what to do with the incoming state. If the field will be
// set/present, we store the new value; otherwise, we leave it uninitialized and zero it out.

extension _MessageStorage {
    /// Updates the `Bool` value at the given offset in the storage, along with its presence.
    @_alwaysEmitIntoClient @inline(__always)
    public func updateValue(at offset: Int, to newValue: Bool, willBeSet: Bool, hasBit: HasBit) {
        let pointer = (buffer.baseAddress! + offset).bindMemory(to: Bool.self, capacity: 1)
        _ = updatePresence(hasBit: hasBit, willBeSet: willBeSet)
        pointer.pointee = newValue
    }

    /// Updates the `Int32` value at the given offset in the storage, along with its presence.
    @_alwaysEmitIntoClient @inline(__always)
    public func updateValue(at offset: Int, to newValue: Int32, willBeSet: Bool, hasBit: HasBit) {
        let pointer = (buffer.baseAddress! + offset).bindMemory(to: Int32.self, capacity: 1)
        _ = updatePresence(hasBit: hasBit, willBeSet: willBeSet)
        pointer.pointee = newValue
    }

    /// Updates the `UInt32` value at the given offset in the storage, along with its presence.
    @_alwaysEmitIntoClient @inline(__always)
    public func updateValue(at offset: Int, to newValue: UInt32, willBeSet: Bool, hasBit: HasBit) {
        let pointer = (buffer.baseAddress! + offset).bindMemory(to: UInt32.self, capacity: 1)
        _ = updatePresence(hasBit: hasBit, willBeSet: willBeSet)
        pointer.pointee = newValue
    }

    /// Updates the `Int64` value at the given offset in the storage, along with its presence.
    @_alwaysEmitIntoClient @inline(__always)
    public func updateValue(at offset: Int, to newValue: Int64, willBeSet: Bool, hasBit: HasBit) {
        let pointer = (buffer.baseAddress! + offset).bindMemory(to: Int64.self, capacity: 1)
        _ = updatePresence(hasBit: hasBit, willBeSet: willBeSet)
        pointer.pointee = newValue
    }

    /// Updates the `UInt64` value at the given offset in the storage, along with its presence.
    @_alwaysEmitIntoClient @inline(__always)
    public func updateValue(at offset: Int, to newValue: UInt64, willBeSet: Bool, hasBit: HasBit) {
        let pointer = (buffer.baseAddress! + offset).bindMemory(to: UInt64.self, capacity: 1)
        _ = updatePresence(hasBit: hasBit, willBeSet: willBeSet)
        pointer.pointee = newValue
    }

    /// Updates the `Float` value at the given offset in the storage, along with its presence.
    @_alwaysEmitIntoClient @inline(__always)
    public func updateValue(at offset: Int, to newValue: Float, willBeSet: Bool, hasBit: HasBit) {
        let pointer = (buffer.baseAddress! + offset).bindMemory(to: Float.self, capacity: 1)
        _ = updatePresence(hasBit: hasBit, willBeSet: willBeSet)
        pointer.pointee = newValue
    }

    /// Updates the `Double` value at the given offset in the storage, along with its presence.
    @_alwaysEmitIntoClient @inline(__always)
    public func updateValue(at offset: Int, to newValue: Double, willBeSet: Bool, hasBit: HasBit) {
        let pointer = (buffer.baseAddress! + offset).bindMemory(to: Double.self, capacity: 1)
        _ = updatePresence(hasBit: hasBit, willBeSet: willBeSet)
        pointer.pointee = newValue
    }

    /// Updates the value at the given offset in the storage, along with its presence.
    @_alwaysEmitIntoClient @inline(__always)
    public func updateValue<T>(at offset: Int, to newValue: T, willBeSet: Bool, hasBit: HasBit) {
        let rawPointer = buffer.baseAddress! + offset
        let pointer = rawPointer.bindMemory(to: T.self, capacity: 1)
        let wasSet = updatePresence(hasBit: hasBit, willBeSet: willBeSet)
        if wasSet {
            pointer.deinitialize(count: 1)
        }
        if willBeSet {
            pointer.initialize(to: newValue)
        } else {
            rawPointer.withMemoryRebound(to: UInt8.self, capacity: MemoryLayout<T>.stride) { bytes in
                bytes.initialize(repeating: 0, count: MemoryLayout<T>.stride)
            }
        }
    }

    /// Clears the value at the given offset in the storage, along with its presence.
    @_alwaysEmitIntoClient @inline(__always)
    public func clearValue<T>(at offset: Int, type: T.Type, hasBit: HasBit) {
        let rawPointer = buffer.baseAddress! + offset
        let pointer = rawPointer.bindMemory(to: T.self, capacity: 1)
        let wasSet = updatePresence(hasBit: hasBit, willBeSet: false)
        if wasSet {
            pointer.deinitialize(count: 1)
        }
        rawPointer.withMemoryRebound(to: UInt8.self, capacity: MemoryLayout<T>.stride) { bytes in
            bytes.initialize(repeating: 0, count: MemoryLayout<T>.stride)
        }
    }

    // TODO: Implement accessors/mutators for remaining types:
    // - Submessages
    // - Enums
    // - Oneofs
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
