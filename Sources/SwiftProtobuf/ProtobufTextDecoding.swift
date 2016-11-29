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

private func fromHexDigit(_ c: Character?) -> UInt32? {
    if let c = c {
        switch c {
        case "0": return 0
        case "1": return 1
        case "2": return 2
        case "3": return 3
        case "4": return 4
        case "5": return 5
        case "6": return 6
        case "7": return 7
        case "8": return 8
        case "9": return 9
        case "a", "A": return 10
        case "b", "B": return 11
        case "c", "C": return 12
        case "d", "D": return 13
        case "e", "E": return 14
        case "f", "F": return 15
        default: return nil
        }
    }
    return nil
}

///
/// Provides a higher-level interface to the JSON token stream coming
/// from a ProtobufTextScanner.  In particular, this provides single-token
/// pushback and convenience functions for iterating over complex
/// structures.
///
public struct ProtobufTextDecoder {
    private var scanner: ProtobufTextScanner
    public var complete: Bool {return scanner.complete}
    
    
    public enum ObjectParseState {
        case expectFirstKey
        case expectKey
        case expectColon
        case expectComma
    }
    
    public init(text: String, extensions: ProtobufExtensionSet? = nil) {
        scanner = ProtobufTextScanner(text: text, tokens: [], extensions: extensions)
    }
    
    public init(tokens: [ProtobufTextToken]) {
        scanner = ProtobufTextScanner(text: "", tokens: tokens)
    }
    
    fileprivate init(scanner: ProtobufTextScanner) {
        self.scanner = scanner
    }
    
    public mutating func pushback(token: ProtobufTextToken) {
        scanner.pushback(token: token)
    }
    
    /// Returns nil if no more tokens, throws an error if
    /// the data being parsed is malformed.
    public mutating func nextToken(expectKey:Bool = false) throws -> ProtobufTextToken? {
        return try scanner.next(expectKey:expectKey)
    }

    public func nextTokenIsBeginObject() throws -> Bool {
        guard let nextToken = try scanner.next() else {throw ProtobufDecodingError.truncatedInput}
        if (nextToken == .beginObject) {
            return true
        }
        scanner.pushback(token: nextToken)
        return false
    }

    public mutating func decodeFullObject<M: ProtobufTextMessageBase>(message: inout M, alreadyInsideObject: Bool = false) throws {
        if alreadyInsideObject {
            try message.decodeFromTextObject(textDecoder: &self)
            if !complete {
                throw ProtobufDecodingError.trailingGarbage
            }
        } else {
            guard let token = try nextToken(expectKey:true) else {throw ProtobufDecodingError.truncatedInput}
            switch token {
            case .null:
                return
            case .beginArray:
                try message.decodeFromTextArray(textDecoder: &self)
                if !complete {
                    throw ProtobufDecodingError.trailingGarbage
                }
            case .beginObject:
                try message.decodeFromTextObject(textDecoder: &self)
                if !complete {
                    throw ProtobufDecodingError.trailingGarbage
                }
            case .string, .number, .boolean:
                // Some special types can decode themselves
                // from a single token (e.g., Timestamp)
                try message.decodeFromTextToken(token: token)
            default:
                throw ProtobufDecodingError.malformedJSON
            }
        }
    }
    
    // TODO: ProtobufMessage here should be ProtobufFieldDecodableType to encompass both groups and messages
    // then this can merge with the decodeValue below...
    public mutating func decodeValue<M: ProtobufMessage>(key: String, message: inout M, parsingObject:Bool = false) throws {
        var handled = false
        let protoFieldNumber = (message.jsonFieldNames[key]
            ?? message.protoFieldNames[key]
            ?? scanner.extensions?.fieldNumberForJson(messageType: M.self, jsonFieldName: key))

        if parsingObject {
            var fieldDecoder:ProtobufFieldDecoder = ProtobufTextObjectFieldDecoder(scanner: scanner)
            if let protoFieldNumber = protoFieldNumber {
                handled = try message.decodeField(setter: &fieldDecoder, protoFieldNumber: protoFieldNumber)
            }
            if !handled {
                var skipped: [ProtobufTextToken] = []
                try skipObject(tokens: &skipped)
            }
        } else {
            if let token = try nextToken() {
                switch token {
                case .colon, .comma, .endObject, .endArray:
                    throw ProtobufDecodingError.malformedJSON
                case .beginObject:
                    break
                case .beginArray:
                    var fieldDecoder:ProtobufFieldDecoder = ProtobufTextArrayFieldDecoder(scanner: scanner)
                    if let protoFieldNumber = protoFieldNumber {
                        handled = try message.decodeField(setter: &fieldDecoder, protoFieldNumber: protoFieldNumber)
                    }
                    if !handled {
                        var skipped: [ProtobufTextToken] = []
                        try skipArray(tokens: &skipped)
                    }
                case .null:
                    var fieldDecoder:ProtobufFieldDecoder = ProtobufTextNullFieldDecoder(scanner: scanner)
                    if let protoFieldNumber = protoFieldNumber {
                        handled = try message.decodeField(setter: &fieldDecoder, protoFieldNumber: protoFieldNumber)
                    }
                // Don't need to handle false case here; null token is already skipped
                case .boolean, .string, .number:
                    var fieldDecoder:ProtobufFieldDecoder = ProtobufTextSingleTokenFieldDecoder(token: token, scanner: scanner)
                    if let protoFieldNumber = protoFieldNumber {
                        handled = try message.decodeField(setter: &fieldDecoder, protoFieldNumber: protoFieldNumber)
                    }
                    if !handled {
                        // Token was already implicitly skipped, but we
                        // need to handle one deferred failure check:
                        if case .number = token, token.asDouble == nil {
                            throw ProtobufDecodingError.malformedJSONNumber
                        }
                    }
                }
            } else {
                throw ProtobufDecodingError.truncatedInput
            }
        }        
    }
    
