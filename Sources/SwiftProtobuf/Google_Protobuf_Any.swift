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

/// Any objects can be parsed from Protobuf Binary, Protobuf Text, or JSON.
/// The contents are not parsed immediately; the raw data is held in the Any
/// object until you `unpack()` it into a message.  At this time, any
/// error can occur that might have occurred from a regular decoding
/// operation.  In addition, there are a number of other errors that are
/// possible, involving the structure of the Any object itself.
public enum AnyUnpackError: Error {
    /// The `urlType` field in the Any object did not match the message type
    /// provided to the `unpack()` method.
    case typeMismatch
    /// Well-known types being decoded from JSON must have only two
    /// fields:  the `@type` field and a `value` field containing
    /// the specialized JSON coding of the well-known type.
    case malformedWellKnownTypeJSON
    /// The `typeURL` field could not be parsed.
    case malformedTypeURL
    /// There was something else wrong...
    case malformedAnyField
    /// The Any field is empty.  You can only `unpack()` an Any
    /// field if it contains an object (either from an initializer
    /// or from having been decoded).
    case emptyAnyField
    /// Decoding JSON or Text format requires the message type
    /// to have been compiled with textual field names.
    case missingFieldNames
}

fileprivate let defaultTypePrefix: String = "type.googleapis.com"

fileprivate func buildTypeURL(forMessage message: Message, typePrefix: String) -> String {
  var url = typePrefix
  if typePrefix.isEmpty || typePrefix.characters.last != "/" {
    url += "/"
  }
  return url + typeName(fromMessage: message)
}

fileprivate func typeName(fromURL s: String) -> String {
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

fileprivate func typeName(fromMessageType messageType: Message.Type) -> String {
    let protoPackageName = messageType.protoPackageName
    if protoPackageName.isEmpty {
        return messageType.protoMessageName
    } else {
        return "\(protoPackageName).\(messageType.protoMessageName)"
    }
}
fileprivate func typeName(fromMessage message: Message) -> String {
    let msgType = type(of: message)
    return typeName(fromMessageType: msgType)
}

/// Traversal-based JSON encoding of a standard message type
/// This mimics the standard JSON message encoding logic, but adds
/// the additional `@type` field.
fileprivate func serializeAnyJSON(for message: Message, typeURL: String) throws -> String {
    var visitor = JSONEncodingVisitor(message: message)
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
    public static let protoPackageName: String = "google.protobuf"
    public static let protoMessageName: String = "Any"
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
                if let messageType = Google_Protobuf_Any.wellKnownTypes[encodedTypeName] {
                    do {
                        let m = try messageType.init(unpackingAny: self)
                        return try m.serializedData()
                    } catch {
                        return nil
                    }
                }
                // See if the user has registered the type:
                if let messageType = Google_Protobuf_Any.knownTypes[encodedTypeName] {
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
    private var _value: Data?

    private var _message: Message?
    private var _contentJSON: Data?  // Any json parsed from with the @type removed.

    static private var wellKnownTypes: [String:Message.Type] = [
        "google.protobuf.Any": Google_Protobuf_Any.self,
        "google.protobuf.BoolValue": Google_Protobuf_BoolValue.self,
        "google.protobuf.BytesValue": Google_Protobuf_BytesValue.self,
        "google.protobuf.DoubleValue": Google_Protobuf_DoubleValue.self,
        "google.protobuf.Duration": Google_Protobuf_Duration.self,
        "google.protobuf.FieldMask": Google_Protobuf_FieldMask.self,
        "google.protobuf.FloatValue": Google_Protobuf_FloatValue.self,
        "google.protobuf.Int32Value": Google_Protobuf_Int32Value.self,
        "google.protobuf.Int64Value": Google_Protobuf_Int64Value.self,
        "google.protobuf.ListValue": Google_Protobuf_ListValue.self,
        "google.protobuf.StringValue": Google_Protobuf_StringValue.self,
        "google.protobuf.Struct": Google_Protobuf_Struct.self,
        "google.protobuf.Timestamp": Google_Protobuf_Timestamp.self,
        "google.protobuf.UInt32Value": Google_Protobuf_UInt32Value.self,
        "google.protobuf.UInt64Value": Google_Protobuf_UInt64Value.self,
        "google.protobuf.Value": Google_Protobuf_Value.self,
    ]

    static private var knownTypes = [String:Message.Type]()

    /// Register a message type so that Any objects can use
    /// them for decoding contents.
    ///
    /// This is currently only required in two cases:
    ///
    /// * When decoding Protobuf Text format.  Currently,
    ///   Any objects do not defer deserialization from Text
    ///   format.  Depending on how the Any objects are stored
    ///   in text format, the Any object may need to look up
    ///   the message type in order to deserialize itself.
    ///
    /// * When re-encoding an Any object into a different
    ///   format than it was decoded from.  For example, if
    ///   you decode a message containing an Any object from
    ///   JSON format and then re-encode the message into Protobuf
    ///   Binary format, the Any object will need to complete the
    ///   deferred deserialization of the JSON object before it
    ///   can re-encode.
    ///
    /// Note that well-known types are pre-registered for you and
    /// you do not need to register them from your code.
    ///
    /// Also note that this is not needed if you only decode and encode
    /// to and from the same format.
    ///
    static public func register(messageType: Message.Type) {
        let messageTypeName = typeName(fromMessageType: messageType)
        knownTypes[messageTypeName] = messageType
    }

    public init() {}

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
        _message = message
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

    mutating public func _protobuf_generated_decodeMessage<T: Decoder>(decoder: inout T) throws {
        while let fieldNumber = try decoder.nextFieldNumber() {
          switch fieldNumber {
          case 1: try decoder.decodeSingularStringField(value: &typeURL)
          case 2: try decoder.decodeSingularBytesField(value: &_value)
          default: break
          }
        }
    }

    // Custom text format decoding support for Any objects.
    // (Note: This is not a part of any protocol; it's invoked
    // directly from TextFormatDecoder whenever it sees an attempt
    // to decode an Any object)
    mutating func decodeTextFormat(decoder: inout TextFormatDecoder) throws {
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
                _message = any
                return
            } else if let messageType = (Google_Protobuf_Any.wellKnownTypes[messageTypeName]
                ?? Google_Protobuf_Any.knownTypes[messageTypeName]) {
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

        // This is not using the specialized encoding, so we can use the
        // standard path to decode the binary value.
        try decodeMessage(decoder: &decoder)
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

    ///
    ///
    /// Update the provided object from the data in the Any container.
    /// This is essentially just a deferred deserialization; the Any
    /// may hold protobuf bytes or JSON fields depending on how the Any
    /// was itself deserialized.
    ///
    public func unpackTo<M: Message>(target: inout M) throws {
        if typeURL == nil {
            throw AnyUnpackError.emptyAnyField
        }
        let encodedType = typeName(fromURL: typeURL!)
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
        } else if let value = _value {
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
            if Google_Protobuf_Any.wellKnownTypes[targetType] != nil {
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
                if let messageType = Google_Protobuf_Any.wellKnownTypes[messageTypeName] {
                    let m = try messageType.init(unpackingAny: self)
                    let value = try m.jsonString()
                    return try serializeAnyJSON(wktValueJSON: value, typeURL: typeURL)
                }
                // Otherwise, it may be a registered type:
                if let messageType = Google_Protobuf_Any.knownTypes[messageTypeName] {
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
