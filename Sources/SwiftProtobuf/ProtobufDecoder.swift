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

private struct ProtobufFieldDecoder: FieldDecoder {
    let scanner: ProtobufScanner
    var consumed = false
    // Used only by packed repeated enums; see below
    var unknownOverride: Data?

    init(scanner: ProtobufScanner) {
        self.scanner = scanner
    }
    
    mutating func reset() {
        consumed = false
    }

    mutating func asProtobufUnknown(protoFieldNumber: Int) throws -> Data? {
        if let override = unknownOverride {
            return override
        } else if !consumed {
            return try scanner.getRawField()
        } else {
            return nil
        }
    }

    mutating func decodeSingularField<S: FieldType>(fieldType: S.Type, value: inout S.BaseType?) throws {
        consumed = try S.setFromProtobuf(scanner: scanner, value: &value)
    }

    mutating func decodeRepeatedField<S: FieldType>(fieldType: S.Type, value: inout [S.BaseType]) throws {
        consumed = try S.setFromProtobuf(scanner: scanner, value: &value)
        // If `S` is Enum and the data was packed on the wire (regardless of
        // whether the schema prefers packed format), then the Enum may
        // have synthesized a new field to carry the unknown values.
        unknownOverride = scanner.unknownOverride
    }

    mutating func decodePackedField<S: FieldType>(fieldType: S.Type, value: inout [S.BaseType]) throws {
        try decodeRepeatedField(fieldType: fieldType, value: &value)
    }

    mutating func decodeExtensionField(values: inout ExtensionFieldValueSet, messageType: Message.Type, protoFieldNumber: Int) throws {
        if let ext = scanner.extensions?[messageType, protoFieldNumber] {
            var mutableSetter: FieldDecoder = self
            var fieldValue = values[protoFieldNumber] ?? ext.newField()
            try fieldValue.decodeField(setter: &mutableSetter)
            values[protoFieldNumber] = fieldValue
            self.consumed = (mutableSetter as! ProtobufFieldDecoder).consumed
        }
    }

    mutating func decodeSingularMessageField<M: Message>(fieldType: M.Type, value: inout M?) throws {
        guard scanner.fieldWireFormat == .lengthDelimited else {
            throw DecodingError.schemaMismatch
        }
        if value == nil {
            value = M()
        }
        var count: Int = 0
        let p = try scanner.getFieldBodyBytes(count: &count)
        try value!.decodeIntoSelf(protobufBytes: p, count: count, extensions: scanner.extensions)
        consumed = true
    }

    mutating func decodeRepeatedMessageField<M: Message>(fieldType: M.Type, value: inout [M]) throws {
        guard scanner.fieldWireFormat == .lengthDelimited else {
            throw DecodingError.schemaMismatch
        }
        var count: Int = 0
        let p = try scanner.getFieldBodyBytes(count: &count)
        var newValue = M()
        try newValue.decodeIntoSelf(protobufBytes: p, count: count, extensions: scanner.extensions)
        value.append(newValue)
        consumed = true
    }

    mutating func decodeMapField<KeyType: FieldType, ValueType: MapValueType>(fieldType: ProtobufMap<KeyType, ValueType>.Type, value: inout ProtobufMap<KeyType, ValueType>.BaseType) throws where KeyType: MapKeyType, KeyType.BaseType: Hashable {
        var k: KeyType.BaseType?
        var v: ValueType.BaseType?
        var count: Int = 0
        let p = try scanner.getFieldBodyBytes(count: &count)
        var subdecoder = ProtobufDecoder(protobufPointer: p, count: count, extensions: scanner.extensions)
        try subdecoder.decodeFullObject {(decoder: inout FieldDecoder, protoFieldNumber: Int) throws in
            switch protoFieldNumber {
            case 1:
                // Keys are always basic types, so we can use the direct path here
                try decoder.decodeSingularField(fieldType: KeyType.self, value: &k)
            case 2:
                // Values can be message or basic types, so we need an indirection
                try ValueType.decodeProtobufMapValue(decoder: &decoder, value: &v)
            default: return // Ignore unused fields within the map entry object
            }
        }
        if let k = k, let v = v {
            value[k] = v
        } else {
            throw DecodingError.malformedProtobuf
        }
    }

    mutating func decodeSingularGroupField<G: Message>(fieldType: G.Type, value: inout G?) throws {
        var group = value ?? G()
        var decoder = ProtobufDecoder(scanner: scanner)
        try decoder.decodeFullGroup(group: &group, protoFieldNumber: scanner.fieldNumber)
        value = group
        consumed = true
    }

    mutating func decodeRepeatedGroupField<G: Message>(fieldType: G.Type, value: inout [G]) throws {
        var group = G()
        var decoder = ProtobufDecoder(scanner: scanner)
        try decoder.decodeFullGroup(group: &group, protoFieldNumber: scanner.fieldNumber)
        value.append(group)
        consumed = true
    }
}

/*
 * Decoder object for Protobuf Binary format.
 *
 * Note:  This object is instantiated with a pointer to the
 * data to be decoded.  That data is assumed to be stable
 * for the lifetime of this object.
 */
