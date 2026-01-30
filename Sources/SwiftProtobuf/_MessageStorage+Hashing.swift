// Sources/SwiftProtobuf/_MessageStorage+Hashing.swift - Table-driven message storage hashing
//
// Copyright (c) 2014 - 2026 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Implementation of hashing for `_MessageStorage`.
///
// -----------------------------------------------------------------------------

import Foundation

extension _MessageStorage {
    /// Hashes the values of this storage object's fields into the given hasher.
    ///
    /// As required by the definitions of those operations, hashing -- like equality -- considers
    /// field presence. That is, a message containing an integer field set to 100 will hash
    /// differently from one where that field is not present but has a default defined to be 100.
    @inline(never)
    public func hash(into hasher: inout Hasher) {
        // TODO: If we store the offset of the first non-trivial field in the layout, we can make
        // this extremely fast by hashing the trivial fields as a single slice of bytes. Likewise,
        // we could avoid the loop entirely if the message contains only trivial fields.

        // Loops through the fields, combining the hashes for any with non-trivial types. We ignore
        // the trivial ones here, instead tracking the byte offset of the first non-trivial field
        // so that we can hash them as a contiguous byte buffer slice afterwards.
        var firstNontrivialStorageOffset = layout.size
        for field in layout.fields {
            guard isPresent(field) else {
                continue
            }

            switch field.fieldMode.cardinality {
            case .map:
                if field.offset < firstNontrivialStorageOffset {
                    firstNontrivialStorageOffset = field.offset
                }
                _ = try! layout.performOnSubmessageStorage(
                    _MessageLayout.TrampolineToken(index: field.submessageIndex),
                    field,
                    self,
                    .read
                ) {
                    $0.hash(into: &hasher)
                    return true
                }

            case .array:
                if field.offset < firstNontrivialStorageOffset {
                    firstNontrivialStorageOffset = field.offset
                }
                switch field.rawFieldType {
                case .bool:
                    hashField(field, into: &hasher, type: [Bool].self)
                case .bytes:
                    hashField(field, into: &hasher, type: [Data].self)
                case .double:
                    hashField(field, into: &hasher, type: [Double].self)
                case .enum, .group, .message:
                    _ = try! layout.performOnSubmessageStorage(
                        _MessageLayout.TrampolineToken(index: field.submessageIndex),
                        field,
                        self,
                        .read
                    ) {
                        $0.hash(into: &hasher)
                        return true
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
                    if field.offset < firstNontrivialStorageOffset {
                        firstNontrivialStorageOffset = field.offset
                    }
                    hashField(field, into: &hasher, type: Data.self)

                case .group, .message:
                    if field.offset < firstNontrivialStorageOffset {
                        firstNontrivialStorageOffset = field.offset
                    }
                    _ = try! layout.performOnSubmessageStorage(
                        _MessageLayout.TrampolineToken(index: field.submessageIndex),
                        field,
                        self,
                        .read
                    ) {
                        $0.hash(into: &hasher)
                        return true
                    }

                case .string:
                    if field.offset < firstNontrivialStorageOffset {
                        firstNontrivialStorageOffset = field.offset
                    }
                    hashField(field, into: &hasher, type: String.self)

                default:
                    // Do nothing. Trivial fields will be bitwise-compared as a block below.
                    break
                }

            default:
                preconditionFailure("Unreachable")
            }
        }

        // Hash all of the trivial values (including has-bits) as a single slice of bytes.
        if firstNontrivialStorageOffset != 0 {
            hasher.combine(bytes: .init(rebasing: buffer[..<firstNontrivialStorageOffset]))
        }
        hasher.combine(unknownFields.data)
        hasher.combine(extensionFieldValues)
    }

    /// Hashes the value of the field, given the expected type of that field.
    private func hashField<T: Hashable>(_ field: FieldLayout, into hasher: inout Hasher, type: T.Type) {
        hasher.combine((buffer.baseAddress! + field.offset).bindMemory(to: T.self, capacity: 1).pointee)
    }
}
