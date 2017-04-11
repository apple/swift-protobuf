// Sources/SwiftProtobuf/ExtensionFields.swift - Extension support
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Core protocols implemented by generated extensions.
///
// -----------------------------------------------------------------------------

private let i_2166136261 = Int(bitPattern: 2166136261)
private let i_16777619 = Int(16777619)

//
// Type-erased Extension field implementation.
// Note that it has no "self or associated type" references, so can
// be used as a protocol type.  (In particular, although it does have
// a hashValue property, it cannot be Hashable.)
//
// This can encode, decode, return a hashValue and test for
// equality with some other extension field; but it's type-sealed
// so you can't actually access the contained value itself.
//
public protocol AnyExtensionField: CustomDebugStringConvertible {
  var hashValue: Int { get }
  var protobufExtension: MessageExtensionBase { get }
  func isEqual(other: AnyExtensionField) -> Bool

  /// General field decoding
  mutating func decodeExtensionField<T: Decoder>(decoder: inout T) throws

  /// Fields know their own type, so can dispatch to a visitor
  func traverse<V: Visitor>(visitor: inout V) throws

  /// Check if the field is initialized.
  var isInitialized: Bool { get }
}

public extension AnyExtensionField {
  // Default implementation for extensions fields.  The message types below provide
  // custom versions.
  var isInitialized: Bool { return true }
}

///
/// The regular ExtensionField type exposes the value directly.
///
public protocol ExtensionField: AnyExtensionField, Hashable {
  associatedtype ValueType
  var value: ValueType { get set }
  init(protobufExtension: MessageExtensionBase)
}

///
/// Singular field
///
public struct OptionalExtensionField<T: FieldType>: ExtensionField {
  public typealias BaseType = T.BaseType
  public typealias ValueType = BaseType?
  public var value: ValueType
  public var protobufExtension: MessageExtensionBase

  public static func ==(lhs: OptionalExtensionField,
                        rhs: OptionalExtensionField) -> Bool {
    return lhs.value == rhs.value
  }

  public init(protobufExtension: MessageExtensionBase) {
    self.protobufExtension = protobufExtension
  }

  public var debugDescription: String {
    get {
      if let value = value {
        return String(reflecting: value)
      }
      return String()
    }
  }

  public var hashValue: Int {
    get { return value?.hashValue ?? 0 }
  }

  public func isEqual(other: AnyExtensionField) -> Bool {
    let o = other as! OptionalExtensionField<T>
    return self == o
  }

  public mutating func decodeExtensionField<D: Decoder>(decoder: inout D) throws {
      try T.decodeSingular(value: &value, from: &decoder)
  }

  public func traverse<V: Visitor>(visitor: inout V) throws {
    if let v = value {
      try T.visitSingular(value: v, fieldNumber: protobufExtension.fieldNumber, with: &visitor)
    }
  }
}

///
/// Repeated fields
///
public struct RepeatedExtensionField<T: FieldType>: ExtensionField {
  public typealias BaseType = T.BaseType
  public typealias ValueType = [BaseType]
  public var value = ValueType()
  public var protobufExtension: MessageExtensionBase

  public static func ==(lhs: RepeatedExtensionField,
                        rhs: RepeatedExtensionField) -> Bool {
    return lhs.value == rhs.value
  }

  public init(protobufExtension: MessageExtensionBase) {
    self.protobufExtension = protobufExtension
  }

  public var hashValue: Int {
    get {
      var hash = i_2166136261
      for e in value {
        hash = (hash &* i_16777619) ^ e.hashValue
      }
      return hash
    }
  }

  public func isEqual(other: AnyExtensionField) -> Bool {
    let o = other as! RepeatedExtensionField<T>
    return self == o
  }

  public var debugDescription: String {
    return "[" + value.map{String(reflecting: $0)}.joined(separator: ",") + "]"
  }

  public mutating func decodeExtensionField<D: Decoder>(decoder: inout D) throws {
      try T.decodeRepeated(value: &value, from: &decoder)
  }