public struct ProtobufDecoder {
    private var scanner: ProtobufScanner
    var unknownData = Data()

    public var complete: Bool {return scanner.available == 0}
    public var fieldWireFormat: WireFormat {return scanner.fieldWireFormat}

    public init(protobufPointer: UnsafePointer<UInt8>, count: Int, extensions: ExtensionSet? = nil) {
        scanner = ProtobufScanner(protobufPointer: protobufPointer, count: count, extensions: extensions)
    }

    fileprivate init(scanner: ProtobufScanner) {
        self.scanner = scanner
    }

    // Only used by decodeMapField above...
    fileprivate mutating func decodeFullObject(decodeField: (inout FieldDecoder, Int) throws -> ()) throws {
        while let tag = try scanner.getTag() {
            if tag.wireFormat == .endGroup {
                throw DecodingError.malformedProtobuf
            }
            let protoFieldNumber = tag.fieldNumber
            var fieldDecoder: FieldDecoder = ProtobufFieldDecoder(scanner: scanner)
            try decodeField(&fieldDecoder, protoFieldNumber)
            if let unknownBytes = try fieldDecoder.asProtobufUnknown(protoFieldNumber: protoFieldNumber) {
                unknownData.append(unknownBytes)
            }
        }
        if scanner.available != 0 {
            throw DecodingError.trailingGarbage
        }
    }

    mutating func decodeFullObject<M: Message>(message: inout M) throws {
        var fieldDecoder: FieldDecoder = ProtobufFieldDecoder(scanner: scanner)
        while let tag = try scanner.getTag() {
            if tag.wireFormat == .endGroup {
                throw DecodingError.malformedProtobuf
            }
            let protoFieldNumber = tag.fieldNumber
            fieldDecoder.reset()
            try message.decodeField(setter: &fieldDecoder, protoFieldNumber: protoFieldNumber)
            if let unknownBytes = try fieldDecoder.asProtobufUnknown(protoFieldNumber: protoFieldNumber) {
                unknownData.append(unknownBytes)
            }
        }
        if scanner.available != 0 {
            throw DecodingError.trailingGarbage
        }
    }

    mutating func decodeFullGroup<G: Message>(group: inout G, protoFieldNumber: Int) throws {
        guard scanner.fieldWireFormat == .startGroup else {throw DecodingError.malformedProtobuf}
        while let tag = try scanner.getTag() {
            if tag.wireFormat == .endGroup {
                if tag.fieldNumber == protoFieldNumber {
                    return
                }
                throw DecodingError.malformedProtobuf
            }
            var fieldDecoder: FieldDecoder = ProtobufFieldDecoder(scanner: scanner)
            // Proto2 groups always consume fields or throw errors, so we can ignore return here
            try group.decodeField(setter: &fieldDecoder, protoFieldNumber: tag.fieldNumber)
            try scanner.skip()
        }
        throw DecodingError.truncatedInput
    }

    mutating func decodeFloat() throws -> Float? {
        guard scanner.available > 0 else {return nil}
        var i: Float = 0
        try scanner.decodeFourByteNumber(value: &i)
        return i
    }

    mutating func decodeDouble() throws -> Double? {
        guard scanner.available > 0 else {return nil}
        var i: Double = 0
        try scanner.decodeEightByteNumber(value: &i)
        return i
    }

    // Returns nil at end-of-input, throws on broken data
    mutating func decodeInt32() throws -> Int32? {
        if let t = try scanner.getRawVarint() {
            return Int32(truncatingBitPattern: t)
        } else {
            return nil
        }
    }

    // Returns nil at end-of-input, throws on broken data
    mutating func decodeInt64() throws -> Int64? {
        if let t = try scanner.getRawVarint() {
            return Int64(bitPattern: t)
        } else {
            return nil
        }
    }

    // Returns nil at end-of-input, throws on broken data
    mutating func decodeUInt32() throws -> UInt32? {
        if let t = try scanner.getRawVarint() {
            return UInt32(truncatingBitPattern: t)
        } else {
            return nil
        }
    }

    // Returns nil at end-of-input, throws on broken data
    mutating func decodeUInt64() throws -> UInt64? {
        if let t = try scanner.getRawVarint() {
            return t
        } else {
            return nil
        }
    }

    // Returns nil at end-of-input, throws on broken data
    mutating func decodeSInt32() throws -> Int32? {
        if let t = try scanner.getRawVarint() {
            let n = UInt32(truncatingBitPattern: t)
            return ZigZag.decoded(n)
        } else {
            return nil
        }
    }

    // Returns nil at end-of-input, throws on broken data
    mutating func decodeSInt64() throws -> Int64? {
        if let t = try scanner.getRawVarint() {
            return ZigZag.decoded(t)
        } else {
            return nil
        }
    }

    // Returns nil at end-of-input, throws on broken data
    mutating func decodeFixed32() throws -> UInt32? {
        guard scanner.available > 0 else {return nil}
        var i: UInt32 = 0
        try scanner.decodeFourByteNumber(value: &i)
        return UInt32(littleEndian: i)
    }

