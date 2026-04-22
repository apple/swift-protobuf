// Sources/SwiftProtobuf/MessageStorage+TextEncoding.swift - Text format encoding for messages
//
// Copyright (c) 2014 - 2026 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Text format encoding support for `MessageStorage.`
///
// -----------------------------------------------------------------------------

import Foundation

extension MessageStorage {
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
    func serializeText(into encoder: inout TextFormatEncoder, options: TextFormatEncodingOptions) {
        var mapEntryWorkingSpace = MapEntryWorkingSpace(ownerSchema: schema)

        switch CustomJSONWKTClassification(messageSchema: schema) {
        case .any:
            emitAsAny(into: &encoder, mapEntryWorkingSpace: &mapEntryWorkingSpace, options: options)

        default:
            for field in schema.fields {
                guard isPresent(field) else { continue }
                serializeField(field, into: &encoder, mapEntryWorkingSpace: &mapEntryWorkingSpace, options: options)
            }
        }

        if options.printUnknownFields {
            emitUnknownFields(bytes: unknownFields.data, into: &encoder)
        }
        extensionStorage.serializeText(into: &encoder, options: options)
    }

    /// Emits the text format representation of the receiver as a well-known-type `Any` to the
    /// encoder.
    ///
    /// If the message type is in the global registry, this function parses it and emits the
    /// verbose form of `Any` text encoding, which renders the type URL like an extension field (in
    /// square brackets) and then prints the value as a fully expanded message. If the type is not
    /// registered, emit it in standard form.
    ///
    /// - Precondition: The receiver must be the storage for `google.protobuf.Any`.
    private func emitAsAny(
        into encoder: inout TextFormatEncoder,
        mapEntryWorkingSpace: inout MapEntryWorkingSpace,
        options: TextFormatEncodingOptions
    ) {
        let typeURLField = schema[fieldNumber: 1]!
        let valueField = schema[fieldNumber: 2]!
        let valueOffset = valueField.offset
        let isValuePresent = isPresent(valueField)

        // If we can unpack it, emit the verbose form.
        let typeURL = value(of: typeURLField) as String
        if isValuePresent, let messageSchema = Google_Protobuf_Any.messageSchema(forTypeURL: typeURL) {
            let messageStorage = MessageStorage(schema: messageSchema)
            let bytes = assumedPresentValue(at: valueOffset) as Data
            do {
                try bytes.withUnsafeBytes { buffer in
                    try messageStorage.merge(
                        byReadingFrom: buffer,
                        extensions: options.extensions,
                        partial: false,
                        options: BinaryDecodingOptions()
                    )
                }
                encoder.emitExtensionFieldName(name: typeURL)
                encoder.startMessageField()
                messageStorage.serializeText(into: &encoder, options: options)
                encoder.endMessageField()
                return
            } catch {
                // Fall back to emitting the standard form below.
            }
        }

        // Otherwise, emit the fields in their standard form (binary serialized string).
        if isPresent(typeURLField) {
            serializeField(typeURLField, into: &encoder, mapEntryWorkingSpace: &mapEntryWorkingSpace, options: options)
        }
        if isValuePresent {
            let bytes = assumedPresentValue(at: valueOffset) as Data
            emitName(ofFieldNumber: valueField.fieldNumber, into: &encoder)
            encoder.startRegularField()
            encoder.putBytesValue(value: bytes)
            encoder.endRegularField()
        }
    }

