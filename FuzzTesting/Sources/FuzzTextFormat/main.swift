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
