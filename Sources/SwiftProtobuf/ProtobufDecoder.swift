// Sources/SwiftProtobuf/ProtobufDecoder.swift - Binary decoding
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Protobuf binary format decoding engine.
///
/// This comprises:
///  * A scanner that handles low-level parsing of the binary data
///  * A decoder that provides higher-level structure knowledge
///  * A collection of FieldDecoder types that handle field-level
///    parsing for each wire type.
///
// -----------------------------------------------------------------------------

import Swift
import Foundation

public struct ProtobufDecoder: FieldDecoder {
    // Used only by packed repeated enums; see below
    internal var unknownOverride: Data?

    // Current position
    private var p : UnsafePointer<UInt8>
    // Remaining bytes in input.
    private var available : Int
    // Position of start of field currently being parsed
    private var fieldStartP : UnsafePointer<UInt8>
    // Position of end of field currently being parsed, nil if we don't know.
    private var fieldEndP : UnsafePointer<UInt8>?
    // Whether or not this field has actually been used
    private var consumed = false
    // Wire format for last-examined field
    private(set) var fieldWireFormat: WireFormat = .varint
    // Field number for last-parsed field tag
    private(set) var fieldNumber: Int = 0
    // Collection of extension fields for this decode
    private var extensions: ExtensionSet?

    var unknownData: Data?

    public var complete: Bool {return available == 0}


    internal init(protobufPointer: UnsafePointer<UInt8>, count: Int, extensions: ExtensionSet? = nil) {
        // Assuming baseAddress is not nil.
        p = protobufPointer
        available = count
        fieldStartP = p
        self.extensions = extensions
    }

    public mutating func asProtobufUnknown(protoFieldNumber: Int) throws -> Data? {
        if let override = unknownOverride {
            return override
        } else if !consumed {
            return try getRawField()
        } else {
            return nil
        }
    }

    public mutating func decodeSingularField<S: FieldType>(fieldType: S.Type, value: inout S.BaseType?) throws {
        guard fieldWireFormat == S.protobufWireFormat else {
            throw DecodingError.schemaMismatch
        }
        consumed = try S.setFromProtobuf(decoder: &self, value: &value)
    }

    public mutating func decodeSingularField<S: FieldType>(fieldType: S.Type, value: inout S.BaseType) throws {
        guard fieldWireFormat == S.protobufWireFormat else {
            throw DecodingError.schemaMismatch
        }
        consumed = try S.setFromProtobuf(decoder: &self, value: &value)
    }

    public mutating func decodeRepeatedField<S: FieldType>(fieldType: S.Type, value: inout [S.BaseType]) throws {
        consumed = try S.setFromProtobuf(decoder: &self, value: &value)
        // If `S` is Enum and the data was packed on the wire (regardless of
        // whether the schema prefers packed format), then the Enum may
        // have synthesized a new field to carry the unknown values.
        //unknownOverride = scanner.unknownOverride
    }

    public mutating func decodePackedField<S: FieldType>(fieldType: S.Type, value: inout [S.BaseType]) throws {
        try decodeRepeatedField(fieldType: fieldType, value: &value)
    }

    public mutating func decodeExtensionField(values: inout ExtensionFieldValueSet, messageType: Message.Type, protoFieldNumber: Int) throws {
        if let ext = extensions?[messageType, protoFieldNumber] {
            var fieldValue = values[protoFieldNumber] ?? ext.newField()
            try fieldValue.decodeField(setter: &self)
            values[protoFieldNumber] = fieldValue
        }
    }

    public mutating func decodeSingularMessageField<M: Message>(fieldType: M.Type, value: inout M?) throws {
        guard fieldWireFormat == .lengthDelimited else {
            throw DecodingError.schemaMismatch
        }
        var count: Int = 0
        let p = try getFieldBodyBytes(count: &count)
        if value == nil {
            value = try M(protobufBytes: p, count: count, extensions: extensions)
        } else {
            // If there's already a message object, overwrite fields with
            // new data and preserve old fields.
            try value!.decodeIntoSelf(protobufBytes: p, count: count, extensions: extensions)
        }
        consumed = true
    }

