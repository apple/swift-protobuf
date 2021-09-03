import Foundation

import FuzzCommon

@_cdecl("LLVMFuzzerTestOneInput")
public func FuzzTextFormat(_ start: UnsafeRawPointer, _ count: Int) -> CInt {
  let bytes = UnsafeRawBufferPointer(start: start, count: count)
  guard let str = String(data: Data(bytes), encoding: .utf8) else { return 0 }
  var msg: Fuzz_Testing_Message?
  do {
    msg = try Fuzz_Testing_Message(
      textFormatString: str,
      extensions: Fuzz_Testing_FuzzTesting_Extensions)
  } catch {
    // Error parsing are to be expected since not all input will be well formed.
  }
  // Test serialization for completeness.
  let _ = msg?.textFormatString()

  return 0
}
