// Sources/SwiftProtobuf/MessageStorage+Equality.swift - Table-driven message storage equality
//
// Copyright (c) 2014 - 2026 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Implementation of equality for `MessageStorage`.
///
// -----------------------------------------------------------------------------

import Foundation

extension MessageStorage {
    /// Tests this message storage for equality with the other storage.
    ///
    /// Precondition: Both instances of storage are assumed to be represented by the same message
    /// type.
    ///
    /// Message equality in SwiftProtobuf includes presence. That is, a message with an integer
    /// field set to 100 is not considered equal to one where that field is not present but has a
    /// default defined to be 100.
    @inline(never)
    func isEqual(to other: MessageStorage) -> Bool {
        if self === other {
            /// Identical message storage means they must be equal.
            return true
        }
        // TODO: If we store the offset of the first non-trivial field in the schema, we can make
        // this extremely fast by doing the memcmp up front and failing fast. Likewise, we can also
        // avoid the loop entirely if the message contains only trivial fields. We could see similar
        // performance wins for copy and deinit.

        // Loops through the fields, checking equality of any that are non-trivial types. We ignore
        // the trivial ones here, instead tracking the byte offset of the first non-trivial field
        // so that we can bitwise-compare those as a block afterward.
        var firstNontrivialStorageOffset = schema.storageSize
        var equalSoFar = true
        for field in schema.fields {
            switch field.fieldMode.cardinality {
            case .map:
                if field.offset < firstNontrivialStorageOffset {
                    firstNontrivialStorageOffset = field.offset
                }
                switch mutualPresence(of: field, withSameFieldIn: other) {
                case .bothPresent:
                    equalSoFar = isMapField(field, equalToSameFieldIn: other)
                case .neitherPresent:
                    break
                case .onlyOnePresent:
                    equalSoFar = false
                }

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
                    switch mutualPresence(of: field, withSameFieldIn: other) {
                    case .bothPresent:
                        let lhsCount = elementCount(forAssumedPresentRepeatedEnumField: field)
                        let rhsCount = other.elementCount(forAssumedPresentRepeatedEnumField: field)
                        guard lhsCount == rhsCount else {
                            equalSoFar = false
                            break
                        }
                        for i in 0..<lhsCount {
                            let lhsValue = rawValue(at: i, inAssumedPresentRepeatedEnumField: field)
                            let rhsValue = other.rawValue(at: i, inAssumedPresentRepeatedEnumField: field)
                            guard lhsValue == rhsValue else {
                                equalSoFar = false
                                break
                            }
                        }
                    case .neitherPresent:
                        break
                    case .onlyOnePresent:
                        equalSoFar = false
                    }

                case .group, .message:
                    switch mutualPresence(of: field, withSameFieldIn: other) {
                    case .bothPresent:
                        let lhsCount = elementCount(forAssumedPresentRepeatedMessageField: field)
                        let rhsCount = other.elementCount(forAssumedPresentRepeatedMessageField: field)
                        guard lhsCount == rhsCount else {
                            equalSoFar = false
                            break
                        }
                        for i in 0..<lhsCount {
                            let lhsValue = messageStorage(at: i, inAssumedPresentRepeatedMessageField: field)
                            let rhsValue = other.messageStorage(at: i, inAssumedPresentRepeatedMessageField: field)
                            guard lhsValue.isEqual(to: rhsValue) else {
                                equalSoFar = false
                                break
                            }
                        }
                    case .neitherPresent:
                        break
                    case .onlyOnePresent:
                        equalSoFar = false
                    }

                case .fixed32, .uint32:
                    equalSoFar = isField(field, equalToSameFieldIn: other, type: [UInt32].self)
                case .fixed64, .uint64:
                    equalSoFar = isField(field, equalToSameFieldIn: other, type: [UInt64].self)
                case .float:
                    equalSoFar = isField(field, equalToSameFieldIn: other, type: [Float].self)
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
                    switch mutualPresence(of: field, withSameFieldIn: other) {
                    case .bothPresent:
                        let lhsStorage = messageStorage(forAssumedPresentSingularMessageField: field)
                        let rhsStorage = other.messageStorage(forAssumedPresentSingularMessageField: field)
                        equalSoFar = lhsStorage.isEqual(to: rhsStorage)
                    case .neitherPresent:
                        break
                    case .onlyOnePresent:
                        equalSoFar = false
                    }

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
        if firstNontrivialStorageOffset != 0
            && memcmp(buffer.baseAddress!, other.buffer.baseAddress!, firstNontrivialStorageOffset) != 0
        {
            return false
        }
        if unknownFields.data != other.unknownFields.data {
            return false
        }
        if !extensionStorage.isEqual(to: other.extensionStorage) {
            return false
        }
        return true
    }

    /// Returns whether the given field in the receiver is equal to the same field in the other
    /// storage, given the expected type of that field.
    func isField<T: Equatable>(
        _ field: FieldSchema,
        equalToSameFieldIn other: MessageStorage,
        type: T.Type
    ) -> Bool {
        switch mutualPresence(of: field, withSameFieldIn: other) {
        case .onlyOnePresent:
            return false
        case .neitherPresent:
            return true
        case .bothPresent:
            let selfPointer = (buffer.baseAddress! + field.offset).bindMemory(to: T.self, capacity: 1)
            let otherPointer = (other.buffer.baseAddress! + field.offset).bindMemory(to: T.self, capacity: 1)
            return selfPointer.pointee == otherPointer.pointee
        }
    }

    /// Describes whether a field is present in both messages, neither message, or only one of them.
    private enum MutualPresence {
        case bothPresent
        case neitherPresent
        case onlyOnePresent
    }

    /// Returns whether a field is present in both messages, neither message, or only one of them.
    private func mutualPresence(of field: FieldSchema, withSameFieldIn other: MessageStorage) -> MutualPresence {
        let isSelfPresent = isPresent(field)
        let isOtherPresent = other.isPresent(field)
        if isSelfPresent && isOtherPresent {
            return .bothPresent
        }
        if !isSelfPresent && !isOtherPresent {
            return .neitherPresent
        }
        return .onlyOnePresent
    }
}