    public mutating func decodeValue<G: ProtobufMessage>(key: String, group: inout G) throws {
        if let token = try nextToken() {
            let protoFieldNumber = (group.jsonFieldNames[key]
                ?? group.protoFieldNames[key])
            // TODO: Look up field number for extension?
            //?? scanner.extensions?.fieldNumberForJson(messageType: G.self, jsonFieldName: key))
            switch token {
            case .colon, .comma, .endObject, .endArray:
                throw ProtobufDecodingError.malformedJSON
            case .beginObject:
                var handled = false
                var fieldDecoder:ProtobufFieldDecoder = ProtobufTextObjectFieldDecoder(scanner: scanner)
                if let protoFieldNumber = protoFieldNumber {
                    handled = try group.decodeField(setter: &fieldDecoder, protoFieldNumber: protoFieldNumber)
                }
                if !handled {
                    var skipped: [ProtobufTextToken] = []
                    try skipObject(tokens: &skipped)
                }
            case .beginArray:
                var handled = false
                var fieldDecoder:ProtobufFieldDecoder = ProtobufTextArrayFieldDecoder(scanner: scanner)
                if let protoFieldNumber = protoFieldNumber {
                    handled = try group.decodeField(setter: &fieldDecoder, protoFieldNumber: protoFieldNumber)
                }
                if !handled {
                    var skipped: [ProtobufTextToken] = []
                    try skipArray(tokens: &skipped)
                }
            case .null:
                var fieldDecoder:ProtobufFieldDecoder = ProtobufTextNullFieldDecoder(scanner: scanner)
                if let protoFieldNumber = protoFieldNumber {
                    _ = try group.decodeField(setter: &fieldDecoder, protoFieldNumber: protoFieldNumber)
                }
            // Don't need to handle false case here; null token is already skipped
            case .boolean, .string, .number:
                var handled = false
                var fieldDecoder:ProtobufFieldDecoder = ProtobufTextSingleTokenFieldDecoder(token: token, scanner: scanner)
                if let protoFieldNumber = protoFieldNumber {
                    handled = try group.decodeField(setter: &fieldDecoder, protoFieldNumber: protoFieldNumber)
                }
                if !handled {
                    // Token was already implicitly skipped, but we
                    // need to handle one deferred failure check:
                    if case .number = token, token.asDouble == nil {
                        throw ProtobufDecodingError.malformedJSONNumber
                    }
                }
            }
        } else {
            throw ProtobufDecodingError.truncatedInput
        }
    }
    
    
    // Build parseArrayFields() method, use it.
    
    /// Updates the provided array with the tokens that were skipped.
    /// This is used for deferred parsing of Any fields.
    public mutating func skip() throws -> [ProtobufTextToken] {
        var tokens = [ProtobufTextToken]()
        try skipValue(tokens: &tokens)
        return tokens
    }
    
    private mutating func skipValue(tokens: inout [ProtobufTextToken]) throws {
        if let token = try nextToken() {
            switch token {
            case .beginObject:
                try skipObject(tokens: &tokens)
            case .beginArray:
                try skipArray(tokens: &tokens)
            case .endObject, .endArray, .comma, .colon:
                throw ProtobufDecodingError.malformedJSON
            case .number:
                // Make sure numbers are actually syntactically valid
                if token.asDouble == nil {
                    throw ProtobufDecodingError.malformedJSONNumber
                }
                tokens.append(token)
            default:
                tokens.append(token)
            }
        } else {
            throw ProtobufDecodingError.truncatedInput
        }
    }
    
