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

private func parseIdentifier(prefix: String, scalarGenerator: inout String.UnicodeScalarView.Generator) -> String? {
    var result = prefix
    var previousScalarGenerator = scalarGenerator
    while let c = scalarGenerator.next() {
        switch c {
        case "a"..."z", "A"..."Z", "0"..."9", "_":
            result.append(String(c))
            previousScalarGenerator = scalarGenerator
        default:
            scalarGenerator = previousScalarGenerator
            return result
        }
    }
    return result
}

/// Parse the rest of an [extension_field_name] in the input, assuming the
/// initial "[" character has already been read (and is in the prefix)
/// This is also used in Any for the typeURL, so we include "/", "."
private func parseExtensionIdentifier(prefix: String, scalarGenerator: inout String.UnicodeScalarView.Generator) -> String? {
    var result = prefix
    if let c = scalarGenerator.next() {
        switch c {
        case "a"..."z", "A"..."Z":
            result.append(String(c))
        default:
            return nil
        }
    } else {
        return nil
    }
    while let c = scalarGenerator.next() {
        switch c {
        case "a"..."z", "A"..."Z", "0"..."9", "_", ".", "/":
            result.append(String(c))
        case "]":
            result.append(String(c))
            return result
        default:
            return nil
        }
    }
    return nil
}

private func parseQuotedString(scalarGenerator: inout String.UnicodeScalarView.Generator, terminator: UnicodeScalar) -> String? {
    var result = ""
    while let c = scalarGenerator.next() {
        if c == terminator {
            return result
        }
        switch c {
        case "\\":
            if let escaped = scalarGenerator.next() {
                result.append("\\")
                result.append(String(escaped))
            } else {
                return nil // Input ends in backslash

            }
        default:
            result.append(String(c))
        }
    }
    return nil // Unterminated quoted string
}

