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
  let bytes = UnsafeRawBufferPointer(start: start, count: count)
  let asyncBytes = asyncByteStream(bytes: bytes)
  let decoding = asyncBytes.binaryProtobufDelimitedMessages(
    of: SwiftProtoTesting_Fuzz_Message.self,
    extensions: SwiftProtoTesting_Fuzz_FuzzTesting_Extensions)

  let semaphore = DispatchSemaphore(value: 0)
  Task {
    do {
      for try await msg in decoding {
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
