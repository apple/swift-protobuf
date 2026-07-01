// Sources/SwiftProtobuf/ExtensionStorage+BinarySize.swift - Binary size calculation for extensions
//
// Copyright (c) 2014 - 2026 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Computes the binary-encoded size of `ExtensionStorage`.
///
// -----------------------------------------------------------------------------

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

extension ExtensionStorage {
    /// Computes and returns the size in bytes required to serialize this message.
    public func serializedBytesSize() -> Int {
        var serializedSize = 0
        for (_, value) in values {
            serializedSize += serializedByteSize(of: value)
        }
        return serializedSize
    }

    /// Returns the serialized byte size of the value of the given extension field.
    ///
    /// - Precondition: The field is already known to be present.
    private func serializedByteSize(of value: ExtensionValueStorage) -> Int {
        // TODO: Unify our field number APIs around `UInt32` to avoid casting.
        let schema = value.schema
        let field = schema.field
        let fieldNumber = Int(field.fieldNumber)
        switch field.fieldMode.cardinality {
        case .map:
            preconditionFailure("unreachable")

        case .array:
            let isPacked = field.fieldMode.isPacked
            switch field.rawFieldType {
            case .bool:
                return fixedWidthRepeatedFieldSize(for: fieldNumber, value: value, isPacked: isPacked, as: Bool.self)

            case .bytes:
                precondition(!isPacked, "a packed bytes field should not be reachable")
                let values = value.value(as: [Data].self)
                let tagSize = FieldTag.encodedSize(ofTagWithFieldNumber: fieldNumber)
                let dataSize = values.reduce(into: 0) { result, value in
                    let count = value.count
                    result += Varint.encodedSize(of: Int64(count)) + count
                }
                return (tagSize * values.count) + dataSize

            case .double:
                return fixedWidthRepeatedFieldSize(for: fieldNumber, value: value, isPacked: isPacked, as: Double.self)

            case .enum:
                return serializedByteSize(ofRepeatedEnumExtension: schema, fieldNumber: fieldNumber, isPacked: isPacked)

            case .fixed32:
                return fixedWidthRepeatedFieldSize(for: fieldNumber, value: value, isPacked: isPacked, as: UInt32.self)

            case .fixed64:
                return fixedWidthRepeatedFieldSize(for: fieldNumber, value: value, isPacked: isPacked, as: UInt64.self)

            case .float:
                return fixedWidthRepeatedFieldSize(for: fieldNumber, value: value, isPacked: isPacked, as: Float.self)

            case .group:
                precondition(!isPacked, "a packed message/group field should not be reachable")
                let count = elementCount(forAssumedPresentRepeatedMessageField: schema)
                // It's slightly more efficient to pre-calculate the total size of the tags here
                // instead of adding it inside the loop, so we don't use `forEach...` here.
                var totalSize = count * (2 * FieldTag.encodedSize(ofTagWithFieldNumber: fieldNumber))
                for i in 0..<count {
                    totalSize +=
                        messageStorage(at: i, inAssumedPresentRepeatedMessageField: schema).serializedBytesSize()
                }
                return totalSize

            case .int32:
                let values = value.value(as: [Int32].self)
                let tagSize = FieldTag.encodedSize(ofTagWithFieldNumber: fieldNumber)
                let dataSize = values.reduce(0) { $0 + Varint.encodedSize(of: $1) }
                return isPacked
                    ? tagSize + Varint.encodedSize(of: Int64(dataSize)) + dataSize
                    : (tagSize * values.count) + dataSize

            case .int64:
                let values = value.value(as: [Int64].self)
                let tagSize = FieldTag.encodedSize(ofTagWithFieldNumber: fieldNumber)
                let dataSize = values.reduce(0) { $0 + Varint.encodedSize(of: $1) }
                return isPacked
                    ? tagSize + Varint.encodedSize(of: Int64(dataSize)) + dataSize
                    : (tagSize * values.count) + dataSize

            case .message:
                precondition(!isPacked, "a packed message/group field should not be reachable")
                var totalSize = 0
                forEachMessage(inAssumedPresentRepeatedMessageField: schema) { groupStorage in
                    let messageSize = groupStorage.serializedBytesSize()
                    totalSize +=
                        messageSize
                        // Include the size of the length-delimited tag.
                        + FieldTag.encodedSize(ofTagWithFieldNumber: fieldNumber)
                        // Include the varint-encoded length.
                        + Varint.encodedSize(of: UInt64(messageSize))
                    return .continue
                }
                return totalSize

            case .sfixed32:
                return fixedWidthRepeatedFieldSize(for: fieldNumber, value: value, isPacked: isPacked, as: Int32.self)

            case .sfixed64:
                return fixedWidthRepeatedFieldSize(for: fieldNumber, value: value, isPacked: isPacked, as: Int64.self)

            case .sint32:
                let values = value.value(as: [Int32].self)
                let tagSize = FieldTag.encodedSize(ofTagWithFieldNumber: fieldNumber)
                let dataSize = values.reduce(0) { $0 + Varint.encodedSize(of: UInt32(zigZagEncoded: $1)) }
                return isPacked
                    ? tagSize + Varint.encodedSize(of: Int64(dataSize)) + dataSize
                    : (tagSize * values.count) + dataSize

            case .sint64:
                let values = value.value(as: [Int64].self)
                let tagSize = FieldTag.encodedSize(ofTagWithFieldNumber: fieldNumber)
                let dataSize = values.reduce(0) { $0 + Varint.encodedSize(of: UInt64(zigZagEncoded: $1)) }
                return isPacked
                    ? tagSize + Varint.encodedSize(of: Int64(dataSize)) + dataSize
                    : (tagSize * values.count) + dataSize

            case .string:
                precondition(!isPacked, "a packed string field should not be reachable")
                let values = value.value(as: [String].self)
                let tagSize = FieldTag.encodedSize(ofTagWithFieldNumber: fieldNumber)
                let dataSize = values.reduce(into: 0) { result, value in
                    let count = value.utf8.count
                    result += Varint.encodedSize(of: Int64(count)) + count
                }
                return (tagSize * values.count) + dataSize

            case .uint32:
                let values = value.value(as: [UInt32].self)
                let tagSize = FieldTag.encodedSize(ofTagWithFieldNumber: fieldNumber)
                let dataSize = values.reduce(0) { $0 + Varint.encodedSize(of: $1) }
                return isPacked
                    ? tagSize + Varint.encodedSize(of: Int64(dataSize)) + dataSize
                    : (tagSize * values.count) + dataSize

            case .uint64:
                let values = value.value(as: [UInt64].self)
                let tagSize = FieldTag.encodedSize(ofTagWithFieldNumber: fieldNumber)
                let dataSize = values.reduce(0) { $0 + Varint.encodedSize(of: $1) }
                return isPacked
                    ? tagSize + Varint.encodedSize(of: Int64(dataSize)) + dataSize
                    : (tagSize * values.count) + dataSize

            default:
                preconditionFailure("Unreachable")
            }

        case .scalar:
            switch field.rawFieldType {
            case .bool:
                return FieldTag.encodedSize(ofTagWithFieldNumber: fieldNumber) + 1

            case .bytes:
                let count = value.value(as: Data.self).count
                return FieldTag.encodedSize(ofTagWithFieldNumber: fieldNumber)
                    + Varint.encodedSize(of: Int64(count)) + count

            case .double:
                return fixedWidthSingularFieldSize(for: fieldNumber, as: Double.self)

            case .enum:
                return FieldTag.encodedSize(ofTagWithFieldNumber: fieldNumber)
                    + Varint.encodedSize(of: value.value(as: Int32.self))

            case .fixed32:
                return fixedWidthSingularFieldSize(for: fieldNumber, as: UInt32.self)

            case .fixed64:
                return fixedWidthSingularFieldSize(for: fieldNumber, as: UInt64.self)

            case .float:
                return fixedWidthSingularFieldSize(for: fieldNumber, as: Float.self)

            case .group:
                let messageSize = messageStorage(forAssumedPresentSingularMessageField: schema).serializedBytesSize()
                return messageSize
                    // Include the size of the start tag and end tag.
                    + 2 * FieldTag.encodedSize(ofTagWithFieldNumber: fieldNumber)

            case .int32:
                return FieldTag.encodedSize(ofTagWithFieldNumber: fieldNumber)
                    + Varint.encodedSize(of: value.value(as: Int32.self))

            case .int64:
                return FieldTag.encodedSize(ofTagWithFieldNumber: fieldNumber)
                    + Varint.encodedSize(of: value.value(as: Int64.self))

            case .message:
                let messageSize = messageStorage(forAssumedPresentSingularMessageField: schema).serializedBytesSize()
                if schema.extendedMessage.extensibilityMode == .messageSet {
                    return messageSetItemTagsEncodedSize
                        + Varint.encodedSize(of: UInt64(fieldNumber))
                        + Varint.encodedSize(of: UInt64(messageSize))
                        + messageSize
                } else {
                    return messageSize
                        // Include the size of the length-delimited tag.
                        + FieldTag.encodedSize(ofTagWithFieldNumber: fieldNumber)
                        // Include the varint-encoded length.
                        + Varint.encodedSize(of: UInt64(messageSize))
                }

            case .sfixed32:
                return fixedWidthSingularFieldSize(for: fieldNumber, as: Int32.self)

            case .sfixed64:
                return fixedWidthSingularFieldSize(for: fieldNumber, as: Int64.self)

            case .sint32:
                return FieldTag.encodedSize(ofTagWithFieldNumber: fieldNumber)
                    + Varint.encodedSize(of: UInt32(zigZagEncoded: value.value(as: Int32.self)))

            case .sint64:
                return FieldTag.encodedSize(ofTagWithFieldNumber: fieldNumber)
                    + Varint.encodedSize(of: UInt64(zigZagEncoded: value.value(as: Int64.self)))

            case .string:
                let count = value.value(as: String.self).utf8.count
                return FieldTag.encodedSize(ofTagWithFieldNumber: fieldNumber)
                    + Varint.encodedSize(of: Int64(count)) + count

            case .uint32:
                return FieldTag.encodedSize(ofTagWithFieldNumber: fieldNumber)
                    + Varint.encodedSize(of: value.value(as: UInt32.self))

            case .uint64:
                return FieldTag.encodedSize(ofTagWithFieldNumber: fieldNumber)
                    + Varint.encodedSize(of: value.value(as: UInt64.self))

            default:
                preconditionFailure("Unreachable")
            }

        default:
            preconditionFailure("Unreachable")
        }
    }

