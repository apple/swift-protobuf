// Sources/SwiftProtobuf/Message.swift - Message support
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
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
/// default implementations of the below methods and properties.
@preconcurrency
public protocol Message: Sendable, Equatable, Hashable, CustomDebugStringConvertible {
    /// Creates a new message with all of its fields initialized to their default
    /// values.
    init()

    // Metadata
    // Basic facts about this class and the proto message it was generated from
    // Used by various encoders and decoders

    /// The fully-scoped name of the message from the original .proto file,
    /// including any relevant package name.
    static var protoMessageName: String { get }

    /// True if all required fields (if any) on this message and any nested
    /// messages (recursively) have values set; otherwise, false.
    var isInitialized: Bool { get }

    /// Some formats include enough information to transport fields that were
    /// not known at generation time. When encountered, they are stored here.
    var unknownFields: UnknownStorage { get set }

    /// The schema that describes this message.
    ///
    /// The schema describes the layout of the message with only enough detail that the Swift
    /// protobuf runtime library can serialize and parse the message in all the required formats.
    /// It is *not* a full descriptor.
    var messageSchema: MessageSchema { get }

    // Standard utility properties and methods.
    // Most of these are simple wrappers on top of the visitor machinery.
    // They are implemented in the protocol, not in the generated structs,
    // so can be overridden in user code by defining custom extensions to
    // the generated struct.

    /// An implementation of hash(into:) to provide conformance with the
    /// `Hashable` protocol.
    func hash(into hasher: inout Hasher)

    /// Helper to compare `Message`s when not having a specific type to use
    /// normal `Equatable`. `Equatable` is provided with specific generated
    /// types.
    func isEqualTo(message: any Message) -> Bool

    /// This is an implementation detail of the runtime; users should not call it. The return type
    /// is a class-bound existential because the true SPI type cannot be used in a protocol
    /// requirement.
    func _protobuf_messageStorage(accessToken: _MessageStorageToken) -> AnyObject

    /// This is an implementation detail of the runtime; users should not call it.
    mutating func _protobuf_ensureUniqueStorage(accessToken: _MessageStorageToken)

    /// This is an implementation detail of the runtime; users should not call it. The return type
    /// is a class-bound existential because the true SPI type cannot be used in a protocol
    /// requirement.
    func _protobuf_extensionStorageImpl() -> AnyObject

    /// This is an implementation detail of the runtime; users should not call it. The return type
    /// is a class-bound existential because the true SPI type cannot be used in a protocol
    /// requirement.
    mutating func _protobuf_uniqueExtensionStorageImpl() -> AnyObject
}

extension Message {
    public func isEqualTo(message: any Message) -> Bool {
        guard let other = message as? Self else {
            return false
        }
        return self == other
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.storageForRuntime.isEqual(to: rhs.storageForRuntime)
    }

    public func hash(into hasher: inout Hasher) {
        self.storageForRuntime.hash(into: &hasher)
    }

    /// Generated proto2 messages that contain required fields, nested messages
    /// that contain required fields, and/or extensions will provide their own
    /// implementation of this property that tests that all required fields are
    /// set. Users of the generated code SHOULD NOT override this property.
    public var isInitialized: Bool {
        // The generated code will include a specialization as needed.
        true
    }

    /// A description generated by recursively visiting all fields in the message,
    /// including messages.
    public var debugDescription: String {
        #if DEBUG
        // TODO Ideally there would be something like serializeText() that can
        // take a prefix so we could do something like:
        //   [class name](
        //      [text format]
        //   )
        let className = String(reflecting: type(of: self))
        let header = "\(className):\n"
        return header + textFormatString()
        #else
        return String(reflecting: type(of: self))
        #endif
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
    public static func with(
        _ populator: (inout Self) throws -> Void
    ) rethrows -> Self {
        var message = Self()
        try populator(&message)
        return message
    }
}

/// Implementation base for all messages; not intended for client use.
///
/// In general, use `SwiftProtobuf.Message` instead when you need a variable or
/// argument that can hold any type of message. Occasionally, you can use
/// `SwiftProtobuf.Message & Equatable` or `SwiftProtobuf.Message & Hashable` as
/// generic constraints if you need to write generic code that can be applied to
/// multiple message types that uses equality tests, puts messages in a `Set`,
/// or uses them as `Dictionary` keys.
@preconcurrency
public protocol _MessageImplementationBase: Message {
    /// Returns the schema for all messages of this generated message type.
    ///
    /// This is identical to the instance property `messageSchema`, but provides a way to access the
    /// statically-known schema for a message without creating an instance of it.
    static var messageSchema: MessageSchema { get }
}

extension _MessageImplementationBase {
    // TODO: Remove this default implementation when we've regenerated all messages.
    public static var messageSchema: MessageSchema {
        fatalError()
    }

    public var messageSchema: MessageSchema {
        Self.messageSchema
    }
}

extension Message {
    /// Convenience property for the runtime to retrieve the underlying storage for a concretely
    /// typed message.
    internal var storageForRuntime: _MessageStorage {
        unsafeDowncast(_protobuf_messageStorage(accessToken: _MessageStorageToken()), to: _MessageStorage.self)
    }

    /// Convenience method for generated code to retrieve the underlying storage for the extensions
    /// of a message.
    @_spi(ForGeneratedCodeOnly)
    public func _protobuf_extensionStorage() -> ExtensionStorage {
        unsafeDowncast(_protobuf_extensionStorageImpl(), to: ExtensionStorage.self)
    }

    /// Convenience method for generated code to retrieve the underlying storage for the extensions
    /// of a message, ensuring that it is unique for mutation.
    @_spi(ForGeneratedCodeOnly)
    public mutating func _protobuf_uniqueExtensionStorage() -> ExtensionStorage {
        unsafeDowncast(_protobuf_uniqueExtensionStorageImpl(), to: ExtensionStorage.self)
    }
}
