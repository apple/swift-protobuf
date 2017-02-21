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
        var visitor = BinaryEncodingVisitor(forWritingInto: pointer)
        try traverse(visitor: &visitor)
    }

    internal func serializedDataSize() throws -> Int {
        var visitor = BinaryEncodingSizeVisitor()
        try traverse(visitor: &visitor)
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
