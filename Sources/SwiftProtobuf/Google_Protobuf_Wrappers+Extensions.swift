// Sources/SwiftProtobuf/Google_Protobuf_Wrappers+Extensions.swift - Well-known wrapper type extensions
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Extensions to the well-known types in wrapper.proto that customize the JSON
/// format of those messages and provide convenience initializers from literals.
///
// -----------------------------------------------------------------------------

import Foundation

/// Internal protocol that minimizes the code duplication across the multiple
/// wrapper types extended below.
protocol ProtobufWrapper {

  /// The wrapped protobuf type (for example, `ProtobufDouble`).
  associatedtype WrappedType: FieldType

  /// Exposes the generated property to the extensions here.
  var value: WrappedType.BaseType { get set }

  /// Exposes the parameterless initializer to the extensions here.
  init()

  /// Creates a new instance of the wrapper with the given value.
  init(_ value: WrappedType.BaseType)

  /// Implements the JSON serialization logic for the wrapper types.
  ///
  /// We cannot have the `ProtobufWrapper` extension below implement
  /// `serializeJSON` because it is also implemented in extensions to other
  /// protocols. In other words, the compiler cannot disambiguate between them
  /// because both extension implementations have equal "weight". Instead, we
  /// have to override `serializeJSON` in the extensions to the generated
  /// concrete structs -- since the struct extension is more specific than the
  /// protocol extensions, it takes priority. In order to share the
  /// implementation, we have those extensions "hop" to this one.
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
    var encoder = JSONEncoder()
    try WrappedType.serializeJSONValue(encoder: &encoder, value: value)
    return encoder.result
  }
}

extension Google_Protobuf_DoubleValue:
  ProtobufWrapper, ExpressibleByFloatLiteral {

  public typealias WrappedType = ProtobufDouble
  public typealias FloatLiteralType = WrappedType.BaseType

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

  public mutating func setFromJSON(decoder: JSONDecoder) throws {
    var v: WrappedType.BaseType?
    try WrappedType.setFromJSON(decoder: decoder, value: &v)
    value = v ?? 0
  }
}

extension Google_Protobuf_FloatValue:
  ProtobufWrapper, ExpressibleByFloatLiteral {

  public typealias WrappedType = ProtobufFloat
  public typealias FloatLiteralType = Float

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

  public mutating func setFromJSON(decoder: JSONDecoder) throws {
    var v: WrappedType.BaseType?
    try WrappedType.setFromJSON(decoder: decoder, value: &v)
    value = v ?? 0
  }
}

extension Google_Protobuf_Int64Value:
  ProtobufWrapper, ExpressibleByIntegerLiteral {

  public typealias WrappedType = ProtobufInt64
  public typealias IntegerLiteralType = WrappedType.BaseType

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

    public mutating func setFromJSON(decoder: JSONDecoder) throws {
        var v: WrappedType.BaseType?
        try WrappedType.setFromJSON(decoder: decoder, value: &v)
        value = v ?? 0
    }
}

extension Google_Protobuf_UInt64Value:
  ProtobufWrapper, ExpressibleByIntegerLiteral {

  public typealias WrappedType = ProtobufUInt64
  public typealias IntegerLiteralType = WrappedType.BaseType

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

    public mutating func setFromJSON(decoder: JSONDecoder) throws {
        var v: WrappedType.BaseType?
        try WrappedType.setFromJSON(decoder: decoder, value: &v)
        value = v ?? 0
    }
}

extension Google_Protobuf_Int32Value:
  ProtobufWrapper, ExpressibleByIntegerLiteral {

  public typealias WrappedType = ProtobufInt32
  public typealias IntegerLiteralType = WrappedType.BaseType

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

    public mutating func setFromJSON(decoder: JSONDecoder) throws {
        var v: WrappedType.BaseType?
        try WrappedType.setFromJSON(decoder: decoder, value: &v)
        value = v ?? 0
    }
}

extension Google_Protobuf_UInt32Value:
  ProtobufWrapper, ExpressibleByIntegerLiteral {

  public typealias WrappedType = ProtobufUInt32
  public typealias IntegerLiteralType = WrappedType.BaseType

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

    public mutating func setFromJSON(decoder: JSONDecoder) throws {
        var v: WrappedType.BaseType?
        try WrappedType.setFromJSON(decoder: decoder, value: &v)
        value = v ?? 0
    }
}

extension Google_Protobuf_BoolValue:
  ProtobufWrapper, ExpressibleByBooleanLiteral {

  public typealias WrappedType = ProtobufBool
  public typealias BooleanLiteralType = Bool

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

    public mutating func setFromJSON(decoder: JSONDecoder) throws {
        var v: WrappedType.BaseType?
        try WrappedType.setFromJSON(decoder: decoder, value: &v)
        value = v ?? false
    }
}

extension Google_Protobuf_StringValue:
  ProtobufWrapper, ExpressibleByStringLiteral {

  public typealias WrappedType = ProtobufString
  public typealias StringLiteralType = String
  public typealias ExtendedGraphemeClusterLiteralType = String
  public typealias UnicodeScalarLiteralType = String

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

    public mutating func setFromJSON(decoder: JSONDecoder) throws {
        var v: WrappedType.BaseType?
        try WrappedType.setFromJSON(decoder: decoder, value: &v)
        value = v ?? ""
    }
}

extension Google_Protobuf_BytesValue: ProtobufWrapper {

  public typealias WrappedType = ProtobufBytes

  public init(_ value: WrappedType.BaseType) {
    self.init()
    self.value = value
  }

  public func serializeJSON() throws -> String {
    return try serializeWrapperJSON()
  }

    public mutating func setFromJSON(decoder: JSONDecoder) throws {
        var v: WrappedType.BaseType?
        try WrappedType.setFromJSON(decoder: decoder, value: &v)
        value = v ?? Data()
    }
}
