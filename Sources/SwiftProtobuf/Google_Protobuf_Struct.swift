// Sources/SwiftProtobuf/Google_Protobuf_Struct.swift - Well-known Struct types.
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Struct, Value, ListValue are well-known message types that can be used
/// to parse or encode arbitrary JSON without a predefined schema.
///
// -----------------------------------------------------------------------------

import Swift

/*
 * Hand-built implementation.
 */

public enum Google_Protobuf_NullValue: Enum {
    // TODO: This is awkward, see the references to .NullValue(.NullValue) below.
    // TODO: The .nullValue property on Google_Protobuf_Value has to have
    // a type; but this is a little weird.
    public typealias RawValue = Int
    ///   Null value.
    case nullValue

    public init?(rawValue: Int) {self = .nullValue}
    public init?(name: String) {self = .nullValue}
    public init?(jsonName: String) {self = .nullValue}
    public init?(protoName: String) {self = .nullValue}
    public init() {self = .nullValue}
    public var rawValue: Int {return 0}
    public var json: String {return "null"}
    public var hashValue: Int {return 0}
    public var debugDescription: String {return "NullValue"}
}

///   `Struct` represents a structured data value, consisting of fields
///   which map to dynamically typed values. In some languages, `Struct`
///   might be supported by a native representation. For example, in
///   scripting languages like JS a struct is represented as an
///   object. The details of that representation are described together
///   with the proto support for the language.
///
///   The JSON representation for `Struct` is JSON object.

// Should Google_Protobuf_Struct be a synonym for [String: Any]?
// TODO: Implement CollectionType
public struct Google_Protobuf_Struct: Message, Proto3Message, _MessageImplementationBase, ExpressibleByDictionaryLiteral, ProtoNameProviding {
    public var swiftClassName: String {return "Google_Protobuf_Struct"}
    public var protoMessageName: String {return "Struct"}
    public var protoPackageName: String {return "google.protobuf"}
    public static let _protobuf_fieldNames: FieldNameMap = [
        1: .same(proto: "fields", swift: "fields"),
    ]
    public typealias Key = String
    public typealias Value = Google_Protobuf_Value

    ///   Unordered map of dynamically typed values.
    public var fields: Dictionary<String,Google_Protobuf_Value> = [:]

    public init() {}

    public init(fields: [String: Google_Protobuf_Value]) {
        self.fields = fields
    }
    
    public init(dictionaryLiteral: (String, Google_Protobuf_Value)...) {
        fields = [:]
        for (k,v) in dictionaryLiteral {
            fields[k] = v
        }
    }
    
    public subscript(index: String) -> Google_Protobuf_Value? {
        get {return fields[index]}
        set(newValue) {fields[index] = newValue}
    }

    public mutating func setFromJSON(decoder: JSONDecoder) throws {
        if try decoder.skipOptionalNull() {
            return
        }
        if try decoder.isObjectEmpty() {
            return
        }
        while true {
            let key = try decoder.nextKey()
            var value = Google_Protobuf_Value()
            try value.setFromJSON(decoder: decoder)
            fields[key] = value
            if let token = try decoder.nextToken() {
                switch token {
                case .comma:
                    break
                case .endObject:
                    return
                default:
                    throw DecodingError.malformedJSON
                }
            }
        }
    }

    public func serializeJSON() throws -> String {
        var jsonEncoder = JSONEncoder()
        jsonEncoder.startObject()
        for (k,v) in fields {
            jsonEncoder.startField(name: k)
            try v.serializeJSONValue(jsonEncoder: &jsonEncoder)
        }
        jsonEncoder.endObject()
        return jsonEncoder.result
    }

    public func serializeAnyJSON() throws -> String {
        let value = try serializeJSON()
        return "{\"@type\":\"\(anyTypeURL)\",\"value\":\(value)}"
    }

    public mutating func _protoc_generated_decodeField<T: FieldDecoder>(setter: inout T, protoFieldNumber: Int) throws {
        switch protoFieldNumber {
        case 1: try setter.decodeMapField(fieldType: ProtobufMap<ProtobufString,Google_Protobuf_Value>.self, value: &fields)
        default:
            break
        }
    }

    public func _protoc_generated_traverse(visitor: Visitor) throws {
        if !fields.isEmpty {
            try visitor.visitMapField(fieldType: ProtobufMap<ProtobufString,Google_Protobuf_Value>.self, value: fields, fieldNumber: 1)
        }
    }

