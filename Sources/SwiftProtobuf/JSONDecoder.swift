// Sources/SwiftProtobuf/JSONDecoder.swift - JSON format decoding
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// JSON format decoding engine.
///
// -----------------------------------------------------------------------------

import Foundation
import Swift

public struct JSONDecoder: Decoder {
    internal var scanner: JSONScanner
    public var rejectConflictingOneof: Bool {return true}

    internal init(json: String) {
        scanner = JSONScanner(json: json)
    }

    internal mutating func decodeFullObject<M: Message>(message: inout M) throws {
        guard let nameProviding = (M.self as? ProtoNameProviding.Type) else {
            throw DecodingError.missingFieldNames
        }
        let names = nameProviding._protobuf_fieldNames
        try scanner.skipRequiredObjectStart()
        if scanner.skipOptionalObjectEnd() {
            return
        }
        // Get number of next known field
        // (Unknown fields are skipped at a low level; nextFieldNumber()
        // returns nil if this skipping reaches the end of the object)
        while let fieldNumber = try scanner.nextFieldNumber(names: names) {
            try message.decodeField(decoder: &self, fieldNumber: fieldNumber)
            if scanner.skipOptionalObjectEnd() {
                return
            }
            try scanner.skipRequiredComma()
        }
    }

        public mutating func decodeSingularFloatField(value: inout Float) throws {
        try decodeSingularField(fieldType: ProtobufFloat.self, value: &value)
    }
    public mutating func decodeSingularFloatField(value: inout Float?) throws {
        try decodeSingularField(fieldType: ProtobufFloat.self, value: &value)
    }
    public mutating func decodeSingularDoubleField(value: inout Double) throws {
        try decodeSingularField(fieldType: ProtobufDouble.self, value: &value)
    }
    public mutating func decodeSingularDoubleField(value: inout Double?) throws {
        try decodeSingularField(fieldType: ProtobufDouble.self, value: &value)
    }
    public mutating func decodeSingularInt32Field(value: inout Int32) throws {
        try decodeSingularField(fieldType: ProtobufInt32.self, value: &value)
    }
    public mutating func decodeSingularInt32Field(value: inout Int32?) throws {
        try decodeSingularField(fieldType: ProtobufInt32.self, value: &value)
    }
    public mutating func decodeSingularInt64Field(value: inout Int64) throws {
        try decodeSingularField(fieldType: ProtobufInt64.self, value: &value)
    }
    public mutating func decodeSingularInt64Field(value: inout Int64?) throws {
        try decodeSingularField(fieldType: ProtobufInt64.self, value: &value)
    }
    public mutating func decodeSingularUInt32Field(value: inout UInt32) throws {
        try decodeSingularField(fieldType: ProtobufUInt32.self, value: &value)
    }
    public mutating func decodeSingularUInt32Field(value: inout UInt32?) throws {
        try decodeSingularField(fieldType: ProtobufUInt32.self, value: &value)
    }
    public mutating func decodeSingularUInt64Field(value: inout UInt64) throws {
        try decodeSingularField(fieldType: ProtobufUInt64.self, value: &value)
    }
    public mutating func decodeSingularUInt64Field(value: inout UInt64?) throws {
        try decodeSingularField(fieldType: ProtobufUInt64.self, value: &value)
    }
    public mutating func decodeSingularSInt32Field(value: inout Int32) throws {
        try decodeSingularField(fieldType: ProtobufSInt32.self, value: &value)
    }
    public mutating func decodeSingularSInt32Field(value: inout Int32?) throws {
        try decodeSingularField(fieldType: ProtobufSInt32.self, value: &value)
    }
    public mutating func decodeSingularSInt64Field(value: inout Int64) throws {
        try decodeSingularField(fieldType: ProtobufSInt64.self, value: &value)
    }
    public mutating func decodeSingularSInt64Field(value: inout Int64?) throws {
        try decodeSingularField(fieldType: ProtobufSInt64.self, value: &value)
    }
    public mutating func decodeSingularFixed32Field(value: inout UInt32) throws {
        try decodeSingularField(fieldType: ProtobufFixed32.self, value: &value)
    }
    public mutating func decodeSingularFixed32Field(value: inout UInt32?) throws {
        try decodeSingularField(fieldType: ProtobufFixed32.self, value: &value)
    }
    public mutating func decodeSingularFixed64Field(value: inout UInt64) throws {
        try decodeSingularField(fieldType: ProtobufFixed64.self, value: &value)
    }
    public mutating func decodeSingularFixed64Field(value: inout UInt64?) throws {
        try decodeSingularField(fieldType: ProtobufFixed64.self, value: &value)
    }
    public mutating func decodeSingularSFixed32Field(value: inout Int32) throws {
        try decodeSingularField(fieldType: ProtobufSFixed32.self, value: &value)
    }
    public mutating func decodeSingularSFixed32Field(value: inout Int32?) throws {
        try decodeSingularField(fieldType: ProtobufSFixed32.self, value: &value)
    }
    public mutating func decodeSingularSFixed64Field(value: inout Int64) throws {
        try decodeSingularField(fieldType: ProtobufSFixed64.self, value: &value)
    }
    public mutating func decodeSingularSFixed64Field(value: inout Int64?) throws {
        try decodeSingularField(fieldType: ProtobufSFixed64.self, value: &value)
    }
    public mutating func decodeSingularBoolField(value: inout Bool) throws {
        try decodeSingularField(fieldType: ProtobufBool.self, value: &value)
    }
    public mutating func decodeSingularBoolField(value: inout Bool?) throws {
        try decodeSingularField(fieldType: ProtobufBool.self, value: &value)
    }
    public mutating func decodeSingularStringField(value: inout String) throws {
        try decodeSingularField(fieldType: ProtobufString.self, value: &value)
    }
    public mutating func decodeSingularStringField(value: inout String?) throws {
        try decodeSingularField(fieldType: ProtobufString.self, value: &value)
    }
    public mutating func decodeSingularBytesField(value: inout Data) throws {
        try decodeSingularField(fieldType: ProtobufBytes.self, value: &value)
    }
    public mutating func decodeSingularBytesField(value: inout Data?) throws {
        try decodeSingularField(fieldType: ProtobufBytes.self, value: &value)
    }


