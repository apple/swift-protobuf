// Sources/SwiftProtobuf/Google_Protobuf_Wrappers+Extensions.swift - Well-known wrapper type extensions
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
//
// Extensions to the well-known types in wrapper.proto that customize the JSON
// format of those messages and provide convenience initializers from literals.
//
// -----------------------------------------------------------------------------

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Internal protocol that minimizes the code duplication across the multiple
/// wrapper types extended below.
protocol ProtobufWrapper {

    /// The wrapped protobuf type (for example, `ProtobufDouble`).
    associatedtype WrappedType: FieldType

    /// Exposes the generated property to the extensions here.
    var value: WrappedType.BaseType { get set }

    /// Exposes the parameterless initializer to the extensions here.
    init()

    /// Creates a new instance of the wrapper with the value you provide.
    init(_ value: WrappedType.BaseType)
}

extension ProtobufWrapper {
    mutating func decodeJSON(from decoder: inout JSONDecoder) throws {
        var v: WrappedType.BaseType?
        try WrappedType.decodeSingular(value: &v, from: &decoder)
        value = v ?? WrappedType.proto3DefaultValue
    }
}

extension Google_Protobuf_DoubleValue:
    ProtobufWrapper, ExpressibleByFloatLiteral, _CustomJSONCodable
{

    /// The protobuf field type that stores this wrapper's underlying value.
    public typealias WrappedType = ProtobufDouble

    /// The type Swift uses when creating this wrapper directly from a floating-point literal.
    public typealias FloatLiteralType = WrappedType.BaseType

    /// Creates a wrapper that holds the value you provide.
    public init(_ value: WrappedType.BaseType) {
        self.init()
        self.value = value
    }

    /// Creates a wrapper from a floating-point literal.
    public init(floatLiteral: FloatLiteralType) {
        self.init(floatLiteral)
    }

    func encodedJSONString(options: JSONEncodingOptions) throws -> String {
        if value.isFinite {
            // Swift 4.2 and later guarantees that this is accurate
            // enough to parse back to the exact value on the other end.
            return value.description
        } else {
            // Protobuf-specific handling of NaN and infinities
            var encoder = JSONEncoder()
            encoder.putDoubleValue(value: value)
            return encoder.stringResult
        }
    }
}

extension Google_Protobuf_FloatValue:
    ProtobufWrapper, ExpressibleByFloatLiteral, _CustomJSONCodable
{

    /// The protobuf field type that stores this wrapper's underlying value.
    public typealias WrappedType = ProtobufFloat

    /// The type Swift uses when creating this wrapper directly from a floating-point literal.
    public typealias FloatLiteralType = Float

    /// Creates a wrapper that holds the value you provide.
    public init(_ value: WrappedType.BaseType) {
        self.init()
        self.value = value
    }

    /// Creates a wrapper from a floating-point literal.
    public init(floatLiteral: FloatLiteralType) {
        self.init(floatLiteral)
    }

    func encodedJSONString(options: JSONEncodingOptions) throws -> String {
        if value.isFinite {
            // Swift 4.2 and later guarantees that this is accurate
            // enough to parse back to the exact value on the other end.
            return value.description
        } else {
            // Protobuf-specific handling of NaN and infinities
            var encoder = JSONEncoder()
            encoder.putFloatValue(value: value)
            return encoder.stringResult
        }
    }
}

extension Google_Protobuf_Int64Value:
    ProtobufWrapper, ExpressibleByIntegerLiteral, _CustomJSONCodable
{

    /// The protobuf field type that stores this wrapper's underlying value.
    public typealias WrappedType = ProtobufInt64

    /// The type Swift uses when creating this wrapper directly from an integer literal.
    public typealias IntegerLiteralType = WrappedType.BaseType

    /// Creates a wrapper that holds the value you provide.
    public init(_ value: WrappedType.BaseType) {
        self.init()
        self.value = value
    }

    /// Creates a wrapper from an integer literal.
    public init(integerLiteral: IntegerLiteralType) {
        self.init(integerLiteral)
    }

    func encodedJSONString(options: JSONEncodingOptions) throws -> String {
        var encoded = value.description
        if !options.alwaysPrintInt64sAsNumbers {
            encoded = "\"" + encoded + "\""
        }
        return encoded
    }
}

extension Google_Protobuf_UInt64Value:
    ProtobufWrapper, ExpressibleByIntegerLiteral, _CustomJSONCodable
{

    /// The protobuf field type that stores this wrapper's underlying value.
    public typealias WrappedType = ProtobufUInt64

    /// The type Swift uses when creating this wrapper directly from an integer literal.
    public typealias IntegerLiteralType = WrappedType.BaseType

    /// Creates a wrapper that holds the value you provide.
    public init(_ value: WrappedType.BaseType) {
        self.init()
        self.value = value
    }

    /// Creates a wrapper from an integer literal.
    public init(integerLiteral: IntegerLiteralType) {
        self.init(integerLiteral)
    }

    func encodedJSONString(options: JSONEncodingOptions) throws -> String {
        var encoded = String(value)
        if !options.alwaysPrintInt64sAsNumbers {
            encoded = "\"" + encoded + "\""
        }
        return encoded
    }
}

