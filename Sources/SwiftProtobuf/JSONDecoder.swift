// ProtobufRuntime/Sources/Protobuf/ProtobufJSONDecoding.swift - JSON decoding
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
/// JSON decoding engine.
///
/// This comprises:
/// * A token struct that represents a single JSON token
/// * A scanner that decomposes a string into JSON tokens.
/// * A decoder that provides high-level parsing functions
///   of the token string.
/// * A collection of FieldDecoder types that handle field-level
///   parsing for each type of JSON data.
///
/// A wrinkle:  you can also instantiate a JSON scanner with
/// a pre-parsed list of tokens.  This is used by Any to defer
/// JSON decoding when schema details are not yet available.
///
// -----------------------------------------------------------------------------

import Foundation
import Swift

///
/// Provides a higher-level interface to the JSON token stream coming
/// from a ProtobufJSONScanner.  In particular, this provides single-token
/// pushback and convenience functions for iterating over complex
/// structures.
///
public struct JSONDecoder {
    private var scanner: JSONScanner
    public var complete: Bool {return scanner.complete}


    public enum ObjectParseState {
        case expectFirstKey
        case expectKey
        case expectColon
        case expectComma
    }

    public init(json: String) {
        scanner = JSONScanner(json: json, tokens: [])
    }

    public init(tokens: [JSONToken]) {
        scanner = JSONScanner(json: "", tokens: tokens)
    }

    fileprivate init(scanner: JSONScanner) {
        self.scanner = scanner
    }

    public mutating func pushback(token: JSONToken) {
        scanner.pushback(token: token)
    }

    /// Returns nil if no more tokens, throws an error if
    /// the data being parsed is malformed.
    public mutating func nextToken() throws -> JSONToken? {
        return try scanner.next()
    }

    public mutating func decodeFullObject<M: Message>(message: inout M) throws {
        guard let token = try nextToken() else {throw DecodingError.truncatedInput}
        switch token {
        case .null:
            return
        case .beginArray:
            try message.decodeFromJSONArray(jsonDecoder: &self)
            if !complete {
                throw DecodingError.trailingGarbage
            }
        case .beginObject:
            try message.decodeFromJSONObject(jsonDecoder: &self)
            if !complete {
                throw DecodingError.trailingGarbage
            }
        case .string(_), .number(_), .boolean(_):
            // Some special types can decode themselves
            // from a single token (e.g., Timestamp)
            try message.decodeFromJSONToken(token: token)
        default:
            throw DecodingError.malformedJSON
        }
    }