    public  func _protoc_generated_isEqualTo(other: Google_Protobuf_Struct) -> Bool {
        if fields != other.fields {return false}
        return true
    }
}

///   `Value` represents a dynamically typed value which can be either
///   null, a number, a string, a boolean, a recursive struct value, or a
///   list of values. A producer of value is expected to set one of that
///   variants, absence of any variant indicates an error.
///
///   The JSON representation for `Value` is JSON value.
public struct Google_Protobuf_Value: Message, Proto3Message, _MessageImplementationBase, ExpressibleByIntegerLiteral, ExpressibleByFloatLiteral, ExpressibleByStringLiteral, ExpressibleByBooleanLiteral, ExpressibleByNilLiteral, ProtoNameProviding {
    public var swiftClassName: String {return "Google_Protobuf_Value"}
    public var protoMessageName: String {return "Value"}
    public var protoPackageName: String {return "google.protobuf"}
    public static let _protobuf_fieldNames: FieldNameMap = [
        1: .unique(proto: "null_value", json: "nullValue", swift: "nullValue"),
        2: .unique(proto: "number_value", json: "numberValue", swift: "numberValue"),
        3: .unique(proto: "string_value", json: "stringValue", swift: "stringValue"),
        4: .unique(proto: "bool_value", json: "boolValue", swift: "boolValue"),
        5: .unique(proto: "struct_value", json: "structValue", swift: "structValue"),
        6: .unique(proto: "list_value", json: "listValue", swift: "listValue"),
    ]

    // TODO: Would it make sense to collapse the implementation here and
    // make Google_Protobuf_Value be the enum directly?
    public typealias FloatLiteralType = Double
    public typealias IntegerLiteralType = Int64
    public typealias StringLiteralType = String
    public typealias ExtendedGraphemeClusterLiteralType = String
    public typealias UnicodeScalarLiteralType = String
    public typealias BooleanLiteralType = Bool

    public init() {
        kind = .nullValue(.nullValue)
    }

    public init(nullValue: ()) {
        kind = .nullValue(.nullValue)
    }
    public init(nilLiteral: ()) {
        kind = .nullValue(.nullValue)
    }

    public init(numberValue: Double) {
        kind = .numberValue(numberValue)
    }
    public init(integerLiteral value: Int64) {
        kind = .numberValue(Double(value))
    }
    public init(floatLiteral value: Double) {
        kind = .numberValue(value)
    }

    public init(stringValue: String) {
        kind = .stringValue(stringValue)
    }
    public init(stringLiteral value: String) {
        kind = .stringValue(value)
    }
    public init(unicodeScalarLiteral value: String) {
        kind = .stringValue(value)
    }
    public init(extendedGraphemeClusterLiteral value: String) {
        kind = .stringValue(value)
    }

    public init(boolValue: Bool) {
        kind = .boolValue(boolValue)
    }
    public init(booleanLiteral value: Bool) {
        kind = .boolValue(value)
    }

    public init(structValue: Google_Protobuf_Struct) {
        kind = .structValue(structValue)
    }

    public init(listValue: Google_Protobuf_ListValue) {
        kind = .listValue(listValue)
    }

    public init<T>(array: [T]) {
        let anyList = array.map {$0 as Any}
        kind = .listValue(Google_Protobuf_ListValue(any: anyList))
    }

    public init(anyArray: [Any]) {
        kind = .listValue(Google_Protobuf_ListValue(any: anyArray))
    }

    public init(any: Any) {
        switch any {
        case let i as Int:
            self.init(numberValue: Double(i))
        case let d as Double:
            self.init(numberValue: d)
        case let f as Float:
            self.init(numberValue: Double(f))
        case let b as Bool:
            self.init(boolValue: b)
        case let s as String:
            self.init(stringValue: s)
        default:
            self.init()
        }
    }

    mutating public func _protoc_generated_decodeField<T: FieldDecoder>(setter: inout T, protoFieldNumber: Int) throws {
        switch protoFieldNumber {
        case 1, 2, 3, 4, 5, 6:
            try kind.decodeField(setter: &setter, protoFieldNumber: protoFieldNumber)
        default: break
        }
    }
    
