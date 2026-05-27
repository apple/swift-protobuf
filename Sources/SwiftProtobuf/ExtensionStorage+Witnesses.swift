// Sources/SwiftProtobuf/ExtensionStorage+Witnesses.swift - Message/enum witness helpers for extensions
//
// Copyright (c) 2014 - 2026 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Helper methods for calling message, enum, and map witness functions on
/// extension fields to keep the call sites within the rest of the runtime
/// clean.
///
// -----------------------------------------------------------------------------

// MARK: - Message witness helpers

extension ExtensionStorage {
    /// Returns the storage for the given submessage field.
    ///
    /// - Precondition: The field must be present and must be a message or group field.
    func messageStorage(forAssumedPresentSingularMessageField ext: ExtensionSchema) -> MessageStorage {
        let value = values[ext.field.fieldNumber]!
        var submessageStorage: Unmanaged<MessageStorage>? = nil
        withUnsafeMutablePointer(to: &submessageStorage) {
            ext.messageSchema.invokeWitness(
                .messageGetStorage(pointer: value.unsafeRawPointer, result: $0)
            )
        }
        return submessageStorage!.takeUnretainedValue()
    }

    /// Returns storage for the given singular message field, ensuring that it is unique for mutation.
    ///
    /// If the field is not yet present, its value will be initialized first.
    ///
    /// - Precondition: The field must be a singular message or group field.
    @inline(never)
    func uniqueMessageStorage(forSingularMessageField ext: ExtensionSchema) -> MessageStorage {
        var submessageStorage: Unmanaged<MessageStorage>? = nil
        withUnsafeMutablePointer(to: &submessageStorage) { submessageStoragePointer in
            if let value = values[ext.field.fieldNumber] {
                // The message already exists, so ensure that its storage is unique for mutation
                // before returning it.
                ext.messageSchema.invokeWitness(
                    .messageGetUniqueStorage(
                        pointer: value.unsafeMutableRawPointer,
                        result: submessageStoragePointer
                    )
                )
            } else {
                // If the extension is not present, initialize it.
                let value = ExtensionValueStorage(uninitializedMessageExtensionField: ext)
                ext.messageSchema.invokeWitness(
                    .messageInitialize(
                        pointer: value.unsafeMutableRawPointer,
                        result: submessageStoragePointer
                    )
                )
                values[ext.field.fieldNumber] = value
            }
        }
        return submessageStorage!.takeUnretainedValue()
    }

    /// Returns the number of elements for the given repeated submessage field.
    ///
    /// - Precondition: The field must be present and must be a repeated message or group field.
    func elementCount(forAssumedPresentRepeatedMessageField ext: ExtensionSchema) -> Int {
        let value = values[ext.field.fieldNumber]!
        var count: Int = 0
        withUnsafeMutablePointer(to: &count) {
            ext.messageSchema.invokeWitness(.arrayGetCount(pointer: value.unsafeRawPointer, result: $0))
        }
        return count
    }

    /// Returns the storage for the element at the given index in the given repeated submessage field.
    ///
    /// - Precondition: The field must be present and must be a repeated message or group field.
    func messageStorage(
        at index: Int,
        inAssumedPresentRepeatedMessageField ext: ExtensionSchema
    ) -> MessageStorage {
        let value = values[ext.field.fieldNumber]!
        var submessageStorage: Unmanaged<MessageStorage>? = nil
        withUnsafeMutablePointer(to: &submessageStorage) {
            ext.messageSchema.invokeWitness(
                .arrayGetElementStorage(pointer: value.unsafeRawPointer, index: index, result: $0)
            )
        }
        return submessageStorage!.takeUnretainedValue()
    }

    /// Performs the given action for each message in the repeated message or group field.
    ///
    /// - Precondition: The field must be present and must be a repeated message or group field.
    func forEachMessage(
        inAssumedPresentRepeatedMessageField ext: ExtensionSchema,
        perform: (MessageStorage) throws -> IterationBehavior
    ) rethrows {
        let count = elementCount(forAssumedPresentRepeatedMessageField: ext)
        for i in 0..<count {
            let behavior = try perform(messageStorage(at: i, inAssumedPresentRepeatedMessageField: ext))
            guard behavior == .continue else { break }
        }
    }

