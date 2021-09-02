// Sources/SwiftProtobuf/Google_Protobuf_Wrappers+TextExtensions.swift - Well-known wrapper type extensions
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Extensions to the well-known types in wrapper.proto that customize the JSON
/// format of those messages and provide convenience initializers from literals.
///
// -----------------------------------------------------------------------------

import Foundation

extension ProtobufWrapper {
  mutating func decodeJSON(from decoder: inout JSONDecoder) throws {
    var v: WrappedType.BaseType?
    try WrappedType.decodeSingular(value: &v, from: &decoder)
    value = v ?? WrappedType.proto3DefaultValue
  }
}

extension Google_Protobuf_DoubleValue: _CustomJSONCodable {
  func encodedJSONString(options: JSONEncodingOptions) throws -> String {
    if value.isFinite {
      // Swift 4.2 and later guarantees that this is accurate
      // enough to parse back to the exact value on the other end.
      return value.description
    } else {
      // Protobuf-specific handling of NaN and infinities
      var encoder = JSONEncoder()
      encoder.putDoubleValue(value: value)
      return encoder.stringResult
    }
  }
}

extension Google_Protobuf_FloatValue: _CustomJSONCodable {
  func encodedJSONString(options: JSONEncodingOptions) throws -> String {
    if value.isFinite {
      // Swift 4.2 and later guarantees that this is accurate
      // enough to parse back to the exact value on the other end.
      return value.description
    } else {
      // Protobuf-specific handling of NaN and infinities
      var encoder = JSONEncoder()
      encoder.putFloatValue(value: value)
      return encoder.stringResult
    }
  }
}

extension Google_Protobuf_Int64Value: _CustomJSONCodable {
  func encodedJSONString(options: JSONEncodingOptions) throws -> String {
    return "\"" + String(value) + "\""
  }
}

extension Google_Protobuf_UInt64Value: _CustomJSONCodable {
  func encodedJSONString(options: JSONEncodingOptions) throws -> String {
    return "\"" + String(value) + "\""
  }
}

extension Google_Protobuf_Int32Value: _CustomJSONCodable {
  func encodedJSONString(options: JSONEncodingOptions) throws -> String {
    return String(value)
  }
}

extension Google_Protobuf_UInt32Value: _CustomJSONCodable {
  func encodedJSONString(options: JSONEncodingOptions) throws -> String {
    return String(value)
  }
}

extension Google_Protobuf_BoolValue: _CustomJSONCodable {
  func encodedJSONString(options: JSONEncodingOptions) throws -> String {
    return value ? "true" : "false"
  }
}

extension Google_Protobuf_StringValue: _CustomJSONCodable {
  func encodedJSONString(options: JSONEncodingOptions) throws -> String {
    var encoder = JSONEncoder()
    encoder.putStringValue(value: value)
    return encoder.stringResult
  }
}

extension Google_Protobuf_BytesValue: _CustomJSONCodable {
  func encodedJSONString(options: JSONEncodingOptions) throws -> String {
    var encoder = JSONEncoder()
    encoder.putBytesValue(value: value)
    return encoder.stringResult
  }
}