    public mutating func decodeRepeatedMessageField<M: Message>(fieldType: M.Type, value: inout [M]) throws {
        guard fieldWireFormat == .lengthDelimited else {
            throw DecodingError.schemaMismatch
        }
        var count: Int = 0
        let p = try getFieldBodyBytes(count: &count)
        var newValue = M()
        try newValue.decodeIntoSelf(protobufBytes: p, count: count, extensions: extensions)
        value.append(newValue)
        consumed = true
    }

    public mutating func decodeMapField<KeyType: FieldType, ValueType: MapValueType>(fieldType: ProtobufMap<KeyType, ValueType>.Type, value: inout ProtobufMap<KeyType, ValueType>.BaseType) throws where KeyType: MapKeyType, KeyType.BaseType: Hashable {
        var k: KeyType.BaseType?
        var v: ValueType.BaseType?
        var count: Int = 0
        let p = try getFieldBodyBytes(count: &count)
        var subdecoder = ProtobufDecoder(protobufPointer: p, count: count, extensions: extensions)
        while let tag = try subdecoder.getTag() {
            if tag.wireFormat == .endGroup {
                throw DecodingError.malformedProtobuf
            }
            let protoFieldNumber = tag.fieldNumber
            switch protoFieldNumber {
            case 1: // Keys are always basic types, so take a shortcut:
                try subdecoder.decodeSingularField(fieldType: KeyType.self, value: &k)
            case 2: // Values can be message or basic types, so use indirection:
                try ValueType.decodeProtobufMapValue(decoder: &subdecoder, value: &v)
            default: // Always ignore unknown fields within the map entry object
                return
            }
        }
        if !subdecoder.complete {
            throw DecodingError.trailingGarbage
        }

        if let k = k, let v = v {
            value[k] = v
        } else {
            throw DecodingError.malformedProtobuf
        }
    }

    public mutating func decodeSingularGroupField<G: Message>(fieldType: G.Type, value: inout G?) throws {
        var group = value ?? G()
        try decodeFullGroup(group: &group, protoFieldNumber: fieldNumber)
        value = group
        consumed = true
    }

    public mutating func decodeRepeatedGroupField<G: Message>(fieldType: G.Type, value: inout [G]) throws {
        var group = G()
        try decodeFullGroup(group: &group, protoFieldNumber: fieldNumber)
        value.append(group)
        consumed = true
    }

    mutating func decodeFullObject<M: Message>(message: inout M) throws {
        while let tag = try getTag() {
            if tag.wireFormat == .endGroup {
                throw DecodingError.malformedProtobuf
            }
            let protoFieldNumber = tag.fieldNumber
            consumed = false
            try message.decodeField(setter: &self, protoFieldNumber: protoFieldNumber)
            if let unknownBytes = try asProtobufUnknown(protoFieldNumber: protoFieldNumber) {
                if unknownData == nil {
                    unknownData = Data()
                }
                unknownData!.append(unknownBytes)
            }
        }
        if available != 0 {
            throw DecodingError.trailingGarbage
        }
    }

    private mutating func decodeFullGroup<G: Message>(group: inout G, protoFieldNumber: Int) throws {
        guard fieldWireFormat == .startGroup else {throw DecodingError.malformedProtobuf}
        while let tag = try getTag() {
            if tag.wireFormat == .endGroup {
                if tag.fieldNumber == protoFieldNumber {
                    return
                }
                throw DecodingError.malformedProtobuf
            }
            // Proto2 groups always consume fields or throw errors, so we can ignore return here
            try group.decodeField(setter: &self, protoFieldNumber: tag.fieldNumber)
            try skip()
        }
        throw DecodingError.truncatedInput
    }

    private mutating func consume(length: Int) {
        available -= length
        p += length
    }

    // Returns tagType for the field being skipped
    // Recursively processes groups; returns the start group marker
    private mutating func skipOver(tag: FieldTag) throws {
        switch tag.wireFormat {
        case .varint:
            if available < 1 {
                throw DecodingError.truncatedInput
            }
            var c = p[0]
            while (c & 0x80) != 0 {
                p += 1
                available -= 1
                if available < 1 {
                    throw DecodingError.truncatedInput
                }
                c = p[0]
            }
            p += 1
            available -= 1
        case .fixed64:
            if available < 8 {
                throw DecodingError.truncatedInput
            }
            p += 8
            available -= 8
        case .lengthDelimited:
            if let n = try getRawVarint(), n <= UInt64(available) {
                p += Int(n)
                available -= Int(n)
            } else {
                throw DecodingError.malformedProtobuf
            }
        case .startGroup:
            while true {
                if let innerTag = try getTagWithoutUpdatingFieldStart() {
                    if innerTag.fieldNumber == tag.fieldNumber {
                        if innerTag.wireFormat == .endGroup {
                            break
                        }
                    } else {
                        try skipOver(tag: innerTag)
                    }
                } else {
                    throw DecodingError.truncatedInput
                }
            }
        case .endGroup:
            throw DecodingError.malformedProtobuf
        case .fixed32:
            if available < 4 {
                throw DecodingError.truncatedInput
            }
            p += 4
            available -= 4
        }
    }

