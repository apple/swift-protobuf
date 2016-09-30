// ProtobufRuntime/Sources/Protobuf/Google_Protobuf_Any.swift - Well-known Any type
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
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
import Swift

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

fileprivate func typeName(fromMessage message: ProtobufMessage) -> String {
    if message.protoPackageName == "" {
        return message.protoMessageName
    } else {
        return "\(message.protoPackageName).\(message.protoMessageName)"
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
public struct Google_Protobuf_Any: ProtobufAbstractMessage, Hashable, Equatable, CustomReflectable {
    public var swiftClassName: String {return "Google_Protobuf_Any"}
    public var protoPackageName: String {return "google.protobuf"}
    public var protoMessageName: String {return "Any"}
    public var jsonFieldNames: [String:Int] {return ["@type":1,"value":2]}
    public var protoFieldNames: [String:Int] {return ["type_url":1,"value":2]}
    
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
                    return try message.serializeProtobuf()
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
                        return try m.serializeProtobuf()
                    } catch {
                        return nil
                    }
                }
                // See if the user has registered the type:
                if let messageType = Google_Protobuf_Any.knownTypes[encodedTypeName] {
                    do {
                        let m = try messageType.init(any: self)
                        return try m.serializeProtobuf()
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

    private var _message: ProtobufMessage?
    private var _jsonFields: [String:[ProtobufJSONToken]]?

    static private var wellKnownTypes: [String:ProtobufMessage.Type] = [
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

    static private var knownTypes = [String:ProtobufMessage.Type]()
    static public func register(messageType: ProtobufMessage.Type) {
        let m = messageType.init()
        let messageTypeName = typeName(fromMessage: m)
        knownTypes[messageTypeName] = messageType
    }

    public init() {}

    public init(message: ProtobufMessage) {
        _message = message
        typeURL = message.anyTypeURL
    }

    mutating public func decodeField(setter: inout ProtobufFieldDecoder, protoFieldNumber: Int) throws -> Bool {
        switch protoFieldNumber {
        case 1: return try setter.decodeOptionalField(fieldType: ProtobufString.self, value: &typeURL)
        case 2: return try setter.decodeOptionalField(fieldType: ProtobufBytes.self, value: &_value)
        default: return false
        }
    }

    public mutating func decodeFromJSONObject(jsonDecoder: inout ProtobufJSONDecoder) throws {
        var key = ""
        var state = ProtobufJSONDecoder.ObjectParseState.expectFirstKey
        _jsonFields = nil
        var jsonFields = [String:[ProtobufJSONToken]]()
        while let token = try jsonDecoder.nextToken() {
            switch token {
            case .string(let s): // This is a key
                if state != .expectKey && state != .expectFirstKey {
                    throw ProtobufDecodingError.malformedJSON
                }
                key = s
                state = .expectColon
            case .colon:
                if state != .expectColon {
                    throw ProtobufDecodingError.malformedJSON
                }
                if key == "@type" {
                    try jsonDecoder.decodeValue(key: key, message: &self)
                } else {
                    jsonFields[key] = try jsonDecoder.skip()
                }
                state = .expectComma
            case .comma:
                if state != .expectComma {
                    throw ProtobufDecodingError.malformedJSON
                }
                state = .expectKey
            case .endObject:
                if state != .expectFirstKey && state != .expectComma {
                    throw ProtobufDecodingError.malformedJSON
                }
                _jsonFields = jsonFields
                return
            default:
                throw ProtobufDecodingError.malformedJSON
            }
        }
        throw ProtobufDecodingError.malformedJSON
    }

    /// Update the provided object from the data in the Any container.
    /// This is essentially just a deferred deserialization; the Any
    /// may hold protobuf bytes or JSON fields depending on how the Any
    /// was itself deserialized.
    ///
    public func unpackTo<M: ProtobufMessage>(target: inout M) throws {
        if typeURL == nil {
            throw ProtobufDecodingError.malformedAnyField
        }
        let encodedType = typeName(fromURL: typeURL!)
        if encodedType == "" {
            throw ProtobufDecodingError.malformedAnyField
        }
        let messageType = typeName(fromMessage: target)
        if encodedType != messageType {
            throw ProtobufDecodingError.malformedAnyField
        }
        var protobuf: Data?
        if let message = _message {
            protobuf = try message.serializeProtobuf()
        } else if let value = _value {
            protobuf = value
        }
        if let protobuf = protobuf {
            // Decode protobuf from the stored bytes
            try protobuf.withUnsafeBytes { (p: UnsafePointer<UInt8>) in
                let bp = UnsafeBufferPointer(start: p, count: protobuf.count)
                var protobufDecoder = ProtobufBinaryDecoder(protobufPointer: bp)
                try protobufDecoder.decodeFullObject(message: &target)
            }
            return
        } else if let jsonFields = _jsonFields {
            let targetType = typeName(fromMessage: target)
            if Google_Protobuf_Any.wellKnownTypes[targetType] != nil {
                // If it's a well-known type, the JSON coding must have a single 'value' field
                if jsonFields.count != 1 || jsonFields["value"] == nil {
                    throw ProtobufDecodingError.schemaMismatch
                }
                var v = jsonFields["value"]!
                guard v.count > 0 else {
                    throw ProtobufDecodingError.schemaMismatch
                }
                switch v[0] {
                case .beginObject:
                    var decoder = ProtobufJSONDecoder(tokens: v)
                    let _ = try decoder.nextToken() // Discard {
                    try target.decodeFromJSONObject(jsonDecoder: &decoder)
                    if !decoder.complete {
                        throw ProtobufDecodingError.trailingGarbage
                    }
                case .beginArray:
                    var decoder = ProtobufJSONDecoder(tokens: v)
                    let _ = try decoder.nextToken() // Discard [
                    try target.decodeFromJSONArray(jsonDecoder: &decoder)
                case .number(_), .string(_), .boolean(_):
                    try target.decodeFromJSONToken(token: v[0])
                case .null:
                    if let n = try M.decodeFromJSONNull() {
                        target = n
                    } else {
                        throw ProtobufDecodingError.malformedJSON
                    }
                default:
                    throw ProtobufDecodingError.malformedJSON
                }
            } else {
                // Decode JSON from the stored tokens for generated messages
                for (k,v) in jsonFields {
                    var decoder = ProtobufJSONDecoder(tokens: v)
                    try decoder.decodeValue(key: k, message: &target)
                    if !decoder.complete {
                        throw ProtobufDecodingError.trailingGarbage
                    }
                }
            }
            return
        }
        throw ProtobufDecodingError.malformedAnyField
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

    public var debugDescription: String {
        get {
            if let message = _message {
                return "Google_Protobuf_Any{" + String(reflecting: message) + "}"
            } else if let typeURL = typeURL {
                if let value = _value {
                    return "Google_Protobuf_Any{\(typeURL), \(value)}"
                } else {
                    return "Google_Protobuf_Any{\(typeURL), <JSON>}"
                }
            } else {
                return "Google_Protobuf_Any{}"
            }
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
    public func serializeJSON() throws -> String {
        if let message = _message {
            return try message.serializeAnyJSON()
        } else if let typeURL = typeURL {
            if _value != nil {
                // Transcode protobuf-to-JSON by decoding and recoding.
                // Well-known types are always available:
                let messageTypeName = typeName(fromURL: typeURL)
                if let messageType = Google_Protobuf_Any.wellKnownTypes[messageTypeName] {
                    let m = try messageType.init(any: self)
                    return try m.serializeAnyJSON()
                }
                // The user may have registered this type:
                if let messageType = Google_Protobuf_Any.knownTypes[messageTypeName] {
                    let m = try messageType.init(any: self)
                    return try m.serializeAnyJSON()
                }
                // TODO: Google spec requires more work in the general case:
                // let encodedType = ... fetch google.protobuf.Type based on typeURL ...
                // let type = Google_Protobuf_Type(protobuf: encodedType)
                // return ProtobufDynamicMessage(type: type, any: self)?.serializeAnyJSON()

                // The big problem here is fetching the type:  Types not in the executable must be fetched from somewhere; Google says we should do an HTTPS fetch against the typeURL, which assumes that everyone will publish all their types and that everyone running this code will have reliable network access.  That seems ... optimistic.

                // ProtobufDynamicMessage() is non-trivial to write but desirable for other reasons.  It's a class that can be instantiated with any protobuf type or descriptor and provides access to protos of the corresponding type.  (Not to be confused with ProtobufRaw which can decode any message but does not use a type descriptor and therefore cannot provide fully-typed access to fields.)
                throw ProtobufEncodingError.anyTranscodeFailure
            } else {
                var jsonEncoder = ProtobufJSONEncoder()
                jsonEncoder.startObject()
                jsonEncoder.startField(name: "@type")
                jsonEncoder.putStringValue(value: typeURL)
                if let jsonFields = _jsonFields {
                    // JSON-to-JSON case, just recode the stored tokens
                    for (k,v) in jsonFields {
                        jsonEncoder.startField(name: k)
                        jsonEncoder.appendTokens(tokens: v)
                    }
                }
                jsonEncoder.endObject()
                return jsonEncoder.result
            }
        } else {
            return "{}"
        }
    }

    public func serializeAnyJSON() throws -> String {
        let value = try serializeJSON()
        return "{\"@type\":\"\(anyTypeURL)\",\"value\":\(value)}"
    }
    
    public func isEqualTo(other: Google_Protobuf_Any) -> Bool {
        // TODO: Fix this for case where Any holds a message or jsonFields or the two Any hold different stuff... <ugh>  This seems unsolvable in the general case.  <ugh>
        if ((typeURL != nil && typeURL != "") || (other.typeURL != nil && other.typeURL != "")) && (typeURL == nil || other.typeURL == nil || typeURL! != other.typeURL!) {
            return false
        }
        if (_value != nil || other._value != nil) && (_value == nil || other._value == nil || _value! != other._value!) {
            return false
        }
        return true
    }

    public func traverse(visitor: inout ProtobufVisitor) throws {
        if let typeURL = typeURL {
            try visitor.visitSingularField(fieldType: ProtobufString.self, value: typeURL, protoFieldNumber: 1, protoFieldName: "type_url", jsonFieldName: "@type", swiftFieldName: "typeURL")
            if let value = value {
                try visitor.visitSingularField(fieldType: ProtobufBytes.self, value: value, protoFieldNumber: 2, protoFieldName: "value", jsonFieldName: "value", swiftFieldName: "value")
            } else {
                throw ProtobufEncodingError.anyTranscodeFailure
            }
        }
    }
}
