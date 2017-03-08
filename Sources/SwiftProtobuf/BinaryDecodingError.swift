// Sources/SwiftProtobuf/BinaryDecodingError.swift - Protobuf binary decoding errors
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

public enum BinaryDecodingError: Error {
    /// Extraneous data remained after decoding should have been complete
    case trailingGarbage
    /// The data stopped before we expected
    case truncated
    /// A string was not valid UTF8
    case invalidUTF8
    /// Protobuf data could not be parsed
    case malformedProtobuf
    /// The message or nested messages definitions have required fields, and the
    /// binary data did not include values for them. The `partial` support will
    /// allow this incomplete data to be decoded.
    case missingRequiredFields
}