    /// Returns the serialized byte size of a single value of the given trivial field.
    @inline(__always)
    private func fixedWidthSingularFieldSize<T>(for fieldNumber: Int, as type: T.Type) -> Int {
        FieldTag.encodedSize(ofTagWithFieldNumber: fieldNumber) + MemoryLayout<T>.size
    }

    /// Returns the size of the given repeated field, assuming that it is a sequence of fixed width
    /// elements (i.e., elements where we do not need the values themselves to determine the size).
    @inline(__always)
    private func fixedWidthRepeatedFieldSize<T>(
        for fieldNumber: Int,
        value: ExtensionValueStorage,
        isPacked: Bool,
        as type: T.Type
    ) -> Int {
        let tagSize = FieldTag.encodedSize(ofTagWithFieldNumber: fieldNumber)
        let count = value.value(as: [T].self).count
        if isPacked {
            let dataSize = count * MemoryLayout<T>.size
            return tagSize + Varint.encodedSize(of: Int64(dataSize)) + dataSize
        }
        return (tagSize + MemoryLayout<T>.size) * count
    }

    /// Returns the serialized byte size of the given repeated enum field.
    ///
    /// This function takes the field number as a separate argument even though it can be computed
    /// from the `MessageSchema.Field` to avoid the (minor but non-zero) cost of decoding it again
    /// from the schema, since that has already been done by the caller.
    private func serializedByteSize(
        ofRepeatedEnumExtension schema: ExtensionSchema,
        fieldNumber: Int,
        isPacked: Bool
    ) -> Int {
        var totalEnumsSize = 0
        let count = elementCount(forAssumedPresentRepeatedEnumField: schema)
        for i in 0..<count {
            let value = rawValue(at: i, inAssumedPresentRepeatedEnumField: schema)
            totalEnumsSize += Varint.encodedSize(of: value)
        }
        if schema.field.fieldMode.isPacked {
            // Packed: we need to add a single (length-delimited) tag and a varint for the length.
            return totalEnumsSize + FieldTag.encodedSize(ofTagWithFieldNumber: fieldNumber)
                + Varint.encodedSize(of: UInt64(totalEnumsSize))
        }
        // Unpacked: there will be a separate tag for each value.
        return totalEnumsSize + FieldTag.encodedSize(ofTagWithFieldNumber: fieldNumber) * count
    }
}