  public func traverse<V: Visitor>(visitor: inout V) throws {
    if value.count > 0 {
      try T.visitRepeated(value: value, fieldNumber: protobufExtension.fieldNumber, with: &visitor)
    }
  }
}

///
/// Packed Repeated fields
///
/// TODO: This is almost (but not quite) identical to RepeatedFields;
/// find a way to collapse the implementations.
///
public struct PackedExtensionField<T: FieldType>: ExtensionField {
  public typealias BaseType = T.BaseType
  public typealias ValueType = [BaseType]
  public var value = ValueType()
  public var protobufExtension: MessageExtensionBase

  public static func ==(lhs: PackedExtensionField,
                        rhs: PackedExtensionField) -> Bool {
    return lhs.value == rhs.value
  }

  public init(protobufExtension: MessageExtensionBase) {
    self.protobufExtension = protobufExtension
  }

  public var hashValue: Int {
    get {
      var hash = i_2166136261
      for e in value {
        hash = (hash &* i_16777619) ^ e.hashValue
      }
      return hash
    }
  }

  public func isEqual(other: AnyExtensionField) -> Bool {
    let o = other as! PackedExtensionField<T>
    return self == o
  }

  public var debugDescription: String {
    return "[" + value.map{String(reflecting: $0)}.joined(separator: ",") + "]"
  }

  public mutating func decodeExtensionField<D: Decoder>(decoder: inout D) throws {
    try T.decodeRepeated(value: &value, from: &decoder)
  }

  public func traverse<V: Visitor>(visitor: inout V) throws {
    if value.count > 0 {
      try T.visitPacked(value: value, fieldNumber: protobufExtension.fieldNumber, with: &visitor)
    }
  }
}

///
/// Enum extensions
///
public struct OptionalEnumExtensionField<E: Enum>: ExtensionField where E.RawValue == Int {
  public typealias BaseType = E
  public typealias ValueType = E?
  public var value: ValueType
  public var protobufExtension: MessageExtensionBase

  public static func ==(lhs: OptionalEnumExtensionField,
                        rhs: OptionalEnumExtensionField) -> Bool {
    return lhs.value == rhs.value
  }

  public init(protobufExtension: MessageExtensionBase) {
    self.protobufExtension = protobufExtension
  }

  public var debugDescription: String {
    get {
      if let value = value {
        return String(reflecting: value)
      }
      return String()
    }
  }

  public var hashValue: Int {
    get { return value?.hashValue ?? 0 }
  }

  public func isEqual(other: AnyExtensionField) -> Bool {
    let o = other as! OptionalEnumExtensionField<E>
    return self == o
  }

  public mutating func decodeExtensionField<D: Decoder>(decoder: inout D) throws {
      try decoder.decodeSingularEnumField(value: &value)
  }

  public func traverse<V: Visitor>(visitor: inout V) throws {
    if let v = value {
      try visitor.visitSingularEnumField(
        value: v,
        fieldNumber: protobufExtension.fieldNumber)
    }
  }
}

///
/// Repeated Enum fields
///
public struct RepeatedEnumExtensionField<E: Enum>: ExtensionField where E.RawValue == Int {
  public typealias BaseType = E
  public typealias ValueType = [E]
  public var value = ValueType()
  public var protobufExtension: MessageExtensionBase

  public static func ==(lhs: RepeatedEnumExtensionField,
                        rhs: RepeatedEnumExtensionField) -> Bool {
    return lhs.value == rhs.value
  }

  public init(protobufExtension: MessageExtensionBase) {
    self.protobufExtension = protobufExtension
  }

  public var hashValue: Int {
    get {
      var hash = i_2166136261
      for e in value {
        hash = (hash &* i_16777619) ^ e.hashValue
      }
      return hash
    }
  }

  public func isEqual(other: AnyExtensionField) -> Bool {
    let o = other as! RepeatedEnumExtensionField<E>
    return self == o
  }

