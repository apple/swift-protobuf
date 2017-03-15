// Sources/SwiftProtobuf/AnyMessageStorage - Custom stroage for Any WKT
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Hand written storage class for Google_Protobuf_Any to support on demand
/// transforms between the formats.
///
// -----------------------------------------------------------------------------

import Foundation

internal func typeName(fromURL s: String) -> String {
    var typeStart = s.startIndex
    var i = typeStart
    while i < s.endIndex {
        let c = s[i]
        i = s.index(after: i)
        if c == "/" {
            typeStart = i
        }
    }

    return s[typeStart..<s.endIndex]
}

internal class AnyMessageStorage {
  var _typeURL: String = ""

  // Computed to do on demand work.
  var _value: Data {
    get { return _valueData ?? Data() }
    set {
      _valueData = newValue
      _message = nil
      _contentJSON = nil
    }
  }

  // The possible internal states for _value.
  var _valueData: Data?
  var _message: Message?
  var _contentJSON: Data?  // Any json parsed from with the @type removed.

  init() {}

  func copy() -> AnyMessageStorage {
    let clone = AnyMessageStorage()
    clone._typeURL = _typeURL
    clone._valueData = _valueData
    clone._message = _message
    clone._contentJSON = _contentJSON
    return clone
  }
}
