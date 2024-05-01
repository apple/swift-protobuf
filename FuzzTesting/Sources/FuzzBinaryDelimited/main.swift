// Copyright (c) 2014 - 2024 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------

import Foundation

import FuzzCommon

import SwiftProtobuf

@_cdecl("LLVMFuzzerTestOneInput")
public func FuzzDelimited(_ start: UnsafeRawPointer, _ count: Int) -> CInt {
  // No decoding options here, a leading zero is actually valid (zero length message),
  // so we rely on the other Binary fuzz tester to test options, and just let this
  // one focus on issue around framing of the messages on the stream.
  let bytes = UnsafeRawBufferPointer(start: start, count: count)
  let istream = InputStream(data: Data(bytes))
  istream.open()
  while true {
    let msg: SwiftProtoTesting_Fuzz_Message?
    do {
      msg = try BinaryDelimited.parse(
        messageType: SwiftProtoTesting_Fuzz_Message.self,
        from: istream,
        extensions: SwiftProtoTesting_Fuzz_FuzzTesting_Extensions)
    } catch {
      // Error parsing are to be expected since not all input will be well formed.
      break
    }
    // Test serialization for completeness.
    // If a message was parsed, it should not fail to serialize, so assert as such.
    if let msg = msg {
      // Could use one stream for all messages, but since fuzz tests have
      // memory limits, attempt to avoid hitting that limit with a new stream
      // for each output attempt.
      let ostream = OutputStream.toMemory()
      ostream.open()
      try! BinaryDelimited.serialize(message: msg, to: ostream)
    }
  }

  return 0
}
