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

private protocol ProtobufBinaryFieldDecoder: ProtobufFieldDecoder {
    var scanner: ProtobufScanner {get}
}

extension ProtobufBinaryFieldDecoder {
    mutating func decodeExtensionField(values: inout ProtobufExtensionFieldValueSet, messageType: ProtobufMessage.Type, protoFieldNumber: Int) throws -> Bool {
        if let ext = scanner.extensions?[messageType, protoFieldNumber] {
            var mutableSetter: ProtobufFieldDecoder = self
            var fieldValue = values[protoFieldNumber] ?? ext.newField()
            if try fieldValue.decodeField(setter: &mutableSetter) {
                values[protoFieldNumber] = fieldValue
                return true
            }
        }
        return false
    }
}

private struct ProtobufFieldWireType0: ProtobufBinaryFieldDecoder {
    let varint: UInt64
    let unknown: UnsafeBufferPointer<UInt8>
    let scanner: ProtobufScanner

    mutating func decodeOptionalField<S: ProtobufTypeProperties>(fieldType: S.Type, value: inout S.BaseType?) throws -> Bool {
        return try S.setFromProtobufVarint(varint: varint, value: &value)
    }

    mutating func decodeRequiredField<S: ProtobufTypeProperties>(fieldType: S.Type, value: inout S.BaseType) throws -> Bool {
        var t: S.BaseType?
        let handled = try S.setFromProtobufVarint(varint: varint, value: &t)
        if let t = t, handled {
            value = t
            return true
        }
        throw ProtobufDecodingError.schemaMismatch
    }

    mutating func decodeRepeatedField<S: ProtobufTypeProperties>(fieldType: S.Type, value: inout [S.BaseType]) throws -> Bool {
        return try S.setFromProtobufVarint(varint: varint, value: &value)
    }

    mutating func decodePackedField<S: ProtobufTypeProperties>(fieldType: S.Type, value: inout [S.BaseType]) throws -> Bool {
        return try S.setFromProtobufVarint(varint: varint, value: &value)
    }


    mutating func asProtobufUnknown() throws -> [UInt8]? {
        return [UInt8](unknown)
    }
}

private struct ProtobufFieldWireType1: ProtobufBinaryFieldDecoder {
    let fixed8: [UInt8]
    let unknown: UnsafeBufferPointer<UInt8>
    let scanner: ProtobufScanner

    mutating func decodeOptionalField<S: ProtobufTypeProperties>(fieldType: S.Type, value: inout S.BaseType?) throws -> Bool {
        return try S.setFromProtobufFixed8(fixed8: fixed8, value: &value)
    }

    mutating func decodeRequiredField<S: ProtobufTypeProperties>(fieldType: S.Type, value: inout S.BaseType) throws -> Bool {
        var t: S.BaseType?
        let handled = try S.setFromProtobufFixed8(fixed8: fixed8, value: &t)
        if let t = t, handled {
            value = t
            return true
        }
        throw ProtobufDecodingError.schemaMismatch
    }

    mutating func decodeRepeatedField<S: ProtobufTypeProperties>(fieldType: S.Type, value: inout [S.BaseType]) throws -> Bool {
        return try S.setFromProtobufFixed8(fixed8: fixed8, value: &value)
    }

    mutating func decodePackedField<S: ProtobufTypeProperties>(fieldType: S.Type, value: inout [S.BaseType]) throws -> Bool {
        return try S.setFromProtobufFixed8(fixed8: fixed8, value: &value)
    }

    mutating func asProtobufUnknown() throws -> [UInt8]? {
        return [UInt8](unknown)
    }
}

private struct ProtobufFieldWireType2: ProtobufBinaryFieldDecoder {
    let buffer: UnsafeBufferPointer<UInt8>
    let unknown: UnsafeBufferPointer<UInt8>
    let scanner: ProtobufScanner

    mutating func decodeOptionalField<S: ProtobufTypeProperties>(fieldType: S.Type, value: inout S.BaseType?) throws -> Bool {
        return try S.setFromProtobufBuffer(buffer: buffer, value: &value)
    }

    mutating func decodeRequiredField<S: ProtobufTypeProperties>(fieldType: S.Type, value: inout S.BaseType) throws -> Bool {
        var t: S.BaseType?
        let handled = try S.setFromProtobufBuffer(buffer: buffer, value: &t)
        if let t = t, handled {
            value = t
            return true
        }
        throw ProtobufDecodingError.schemaMismatch
    }

    mutating func decodeRepeatedField<S: ProtobufTypeProperties>(fieldType: S.Type, value: inout [S.BaseType]) throws -> Bool {
        return try S.setFromProtobufBuffer(buffer: buffer, value: &value)
    }

