// Sources/PluginLibrary/Array+Extensions.swift - Additions to Arrays
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------

import Foundation

extension Array {
  /// Like map, but calls the transform with the index and value.
  func enumeratedMap<T>(_ transform: (Int, Element) throws -> T) rethrows -> [T] {
    var i: Int = -1
    return try map {
      i += 1
      return try transform(i, $0)
    }
  }
}
