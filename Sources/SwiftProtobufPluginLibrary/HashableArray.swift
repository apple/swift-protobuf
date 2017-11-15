// Sources/SwiftProtobufPluginLibrary/HashableArray.swift - Wrapper array to support hashing
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------

/// Helper type to use an array as a dictionary key.
struct HashableArray<T: Hashable>: Hashable {
  let array: [T]
  let hashValue: Int

  init(_ array: [T]) {
    self.array = array
    var hash = Int(bitPattern: 2166136261)
    for i in array {
      hash = (hash &* Int(16777619)) ^ i.hashValue
    }
    hashValue = hash
  }
  static func ==(lhs: HashableArray<T>, rhs: HashableArray<T>) -> Bool {
    return lhs.hashValue == rhs.hashValue && lhs.array == rhs.array
  }
}
