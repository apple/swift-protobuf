// Sources/SwiftProtobuf/ExtensionValueStorage.swift - Storage for a single extension field
//
// Copyright (c) 2014 - 2026 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// The storage for a single extension field in a message.
///
// -----------------------------------------------------------------------------

/// The storage for a single extension field in a message.
///
/// This can be thought of as a miniature version of `_MessageStorage`, but which only holds the
/// value for a single field. Just as `_MessageStorage` is self-describing (it contains its own
/// `_MessageLayout`), each extension value is self-describing (it contains its own
/// `_MessageExtension`).
///
/// Ideally this would be `~Copyable`, but we store these in a `Dictionary` so we can't use
/// non-copyable types as values yet. These values don't need to be and should not be shared, nor
/// should they escape the owning `ExtensionStorage`, so they provide some low-level unsafe pointer
/// APIs that would otherwise be dangerous. The owning `ExtensionStorage` is fully responsible for
/// deallocating these values.
@usableFromInline struct ExtensionValueStorage {
    /// The message extension that this field represents.
    @usableFromInline let schema: ExtensionSchema

    /// The storage for the value.
    ///
    /// POD types (`bool`, integers, floating point values) are stored inline. Enums are stored as
    /// their `Int32` raw value, also inline. Non-POD types (strings, data, repeated fields) are
    /// copied into a single-element heap-allocated block and the bit pattern of the pointer to
    /// that block is stored here.
    @usableFromInline let storage: UInt64

    /// Creates a new extension storage value for the given `Bool` value.
    @_alwaysEmitIntoClient @inline(__always)
    init(schema: ExtensionSchema, value: Bool) {
        self.schema = schema
        self.storage = value ? 1 : 0
    }

    /// Creates a new extension storage value for the given `Int64` value.
    @_alwaysEmitIntoClient @inline(__always)
    init(schema: ExtensionSchema, value: Int64) {
        self.schema = schema
        self.storage = .init(bitPattern: value)
    }

    /// Creates a new extension storage value for the given `UInt64` value.
    @_alwaysEmitIntoClient @inline(__always)
    init(schema: ExtensionSchema, value: UInt64) {
        self.schema = schema
        self.storage = value
    }

    /// Creates a new extension storage value for the given `Int32` value.
    @_alwaysEmitIntoClient @inline(__always)
    init(schema: ExtensionSchema, value: Int32) {
        self.schema = schema
        self.storage = .init(bitPattern: Int64(value))
    }

    /// Creates a new extension storage value for the given `UInt32` value.
    @_alwaysEmitIntoClient @inline(__always)
    init(schema: ExtensionSchema, value: UInt32) {
        self.schema = schema
        self.storage = UInt64(value)
    }

    /// Creates a new extension storage value for the given `Float` value.
    @_alwaysEmitIntoClient @inline(__always)
    init(schema: ExtensionSchema, value: Float) {
        self.schema = schema
        self.storage = UInt64(value.bitPattern)
    }

    /// Creates a new extension storage value for the given `Double` value.
    @_alwaysEmitIntoClient @inline(__always)
    init(schema: ExtensionSchema, value: Double) {
        self.schema = schema
        self.storage = value.bitPattern
    }

    /// Creates a new extension storage value for the given non-POD value (string, data, repeated
    /// fields).
    @_alwaysEmitIntoClient @inline(__always)
    init<Value>(schema: ExtensionSchema, value: Value) {
        self.schema = schema
        let typedStorage = UnsafeMutablePointer<Value>.allocate(capacity: 1)
        typedStorage.initialize(to: value)
        self.storage = UInt64(UInt(bitPattern: typedStorage))
    }

    /// Deinitializes the stored value in the receiver and then deallocates its heap storage.
    ///
    /// - Precondition: This must only be called on values for which `storage` is a pointer to
    ///   heap-allocated storage.
    @_alwaysEmitIntoClient @inline(__always)
    func release<Value>(type: Value.Type) {
        let pointer = UnsafeMutablePointer<Value>(bitPattern: Int(truncatingIfNeeded: Int64(bitPattern: storage)))!
        pointer.deinitialize(count: 1)
        pointer.deallocate()
    }

