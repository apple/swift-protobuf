import Foundation

import FuzzCommon

import SwiftProtobuf

fileprivate func asyncByteStream(bytes: [UInt8]) -> AsyncStream<UInt8> {
  AsyncStream(UInt8.self) { continuation in
    for byte in bytes {
      continuation.yield(byte)
    }
    continuation.finish()
  }
}

@_cdecl("LLVMFuzzerTestOneInput")
public func FuzzAsyncMessageSequence(_ start: UnsafeRawPointer, _ count: Int) -> CInt {
  let bytes = UnsafeRawBufferPointer(start: start, count: count)
  let asyncBytes = asyncByteStream(data: Data(bytes))
  let decoded = asyncBytes.binaryProtobufDelimitedMessages(
      of: SwiftProtoTesting_Fuzz_Message.self,
      extensions: SwiftProtoTesting_Fuzz_FuzzTesting_Extensions)

  var msgs: [SwiftProtoTesting_Fuzz_Message]
  do {
    let msgs = try await decoded.reduce(into: [SwiftProtoTesting_Fuzz_Message]()) { array, msg in
      msgs.append(msg)
    }
  } catch {
    // Error parsing are to be expected since not all input will be well formed.
  }
  // Test serialization for completeness.
  // There is no output version of this, so just loop and write them out.
  for msg in msgs {
    let _: [UInt8]? = try! msg.serializedBytes()
  }

  return 0
}
