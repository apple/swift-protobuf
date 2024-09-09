// Sources/SwiftProtobuf/Google_Protobuf_NullValue+Extensions.swift - NullValue extensions
//
// Copyright (c) 2014 - 2020 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// NullValue is a well-known message type that can be used to parse or encode
/// JSON Null values.
///
// -----------------------------------------------------------------------------

extension Google_Protobuf_NullValue: _CustomJSONCodable {
    internal func encodedJSONString(options: JSONEncodingOptions) throws -> String {
        "null"
    }
    internal mutating func decodeJSON(from decoder: inout JSONDecoder) throws {
        if decoder.scanner.skipOptionalNull() {
            return
        }
    }
    static func decodedFromJSONNull() -> Google_Protobuf_NullValue? {
        .nullValue
    }
}
