// Sources/SwiftProtobuf/Visitor.swift - Basic serialization machinery
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//

import Foundation

/// Protocol for traversing the fields of a message, including recursing
/// into any fields which are messages themselves.
///
/// Internally, this is used by:
///
/// * Protobuf binary serialization
/// * JSON serialization (with some twists to account for specialty JSON
///   encodings)
/// * Protobuf text serialization, including `debugDescription`
/// * `hashValue` computation
///
/// Conceptually, serializers create visitor objects that are
/// then passed recursively to every message and field via generated
/// `traverse` methods.  The details get a little involved due to
/// the need to allow particular messages to override particular
/// behaviors for specific encodings, but the general idea is quite simple.
public protocol Visitor: class {

  /// Called for each non-repeated scalar field (i.e., not messages or groups).
  func visitSingularField<S: FieldType>(fieldType: S.Type,
                                        value: S.BaseType,
                                        fieldNumber: Int) throws

  /// Called for each repeated, unpacked scalar field (i.e., not messages or
  /// groups). The method is called once with the complete array of values for
  /// the field.
  func visitRepeatedField<S: FieldType>(fieldType: S.Type,
                                        value: [S.BaseType],
                                        fieldNumber: Int) throws

  /// Called for each repeated, packed scalar field (i.e., not messages or
  /// groups). The method is called once with the complete array of values for
  /// the field.
  func visitPackedField<S: FieldType>(fieldType: S.Type,
                                      value: [S.BaseType],
                                      fieldNumber: Int) throws

  /// Called for each non-repeated nested message field.
  func visitSingularMessageField<M: Message>(value: M, fieldNumber: Int) throws

  /// Called for each repeated nested message field. The method is called once
  /// with the complete array of values for the field.
  func visitRepeatedMessageField<M: Message>(value: [M],
                                             fieldNumber: Int) throws

  /// Called for each non-repeated proto2 group field.
  func visitSingularGroupField<G: Message>(value: G, fieldNumber: Int) throws

  /// Called for each repeated proto2 group field.
  func visitRepeatedGroupField<G: Message>(value: [G], fieldNumber: Int) throws

  /// Called for each map field. The method is called once with the complete
  /// dictionary of keys/values for the field.
  func visitMapField<KeyType: MapKeyType, ValueType: MapValueType>(
    fieldType: ProtobufMap<KeyType, ValueType>.Type,
    value: ProtobufMap<KeyType, ValueType>.BaseType,
    fieldNumber: Int) throws where KeyType.BaseType: Hashable

  /// Called with the raw bytes that represent any proto2 unknown fields.
  func visitUnknown(bytes: Data)
}

extension Visitor {

  /// Forwards to `visitRepeatedField`. Implementors who need to handle 
  /// packed fields differently than unpacked fields can override this and
  /// provide distinct implementations.
  public func visitPackedField<S: FieldType>(fieldType: S.Type,
                                             value: [S.BaseType],
                                             fieldNumber: Int) throws {
    try visitRepeatedField(fieldType: fieldType,
                           value: value,
                           fieldNumber: fieldNumber)
  }

  /// Forwards to `visitSingularMessageField`. Implementors who need to handle
  /// groups differently than nested messages can override this and provide
  /// distinct implementations.
  public func visitSingularGroupField<G: Message>(value: G,
                                                  fieldNumber: Int) throws {
    try visitSingularMessageField(value: value, fieldNumber: fieldNumber)
  }

  /// Forwards to `visitRepeatedMessageField`. Implementors who need to handle
  /// groups differently than nested messages can override this and provide
  /// distinct
  /// implementations.
  public func visitRepeatedGroupField<G: Message>(value: [G],
                                                  fieldNumber: Int) throws {
    try visitRepeatedMessageField(value: value, fieldNumber: fieldNumber)
  }
}
