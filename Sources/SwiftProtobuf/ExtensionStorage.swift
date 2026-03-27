// Sources/SwiftProtobuf/ExtensionStorage.swift - Storage for a message's extension fields
//
// Copyright (c) 2014 - 2026 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Manages the storage of and access to all extension fields in a message.
///
// -----------------------------------------------------------------------------

import Foundation

/// The storage for all of the extension fields in a message.
///
/// This class is not thread-safe; it contains mutable state. It is the responsibility of the
/// CoW message that owns it to ensure that a deep copy is made before any mutating operation.
@_spi(ForGeneratedCodeOnly)
public final class ExtensionStorage {
    /// The stored values of the extension fields.
    @usableFromInline var values: [UInt32: ExtensionValueStorage] = [:]

    deinit {
        for (_, value) in values {
            let ext = value.schema
            let field = ext.field
            switch field.fieldMode.cardinality {
            case .map:
                preconditionFailure("Unreachable")

            case .array:
                switch field.rawFieldType {
                case .bool: value.release(type: [Bool].self)
                case .bytes: value.release(type: [Data].self)
                case .double: value.release(type: [Double].self)
                case .enum, .group, .message:
                    _ = ext.performNontrivialExtensionOperation(
                        .deinitialize,
                        ext,
                        self
                    )
                case .fixed32, .uint32: value.release(type: [UInt32].self)
                case .fixed64, .uint64: value.release(type: [UInt64].self)
                case .float: value.release(type: [Float].self)
                case .int32, .sfixed32, .sint32: value.release(type: [Int32].self)
                case .int64, .sfixed64, .sint64: value.release(type: [Int64].self)
                case .string: value.release(type: [String].self)
                default: preconditionFailure("Unreachable")
                }

            case .scalar:
                switch field.rawFieldType {
                case .bytes: value.release(type: Data.self)
                case .string: value.release(type: String.self)
                case .group, .message:
                    _ = ext.performNontrivialExtensionOperation(
                        .deinitialize,
                        ext,
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
    }

    @inline(never)
    func copy() -> ExtensionStorage {
        let destination = ExtensionStorage()
        for (fieldNumber, value) in values {
            let ext = value.schema
            let field = ext.field

            // We manipulate the destination dictionary directly here instead of using `updateValue`
            // because we don't need the overhead of checking for existing values in a newly created
            // storage.
            switch field.fieldMode.cardinality {
            case .map:
                preconditionFailure("Unreachable")

            case .array:
                switch field.rawFieldType {
                case .bool:
                    destination.values[fieldNumber] = .init(schema: ext, value: value.value(as: [Bool].self))
                case .bytes:
                    destination.values[fieldNumber] = .init(schema: ext, value: value.value(as: [Data].self))
                case .double:
                    destination.values[fieldNumber] = .init(schema: ext, value: value.value(as: [Double].self))
                case .enum, .group, .message:
                    _ = ext.performNontrivialExtensionOperation(
                        .copy(destination: destination),
                        ext,
                        self
                    )
                case .fixed32, .uint32:
                    destination.values[fieldNumber] = .init(schema: ext, value: value.value(as: [UInt32].self))
                case .fixed64, .uint64:
                    destination.values[fieldNumber] = .init(schema: ext, value: value.value(as: [UInt64].self))
                case .float:
                    destination.values[fieldNumber] = .init(schema: ext, value: value.value(as: [Float].self))
                case .int32, .sfixed32, .sint32:
                    destination.values[fieldNumber] = .init(schema: ext, value: value.value(as: [Int32].self))
                case .int64, .sfixed64, .sint64:
                    destination.values[fieldNumber] = .init(schema: ext, value: value.value(as: [Int64].self))
                case .string:
                    destination.values[fieldNumber] = .init(schema: ext, value: value.value(as: [String].self))
                default:
                    preconditionFailure("Unreachable")
                }

            case .scalar:
                switch field.rawFieldType {
                case .bytes:
                    destination.values[fieldNumber] = .init(schema: ext, value: value.value(as: Data.self))

                case .group, .message:
                    _ = ext.performNontrivialExtensionOperation(
                        .copy(destination: destination),
                        ext,
                        self
                    )

                case .string:
                    destination.values[fieldNumber] = .init(schema: ext, value: value.value(as: String.self))

                default:
                    // It is a POD, so it's safe to just bitwise-copy the value instead of going
                    // through the `copyField` helper.
                    destination.values[fieldNumber] = value
                }

            default:
                preconditionFailure("Unreachable")
            }
        }
        return destination
    }
}

/// An operation that the runtime requests to be performed on nontrivial extension fields that
/// require trampolining through a generated function to propagate the correct concrete type.
@_spi(ForGeneratedCodeOnly)
public enum NontrivialExtensionOperation {
    /// The value of the extension field should be deinitialized.
    case deinitialize

    /// The value of the extension field should be copied into the destination storage.
    case copy(destination: ExtensionStorage)

    /// The value of the extension field should be checked for equality against the value of the
    /// same extension in the other storage.
    case isEqual(other: ExtensionStorage)
}

extension ExtensionStorage {
    /// Returns the value of the given message extension, or the default value if it is not set.
    @_alwaysEmitIntoClient @inline(__always)
    public func value<Value: BitwiseCopyable>(of ext: ExtensionSchema, default: Value) -> Value {
        values[ext.field.fieldNumber]?.value(as: Value.self) ?? `default`
    }

    /// Returns the value of the given message extension, or the default value if it is not set.
    @_alwaysEmitIntoClient @inline(__always)
    public func value<Value>(of ext: ExtensionSchema, default: Value) -> Value {
        values[ext.field.fieldNumber]?.value(as: Value.self) ?? `default`
    }

    /// Returns a value indicating whether the given message extension is set.
    @_alwaysEmitIntoClient @inline(__always)
    public func hasValue(for ext: ExtensionSchema) -> Bool {
        values[ext.field.fieldNumber] != nil
    }

    /// Updates the value of the given message extension.
    @_alwaysEmitIntoClient @inline(__always)
    public func updateValue<Value: BitwiseCopyable>(of ext: ExtensionSchema, to newValue: Value) {
        values[ext.field.fieldNumber] = ExtensionValueStorage(schema: ext, value: newValue)
    }

    /// Updates the value of the given message extension.
    @_alwaysEmitIntoClient @inline(__always)
    public func updateValue<Value>(of ext: ExtensionSchema, to newValue: Value) {
        clearValue(of: ext, type: Value.self)
        values[ext.field.fieldNumber] = ExtensionValueStorage(schema: ext, value: newValue)
    }

    /// Clears the value of the given message extension.
    @_alwaysEmitIntoClient @inline(__always)
    public func clearValue<Value: BitwiseCopyable>(of ext: ExtensionSchema, type: Value.Type) {
        values.removeValue(forKey: ext.field.fieldNumber)
    }

    /// Clears the value of the given message extension.
    @_alwaysEmitIntoClient @inline(__always)
    public func clearValue<Value>(of ext: ExtensionSchema, type: Value.Type) {
        values.removeValue(forKey: ext.field.fieldNumber)?.release(type: Value.self)
    }

    /// Appends the given value to the array-typed value of the message extension, creating a new
    /// array if it is not already present.
    func appendValue<Value>(_ value: Value, to ext: ExtensionSchema) {
        if let existingValue = values[ext.field.fieldNumber] {
            existingValue.unsafeMutablePointerToValue(as: [Value].self).pointee.append(value)
        } else {
            updateValue(of: ext, to: [value])
        }
    }

    /// Returns the `ExtensionValueStorage` for the given extension, assuming that it is already
    /// known to be present.
    @_alwaysEmitIntoClient @inline(__always)
    private func assumedPresentStorage(of ext: ExtensionSchema) -> ExtensionValueStorage {
        values[ext.field.fieldNumber]!
    }
}

extension ExtensionStorage {
    /// Performs the given operation on the nontrivial value of an extension field.
    ///
    /// - Parameters:
    ///   - operation: The operation to perform.
    ///   - ext: The extension on which to perform the operation.
    ///   - type: The concrete type of the field.
    /// - Returns: If the operation being performed is `isEqual`, then the result indicates whether
    ///   the two values were equal. Otherwise, the result is always true and can be ignored.
    public func performNontrivialExtensionOperation<T: Equatable>(
        _ operation: NontrivialExtensionOperation,
        extension ext: ExtensionSchema,
        type: T.Type
    ) -> Bool {
        let valueStorage = assumedPresentStorage(of: ext)
        switch operation {
        case .deinitialize:
            valueStorage.release(type: type)
            return true

        case .copy(destination: let destination):
            destination.updateValue(of: valueStorage.schema, to: valueStorage.value(as: type))
            return true

        case .isEqual(other: let other):
            return isExtensionValue(valueStorage, equalToSameValueIn: other, type: type)
        }
    }

    /// Called by generated trampoline functions to invoke the given closure on the storage of a
    /// singular submessage, providing the type hint of the concrete message type.
    ///
    /// - Precondition: For read operations, the field is already known to be present.
    ///
    /// - Returns: The value returned from the closure.
    public func performOnSubmessageStorage<T: _MessageImplementationBase>(
        of ext: ExtensionSchema,
        operation: TrampolineFieldOperation,
        type: T.Type,
        perform: (_MessageStorage) throws -> Bool
    ) rethrows -> Bool {
        let field = ext.field

        switch operation {
        case .read:
            let submessage = assumedPresentStorage(of: ext).value(as: T.self)
            return try perform(submessage.storageForRuntime)

        case .mutate:
            let fieldNumber = field.fieldNumber
            if let value = values[ext.field.fieldNumber] {
                let pointer = value.unsafePointerToSubmessageWithUniqueStorage(as: T.self)
                return try perform(pointer.pointee.storageForRuntime)
            }
            let submessage = T.init()
            defer {
                values[fieldNumber] = ExtensionValueStorage(schema: ext, value: submessage)
            }
            return try perform(submessage.storageForRuntime)

        case .append:
            preconditionFailure("Internal error: singular performOnSubmessageStorage should not be called to append")

        case .jsonNull:
            if type != Google_Protobuf_Value.self {
                clearValue(of: ext, type: type)
                return true
            }
            // This well-known-type represents `null` as a populated `Value` instance whose
            // `nullValue` field (a one-of member) is initialized to the `nullValue` enum value.
            // Handle that accordingly.
            updateValue(of: ext, to: nil as Google_Protobuf_Value)
            return true
        }
    }

    /// Called by generated trampoline functions to invoke the given closure on the storage of each
    /// submessage in a repeated field, providing the type hint of the concrete message type.
    ///
    /// The closure can return false to stop iteration over the submessages early. Likewise, if the
    /// closure throws an error, that error will be propagated all the way to the caller.
    ///
    /// - Precondition: For the read and mutate operations, the field is already known to be
    ///   present.
    ///
    /// - Returns: The value returned from the last invocation of the closure.
    public func performOnSubmessageStorage<T: _MessageImplementationBase>(
        of ext: ExtensionSchema,
        operation: TrampolineFieldOperation,
        type: [T].Type,
        perform: (_MessageStorage) throws -> Bool
    ) rethrows -> Bool {
        let field = ext.field

        switch operation {
        case .read, .mutate:
            let submessages = assumedPresentStorage(of: ext).value(as: [T].self)
            for submessage in submessages {
                guard try perform(submessage.storageForRuntime) else { return false }
            }
            return true

        case .append:
            let fieldNumber = field.fieldNumber
            let submessage = T.init()
            guard try perform(submessage.storageForRuntime) else { return false }

            if let value = values[ext.field.fieldNumber] {
                // The field was set, so create a new message, perform the operation, and then
                // append it to the existing array.
                let pointer = value.unsafeMutablePointerToValue(as: [T].self)
                pointer.pointee.append(submessage)
                return true
            }
            // The field wasn't set yet, so create a new message, perform the operation, and then
            // set the field to an array of one.
            values[fieldNumber] = ExtensionValueStorage(schema: ext, value: [submessage])
            return true

        case .jsonNull:
            clearValue(of: ext, type: type)
            return true
        }
    }

    /// Called by generated trampoline functions to invoke the given closure on the raw value of a
    /// singular enum field, providing the type hint of the concrete enum type.
    ///
    /// - Precondition: For read operations, the field is already known to be present.
    ///
    /// - Parameters:
    ///   - ext: The extension enum field being operated on.
    ///   - operation: The specific operation to perform on the field.
    ///   - type: The concrete type of the enum.
    ///   - enumSchema: The schema of the enum.
    ///   - perform: A closure called with the (possibly mutable) value of the field. For `.read`
    ///     operations, the incoming value will be the actual value of the field, and mutating it
    ///     will be ignored. For `.mutate`, the incoming value is not specified and the closure
    ///     must mutate it to supply the desired value.
    ///   - onInvalidValue: A closure that is called during `.mutate` operations if the raw value
    ///     returned by the `perform` closure is not a valid enum case.
    public func performOnRawEnumValues<T: Enum>(
        of ext: ExtensionSchema,
        operation: TrampolineFieldOperation,
        type: T.Type,
        enumSchema: EnumSchema,
        perform: (EnumSchema, inout Int32) throws -> Bool,
        onInvalidValue: (Int32) throws -> Void
    ) rethrows {
        switch operation {
        case .read:
            // When reading, we can get the raw value directly from storage, and we don't need to
            // verify it against the defined values in the actual enum.
            var rawValue = assumedPresentStorage(of: ext).value(as: Int32.self)
            _ = try perform(enumSchema, &rawValue)

        case .mutate:
            // When updating a singular enum field, verify that it is a defined enum case. If not,
            // call the invalid value handler.
            var rawValue: Int32 = 0
            _ = try perform(enumSchema, &rawValue)
            if T(rawValue: Int(rawValue)) != nil {
                updateValue(of: ext, to: rawValue)
            } else {
                try onInvalidValue(rawValue)
            }

        case .append:
            preconditionFailure("Internal error: singular performOnRawEnumValues should not be called to append")

        case .jsonNull:
            preconditionFailure("Internal error: singular performOnRawEnumValues should not be called for jsonNull")
        }
    }

    /// Called by generated trampoline functions to invoke the given closure on the raw value of
    /// each element in a repeated enum field, providing the type hint of the concrete enum type.
    ///
    /// The closure can return false to stop iteration over the values early. Furthermore, when the
    /// operation is `.append`, the closure will be called repeatedly **until** it returns false.
    /// Likewise, if the closure throws an error, that error will be propagated all the way to the
    /// caller.
    ///
    /// - Precondition: For the read and mutate operations, the field is already known to be
    ///   present.
    ///
    /// - Parameters:
    ///   - ext: The extension enum field being operated on.
    ///   - operation: The specific operation to perform on the field.
    ///   - type: The concrete type of the enum.
    ///   - enumSchema: The schema of the enum.
    ///   - perform: A closure called with the (possibly mutable) value of the field. For `.read`
    ///     operations, the incoming value will be the actual value of the field, and mutating it
    ///     will be ignored. For `.mutate` and `.append`, the incoming value is not specified, and
    ///     the closure must mutate it to supply the desired value.
    ///   - onInvalidValue: A closure that is called during `.mutate` and `.append` operations if
    ///     the raw value returned by the `perform` closure is not a valid enum case.
    public func performOnRawEnumValues<T: Enum>(
        of ext: ExtensionSchema,
        operation: TrampolineFieldOperation,
        type: [T].Type,
        enumSchema: EnumSchema,
        perform: (EnumSchema, inout Int32) throws -> Bool,
        onInvalidValue: (Int32) throws -> Void
    ) rethrows {
        switch operation {
        case .read:
            for value in assumedPresentStorage(of: ext).value(as: [T].self) {
                var rawValue = Int32(value.rawValue)
                guard try perform(enumSchema, &rawValue) else { break }
            }

        case .mutate:
            preconditionFailure("Internal error: repeated performOnRawEnumValues should not be called to mutate")

        case .append:
            var rawValue: Int32 = 0
            var pointer: UnsafeMutablePointer<[T]>? = nil
            if let value = values[ext.field.fieldNumber] {
                pointer = value.unsafeMutablePointerToValue(as: [T].self)
            }
            while try perform(enumSchema, &rawValue) {
                if let newValue = T(rawValue: Int(rawValue)) {
                    if pointer == nil {
                        let value = ExtensionValueStorage(schema: ext, value: [T]())
                        values[ext.field.fieldNumber] = value
                        pointer = value.unsafeMutablePointerToValue(as: [T].self)
                    }
                    pointer!.pointee.append(newValue)
                } else {
                    try onInvalidValue(rawValue)
                }
            }

        case .jsonNull:
            clearValue(of: ext, type: type)
        }
    }
}

extension ExtensionStorage {
    @inline(never)
    func isEqual(to other: ExtensionStorage) -> Bool {
        // Identical storages mean they must be equal.
        if self === other {
            return true
        }
        // If the number of extension values differs, we know they're unequal.
        guard self.values.count == other.values.count else {
            return false
        }

        // Iterate over the values in the receiver and check if each is equal to the same value in
        // the other storage. If a value isn't present in the other, that is also false.
        var equalSoFar = true
        for (_, value) in values {
            let ext = value.schema
            let field = ext.field
            switch field.fieldMode.cardinality {
            case .map:
                preconditionFailure("Unreachable")

            case .array:
                switch field.rawFieldType {
                case .bool:
                    equalSoFar = isExtensionValue(value, equalToSameValueIn: other, type: [Bool].self)
                case .bytes:
                    equalSoFar = isExtensionValue(value, equalToSameValueIn: other, type: [Data].self)
                case .double:
                    equalSoFar = isExtensionValue(value, equalToSameValueIn: other, type: [Double].self)
                case .enum, .group, .message:
                    _ = ext.performNontrivialExtensionOperation(
                        .isEqual(other: other),
                        ext,
                        self
                    )
                case .fixed32, .uint32:
                    equalSoFar = isExtensionValue(value, equalToSameValueIn: other, type: [UInt32].self)
                case .fixed64, .uint64:
                    equalSoFar = isExtensionValue(value, equalToSameValueIn: other, type: [UInt64].self)
                case .float:
                    equalSoFar = isExtensionValue(value, equalToSameValueIn: other, type: [Float].self)
                case .int32, .sfixed32, .sint32:
                    equalSoFar = isExtensionValue(value, equalToSameValueIn: other, type: [Int32].self)
                case .int64, .sfixed64, .sint64:
                    equalSoFar = isExtensionValue(value, equalToSameValueIn: other, type: [Int64].self)
                case .string:
                    equalSoFar = isExtensionValue(value, equalToSameValueIn: other, type: [String].self)
                default:
                    preconditionFailure("Unreachable")
                }

            case .scalar:
                switch field.rawFieldType {
                case .bool:
                    equalSoFar = isExtensionValue(value, equalToSameValueIn: other, type: Bool.self)
                case .bytes:
                    equalSoFar = isExtensionValue(value, equalToSameValueIn: other, type: Data.self)
                case .double:
                    equalSoFar = isExtensionValue(value, equalToSameValueIn: other, type: Double.self)
                case .enum:
                    // Singular enum fields are stored as their raw value.
                    equalSoFar = isExtensionValue(value, equalToSameValueIn: other, type: Int32.self)
                case .group, .message:
                    _ = ext.performNontrivialExtensionOperation(
                        .isEqual(other: other),
                        ext,
                        self
                    )
                case .fixed32, .uint32:
                    equalSoFar = isExtensionValue(value, equalToSameValueIn: other, type: UInt32.self)
                case .fixed64, .uint64:
                    equalSoFar = isExtensionValue(value, equalToSameValueIn: other, type: UInt64.self)
                case .float:
                    equalSoFar = isExtensionValue(value, equalToSameValueIn: other, type: Float.self)
                case .int32, .sfixed32, .sint32:
                    equalSoFar = isExtensionValue(value, equalToSameValueIn: other, type: Int32.self)
                case .int64, .sfixed64, .sint64:
                    equalSoFar = isExtensionValue(value, equalToSameValueIn: other, type: Int64.self)
                case .string:
                    equalSoFar = isExtensionValue(value, equalToSameValueIn: other, type: String.self)
                default:
                    preconditionFailure("Unreachable")
                }

            default:
                preconditionFailure("Unreachable")
            }

            guard equalSoFar else {
                return false
            }
        }
        return true
    }

    @_alwaysEmitIntoClient @inline(__always)
    private func isExtensionValue<T: BitwiseCopyable & Equatable>(
        _ value: ExtensionValueStorage,
        equalToSameValueIn other: ExtensionStorage,
        type: T.Type
    ) -> Bool {
        guard let otherValue = other.values[value.schema.field.fieldNumber] else {
            return false
        }
        return value.value(as: T.self) == otherValue.value(as: T.self)
    }

    @_alwaysEmitIntoClient @inline(__always)
    private func isExtensionValue<T: Equatable>(
        _ value: ExtensionValueStorage,
        equalToSameValueIn other: ExtensionStorage,
        type: T.Type
    ) -> Bool {
        guard let otherValue = other.values[value.schema.field.fieldNumber] else {
            return false
        }
        return value.value(as: T.self) == otherValue.value(as: T.self)
    }
}

extension ExtensionStorage {
    @inline(never)
    func hash(into hasher: inout Hasher) {
        for (_, value) in values {
            let ext = value.schema
            let field = ext.field
            switch field.fieldMode.cardinality {
            case .map:
                preconditionFailure("Unreachable")

            case .array:
                switch field.rawFieldType {
                case .bool: hasher.combine(value.value(as: [Bool].self))
                case .bytes: hasher.combine(value.value(as: [Data].self))
                case .double: hasher.combine(value.value(as: [Double].self))
                case .enum:
                    _ = try! ext.performOnRawEnumValues(ext, self, .read) { _, rawValue in
                        rawValue.hash(into: &hasher)
                        return true
                    } /*onInvalidValue*/ _: { _ in }
                case .group, .message:
                    _ = try! ext.performOnSubmessageStorage(ext, self, .read) {
                        $0.hash(into: &hasher)
                        return true
                    }
                case .fixed32, .uint32: hasher.combine(value.value(as: [UInt32].self))
                case .fixed64, .uint64: hasher.combine(value.value(as: [UInt64].self))
                case .float: hasher.combine(value.value(as: [Float].self))
                case .int32, .sfixed32, .sint32: hasher.combine(value.value(as: [Int32].self))
                case .int64, .sfixed64, .sint64: hasher.combine(value.value(as: [Int64].self))
                case .string: hasher.combine(value.value(as: [String].self))
                default: preconditionFailure("Unreachable")
                }

            case .scalar:
                switch field.rawFieldType {
                case .bool: hasher.combine(value.value(as: Bool.self))
                case .bytes: hasher.combine(value.value(as: Data.self))
                case .double: hasher.combine(value.value(as: Double.self))
                case .enum:
                    // Singular enum fields are stored as their raw value.
                    hasher.combine(value.value(as: Int32.self))
                case .group, .message:
                    _ = try! ext.performOnSubmessageStorage(ext, self, .read) {
                        $0.hash(into: &hasher)
                        return true
                    }
                case .fixed32, .uint32: hasher.combine(value.value(as: UInt32.self))
                case .fixed64, .uint64: hasher.combine(value.value(as: UInt64.self))
                case .float: hasher.combine(value.value(as: Float.self))
                case .int32, .sfixed32, .sint32: hasher.combine(value.value(as: Int32.self))
                case .int64, .sfixed64, .sint64: hasher.combine(value.value(as: Int64.self))
                case .string: hasher.combine(value.value(as: String.self))
                default: preconditionFailure("Unreachable")
                }

            default:
                preconditionFailure("Unreachable")
            }
        }
    }
}
