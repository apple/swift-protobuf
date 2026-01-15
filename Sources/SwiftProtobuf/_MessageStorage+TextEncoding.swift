// Sources/SwiftProtobuf/_MessageStorage+TextEncoding.swift - Text format encoding for messages
//
// Copyright (c) 2014 - 2026 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Text format encoding support for `_MessageStorage.`
///
// -----------------------------------------------------------------------------

import Foundation

extension _MessageStorage {
    /// Returns a string containing the Protocol Buffer text format serialization of the message.
    ///
    /// - Parameter options: The options to use when encoding the message.
    /// - Returns: A string containing the text format serialization of the message.
    public func textFormatString(options: TextFormatEncodingOptions) -> String {
        var encoder = TextFormatEncoder()
        serializeText(into: &encoder, options: options)
        return encoder.stringResult
    }

    /// A recursion helper that serializes the fields in the storage into the given text format encoder.
    private func serializeText(into encoder: inout TextFormatEncoder, options: TextFormatEncodingOptions) {
        var mapEntryWorkingSpace = MapEntryWorkingSpace(ownerLayout: layout)
        for field in layout.fields {
            guard isPresent(field) else { continue }
            serializeField(field, into: &encoder, mapEntryWorkingSpace: &mapEntryWorkingSpace, options: options)
        }
        if options.printUnknownFields {
            emitUnknownFields(bytes: unknownFields.data, into: &encoder)
        }
        // TODO: Support extensions.
    }

