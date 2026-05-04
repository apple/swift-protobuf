// Sources/SwiftProtobuf/GeneratedMessage.swift - Protocol for generated messages
//
// Copyright (c) 2014 - 2026 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Protocol for generated messages.
///
// -----------------------------------------------------------------------------

/// Types that are generated messages conform to this protocol.
public protocol GeneratedMessage: Message {
    /// The message schema used by all messages of the conforming type.
    static var messageSchema: MessageSchema { get }
}

extension GeneratedMessage {
    /// All instances of a generated message return the type-wide schema.
    public var messageSchema: MessageSchema {
        return Self.messageSchema
    }
}