    /// Returns the value of the extension field, assuming it is a `Bool`.
    @_alwaysEmitIntoClient @inline(__always)
    func value(as type: Bool.Type) -> Bool {
        storage != 0
    }

    /// Returns the value of the extension field, assuming it is an `Int64`.
    @_alwaysEmitIntoClient @inline(__always)
    func value(as type: Int64.Type) -> Int64 {
        Int64(bitPattern: storage)
    }

    /// Returns the value of the extension field, assuming it is a `UInt64`.
    @_alwaysEmitIntoClient @inline(__always)
    func value(as type: UInt64.Type) -> UInt64 {
        storage
    }

    /// Returns the value of the extension field, assuming it is an `Int32`.
    @_alwaysEmitIntoClient @inline(__always)
    func value(as type: Int32.Type) -> Int32 {
        Int32(truncatingIfNeeded: Int64(bitPattern: storage))
    }

    /// Returns the value of the extension field, assuming it is a `UInt32`.
    @_alwaysEmitIntoClient @inline(__always)
    func value(as type: UInt32.Type) -> UInt32 {
        UInt32(truncatingIfNeeded: storage)
    }

    /// Returns the value of the extension field, assuming it is a `Float`.
    @_alwaysEmitIntoClient @inline(__always)
    func value(as type: Float.Type) -> Float {
        Float(bitPattern: UInt32(truncatingIfNeeded: storage))
    }

    /// Returns the value of the extension field, assuming it is a `Double`.
    @_alwaysEmitIntoClient @inline(__always)
    func value(as type: Double.Type) -> Double {
        Double(bitPattern: storage)
    }

    /// Returns the value of the extension field, assuming it is a heap-allocated non-POD type.
    @_alwaysEmitIntoClient @inline(__always)
    func value<Value>(as type: Value.Type) -> Value {
        UnsafePointer<Value>(bitPattern: Int(truncatingIfNeeded: Int64(bitPattern: storage)))!.pointee
    }

    /// Returns the pointer to the value of the extension field, assuming it is a heap-allocated
    /// non-POD type.
    ///
    /// The returned pointer must not escape the `ExtensionStorage` that owns it.
    @_alwaysEmitIntoClient @inline(__always)
    func unsafePointerToValue<Value>(as type: Value.Type) -> UnsafePointer<Value> {
        UnsafePointer<Value>(bitPattern: Int(truncatingIfNeeded: Int64(bitPattern: storage)))!
    }

    /// Returns the mutable pointer to the value of the extension field, assuming it is a
    /// heap-allocated non-POD type.
    ///
    /// The returned pointer must not escape the `ExtensionStorage` that owns it.
    @_alwaysEmitIntoClient @inline(__always)
    func unsafeMutablePointerToValue<Value>(as type: Value.Type) -> UnsafeMutablePointer<Value> {
        UnsafeMutablePointer<Value>(bitPattern: Int(truncatingIfNeeded: Int64(bitPattern: storage)))!
    }

    /// Ensures that the storage of the extension field's submessage value is unique and returns the
    /// pointer to the message.
    ///
    /// The returned pointer must not escape the `ExtensionStorage` that owns it.
    ///
    /// - Precondition: The type of the extension field must be a message or group.
    func unsafePointerToSubmessageWithUniqueStorage<Value: _MessageImplementationBase>(
        as type: Value.Type,
    ) -> UnsafeMutablePointer<Value> {
        let pointer = UnsafeMutablePointer<Value>(bitPattern: Int(truncatingIfNeeded: Int64(bitPattern: storage)))!
        pointer.pointee._protobuf_ensureUniqueStorage(accessToken: _MessageStorageToken())
        return pointer
    }
}
