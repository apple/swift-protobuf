// Sources/SwiftProtobuf/ProtobufTypeAdditions.swift - Per-type binary coding
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Extensions to the proto types defined in ProtobufTypes.swift to provide
/// type-specific binary coding and decoding.
///
// -----------------------------------------------------------------------------

import Swift
import Foundation

/// Extension defines default handling for mismatched wire types.
/// TODO: Examine how C++ proto2 treats wire type mismatches -- if
/// it treats them as unknown fields, consider changing the following
/// to 'return false' to match.
public extension FieldType {
    public static func setFromProtobuf(scanner: ProtobufScanner, value: inout BaseType?) throws -> Bool {
        throw DecodingError.schemaMismatch
    }
    public static func setFromProtobuf(scanner: ProtobufScanner, value: inout [BaseType]) throws -> Bool {
        throw DecodingError.schemaMismatch
    }
}

protocol ProtobufMapValueType: MapValueType {
}

extension ProtobufMapValueType {
    public static func decodeProtobufMapValue(decoder: inout FieldDecoder, value: inout BaseType?) throws {
        try decoder.decodeSingularField(fieldType: Self.self, value: &value)
        assert(value != nil)
    }
}

///
/// Float traits
///
extension ProtobufFloat: ProtobufMapValueType {
    public static var protobufWireFormat: WireFormat { return .fixed32 }
    public static func serializeProtobufValue(encoder: inout ProtobufEncoder, value: Float) {
        encoder.putFloatValue(value: value)
    }

    public static func setFromProtobuf(scanner: ProtobufScanner, value: inout BaseType?) throws -> Bool {
        guard scanner.fieldWireFormat == .fixed32 else {
            throw DecodingError.schemaMismatch
        }
        var i: Float = 0
        try scanner.decodeFourByteNumber(value: &i)
        value = i
        return true
    }

    public static func setFromProtobuf(scanner: ProtobufScanner, value: inout [BaseType]) throws -> Bool {
        switch scanner.fieldWireFormat {
        case .fixed32:
            var i: Float = 0
            try scanner.decodeFourByteNumber(value: &i)
            value.append(i)
            return true
        case .lengthDelimited:
            var n: Int = 0
            let p = try scanner.getFieldBodyBytes(count: &n)
            value.reserveCapacity(value.count + n / MemoryLayout<BaseType>.size)
            var decoder = ProtobufDecoder(protobufPointer: p, count: n)
            while let t = try decoder.decodeFloat() {
                value.append(t)
            }
            return true
        default:
            throw DecodingError.schemaMismatch
        }
    }

    public static func encodedSizeWithoutTag(of value: Float) -> Int {
        return MemoryLayout<Float>.size
    }
}


///
/// Double traits
///
extension ProtobufDouble: ProtobufMapValueType {
    public static var protobufWireFormat: WireFormat { return .fixed64 }
    public static func serializeProtobufValue(encoder: inout ProtobufEncoder, value: Double) {
        encoder.putDoubleValue(value: value)
    }

    public static func setFromProtobuf(scanner: ProtobufScanner, value: inout BaseType?) throws -> Bool {
        guard scanner.fieldWireFormat == .fixed64 else {
            throw DecodingError.schemaMismatch
        }
        var i: Double = 0
        try scanner.decodeEightByteNumber(value: &i)
        value = i
        return true
    }

    public static func setFromProtobuf(scanner: ProtobufScanner, value: inout [BaseType]) throws -> Bool {
        switch scanner.fieldWireFormat {
        case .fixed64:
            var i: Double = 0
            try scanner.decodeEightByteNumber(value: &i)
            value.append(i)
            return true
        case .lengthDelimited:
            var n: Int = 0
            let p = try scanner.getFieldBodyBytes(count: &n)
            value.reserveCapacity(value.count + n / MemoryLayout<BaseType>.size)
            var decoder = ProtobufDecoder(protobufPointer: p, count: n)
            while let t = try decoder.decodeDouble() {
                value.append(t)
            }
            return true
        default:
            throw DecodingError.schemaMismatch
        }
    }

    public static func encodedSizeWithoutTag(of value: Double) -> Int {
        return MemoryLayout<Double>.size
    }
}

///
/// Int32 traits
///
extension ProtobufInt32: ProtobufMapValueType {
    public static var protobufWireFormat: WireFormat { return .varint }