    /// Appends a new element to the repeated message or group field and returns its storage.
    ///
    /// If the field is not yet present, its array value will be initialized first.
    ///
    /// - Precondition: The field must be a repeated message or group field.
    func messageStorage(forNewlyAppendedElementOfRepeatedMessageField ext: ExtensionSchema) -> MessageStorage {
        let messageSchema = ext.messageSchema
        var submessageStorage: Unmanaged<MessageStorage>? = nil
        withUnsafeMutablePointer(to: &submessageStorage) { submessageStoragePointer in
            let value: ExtensionValueStorage
            if let existingValue = values[ext.field.fieldNumber] {
                value = existingValue
            } else {
                // If the extension is not present, initialize it to an empty array.
                value = ExtensionValueStorage(uninitializedMessageExtensionField: ext)
                messageSchema.invokeWitness(.arrayInitialize(pointer: value.unsafeMutableRawPointer))
                values[ext.field.fieldNumber] = value
            }
            // Append a new element to the array and return its storage.
            messageSchema.invokeWitness(
                .arrayAppendNew(
                    pointer: value.unsafeMutableRawPointer,
                    result: submessageStoragePointer
                )
            )
        }
        return submessageStorage!.takeUnretainedValue()
    }

    /// Clears the singular message or group field.
    ///
    /// If the field is not present, this method does nothing.
    ///
    /// - Precondition: The field must be a singular message or group field.
    func clearSingularMessageField(_ ext: ExtensionSchema) {
        guard let value = values.removeValue(forKey: ext.field.fieldNumber) else {
            return
        }
        value.releaseMessageValue()
    }

    /// Clears the repeated or map field.
    ///
    /// If the field is not present, this method does nothing.
    ///
    /// - Precondition: The field must be a repeated or map field.
    func clearRepeatedField(_ ext: ExtensionSchema) {
        // TODO
    }
}

// MARK: - Enum witness helpers

extension ExtensionStorage {
    /// Returns the number of elements for the given repeated enum field.
    ///
    /// - Precondition: The field must be present and must be a repeated enum field.
    func elementCount(forAssumedPresentRepeatedEnumField ext: ExtensionSchema) -> Int {
        let value = values[ext.field.fieldNumber]!
        var count: Int = 0
        withUnsafeMutablePointer(to: &count) {
            ext.enumSchema.invokeWitness(.arrayGetCount(pointer: value.unsafeRawPointer, result: $0))
        }
        return count
    }

    /// Returns the raw value for the enum element at the given index in the given repeated enum field.
    ///
    /// - Precondition: The field must be present and must be a repeated enum field.
    func rawValue(at index: Int, inAssumedPresentRepeatedEnumField ext: ExtensionSchema) -> Int32 {
        let value = values[ext.field.fieldNumber]!
        var rawValue: Int32 = 0
        withUnsafeMutablePointer(to: &rawValue) {
            ext.enumSchema.invokeWitness(
                .arrayGetElementRawValue(pointer: value.unsafeRawPointer, index: index, result: $0)
            )
        }
        return rawValue
    }

    /// Performs the given action for each raw value in the repeated enum field.
    ///
    /// - Precondition: The field must be present and must be a repeated enum field.
    func forEachRawValue(
        inAssumedPresentRepeatedEnumField ext: ExtensionSchema,
        perform: (Int32) throws -> IterationBehavior
    ) rethrows {
        let count = elementCount(forAssumedPresentRepeatedEnumField: ext)
        for i in 0..<count {
            let behavior = try perform(rawValue(at: i, inAssumedPresentRepeatedEnumField: ext))
            guard behavior == .continue else { break }
        }
    }

    /// Appends a new element with the given raw value to the repeated enum field.
    ///
    /// If the field is not yet present, its array value will be initialized first.
    ///
    /// - Precondition: The field must be a repeated enum field.
    func appendEnumValue(withRawValue rawValue: Int32, toRepeatedEnumField ext: ExtensionSchema) {
        let enumSchema = ext.enumSchema
        let value: ExtensionValueStorage
        if let existingValue = values[ext.field.fieldNumber] {
            value = existingValue
        } else {
            // If the extension is not present, initialize it to an empty array.
            value = ExtensionValueStorage(uninitializedMessageExtensionField: ext)
            enumSchema.invokeWitness(.arrayInitialize(pointer: value.unsafeMutableRawPointer))
            values[ext.field.fieldNumber] = value
        }
        enumSchema.invokeWitness(
            .arrayAppendRawValue(
                pointer: value.unsafeMutableRawPointer,
                rawValue: rawValue
            )
        )
    }
}
