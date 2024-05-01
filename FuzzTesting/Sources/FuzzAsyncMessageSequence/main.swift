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

fileprivate func asyncByteStream(bytes: UnsafeRawBufferPointer) -> AsyncStream<UInt8> {
  AsyncStream(UInt8.self) { continuation in
    for i in 0..<bytes.count {
      continuation.yield(bytes.loadUnaligned(fromByteOffset: i, as: UInt8.self))
    }
    continuation.finish()
  }
}

@_cdecl("LLVMFuzzerTestOneInput")
public func FuzzAsyncMessageSequence(_ start: UnsafeRawPointer, _ count: Int) -> CInt {
  // No decoding options here, a leading zero is actually valid (zero length message),
  // so we rely on the other Binary fuzz tester to test options, and just let this
  // one focus on issue around framing of the messages on the stream.
  let bytes = UnsafeRawBufferPointer(start: start, count: count)
  let asyncBytes = asyncByteStream(bytes: bytes)
  let decoding = asyncBytes.binaryProtobufDelimitedMessages(
    of: SwiftProtoTesting_Fuzz_Message.self,
    extensions: SwiftProtoTesting_Fuzz_FuzzTesting_Extensions)

  let semaphore = DispatchSemaphore(value: 0)
  Task {
    do {
      for try await _ in decoding {
        // TODO: Test serialization for completeness.
        // We could serialize individual messages like this:
        // let _: [UInt8] = try! msg.serializedBytes()
        // but we don't have a stream writer which is what
        // we really want to exercise here.

        // Also, serialization here more than doubles the total
        // run time, leading to timeouts for the fuzz tester. :(
      }
    } catch {
      // Error parsing are to be expected since not all input will be well formed.
    }
    semaphore.signal()
  }
  semaphore.wait()
  return 0
}
