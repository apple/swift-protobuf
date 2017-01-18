// Sources/SwiftProtobuf/Message.swift - Message support
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
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


///
/// See ProtobufBinaryTypes and ProtobufJSONTypes for extensions
/// to these protocols for supporting binary and JSON coding.
///

///
/// ProtobufMessage is the protocol type you should use whenever
/// you need an argument or variable which holds "some message".
///
/// In particular, this has no associated types or self references so can be
/// used as a variable or argument type.
///
public protocol Message: CustomDebugStringConvertible {
  init()

  // Metadata
  // Basic facts about this class and the proto message it was generated from
  // Used by various encoders and decoders
  var swiftClassName: String { get }
  var protoMessageName: String { get }
  var protoPackageName: String { get }
  var anyTypePrefix: String { get }
  var anyTypeURL: String { get }

  //
  // General serialization/deserialization machinery
  //

  /// Decode a field identified by a field number (as given in the .proto file).
  /// The Message will call the FieldDecoder method corresponding
  /// to the declared type of the field.
  ///
  /// This is the core method used by the deserialization machinery.
  ///
  /// Note that this is not specific to protobuf encoding; formats that use
  /// textual identifiers translate those to protoFieldNumbers and then invoke
  /// this to decode the field value.
 mutating func decodeField<T: FieldDecoder>(setter: inout T, protoFieldNumber: Int) throws

  /// Support for traversing the object tree.
  ///
  /// This is used by:
  /// = Protobuf binary serialization
  /// = JSON serialization (with some twists to account for specialty JSON
  ///   encodings)
  /// = Protouf Text serialization
  /// = hashValue computation
  ///
  /// Conceptually, serializers create visitor objects that are
  /// then passed recursively to every message and field via generated
  /// 'traverse' methods.  The details get a little involved due to
  /// the need to allow particular messages to override particular
  /// behaviors for specific encodings, but the general idea is quite simple.
  func traverse(visitor: Visitor) throws

  //
  // Protobuf Binary decoding
  //
  mutating func decodeIntoSelf(protobufBytes: UnsafePointer<UInt8>,
                               count: Int,
                               extensions: ExtensionSet?) throws

  //
  // Protobuf Text decoding
  //
  init(scanner: TextScanner) throws

  //
  // google.protobuf.Any support
  //

  // Decode from an `Any` (which might itself have been decoded from JSON,
  // protobuf, or another `Any`).
  init(any: Google_Protobuf_Any) throws

  /// Serialize as an `Any` object in JSON format.
  ///
  /// For generated message types, this generates the same JSON object as
  /// `serializeJSON()` except it adds an additional `@type` field.
  func serializeAnyJSON() throws -> String

  //
  // JSON encoding/decoding support
  //

  /// Serialize to JSON
  /// Overridden by well-known-types with custom JSON requirements.
  func serializeJSON() throws -> String
  /// Decode from tokens read from a JSON decoder
  mutating func setFromJSON(decoder: JSONDecoder) throws

  // Standard utility properties and methods.
  // Most of these are simple wrappers on top of the visitor machinery.
  // They are implemented in the protocol, not in the generated structs,
  // so can be overridden in user code by defining custom extensions to
  // the generated struct.
  var hashValue: Int { get }
  var debugDescription: String { get }
}

public extension Message {
  var hashValue: Int {
    let visitor = HashVisitor()
    try? traverse(visitor: visitor)
    return visitor.hashValue
  }

  var debugDescription: String {
    return DebugDescriptionVisitor(message: self).description
  }

  // TODO: Add an option to the generator to override this in particular
  // messages.
  // TODO: It would be nice if this could default to "" instead; that would save
  // ~20 bytes on every serialized Any.
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
  public static func with(_ populator: (inout Self) throws -> ()) rethrows -> Self {
    var message = Self()
    try populator(&message)
    return message
  }
}

///
/// Marker type that specifies the message was generated from
/// a proto2 source file.
///
public protocol Proto2Message: Message {
  var unknown: UnknownStorage { get set }
}

///
/// Marker type that specifies the message was generated from
/// a proto3 source file.
///
public protocol Proto3Message: Message {
}

///
/// Implementation base for all messages.
///
/// All messages (whether hand-implemented or generated)
/// should conform to this type.  It is very rarely
/// used for any other purpose.
///
/// Generally, you should use `SwiftProtobuf.Message` instead
/// when you need a variable or argument that holds a message,
/// or occasionally `SwiftProtobuf.Message & Equatable` or even
/// `SwiftProtobuf.Message & Hashable` if you need to use equality
/// tests or put it in a `Set<>`.
///
public protocol _MessageImplementationBase: Message, Hashable, MapValueType, FieldType {
  // The compiler actually generates the following methods. Default
  // implementations below redirect the standard names. This allows developers
  // to override the standard names to customize the behavior.
  mutating func _protoc_generated_decodeField<T: FieldDecoder>(setter: inout T,
                                              protoFieldNumber: Int) throws

  func _protoc_generated_traverse(visitor: Visitor) throws

  func _protoc_generated_isEqualTo(other: Self) -> Bool
}

public extension _MessageImplementationBase {
  public static func ==(lhs: Self, rhs: Self) -> Bool {
    return lhs._protoc_generated_isEqualTo(other: rhs)
  }

  // Default implementations simply redirect to the generated versions.
  public func traverse(visitor: Visitor) throws {
    try _protoc_generated_traverse(visitor: visitor)
  }

  mutating func decodeField<T: FieldDecoder>(setter: inout T, protoFieldNumber: Int) throws {
    try _protoc_generated_decodeField(setter: &setter,
                                      protoFieldNumber: protoFieldNumber)
  }
}
