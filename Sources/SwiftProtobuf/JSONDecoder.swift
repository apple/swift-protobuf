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
    private var fieldCount = 0
    private var fieldNameMap: FieldNameMap?
    public var rejectConflictingOneof: Bool {return true}

    internal init(utf8Pointer: UnsafePointer<UInt8>, count: Int) {
        self.scanner = JSONScanner(utf8Pointer: utf8Pointer, count: count)
    }

    private init(scanner: JSONScanner) {
        self.scanner = scanner
    }

    internal mutating func decodeFullObject<M: Message>(message: inout M) throws {
        guard let nameProviding = (M.self as? ProtoNameProviding.Type) else {
            throw DecodingError.missingFieldNames
        }
        fieldNameMap = nameProviding._protobuf_fieldNames
        try scanner.skipRequiredObjectStart()
        if scanner.skipOptionalObjectEnd() {
            return
        }
        try message.decodeMessage(decoder: &self)
    }

    // TODO: Implement this, move JSON onto the new decodeMessage API
    public mutating func nextFieldNumber() throws -> Int? {
        if scanner.skipOptionalObjectEnd() {
            return nil
        }
        if fieldCount > 0 {
            try scanner.skipRequiredComma()
        }
        if let fieldNumber = try scanner.nextFieldNumber(names: fieldNameMap!) {
            fieldCount += 1
            return fieldNumber
        }
        return nil
    }

    public mutating func decodeSingularFloatField(value: inout Float) throws {
        if scanner.skipOptionalNull() {
            value = 0
            return
        }
        value = try scanner.nextFloat()
    }

    public mutating func decodeSingularFloatField(value: inout Float?) throws {
        if scanner.skipOptionalNull() {
            value = nil
            return
        }
        value = try scanner.nextFloat()
    }

    public mutating func decodeRepeatedFloatField(value: inout [Float]) throws {
        if scanner.skipOptionalNull() {
            return
        }
        try scanner.skipRequiredArrayStart()
        if scanner.skipOptionalArrayEnd() {
            return
        }
        while true {
            let n = try scanner.nextFloat()
            value.append(n)
            if scanner.skipOptionalArrayEnd() {
                return
            }
            try scanner.skipRequiredComma()
        }
    }

    public mutating func decodeSingularDoubleField(value: inout Double) throws {
        if scanner.skipOptionalNull() {
            value = 0
            return
        }
        value = try scanner.nextDouble()
    }

    public mutating func decodeSingularDoubleField(value: inout Double?) throws {
        if scanner.skipOptionalNull() {
            value = nil
            return
        }
        value = try scanner.nextDouble()
    }

    public mutating func decodeRepeatedDoubleField(value: inout [Double]) throws {
        if scanner.skipOptionalNull() {
            return
        }
        try scanner.skipRequiredArrayStart()
        if scanner.skipOptionalArrayEnd() {
            return
        }
        while true {
            let n = try scanner.nextDouble()
            value.append(n)
            if scanner.skipOptionalArrayEnd() {
                return
            }
            try scanner.skipRequiredComma()
        }
    }

    public mutating func decodeSingularInt32Field(value: inout Int32) throws {
        if scanner.skipOptionalNull() {
            value = 0
            return
        }
        let n = try scanner.nextSInt()
        if n > Int64(Int32.max) || n < Int64(Int32.min) {
            throw DecodingError.malformedJSONNumber
        }
        value = Int32(truncatingBitPattern: n)
    }

    public mutating func decodeSingularInt32Field(value: inout Int32?) throws {
        if scanner.skipOptionalNull() {
            value = nil
            return
        }
        let n = try scanner.nextSInt()
        if n > Int64(Int32.max) || n < Int64(Int32.min) {
            throw DecodingError.malformedJSONNumber
        }
        value = Int32(truncatingBitPattern: n)
    }

    public mutating func decodeRepeatedInt32Field(value: inout [Int32]) throws {
        if scanner.skipOptionalNull() {
            return
        }
        try scanner.skipRequiredArrayStart()
        if scanner.skipOptionalArrayEnd() {
            return
        }
        while true {
            let n = try scanner.nextSInt()
            if n > Int64(Int32.max) || n < Int64(Int32.min) {
                throw DecodingError.malformedJSONNumber
            }
            value.append(Int32(truncatingBitPattern: n))
            if scanner.skipOptionalArrayEnd() {
                return
            }
            try scanner.skipRequiredComma()
        }
    }

    public mutating func decodeSingularInt64Field(value: inout Int64) throws {
        if scanner.skipOptionalNull() {
            value = 0
            return
        }
        value = try scanner.nextSInt()
    }

    public mutating func decodeSingularInt64Field(value: inout Int64?) throws {
        if scanner.skipOptionalNull() {
            value = nil
            return
        }
        value = try scanner.nextSInt()
    }

    public mutating func decodeRepeatedInt64Field(value: inout [Int64]) throws {
        if scanner.skipOptionalNull() {
            return
        }
        try scanner.skipRequiredArrayStart()
        if scanner.skipOptionalArrayEnd() {
            return
        }
        while true {
            let n = try scanner.nextSInt()
            value.append(n)
            if scanner.skipOptionalArrayEnd() {
                return
            }
            try scanner.skipRequiredComma()
        }
    }

    public mutating func decodeSingularUInt32Field(value: inout UInt32) throws {
        if scanner.skipOptionalNull() {
            value = 0
            return
        }
        let n = try scanner.nextUInt()
        if n > UInt64(UInt32.max) {
            throw DecodingError.malformedJSONNumber
        }
        value = UInt32(truncatingBitPattern: n)
    }

    public mutating func decodeSingularUInt32Field(value: inout UInt32?) throws {
        if scanner.skipOptionalNull() {
            value = nil
            return
        }
        let n = try scanner.nextUInt()
        if n > UInt64(UInt32.max) {
            throw DecodingError.malformedJSONNumber
        }
        value = UInt32(truncatingBitPattern: n)
    }

    public mutating func decodeRepeatedUInt32Field(value: inout [UInt32]) throws {
        if scanner.skipOptionalNull() {
            return
        }
        try scanner.skipRequiredArrayStart()
        if scanner.skipOptionalArrayEnd() {
            return
        }
        while true {
            let n = try scanner.nextUInt()
            if n > UInt64(UInt32.max) {
                throw DecodingError.malformedJSONNumber
            }
            value.append(UInt32(truncatingBitPattern: n))
            if scanner.skipOptionalArrayEnd() {
                return
            }
            try scanner.skipRequiredComma()
        }
    }

    public mutating func decodeSingularUInt64Field(value: inout UInt64) throws {
        if scanner.skipOptionalNull() {
            value = 0
            return
        }
        value = try scanner.nextUInt()
    }

    public mutating func decodeSingularUInt64Field(value: inout UInt64?) throws {
        if scanner.skipOptionalNull() {
            value = nil
            return
        }
        value = try scanner.nextUInt()
    }

    public mutating func decodeRepeatedUInt64Field(value: inout [UInt64]) throws {
        if scanner.skipOptionalNull() {
            return
        }
        try scanner.skipRequiredArrayStart()
        if scanner.skipOptionalArrayEnd() {
            return
        }
        while true {
            let n = try scanner.nextUInt()
            value.append(n)
            if scanner.skipOptionalArrayEnd() {
                return
            }
            try scanner.skipRequiredComma()
        }
    }

    public mutating func decodeSingularSInt32Field(value: inout Int32) throws {
        try decodeSingularInt32Field(value: &value)
    }

    public mutating func decodeSingularSInt32Field(value: inout Int32?) throws {
        try decodeSingularInt32Field(value: &value)
    }

    public mutating func decodeRepeatedSInt32Field(value: inout [Int32]) throws {
        try decodeRepeatedInt32Field(value: &value)
    }

    public mutating func decodeSingularSInt64Field(value: inout Int64) throws {
        try decodeSingularInt64Field(value: &value)
    }

    public mutating func decodeSingularSInt64Field(value: inout Int64?) throws {
        try decodeSingularInt64Field(value: &value)
    }

    public mutating func decodeRepeatedSInt64Field(value: inout [Int64]) throws {
        try decodeRepeatedInt64Field(value: &value)
    }

    public mutating func decodeSingularFixed32Field(value: inout UInt32) throws {
        try decodeSingularUInt32Field(value: &value)
    }

    public mutating func decodeSingularFixed32Field(value: inout UInt32?) throws {
        try decodeSingularUInt32Field(value: &value)
    }

    public mutating func decodeRepeatedFixed32Field(value: inout [UInt32]) throws {
        try decodeRepeatedUInt32Field(value: &value)
    }

    public mutating func decodeSingularFixed64Field(value: inout UInt64) throws {
        try decodeSingularUInt64Field(value: &value)
    }

    public mutating func decodeSingularFixed64Field(value: inout UInt64?) throws {
        try decodeSingularUInt64Field(value: &value)
    }

    public mutating func decodeRepeatedFixed64Field(value: inout [UInt64]) throws {
        try decodeRepeatedUInt64Field(value: &value)
    }

    public mutating func decodeSingularSFixed32Field(value: inout Int32) throws {
        try decodeSingularInt32Field(value: &value)
    }

    public mutating func decodeSingularSFixed32Field(value: inout Int32?) throws {
        try decodeSingularInt32Field(value: &value)
    }

    public mutating func decodeRepeatedSFixed32Field(value: inout [Int32]) throws {
        try decodeRepeatedInt32Field(value: &value)
    }

    public mutating func decodeSingularSFixed64Field(value: inout Int64) throws {
        try decodeSingularInt64Field(value: &value)
    }

    public mutating func decodeSingularSFixed64Field(value: inout Int64?) throws {
        try decodeSingularInt64Field(value: &value)
    }

    public mutating func decodeRepeatedSFixed64Field(value: inout [Int64]) throws {
        try decodeRepeatedInt64Field(value: &value)
    }

    public mutating func decodeSingularBoolField(value: inout Bool) throws {
        if scanner.skipOptionalNull() {
            value = false
            return
        }
        value = try scanner.nextBool()
    }

    public mutating func decodeSingularBoolField(value: inout Bool?) throws {
        if scanner.skipOptionalNull() {
            value = nil
            return
        }
        value = try scanner.nextBool()
    }

    public mutating func decodeRepeatedBoolField(value: inout [Bool]) throws {
        if scanner.skipOptionalNull() {
            return
        }
        try scanner.skipRequiredArrayStart()
        if scanner.skipOptionalArrayEnd() {
            return
        }
        while true {
            let n = try scanner.nextBool()
            value.append(n)
            if scanner.skipOptionalArrayEnd() {
                return
            }
            try scanner.skipRequiredComma()
        }
    }

    public mutating func decodeSingularStringField(value: inout String) throws {
        if scanner.skipOptionalNull() {
            value = ""
            return
        }
        value = try scanner.nextQuotedString()
    }

    public mutating func decodeSingularStringField(value: inout String?) throws {
        if scanner.skipOptionalNull() {
            value = nil
            return
        }
        value = try scanner.nextQuotedString()
    }

    public mutating func decodeRepeatedStringField(value: inout [String]) throws {
        if scanner.skipOptionalNull() {
            return
        }
        try scanner.skipRequiredArrayStart()
        if scanner.skipOptionalArrayEnd() {
            return
        }
        while true {
            let n = try scanner.nextQuotedString()
            value.append(n)
            if scanner.skipOptionalArrayEnd() {
                return
            }
            try scanner.skipRequiredComma()
        }
    }

    public mutating func decodeSingularBytesField(value: inout Data) throws {
        if scanner.skipOptionalNull() {
            value = Data()
            return
        }
        value = try scanner.nextBytesValue()
    }

    public mutating func decodeSingularBytesField(value: inout Data?) throws {
        if scanner.skipOptionalNull() {
            value = nil
            return
        }
        value = try scanner.nextBytesValue()
    }

    public mutating func decodeRepeatedBytesField(value: inout [Data]) throws {
        if scanner.skipOptionalNull() {
            return
        }
        try scanner.skipRequiredArrayStart()
        if scanner.skipOptionalArrayEnd() {
            return
        }
        while true {
            let n = try scanner.nextBytesValue()
            value.append(n)
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
        if value == nil {
            value = M()
        }
        var subDecoder = JSONDecoder(scanner: scanner)
        try value!.decodeIntoSelf(decoder: &subDecoder)
        scanner = subDecoder.scanner
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
            if scanner.skipOptionalNull() {
                if M.self == Google_Protobuf_Value.self {
                    value.append(M())
                } else {
                    throw DecodingError.malformedJSON
                }
            } else {
                var message = M()
                var subDecoder = JSONDecoder(scanner: scanner)
                try message.decodeIntoSelf(decoder: &subDecoder)
                scanner = subDecoder.scanner
                value.append(message)
            }
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
            try KeyType.decodeSingular(value: &keyField, from: &self)
            try scanner.skipRequiredColon()
            var valueField: ValueType.BaseType?
            try ValueType.decodeSingular(value: &valueField, from: &self)
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
            try KeyType.decodeSingular(value: &keyField, from: &self)
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
            try KeyType.decodeSingular(value: &keyField, from: &self)
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
