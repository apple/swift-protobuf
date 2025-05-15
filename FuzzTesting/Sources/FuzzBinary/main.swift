// Copyright (c) 2014 - 2024 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------

import FuzzCommon
import SwiftProtobuf

@_cdecl("LLVMFuzzerTestOneInput")
public func FuzzBinary(_ start: UnsafeRawPointer, _ count: Int) -> CInt {
    guard let (options, bytes) = BinaryDecodingOptions.extractOptions(start, count) else {
        return 1
    }
    var msg: SwiftProtoTesting_Fuzz_Message?
    do {
        msg = try SwiftProtoTesting_Fuzz_Message(
            serializedBytes: Array(bytes),
            extensions: SwiftProtoTesting_Fuzz_FuzzTesting_Extensions,
            options: options
        )
    } catch {
        // Error parsing are to be expected since not all input will be well formed.
    }
    // Test serialization for completeness.
    // If a message was parsed, it should not fail to serialize, so assert as such.
    let _: [UInt8]? = try! msg?.serializedBytes()

    return 0
}
