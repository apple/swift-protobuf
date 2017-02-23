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
    /// Serializes the message to the Protocol Buffer binary serialization format.
    ///
    /// - Parameters:
    ///   - partial: The binary serialization format requires all `required` fields
    ///     be present; when `partial` is `false`, `EncodingError.missingRequiredFields`
    ///     is throw if any were missing. When `partial` is `true`, then partial
    ///     messages are allowed, and `Message.isRequired` is not checked.
    /// - Throws: An instance of `EncodingError` on failure .
    func serializedData(partial: Bool = false) throws -> Data {
        if !partial && !isInitialized {
            throw BinaryEncodingError.missingRequiredFields
        }
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
        // Note: since this api is internal, it doesn't currently worry about
        // needing a partial argument to handle proto2 syntax required fields.
        // If this become public, it will need that added.
        var visitor = BinaryEncodingSizeVisitor()
        try traverse(visitor: &visitor)
        return visitor.serializedSize
    }

    /// Initializes the message by decoding the Protocol Buffer binary serialization
    /// format for this message.
    ///
    /// - Parameters:
    ///   - serializedData: The binary serialization data to decode.
    ///   - extensions: An `ExtensionSet` to look up and decode any extensions in this
    ///     message or messages nested within this message's fields.
    ///   - partial: By default, the binary serialization format requires all `required`
    ///     fields be present; when `partial` is `false`,
    ///     `BinaryDecodingError.missingRequiredFields` is thrown if any were missing.
    ///     When `partial` is `true`, then partial messages are allowed, and
    ///     `Message.isInitialized` is not checked.
    /// - Throws: An instance of `BinaryDecodingError` on failure.
    init(serializedData data: Data, extensions: ExtensionSet? = nil, partial: Bool = false) throws {
        self.init()
        try merge(serializedData: data, extensions: extensions, partial: partial)
    }

    /// Updates the message by decoding the Protocol Buffer binary serialization
    /// format data into this message.
    ///
    /// - Note: If this method throws, the message may still have been mutated by the
    ///   binary data that was decoded before the error.
    ///
    /// - Parameters:
    ///   - serializedData: The binary serialization data to decode.
    ///   - extensions: An `ExtensionSet` to look up and decode any extensions in this
    ///     message or messages nested within this message's fields.
    ///   - partial: By default, the binary serialization format requires all `required`
    ///     fields be present; when `partial` is `false`,
    ///     `BinaryDecodingError.missingRequiredFields` is thrown if any were missing.
    ///     When `partial` is `true`, then partial messages are allowed, and
    ///     `Message.isInitialized` is not checked.
    /// - Throws: An instance of `BinaryDecodingError` on failure.
    mutating func merge(serializedData data: Data, extensions: ExtensionSet? = nil, partial: Bool = false) throws {
        if !data.isEmpty {
            try data.withUnsafeBytes { (pointer: UnsafePointer<UInt8>) in
                try decodeBinary(from: pointer,
                                 count: data.count,
                                 extensions: extensions)
            }
        }
        if !partial && !isInitialized {
            throw BinaryDecodingError.missingRequiredFields
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
