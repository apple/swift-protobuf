// Sources/SwiftProtobuf/ExtensionFieldValueSet.swift - Extension support
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// A collection of extension field values on a particular object.
/// This is only used within messages to manage the values of extension fields;
/// it does not need to be very sophisticated.
///
// -----------------------------------------------------------------------------

public struct ExtensionFieldValueSet: Equatable {
  fileprivate var values = [Int : AnyExtensionField]()

  public static func ==(lhs: ExtensionFieldValueSet,
                        rhs: ExtensionFieldValueSet) -> Bool {
    guard lhs.values.count == rhs.values.count else {
      return false
    }
    for (index, l) in lhs.values {
      if let r = rhs.values[index] {
        if type(of: l) != type(of: r) {
          return false
        }
        if !l.isEqual(other: r) {
          return false
        }
      } else {
        return false
      }
    }
    return true
  }

  public init() {}

  public var hashValue: Int {
    var hash = 16777619
    for (fieldNumber, v) in values {
      // Note: This calculation cannot depend on the order of the items.
      hash = hash &+ fieldNumber &+ v.hashValue
    }
    return hash
  }

  public func traverse<V: Visitor>(visitor: inout V, start: Int, end: Int) throws {
    let validIndexes = values.keys.filter {$0 >= start && $0 < end}
    for i in validIndexes.sorted() {
      let value = values[i]!
      try value.traverse(visitor: &visitor)
    }
  }

  public subscript(index: Int) -> AnyExtensionField? {
    get { return values[index] }
    set { values[index] = newValue }
  }

  public var isInitialized: Bool {
    for (_, v) in values {
      if !v.isInitialized {
        return false
      }
    }
    return true
  }
}