    public static func serializeProtobufValue(encoder: inout ProtobufEncoder, value: Int32) {
        encoder.putVarInt(value: Int64(value))
    }

    public static func setFromProtobuf(scanner: ProtobufScanner, value: inout BaseType?) throws -> Bool {
        guard scanner.fieldWireFormat == .varint else {
            throw DecodingError.schemaMismatch
        }
        let varint = try scanner.decodeVarint()
        value = Int32(truncatingBitPattern: varint)
        return true
    }

    public static func setFromProtobuf(scanner: ProtobufScanner, value: inout [BaseType]) throws -> Bool {
        switch scanner.fieldWireFormat {
        case .varint:
            let varint = try scanner.decodeVarint()
            value.append(Int32(truncatingBitPattern: varint))
            return true
        case .lengthDelimited:
            var n: Int = 0
            let p = try scanner.getFieldBodyBytes(count: &n)
            var decoder = ProtobufDecoder(protobufPointer: p, count: n)
            while let t = try decoder.decodeInt32() {
                value.append(t)
            }
            return true
        default:
            throw DecodingError.schemaMismatch
        }
    }

    public static func encodedSizeWithoutTag(of value: Int32) -> Int {
        return Varint.encodedSize(of: value)
    }
}

///
/// Int64 traits
///
extension ProtobufInt64: ProtobufMapValueType {
    public static var protobufWireFormat: WireFormat { return .varint }

    public static func serializeProtobufValue(encoder: inout ProtobufEncoder, value: Int64) {
        encoder.putVarInt(value: value)
    }

    public static func setFromProtobuf(scanner: ProtobufScanner, value: inout BaseType?) throws -> Bool {
        guard scanner.fieldWireFormat == .varint else {
            throw DecodingError.schemaMismatch
        }
        let varint = try scanner.decodeVarint()
        value = Int64(bitPattern: varint)
        return true
    }

    public static func setFromProtobuf(scanner: ProtobufScanner, value: inout [BaseType]) throws -> Bool {
        switch scanner.fieldWireFormat {
        case .varint:
            let varint = try scanner.decodeVarint()
            value.append(Int64(bitPattern: varint))
            return true
        case .lengthDelimited:
            var n: Int = 0
            let p = try scanner.getFieldBodyBytes(count: &n)
            var decoder = ProtobufDecoder(protobufPointer: p, count: n)
            while let t = try decoder.decodeInt64() {
                value.append(t)
            }
            return true
        default:
            throw DecodingError.schemaMismatch
        }
    }

    public static func encodedSizeWithoutTag(of value: Int64) -> Int {
        return Varint.encodedSize(of: value)
    }
}

///
/// UInt32 traits
///
extension ProtobufUInt32: ProtobufMapValueType {
    public static var protobufWireFormat: WireFormat { return .varint }

    public static func serializeProtobufValue(encoder: inout ProtobufEncoder, value: UInt32) {
        encoder.putVarInt(value: UInt64(value))
    }

    public static func setFromProtobuf(scanner: ProtobufScanner, value: inout BaseType?) throws -> Bool {
        guard scanner.fieldWireFormat == .varint else {
            throw DecodingError.schemaMismatch
        }
        let varint = try scanner.decodeVarint()
        value = UInt32(truncatingBitPattern: varint)
        return true
    }

    public static func setFromProtobuf(scanner: ProtobufScanner, value: inout [BaseType]) throws -> Bool {
        switch scanner.fieldWireFormat {
        case .varint:
            let varint = try scanner.decodeVarint()
            value.append(UInt32(truncatingBitPattern: varint))
            return true
        case .lengthDelimited:
            var n: Int = 0
            let p = try scanner.getFieldBodyBytes(count: &n)
            var decoder = ProtobufDecoder(protobufPointer: p, count: n)
            while let t = try decoder.decodeUInt32() {
                value.append(t)
            }
            return true
        default:
            throw DecodingError.schemaMismatch
        }
    }

    public static func encodedSizeWithoutTag(of value: UInt32) -> Int {
        return Varint.encodedSize(of: value)
    }
}

///
/// UInt64 traits
///
extension ProtobufUInt64: ProtobufMapValueType {
    public static var protobufWireFormat: WireFormat { return .varint }