    mutating func decodePackedField<S: ProtobufTypeProperties>(fieldType: S.Type, value: inout [S.BaseType]) throws -> Bool {
        return try S.setFromProtobufBuffer(buffer: buffer, value: &value)
    }

    mutating func decodeOptionalMessageField<M: ProtobufMessage>(fieldType: M.Type, value: inout M?) throws -> Bool {
        var v = value ?? M()
        var subDecoder = ProtobufBinaryDecoder(protobufPointer: buffer, extensions: scanner.extensions)
        try subDecoder.decodeFullObject(message: &v)
        value = v
        return true
    }

    mutating func decodeRepeatedMessageField<M: ProtobufMessage>(fieldType: M.Type, value: inout [M]) throws -> Bool {
        value.append(try M(protobufBuffer: buffer, extensions: scanner.extensions))
        return true
    }

    mutating func decodeMapField<KeyType: ProtobufTypeProperties, ValueType: ProtobufMapValueType>(fieldType: ProtobufMap<KeyType, ValueType>.Type, value: inout ProtobufMap<KeyType, ValueType>.BaseType) throws -> Bool where KeyType: ProtobufMapKeyType, KeyType.BaseType: Hashable {
        var k: KeyType.BaseType?
        var v: ValueType.BaseType?
        var subdecoder = ProtobufBinaryDecoder(protobufPointer: buffer, extensions: scanner.extensions)
        try subdecoder.decodeFullObject {(decoder: inout ProtobufFieldDecoder, protoFieldNumber: Int) throws -> Bool in
            switch protoFieldNumber {
            case 1:
                // Keys are always basic types, so we can use the direct path here
                let handled = try decoder.decodeOptionalField(fieldType: KeyType.self, value: &k)
                if !handled {
                    return false
                }
            case 2:
                // Values can be message or basic types, so we need an indirection
                try ValueType.decodeProtobufMapValue(decoder: &decoder, value: &v)
            default: return false // Unhandled
            }
            return true
        }
        if let k = k, let v = v {
            value[k] = v
            return true
        }
        throw ProtobufDecodingError.malformedProtobuf
    }

    mutating func asProtobufUnknown() throws -> [UInt8]? {
        return [UInt8](unknown)
    }
}

private struct ProtobufFieldWireType3: ProtobufBinaryFieldDecoder {
    let scanner: ProtobufScanner
    let protoFieldNumber: Int

    mutating func decodeOptionalGroupField<G: ProtobufGroup>(fieldType: G.Type, value: inout G?) throws -> Bool {
        var group = value ?? G()
        var decoder = ProtobufBinaryDecoder(scanner: scanner)
        try decoder.decodeFullGroup(group: &group, protoFieldNumber: protoFieldNumber)
        value = group
        return true
    }

    mutating func decodeRepeatedGroupField<G: ProtobufGroup>(fieldType: G.Type, value: inout [G]) throws -> Bool {
        var group = G()
        var decoder = ProtobufBinaryDecoder(scanner: scanner)
        try decoder.decodeFullGroup(group: &group, protoFieldNumber: protoFieldNumber)
        value.append(group)
        return true
    }

    mutating func asProtobufUnknown() throws -> [UInt8]? {
        return [UInt8](try scanner.skip())
    }
}

private struct ProtobufFieldWireType5: ProtobufBinaryFieldDecoder {
    let fixed4: [UInt8]
    let unknown: UnsafeBufferPointer<UInt8>
    let scanner: ProtobufScanner

    mutating func decodeOptionalField<S: ProtobufTypeProperties>(fieldType: S.Type, value: inout S.BaseType?) throws -> Bool {
        return try S.setFromProtobufFixed4(fixed4: fixed4, value: &value)
    }

    mutating func decodeRequiredField<S: ProtobufTypeProperties>(fieldType: S.Type, value: inout S.BaseType) throws -> Bool {
        var t: S.BaseType?
        let handled = try S.setFromProtobufFixed4(fixed4: fixed4, value: &t)
        if let t = t, handled {
            value = t
            return true
        }
        throw ProtobufDecodingError.schemaMismatch
    }

    mutating func decodeRepeatedField<S: ProtobufTypeProperties>(fieldType: S.Type, value: inout [S.BaseType]) throws -> Bool {
        return try S.setFromProtobufFixed4(fixed4: fixed4, value: &value)
    }

    mutating func decodePackedField<S: ProtobufTypeProperties>(fieldType: S.Type, value: inout [S.BaseType]) throws -> Bool {
        return try S.setFromProtobufFixed4(fixed4: fixed4, value: &value)
    }

    mutating func asProtobufUnknown() throws -> [UInt8]? {
        return [UInt8](unknown)
    }
}

/*
 * Decoder object for Protobuf Binary format.
 *
 * Note:  This object is instantiated with an UnsafeBufferPointer<UInt8>
 * that is assumed to be stable for the lifetime of this object.
 */
