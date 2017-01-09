// Sources/SwiftProtobuf/TextScanner.swift - Text format decoding
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
/// TextScanner has no public members.
///
public class TextScanner {
    internal var extensions: ExtensionSet?
    private var scalars: String.UnicodeScalarView
    private var index: String.UnicodeScalarView.Index
    private var tokenStart: String.UnicodeScalarView.Index
    private var tokenPushback = [TextToken]()
    private var eof: Bool = false
    internal var complete: Bool {
        while index != scalars.endIndex {
            let c = scalars[index]
            switch c {
            case " ", "\t", "\r", "\n":
                index = scalars.index(after: index)
            default:
                return false
            }
        }
        return true
    }

    internal init(text: String, extensions: ExtensionSet? = nil) {
        scalars = text.unicodeScalars
        index = scalars.startIndex
        tokenStart = index
        self.extensions = extensions
    }

    internal func pushback(token: TextToken) {
        tokenPushback.append(token)
    }

    /// Skip whitespace, set token start to first non-whitespace character
    private func skipWhitespace() {
        var lastIndex = index
        while index != scalars.endIndex {
            let scalar = scalars[index]
            switch scalar {
            case " ", "\t", "\r", "\n":
                index = scalars.index(after: index)
                lastIndex = index
            case "#":
                while index != scalars.endIndex {
                    // Skip until end of line
                    let c = scalars[index]
                    index = scalars.index(after: index)
                    if c == "\n" || c == "\r" {
                        break
                    }
                }
            default:
                index = lastIndex
                return
            }
        }
    }

    private func parseIdentifier() -> String? {
        while index != scalars.endIndex {
            let c = scalars[index]
            switch c {
            case "a"..."z", "A"..."Z", "0"..."9", "_":
                index = scalars.index(after: index)
            default:
                return String(scalars[tokenStart..<index])
            }
        }
        return String(scalars[tokenStart..<index])
    }
    
    /// Parse the rest of an [extension_field_name] in the input, assuming the
    /// initial "[" character has already been read (and is in the prefix)
    /// This is also used in Any for the typeURL, so we include "/", "."
    private func parseExtensionIdentifier() -> String? {
        if index == scalars.endIndex {
            return nil
        }
        let c = scalars[index]
        switch c {
        case "a"..."z", "A"..."Z":
            index = scalars.index(after: index)
        default:
            return nil
        }
        while index != scalars.endIndex {
            let c = scalars[index]
            switch c {
            case "a"..."z", "A"..."Z", "0"..."9", "_", ".", "/":
                index = scalars.index(after: index)
            case "]":
                index = scalars.index(after: index)
                return String(scalars[tokenStart..<index])
            default:
                return nil
            }
        }
        return nil
    }
    
    /// Assumes the leading quote has already been consumed
    private func parseQuotedString(terminator: UnicodeScalar) -> String? {
        tokenStart = index
        while index != scalars.endIndex {
            let c = scalars[index]
            if c == terminator {
                let s = String(scalars[tokenStart..<index])
                index = scalars.index(after: index)
                return s
            }
            index = scalars.index(after: index)
            if c == "\\" {
                if index == scalars.endIndex {
                    return nil
                }
                index = scalars.index(after: index)
            }
        }
        return nil // Unterminated quoted string
    }

    private func parseHexInteger() -> String {
        while index != scalars.endIndex {
            let c = scalars[index]
            switch c {
            case "0"..."9", "a"..."f", "A"..."F":
                index = scalars.index(after: index)
            default:
                return String(scalars[tokenStart..<index])
            }
        }
        return String(scalars[tokenStart..<index])
    }
    
    private func parseOctalInteger() -> String {
        while index != scalars.endIndex {
            let c = scalars[index]
            switch c {
            case "0"..."7":
                index = scalars.index(after: index)
            default:
                return String(scalars[tokenStart..<index])
            }
        }
        return String(scalars[tokenStart..<index])
    }

    private func parseUnsignedNumber() -> String {
        while index != scalars.endIndex {
            let c = scalars[index]
            switch c {
            case "0"..."9", ".", "+", "-", "e", "E":
                index = scalars.index(after: index)
            case "f", "u":
                // proto1 allowed floats to be suffixed with 'f'
                // and unsigned integers to be suffixed with 'u'
                // Just ignore it:
                let s = String(scalars[tokenStart..<index])
                index = scalars.index(after: index)
                return s
            default:
                return String(scalars[tokenStart..<index])
            }
        }
        return String(scalars[tokenStart..<index])
    }

    private func parseFloat() -> String {
        return parseUnsignedNumber()
    }

    private func parseNumber() throws -> TextToken {
        // Restart parse at start of token
        index = tokenStart
        var digit = scalars[index]
        index = scalars.index(after: index)
        if digit == "-" {
            if index == scalars.endIndex {
                throw DecodingError.malformedText
            } else {
                digit = scalars[index]
                index = scalars.index(after: index)
            }
        }

        switch digit {
        case "a"..."z", "A"..."Z":
            // Treat "-" followed by a letter as a floating-point literal.
            // This treats "-Infinity" as a single token
            // Note that "Infinity" and "NaN" are regular identifiers.
            if let s = parseIdentifier() {
                return .floatingPointLiteral(s)
            } else {
                throw DecodingError.malformedText
            }
        case "0":  // Octal or hex integer or floating point (e.g., "0.2")
            let second = scalars[index]
            switch second {
            case "1"..."7":
                let n = parseOctalInteger()
                return .octalInteger(n)
            case "x":
                index = scalars.index(after: index)
                let n = parseHexInteger()
                return .hexadecimalInteger(n)
            case ".":
                let n = parseFloat()
                return .floatingPointLiteral(n)
            default: // Either "0" or "-0"
                let n = String(scalars[tokenStart..<index])
                return .decimalInteger(n)
            }
        default:
            let n = parseUnsignedNumber()
            return .decimalInteger(n)
        }
    }

    internal func next() throws -> TextToken? {
        if let t = tokenPushback.popLast() {
            return t
        }
        skipWhitespace()
        if index == scalars.endIndex {
            eof = true
            return nil
        }
        tokenStart = index
        let c = scalars[index]
        index = scalars.index(after: index)
        switch c {
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
            if let s = parseQuotedString(terminator: c) {
                return .string(s)
            }
            throw DecodingError.malformedText
        case "-", "0"..."9":
            return try parseNumber()
        case "a"..."z", "A"..."Z":
            if let s = parseIdentifier() {
                return .identifier(s)
            } else {
                throw DecodingError.malformedText
            }
        default:
            throw DecodingError.malformedText
        }
    }

    /// Returns end-of-message terminator or next key
    /// Note:  This treats [abc] as a single identifier token, consistent
    /// with Text format key handling.
    internal func nextKey() throws -> TextToken? {
        if let t = tokenPushback.popLast() {
            return t
        }
        skipWhitespace()
        if index == scalars.endIndex {
            eof = true
            return nil
        }
        tokenStart = index
        let c = scalars[index]
        index = scalars.index(after: index)
        switch c {
        case "}":
            return .endObject
        case ">":
            return .altEndObject
        case "[":
            if let s = parseExtensionIdentifier() {
                return .identifier(s)
            } else {
                throw DecodingError.malformedText
            }
        case "a"..."z", "A"..."Z":
            if let s = parseIdentifier() {
                return .identifier(s)
            } else {
                throw DecodingError.malformedText
            }
        default:
            throw DecodingError.malformedText
        }
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