    public static func serializeProtobufValue(encoder: inout ProtobufEncoder, value: UInt64) {
        encoder.putVarInt(value: value)
    }

    public static func setFromProtobuf(scanner: ProtobufScanner, value: inout BaseType?) throws -> Bool {
        guard scanner.fieldWireFormat == .varint else {
            throw DecodingError.schemaMismatch
        }
        value = try scanner.decodeVarint()
        return true
    }

    public static func setFromProtobuf(scanner: ProtobufScanner, value: inout [BaseType]) throws -> Bool {
        switch scanner.fieldWireFormat {
        case .varint:
            let varint = try scanner.decodeVarint()
            value.append(varint)
            return true
        case .lengthDelimited:
            var n: Int = 0
            let p = try scanner.getFieldBodyBytes(count: &n)
            var decoder = ProtobufDecoder(protobufPointer: p, count: n)
            while let t = try decoder.decodeUInt64() {
                value.append(t)
            }
            return true
        default:
            throw DecodingError.schemaMismatch
        }
    }

    public static func encodedSizeWithoutTag(of value: UInt64) -> Int {
        return Varint.encodedSize(of: value)
    }
}

///
/// SInt32 traits
///
extension ProtobufSInt32: ProtobufMapValueType {
    public static var protobufWireFormat: WireFormat { return .varint }

    public static func serializeProtobufValue(encoder: inout ProtobufEncoder, value: Int32) {
        encoder.putZigZagVarInt(value: Int64(value))
    }

    public static func setFromProtobuf(scanner: ProtobufScanner, value: inout BaseType?) throws -> Bool {
        guard scanner.fieldWireFormat == .varint else {
            throw DecodingError.schemaMismatch
        }
        let varint = try scanner.decodeVarint()
        let t = UInt32(truncatingBitPattern: varint)
        value = ZigZag.decoded(t)
        return true
    }

    public static func setFromProtobuf(scanner: ProtobufScanner, value: inout [BaseType]) throws -> Bool {
        switch scanner.fieldWireFormat {
        case .varint:
            let varint = try scanner.decodeVarint()
            let t = UInt32(truncatingBitPattern: varint)
            value.append(ZigZag.decoded(t))
            return true
        case .lengthDelimited:
            var n: Int = 0
            let p = try scanner.getFieldBodyBytes(count: &n)
            var decoder = ProtobufDecoder(protobufPointer: p, count: n)
            while let t = try decoder.decodeSInt32() {
                value.append(t)
            }
            return true
        default:
            throw DecodingError.schemaMismatch
        }
    }

    public static func encodedSizeWithoutTag(of value: Int32) -> Int {
        return Varint.encodedSize(of: ZigZag.encoded(value))
    }
}

///
/// SInt64 traits
///
extension ProtobufSInt64: ProtobufMapValueType {
    public static var protobufWireFormat: WireFormat { return .varint }

    public static func serializeProtobufValue(encoder: inout ProtobufEncoder, value: Int64) {
        encoder.putZigZagVarInt(value: value)
    }


    public static func setFromProtobuf(scanner: ProtobufScanner, value: inout BaseType?) throws -> Bool {
        guard scanner.fieldWireFormat == .varint else {
            throw DecodingError.schemaMismatch
        }
        let varint = try scanner.decodeVarint()
        value = ZigZag.decoded(varint)
        return true
    }

    public static func setFromProtobuf(scanner: ProtobufScanner, value: inout [BaseType]) throws -> Bool {
        switch scanner.fieldWireFormat {
        case .varint:
            let varint = try scanner.decodeVarint()
            value.append(ZigZag.decoded(varint))
            return true
        case .lengthDelimited:
            var n: Int = 0
            let p = try scanner.getFieldBodyBytes(count: &n)
            var decoder = ProtobufDecoder(protobufPointer: p, count: n)
            while let t = try decoder.decodeSInt64() {
                value.append(t)
            }
            return true
        default:
            throw DecodingError.schemaMismatch
        }
    }

    public static func encodedSizeWithoutTag(of value: Int64) -> Int {
        return Varint.encodedSize(of: ZigZag.encoded(value))
    }
}

///
/// Fixed32 traits
///
extension ProtobufFixed32: ProtobufMapValueType {
    public static var protobufWireFormat: WireFormat { return .fixed32 }
    public static func serializeProtobufValue(encoder: inout ProtobufEncoder, value: UInt32) {
        encoder.putFixedUInt32(value: value)
    }

