import Foundation

import FuzzCommon

@_cdecl("LLVMFuzzerTestOneInput")
public func FuzzTextFormat(_ start: UnsafeRawPointer, _ count: Int) -> CInt {
  let bytes = UnsafeRawBufferPointer(start: start, count: count)
  guard let str = String(data: Data(bytes), encoding: .utf8) else { return 0 }
  var msg: SwiftProtoTesting_Fuzz_Message?
  do {
    msg = try SwiftProtoTesting_Fuzz_Message(
      textFormatString: str,
      extensions: SwiftProtoTesting_Fuzz_FuzzTesting_Extensions)
  } catch {
    // Error parsing are to be expected since not all input will be well formed.
  }
  // Test serialization for completeness.
  let _ = msg?.textFormatString()

  return 0
}
