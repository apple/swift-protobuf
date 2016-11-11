// ProtobufRuntime/Sources/Protobuf/ProtobufMessage.swift - Message support
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
/// All messages implement some of these protocols:  Generated messages output
/// by protoc implement ProtobufGeneratedMessageType, hand-coded messages often
/// implement ProtobufAbstractMessage.  The protocol heirarchy here is
/// a little involved due to the variety of requirements and the need to
/// mix in JSON and binary support (see ProtobufBinaryTypes and
/// ProtobufJSONTypes for extensions that support binary and JSON coding).
///
// -----------------------------------------------------------------------------

import Swift

///
/// See ProtobufBinaryTypes and ProtobufJSONTypes for extensions
/// to these protocols for supporting binary and JSON coding.
///

///
/// The core protocol implemented by all messages, whether generated or
/// hand-coded.
///
/// In particular, this has no associated types or self references so can be
/// used as a variable or argument type.
///
public protocol ProtobufMessageBase:
  CustomDebugStringConvertible, ProtobufTraversable {

  init()

  // Basic facts about this class and the proto message it was generated from
  // Used by various encoders and decoders
  var swiftClassName: String { get }
  var protoMessageName: String { get }
  var protoPackageName: String { get }
  var anyTypePrefix: String { get }
  var anyTypeURL: String { get }
  var jsonFieldNames: [String: Int] {get}
  var protoFieldNames: [String: Int] {get}

  /// Decode a field identified by a field number (as given in the .proto file).
  ///
  /// This is the core method used by the deserialization machinery.
  ///
  /// Note that this is not specific to protobuf encoding; formats that use
  /// textual identifiers translate those to protoFieldNumbers and then invoke
  /// this to decode the field value.
  mutating func decodeField(setter: inout ProtobufFieldDecoder,
                            protoFieldNumber: Int) throws

  // The corresponding serialization support is the traverse() method
  // declared in ProtobufTraversable

  // Decode from an `Any` (which might itself have been decoded from JSON,
  // protobuf, or another `Any`).
  init(any: Google_Protobuf_Any) throws

  /// Serialize as an `Any` object in JSON format.
  ///
  /// For generated message types, this generates the same JSON object as
  /// `serializeJSON()` except it adds an additional `@type` field.
  func serializeAnyJSON() throws -> String

  // Standard utility properties and methods.
  // Most of these are simple wrappers on top of the visitor machinery.
  // They are implemented in the protocol, not in the generated structs,
  // so can be overridden in user code by defining custom extensions to
  // the generated struct.
  var hashValue: Int { get }
  var debugDescription: String { get }
  var customMirror: Mirror { get }
}

public extension ProtobufMessageBase {
  var hashValue: Int { return ProtobufHashVisitor(message: self).hashValue }

  var debugDescription: String {
    return ProtobufDebugDescriptionVisitor(message: self).description
  }

  var customMirror: Mirror {
    return ProtobufMirrorVisitor(message: self).mirror
  }

  // TODO:  Add an option to the generator to override this in particular messages.
  // TODO:  It would be nice if this could default to "" instead; that would save ~20
  // bytes on every serialized Any.
  var anyTypePrefix: String { return "type.googleapis.com" }

  var anyTypeURL: String {
    var url = anyTypePrefix
    if anyTypePrefix == "" || anyTypePrefix.characters.last! != "/" {
      url += "/"
    }
    if protoPackageName != "" {
      url += protoPackageName
      url += "."
    }
    url += protoMessageName
    return url
  }

  /// Creates an instance of the message type on which this method is called,
  /// executes the given block passing the message in as its sole `inout`
  /// argument, and then returns the message.
  ///
  /// This method acts essentially as a "builder" in that the initialization of
  /// the message is captured within the block, allowing the returned value to
  /// be set in an immutable variable. For example,
  ///
  ///     let msg = MyMessage.with { $0.myField = "foo" }
  ///     msg.myOtherField = 5  // error: msg is immutable
  ///
  /// - Parameter populator: A block or function that populates the new message,
  ///   which is passed into the block as an `inout` argument.
  /// - Returns: The message after execution of the block.
  public static func with(populator: (inout Self) -> ()) -> Self {
    var message = Self()
    populator(&message)
    return message
  }
}

///
/// ProtobufMessage which extends ProtobufMessageBase with some
/// additional requirements, including serialization extensions.
/// This is used directly by hand-coded message implementations.
///
public protocol ProtobufMessage:
  ProtobufMessageBase, ProtobufBinaryMessageBase, ProtobufJSONMessageBase,
  CustomReflectable {}

public protocol ProtobufAbstractMessage:
  ProtobufMessage, Hashable, ProtobufMapValueType {

  func isEqualTo(other: Self) -> Bool
}

public extension ProtobufAbstractMessage {
  static func isEqual(_ lhs: Self, _ rhs: Self) -> Bool {
    return lhs == rhs
  }

  public init(any: Google_Protobuf_Any) throws {
    self.init()
    try any.unpackTo(target: &self)
  }
}

public func ==<M: ProtobufAbstractMessage>(lhs: M, rhs: M) -> Bool {
  return lhs.isEqualTo(other: rhs)
}

public protocol ProtobufProto2Message: ProtobufMessage {
  var unknown: ProtobufUnknownStorage { get set }
}

public protocol ProtobufProto3Message: ProtobufMessage {
}

///
/// Base type for generated message types.
///
/// This provides some basic indirection so end users can override generated
/// methods.
///
public protocol ProtobufGeneratedMessage: ProtobufAbstractMessage {
  // The compiler actually generates the following methods. Default
  // implementations below redirect the standard names. This allows developers
  // to override the standard names to customize the behavior.
  mutating func _protoc_generated_decodeField(
    setter: inout ProtobufFieldDecoder,
    protoFieldNumber: Int) throws

  func _protoc_generated_traverse(visitor: inout ProtobufVisitor) throws

  func _protoc_generated_isEqualTo(other: Self) -> Bool
}

public extension ProtobufGeneratedMessage {
  // Default implementations simply redirect to the generated versions.
  public func traverse(visitor: inout ProtobufVisitor) throws {
    try _protoc_generated_traverse(visitor: &visitor)
  }

  mutating func decodeField(setter: inout ProtobufFieldDecoder,
                            protoFieldNumber: Int) throws {
      try _protoc_generated_decodeField(setter: &setter,
                                        protoFieldNumber: protoFieldNumber)
  }

  func isEqualTo(other: Self) -> Bool {
    return _protoc_generated_isEqualTo(other: other)
  }
}
