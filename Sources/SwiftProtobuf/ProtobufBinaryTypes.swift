// ProtobufRuntime/Sources/Protobuf/ProtobufBinaryTypes.swift - Per-type binary coding
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
/// Extensions to the proto types defined in ProtobufTypes.swift to provide
/// type-specific binary coding and decoding.
///
// -----------------------------------------------------------------------------

import Swift
import Foundation

public protocol ProtobufBinaryCodableType: ProtobufTypePropertiesBase {
    static var protobufWireFormat: WireFormat { get }
    /// Write out the protobuf value only.
    static func serializeProtobufValue(encoder: inout ProtobufBinaryEncoder, value: BaseType) throws

    static func setFromProtobufVarint(varint: UInt64, value: inout BaseType?) throws -> Bool
    static func setFromProtobufVarint(varint: UInt64, value: inout [BaseType]) throws -> Bool
    static func setFromProtobufFixed4(fixed4: [UInt8], value: inout BaseType?) throws -> Bool
    static func setFromProtobufFixed4(fixed4: [UInt8], value: inout [BaseType]) throws -> Bool
    static func setFromProtobufFixed8(fixed8: [UInt8], value: inout BaseType?) throws -> Bool
    static func setFromProtobufFixed8(fixed8: [UInt8], value: inout [BaseType]) throws -> Bool
    static func setFromProtobufBuffer(buffer: UnsafeBufferPointer<UInt8>, value: inout BaseType?) throws -> Bool
    static func setFromProtobufBuffer(buffer: UnsafeBufferPointer<UInt8>, value: inout [BaseType]) throws -> Bool

    static func setFromProtobufBinaryDecoder(decoder: inout ProtobufBinaryDecoder, value: inout [BaseType]) throws -> Bool

    // Special interface for decoding a value of this type as a map value.
    static func decodeProtobufMapValue(decoder: inout ProtobufFieldDecoder, value: inout BaseType?) throws

    /// Returns the number of bytes required to encode `value` on the wire.
    ///
    /// Note that for length-delimited data (such as strings, bytes, and messages), the returned
    /// size includes the space required for the length prefix. For messages, this is a subtle
    /// distinction from the `serializedSize()` method, which does *not* include the length prefix.
    static func encodedSizeWithoutTag(of value: BaseType) throws -> Int
}

/// Extension defines default handling for mismatched wire types.
/// TODO: Examine how C++ proto2 treats wire type mismatches -- if
/// it treats them as unknown fields, consider changing the following
/// to 'return false' to match.
public extension ProtobufBinaryCodableType {
    public static func setFromProtobufVarint(varint: UInt64, value: inout BaseType?) throws -> Bool {
        throw ProtobufDecodingError.schemaMismatch
    }

    public static func setFromProtobufVarint(varint: UInt64, value: inout [BaseType]) throws -> Bool {
        throw ProtobufDecodingError.schemaMismatch
    }

    public static func setFromProtobufFixed4(fixed4: [UInt8], value: inout BaseType?) throws -> Bool {
        throw ProtobufDecodingError.schemaMismatch
    }

    public static func setFromProtobufFixed4(fixed4: [UInt8], value: inout [BaseType]) throws -> Bool {
        throw ProtobufDecodingError.schemaMismatch
    }

    public static func setFromProtobufFixed8(fixed8: [UInt8], value: inout BaseType?) throws -> Bool {
        throw ProtobufDecodingError.schemaMismatch
    }

    public static func setFromProtobufFixed8(fixed8: [UInt8], value: inout [BaseType]) throws -> Bool {
        throw ProtobufDecodingError.schemaMismatch
    }

    public static func setFromProtobufBuffer(buffer: UnsafeBufferPointer<UInt8>, value: inout BaseType?) throws -> Bool {
        throw ProtobufDecodingError.schemaMismatch
    }

    public static func setFromProtobufBuffer(buffer: UnsafeBufferPointer<UInt8>, value: inout [BaseType]) throws -> Bool {
        throw ProtobufDecodingError.schemaMismatch
    }

    public static func setFromProtobufBinaryDecoder(decoder: inout ProtobufBinaryDecoder, value: inout [BaseType]) throws -> Bool {
        throw ProtobufDecodingError.schemaMismatch
    }
}