    public mutating func decodeSingularField<S: FieldType>(fieldType: S.Type, value: inout S.BaseType?) throws {
        if scanner.skipOptionalNull() {
            value = nil
            return
        }
        try S.setFromJSON(decoder: &self, value: &value)
    }

    public mutating func decodeSingularField<S: FieldType>(fieldType: S.Type, value: inout S.BaseType) throws {
        if scanner.skipOptionalNull() {
            value = S.proto3DefaultValue
            return
        }
        try S.setFromJSON(decoder: &self, value: &value)
    }

    public mutating func decodeRepeatedField<S: FieldType>(fieldType: S.Type, value: inout [S.BaseType]) throws {
        if scanner.skipOptionalNull() {
            return
        }
        try scanner.skipRequiredArrayStart()
        if scanner.skipOptionalArrayEnd() {
            return
        }
        while true {
            try S.setFromJSON(decoder: &self, value: &value)
            if scanner.skipOptionalArrayEnd() {
                return
            }
            try scanner.skipRequiredComma()
        }
    }

    public mutating func decodeSingularEnumField<E: Enum>(value: inout E?) throws where E.RawValue == Int {
        if scanner.skipOptionalNull() {
            value = nil
            return
        } else if let name = try scanner.nextOptionalQuotedString() {
            if let b = E(jsonName: name) {
                value = b
                return
            }
        } else {
            let n = try scanner.nextSInt()
            if let i = Int(exactly: n) {
                value = E(rawValue: i)
                return
            }
        }
        throw DecodingError.unrecognizedEnumValue
    }

    public mutating func decodeSingularEnumField<E: Enum>(value: inout E) throws where E.RawValue == Int {
        if scanner.skipOptionalNull() {
            value = E()
            return
        } else if let name = try scanner.nextOptionalQuotedString() {
            if let b = E(jsonName: name) {
                value = b
                return
            }
        } else {
            let n = try scanner.nextSInt()
            if let i = Int(exactly: n) {
                if let v = E(rawValue: i) {
                    value = v
                    return
                }
            }
        }
        throw DecodingError.unrecognizedEnumValue
    }

    public mutating func decodeRepeatedEnumField<E: Enum>(value: inout [E]) throws where E.RawValue == Int {
        if scanner.skipOptionalNull() {
            return
        }
        try scanner.skipRequiredArrayStart()
        if scanner.skipOptionalArrayEnd() {
            return
        }
        while true {
            if let name = try scanner.nextOptionalQuotedString() {
                if let b = E(jsonName: name) {
                    value.append(b)
                } else {
                    throw DecodingError.unrecognizedEnumValue
                }
            } else {
                let n = try scanner.nextSInt()
                if let i = Int(exactly: n) {
                    if let v = E(rawValue: i) {
                        value.append(v)
                    } else {
                        throw DecodingError.unrecognizedEnumValue
                    }
                } else {
                    throw DecodingError.malformedJSON
                }
            }
            if scanner.skipOptionalArrayEnd() {
                return
            }
            try scanner.skipRequiredComma()
        }
    }

