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

/*
 * Hand-built implementation.
 */

public enum Google_Protobuf_NullValue: Enum, _ProtoNameProviding {
    // TODO: This is awkward, see the references to .NullValue(.NullValue) below.
    // TODO: The .nullValue property on Google_Protobuf_Value has to have
    // a type; but this is a little weird.
    public typealias RawValue = Int
    ///   Null value.
    case nullValue

    public static var _protobuf_nameMap: _NameMap = [
      0: .same(proto: "NULL_VALUE"),
    ]

    public init() {self = .nullValue}
    public init?(rawValue: Int) {self = .nullValue}
    public var rawValue: Int {return 0}
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
public struct Google_Protobuf_Struct: Message, Proto3Message, _MessageImplementationBase, ExpressibleByDictionaryLiteral, _ProtoNameProviding {
    public static let protoMessageName: String = "Struct"
    public static let protoPackageName: String = "google.protobuf"
    public static let _protobuf_nameMap: _NameMap = [
        1: .same(proto: "fields"),
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

    public mutating func decodeJSON(from decoder: inout JSONDecoder) throws {
        try decoder.scanner.skipRequiredObjectStart()
        if decoder.scanner.skipOptionalObjectEnd() {
            return
        }
        while true {
            let key = try decoder.scanner.nextQuotedString()
            try decoder.scanner.skipRequiredColon()
            var value = Google_Protobuf_Value()
            try value.decodeJSON(from: &decoder)
            fields[key] = value
            if decoder.scanner.skipOptionalObjectEnd() {
                return
            }
            try decoder.scanner.skipRequiredComma()
        }
    }

    public func jsonString() throws -> String {
        var jsonEncoder = JSONEncoder()
        jsonEncoder.startObject()
        var mapVisitor = JSONMapEncodingVisitor(encoder: jsonEncoder)
        for (k,v) in fields {
            try mapVisitor.visitSingularStringField(value: k, fieldNumber: 1)
            try mapVisitor.visitSingularMessageField(value: v, fieldNumber: 2)
        }
        mapVisitor.encoder.endObject()
        return mapVisitor.encoder.stringResult
    }

    public func anyJSONString() throws -> String {
        let value = try jsonString()
        return "{\"@type\":\"\(type(of: self).anyTypeURL)\",\"value\":\(value)}"
    }

    mutating public func _protoc_generated_decodeMessage<T: Decoder>(decoder: inout T) throws {
        while let fieldNumber = try decoder.nextFieldNumber() {
            try decodeField(decoder: &decoder, fieldNumber: fieldNumber)
        }
    }

    public mutating func _protoc_generated_decodeField<T: Decoder>(decoder: inout T, fieldNumber: Int) throws {
        switch fieldNumber {
        case 1: try decoder.decodeMapField(fieldType: _ProtobufMessageMap<ProtobufString,Google_Protobuf_Value>.self, value: &fields)
        default:
            break
        }
    }

    public func _protoc_generated_traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
        if !fields.isEmpty {
            try visitor.visitMapField(fieldType: _ProtobufMessageMap<ProtobufString,Google_Protobuf_Value>.self, value: fields, fieldNumber: 1)
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
public struct Google_Protobuf_Value: Message, Proto3Message, _MessageImplementationBase, ExpressibleByIntegerLiteral, ExpressibleByFloatLiteral, ExpressibleByStringLiteral, ExpressibleByBooleanLiteral, ExpressibleByNilLiteral, _ProtoNameProviding {
    public static let protoMessageName: String = "Value"
    public static let protoPackageName: String = "google.protobuf"
    public static let _protobuf_nameMap: _NameMap = [
        1: .unique(proto: "null_value", json: "nullValue"),
        2: .unique(proto: "number_value", json: "numberValue"),
        3: .unique(proto: "string_value", json: "stringValue"),
        4: .unique(proto: "bool_value", json: "boolValue"),
        5: .unique(proto: "struct_value", json: "structValue"),
        6: .unique(proto: "list_value", json: "listValue"),
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

    mutating public func _protoc_generated_decodeMessage<T: Decoder>(decoder: inout T) throws {
        while let fieldNumber = try decoder.nextFieldNumber() {
            try decodeField(decoder: &decoder, fieldNumber: fieldNumber)
        }
    }

    mutating public func _protoc_generated_decodeField<T: Decoder>(decoder: inout T, fieldNumber: Int) throws {
        switch fieldNumber {
        case 1, 2, 3, 4, 5, 6:
            if kind != nil {
                try decoder.handleConflictingOneOf()
            }
            kind = try OneOf_Kind(byDecodingFrom: &decoder, fieldNumber: fieldNumber)
        default: break
        }
    }

    public func jsonString() throws -> String {
        var jsonEncoder = JSONEncoder()
        try serializeJSONValue(jsonEncoder: &jsonEncoder)
        return jsonEncoder.stringResult
    }

    public func anyJSONString() throws -> String {
        let value = try jsonString()
        return "{\"@type\":\"\(type(of: self).anyTypeURL)\",\"value\":\(value)}"
    }

    fileprivate func serializeJSONValue(jsonEncoder: inout JSONEncoder) throws {
        try kind?.serializeJSONField(encoder: &jsonEncoder)
    }

    public mutating func decodeJSON(from decoder: inout JSONDecoder) throws {
        let c = try decoder.scanner.peekOneCharacter()
        switch c {
        case "n":
            if !decoder.scanner.skipOptionalNull() {
                throw JSONDecodingError.failure
            }
        case "[":
            var l = Google_Protobuf_ListValue()
            try l.decodeJSON(from: &decoder)
            kind = .listValue(l)
        case "{":
            var s = Google_Protobuf_Struct()
            try s.decodeJSON(from: &decoder)
            kind = .structValue(s)
        case "t", "f":
            let b = try decoder.scanner.nextBool()
            kind = .boolValue(b)
        case "\"":
            let s = try decoder.scanner.nextQuotedString()
            kind = .stringValue(s)
        default:
            let d = try decoder.scanner.nextDouble()
            kind = .numberValue(d)
        }
    }

    public func _protoc_generated_isEqualTo(other: Google_Protobuf_Value) -> Bool {
        return kind == other.kind
    }

    public init(any: Google_Protobuf_Any) throws {
        try any.unpackTo(target: &self)
    }

    public func _protoc_generated_traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
        try kind?.traverse(visitor: &visitor, start:1, end: 7)
    }

    // Storage ivars
    private var kind: Google_Protobuf_Value.OneOf_Kind?

    ///   Represents a null value.
    public var nullValue: Google_Protobuf_NullValue? {
        get {
            if case .nullValue(let v)? = kind {
                return v
            }
            return nil
        }
        set {
            if let newValue = newValue {
                kind = .nullValue(newValue)
            } else {
                kind = nil
            }
        }
    }

    ///   Represents a double value.
    public var numberValue: Double? {
        get {
            if case .numberValue(let v)? = kind {
                return v
            }
            return nil
        }
        set {
            if let newValue = newValue {
                kind = .numberValue(newValue)
            } else {
                kind = nil
            }
        }
    }

    ///   Represents a string value.
    public var stringValue: String? {
        get {
            if case .stringValue(let v)? = kind {
                return v
            }
            return nil
        }
        set {
            if let newValue = newValue {
                kind = .stringValue(newValue)
            } else {
                kind = nil
            }
        }
    }

    ///   Represents a boolean value.
    public var boolValue: Bool? {
        get {
            if case .boolValue(let v)? = kind {
                return v
            }
            return nil
        }
        set {
            if let newValue = newValue {
                kind = .boolValue(newValue)
            } else {
                kind = nil
            }
        }
    }

    ///   Represents a structured value.
    public var structValue: Google_Protobuf_Struct? {
        get {
            if case .structValue(let v)? = kind {
                return v
            }
            return nil
        }
        set {
            if let newValue = newValue {
                kind = .structValue(newValue)
            } else {
                kind = nil
            }
        }
    }

    ///   Represents a repeated `Value`.
    public var listValue: Google_Protobuf_ListValue? {
        get {
            if case .listValue(let v)? = kind {
                return v
            }
            return nil
        }
        set {
            if let newValue = newValue {
                kind = .listValue(newValue)
            } else {
                kind = nil
            }
        }
    }

    public enum OneOf_Kind: Equatable {
        case nullValue(Google_Protobuf_NullValue)
        case numberValue(Double)
        case stringValue(String)
        case boolValue(Bool)
        case structValue(Google_Protobuf_Struct)
        case listValue(Google_Protobuf_ListValue)

        fileprivate init?<T: Decoder>(byDecodingFrom decoder: inout T, fieldNumber: Int) throws {
            switch fieldNumber {
            case 1:
                var value: Google_Protobuf_NullValue?
                try decoder.decodeSingularEnumField(value: &value)
                if let value = value {
                    self = .nullValue(value)
                    return
                }
            case 2:
                var value: Double?
                try decoder.decodeSingularDoubleField(value: &value)
                if let value = value {
                    self = .numberValue(value)
                    return
                }
            case 3:
                var value: String?
                try decoder.decodeSingularStringField(value: &value)
                if let value = value {
                    self = .stringValue(value)
                    return
                }
            case 4:
                var value: Bool?
                try decoder.decodeSingularBoolField(value: &value)
                if let value = value {
                    self = .boolValue(value)
                    return
                }
            case 5:
                var value: Google_Protobuf_Struct?
                try decoder.decodeSingularMessageField(value: &value)
                if let value = value {
                    self = .structValue(value)
                    return
                }
            case 6:
                var value: Google_Protobuf_ListValue?
                try decoder.decodeSingularMessageField(value: &value)
                if let value = value {
                    self = .listValue(value)
                    return
                }
            default:
                break
            }
            return nil
        }

        fileprivate func serializeJSONField(encoder: inout JSONEncoder) throws {
            switch self {
            case .nullValue(_): encoder.putNullValue()
            case .numberValue(let v): encoder.putDoubleValue(value: v)
            case .stringValue(let v): encoder.putStringValue(value: v)
            case .boolValue(let v): encoder.putBoolValue(value: v)
            case .structValue(let v): encoder.append(text: try v.jsonString())
            case .listValue(let v): encoder.append(text: try v.jsonString())
            }
        }

        fileprivate func traverse<V: Visitor>(visitor: inout V, start: Int, end: Int) throws {
            switch self {
            case .nullValue(let v):
                if start <= 1 && 1 < end {
                    try visitor.visitSingularEnumField(value: v, fieldNumber: 1)
                }
            case .numberValue(let v):
                if start <= 2 && 2 < end {
                    try visitor.visitSingularDoubleField(value: v, fieldNumber: 2)
                }
            case .stringValue(let v):
                if start <= 3 && 3 < end {
                    try visitor.visitSingularStringField(value: v, fieldNumber: 3)
                }
            case .boolValue(let v):
                if start <= 4 && 4 < end {
                    try visitor.visitSingularBoolField(value: v, fieldNumber: 4)
                }
            case .structValue(let v):
                if start <= 5 && 5 < end {
                    try visitor.visitSingularMessageField(value: v, fieldNumber: 5)
                }
            case .listValue(let v):
                if start <= 6 && 6 < end {
                    try visitor.visitSingularMessageField(value: v, fieldNumber: 6)
                }
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
            }
        }
    }
}

///   `ListValue` is a wrapper around a repeated field of values.
///
///   The JSON representation for `ListValue` is JSON array.
public struct Google_Protobuf_ListValue: Message, Proto3Message, _MessageImplementationBase, ExpressibleByArrayLiteral, _ProtoNameProviding {
    public static let protoMessageName: String = "ListValue"
    public static let protoPackageName: String = "google.protobuf"
    public static let _protobuf_nameMap: _NameMap = [
        1: .same(proto: "values"),
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

    public func jsonString() throws -> String {
        var jsonEncoder = JSONEncoder()
        jsonEncoder.append(text: "[")
        var separator: StaticString = ""
        for v in values {
            jsonEncoder.append(staticText: separator)
            try v.serializeJSONValue(jsonEncoder: &jsonEncoder)
            separator = ","
        }
        jsonEncoder.append(text: "]")
        return jsonEncoder.stringResult
    }

    public mutating func decodeJSON(from decoder: inout JSONDecoder) throws {
        if decoder.scanner.skipOptionalNull() {
            return
        }
        try decoder.scanner.skipRequiredArrayStart()
        if decoder.scanner.skipOptionalArrayEnd() {
            return
        }
        while true {
            var v = Google_Protobuf_Value()
            try v.decodeJSON(from: &decoder)
            values.append(v)
            if decoder.scanner.skipOptionalArrayEnd() {
                return
            }
            try decoder.scanner.skipRequiredComma()
        }
    }

    public func anyJSONString() throws -> String {
        let value = try jsonString()
        return "{\"@type\":\"\(type(of: self).anyTypeURL)\",\"value\":\(value)}"
    }

    public init(any: Google_Protobuf_Any) throws {
        try any.unpackTo(target: &self)
    }

    mutating public func _protoc_generated_decodeMessage<T: Decoder>(decoder: inout T) throws {
        while let fieldNumber = try decoder.nextFieldNumber() {
            try decodeField(decoder: &decoder, fieldNumber: fieldNumber)
        }
    }

    mutating public func _protoc_generated_decodeField<T: Decoder>(decoder: inout T, fieldNumber: Int) throws {
        switch fieldNumber {
        case 1: try decoder.decodeRepeatedMessageField(value: &values)
        default: break
        }
    }

    public func _protoc_generated_traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
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
  default: return false
  }
}
