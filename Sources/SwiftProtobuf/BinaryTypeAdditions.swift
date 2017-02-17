// Sources/SwiftProtobuf/BinaryTypeAdditions.swift - Per-type binary coding
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

import Foundation

// TODO: Examine how other proto2 implementations treat wire type mismatches
//
// I think I've heard that C++ treats a mismatched wire type as an unknown
// field, and Go treats a mismatched wire type as a decode error.  Personally,
// I prefer the latter.

///
/// Float traits
///
extension ProtobufFloat {
    public static var protobufWireFormat: WireFormat { return .fixed32 }
    public static func serializeProtobufValue(encoder: inout BinaryEncoder, value: Float) {
        encoder.putFloatValue(value: value)
    }

    public static func encodedSizeWithoutTag(of value: Float) -> Int {
        return MemoryLayout<Float>.size
    }
}


///
/// Double traits
///
extension ProtobufDouble {
    public static var protobufWireFormat: WireFormat { return .fixed64 }
    public static func serializeProtobufValue(encoder: inout BinaryEncoder, value: Double) {
        encoder.putDoubleValue(value: value)
    }

    public static func encodedSizeWithoutTag(of value: Double) -> Int {
        return MemoryLayout<Double>.size
    }
}

///
/// Int32 traits
///
extension ProtobufInt32 {
    public static var protobufWireFormat: WireFormat { return .varint }

    public static func serializeProtobufValue(encoder: inout BinaryEncoder, value: Int32) {
        encoder.putVarInt(value: Int64(value))
    }

    public static func encodedSizeWithoutTag(of value: Int32) -> Int {
        return Varint.encodedSize(of: value)
    }
}

///
/// Int64 traits
///
extension ProtobufInt64 {
    public static var protobufWireFormat: WireFormat { return .varint }

    public static func serializeProtobufValue(encoder: inout BinaryEncoder, value: Int64) {
        encoder.putVarInt(value: value)
    }

    public static func encodedSizeWithoutTag(of value: Int64) -> Int {
        return Varint.encodedSize(of: value)
    }
}

///
/// UInt32 traits
///
extension ProtobufUInt32 {
    public static var protobufWireFormat: WireFormat { return .varint }

    public static func serializeProtobufValue(encoder: inout BinaryEncoder, value: UInt32) {
        encoder.putVarInt(value: UInt64(value))
    }

    public static func encodedSizeWithoutTag(of value: UInt32) -> Int {
        return Varint.encodedSize(of: value)
    }
}

///
/// UInt64 traits
///
extension ProtobufUInt64 {
    public static var protobufWireFormat: WireFormat { return .varint }

    public static func serializeProtobufValue(encoder: inout BinaryEncoder, value: UInt64) {
        encoder.putVarInt(value: value)
    }

    public static func encodedSizeWithoutTag(of value: UInt64) -> Int {
        return Varint.encodedSize(of: value)
    }
}

///
/// SInt32 traits
///
extension ProtobufSInt32 {
    public static var protobufWireFormat: WireFormat { return .varint }

    public static func serializeProtobufValue(encoder: inout BinaryEncoder, value: Int32) {
        encoder.putZigZagVarInt(value: Int64(value))
    }

    public static func encodedSizeWithoutTag(of value: Int32) -> Int {
        return Varint.encodedSize(of: ZigZag.encoded(value))
    }
}

///
/// SInt64 traits
///
extension ProtobufSInt64 {
    public static var protobufWireFormat: WireFormat { return .varint }

    public static func serializeProtobufValue(encoder: inout BinaryEncoder, value: Int64) {
        encoder.putZigZagVarInt(value: value)
    }

    public static func encodedSizeWithoutTag(of value: Int64) -> Int {
        return Varint.encodedSize(of: ZigZag.encoded(value))
    }
}

///
/// Fixed32 traits
///
extension ProtobufFixed32 {
    public static var protobufWireFormat: WireFormat { return .fixed32 }
    public static func serializeProtobufValue(encoder: inout BinaryEncoder, value: UInt32) {
        encoder.putFixedUInt32(value: value)
    }

    public static func encodedSizeWithoutTag(of value: UInt32) -> Int {
        return MemoryLayout<UInt32>.size
    }
}

