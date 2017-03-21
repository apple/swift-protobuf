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

private let i_2166136261 = Int(bitPattern: 2166136261)
private let i_16777619 = Int(16777619)

fileprivate func serializeAnyJSON(for message: Message, typeURL: String) throws -> String {
  var visitor = try JSONEncodingVisitor(message: message)
  visitor.startObject()
  visitor.encodeField(name: "@type", stringValue: typeURL)
  if let m = message as? _CustomJSONCodable {
    let value = try m.encodedJSONString()
    visitor.encodeField(name: "value", jsonText: value)
  } else {
    try message.traverse(visitor: &visitor)
  }
  visitor.endObject()
  return visitor.stringResult
}

internal class AnyMessageStorage {
  var _typeURL: String = ""

  // Computed to do on demand work.
  var _value: Data {
    get {
      if let value = _valueData {
        return value
      }

      if let message = _message {
        do {
          return try message.serializedData(partial: true)
        } catch {
          return Data()
        }
      }

      if let contentJSON = _contentJSON, !_typeURL.isEmpty {
        if let messageType = Google_Protobuf_Any.messageType(forTypeURL: _typeURL) {
          do {
            // Hack, make an any to use init(unpackingAny:)
            var any = Google_Protobuf_Any()
            any.typeURL = _typeURL
            any._storage._contentJSON = contentJSON
            any._storage._valueData = nil
            let m = try messageType.init(unpackingAny: any)
            return try m.serializedData(partial: true)
          } catch {
            return Data()
          }
        }
      }

      return Data()
    }
    set {
      _valueData = newValue
      _message = nil
      _contentJSON = nil
    }
  }

  // The possible internal states for _value.
  //
  // Note: It might make sense to shift to using an enum for internal
  // state instead to better enforce this; but that also means we could
  // never got a model were we might also be able to cache the things
  // we have.
  var _valueData: Data? = Data()
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

  func isA<M: Message>(_ type: M.Type) -> Bool {
    if _typeURL.isEmpty {
      return false
    }
    let encodedType = typeName(fromURL: _typeURL)
    return encodedType == M.protoMessageName
  }

  // This is only ever called with the expactation that target will be fully
  // replaced during the unpacking and never as a merge.
  func unpackTo<M: Message>(target: inout M, extensions: ExtensionMap?) throws {
    guard isA(M.self) else {
      throw AnyUnpackError.typeMismatch
    }

    // Cached message is correct type, copy it over.
    if let message = _message as? M {
      target = message
      return
    }

    // If internal state is a message (of different type), get serializedData
    // from it. If state was binary, use that serialized data.
    var protobuf: Data?
    if let message = _message {
      protobuf = try message.serializedData(partial: true)
    } else if let value = _valueData {
      protobuf = value
    }
    if let protobuf = protobuf {
      target = try M(serializedData: protobuf, extensions: extensions)
      return
    }

    // If internal state is JSON, do the decode now.
    if let contentJSON = _contentJSON {
      if let _ = target as? _CustomJSONCodable {
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
          target = try M(jsonString: value)
        }
      } else {
        let asciiOpenCurlyBracket = UInt8(ascii: "{")
        let asciiCloseCurlyBracket = UInt8(ascii: "}")
        var contentJSONAsObject = Data(bytes: [asciiOpenCurlyBracket])
        contentJSONAsObject.append(contentJSON)
        contentJSONAsObject.append(asciiCloseCurlyBracket)
        target = try M(jsonUTF8Data: contentJSONAsObject)
      }
      return
    }

    // Didn't have any of the three internal states?
    throw AnyUnpackError.malformedAnyField
  }


  // Called before the message is traversed to do any error preflights.
  // Since traverse() will use _value, this is our chance to throw
  // when _value can't.
  func preTraverse() throws {
    // 1. if _valueData is set, it will be used, nothing to check.

    // 2. _message could be checked when set, but that isn't always
    //    clean in the places it gets decoded from some other form, so
    //    validate it here.
    if let msg = _message, !msg.isInitialized {
      throw BinaryEncodingError.missingRequiredFields
    }

    // 3. _contentJSON requires a good URL and our ability to look up
    //    the message type to transcode.
    if _contentJSON != nil {
      if _typeURL.isEmpty {
        throw BinaryEncodingError.anyTranscodeFailure
      }
      if Google_Protobuf_Any.messageType(forTypeURL: _typeURL) == nil {
        // Isn't registered, we can't transform it for binary.
        throw BinaryEncodingError.anyTranscodeFailure
      }
    }
  }
}

