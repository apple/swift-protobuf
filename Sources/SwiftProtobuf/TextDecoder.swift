// ProtobufRuntime/Sources/Protobuf/ProtobufTextDecoding.swift - Text format decoding
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
/// Test format decoding engine.
///
// -----------------------------------------------------------------------------

import Foundation
import Swift

///
/// Provides a higher-level interface to the JSON token stream coming
/// from a ProtobufTextScanner.  In particular, this provides single-token
/// pushback and convenience functions for iterating over complex
/// structures.
///
public struct TextDecoder {
    private var scanner: ProtobufTextScanner
    public var complete: Bool {return scanner.complete}


    public enum ObjectParseState {
        case expectFirstKey
        case expectKey
        case expectColon
        case expectComma
    }

    public init(text: String, extensions: ExtensionSet? = nil) {
        scanner = ProtobufTextScanner(text: text, tokens: [], extensions: extensions)
    }

    public init(tokens: [TextToken]) {
        scanner = ProtobufTextScanner(text: "", tokens: tokens)
    }

    fileprivate init(scanner: ProtobufTextScanner) {
        self.scanner = scanner
    }

    public mutating func pushback(token: TextToken) {
        scanner.pushback(token: token)
    }

    /// Returns nil if no more tokens, throws an error if
    /// the data being parsed is malformed.
    public mutating func nextToken() throws -> TextToken? {
        return try scanner.next()
    }

    public func nextTokenIsBeginObject() throws -> Bool {
        guard let nextToken = try scanner.next() else {throw DecodingError.truncatedInput}
        if (nextToken == .beginObject) {
            return true
        }
        scanner.pushback(token: nextToken)
        return false
    }

    public mutating func decodeFullObject<M: Message>(message: inout M, alreadyInsideObject: Bool = false) throws {
        if alreadyInsideObject {
            try message.decodeFromTextObject(textDecoder: &self)
            if !complete {
                throw DecodingError.trailingGarbage
            }
        } else {
            guard let token = try nextToken() else {throw DecodingError.truncatedInput}
            switch token {
            case .beginObject:
                try message.decodeFromTextObject(textDecoder: &self)
                if !complete {
                    throw DecodingError.trailingGarbage
                }
            default:
                throw DecodingError.malformedText
            }
        }
    }

    public mutating func decodeValue<M: Message>(key: String, message: inout M, parsingObject:Bool = false) throws {
        guard let nameProviding = (M.self as? ProtoNameProviding.Type) else {
            throw DecodingError.missingFieldNames
        }
        let protoFieldNumber = (nameProviding._protobuf_fieldNames.fieldNumber(forProtoName: key)
            ?? scanner.extensions?.fieldNumberForProto(messageType: M.self, protoFieldName: key))

        if parsingObject {
            var fieldDecoder:FieldDecoder = ProtobufTextObjectFieldDecoder(scanner: scanner)
            if let protoFieldNumber = protoFieldNumber {
                try message.decodeField(setter: &fieldDecoder, protoFieldNumber: protoFieldNumber)
            }
        } else {
            if let token = try nextToken() {
                switch token {
                case .colon, .comma, .endObject, .endArray:
                    throw DecodingError.malformedText
                case .beginObject:
                    break
                case .beginArray:
                    var fieldDecoder:FieldDecoder = TextArrayFieldDecoder(scanner: scanner)
                    if let protoFieldNumber = protoFieldNumber {
                        try message.decodeField(setter: &fieldDecoder, protoFieldNumber: protoFieldNumber)
                    } else {
                        var skipped: [TextToken] = []
                        try skipArray(tokens: &skipped)
                    }
                case .string, .identifier, .octalInteger, .hexadecimalInteger, .decimalInteger, .floatingPointLiteral:
                    var fieldDecoder:FieldDecoder = ProtobufTextSingleTokenFieldDecoder(token: token, scanner: scanner)
                    if let protoFieldNumber = protoFieldNumber {
                        try message.decodeField(setter: &fieldDecoder, protoFieldNumber: protoFieldNumber)
                    } else {
                        throw DecodingError.unknownField
                    }
                }
            } else {
                throw DecodingError.truncatedInput
            }
        }
    }

