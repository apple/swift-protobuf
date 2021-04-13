import Foundation

import FuzzCommon

@_cdecl("LLVMFuzzerTestOneInput")
public func FuzzJSON(_ start: UnsafeRawPointer, _ count: Int) -> CInt {
  let bytes = UnsafeRawBufferPointer(start: start, count: count)
  do {
    let _ = try Fuzz_Testing_Message(
      jsonUTF8Data: Data(bytes),
      extensions: Fuzz_Testing_FuzzTesting_Extensions)
  } catch {
    // Error parsing are to be expected since not all input will be well formed.
  }

  return 0
}
