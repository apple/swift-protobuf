// ProtobufRuntime/Sources/Protobuf/ProtobufBinaryDecoding.swift - Binary decoding
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
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

private protocol ProtobufFieldDecoder: FieldDecoder {
    var scanner: ProtobufScanner {get}
    var consumed: Bool {get set}
}

extension ProtobufFieldDecoder {
    mutating func decodeExtensionField(values: inout ExtensionFieldValueSet, messageType: Message.Type, protoFieldNumber: Int) throws {
        if let ext = scanner.extensions?[messageType, protoFieldNumber] {
            var mutableSetter: FieldDecoder = self
            var fieldValue = values[protoFieldNumber] ?? ext.newField()
            try fieldValue.decodeField(setter: &mutableSetter)
            values[protoFieldNumber] = fieldValue
            self.consumed = (mutableSetter as! ProtobufFieldDecoder).consumed
        }
    }
}

private struct FieldWireTypeVarint: ProtobufFieldDecoder {
    let varint: UInt64
    let unknown: UnsafeBufferPointer<UInt8>
    let scanner: ProtobufScanner
    var consumed = false

    init(varint: UInt64, unknown: UnsafeBufferPointer<UInt8>, scanner: ProtobufScanner) {
        self.varint = varint
        self.unknown = unknown
        self.scanner = scanner
    }

    mutating func decodeSingularField<S: FieldType>(fieldType: S.Type, value: inout S.BaseType?) throws {
        consumed = try S.setFromProtobufVarint(varint: varint, value: &value)
    }

    mutating func decodeRepeatedField<S: FieldType>(fieldType: S.Type, value: inout [S.BaseType]) throws {
        consumed = try S.setFromProtobufVarint(varint: varint, value: &value)
    }

    mutating func decodePackedField<S: FieldType>(fieldType: S.Type, value: inout [S.BaseType]) throws {
        consumed = try S.setFromProtobufVarint(varint: varint, value: &value)
    }

    mutating func asProtobufUnknown(protoFieldNumber: Int) throws -> Data? {
        return consumed ? nil : Data(buffer: unknown)
    }
}

private struct FieldWireTypeFixed64: ProtobufFieldDecoder {
    let fixed8: [UInt8]
    let unknown: UnsafeBufferPointer<UInt8>
    let scanner: ProtobufScanner
    var consumed = false

    init(fixed8: [UInt8], unknown: UnsafeBufferPointer<UInt8>, scanner: ProtobufScanner) {
        self.fixed8 = fixed8
        self.unknown = unknown
        self.scanner = scanner
    }

    mutating func decodeSingularField<S: FieldType>(fieldType: S.Type, value: inout S.BaseType?) throws {
        try S.setFromProtobufFixed8(fixed8: fixed8, value: &value)
        consumed = true
    }

    mutating func decodeRepeatedField<S: FieldType>(fieldType: S.Type, value: inout [S.BaseType]) throws {
        try S.setFromProtobufFixed8(fixed8: fixed8, value: &value)
        consumed = true
    }

    mutating func decodePackedField<S: FieldType>(fieldType: S.Type, value: inout [S.BaseType]) throws {
        try S.setFromProtobufFixed8(fixed8: fixed8, value: &value)
        consumed = true
    }

    mutating func asProtobufUnknown(protoFieldNumber: Int) throws -> Data? {
        return consumed ? nil : Data(buffer: unknown)
    }
}

private struct FieldWireTypeLengthDelimited: ProtobufFieldDecoder {
    let buffer: UnsafeBufferPointer<UInt8>
    let unknown: UnsafeBufferPointer<UInt8>
    let scanner: ProtobufScanner
    var consumed = false
    var unknownOverride: Data?

    init(buffer: UnsafeBufferPointer<UInt8>, unknown: UnsafeBufferPointer<UInt8>, scanner: ProtobufScanner) {
        self.buffer = buffer
        self.unknown = unknown
        self.scanner = scanner
    }

    mutating func decodeSingularField<S: FieldType>(fieldType: S.Type, value: inout S.BaseType?) throws {
        try S.setFromProtobufBuffer(buffer: buffer, value: &value)
        consumed = true
    }

