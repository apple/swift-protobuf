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

fileprivate func typeName(fromMessage message: Message) -> String {
    let msgType = type(of: message)
    let protoPackageName = msgType.protoPackageName
    if protoPackageName == "" {
        return msgType.protoMessageName
    } else {
        return "\(protoPackageName).\(msgType.protoMessageName)"
    }
}

public extension Message {
  public init(any: Google_Protobuf_Any) throws {
    self.init()
    try any.unpackTo(target: &self)
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
public struct Google_Protobuf_Any: Message, Proto3Message, _MessageImplementationBase, _ProtoNameProviding {
    public static let protoPackageName: String = "google.protobuf"
    public static let protoMessageName: String = "Any"
    public static let _protobuf_nameMap: _NameMap = [
        1: .unique(proto: "type_url", json: "@type"),
        2: .same(proto: "value"),
    ]

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
            } else if let _ = _jsonFields, let typeURL = typeURL {
                // Transcode JSON-to-protobuf by decoding/recoding:
                // Well-known types are always available:
                let encodedTypeName = typeName(fromURL: typeURL)
                if let messageType = Google_Protobuf_Any.wellKnownTypes[encodedTypeName] {
                    do {
                        let m = try messageType.init(any: self)
                        return try m.serializedData()
                    } catch {
                        return nil
                    }
                }
                // See if the user has registered the type:
                if let messageType = Google_Protobuf_Any.knownTypes[encodedTypeName] {
                    do {
                        let m = try messageType.init(any: self)
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
            _jsonFields = nil
        }
    }
    private var _value: Data?

    private var _message: Message?
    private var _jsonFields: [String:String]?

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
    static public func register(messageType: Message.Type) {
        let m = messageType.init()
        let messageTypeName = typeName(fromMessage: m)
        knownTypes[messageTypeName] = messageType
    }

    public init() {}

    public init(message: Message) {
        _message = message
        typeURL = type(of: message).anyTypeURL
    }

    mutating public func _protobuf_generated_decodeMessage<T: Decoder>(decoder: inout T) throws {
        while let fieldNumber = try decoder.nextFieldNumber() {
            try decodeField(decoder: &decoder, fieldNumber: fieldNumber)
        }
    }

    mutating public func _protobuf_generated_decodeField<T: Decoder>(decoder: inout T, fieldNumber: Int) throws {
        switch fieldNumber {
        case 1: try decoder.decodeSingularStringField(value: &typeURL)
        case 2: try decoder.decodeSingularBytesField(value: &_value)
        default: break
        }
    }

    public mutating func decodeTextFormat(from decoder: inout TextFormatDecoder) throws {
        // First, check if this uses the "verbose" Any encoding.
        // If it does, and we have the type available, we can
        // eagerly decode the contained Message object.
        if let url = try decoder.scanner.nextOptionalAnyURL() {
            // Decoding the verbose form requires knowing the type:
            typeURL = url
            let messageTypeName = typeName(fromURL: url)
            // Is it a well-known type? Or a user-registered type?
            if let messageType = (Google_Protobuf_Any.wellKnownTypes[messageTypeName]
                ?? Google_Protobuf_Any.knownTypes[messageTypeName]) {
                _message = messageType.init()
                let terminator = try decoder.scanner.skipObjectStart()
                var subDecoder = try TextFormatDecoder(messageType: messageType, scanner: decoder.scanner, terminator: terminator)
                try _message!.decodeTextFormat(from: &subDecoder)
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
    public mutating func decodeJSON(from decoder: inout JSONDecoder) throws {
        try decoder.scanner.skipRequiredObjectStart()
        if decoder.scanner.skipOptionalObjectEnd() {
            return
        }
        _jsonFields = nil
        var jsonFields = [String:String]()
        while true {
            let key = try decoder.scanner.nextQuotedString()
            try decoder.scanner.skipRequiredColon()
            if key == "@type" {
                typeURL = try decoder.scanner.nextQuotedString()
            } else {
                jsonFields[key] = try decoder.scanner.skip()
            }
            if decoder.scanner.skipOptionalObjectEnd() {
                _jsonFields = jsonFields
                return
            }
            try decoder.scanner.skipRequiredComma()
        }
    }

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
        if encodedType == "" {
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
        } else if let jsonFields = _jsonFields {
            let targetType = typeName(fromMessage: target)
            if Google_Protobuf_Any.wellKnownTypes[targetType] != nil {
                // If it's a well-known type, the JSON coding must have a single 'value' field
                if jsonFields.count != 1 {
                    throw AnyUnpackError.malformedWellKnownTypeJSON
                }
                if let v = jsonFields["value"], !v.isEmpty {
                    target = try M(jsonString: v)
                } else {
                    throw AnyUnpackError.malformedWellKnownTypeJSON
                }
            } else {
                // Decode JSON from the stored tokens for generated messages
                guard let nameProviding = (target as? _ProtoNameProviding) else {
                    throw JSONDecodingError.missingFieldNames
                }
                let fieldNames = type(of: nameProviding)._protobuf_nameMap
                for (k,v) in jsonFields {
                    if let fieldNumber = fieldNames.number(forJSONName: k) {
                        let raw = v.data(using: String.Encoding.utf8)!
                        try raw.withUnsafeBytes { (bytes: UnsafePointer<UInt8>) in
                            var decoder = JSONDecoder(utf8Pointer: bytes, count: raw.count)
                            try target.decodeField(decoder: &decoder, fieldNumber: fieldNumber)
                            if !decoder.scanner.complete {
                                throw JSONDecodingError.trailingGarbage
                            }
                        }
                    }
                    // Ignore unrecognized field names (as per usual with JSON decoding)
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

    public init(any: Google_Protobuf_Any) throws {
        try any.unpackTo(target: &self)
    }

    // Override the traversal-based JSON encoding
    // This builds an Any JSON representation from one of:
    //  * The message we were initialized with,
    //  * The JSON fields we last deserialized, or
    //  * The protobuf field we were deserialized from.
    // The last case requires locating the type, deserializing
    // into an object, then reserializing back to JSON.
    public func jsonString() throws -> String {
        if let message = _message {
            return try message.anyJSONString()
        } else if let typeURL = typeURL {
            if _value != nil {
                // Transcode protobuf-to-JSON by decoding and recoding.
                // Well-known types are always available:
                let messageTypeName = typeName(fromURL: typeURL)
                if let messageType = Google_Protobuf_Any.wellKnownTypes[messageTypeName] {
                    let m = try messageType.init(any: self)
                    return try m.anyJSONString()
                }
                // The user may have registered this type:
                if let messageType = Google_Protobuf_Any.knownTypes[messageTypeName] {
                    let m = try messageType.init(any: self)
                    return try m.anyJSONString()
                }
                // TODO: Google spec requires more work in the general case:
                // let encodedType = ... fetch google.protobuf.Type based on typeURL ...
                // let type = Google_Protobuf_Type(protobuf: encodedType)
                // return ProtobufDynamicMessage(type: type, any: self)?.serializeAnyJSON()

                // The big problem here is fetching the type:  Types not in the executable must be fetched from somewhere; Google says we should do an HTTPS fetch against the typeURL, which assumes that everyone will publish all their types and that everyone running this code will have reliable network access.  That seems ... optimistic.

                // ProtobufDynamicMessage() is non-trivial to write but desirable for other reasons.  It's a class that can be instantiated with any protobuf type or descriptor and provides access to protos of the corresponding type.  (Not to be confused with ProtobufRaw which can decode any message but does not use a type descriptor and therefore cannot provide fully-typed access to fields.)
                throw JSONEncodingError.anyTranscodeFailure
            } else {
                var jsonEncoder = JSONEncoder()
                jsonEncoder.startObject()
                jsonEncoder.startField(name: "@type")
                jsonEncoder.putStringValue(value: typeURL)
                if let jsonFields = _jsonFields {
                    // JSON-to-JSON case, just recode the stored tokens
                    for (k,v) in jsonFields {
                        jsonEncoder.startField(name: k)
                        jsonEncoder.append(text: v)
                    }
                }
                jsonEncoder.endObject()
                return jsonEncoder.stringResult
            }
        } else {
            return "{}"
        }
    }

    public func anyJSONString() throws -> String {
        let value = try jsonString()
        return "{\"@type\":\"\(type(of: self).anyTypeURL)\",\"value\":\(value)}"
    }

    // Caveat:  This can be very expensive.  We should consider organizing
    // the code generation so that generated equality tests check Any fields last.
    public func _protobuf_generated_isEqualTo(other: Google_Protobuf_Any) -> Bool {
        if ((typeURL != nil && typeURL != "") || (other.typeURL != nil && other.typeURL != "")) && (typeURL == nil || other.typeURL == nil || typeURL! != other.typeURL!) {
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

        // If we were both deserialized from JSON, compare the JSON token streams:
        //if let myJSON = _jsonFields, let otherJSON = other._jsonFields, myJSON == otherJSON {
        //    return true
        //}

        return false
    }

    public func _protobuf_generated_traverse<V: Visitor>(visitor: inout V) throws {
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
