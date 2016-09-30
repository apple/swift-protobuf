// ProtobufRuntime/Sources/Protobuf/Google_Protobuf_Wrappers.swift - Well-known Wrapper types
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
/// This is a hand-built implementation of the well-known wrapper types.
/// It exploits a common generic protocol to reduce duplicated code.
///
// -----------------------------------------------------------------------------

import Swift

public protocol Google_Protobuf_Wrapper: ProtobufAbstractMessage, Hashable, CustomReflectable {
    associatedtype WrappedType: ProtobufTypeProperties
    var protoMessageName: String { get }
    var value: WrappedType.BaseType? { get set }
}

public extension Google_Protobuf_Wrapper {
    var protoPackageName: String {return "google.protobuf"}
    var swiftClassName: String {return "Google_Protobuf_" + protoMessageName}
    var jsonFieldNames: [String:Int] {return ["value":1]}
    var protoFieldNames: [String:Int] {return ["value":1]}

    public init(_ value: WrappedType.BaseType) {
        self.init()
        self.value = value
    }

    public mutating func decodeField(setter: inout ProtobufFieldDecoder, protoFieldNumber: Int) throws -> Bool {
        switch protoFieldNumber {
        case 1: return try setter.decodeOptionalField(fieldType: WrappedType.self, value: &value)
        default: return false
        }
    }

    public mutating func decodeField(setter: inout ProtobufFieldDecoder, protoFieldName: String) throws -> Bool {
        return try decodeField(setter: &setter, protoFieldNumber: 1)
    }

    public mutating func decodeField(setter: inout ProtobufFieldDecoder, jsonFieldName: String) throws -> Bool {
        return try decodeField(setter: &setter, protoFieldNumber: 1)
    }

    func serializeJSON() throws -> String {
        if let value = value {
            var encoder = ProtobufJSONEncoder()
            try WrappedType.serializeJSONValue(encoder: &encoder, value: value)
            return encoder.result
        } else {
            return "null"
        }
    }

    func serializeAnyJSON() throws -> String {
        let value = try serializeJSON()
        return "{\"@type\":\"\(anyTypeURL)\",\"value\":\(value)}"
    }

    public func traverse(visitor: inout ProtobufVisitor) throws {
        if let value = value {
            try visitor.visitSingularField(fieldType: WrappedType.self, value: value, protoFieldNumber: 1, protoFieldName: "value", jsonFieldName: "value", swiftFieldName: "value")
        }
    }
}

public extension Google_Protobuf_Wrapper where WrappedType.BaseType: Equatable {
    public func isEqualTo(other: Self) -> Bool {
        return value == other.value
    }
}

///   Wrapper message for `double`.
///
///   The JSON representation for `DoubleValue` is JSON number.
public struct Google_Protobuf_DoubleValue: Google_Protobuf_Wrapper, ExpressibleByFloatLiteral {
    public typealias WrappedType = ProtobufDouble
    public var protoMessageName: String {return "DoubleValue"}
    public var value: WrappedType.BaseType?
    public init() {}
    public typealias FloatLiteralType = Double
    public init(floatLiteral: FloatLiteralType) {value = floatLiteral}

    public mutating func decodeFromJSONToken(token: ProtobufJSONToken) throws {
        if let t = token.asDouble {
            value = t
        } else {
            throw ProtobufDecodingError.malformedJSONNumber
        }
    }
}

///   Wrapper message for `float`.
///
///   The JSON representation for `FloatValue` is JSON number.
public struct Google_Protobuf_FloatValue: Google_Protobuf_Wrapper, ExpressibleByFloatLiteral {
    public typealias WrappedType = ProtobufFloat
    public var protoMessageName: String {return "FloatValue"}
    public var value: WrappedType.BaseType?
    public init() {}
    public typealias FloatLiteralType = Float
    public init(floatLiteral: FloatLiteralType) {value = floatLiteral}

    public mutating func decodeFromJSONToken(token: ProtobufJSONToken) throws {
        if let t = token.asFloat {
            value = t
        } else {
            throw ProtobufDecodingError.malformedJSONNumber
        }
    }
}

///   Wrapper message for `int64`.
///
///   The JSON representation for `Int64Value` is JSON string.
public struct Google_Protobuf_Int64Value: Google_Protobuf_Wrapper {
    public typealias WrappedType = ProtobufInt64
    public var protoMessageName: String {return "Int64Value"}
    public var value: WrappedType.BaseType?
    public init() {}
    public mutating func decodeFromJSONToken(token: ProtobufJSONToken) throws {
        if let t = token.asInt64 {
            value = t
        } else {
            throw ProtobufDecodingError.malformedJSONNumber
        }
    }
}

