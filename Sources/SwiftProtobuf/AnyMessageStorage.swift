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
        let encodedTypeName = typeName(fromURL: _typeURL)
        if let messageType = Google_Protobuf_Any.lookupMessageType(forMessageName: encodedTypeName) {
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
      protobuf = try message.serializedData(partial: true)
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

  func decodeTextFormat(typeURL url: String, decoder: inout TextFormatDecoder) throws {
    // Decoding the verbose form requires knowing the type:
    _valueData = nil
    _typeURL = url
    let messageTypeName = typeName(fromURL: url)
    let terminator = try decoder.scanner.skipObjectStart()
    // Is it a well-known type? Or a user-registered type?
    if messageTypeName == "google.protobuf.Any" {
      var subDecoder = try TextFormatDecoder(messageType: Google_Protobuf_Any.self, scanner: decoder.scanner, terminator: terminator)
      var any = Google_Protobuf_Any()
      try any.decodeTextFormat(decoder: &subDecoder)
      decoder.scanner = subDecoder.scanner
      if let _ = try decoder.nextFieldNumber() {
        // Verbose any can never have additional keys
        throw TextFormatDecodingError.malformedText
      }
      _message = any
      return
    } else if let messageType = Google_Protobuf_Any.lookupMessageType(forMessageName: messageTypeName) {
      var subDecoder = try TextFormatDecoder(messageType: messageType, scanner: decoder.scanner, terminator: terminator)
      _message = messageType.init()
      try _message!.decodeMessage(decoder: &subDecoder)
      decoder.scanner = subDecoder.scanner
      if let _ = try decoder.nextFieldNumber() {
        // Verbose any can never have additional keys
        throw TextFormatDecodingError.malformedText
      }
      return
    }
    // TODO: If we don't know the type, we should consider deferring the
    // decode as we do for JSON and Protobuf binary.
    throw TextFormatDecodingError.malformedText
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
      let encodedTypeName = typeName(fromURL: _typeURL)
      if Google_Protobuf_Any.lookupMessageType(forMessageName: encodedTypeName) == nil {
        // Isn't registered, we can't transform it for binary.
        throw BinaryEncodingError.anyTranscodeFailure
      }
    }
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

  func isEqualTo(other: AnyMessageStorage) -> Bool {
    if (_typeURL != other._typeURL) {
      return false
    }

    // If we have both data's, compare those.
    // The best option is to decode and compare the messages; this
    // insulates us from variations in serialization details.  For
    // example, one Any might hold protobuf binary bytes from one
    // language implementation and the other from another language
    // implementation.  But of course this only works if we
    // actually know the message type.
    //if let myMessage = _message {
    //    if let otherMessage = other._message {
    //        ... compare them directly
    //    } else {
    //        ... try to decode other and compare
    //    }
    //} else if let otherMessage = other._message {
    //    ... try to decode ourselves and compare
    //} else {
    //    ... try to decode both and compare
    //}
    // If we don't know the message type, we have few options:
    // If we were both deserialized from proto, compare the binary value:
    // If we were both deserialized from JSON, compare content of the JSON?
    if let myValue = _valueData, let otherValue = other._valueData, myValue == otherValue {
      return true
    }

    return false
  }
}

fileprivate func serializeAnyJSON(for message: Message, typeURL: String) throws -> String {
  var visitor = try JSONEncodingVisitor(message: message)
  visitor.encoder.startObject()
  visitor.encoder.startField(name: "@type")
  visitor.encoder.putStringValue(value: typeURL)
  try message.traverse(visitor: &visitor)
  visitor.encoder.endObject()
  return visitor.stringResult
}

fileprivate func serializeAnyJSON(wktValueJSON value: String, typeURL: String) throws -> String {
  var jsonEncoder = JSONEncoder()
  jsonEncoder.startObject()
  jsonEncoder.startField(name: "@type")
  jsonEncoder.putStringValue(value: typeURL)
  jsonEncoder.startField(name: "value")
  jsonEncoder.append(text: value)
  jsonEncoder.endObject()
  return jsonEncoder.stringResult
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
      let url: String
      if !_typeURL.isEmpty {
        url = _typeURL
      } else {
        url = buildTypeURL(forMessage: message, typePrefix: defaultTypePrefix)
      }
      if let m = message as? _CustomJSONCodable {
        // Serialize a Well-known type to JSON:
        let value = try m.encodedJSONString()
        return try serializeAnyJSON(wktValueJSON: value, typeURL: url)
      } else {
        // Serialize a regular message to JSON:
        return try serializeAnyJSON(for: message, typeURL: url)
      }
    } else if !_typeURL.isEmpty {
      if let valueData = _valueData {
        // We have protobuf binary data and want to build JSON,
        // transcode by decoding the binary data to a message object
        // and then recode back into JSON:

        // If it's a well-known type, we can always do this:
        let messageTypeName = typeName(fromURL: _typeURL)
        if let messageType = Google_Protobuf_Any.wellKnownType(forMessageName: messageTypeName) {
          let m = try messageType.init(serializedData: valueData)
          let value = try m.jsonString()
          return try serializeAnyJSON(wktValueJSON: value, typeURL: _typeURL)
        }
        // Otherwise, it may be a registered type:
        if let messageType = Google_Protobuf_Any.lookupMessageType(forMessageName: messageTypeName) {
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
