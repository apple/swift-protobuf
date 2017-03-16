// Sources/SwiftProtobuf/Google_Protobuf_Any+Extensions.swift - Well-known Any type
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Extends the Google_Protobuf_Any and Message structs with various
/// custom behaviors.
///
// -----------------------------------------------------------------------------

import Foundation


fileprivate let defaultTypePrefix: String = "type.googleapis.com"

internal func typeName(fromMessage message: Message) -> String {
  let messageType = type(of: message)
  return messageType.protoMessageName
}

fileprivate func buildTypeURL(forMessage message: Message, typePrefix: String) -> String {
  var url = typePrefix
  if typePrefix.isEmpty || typePrefix.characters.last != "/" {
    url += "/"
  }
  return url + typeName(fromMessage: message)
}


public extension Message {
  /// Initialize this message from the provided `google.protobuf.Any`
  /// well-known type.
  ///
  /// This corresponds to the `unpack` method in the Google C++ API.
  ///
  /// If the Any object was decoded from Protobuf Binary or JSON
  /// format, then the enclosed field data was stored and is not
  /// fully decoded until you unpack the Any object into a message.
  /// As such, this method will typically need to perform a full
  /// deserialization of the enclosed data and can fail for any
  /// reason that deserialization can fail.
  ///
  /// See `Google_Protobuf_Any.unpackTo()` for more discussion.
  ///
  /// - Parameter unpackingAny: the message to decode.
  /// - Throws: an instance of `AnyUnpackError`, `JSONDecodingError`, or
  ///   `BinaryDecodingError` on failure.
  public init(unpackingAny: Google_Protobuf_Any) throws {
    self.init()
    try unpackingAny.unpackTo(target: &self)
  }
}


public extension Google_Protobuf_Any {

  /// Initialize an Any object from the provided message.
  ///
  /// This corresponds to the `pack` operation in the C++ API.
  ///
  /// Unlike the C++ implementation, the message is not immediately
  /// serialized; it is merely stored until the Any object itself
  /// needs to be serialized.  This design avoids unnecessary
  /// decoding/recoding when writing JSON format.
  ///
  public init(message: Message, typePrefix: String = defaultTypePrefix) {
    self.init()
    _storage._message = message
    typeURL = buildTypeURL(forMessage:message, typePrefix: typePrefix)
  }


  /// Decode an Any object from Protobuf Text Format.
  public init(textFormatString: String, extensions: ExtensionSet? = nil) throws {
    self.init()
    var textDecoder = try TextFormatDecoder(messageType: Google_Protobuf_Any.self,
                                            text: textFormatString,
                                            extensions: extensions)
    try decodeTextFormat(decoder: &textDecoder)
    if !textDecoder.complete {
      throw TextFormatDecodingError.trailingGarbage
    }
  }

  ///
  /// Update the provided object from the data in the Any container.
  /// This is essentially just a deferred deserialization; the Any
  /// may hold protobuf bytes or JSON fields depending on how the Any
  /// was itself deserialized.
  ///
  public func unpackTo<M: Message>(target: inout M) throws {
    try _storage.unpackTo(target: &target)
  }

  public var hashValue: Int {
    var hash: Int = 0
    hash = (hash &* 16777619) ^ typeURL.hashValue
    if let v = _storage._valueData {
      hash = (hash &* 16777619) ^ v.hashValue
    }
    if let m = _storage._message {
      hash = (hash &* 16777619) ^ m.hashValue
    }
    return hash
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

extension Google_Protobuf_Any: _CustomJSONCodable {

  // _value is computed be on demand conversions.
  public var _value: Data? {
    get {
      if let value = _storage._valueData {
        return value
      } else if let message = _storage._message {
        do {
          return try message.serializedData()
        } catch {
          return nil
        }
      } else if _storage._contentJSON != nil && !_storage._typeURL.isEmpty {
        // Transcode JSON-to-protobuf by decoding/recoding:
        // Well-known types are always available:
        let encodedTypeName = typeName(fromURL: _storage._typeURL)
        if let messageType = Google_Protobuf_Any.lookupMessageType(forMessageName: encodedTypeName) {
          do {
            let m = try messageType.init(unpackingAny: self)
            return try m.serializedData()
          } catch {
            return nil
          }
        }
        // TODO: Google spec requires a lot more work in the general case:
        // let encodedType = ... fetch google.protobuf.Type based on typeURL ...
        // let type = Google_Protobuf_Type(protobuf: encodedType)
        // return ProtobufDynamic(type: type, any: self)?.serializeProtobuf()

        // See the comments in serializeJSON() above for more discussion of what would be needed to fully implement this.
        return nil
      } else {
        return nil
      }
    }
    set {
      _ = _uniqueStorage()
      _storage._valueData = newValue
      _storage._message = nil
      _storage._contentJSON = nil
    }
  }

  // Custom text format decoding support for Any objects.
  // (Note: This is not a part of any protocol; it's invoked
  // directly from TextFormatDecoder whenever it sees an attempt
  // to decode an Any object)
  internal mutating func decodeTextFormat(decoder: inout TextFormatDecoder) throws {
    // First, check if this uses the "verbose" Any encoding.
    // If it does, and we have the type available, we can
    // eagerly decode the contained Message object.
    if let url = try decoder.scanner.nextOptionalAnyURL() {
      // Decoding the verbose form requires knowing the type:
      typeURL = url
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
        _uniqueStorage()._message = any
        return
      } else if let messageType = Google_Protobuf_Any.lookupMessageType(forMessageName: messageTypeName) {
        var subDecoder = try TextFormatDecoder(messageType: messageType, scanner: decoder.scanner, terminator: terminator)
        _uniqueStorage()._message = messageType.init()
        try _storage._message!.decodeMessage(decoder: &subDecoder)
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

    // This is not using the specialized encoding, so we can use the
    // standard path to decode the binary value.
    try decodeMessage(decoder: &decoder)
  }

  // Override the traversal-based JSON encoding
  // This builds an Any JSON representation from one of:
  //  * The message we were initialized with,
  //  * The JSON fields we last deserialized, or
  //  * The protobuf field we were deserialized from.
  // The last case requires locating the type, deserializing
  // into an object, then reserializing back to JSON.
  internal func encodedJSONString() throws -> String {
    if let message = _storage._message {
      // We were initialized from a message object.

      // We should have been initialized with a typeURL, but
      // ensure it wasn't cleared.
      let url: String
      if !typeURL.isEmpty {
        url = typeURL
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
    } else if !typeURL.isEmpty {
      if _storage._valueData != nil {
        // We have protobuf binary data and want to build JSON,
        // transcode by decoding the binary data to a message object
        // and then recode back into JSON:

        // If it's a well-known type, we can always do this:
        let messageTypeName = typeName(fromURL: typeURL)
        if let messageType = Google_Protobuf_Any.wellKnownType(forMessageName: messageTypeName) {
          let m = try messageType.init(unpackingAny: self)
          let value = try m.jsonString()
          return try serializeAnyJSON(wktValueJSON: value, typeURL: typeURL)
        }
        // Otherwise, it may be a registered type:
        if let messageType = Google_Protobuf_Any.lookupMessageType(forMessageName: messageTypeName) {
          let m = try messageType.init(unpackingAny: self)
          return try serializeAnyJSON(for: m, typeURL: typeURL)
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
        jsonEncoder.putStringValue(value: typeURL)
        if let contentJSON = _storage._contentJSON, !contentJSON.isEmpty {
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

  internal mutating func decodeJSON(from decoder: inout JSONDecoder) throws {
    try _uniqueStorage().decodeJSON(from: &decoder)
  }

}