public extension ProtobufTypeProperties {
    public static func decodeProtobufMapValue(decoder: inout ProtobufFieldDecoder, value: inout BaseType?) throws {
        let handled = try decoder.decodeSingularField(fieldType: Self.self, value: &value)
        assert(handled)
    }
}

public protocol ProtobufBinaryCodableMapKeyType: ProtobufTypePropertiesBase {
    /// Basic protobuf encoding hooks.
    static var protobufWireFormat: WireFormat { get }
    /// Write out the protobuf value only.
    static func serializeProtobufValue(encoder: inout ProtobufBinaryEncoder, value: BaseType)
    static func encodedSizeWithoutTag(of: BaseType) throws -> Int
}


///
/// Float traits
///
public extension ProtobufFloat {
    public static var protobufWireFormat: WireFormat { return .fixed32 }
    public static func serializeProtobufValue(encoder: inout ProtobufBinaryEncoder, value: Float) {
        encoder.putFloatValue(value: value)
    }

    public static func setFromProtobufFixed4(fixed4: [UInt8], value: inout BaseType?) throws -> Bool {
        assert(fixed4.count == 4)
        var i: Float = 0
        withUnsafeMutablePointer(to: &i) { ip -> Void in
            ip.withMemoryRebound(to: UInt8.self, capacity: 4) { dest -> () in
                let src = UnsafeMutablePointer<UInt8>(mutating: fixed4)
                dest.initialize(from: src, count: 4)
            }
        }
        value = i
        return true
    }

    public static func setFromProtobufFixed4(fixed4: [UInt8], value: inout [BaseType]) throws -> Bool {
        assert(fixed4.count == 4)
        var i: Float = 0
        withUnsafeMutablePointer(to: &i) { ip -> Void in
            ip.withMemoryRebound(to: UInt8.self, capacity: 4) { dest -> () in
                let src = UnsafeMutablePointer<UInt8>(mutating: fixed4)
                dest.initialize(from: src, count: 4)
            }
        }
        value.append(i)
        return true
    }

    public static func setFromProtobufBuffer(buffer: UnsafeBufferPointer<UInt8>, value: inout [BaseType]) throws -> Bool {
        var decoder = ProtobufBinaryDecoder(protobufPointer: buffer)
        while let t = try decoder.decodeFloat() {
            value.append(t)
        }
        return true
    }

    public static func encodedSizeWithoutTag(of value: Float) -> Int {
        return MemoryLayout<Float>.size
    }
}


///
/// Double traits
///
public extension ProtobufDouble {
    public static var protobufWireFormat: WireFormat { return .fixed64 }
    public static func serializeProtobufValue(encoder: inout ProtobufBinaryEncoder, value: Double) {
        encoder.putDoubleValue(value: value)
    }

    public static func setFromProtobufFixed8(fixed8: [UInt8], value: inout BaseType?) throws -> Bool {
        assert(fixed8.count == 8)
        var i: Double = 0
        withUnsafeMutablePointer(to: &i) { ip -> Void in
            ip.withMemoryRebound(to: UInt8.self, capacity: 8) { dest -> () in
                let src = UnsafeMutablePointer<UInt8>(mutating: fixed8)
                dest.initialize(from: src, count: 8)
            }
        }
        value = i
        return true
    }

    public static func setFromProtobufFixed8(fixed8: [UInt8], value: inout [BaseType]) throws -> Bool {
        assert(fixed8.count == 8)
        var i: Double = 0
        withUnsafeMutablePointer(to: &i) { ip -> Void in
            ip.withMemoryRebound(to: UInt8.self, capacity: 8) { dest -> () in
                let src = UnsafeMutablePointer<UInt8>(mutating: fixed8)
                dest.initialize(from: src, count: 8)
            }
        }
        value.append(i)
        return true
    }

    public static func setFromProtobufBuffer(buffer: UnsafeBufferPointer<UInt8>, value: inout [BaseType]) throws -> Bool {
        var decoder = ProtobufBinaryDecoder(protobufPointer: buffer)
        while let t = try decoder.decodeDouble() {
            value.append(t)
        }
        return true
    }

    public static func encodedSizeWithoutTag(of value: Double) -> Int {
        return MemoryLayout<Double>.size
    }
}

///
/// Int32 traits
///
public extension ProtobufInt32 {
    public static var protobufWireFormat: WireFormat { return .varint }

    public static func serializeProtobufValue(encoder: inout ProtobufBinaryEncoder, value: Int32) {
        encoder.putVarInt(value: Int64(value))
    }

