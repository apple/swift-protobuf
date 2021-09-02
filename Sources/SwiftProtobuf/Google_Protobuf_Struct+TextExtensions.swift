// Sources/SwiftProtobuf/Google_Protobuf_Struct+TextExtensions.swift - Struct extensions
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Struct is a well-known message type that can be used to parse or encode
/// arbitrary JSON objects without a predefined schema.
///
// -----------------------------------------------------------------------------

extension Google_Protobuf_Struct: _CustomJSONCodable {
  internal func encodedJSONString(options: JSONEncodingOptions) throws -> String {
    var jsonEncoder = JSONEncoder()
    jsonEncoder.startObject()
    var mapVisitor = JSONMapEncodingVisitor(encoder: jsonEncoder, options: options)
    for (k,v) in fields {
      try mapVisitor.visitSingularStringField(value: k, fieldNumber: 1)
      try mapVisitor.visitSingularMessageField(value: v, fieldNumber: 2)
    }
    mapVisitor.encoder.endObject()
    return mapVisitor.encoder.stringResult
  }

  internal mutating func decodeJSON(from decoder: inout JSONDecoder) throws {
    try decoder.scanner.skipRequiredObjectStart()
    if decoder.scanner.skipOptionalObjectEnd() {
      return
    }
    while true {
      let key = try decoder.scanner.nextQuotedString()
      try decoder.scanner.skipRequiredColon()
      var value = Google_Protobuf_Value()
      try value.decodeJSON(from: &decoder)
      fields[key] = value
      if decoder.scanner.skipOptionalObjectEnd() {
        return
      }
      try decoder.scanner.skipRequiredComma()
    }
  }
}
