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
  static var protoMessageName: String { get }
  static var protoPackageName: String { get }
  static var anyTypePrefix: String { get }
  static var anyTypeURL: String { get }

  /// Check if all required fields (if any) have values set on this message
  /// on any messages withing this message.
  var isInitialized: Bool { get }

  /// Some formats include enough information to transport fields that were
  /// not known at generation time. When encountered, they are stored here.
  var unknownFields: UnknownStorage { get set }

  //
  // General serialization/deserialization machinery
  //

  /// Decode a field identified by a field number (as given in the .proto file).
  /// The Message will call the Decoder method corresponding
  /// to the declared type of the field.
  ///
  /// This is the core method used by the deserialization machinery.
  ///
  /// Note that this is not specific to protobuf encoding; formats that use
  /// textual identifiers translate those to fieldNumbers and then invoke
  /// this to decode the field value.
  ///
  /// Warning: This method does NOT take precautions to preserve copy-on-write
  /// semantics for messages with heap storage; it should only be called on
  /// newly-created messages or messages where the storage has been ensured
  /// unique.
  mutating func decodeField<D: Decoder>(decoder: inout D, fieldNumber: Int) throws

  /// Decode all of the fields from the given decoder.
  ///
  /// This is generally a simple loop that repeatedly gets the next
  /// field number from `decoder.nextFieldNumber()` and
  /// then invokes `decodeField` above.
  mutating func decodeMessage<D: Decoder>(decoder: inout D) throws

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
  func traverse<V: Visitor>(visitor: inout V) throws

  // Standard utility properties and methods.
  // Most of these are simple wrappers on top of the visitor machinery.
  // They are implemented in the protocol, not in the generated structs,
  // so can be overridden in user code by defining custom extensions to
  // the generated struct.
  var hashValue: Int { get }
  var debugDescription: String { get }
}

public extension Message {

  var isInitialized: Bool {
    // The generated code will include a specialization as needed.
    return true;
  }

  var hashValue: Int {
    var visitor = HashVisitor()
    try? traverse(visitor: &visitor)
    return visitor.hashValue
  }

  var debugDescription: String {
    // TODO Ideally there would be something like serializeText() that can
    // take a prefix so we could do something like:
    //   [class name](
    //      [text format]
    //   )
    let className = String(reflecting: type(of: self))
    var result = "\(className):\n"
    if let textFormat = try? textFormatString() {
      result += textFormat
    } else {
      result += "<internal error>"
    }
    return result
  }

  static var anyTypePrefix: String { return "type.googleapis.com" }
  static var anyTypeURL: String {
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
/// Implementation base for all messages.
///
/// All messages (whether hand-implemented or generated)
/// should conform to this type.  It is very rarely
/// used for any other purpose.
///
/// Generally, you should use `SwiftProtobuf.Message` instead
/// when you need a variable or argument that holds a message,
/// or occasionally `SwiftProtobuf.Message & Equatable` or
/// `SwiftProtobuf.Message & Hashable` if you need to use equality
/// tests or put it in a `Set<>`.
///
public protocol _MessageImplementationBase: Message, Hashable {
  // The compiler actually generates the following methods. Default
  // implementations below redirect the standard names. This allows developers
  // to override the standard names to customize the behavior.
  mutating func _protobuf_generated_decodeMessage<T: Decoder>(decoder: inout T) throws

  mutating func _protobuf_generated_decodeField<T: Decoder>(decoder: inout T,
                                                          fieldNumber: Int) throws

  func _protobuf_generated_traverse<V: Visitor>(visitor: inout V) throws

  func _protobuf_generated_isEqualTo(other: Self) -> Bool
}

public extension _MessageImplementationBase {
  public static func ==(lhs: Self, rhs: Self) -> Bool {
    return lhs._protobuf_generated_isEqualTo(other: rhs)
  }

  // Default implementations simply redirect to the generated versions.
  public func traverse<V: Visitor>(visitor: inout V) throws {
    try _protobuf_generated_traverse(visitor: &visitor)
  }

  mutating func decodeField<T: Decoder>(decoder: inout T, fieldNumber: Int) throws {
    try _protobuf_generated_decodeField(decoder: &decoder,
                                      fieldNumber: fieldNumber)
  }

  mutating func decodeMessage<T: Decoder>(decoder: inout T) throws {
      try _protobuf_generated_decodeMessage(decoder: &decoder)
  }
}