    public mutating func decodeSingularMessageField<M: Message>(value: inout M?) throws {
        if scanner.skipOptionalNull() {
            // Fields of type google.protobuf.Value treat 'null' as the default value
            if M.self == Google_Protobuf_Value.self {
                value = M()
            } else {
                // All other message field types treat 'null' as an unset field
                value = nil
            }
            return
        }
        let message = try M(decoder: &self)
        value = message
    }

    public mutating func decodeRepeatedMessageField<M: Message>(value: inout [M]) throws {
        if scanner.skipOptionalNull() {
            return
        }
       try scanner.skipRequiredArrayStart()
        if scanner.skipOptionalArrayEnd() {
            return
        }
        while true {
            let message = try M(decoder: &self)
            value.append(message)
            if scanner.skipOptionalArrayEnd() {
                return
            }
            try scanner.skipRequiredComma()
        }
    }

    public mutating func decodeSingularGroupField<G: Message>(value: inout G?) throws {
        throw DecodingError.schemaMismatch
    }
    public mutating func decodeRepeatedGroupField<G: Message>(value: inout [G]) throws {
        throw DecodingError.schemaMismatch
    }

    public mutating func decodeMapField<KeyType: MapKeyType, ValueType: MapValueType>(fieldType: ProtobufMap<KeyType, ValueType>.Type, value: inout ProtobufMap<KeyType, ValueType>.BaseType) throws {
        if scanner.skipOptionalNull() {
            return
        }
        try scanner.skipRequiredObjectStart()
        if scanner.skipOptionalObjectEnd() {
            return
        }
        while true {
            // Next character must be double quote, because
            // map keys must always be quoted strings.
            let c = try scanner.peekOneCharacter()
            if c != "\"" {
                throw DecodingError.malformedJSON
            }
            var keyField: KeyType.BaseType?
            try KeyType.setFromJSON(decoder: &self, value: &keyField)
            try scanner.skipRequiredColon()
            var valueField: ValueType.BaseType?
            try ValueType.setFromJSON(decoder: &self, value: &valueField)
            if let keyField = keyField, let valueField = valueField {
                value[keyField] = valueField
            } else {
                throw DecodingError.malformedJSON
            }
            if scanner.skipOptionalObjectEnd() {
                return
            }
            try scanner.skipRequiredComma()
        }
    }

    public mutating func decodeMapField<KeyType: MapKeyType, ValueType: Enum>(fieldType: ProtobufEnumMap<KeyType, ValueType>.Type, value: inout ProtobufEnumMap<KeyType, ValueType>.BaseType) throws where ValueType.RawValue == Int {
        if scanner.skipOptionalNull() {
            return
        }
        try scanner.skipRequiredObjectStart()
        if scanner.skipOptionalObjectEnd() {
            return
        }
        while true {
            // Next character must be double quote, because
            // map keys must always be quoted strings.
            let c = try scanner.peekOneCharacter()
            if c != "\"" {
                throw DecodingError.malformedJSON
            }
            var keyField: KeyType.BaseType?
            try KeyType.setFromJSON(decoder: &self, value: &keyField)
            try scanner.skipRequiredColon()
            var valueField: ValueType?
            try decodeSingularEnumField(value: &valueField)
            if let keyField = keyField, let valueField = valueField {
                value[keyField] = valueField
            } else {
                throw DecodingError.malformedJSON
            }
            if scanner.skipOptionalObjectEnd() {
                return
            }
            try scanner.skipRequiredComma()
        }
    }

    public mutating func decodeMapField<KeyType: MapKeyType, ValueType: Message>(fieldType: ProtobufMessageMap<KeyType, ValueType>.Type, value: inout ProtobufMessageMap<KeyType, ValueType>.BaseType) throws {
        if scanner.skipOptionalNull() {
            return
        }
        try scanner.skipRequiredObjectStart()
        if scanner.skipOptionalObjectEnd() {
            return
        }
        while true {
            // Next character must be double quote, because
            // map keys must always be quoted strings.
            let c = try scanner.peekOneCharacter()
            if c != "\"" {
                throw DecodingError.malformedJSON
            }
            var keyField: KeyType.BaseType?
            try KeyType.setFromJSON(decoder: &self, value: &keyField)
            try scanner.skipRequiredColon()
            var valueField: ValueType?
            try decodeSingularMessageField(value: &valueField)
            if let keyField = keyField, let valueField = valueField {
                value[keyField] = valueField
            } else {
                throw DecodingError.malformedJSON
            }
            if scanner.skipOptionalObjectEnd() {
                return
            }
            try scanner.skipRequiredComma()
        }
    }

    public mutating func decodeExtensionField(values: inout ExtensionFieldValueSet, messageType: Message.Type, fieldNumber: Int) throws {
        throw DecodingError.schemaMismatch
    }
}
