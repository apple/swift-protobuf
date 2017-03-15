// Sources/SwiftProtobuf/Google_Protobuf_Any.swift - Well-known Any type
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// This is pretty much completely hand-built.
///
/// Generating it from any.proto -- even just partially -- is
/// probably not feasible.
///
// -----------------------------------------------------------------------------

import Foundation

internal let defaultTypePrefix: String = "type.googleapis.com"

internal func buildTypeURL(forMessage message: Message, typePrefix: String) -> String {
  var url = typePrefix
  if typePrefix.isEmpty || typePrefix.characters.last != "/" {
    url += "/"
  }
  return url + typeName(fromMessage: message)
}

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

internal func typeName(fromMessage message: Message) -> String {
    let messageType = type(of: message)
    return messageType.protoMessageName
}

/// Traversal-based JSON encoding of a standard message type
/// This mimics the standard JSON message encoding logic, but adds
/// the additional `@type` field.
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

///   `Any` contains an arbitrary serialized message along with a URL
///   that describes the type of the serialized message.
///
///   JSON
///   ====
///   The JSON representation of an `Any` value uses the regular
///   representation of the deserialized, embedded message, with an
///   additional field `@type` which contains the type URL. Example:
///
///       package google.profile;
///       message Person {
///         string first_name = 1;
///         string last_name = 2;
///       }
///
///       {
///         "@type": "type.googleapis.com/google.profile.Person",
///         "firstName": <string>,
///         "lastName": <string>
///       }
///
///   If the embedded message type is well-known and has a custom JSON
///   representation, that representation will be embedded adding a field
///   `value` which holds the custom JSON in addition to the the `@type`
///   field. Example (for message [google.protobuf.Duration][google.protobuf.Duration]):
///
///       {
///         "@type": "type.googleapis.com/google.protobuf.Duration",
///         "value": "1.212s"
///       }
///
/// Swift implementation details
/// ============================
///
/// Internally, the Google_Protobuf_Any holds either a
/// message struct, a protobuf-serialized bytes value, or a collection
/// of JSON fields.
///
/// If you create a Google_Protobuf_Any(message:) then the object will
/// keep a copy of the provided message.  When the Any itself is later
/// serialized, the message will be inspected to correctly serialize
/// the Any to protobuf or JSON as appropriate.
///
/// If you deserialize a Google_Protobuf_Any() from protobuf, then it will
/// contain a protobuf-serialized form of the contained object.  This will
/// in turn be deserialized only when you use the unpackTo() method.
///
/// If you deserialize a Google_Protobuf_Any() from JSON, then it will
/// contain a set of partially-decoded JSON fields.  These will
/// be fully deserialized when you use the unpackTo() method.
///
/// Note that deserializing from protobuf and reserializing back to
/// protobuf (or JSON-to-JSON) is efficient and well-supported.
/// However, deserializing from protobuf and reserializing to JSON
/// (or vice versa) is much more complicated:
///   * Well-known types are automatically detected and handled as
///     if the Any field were deserialized to the in-memory form
///     and then serialized back out again.
///   * You can register your message types via Google_Protobuf_Any.register().
///     Such types will be automatically handled as above.
///   * Someday, there will be a mechanism for you to provide
///     Type descriptors (which might be fetched from a remote server
///     on-demand).
///
/// In particular, note that it is not possible to decode a google.protobuf.Any
/// field in a protobuf message and then recode to JSON (or vice versa)
/// without having the type information available.  This is a basic
/// limitation of Google's spec for google.protobuf.Any.
///
public struct Google_Protobuf_Any: Message, _MessageImplementationBase, _ProtoNameProviding, _CustomJSONCodable {
    public static let protoMessageName: String = "google.protobuf.Any"
    public static let _protobuf_nameMap: _NameMap = [
        1: .unique(proto: "type_url", json: "@type"),
        2: .same(proto: "value"),
    ]
    public var unknownFields = UnknownStorage()

    ///   A URL/resource name whose content describes the type of the
    ///   serialized message.
    ///
    ///   For URLs which use the schema `http`, `https`, or no schema, the
    ///   following restrictions and interpretations apply:
    ///
    ///   * If no schema is provided, `https` is assumed.
    ///   * The last segment of the URL's path must represent the fully
    ///     qualified name of the type (as in `path/google.protobuf.Duration`).
    ///   * An HTTP GET on the URL must yield a [google.protobuf.Type][google.protobuf.Type]
    ///     value in binary format, or produce an error.
    ///   * Applications are allowed to cache lookup results based on the
    ///     URL, or have them precompiled into a binary to avoid any
    ///     lookup. Therefore, binary compatibility needs to be preserved
    ///     on changes to types. (Use versioned type names to manage
    ///     breaking changes.)
    ///
    ///   Schemas other than `http`, `https` (or the empty schema) might be
    ///   used with implementation specific semantics.
    public var typeURL: String?

