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

public struct JSONDecoder: FieldDecoder {
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
            try message.decodeField(setter: &self, protoFieldNumber: fieldNumber)
            if scanner.skipOptionalObjectEnd() {
                return
            }
            try scanner.skipRequiredComma()
        }
    }

    public mutating func decodeExtensionField(values: inout ExtensionFieldValueSet, messageType: Message.Type, protoFieldNumber: Int) throws {
        throw DecodingError.schemaMismatch
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

    public mutating func decodePackedField<S: FieldType>(fieldType: S.Type, value: inout [S.BaseType]) throws {
        try decodeRepeatedField(fieldType: fieldType, value: &value)
    }

    public mutating func decodeSingularMessageField<M: Message>(fieldType: M.Type, value: inout M?) throws {
        try M.setFromJSON(decoder: &self, value: &value)
    }

    public mutating func decodeRepeatedMessageField<M: Message>(fieldType: M.Type, value: inout [M]) throws {
        if scanner.skipOptionalNull() {
            return
        }
       try scanner.skipRequiredArrayStart()
        if scanner.skipOptionalArrayEnd() {
            return
        }
        while true {
            try M.setFromJSON(decoder: &self, value: &value)
            if scanner.skipOptionalArrayEnd() {
                return
            }
            try scanner.skipRequiredComma()
        }
    }

    public mutating func decodeSingularGroupField<G: Message>(fieldType: G.Type, value: inout G?) throws {
        throw DecodingError.schemaMismatch
    }

    public mutating func decodeRepeatedGroupField<G: Message>(fieldType: G.Type, value: inout [G]) throws {
        throw DecodingError.schemaMismatch
    }

    public mutating func decodeMapField<KeyType: MapKeyType, ValueType: MapValueType>(fieldType: ProtobufMap<KeyType, ValueType>.Type, value: inout ProtobufMap<KeyType, ValueType>.BaseType) throws where KeyType.BaseType: Hashable {
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
}
