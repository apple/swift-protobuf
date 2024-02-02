// Sources/SwiftProtobuf/Message+FieldMask.swift - Message field mask extensions
//
// Copyright (c) 2014 - 2023 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Extend the Message types with FieldMask utilities.
///
// -----------------------------------------------------------------------------

import Foundation

extension Message {

  /// Checks whether the given path is valid for Message type.
  ///
  /// - Parameter path: Path to be checked
  /// - Returns: Boolean determines path is valid.
  public static func isPathValid(
    _ path: String
  ) -> Bool {
    var message = Self()
    return message.hasPath(path: path)
  }

  internal mutating func isPathValid(
    _ path: String
  ) -> Bool {
    hasPath(path: path)
  }
}

extension Google_Protobuf_FieldMask {

  /// Defines available options for merging two messages.
  public struct MergeOptions {

    public init() {}

    /// The default merging behavior will append entries from the source
    /// repeated field to the destination repeated field. If you only want
    /// to keep the entries from the source repeated field, set this flag
    /// to true.
    public var replaceRepeatedFields = false
  }
}

extension Message {

  /// Merges fields specified in a FieldMask into another message.
  ///
  /// - Parameters:
  ///   - source: Message should be merged to the original one.
  ///   - fieldMask: FieldMask specifies which fields should be merged.
  public mutating func merge(
    from source: Self,
    fieldMask: Google_Protobuf_FieldMask,
    mergeOption: Google_Protobuf_FieldMask.MergeOptions = .init()
  ) throws {
    var source = source
    var pathToValueMap: [String: Any?] = [:]
    for path in fieldMask.paths {
      pathToValueMap[path] = try source.get(path: path)
    }
    for (path, value) in pathToValueMap {
      try? set(
        path: path,
        value: value,
        mergeOption: mergeOption
      )
    }
  }
}

extension Message where Self: Equatable, Self: _ProtoNameProviding {

  // TODO: Re-implement using clear fields instead of copying message

  @discardableResult
  /// Removes from 'message' any field that is not represented in the given
  /// FieldMask. If the FieldMask is empty, does nothing.
  ///
  /// - Parameter fieldMask: FieldMask specifies which fields should be kept.
  /// - Returns: Boolean determines if the message is modified
  public mutating func trim(
    fieldMask: Google_Protobuf_FieldMask
  ) -> Bool {
    if !fieldMask.isValid(for: Self.self) {
      return false
    }
    if fieldMask.paths.isEmpty {
      return false
    }
    var tmp = Self(removingAllFieldsOf: self)
    do {
      try tmp.merge(from: self, fieldMask: fieldMask)
      let changed = tmp != self
      self = tmp
      return changed
    } catch {
      return false
    }
  }
}

private extension Message {
  init(removingAllFieldsOf message: Self) {
    if let type = Self.self as? ExtensibleMessage.Type,
       let extensible = message as? ExtensibleMessage {
      self = type.init(extensionsOf: extensible) as? Self ?? .init()
    } else {
      self = .init()
    }
    self.unknownFields = message.unknownFields
  }
}

private extension Message where Self: ExtensibleMessage {
  init(extensionsOf message: ExtensibleMessage) {
    self.init()
    _protobuf_extensionFieldValues = message._protobuf_extensionFieldValues
  }
}