    // Returns nil at end-of-input, throws on broken data
    mutating func decodeFixed64() throws -> UInt64? {
        guard scanner.available > 0 else {return nil}
        var i: UInt64 = 0
        try scanner.decodeEightByteNumber(value: &i)
        return UInt64(littleEndian: i)
    }

    // Returns nil at end-of-input, throws on broken data
    mutating func decodeSFixed32() throws -> Int32? {
        guard scanner.available > 0 else {return nil}
        var i: Int32 = 0
        try scanner.decodeFourByteNumber(value: &i)
        return Int32(littleEndian: i)
    }

    // Returns nil at end-of-input, throws on broken data
    mutating func decodeSFixed64() throws -> Int64? {
        guard scanner.available > 0 else {return nil}
        var i: Int64 = 0
        try scanner.decodeEightByteNumber(value: &i)
        return Int64(littleEndian: i)
    }

    // Returns nil at end-of-input, throws on broken data
    mutating func decodeBool() throws -> Bool? {
        if let t = try scanner.getRawVarint() {
            return t != 0
        } else {
            return nil
        }
    }
}

public class ProtobufScanner {
    // Current position
    fileprivate var p : UnsafePointer<UInt8>
    // Remaining bytes in input.
    fileprivate var available : Int
    // Position of start of field currently being parsed
    private var fieldStartP : UnsafePointer<UInt8>
    // Position of end of field currently being parsed, nil if we don't know.
    private var fieldEndP : UnsafePointer<UInt8>?
    // Remaining bytes from start of field to end of input
    private var fieldStartAvailable : Int
    // Wire format for last-examined field
    private(set) var fieldWireFormat: WireFormat = .varint
    // Field number for last-parsed field tag
    private(set) var fieldNumber: Int = 0
    // Collection of extension fields for this decode
    fileprivate var extensions: ExtensionSet?
    // Holder for Enum fields to push back unknown values:
    internal var unknownOverride: Data?

    internal init(protobufPointer: UnsafePointer<UInt8>, count: Int, extensions: ExtensionSet? = nil) {
        // Assuming baseAddress is not nil.
        p = protobufPointer
        available = count
        fieldStartP = p
        fieldStartAvailable = available
        self.extensions = extensions
    }

    fileprivate func consume(length: Int) {
        available -= length
        p += length
    }

    // Returns tagType for the field being skipped
    // Recursively processes groups; returns the start group marker
    private func skipOver(tag: FieldTag) throws {
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
                    if innerTag.fieldNumber == tag.fieldNumber && innerTag.wireFormat == .endGroup {
                        break
                    } else if innerTag.fieldNumber != tag.fieldNumber {
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
    fileprivate func skip() throws {
        if let end = fieldEndP {
            p = end
        } else {
            p = fieldStartP
            available = fieldStartAvailable
            guard let tag = try getTagWithoutUpdatingFieldStart() else {
                throw DecodingError.truncatedInput
            }
            try skipOver(tag: tag)
            fieldEndP = p
        }
    }

    // Nil at end-of-input, throws if broken varint
    fileprivate func getRawVarint() throws -> UInt64? {
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
    fileprivate func getTag() throws -> FieldTag? {
        fieldStartP = p
        fieldEndP = nil
        fieldStartAvailable = available
        return try getTagWithoutUpdatingFieldStart()
    }

    // Parse index/type marker that starts each field.
    // Used during skipping to avoid updating the field start offset.
    private func getTagWithoutUpdatingFieldStart() throws -> FieldTag? {
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

    fileprivate func getRawField() throws -> Data {
        try skip()
        return Data(bytes: fieldStartP, count: fieldEndP! - fieldStartP)
    }

    internal func decodeVarint() throws -> UInt64 {
        if let v = try getRawVarint() {
            return v
        } else {
            throw DecodingError.truncatedInput
        }
    }

    internal func decodeFourByteNumber<T>(value: inout T) throws {
        guard available >= 4 else {throw DecodingError.truncatedInput}
        withUnsafeMutablePointer(to: &value) { ip -> Void in
            let dest = UnsafeMutableRawPointer(ip).assumingMemoryBound(to: UInt8.self)
            let src = UnsafeRawPointer(p).assumingMemoryBound(to: UInt8.self)
            dest.initialize(from: src, count: 4)
        }
        consume(length: 4)
    }

    internal func decodeEightByteNumber<T>(value: inout T) throws {
        guard available >= 8 else {throw DecodingError.truncatedInput}
        withUnsafeMutablePointer(to: &value) { ip -> Void in
            let dest = UnsafeMutableRawPointer(ip).assumingMemoryBound(to: UInt8.self)
            let src = UnsafeRawPointer(p).assumingMemoryBound(to: UInt8.self)
            dest.initialize(from: src, count: 8)
        }
        consume(length: 8)
    }

    func getFieldBodyBytes(count: inout Int) throws -> UnsafePointer<UInt8> {
        if let length = try getRawVarint(), length <= UInt64(available) {
            count = Int(length)
            let body = p
            consume(length: count)
            return body
        }
        throw DecodingError.truncatedInput
    }
}
