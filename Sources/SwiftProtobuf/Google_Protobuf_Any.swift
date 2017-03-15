//// Sources/SwiftProtobuf/Google_Protobuf_Any.swift - Well-known Any type
////
//// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
//// Licensed under Apache License v2.0 with Runtime Library Exception
////
//// See LICENSE.txt for license information:
//// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
////
//// -----------------------------------------------------------------------------
/////
///// This is pretty much completely hand-built.
/////
///// Generating it from any.proto -- even just partially -- is
///// probably not feasible.
/////
//// -----------------------------------------------------------------------------
//
///// ### DELETE ME
//
//import Foundation
//
//internal func typeName(fromURL s: String) -> String {
//    var typeStart = s.startIndex
//    var i = typeStart
//    while i < s.endIndex {
//        let c = s[i]
//        i = s.index(after: i)
//        if c == "/" {
//            typeStart = i
//        }
//    }
//
//    return s[typeStart..<s.endIndex]
//}
//
/////   `Any` contains an arbitrary serialized message along with a URL
/////   that describes the type of the serialized message.
/////
/////   JSON
/////   ====
/////   The JSON representation of an `Any` value uses the regular
/////   representation of the deserialized, embedded message, with an
/////   additional field `@type` which contains the type URL. Example:
/////
/////       package google.profile;
/////       message Person {
/////         string first_name = 1;
/////         string last_name = 2;
/////       }
/////
/////       {
/////         "@type": "type.googleapis.com/google.profile.Person",
/////         "firstName": <string>,
/////         "lastName": <string>
/////       }
/////
/////   If the embedded message type is well-known and has a custom JSON
/////   representation, that representation will be embedded adding a field
/////   `value` which holds the custom JSON in addition to the the `@type`
/////   field. Example (for message [google.protobuf.Duration][google.protobuf.Duration]):
/////
/////       {
/////         "@type": "type.googleapis.com/google.protobuf.Duration",
/////         "value": "1.212s"
/////       }
/////
///// Swift implementation details
///// ============================
/////
///// Internally, the Google_Protobuf_Any holds either a
///// message struct, a protobuf-serialized bytes value, or a collection
///// of JSON fields.
/////
///// If you create a Google_Protobuf_Any(message:) then the object will
///// keep a copy of the provided message.  When the Any itself is later
///// serialized, the message will be inspected to correctly serialize
///// the Any to protobuf or JSON as appropriate.
/////
///// If you deserialize a Google_Protobuf_Any() from protobuf, then it will
///// contain a protobuf-serialized form of the contained object.  This will
///// in turn be deserialized only when you use the unpackTo() method.
/////
///// If you deserialize a Google_Protobuf_Any() from JSON, then it will
///// contain a set of partially-decoded JSON fields.  These will
///// be fully deserialized when you use the unpackTo() method.
/////
///// Note that deserializing from protobuf and reserializing back to
///// protobuf (or JSON-to-JSON) is efficient and well-supported.
///// However, deserializing from protobuf and reserializing to JSON
///// (or vice versa) is much more complicated:
/////   * Well-known types are automatically detected and handled as
/////     if the Any field were deserialized to the in-memory form
/////     and then serialized back out again.
/////   * You can register your message types via Google_Protobuf_Any.register().
/////     Such types will be automatically handled as above.
/////   * Someday, there will be a mechanism for you to provide
/////     Type descriptors (which might be fetched from a remote server
/////     on-demand).
/////
///// In particular, note that it is not possible to decode a google.protobuf.Any
///// field in a protobuf message and then recode to JSON (or vice versa)
///// without having the type information available.  This is a basic
///// limitation of Google's spec for google.protobuf.Any.
/////
//public struct Google_Protobuf_Any: Message, _MessageImplementationBase, _ProtoNameProviding {
//    public static let protoMessageName: String = "google.protobuf.Any"
//    public static let _protobuf_nameMap: _NameMap = [
//        1: .unique(proto: "type_url", json: "@type"),
//        2: .same(proto: "value"),
//    ]
//    public var unknownFields = UnknownStorage()
//
//    ///   A URL/resource name whose content describes the type of the
//    ///   serialized message.
//    ///
//    ///   For URLs which use the schema `http`, `https`, or no schema, the
//    ///   following restrictions and interpretations apply:
//    ///
//    ///   * If no schema is provided, `https` is assumed.
//    ///   * The last segment of the URL's path must represent the fully
//    ///     qualified name of the type (as in `path/google.protobuf.Duration`).
//    ///   * An HTTP GET on the URL must yield a [google.protobuf.Type][google.protobuf.Type]
//    ///     value in binary format, or produce an error.
//    ///   * Applications are allowed to cache lookup results based on the
//    ///     URL, or have them precompiled into a binary to avoid any
//    ///     lookup. Therefore, binary compatibility needs to be preserved
//    ///     on changes to types. (Use versioned type names to manage
//    ///     breaking changes.)
//    ///
//    ///   Schemas other than `http`, `https` (or the empty schema) might be
//    ///   used with implementation specific semantics.
//    public var typeURL: String = ""
//
//    ///   Must be valid serialized data of the above specified type.
//    internal var _value: Data?
//
//    internal var _message: Message?
//    internal var _contentJSON: Data?  // Any json parsed from with the @type removed.
//
//    public init() {}
//
//    mutating public func decodeMessage<T: Decoder>(decoder: inout T) throws {
//        while let fieldNumber = try decoder.nextFieldNumber() {
//          switch fieldNumber {
//          case 1: try decoder.decodeSingularStringField(value: &typeURL)
//          case 2: try decoder.decodeSingularBytesField(value: &_value)
//          default: break
//          }
//        }
//    }
//
//    // Caveat:  This can be very expensive.  We should consider organizing
//    // the code generation so that generated equality tests check Any fields last.
//    public func _protobuf_generated_isEqualTo(other: Google_Protobuf_Any) -> Bool {
//        if (typeURL != other.typeURL) {
//            return false
//        }
//
//        // The best option is to decode and compare the messages; this
//        // insulates us from variations in serialization details.  For
//        // example, one Any might hold protobuf binary bytes from one
//        // language implementation and the other from another language
//        // implementation.  But of course this only works if we
//        // actually know the message type.
//
//        //if let myMessage = _message {
//        //    if let otherMessage = other._message {
//        //        ... compare them directly
//        //    } else {
//        //        ... try to decode other and compare
//        //    }
//        //} else if let otherMessage = other._message {
//        //    ... try to decode ourselves and compare
//        //} else {
//        //    ... try to decode both and compare
//        //}
//
//        // If we don't know the message type, we have few options:
//
//        // If we were both deserialized from proto, compare the binary value:
//        if let myValue = _value, let otherValue = other._value, myValue == otherValue {
//            return true
//        }
//
//        // If we were both deserialized from JSON, compare content of the JSON?
//
//        return false
//    }
//
//    public func traverse<V: Visitor>(visitor: inout V) throws {
//        try visitor.visitSingularStringField(value: typeURL, fieldNumber: 1)
//        // Try to generate bytes for this field...
//        if let value = value {
//            try visitor.visitSingularBytesField(value: value, fieldNumber: 2)
//        } else {
//            throw BinaryEncodingError.anyTranscodeFailure
//        }
//    }
//}