    public static func setFromProtobuf(scanner: ProtobufScanner, value: inout BaseType?) throws -> Bool {
        guard scanner.fieldWireFormat == .fixed32 else {
            throw DecodingError.schemaMismatch
        }
        var i: UInt32 = 0
        try scanner.decodeFourByteNumber(value: &i)
        value = UInt32(littleEndian: i)
        return true
    }

    public static func setFromProtobuf(scanner: ProtobufScanner, value: inout [BaseType]) throws -> Bool {
        switch scanner.fieldWireFormat {
        case .fixed32:
            var i: UInt32 = 0
            try scanner.decodeFourByteNumber(value: &i)
            value.append(UInt32(littleEndian: i))
            return true
        case .lengthDelimited:
            var n: Int = 0
            let p = try scanner.getFieldBodyBytes(count: &n)
            value.reserveCapacity(value.count + n / MemoryLayout<BaseType>.size)
            var decoder = ProtobufDecoder(protobufPointer: p, count: n)
            while let t = try decoder.decodeFixed32() {
                value.append(t)
            }
            return true
        default:
            throw DecodingError.schemaMismatch
        }
    }

    public static func encodedSizeWithoutTag(of value: UInt32) -> Int {
        return MemoryLayout<UInt32>.size
    }
}

///
/// Fixed64 traits
///
extension ProtobufFixed64: ProtobufMapValueType {
    public static var protobufWireFormat: WireFormat { return .fixed64 }
    public static func serializeProtobufValue(encoder: inout ProtobufEncoder, value: UInt64) {
        encoder.putFixedUInt64(value: value.littleEndian)
    }

    public static func setFromProtobuf(scanner: ProtobufScanner, value: inout BaseType?) throws -> Bool {
        guard scanner.fieldWireFormat == .fixed64 else {
            throw DecodingError.schemaMismatch
        }
        var i: UInt64 = 0
        try scanner.decodeEightByteNumber(value: &i)
        value = i
        return true
    }

    public static func setFromProtobuf(scanner: ProtobufScanner, value: inout [BaseType]) throws -> Bool {
        switch scanner.fieldWireFormat {
        case .fixed64:
            var i: UInt64 = 0
            try scanner.decodeEightByteNumber(value: &i)
            value.append(i)
            return true
        case .lengthDelimited:
            var n: Int = 0
            let p = try scanner.getFieldBodyBytes(count: &n)
            value.reserveCapacity(value.count + n / MemoryLayout<BaseType>.size)
            var decoder = ProtobufDecoder(protobufPointer: p, count: n)
            while let t = try decoder.decodeFixed64() {
                value.append(t)
            }
            return true
        default:
            throw DecodingError.schemaMismatch
        }

    }

    public static func encodedSizeWithoutTag(of value: UInt64) -> Int {
        return MemoryLayout<UInt64>.size
    }
}

///
/// SFixed32 traits
///
extension ProtobufSFixed32: ProtobufMapValueType {
    public static var protobufWireFormat: WireFormat { return .fixed32 }
    public static func serializeProtobufValue(encoder: inout ProtobufEncoder, value: Int32) {
        encoder.putFixedUInt32(value: UInt32(bitPattern: value))
    }

    public static func setFromProtobuf(scanner: ProtobufScanner, value: inout BaseType?) throws -> Bool {
        guard scanner.fieldWireFormat == .fixed32 else {
            throw DecodingError.schemaMismatch
        }
        var i: Int32 = 0
        try scanner.decodeFourByteNumber(value: &i)
        value = Int32(littleEndian: i)
        return true
    }

    public static func setFromProtobuf(scanner: ProtobufScanner, value: inout [BaseType]) throws -> Bool {
        switch scanner.fieldWireFormat {
        case .fixed32:
            var i: Int32 = 0
            try scanner.decodeFourByteNumber(value: &i)
            value.append(Int32(littleEndian: i))
            return true
        case .lengthDelimited:
            var n: Int = 0
            let p = try scanner.getFieldBodyBytes(count: &n)
            value.reserveCapacity(value.count + n / MemoryLayout<BaseType>.size)
            var decoder = ProtobufDecoder(protobufPointer: p, count: n)
            while let t = try decoder.decodeSFixed32() {
                value.append(t)
            }
            return true
        default:
            throw DecodingError.schemaMismatch
        }
    }