    public static func setFromProtobufVarint(varint: UInt64, value: inout BaseType?) throws -> Bool {
        value = Int32(truncatingBitPattern: varint)
        return true
    }

    public static func setFromProtobufVarint(varint: UInt64, value: inout [BaseType]) throws -> Bool {
        value.append(Int32(truncatingBitPattern: varint))
        return true
    }

    public static func setFromProtobufBuffer(buffer: UnsafeBufferPointer<UInt8>, value: inout [BaseType]) throws -> Bool {
        var decoder = ProtobufBinaryDecoder(protobufPointer: buffer)
        while let t = try decoder.decodeInt32() {
            value.append(t)
        }
        return true
    }

    public static func encodedSizeWithoutTag(of value: Int32) -> Int {
        return Varint.encodedSize(of: value)
    }
}

///
/// Int64 traits
///
public extension ProtobufInt64 {
    public static var protobufWireFormat: WireFormat { return .varint }

    public static func serializeProtobufValue(encoder: inout ProtobufBinaryEncoder, value: Int64) {
        encoder.putVarInt(value: value)
    }

    public static func setFromProtobufVarint(varint: UInt64, value: inout BaseType?) throws -> Bool {
        value = Int64(bitPattern: varint)
        return true
    }

    public static func setFromProtobufVarint(varint: UInt64, value: inout [BaseType]) throws -> Bool {
        value.append(Int64(bitPattern: varint))
        return true
    }

    public static func setFromProtobufBuffer(buffer: UnsafeBufferPointer<UInt8>, value: inout [BaseType]) throws -> Bool {
        var decoder = ProtobufBinaryDecoder(protobufPointer: buffer)
        while let t = try decoder.decodeInt64() {
            value.append(t)
        }
        return true
    }

    public static func encodedSizeWithoutTag(of value: Int64) -> Int {
        return Varint.encodedSize(of: value)
    }
}

///
/// UInt32 traits
///
public extension ProtobufUInt32 {
    public static var protobufWireFormat: WireFormat { return .varint }

    public static func serializeProtobufValue(encoder: inout ProtobufBinaryEncoder, value: UInt32) {
        encoder.putVarInt(value: UInt64(value))
    }

    public static func setFromProtobufVarint(varint: UInt64, value: inout BaseType?) throws -> Bool {
        value = UInt32(truncatingBitPattern: varint)
        return true
    }

    public static func setFromProtobufVarint(varint: UInt64, value: inout [BaseType]) throws -> Bool {
        value.append(UInt32(truncatingBitPattern: varint))
        return true
    }

    public static func setFromProtobufBuffer(buffer: UnsafeBufferPointer<UInt8>, value: inout [BaseType]) throws -> Bool {
        var decoder = ProtobufBinaryDecoder(protobufPointer: buffer)
        while let t = try decoder.decodeUInt32() {
            value.append(t)
        }
        return true
    }

    public static func encodedSizeWithoutTag(of value: UInt32) -> Int {
        return Varint.encodedSize(of: value)
    }
}

///
/// UInt64 traits
///
public extension ProtobufUInt64 {
    public static var protobufWireFormat: WireFormat { return .varint }

    public static func serializeProtobufValue(encoder: inout ProtobufBinaryEncoder, value: UInt64) {
        encoder.putVarInt(value: value)
    }

    public static func setFromProtobufVarint(varint: UInt64, value: inout BaseType?) throws -> Bool {
        value = varint
        return true
    }

    public static func setFromProtobufVarint(varint: UInt64, value: inout [BaseType]) throws -> Bool {
        value.append(varint)
        return true
    }

    public static func setFromProtobufBuffer(buffer: UnsafeBufferPointer<UInt8>, value: inout [BaseType]) throws -> Bool {
        var decoder = ProtobufBinaryDecoder(protobufPointer: buffer)
        while let t = try decoder.decodeUInt64() {
            value.append(t)
        }
        return true
    }

    public static func encodedSizeWithoutTag(of value: UInt64) -> Int {
        return Varint.encodedSize(of: value)
    }
}

///
/// SInt32 traits
///
public extension ProtobufSInt32 {
    public static var protobufWireFormat: WireFormat { return .varint }

    public static func serializeProtobufValue(encoder: inout ProtobufBinaryEncoder, value: Int32) {
        encoder.putZigZagVarInt(value: Int64(value))
    }

