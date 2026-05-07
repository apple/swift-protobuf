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
    ///
    /// TODO: This only has package visibility to allow MessageSet tests to access the values.
    /// When we have a true reflection API, use that instead and make this internal again.
    @usableFromInline package var values: [UInt32: ExtensionValueStorage]

    init() {
        self.values = [:]
    }

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
                case .enum:
                    ext.enumSchema.invokeWitness(.arrayDeinitialize(pointer: value.unsafeMutableRawPointer))
                case .group, .message:
                    ext.messageSchema.invokeWitness(.arrayDeinitialize(pointer: value.unsafeMutableRawPointer))
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
                    ext.messageSchema.invokeWitness(.messageDeinitialize(pointer: value.unsafeMutableRawPointer))
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
                case .enum:
                    let destinationValue = ExtensionValueStorage(uninitializedMessageExtensionField: ext)
                    ext.enumSchema.invokeWitness(.arrayCopyInitialize(
                        source: value.unsafeRawPointer, destination: destinationValue.unsafeMutableRawPointer))
                    destination.values[fieldNumber] = destinationValue
                case .group, .message:
                    let destinationValue = ExtensionValueStorage(uninitializedMessageExtensionField: ext)
                    ext.messageSchema.invokeWitness(.arrayCopyInitialize(
                        source: value.unsafeRawPointer, destination: destinationValue.unsafeMutableRawPointer))
                    destination.values[fieldNumber] = destinationValue
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
                    let destinationValue = ExtensionValueStorage(uninitializedMessageExtensionField: ext)
                    ext.messageSchema.invokeWitness(.messageCopyInitialize(
                        source: value.unsafeRawPointer, destination: destinationValue.unsafeMutableRawPointer))
                    destination.values[fieldNumber] = destinationValue

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

    /// Indicates whether all message and group fields that are present are initialized.
    var allSubmessagesAreInitialized: Bool {
        for (_, value) in values {
            let ext = value.schema
            let field = ext.field
            if field.rawFieldType == .message || field.rawFieldType == .group {
                switch field.fieldMode.cardinality {
                case .map:
                    preconditionFailure("Unreachable")

                case .array:
                    var areAllInitialized = true
                    forEachMessage(inAssumedPresentRepeatedMessageField: ext) {
                        guard $0.isInitialized else {
                            areAllInitialized = false
                            return .stop
                        }
                        return .continue
                    }
                    return areAllInitialized

                case .scalar:
                    let storage = messageStorage(forAssumedPresentSingularMessageField: ext)
                    guard storage.isInitialized else {
                        return false
                    }

                default:
                    preconditionFailure("Unreachable")
                }
            }
        }
        return true
    }
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
                case .enum:
                    guard other.values[field.fieldNumber] != nil else {
                        equalSoFar = false
                        break
                    }
                    // Both are present; compare them.
                    let lhsCount = elementCount(forAssumedPresentRepeatedEnumField: ext)
                    let rhsCount = other.elementCount(forAssumedPresentRepeatedEnumField: ext)
                    guard lhsCount == rhsCount else {
                        equalSoFar = false
                        break
                    }
                    for i in 0..<lhsCount {
                        let lhsValue = rawValue(at: i, inAssumedPresentRepeatedEnumField: ext)
                        let rhsValue = other.rawValue(at: i, inAssumedPresentRepeatedEnumField: ext)
                        guard lhsValue == rhsValue else {
                            equalSoFar = false
                            break
                        }
                    }

                case .group, .message:
                    guard other.values[field.fieldNumber] != nil else {
                        equalSoFar = false
                        break
                    }
                    // Both are present; compare them.
                    let lhsCount = elementCount(forAssumedPresentRepeatedMessageField: ext)
                    let rhsCount = other.elementCount(forAssumedPresentRepeatedMessageField: ext)
                    guard lhsCount == rhsCount else {
                        equalSoFar = false
                        break
                    }
                    for i in 0..<lhsCount {
                        let lhsValue = messageStorage(at: i, inAssumedPresentRepeatedMessageField: ext)
                        let rhsValue = other.messageStorage(at: i, inAssumedPresentRepeatedMessageField: ext)
                        guard lhsValue.isEqual(to: rhsValue) else {
                            equalSoFar = false
                            break
                        }
                    }

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
                    guard other.values[field.fieldNumber] != nil else {
                        equalSoFar = false
                        break
                    }
                    let lhsStorage = messageStorage(forAssumedPresentSingularMessageField: ext)
                    let rhsStorage = other.messageStorage(forAssumedPresentSingularMessageField: ext)
                    equalSoFar = lhsStorage.isEqual(to: rhsStorage)
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
                    forEachRawValue(inAssumedPresentRepeatedEnumField: ext) {
                        $0.hash(into: &hasher)
                        return .continue
                    }
                case .group, .message:
                    forEachMessage(inAssumedPresentRepeatedMessageField: ext) {
                        $0.hash(into: &hasher)
                        return .continue
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
                    messageStorage(forAssumedPresentSingularMessageField: ext).hash(into: &hasher)
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
