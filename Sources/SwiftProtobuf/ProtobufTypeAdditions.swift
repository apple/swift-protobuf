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
    public static func setFromProtobufVarint(varint: UInt64, value: inout BaseType?) throws -> Bool {
        throw DecodingError.schemaMismatch
    }

    public static func setFromProtobufVarint(varint: UInt64, value: inout [BaseType]) throws -> Bool {
        throw DecodingError.schemaMismatch
    }

    public static func setFromProtobufFixed4(fixed4: [UInt8], value: inout BaseType?) throws {
        throw DecodingError.schemaMismatch
    }

    public static func setFromProtobufFixed4(fixed4: [UInt8], value: inout [BaseType]) throws {
        throw DecodingError.schemaMismatch
    }

    public static func setFromProtobufFixed8(fixed8: [UInt8], value: inout BaseType?) throws {
        throw DecodingError.schemaMismatch
    }

    public static func setFromProtobufFixed8(fixed8: [UInt8], value: inout [BaseType]) throws {
        throw DecodingError.schemaMismatch
    }

    public static func setFromProtobufBuffer(buffer: UnsafeBufferPointer<UInt8>, value: inout BaseType?) throws {
        throw DecodingError.schemaMismatch
    }

    public static func setFromProtobufBuffer(buffer: UnsafeBufferPointer<UInt8>, value: inout [BaseType], unknown: inout Data) throws {
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

    public static func setFromProtobufFixed4(fixed4: [UInt8], value: inout BaseType?) throws {
        assert(fixed4.count == 4)
        var i: Float = 0
        withUnsafeMutablePointer(to: &i) { ip -> Void in
            ip.withMemoryRebound(to: UInt8.self, capacity: 4) { dest -> () in
                let src = UnsafeMutablePointer<UInt8>(mutating: fixed4)
                dest.initialize(from: src, count: 4)
            }
        }
        value = i
    }

    public static func setFromProtobufFixed4(fixed4: [UInt8], value: inout [BaseType]) throws {
        assert(fixed4.count == 4)
        var i: Float = 0
        withUnsafeMutablePointer(to: &i) { ip -> Void in
            ip.withMemoryRebound(to: UInt8.self, capacity: 4) { dest -> () in
                let src = UnsafeMutablePointer<UInt8>(mutating: fixed4)
                dest.initialize(from: src, count: 4)
            }
        }
        value.append(i)
    }

    public static func setFromProtobufBuffer(buffer: UnsafeBufferPointer<UInt8>, value: inout [BaseType], unknown: inout Data) throws {
        var decoder = ProtobufDecoder(protobufPointer: buffer)
        while let t = try decoder.decodeFloat() {
            value.append(t)
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

    public static func setFromProtobufFixed8(fixed8: [UInt8], value: inout BaseType?) throws {
        assert(fixed8.count == 8)
        var i: Double = 0
        withUnsafeMutablePointer(to: &i) { ip -> Void in
            ip.withMemoryRebound(to: UInt8.self, capacity: 8) { dest -> () in
                let src = UnsafeMutablePointer<UInt8>(mutating: fixed8)
                dest.initialize(from: src, count: 8)
            }
        }
        value = i
    }

    public static func setFromProtobufFixed8(fixed8: [UInt8], value: inout [BaseType]) throws {
        assert(fixed8.count == 8)
        var i: Double = 0
        withUnsafeMutablePointer(to: &i) { ip -> Void in
            ip.withMemoryRebound(to: UInt8.self, capacity: 8) { dest -> () in
                let src = UnsafeMutablePointer<UInt8>(mutating: fixed8)
                dest.initialize(from: src, count: 8)
            }
        }
        value.append(i)
    }

    public static func setFromProtobufBuffer(buffer: UnsafeBufferPointer<UInt8>, value: inout [BaseType], unknown: inout Data) throws {
        var decoder = ProtobufDecoder(protobufPointer: buffer)
        while let t = try decoder.decodeDouble() {
            value.append(t)
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

    public static func setFromProtobufVarint(varint: UInt64, value: inout BaseType?) throws -> Bool {
        value = Int32(truncatingBitPattern: varint)
        return true
    }

    public static func setFromProtobufVarint(varint: UInt64, value: inout [BaseType]) throws -> Bool {
        value.append(Int32(truncatingBitPattern: varint))
        return true
    }

    public static func setFromProtobufBuffer(buffer: UnsafeBufferPointer<UInt8>, value: inout [BaseType], unknown: inout Data) throws {
        var decoder = ProtobufDecoder(protobufPointer: buffer)
        while let t = try decoder.decodeInt32() {
            value.append(t)
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

    public static func setFromProtobufVarint(varint: UInt64, value: inout BaseType?) throws -> Bool {
        value = Int64(bitPattern: varint)
        return true
    }

    public static func setFromProtobufVarint(varint: UInt64, value: inout [BaseType]) throws -> Bool {
        value.append(Int64(bitPattern: varint))
        return true
    }

    public static func setFromProtobufBuffer(buffer: UnsafeBufferPointer<UInt8>, value: inout [BaseType], unknown: inout Data) throws {
        var decoder = ProtobufDecoder(protobufPointer: buffer)
        while let t = try decoder.decodeInt64() {
            value.append(t)
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

    public static func setFromProtobufVarint(varint: UInt64, value: inout BaseType?) throws -> Bool {
        value = UInt32(truncatingBitPattern: varint)
        return true
    }

    public static func setFromProtobufVarint(varint: UInt64, value: inout [BaseType]) throws -> Bool {
        value.append(UInt32(truncatingBitPattern: varint))
        return true
    }

    public static func setFromProtobufBuffer(buffer: UnsafeBufferPointer<UInt8>, value: inout [BaseType], unknown: inout Data) throws {
        var decoder = ProtobufDecoder(protobufPointer: buffer)
        while let t = try decoder.decodeUInt32() {
            value.append(t)
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

    public static func setFromProtobufVarint(varint: UInt64, value: inout BaseType?) throws -> Bool {
        value = varint
        return true
    }

    public static func setFromProtobufVarint(varint: UInt64, value: inout [BaseType]) throws -> Bool {
        value.append(varint)
        return true
    }

    public static func setFromProtobufBuffer(buffer: UnsafeBufferPointer<UInt8>, value: inout [BaseType], unknown: inout Data) throws {
        var decoder = ProtobufDecoder(protobufPointer: buffer)
        while let t = try decoder.decodeUInt64() {
            value.append(t)
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

    public static func setFromProtobufBuffer(buffer: UnsafeBufferPointer<UInt8>, value: inout [BaseType], unknown: inout Data) throws {
        var decoder = ProtobufDecoder(protobufPointer: buffer)
        while let t = try decoder.decodeSInt32() {
            value.append(t)
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

    public static func setFromProtobufVarint(varint: UInt64, value: inout BaseType?) throws -> Bool {
        value = ZigZag.decoded(varint)
        return true
    }

    public static func setFromProtobufVarint(varint: UInt64, value: inout [BaseType]) throws -> Bool {
        value.append(ZigZag.decoded(varint))
        return true
    }

    public static func setFromProtobufBuffer(buffer: UnsafeBufferPointer<UInt8>, value: inout [BaseType], unknown: inout Data) throws {
        var decoder = ProtobufDecoder(protobufPointer: buffer)
        while let t = try decoder.decodeSInt64() {
            value.append(t)
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

    public static func setFromProtobufFixed4(fixed4: [UInt8], value: inout BaseType?) throws {
        assert(fixed4.count == 4)
        var i: UInt32 = 0
        withUnsafeMutablePointer(to: &i) { ip -> Void in
            ip.withMemoryRebound(to: UInt8.self, capacity: 4) { dest -> () in
                let src = UnsafeMutablePointer<UInt8>(mutating: fixed4)
                dest.initialize(from: src, count: 4)
            }
        }
        value = i
    }

    public static func setFromProtobufFixed4(fixed4: [UInt8], value: inout [BaseType]) throws {
        assert(fixed4.count == 4)
        var i: UInt32 = 0
        withUnsafeMutablePointer(to: &i) { ip -> Void in
            ip.withMemoryRebound(to: UInt8.self, capacity: 4) { dest -> () in
                let src = UnsafeMutablePointer<UInt8>(mutating: fixed4)
                dest.initialize(from: src, count: 4)
            }
        }
        value.append(i)
    }

    public static func setFromProtobufBuffer(buffer: UnsafeBufferPointer<UInt8>, value: inout [BaseType], unknown: inout Data) throws {
        var decoder = ProtobufDecoder(protobufPointer: buffer)
        while let t = try decoder.decodeFixed32() {
            value.append(t)
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

    public static func setFromProtobufFixed8(fixed8: [UInt8], value: inout BaseType?) throws {
        assert(fixed8.count == 8)
        var i: UInt64 = 0
        withUnsafeMutablePointer(to: &i) { ip -> Void in
            ip.withMemoryRebound(to: UInt8.self, capacity: 8) { dest -> () in
                let src = UnsafeMutablePointer<UInt8>(mutating: fixed8)
                dest.initialize(from: src, count: 8)
            }
        }
        value = i
    }

    public static func setFromProtobufFixed8(fixed8: [UInt8], value: inout [BaseType]) throws {
        assert(fixed8.count == 8)
        var i: UInt64 = 0
        withUnsafeMutablePointer(to: &i) { ip -> Void in
            ip.withMemoryRebound(to: UInt8.self, capacity: 8) { dest -> () in
                let src = UnsafeMutablePointer<UInt8>(mutating: fixed8)
                dest.initialize(from: src, count: 8)
            }
        }
        value.append(i)
    }

    public static func setFromProtobufBuffer(buffer: UnsafeBufferPointer<UInt8>, value: inout [BaseType], unknown: inout Data) throws {
        var decoder = ProtobufDecoder(protobufPointer: buffer)
        while let t = try decoder.decodeFixed64() {
            value.append(t)
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

    public static func setFromProtobufFixed4(fixed4: [UInt8], value: inout BaseType?) throws {
        assert(fixed4.count == 4)
        var i: Int32 = 0
        withUnsafeMutablePointer(to: &i) { ip -> Void in
            ip.withMemoryRebound(to: UInt8.self, capacity: 4) { dest -> () in
                let src = UnsafeMutablePointer<UInt8>(mutating: fixed4)
                dest.initialize(from: src, count: 4)
            }
        }
        value = i
    }

    public static func setFromProtobufFixed4(fixed4: [UInt8], value: inout [BaseType]) throws {
        assert(fixed4.count == 4)
        var i: Int32 = 0
        withUnsafeMutablePointer(to: &i) { ip -> Void in
            ip.withMemoryRebound(to: UInt8.self, capacity: 4) { dest -> () in
                let src = UnsafeMutablePointer<UInt8>(mutating: fixed4)
                dest.initialize(from: src, count: 4)
            }
        }
        value.append(i)
    }

    public static func setFromProtobufBuffer(buffer: UnsafeBufferPointer<UInt8>, value: inout [BaseType], unknown: inout Data) throws {
        var decoder = ProtobufDecoder(protobufPointer: buffer)
        while let t = try decoder.decodeSFixed32() {
            value.append(t)
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

    public static func setFromProtobufFixed8(fixed8: [UInt8], value: inout BaseType?) throws {
        assert(fixed8.count == 8)
        var i: Int64 = 0
        withUnsafeMutablePointer(to: &i) { ip -> Void in
            ip.withMemoryRebound(to: UInt8.self, capacity: 8) { dest -> () in
                let src = UnsafeMutablePointer<UInt8>(mutating: fixed8)
                dest.initialize(from: src, count: 8)
            }
        }
        value = i
    }

    public static func setFromProtobufFixed8(fixed8: [UInt8], value: inout [BaseType]) throws {
        assert(fixed8.count == 8)
        var i: Int64 = 0
        withUnsafeMutablePointer(to: &i) { ip -> Void in
            ip.withMemoryRebound(to: UInt8.self, capacity: 8) { dest -> () in
                let src = UnsafeMutablePointer<UInt8>(mutating: fixed8)
                dest.initialize(from: src, count: 8)
            }
        }
        value.append(i)
    }

    public static func setFromProtobufBuffer(buffer: UnsafeBufferPointer<UInt8>, value: inout [BaseType], unknown: inout Data) throws {
        var decoder = ProtobufDecoder(protobufPointer: buffer)
        while let t = try decoder.decodeSFixed64() {
            value.append(t)
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

    public static func setFromProtobufVarint(varint: UInt64, value: inout BaseType?) throws -> Bool {
        value = (varint != 0)
        return true
    }

    public static func setFromProtobufVarint(varint: UInt64, value: inout [BaseType]) throws -> Bool {
        value.append(varint != 0)
        return true
    }

    public static func setFromProtobufBuffer(buffer: UnsafeBufferPointer<UInt8>, value: inout [BaseType], unknown: inout Data) throws {
        var decoder = ProtobufDecoder(protobufPointer: buffer)
        while let t = try decoder.decodeBool() {
            value.append(t)
        }
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

extension ProtobufString: ProtobufMapValueType {
    public static var protobufWireFormat: WireFormat { return .lengthDelimited }
    public static func serializeProtobufValue(encoder: inout ProtobufEncoder, value: String) {
        encoder.putStringValue(value: value)
    }

    public static func setFromProtobufBuffer(buffer: UnsafeBufferPointer<UInt8>, value: inout String?) throws {
        if let s = bufferToString(buffer: buffer) {
            value = s
        } else {
            throw DecodingError.invalidUTF8
        }
    }

    public static func setFromProtobufBuffer(buffer: UnsafeBufferPointer<UInt8>, value: inout [String], unknown: inout Data) throws {
        if let s = bufferToString(buffer: buffer) {
            value.append(s)
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

    public static func setFromProtobufBuffer(buffer: UnsafeBufferPointer<UInt8>, value: inout Data?) throws {
        value = Data(bytes: [UInt8](buffer))
    }

    public static func setFromProtobufBuffer(buffer: UnsafeBufferPointer<UInt8>, value: inout [Data], unknown: inout Data) throws {
        value.append(Data(bytes: [UInt8](buffer)))
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

    public static func setFromProtobufBuffer(buffer: UnsafeBufferPointer<UInt8>, value: inout [Self], unknown: inout Data) throws {
        var decoder = ProtobufDecoder(protobufPointer: buffer)
        var extras = [Int32]()
        while let t = try decoder.decodeInt32() {
            if let e = Self(rawValue:Int(t)) {
                value.append(e)
            } else {
                extras.append(t)
            }
        }
        if !extras.isEmpty {
            var dataSize = 0
            for v in extras {
                dataSize += Varint.encodedSize(of: Int64(v))
            }
            var data = Data(count: dataSize)
            data.withUnsafeMutableBytes { (pointer: UnsafeMutablePointer<UInt8>) in
                var encoder = ProtobufEncoder(pointer: pointer)
                for v in extras {
                    encoder.putVarInt(value: Int64(v))
                }
            }
            unknown.append(data)
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
        _ = try ProtobufEncodingVisitor(message: self, pointer: pointer)
    }

    func serializedProtobufSize() throws -> Int {
        return try ProtobufEncodingSizeVisitor(message: self).serializedSize
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
                let bufferPointer = UnsafeBufferPointer<UInt8>(start: pointer, count: protobuf.count)
                try decodeIntoSelf(protobuf: bufferPointer, extensions: extensions)
            }
        }
    }

    init(protobufBuffer: UnsafeBufferPointer<UInt8>, extensions: ExtensionSet?) throws {
        self.init()
        try decodeIntoSelf(protobuf: protobufBuffer, extensions: extensions)
    }
}

/// Proto2 messages preserve unknown fields
public extension Proto2Message {
    public mutating func decodeIntoSelf(protobuf bufferPointer: UnsafeBufferPointer<UInt8>, extensions: ExtensionSet?) throws {
        var protobufDecoder = ProtobufDecoder(protobufPointer: bufferPointer, extensions: extensions)
        try protobufDecoder.decodeFullObject(message: &self)
        unknown.append(protobufData: protobufDecoder.unknownData)
    }
}

// Proto3 messages ignore unknown fields
public extension Proto3Message {
    public mutating func decodeIntoSelf(protobuf bufferPointer: UnsafeBufferPointer<UInt8>, extensions: ExtensionSet?) throws {
        var protobufDecoder = ProtobufDecoder(protobufPointer: bufferPointer, extensions: extensions)
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