    mutating func decodeRepeatedField<S: FieldType>(fieldType: S.Type, value: inout [S.BaseType]) throws {
        var unknownData = Data()
        try S.setFromProtobufBuffer(buffer: buffer, value: &value, unknown: &unknownData)
        consumed = true
        if !unknownData.isEmpty {
            unknownOverride = unknownData
        }
    }

    mutating func decodePackedField<S: FieldType>(fieldType: S.Type, value: inout [S.BaseType]) throws {
        var unknownData = Data()
        try S.setFromProtobufBuffer(buffer: buffer, value: &value, unknown: &unknownData)
        consumed = true
        if !unknownData.isEmpty {
            unknownOverride = unknownData
        }
    }

    mutating func decodeSingularMessageField<M: Message>(fieldType: M.Type, value: inout M?) throws {
        if value == nil {
            value = M()
        }
        try value!.decodeIntoSelf(protobuf: buffer, extensions: scanner.extensions)
        consumed = true
    }

    mutating func decodeRepeatedMessageField<M: Message>(fieldType: M.Type, value: inout [M]) throws {
        var newValue = M()
        try newValue.decodeIntoSelf(protobuf: buffer, extensions: scanner.extensions)
        value.append(newValue)
        consumed = true
    }

    mutating func decodeMapField<KeyType: FieldType, ValueType: MapValueType>(fieldType: Map<KeyType, ValueType>.Type, value: inout Map<KeyType, ValueType>.BaseType) throws where KeyType: MapKeyType, KeyType.BaseType: Hashable {
        var k: KeyType.BaseType?
        var v: ValueType.BaseType?
        var subdecoder = ProtobufDecoder(protobufPointer: buffer, extensions: scanner.extensions)
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

    mutating func asProtobufUnknown(protoFieldNumber: Int) throws -> Data? {
        if let override = unknownOverride {
            let fieldTag = FieldTag(fieldNumber: protoFieldNumber, wireFormat: .lengthDelimited)
            let dataSize = Varint.encodedSize(of: fieldTag.rawValue) + Varint.encodedSize(of: Int64(override.count)) + override.count
            var data = Data(count: dataSize)
            data.withUnsafeMutableBytes { (pointer: UnsafeMutablePointer<UInt8>) -> () in
                var encoder = ProtobufEncoder(pointer: pointer)
                encoder.startField(tag: fieldTag)
                encoder.putBytesValue(value: override)
            }
            return data
        } else if !consumed {
            return Data(buffer: unknown)
        } else {
            return nil
        }
    }
}

private struct FieldWireTypeStartGroup: ProtobufFieldDecoder {
    let scanner: ProtobufScanner
    let protoFieldNumber: Int
    var consumed = false

    init(scanner: ProtobufScanner, protoFieldNumber: Int) {
        self.scanner = scanner
        self.protoFieldNumber = protoFieldNumber
    }

    mutating func decodeSingularGroupField<G: Message>(fieldType: G.Type, value: inout G?) throws {
        var group = value ?? G()
        var decoder = ProtobufDecoder(scanner: scanner)
        try decoder.decodeFullGroup(group: &group, protoFieldNumber: protoFieldNumber)
        value = group
        consumed = true
    }

    mutating func decodeRepeatedGroupField<G: Message>(fieldType: G.Type, value: inout [G]) throws {
        var group = G()
        var decoder = ProtobufDecoder(scanner: scanner)
        try decoder.decodeFullGroup(group: &group, protoFieldNumber: protoFieldNumber)
        value.append(group)
        consumed = true
    }

    mutating func asProtobufUnknown(protoFieldNumber: Int) throws -> Data? {
        return consumed ? nil : Data(buffer: try scanner.skip())
    }
}

private struct FieldWireTypeFixed32: ProtobufFieldDecoder {
    let fixed4: [UInt8]
    let unknown: UnsafeBufferPointer<UInt8>
    let scanner: ProtobufScanner
    var consumed = false

    init(fixed4: [UInt8], unknown: UnsafeBufferPointer<UInt8>, scanner: ProtobufScanner) {
        self.fixed4 = fixed4
        self.unknown = unknown
        self.scanner = scanner
    }


    mutating func decodeSingularField<S: FieldType>(fieldType: S.Type, value: inout S.BaseType?) throws {
        try S.setFromProtobufFixed4(fixed4: fixed4, value: &value)
        consumed = true
    }

