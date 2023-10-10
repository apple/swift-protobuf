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

func partition(string: String, atFirstOccurrenceOf substring: String) -> (String, String) {
  guard let index = string.range(of: substring)?.lowerBound else {
    return (string, "")
  }
  return (String(string[..<index]),
          String(string[string.index(after: index)...]))
}

func trimWhitespace(_ s: String) -> String {
  return s.trimmingCharacters(in: .whitespacesAndNewlines)
}
