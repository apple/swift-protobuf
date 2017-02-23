// Sources/SwiftProtobuf/UnknownStorage.swift - Handling unknown fields
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Proto2 binary coding requires storing and recoding of unknown fields.
/// This simple support class handles that requirement.  A property of this type
/// is compiled into every proto2 message.
///
// -----------------------------------------------------------------------------

import Foundation

public struct UnknownStorage: Equatable {
  internal var data = Data()

  public static func ==(lhs: UnknownStorage, rhs: UnknownStorage) -> Bool {
    return lhs.data == rhs.data
  }

  public init() {}

  public init(data: Data) {
      self.data = data
  }

  public mutating func append(protobufData: Data) {
    data.append(protobufData)
  }

  public func traverse<V: Visitor>(visitor: inout V) throws {
    try visitor.visitUnknown(bytes: data)
  }
}