    mutating func decodeRepeatedField<S: FieldType>(fieldType: S.Type, value: inout [S.BaseType]) throws {
        try S.setFromProtobufFixed4(fixed4: fixed4, value: &value)
        consumed = true
    }

    mutating func decodePackedField<S: FieldType>(fieldType: S.Type, value: inout [S.BaseType]) throws {
        try S.setFromProtobufFixed4(fixed4: fixed4, value: &value)
        consumed = true
    }

    mutating func asProtobufUnknown(protoFieldNumber: Int) throws -> Data? {
        return consumed ? nil : Data(buffer: unknown)
    }
}

/*
 * Decoder object for Protobuf Binary format.
 *
 * Note:  This object is instantiated with an UnsafeBufferPointer<UInt8>
 * that is assumed to be stable for the lifetime of this object.
 */
public struct ProtobufDecoder {
    private var scanner: ProtobufScanner
    var unknownData = Data()

    public var complete: Bool {return scanner.available == 0}
    public var fieldWireFormat: WireFormat {return scanner.fieldWireFormat}

    public init(protobufPointer: UnsafeBufferPointer<UInt8>, extensions: ExtensionSet? = nil) {
        scanner = ProtobufScanner(protobufPointer: protobufPointer, extensions: extensions)
    }

    fileprivate init(scanner: ProtobufScanner) {
        self.scanner = scanner
    }

    internal func getTag() throws -> FieldTag? {
        return try scanner.getTag()
    }

    @discardableResult
    internal func skip() throws -> UnsafeBufferPointer<UInt8> {
        return try scanner.skip()
    }

    public mutating func decodeFullObject(decodeField: (inout FieldDecoder, Int) throws -> ()) throws {
        while let tag = try scanner.getTag() {
            let protoFieldNumber = tag.fieldNumber
            var fieldDecoder = try decoder(forFieldNumber: protoFieldNumber, scanner: scanner)
            try decodeField(&fieldDecoder, protoFieldNumber)
            if let unknownBytes = try fieldDecoder.asProtobufUnknown(protoFieldNumber: protoFieldNumber) {
                unknownData.append(unknownBytes)
            }
        }
        if scanner.available != 0 {
            throw DecodingError.trailingGarbage
        }
    }

    public mutating func decodeFullObject<M: Message>(message: inout M) throws {
        try decodeFullObject {(setter: inout FieldDecoder, protoFieldNumber: Int) throws in
            try message.decodeField(setter: &setter, protoFieldNumber: protoFieldNumber)
        }
    }

    public mutating func decodeFullGroup<G: Message>(group: inout G, protoFieldNumber: Int) throws {
        guard scanner.fieldWireFormat == .startGroup else {throw DecodingError.malformedProtobuf}
        while let tag = try scanner.getTag() {
            if tag.fieldNumber == protoFieldNumber {
                if tag.wireFormat == .endGroup {
                    return
                }
                break // Fail and exit
            }
            var fieldDecoder = try decoder(forFieldNumber: protoFieldNumber, scanner: scanner)
            // Proto2 groups always consume fields or throw errors, so we can ignore return here
            let _ = try group.decodeField(setter: &fieldDecoder, protoFieldNumber: tag.fieldNumber)
        }
        throw DecodingError.truncatedInput
    }

    private mutating func decoder(forFieldNumber fieldNumber: Int, scanner: ProtobufScanner) throws -> FieldDecoder {
        switch scanner.fieldWireFormat {
        case .varint:
            let value = try getVarint()
            let raw = try scanner.getRawField()
            return FieldWireTypeVarint(varint: value, unknown: raw, scanner: scanner)
        case .fixed64:
            let value = try getFixed8()
            let raw = try scanner.getRawField()
            return FieldWireTypeFixed64(fixed8: value, unknown: raw, scanner: scanner)
        case .lengthDelimited:
            let value = try getBytesRef()
            let raw = try scanner.getRawField()
            return FieldWireTypeLengthDelimited(buffer: value, unknown: raw, scanner: scanner)
        case .startGroup:
            return FieldWireTypeStartGroup(scanner: scanner, protoFieldNumber: fieldNumber)
        case .endGroup:
            throw DecodingError.malformedProtobuf
        case .fixed32:
            let value = try getFixed4()
            let raw = try scanner.getRawField()
            return FieldWireTypeFixed32(fixed4: value, unknown: raw, scanner: scanner)
        }
    }

