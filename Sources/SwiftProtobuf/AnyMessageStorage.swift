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

  func unpackTo<M: Message>(target: inout M) throws {
    if _typeURL.isEmpty {
      throw AnyUnpackError.emptyAnyField
    }
    let encodedType = typeName(fromURL: _typeURL)
    if encodedType.isEmpty {
      throw AnyUnpackError.malformedTypeURL
    }
    let messageType = typeName(fromMessage: target)
    if encodedType != messageType {
      throw AnyUnpackError.typeMismatch
    }
    var protobuf: Data?
    if let message = _message as? M {
      target = message
      return
    }

    if let message = _message {
      protobuf = try message.serializedData()
    } else if let value = _valueData {
      protobuf = value
    }
    if let protobuf = protobuf {
      // Decode protobuf from the stored bytes
      if protobuf.count > 0 {
        try protobuf.withUnsafeBytes { (p: UnsafePointer<UInt8>) in
          try target._protobuf_mergeSerializedBytes(from: p, count: protobuf.count, extensions: nil)
        }
      }
      return
    } else if let contentJSON = _contentJSON {
      let targetType = typeName(fromMessage: target)
      if Google_Protobuf_Any.isWellKnownType(messageName: targetType) {
        try contentJSON.withUnsafeBytes { (bytes:UnsafePointer<UInt8>) in
          var scanner = JSONScanner(utf8Pointer: bytes,
                                    count: contentJSON.count)
          let key = try scanner.nextQuotedString()
          if key != "value" {
            // The only thing within a WKT should be "value".
            throw AnyUnpackError.malformedWellKnownTypeJSON
          }
          try scanner.skipRequiredColon()  // Can't fail
          let value = try scanner.skip()
          if !scanner.complete {
            // If that wasn't the end, then there was another key,
            // and WKTs should only have the one.
            throw AnyUnpackError.malformedWellKnownTypeJSON
          }
          // Note: This api is unpackTo(target:) so it really should be
          // a merge and not a replace (the non WKT case next is a merge).
          // The only WKTs where there would seem to be a difference are:
          //   Struct - It is a map, so it would merge into any existing
          //     enties.
          //   ValueList - Repeated, so values should append to the
          //       existing ones instead of instead of replace.
          //   FieldMask - Repeated, so values should append to the
          //       existing ones instead of instead of replace.
          //   Value - Interesting case, it is a oneof, so currently
          //       that would error if it was already set, so maybe
          //       replace is ok.
          target = try M(jsonString: value)
        }
      } else {
        let asciiOpenCurlyBracket = UInt8(ascii: "{")
        let asciiCloseCurlyBracket = UInt8(ascii: "}")
        var contentJSONAsObject = Data(bytes: [asciiOpenCurlyBracket])
        contentJSONAsObject.append(contentJSON)
        contentJSONAsObject.append(asciiCloseCurlyBracket)

        try contentJSONAsObject.withUnsafeBytes { (bytes:UnsafePointer<UInt8>) in
          var decoder = JSONDecoder(utf8Pointer: bytes,
                                    count: contentJSONAsObject.count)
          try decoder.decodeFullObject(message: &target)
          if !decoder.scanner.complete {
            throw JSONDecodingError.trailingGarbage
          }
        }
      }
      return
    }
    throw AnyUnpackError.malformedAnyField
  }

}

// Since things are decoded on demand, hashValue and Equality are a little
// messy.  Message could be equal, but do to how they are currected, we
// currently end up with different hashValue and equalty could come back
// false.
extension AnyMessageStorage {
  var hashValue: Int {
    var hash: Int = 0
    hash = (hash &* 16777619) ^ _typeURL.hashValue
    if let v = _valueData {
      hash = (hash &* 16777619) ^ v.hashValue
    }
    if let m = _message {
      hash = (hash &* 16777619) ^ m.hashValue
    }
    return hash
  }
}

// _CustomJSONCodable support for Google_Protobuf_Any
extension AnyMessageStorage {
  // TODO: If the type is well-known or has already been registered,
  // we should consider decoding eagerly.  Eager decoding would
  // catch certain errors earlier (good) but would probably be
  // a performance hit if the Any contents were never accessed (bad).
  // Of course, we can't always decode eagerly (we don't always have the
  // message type available), so the deferred logic here is still needed.
  func decodeJSON(from decoder: inout JSONDecoder) throws {
    try decoder.scanner.skipRequiredObjectStart()
    // Reset state
    _typeURL = ""
    _contentJSON = nil
    _message = nil
    _valueData = nil
    if decoder.scanner.skipOptionalObjectEnd() {
      return
    }

    var jsonEncoder = JSONEncoder()
    while true {
      let key = try decoder.scanner.nextQuotedString()
      try decoder.scanner.skipRequiredColon()
      if key == "@type" {
        _typeURL = try decoder.scanner.nextQuotedString()
      } else {
        jsonEncoder.startField(name: key)
        let keyValueJSON = try decoder.scanner.skip()
        jsonEncoder.append(text: keyValueJSON)
      }
      if decoder.scanner.skipOptionalObjectEnd() {
        _contentJSON = jsonEncoder.dataResult
        return
      }
      try decoder.scanner.skipRequiredComma()
    }
  }
}
