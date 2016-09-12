// ProtobufRuntime/Sources/Protobuf/ProtobufRawMessage.swift - Raw message decoding
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
/// A "RawMessage" is a tool for parsing proto binary messages without
/// using a schema of any sort.  This is slow, inconvenient, and unsafe.
/// Despite these drawbacks, it is occasionally quite useful...
///
// -----------------------------------------------------------------------------

import Swift

// TODO: This is a tentative sketch; needs tests and plenty of more stuff filled in.

public struct ProtobufRawMessage {
    public private(set) var fieldWireType = [Int: Int]()
    public private(set) var fieldData = [Int: Any]()

    public init(protobuf: [UInt8]) throws {
        try protobuf.withUnsafeBufferPointer { (bp) throws in
            var protobufDecoder = ProtobufBinaryDecoder(protobufPointer: bp)
            while let tagType = try protobufDecoder.getTagType() {
                let protoFieldNumber = tagType / 8
                let wireType = tagType % 8
                fieldWireType[protoFieldNumber] = wireType
                switch wireType {
                case 0:
                    if let v = try protobufDecoder.decodeUInt64() {
                        fieldData[protoFieldNumber] = v
                    } else {
                        throw ProtobufDecodingError.malformedProtobuf
                    }
                case 1:
                    if let v = try protobufDecoder.decodeFixed64() {
                        fieldData[protoFieldNumber] = v
                    } else {
                        throw ProtobufDecodingError.malformedProtobuf
                    }
                case 2:
                    if let v = try protobufDecoder.decodeBytes() {
                        fieldData[protoFieldNumber] = v
                    } else {
                        throw ProtobufDecodingError.malformedProtobuf
                    }
                case 3:
                    // TODO: Find a useful way to deal with groups
                    try protobufDecoder.skip()
                case 5:
                    if let v = try protobufDecoder.decodeFixed32() {
                        fieldData[protoFieldNumber] = v
                    } else {
                        throw ProtobufDecodingError.malformedProtobuf
                    }
                default:
                    throw ProtobufDecodingError.malformedProtobuf
                }
            }
        }
    }

    // TODO: serializeProtobuf(), serializeProtobufBytes()

    /// Get the contents of this field as a UInt64
    /// Returns nil if the field doesn't exist or it's contents cannot be expressed as a UInt64
    public func getUInt64(protoFieldNumber: Int) -> UInt64? {
        return fieldData[protoFieldNumber] as? UInt64
    }

    public func getString(protoFieldNumber: Int) -> String? {
        if let bytes = fieldData[protoFieldNumber] as? [UInt8] {
            return bytes.withUnsafeBufferPointer {(buffer) -> String? in
                buffer.baseAddress?.withMemoryRebound(to: CChar.self, capacity: buffer.count) { (cp) -> String? in
                    // cp is not null-terminated!
                    var chars = [CChar](UnsafeBufferPointer<CChar>(start: cp, count: buffer.count))
                    chars.append(0)
                    return String(validatingUTF8: chars)
                }
            }
        } else {
            return nil
        }
    }

    // TODO: More getters...

    // TODO: Setters...
}