    public mutating func setFromJSON(decoder: JSONDecoder) throws {
        if let token = try decoder.nextToken() {
            switch token {
            case .null:
                kind = .nullValue(.nullValue)
                return
            case .beginObject:
                decoder.pushback(token: token)
                var s = Google_Protobuf_Struct()
                try s.setFromJSON(decoder: decoder)
                kind = .structValue(s)
                return
            case .beginArray:
                decoder.pushback(token: token)
                var l = Google_Protobuf_ListValue()
                try l.setFromJSON(decoder: decoder)
                kind = .listValue(l)
                return
            case .boolean(let b):
                kind = .boolValue(b)
                return
            case .string(let s):
                kind = .stringValue(s)
                return
            case .number(_):
                if let n = token.asDouble {
                    kind = .numberValue(n)
                    return
                }
            default:
                break
            }
        }
        throw DecodingError.malformedJSON
    }

    public func serializeJSON() throws -> String {
        var jsonEncoder = JSONEncoder()
        try serializeJSONValue(jsonEncoder: &jsonEncoder)
        return jsonEncoder.result
    }

    public func serializeAnyJSON() throws -> String {
        let value = try serializeJSON()
        return "{\"@type\":\"\(anyTypeURL)\",\"value\":\(value)}"
    }

    fileprivate func serializeJSONValue(jsonEncoder: inout JSONEncoder) throws {
        try kind.serializeJSONField(encoder: &jsonEncoder)
    }

    public func _protoc_generated_isEqualTo(other: Google_Protobuf_Value) -> Bool {
        return kind == other.kind
    }

    public init(any: Google_Protobuf_Any) throws {
        try any.unpackTo(target: &self)
    }

    public var debugDescription: String {
        get {
            do {
                let json = try serializeJSON()
                switch kind {
                case .nullValue(_): return "\(swiftClassName)(null)"
                case .numberValue(_): return "\(swiftClassName)(numberValue:\(json))"
                case .stringValue(_): return"\(swiftClassName)(stringValue:\(json))"
                case .boolValue(_): return"\(swiftClassName)(boolValue:\(json))"
                case .structValue(_): return"\(swiftClassName)(structValue:\(json))"
                case .listValue(_): return"\(swiftClassName)(listValue:\(json))"
                case .None: return "\(swiftClassName)()"
                }
            } catch let e {
                return "\(swiftClassName)(FAILURE: \(e))"
            }
        }
    }

    public func _protoc_generated_traverse(visitor: Visitor) throws {
        try kind.traverse(visitor: visitor, start:1, end: 7)
    }

    // Storage ivars
    private var kind = Google_Protobuf_Value.OneOf_Kind()

    ///   Represents a null value.
    public var nullValue: Google_Protobuf_NullValue? {
        get {
            if case .nullValue(let v) = kind {
                return v
            }
            return nil
        }
        set {
            if let newValue = newValue {
                kind = .nullValue(newValue)
            } else {
                kind = .None
            }
        }
    }

    ///   Represents a double value.
    public var numberValue: Double? {
        get {
            if case .numberValue(let v) = kind {
                return v
            }
            return nil
        }
        set {
            if let newValue = newValue {
                kind = .numberValue(newValue)
            } else {
                kind = .None
            }
        }
    }

    ///   Represents a string value.
    public var stringValue: String? {
        get {
            if case .stringValue(let v) = kind {
                return v
            }
            return nil
        }
        set {
            if let newValue = newValue {
                kind = .stringValue(newValue)
            } else {
                kind = .None
            }
        }
    }

    ///   Represents a boolean value.
    public var boolValue: Bool? {
        get {
            if case .boolValue(let v) = kind {
                return v
            }
            return nil
        }
        set {
            if let newValue = newValue {
                kind = .boolValue(newValue)
            } else {
                kind = .None
            }
        }
    }

    ///   Represents a structured value.
    public var structValue: Google_Protobuf_Struct? {
        get {
            if case .structValue(let v) = kind {
                return v
            }
            return nil
        }
        set {
            if let newValue = newValue {
                kind = .structValue(newValue)
            } else {
                kind = .None
            }
        }
    }

    ///   Represents a repeated `Value`.
    public var listValue: Google_Protobuf_ListValue? {
        get {
            if case .listValue(let v) = kind {
                return v
            }
            return nil
        }
        set {
            if let newValue = newValue {
                kind = .listValue(newValue)
            } else {
                kind = .None
            }
        }
    }