    // Marks failure if no or broken varint but returns zero
    fileprivate mutating func getVarint() throws -> UInt64 {
        if let t = try scanner.getRawVarint() {
            return t
        }
        throw DecodingError.malformedProtobuf
    }

    fileprivate mutating func getFixed8() throws -> [UInt8] {
        guard scanner.available >= 8 else {throw DecodingError.truncatedInput}
        var i = Array<UInt8>(repeating: 0, count: 8)
        i.withUnsafeMutableBufferPointer { ip -> Void in
            let src = UnsafeMutablePointer<UInt8>(mutating: scanner.p)
            ip.baseAddress!.initialize(from: src, count: 8)
        }
        scanner.consume(length: 8)
        return i
    }

    fileprivate mutating func getFixed4() throws -> [UInt8] {
        guard scanner.available >= 4 else {throw DecodingError.truncatedInput}
        var i = Array<UInt8>(repeating: 0, count: 4)
        i.withUnsafeMutableBufferPointer { ip -> Void in
            let src = UnsafeMutablePointer<UInt8>(mutating: scanner.p)
            ip.baseAddress!.initialize(from: src, count: 4)
        }
        scanner.consume(length: 4)
        return i
    }

    mutating func decodeFloat() throws -> Float? {
        guard scanner.available > 0 else {return nil}
        guard scanner.available >= 4 else {throw DecodingError.truncatedInput}
        var i: Float = 0
        withUnsafeMutablePointer(to: &i) { ip -> Void in
            let dest = UnsafeMutableRawPointer(ip).assumingMemoryBound(to: UInt8.self)
            let src = UnsafeRawPointer(scanner.p).assumingMemoryBound(to: UInt8.self)
            dest.initialize(from: src, count: 4)
        }
        scanner.consume(length: 4)
        return i
    }

    mutating func decodeDouble() throws -> Double? {
        guard scanner.available > 0 else {return nil}
        guard scanner.available >= 8 else {throw DecodingError.truncatedInput}
        var i: Double = 0
        withUnsafeMutablePointer(to: &i) { ip -> Void in
            let dest = UnsafeMutableRawPointer(ip).assumingMemoryBound(to: UInt8.self)
            let src = UnsafeRawPointer(scanner.p).assumingMemoryBound(to: UInt8.self)
            dest.initialize(from: src, count: 8)
        }
        scanner.consume(length: 8)
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
            return unZigZag32(zigZag: t)
        } else {
            return nil
        }
    }

    // Returns nil at end-of-input, throws on broken data
    mutating func decodeSInt64() throws -> Int64? {
        if let t = try scanner.getRawVarint() {
            return unZigZag64(zigZag: t)
        } else {
            return nil
        }
    }

    // Returns nil at end-of-input, throws on broken data
    mutating func decodeFixed32() throws -> UInt32? {
        guard scanner.available > 0 else {return nil}
        guard scanner.available >= 4 else {throw DecodingError.truncatedInput}
        var i: UInt32 = 0
        withUnsafeMutablePointer(to: &i) { ip -> Void in
            let dest = UnsafeMutableRawPointer(ip).assumingMemoryBound(to: UInt8.self)
            let src = UnsafeRawPointer(scanner.p).assumingMemoryBound(to: UInt8.self)
            dest.initialize(from: src, count: 4)
        }
        scanner.consume(length: 4)
        return UInt32(littleEndian: i)
    }

    // Returns nil at end-of-input, throws on broken data
    mutating func decodeFixed64() throws -> UInt64? {
        guard scanner.available > 0 else {return nil}
        guard scanner.available >= 8 else {throw DecodingError.truncatedInput}
        var i: UInt64 = 0
        withUnsafeMutablePointer(to: &i) { ip -> Void in
            let dest = UnsafeMutableRawPointer(ip).assumingMemoryBound(to: UInt8.self)
            let src = UnsafeRawPointer(scanner.p).assumingMemoryBound(to: UInt8.self)
            dest.initialize(from: src, count: 8)
        }
        scanner.consume(length: 8)
        return UInt64(littleEndian: i)
    }

