// Sources/SwiftProtobuf/JSONEncodingVisitor.swift - JSON encoding visitor
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
/// Visitor that writes a message in JSON format.
///
// -----------------------------------------------------------------------------

import Foundation

/// Visitor that serializes a message into JSON format.
final class JSONEncodingVisitor: Visitor {

  private var encoder = JSONEncoder()
  private var nameResolver: (Int) -> String?
  private var anyTypeURL: String?

  /// The JSON text produced by the visitor.
  var result: String {
    return encoder.result
  }

  /// Creates a new visitor that serializes the given message to JSON format.
  init(message: Message, anyTypeURL: String? = nil) throws {
    self.nameResolver =
      ProtoNameResolvers.jsonFieldNameResolver(for: message)
    self.anyTypeURL = anyTypeURL

    encoder.startObject()

    // TODO: This is a bit of a hack that exists as a workaround to make the
    // hand-written Any serialization work with the new design. We need to
    // generate those WKTs instead of maintaining the hand-written ones,
    // handle the special cases differently, and then remove this.
    if let anyTypeURL = anyTypeURL {
      encoder.startField(name: "@type")
      ProtobufString.serializeJSONValue(encoder: &encoder, value: anyTypeURL)
    }

    try message.traverse(visitor: self)
    encoder.endObject()
  }

  func visitUnknown(bytes: Data) {
    // JSON encoding has no provision for carrying proto2 unknown fields.
  }

  func visitSingularField<S: FieldType>(fieldType: S.Type, value: S.BaseType, fieldNumber: Int) throws {
    let jsonFieldName = try self.jsonFieldName(for: fieldNumber)
    encoder.startField(name: jsonFieldName)
    try S.serializeJSONValue(encoder: &encoder, value: value)
  }

  func visitRepeatedField<S: FieldType>(fieldType: S.Type, value: [S.BaseType], fieldNumber: Int) throws {
    let jsonFieldName = try self.jsonFieldName(for: fieldNumber)
    encoder.startField(name: jsonFieldName)
    var arraySeparator = ""
    encoder.append(text: "[")
    for v in value {
      encoder.append(text: arraySeparator)
      try S.serializeJSONValue(encoder: &encoder, value: v)
      arraySeparator = ","
    }
    encoder.append(text: "]")
  }

  func visitPackedField<S: FieldType>(fieldType: S.Type, value: [S.BaseType], fieldNumber: Int) throws {
    try visitRepeatedField(fieldType: fieldType, value: value, fieldNumber: fieldNumber)
  }

  func visitSingularMessageField<M: Message>(value: M, fieldNumber: Int) throws {
    let jsonFieldName = try self.jsonFieldName(for: fieldNumber)
    encoder.startField(name: jsonFieldName)
    // Note: We ask the message to serialize itself instead of
    // using JSONEncodingVisitor(message:) since
    // some messages override the JSON format at this point.
    try M.serializeJSONValue(encoder: &encoder, value: value)
  }

  func visitRepeatedMessageField<M: Message>(value: [M], fieldNumber: Int) throws {
    let jsonFieldName = try self.jsonFieldName(for: fieldNumber)
    encoder.startField(name: jsonFieldName)
    var arraySeparator = ""
    encoder.append(text: "[")
    for v in value {
      encoder.append(text: arraySeparator)
      // Note: We ask the message to serialize itself instead of
      // using JSONEncodingVisitor(message:) since
      // some messages override the JSON format at this point.
      try M.serializeJSONValue(encoder: &encoder, value: v)
      arraySeparator = ","
    }
    encoder.append(text: "]")
  }

  // Note that JSON encoding for groups is not officially supported
  // by any Google spec.  But it's trivial to support it here.
  func visitSingularGroupField<G: Message>(value: G, fieldNumber: Int) throws {
    let jsonFieldName = try self.jsonFieldName(for: fieldNumber)
    encoder.startField(name: jsonFieldName)
    // Groups have no special JSON support, so we use only the generic traversal mechanism here
    let nestedVisitor = try JSONEncodingVisitor(message: value)
    encoder.append(text: nestedVisitor.result)
  }

  func visitRepeatedGroupField<G: Message>(value: [G], fieldNumber: Int) throws {
    let jsonFieldName = try self.jsonFieldName(for: fieldNumber)
    encoder.startField(name: jsonFieldName)
    var arraySeparator = ""
    encoder.append(text: "[")
    for v in value {
      encoder.append(text: arraySeparator)
      // Groups have no special JSON support, so we use only the generic traversal mechanism here
      let nestedVisitor = try JSONEncodingVisitor(message: v)
      encoder.append(text: nestedVisitor.result)
      arraySeparator = ","
    }
    encoder.append(text: "]")
  }

  func visitMapField<KeyType: MapKeyType, ValueType: MapValueType>(fieldType: ProtobufMap<KeyType, ValueType>.Type, value: ProtobufMap<KeyType, ValueType>.BaseType, fieldNumber: Int) throws  where KeyType.BaseType: Hashable {
    let jsonFieldName = try self.jsonFieldName(for: fieldNumber)
    encoder.startField(name: jsonFieldName)
    var arraySeparator = ""
    encoder.append(text: "{")
    for (k,v) in value {
      encoder.append(text: arraySeparator)
      KeyType.serializeJSONMapKey(encoder: &encoder, value: k)
      encoder.append(text: ":")
      try ValueType.serializeJSONValue(encoder: &encoder, value: v)
      arraySeparator = ","
    }
    encoder.append(text: "}")
  }

  /// Helper function that throws an error if the field number could not be
  /// resolved.
  private func jsonFieldName(for number: Int) throws -> String {
    if let jsonName = nameResolver(number) {
      return jsonName
    }
    throw EncodingError.missingFieldNames
  }
}
