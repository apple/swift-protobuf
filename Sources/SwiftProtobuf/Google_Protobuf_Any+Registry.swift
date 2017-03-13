// Sources/SwiftProtobuf/Google_Protobuf_Any+Registry.swift - Registry for JSON support
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
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

fileprivate let wktToMessageType: [String:Message.Type] = [
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

fileprivate var knownTypes = [String:Message.Type]()

public extension Google_Protobuf_Any {

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
    static public func register(messageType: Message.Type) {
        let messageTypeName = messageType.protoMessageName
        assert(!isWellKnownType(messageName: messageTypeName))
        knownTypes[messageTypeName] = messageType
    }

    /// Returns the Message.type expected for the given proto message name.
    static public func lookupMessageType(forMessageName name: String) -> Message.Type? {
        if let messageType = wellKnownType(forMessageName: name) {
            return messageType
        }
        return knownTypes[name]
    }

    static internal func wellKnownType(forMessageName name: String) -> Message.Type? {
        return wktToMessageType[name]
    }

    static internal func isWellKnownType(messageName name: String) -> Bool {
        return wellKnownType(forMessageName: name) != nil
    }

}