    // Jump to end of current field.
    //
    // This uses the bookmarked position saved by the last call to getTagType().
    // On exit, fieldStartP points to the first byte of the tag, fieldEndP points
    // to the first byte after the field contents.
    //
    private mutating func skip() throws {
        if let end = fieldEndP {
            p = end
        } else {
            available += p - fieldStartP
            p = fieldStartP
            guard let tag = try getTagWithoutUpdatingFieldStart() else {
                throw DecodingError.truncatedInput
            }
            try skipOver(tag: tag)
            fieldEndP = p
        }
    }

    // Nil at end-of-input, throws if broken varint
    private mutating func getRawVarint() throws -> UInt64? {
        if available < 1 {
            return nil
        }
        var start = p
        var length = available
        var c = start[0]
        start += 1
        length -= 1
        var value = UInt64(c & 0x7f)
        var shift = UInt64(7)
        while (c & 0x80) != 0 {
            if length < 1 || shift > 63 {
                throw DecodingError.malformedProtobuf
            }
            c = start[0]
            start += 1
            length -= 1
            value |= UInt64(c & 0x7f) << shift
            shift += 7
        }
        p = start
        available = length
        return value
    }

    // Parse index/type marker that starts each field.
    // This also bookmarks the start of field for a possible skip().
    private mutating func getTag() throws -> FieldTag? {
        fieldStartP = p
        fieldEndP = nil
        return try getTagWithoutUpdatingFieldStart()
    }

    // Parse index/type marker that starts each field.
    // Used during skipping to avoid updating the field start offset.
    private mutating func getTagWithoutUpdatingFieldStart() throws -> FieldTag? {
        if let t = try getRawVarint() {
            if t < UInt64(UInt32.max) {
                guard let tag = FieldTag(rawValue: UInt32(truncatingBitPattern: t)) else {
                    throw DecodingError.malformedProtobuf
                }
                fieldWireFormat = tag.wireFormat
                fieldNumber = tag.fieldNumber
                return tag
            } else {
                throw DecodingError.malformedProtobuf
            }
        }
        return nil
    }

    private mutating func getRawField() throws -> Data {
        try skip()
        return Data(bytes: fieldStartP, count: fieldEndP! - fieldStartP)
    }

    internal mutating func decodeVarint() throws -> UInt64 {
        if let v = try getRawVarint() {
            return v
        } else {
            throw DecodingError.truncatedInput
        }
    }

    internal mutating func decodeFourByteNumber<T>(value: inout T) throws {
        guard available >= 4 else {throw DecodingError.truncatedInput}
        withUnsafeMutablePointer(to: &value) { ip -> Void in
            let dest = UnsafeMutableRawPointer(ip).assumingMemoryBound(to: UInt8.self)
            let src = UnsafeRawPointer(p).assumingMemoryBound(to: UInt8.self)
            dest.initialize(from: src, count: 4)
        }
        consume(length: 4)
    }

    internal mutating func decodeEightByteNumber<T>(value: inout T) throws {
        guard available >= 8 else {throw DecodingError.truncatedInput}
        withUnsafeMutablePointer(to: &value) { ip -> Void in
            let dest = UnsafeMutableRawPointer(ip).assumingMemoryBound(to: UInt8.self)
            let src = UnsafeRawPointer(p).assumingMemoryBound(to: UInt8.self)
            dest.initialize(from: src, count: 8)
        }
        consume(length: 8)
    }

    internal mutating func getFieldBodyBytes(count: inout Int) throws -> UnsafePointer<UInt8> {
        if let length = try getRawVarint(), length <= UInt64(available) {
            count = Int(length)
            let body = p
            consume(length: count)
            return body
        }
        throw DecodingError.truncatedInput
    }
}