    // Assumes begin object already consumed
    private mutating func skipObject( tokens: inout [ProtobufTextToken]) throws {
        tokens.append(.beginObject)
        if let token = try nextToken() {
            switch token {
            case .endObject:
                tokens.append(token)
                return
            case .string:
                pushback(token: token)
            default:
                throw ProtobufDecodingError.malformedJSON
            }
        } else {
            throw ProtobufDecodingError.truncatedInput
        }
        
        while true {
            if let token = try nextToken() {
                if case .string = token {
                    tokens.append(token)
                } else {
                    throw ProtobufDecodingError.malformedJSON
                }
            }
            
            if let token = try nextToken() {
                if case .colon = token {
                    tokens.append(token)
                } else {
                    throw ProtobufDecodingError.malformedJSON
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
                    throw ProtobufDecodingError.malformedJSON
                }
            }
        }
    }
    
    private mutating func skipArray( tokens: inout [ProtobufTextToken]) throws {
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
            throw ProtobufDecodingError.truncatedInput
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
                    throw ProtobufDecodingError.malformedJSON
                }
            }
        }
    }
}

public protocol ProtobufTextFieldDecoder: ProtobufFieldDecoder {
    var scanner: ProtobufTextScanner {get}
}

extension ProtobufTextFieldDecoder {
    public mutating func decodeExtensionField(values: inout ProtobufExtensionFieldValueSet, messageType: ProtobufMessage.Type, protoFieldNumber: Int) throws -> Bool {
        if let ext = scanner.extensions?[messageType, protoFieldNumber] {
            var mutableSetter: ProtobufFieldDecoder = self
            var fieldValue = values[protoFieldNumber] ?? ext.newField()
            if try fieldValue.decodeField(setter: &mutableSetter) {
                values[protoFieldNumber] = fieldValue
                return true
            }
        }
        return false
    }
}

private struct ProtobufTextNullFieldDecoder: ProtobufTextFieldDecoder {
    let scanner: ProtobufTextScanner
    var rejectConflictingOneof: Bool {return true}
    
    mutating func decodeSingularField<S: ProtobufTypeProperties>(fieldType: S.Type, value: inout S.BaseType?) throws -> Bool {
        return true
    }
    mutating func decodeRepeatedField<S: ProtobufTypeProperties>(fieldType: S.Type, value: inout [S.BaseType]) throws -> Bool {
        return true
    }
    mutating func decodePackedField<S: ProtobufTypeProperties>(fieldType: S.Type, value: inout [S.BaseType]) throws -> Bool {
        return true
    }
    mutating func decodeSingularMessageField<M: ProtobufMessage>(fieldType: M.Type, value: inout M?) throws -> Bool {
        value = try M.decodeFromTextNull()
        return true
    }
    mutating func decodeRepeatedMessageField<M: ProtobufMessage>(fieldType: M.Type, value: inout [M]) throws -> Bool {
        return true
    }
    mutating func decodeSingularGroupField<G: ProtobufMessage>(fieldType: G.Type, value: inout G?) throws -> Bool {
        return true
    }
    mutating func decodeRepeatedGroupField<G: ProtobufMessage>(fieldType: G.Type, value: inout [G]) throws -> Bool {
        return true
    }
    mutating func decodeMapField<KeyType: ProtobufMapKeyType, ValueType: ProtobufMapValueType>(fieldType: ProtobufMap<KeyType, ValueType>.Type, value: inout ProtobufMap<KeyType, ValueType>.BaseType) throws -> Bool where KeyType.BaseType: Hashable {
        return true
    }
    mutating func decodeExtensionField(values: inout ProtobufExtensionFieldValueSet, messageType: ProtobufMessage.Type, protoFieldNumber: Int) throws -> Bool {
        return true
    }
}

private struct ProtobufTextSingleTokenFieldDecoder: ProtobufTextFieldDecoder {
    var rejectConflictingOneof: Bool {return true}
    
    var token: ProtobufTextToken
    var scanner: ProtobufTextScanner
    
    mutating func decodeSingularField<S: ProtobufTypeProperties>(fieldType: S.Type, value: inout S.BaseType?) throws -> Bool {
        try S.setFromTextToken(token: token, value: &value)
        return true
    }
    
    mutating func decodeSingularMessageField<M: ProtobufMessage>(fieldType: M.Type, value: inout M?) throws -> Bool {
        var m = M()
        try m.decodeFromTextToken(token: token)
        value = m
        return true
    }
    
    mutating func decodeRepeatedField<S: ProtobufTypeProperties>(fieldType: S.Type, value: inout [S.BaseType]) throws -> Bool {
        try S.setFromTextToken(token: token, value: &value)
        return true
    }
    