extension Google_Protobuf_Int32Value:
    ProtobufWrapper, ExpressibleByIntegerLiteral, _CustomJSONCodable
{

    /// The protobuf field type that stores this wrapper's underlying value.
    public typealias WrappedType = ProtobufInt32

    /// The type Swift uses when creating this wrapper directly from an integer literal.
    public typealias IntegerLiteralType = WrappedType.BaseType

    /// Creates a wrapper that holds the value you provide.
    public init(_ value: WrappedType.BaseType) {
        self.init()
        self.value = value
    }

    /// Creates a wrapper from an integer literal.
    public init(integerLiteral: IntegerLiteralType) {
        self.init(integerLiteral)
    }

    func encodedJSONString(options: JSONEncodingOptions) throws -> String {
        String(value)
    }
}

extension Google_Protobuf_UInt32Value:
    ProtobufWrapper, ExpressibleByIntegerLiteral, _CustomJSONCodable
{

    /// The protobuf field type that stores this wrapper's underlying value.
    public typealias WrappedType = ProtobufUInt32

    /// The type Swift uses when creating this wrapper directly from an integer literal.
    public typealias IntegerLiteralType = WrappedType.BaseType

    /// Creates a wrapper that holds the value you provide.
    public init(_ value: WrappedType.BaseType) {
        self.init()
        self.value = value
    }

    /// Creates a wrapper from an integer literal.
    public init(integerLiteral: IntegerLiteralType) {
        self.init(integerLiteral)
    }

    func encodedJSONString(options: JSONEncodingOptions) throws -> String {
        String(value)
    }
}

extension Google_Protobuf_BoolValue:
    ProtobufWrapper, ExpressibleByBooleanLiteral, _CustomJSONCodable
{

    /// The protobuf field type that stores this wrapper's underlying value.
    public typealias WrappedType = ProtobufBool

    /// The type Swift uses when creating this wrapper directly from a Boolean literal.
    public typealias BooleanLiteralType = Bool

    /// Creates a wrapper that holds the value you provide.
    public init(_ value: WrappedType.BaseType) {
        self.init()
        self.value = value
    }

    /// Creates a wrapper from a Boolean literal.
    public init(booleanLiteral: Bool) {
        self.init(booleanLiteral)
    }

    func encodedJSONString(options: JSONEncodingOptions) throws -> String {
        value ? "true" : "false"
    }
}

extension Google_Protobuf_StringValue:
    ProtobufWrapper, ExpressibleByStringLiteral, _CustomJSONCodable
{

    /// The protobuf field type that stores this wrapper's underlying value.
    public typealias WrappedType = ProtobufString

    /// The type Swift uses when creating this wrapper directly from a string literal.
    public typealias StringLiteralType = String

    /// The type Swift uses when creating this wrapper from a single extended grapheme cluster.
    public typealias ExtendedGraphemeClusterLiteralType = String

    /// The type Swift uses when creating this wrapper from a single Unicode scalar.
    public typealias UnicodeScalarLiteralType = String

    /// Creates a wrapper that holds the value you provide.
    public init(_ value: WrappedType.BaseType) {
        self.init()
        self.value = value
    }

    /// Creates a wrapper from a string literal.
    public init(stringLiteral: String) {
        self.init(stringLiteral)
    }

    /// Creates a wrapper from a single extended grapheme cluster literal.
    public init(extendedGraphemeClusterLiteral: String) {
        self.init(extendedGraphemeClusterLiteral)
    }

    /// Creates a wrapper from a single Unicode scalar literal.
    public init(unicodeScalarLiteral: String) {
        self.init(unicodeScalarLiteral)
    }

    func encodedJSONString(options: JSONEncodingOptions) throws -> String {
        var encoder = JSONEncoder()
        encoder.putStringValue(value: value)
        return encoder.stringResult
    }
}

extension Google_Protobuf_BytesValue: ProtobufWrapper, _CustomJSONCodable {

    /// The protobuf field type that stores this wrapper's underlying value.
    public typealias WrappedType = ProtobufBytes

    /// Creates a wrapper that holds the value you provide.
    public init(_ value: WrappedType.BaseType) {
        self.init()
        self.value = value
    }

    func encodedJSONString(options: JSONEncodingOptions) throws -> String {
        var encoder = JSONEncoder()
        encoder.putBytesValue(value: value)
        return encoder.stringResult
    }
}