    public static func setFromProtobufVarint(varint: UInt64, value: inout BaseType?) throws -> Bool {
        let t = UInt32(truncatingBitPattern: varint)
        value = ZigZag.decoded(t)
        return true
    }

    public static func setFromProtobufVarint(varint: UInt64, value: inout [BaseType]) throws -> Bool {
        let t = UInt32(truncatingBitPattern: varint)
        value.append(ZigZag.decoded(t))
        return true
    }

    public static func setFromProtobufBuffer(buffer: UnsafeBufferPointer<UInt8>, value: inout [BaseType]) throws -> Bool {
        var decoder = ProtobufBinaryDecoder(protobufPointer: buffer)
        while let t = try decoder.decodeSInt32() {
            value.append(t)
        }
        return true
    }

    public static func encodedSizeWithoutTag(of value: Int32) -> Int {
        return Varint.encodedSize(of: ZigZag.encoded(value))
    }
}

///
/// SInt64 traits
///
public extension ProtobufSInt64 {
    public static var protobufWireFormat: WireFormat { return .varint }

    public static func serializeProtobufValue(encoder: inout ProtobufBinaryEncoder, value: Int64) {
        encoder.putZigZagVarInt(value: value)
    }

    public static func setFromProtobufVarint(varint: UInt64, value: inout BaseType?) throws -> Bool {
        value = ZigZag.decoded(varint)
        return true
    }

    public static func setFromProtobufVarint(varint: UInt64, value: inout [BaseType]) throws -> Bool {
        value.append(ZigZag.decoded(varint))
        return true
    }

    public static func setFromProtobufBuffer(buffer: UnsafeBufferPointer<UInt8>, value: inout [BaseType]) throws -> Bool {
        var decoder = ProtobufBinaryDecoder(protobufPointer: buffer)
        while let t = try decoder.decodeSInt64() {
            value.append(t)
        }
        return true
    }

    public static func encodedSizeWithoutTag(of value: Int64) -> Int {
        return Varint.encodedSize(of: ZigZag.encoded(value))
    }
}

///
/// Fixed32 traits
///
public extension ProtobufFixed32 {
    public static var protobufWireFormat: WireFormat { return .fixed32 }
    public static func serializeProtobufValue(encoder: inout ProtobufBinaryEncoder, value: UInt32) {
        encoder.putFixedUInt32(value: value)
    }

    public static func setFromProtobufFixed4(fixed4: [UInt8], value: inout BaseType?) throws -> Bool {
        assert(fixed4.count == 4)
        var i: UInt32 = 0
        withUnsafeMutablePointer(to: &i) { ip -> Void in
            ip.withMemoryRebound(to: UInt8.self, capacity: 4) { dest -> () in
                let src = UnsafeMutablePointer<UInt8>(mutating: fixed4)
                dest.initialize(from: src, count: 4)
            }
        }
        value = i
        return true
    }

    public static func setFromProtobufFixed4(fixed4: [UInt8], value: inout [BaseType]) throws -> Bool {
        assert(fixed4.count == 4)
        var i: UInt32 = 0
        withUnsafeMutablePointer(to: &i) { ip -> Void in
            ip.withMemoryRebound(to: UInt8.self, capacity: 4) { dest -> () in
                let src = UnsafeMutablePointer<UInt8>(mutating: fixed4)
                dest.initialize(from: src, count: 4)
            }
        }
        value.append(i)
        return true
    }

    public static func setFromProtobufBuffer(buffer: UnsafeBufferPointer<UInt8>, value: inout [BaseType]) throws -> Bool {
        var decoder = ProtobufBinaryDecoder(protobufPointer: buffer)
        while let t = try decoder.decodeFixed32() {
            value.append(t)
        }
        return true
    }

    public static func encodedSizeWithoutTag(of value: UInt32) -> Int {
        return MemoryLayout<UInt32>.size
    }
}

///
/// Fixed64 traits
///
public extension ProtobufFixed64 {
    public static var protobufWireFormat: WireFormat { return .fixed64 }
    public static func serializeProtobufValue(encoder: inout ProtobufBinaryEncoder, value: UInt64) {
        encoder.putFixedUInt64(value: value.littleEndian)
    }