    public mutating func decodeValue<M: Message>(key: String, message: inout M) throws {
        guard let nameProviding = (M.self as? ProtoNameProviding.Type) else {
            throw DecodingError.missingFieldNames
        }
        if let token = try nextToken() {
            let protoFieldNumber = nameProviding._protobuf_fieldNames.fieldNumber(forJSONName: key)
            switch token {
            case .colon, .comma, .endObject, .endArray:
                throw DecodingError.malformedJSON
            case .beginObject:
                var fieldDecoder:FieldDecoder = JSONObjectFieldDecoder(scanner: scanner)
                if let protoFieldNumber = protoFieldNumber {
                    try message.decodeField(setter: &fieldDecoder, protoFieldNumber: protoFieldNumber)
                } else {
                    var skipped: [JSONToken] = []
                    try skipObject(tokens: &skipped)
                }
            case .beginArray:
                var fieldDecoder:FieldDecoder = JSONArrayFieldDecoder(scanner: scanner)
                if let protoFieldNumber = protoFieldNumber {
                    try message.decodeField(setter: &fieldDecoder, protoFieldNumber: protoFieldNumber)
                } else {
                    var skipped: [JSONToken] = []
                    try skipArray(tokens: &skipped)
                }
            case .null:
                var fieldDecoder:FieldDecoder = JSONNullFieldDecoder(scanner: scanner)
                if let protoFieldNumber = protoFieldNumber {
                    try message.decodeField(setter: &fieldDecoder, protoFieldNumber: protoFieldNumber)
                }
                // Don't need to handle false case here; null token is already skipped
            case .boolean(_), .string(_), .number(_):
                var fieldDecoder:FieldDecoder = JSONSingleTokenFieldDecoder(token: token, scanner: scanner)
                if let protoFieldNumber = protoFieldNumber {
                    try message.decodeField(setter: &fieldDecoder, protoFieldNumber: protoFieldNumber)
                } else {
                    // Token was already implicitly skipped, but we
                    // need to handle one deferred failure check:
                    if case .number(_) = token, token.asDouble == nil {
                        throw DecodingError.malformedJSONNumber
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
    public mutating func skip() throws -> [JSONToken] {
        var tokens = [JSONToken]()
        try skipValue(tokens: &tokens)
        return tokens
    }

    private mutating func skipValue(tokens: inout [JSONToken]) throws {
        if let token = try nextToken() {
            switch token {
            case .beginObject:
                try skipObject(tokens: &tokens)
            case .beginArray:
                try skipArray(tokens: &tokens)
            case .endObject, .endArray, .comma, .colon:
                throw DecodingError.malformedJSON
            case .number(_):
                // Make sure numbers are actually syntactically valid
                if token.asDouble == nil {
                    throw DecodingError.malformedJSONNumber
                }
                tokens.append(token)
            default:
                tokens.append(token)
            }
        } else {
            throw DecodingError.truncatedInput
        }
    }

    // Assumes begin object already consumed
    private mutating func skipObject( tokens: inout [JSONToken]) throws {
        tokens.append(.beginObject)
        if let token = try nextToken() {
            switch token {
            case .endObject:
                tokens.append(token)
                return
            case .string(_):
                pushback(token: token)
            default:
                throw DecodingError.malformedJSON
            }
        } else {
            throw DecodingError.truncatedInput
        }

        while true {
            if let token = try nextToken() {
                if case .string(_) = token {
                    tokens.append(token)
                } else {
                    throw DecodingError.malformedJSON
                }
            }

            if let token = try nextToken() {
                if case .colon = token {
                    tokens.append(token)
                } else {
                    throw DecodingError.malformedJSON
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
                    throw DecodingError.malformedJSON
                }
            }
        }
    }

    private mutating func skipArray( tokens: inout [JSONToken]) throws {
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
                    throw DecodingError.malformedJSON
                }
            }
        }
    }
}

protocol JSONFieldDecoder: FieldDecoder {
    var scanner: JSONScanner {get}
}

extension JSONFieldDecoder {
    public mutating func decodeExtensionField(values: inout ExtensionFieldValueSet, messageType: Message.Type, protoFieldNumber: Int) throws {
    }
}

private struct JSONNullFieldDecoder: JSONFieldDecoder {
    let scanner: JSONScanner
    var rejectConflictingOneof: Bool {return true}

    mutating func decodeSingularField<S: FieldType>(fieldType: S.Type, value: inout S.BaseType?) throws {
    }
    mutating func decodeRepeatedField<S: FieldType>(fieldType: S.Type, value: inout [S.BaseType]) throws {
    }
    mutating func decodePackedField<S: FieldType>(fieldType: S.Type, value: inout [S.BaseType]) throws {
    }
    mutating func decodeSingularMessageField<M: Message>(fieldType: M.Type, value: inout M?) throws {
        value = try M.decodeFromJSONNull()
    }
    mutating func decodeRepeatedMessageField<M: Message>(fieldType: M.Type, value: inout [M]) throws {
    }
    mutating func decodeSingularGroupField<G: Message>(fieldType: G.Type, value: inout G?) throws {
    }
    mutating func decodeRepeatedGroupField<G: Message>(fieldType: G.Type, value: inout [G]) throws {
    }
    mutating func decodeMapField<KeyType: MapKeyType, ValueType: MapValueType>(fieldType: ProtobufMap<KeyType, ValueType>.Type, value: inout ProtobufMap<KeyType, ValueType>.BaseType) throws where KeyType.BaseType: Hashable {
    }
    mutating func decodeExtensionField(values: inout ExtensionFieldValueSet, messageType: Message.Type, protoFieldNumber: Int) throws {
    }
}

private struct JSONSingleTokenFieldDecoder: JSONFieldDecoder {
    var rejectConflictingOneof: Bool {return true}

    var token: JSONToken
    var scanner: JSONScanner

    mutating func decodeSingularField<S: FieldType>(fieldType: S.Type, value: inout S.BaseType?) throws {
        try S.setFromJSONToken(token: token, value: &value)
    }

    mutating func decodeSingularMessageField<M: Message>(fieldType: M.Type, value: inout M?) throws {
        var m = M()
        try m.decodeFromJSONToken(token: token)
        value = m
    }
}

private struct JSONObjectFieldDecoder: JSONFieldDecoder {
    var rejectConflictingOneof: Bool {return true}

    var scanner: JSONScanner

    mutating func decodeSingularMessageField<M: Message>(fieldType: M.Type, value: inout M?) throws {
        var message = M()
        var subDecoder = JSONDecoder(scanner: scanner)
        try message.decodeFromJSONObject(jsonDecoder: &subDecoder)
        value = message
    }

    mutating func decodeSingularGroupField<G: Message>(fieldType: G.Type, value: inout G?) throws {
        var group = G()
        var subDecoder = JSONDecoder(scanner: scanner)
        try group.decodeFromJSONObject(jsonDecoder: &subDecoder)
        value = group
    }
    mutating func decodeMapField<KeyType: MapKeyType, ValueType: MapValueType>(fieldType: ProtobufMap<KeyType, ValueType>.Type, value: inout ProtobufMap<KeyType, ValueType>.BaseType) throws where KeyType.BaseType: Hashable {
        var keyToken: JSONToken?
        var state = JSONDecoder.ObjectParseState.expectFirstKey
        while let token = try scanner.next() {
            switch token {
            case .string(_): // This is a key
                if state != .expectKey && state != .expectFirstKey {
                    throw DecodingError.malformedJSON
                }
                keyToken = token
                state = .expectColon
            case .colon:
                if state != .expectColon {
                    throw DecodingError.malformedJSON
                }
                if let keyToken = keyToken,
                    let mapKey = try KeyType.decodeJSONMapKey(token: keyToken),
                    let token = try scanner.next() {

                    let mapValue: ValueType.BaseType?
                    scanner.pushback(token: token)
                    var subDecoder = JSONDecoder(scanner: scanner)
                    switch token {
                    case .beginObject, .boolean(_), .string(_), .number(_):
                        mapValue = try ValueType.decodeJSONMapValue(jsonDecoder: &subDecoder)
                        if mapValue == nil {
                            throw DecodingError.malformedJSON
                        }
                    default:
                        throw DecodingError.malformedJSON
                    }
                    value[mapKey] = mapValue
                } else {
                    throw DecodingError.malformedJSON
                }
                state = .expectComma
            case .comma:
                if state != .expectComma {
                    throw DecodingError.malformedJSON
                }
                state = .expectKey
            case .endObject:
                if state != .expectFirstKey && state != .expectComma {
                    throw DecodingError.malformedJSON
                }
                return
            default:
                throw DecodingError.malformedJSON
            }
        }
        throw DecodingError.truncatedInput
    }
}

internal struct JSONArrayFieldDecoder: JSONFieldDecoder {
    var scanner: JSONScanner

    // Decode a field containing repeated basic type
    mutating func decodeRepeatedField<S: FieldType>(fieldType: S.Type, value: inout [S.BaseType]) throws {
        var token: JSONToken
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
            case .boolean(_), .string(_), .number(_):
                try S.setFromJSONToken(token: token, value: &value)
            default:
                throw DecodingError.malformedJSON
            }
            if let separatorToken = try scanner.next() {
                switch separatorToken {
                case .comma:
                    if let t = try scanner.next() {
                       token = t
                    } else {
                       throw DecodingError.malformedJSON
                    }
                    break
                case .endArray:
                    return
                default:
                    throw DecodingError.malformedJSON
                }
            }
        }
    }

