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

private func parseIdentifier(prefix: String, charGenerator: inout String.CharacterView.Generator) -> String? {
    var result = prefix
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
    return result
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
    var complete: Bool {
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

    init(text: String, tokens: [TextToken], extensions: ExtensionSet? = nil) {
        charGenerator = text.characters.makeIterator()
        tokenPushback = tokens.reversed()
        self.extensions = extensions
    }

    func pushback(token: TextToken) {
        tokenPushback.append(token)
    }

    private func parseHexInteger() -> String? {
        var s = String()
        while let c = charGenerator.next() {
            switch c {
            case "0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
                 "a", "A", "b", "B", "c", "C", "d", "D", "e", "E", "f", "F":
                s.append(c)
            default:
                characterPushback = c
                return s
            }
        }
        return s
    }

    private func parseOctalInteger() -> String? {
        var s = String()
        while let c = charGenerator.next() {
            switch c {
            case "0", "1", "2", "3", "4", "5", "6", "7":
                s.append(c)
            default:
                characterPushback = c
                return s
            }
        }
        return s
    }

    private func parseUnsignedInteger() -> String? {
        return nil
    }

    private func parseUnsignedNumber() throws -> String? {
        var s = String()
        while let c = charGenerator.next() {
            switch c {
            case "0", "1", "2", "3", "4", "5", "6", "7", "8", "9":
                s.append(c)
            case ".":
                s.append(c)
            case "+", "-":
                s.append(c)
            case "e", "E":
                s.append(c)
            case "f", "u":
                // proto1 allowed floats to be suffixed with 'f'
                // and unsigned integers to be suffixed with 'u'
                // Just ignore it:
                return s
            default:
                characterPushback = c
                return s
            }
        }
        return s
    }

    private func parseFloat() throws -> String? {
        return try parseUnsignedNumber()
    }

    private func parseNumber(first: Character) throws -> TextToken {
        var s: String
        var digit: Character
        if first == "-" {
            if let d = charGenerator.next() {
                s = String("-")
                digit = d
            } else {
                throw DecodingError.malformedText
            }
        } else {
            digit = first
            s = String()
        }

        switch digit {
        case "a"..."z", "A"..."Z":
            // Treat "-" followed by a letter as a floating-point literal.
            // This treats "-Infinity" as a single token
            // Note that "Infinity" and "NaN" are regular identifiers.
            wordSeparator = false
            if let s = parseIdentifier(prefix: String(s + String(digit)), charGenerator: &charGenerator) {
                return .floatingPointLiteral(s)
            } else {
                throw DecodingError.malformedText
            }
        case "0":  // Octal or hex integer or floating point (e.g., "0.2")
            s += String(digit)
            if let second = charGenerator.next() {
                switch second {
                case "1", "2", "3", "4", "5", "6", "7":
                    s += String(second)
                    if let n = parseOctalInteger() {
                        return .octalInteger(s + n)
                    } else {
                        return .octalInteger(s)
                    }
                case "x":
                    if let n = parseHexInteger() {
                        s += "x"
                        return .hexadecimalInteger(s + n)
                    } else {
                        throw DecodingError.malformedText
                    }
                case ".":
                    s += "."
                    if let n = try parseFloat() {
                        return .floatingPointLiteral(s + n)
                    } else {
                        return .floatingPointLiteral(s)
                    }
                default:
                    characterPushback = second
                }
            }
            return .decimalInteger(s) // Either "0" or "-0"
        default:
            s += String(digit)
            if let n = try parseUnsignedNumber() {
                return .decimalInteger(s + n)
            } else {
                return .decimalInteger(s)
            }
        }
    }

    func next() throws -> TextToken? {
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
                if !wordSeparator {
                    throw DecodingError.malformedText
                }
                wordSeparator = false
                return try parseNumber(first: c)
            case "a"..."z", "A"..."Z":
                wordSeparator = false
                if let s = parseIdentifier(prefix: String(c), charGenerator: &charGenerator) {
                    return .identifier(s)
                } else {
                    throw DecodingError.malformedText
                }
            case "#":
                while let s = charGenerator.next(), s != "\n", s != "\r" {
                    // Skip until end of line
                }
                wordSeparator = true
            default:
                throw DecodingError.malformedText
            }
        }
        eof = true
        return nil
    }
}