    public static func setFromProtobufFixed8(fixed8: [UInt8], value: inout BaseType?) throws -> Bool {
        assert(fixed8.count == 8)
        var i: UInt64 = 0
        withUnsafeMutablePointer(to: &i) { ip -> Void in
            ip.withMemoryRebound(to: UInt8.self, capacity: 8) { dest -> () in
                let src = UnsafeMutablePointer<UInt8>(mutating: fixed8)
                dest.initialize(from: src, count: 8)
            }
        }
        value = i
        return true
    }

    public static func setFromProtobufFixed8(fixed8: [UInt8], value: inout [BaseType]) throws -> Bool {
        assert(fixed8.count == 8)
        var i: UInt64 = 0
        withUnsafeMutablePointer(to: &i) { ip -> Void in
            ip.withMemoryRebound(to: UInt8.self, capacity: 8) { dest -> () in
                let src = UnsafeMutablePointer<UInt8>(mutating: fixed8)
                dest.initialize(from: src, count: 8)
            }
        }
        value.append(i)
        return true
    }

    public static func setFromProtobufBuffer(buffer: UnsafeBufferPointer<UInt8>, value: inout [BaseType]) throws -> Bool {
        var decoder = ProtobufBinaryDecoder(protobufPointer: buffer)
        while let t = try decoder.decodeFixed64() {
            value.append(t)
        }
        return true
    }

    public static func encodedSizeWithoutTag(of value: UInt64) -> Int {
        return MemoryLayout<UInt64>.size
    }
}

///
/// SFixed32 traits
///
public extension ProtobufSFixed32 {
    public static var protobufWireFormat: WireFormat { return .fixed32 }
    public static func serializeProtobufValue(encoder: inout ProtobufBinaryEncoder, value: Int32) {
        encoder.putFixedUInt32(value: UInt32(bitPattern: value))
    }

    public static func setFromProtobufFixed4(fixed4: [UInt8], value: inout BaseType?) throws -> Bool {
        assert(fixed4.count == 4)
        var i: Int32 = 0
        withUnsafeMutablePointer(to: &i) { ip -> Void in
            ip.withMemoryRebound(to: UInt8.self, capacity: 4) { dest -> () in
                let src = UnsafeMutablePointer<UInt8>(mutating: fixed4)
                dest.initialize(from: src, count: 4)
            }
        }
        value = i
        return true
    }

    public static func setFromProtobufFixed4(fixed4: [UInt8], value: inout [BaseType]) throws -> Bool {
        assert(fixed4.count == 4)
        var i: Int32 = 0
        withUnsafeMutablePointer(to: &i) { ip -> Void in
            ip.withMemoryRebound(to: UInt8.self, capacity: 4) { dest -> () in
                let src = UnsafeMutablePointer<UInt8>(mutating: fixed4)
                dest.initialize(from: src, count: 4)
            }
        }
        value.append(i)
        return true
    }

    public static func setFromProtobufBuffer(buffer: UnsafeBufferPointer<UInt8>, value: inout [BaseType]) throws -> Bool {
        var decoder = ProtobufBinaryDecoder(protobufPointer: buffer)
        while let t = try decoder.decodeSFixed32() {
            value.append(t)
        }
        return true
    }

    public static func encodedSizeWithoutTag(of value: Int32) -> Int {
        return MemoryLayout<Int32>.size
    }
}

///
/// SFixed64 traits
///
public extension ProtobufSFixed64 {
    public static var protobufWireFormat: WireFormat { return .fixed64 }
    public static func serializeProtobufValue(encoder: inout ProtobufBinaryEncoder, value: Int64) {
        encoder.putFixedUInt64(value: UInt64(bitPattern: value.littleEndian))
    }

    public static func setFromProtobufFixed8(fixed8: [UInt8], value: inout BaseType?) throws -> Bool {
        assert(fixed8.count == 8)
        var i: Int64 = 0
        withUnsafeMutablePointer(to: &i) { ip -> Void in
            ip.withMemoryRebound(to: UInt8.self, capacity: 8) { dest -> () in
                let src = UnsafeMutablePointer<UInt8>(mutating: fixed8)
                dest.initialize(from: src, count: 8)
            }
        }
        value = i
        return true
    }

    public static func setFromProtobufFixed8(fixed8: [UInt8], value: inout [BaseType]) throws -> Bool {
        assert(fixed8.count == 8)
        var i: Int64 = 0
        withUnsafeMutablePointer(to: &i) { ip -> Void in
            ip.withMemoryRebound(to: UInt8.self, capacity: 8) { dest -> () in
                let src = UnsafeMutablePointer<UInt8>(mutating: fixed8)
                dest.initialize(from: src, count: 8)
            }
        }
        value.append(i)
        return true
    }

