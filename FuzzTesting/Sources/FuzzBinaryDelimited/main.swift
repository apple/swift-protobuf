import Foundation

import FuzzCommon

import SwiftProtobuf

@_cdecl("LLVMFuzzerTestOneInput")
public func FuzzDelimited(_ start: UnsafeRawPointer, _ count: Int) -> CInt {
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