///
/// Fixed64 traits
///
extension ProtobufFixed64 {
    public static var protobufWireFormat: WireFormat { return .fixed64 }
    public static func serializeProtobufValue(encoder: inout BinaryEncoder, value: UInt64) {
        encoder.putFixedUInt64(value: value.littleEndian)
    }

    public static func encodedSizeWithoutTag(of value: UInt64) -> Int {
        return MemoryLayout<UInt64>.size
    }
}

///
/// SFixed32 traits
///
extension ProtobufSFixed32 {
    public static var protobufWireFormat: WireFormat { return .fixed32 }
    public static func serializeProtobufValue(encoder: inout BinaryEncoder, value: Int32) {
        encoder.putFixedUInt32(value: UInt32(bitPattern: value))
    }

    public static func encodedSizeWithoutTag(of value: Int32) -> Int {
        return MemoryLayout<Int32>.size
    }
}

///
/// SFixed64 traits
///
extension ProtobufSFixed64 {
    public static var protobufWireFormat: WireFormat { return .fixed64 }
    public static func serializeProtobufValue(encoder: inout BinaryEncoder, value: Int64) {
        encoder.putFixedUInt64(value: UInt64(bitPattern: value.littleEndian))
    }

    public static func encodedSizeWithoutTag(of value: Int64) -> Int {
        return MemoryLayout<Int64>.size
    }
}

///
/// Bool traits
///
extension ProtobufBool {
    public static var protobufWireFormat: WireFormat { return .varint }

    public static func serializeProtobufValue(encoder: inout BinaryEncoder, value: Bool) {
        encoder.putBoolValue(value: value)
    }

    public static func encodedSizeWithoutTag(of value: Bool) -> Int {
        return 1
    }
}

///
/// String traits
///

extension ProtobufString {
    public static var protobufWireFormat: WireFormat { return .lengthDelimited }
    public static func serializeProtobufValue(encoder: inout BinaryEncoder, value: String) {
        encoder.putStringValue(value: value)
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
extension ProtobufBytes {
    public static var protobufWireFormat: WireFormat { return .lengthDelimited }

    public static func serializeProtobufValue(encoder: inout BinaryEncoder, value: Data) {
        encoder.putBytesValue(value: value)
    }

    public static func encodedSizeWithoutTag(of value: Data) -> Int {
        let count = value.count
        return Varint.encodedSize(of: Int64(count)) + count
    }
}

///
/// Messages
///
public extension Message {
    func serializedData() throws -> Data {
        let requiredSize = try serializedDataSize()
        var data = Data(count: requiredSize)
        try data.withUnsafeMutableBytes { (pointer: UnsafeMutablePointer<UInt8>) in
            try serializeBinary(into: pointer)
        }
        return data
    }

    private func serializeBinary(into pointer: UnsafeMutablePointer<UInt8>) throws {
        let visitor = BinaryEncodingVisitor(forWritingInto: pointer)
        try traverse(visitor: visitor)
    }

    internal func serializedDataSize() throws -> Int {
        let visitor = BinaryEncodingSizeVisitor()
        try traverse(visitor: visitor)
        return visitor.serializedSize
    }

    init(serializedData data: Data, extensions: ExtensionSet? = nil) throws {
        self.init()
        if !data.isEmpty {
            try data.withUnsafeBytes { (pointer: UnsafePointer<UInt8>) in
                try decodeBinary(from: pointer,
                                 count: data.count,
                                 extensions: extensions)
            }
        }
    }
}

/// Proto2 messages preserve unknown fields
public extension Proto2Message {
    public mutating func decodeBinary(from bytes: UnsafePointer<UInt8>, count: Int, extensions: ExtensionSet?) throws {
        var decoder = BinaryDecoder(forReadingFrom: bytes, count: count, extensions: extensions)
        try decodeMessage(decoder: &decoder)
        guard decoder.complete else {
            throw BinaryDecodingError.trailingGarbage
        }
        if let unknownData = decoder.unknownData {
            unknownFields.append(protobufData: unknownData)
        }
    }
}

// Proto3 messages ignore unknown fields
public extension Proto3Message {
    public mutating func decodeBinary(from bytes: UnsafePointer<UInt8>, count: Int, extensions: ExtensionSet?) throws {
        var decoder = BinaryDecoder(forReadingFrom: bytes, count: count, extensions: extensions)
        try decodeMessage(decoder: &decoder)
        guard decoder.complete else {
            throw BinaryDecodingError.trailingGarbage
        }
    }
}