/// Custom handling for Text format.
extension AnyMessageStorage {
  func decodeTextFormat(typeURL url: String, decoder: inout TextFormatDecoder) throws {
    // Decoding the verbose form requires knowing the type.
    _typeURL = url
    guard let messageType = Google_Protobuf_Any.messageType(forTypeURL: url) else {
      // The type wasn't registered, can't parse it.
      throw TextFormatDecodingError.malformedText
    }
    _valueData = nil
    let terminator = try decoder.scanner.skipObjectStart()
    var subDecoder = try TextFormatDecoder(messageType: messageType, scanner: decoder.scanner, terminator: terminator)
    if messageType == Google_Protobuf_Any.self {
      var any = Google_Protobuf_Any()
      try any.decodeTextFormat(decoder: &subDecoder)
      _message = any
    } else {
      _message = messageType.init()
      try _message!.decodeMessage(decoder: &subDecoder)
    }
    decoder.scanner = subDecoder.scanner
    if try decoder.nextFieldNumber() != nil {
      // Verbose any can never have additional keys.
      throw TextFormatDecodingError.malformedText
    }
  }

  private func emitVerboseTextForm(visitor: inout TextFormatEncodingVisitor, message: Message, typeURL: String) {
    let url: String
    if typeURL.isEmpty {
      url = buildTypeURL(forMessage: message, typePrefix: defaultTypePrefix)
    } else {
      url = _typeURL
    }
    visitor.visitAnyVerbose(value: message, typeURL: url)
  }

  // Specialized traverse for writing out a Text form of the Any.
  // This prefers the more-legible "verbose" format if it can
  // use it, otherwise will fall back to simpler forms.
  internal func textTraverse(visitor: inout TextFormatEncodingVisitor) {
    if let msg = _message {
      emitVerboseTextForm(visitor: &visitor, message: msg, typeURL: _typeURL)
    } else if let valueData = _valueData {
      if let messageType = Google_Protobuf_Any.messageType(forTypeURL: _typeURL) {
        // If we can decode it, we can write the readable verbose form:
        do {
          let m = try messageType.init(serializedData: valueData, partial: true)
          emitVerboseTextForm(visitor: &visitor, message: m, typeURL: _typeURL)
          return
        } catch {
          // Fall through to just print the type and raw binary data
        }
      }
      if !_typeURL.isEmpty {
        try! visitor.visitSingularStringField(value: _typeURL, fieldNumber: 1)
      }
      if !valueData.isEmpty {
        try! visitor.visitSingularBytesField(value: valueData, fieldNumber: 2)
      }
    } else if let contentJSON = _contentJSON {
      // Build a readable form of the JSON:
      let asciiOpenCurlyBracket = UInt8(ascii: "{")
      let asciiCloseCurlyBracket = UInt8(ascii: "}")
      var contentJSONAsObject = Data(bytes: [asciiOpenCurlyBracket])
      contentJSONAsObject.append(contentJSON)
      contentJSONAsObject.append(asciiCloseCurlyBracket)
      // If we can decode it, we can write the readable verbose form:
      if let messageType = Google_Protobuf_Any.messageType(forTypeURL: _typeURL) {
        var any = Google_Protobuf_Any()
        any.typeURL = _typeURL
        any._storage._contentJSON = contentJSON
        any._storage._valueData = nil
        do {
          let m = try messageType.init(unpackingAny: any)
          emitVerboseTextForm(visitor: &visitor, message: m, typeURL: _typeURL)
          return
        } catch {
          // Fall through to just print the raw JSON data
        }
      }
      if !_typeURL.isEmpty {
        try! visitor.visitSingularStringField(value: _typeURL, fieldNumber: 1)
      }
      visitor.visitAnyJSONDataField(value: contentJSONAsObject)
    } else if !_typeURL.isEmpty {
      try! visitor.visitSingularStringField(value: _typeURL, fieldNumber: 1)
    }
  }
}

extension AnyMessageStorage {
  var hashValue: Int {
    var hash: Int = i_2166136261
    if !_typeURL.isEmpty {
      hash = (hash &* i_16777619) ^ _typeURL.hashValue
    }
    // Can't use _valueData for a few reasons:
    // 1. Since decode is done on demand, two objects could be equal
    //    but created differently (one from JSON, one for Message, etc.),
    //    and the hashes have to be equal even if we don't have data yet.
    // 2. map<> serialization order is undefined. At the time of writing
    //    the Swift, Objective-C, and Go runtimes all tend to have random
    //    orders, so the messages could be identical, but in binary form
    //    they could differ.
    return hash
  }

