// Sources/SwiftProtobufPluginLibrary/Google_Protobuf_Edition+Extensions.swift - Google_Protobuf_Edition extensions
//
// Copyright (c) 2014 - 2024 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Extensions to `Google_Protobuf_Edition` provide some simple helpers.
///
// -----------------------------------------------------------------------------

import Foundation

import SwiftProtobuf

/// The spec for editions calls out them being ordered and comparable.
/// https://github.com/protocolbuffers/protobuf/blob/main/docs/design/editions/edition-naming.md
extension Google_Protobuf_Edition: Comparable {
  public static func < (lhs: Google_Protobuf_Edition, rhs: Google_Protobuf_Edition) -> Bool {
    return lhs.rawValue < rhs.rawValue
  }
}