    /// Serializes a single field in the storage into the given text format encoder.
    private func serializeField(
        _ field: FieldLayout,
        into encoder: inout TextFormatEncoder,
        mapEntryWorkingSpace: inout MapEntryWorkingSpace,
        options: TextFormatEncodingOptions
    ) {
        let fieldNumber = Int(field.fieldNumber)
        let offset = field.offset

        switch field.fieldMode.cardinality {
        case .map:
            _ = try! layout.performOnMapEntry(
                _MessageLayout.TrampolineToken(index: field.submessageIndex),
                field,
                self,
                mapEntryWorkingSpace.storage(for: field.submessageIndex),
                .read,
                false  // useDeterministicOrdering
            ) {
                emitName(ofFieldNumber: fieldNumber, into: &encoder)
                encoder.startMessageField()
                $0.serializeText(into: &encoder, options: options)
                encoder.endMessageField()
                return true
            }

        case .array:
            let isPacked = field.fieldMode.isPacked

            func emitRepeatedField<Value>(_ emitValue: (Value) -> Void) {
                let values = assumedPresentValue(at: offset, as: [Value].self)
                if isPacked {
                    // Use the shorthand representation, "fieldName: [...]".
                    emitName(ofFieldNumber: fieldNumber, into: &encoder)
                    encoder.startRegularField()
                    encoder.startArray()
                    for value in values {
                        emitValue(value)
                    }
                    encoder.endArray()
                    encoder.endRegularField()
                } else {
                    // Each element is a fully serialized "name: value" pair.
                    for value in values {
                        emitName(ofFieldNumber: fieldNumber, into: &encoder)
                        encoder.startRegularField()
                        emitValue(value)
                        encoder.endRegularField()
                    }
                }
            }

            switch field.rawFieldType {
            case .bool:
                emitRepeatedField { encoder.putBoolValue(value: $0) }

            case .bytes:
                precondition(!isPacked, "a packed bytes field should not be reachable")
                emitRepeatedField { encoder.putBytesValue(value: $0) }

            case .double:
                emitRepeatedField { encoder.putDoubleValue(value: $0) }

            case .enum:
                // TODO: serializeInt32Field(assumedPresentValue(at: offset), for: fieldNumber, into: &encoder)
                break

            case .fixed32, .uint32:
                emitRepeatedField { (value: UInt32) in encoder.putUInt64(value: UInt64(value)) }

            case .fixed64, .uint64:
                emitRepeatedField { (value: UInt64) in encoder.putUInt64(value: value) }

            case .float:
                emitRepeatedField { encoder.putFloatValue(value: $0) }

            case .group, .message:
                precondition(!isPacked, "a packed group/message field should not be reachable")
                _ = try! layout.performOnSubmessageStorage(
                    _MessageLayout.TrampolineToken(index: field.submessageIndex),
                    field,
                    self,
                    .read
                ) {
                    emitName(ofFieldNumber: fieldNumber, into: &encoder)
                    encoder.startMessageField()
                    $0.serializeText(into: &encoder, options: options)
                    encoder.endMessageField()
                    return true
                }

            case .int32, .sfixed32, .sint32:
                emitRepeatedField { (value: Int32) in encoder.putInt64(value: Int64(value)) }

            case .int64, .sfixed64, .sint64:
                emitRepeatedField { (value: Int64) in encoder.putInt64(value: value) }

            case .string:
                precondition(!isPacked, "a packed string field should not be reachable")
                emitRepeatedField { encoder.putStringValue(value: $0) }

            default: preconditionFailure("Unreachable")
            }

        case .scalar:
            func emitScalarField<Value>(_ emitValue: (Value) -> Void) {
                emitName(ofFieldNumber: fieldNumber, into: &encoder)
                encoder.startRegularField()
                emitValue(assumedPresentValue(at: offset))
                encoder.endRegularField()
            }

            switch field.rawFieldType {
            case .bool:
                emitScalarField { encoder.putBoolValue(value: $0) }

            case .bytes:
                emitScalarField { encoder.putBytesValue(value: $0) }

            case .double:
                emitScalarField { encoder.putDoubleValue(value: $0) }

            case .enum:
                // TODO: serializeInt32Field(assumedPresentValue(at: offset), for: fieldNumber, into: &encoder)
                break

            case .fixed32, .uint32:
                emitScalarField { (value: UInt32) in encoder.putUInt64(value: UInt64(value)) }

            case .fixed64, .uint64:
                emitScalarField { (value: UInt64) in encoder.putUInt64(value: value) }

            case .float:
                emitScalarField { encoder.putFloatValue(value: $0) }

            case .group, .message:
                _ = try! layout.performOnSubmessageStorage(
                    _MessageLayout.TrampolineToken(index: field.submessageIndex),
                    field,
                    self,
                    .read
                ) {
                    emitName(ofFieldNumber: fieldNumber, into: &encoder)
                    encoder.startMessageField()
                    $0.serializeText(into: &encoder, options: options)
                    encoder.endMessageField()
                    return true
                }

            case .int32, .sfixed32, .sint32:
                emitScalarField { (value: Int32) in encoder.putInt64(value: Int64(value)) }

            case .int64, .sfixed64, .sint64:
                emitScalarField { (value: Int64) in encoder.putInt64(value: value) }

            case .string:
                emitScalarField { encoder.putStringValue(value: $0) }

            default: preconditionFailure("Unreachable")
            }

        default: preconditionFailure("Unreachable")
        }
    }

    /// Emits the name of the field with the given number to the encoder.
    ///
    /// If the field name cannot be found, the field number is used instead.
    private func emitName(ofFieldNumber fieldNumber: Int, into encoder: inout TextFormatEncoder) {
        // TODO: Check extensions if the first check fails.
        if let protoName = layout.nameMap.names(for: fieldNumber)?.proto {
            encoder.emitFieldName(name: protoName.utf8Buffer)
        } else {
            encoder.emitFieldNumber(number: fieldNumber)
        }
    }

    /// Emits the unknown fields represented by the given binary blob into the given text format
    /// encoder.
    private func emitUnknownFields(bytes: Data, into encoder: inout TextFormatEncoder) {
        bytes.withUnsafeBytes { (body: UnsafeRawBufferPointer) -> Void in
            if let baseAddress = body.baseAddress, body.count > 0 {
                // All fields will be directly handled, so there is no need for
                // the unknown field buffering/collection (when scannings to see
                // if something is a message, this would be extremely wasteful).
                var binaryOptions = BinaryDecodingOptions()
                binaryOptions.discardUnknownFields = true
                var decoder = BinaryDecoder(
                    forReadingFrom: baseAddress,
                    count: body.count,
                    options: binaryOptions
                )
                emitUnknownFields(decoder: &decoder, into: &encoder)
            }
        }
    }

