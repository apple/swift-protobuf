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

private func parseIdentifier(firstCharacter: Character, charGenerator: inout String.CharacterView.Generator) -> String? {
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

private func parseQuotedString(charGenerator: inout String.CharacterView.Generator, terminator: Character) -> String? {
    var result = ""
    while let c = charGenerator.next() {
        if c == terminator {
            return result
        }
        switch c {
        case "\\":
            if let escaped = charGenerator.next() {
                result.append("\\")
                result.append(escaped)
            } else {
                return nil // Input ends in backslash

            }
        default:
            result.append(c)
        }
    }
    return nil // Unterminated quoted string
}

class ProtobufTextScanner {
    internal var extensions: ExtensionSet?
    private var charGenerator: String.CharacterView.Generator
    private var characterPushback: Character?
    private var tokenPushback: [TextToken]
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

    public init(text: String, tokens: [TextToken], extensions: ExtensionSet? = nil) {
        charGenerator = text.characters.makeIterator()
        tokenPushback = tokens.reversed()
        self.extensions = extensions
    }

    public func pushback(token: TextToken) {
        tokenPushback.append(token)
    }

    public func next() throws -> TextToken? {
        if let t = tokenPushback.popLast() {
            return t
        }
        if eof {
            return nil
        }
        while let c = characterPushback ?? charGenerator.next() {
            characterPushback = nil
            switch c {
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
            case "\'", "\"": // string
                wordSeparator = true
                if let s = parseQuotedString(charGenerator: &charGenerator, terminator: c) {
                    // Recurse to combine consecutive strings
                    if let n = try next() {
                        if case .string(let additional) = n {
                            return .string(s + additional)
                        } else {
                            pushback(token: n)
                        }
                    }
                    return .string(s)
                }
                throw DecodingError.malformedText
            case "-", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9":
                if wordSeparator {
                    wordSeparator = false
                    var s = String(c)
                    while let c = charGenerator.next() {
                        switch c {
                        case "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ".", "+", "-", "e", "E":
                            s.append(c)
                        case "f", "u":
                            // proto1 allowed floats to be suffixed with 'f'
                            // and unsigned integers to be suffixed with 'u'
                            // Just ignore it:
                            return .number(s)
                        default:
                            characterPushback = c // Note: Only place we need pushback
                            return .number(s)
                        }
                    }
                    return .number(s)
                }
                throw DecodingError.malformedText
            default:
                wordSeparator = false
                if let s = parseIdentifier(firstCharacter: c, charGenerator: &charGenerator) {
                    return .identifier(s)
                } else {
                    throw DecodingError.malformedText
                }
            }
        }
        eof = true
        return nil
    }
}
