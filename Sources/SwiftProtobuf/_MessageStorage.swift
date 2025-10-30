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
    @usableFromInline let layout: _MessageLayout

    /// The memory buffer that contain's the data for the message's fields.
    @usableFromInline let buffer: UnsafeMutableRawBufferPointer

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
            deinitializeField(field)
        }
        buffer.deallocate()
    }

    /// Deinitializes the given field.
    @usableFromInline func deinitializeField(_ field: FieldLayout) {
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

    /// Deinitializes the field associated with the given concrete type information.
    public func deinitializeField<T>(_ field: FieldLayout, type: T.Type) {
        guard isPresent(field) else { return }
        (buffer.baseAddress! + field.offset).bindMemory(to: T.self, capacity: 1).deinitialize(count: 1)
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
    func isPresent(_ field: FieldLayout) -> Bool {
        switch field.presence {
        case .oneOfMember(let oneofOffset):
            return populatedOneofMember(at: oneofOffset) == field.fieldNumber
        case .hasBit(let byteOffset, let mask):
            return isPresent(hasBit: (byteOffset, mask))
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
        // the trivial ones here, instead tracking the byte offset of the first non-trivial field
        // so that we can bitwise copy those as a block afterward.
        var firstNontrivialStorageOffset = layout.size
        for field in layout.fields {
            switch field.fieldMode.cardinality {
            case .map:
                if field.offset < firstNontrivialStorageOffset {
                    firstNontrivialStorageOffset = field.offset
                }
                // TODO: Support map fields.
                break

            case .array:
                if field.offset < firstNontrivialStorageOffset {
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
                    if field.offset < firstNontrivialStorageOffset {
                        firstNontrivialStorageOffset = field.offset
                    }
                    copyField(field, to: destination, type: Data.self)

                case .group, .message:
                    if field.offset < firstNontrivialStorageOffset {
                        firstNontrivialStorageOffset = field.offset
                    }
                    layout.copySubmessage(
                        _MessageLayout.SubmessageToken(index: field.submessageIndex),
                        field,
                        self,
                        destination
                    )

                case .string:
                    if field.offset < firstNontrivialStorageOffset {
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

        // Copy all of the trivial field values, has-bits, and any oneof tracking in bitwise
        // fashion.
        destination.buffer.copyMemory(from: .init(rebasing: buffer[..<firstNontrivialStorageOffset]))

        destination.unknownFields = unknownFields
        // TODO: Handle extension fields.

        return destination
    }

    /// Copy-initializes the field associated with the given layout information in the destination
    /// storage using its value from this storage.
    public func copyField<T>(_ field: FieldLayout, to destination: _MessageStorage, type: T.Type) {
        guard isPresent(field) else { return }

        let sourcePointer = (buffer.baseAddress! + field.offset).bindMemory(to: T.self, capacity: 1)
        let destinationPointer = (destination.buffer.baseAddress! + field.offset).bindMemory(
            to: T.self,
            capacity: 1
        )
        destinationPointer.initialize(from: sourcePointer, count: 1)
    }
}

// MARK: - Non-specific submessage storage operations

extension _MessageStorage {
    /// Called by generated trampoline functions to invoke the given closure on the storage of a
    /// singular submessage, providing the type hint of the concrete message type.
    ///
    /// - Precondition: The field is already known to be present.
    ///
    /// - Returns: The value returned from the closure.
    public func performOnSubmessageStorage<T: _MessageImplementationBase>(
        of field: FieldLayout,
        type: T.Type,
        perform: (_MessageStorage) throws -> Bool
    ) rethrows -> Bool {
        let submessage = (buffer.baseAddress! + field.offset).bindMemory(to: T.self, capacity: 1).pointee
        return try perform(submessage.storageForRuntime)
    }

    /// Called by generated trampoline functions to invoke the given closure on the storage of each
    /// submessage in a repeated field, providing the type hint of the concrete message type.
    ///
    /// The closure can return false to stop iteration over the submessages early. Likewise, if the
    /// closure throws an error, that error will be propagated all the way to the caller.
    ///
    /// - Precondition: The field is already known to be present.
    ///
    /// - Returns: The value returned from the last invocation of the closure.
    public func performOnSubmessageStorage<T: _MessageImplementationBase>(
        of field: FieldLayout,
        type: [T].Type,
        perform: (_MessageStorage) throws -> Bool
    ) rethrows -> Bool {
        let submessages = (buffer.baseAddress! + field.offset).bindMemory(to: [T].self, capacity: 1).pointee
        for submessage in submessages {
            guard try perform(submessage.storageForRuntime) else { return false }
        }
        return true
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

// MARK: - Field readers used during encoding

extension _MessageStorage {
    /// Returns the value at the given offset in the storage.
    ///
    /// - Precondition: The value must already be known to be present.
    @_alwaysEmitIntoClient @inline(__always)
    func assumedPresentValue<Value>(at offset: Int, as type: Value.Type = Value.self) -> Value {
        (buffer.baseAddress! + offset).bindMemory(to: Value.self, capacity: 1).pointee
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
// code for accessors than one that would have to extract the same information from a `FieldLayout`.

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
    // - Enums
}

// MARK: - Field mutators used for parsing and reflection APIs

// Unlike the above APIs, these only take a `FieldLayout` as an argument. These are used when
// parsing messages and in reflection APIs, where we don't already know at generation time (as we
// do for accessors) the nature of the field's explicit presence (or lack of it).

extension _MessageStorage {
    /// Updates the `Bool` value of the given field, tracking its presence accordingly.
    func updateValue(of field: FieldLayout, to newValue: Bool) {
        let offset = field.offset
        switch field.presence {
        case .hasBit(let hasByteOffset, let hasMask):
            updateValue(
                at: offset,
                to: newValue,
                willBeSet: layout.fieldHasPresence(field) ? true : newValue,
                hasBit: (hasByteOffset, hasMask)
            )
        case .oneOfMember(let oneofOffset):
            updateValue(at: offset, to: newValue, oneofPresence: (oneofOffset, field.fieldNumber))
        }
    }

    /// Updates the `Int32` value of the given field, tracking its presence accordingly.
    func updateValue(of field: FieldLayout, to newValue: Int32) {
        let offset = field.offset
        switch field.presence {
        case .hasBit(let hasByteOffset, let hasMask):
            updateValue(
                at: offset,
                to: newValue,
                willBeSet: layout.fieldHasPresence(field) ? true : (newValue != 0),
                hasBit: (hasByteOffset, hasMask)
            )
        case .oneOfMember(let oneofOffset):
            updateValue(at: offset, to: newValue, oneofPresence: (oneofOffset, field.fieldNumber))
        }
    }

    /// Updates the `UInt32` value of the given field, tracking its presence accordingly.
    func updateValue(of field: FieldLayout, to newValue: UInt32) {
        let offset = field.offset
        switch field.presence {
        case .hasBit(let hasByteOffset, let hasMask):
            updateValue(
                at: offset,
                to: newValue,
                willBeSet: layout.fieldHasPresence(field) ? true : (newValue != 0),
                hasBit: (hasByteOffset, hasMask)
            )
        case .oneOfMember(let oneofOffset):
            updateValue(at: offset, to: newValue, oneofPresence: (oneofOffset, field.fieldNumber))
        }
    }

    /// Updates the `Int64` value of the given field, tracking its presence accordingly.
    func updateValue(of field: FieldLayout, to newValue: Int64) {
        let offset = field.offset
        switch field.presence {
        case .hasBit(let hasByteOffset, let hasMask):
            updateValue(
                at: offset,
                to: newValue,
                willBeSet: layout.fieldHasPresence(field) ? true : (newValue != 0),
                hasBit: (hasByteOffset, hasMask)
            )
        case .oneOfMember(let oneofOffset):
            updateValue(at: offset, to: newValue, oneofPresence: (oneofOffset, field.fieldNumber))
        }
    }

    /// Updates the `UInt64` value of the given field, tracking its presence accordingly.
    func updateValue(of field: FieldLayout, to newValue: UInt64) {
        let offset = field.offset
        switch field.presence {
        case .hasBit(let hasByteOffset, let hasMask):
            updateValue(
                at: offset,
                to: newValue,
                willBeSet: layout.fieldHasPresence(field) ? true : (newValue != 0),
                hasBit: (hasByteOffset, hasMask)
            )
        case .oneOfMember(let oneofOffset):
            updateValue(at: offset, to: newValue, oneofPresence: (oneofOffset, field.fieldNumber))
        }
    }

    /// Updates the `Float` value of the given field, tracking its presence accordingly.
    func updateValue(of field: FieldLayout, to newValue: Float) {
        let offset = field.offset
        switch field.presence {
        case .hasBit(let hasByteOffset, let hasMask):
            updateValue(
                at: offset,
                to: newValue,
                willBeSet: layout.fieldHasPresence(field) ? true : (newValue != 0),
                hasBit: (hasByteOffset, hasMask)
            )
        case .oneOfMember(let oneofOffset):
            updateValue(at: offset, to: newValue, oneofPresence: (oneofOffset, field.fieldNumber))
        }
    }

    /// Updates the `Double` value of the given field, tracking its presence accordingly.
    func updateValue(of field: FieldLayout, to newValue: Double) {
        let offset = field.offset
        switch field.presence {
        case .hasBit(let hasByteOffset, let hasMask):
            updateValue(
                at: offset,
                to: newValue,
                willBeSet: layout.fieldHasPresence(field) ? true : (newValue != 0),
                hasBit: (hasByteOffset, hasMask)
            )
        case .oneOfMember(let oneofOffset):
            updateValue(at: offset, to: newValue, oneofPresence: (oneofOffset, field.fieldNumber))
        }
    }

    /// Updates the `String` value of the given field, tracking its presence accordingly.
    func updateValue(of field: FieldLayout, to newValue: String) {
        let offset = field.offset
        switch field.presence {
        case .hasBit(let hasByteOffset, let hasMask):
            updateValue(
                at: offset,
                to: newValue,
                willBeSet: layout.fieldHasPresence(field) ? true : !newValue.isEmpty,
                hasBit: (hasByteOffset, hasMask)
            )
        case .oneOfMember(let oneofOffset):
            updateValue(at: offset, to: newValue, oneofPresence: (oneofOffset, field.fieldNumber))
        }
    }

    /// Updates the `Data` value of the given field, tracking its presence accordingly.
    func updateValue(of field: FieldLayout, to newValue: Data) {
        let offset = field.offset
        switch field.presence {
        case .hasBit(let hasByteOffset, let hasMask):
            updateValue(
                at: offset,
                to: newValue,
                willBeSet: layout.fieldHasPresence(field) ? true : !newValue.isEmpty,
                hasBit: (hasByteOffset, hasMask)
            )
        case .oneOfMember(let oneofOffset):
            updateValue(at: offset, to: newValue, oneofPresence: (oneofOffset, field.fieldNumber))
        }
    }
}

// MARK: - Oneof support

extension _MessageStorage {
    /// Describes presence information that is used when getting or setting oneof members.
    public typealias OneofPresence = (offset: Int, fieldNumber: UInt32)

    /// Returns the field number of the oneof member that is populated, given the oneof offset into
    /// the storage buffer.
    @_alwaysEmitIntoClient @inline(__always)
    public func populatedOneofMember(at oneofOffset: Int) -> UInt32 {
        (buffer.baseAddress! + oneofOffset).bindMemory(to: UInt32.self, capacity: 1).pointee
    }

    /// Updates the field number of the oneof member that is populated, given the oneof offset into
    /// the storage buffer, and returns the field number of the previously set member (or zero if
    /// none was set).
    @_alwaysEmitIntoClient @inline(__always)
    public func updatePopulatedOneofMember(_ presence: OneofPresence) -> UInt32 {
        let offsetPointer = (buffer.baseAddress! + presence.offset).bindMemory(to: UInt32.self, capacity: 1)
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
        return (buffer.baseAddress! + offset).bindMemory(to: Bool.self, capacity: 1).pointee
    }

    /// Returns the `Int32` value at the given offset in the storage if it is the currently
    /// populated member of its containing oneof, or the default value otherwise.
    @_alwaysEmitIntoClient @inline(__always)
    public func value(at offset: Int, default defaultValue: Int32 = 0, oneofPresence: OneofPresence) -> Int32 {
        guard populatedOneofMember(at: oneofPresence.offset) == oneofPresence.fieldNumber else {
            return defaultValue
        }
        return (buffer.baseAddress! + offset).bindMemory(to: Int32.self, capacity: 1).pointee
    }

    /// Returns the `UInt32` value at the given offset in the storage if it is the currently
    /// populated member of its containing oneof, or the default value otherwise.
    @_alwaysEmitIntoClient @inline(__always)
    public func value(at offset: Int, default defaultValue: UInt32 = 0, oneofPresence: OneofPresence) -> UInt32 {
        guard populatedOneofMember(at: oneofPresence.offset) == oneofPresence.fieldNumber else {
            return defaultValue
        }
        return (buffer.baseAddress! + offset).bindMemory(to: UInt32.self, capacity: 1).pointee
    }

    /// Returns the `Int64` value at the given offset in the storage if it is the currently
    /// populated member of its containing oneof, or the default value otherwise.
    @_alwaysEmitIntoClient @inline(__always)
    public func value(at offset: Int, default defaultValue: Int64 = 0, oneofPresence: OneofPresence) -> Int64 {
        guard populatedOneofMember(at: oneofPresence.offset) == oneofPresence.fieldNumber else {
            return defaultValue
        }
        return (buffer.baseAddress! + offset).bindMemory(to: Int64.self, capacity: 1).pointee
    }

    /// Returns the `UInt64` value at the given offset in the storage if it is the currently
    /// populated member of its containing oneof, or the default value otherwise.
    @_alwaysEmitIntoClient @inline(__always)
    public func value(at offset: Int, default defaultValue: UInt64 = 0, oneofPresence: OneofPresence) -> UInt64 {
        guard populatedOneofMember(at: oneofPresence.offset) == oneofPresence.fieldNumber else {
            return defaultValue
        }
        return (buffer.baseAddress! + offset).bindMemory(to: UInt64.self, capacity: 1).pointee
    }

    /// Returns the `Float` value at the given offset in the storage if it is the currently
    /// populated member of its containing oneof, or the default value otherwise.
    @_alwaysEmitIntoClient @inline(__always)
    public func value(at offset: Int, default defaultValue: Float = 0, oneofPresence: OneofPresence) -> Float {
        guard populatedOneofMember(at: oneofPresence.offset) == oneofPresence.fieldNumber else {
            return defaultValue
        }
        return (buffer.baseAddress! + offset).bindMemory(to: Float.self, capacity: 1).pointee
    }

    /// Returns the `Double` value at the given offset in the storage if it is the currently
    /// populated member of its containing oneof, or the default value otherwise.
    @_alwaysEmitIntoClient @inline(__always)
    public func value(at offset: Int, default defaultValue: Double = 0, oneofPresence: OneofPresence) -> Double {
        guard populatedOneofMember(at: oneofPresence.offset) == oneofPresence.fieldNumber else {
            return defaultValue
        }
        return (buffer.baseAddress! + offset).bindMemory(to: Double.self, capacity: 1).pointee
    }

    /// Returns the `String` value at the given offset in the storage if it is the currently
    /// populated member of its containing oneof, or the default value otherwise.
    @_alwaysEmitIntoClient @inline(__always)
    public func value(at offset: Int, default defaultValue: String = "", oneofPresence: OneofPresence) -> String {
        guard populatedOneofMember(at: oneofPresence.offset) == oneofPresence.fieldNumber else {
            return defaultValue
        }
        return (buffer.baseAddress! + offset).bindMemory(to: String.self, capacity: 1).pointee
    }

    /// Returns the `Data` value at the given offset in the storage if it is the currently
    /// populated member of its containing oneof, or the default value otherwise.
    @_alwaysEmitIntoClient @inline(__always)
    public func value(at offset: Int, default defaultValue: Data = Data(), oneofPresence: OneofPresence) -> Data {
        guard populatedOneofMember(at: oneofPresence.offset) == oneofPresence.fieldNumber else {
            return defaultValue
        }
        return (buffer.baseAddress! + offset).bindMemory(to: Data.self, capacity: 1).pointee
    }

    /// Returns the value at the given offset in the storage if it is the currently populated
    /// member of its containing oneof, or the default value otherwise.
    @_alwaysEmitIntoClient @inline(__always)
    public func value<T>(at offset: Int, default defaultValue: T, oneofPresence: OneofPresence) -> T {
        guard populatedOneofMember(at: oneofPresence.offset) == oneofPresence.fieldNumber else {
            return defaultValue
        }
        return (buffer.baseAddress! + offset).bindMemory(to: T.self, capacity: 1).pointee
    }

    /// Updates the `Bool` value at the given offset in the storage, along with its presence.
    @_alwaysEmitIntoClient @inline(__always)
    public func updateValue(at offset: Int, to newValue: Bool, oneofPresence: OneofPresence) {
        let rawPointer = buffer.baseAddress! + offset
        let oldFieldNumber = updatePopulatedOneofMember(oneofPresence)
        if oldFieldNumber != 0 {
            // We can force-unwrap this because the field must exist or it would be a generator bug.
            deinitializeOneofMember(layout[fieldNumber: oldFieldNumber]!)
        }
        rawPointer.bindMemory(to: Bool.self, capacity: 1).pointee = newValue
    }

    /// Updates the `Int32` value at the given offset in the storage, along with its presence.
    @_alwaysEmitIntoClient @inline(__always)
    public func updateValue(at offset: Int, to newValue: Int32, oneofPresence: OneofPresence) {
        let oldFieldNumber = updatePopulatedOneofMember(oneofPresence)
        if oldFieldNumber != 0 {
            // We can force-unwrap this because the field must exist or it would be a generator bug.
            deinitializeOneofMember(layout[fieldNumber: oldFieldNumber]!)
        }
        (buffer.baseAddress! + offset).bindMemory(to: Int32.self, capacity: 1).pointee = newValue
    }

    /// Updates the `UInt32` value at the given offset in the storage, along with its presence.
    @_alwaysEmitIntoClient @inline(__always)
    public func updateValue(at offset: Int, to newValue: UInt32, oneofPresence: OneofPresence) {
        let oldFieldNumber = updatePopulatedOneofMember(oneofPresence)
        if oldFieldNumber != 0 {
            // We can force-unwrap this because the field must exist or it would be a generator bug.
            deinitializeOneofMember(layout[fieldNumber: oldFieldNumber]!)
        }
        (buffer.baseAddress! + offset).bindMemory(to: UInt32.self, capacity: 1).pointee = newValue
    }

    /// Updates the `Int64` value at the given offset in the storage, along with its presence.
    @_alwaysEmitIntoClient @inline(__always)
    public func updateValue(at offset: Int, to newValue: Int64, oneofPresence: OneofPresence) {
        let oldFieldNumber = updatePopulatedOneofMember(oneofPresence)
        if oldFieldNumber != 0 {
            // We can force-unwrap this because the field must exist or it would be a generator bug.
            deinitializeOneofMember(layout[fieldNumber: oldFieldNumber]!)
        }
        (buffer.baseAddress! + offset).bindMemory(to: Int64.self, capacity: 1).pointee = newValue
    }

    /// Updates the `UInt64` value at the given offset in the storage, along with its presence.
    @_alwaysEmitIntoClient @inline(__always)
    public func updateValue(at offset: Int, to newValue: UInt64, oneofPresence: OneofPresence) {
        let oldFieldNumber = updatePopulatedOneofMember(oneofPresence)
        if oldFieldNumber != 0 {
            // We can force-unwrap this because the field must exist or it would be a generator bug.
            deinitializeOneofMember(layout[fieldNumber: oldFieldNumber]!)
        }
        (buffer.baseAddress! + offset).bindMemory(to: UInt64.self, capacity: 1).pointee = newValue
    }

    /// Updates the `Float` value at the given offset in the storage, along with its presence.
    @_alwaysEmitIntoClient @inline(__always)
    public func updateValue(at offset: Int, to newValue: Float, oneofPresence: OneofPresence) {
        let oldFieldNumber = updatePopulatedOneofMember(oneofPresence)
        if oldFieldNumber != 0 {
            // We can force-unwrap this because the field must exist or it would be a generator bug.
            deinitializeOneofMember(layout[fieldNumber: oldFieldNumber]!)
        }
        (buffer.baseAddress! + offset).bindMemory(to: Float.self, capacity: 1).pointee = newValue
    }

    /// Updates the `Double` value at the given offset in the storage, along with its presence.
    @_alwaysEmitIntoClient @inline(__always)
    public func updateValue(at offset: Int, to newValue: Double, oneofPresence: OneofPresence) {
        let oldFieldNumber = updatePopulatedOneofMember(oneofPresence)
        if oldFieldNumber != 0 {
            // We can force-unwrap this because the field must exist or it would be a generator bug.
            deinitializeOneofMember(layout[fieldNumber: oldFieldNumber]!)
        }
        (buffer.baseAddress! + offset).bindMemory(to: Double.self, capacity: 1).pointee = newValue
    }

    /// Updates the value at the given offset in the storage, along with its presence.
    @_alwaysEmitIntoClient @inline(__always)
    public func updateValue<T>(at offset: Int, to newValue: T, oneofPresence: OneofPresence) {
        let oldFieldNumber = updatePopulatedOneofMember(oneofPresence)
        if oldFieldNumber != 0 {
            // We can force-unwrap this because the field must exist or it would be a generator bug.
            deinitializeOneofMember(layout[fieldNumber: oldFieldNumber]!)
        }
        (buffer.baseAddress! + offset).bindMemory(to: T.self, capacity: 1).initialize(to: newValue)
    }

    /// Clears the populated oneof member give the oneof offset into the storage buffer,
    /// deinitializing any existing value if necessary.
    @_alwaysEmitIntoClient @inline(__always)
    public func clearPopulatedOneofMember(at oneofOffset: Int) {
        let oldFieldNumber = updatePopulatedOneofMember((offset: oneofOffset, fieldNumber: 0))
        guard oldFieldNumber != 0 else { return }
        // We can force-unwrap this because the field must exist or it would be a generator bug.
        deinitializeOneofMember(layout[fieldNumber: oldFieldNumber]!)
    }

    /// Deinitializes the value for the given field that is a oneof member and zeros out the
    /// storage slot.
    ///
    /// - Precondition: The value associated with this field must be initialized.
    @_alwaysEmitIntoClient @inline(__always)
    private func deinitializeOneofMember(_ field: FieldLayout) {
        // TODO: We could skip zeroing out the backing storage if this is part of a mutation that
        // is setting the same member that's being deinitialized. Determine if that's a worthwhile
        // optimization.
        deinitializeField(field)
        let stride = field.scalarStride
        (buffer.baseAddress! + field.offset).withMemoryRebound(to: UInt8.self, capacity: stride) { bytes in
            bytes.initialize(repeating: 0, count: stride)
        }
    }
}

// MARK: - Message equality

extension _MessageStorage {
    /// Tests this message storage for equality with the other storage.
    ///
    /// Precondition: Both instances of storage are assumed to be represented by the same message
    /// type.
    ///
    /// Message equality in SwiftProtobuf includes presence. That is, a message with an integer
    /// field set to 100 is not considered equal to one where that field is not present but has a
    /// default defined to be 100.
    @inline(never)
    public func isEqual(to other: _MessageStorage) -> Bool {
        if self === other {
            /// Identical message storage means they must be equal.
            return true
        }
        // TODO: If we store the offset of the first non-trivial field in the layout, we can make
        // this extremely fast by doing the memcmp up front and failing fast. Likewise, we can also
        // avoid the loop entirely if the message contains only trivial fields. We could see similar
        // performance wins for copy and deinit.

        // Loops through the fields, checking equality of any that are non-trivial types. We ignore
        // the trivial ones here, instead tracking the byte offset of the first non-trivial field
        // so that we can bitwise-compare those as a block afterward.
        var firstNontrivialStorageOffset = layout.size
        var equalSoFar = true
        for field in layout.fields {
            switch field.fieldMode.cardinality {
            case .map:
                if field.offset < firstNontrivialStorageOffset {
                    firstNontrivialStorageOffset = field.offset
                }
                // TODO: Support map fields.
                break

            case .array:
                if field.offset < firstNontrivialStorageOffset {
                    firstNontrivialStorageOffset = field.offset
                }
                switch field.rawFieldType {
                case .bool:
                    equalSoFar = isField(field, equalToSameFieldIn: other, type: [Bool].self)
                case .bytes:
                    equalSoFar = isField(field, equalToSameFieldIn: other, type: [Data].self)
                case .double:
                    equalSoFar = isField(field, equalToSameFieldIn: other, type: [Double].self)
                case .enum:
                    // TODO: Figure out how we represent enums (open vs. closed).
                    break
                case .fixed32, .uint32:
                    equalSoFar = isField(field, equalToSameFieldIn: other, type: [UInt32].self)
                case .fixed64, .uint64:
                    equalSoFar = isField(field, equalToSameFieldIn: other, type: [UInt64].self)
                case .float:
                    equalSoFar = isField(field, equalToSameFieldIn: other, type: [Float].self)
                case .group, .message:
                    equalSoFar = layout.areSubmessagesEqual(
                        _MessageLayout.SubmessageToken(index: field.submessageIndex),
                        field,
                        self,
                        other
                    )
                case .int32, .sfixed32, .sint32:
                    equalSoFar = isField(field, equalToSameFieldIn: other, type: [Int32].self)
                case .int64, .sfixed64, .sint64:
                    equalSoFar = isField(field, equalToSameFieldIn: other, type: [Int64].self)
                case .string:
                    equalSoFar = isField(field, equalToSameFieldIn: other, type: [String].self)
                default:
                    preconditionFailure("Unreachable")
                }

            case .scalar:
                switch field.rawFieldType {
                case .bytes:
                    if field.offset < firstNontrivialStorageOffset {
                        firstNontrivialStorageOffset = field.offset
                    }
                    equalSoFar = isField(field, equalToSameFieldIn: other, type: Data.self)

                case .group, .message:
                    if field.offset < firstNontrivialStorageOffset {
                        firstNontrivialStorageOffset = field.offset
                    }
                    equalSoFar = layout.areSubmessagesEqual(
                        _MessageLayout.SubmessageToken(index: field.submessageIndex),
                        field,
                        self,
                        other
                    )

                case .string:
                    if field.offset < firstNontrivialStorageOffset {
                        firstNontrivialStorageOffset = field.offset
                    }
                    equalSoFar = isField(field, equalToSameFieldIn: other, type: String.self)

                default:
                    // Do nothing. Trivial fields will be bitwise-compared as a block below.
                    break
                }

            default:
                preconditionFailure("Unreachable")
            }

            guard equalSoFar else {
                return false
            }
        }

        // Compare all of the trivial values (including has-bits) in bitwise fashion.
        if firstNontrivialStorageOffset != 0 {
            return memcmp(buffer.baseAddress!, other.buffer.baseAddress!, firstNontrivialStorageOffset) == 0
        }
        return true
    }

    /// Returns whether the given field in the receiver is equal to the same field in the other
    /// storage, given the expected type of that field.
    public func isField<T: Equatable>(
        _ field: FieldLayout,
        equalToSameFieldIn other: _MessageStorage,
        type: T.Type
    ) -> Bool {
        let isSelfPresent = isPresent(field)
        let isOtherPresent = other.isPresent(field)
        guard isSelfPresent && isOtherPresent else {
            // If the field isn't present in both messages, then it must be absent in both to be
            // considered equal.
            return isSelfPresent == isOtherPresent
        }
        // The field is present in both messages, so compare their values.
        let selfPointer = (buffer.baseAddress! + field.offset).bindMemory(to: T.self, capacity: 1)
        let otherPointer = (other.buffer.baseAddress! + field.offset).bindMemory(to: T.self, capacity: 1)
        return selfPointer.pointee == otherPointer.pointee
    }
}

// MARK: - Message initialized (i.e., required fields) check

extension _MessageStorage {
    /// Indicates whether all required fields are present in this message.
    ///
    /// This is a shallow check; it does not recurse into submessages to check their initialized
    /// state.
    @inline(never)
    private var isMessageInitializedShallow: Bool {
        // A message with no required fields is trivially considered initialized.
        guard layout.requiredCount > 0 else { return true }

        // The has-bits for the required fields have been ordered first in storage, so we can
        // quickly determine whether a message is initialzed using a simple `memcmp` (with at most
        // one additional masked byte comparison for overflow bits).
        let requiredByteCount = layout.requiredCount / 8
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
        let remainingBits = UInt8(layout.requiredCount & 7)
        guard remainingBits != 0 else { return true }

        let remainingMask: UInt8 = (1 << remainingBits) - 1
        return buffer[requiredByteCount] & remainingMask == remainingMask
    }

    /// Indicates whether all required fields are present in this message, recursively checking
    /// submessages.
    public var isInitialized: Bool {
        guard isMessageInitializedShallow else { return false }

        for field in layout.fields {
            switch field.rawFieldType {
            case .message, .group:
                guard isPresent(field) else {
                    // If the submessage is not present, check if it's required. If it is, then
                    // we're not initialized; otherwise, we can skip to the next field.
                    if layout.isFieldRequired(field) {
                        return false
                    }
                    continue
                }

                // This never actually throws because the closure cannot throw, but closures cannot
                // be declared rethrows..
                let isSubmessageInitialized = try! layout.performOnSubmessageStorage(
                    _MessageLayout.SubmessageToken(index: field.submessageIndex),
                    field,
                    self
                ) { $0.isInitialized }
                guard isSubmessageInitialized else { return false }

            default:
                // Nothing to do for other types of fields; they've already been considered by the
                // shallow check.
                break
            }
        }
        // TODO: Check extension fields.
        return true
    }

    /// Returns whether the given field in the receiver, which must be another message type, is
    /// initialized (recursively).
    public func isFieldInitialized<T: Message>(_ field: FieldLayout, type: T.Type) -> Bool {
        (buffer.baseAddress! + field.offset).bindMemory(to: T.self, capacity: 1).pointee.isInitialized
    }

    /// Returns whether the given field in the receiver, which must be an array of a message type,
    /// is initialized (recursively).
    public func isFieldInitialized<T: Message>(_ field: FieldLayout, type: [T].Type) -> Bool {
        (buffer.baseAddress! + field.offset).bindMemory(to: [T].self, capacity: 1).pointee.allSatisfy {
            $0.isInitialized
        }
    }
}

/// A token that allows the runtime to access the underlying storage of a message.
///
/// This type is public because the runtime must be able to generically access the underlying
/// storage of a message, so a protocol requirement on `_MessageImplementationBase` is provided that
/// takes a value of this type as an argument. However, only the runtime may create instances of it.
public struct _MessageStorageToken {
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
