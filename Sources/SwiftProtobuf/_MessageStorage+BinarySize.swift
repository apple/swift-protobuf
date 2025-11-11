// Sources/SwiftProtobuf/_MessageStorage+BinarySize.swift - Binary size calculation for messages
//
// Copyright (c) 2014 - 2025 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Computes the binary-encoded size of `_MessageStorage.`
///
// -----------------------------------------------------------------------------

import Foundation

extension _MessageStorage {
    /// Computes and returns the size in bytes required to serialize this message.
    public func serializedBytesSize() -> Int {
        var serializedSize = 0
        var mapEntryWorkingSpace = MapEntryWorkingSpace(ownerLayout: layout)
        for field in layout.fields {
            guard isPresent(field) else { continue }
            serializedSize += serializedByteSize(of: field, mapEntryWorkingSpace: &mapEntryWorkingSpace)
        }
        serializedSize += unknownFields.data.count
        // TODO: Support extensions.
        return serializedSize
    }

    /// Returns the serialized byte size of the value of the given field.
    ///
    /// - Precondition: The field is already known to be present.
    private func serializedByteSize(of field: FieldLayout, mapEntryWorkingSpace: inout MapEntryWorkingSpace) -> Int {
        // TODO: Unify our field number APIs around `UInt32` to avoid casting.
        let fieldNumber = Int(field.fieldNumber)
        let offset = field.offset
        switch field.fieldMode.cardinality {
        case .map:
            return serializedByteSize(
                ofMapField: field,
                fieldNumber: fieldNumber,
                mapEntryWorkingSpace: &mapEntryWorkingSpace
            )

        case .array:
            let isPacked = field.fieldMode.isPacked
            switch field.rawFieldType {
            case .bool:
                return fixedWidthRepeatedFieldSize(for: fieldNumber, at: offset, isPacked: isPacked, as: Bool.self)

            case .bytes:
                precondition(!isPacked, "a packed bytes field should not be reachable")
                let values = assumedPresentValue(at: offset, as: [Data].self)
                let tagSize = FieldTag.encodedSize(ofTagWithFieldNumber: fieldNumber)
                let dataSize = values.reduce(into: 0) { result, value in
                    let count = value.count
                    result += Varint.encodedSize(of: Int64(count)) + count
                }
                return (tagSize * values.count) + dataSize

            case .double:
                return fixedWidthRepeatedFieldSize(for: fieldNumber, at: offset, isPacked: isPacked, as: Double.self)

            case .enum:
                return serializedByteSize(ofRepeatedEnumField: field, fieldNumber: fieldNumber)

            case .fixed32:
                return fixedWidthRepeatedFieldSize(for: fieldNumber, at: offset, isPacked: isPacked, as: UInt32.self)

            case .fixed64:
                return fixedWidthRepeatedFieldSize(for: fieldNumber, at: offset, isPacked: isPacked, as: UInt64.self)

            case .float:
                return fixedWidthRepeatedFieldSize(for: fieldNumber, at: offset, isPacked: isPacked, as: Float.self)

            case .group:
                precondition(!isPacked, "a packed message/group field should not be reachable")
                return serializedByteSize(ofGroupField: field, fieldNumber: fieldNumber)

            case .int32:
                let values = assumedPresentValue(at: offset, as: [Int32].self)
                let tagSize = FieldTag.encodedSize(ofTagWithFieldNumber: fieldNumber)
                let dataSize = values.reduce(0) { $0 + Varint.encodedSize(of: $1) }
                return isPacked
                    ? tagSize + Varint.encodedSize(of: Int64(dataSize)) + dataSize
                    : (tagSize * values.count) + dataSize

            case .int64:
                let values = assumedPresentValue(at: offset, as: [Int64].self)
                let tagSize = FieldTag.encodedSize(ofTagWithFieldNumber: fieldNumber)
                let dataSize = values.reduce(0) { $0 + Varint.encodedSize(of: $1) }
                return isPacked
                    ? tagSize + Varint.encodedSize(of: Int64(dataSize)) + dataSize
                    : (tagSize * values.count) + dataSize

            case .message:
                precondition(!isPacked, "a packed message/group field should not be reachable")
                return serializedByteSize(ofMessageField: field, fieldNumber: fieldNumber)

            case .sfixed32:
                return fixedWidthRepeatedFieldSize(for: fieldNumber, at: offset, isPacked: isPacked, as: Int32.self)

            case .sfixed64:
                return fixedWidthRepeatedFieldSize(for: fieldNumber, at: offset, isPacked: isPacked, as: Int64.self)

            case .sint32:
                let values = assumedPresentValue(at: offset, as: [Int32].self)
                let tagSize = FieldTag.encodedSize(ofTagWithFieldNumber: fieldNumber)
                let dataSize = values.reduce(0) { $0 + Varint.encodedSize(of: ZigZag.encoded($1)) }
                return isPacked
                    ? tagSize + Varint.encodedSize(of: Int64(dataSize)) + dataSize
                    : (tagSize * values.count) + dataSize

            case .sint64:
                let values = assumedPresentValue(at: offset, as: [Int64].self)
                let tagSize = FieldTag.encodedSize(ofTagWithFieldNumber: fieldNumber)
                let dataSize = values.reduce(0) { $0 + Varint.encodedSize(of: ZigZag.encoded($1)) }
                return isPacked
                    ? tagSize + Varint.encodedSize(of: Int64(dataSize)) + dataSize
                    : (tagSize * values.count) + dataSize

            case .string:
                precondition(!isPacked, "a packed string field should not be reachable")
                let values = assumedPresentValue(at: offset, as: [String].self)
                let tagSize = FieldTag.encodedSize(ofTagWithFieldNumber: fieldNumber)
                let dataSize = values.reduce(into: 0) { result, value in
                    let count = value.utf8.count
                    result += Varint.encodedSize(of: Int64(count)) + count
                }
                return (tagSize * values.count) + dataSize

            case .uint32:
                let values = assumedPresentValue(at: offset, as: [UInt32].self)
                let tagSize = FieldTag.encodedSize(ofTagWithFieldNumber: fieldNumber)
                let dataSize = values.reduce(0) { $0 + Varint.encodedSize(of: $1) }
                return isPacked
                    ? tagSize + Varint.encodedSize(of: Int64(dataSize)) + dataSize
                    : (tagSize * values.count) + dataSize

            case .uint64:
                let values = assumedPresentValue(at: offset, as: [UInt64].self)
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
                let count = assumedPresentValue(at: offset, as: Data.self).count
                return FieldTag.encodedSize(ofTagWithFieldNumber: fieldNumber)
                    + Varint.encodedSize(of: Int64(count)) + count

            case .double:
                return fixedWidthSingularFieldSize(for: fieldNumber, as: Double.self)

            case .enum:
                return FieldTag.encodedSize(ofTagWithFieldNumber: fieldNumber)
                    + Varint.encodedSize(of: assumedPresentValue(at: offset, as: Int32.self))

            case .fixed32:
                return fixedWidthSingularFieldSize(for: fieldNumber, as: UInt32.self)

            case .fixed64:
                return fixedWidthSingularFieldSize(for: fieldNumber, as: UInt64.self)

            case .float:
                return fixedWidthSingularFieldSize(for: fieldNumber, as: Float.self)

            case .group:
                return serializedByteSize(ofGroupField: field, fieldNumber: fieldNumber)

            case .int32:
                return FieldTag.encodedSize(ofTagWithFieldNumber: fieldNumber)
                    + Varint.encodedSize(of: assumedPresentValue(at: offset, as: Int32.self))

            case .int64:
                return FieldTag.encodedSize(ofTagWithFieldNumber: fieldNumber)
                    + Varint.encodedSize(of: assumedPresentValue(at: offset, as: Int64.self))

            case .message:
                return serializedByteSize(ofMessageField: field, fieldNumber: fieldNumber)

            case .sfixed32:
                return fixedWidthSingularFieldSize(for: fieldNumber, as: Int32.self)

            case .sfixed64:
                return fixedWidthSingularFieldSize(for: fieldNumber, as: Int64.self)

            case .sint32:
                return FieldTag.encodedSize(ofTagWithFieldNumber: fieldNumber)
                    + Varint.encodedSize(of: ZigZag.encoded(assumedPresentValue(at: offset, as: Int32.self)))

            case .sint64:
                return FieldTag.encodedSize(ofTagWithFieldNumber: fieldNumber)
                    + Varint.encodedSize(of: ZigZag.encoded(assumedPresentValue(at: offset, as: Int64.self)))

            case .string:
                let count = assumedPresentValue(at: offset, as: String.self).utf8.count
                return FieldTag.encodedSize(ofTagWithFieldNumber: fieldNumber)
                    + Varint.encodedSize(of: Int64(count)) + count

            case .uint32:
                return FieldTag.encodedSize(ofTagWithFieldNumber: fieldNumber)
                    + Varint.encodedSize(of: assumedPresentValue(at: offset, as: UInt32.self))

            case .uint64:
                return FieldTag.encodedSize(ofTagWithFieldNumber: fieldNumber)
                    + Varint.encodedSize(of: assumedPresentValue(at: offset, as: UInt64.self))

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
        at offset: Int,
        isPacked: Bool,
        as type: T.Type
    ) -> Int {
        let tagSize = FieldTag.encodedSize(ofTagWithFieldNumber: fieldNumber)
        let count = assumedPresentValue(at: offset, as: [T].self).count
        if isPacked {
            let dataSize = count * MemoryLayout<T>.size
            return tagSize + Varint.encodedSize(of: Int64(dataSize)) + dataSize
        }
        return (tagSize + MemoryLayout<T>.size) * count
    }

    /// Returns the serialized byte size of the given repeated enum field.
    ///
    /// This function takes the field number as a separate argument even though it can be computed
    /// from the `FieldLayout` to avoid the (minor but non-zero) cost of decoding it again from the
    /// layout, since that has already been done by the caller.
    private func serializedByteSize(ofRepeatedEnumField field: FieldLayout, fieldNumber: Int) -> Int {
        var totalEnumsSize = 0
        var count = 0
        _ = try! layout.performOnRawEnumValues(
            _MessageLayout.TrampolineToken(index: field.submessageIndex),
            field,
            self,
            .read
        ) {
            count += 1
            totalEnumsSize += Varint.encodedSize(of: $0)
            return true
        } /*onInvalidValue*/ _: { _ in
        }
        if field.fieldMode.isPacked {
            // Packed: we need to add a single (length-delimited) tag and a varint for the length.
            return totalEnumsSize + FieldTag.encodedSize(ofTagWithFieldNumber: fieldNumber)
                + Varint.encodedSize(of: UInt64(totalEnumsSize))
        }
        // Unpacked: there will be a separate tag for each value.
        return totalEnumsSize + FieldTag.encodedSize(ofTagWithFieldNumber: fieldNumber) * count
    }

    /// Returns the serialized byte size of the given map field.
    ///
    /// This function takes the field number as a separate argument even though it can be computed
    /// from the `FieldLayout` to avoid the (minor but non-zero) cost of decoding it again from the
    /// layout, since that has already been done by the caller.
    private func serializedByteSize(
        ofMapField field: FieldLayout,
        fieldNumber: Int,
        mapEntryWorkingSpace: inout MapEntryWorkingSpace
    ) -> Int {
        var totalEntriesSize = 0
        _ = try! layout.performOnMapEntry(
            _MessageLayout.TrampolineToken(index: field.submessageIndex),
            field,
            self,
            mapEntryWorkingSpace.storage(for: field.submessageIndex),
            .read,
            // Deterministic ordering doesn't matter when calculating the size. Don't waste time
            // sorting.
            false
        ) {
            let entrySize = $0.serializedBytesSize()
            totalEntriesSize +=
                entrySize
                // Include the size of the length-delimited tag.
                + FieldTag.encodedSize(ofTagWithFieldNumber: fieldNumber)
                // Include the varint-encoded length.
                + Varint.encodedSize(of: UInt64(entrySize))
            return true
        }
        return totalEntriesSize
    }

    /// Returns the serialized byte size of the given submessage field.
    ///
    /// Since this function recurses via `performOnSubmessageStorage`, it supports both the singular
    /// case and the repeated case (i.e., calling this on a repeated field will iterate over all of
    /// the elements).
    ///
    /// This function takes the field number as a separate argument even though it can be computed
    /// from the `FieldLayout` to avoid the (minor but non-zero) cost of decoding it again from the
    /// layout, since that has already been done by the caller.
    private func serializedByteSize(ofMessageField field: FieldLayout, fieldNumber: Int) -> Int {
        var totalMessagesSize = 0
        _ = try! layout.performOnSubmessageStorage(
            _MessageLayout.TrampolineToken(index: field.submessageIndex),
            field,
            self,
            .read
        ) {
            let singleMessageSize = $0.serializedBytesSize()
            totalMessagesSize +=
                singleMessageSize
                // Include the size of the length-delimited tag.
                + FieldTag.encodedSize(ofTagWithFieldNumber: fieldNumber)
                // Include the varint-encoded length.
                + Varint.encodedSize(of: UInt64(singleMessageSize))
            return true
        }
        return totalMessagesSize
    }

    /// Returns the serialized byte size of the given `group` field.
    ///
    /// Since this function recurses via `performOnSubmessageStorage`, it supports both the singular
    /// case and the repeated case (i.e., calling this on a repeated field will iterate over all of
    /// the elements).
    ///
    /// This function takes the field number as a separate argument even though it can be computed
    /// from the `FieldLayout` to avoid the (minor but non-zero) cost of decoding it again from the
    /// layout, since that has already been done by the caller.
    private func serializedByteSize(ofGroupField field: FieldLayout, fieldNumber: Int) -> Int {
        var totalMessagesSize = 0
        _ = try! layout.performOnSubmessageStorage(
            _MessageLayout.TrampolineToken(index: field.submessageIndex),
            field,
            self,
            .read
        ) {
            totalMessagesSize +=
                $0.serializedBytesSize()
                // Include the size of the start tag and end tag.
                + 2 * FieldTag.encodedSize(ofTagWithFieldNumber: fieldNumber)
            return true
        }
        return totalMessagesSize
    }
}