  func isEqualTo(other: AnyMessageStorage) -> Bool {
    if (_typeURL != other._typeURL) {
      return false
    }

    // Since the library does lazy Any decode, equality is a very hard problem.
    // It things exactly match, that's pretty easy, otherwise, one ends up having
    // to error on saying they aren't equal.
    //
    // The best option would be to have Message forms and compare those, as that
    // removes issues like map<> serialization order, some other protocol buffer
    // implementation details/bugs around serialized form order, etc.; but that
    // would also greatly slow down equality tests.
    //
    // Do our best to compare what is present have...

    // If both have messages, check if they are the same.
    if let myMsg = _message, let otherMsg = other._message, type(of: myMsg) == type(of: otherMsg) {
      // Since the messages are known to be same type, we can claim both equal and
      // not equal based on the equality comparison.
      return myMsg.isEqualTo(message: otherMsg)
    }

    // If both have serialized data, and they exactly match; the messages are equal.
    // Because there could be map in the message, the fact that the data isn't the
    // same doesn't always mean the messages aren't equal.
    if let myValue = _valueData, let otherValue = other._valueData, myValue == otherValue {
      return true
    }

    // If both have contentJSON, and they exactly match; the messages are equal.
    // Because there could be map in the message (or the JSON could just be in a different
    // order), the fact that the JSON isn't the same doesn't always mean the messages
    // aren't equal.
    if let myJSON = _contentJSON, let otherJSON = other._contentJSON, myJSON == otherJSON {
      return true
    }

    // Out of options; to do more compares, the states conversions would have to be
    // done to do comparisions.  Give up and say they aren't equal.
    return false
  }
}

// _CustomJSONCodable support for Google_Protobuf_Any
extension AnyMessageStorage {
  // Override the traversal-based JSON encoding
  // This builds an Any JSON representation from one of:
  //  * The message we were initialized with,
  //  * The JSON fields we last deserialized, or
  //  * The protobuf field we were deserialized from.
  // The last case requires locating the type, deserializing
  // into an object, then reserializing back to JSON.
  func encodedJSONString() throws -> String {
    if let message = _message {
      // We were initialized from a message object.

      // We should have been initialized with a typeURL, but
      // ensure it wasn't cleared.
      let url = !_typeURL.isEmpty ? _typeURL : buildTypeURL(forMessage: message, typePrefix: defaultTypePrefix)
      return try serializeAnyJSON(for: message, typeURL: url)
    } else if !_typeURL.isEmpty {
      if let valueData = _valueData {
        // We have protobuf binary data and want to build JSON,
        // transcode by decoding the binary data to a message object
        // and then recode back into JSON:
        if let messageType = Google_Protobuf_Any.messageType(forTypeURL: _typeURL) {
          let m = try messageType.init(serializedData: valueData)
          return try serializeAnyJSON(for: m, typeURL: _typeURL)
        }

        // If we don't have the type available, we can't decode the
        // binary value, so we're stuck.  (The Google spec does not
        // provide a way to just package the binary value for someone
        // else to decode later.)

        // TODO: Google spec requires more work in the general case:
        // let encodedType = ... fetch google.protobuf.Type based on typeURL ...
        // let type = Google_Protobuf_Type(protobuf: encodedType)
        // return ProtobufDynamicMessage(type: type, any: self)?.serializeAnyJSON()

        // ProtobufDynamicMessage() is non-trivial to write
        // but desirable for other reasons.  It's a class that
        // can be instantiated with any protobuf type or
        // descriptor and provides access to protos of the
        // corresponding type.
        throw JSONEncodingError.anyTranscodeFailure
      } else {
        // We don't have binary data, so include the typeURL and
        // any other contentJSON this Any was created from.
        var jsonEncoder = JSONEncoder()
        jsonEncoder.startObject()
        jsonEncoder.startField(name: "@type")
        jsonEncoder.putStringValue(value: _typeURL)
        if let contentJSON = _contentJSON, !contentJSON.isEmpty {
          jsonEncoder.append(staticText: ",")
          jsonEncoder.append(utf8Data: contentJSON)
        }
        jsonEncoder.endObject()
        return jsonEncoder.stringResult
      }
    } else {
      return "{}"
    }
  }

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
    _valueData = Data()
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
        _valueData = nil
        return
      }
      try decoder.scanner.skipRequiredComma()
    }
  }
}
