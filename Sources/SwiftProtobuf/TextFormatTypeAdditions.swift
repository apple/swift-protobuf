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
/// Messages
///
public extension Message {
    public func textFormatString() throws -> String {
        var visitor = TextFormatEncodingVisitor(message: self)
        try traverse(visitor: &visitor)
        return visitor.result
    }

    public init(textFormatString: String, extensions: ExtensionSet? = nil) throws {
        self.init()
        var textDecoder = try TextFormatDecoder(messageType: Self.self,
                                                text: textFormatString,
                                                extensions: extensions)
        try decodeMessage(decoder: &textDecoder)
        if !textDecoder.complete {
            throw TextFormatDecodingError.trailingGarbage
        }
    }
}
