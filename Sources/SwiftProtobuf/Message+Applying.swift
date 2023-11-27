// Sources/SwiftProtobuf/Message+Applying.swift - Applying feature
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Extends the `Message` type with applying behavior.
///
// -----------------------------------------------------------------------------

/// Applying a value to a field of the message by its field number
extension Message {

  /// Applies a value for a specific `fieldNumber` of the message and returns a copy
  /// of the original message.
  ///
  /// - Parameters:
  ///   - value: The value to be applied.
  ///   - fieldNumber: Protobuf index of the field that the value should be applied for.
  /// - Returns: A copy of the message with applied value.
  public func applying(
    _ value: Any,
    for fieldNumber: Int
  ) throws -> Self {
    var copy = self
    try copy.apply(value, for: fieldNumber)
    return copy
  }

  /// Applies a value for a specific `fieldNumber` of the message without making a
  /// copy. This method mutates the original message.
  ///
  /// - Parameters:
  ///   - value: The value to be applied.
  ///   - fieldNumber: Protobuf index of the field that the value should be applied for.
  public mutating func apply(
    _ value: Any,
    for fieldNumber: Int
  ) throws {
    var decoder = ApplyingDecoder(
      fieldNumber: fieldNumber,
      value: value
    )
    try decodeMessage(decoder: &decoder)
  }
}