    public mutating func decodeValue<G: Message>(key: String, group: inout G) throws {
        guard let nameProviding = (G.self as? ProtoNameProviding.Type) else {
            throw DecodingError.missingFieldNames
        }
        if let token = try nextToken() {
            let protoFieldNumber = (nameProviding._protobuf_fieldNames.fieldNumber(forProtoName: key))
            // TODO: Look up field number for extension?
            //?? scanner.extensions?.fieldNumberForJson(messageType: G.self, jsonFieldName: key))
            switch token {
            case .colon, .comma, .endObject, .endArray:
                throw DecodingError.malformedText
            case .beginObject:
                var fieldDecoder:FieldDecoder = ProtobufTextObjectFieldDecoder(scanner: scanner)
                if let protoFieldNumber = protoFieldNumber {
                    try group.decodeField(setter: &fieldDecoder, protoFieldNumber: protoFieldNumber)
                } else {
                    var skipped: [TextToken] = []
                    try skipObject(tokens: &skipped)
                }
            case .beginArray:
                var fieldDecoder:FieldDecoder = TextArrayFieldDecoder(scanner: scanner)
                if let protoFieldNumber = protoFieldNumber {
                    try group.decodeField(setter: &fieldDecoder, protoFieldNumber: protoFieldNumber)
                } else {
                    var skipped: [TextToken] = []
                    try skipArray(tokens: &skipped)
                }
            default:
                var fieldDecoder:FieldDecoder = ProtobufTextSingleTokenFieldDecoder(token: token, scanner: scanner)
                if let protoFieldNumber = protoFieldNumber {
                    try group.decodeField(setter: &fieldDecoder, protoFieldNumber: protoFieldNumber)
                } else {
                    // Token was already implicitly skipped, but we
                    // need to handle one deferred failure check:
                    if !token.isValid {
                        throw DecodingError.malformedTextNumber
                    }
                }
            }
        } else {
            throw DecodingError.truncatedInput
        }
    }


    // Build parseArrayFields() method, use it.

    /// Updates the provided array with the tokens that were skipped.
    /// This is used for deferred parsing of Any fields.
    public mutating func skip() throws -> [TextToken] {
        var tokens = [TextToken]()
        try skipValue(tokens: &tokens)
        return tokens
    }

    private mutating func skipValue(tokens: inout [TextToken]) throws {
        if let token = try nextToken() {
            switch token {
            case .beginObject:
                try skipObject(tokens: &tokens)
            case .beginArray:
                try skipArray(tokens: &tokens)
            case .endObject, .endArray, .comma, .colon:
                throw DecodingError.malformedText
            default:
                if !token.isValid {
                    throw DecodingError.malformedText
                }
                tokens.append(token)
            }
        } else {
            throw DecodingError.truncatedInput
        }
    }

    // Assumes begin object already consumed
    private mutating func skipObject( tokens: inout [TextToken]) throws {
        tokens.append(.beginObject)
        if let token = try nextToken() {
            switch token {
            case .endObject:
                tokens.append(token)
                return
            case .string:
                pushback(token: token)
            default:
                throw DecodingError.malformedText
            }
        } else {
            throw DecodingError.truncatedInput
        }
    
        while true {
            if let token = try nextToken() {
                if case .string = token {
                    tokens.append(token)
                } else {
                    throw DecodingError.malformedText
                }
            }
        
            if let token = try nextToken() {
                if case .colon = token {
                    tokens.append(token)
                } else {
                    throw DecodingError.malformedText
                }
            }
        
            try skipValue(tokens: &tokens)
        
            if let token = try nextToken() {
                switch token {
                case .comma:
                    tokens.append(token)
                case .endObject:
                    tokens.append(token)
                    return
                default:
                    throw DecodingError.malformedText
                }
            }
        }
    }

    private mutating func skipArray( tokens: inout [TextToken]) throws {
        tokens.append(.beginArray)
        if let token = try nextToken() {
            switch token {
            case .endArray:
                tokens.append(token)
                return
            default:
                pushback(token: token)
            }
        } else {
            throw DecodingError.truncatedInput
        }
    
        while true {
            try skipValue(tokens: &tokens)
        
            if let token = try nextToken() {
                switch token {
                case .comma:
                    tokens.append(token)
                case .endArray:
                    tokens.append(token)
                    return
                default:
                    throw DecodingError.malformedText
                }
            }
        }
    }
}

