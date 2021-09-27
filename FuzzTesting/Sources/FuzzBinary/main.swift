import Foundation

import FuzzCommon

@_cdecl("LLVMFuzzerTestOneInput")
public func FuzzBinary(_ start: UnsafeRawPointer, _ count: Int) -> CInt {
  let bytes = UnsafeRawBufferPointer(start: start, count: count)
  var msg: Fuzz_Testing_Message?
  do {
    msg = try Fuzz_Testing_Message(
      serializedData: Data(bytes),
      extensions: Fuzz_Testing_FuzzTesting_Extensions)
  } catch {
    // Error parsing are to be expected since not all input will be well formed.
  }
  // Test serialization for completeness.
  // If a message was parsed, it should not fail to serialize, so assert as such.
  let _ = try! msg?.serializedData()

  return 0
}