    /// Helper for printing out unknown fields by decoding them from the given binary decoder
    /// (which wraps the original unknown fields binary blob)..
    ///
    /// The implementation tries to be "helpful" and if a length delimited field appears to be a
    /// submessage, it prints it as such. However, that opens the door to someone sending a message
    /// with an unknown field that is a stack bomb; i.e., it causes this code to recurse, exhausting
    /// the stack and thus opening up an attack vector. To keep this "help" but avoid the attack, a
    /// limit is placed on how many times it will recurse before just treating the length delimited
    /// fields as bytes and not trying to decode them.
    private func emitUnknownFields(
        decoder: inout BinaryDecoder,
        into encoder: inout TextFormatEncoder,
        recursionBudget: Int = 10
    ) {
        // This stack serves to avoid recursion for groups within groups within groups..., avoiding
        // the stack attack that the message detection hits. No limit is placed on this because
        // there is no stack risk with recursion, and because if a limit was hit, there is no other
        // way to encode the group (the message field can just print as length-delimited; groups
        // don't have an option like that).
        var groupFieldNumberStack: [Int] = []

        while let tag = try! decoder.getTag() {
            switch tag.wireFormat {
            case .varint:
                encoder.emitFieldNumber(number: tag.fieldNumber)
                var value: UInt64 = 0
                encoder.startRegularField()
                try! decoder.decodeSingularUInt64Field(value: &value)
                encoder.putUInt64(value: value)
                encoder.endRegularField()

            case .fixed64:
                encoder.emitFieldNumber(number: tag.fieldNumber)
                var value: UInt64 = 0
                encoder.startRegularField()
                try! decoder.decodeSingularFixed64Field(value: &value)
                encoder.putUInt64Hex(value: value, digits: 16)
                encoder.endRegularField()

            case .lengthDelimited:
                encoder.emitFieldNumber(number: tag.fieldNumber)
                var bytes = Data()
                try! decoder.decodeSingularBytesField(value: &bytes)
                var encodeAsBytes = true
                if bytes.count > 0 && recursionBudget > 0 {
                    bytes.withUnsafeBytes { (body: UnsafeRawBufferPointer) -> Void in
                        if let baseAddress = body.baseAddress, body.count > 0 {
                            do {
                                // Walk all the fields to test if it looks like a message.
                                var testDecoder = BinaryDecoder(
                                    forReadingFrom: baseAddress,
                                    count: body.count,
                                    parent: decoder
                                )
                                while let _ = try testDecoder.nextFieldNumber() {}

                                // If there was no error, output the fields as a message body.
                                encodeAsBytes = false
                                var subDecoder = BinaryDecoder(
                                    forReadingFrom: baseAddress,
                                    count: bytes.count,
                                    parent: decoder
                                )
                                encoder.startMessageField()
                                emitUnknownFields(
                                    decoder: &subDecoder,
                                    into: &encoder,
                                    recursionBudget: recursionBudget - 1
                                )
                                encoder.endMessageField()
                            } catch {
                                // Fall back to encoding the fields as a binary blob.
                                encodeAsBytes = true
                            }
                        }
                    }
                }
                if encodeAsBytes {
                    encoder.startRegularField()
                    encoder.putBytesValue(value: bytes)
                    encoder.endRegularField()
                }

            case .startGroup:
                encoder.emitFieldNumber(number: tag.fieldNumber)
                encoder.startMessageField()
                groupFieldNumberStack.append(tag.fieldNumber)

            case .endGroup:
                let groupFieldNumber = groupFieldNumberStack.popLast()
                // Unknown data is scanned and verified by the binary parser, so this can never
                // fail.
                assert(tag.fieldNumber == groupFieldNumber)
                encoder.endMessageField()

            case .fixed32:
                encoder.emitFieldNumber(number: tag.fieldNumber)
                var value: UInt32 = 0
                encoder.startRegularField()
                try! decoder.decodeSingularFixed32Field(value: &value)
                encoder.putUInt64Hex(value: UInt64(value), digits: 8)
                encoder.endRegularField()
            }
        }

        // Unknown data is scanned and verified by the binary parser, so this can never fail.
        assert(groupFieldNumberStack.isEmpty)
    }
}