    public static func setFromProtobufBuffer(buffer: UnsafeBufferPointer<UInt8>, value: inout [BaseType]) throws -> Bool {
        var decoder = ProtobufBinaryDecoder(protobufPointer: buffer)
        while let t = try decoder.decodeSFixed64() {
            value.append(t)
        }
        return true
    }

    public static func encodedSizeWithoutTag(of value: Int64) -> Int {
        return MemoryLayout<Int64>.size
    }
}

///
/// Bool traits
///
public extension ProtobufBool {
    public static var protobufWireFormat: WireFormat { return .varint }

    public static func serializeProtobufValue(encoder: inout ProtobufBinaryEncoder, value: Bool) {
        encoder.putBoolValue(value: value)
    }

    public static func setFromProtobufVarint(varint: UInt64, value: inout BaseType?) throws -> Bool {
        value = (varint != 0)
        return true
    }

    public static func setFromProtobufVarint(varint: UInt64, value: inout [BaseType]) throws -> Bool {
        value.append(varint != 0)
        return true
    }

    public static func setFromProtobufBuffer(buffer: UnsafeBufferPointer<UInt8>, value: inout [BaseType]) throws -> Bool {
        var decoder = ProtobufBinaryDecoder(protobufPointer: buffer)
        while let t = try decoder.decodeBool() {
            value.append(t)
        }
        return true
    }

    public static func encodedSizeWithoutTag(of value: Bool) -> Int {
        return 1
    }
}

///
/// String traits
///
private func bufferToString(buffer: UnsafeBufferPointer<UInt8>) -> String? {
    var s = ""
    var bytes = buffer.makeIterator()
    var utf8Decoder = UTF8()
    while true {
        switch utf8Decoder.decode(&bytes) {
        case .scalarValue(let scalar): s.append(String(scalar))
        case .emptyInput: return s
        case .error: return nil
        }
    }
}

public extension ProtobufString {
    public static var protobufWireFormat: WireFormat { return .lengthDelimited }
    public static func serializeProtobufValue(encoder: inout ProtobufBinaryEncoder, value: String) {
        encoder.putStringValue(value: value)
    }

    public static func setFromProtobufBuffer(buffer: UnsafeBufferPointer<UInt8>, value: inout String?) throws -> Bool {
        if let s = bufferToString(buffer: buffer) {
            value = s
            return true
        }
        throw ProtobufDecodingError.invalidUTF8
    }

