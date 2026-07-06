// Sources/SwiftProtobuf/MessageStorage+Hashing.swift - Table-driven message storage hashing
//
// Copyright (c) 2014 - 2026 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Implementation of hashing for `MessageStorage`.
///
// -----------------------------------------------------------------------------

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

extension MessageStorage {
    /// Hashes the values of this storage object's fields into the given hasher.
    ///
    /// As required by the definitions of those operations, hashing -- like equality -- considers
    /// field presence. That is, a message containing an integer field set to 100 will hash
    /// differently from one where that field is not present but has a default defined to be 100.
    @inline(never)
    func hash(into hasher: inout Hasher) {
        var mapEntryWorkingSpace = MapEntryWorkingSpace(ownerSchema: schema)

        // Hash all of the trivial values (including has-bits) as a single slice of bytes up front.
        let firstNontrivialStorageOffset = schema.firstNontrivialOffset
        if firstNontrivialStorageOffset != 0 {
            hasher.combine(bytes: .init(rebasing: buffer[..<firstNontrivialStorageOffset]))
        }
        hasher.combine(unknownFields.data)
        extensionStorage.hash(into: &hasher)

        // If the message contains only trivial fields, we are done since we hashed them above.
        guard firstNontrivialStorageOffset != schema.storageSize else {
            return
        }

        for field in schema.fields {
            guard isPresent(field) else {
                continue
            }

            switch field.fieldMode.cardinality {
            case .map:
                let workingSpace = mapEntryWorkingSpace.storage(for: field.submessageIndex)
                forEachMapEntry(
                    in: field,
                    useDeterministicOrdering: false,
                    workingSpace: workingSpace
                ) {
                    $0.hash(into: &hasher)
                    return .continue
                }

            case .array:
                switch field.rawFieldType {
                case .bool:
                    hashField(field, into: &hasher, type: [Bool].self)
                case .bytes:
                    hashField(field, into: &hasher, type: [Data].self)
                case .double:
                    hashField(field, into: &hasher, type: [Double].self)
                case .enum:
                    forEachRawValue(inAssumedPresentRepeatedEnumField: field) {
                        $0.hash(into: &hasher)
                        return .continue
                    }
                case .group, .message:
                    forEachMessage(inAssumedPresentRepeatedMessageField: field) {
                        $0.hash(into: &hasher)
                        return .continue
                    }
                case .fixed32, .uint32:
                    hashField(field, into: &hasher, type: [UInt32].self)
                case .fixed64, .uint64:
                    hashField(field, into: &hasher, type: [UInt64].self)
                case .float:
                    hashField(field, into: &hasher, type: [Float].self)
                case .int32, .sfixed32, .sint32:
                    hashField(field, into: &hasher, type: [Int32].self)
                case .int64, .sfixed64, .sint64:
                    hashField(field, into: &hasher, type: [Int64].self)
                case .string:
                    hashField(field, into: &hasher, type: [String].self)
                default:
                    preconditionFailure("Unreachable")
                }

            case .scalar:
                switch field.rawFieldType {
                case .bytes:
                    hashField(field, into: &hasher, type: Data.self)

                case .group, .message:
                    messageStorage(forAssumedPresentSingularMessageField: field).hash(into: &hasher)

                case .string:
                    hashField(field, into: &hasher, type: String.self)

                default:
                    // Do nothing. Trivial fields were hashed above.
                    break
                }

            default:
                preconditionFailure("Unreachable")
            }
        }
    }

    /// Hashes the value of the field, given the expected type of that field.
    private func hashField<T: Hashable>(_ field: MessageSchema.Field, into hasher: inout Hasher, type: T.Type) {
        hasher.combine(typedPointer(for: field, as: T.self).pointee)
    }
}