    public static func encodedSizeWithoutTag(of value: Int32) -> Int {
        return MemoryLayout<Int32>.size
    }
}

///
/// SFixed64 traits
///
extension ProtobufSFixed64: ProtobufMapValueType {
    public static var protobufWireFormat: WireFormat { return .fixed64 }
    public static func serializeProtobufValue(encoder: inout ProtobufEncoder, value: Int64) {
        encoder.putFixedUInt64(value: UInt64(bitPattern: value.littleEndian))
    }

    public static func setFromProtobuf(scanner: ProtobufScanner, value: inout BaseType?) throws -> Bool {
        guard scanner.fieldWireFormat == .fixed64 else {
            throw DecodingError.schemaMismatch
        }
        var i: Int64 = 0
        try scanner.decodeEightByteNumber(value: &i)
        value = i
        return true
    }

    public static func setFromProtobuf(scanner: ProtobufScanner, value: inout [BaseType]) throws -> Bool {
        switch scanner.fieldWireFormat {
        case .fixed64:
            var i: Int64 = 0
            try scanner.decodeEightByteNumber(value: &i)
            value.append(i)
            return true
        case .lengthDelimited:
            var n: Int = 0
            let p = try scanner.getFieldBodyBytes(count: &n)
            value.reserveCapacity(value.count + n / MemoryLayout<BaseType>.size)
            var decoder = ProtobufDecoder(protobufPointer: p, count: n)
            while let t = try decoder.decodeSFixed64() {
                value.append(t)
            }
            return true
        default:
            throw DecodingError.schemaMismatch
        }
    }

    public static func encodedSizeWithoutTag(of value: Int64) -> Int {
        return MemoryLayout<Int64>.size
    }
}

///
/// Bool traits
///
extension ProtobufBool: ProtobufMapValueType {
    public static var protobufWireFormat: WireFormat { return .varint }

    public static func serializeProtobufValue(encoder: inout ProtobufEncoder, value: Bool) {
        encoder.putBoolValue(value: value)
    }


    public static func setFromProtobuf(scanner: ProtobufScanner, value: inout BaseType?) throws -> Bool {
        guard scanner.fieldWireFormat == .varint else {
            throw DecodingError.schemaMismatch
        }
        let varint = try scanner.decodeVarint()
        value = (varint != 0)
        return true
    }

    public static func setFromProtobuf(scanner: ProtobufScanner, value: inout [BaseType]) throws -> Bool {
        switch scanner.fieldWireFormat {
        case .varint:
            let varint = try scanner.decodeVarint()
            value.append(varint != 0)
            return true
        case .lengthDelimited:
            var n: Int = 0
            let p = try scanner.getFieldBodyBytes(count: &n)
            var decoder = ProtobufDecoder(protobufPointer: p, count: n)
            while let t = try decoder.decodeBool() {
                value.append(t)
            }
            return true
        default:
            throw DecodingError.schemaMismatch
        }
    }

    public static func encodedSizeWithoutTag(of value: Bool) -> Int {
        return 1
    }
}

///
/// String traits
///

// Note:  When decoding a lot of string fields, this function
// accounts for ~50% of the total run time.  Optimizations here
// can have big impacts.
private func bufferToString(buffer p: UnsafePointer<UInt8>, count: Int) throws -> String {
    // The extra copy here is regrettable, but even with that,
    // this seems to be faster than many alternatives (see below).
    let data = Data(bytes: p, count: count)
    if let s = String(data: data, encoding: String.Encoding.utf8) {
        return s
    } else {
        throw DecodingError.invalidUTF8
    }
    // Other alternatives that have been tried (roughly ordered from
    // faster to slower):
    // = Passing an UnsafeBufferPointer to String(bytes:encoding:)
    // = Using a UTF8() codec to decode character-by-character
    // = Copy the data, append a zero byte, then use String(utf8String:)
    // Of course, any of these may suddenly become much faster in a
    // future Swift release.
}

extension ProtobufString: ProtobufMapValueType {
    public static var protobufWireFormat: WireFormat { return .lengthDelimited }
    public static func serializeProtobufValue(encoder: inout ProtobufEncoder, value: String) {
        encoder.putStringValue(value: value)
    }