///   Wrapper message for `uint64`.
///
///   The JSON representation for `UInt64Value` is JSON string.
public struct Google_Protobuf_UInt64Value: Google_Protobuf_Wrapper {
    public typealias WrappedType = ProtobufUInt64
    public var protoMessageName: String {return "UInt64Value"}
    public var value: WrappedType.BaseType?
    public init() {}
    public mutating func decodeFromJSONToken(token: ProtobufJSONToken) throws {
        if let t = token.asUInt64 {
            value = t
        } else {
            throw ProtobufDecodingError.malformedJSONNumber
        }
    }
}

///   Wrapper message for `int32`.
///
///   The JSON representation for `Int32Value` is JSON number.
public struct Google_Protobuf_Int32Value: Google_Protobuf_Wrapper {
    public typealias WrappedType = ProtobufInt32
    public var protoMessageName: String {return "Int32Value"}
    public var value: WrappedType.BaseType?
    public init() {}
    public mutating func decodeFromJSONToken(token: ProtobufJSONToken) throws {
        if let t = token.asInt32 {
            value = t
        } else {
            throw ProtobufDecodingError.malformedJSONNumber
        }
    }
}

///   Wrapper message for `uint32`.
///
///   The JSON representation for `UInt32Value` is JSON number.
public struct Google_Protobuf_UInt32Value: Google_Protobuf_Wrapper {
    public typealias WrappedType = ProtobufUInt32
    public var protoMessageName: String {return "UInt32Value"}
    public var value: WrappedType.BaseType?
    public init() {}
    public mutating func decodeFromJSONToken(token: ProtobufJSONToken) throws {
        if let t = token.asUInt32 {
            value = t
        } else {
            throw ProtobufDecodingError.malformedJSONNumber
        }
    }
}

///   Wrapper message for `bool`.
///
///   The JSON representation for `BoolValue` is JSON `true` and `false`.
public struct Google_Protobuf_BoolValue: Google_Protobuf_Wrapper, ExpressibleByBooleanLiteral {
    public typealias WrappedType = ProtobufBool
    public var protoMessageName: String {return "BoolValue"}
    public var value: WrappedType.BaseType?
    public init() {}
    public typealias BooleanLiteralType = Bool
    public init(booleanLiteral: Bool) {value = booleanLiteral}
    public mutating func decodeFromJSONToken(token: ProtobufJSONToken) throws {
        if let t = token.asBoolean {
            value = t
        } else {
            throw ProtobufDecodingError.schemaMismatch
        }
    }
}

///   Wrapper message for `string`.
///
///   The JSON representation for `StringValue` is JSON string.
public struct Google_Protobuf_StringValue: Google_Protobuf_Wrapper, ExpressibleByStringLiteral {
    public typealias WrappedType = ProtobufString
    public var protoMessageName: String {return "StringValue"}
    public var value: WrappedType.BaseType?
    public init() {}
    public typealias StringLiteralType = String
    public init(stringLiteral: String) {value = stringLiteral}
    public typealias ExtendedGraphemeClusterLiteralType = String
    public init(extendedGraphemeClusterLiteral: String) {value = extendedGraphemeClusterLiteral}
    public typealias UnicodeScalarLiteralType = String
    public init(unicodeScalarLiteral: String) {value = unicodeScalarLiteral}
    public mutating func decodeFromJSONToken(token: ProtobufJSONToken) throws {
        if case .string(let s) = token {
            value = s
        } else {
            throw ProtobufDecodingError.schemaMismatch
        }
    }
}

///   Wrapper message for `bytes`.
///
///   The JSON representation for `BytesValue` is JSON string.
public struct Google_Protobuf_BytesValue: Google_Protobuf_Wrapper {
    public typealias WrappedType = ProtobufBytes
    public var protoMessageName: String {return "BytesValue"}
    public var value: WrappedType.BaseType?
    public init() {}
    public mutating func decodeFromJSONToken(token: ProtobufJSONToken) throws {
        if let t = token.asBytes {
            value = t
        } else {
            throw ProtobufDecodingError.schemaMismatch
        }
    }
    public func isEqualTo(other: Google_Protobuf_BytesValue) -> Bool {
        if let l = value {
            if let r = other.value {
                return l == r
            }
            return l.isEmpty
        } else if let r = value {
            return r.isEmpty
        } else {
            return true
        }
    }
}
