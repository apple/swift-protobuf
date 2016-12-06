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
/// JSONScanner translates a JSON input into a series of JSON tokens.
///
// -----------------------------------------------------------------------------

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


public class JSONScanner {
    internal var extensions: ExtensionSet?
    private var charGenerator: String.CharacterView.Generator
    private var characterPushback: Character?
    private var tokenPushback: [JSONToken]
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
    
    public init(json: String, tokens: [JSONToken], extensions: ExtensionSet? = nil) {
        charGenerator = json.characters.makeIterator()
        tokenPushback = tokens.reversed()
        self.extensions = extensions
    }
    
    public func pushback(token: JSONToken) {
        tokenPushback.append(token)
    }
    
    public func next() throws -> JSONToken? {
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
                throw DecodingError.malformedJSON
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
                throw DecodingError.malformedJSON
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
                throw DecodingError.malformedJSON
            case "\"": // string
                if wordSeparator {
                    wordSeparator = false
                    if let s = parseQuotedString(charGenerator: &charGenerator) {
                        return .string(s)
                    }
                }
                throw DecodingError.malformedJSON
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
                throw DecodingError.malformedJSON
            default:
                throw DecodingError.malformedJSON
            }
        }
        eof = true
        return nil
    }
}