    mutating func decodePackedField<S: FieldType>(fieldType: S.Type, value: inout [S.BaseType]) throws {
        try decodeRepeatedField(fieldType: fieldType, value: &value)
    }

    mutating func decodeSingularMessageField<M: Message>(fieldType: M.Type, value: inout M?) throws {
        var m = value ?? M()
        var subDecoder = JSONDecoder(scanner: scanner)
        try m.decodeFromJSONArray(jsonDecoder: &subDecoder)
        value = m
    }

    mutating func decodeRepeatedMessageField<M: Message>(fieldType: M.Type, value: inout [M]) throws {
        var token: JSONToken
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
                var subDecoder = JSONDecoder(scanner: scanner)
                try message.decodeFromJSONObject(jsonDecoder: &subDecoder)
                value.append(message)
            case .boolean(_), .string(_), .number(_):
                var message = M()
                try message.decodeFromJSONToken(token: token)
                value.append(message)
            case .null:
                if let message = try M.decodeFromJSONNull() {
                    // Sometimes 'null' is a valid message value
                    value.append(message)
                } else {
                    // Otherwise, null is not allowed in repeated fields
                    throw DecodingError.malformedJSON
                }
            default:
                throw DecodingError.malformedJSON
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
                    throw DecodingError.malformedJSON
                }
            }
        }
    }

    mutating func decodeRepeatedGroupField<G: Message>(fieldType: G.Type, value: inout [G]) throws {
        var token: JSONToken
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
                var subDecoder = JSONDecoder(scanner: scanner)
                try group.decodeFromJSONObject(jsonDecoder: &subDecoder)
                value.append(group)
            default:
                throw DecodingError.malformedJSON
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
                    throw DecodingError.malformedJSON
                }
            }
        }
    }
}


