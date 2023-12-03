// Sources/SwiftProtobuf/Message+FieldMask.swift - Message field mask extensions
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Extend the Message types with FieldMask utilities. (e.g. masking)
///
// -----------------------------------------------------------------------------

extension Message where Self: _ProtoNameProviding {

  /// Clears masked fields and keep the other fields unchanged.
  /// Notice that masking will be done in order of field mask paths.
  ///
  /// - Parameter mask: Field mask which determines what fields 
  /// shoud be cleared.
  public mutating func mask(
    by mask: Google_Protobuf_FieldMask
  ) throws {
    try override(with: .init(), by: mask)
  }

  /// Overrides value of masked fields in original message with the input message.
  /// Notice that overriding will be done in order of field mask paths.
  ///
  /// - Parameters:
  ///   - message: Message which overrides some fields of the original message.
  ///   - mask: Field mask which determines what fields should be overriden.
  public mutating func override(
    with message: Self,
    by mask: Google_Protobuf_FieldMask
  ) throws {
    var copy = self
    var pathToValueMap: [String: Any?] = [:]
    for path in mask.paths {
      pathToValueMap[path] = try message.get(path: path)
    }
    for (path, value) in pathToValueMap {
      try copy.set(path: path, value: value)
    }
    self = copy
  }

  /// Returns a new message with cleared masked fields.
  /// Notice that masking will be done in order of field mask paths.
  ///
  /// - Parameter mask: Field mask which determines what fields
  /// should be cleared.
  public func masked(
    by mask: Google_Protobuf_FieldMask
  ) throws -> Self {
    var copy = self
    try copy.mask(by: mask)
    return copy
  }

  /// Returns a new message which some of its value are overriden with the
  /// input message. Notice that masking will be done in order of field
  /// mask paths.
  ///
  /// - Parameters:
  ///   - message: Message which overrides some fields of the original message.
  ///   - mask: Field mask which determines what fields should be overriden.
  public func overriden(
    with message: Self,
    by mask: Google_Protobuf_FieldMask
  ) throws -> Self {
    var copy = self
    try copy.override(with: message, by: mask)
    return copy
  }
}
