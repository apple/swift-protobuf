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

fileprivate func typeName(fromMessage message: Message) -> String {
    if message.protoPackageName == "" {
        return message.protoMessageName
    } else {
        return "\(message.protoPackageName).\(message.protoMessageName)"
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
public struct Google_Protobuf_Any: Message, Proto3Message, _MessageImplementationBase, ProtoNameProviding {
    public var swiftClassName: String {return "Google_Protobuf_Any"}
    public var protoPackageName: String {return "google.protobuf"}
    public var protoMessageName: String {return "Any"}
    public static let _protobuf_fieldNames: FieldNameMap = [
        1: .unique(proto: "type_url", json: "@type", swift: "typeURL"),
        2: .same(proto: "value", swift: "value"),
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

    private var _message: Message?
    private var _jsonFields: [String:[JSONToken]]?

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
        typeURL = message.anyTypeURL
    }

    mutating public func _protoc_generated_decodeField<T: FieldDecoder>(setter: inout T, protoFieldNumber: Int) throws {
        switch protoFieldNumber {
        case 1: try setter.decodeSingularField(fieldType: ProtobufString.self, value: &typeURL)
        case 2: try setter.decodeSingularField(fieldType: ProtobufBytes.self, value: &_value)
        default: break
        }
    }

    public mutating func setFromJSON(decoder: JSONDecoder) throws {
        if try decoder.isObjectEmpty() {
            return
        }
        _jsonFields = nil
        var jsonFields = [String:[JSONToken]]()
        while true {
            let key = try decoder.nextKey()
            if key == "@type" {
                if let typeNameToken = try decoder.nextToken(),
                    case .string(let typeName) = typeNameToken {
                    typeURL = typeName
                } else {
                    throw DecodingError.malformedJSON
                }
            } else {
                jsonFields[key] = try decoder.skip()
            }
            if let token = try decoder.nextToken() {
                switch token {
                case .comma:
                    break
                case .endObject:
                    _jsonFields = jsonFields
                    return
                default:
                    throw DecodingError.malformedJSON
                }
            } else {
                throw DecodingError.malformedJSON
            }
        }
    }

    /// Update the provided object from the data in the Any container.
    /// This is essentially just a deferred deserialization; the Any
    /// may hold protobuf bytes or JSON fields depending on how the Any
    /// was itself deserialized.
    ///
    public func unpackTo<M: Message>(target: inout M) throws {
        if typeURL == nil {
            throw DecodingError.malformedAnyField
        }
        let encodedType = typeName(fromURL: typeURL!)
        if encodedType == "" {
            throw DecodingError.malformedAnyField
        }
        let messageType = typeName(fromMessage: target)
        if encodedType != messageType {
            throw DecodingError.malformedAnyField
        }
        var protobuf: Data?
        if let message = _message as? M {
            target = message
            return
        }

        if let message = _message {
            protobuf = try message.serializeProtobuf()
        } else if let value = _value {
            protobuf = value
        }
        if let protobuf = protobuf {
            // Decode protobuf from the stored bytes
            if protobuf.count > 0 {
                try protobuf.withUnsafeBytes { (p: UnsafePointer<UInt8>) in
                    try target.decodeIntoSelf(protobufBytes: p, count: protobuf.count, extensions: nil)
                }
            }
            return
        } else if let jsonFields = _jsonFields {
            let targetType = typeName(fromMessage: target)
            if Google_Protobuf_Any.wellKnownTypes[targetType] != nil {
                // If it's a well-known type, the JSON coding must have a single 'value' field
                if jsonFields.count != 1 || jsonFields["value"] == nil {
                    throw DecodingError.schemaMismatch
                }
                let v = jsonFields["value"]!
                guard v.count > 0 else {
                    throw DecodingError.schemaMismatch
                }
                let decoder = JSONDecoder(tokens: v)
                var m: M? = M()
                try M.setFromJSON(decoder: decoder, value: &m)
                target = m!
            } else {
                // Decode JSON from the stored tokens for generated messages
                guard let nameProviding = (target as? ProtoNameProviding) else {
                    throw DecodingError.missingFieldNames
                }
                let fieldNames = type(of: nameProviding)._protobuf_fieldNames
                for (k,v) in jsonFields {
                    if let protoFieldNumber = fieldNames.fieldNumber(forJSONName: k) {
                        var decoder = JSONDecoder(tokens: v)
                        try target.decodeField(setter: &decoder, protoFieldNumber: protoFieldNumber)
                        if !decoder.complete {
                            throw DecodingError.trailingGarbage
                        }
                    }
                }
            }
            return
        }
        throw DecodingError.malformedAnyField
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
                throw EncodingError.anyTranscodeFailure
            } else {
                var jsonEncoder = JSONEncoder()
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

    public init(scanner: TextScanner) throws {
        self.init()
        let terminator = try scanner.readObjectStart()
        if let keyToken = try scanner.nextKey() {
            if case .identifier(let key) = keyToken, key.hasPrefix("["), key.hasSuffix("]") {
                var url = key
                url.remove(at: url.startIndex)
                url.remove(at: url.index(before: url.endIndex))
                typeURL = url
                let messageTypeName = typeName(fromURL: url)
                if let messageType = Google_Protobuf_Any.wellKnownTypes[messageTypeName] {
                    _message = try messageType.init(scanner: scanner)
                    try scanner.skipRequired(token: terminator)
                    return
                }
                throw DecodingError.malformedText
            } else {
                scanner.pushback(token: keyToken)
                var subDecoder = TextDecoder(scanner: scanner)
                try subDecoder.decodeFullObject(message: &self, terminator: terminator)
            }
        } else {
            throw DecodingError.truncatedInput
        }
    }

    // Caveat:  This can be very expensive.  We should consider organizing
    // the code generation so that generated equality tests check Any fields last.
    public func _protoc_generated_isEqualTo(other: Google_Protobuf_Any) -> Bool {
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

    public func _protoc_generated_traverse(visitor: Visitor) throws {
        if let typeURL = typeURL {
            try visitor.visitSingularField(fieldType: ProtobufString.self, value: typeURL, fieldNumber: 1)
            // Try to generate bytes for this field...
            if let value = value {
                try visitor.visitSingularField(fieldType: ProtobufBytes.self, value: value, fieldNumber: 2)
            } else {
                throw EncodingError.anyTranscodeFailure
            }
        }
    }
}