    public enum OneOf_Kind: ExpressibleByNilLiteral, OneofEnum {
        case nullValue(Google_Protobuf_NullValue)
        case numberValue(Double)
        case stringValue(String)
        case boolValue(Bool)
        case structValue(Google_Protobuf_Struct)
        case listValue(Google_Protobuf_ListValue)
        case None

        public init(nilLiteral: ()) {
            self = .None
        }

        public init() {
            self = .None
        }

        public mutating func decodeField<T: FieldDecoder>(setter: inout T, protoFieldNumber: Int) throws {
            switch protoFieldNumber {
            case 1:
                var value: Google_Protobuf_NullValue?
                try setter.decodeSingularField(fieldType: Google_Protobuf_NullValue.self, value: &value)
                if let value = value {
                    self = .nullValue(value)
                }
            case 2:
                var value: Double?
                try setter.decodeSingularField(fieldType: ProtobufDouble.self, value: &value)
                if let value = value {
                    self = .numberValue(value)
                }
            case 3:
                var value: String?
                try setter.decodeSingularField(fieldType: ProtobufString.self, value: &value)
                if let value = value {
                    self = .stringValue(value)
                }
            case 4:
                var value: Bool?
                try setter.decodeSingularField(fieldType: ProtobufBool.self, value: &value)
                if let value = value {
                    self = .boolValue(value)
                }
            case 5:
                var value: Google_Protobuf_Struct?
                try setter.decodeSingularMessageField(fieldType: Google_Protobuf_Struct.self, value: &value)
                if let value = value {
                    self = .structValue(value)
                }
            case 6:
                var value: Google_Protobuf_ListValue?
                try setter.decodeSingularMessageField(fieldType: Google_Protobuf_ListValue.self, value: &value)
                if let value = value {
                    self = .listValue(value)
                }
            default:
                throw DecodingError.schemaMismatch
            }
        }

        fileprivate func serializeJSONField(encoder: inout JSONEncoder) throws {
            switch self {
            case .nullValue(_): encoder.putNullValue()
            case .numberValue(let v): encoder.putDoubleValue(value: v, quote: false)
            case .stringValue(let v): encoder.putStringValue(value: v)
            case .boolValue(let v): encoder.putBoolValue(value: v, quote: false)
            case .structValue(let v): encoder.append(text: try v.serializeJSON())
            case .listValue(let v): encoder.append(text: try v.serializeJSON())
            case .None:
                break
            }
        }

        public mutating func decodeFromJSONToken(token: JSONToken) throws {
            switch token {
            case .null:
                self = .nullValue(.nullValue)
            case .number(_):
                if let value = token.asDouble {
                    self = .numberValue(value)
                } else {
                    throw DecodingError.malformedJSONNumber
                }
            case .string(let s):
                self = .stringValue(s)
            case .boolean(let b):
                self = .boolValue(b)
            default:
                throw DecodingError.schemaMismatch
            }
        }

        public func traverse(visitor: Visitor, start: Int, end: Int) throws {
            switch self {
            case .nullValue(let v):
                if start <= 1 && 1 < end {
                    try visitor.visitSingularField(fieldType: Google_Protobuf_NullValue.self, value: v, fieldNumber: 1)
                }
            case .numberValue(let v):
                if start <= 2 && 2 < end {
                    try visitor.visitSingularField(fieldType: ProtobufDouble.self, value: v, fieldNumber: 2)
                }
            case .stringValue(let v):
                if start <= 3 && 3 < end {
                    try visitor.visitSingularField(fieldType: ProtobufString.self, value: v, fieldNumber: 3)
                }
            case .boolValue(let v):
                if start <= 4 && 4 < end {
                    try visitor.visitSingularField(fieldType: ProtobufBool.self, value: v, fieldNumber: 4)
                }
            case .structValue(let v):
                if start <= 5 && 5 < end {
                    try visitor.visitSingularMessageField(value: v, fieldNumber: 5)
                }
            case .listValue(let v):
                if start <= 6 && 6 < end {
                    try visitor.visitSingularMessageField(value: v, fieldNumber: 6)
                }
            case .None:
                break
            }
        }

