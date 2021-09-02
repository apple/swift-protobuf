// Sources/SwiftProtobuf/Google_Protobuf_Any+Extensions.swift - Well-known Any type
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Extends the `Google_Protobuf_Any` type with various custom behaviors.
///
// -----------------------------------------------------------------------------

// Explicit import of Foundation is necessary on Linux,
// don't remove unless obsolete on all platforms
import Foundation

public let defaultAnyTypeURLPrefix: String = "type.googleapis.com"

extension Google_Protobuf_Any {
  /// Initialize an Any object from the provided message.
  ///
  /// This corresponds to the `pack` operation in the C++ API.
  ///
  /// Unlike the C++ implementation, the message is not immediately
  /// serialized; it is merely stored until the Any object itself
  /// needs to be serialized.  This design avoids unnecessary
  /// decoding/recoding when writing JSON format.
  ///
  /// - Parameters:
  ///   - partial: If `false` (the default), this method will check
  ///     `Message.isInitialized` before encoding to verify that all required
  ///     fields are present. If any are missing, this method throws
  ///     `BinaryEncodingError.missingRequiredFields`.
  ///   - typePrefix: The prefix to be used when building the `type_url`. 
  ///     Defaults to "type.googleapis.com".
  /// - Throws: `BinaryEncodingError.missingRequiredFields` if `partial` is
  ///     false and `message` wasn't fully initialized.
  public init(
    message: Message,
    partial: Bool = false,
    typePrefix: String = defaultAnyTypeURLPrefix
  ) throws {
    if !partial && !message.isInitialized {
      throw BinaryEncodingError.missingRequiredFields
    }
    self.init()
    typeURL = buildTypeURL(forMessage:message, typePrefix: typePrefix)
    _storage.state = .message(message)
  }

  /// Returns true if this `Google_Protobuf_Any` message contains the given
  /// message type.
  ///
  /// The check is performed by looking at the passed `Message.Type` and the
  /// `typeURL` of this message.
  ///
  /// - Parameter type: The concrete message type.
  /// - Returns: True if the receiver contains the given message type.
  public func isA<M: Message>(_ type: M.Type) -> Bool {
    return _storage.isA(type)
  }

  public func hash(into hasher: inout Hasher) {
    _storage.hash(into: &hasher)
  }
}