    mutating func decodePackedField<S: ProtobufTypeProperties>(fieldType: S.Type, value: inout [S.BaseType]) throws -> Bool {
        return try decodeRepeatedField(fieldType: fieldType, value: &value)
    }
    
    mutating func decodeRepeatedMessageField<M: ProtobufMessage>(fieldType: M.Type, value: inout [M]) throws -> Bool {
        var m = M()
        try m.decodeFromTextToken(token: token)
        value.append(m)
        return true
    }
    
    mutating func decodeRepeatedGroupField<G: ProtobufMessage>(fieldType: G.Type, value: inout [G]) throws -> Bool {
        // TODO: Complete this
        return true
    }
}

private struct ProtobufTextObjectFieldDecoder: ProtobufTextFieldDecoder {
    var rejectConflictingOneof: Bool {return true}
    
    var scanner: ProtobufTextScanner
    
    mutating func decodeSingularMessageField<M: ProtobufMessage>(fieldType: M.Type, value: inout M?) throws -> Bool {
        var message = M()
        var subDecoder = ProtobufTextDecoder(scanner: scanner)
        try message.decodeFromTextObject(textDecoder: &subDecoder)
        value = message
        return true
    }
    
    mutating func decodeSingularGroupField<G: ProtobufMessage>(fieldType: G.Type, value: inout G?) throws -> Bool {
        var group = G()
        var subDecoder = ProtobufTextDecoder(scanner: scanner)
        try group.decodeFromTextObject(textDecoder: &subDecoder)
        value = group
        return true
    }
    mutating func decodeMapField<KeyType: ProtobufMapKeyType, ValueType: ProtobufMapValueType>(fieldType: ProtobufMap<KeyType, ValueType>.Type, value: inout ProtobufMap<KeyType, ValueType>.BaseType) throws -> Bool where KeyType.BaseType: Hashable {
        var keyToken: ProtobufTextToken?
        var state = ProtobufTextDecoder.ObjectParseState.expectFirstKey
        while let token = try scanner.next() {
            switch token {
            case .string: // This is a key
                if state != .expectKey && state != .expectFirstKey {
                    throw ProtobufDecodingError.malformedJSON
                }
                keyToken = token
                state = .expectColon
            case .colon:
                if state != .expectColon {
                    throw ProtobufDecodingError.malformedJSON
                }
                if let keyToken = keyToken,
                    let mapKey = try KeyType.decodeTextMapKeyValue(token: keyToken),
                    let token = try scanner.next() {
                    
                    let mapValue: ValueType.BaseType?
                    scanner.pushback(token: token)
                    var subDecoder = ProtobufTextDecoder(scanner: scanner)
                    switch token {
                    case .beginObject, .boolean, .string, .number:
                        mapValue = try ValueType.decodeTextMapFieldValue(textDecoder: &subDecoder)
                        if mapValue == nil {
                            throw ProtobufDecodingError.malformedJSON
                        }
                    default:
                        throw ProtobufDecodingError.malformedJSON
                    }
                    value[mapKey] = mapValue
                } else {
                    throw ProtobufDecodingError.malformedJSON
                }
                state = .expectComma
            case .comma:
                if state != .expectComma {
                    throw ProtobufDecodingError.malformedJSON
                }
                state = .expectKey
            case .endObject:
                if state != .expectFirstKey && state != .expectComma {
                    throw ProtobufDecodingError.malformedJSON
                }
                return true
            default:
                throw ProtobufDecodingError.malformedJSON
            }
        }
        throw ProtobufDecodingError.truncatedInput
    }
    
    mutating func decodeRepeatedMessageField<M: ProtobufMessage>(fieldType: M.Type, value: inout [M]) throws -> Bool {
        var message = M()
        var subDecoder = ProtobufTextDecoder(scanner: scanner)
        try message.decodeFromTextObject(textDecoder: &subDecoder)
        value.append(message)
        return true
    }
    
    mutating func decodeRepeatedGroupField<G: ProtobufMessage>(fieldType: G.Type, value: inout [G]) throws -> Bool {
        // TODO: Complete this
        return true
    }

}

internal struct ProtobufTextArrayFieldDecoder: ProtobufTextFieldDecoder {
    var scanner: ProtobufTextScanner
    
    // Decode a field containing repeated basic type
    mutating func decodeRepeatedField<S: ProtobufTypeProperties>(fieldType: S.Type, value: inout [S.BaseType]) throws -> Bool {
        var token: ProtobufTextToken
        if let startToken = try scanner.next() {
            switch startToken {
            case .endArray: return true // Empty array case
            default: token = startToken
            }
        } else {
            throw ProtobufDecodingError.truncatedInput
        }
        
        while true {
            switch token {
            case .boolean, .string, .number:
                try S.setFromTextToken(token: token, value: &value)
            default:
                throw ProtobufDecodingError.malformedJSON
            }
            if let separatorToken = try scanner.next() {
                switch separatorToken {
                case .comma:
                    if let t = try scanner.next() {
                        token = t
                    } else {
                        throw ProtobufDecodingError.malformedJSON
                    }
                    break
                case .endArray:
                    return true
                default:
                    throw ProtobufDecodingError.malformedJSON
                }
            }
        }
    }
    
