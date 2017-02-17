// Sources/SwiftProtobuf/TextFormatTypeAdditions.swift - Text format primitive types
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Extend the type definitions from ProtobufTypes.swift with details
/// of protobuf text format handling.
///
// -----------------------------------------------------------------------------

import Foundation

///
/// Float traits
///
public extension ProtobufFloat {
    public static func serializeTextValue(encoder: TextFormatEncoder, value: Float) {
        encoder.putDoubleValue(value: Double(value))
    }
}

///
/// Double traits
///
public extension ProtobufDouble {
    public static func serializeTextValue(encoder: TextFormatEncoder, value: Double) {
        encoder.putDoubleValue(value: value)
    }
}

///
/// Int32 traits
///
public extension ProtobufInt32 {
    public static func serializeTextValue(encoder: TextFormatEncoder, value: Int32) {
        encoder.putInt64(value: Int64(value))
    }
}

///
/// Int64 traits
///
public extension ProtobufInt64 {
    public static func serializeTextValue(encoder: TextFormatEncoder, value: Int64) {
        encoder.putInt64(value: value)
    }
}

///
/// UInt32 traits
///
public extension ProtobufUInt32 {
    public static func serializeTextValue(encoder: TextFormatEncoder, value: UInt32) {
        encoder.putUInt64(value: UInt64(value))
    }
}

///
/// UInt64 traits
///
public extension ProtobufUInt64 {
    public static func serializeTextValue(encoder: TextFormatEncoder, value: UInt64) {
        encoder.putUInt64(value: value)
    }
}

///
/// SInt32 traits
///
public extension ProtobufSInt32 {
    public static func serializeTextValue(encoder: TextFormatEncoder, value: Int32) {
        encoder.putInt64(value: Int64(value))
    }
}

///
/// SInt64 traits
///
public extension ProtobufSInt64 {
    public static func serializeTextValue(encoder: TextFormatEncoder, value: Int64) {
        encoder.putInt64(value: value)
    }
}

///
/// Fixed32 traits
///
public extension ProtobufFixed32 {
    public static func serializeTextValue(encoder: TextFormatEncoder, value: UInt32) {
        encoder.putUInt64(value: UInt64(value))
    }
}

///
/// Fixed64 traits
///
public extension ProtobufFixed64 {
    public static func serializeTextValue(encoder: TextFormatEncoder, value: UInt64) {
        encoder.putUInt64(value: value)
    }
}

///
/// SFixed32 traits
///
public extension ProtobufSFixed32 {
    public static func serializeTextValue(encoder: TextFormatEncoder, value: Int32) {
        encoder.putInt64(value: Int64(value))
    }
}

///
/// SFixed64 traits
///
public extension ProtobufSFixed64 {
    public static func serializeTextValue(encoder: TextFormatEncoder, value: Int64) {
        encoder.putInt64(value: value)
    }
}

///
/// Bool traits
///
public extension ProtobufBool {
    public static func serializeTextValue(encoder: TextFormatEncoder, value: Bool) {
        encoder.putBoolValue(value: value)
    }
}

///
/// String traits
///
public extension ProtobufString {
    public static func serializeTextValue(encoder: TextFormatEncoder, value: String) {
        encoder.putStringValue(value: value)
    }
}

///
/// Bytes traits
///
public extension ProtobufBytes {
    public static func serializeTextValue(encoder: TextFormatEncoder, value: Data) {
        encoder.putBytesValue(value: value)
    }
}

///
/// Messages
///
public extension Message {
    public func textFormatString() throws -> String {
        let visitor = TextFormatEncodingVisitor(message: self)
        try traverse(visitor: visitor)
        return visitor.result
    }

    public init(textFormatString: String, extensions: ExtensionSet? = nil) throws {
        self.init()
        var textDecoder = try TextFormatDecoder(messageType: Self.self,
                                                text: textFormatString,
                                                extensions: extensions)
        try decodeTextFormat(from: &textDecoder)
        if !textDecoder.complete {
            throw TextFormatDecodingError.trailingGarbage
        }
    }

    public mutating func decodeTextFormat(from decoder: inout TextFormatDecoder) throws {
        try decodeMessage(decoder: &decoder)
    }
}
