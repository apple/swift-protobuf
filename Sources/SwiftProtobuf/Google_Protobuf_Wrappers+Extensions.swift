// Sources/SwiftProtobuf/Google_Protobuf_Wrappers+Extensions.swift - Well-known wrapper type extensions
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
/// Extensions to the well-known types in wrapper.proto that customize the JSON
/// format of those messages and provide convenience initializers from literals.
///
// -----------------------------------------------------------------------------


/// Internal protocol that minimizes the code duplication across the multiple
/// wrapper types extended below.
protocol ProtobufWrapper {

  /// The wrapped protobuf type (for example, `ProtobufDouble`).
  associatedtype WrappedType: FieldType

  /// Exposes the generated property to the extensions here.
  var value: WrappedType.BaseType { get set }

  /// Returns true if the given value is the zero or empty value for the wrapped
  /// type.
  ///
  /// TODO(#64): This currently exists to duplicate the current behavior of the
  /// old hand-generated types. If these should be serialized as zero/empty
  /// instead of null, remove this.
  var isZeroOrEmpty: Bool { get }

  /// Exposes the parameterless initializer to the extensions here.
  init()

  /// Creates a new instance of the wrapper with the given value.
  init(_ value: WrappedType.BaseType)

  /// Implements the JSON serialization logic for the wrapper types.
  ///
  /// We cannot have the `ProtobufWrapper` extension below implement this method
  /// because it is also implemented in extensions to other protocols. In other
  /// words, the compiler cannot disambiguate between them because both are
  /// equally valid. Instead, we have to override `serializeJSON` in the
  /// extensions to the generated concrete structs -- since the struct extension
  /// is more specific than the protocol extensions, it takes priority. In order
  /// to share the implementation, we have those extensions "hop" to this one.
  func serializeWrapperJSON() throws -> String
}

extension ProtobufWrapper {
  // NOTE: The `init(_ value: WrappedType.BaseType)` initializer repeated below
  // should theoretically be able to go here and be declared public, but this
  // causes linker errors in release builds (see issue #70). If this is indeed a
  // bug and should be allowed, we should move the initializer back into this
  // extension once it's fixed, to reduce a small amount of code duplication/
  // bloat.

  func serializeWrapperJSON() throws -> String {
    if !isZeroOrEmpty {
      var encoder = JSONEncoder()
      try WrappedType.serializeJSONValue(encoder: &encoder, value: value)
      return encoder.result
    } else {
      return "null"
    }
  }
}

extension Google_Protobuf_DoubleValue:
  ProtobufWrapper, ExpressibleByFloatLiteral {

  public typealias WrappedType = ProtobufDouble
  public typealias FloatLiteralType = WrappedType.BaseType

  var isZeroOrEmpty: Bool {
    return value == 0
  }

  public init(_ value: WrappedType.BaseType) {
    self.init()
    self.value = value
  }

  public init(floatLiteral: FloatLiteralType) {
    self.init(floatLiteral)
  }

  public func serializeJSON() throws -> String {
    return try serializeWrapperJSON()
  }

  public mutating func decodeFromJSONToken(token: JSONToken) throws {
    if let t = token.asDouble {
        value = t
    } else {
        throw DecodingError.malformedJSONNumber
    }
  }
}

extension Google_Protobuf_FloatValue:
  ProtobufWrapper, ExpressibleByFloatLiteral {

  public typealias WrappedType = ProtobufFloat
  public typealias FloatLiteralType = Float

  var isZeroOrEmpty: Bool {
    return value.isZero
  }

  public init(_ value: WrappedType.BaseType) {
    self.init()
    self.value = value
  }

  public init(floatLiteral: FloatLiteralType) {
    self.init(floatLiteral)
  }

  public func serializeJSON() throws -> String {
    return try serializeWrapperJSON()
  }

  public mutating func decodeFromJSONToken(token: JSONToken) throws {
    if let t = token.asFloat {
      value = t
    } else {
      throw DecodingError.malformedJSONNumber
    }
  }
}

extension Google_Protobuf_Int64Value:
  ProtobufWrapper, ExpressibleByIntegerLiteral {

  public typealias WrappedType = ProtobufInt64
  public typealias IntegerLiteralType = WrappedType.BaseType

  var isZeroOrEmpty: Bool {
    return value == 0
  }

  public init(_ value: WrappedType.BaseType) {
    self.init()
    self.value = value
  }

  public init(integerLiteral: IntegerLiteralType) {
    self.init(integerLiteral)
  }

  public func serializeJSON() throws -> String {
    return try serializeWrapperJSON()
  }

  public mutating func decodeFromJSONToken(token: JSONToken) throws {
    if let t = token.asInt64 {
      value = t
    } else {
      throw DecodingError.malformedJSONNumber
    }
  }
}

