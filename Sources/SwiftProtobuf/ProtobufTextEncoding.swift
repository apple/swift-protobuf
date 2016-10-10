// ProtobufRuntime/Sources/Protobuf/ProtobufTextEncoding.swift - Text format encoding support
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
/// Text format serialization engine.
///
// -----------------------------------------------------------------------------

import Foundation

public struct ProtobufTextEncodingVisitor: ProtobufVisitor {
    private var encoder = ProtobufTextEncoder()
    private var tabLevel: Int = 0
    public var result: String {return encoder.result}
    
    
    public init() {}
    
    public init(message: ProtobufTextMessageBase, tabLevel: Int) throws {
        self.tabLevel = tabLevel
        
        try withAbstractVisitor {(visitor: inout ProtobufVisitor) in
            try message.traverse(visitor: &visitor)
        }
    }
    
    public init(group: ProtobufGroupBase, tabLevel: Int) throws {
        self.tabLevel = tabLevel

        try withAbstractVisitor {(visitor: inout ProtobufVisitor) in
            try group.traverse(visitor: &visitor)
        }
    }
    
    mutating public func withAbstractVisitor(clause: (inout ProtobufVisitor) throws -> ()) throws {
        var visitor: ProtobufVisitor = self
        try clause(&visitor)
        encoder.text = (visitor as! ProtobufTextEncodingVisitor).encoder.text
    }
    
    
    mutating public func visitUnknown(bytes: [UInt8]) {
        // JSON encoding has no provision for carrying proto2 unknown fields
        // TODO: Does this apply to the text format, as well?
    }
    
    mutating public func visitSingularField<S: ProtobufTypeProperties>(fieldType: S.Type, value: S.BaseType, protoFieldNumber: Int, protoFieldName: String, jsonFieldName: String, swiftFieldName: String) throws {
        encoder.startField(name: protoFieldName, tabLevel: tabLevel)
        try S.serializeTextValue(encoder: &encoder, value: value)
        encoder.endField()
    }
    
    mutating public func visitRepeatedField<S: ProtobufTypeProperties>(fieldType: S.Type, value: [S.BaseType], protoFieldNumber: Int, protoFieldName: String, jsonFieldName: String, swiftFieldName: String) throws {
        for v in value {
            encoder.startField(name: protoFieldName, tabLevel: tabLevel)
            try S.serializeTextValue(encoder: &encoder, value: v)
            encoder.endField()
        }
    }
    
    mutating public func visitPackedField<S: ProtobufTypeProperties>(fieldType: S.Type, value: [S.BaseType], protoFieldNumber: Int, protoFieldName: String, jsonFieldName: String, swiftFieldName: String) throws {
        try visitRepeatedField(fieldType: fieldType, value: value, protoFieldNumber: protoFieldNumber, protoFieldName: protoFieldName, jsonFieldName: jsonFieldName, swiftFieldName: swiftFieldName)
    }
    
    mutating public func visitSingularMessageField<M: ProtobufMessage>(value: M, protoFieldNumber: Int, protoFieldName: String, jsonFieldName: String, swiftFieldName: String) throws {
        encoder.startField(name: protoFieldName, tabLevel: tabLevel, dropColon: true)
        // Note: We ask the message to serialize itself instead of
        // using ProtobufJSONEncodingVisitor(message:) since
        // some messages override the JSON format at this point.
        encoder.startObject()
        try M.serializeTextValue(encoder: &encoder, value: value, tabLevel: tabLevel + 1)
        encoder.endObject(tabLevel: tabLevel)
        encoder.endField()
    }
    
    mutating public func visitRepeatedMessageField<M: ProtobufMessage>(value: [M], protoFieldNumber: Int, protoFieldName: String, jsonFieldName: String, swiftFieldName: String) throws {
        for v in value {
            encoder.startField(name: protoFieldName, tabLevel: tabLevel, dropColon: true)
            encoder.startObject()
            // Note: We ask the message to serialize itself instead of
            // using ProtobufJSONEncodingVisitor(message:) since
            // some messages override the JSON format at this point.
            try M.serializeTextValue(encoder: &encoder, value: v, tabLevel: tabLevel + 1)
            encoder.endObject(tabLevel: tabLevel)
            encoder.endField()
        }
    }
    
    // Note that JSON encoding for groups is not officially supported
    // by any Google spec.  But it's trivial to support it here.
    mutating public func visitSingularGroupField<G: ProtobufGroup>(value: G, protoFieldNumber: Int, protoFieldName: String, jsonFieldName: String, swiftFieldName: String) throws {
        encoder.startField(name: protoFieldName, tabLevel: tabLevel)
        // Groups have no special JSON support, so we use only the generic traversal mechanism here
        let t = try ProtobufTextEncodingVisitor(group: value, tabLevel:tabLevel).result
        encoder.append(text: t)
        encoder.endField()
    }
    
    mutating public func visitRepeatedGroupField<G: ProtobufGroup>(value: [G], protoFieldNumber: Int, protoFieldName: String, jsonFieldName: String, swiftFieldName: String) throws {
        for v in value {
            encoder.startField(name: protoFieldName, tabLevel: tabLevel)
            // Groups have no special JSON support, so we use only the generic traversal mechanism here
            let t = try ProtobufTextEncodingVisitor(group: v, tabLevel:tabLevel).result
            encoder.append(text: t)
            encoder.endField()
        }
    }
    