    public static func setFromProtobuf(scanner: ProtobufScanner, value: inout String?) throws -> Bool {
        guard scanner.fieldWireFormat == .lengthDelimited else {
            throw DecodingError.schemaMismatch
        }
        var n: Int = 0
        let p = try scanner.getFieldBodyBytes(count: &n)
        value = try bufferToString(buffer: p, count: n)
        return true
    }

    public static func setFromProtobuf(scanner: ProtobufScanner, value: inout [String]) throws -> Bool {
        guard scanner.fieldWireFormat == .lengthDelimited else {
            throw DecodingError.schemaMismatch
        }
        var n: Int = 0
        let p = try scanner.getFieldBodyBytes(count: &n)
        let s = try bufferToString(buffer: p, count: n)
        value.append(s)
        return true
    }

    public static func encodedSizeWithoutTag(of value: String) -> Int {
        let stringWithNul = value.utf8CString
        let stringLength = stringWithNul.count - 1
        return Varint.encodedSize(of: Int64(stringLength)) + stringLength
    }
}

///
/// Bytes traits
///
extension ProtobufBytes: ProtobufMapValueType {
    public static var protobufWireFormat: WireFormat { return .lengthDelimited }

    public static func serializeProtobufValue(encoder: inout ProtobufEncoder, value: Data) {
        encoder.putBytesValue(value: value)
    }

    public static func setFromProtobuf(scanner: ProtobufScanner, value: inout Data?) throws -> Bool {
        guard scanner.fieldWireFormat == .lengthDelimited else {
            throw DecodingError.schemaMismatch
        }
        var n: Int = 0
        let p = try scanner.getFieldBodyBytes(count: &n)
        value = Data(bytes: p, count: n)
        return true
    }

    public static func setFromProtobuf(scanner: ProtobufScanner, value: inout [Data]) throws -> Bool {
        guard scanner.fieldWireFormat == .lengthDelimited else {
            throw DecodingError.schemaMismatch
        }
        var n: Int = 0
        let p = try scanner.getFieldBodyBytes(count: &n)
        value.append(Data(bytes: p, count: n))
        return true
    }

    public static func encodedSizeWithoutTag(of value: Data) -> Int {
        let count = value.count
        return Varint.encodedSize(of: Int64(count)) + count
    }
}

//
// Enum traits
//
extension Enum where RawValue == Int {
    public static var protobufWireFormat: WireFormat { return .varint }
    public static func decodeOptionalField(decoder: inout FieldDecoder, value: inout BaseType?) throws-> Bool {
        try decoder.decodeSingularField(fieldType: Self.self, value: &value)
        return true
    }

    public static func serializeProtobufValue(encoder: inout ProtobufEncoder, value: Self) {
        encoder.putVarInt(value: value.rawValue)
    }

    public static func setFromProtobuf(scanner: ProtobufScanner, value: inout Self?) throws -> Bool {
        guard scanner.fieldWireFormat == .varint else {
            throw DecodingError.schemaMismatch
        }
        let varint = try scanner.decodeVarint()
        if let v = Self(rawValue: Int(Int32(truncatingBitPattern: varint))) {
            value = v
            return true
        } else {
            return false
        }
    }

    public static func setFromProtobuf(scanner: ProtobufScanner, value: inout [Self]) throws -> Bool {
        switch scanner.fieldWireFormat {
        case .varint:
            let varint = try scanner.decodeVarint()
            if let v = Self(rawValue: Int(Int32(truncatingBitPattern: varint))) {
                value.append(v)
                return true
            } else {
                return false
            }
        case .lengthDelimited:
            var n: Int = 0
            var extras = [Int32]()
            let p = try scanner.getFieldBodyBytes(count: &n)
            var decoder = ProtobufDecoder(protobufPointer: p, count: n)
            while let t = try decoder.decodeInt32() {
                if let v = Self(rawValue: Int(t)) {
                    value.append(v)
                } else {
                    extras.append(t)
                }
            }
            if extras.isEmpty {
                scanner.unknownOverride = nil
            } else {
                let fieldTag = FieldTag(fieldNumber: scanner.fieldNumber, wireFormat: .lengthDelimited)
                var bodySize = 0
                for v in extras {
                    bodySize += Varint.encodedSize(of: Int64(v))
                }
                let fieldSize = Varint.encodedSize(of: fieldTag.rawValue) + Varint.encodedSize(of: Int64(bodySize)) + bodySize
                var field = Data(count: fieldSize)
                field.withUnsafeMutableBytes { (pointer: UnsafeMutablePointer<UInt8>) in
                    var encoder = ProtobufEncoder(pointer: pointer)
                    encoder.startField(tag: fieldTag)
                    encoder.putVarInt(value: Int64(bodySize))
                    for v in extras {
                        encoder.putVarInt(value: Int64(v))
                    }
                }
                scanner.unknownOverride = field
            }
            return true
        default:
            throw DecodingError.schemaMismatch
        }
    }