public struct ProtobufBinaryDecoder {
    private var scanner: ProtobufScanner

    public var complete: Bool {return scanner.available == 0}
    public var fieldWireType: Int {return scanner.fieldWireType}

    public init(protobufPointer: UnsafeBufferPointer<UInt8>, extensions: ProtobufExtensionSet? = nil) {
        scanner = ProtobufScanner(protobufPointer: protobufPointer, extensions: extensions)
    }

    fileprivate init(scanner: ProtobufScanner) {
        self.scanner = scanner
    }

    internal func getTagType() throws -> Int? {
        return try scanner.getTagType()
    }

    @discardableResult
    internal func skip() throws -> UnsafeBufferPointer<UInt8> {
        return try scanner.skip()
    }

    public mutating func decodeFullObject(decodeField: (inout ProtobufFieldDecoder, Int) throws -> Bool) throws {
        while let tagType = try scanner.getTagType() {
            let protoFieldNumber = tagType / 8
            var fieldDecoder: ProtobufFieldDecoder
            switch scanner.fieldWireType {
            case 0:
                let value = try getVarint()
                let raw = try scanner.getRawField()
                fieldDecoder = ProtobufFieldWireType0(varint: value, unknown: raw, scanner: scanner)
            case 1:
                let value = try getFixed8()
                let raw = try scanner.getRawField()
                fieldDecoder = ProtobufFieldWireType1(fixed8: value, unknown: raw, scanner: scanner)
            case 2:
                let value = try getBytesRef()
                let raw = try scanner.getRawField()
                fieldDecoder = ProtobufFieldWireType2(buffer: value, unknown: raw, scanner: scanner)
            case 3:
                fieldDecoder = ProtobufFieldWireType3(scanner: scanner, protoFieldNumber: protoFieldNumber)
            case 4:
                throw ProtobufDecodingError.malformedProtobuf
            case 5:
                let value = try getFixed4()
                let raw = try scanner.getRawField()
                fieldDecoder = ProtobufFieldWireType5(fixed4: value, unknown: raw, scanner: scanner)
            case 6:
                throw ProtobufDecodingError.malformedProtobuf
            case 7:
                throw ProtobufDecodingError.malformedProtobuf
            default:
                throw ProtobufDecodingError.malformedProtobuf
            }
            if !(try decodeField(&fieldDecoder, protoFieldNumber)) {
                let _ = try scanner.skip() // Skip and discard the field.
            }
        }
        if scanner.available != 0 {
            throw ProtobufDecodingError.trailingGarbage
        }
    }

    public mutating func decodeFullObject<M: ProtobufMessage>(message: inout M) throws {
        try decodeFullObject {(setter: inout ProtobufFieldDecoder, protoFieldNumber: Int) throws -> Bool in
            return try message.decodeField(setter: &setter, protoFieldNumber: protoFieldNumber)
        }
    }

    public mutating func decodeFullGroup<G: ProtobufGroupBase>(group: inout G, protoFieldNumber: Int) throws {
        guard scanner.fieldWireType == 3 else {throw ProtobufDecodingError.malformedProtobuf}
        while let tagType = try scanner.getTagType() {
            if tagType / 8 == protoFieldNumber {
                if tagType % 8 == 4 {
                    return
                }
                break // Fail and exit
            }
            var fieldDecoder: ProtobufFieldDecoder
            switch scanner.fieldWireType {
            case 0:
                let value = try getVarint()
                let raw = try scanner.getRawField()
                fieldDecoder = ProtobufFieldWireType0(varint: value, unknown: raw, scanner: scanner)
            case 1:
                let value = try getFixed8()
                let raw = try scanner.getRawField()
                fieldDecoder = ProtobufFieldWireType1(fixed8: value, unknown: raw, scanner: scanner)
            case 2:
                let value = try getBytesRef()
                let raw = try scanner.getRawField()
                fieldDecoder = ProtobufFieldWireType2(buffer: value, unknown: raw, scanner: scanner)
            case 3:
                fieldDecoder = ProtobufFieldWireType3(scanner: scanner, protoFieldNumber: protoFieldNumber)
            case 4:
                throw ProtobufDecodingError.malformedProtobuf
            case 5:
                let value = try getFixed4()
                let raw = try scanner.getRawField()
                fieldDecoder = ProtobufFieldWireType5(fixed4: value, unknown: raw, scanner: scanner)
            default:
                throw ProtobufDecodingError.malformedProtobuf
            }
            // Proto2 groups always consume fields or throw errors, so we can ignore return here
            let _ = try group.decodeField(setter: &fieldDecoder, protoFieldNumber: tagType / 8)
        }
        throw ProtobufDecodingError.truncatedInput
    }

