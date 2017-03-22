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

//
// Messages
//
public extension Message {
    /// Serializes the message to the Protocol Buffer text serialization format.
    ///
    /// - Throws: an instance of `TextFormatEncodingError` if encoding fails.
    public func textFormatString() -> String {
        var visitor = TextFormatEncodingVisitor(message: self)
        if let any = self as? Google_Protobuf_Any {
            any._storage.textTraverse(visitor: &visitor)
        } else {
            try! traverse(visitor: &visitor)
        }
        return visitor.result
    }

    /// Initializes the message by decoding the Protocol Buffer text
    /// serialization format for this message.
    ///
    /// - Parameters:
    ///   - textFormatString: the text serialization string to decode.
    ///   - extensions: an `ExtensionSet` to look up and decode any extensions
    ///     in this message or messages nested within this message's fields.
    /// - Throws: an instance of `TextFormatDecodingError` on failure.
    public init(textFormatString: String, extensions: ExtensionSet? = nil) throws {
        self.init()
        if !textFormatString.isEmpty {
            if let data = textFormatString.data(using: String.Encoding.utf8) {
                try data.withUnsafeBytes { (bytes: UnsafePointer<UInt8>) in
                    var decoder = try TextFormatDecoder(messageType: Self.self,
                                                    utf8Pointer: bytes,
                                                    count: data.count,
                                                    extensions: extensions)
                    try decodeMessage(decoder: &decoder)
                    if !decoder.complete {
                        throw TextFormatDecodingError.trailingGarbage
                    }
                }
            }
        }
    }
}