    ///   Must be valid serialized data of the above specified type.
    public var value: Data? {
        get {
            if let value = _value {
                return value
            } else if let message = _message {
                do {
                    return try message.serializedData()
                } catch {
                    return nil
                }
            } else if let _ = _contentJSON, let typeURL = typeURL {
                // Transcode JSON-to-protobuf by decoding/recoding:
                // Well-known types are always available:
                let encodedTypeName = typeName(fromURL: typeURL)
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
            _value = newValue
            _message = nil
            _contentJSON = nil
        }
    }
    internal var _value: Data?

    internal var _message: Message?
    internal var _contentJSON: Data?  // Any json parsed from with the @type removed.

    public init() {}

    mutating public func decodeMessage<T: Decoder>(decoder: inout T) throws {
        while let fieldNumber = try decoder.nextFieldNumber() {
          switch fieldNumber {
          case 1: try decoder.decodeSingularStringField(value: &typeURL)
          case 2: try decoder.decodeSingularBytesField(value: &_value)
          default: break
          }
        }
    }

    // TODO: If the type is well-known or has already been registered,
    // we should consider decoding eagerly.  Eager decoding would
    // catch certain errors earlier (good) but would probably be
    // a performance hit if the Any contents were never accessed (bad).
    // Of course, we can't always decode eagerly (we don't always have the
    // message type available), so the deferred logic here is still needed.
    mutating func decodeJSON(from decoder: inout JSONDecoder) throws {
        try decoder.scanner.skipRequiredObjectStart()
        // Reset state
        typeURL = nil
        _contentJSON = nil
        _message = nil
        _value = nil
        if decoder.scanner.skipOptionalObjectEnd() {
            return
        }

        var jsonEncoder = JSONEncoder()
        while true {
            let key = try decoder.scanner.nextQuotedString()
            try decoder.scanner.skipRequiredColon()
            if key == "@type" {
                typeURL = try decoder.scanner.nextQuotedString()
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

    public var hashValue: Int {
        get {
            var hash: Int = 0
            if let t = typeURL {
                hash = (hash &* 16777619) ^ t.hashValue
            }
            if let v = _value {
                hash = (hash &* 16777619) ^ v.hashValue
            }
            if let m = _message {
                hash = (hash &* 16777619) ^ m.hashValue
            }
            return hash
        }
    }

    // Override the traversal-based JSON encoding
    // This builds an Any JSON representation from one of:
    //  * The message we were initialized with,
    //  * The JSON fields we last deserialized, or
    //  * The protobuf field we were deserialized from.
    // The last case requires locating the type, deserializing
    // into an object, then reserializing back to JSON.
    internal func encodedJSONString() throws -> String {
        if let message = _message {
            // We were initialized from a message object.

            // We should have been initialized with a typeURL, but
            // ensure it wasn't cleared.
            let url = typeURL ?? buildTypeURL(forMessage: message, typePrefix: defaultTypePrefix)
            if let m = message as? _CustomJSONCodable {
                // Serialize a Well-known type to JSON:
                let value = try m.encodedJSONString()
                return try serializeAnyJSON(wktValueJSON: value, typeURL: url)
            } else {
                // Serialize a regular message to JSON:
                return try serializeAnyJSON(for: message, typeURL: url)
            }
        } else if let typeURL = typeURL {
            if _value != nil {
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

    // Caveat:  This can be very expensive.  We should consider organizing
    // the code generation so that generated equality tests check Any fields last.
    public func _protobuf_generated_isEqualTo(other: Google_Protobuf_Any) -> Bool {
        if ((typeURL != nil && !typeURL!.isEmpty) || (other.typeURL != nil && !other.typeURL!.isEmpty)) && (typeURL == nil || other.typeURL == nil || typeURL! != other.typeURL!) {
            return false
        }

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
        if let myValue = _value, let otherValue = other._value, myValue == otherValue {
            return true
        }

        // If we were both deserialized from JSON, compare content of the JSON?

        return false
    }

    public func traverse<V: Visitor>(visitor: inout V) throws {
        if let typeURL = typeURL {
            try visitor.visitSingularStringField(value: typeURL, fieldNumber: 1)
            // Try to generate bytes for this field...
            if let value = value {
                try visitor.visitSingularBytesField(value: value, fieldNumber: 2)
            } else {
                throw BinaryEncodingError.anyTranscodeFailure
            }
        }
    }
}