    mutating func decodePackedField<S: ProtobufTypeProperties>(fieldType: S.Type, value: inout [S.BaseType]) throws -> Bool {
        return try decodeRepeatedField(fieldType: fieldType, value: &value)
    }
    
    mutating func decodeSingularMessageField<M: ProtobufMessage>(fieldType: M.Type, value: inout M?) throws -> Bool {
        var m = value ?? M()
        var subDecoder = ProtobufTextDecoder(scanner: scanner)
        try m.decodeFromTextArray(textDecoder: &subDecoder)
        value = m
        return true
    }
    
    mutating func decodeRepeatedMessageField<M: ProtobufMessage>(fieldType: M.Type, value: inout [M]) throws -> Bool {
        var token: ProtobufTextToken
        if let startToken = try scanner.next() {
            switch startToken {
            case .endArray: return true // Empty array case
            default: token = startToken
            }
        } else {
            throw ProtobufDecodingError.truncatedInput
        }
        
        while true {
            switch token {
            case .beginObject:
                var message = M()
                var subDecoder = ProtobufTextDecoder(scanner: scanner)
                try message.decodeFromTextObject(textDecoder: &subDecoder)
                value.append(message)
            case .boolean, .string, .number:
                var message = M()
                try message.decodeFromTextToken(token: token)
                value.append(message)
            case .null:
                if let message = try M.decodeFromTextNull() {
                    // Sometimes 'null' is a valid message value
                    value.append(message)
                } else {
                    // Otherwise, null is not allowed in repeated fields
                    throw ProtobufDecodingError.malformedJSON
                }
            default:
                throw ProtobufDecodingError.malformedJSON
            }
            if let separatorToken = try scanner.next() {
                switch separatorToken {
                case .comma:
                    if let t = try scanner.next() {
                        token = t
                    } else {
                        throw ProtobufDecodingError.truncatedInput
                    }
                    break
                case .endArray:
                    return true
                default:
                    throw ProtobufDecodingError.malformedJSON
                }
            }
        }
    }
    
    mutating func decodeRepeatedGroupField<G: ProtobufMessage>(fieldType: G.Type, value: inout [G]) throws -> Bool {
        var token: ProtobufTextToken
        if let startToken = try scanner.next() {
            switch startToken {
            case .endArray: return true // Empty array case
            default: token = startToken
            }
        } else {
            throw ProtobufDecodingError.truncatedInput
        }
        
        while true {
            switch token {
            case .beginObject:
                var group = G()
                var subDecoder = ProtobufTextDecoder(scanner: scanner)
                try group.decodeFromTextObject(textDecoder: &subDecoder)
                value.append(group)
            default:
                throw ProtobufDecodingError.malformedJSON
            }
            if let separatorToken = try scanner.next() {
                switch separatorToken {
                case .comma:
                    if let t = try scanner.next() {
                        token = t
                    } else {
                        throw ProtobufDecodingError.truncatedInput
                    }
                    break
                case .endArray:
                    return true
                default:
                    throw ProtobufDecodingError.malformedJSON
                }
            }
        }
    }
}


private func parseUnquotedString( firstCharacter: Character, charGenerator: inout String.CharacterView.Generator) -> String? {
    var result = "\(firstCharacter)"
    var previousCharGenerator = charGenerator
    while let c = charGenerator.next() {
        switch c {
        case " ", "\t", "\r", "\n", ":", ",", "{", "}", "[", "]":
            charGenerator = previousCharGenerator
            return result
        default:
            result.append(c)
            previousCharGenerator = charGenerator
        }
    }
    return nil
}