///
/// TextScanner has no public members.
///
public class TextScanner {
    internal var extensions: ExtensionSet?
    private var scalarGenerator: String.UnicodeScalarView.Generator
    private var scalarPushback: UnicodeScalar?
    private var tokenPushback: [TextToken]
    private var eof: Bool = false
    internal var complete: Bool {
        switch scalarPushback {
        case .some(" "), .some("\t"), .some("\r"), .some("\n"): break
        case .none: break
        default:
            return false
        }
        var g = scalarGenerator
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

    internal init(text: String, tokens: [TextToken], extensions: ExtensionSet? = nil) {
        scalarGenerator = text.unicodeScalars.makeIterator()
        tokenPushback = tokens.reversed()
        self.extensions = extensions
    }

    internal func pushback(token: TextToken) {
        tokenPushback.append(token)
    }

    private func parseHexInteger() -> String? {
        var s = String()
        while let c = scalarGenerator.next() {
            switch c {
            case "0"..."9", "a"..."f", "A"..."F":
                s.append(String(c))
            default:
                scalarPushback = c
                return s
            }
        }
        return s
    }

    private func parseOctalInteger() -> String? {
        var s = String()
        while let c = scalarGenerator.next() {
            switch c {
            case "0"..."7":
                s.append(String(c))
            default:
                scalarPushback = c
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
        while let c = scalarGenerator.next() {
            switch c {
            case "0"..."9":
                s.append(String(c))
            case ".":
                s.append(String(c))
            case "+", "-":
                s.append(String(c))
            case "e", "E":
                s.append(String(c))
            case "f", "u":
                // proto1 allowed floats to be suffixed with 'f'
                // and unsigned integers to be suffixed with 'u'
                // Just ignore it:
                return s
            default:
                scalarPushback = c
                return s
            }
        }
        return s
    }

    private func parseFloat() throws -> String? {
        return try parseUnsignedNumber()
    }

    private func parseNumber(first: UnicodeScalar) throws -> TextToken {
        var s: String
        var digit: UnicodeScalar
        if first == "-" {
            if let d = scalarGenerator.next() {
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
            if let s = parseIdentifier(prefix: String(s + String(digit)), scalarGenerator: &scalarGenerator) {
                return .floatingPointLiteral(s)
            } else {
                throw DecodingError.malformedText
            }
        case "0":  // Octal or hex integer or floating point (e.g., "0.2")
            s += String(digit)
            if let second = scalarGenerator.next() {
                switch second {
                case "1"..."7":
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
                    scalarPushback = second
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

    internal func next() throws -> TextToken? {
        if let t = tokenPushback.popLast() {
            return t
        }
        if eof {
            return nil
        }
        while let c = scalarPushback ?? scalarGenerator.next() {
            scalarPushback = nil
            switch c {
            case " ", "\t", "\r", "\n":
                break
            case ":":
                return .colon
            case ",":
                return .comma
            case ";":
                return .semicolon
            case "<":
                return .altBeginObject
            case "{":
                return .beginObject
            case "}":
                return .endObject
            case ">":
                return .altEndObject
            case "[":
                return .beginArray
            case "]":
                return .endArray
            case "\'", "\"": // string
                if let s = parseQuotedString(scalarGenerator: &scalarGenerator, terminator: c) {
                    return .string(s)
                }
                throw DecodingError.malformedText
            case "-", "0"..."9":
                return try parseNumber(first: c)
            case "a"..."z", "A"..."Z":
                if let s = parseIdentifier(prefix: String(c), scalarGenerator: &scalarGenerator) {
                    return .identifier(s)
                } else {
                    throw DecodingError.malformedText
                }
            case "#":
                while let s = scalarGenerator.next(), s != "\n", s != "\r" {
                    // Skip until end of line
                }
            default:
                throw DecodingError.malformedText
            }
        }
        eof = true
        return nil
    }

    /// Returns end-of-message terminator or next key
    /// Note:  This treats [abc] as a single identifier token, consistent
    /// with Text format key handling.
    internal func nextKey() throws -> TextToken? {
        if let t = tokenPushback.popLast() {
            return t
        }
        if eof {
            return nil
        }
        while let c = scalarPushback ?? scalarGenerator.next() {
            scalarPushback = nil
            switch c {
            case " ", "\t", "\r", "\n":
                break
            case "}":
                return .endObject
            case ">":
                return .altEndObject
            case "[":
                if let s = parseExtensionIdentifier(prefix: String(c), scalarGenerator: &scalarGenerator) {
                    return .identifier(s)
                } else {
                    throw DecodingError.malformedText
                }
            case "a"..."z", "A"..."Z":
                if let s = parseIdentifier(prefix: String(c), scalarGenerator: &scalarGenerator) {
                    return .identifier(s)
                } else {
                    throw DecodingError.malformedText
                }
            case "#":
                while let s = scalarGenerator.next(), s != "\n", s != "\r" {
                    // Skip until end of line
                }
            default:
                throw DecodingError.malformedText
            }
        }
        eof = true
        return nil
    }

    // Consume the specified token, throw an error if the token isn't there
    internal func skipRequired(token: TextToken) throws {
        if let t = try next(), t == token {
            return
        } else {
            throw DecodingError.malformedText
        }
    }

    /// Consume the next token if it matches the specified one
    ///  * return true if it was there, false otherwise
    ///  * error only if there's a scanning failure
    internal func skipOptional(token: TextToken) throws -> Bool {
        if let t = try next() {
            if t == token {
                return true
            } else {
                pushback(token: t)
                return false
            }
        } else {
            throw DecodingError.malformedText
        }
    }

    internal func skipOptionalSeparator() throws {
        if let t = try next() {
            if t == .comma || t == .semicolon {
                return
            } else {
                pushback(token: t)
            }
        }
    }

    /// Returns the token that should end this field.
    /// E.g., if object starts with "{", returns "}"
    internal func readObjectStart() throws -> TextToken {
        if let t = try next() {
            switch t {
            case .beginObject: // Starts with "{"
                return .endObject // Should end with "}"
            case .altBeginObject: // Starts with "<"
                return .altEndObject // Should end with ">"
            default: break
            }
        }
        throw DecodingError.malformedText
    }
}