    public static func setFromProtobufBuffer(buffer: UnsafeBufferPointer<UInt8>, value: inout [String]) throws -> Bool {
        if let s = bufferToString(buffer: buffer) {
            value.append(s)
            return true
        }
        throw ProtobufDecodingError.invalidUTF8
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
public extension ProtobufBytes {
    public static var protobufWireFormat: WireFormat { return .lengthDelimited }

    public static func serializeProtobufValue(encoder: inout ProtobufBinaryEncoder, value: Data) {
        encoder.putBytesValue(value: [UInt8](value))
    }

    public static func setFromProtobufBuffer(buffer: UnsafeBufferPointer<UInt8>, value: inout Data?) throws -> Bool {
        value = Data(bytes: [UInt8](buffer))
        return true
    }

    public static func setFromProtobufBuffer(buffer: UnsafeBufferPointer<UInt8>, value: inout [Data]) throws -> Bool {
        value.append(Data(bytes: [UInt8](buffer)))
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
extension ProtobufEnum where RawValue == Int {
    public static var protobufWireFormat: WireFormat { return .varint }
    public static func decodeOptionalField(decoder: inout ProtobufFieldDecoder, value: inout BaseType?) throws -> Bool {
        return try decoder.decodeSingularField(fieldType: Self.self, value: &value)
    }

    public static func serializeProtobufValue(encoder: inout ProtobufBinaryEncoder, value: Self) {
        encoder.putVarInt(value: value.rawValue)
    }

    public static func setFromProtobufVarint(varint: UInt64, value: inout Self?) throws -> Bool {
        if let v = Self(rawValue: Int(Int32(truncatingBitPattern: varint))) {
            value = v
            return true
        } else {
            return false
        }
    }

    public static func setFromProtobufVarint(varint: UInt64, value: inout [Self]) throws -> Bool {
        if let v = Self(rawValue: Int(Int32(truncatingBitPattern: varint))) {
            value.append(v)
            return true
        } else {
            return false
        }
    }

    public static func setFromProtobufBuffer(buffer: UnsafeBufferPointer<UInt8>, value: inout [Self]) throws -> Bool {
        var decoder = ProtobufBinaryDecoder(protobufPointer: buffer)
        while let t = try decoder.decodeInt32() {
            if let e = Self(rawValue:Int(t)) {
                value.append(e)
            }
        }
        return true
    }

    public static func encodedSizeWithoutTag(of value: Self) -> Int {
        return Varint.encodedSize(of: Int32(truncatingBitPattern: value.rawValue))
    }
}

///
/// Messages
///

public protocol ProtobufBinaryMessageBase: ProtobufMessageBase {
    // Serialize to protobuf
    func serializeProtobuf() throws -> Data
    func serializedProtobufSize() throws -> Int
    // Decode from protobuf
    init(protobuf: Data) throws
    init(protobuf: Data, extensions: ProtobufExtensionSet?) throws
    init(protobufBuffer: UnsafeBufferPointer<UInt8>) throws
    init(protobufBuffer: UnsafeBufferPointer<UInt8>, extensions: ProtobufExtensionSet?) throws
}

public extension ProtobufBinaryMessageBase {
    func serializeProtobuf() throws -> Data {
        let requiredSize = try serializedProtobufSize()
        var data = Data(count: requiredSize)
        try data.withUnsafeMutableBytes { (pointer: UnsafeMutablePointer<UInt8>) in
            try serializeProtobuf(into: pointer)
        }
        return data
    }
    private func serializeProtobuf(into pointer: UnsafeMutablePointer<UInt8>) throws {
        _ = try ProtobufBinaryEncodingVisitor(message: self, pointer: pointer)
    }

    func serializedProtobufSize() throws -> Int {
        return try ProtobufBinarySizeVisitor(message: self).serializedSize
    }

    static var protobufWireFormat: WireFormat { return .lengthDelimited }

    static func serializeProtobufValue(encoder: inout ProtobufBinaryEncoder, value: Self) throws {
        let t = try value.serializeProtobuf()
        encoder.putBytesValue(value: t)
    }

    static func encodedSizeWithoutTag(of value: Self) throws -> Int {
        let messageSize = try value.serializedProtobufSize()
        return Varint.encodedSize(of: Int64(messageSize)) + messageSize
    }
}

public extension ProtobufMessage {
    static func decodeProtobufMapValue(decoder: inout ProtobufFieldDecoder, value: inout Self?) throws {
        let handled = try decoder.decodeSingularMessageField(fieldType: Self.self, value: &value)
        assert(handled)
    }

    init(protobuf: Data) throws {
        try self.init(protobuf: protobuf, extensions: nil)
    }

    init(protobuf: Data, extensions: ProtobufExtensionSet? = nil) throws {
        self.init()
        // We need to gracefully handle empty data, because the pointer passed into withUnsafeBytes'
        // closure will be nil in that case.
        guard !protobuf.isEmpty else {
            return
        }
        try protobuf.withUnsafeBytes { (pointer: UnsafePointer<UInt8>) in
            let bufferPointer = UnsafeBufferPointer<UInt8>(start: pointer, count: protobuf.count)
            try decodeIntoSelf(from: bufferPointer, extensions: extensions)
        }
    }

    init(protobufBuffer: UnsafeBufferPointer<UInt8>) throws {
        try self.init(protobufBuffer: protobufBuffer, extensions: nil)
    }
    init(protobufBuffer: UnsafeBufferPointer<UInt8>, extensions: ProtobufExtensionSet? = nil) throws {
        self.init()
        try decodeIntoSelf(from: protobufBuffer, extensions: extensions)
    }
    private mutating func decodeIntoSelf(from bufferPointer: UnsafeBufferPointer<UInt8>, extensions: ProtobufExtensionSet?) throws {
        var protobufDecoder = ProtobufBinaryDecoder(protobufPointer: bufferPointer, extensions: extensions)
        try protobufDecoder.decodeFullObject(message: &self)
    }
}

///
/// Groups
///

// TODO:  Does something belong here?

///
/// Maps
///
public extension ProtobufMap {
}