    // Marks failure if no or broken varint but returns zero
    fileprivate mutating func getVarint() throws -> UInt64 {
        if let t = try scanner.getRawVarint() {
            return t
        }
        throw ProtobufDecodingError.malformedProtobuf
    }

    fileprivate mutating func getFixed8() throws -> [UInt8] {
        guard scanner.available >= 8 else {throw ProtobufDecodingError.truncatedInput}
        var i = Array<UInt8>(repeating: 0, count: 8)
        i.withUnsafeMutableBufferPointer { ip -> Void in
            let src = UnsafeMutablePointer<UInt8>(mutating: scanner.p)
            ip.baseAddress!.initialize(from: src, count: 8)
        }
        scanner.consume(length: 8)
        return i
    }

    fileprivate mutating func getFixed4() throws -> [UInt8] {
        guard scanner.available >= 4 else {throw ProtobufDecodingError.truncatedInput}
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
        guard scanner.available >= 4 else {throw ProtobufDecodingError.truncatedInput}
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
        guard scanner.available >= 8 else {throw ProtobufDecodingError.truncatedInput}
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
        guard scanner.available >= 4 else {throw ProtobufDecodingError.truncatedInput}
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
        guard scanner.available >= 8 else {throw ProtobufDecodingError.truncatedInput}
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
        guard scanner.available >= 4 else {throw ProtobufDecodingError.truncatedInput}
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
        guard scanner.available >= 8 else {throw ProtobufDecodingError.truncatedInput}
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
        throw ProtobufDecodingError.truncatedInput
    }

    // Convert a 64-bit value from zigzag coding.
    fileprivate func unZigZag64(zigZag: UIntMax) -> Int64 {
        let n = Int64(bitPattern: (zigZag >> 1))
        return n ^ -Int64(bitPattern: zigZag & 1)
    }

    // Convert a 32-bit value from zigzag coding.
    fileprivate func unZigZag32(zigZag: UIntMax) -> Int32 {
        let t = UInt32(truncatingBitPattern: zigZag)
        let n = Int32(bitPattern: (t >> 1))
        return n ^ -Int32(bitPattern: t & 1)
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
    // Wire type for last-examined field
    var fieldWireType: Int = 0
    // Collection of extension fields for this decode
    var extensions: ProtobufExtensionSet?

    init(protobufPointer: UnsafeBufferPointer<UInt8>, extensions: ProtobufExtensionSet? = nil) {
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
    func skipOver(tagType: UInt64) throws {
        if tagType < 8 || tagType > UInt64(UInt32.max) {
            throw ProtobufDecodingError.malformedProtobuf
        }
        switch tagType % 8 {
        case 0:
            if available < 1 {
                throw ProtobufDecodingError.truncatedInput
            }
            var c = p[0]
            while (c & 0x80) != 0 {
                p += 1
                available -= 1
                if available < 1 {
                    throw ProtobufDecodingError.truncatedInput
                }
                c = p[0]
            }
            p += 1
            available -= 1
        case 1:
            if available < 8 {
                throw ProtobufDecodingError.truncatedInput
            }
            p += 8
            available -= 8
        case 2:
            if let n = try getRawVarint(), n <= UInt64(available) {
                p += Int(n)
                available -= Int(n)
            } else {
                throw ProtobufDecodingError.malformedProtobuf
            }
        case 3:
            while true {
                if let innerTagType = try getRawVarint() {
                    if innerTagType == tagType + 1 {
                        break
                    } else if innerTagType / 8 != tagType / 8 {
                        try skipOver(tagType: innerTagType)
                    }
                } else {
                    throw ProtobufDecodingError.truncatedInput
                }
            }
        case 4:
            throw ProtobufDecodingError.malformedProtobuf
        case 5:
            if available < 4 {
                throw ProtobufDecodingError.truncatedInput
            }
            p += 4
            available -= 4
        default:
            throw ProtobufDecodingError.malformedProtobuf
        }
    }

    // Returns block of bytes representing the skipped field or nil if failure.
    //
    // This uses the bookmarked position saved by the last call to getTagType().
    //
    func skip() throws -> UnsafeBufferPointer<UInt8> {
        p = fieldStartP
        available = fieldStartAvailable
        guard let tagType = try getRawVarint() else {
            throw ProtobufDecodingError.truncatedInput
        }
        try skipOver(tagType: tagType)
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
                throw ProtobufDecodingError.malformedProtobuf
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
    func getTagType() throws -> Int? {
        fieldStartP = p
        fieldStartAvailable = available
        if let t = try getRawVarint() {
            if t > 7 && t < UInt64(UInt32.max) {
                let tagType = Int(truncatingBitPattern: t)
                fieldWireType = tagType % 8
                return tagType
            } else {
                throw ProtobufDecodingError.malformedProtobuf
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