private func parseQuotedString( charGenerator: inout String.CharacterView.Generator) -> String? {
    var result = ""
    while let c = charGenerator.next() {
        switch c {
        case "\"":
            return result
        case "\\":
            if let escaped = charGenerator.next() {
                switch escaped {
                case "b": result.append(Character("\u{0008}"))
                case "t": result.append(Character("\u{0009}"))
                case "n": result.append(Character("\u{000a}"))
                case "f": result.append(Character("\u{000c}"))
                case "r": result.append(Character("\u{000d}"))
                case "\"": result.append(escaped)
                case "\\": result.append(escaped)
                case "/": result.append(escaped)
                case "u":
                    if let c1 = fromHexDigit(charGenerator.next()),
                        let c2 = fromHexDigit(charGenerator.next()),
                        let c3 = fromHexDigit(charGenerator.next()),
                        let c4 = fromHexDigit(charGenerator.next()) {
                        let scalar = ((c1 * 16 + c2) * 16 + c3) * 16 + c4
                        if let char = UnicodeScalar(scalar) {
                            result.append(String(char))
                        } else if scalar < 0xD800 || scalar >= 0xE000 {
                            // Invalid Unicode scalar
                            return nil
                        } else if scalar >= UInt32(0xDC00) {
                            // Low surrogate is invalid
                            return nil
                        } else {
                            // We have a high surrogate, must be followed by low
                            if let slash = charGenerator.next(), slash == "\\",
                                let u = charGenerator.next(), u == "u",
                                let c1 = fromHexDigit(charGenerator.next()),
                                let c2 = fromHexDigit(charGenerator.next()),
                                let c3 = fromHexDigit(charGenerator.next()),
                                let c4 = fromHexDigit(charGenerator.next()) {
                                let follower = ((c1 * 16 + c2) * 16 + c3) * 16 + c4
                                if follower >= UInt32(0xDC00) && follower < UInt32(0xE000) {
                                    let high = scalar - UInt32(0xD800)
                                    let low = follower - UInt32(0xDC00)
                                    let composed = UInt32(0x10000) + high << 10 + low
                                    if let char = UnicodeScalar(composed) {
                                        result.append(String(char))
                                    } else {
                                        // Composed value is not valid
                                        return nil
                                    }
                                } else {
                                    // high surrogate was not followed by low
                                    return nil
                                }
                            } else {
                                // high surrogate not followed by unicode hex escape
                                return nil
                            }
                        }
                    } else {
                        // Broken unicode escape
                        return nil
                    }
                default:
                    // Unrecognized backslash escape
                    return nil
                }
            } else {
                // Input ends in backslash
                return nil
            }
        default:
            result.append(c)
        }
    }
    // Unterminated quoted string
    return nil
}

// Protobuf JSON allows integers (signed and unsigned) to be
// coded using floating-point exponential format, but does
// reject anything that actually has a fractional part.
// This code converts numbers like 4.294967e9 to a standard
// integer decimal string format 429496700 using only pure
// textual operations (adding/removing trailing zeros, removing
// decimal point character).  The result can be handed
// to IntMax(string:) or UIntMax(string:) as appropriate.
//
// Returns an array of Character (to make it easy for clients to
// check specific character values) or nil if the provided string
// cannot be normalized to a valid integer format.
//
// Here are some sample inputs and outputs to clarify what this function does:
//   = "0.1.2" => nil (extra period)
//   = "0x02" => nil (invalid 'x' character)
//   = "4.123" => nil (not an integer)
//   = "012" => nil (leading zero rejected)
//   = "0" => "0" (bare zero is okay)
//   = "400e-1" => "40" (adjust decimal point)
//   = "4.12e2" => "412" (adjust decimal point)
//   = "1.0000" => "1" (drop extraneous trailing zeros)
//
// Note: This does reject sequences that are "obviously" out
// of the range of a 64-bit integer, but that's just to avoid
// crazy cases like trying to build million-character string for
// "1e1000000".  The client code is responsible for real range
// checking.
//
private func normalizeIntString(_ s: String) -> [Character]? {
    var total = 0
    var digits = 0
    var fractionalDigits: Int?
    var hasLeadingZero = false
    var chars = s.characters.makeIterator()
    var number = [Character]()
    while let c = chars.next() {
        if hasLeadingZero { // Leading zero must be last character
            return nil
        }
        switch c {
        case "-":
            if total > 0 {
                return nil
            }
            number.append(c)
            total += 1
        case "0":
            if digits == 0 {
                hasLeadingZero = true
            }
            fallthrough
        case "1", "2", "3", "4", "5", "6", "7", "8", "9":
            if fractionalDigits != nil {
                fractionalDigits = fractionalDigits! + 1
            } else {
                digits += 1
            }
            number.append(c)
            total += 1
        case ".":
            if fractionalDigits != nil {
                return nil // Duplicate '.'
            }
            fractionalDigits = 0
            total += 1
        case "e", "E":
            var expString = ""
            var c2 = chars.next()
            if c2 == "+" || c2 == "-" {
                expString.append(c2!)
                c2 = chars.next()
            }
            if c2 == nil {
                return nil
            }
            while let expDigit = c2 {
                switch expDigit {
                case "0", "1", "2", "3", "4", "5", "6", "7", "8", "9":
                    expString.append(expDigit)
                default:
                    return nil
                }
                c2 = chars.next()
            }
            // Limit on exp here follows from:
            //   = 64-bit int has range less than 10 ^ 20,
            //     so a positive exponent can't result in
            //     more than 20 digits wihout overflow
            //   = Value must be integral, so a negative exponent
            //     can't be greater than number of digits
            // The limit here is deliberately sloppy, it is only intended
            // to avoid painful abuse cases (e.g., 1e1000000000 will be
            // quickly dropped without trying to build a an array
            // of a billion characters).
            if let exp = Int(expString), exp + digits < 20 && exp > -digits {
                // Fold fractional digits into exponent
                var adjustment = exp - (fractionalDigits ?? 0)
                fractionalDigits = 0
                // Adjust digit string to account for exponent
                while adjustment > 0 {
                    number.append("0")
                    adjustment -= 1
                }
                while adjustment < 0 {
                    if number.isEmpty || number[number.count - 1] != "0" {
                        return nil
                    }
                    number.remove(at: number.count - 1)
                    adjustment += 1
                }
            } else {
                // Error if exponent is malformed or out of range
                return nil
            }
        default:
            return nil
        }
    }
    if number.isEmpty {
        return nil
    }
    // Allow 7.000 and 1.23000e2 by trimming fractional zero digits
    if let f = fractionalDigits {
        var fractionalDigits = f
        while fractionalDigits > 0 && !number.isEmpty && number[number.count - 1] == "0" {
            number.remove(at: number.count - 1)
            fractionalDigits -= 1
        }
        if fractionalDigits > 0 {
            return nil
        }
    }
    return number
}