    mutating public func visitMapField<KeyType: ProtobufMapKeyType, ValueType: ProtobufMapValueType>(fieldType: ProtobufMap<KeyType, ValueType>.Type, value: ProtobufMap<KeyType, ValueType>.BaseType, protoFieldNumber: Int, protoFieldName: String, jsonFieldName: String, swiftFieldName: String) throws  where KeyType.BaseType: Hashable {
        encoder.startField(name: protoFieldName, tabLevel: tabLevel)
        var arraySeparator = ""
        encoder.append(text: "{")
        for (k,v) in value {
            encoder.append(text: arraySeparator)
            KeyType.serializeTextMapKeyValue(encoder: &encoder, value: k)
            encoder.append(text: ":")
            try ValueType.serializeTextValue(encoder: &encoder, value: v)
            arraySeparator = ","
        }
        encoder.append(text: "}")
        encoder.endField()
    }
}


public struct ProtobufTextEncoder {
    fileprivate var text: [String] = []
    public init() {}
    public var result: String { return text.joined(separator: "") }
    
    mutating func append(text newText: String) {
        text.append(newText)
    }
    mutating func appendTokens(tokens: [ProtobufTextToken]) {
        for t in tokens {
            switch t {
            case .beginArray: append(text: "[")
            case .beginObject: append(text: "{")
            case .boolean(let v):
                // Note that quoted boolean map keys get stored as .string()
                putBoolValue(value: v, quote: false)
            case .colon: append(text: ":")
            case .comma: append(text: ",")
            case .endArray: append(text: "]")
            case .endObject: append(text: "}")
            case .null: putNullValue()
            case .number(let v): append(text: v)
            case .string(let v): putStringValue(value: v)
            }
        }
    }
    mutating func startField(name: String, tabLevel: Int, dropColon:Bool = false) {
        for _ in 0..<tabLevel {
            append(text:"  ")
        }
        
        if dropColon {
            append(text: name + " ")
        } else {
            append(text: name + ": ")
        }
    }
    mutating func endField() {
        append(text: "\n")
    }
    public mutating func startObject() {
        append(text: "{\n")
    }
    public mutating func endObject(tabLevel: Int) {
        for _ in 0..<tabLevel {
            append(text:"  ")
        }

        append(text: "}")
    }
    mutating func putNullValue() {
        append(text: "null")
    }
    mutating func putFloatValue(value: Float, quote: Bool) {
        putDoubleValue(value: Double(value), quote: quote)
    }
    mutating func putDoubleValue(value: Double, quote: Bool) {
        if value.isNaN {
            append(text: "\"NaN\"")
        } else if !value.isFinite {
            if value < 0 {
                append(text: "\"-Infinity\"")
            } else {
                append(text: "\"Infinity\"")
            }
        } else {
            // TODO: Be smarter here about choosing significant digits
            // See: protoc source has C++ code for this with interesting ideas
            let s: String
            if value < Double(Int64.max) && value > Double(Int64.min) && value == Double(Int64(value)) {
                s = String(Int64(value))
            } else {
                s = String(value)
            }
            if quote {
                append(text: "\"" + s + "\"")
            } else {
                append(text: s)
            }
        }
    }
    mutating func putInt64(value: Int64, quote: Bool) {
        append(text: String(value))
    }
    mutating func putUInt64(value: UInt64, quote: Bool) {
        append(text: String(value))
    }
    
    mutating func putBoolValue(value: Bool, quote: Bool) {
        if quote {
            append(text: value ? "\"true\"" : "\"false\"")
        } else {
            append(text: value ? "true" : "false")
        }
    }
    mutating func putStringValue(value: String) {
        let hexDigits = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F"];
        append(text: "\"")
        for c in value.unicodeScalars {
            switch c.value {
            // Special two-byte escapes
            case 8: append(text: "\\b")
            case 9: append(text: "\\t")
            case 10: append(text: "\\n")
            case 12: append(text: "\\f")
            case 13: append(text: "\\r")
            case 34: append(text: "\\\"")
            case 92: append(text: "\\\\")
            case 0...31, 127...159: // Hex form for C0 and C1 control chars
                let digit1 = hexDigits[Int(c.value / 16)]
                let digit2 = hexDigits[Int(c.value & 15)]
                append(text: "\\u00\(digit1)\(digit2)")
            case 0...127:  // ASCII
                append(text: String(c))
            default: // Non-ASCII
                append(text: String(c))
            }
        }
        append(text: "\"")
    }
    mutating func putBytesValue(value: Data) {
        var out: String = ""
        if value.count > 0 {
            let digits: [Character] = ["A", "B", "C", "D", "E", "F",
                                       "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q",
                                       "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "a", "b",
                                       "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m",
                                       "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x",
                                       "y", "z", "0", "1", "2", "3", "4", "5", "6", "7", "8",
                                       "9", "+", "/"]
            var t: Int = 0
            for (i,v) in value.enumerated() {
                if i > 0 && i % 3 == 0 {
                    out.append(digits[(t >> 18) & 63])
                    out.append(digits[(t >> 12) & 63])
                    out.append(digits[(t >> 6) & 63])
                    out.append(digits[t & 63])
                    t = 0
                }
                t <<= 8
                t += Int(v)
            }
            switch value.count % 3 {
            case 0:
                out.append(digits[(t >> 18) & 63])
                out.append(digits[(t >> 12) & 63])
                out.append(digits[(t >> 6) & 63])
                out.append(digits[t & 63])
            case 1:
                t <<= 16
                out.append(digits[(t >> 18) & 63])
                out.append(digits[(t >> 12) & 63])
                out.append(Character("="))
                out.append(Character("="))
            default:
                t <<= 8
                out.append(digits[(t >> 18) & 63])
                out.append(digits[(t >> 12) & 63])
                out.append(digits[(t >> 6) & 63])
                out.append(Character("="))
            }
        }
        append(text: "\"" + out + "\"")
    }
}

