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
public struct TextDecoder: FieldDecoder {
    private var scanner: TextScanner
    public var complete: Bool {return scanner.complete}
    public var rejectConflictingOneof: Bool {return true}

    internal init(text: String, extensions: ExtensionSet? = nil) {
        scanner = TextScanner(text: text, extensions: extensions)
    }

    internal init(scanner: TextScanner) {
        self.scanner = scanner
    }

    internal mutating func decodeFullObject<M: Message>(message: inout M, terminator: UInt8?) throws {
        guard let nameProviding = (M.self as? ProtoNameProviding.Type) else {
            throw DecodingError.missingFieldNames
        }
        let names = nameProviding._protobuf_fieldNames
        while true {
            if let terminator = terminator {
                if scanner.skipOptionalObjectEnd(terminator) {
                    return
                }
            }
            if let token = try scanner.nextKey() {
                switch token {
                case .extensionIdentifier(let key):
                    // Extension key; look up in the extension registry
                    if let protoFieldNumber = scanner.extensions?.fieldNumberForProto(messageType: M.self, protoFieldName: key) {
                        try message.decodeField(setter: &self, protoFieldNumber: protoFieldNumber)
                    } else {
                        print("Unknown extension field \(key)")
                        throw DecodingError.unknownField
                    }
                case .identifier(let key):
                    // Regular key; look it up on the message
                    if let protoFieldNumber = names.fieldNumber(forProtoName: key) {
                        try message.decodeField(setter: &self, protoFieldNumber: protoFieldNumber)
                    } else {
                        throw DecodingError.unknownField
                    }
                }
            } else if terminator == nil {
                return
            } else {
                throw DecodingError.truncatedInput
            }
            scanner.skipOptionalSeparator()
        }
    }

    public mutating func decodeExtensionField(values: inout ExtensionFieldValueSet, messageType: Message.Type, protoFieldNumber: Int) throws {
        if let ext = scanner.extensions?[messageType, protoFieldNumber] {
            var fieldValue = values[protoFieldNumber] ?? ext.newField()
            try fieldValue.decodeField(setter: &self)
            values[protoFieldNumber] = fieldValue
        }
    }

    public mutating func decodeSingularField<S: FieldType>(fieldType: S.Type, value: inout S.BaseType?) throws {
        try scanner.skipRequiredColon()
        try S.setFromText(scanner: scanner, value: &value)
    }

    public mutating func decodeRepeatedField<S: FieldType>(fieldType: S.Type, value: inout [S.BaseType]) throws {
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
                try S.setFromText(scanner: scanner, value: &value)
            }
        } else {
            try S.setFromText(scanner: scanner, value: &value)
        }
    }

    public mutating func decodePackedField<S: FieldType>(fieldType: S.Type, value: inout [S.BaseType]) throws {
        try decodeRepeatedField(fieldType: fieldType, value: &value)
    }

    public mutating func decodeSingularMessageField<M: Message>(fieldType: M.Type, value: inout M?) throws {
        _ = scanner.skipOptionalColon()
        try M.setFromText(scanner: scanner, value: &value)
    }

    public mutating func decodeRepeatedMessageField<M: Message>(fieldType: M.Type, value: inout [M]) throws {
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
                try M.setFromText(scanner: scanner, value: &value)
            }
        } else {
            try M.setFromText(scanner: scanner, value: &value)
        }
    }

    public mutating func decodeSingularGroupField<G: Message>(fieldType: G.Type, value: inout G?) throws {
        try decodeSingularMessageField(fieldType: fieldType, value: &value)
    }

    public mutating func decodeRepeatedGroupField<G: Message>(fieldType: G.Type, value: inout [G]) throws {
        try decodeRepeatedMessageField(fieldType: fieldType, value: &value)
    }

    private func decodeMapEntry<KeyType: MapKeyType, ValueType: MapValueType>(mapType: ProtobufMap<KeyType, ValueType>.Type, keyField: inout KeyType.BaseType?, valueField: inout ValueType.BaseType?) throws where KeyType.BaseType: Hashable {
        let terminator = try scanner.skipObjectStart()
        while true {
            if scanner.skipOptionalObjectEnd(terminator) {
                return
            }
            if let keyToken = try scanner.nextKey() {
                switch keyToken {
                case .identifier("key"):
                    try scanner.skipRequiredColon()
                    try KeyType.setFromText(scanner: scanner, value: &keyField)
                case .identifier("value"):
                    // Awkward:  If the value is message-typed, the colon is
                    // optional, otherwise, it's required.
                    _ = scanner.skipOptionalColon()
                    try ValueType.setFromText(scanner: scanner, value: &valueField)
                default:
                    throw DecodingError.unknownField
                }
                scanner.skipOptionalSeparator()
            }
        }
    }

    public mutating func decodeMapField<KeyType: MapKeyType, ValueType: MapValueType>(fieldType: ProtobufMap<KeyType, ValueType>.Type, value: inout ProtobufMap<KeyType, ValueType>.BaseType) throws where KeyType.BaseType: Hashable {
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