private func decodeBytes(_ s: String) -> Data? {
    var out = [UInt8]()
    let digits = s.utf8
    var n = 0
    var bits = 0
    for (i, digit) in digits.enumerated() {
        n <<= 6
        switch digit {
        case 65...90: n |= Int(digit - 65); bits += 6
        case 97...122: n |= Int(digit - 97 + 26); bits += 6
        case 48...57: n |= Int(digit - 48 + 52); bits += 6
        case 43: n |= 62; bits += 6
        case 47: n |= 63; bits += 6
        case 61: n |= 0
        default:
            return nil
        }
        if i % 4 == 3 {
            out.append(UInt8(truncatingBitPattern: n >> 16))
            if bits >= 16 {
                out.append(UInt8(truncatingBitPattern: n >> 8))
                if bits >= 24 {
                    out.append(UInt8(truncatingBitPattern: n))
                }
            }
            bits = 0
        }
    }
    if bits != 0 {
        return nil
    }
    return Data(bytes: out)
}


public enum ProtobufTextToken: Equatable, ProtobufFieldDecoder {
    case colon
    case comma
    case beginObject
    case endObject
    case beginArray
    case endArray
    case null
    case boolean(Bool)
    case string(String)
    case number(String)
    
    public var asBoolean: Bool? {
        switch self {
        case .boolean(let b): return b
        default: return nil
        }
    }
    
    public var asBooleanMapKey: Bool? {
        switch self {
        case .string("true"): return true
        case .string("false"): return false
        default: return nil
        }
    }
    
    var asInt64: Int64? {
        let text: String
        switch self {
        case .string(let s): text = s
        case .number(let n): text = n
        default: return nil
        }
        if let normalized = normalizeIntString(text) {
            let numberString = String(normalized)
            if let n = Int64(numberString) {
                return n
            }
        }
        return nil
    }
    
    var asInt32: Int32? {
        let text: String
        switch self {
        case .string(let s): text = s
        case .number(let n): text = n
        default: return nil
        }
        if let normalized = normalizeIntString(text) {
            let numberString = String(normalized)
            if let n = Int32(numberString) {
                return n
            }
        }
        return nil
    }
    
    var asUInt64: UInt64? {
        let text: String
        switch self {
        case .string(let s): text = s
        case .number(let n): text = n
        default: return nil
        }
        if let normalized = normalizeIntString(text), normalized[0] != "-" {
            let numberString = String(normalized)
            if let n = UInt64(numberString) {
                return n
            }
        }
        return nil
    }
    
    var asUInt32: UInt32? {
        let text: String
        switch self {
        case .string(let s): text = s
        case .number(let n): text = n
        default: return nil
        }
        if let normalized = normalizeIntString(text), normalized[0] != "-" {
            let numberString = String(normalized)
            if let n = UInt32(numberString) {
                return n
            }
        }
        return nil
    }
    
    var asFloat: Float? {
        switch self {
        case .string(let s): return Float(s)
        case .number(let n): return Float(n)
        default: return nil
        }
    }
    
    var asDouble: Double? {
        switch self {
        case .string(let s): return Double(s)
        case .number(let n): return Double(n)
        default: return nil
        }
    }
    
