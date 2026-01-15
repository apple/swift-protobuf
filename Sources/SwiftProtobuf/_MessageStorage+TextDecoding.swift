// Sources/SwiftProtobuf/_MessageStorage+TextDecoding.swift - Text format decoding for messages
//
// Copyright (c) 2014 - 2026 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Text format decoding support for `_MessageStorage.`
///
// -----------------------------------------------------------------------------

import Foundation

extension _MessageStorage {
    // TODO: This is only called by the generated code. Remove it once we've cleaned up the
    // protocol requirements.
    public func merge(
        byParsingTextFormatString textFormatString: String,
        options: TextFormatDecodingOptions
    ) throws {
        var textFormatString = textFormatString
        try textFormatString.withUTF8 {
            try merge(byParsingTextFormatBytes: $0, options: options)
        }
    }

    /// Decodes field values from the given binary-encoded buffer into this storage class.
    ///
    /// - Parameters:
    ///   - buffer: The binary-encoded message data to decode.
    ///   - partial: If `false` (the default), this method will check
    ///     ``Message/isInitialized-6abgi`` after decoding to verify that all required
    ///     fields are present. If any are missing, this method throws
    ///     ``BinaryDecodingError/missingRequiredFields``.
    ///   - options: The ``BinaryDecodingOptions`` to use.
    /// - Throws: ``BinaryDecodingError`` if decoding fails.
    public func merge(
        byParsingTextFormatBytes buffer: UnsafeBufferPointer<UInt8>,
        options: TextFormatDecodingOptions
    ) throws {
        guard buffer.baseAddress != nil, buffer.count > 0 else { return }

        // TODO: Support extensions.
        var reader = TextFormatReader(
            buffer: buffer,
            nameMap: layout.nameMap,
            options: options,
            extensions: nil
        )
        try merge(byParsingTextFormatFrom: &reader)

        guard reader.complete else {
            throw TextFormatDecodingError.trailingGarbage
        }
    }

    private func merge(byParsingTextFormatFrom reader: inout TextFormatReader) throws {
        var mapEntryWorkingSpace = MapEntryWorkingSpace(ownerLayout: layout)
        while let fieldNumber = try reader.nextFieldNumber() {
            guard let field = layout[fieldNumber: fieldNumber] else {
                // The scanner should have already skipped any unknown fields or thrown an error
                // (depending on the decoding options), so any field we get back from this reader
                // should always exist.
                preconditionFailure("unreachable")
            }

            try decodeNextFieldValue(from: &reader, field: field, mapEntryWorkingSpace: &mapEntryWorkingSpace)
        }
    }

