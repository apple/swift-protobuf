// Sources/SwiftProtobuf/TextDecoder.swift - Text format decoding
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Test format decoding engine.
///
// -----------------------------------------------------------------------------

import Foundation
import Swift

///
/// Provides a higher-level interface to the token stream coming
/// from a TextScanner.  In particular, this provides single-token
/// pushback and convenience functions for iterating over complex
/// structures.
///
public struct TextDecoder: Decoder {
    internal var scanner: TextScanner
    private var fieldCount = 0
    private var terminator: UInt8?
    private var fieldNameMap: FieldNameMap?
    private var messageType: Message.Type?

    internal var complete: Bool {
        mutating get {
            return scanner.complete
        }
    }

    internal init(messageType: Message.Type, text: String, extensions: ExtensionSet?) throws {
        scanner = TextScanner(text: text, extensions: extensions)
        guard let nameProviding = (messageType as? ProtoNameProviding.Type) else {
            throw TextDecodingError.missingFieldNames
        }
        fieldNameMap = nameProviding._protobuf_fieldNames
        self.messageType = messageType
    }

    internal init(messageType: Message.Type, scanner: TextScanner, terminator: UInt8?) throws {
        self.scanner = scanner
        self.terminator = terminator
        guard let nameProviding = (messageType as? ProtoNameProviding.Type) else {
            throw TextDecodingError.missingFieldNames
        }
        fieldNameMap = nameProviding._protobuf_fieldNames
        self.messageType = messageType
    }


    public mutating func handleConflictingOneOf() throws {
        throw TextDecodingError.conflictingOneOf
    }

    public mutating func nextFieldNumber() throws -> Int? {
        if let terminator = terminator {
            if scanner.skipOptionalObjectEnd(terminator) {
                return nil
            }
        }
        if fieldCount > 0 {
            scanner.skipOptionalSeparator()
        }
        if let key = try scanner.nextOptionalExtensionKey() {
            // Extension key; look up in the extension registry
            if let fieldNumber = scanner.extensions?.fieldNumberForProto(messageType: messageType!, protoFieldName: key) {
                fieldCount += 1
                return fieldNumber
            } else {
                throw TextDecodingError.unknownField
            }
        } else if let fieldNumber = try scanner.nextFieldNumber(names: fieldNameMap!) {
            fieldCount += 1
            return fieldNumber
        } else if terminator == nil {
            return nil
        } else {
            throw TextDecodingError.truncated
        }

    }

