// Sources/SwiftProtobuf/Google_Protobuf_Value+TextExtensions.swift - Value extensions
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Value is a well-known message type that can be used to parse or encode
/// arbitrary JSON without a predefined schema.
///
// -----------------------------------------------------------------------------

extension Google_Protobuf_Value: _CustomJSONCodable {
  internal func encodedJSONString(options: JSONEncodingOptions) throws -> String {
    var jsonEncoder = JSONEncoder()
    try serializeJSONValue(to: &jsonEncoder, options: options)
    return jsonEncoder.stringResult
  }

  internal mutating func decodeJSON(from decoder: inout JSONDecoder) throws {
    let c = try decoder.scanner.peekOneCharacter()
    switch c {
    case "n":
      if !decoder.scanner.skipOptionalNull() {
        throw JSONDecodingError.failure
      }
      kind = .nullValue(.nullValue)
    case "[":
      var l = Google_Protobuf_ListValue()
      try l.decodeJSON(from: &decoder)
      kind = .listValue(l)
    case "{":
      var s = Google_Protobuf_Struct()
      try s.decodeJSON(from: &decoder)
      kind = .structValue(s)
    case "t", "f":
      let b = try decoder.scanner.nextBool()
      kind = .boolValue(b)
    case "\"":
      let s = try decoder.scanner.nextQuotedString()
      kind = .stringValue(s)
    default:
      let d = try decoder.scanner.nextDouble()
      kind = .numberValue(d)
    }
  }

  internal static func decodedFromJSONNull() -> Google_Protobuf_Value? {
    return Google_Protobuf_Value(nil)
  }
}

extension Google_Protobuf_Value {
  /// Writes out the JSON representation of the value to the given encoder.
  internal func serializeJSONValue(
    to encoder: inout JSONEncoder,
    options: JSONEncodingOptions
  ) throws {
    switch kind {
    case .nullValue?: encoder.putNullValue()
    case .numberValue(let v)?: encoder.putDoubleValue(value: v)
    case .stringValue(let v)?: encoder.putStringValue(value: v)
    case .boolValue(let v)?: encoder.putBoolValue(value: v)
    case .structValue(let v)?: encoder.append(text: try v.jsonString(options: options))
    case .listValue(let v)?: encoder.append(text: try v.jsonString(options: options))
    case nil: throw JSONEncodingError.missingValue
    }
  }
}