    private func decodeNextFieldValue(
        from reader: inout TextFormatReader,
        field: FieldLayout,
        mapEntryWorkingSpace: inout MapEntryWorkingSpace
    ) throws {
        let fieldType = field.rawFieldType

        // A colon after the field name is required unless it's a group/message field.
        switch fieldType {
        case .group, .message:
            _ = reader.scanner.skipOptionalColon()
        default:
            try reader.scanner.skipRequiredColon()
        }

        switch field.fieldMode.cardinality {
        case .map:
            try scanPossibleArray(from: &reader) { reader in
                _ = try layout.performOnMapEntry(
                    _MessageLayout.TrampolineToken(index: field.submessageIndex),
                    field,
                    self,
                    mapEntryWorkingSpace.storage(for: field.submessageIndex),
                    .append,
                    // Deterministic ordering doesn't apply to decoding.
                    false
                ) { submessageStorage in
                    let mapEntryLayout = submessageStorage.layout
                    try reader.withReaderForNextObject(expectedLayout: mapEntryLayout) { subReader in
                        try submessageStorage.merge(byParsingTextFormatFrom: &subReader)

                        // Throw an error if the key or the value was missing.
                        guard
                            submessageStorage.isPresent(mapEntryLayout[fieldNumber: 1]!)
                                && submessageStorage.isPresent(mapEntryLayout[fieldNumber: 2]!)
                        else {
                            throw TextFormatDecodingError.malformedText
                        }
                    }
                    return true
                }
            }

        case .array:
            try scanPossibleArray(from: &reader) { reader in
                switch fieldType {
                case .bool:
                    appendValue(try reader.scanner.nextBool(), to: field)

                case .bytes:
                    appendValue(try reader.scanner.nextBytesValue(), to: field)

                case .double:
                    appendValue(try reader.scanner.nextDouble(), to: field)

                case .enum:
                    // TODO: Support enums.
                    break

                case .fixed32, .uint32:
                    let n = try reader.scanner.nextSInt()
                    if n > UInt64(UInt32.max) {
                        throw TextFormatDecodingError.malformedNumber
                    }
                    appendValue(UInt32(truncatingIfNeeded: n), to: field)

                case .fixed64, .uint64:
                    appendValue(try reader.scanner.nextUInt(), to: field)

                case .float:
                    appendValue(try reader.scanner.nextFloat(), to: field)

                case .group, .message:
                    try scanSubmessageValue(field, from: &reader, operation: .append)

                case .int32, .sfixed32, .sint32:
                    let n = try reader.scanner.nextSInt()
                    if n > Int64(Int32.max) || n < Int64(Int32.min) {
                        throw TextFormatDecodingError.malformedNumber
                    }
                    appendValue(Int32(truncatingIfNeeded: n), to: field)

                case .int64, .sfixed64, .sint64:
                    appendValue(try reader.scanner.nextSInt(), to: field)

                case .string:
                    appendValue(try reader.scanner.nextStringValue(), to: field)

                default:
                    preconditionFailure("Unreachable")
                }
            }

        case .scalar:
            switch fieldType {
            case .bool:
                updateValue(of: field, to: try reader.scanner.nextBool())

            case .bytes:
                updateValue(of: field, to: try reader.scanner.nextBytesValue())

            case .double:
                updateValue(of: field, to: try reader.scanner.nextDouble())

            case .enum:
                // TODO: Support enums.
                break

            case .fixed32, .uint32:
                let n = try reader.scanner.nextUInt()
                if n > UInt64(UInt32.max) {
                    throw TextFormatDecodingError.malformedNumber
                }
                updateValue(of: field, to: UInt32(truncatingIfNeeded: n))

            case .fixed64, .uint64:
                updateValue(of: field, to: try reader.scanner.nextUInt())

            case .float:
                updateValue(of: field, to: try reader.scanner.nextFloat())

            case .group, .message:
                try scanSubmessageValue(field, from: &reader, operation: .mutate)

            case .int32, .sfixed32, .sint32:
                let n = try reader.scanner.nextSInt()
                if n > Int64(Int32.max) || n < Int64(Int32.min) {
                    throw TextFormatDecodingError.malformedNumber
                }
                updateValue(of: field, to: Int32(truncatingIfNeeded: n))

            case .int64, .sfixed64, .sint64:
                updateValue(of: field, to: try reader.scanner.nextSInt())

            case .string:
                updateValue(of: field, to: try reader.scanner.nextStringValue())

            default:
                preconditionFailure("Unreachable")
            }

        default:
            preconditionFailure("Unreachable")
        }
    }

    /// Called to scan the next value, which might be an array of values.
    ///
    /// In text format, repeated fields of non-message types can be represented in two ways:
    /// repetition of the field name and value, or as the field name followed by an array of values
    /// in square brackets. If we detect the square bracket, we delegate to the given closure to
    /// scan and append the value until we encounter the corresponding closing bracket. Otherwise,
    /// we call the closure only once to scan and append an individual value.
    private func scanPossibleArray(
        from reader: inout TextFormatReader,
        scanAndAppendSingleValue: (inout TextFormatReader) throws -> Void
    ) throws {
        guard reader.scanner.skipOptionalBeginArray() else {
            // If we didn't see a square bracket, assume it's a single element and call the closure
            // once.
            try scanAndAppendSingleValue(&reader)
            return
        }

        // We saw a left bracket, so read multiple elements, calling the closure for each one.
        var firstItem = true
        while true {
            if reader.scanner.skipOptionalEndArray() {
                return
            }
            if firstItem {
                firstItem = false
            } else {
                try reader.scanner.skipRequiredComma()
            }
            try scanAndAppendSingleValue(&reader)
        }
    }

    /// Scans the submessage value of the given field from the reader, performing the given
    /// operation on its storage (either mutate or append).
    private func scanSubmessageValue(
        _ field: FieldLayout,
        from reader: inout TextFormatReader,
        operation: TrampolineFieldOperation
    ) throws {
        _ = try layout.performOnSubmessageStorage(
            _MessageLayout.TrampolineToken(index: field.submessageIndex),
            field,
            self,
            operation
        ) { submessageStorage in
            try reader.withReaderForNextObject(expectedLayout: submessageStorage.layout) { subReader in
                try submessageStorage.merge(byParsingTextFormatFrom: &subReader)
            }
            return true
        }
    }
}
