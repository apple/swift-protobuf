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
    public static func setFromProtobuf(decoder: inout ProtobufDecoder, value: inout BaseType?) throws -> Bool {
        throw DecodingError.schemaMismatch
    }

    public static func setFromProtobuf(decoder: inout ProtobufDecoder, value: inout BaseType) throws -> Bool {
        var v: BaseType?
        let consumed = try setFromProtobuf(decoder: &decoder, value: &v)
        if let v = v {
            value = v
        }
        return consumed
    }

    public static func setFromProtobuf(decoder: inout ProtobufDecoder, value: inout [BaseType]) throws -> Bool {
        throw DecodingError.schemaMismatch
    }
}

protocol ProtobufMapValueType: MapValueType {
}

extension ProtobufMapValueType {
    public static func decodeProtobufMapValue(decoder: inout ProtobufDecoder, value: inout BaseType?) throws {
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

    public static func setFromProtobuf(decoder: inout ProtobufDecoder, value: inout BaseType?) throws -> Bool {
        var i: Float = 0
        try decoder.decodeFourByteNumber(value: &i)
        value = i
        return true
    }

    public static func setFromProtobuf(decoder: inout ProtobufDecoder, value: inout [BaseType]) throws -> Bool {
        switch decoder.fieldWireFormat {
        case .fixed32:
            var i: Float = 0
            try decoder.decodeFourByteNumber(value: &i)
            value.append(i)
            return true
        case .lengthDelimited:
            var n: Int = 0
            let p = try decoder.getFieldBodyBytes(count: &n)
            value.reserveCapacity(value.count + n / MemoryLayout<BaseType>.size)
            var decoder = ProtobufDecoder(protobufPointer: p, count: n)
            var i: Float = 0
            while !decoder.complete {
                try decoder.decodeFourByteNumber(value: &i)
                value.append(i)
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

    public static func setFromProtobuf(decoder: inout ProtobufDecoder, value: inout BaseType?) throws -> Bool {
        var i: Double = 0
        try decoder.decodeEightByteNumber(value: &i)
        value = i
        return true
    }

    public static func setFromProtobuf(decoder: inout ProtobufDecoder, value: inout [BaseType]) throws -> Bool {
        switch decoder.fieldWireFormat {
        case .fixed64:
            var i: Double = 0
            try decoder.decodeEightByteNumber(value: &i)
            value.append(i)
            return true
        case .lengthDelimited:
            var n: Int = 0
            let p = try decoder.getFieldBodyBytes(count: &n)
            value.reserveCapacity(value.count + n / MemoryLayout<BaseType>.size)
            var decoder = ProtobufDecoder(protobufPointer: p, count: n)
            var i: Double = 0
            while !decoder.complete {
                try decoder.decodeEightByteNumber(value: &i)
                value.append(i)
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

    public static func setFromProtobuf(decoder: inout ProtobufDecoder, value: inout BaseType?) throws -> Bool {
        let varint = try decoder.decodeVarint()
        value = Int32(truncatingBitPattern: varint)
        return true
    }

    public static func setFromProtobuf(decoder: inout ProtobufDecoder, value: inout [BaseType]) throws -> Bool {
        switch decoder.fieldWireFormat {
        case .varint:
            let varint = try decoder.decodeVarint()
            value.append(Int32(truncatingBitPattern: varint))
            return true
        case .lengthDelimited:
            var n: Int = 0
            let p = try decoder.getFieldBodyBytes(count: &n)
            var decoder = ProtobufDecoder(protobufPointer: p, count: n)
            while !decoder.complete {
                let varint = try decoder.decodeVarint()
                value.append(Int32(truncatingBitPattern: varint))
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

    public static func setFromProtobuf(decoder: inout ProtobufDecoder, value: inout BaseType?) throws -> Bool {
        let varint = try decoder.decodeVarint()
        value = Int64(bitPattern: varint)
        return true
    }

    public static func setFromProtobuf(decoder: inout ProtobufDecoder, value: inout [BaseType]) throws -> Bool {
        switch decoder.fieldWireFormat {
        case .varint:
            let varint = try decoder.decodeVarint()
            value.append(Int64(bitPattern: varint))
            return true
        case .lengthDelimited:
            var n: Int = 0
            let p = try decoder.getFieldBodyBytes(count: &n)
            var decoder = ProtobufDecoder(protobufPointer: p, count: n)
            while !decoder.complete {
                let varint = try decoder.decodeVarint()
                value.append(Int64(bitPattern: varint))
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

    public static func setFromProtobuf(decoder: inout ProtobufDecoder, value: inout BaseType?) throws -> Bool {
        let varint = try decoder.decodeVarint()
        value = UInt32(truncatingBitPattern: varint)
        return true
    }

    public static func setFromProtobuf(decoder: inout ProtobufDecoder, value: inout [BaseType]) throws -> Bool {
        switch decoder.fieldWireFormat {
        case .varint:
            let varint = try decoder.decodeVarint()
            value.append(UInt32(truncatingBitPattern: varint))
            return true
        case .lengthDelimited:
            var n: Int = 0
            let p = try decoder.getFieldBodyBytes(count: &n)
            var decoder = ProtobufDecoder(protobufPointer: p, count: n)
            while !decoder.complete {
                let t = try decoder.decodeVarint()
                value.append(UInt32(truncatingBitPattern: t))
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

    public static func setFromProtobuf(decoder: inout ProtobufDecoder, value: inout BaseType?) throws -> Bool {
        value = try decoder.decodeVarint()
        return true
    }

    public static func setFromProtobuf(decoder: inout ProtobufDecoder, value: inout [BaseType]) throws -> Bool {
        switch decoder.fieldWireFormat {
        case .varint:
            let varint = try decoder.decodeVarint()
            value.append(varint)
            return true
        case .lengthDelimited:
            var n: Int = 0
            let p = try decoder.getFieldBodyBytes(count: &n)
            var decoder = ProtobufDecoder(protobufPointer: p, count: n)
            while !decoder.complete {
                let t = try decoder.decodeVarint()
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

    public static func setFromProtobuf(decoder: inout ProtobufDecoder, value: inout BaseType?) throws -> Bool {
        let varint = try decoder.decodeVarint()
        let t = UInt32(truncatingBitPattern: varint)
        value = ZigZag.decoded(t)
        return true
    }

    public static func setFromProtobuf(decoder: inout ProtobufDecoder, value: inout [BaseType]) throws -> Bool {
        switch decoder.fieldWireFormat {
        case .varint:
            let varint = try decoder.decodeVarint()
            let t = UInt32(truncatingBitPattern: varint)
            value.append(ZigZag.decoded(t))
            return true
        case .lengthDelimited:
            var n: Int = 0
            let p = try decoder.getFieldBodyBytes(count: &n)
            var decoder = ProtobufDecoder(protobufPointer: p, count: n)
            while !decoder.complete {
                let varint = try decoder.decodeVarint()
                let t = UInt32(truncatingBitPattern: varint)
                value.append(ZigZag.decoded(t))
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


    public static func setFromProtobuf(decoder: inout ProtobufDecoder, value: inout BaseType?) throws -> Bool {
        let varint = try decoder.decodeVarint()
        value = ZigZag.decoded(varint)
        return true
    }

    public static func setFromProtobuf(decoder: inout ProtobufDecoder, value: inout [BaseType]) throws -> Bool {
        switch decoder.fieldWireFormat {
        case .varint:
            let varint = try decoder.decodeVarint()
            value.append(ZigZag.decoded(varint))
            return true
        case .lengthDelimited:
            var n: Int = 0
            let p = try decoder.getFieldBodyBytes(count: &n)
            var decoder = ProtobufDecoder(protobufPointer: p, count: n)
            while !decoder.complete {
                let varint = try decoder.decodeVarint()
                value.append(ZigZag.decoded(varint))
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

    public static func setFromProtobuf(decoder: inout ProtobufDecoder, value: inout BaseType?) throws -> Bool {
        var i: UInt32 = 0
        try decoder.decodeFourByteNumber(value: &i)
        value = UInt32(littleEndian: i)
        return true
    }

    public static func setFromProtobuf(decoder: inout ProtobufDecoder, value: inout [BaseType]) throws -> Bool {
        switch decoder.fieldWireFormat {
        case .fixed32:
            var i: UInt32 = 0
            try decoder.decodeFourByteNumber(value: &i)
            value.append(UInt32(littleEndian: i))
            return true
        case .lengthDelimited:
            var n: Int = 0
            let p = try decoder.getFieldBodyBytes(count: &n)
            value.reserveCapacity(value.count + n / MemoryLayout<BaseType>.size)
            var decoder = ProtobufDecoder(protobufPointer: p, count: n)
            var i: UInt32 = 0
            while !decoder.complete {
                try decoder.decodeFourByteNumber(value: &i)
                value.append(UInt32(littleEndian: i))
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

    public static func setFromProtobuf(decoder: inout ProtobufDecoder, value: inout BaseType?) throws -> Bool {
        var i: UInt64 = 0
        try decoder.decodeEightByteNumber(value: &i)
        value = UInt64(littleEndian: i)
        return true
    }

    public static func setFromProtobuf(decoder: inout ProtobufDecoder, value: inout [BaseType]) throws -> Bool {
        switch decoder.fieldWireFormat {
        case .fixed64:
            var i: UInt64 = 0
            try decoder.decodeEightByteNumber(value: &i)
            value.append(UInt64(littleEndian: i))
            return true
        case .lengthDelimited:
            var n: Int = 0
            let p = try decoder.getFieldBodyBytes(count: &n)
            value.reserveCapacity(value.count + n / MemoryLayout<BaseType>.size)
            var decoder = ProtobufDecoder(protobufPointer: p, count: n)
            var i: UInt64 = 0
            while !decoder.complete {
                try decoder.decodeEightByteNumber(value: &i)
                value.append(UInt64(littleEndian: i))
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

    public static func setFromProtobuf(decoder: inout ProtobufDecoder, value: inout BaseType?) throws -> Bool {
        var i: Int32 = 0
        try decoder.decodeFourByteNumber(value: &i)
        value = Int32(littleEndian: i)
        return true
    }

    public static func setFromProtobuf(decoder: inout ProtobufDecoder, value: inout [BaseType]) throws -> Bool {
        switch decoder.fieldWireFormat {
        case .fixed32:
            var i: Int32 = 0
            try decoder.decodeFourByteNumber(value: &i)
            value.append(Int32(littleEndian: i))
            return true
        case .lengthDelimited:
            var n: Int = 0
            let p = try decoder.getFieldBodyBytes(count: &n)
            value.reserveCapacity(value.count + n / MemoryLayout<BaseType>.size)
            var decoder = ProtobufDecoder(protobufPointer: p, count: n)
            var i: Int32 = 0
            while !decoder.complete {
                try decoder.decodeFourByteNumber(value: &i)
                value.append(Int32(littleEndian: i))
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

    public static func setFromProtobuf(decoder: inout ProtobufDecoder, value: inout BaseType?) throws -> Bool {
        var i: Int64 = 0
        try decoder.decodeEightByteNumber(value: &i)
        value = Int64(littleEndian: i)
        return true
    }

    public static func setFromProtobuf(decoder: inout ProtobufDecoder, value: inout [BaseType]) throws -> Bool {
        switch decoder.fieldWireFormat {
        case .fixed64:
            var i: Int64 = 0
            try decoder.decodeEightByteNumber(value: &i)
            value.append(Int64(littleEndian: i))
            return true
        case .lengthDelimited:
            var n: Int = 0
            let p = try decoder.getFieldBodyBytes(count: &n)
            value.reserveCapacity(value.count + n / MemoryLayout<BaseType>.size)
            var decoder = ProtobufDecoder(protobufPointer: p, count: n)
            var i: Int64 = 0
            while !decoder.complete {
                try decoder.decodeEightByteNumber(value: &i)
                value.append(Int64(littleEndian: i))
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


    public static func setFromProtobuf(decoder: inout ProtobufDecoder, value: inout BaseType?) throws -> Bool {
        let varint = try decoder.decodeVarint()
        value = (varint != 0)
        return true
    }

    public static func setFromProtobuf(decoder: inout ProtobufDecoder, value: inout [BaseType]) throws -> Bool {
        switch decoder.fieldWireFormat {
        case .varint:
            let varint = try decoder.decodeVarint()
            value.append(varint != 0)
            return true
        case .lengthDelimited:
            var n: Int = 0
            let p = try decoder.getFieldBodyBytes(count: &n)
            var decoder = ProtobufDecoder(protobufPointer: p, count: n)
            while !decoder.complete {
                let t = try decoder.decodeVarint()
                value.append(t != 0)
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

extension ProtobufString: ProtobufMapValueType {
    public static var protobufWireFormat: WireFormat { return .lengthDelimited }
    public static func serializeProtobufValue(encoder: inout ProtobufEncoder, value: String) {
        encoder.putStringValue(value: value)
    }

    public static func setFromProtobuf(decoder: inout ProtobufDecoder, value: inout String?) throws -> Bool {
        var n: Int = 0
        let p = try decoder.getFieldBodyBytes(count: &n)
        if let s = utf8ToString(bytes: p, count: n) {
            value = s
            return true
        } else {
            throw DecodingError.invalidUTF8
        }
    }

    public static func setFromProtobuf(decoder: inout ProtobufDecoder, value: inout [String]) throws -> Bool {
        guard decoder.fieldWireFormat == .lengthDelimited else {
            throw DecodingError.schemaMismatch
        }
        var n: Int = 0
        let p = try decoder.getFieldBodyBytes(count: &n)
        if let s = utf8ToString(bytes: p, count: n) {
            value.append(s)
            return true
        } else {
            throw DecodingError.invalidUTF8
        }
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

    public static func setFromProtobuf(decoder: inout ProtobufDecoder, value: inout Data?) throws -> Bool {
        var n: Int = 0
        let p = try decoder.getFieldBodyBytes(count: &n)
        value = Data(bytes: p, count: n)
        return true
    }

    public static func setFromProtobuf(decoder: inout ProtobufDecoder, value: inout [Data]) throws -> Bool {
        guard decoder.fieldWireFormat == .lengthDelimited else {
            throw DecodingError.schemaMismatch
        }
        var n: Int = 0
        let p = try decoder.getFieldBodyBytes(count: &n)
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

    public static func setFromProtobuf(decoder: inout ProtobufDecoder, value: inout Self?) throws -> Bool {
        let varint = try decoder.decodeVarint()
        if let v = Self(rawValue: Int(Int32(truncatingBitPattern: varint))) {
            value = v
            return true
        } else {
            return false
        }
    }

    public static func setFromProtobuf(decoder: inout ProtobufDecoder, value: inout [Self]) throws -> Bool {
        switch decoder.fieldWireFormat {
        case .varint:
            let varint = try decoder.decodeVarint()
            if let v = Self(rawValue: Int(Int32(truncatingBitPattern: varint))) {
                value.append(v)
                return true
            } else {
                return false
            }
        case .lengthDelimited:
            var n: Int = 0
            var extras = [Int32]()
            let p = try decoder.getFieldBodyBytes(count: &n)
            var subdecoder = ProtobufDecoder(protobufPointer: p, count: n)
            while !subdecoder.complete {
                let u64 = try subdecoder.decodeVarint()
                let i32 = Int32(truncatingBitPattern: u64)
                if let v = Self(rawValue: Int(i32)) {
                    value.append(v)
                } else {
                    extras.append(i32)
                }
            }
            if extras.isEmpty {
                decoder.unknownOverride = nil
            } else {
                let fieldTag = FieldTag(fieldNumber: decoder.fieldNumber, wireFormat: .lengthDelimited)
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
                decoder.unknownOverride = field
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

    static func decodeProtobufMapValue(decoder: inout ProtobufDecoder, value: inout Self?) throws {
        try decoder.decodeSingularMessageField(fieldType: Self.self, value: &value)
        assert(value != nil)
    }

    init(protobuf: Data) throws {
        try self.init(protobuf: protobuf, extensions: nil)
    }

    init(protobuf: Data, extensions: ExtensionSet?) throws {
        self.init()
        if !protobuf.isEmpty {
            try protobuf.withUnsafeBytes { (pointer: UnsafePointer<UInt8>) in
                try decodeIntoSelf(protobufBytes: pointer, count: protobuf.count, extensions: extensions)
            }
        }
    }

    init(protobufBytes: UnsafePointer<UInt8>, count: Int) throws {
        try self.init(protobufBytes: protobufBytes, count: count, extensions: nil)
    }

    init(protobufBytes: UnsafePointer<UInt8>, count: Int, extensions: ExtensionSet?) throws {
        self.init()
        try decodeIntoSelf(protobufBytes: protobufBytes, count: count, extensions: extensions)
    }
}

/// Proto2 messages preserve unknown fields
public extension Proto2Message {
    public mutating func decodeIntoSelf(protobufBytes: UnsafePointer<UInt8>, count: Int, extensions: ExtensionSet?) throws {
        var protobufDecoder = ProtobufDecoder(protobufPointer: protobufBytes, count: count, extensions: extensions)
        try protobufDecoder.decodeFullObject(message: &self)
        if let unknownData = protobufDecoder.unknownData {
            unknown.append(protobufData: unknownData)
        }
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