    public mutating func decodeSingularFloatField(value: inout Float) throws {
        try scanner.skipRequiredColon()
        value = try scanner.nextFloat()
    }
    public mutating func decodeSingularFloatField(value: inout Float?) throws {
        try scanner.skipRequiredColon()
        value = try scanner.nextFloat()
    }
    public mutating func decodeRepeatedFloatField(value: inout [Float]) throws {
        try scanner.skipRequiredColon()
        if scanner.skipOptionalBeginArray() {
            var firstItem = true
            while true {
                if scanner.skipOptionalEndArray() {
                    return
                }
                if firstItem {
                    firstItem = false
                } else {
                    try scanner.skipRequiredComma()
                }
                let n = try scanner.nextFloat()
                value.append(n)
            }
        } else {
            let n = try scanner.nextFloat()
            value.append(n)
        }
    }
    public mutating func decodeSingularDoubleField(value: inout Double) throws {
        try scanner.skipRequiredColon()
        value = try scanner.nextDouble()
    }
    public mutating func decodeSingularDoubleField(value: inout Double?) throws {
        try scanner.skipRequiredColon()
        value = try scanner.nextDouble()
    }
    public mutating func decodeRepeatedDoubleField(value: inout [Double]) throws {
        try scanner.skipRequiredColon()
        if scanner.skipOptionalBeginArray() {
            var firstItem = true
            while true {
                if scanner.skipOptionalEndArray() {
                    return
                }
                if firstItem {
                    firstItem = false
                } else {
                    try scanner.skipRequiredComma()
                }
                let n = try scanner.nextDouble()
                value.append(n)
            }
        } else {
            let n = try scanner.nextDouble()
            value.append(n)
        }
    }
    public mutating func decodeSingularInt32Field(value: inout Int32) throws {
        try scanner.skipRequiredColon()
        let n = try scanner.nextSInt()
        if n > Int64(Int32.max) || n < Int64(Int32.min) {
            throw TextDecodingError.malformedNumber
        }
        value = Int32(truncatingBitPattern: n)
    }
    public mutating func decodeSingularInt32Field(value: inout Int32?) throws {
        try scanner.skipRequiredColon()
        let n = try scanner.nextSInt()
        if n > Int64(Int32.max) || n < Int64(Int32.min) {
            throw TextDecodingError.malformedNumber
        }
        value = Int32(truncatingBitPattern: n)
    }
    public mutating func decodeRepeatedInt32Field(value: inout [Int32]) throws {
        try scanner.skipRequiredColon()
        if scanner.skipOptionalBeginArray() {
            var firstItem = true
            while true {
                if scanner.skipOptionalEndArray() {
                    return
                }
                if firstItem {
                    firstItem = false
                } else {
                    try scanner.skipRequiredComma()
                }
                let n = try scanner.nextSInt()
                if n > Int64(Int32.max) || n < Int64(Int32.min) {
                    throw TextDecodingError.malformedNumber
                }
                value.append(Int32(truncatingBitPattern: n))
            }
        } else {
            let n = try scanner.nextSInt()
            if n > Int64(Int32.max) || n < Int64(Int32.min) {
                throw TextDecodingError.malformedNumber
            }
            value.append(Int32(truncatingBitPattern: n))
        }
    }
    public mutating func decodeSingularInt64Field(value: inout Int64) throws {
        try scanner.skipRequiredColon()
        value = try scanner.nextSInt()
    }
    public mutating func decodeSingularInt64Field(value: inout Int64?) throws {
        try scanner.skipRequiredColon()
        value = try scanner.nextSInt()
    }
    public mutating func decodeRepeatedInt64Field(value: inout [Int64]) throws {
        try scanner.skipRequiredColon()
        if scanner.skipOptionalBeginArray() {
            var firstItem = true
            while true {
                if scanner.skipOptionalEndArray() {
                    return
                }
                if firstItem {
                    firstItem = false
                } else {
                    try scanner.skipRequiredComma()
                }
                let n = try scanner.nextSInt()
                value.append(n)
            }
        } else {
            let n = try scanner.nextSInt()
            value.append(n)
        }
    }
    public mutating func decodeSingularUInt32Field(value: inout UInt32) throws {
        try scanner.skipRequiredColon()
        let n = try scanner.nextUInt()
        if n > UInt64(UInt32.max) {
            throw TextDecodingError.malformedNumber
        }
        value = UInt32(truncatingBitPattern: n)
    }
    public mutating func decodeSingularUInt32Field(value: inout UInt32?) throws {
        try scanner.skipRequiredColon()
        let n = try scanner.nextUInt()
        if n > UInt64(UInt32.max) {
            throw TextDecodingError.malformedNumber
        }
        value = UInt32(truncatingBitPattern: n)
    }
    public mutating func decodeRepeatedUInt32Field(value: inout [UInt32]) throws {
        try scanner.skipRequiredColon()
        if scanner.skipOptionalBeginArray() {
            var firstItem = true
            while true {
                if scanner.skipOptionalEndArray() {
                    return
                }
                if firstItem {
                    firstItem = false
                } else {
                    try scanner.skipRequiredComma()
                }
                let n = try scanner.nextUInt()
                if n > UInt64(UInt32.max) {
                    throw TextDecodingError.malformedNumber
                }
                value.append(UInt32(truncatingBitPattern: n))
            }
        } else {
            let n = try scanner.nextUInt()
            if n > UInt64(UInt32.max) {
                throw TextDecodingError.malformedNumber
            }
            value.append(UInt32(truncatingBitPattern: n))
        }
    }
    public mutating func decodeSingularUInt64Field(value: inout UInt64) throws {
        try scanner.skipRequiredColon()
        value = try scanner.nextUInt()
    }
    public mutating func decodeSingularUInt64Field(value: inout UInt64?) throws {
        try scanner.skipRequiredColon()
        value = try scanner.nextUInt()
    }
    public mutating func decodeRepeatedUInt64Field(value: inout [UInt64]) throws {
        try scanner.skipRequiredColon()
        if scanner.skipOptionalBeginArray() {
            var firstItem = true
            while true {
                if scanner.skipOptionalEndArray() {
                    return
                }
                if firstItem {
                    firstItem = false
                } else {
                    try scanner.skipRequiredComma()
                }
                let n = try scanner.nextUInt()
                value.append(n)
            }
        } else {
            let n = try scanner.nextUInt()
            value.append(n)
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
        try scanner.skipRequiredColon()
        value = try scanner.nextBool()
    }
    public mutating func decodeSingularBoolField(value: inout Bool?) throws {
        try scanner.skipRequiredColon()
        value = try scanner.nextBool()
    }
    public mutating func decodeRepeatedBoolField(value: inout [Bool]) throws {
        try scanner.skipRequiredColon()
        if scanner.skipOptionalBeginArray() {
            var firstItem = true
            while true {
                if scanner.skipOptionalEndArray() {
                    return
                }
                if firstItem {
                    firstItem = false
                } else {
                    try scanner.skipRequiredComma()
                }
                let n = try scanner.nextBool()
                value.append(n)
            }
        } else {
            let n = try scanner.nextBool()
            value.append(n)
        }
    }
    public mutating func decodeSingularStringField(value: inout String) throws {
        try scanner.skipRequiredColon()
        value = try scanner.nextStringValue()
    }
    public mutating func decodeSingularStringField(value: inout String?) throws {
        try scanner.skipRequiredColon()
        value = try scanner.nextStringValue()
    }
    public mutating func decodeRepeatedStringField(value: inout [String]) throws {
        try scanner.skipRequiredColon()
        if scanner.skipOptionalBeginArray() {
            var firstItem = true
            while true {
                if scanner.skipOptionalEndArray() {
                    return
                }
                if firstItem {
                    firstItem = false
                } else {
                    try scanner.skipRequiredComma()
                }
                let n = try scanner.nextStringValue()
                value.append(n)
            }
        } else {
            let n = try scanner.nextStringValue()
            value.append(n)
        }
    }
    public mutating func decodeSingularBytesField(value: inout Data) throws {
        try scanner.skipRequiredColon()
        value = try scanner.nextBytesValue()
    }
    public mutating func decodeSingularBytesField(value: inout Data?) throws {
        try scanner.skipRequiredColon()
        value = try scanner.nextBytesValue()
    }
    public mutating func decodeRepeatedBytesField(value: inout [Data]) throws {
        try scanner.skipRequiredColon()
        if scanner.skipOptionalBeginArray() {
            var firstItem = true
            while true {
                if scanner.skipOptionalEndArray() {
                    return
                }
                if firstItem {
                    firstItem = false
                } else {
                    try scanner.skipRequiredComma()
                }
                let n = try scanner.nextBytesValue()
                value.append(n)
            }
        } else {
            let n = try scanner.nextBytesValue()
            value.append(n)
        }
    }

    private mutating func decodeEnum<E: Enum>() throws -> E where E.RawValue == Int {
        if let name = try scanner.nextOptionalEnumName() {
            if let b = E(protoName: name) {
                return b
            } else {
                throw TextDecodingError.unrecognizedEnumValue
            }
        }
        let number = try scanner.nextSInt()
        if number >= Int64(Int32.min) && number <= Int64(Int32.max) {
            let n = Int32(truncatingBitPattern: number)
            if let e = E(rawValue: Int(n)) {
                return e
            } else {
                throw TextDecodingError.unrecognizedEnumValue
            }
        }
        throw TextDecodingError.malformedText

    }

    public mutating func decodeSingularEnumField<E: Enum>(value: inout E?) throws where E.RawValue == Int {
        try scanner.skipRequiredColon()
        let e: E = try decodeEnum()
        value = e
    }

    public mutating func decodeSingularEnumField<E: Enum>(value: inout E) throws where E.RawValue == Int {
        try scanner.skipRequiredColon()
        let e: E = try decodeEnum()
        value = e
    }

    public mutating func decodeRepeatedEnumField<E: Enum>(value: inout [E]) throws where E.RawValue == Int {
        try scanner.skipRequiredColon()
        if scanner.skipOptionalBeginArray() {
            var firstItem = true
            while true {
                if scanner.skipOptionalEndArray() {
                    return
                }
                if firstItem {
                    firstItem = false
                } else {
                    try scanner.skipRequiredComma()
                }
                let e: E = try decodeEnum()
                value.append(e)
            }
        } else {
            let e: E = try decodeEnum()
            value.append(e)
        }
    }


    public mutating func decodeSingularMessageField<M: Message>(value: inout M?) throws {
        _ = scanner.skipOptionalColon()
        if value == nil {
            value = M()
        }
        let terminator = try scanner.skipObjectStart()
        var subDecoder = try TextDecoder(messageType: M.self,scanner: scanner, terminator: terminator)
        try value!.decodeText(from: &subDecoder)
        scanner = subDecoder.scanner
    }

    public mutating func decodeRepeatedMessageField<M: Message>(value: inout [M]) throws {
        _ = scanner.skipOptionalColon()
        if scanner.skipOptionalBeginArray() {
            var firstItem = true
            while true {
                if scanner.skipOptionalEndArray() {
                    return
                }
                if firstItem {
                    firstItem = false
                } else {
                    try scanner.skipRequiredComma()
                }
                var message = M()
                let terminator = try scanner.skipObjectStart()
                var subDecoder = try TextDecoder(messageType: M.self,scanner: scanner, terminator: terminator)
                try message.decodeText(from: &subDecoder)
                scanner = subDecoder.scanner
                value.append(message)
            }
        } else {
            var message = M()
            let terminator = try scanner.skipObjectStart()
            var subDecoder = try TextDecoder(messageType: M.self,scanner: scanner, terminator: terminator)
            try message.decodeText(from: &subDecoder)
            scanner = subDecoder.scanner
            value.append(message)
        }
    }

    public mutating func decodeSingularGroupField<G: Message>(value: inout G?) throws {
        try decodeSingularMessageField(value: &value)
    }

    public mutating func decodeRepeatedGroupField<G: Message>(value: inout [G]) throws {
        try decodeRepeatedMessageField(value: &value)
    }

    private mutating func decodeMapEntry<KeyType: MapKeyType, ValueType: MapValueType>(mapType: ProtobufMap<KeyType, ValueType>.Type, value: inout ProtobufMap<KeyType, ValueType>.BaseType) throws {
        var keyField: KeyType.BaseType?
        var valueField: ValueType.BaseType?
        let terminator = try scanner.skipObjectStart()
        while true {
            if scanner.skipOptionalObjectEnd(terminator) {
                if let keyField = keyField, let valueField = valueField {
                    value[keyField] = valueField
                    return
                } else {
                    throw TextDecodingError.malformedText
                }
            }
            if let key = try scanner.nextKey() {
                switch key {
                case "key":
                    try KeyType.decodeSingular(value: &keyField, from: &self)
                case "value":
                    try ValueType.decodeSingular(value: &valueField, from: &self)
                default:
                    throw TextDecodingError.unknownField
                }
                scanner.skipOptionalSeparator()
            }
        }
    }

    public mutating func decodeMapField<KeyType: MapKeyType, ValueType: MapValueType>(fieldType: ProtobufMap<KeyType, ValueType>.Type, value: inout ProtobufMap<KeyType, ValueType>.BaseType) throws {
        _ = scanner.skipOptionalColon()
        if scanner.skipOptionalBeginArray() {
            var firstItem = true
            while true {
                if scanner.skipOptionalEndArray() {
                    return
                }
                if firstItem {
                    firstItem = false
                } else {
                    try scanner.skipRequiredComma()
                }
                try decodeMapEntry(mapType: fieldType, value: &value)
            }
        } else {
            try decodeMapEntry(mapType: fieldType, value: &value)
        }
    }

    private mutating func decodeMapEntry<KeyType: MapKeyType, ValueType: Enum>(mapType: ProtobufEnumMap<KeyType, ValueType>.Type, value: inout ProtobufEnumMap<KeyType, ValueType>.BaseType) throws where ValueType.RawValue == Int {
        var keyField: KeyType.BaseType?
        var valueField: ValueType?
        let terminator = try scanner.skipObjectStart()
        while true {
            if scanner.skipOptionalObjectEnd(terminator) {
                if let keyField = keyField, let valueField = valueField {
                    value[keyField] = valueField
                    return
                } else {
                    throw TextDecodingError.malformedText
                }
            }
            if let key = try scanner.nextKey() {
                switch key {
                case "key":
                    try KeyType.decodeSingular(value: &keyField, from: &self)
                case "value":
                    try decodeSingularEnumField(value: &valueField)
                default:
                    throw TextDecodingError.unknownField
                }
                scanner.skipOptionalSeparator()
            }
        }
    }

    public mutating func decodeMapField<KeyType: MapKeyType, ValueType: Enum>(fieldType: ProtobufEnumMap<KeyType, ValueType>.Type, value: inout ProtobufEnumMap<KeyType, ValueType>.BaseType) throws where ValueType.RawValue == Int {
        _ = scanner.skipOptionalColon()
        if scanner.skipOptionalBeginArray() {
            var firstItem = true
            while true {
                if scanner.skipOptionalEndArray() {
                    return
                }
                if firstItem {
                    firstItem = false
                } else {
                    try scanner.skipRequiredComma()
                }
                try decodeMapEntry(mapType: fieldType, value: &value)
            }
        } else {
            try decodeMapEntry(mapType: fieldType, value: &value)
        }
    }

    private mutating func decodeMapEntry<KeyType: MapKeyType, ValueType: Message>(mapType: ProtobufMessageMap<KeyType, ValueType>.Type, value: inout ProtobufMessageMap<KeyType, ValueType>.BaseType) throws {
        var keyField: KeyType.BaseType?
        var valueField: ValueType?
        let terminator = try scanner.skipObjectStart()
        while true {
            if scanner.skipOptionalObjectEnd(terminator) {
                if let keyField = keyField, let valueField = valueField {
                    value[keyField] = valueField
                    return
                } else {
                    throw TextDecodingError.malformedText
                }
            }
            if let key = try scanner.nextKey() {
                switch key {
                case "key":
                    try KeyType.decodeSingular(value: &keyField, from: &self)
                case "value":
                    try decodeSingularMessageField(value: &valueField)
                default:
                    throw TextDecodingError.unknownField
                }
                scanner.skipOptionalSeparator()
            }
        }
    }

    public mutating func decodeMapField<KeyType: MapKeyType, ValueType: Message>(fieldType: ProtobufMessageMap<KeyType, ValueType>.Type, value: inout ProtobufMessageMap<KeyType, ValueType>.BaseType) throws {
        _ = scanner.skipOptionalColon()
        if scanner.skipOptionalBeginArray() {
            var firstItem = true
            while true {
                if scanner.skipOptionalEndArray() {
                    return
                }
                if firstItem {
                    firstItem = false
                } else {
                    try scanner.skipRequiredComma()
                }
                try decodeMapEntry(mapType: fieldType, value: &value)
            }
        } else {
            try decodeMapEntry(mapType: fieldType, value: &value)
        }
    }

    public mutating func decodeExtensionField(values: inout ExtensionFieldValueSet, messageType: Message.Type, fieldNumber: Int) throws {
        if let ext = scanner.extensions?[messageType, fieldNumber] {
            var fieldValue = values[fieldNumber] ?? ext.newField()
            try fieldValue.decodeExtensionField(decoder: &self)
            values[fieldNumber] = fieldValue
        }
    }
}