    // Returns nil at end-of-input, throws on broken data
    mutating func decodeSFixed32() throws -> Int32? {
        guard scanner.available > 0 else {return nil}
        guard scanner.available >= 4 else {throw DecodingError.truncatedInput}
        var i: Int32 = 0
        withUnsafeMutablePointer(to: &i) { ip -> Void in
            let dest = UnsafeMutableRawPointer(ip).assumingMemoryBound(to: UInt8.self)
            let src = UnsafeRawPointer(scanner.p).assumingMemoryBound(to: UInt8.self)
            dest.initialize(from: src, count: 4)
        }
        scanner.consume(length: 4)
        return Int32(littleEndian: i)
    }

    // Returns nil at end-of-input, throws on broken data
    mutating func decodeSFixed64() throws -> Int64? {
        guard scanner.available > 0 else {return nil}
        guard scanner.available >= 8 else {throw DecodingError.truncatedInput}
        var i: Int64 = 0
        withUnsafeMutablePointer(to: &i) { ip -> Void in
            let dest = UnsafeMutableRawPointer(ip).assumingMemoryBound(to: UInt8.self)
            let src = UnsafeRawPointer(scanner.p).assumingMemoryBound(to: UInt8.self)
            dest.initialize(from: src, count: 8)
        }
        scanner.consume(length: 8)
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

    // Throws on broken data or premature end-of-input
    mutating func decodeBytes() throws -> [UInt8]? {
        return [UInt8](try getBytesRef())
    }

    mutating func getBytesRef() throws -> UnsafeBufferPointer<UInt8> {
        if let length = try scanner.getRawVarint(), length <= UInt64(scanner.available) {
            let n = Int(length)
            let bp = UnsafeBufferPointer<UInt8>(start: scanner.p, count: n)
            scanner.consume(length: n)
            return bp
        }
        throw DecodingError.truncatedInput
    }

    // Convert a 64-bit value from zigzag coding.
    fileprivate func unZigZag64(zigZag: UIntMax) -> Int64 {
        return ZigZag.decoded(zigZag)
    }

    // Convert a 32-bit value from zigzag coding.
    fileprivate func unZigZag32(zigZag: UIntMax) -> Int32 {
        let t = UInt32(truncatingBitPattern: zigZag)
        return ZigZag.decoded(t)
    }
}

private class ProtobufScanner {
    // Current position
    var p : UnsafePointer<UInt8>
    // Remaining bytes in input.
    var available : Int
    // Position of start of field currently being parsed
    private var fieldStartP : UnsafePointer<UInt8>
    // Remaining bytes from start of field to end of input
    var fieldStartAvailable : Int
    // Wire format for last-examined field
    var fieldWireFormat: WireFormat = .varint
    // Collection of extension fields for this decode
    var extensions: ExtensionSet?

    init(protobufPointer: UnsafeBufferPointer<UInt8>, extensions: ExtensionSet? = nil) {
        // Assuming baseAddress is not nil.
        p = protobufPointer.baseAddress!
        available = protobufPointer.count
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
    func skipOver(tag: FieldTag) throws {
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

    // Returns block of bytes representing the skipped field or nil if failure.
    //
    // This uses the bookmarked position saved by the last call to getTagType().
    //
    func skip() throws -> UnsafeBufferPointer<UInt8> {
        p = fieldStartP
        available = fieldStartAvailable
        guard let tag = try getTagWithoutUpdatingFieldStart() else {
            throw DecodingError.truncatedInput
        }
        try skipOver(tag: tag)
        return UnsafeBufferPointer<UInt8>(start: fieldStartP, count: p - fieldStartP)
    }

    // Nil at end-of-input, throws if broken varint
    func getRawVarint() throws -> UInt64? {
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
    func getTag() throws -> FieldTag? {
        fieldStartP = p
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
                return tag
            } else {
                throw DecodingError.malformedProtobuf
            }
        }
        return nil
    }

    func getRawField() throws -> UnsafeBufferPointer<UInt8> {
        let s = fieldStartP
        let c = p - fieldStartP
        return UnsafeBufferPointer<UInt8>(start: s, count: c)
    }
}
