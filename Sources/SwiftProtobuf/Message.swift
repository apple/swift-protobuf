// Sources/SwiftProtobuf/Message.swift - Message support
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//

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

  /// The fully-scoped name of the message from the original .proto file,
  /// including any relevant package name.
  static var protoMessageName: String { get }

  /// Check if all required fields (if any) have values set on this message,
  /// including any messages within this message.
  var isInitialized: Bool { get }

  /// Some formats include enough information to transport fields that were
  /// not known at generation time. When encountered, they are stored here.
  var unknownFields: UnknownStorage { get set }

  //
  // General serialization/deserialization machinery
  //

  /// Decode a field identified by a field number (as given in the .proto file).
  /// The `Message` will call the Decoder method corresponding
  /// to the declared type of the field.
  ///
  /// This is the core method used by the deserialization machinery. It is
  /// `public` to enable users to implement their own encoding formats; it
  /// should not be called otherwise.
  ///
  /// Note that this is not specific to protobuf encoding; formats that use
  /// textual identifiers translate those to fieldNumbers and then invoke
  /// this to decode the field value.
  ///
  /// Warning: This method does NOT take precautions to preserve copy-on-write
  /// semantics for messages with heap storage; it should only be called on
  /// newly-created messages or messages where the storage has been ensured
  /// unique.
  ///
  /// - Parameters:
  ///   - decoder: a `Decoder`; the `Message` will call the method
  ///     corresponding to the type of this field.
  ///   - protoFieldNumber: the number of the field to decode.
  /// - Throws: an error on failure or type mismatch.
  mutating func decodeField<D: Decoder>(decoder: inout D, fieldNumber: Int) throws

  /// Decode all of the fields from the given decoder.
  ///
  /// This is generally a simple loop that repeatedly gets the next
  /// field number from `decoder.nextFieldNumber()` and
  /// then invokes `decodeField` above.
  ///
  /// If you're not implementing a custom encoding format, you probably
  /// shouldn't call this.
  mutating func decodeMessage<D: Decoder>(decoder: inout D) throws

  /// Traverses the fields of the message, calling the appropriate methods
  /// of the passed `Visitor` object.
  ///
  /// This is used internally by:
  ///
  /// * Protobuf binary serialization
  /// * JSON serialization (with some twists to account for specialty JSON
  /// * Protobuf Text serialization
  /// * `hashValue` computation
  ///
  /// Conceptually, serializers create visitor objects that are
  /// then passed recursively to every message and field via generated
  /// `traverse` methods.  The details get a little involved due to
  /// the need to allow particular messages to override particular
  /// behaviors for specific encodings, but the general idea is quite simple.
  func traverse<V: Visitor>(visitor: inout V) throws

  // Standard utility properties and methods.
  // Most of these are simple wrappers on top of the visitor machinery.
  // They are implemented in the protocol, not in the generated structs,
  // so can be overridden in user code by defining custom extensions to
  // the generated struct.

  /// The hash value generated from this message's contents, for conformance
  /// with the `Hashable` protocol.
  var hashValue: Int { get }

  /// A textual representation of this message's contents suitable for
  /// debugging, for conformance with the `CustomDebugStringConvertible`
  /// protocol.
  var debugDescription: String { get }
}

public extension Message {

  /// If the generated code needs to provide its own implementation, usually
  /// because the underlying `.proto` file uses proto2 syntax, it will provide
  /// its own implementation. Generally, users of the generated code should
  /// not.
  var isInitialized: Bool {
    // The generated code will include a specialization as needed.
    return true;
  }

  /// A hash based on the message's full contents. Can be overridden
  /// to improve performance and/or remove some values from being used for the
  /// hash.
  ///
  /// If you override this, make sure you maintain the property that values
  /// which are `==` to each other have identical `hashValues`, providing a
  /// custom implementation of `==` if necessary.
  var hashValue: Int {
    var visitor = HashVisitor()
    try? traverse(visitor: &visitor)
    return visitor.hashValue
  }

  /// A description generated by recursively visiting all fields in the message,
  /// including messages. May be overridden to improve readability and/or
  /// performance.
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

  func _protobuf_generated_isEqualTo(other: Self) -> Bool
}

public extension _MessageImplementationBase {
  public static func ==(lhs: Self, rhs: Self) -> Bool {
    return lhs._protobuf_generated_isEqualTo(other: rhs)
  }

  mutating func decodeField<T: Decoder>(decoder: inout T, fieldNumber: Int) throws {
    try _protobuf_generated_decodeField(decoder: &decoder,
                                      fieldNumber: fieldNumber)
  }

  mutating func decodeMessage<T: Decoder>(decoder: inout T) throws {
      try _protobuf_generated_decodeMessage(decoder: &decoder)
  }
}
