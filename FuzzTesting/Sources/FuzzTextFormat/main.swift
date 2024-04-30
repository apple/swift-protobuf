import Foundation

import FuzzCommon

import SwiftProtobuf

@_cdecl("LLVMFuzzerTestOneInput")
public func FuzzTextFormat(_ start: UnsafeRawPointer, _ count: Int) -> CInt {
  guard let (options, bytes) = TextFormatDecodingOptions.extractOptions(start, count) else {
    return 1
  }
  guard let str = String(data: Data(bytes), encoding: .utf8) else { return 0 }
  var msg: SwiftProtoTesting_Fuzz_Message?
  do {
    msg = try SwiftProtoTesting_Fuzz_Message(
      textFormatString: str,
      options: options,
      extensions: SwiftProtoTesting_Fuzz_FuzzTesting_Extensions)
  } catch {
    // Error parsing are to be expected since not all input will be well formed.
  }
  // Test serialization for completeness.
  let _ = msg?.textFormatString()

  return 0
}