    var asBytes: Data? {
        switch self {
        case .string(let s): return decodeBytes(s)
        default: return nil
        }
    }
}

public func ==(lhs: ProtobufTextToken, rhs: ProtobufTextToken) -> Bool {
    switch (lhs, rhs) {
    case (.colon, .colon),
         (.comma, .comma),
         (.beginObject, .beginObject),
         (.endObject, .endObject),
         (.beginArray, .beginArray),
         (.endArray, .endArray),
         (.null, .null):
        return true
    case (.boolean(let a), .boolean(let b)):
        return a == b
    case (.string(let a), .string(let b)):
        return a == b
    case (.number(let a), .number(let b)):
        return a == b
    default:
        return false
    }
}

public class ProtobufTextScanner {
    fileprivate var extensions: ProtobufExtensionSet?
    private var charGenerator: String.CharacterView.Generator
    private var characterPushback: Character?
    private var tokenPushback: [ProtobufTextToken]
    private var eof: Bool = false
    private var wordSeparator: Bool = true
    public var complete: Bool {
        switch characterPushback {
        case .some(" "), .some("\t"), .some("\r"), .some("\n"): break
        case .none: break
        default:
            return false
        }
        var g = charGenerator
        while let c = g.next() {
            switch c {
            case " ", "\t", "\r", "\n":
                break
            default:
                return false
            }
        }
        return true
    }
    
    public init(text: String, tokens: [ProtobufTextToken], extensions: ProtobufExtensionSet? = nil) {
        charGenerator = text.characters.makeIterator()
        tokenPushback = tokens.reversed()
        self.extensions = extensions
    }
    
    public func pushback(token: ProtobufTextToken) {
        tokenPushback.append(token)
    }
    
    public func next(expectKey:Bool = false) throws -> ProtobufTextToken? {
        if eof {
            return nil
        }
        if let t = tokenPushback.popLast() {
            return t
        }
        while let next = characterPushback ?? charGenerator.next() {
            characterPushback = nil
            switch next {
            case " ", "\t", "\r", "\n":
                wordSeparator = true
                break
            case ":":
                wordSeparator = true
                return .colon
            case ",":
                wordSeparator = true
                return .comma
            case "{":
                wordSeparator = true
                return .beginObject
            case "}":
                wordSeparator = true
                return .endObject
            case "[":
                wordSeparator = true
                return .beginArray
            case "]":
                wordSeparator = true
                return .endArray
            case _ where expectKey == true:
                if wordSeparator {
                    wordSeparator = false
                    if let s = parseUnquotedString(firstCharacter: next, charGenerator: &charGenerator) {
                        return .string(s)
                    }
                }
                throw ProtobufDecodingError.malformedJSON
            case "n": // null
                if wordSeparator {
                    wordSeparator = false
                    if let u = charGenerator.next(), u == "u" {
                        if let l = charGenerator.next(), l == "l" {
                            if let l = charGenerator.next(), l == "l" {
                                return .null
                            }
                        }
                    }
                }
                throw ProtobufDecodingError.malformedJSON
            case "t": // true
                if wordSeparator {
                    wordSeparator = false
                    if let r = charGenerator.next(), r == "r" {
                        if let u = charGenerator.next(), u == "u" {
                            if let e = charGenerator.next(), e == "e" {
                                return .boolean(true)
                            }
                        }
                    }
                }
                throw ProtobufDecodingError.malformedJSON
            case "f": // false
                if wordSeparator {
                    wordSeparator = false
                    if let a = charGenerator.next(), a == "a" {
                        if let l = charGenerator.next(), l == "l" {
                            if let s = charGenerator.next(), s == "s" {
                                if let e = charGenerator.next(), e == "e" {
                                    return .boolean(false)
                                }
                            }
                        }
                    }
                }
                throw ProtobufDecodingError.malformedJSON
            case "\"": // string
                if wordSeparator {
                    wordSeparator = false
                    if let s = parseQuotedString(charGenerator: &charGenerator) {
                        return .string(s)
                    }
                }
                throw ProtobufDecodingError.malformedJSON
            case "-", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9":
                if wordSeparator {
                    wordSeparator = false
                    var s = String(next)
                    while let c = charGenerator.next() {
                        switch c {
                        case "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ".", "+", "-", "e", "E":
                            s.append(c)
                        default:
                            characterPushback = c // Note: Only place we need pushback
                            return .number(s)
                        }
                    }
                    return .number(s)
                }
                throw ProtobufDecodingError.malformedJSON
            default:
                if let s = parseUnquotedString(firstCharacter: next, charGenerator: &charGenerator) {
                    return .string(s)
                } else {
                    throw ProtobufDecodingError.malformedJSON
                }
            }
        }
        eof = true
        return nil
    }
}
