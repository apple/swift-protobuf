// Sources/SwiftProtobuf/CustomJSONCodable.swift - Custom JSON support for WKTs
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Custom protocol for the WKTs to support their custom JSON encodings.
///
// -----------------------------------------------------------------------------

import Foundation

/// Allows WKTs to provide their custom JSON encodings.
internal protocol _CustomJSONCodable {
    func encodedJSONString() throws -> String
    mutating func decodeJSON(from: inout JSONDecoder) throws
}
