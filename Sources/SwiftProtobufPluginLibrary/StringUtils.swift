// Sources/SwiftProtobufPluginLibrary/StringUtils.swift - String processing utilities
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------

import Foundation

@inlinable
func trimWhitespace(_ s: String) -> String {
  return s.trimmingCharacters(in: .whitespacesAndNewlines)
}

@inlinable
func trimWhitespace(_ s: String.SubSequence) -> String {
  return s.trimmingCharacters(in: .whitespacesAndNewlines)
}
