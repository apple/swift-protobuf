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


/// The protocol which all generated protobuf messages implement.
/// `Message` is the protocol type you should use whenever
/// you need an argument or variable which holds "some message".
///
/// Generated messages also implement `Hashable`, and thus `Equatable`.
/// However, the protocol conformance is declared on a different protocol.
/// This allows you to use `Message` as a type directly:
///
///     func consume(message: Message) { ... }
///
/// Instead of needing to use it as a type constraint on a generic declaration:
///
///     func consume<M: Message>(message: M) { ... }
///
/// If you need to convince the compiler that your message is `Hashable` so
/// you can insert it into a `Set` or use it as a `Dictionary` key, use
/// a generic declaration with a type constraint:
///
///     func insertIntoSet<M: Message & Hashable>(message: M) {
///         mySet.insert(message)
///     }
///
/// The actual functionality is implemented either in the generated code or in
/// default implementations of the below methods and properties. Some of them,
/// including `hashValue` and `debugDescription`, are designed to let you
/// override the functionality in custom extensions to the generated code.
public protocol Message: CustomDebugStringConvertible {
  /// Creates an instance of the message with all fields initialized to
  /// their default values.
  init()

  // Metadata
  // Basic facts about this class and the proto message it was generated from
  // Used by various encoders and decoders

  /// The name of the message from the original .proto file.
  var protoMessageName: String { get }

  /// The name of the protobuf package from the original .proto file.
  var protoPackageName: String { get }

  /// The prefix used for this message's type when encoded as an `Any`.
  var anyTypePrefix: String { get }

  /// The fully qualifed name used for this message's type when encoded as an `Any`.
  var anyTypeURL: String { get }

  //
  // General serialization/deserialization machinery
  //

  /// Decode a field identified by a field number (as given in the .proto file).
  /// The `Message` will call the `FieldDecoder` method corresponding
  /// to the declared type of the field.
  ///
  /// This is the core method used by the deserialization machinery.
  ///
  /// Note that this is not specific to protobuf encoding; formats that use
  /// textual identifiers translate those to protoFieldNumbers and then invoke
  /// this to decode the field value.
  ///
  /// - Parameters:
  ///   - setter: A `FieldDecoder`; the `Message` will call the method corresponding
  ///     to the type of this field.
  ///   - protoFieldNumber: number of the field to decode
  /// - Throws: An instance of `DecoderError` on failure or type mismatch
  mutating func decodeField<T: FieldDecoder>(setter: inout T, protoFieldNumber: Int) throws

  /// Traverses the fields of the message, calling the appropriate methods
  /// of the passed `Visitor` object.
  ///
  /// This is used internally by:
  ///
  /// * Protobuf binary serialization
  /// * JSON serialization (with some twists to account for specialty JSON
  ///   encodings)
  /// * Protouf Text serialization
  /// * hashValue computation
  ///
  /// Conceptually, serializers create visitor objects that are
  /// then passed recursively to every message and field via generated
  /// `traverse` methods.  The details get a little involved due to
  /// the need to allow particular messages to override particular
  /// behaviors for specific encodings, but the general idea is quite simple.
  func traverse(visitor: Visitor) throws

  /// Attempts to decode raw bytes into this message.
  ///
  /// This is primarily for use by the generated code; you should use
  /// `init(protobuf:)` and siblings to parse binary encoded messages.
  ///
  /// - Parameters:
  ///   - protobufBytes: raw buffer to decode
  ///   - count: length of buffer
  ///   - extensions: Any proto2 message extensions to consider during decoding
  /// - Throws: an instance of `DecodingError` if the message cannot be parsed
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

  /// Creates an instance of this message by decoding an instance of `Any`
  /// (which might itself have been decoded from JSON, protobuf, or another `Any`).
  ///
  /// - Parameter any: item to decode
  /// - Throws: an instance of `DecodingError` if the message cannot be parsed
  init(any: Google_Protobuf_Any) throws

  /// Returns this message serialized as an `Any` object in JSON format.
  ///
  /// This is used by the JSON serialization support to allow certain types
  /// to override how they are represented within `Any` containers. You should
  /// not normally call or override this method.
  ///
  /// - Throws: an instance of `EncodingError` on failure
  func serializeAnyJSON() throws -> String

  //
  // JSON encoding/decoding support
  //

  /// Returns this message serialized using the standard protobuf JSON representation.
  ///
  /// - Throws: an instance of `EncodingError` on failure
  func serializeJSON() throws -> String


  /// Creates an instance of this message based on the given
  /// `JSONDecoder` argument. This is overridden by messages with
  /// specialized JSON encodings, but should not normally be overridden
  /// in user code.
  ///
  /// - Parameter decoder: the decoder
  /// - Throws: an instance of `DecodingError` on failure
  init(decoder: inout JSONDecoder) throws

  // Standard utility properties and methods.
  // Most of these are simple wrappers on top of the visitor machinery.
  // They are implemented in the protocol, not in the generated structs,
  // so can be overridden in user code by defining custom extensions to
  // the generated struct.

  /// The hash value generated from this message's contents, for conformance with
  /// the `Hashable` protocol.
  var hashValue: Int { get }

  /// A textual representation of this message's contents suitable for debugging,
  /// for conformance with the `CustomDebutStringConvertible` protocol.
  var debugDescription: String { get }
}

public extension Message {

  /// A hash based on the message's full contents. Can be overridden
  /// to improve performance and/or remove some values from being used for the
  /// hash.
  ///
  /// If you override this, make sure you maintain the property that values
  /// which are `==` to each other have identical `hashValues`, providing a
  /// custom implementation of `==` if necessary.
  var hashValue: Int {
    let visitor = HashVisitor()
    try? traverse(visitor: visitor)
    return visitor.hashValue
  }

  /// A description generated by recursively visiting all fields in the message,
  /// including messages. May be overridden to improve readability and/or performance.
  var debugDescription: String {
    // TODO Ideally there would be something like serializeText() that can
    // take a prefix so we could do something like:
    //   [class name](
    //      [text format]
    //   )
    let className = String(reflecting: type(of: self))
    var result = "\(className):\n"
    if let textFormat = try? serializeText() {
      result += textFormat
    } else {
      result += "<internal error>"
    }
    return result
  }

  // TODO: Add an option to the generator to override this in particular
  // messages.
  // TODO: It would be nice if this could default to "" instead; that would save
  // ~20 bytes on every serialized Any.

  /// The literal `type.googleapis.com`; may be overridden if your
  /// message's type should be encoded differently.
  var anyTypePrefix: String { return "type.googleapis.com" }

  /// A type URL of the form `anyTypePrefix/protoPackageName.protoMessageName`; may
  /// be overridden if your message's type should be encoded differently.
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
  /// An accessor for unknown fields found when deserializing the message.
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
/// when you need a variable or argument that holds a message.
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
