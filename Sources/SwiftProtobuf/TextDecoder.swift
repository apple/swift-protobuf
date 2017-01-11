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
public struct TextDecoder {
    private var scanner: TextScanner
    public var complete: Bool {return scanner.complete}

    internal init(text: String, extensions: ExtensionSet? = nil) {
        scanner = TextScanner(text: text, extensions: extensions)
    }

    internal init(scanner: TextScanner) {
        self.scanner = scanner
    }

    internal mutating func decodeFullObject<M: Message>(message: inout M, terminator: TextToken?) throws {
        guard let nameProviding = (M.self as? ProtoNameProviding.Type) else {
            throw DecodingError.missingFieldNames
        }
        while let token = try scanner.nextKey() {
            switch token {
            case .identifier(let key):
                let protoFieldNumber: Int
                if key.hasPrefix("[") {
                    // Extension key
                    if let n = scanner.extensions?.fieldNumberForProto(messageType: M.self, protoFieldName: key) {
                        protoFieldNumber = n
                    } else {
                        throw DecodingError.unknownField
                    }
                } else {
                    // Regular key; look it up on the message
                    if let n = nameProviding._protobuf_fieldNames.fieldNumber(forProtoName: key) {
                        protoFieldNumber = n
                    } else {
                        throw DecodingError.unknownField
                    }
                }
                var subdecoder = TextFieldDecoder(scanner: scanner)
                try message.decodeField(setter: &subdecoder, protoFieldNumber: protoFieldNumber)
            default:
                if terminator != nil && terminator == token {
                    return
                }
                throw DecodingError.malformedText
            }
            try scanner.skipOptionalSeparator()
        }
        if terminator == nil {
            return
        } else {
            throw DecodingError.truncatedInput
        }
    }
}

struct TextFieldDecoder: FieldDecoder {
    var rejectConflictingOneof: Bool {return true}
    var scanner: TextScanner

    mutating func decodeExtensionField(values: inout ExtensionFieldValueSet, messageType: Message.Type, protoFieldNumber: Int) throws {
        if let ext = scanner.extensions?[messageType, protoFieldNumber] {
            var fieldValue = values[protoFieldNumber] ?? ext.newField()
            try fieldValue.decodeField(setter: &self)
            values[protoFieldNumber] = fieldValue
        }
    }

    mutating func decodeSingularField<S: FieldType>(fieldType: S.Type, value: inout S.BaseType?) throws {
        try scanner.skipRequired(token: .colon)
        try S.setFromText(scanner: scanner, value: &value)
    }

    mutating func decodeRepeatedField<S: FieldType>(fieldType: S.Type, value: inout [S.BaseType]) throws {
        try scanner.skipRequired(token: .colon)
        if try scanner.skipOptional(token: .beginArray) {
            var firstItem = true
            while true {
                if try scanner.skipOptional(token: .endArray) {
                    return
                }
                if firstItem {
                    firstItem = false
                } else {
                    try scanner.skipRequired(token: .comma)
                }
                try S.setFromText(scanner: scanner, value: &value)
            }
        } else {
            try S.setFromText(scanner: scanner, value: &value)
        }
    }

    mutating func decodePackedField<S: FieldType>(fieldType: S.Type, value: inout [S.BaseType]) throws {
        try decodeRepeatedField(fieldType: fieldType, value: &value)
    }

    mutating func decodeSingularMessageField<M: Message>(fieldType: M.Type, value: inout M?) throws {
        _ = try scanner.skipOptional(token: .colon)
        try M.setFromText(scanner: scanner, value: &value)
    }

    mutating func decodeRepeatedMessageField<M: Message>(fieldType: M.Type, value: inout [M]) throws {
        _ = try scanner.skipOptional(token: .colon)
        if try scanner.skipOptional(token: .beginArray) {
            var firstItem = true
            while true {
                if try scanner.skipOptional(token: .endArray) {
                    return
                }
                if firstItem {
                    firstItem = false
                } else {
                    try scanner.skipRequired(token: .comma)
                }
                try M.setFromText(scanner: scanner, value: &value)
            }
        } else {
            try M.setFromText(scanner: scanner, value: &value)
        }
    }

    mutating func decodeSingularGroupField<G: Message>(fieldType: G.Type, value: inout G?) throws {
        try decodeSingularMessageField(fieldType: fieldType, value: &value)
    }

    mutating func decodeRepeatedGroupField<G: Message>(fieldType: G.Type, value: inout [G]) throws {
        try decodeRepeatedMessageField(fieldType: fieldType, value: &value)
    }
    
    private func decodeMapEntry<KeyType: MapKeyType, ValueType: MapValueType>(mapType: ProtobufMap<KeyType, ValueType>.Type, keyField: inout KeyType.BaseType?, valueField: inout ValueType.BaseType?) throws where KeyType.BaseType: Hashable {
        let terminator = try scanner.readObjectStart()
        while let token = try scanner.next() {
            if token == terminator {
                return
            }
            switch token {
            case .identifier("key"):
                _ = try scanner.skipRequired(token: .colon)
                try KeyType.setFromText(scanner: scanner, value: &keyField)
            case .identifier("value"):
                // Awkward:  If the value is message-typed, the colon is optional,
                // otherwise, it's required.
                _ = try scanner.skipOptional(token: .colon)
                try ValueType.setFromText(scanner: scanner, value: &valueField)
            default:
                throw DecodingError.unknownField
            }
            try scanner.skipOptionalSeparator()
        }
        throw DecodingError.truncatedInput
 
    }
    
    mutating func decodeMapField<KeyType: MapKeyType, ValueType: MapValueType>(fieldType: ProtobufMap<KeyType, ValueType>.Type, value: inout ProtobufMap<KeyType, ValueType>.BaseType) throws where KeyType.BaseType: Hashable {
        _ = try scanner.skipOptional(token: .colon)
        if try scanner.skipOptional(token: .beginArray) {
            var firstItem = true
            while true {
                if try scanner.skipOptional(token: .endArray) {
                    return
                }
                if firstItem {
                    firstItem = false
                } else {
                    try scanner.skipRequired(token: .comma)
                }
                var keyField: KeyType.BaseType?
                var valueField: ValueType.BaseType?
                try decodeMapEntry(mapType: fieldType, keyField: &keyField, valueField: &valueField)
                if let keyField = keyField, let valueField = valueField {
                    value[keyField] = valueField
                } else {
                    throw DecodingError.malformedText
                }
            }
        } else {
            var keyField: KeyType.BaseType?
            var valueField: ValueType.BaseType?
            try decodeMapEntry(mapType: fieldType, keyField: &keyField, valueField: &valueField)
            if let keyField = keyField, let valueField = valueField {
                value[keyField] = valueField
            } else {
                throw DecodingError.malformedText
            }
        }
    }
}