protocol TextFieldDecoder: FieldDecoder {
    var scanner: ProtobufTextScanner {get}
}

extension TextFieldDecoder {
    public mutating func decodeExtensionField(values: inout ExtensionFieldValueSet, messageType: Message.Type, protoFieldNumber: Int) throws {
        if let ext = scanner.extensions?[messageType, protoFieldNumber] {
            var mutableSetter: FieldDecoder = self
            var fieldValue = values[protoFieldNumber] ?? ext.newField()
            try fieldValue.decodeField(setter: &mutableSetter)
            values[protoFieldNumber] = fieldValue
        }
    }
}

private struct ProtobufTextSingleTokenFieldDecoder: TextFieldDecoder {
    var rejectConflictingOneof: Bool {return true}

    var token: TextToken
    var scanner: ProtobufTextScanner

    mutating func decodeSingularField<S: FieldType>(fieldType: S.Type, value: inout S.BaseType?) throws {
        try S.setFromTextToken(token: token, value: &value)
    }

    mutating func decodeRepeatedField<S: FieldType>(fieldType: S.Type, value: inout [S.BaseType]) throws {
        try S.setFromTextToken(token: token, value: &value)
    }

    mutating func decodePackedField<S: FieldType>(fieldType: S.Type, value: inout [S.BaseType]) throws {
        try decodeRepeatedField(fieldType: fieldType, value: &value)
    }

    mutating func decodeRepeatedGroupField<G: Message>(fieldType: G.Type, value: inout [G]) throws {
        // TODO: Complete this
    }
}

private struct ProtobufTextObjectFieldDecoder: TextFieldDecoder {
    var rejectConflictingOneof: Bool {return true}

    var scanner: ProtobufTextScanner

    mutating func decodeSingularMessageField<M: Message>(fieldType: M.Type, value: inout M?) throws {
        var message = M()
        var subDecoder = TextDecoder(scanner: scanner)
        try message.decodeFromTextObject(textDecoder: &subDecoder)
        value = message
    }

    mutating func decodeSingularGroupField<G: Message>(fieldType: G.Type, value: inout G?) throws {
        var group = G()
        var subDecoder = TextDecoder(scanner: scanner)
        try group.decodeFromTextObject(textDecoder: &subDecoder)
        value = group

    }

    mutating func decodeMapField<KeyType: MapKeyType, ValueType: MapValueType>(fieldType: ProtobufMap<KeyType, ValueType>.Type, value: inout ProtobufMap<KeyType, ValueType>.BaseType) throws where KeyType.BaseType: Hashable {
        var keyToken: TextToken?
        var state = TextDecoder.ObjectParseState.expectFirstKey
        while let token = try scanner.next() {
            switch token {
            case .string: // This is a key
                if state != .expectKey && state != .expectFirstKey {
                    throw DecodingError.malformedText
                }
                keyToken = token
                state = .expectColon
            case .colon:
                if state != .expectColon {
                    throw DecodingError.malformedText
                }
                if let keyToken = keyToken,
                    let mapKey = try KeyType.decodeTextMapKey(token: keyToken),
                    let token = try scanner.next() {

                    let mapValue: ValueType.BaseType?
                    scanner.pushback(token: token)
                    var subDecoder = TextDecoder(scanner: scanner)
                    switch token {
                    case .beginObject, .string:
                        mapValue = try ValueType.decodeTextMapValue(textDecoder: &subDecoder)
                        if mapValue == nil {
                            throw DecodingError.malformedText
                        }
                    default:
                        if token.isNumber {
                            mapValue = try ValueType.decodeTextMapValue(textDecoder: &subDecoder)
                            if mapValue == nil {
                                throw DecodingError.malformedText
                            }
                        } else {
                            throw DecodingError.malformedText
                        }
                    }
                    value[mapKey] = mapValue
                } else {
                    throw DecodingError.malformedText
                }
                state = .expectComma
            case .comma:
                if state != .expectComma {
                    throw DecodingError.malformedText
                }
                state = .expectKey
            case .endObject:
                if state != .expectFirstKey && state != .expectComma {
                    throw DecodingError.malformedText
                }
                return
            default:
                throw DecodingError.malformedText
            }
        }
        throw DecodingError.truncatedInput
    }