extension Google_Protobuf_UInt64Value:
  ProtobufWrapper, ExpressibleByIntegerLiteral {

  public typealias WrappedType = ProtobufUInt64
  public typealias IntegerLiteralType = WrappedType.BaseType

  var isZeroOrEmpty: Bool {
    return value == 0
  }

  public init(_ value: WrappedType.BaseType) {
    self.init()
    self.value = value
  }

  public init(integerLiteral: IntegerLiteralType) {
    self.init(integerLiteral)
  }

  public func serializeJSON() throws -> String {
    return try serializeWrapperJSON()
  }

  public mutating func decodeFromJSONToken(token: JSONToken) throws {
    if let t = token.asUInt64 {
      value = t
    } else {
      throw DecodingError.malformedJSONNumber
    }
  }
}

extension Google_Protobuf_Int32Value:
  ProtobufWrapper, ExpressibleByIntegerLiteral {

  public typealias WrappedType = ProtobufInt32
  public typealias IntegerLiteralType = WrappedType.BaseType

  var isZeroOrEmpty: Bool {
    return value == 0
  }

  public init(_ value: WrappedType.BaseType) {
    self.init()
    self.value = value
  }

  public init(integerLiteral: IntegerLiteralType) {
    self.init(integerLiteral)
  }

  public func serializeJSON() throws -> String {
    return try serializeWrapperJSON()
  }

  public mutating func decodeFromJSONToken(token: JSONToken) throws {
    if let t = token.asInt32 {
      value = t
    } else {
      throw DecodingError.malformedJSONNumber
    }
  }
}

extension Google_Protobuf_UInt32Value:
  ProtobufWrapper, ExpressibleByIntegerLiteral {

  public typealias WrappedType = ProtobufUInt32
  public typealias IntegerLiteralType = WrappedType.BaseType

  var isZeroOrEmpty: Bool {
    return value == 0
  }

  public init(_ value: WrappedType.BaseType) {
    self.init()
    self.value = value
  }

  public init(integerLiteral: IntegerLiteralType) {
    self.init(integerLiteral)
  }

  public func serializeJSON() throws -> String {
    return try serializeWrapperJSON()
  }

  public mutating func decodeFromJSONToken(token: JSONToken) throws {
    if let t = token.asUInt32 {
      value = t
    } else {
      throw DecodingError.malformedJSONNumber
    }
  }
}

extension Google_Protobuf_BoolValue:
  ProtobufWrapper, ExpressibleByBooleanLiteral {

  public typealias WrappedType = ProtobufBool
  public typealias BooleanLiteralType = Bool

  var isZeroOrEmpty: Bool {
    return !value
  }

  public init(_ value: WrappedType.BaseType) {
    self.init()
    self.value = value
  }

  public init(booleanLiteral: Bool) {
    self.init(booleanLiteral)
  }

  public func serializeJSON() throws -> String {
    return try serializeWrapperJSON()
  }

  public mutating func decodeFromJSONToken(token: JSONToken) throws {
    if let t = token.asBoolean {
      value = t
    } else {
      throw DecodingError.schemaMismatch
    }
  }
}

extension Google_Protobuf_StringValue:
  ProtobufWrapper, ExpressibleByStringLiteral {

  public typealias WrappedType = ProtobufString
  public typealias StringLiteralType = String
  public typealias ExtendedGraphemeClusterLiteralType = String
  public typealias UnicodeScalarLiteralType = String

  var isZeroOrEmpty: Bool {
    return value.isEmpty
  }

  public init(_ value: WrappedType.BaseType) {
    self.init()
    self.value = value
  }

  public init(stringLiteral: String) {
    self.init(stringLiteral)
  }

  public init(extendedGraphemeClusterLiteral: String) {
    self.init(extendedGraphemeClusterLiteral)
  }

  public init(unicodeScalarLiteral: String) {
    self.init(unicodeScalarLiteral)
  }

  public func serializeJSON() throws -> String {
    return try serializeWrapperJSON()
  }

  public mutating func decodeFromJSONToken(token: JSONToken) throws {
    if case .string(let s) = token {
      value = s
    } else {
      throw DecodingError.schemaMismatch
    }
  }
}

extension Google_Protobuf_BytesValue: ProtobufWrapper {

  public typealias WrappedType = ProtobufBytes

  var isZeroOrEmpty: Bool {
    return value.isEmpty
  }

  public init(_ value: WrappedType.BaseType) {
    self.init()
    self.value = value
  }

  public func serializeJSON() throws -> String {
    return try serializeWrapperJSON()
  }

  public mutating func decodeFromJSONToken(token: JSONToken) throws {
    if let t = token.asBytes {
      value = t
    } else {
      throw DecodingError.schemaMismatch
    }
  }
}