    public static func encodedSizeWithoutTag(of value: Self) -> Int {
        return Varint.encodedSize(of: Int32(truncatingBitPattern: value.rawValue))
    }
}

///
/// Messages
///
public extension Message {
    func serializeProtobuf() throws -> Data {
        let requiredSize = try serializedProtobufSize()
        var data = Data(count: requiredSize)
        try data.withUnsafeMutableBytes { (pointer: UnsafeMutablePointer<UInt8>) in
            try serializeProtobuf(into: pointer)
        }
        return data
    }
    private func serializeProtobuf(into pointer: UnsafeMutablePointer<UInt8>) throws {
        let visitor = ProtobufEncodingVisitor(forWritingInto: pointer)
        try traverse(visitor: visitor)
    }

    func serializedProtobufSize() throws -> Int {
        let visitor = ProtobufEncodingSizeVisitor()
        try traverse(visitor: visitor)
        return visitor.serializedSize
    }

    static var protobufWireFormat: WireFormat { return .lengthDelimited }

    static func serializeProtobufValue(encoder: inout ProtobufEncoder, value: Self) {
        // We already verified the size, so this must succeed!
        let t = try! value.serializeProtobuf()
        encoder.putBytesValue(value: t)
    }

    static func encodedSizeWithoutTag(of value: Self) throws -> Int {
        let messageSize = try value.serializedProtobufSize()
        return Varint.encodedSize(of: Int64(messageSize)) + messageSize
    }

    static func decodeProtobufMapValue(decoder: inout FieldDecoder, value: inout Self?) throws {
        try decoder.decodeSingularMessageField(fieldType: Self.self, value: &value)
        assert(value != nil)
    }

    init(protobuf: Data) throws {
        try self.init(protobuf: protobuf, extensions: nil)
    }

    init(protobufBuffer: UnsafeBufferPointer<UInt8>) throws {
        try self.init(protobufBuffer: protobufBuffer, extensions: nil)
    }

    init(protobuf: Data, extensions: ExtensionSet?) throws {
        self.init()
        if !protobuf.isEmpty {
            try protobuf.withUnsafeBytes { (pointer: UnsafePointer<UInt8>) in
                try decodeIntoSelf(protobufBytes: pointer, count: protobuf.count, extensions: extensions)
            }
        }
    }

    init(protobufBuffer: UnsafeBufferPointer<UInt8>, extensions: ExtensionSet?) throws {
        self.init()
        try decodeIntoSelf(protobufBytes: protobufBuffer.baseAddress!, count: protobufBuffer.count, extensions: extensions)
    }
}

/// Proto2 messages preserve unknown fields
public extension Proto2Message {
    public mutating func decodeIntoSelf(protobufBytes: UnsafePointer<UInt8>, count: Int, extensions: ExtensionSet?) throws {
        var protobufDecoder = ProtobufDecoder(protobufPointer: protobufBytes, count: count, extensions: extensions)
        try protobufDecoder.decodeFullObject(message: &self)
        unknown.append(protobufData: protobufDecoder.unknownData)
    }
}

// Proto3 messages ignore unknown fields
public extension Proto3Message {
    public mutating func decodeIntoSelf(protobufBytes: UnsafePointer<UInt8>, count: Int, extensions: ExtensionSet?) throws {
        var protobufDecoder = ProtobufDecoder(protobufPointer: protobufBytes, count: count, extensions: extensions)
        try protobufDecoder.decodeFullObject(message: &self)
    }
}

///
/// Groups
///

// Nothing.  Groups are implemented as messages.

///
/// Maps
///

// No special support here.