    mutating func decodeRepeatedMessageField<M: Message>(fieldType: M.Type, value: inout [M]) throws {
        var message = M()
        var subDecoder = TextDecoder(scanner: scanner)
        try message.decodeFromTextObject(textDecoder: &subDecoder)
        value.append(message)
    }

    mutating func decodeRepeatedGroupField<G: Message>(fieldType: G.Type, value: inout [G]) throws {
        // TODO: Complete this
    }

}

internal struct TextArrayFieldDecoder: TextFieldDecoder {
    var scanner: ProtobufTextScanner

    // Decode a field containing repeated basic type
    // The leading '[' has already been consumed
    // Note: Google requires that we reject trailing commas
    mutating func decodeRepeatedField<S: FieldType>(fieldType: S.Type, value: inout [S.BaseType]) throws {
        var token: TextToken
        if let startToken = try scanner.next() {
            switch startToken {
            case .endArray: return // Empty array case
            default: token = startToken
            }
        } else {
            throw DecodingError.truncatedInput
        }
        while true {
            switch token {
            case .string, .identifier, .octalInteger, .hexadecimalInteger, .decimalInteger, .floatingPointLiteral:
                try S.setFromTextToken(token: token, value: &value)
            default:
                throw DecodingError.malformedText
            }
            if let separatorToken = try scanner.next() {
                switch separatorToken {
                case .comma:
                    if let t = try scanner.next() {
                        token = t
                    } else {
                        throw DecodingError.truncatedInput
                    }
                case .endArray:
                    return
                default:
                    throw DecodingError.malformedText
                }
            } else {
                throw DecodingError.truncatedInput
            }
        }
    }

    mutating func decodePackedField<S: FieldType>(fieldType: S.Type, value: inout [S.BaseType]) throws {
        try decodeRepeatedField(fieldType: fieldType, value: &value)
    }

    mutating func decodeRepeatedMessageField<M: Message>(fieldType: M.Type, value: inout [M]) throws {
        var token: TextToken
        if let startToken = try scanner.next() {
            switch startToken {
            case .endArray: return // Empty array case
            default: token = startToken
            }
        } else {
            throw DecodingError.truncatedInput
        }

        while true {
            switch token {
            case .beginObject:
                var message = M()
                var subDecoder = TextDecoder(scanner: scanner)
                try message.decodeFromTextObject(textDecoder: &subDecoder)
                value.append(message)
            default:
                throw DecodingError.malformedText
            }
            if let separatorToken = try scanner.next() {
                switch separatorToken {
                case .comma:
                    if let t = try scanner.next() {
                        token = t
                    } else {
                        throw DecodingError.truncatedInput
                    }
                case .endArray:
                    return
                default:
                    throw DecodingError.malformedText
                }
            } else {
                throw DecodingError.truncatedInput
            }
        }
    }

    mutating func decodeRepeatedGroupField<G: Message>(fieldType: G.Type, value: inout [G]) throws {
        var token: TextToken
        if let startToken = try scanner.next() {
            switch startToken {
            case .endArray: return // Empty array case
            default: token = startToken
            }
        } else {
            throw DecodingError.truncatedInput
        }

        while true {
            switch token {
            case .beginObject:
                var group = G()
                var subDecoder = TextDecoder(scanner: scanner)
                try group.decodeFromTextObject(textDecoder: &subDecoder)
                value.append(group)
            default:
                throw DecodingError.malformedText
            }
            if let separatorToken = try scanner.next() {
                switch separatorToken {
                case .comma:
                    if let t = try scanner.next() {
                        token = t
                    } else {
                        throw DecodingError.truncatedInput
                    }
                    break
                case .endArray:
                    return
                default:
                    throw DecodingError.malformedText
                }
            }
        }
    }
}