        public var hashValue: Int {
            switch self {
            case .nullValue(_): return 1
            case .numberValue(let v): return v.hashValue
            case .stringValue(let v): return v.hashValue
            case .boolValue(let v): return v.hashValue
            case .structValue(let v): return v.hashValue
            case .listValue(let v): return v.hashValue
            case .None: return 0
            }
        }
    }
}

///   `ListValue` is a wrapper around a repeated field of values.
///
///   The JSON representation for `ListValue` is JSON array.
public struct Google_Protobuf_ListValue: Message, Proto3Message, _MessageImplementationBase, ExpressibleByArrayLiteral, ProtoNameProviding {
    public var swiftClassName: String {return "Google_Protobuf_ListValue"}
    public var protoMessageName: String {return "ListValue"}
    public var protoPackageName: String {return "google.protobuf"}
    public static let _protobuf_fieldNames: FieldNameMap = [
        1: .same(proto: "values", swift: "values"),
    ]

    // TODO: Give this a direct array interface by proxying the interesting
    // bits down to values
    public typealias Element = Google_Protobuf_Value

    ///   Repeated field of dynamically typed values.
    public var values: [Google_Protobuf_Value] = []

    public init() {}

    public init(values: [Google_Protobuf_Value]) {
        self.values = values
    }

    public init(arrayLiteral elements: Google_Protobuf_ListValue.Element...) {
        values = elements
    }

    public init(any: [Any]) {
        values = any.map {Google_Protobuf_Value(any: $0)}
    }

    public subscript(index: Int) -> Google_Protobuf_Value {
        get {return values[index]}
        set(newValue) {values[index] = newValue}
    }

    public func serializeJSON() throws -> String {
        var jsonEncoder = JSONEncoder()
        jsonEncoder.append(text: "[")
        var separator = ""
        for v in values {
            jsonEncoder.append(text: separator)
            try v.serializeJSONValue(jsonEncoder: &jsonEncoder)
            separator = ","
        }
        jsonEncoder.append(text: "]")
        return jsonEncoder.result
    }
    
    public mutating func setFromJSON(decoder: JSONDecoder) throws {
        if try decoder.skipOptionalNull() {
            return
        }
        try decoder.skipRequired(token: .beginArray)
        if try decoder.skipOptional(token: .endArray) {
            return
        }
        while true {
            var v = Google_Protobuf_Value()
            try v.setFromJSON(decoder: decoder)
            values.append(v)
            if let token = try decoder.nextToken() {
                switch token {
                case .comma:
                    break
                case .endArray:
                    return
                default:
                    throw DecodingError.malformedJSON
                }
            } else {
                throw DecodingError.malformedJSON
            }
        }
    }

    public func serializeAnyJSON() throws -> String {
        let value = try serializeJSON()
        return "{\"@type\":\"\(anyTypeURL)\",\"value\":\(value)}"
    }

    public init(any: Google_Protobuf_Any) throws {
        try any.unpackTo(target: &self)
    }

    public var debugDescription: String {
        get {
            do {
                let json = try serializeJSON()
                return "\(swiftClassName)(\(json))"
            } catch let e {
                return "\(swiftClassName)(FAILURE: \(e))"
            }
        }
    }

    mutating public func _protoc_generated_decodeField<T: FieldDecoder>(setter: inout T, protoFieldNumber: Int) throws {
        switch protoFieldNumber {
        case 1: try setter.decodeRepeatedMessageField(fieldType: Google_Protobuf_Value.self, value: &values)
        default: break
        }
    }

    public func _protoc_generated_traverse(visitor: Visitor) throws {
        if !values.isEmpty {
            try visitor.visitRepeatedMessageField(value: values, fieldNumber: 1)
        }
    }

    public func _protoc_generated_isEqualTo(other: Google_Protobuf_ListValue) -> Bool {
        return values == other.values
    }
}

public func ==(lhs: Google_Protobuf_Value.OneOf_Kind, rhs: Google_Protobuf_Value.OneOf_Kind) -> Bool {
  switch (lhs, rhs) {
  case (.nullValue(_), .nullValue(_)): return true
  case (.numberValue(let l), .numberValue(let r)): return l == r
  case (.stringValue(let l), .stringValue(let r)): return l == r
  case (.boolValue(let l), .boolValue(let r)): return l == r
  case (.structValue(let l), .structValue(let r)): return l == r
  case (.listValue(let l), .listValue(let r)): return l == r
  case (.None, .None): return true
  default: return false
  }
}
