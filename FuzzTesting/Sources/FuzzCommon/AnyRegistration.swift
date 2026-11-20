// Copyright (c) 2014 - 2026 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------

import SwiftProtobuf

public enum FuzzAnyRegistry {
    private static let registered: Bool = {
        let messageOK = Google_Protobuf_Any.register(messageType: SwiftProtoTesting_Fuzz_Message.self)
        let messageSetOK = Google_Protobuf_Any.register(
            messageType: SwiftProtoTesting_Fuzz_AMessageSetMessage.self
        )
        let requiredOK = Google_Protobuf_Any.register(
            messageType: SwiftProtoTesting_Fuzz_MessageWithRequired.self
        )
        return messageOK && messageSetOK && requiredOK
    }()

    /// Registers the fuzz schema message types with `Google_Protobuf_Any` once per process.
    public static func registerTypes() {
        precondition(registered)
    }
}
