// Sources/SwiftProtobuf/JSONDecodingError.swift - JSON decoding errors
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// JSON decoding errors
///
// -----------------------------------------------------------------------------

public enum JSONDecodingError: Error {
    /// A JSON Duration could not be parsed
    case malformedDuration
    /// A JSON Timestamp could not be parsed
    case malformedTimestamp
    /// A FieldMask could not be parsed
    case malformedFieldMask
}
