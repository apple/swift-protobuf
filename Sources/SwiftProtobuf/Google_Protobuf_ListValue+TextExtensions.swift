// Sources/SwiftProtobuf/Google_Protobuf_ListValue+TextExtensions.swift - ListValue extensions
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// ListValue is a well-known message type that can be used to parse or encode
/// arbitrary JSON arrays without a predefined schema.
///
// -----------------------------------------------------------------------------

extension Google_Protobuf_ListValue: _CustomJSONCodable {
  internal func encodedJSONString(options: JSONEncodingOptions) throws -> String {
    var jsonEncoder = JSONEncoder()
    jsonEncoder.append(text: "[")
    var separator: StaticString = ""
    for v in values {
      jsonEncoder.append(staticText: separator)
      try v.serializeJSONValue(to: &jsonEncoder, options: options)
      separator = ","
    }
    jsonEncoder.append(text: "]")
    return jsonEncoder.stringResult
  }

  internal mutating func decodeJSON(from decoder: inout JSONDecoder) throws {
    if decoder.scanner.skipOptionalNull() {
      return
    }
    try decoder.scanner.skipRequiredArrayStart()
    // Since we override the JSON decoding, we can't rely
    // on the default recursion depth tracking.
    try decoder.scanner.incrementRecursionDepth()
    if decoder.scanner.skipOptionalArrayEnd() {
      decoder.scanner.decrementRecursionDepth()
      return
    }
    while true {
      var v = Google_Protobuf_Value()
      try v.decodeJSON(from: &decoder)
      values.append(v)
      if decoder.scanner.skipOptionalArrayEnd() {
        decoder.scanner.decrementRecursionDepth()
        return
      }
      try decoder.scanner.skipRequiredComma()
    }
  }
}