  public var debugDescription: String {
    return "[" + value.map{String(reflecting: $0)}.joined(separator: ",") + "]"
  }

  public mutating func decodeExtensionField<D: Decoder>(decoder: inout D) throws {
    try decoder.decodeRepeatedEnumField(value: &value)
  }

  public func traverse<V: Visitor>(visitor: inout V) throws {
    if value.count > 0 {
      try visitor.visitRepeatedEnumField(
        value: value,
        fieldNumber: protobufExtension.fieldNumber)
    }
  }
}

///
/// Packed Repeated Enum fields
///
/// TODO: This is almost (but not quite) identical to RepeatedEnumFields;
/// find a way to collapse the implementations.
///
public struct PackedEnumExtensionField<E: Enum>: ExtensionField where E.RawValue == Int {
  public typealias BaseType = E
  public typealias ValueType = [E]
  public var value = ValueType()
  public var protobufExtension: MessageExtensionBase

  public static func ==(lhs: PackedEnumExtensionField,
                        rhs: PackedEnumExtensionField) -> Bool {
    return lhs.value == rhs.value
  }

  public init(protobufExtension: MessageExtensionBase) {
    self.protobufExtension = protobufExtension
  }

  public var hashValue: Int {
    get {
      var hash = i_2166136261
      for e in value {
        hash = (hash &* i_16777619) ^ e.hashValue
      }
      return hash
    }
  }

  public func isEqual(other: AnyExtensionField) -> Bool {
    let o = other as! PackedEnumExtensionField<E>
    return self == o
  }

  public var debugDescription: String {
    return "[" + value.map{String(reflecting: $0)}.joined(separator: ",") + "]"
  }

  public mutating func decodeExtensionField<D: Decoder>(decoder: inout D) throws {
    try decoder.decodeRepeatedEnumField(value: &value)
  }

  public func traverse<V: Visitor>(visitor: inout V) throws {
    if value.count > 0 {
      try visitor.visitPackedEnumField(
        value: value,
        fieldNumber: protobufExtension.fieldNumber)
    }
  }
}

//
// ========== Message ==========
//
public struct OptionalMessageExtensionField<M: Message & Equatable>:
  ExtensionField {
  public typealias BaseType = M
  public typealias ValueType = BaseType?
  public var value: ValueType
  public var protobufExtension: MessageExtensionBase

  public static func ==(lhs: OptionalMessageExtensionField,
                        rhs: OptionalMessageExtensionField) -> Bool {
    return lhs.value == rhs.value
  }

  public init(protobufExtension: MessageExtensionBase) {
    self.protobufExtension = protobufExtension
  }

  public var debugDescription: String {
    get {
      if let value = value {
        return String(reflecting: value)
      }
      return String()
    }
  }

  public var hashValue: Int {return value?.hashValue ?? 0}

  public func isEqual(other: AnyExtensionField) -> Bool {
    let o = other as! OptionalMessageExtensionField<M>
    return self == o
  }

  public mutating func decodeExtensionField<D: Decoder>(decoder: inout D) throws {
    try decoder.decodeSingularMessageField(value: &value)
  }

  public func traverse<V: Visitor>(visitor: inout V) throws {
    if let v = value {
      try visitor.visitSingularMessageField(
        value: v, fieldNumber: protobufExtension.fieldNumber)
    }
  }

  public var isInitialized: Bool {
    if let v = value {
      return v.isInitialized
    }
    return true
  }
}