    /// Serializes a single field in the storage into the given text format encoder.
    private func serializeField(
        _ field: FieldSchema,
        into encoder: inout TextFormatEncoder,
        mapEntryWorkingSpace: inout MapEntryWorkingSpace,
        options: TextFormatEncodingOptions
    ) {
        let fieldNumber = field.fieldNumber
        let fieldType = field.rawFieldType
        let offset = field.offset

        switch field.fieldMode.cardinality {
        case .map:
            _ = try! schema.performOnMapEntry(
                MessageSchema.TrampolineToken(index: field.submessageIndex),
                field,
                self,
                mapEntryWorkingSpace.storage(for: field.submessageIndex),
                .read,
                true  // useDeterministicOrdering
            ) {
                emitName(ofFieldNumber: fieldNumber, into: &encoder)
                encoder.startMessageField()
                let mapEntrySchema = $0.schema
                if let keyField = mapEntrySchema[fieldNumber: 1] {
                    $0.serializeField(keyField, into: &encoder, mapEntryWorkingSpace: &mapEntryWorkingSpace, options: options)
                }
                if let valueField = mapEntrySchema[fieldNumber: 2] {
                    $0.serializeField(valueField, into: &encoder, mapEntryWorkingSpace: &mapEntryWorkingSpace, options: options)
                }
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
                    var firstItem = true
                    for value in values {
                        if !firstItem {
                            encoder.arraySeparator()
                        }
                        emitValue(value)
                        firstItem = false
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

            switch fieldType {
            case .bool:
                emitRepeatedField { encoder.putBoolValue(value: $0) }

            case .bytes:
                precondition(!isPacked, "a packed bytes field should not be reachable")
                emitRepeatedField { encoder.putBytesValue(value: $0) }

            case .double:
                emitRepeatedField { encoder.putDoubleValue(value: $0) }

            case .enum:
                emitRepeatedEnumField(field, into: &encoder)

            case .fixed32, .uint32:
                emitRepeatedField { (value: UInt32) in encoder.putUInt64(value: UInt64(value)) }

            case .fixed64, .uint64:
                emitRepeatedField { (value: UInt64) in encoder.putUInt64(value: value) }

            case .float:
                emitRepeatedField { encoder.putFloatValue(value: $0) }

            case .group, .message:
                precondition(!isPacked, "a packed group/message field should not be reachable")
                _ = try! schema.performOnSubmessageStorage(
                    MessageSchema.TrampolineToken(index: field.submessageIndex),
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
            emitName(ofFieldNumber: fieldNumber, into: &encoder)

            // Handle groups/messages separately since they have different delimiters than regular
            // fields.
            switch fieldType {
            case .group, .message:
                _ = try! schema.performOnSubmessageStorage(
                    MessageSchema.TrampolineToken(index: field.submessageIndex),
                    field,
                    self,
                    .read
                ) {
                    encoder.startMessageField()
                    $0.serializeText(into: &encoder, options: options)
                    encoder.endMessageField()
                    return true
                }
                return

            default:
                // Continue below.
                break
            }

            encoder.startRegularField()

            switch fieldType {
            case .bool:
                encoder.putBoolValue(value: assumedPresentValue(at: offset))

            case .bytes:
                encoder.putBytesValue(value: assumedPresentValue(at: offset))

            case .double:
                encoder.putDoubleValue(value: assumedPresentValue(at: offset))

            case .enum:
                _ = try! schema.performOnRawEnumValues(
                    MessageSchema.TrampolineToken(index: field.submessageIndex),
                    field,
                    self,
                    .read
                ) { enumSchema, value in
                    encoder.putEnumValue(rawValue: value, enumSchema: enumSchema)
                    return true
                } /*onInvalidValue*/ _: { _ in
                    assertionFailure("invalid value handler should never be called for .read")
                }

            case .fixed32, .uint32:
                encoder.putUInt64(value: UInt64(assumedPresentValue(at: offset) as UInt32))

            case .fixed64, .uint64:
                encoder.putUInt64(value: assumedPresentValue(at: offset))

            case .float:
                encoder.putFloatValue(value: assumedPresentValue(at: offset))

            case .int32, .sfixed32, .sint32:
                encoder.putInt64(value: Int64(assumedPresentValue(at: offset) as Int32))

            case .int64, .sfixed64, .sint64:
                encoder.putInt64(value: assumedPresentValue(at: offset))

            case .string:
                encoder.putStringValue(value: assumedPresentValue(at: offset))

            default: preconditionFailure("Unreachable")
            }

            encoder.endRegularField()

        default: preconditionFailure("Unreachable")
        }
    }

    /// Emits the name of the field with the given number to the encoder.
    ///
    /// If the field name cannot be found, the field number is used instead.
    private func emitName(ofFieldNumber fieldNumber: UInt32, into encoder: inout TextFormatEncoder) {
        if let name = schema.textName(forFieldNumber: fieldNumber) {
            encoder.emitFieldName(name: name)
        } else {
            encoder.emitFieldNumber(number: Int(fieldNumber))
        }
    }

    /// Emits the name and values of a repeated enum field, using compact representation if the
    /// field is packed.
    private func emitRepeatedEnumField(_ field: FieldSchema, into encoder: inout TextFormatEncoder) {
        let fieldNumber = field.fieldNumber
        if field.fieldMode.isPacked {
            // Use the shorthand representation, "fieldName: [...]".
            emitName(ofFieldNumber: fieldNumber, into: &encoder)
            encoder.startRegularField()
            encoder.startArray()
            var firstItem = true

            _ = try! schema.performOnRawEnumValues(
                MessageSchema.TrampolineToken(index: field.submessageIndex),
                field,
                self,
                .read
            ) { enumSchema, value in
                if !firstItem {
                    encoder.arraySeparator()
                }
                encoder.putEnumValue(rawValue: value, enumSchema: enumSchema)
                firstItem = false
                return true
            } /*onInvalidValue*/ _: { _ in
                assertionFailure("invalid value handler should never be called for .read")
            }

            encoder.endArray()
            encoder.endRegularField()
        } else {
            // Each element is a fully serialized "name: value" pair.
            _ = try! schema.performOnRawEnumValues(
                MessageSchema.TrampolineToken(index: field.submessageIndex),
                field,
                self,
                .read
            ) { enumSchema, value in
                emitName(ofFieldNumber: fieldNumber, into: &encoder)
                encoder.startRegularField()
                encoder.putEnumValue(rawValue: value, enumSchema: enumSchema)
                encoder.endRegularField()
                return true
            } /*onInvalidValue*/ _: { _ in
                assertionFailure("invalid value handler should never be called for .read")
            }
        }
    }

    /// Emits the unknown fields represented by the given binary blob into the given text format
    /// encoder.
    private func emitUnknownFields(bytes: Data, into encoder: inout TextFormatEncoder) {
        bytes.withUnsafeBytes { (body: UnsafeRawBufferPointer) -> Void in
            if body.count > 0 {
                var reader = WireFormatReader(buffer: body, recursionBudget: 10)
                emitUnknownFields(reader: &reader, into: &encoder)
            }
        }
    }

    /// Helper for printing out unknown fields by decoding them from the given wire format reader
    /// (which wraps the original unknown fields binary blob).
    ///
    /// The implementation tries to be "helpful" and if a length delimited field appears to be a
    /// submessage, it prints it as such. However, that opens the door to someone sending a message
    /// with an unknown field that is a stack bomb; i.e., it causes this code to recurse, exhausting
    /// the stack and thus opening up an attack vector. To keep this "help" but avoid the attack, a
    /// limit is placed on how many times it will recurse before just treating the length delimited
    /// fields as bytes and not trying to decode them.
    private func emitUnknownFields(reader: inout WireFormatReader, into encoder: inout TextFormatEncoder) {
        // This stack serves to avoid recursion for groups within groups within groups, avoiding
        // the stack attack that the message detection hits. No limit is placed on this because
        // there is no stack risk with recursion, and because if a limit was hit, there is no other
        // way to encode the group (the message field can just print as length-delimited; groups
        // don't have an option like that).
        var groupFieldNumberStack: [Int] = []

        while reader.hasAvailableData {
            guard let tag = try? reader.nextTagWithoutGroupCheck() else {
                // Stop processing unknown fields if we encounter malformed data.
                return
            }
            switch tag.wireFormat {
            case .varint:
                encoder.emitFieldNumber(number: tag.fieldNumber)
                encoder.startRegularField()
                let value = try! reader.nextVarint()
                encoder.putUInt64(value: value)
                encoder.endRegularField()

            case .fixed64:
                encoder.emitFieldNumber(number: tag.fieldNumber)
                encoder.startRegularField()
                let value = try! reader.nextLittleEndianUInt64()
                encoder.putUInt64Hex(value: value, digits: 16)
                encoder.endRegularField()

            case .lengthDelimited:
                encoder.emitFieldNumber(number: tag.fieldNumber)
                let slice = try! reader.nextLengthDelimitedSlice()
                var encodeAsBytes = true
                if slice.count > 0 && reader.recursionBudget > 0 {
                    do {
                        // Walk all the fields to test if it looks like a message.
                        var testReader = WireFormatReader(buffer: slice, recursionBudget: 0)
                        while testReader.hasAvailableData {
                            let innerTag = try testReader.nextTag()
                            _ = try testReader.sliceBySkippingField(tag: innerTag)
                        }

                        // If there was no error, output the fields as a message body.
                        encodeAsBytes = false
                        var subReader = WireFormatReader(buffer: slice, recursionBudget: reader.recursionBudget - 1)
                        encoder.startMessageField()
                        emitUnknownFields(reader: &subReader, into: &encoder)
                        encoder.endMessageField()
                    } catch {
                        // Fall back to encoding the fields as a binary blob.
                        encodeAsBytes = true
                    }
                }
                if encodeAsBytes {
                    encoder.startRegularField()
                    let bytes = Data(bytes: slice.baseAddress!, count: slice.count)
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
                encoder.startRegularField()
                let value = try! reader.nextLittleEndianUInt32()
                encoder.putUInt64Hex(value: UInt64(value), digits: 8)
                encoder.endRegularField()
            }
        }

        // Unknown data is scanned and verified by the binary parser, so this can never fail.
        assert(groupFieldNumberStack.isEmpty)
    }
}
