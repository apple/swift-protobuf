// Sources/SwiftProtobuf/ProtobufDecodingError.swift - Protobuf binary decoding errors
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Protobuf binary format decoding errors
///
// -----------------------------------------------------------------------------

public enum ProtobufDecodingError: Error {
    /// Extraneous data remained after decoding should have been complete
    case trailingGarbage
    /// The data stopped before we expected
    case truncated
    /// A string was not valid UTF8
    case invalidUTF8
    /// Protobuf data could not be parsed
    case malformedProtobuf
    /// The data being parsed does not match the type specified in the proto file
    case schemaMismatch
}