public struct RepeatedMessageExtensionField<M: Message & Equatable>:
  ExtensionField {
  public typealias BaseType = M
  public typealias ValueType = [BaseType]
  public var value = ValueType()
  public var protobufExtension: MessageExtensionBase

  public static func ==(lhs: RepeatedMessageExtensionField,
                        rhs: RepeatedMessageExtensionField) -> Bool {
    return lhs.value == rhs.value
  }

  public init(protobufExtension: MessageExtensionBase) {
    self.protobufExtension = protobufExtension
  }

  public var hashValue: Int {
    get {
      var hash = i_2166136261
      for e in value {
        hash = (hash &* i_16777619) ^ e.hashValue
      }
      return hash
    }
  }

  public func isEqual(other: AnyExtensionField) -> Bool {
    let o = other as! RepeatedMessageExtensionField<M>
    return self == o
  }

  public var debugDescription: String {
    return "[" + value.map{String(reflecting: $0)}.joined(separator: ",") + "]"
  }

  public mutating func decodeExtensionField<D: Decoder>(decoder: inout D) throws {
    try decoder.decodeRepeatedMessageField(value: &value)
  }

  public func traverse<V: Visitor>(visitor: inout V) throws {
    if value.count > 0 {
      try visitor.visitRepeatedMessageField(
        value: value, fieldNumber: protobufExtension.fieldNumber)
    }
  }

  public var isInitialized: Bool {
    return Internal.areAllInitialized(value)
  }
}

//
// ======== Groups within Messages ========
//
// Protoc internally treats groups the same as messages, but
// they serialize very differently, so we have separate serialization
// handling here...
public struct OptionalGroupExtensionField<G: Message & Hashable>:
  ExtensionField {
  public typealias BaseType = G
  public typealias ValueType = BaseType?
  public var value: G?
  public var protobufExtension: MessageExtensionBase

  public static func ==(lhs: OptionalGroupExtensionField,
                        rhs: OptionalGroupExtensionField) -> Bool {
    return lhs.value == rhs.value
  }

  public init(protobufExtension: MessageExtensionBase) {
    self.protobufExtension = protobufExtension
  }

  public var hashValue: Int {return value?.hashValue ?? 0}

  public var debugDescription: String { get {return value?.debugDescription ?? String()} }

  public func isEqual(other: AnyExtensionField) -> Bool {
    let o = other as! OptionalGroupExtensionField<G>
    return self == o
  }

  public mutating func decodeExtensionField<D: Decoder>(decoder: inout D) throws {
    try decoder.decodeSingularGroupField(value: &value)
  }

  public func traverse<V: Visitor>(visitor: inout V) throws {
    if let v = value {
      try visitor.visitSingularGroupField(
        value: v, fieldNumber: protobufExtension.fieldNumber)
    }
  }

  public var isInitialized: Bool {
    if let v = value {
      return v.isInitialized
    }
    return true
  }
}

public struct RepeatedGroupExtensionField<G: Message & Hashable>:
  ExtensionField {
  public typealias BaseType = G
  public typealias ValueType = [BaseType]
  public var value = [G]()
  public var protobufExtension: MessageExtensionBase

  public static func ==(lhs: RepeatedGroupExtensionField,
                        rhs: RepeatedGroupExtensionField) -> Bool {
    return lhs.value == rhs.value
  }

  public init(protobufExtension: MessageExtensionBase) {
    self.protobufExtension = protobufExtension
  }

  public var hashValue: Int {
    get {
      var hash = i_2166136261
      for e in value {
        hash = (hash &* i_16777619) ^ e.hashValue
      }
      return hash
    }
  }

  public var debugDescription: String {
    return "[" + value.map{$0.debugDescription}.joined(separator: ",") + "]"
  }

  public func isEqual(other: AnyExtensionField) -> Bool {
    let o = other as! RepeatedGroupExtensionField<G>
    return self == o
  }

  public mutating func decodeExtensionField<D: Decoder>(decoder: inout D) throws {
    try decoder.decodeRepeatedGroupField(value: &value)
  }

  public func traverse<V: Visitor>(visitor: inout V) throws {
    if value.count > 0 {
      try visitor.visitRepeatedGroupField(
        value: value, fieldNumber: protobufExtension.fieldNumber)
    }
  }

  public var isInitialized: Bool {
    return Internal.areAllInitialized(value)
  }
}
