// Sources/SwiftProtobuf/Tokenizer.swift - Shared TextFormat/JSON tokenizer
//
// Copyright (c) 2014 - 2026 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// A low-level tokenizer shared by the TextFormat and JSON parsers.
///
// -----------------------------------------------------------------------------

import Foundation

/// Converts a stream of UTF-8 code units into tokens that can be parsed by a TextFormat or JSON
/// parser.
///
/// This is largely based on the `Tokenizer` class from the C++ protobuf implementation.
package struct Tokenizer {
    let buffer: UnsafeBufferPointer<UInt8>
    private(set) var currentIndex: Int
    private var nextIndex: Int

    fileprivate var line: Int
    fileprivate var column: Int

    private var currentChar: UInt8?

    package private(set) var current: Token

    /// The offset of the current token within the buffer.
    package var currentOffset: Int {
        if let current = current.text.baseAddress {
            return current - buffer.baseAddress!
        }
        // .start uses a fake buffer, so ensure it returns zero.
        if current.kind == .start {
            return 0
        }
        // If we have a nil current token text buffer, then we've reached the end of the buffer.
        return buffer.endIndex
    }

    /// If true, the tokenizer will treat a sequence of URL characters as a single token with the
    /// kind `Token.Kind.urlCharacters`.
    ///
    /// This is used when parsing extension field names in TextFormat, which allow URL symbols as
    /// part of a bare identifier.
    package var allowURLCharacters: Bool

    /// The mode in which the tokenizer is operating.
    package enum Mode {
        /// TextFormat mode.
        case textFormat
        /// JSON mode.
        case json
    }

    /// The mode in which the tokenizer is operating, which determines whether certain kinds of
    /// tokens are allowed.
    package let mode: Mode

    /// The error code that will be reported for any parsing errors encountered by this tokenizer.
    let errorCode: SwiftProtobufError.Code

    /// The number of columns to treat a tab character as.
    private static var tabWidth: Int { 8 }

    /// Creates a tokenizer that will tokenize the contents of the given buffer.
    package init(buffer: UnsafeBufferPointer<UInt8>, mode: Mode, errorCode: SwiftProtobufError.Code) {
        self.buffer = buffer
        self.currentIndex = 0
        self.nextIndex = 0
        self.line = 0
        self.column = 0
        self.current = .start
        self.mode = mode
        self.errorCode = errorCode
        self.allowURLCharacters = false

        if nextIndex != buffer.count {
            currentChar = buffer[nextIndex]
            nextIndex += 1
        } else {
            currentChar = nil
        }
    }

    /// Advances the tokenizer to the next token in the input.
    ///
    /// After this function returns, `self.current` and `self.previous` will be updated to hold the
    /// current and previous tokens, respectively.
    @discardableResult
    package mutating func next() throws -> Bool {
        while true {
            if tryConsumeWhitespace() || tryConsumeComment() {
                continue
            }
            guard let currentChar else {
                break
            }

            guard !Tokenizer.isUnprintable(currentChar) && currentChar != 0 else {
                throw makeError("Invalid control characters encountered in text")
            }

            let tokenStartIndex = currentIndex
            let tokenStartLine = line
            let tokenStartColumn = column
            let type: Token.Kind

            if allowURLCharacters {
                if Tokenizer.isURLCharacter(currentChar) {
                    consumeZeroOrMore(Tokenizer.isURLCharacter)
                    type = .urlCharacters
                } else {
                    let byte = currentChar
                    try consumeSymbol()
                    type = Token.Kind(symbol: byte)
                }
            } else {
                if tryConsumeOne(Tokenizer.isLetter) {
                    consumeZeroOrMore(Tokenizer.isAlphanumeric)
                    type = .identifier
                } else if tryConsume(UInt8(ascii: "0")) {
                    type = try consumeNumber(startedWithZero: true, startedWithDot: false)
                } else if tryConsume(UInt8(ascii: ".")) {
                    if tryConsumeOne(Tokenizer.isDigit) {
                        if current.kind == .identifier
                            && tokenStartLine == current.line
                            && tokenStartColumn == current.endColumn
                        {
                            throw SwiftProtobufError.parsingError(
                                code: errorCode,
                                message: "A space is required between an identifier and a decimal point",
                                inputLine: line,
                                inputColumn: column - 2
                            )
                        }
                        type = try consumeNumber(startedWithZero: false, startedWithDot: true)
                    } else {
                        type = .symbol(UInt8(ascii: "."))
                    }
                } else if tryConsumeOne(Tokenizer.isDigit) {
                    type = try consumeNumber(startedWithZero: false, startedWithDot: false)
                } else if tryConsume(UInt8(ascii: "\"")) {
                    type = try consumeString(delimiter: UInt8(ascii: "\""))
                } else if currentChar == UInt8(ascii: "'") {
                    guard mode == .textFormat else {
                        throw makeError("Single quoted strings are not allowed in JSON")
                    }
                    _ = tryConsume(UInt8(ascii: "'"))
                    type = try consumeString(delimiter: UInt8(ascii: "'"))
                } else {
                    let byte = currentChar
                    try consumeSymbol()
                    type = Token.Kind(symbol: byte)
                    guard mode == .textFormat || Tokenizer.isJSONSymbol(byte) else {
                        throw makeError("Invalid symbol '\(UnicodeScalar(byte))' in JSON")
                    }
                }
            }

            current = Token(
                type: type,
                text: UnsafeBufferPointer(rebasing: buffer[tokenStartIndex..<currentIndex]),
                line: tokenStartLine,
                column: tokenStartColumn,
                endColumn: column
            )
            return true
        }

        current = Token(
            type: .end,
            text: UnsafeBufferPointer(start: nil, count: 0),
            line: line,
            column: column,
            endColumn: column
        )
        return false
    }

    /// Returns true if the given text represents a valid identifier.
    package static func isIdentifier(_ text: some StringProtocol) -> Bool {
        let utf8 = text.utf8
        guard let first = utf8.first, Tokenizer.isLetter(first) else {
            return false
        }
        return utf8.dropFirst().allSatisfy(Tokenizer.isAlphanumeric)
    }

    /// Advances the tokenizer to the next character, updating the internal position and state.
    mutating func advance() {
        guard let c = currentChar else { return }

        if c == UInt8(ascii: "\n") {
            line += 1
            column = 0
        } else if c == UInt8(ascii: "\t") {
            column += Tokenizer.tabWidth - (column % Tokenizer.tabWidth)
        } else {
            column += 1
        }

        currentIndex = nextIndex
        if nextIndex == buffer.count {
            currentChar = nil
        } else {
            currentChar = buffer[nextIndex]
            nextIndex += 1
        }
    }

    /// Returns a parsing error with the given message and the current position.
    func makeError(_ message: String) -> SwiftProtobufError {
        SwiftProtobufError.parsingError(
            code: errorCode,
            message: message,
            inputLine: line,
            inputColumn: column
        )
    }

    /// Tries to consume whitespace characters starting at the current position.
    ///
    /// - Returns: `true` if any whitespace characters were consumed, `false` otherwise.
    mutating func tryConsumeWhitespace() -> Bool {
        if tryConsumeOne(Tokenizer.isWhitespace) {
            consumeZeroOrMore(Tokenizer.isWhitespace)
            return true
        }
        return false
    }

    /// Tries to consume a comment starting at the current position.
    ///
    /// - Returns: `true` if a comment was consumed, `false` otherwise.
    mutating func tryConsumeComment() -> Bool {
        if mode == .textFormat && tryConsume(UInt8(ascii: "#")) {
            consumeLineComment()
            return true
        }
        return false
    }

    /// Consumes a line comment, continuing until a newline character is encountered.
    mutating func consumeLineComment() {
        while currentChar != nil && currentChar != UInt8(ascii: "\n") {
            advance()
        }
        _ = tryConsume(UInt8(ascii: "\n"))
    }

    /// Consumes a string literal from the tokenizer, handling escapes and Unicode decoding.
    ///
    /// - Parameter delimiter: The character used to delimit the string (e.g., `"` or `'`).
    /// - Returns: The `Token.Kind` representing the consumed string.
    /// - Throws: A `SwiftProtobufError` if the string is malformed.
    mutating func consumeString(delimiter: UInt8) throws -> Token.Kind {
        var hasEscapes = false
        while true {
            guard let c = currentChar else {
                throw makeError("Unexpected end of string")
            }

            switch c {
            case UInt8(ascii: "\n"):
                throw makeError("Unexpected newline in string")
            case UInt8(ascii: "\\"):
                hasEscapes = true
                advance()
                if tryConsumeOne(mode == .json ? Tokenizer.isJSONEscape : Tokenizer.isEscape) {
                    // Valid
                } else if tryConsume(UInt8(ascii: "u")) {
                    guard
                        tryConsumeOne(Tokenizer.isHexDigit)
                            && tryConsumeOne(Tokenizer.isHexDigit)
                            && tryConsumeOne(Tokenizer.isHexDigit)
                            && tryConsumeOne(Tokenizer.isHexDigit)
                    else {
                        throw makeError("Expected four hex digits for '\\u' escape sequence")
                    }
                } else if mode == .textFormat && tryConsumeOne(Tokenizer.isOctalDigit) {
                    // Valid
                } else if mode == .textFormat && (tryConsume(UInt8(ascii: "x")) || tryConsume(UInt8(ascii: "X"))) {
                    guard tryConsumeOne(Tokenizer.isHexDigit) else {
                        throw makeError("Expected hex digits for escape sequence")
                    }
                } else if mode == .textFormat && tryConsume(UInt8(ascii: "U")) {
                    guard
                        tryConsume(UInt8(ascii: "0"))
                            && tryConsume(UInt8(ascii: "0"))
                            && (tryConsume(UInt8(ascii: "0")) || tryConsume(UInt8(ascii: "1")))
                            && tryConsumeOne(Tokenizer.isHexDigit)
                            && tryConsumeOne(Tokenizer.isHexDigit)
                            && tryConsumeOne(Tokenizer.isHexDigit)
                            && tryConsumeOne(Tokenizer.isHexDigit)
                            && tryConsumeOne(Tokenizer.isHexDigit)
                    else {
                        throw makeError("Expected eight hex digits up to 10ffff for '\\U' escape sequence")
                    }
                } else {
                    throw makeError("Invalid escape sequence in string literal")
                }
            default:
                if c == delimiter {
                    advance()
                    return hasEscapes ? .stringWithEscapes : .string
                }
                advance()
            }
        }
    }

    /// Consumes a number, handling optional leading zero and optional decimal point.
    ///
    /// - Parameters:
    ///   - startedWithZero: Whether the number started with a zero.
    ///   - startedWithDot: Whether the number started with a decimal point.
    /// - Returns: The `Token.Kind` representing the consumed number.
    /// - Throws: A `SwiftProtobufError` if the number is malformed.
    private mutating func consumeNumber(startedWithZero: Bool, startedWithDot: Bool) throws -> Token.Kind {
        var isFloat = false

        if startedWithZero && (tryConsume(UInt8(ascii: "x")) || tryConsume(UInt8(ascii: "X"))) {
            guard mode == .textFormat else {
                throw makeError("Hex numbers are not allowed in JSON")
            }
            try consumeOneOrMore(Tokenizer.isHexDigit, "\"0x\" must be followed by hex digits")
        } else if startedWithZero && lookingAt(Tokenizer.isDigit) {
            guard mode == .textFormat else {
                throw makeError("Leading zeros are not allowed in JSON")
            }
            consumeZeroOrMore(Tokenizer.isOctalDigit)
            guard !lookingAt(Tokenizer.isDigit) else {
                throw makeError("Numbers starting with leading zero must be in octal")
            }
        } else {
            if startedWithDot {
                guard mode == .textFormat else {
                    throw makeError("Numbers cannot start with a decimal point in JSON")
                }
                isFloat = true
                consumeZeroOrMore(Tokenizer.isDigit)
            } else {
                consumeZeroOrMore(Tokenizer.isDigit)
                if tryConsume(UInt8(ascii: ".")) {
                    isFloat = true
                    if mode == .json {
                        try consumeOneOrMore(Tokenizer.isDigit, "Decimal point must be followed by digits in JSON")
                    } else {
                        consumeZeroOrMore(Tokenizer.isDigit)
                    }
                }
            }

            if tryConsume(UInt8(ascii: "e")) || tryConsume(UInt8(ascii: "E")) {
                isFloat = true
                _ = tryConsume(UInt8(ascii: "-")) || tryConsume(UInt8(ascii: "+"))
                try consumeOneOrMore(Tokenizer.isDigit, "\"e\" must be followed by exponent")
            }

            if mode == .textFormat && (tryConsume(UInt8(ascii: "f")) || tryConsume(UInt8(ascii: "F"))) {
                isFloat = true
            }
        }

        guard !lookingAt(Tokenizer.isLetter) else {
            throw makeError("Need space between number and identifier")
        }
        if currentChar == UInt8(ascii: ".") {
            if isFloat {
                throw makeError("Already saw decimal point or exponent; can't have another one")
            } else {
                throw makeError("Hex and octal numbers must be integers")
            }
        }

        return isFloat ? .float : .integer
    }

    /// Consumes a symbol, checking for non-UTF-8 code units.
    ///
    /// - Throws: A `SwiftProtobufError` if the symbol contains non-UTF-8 code units.
    private mutating func consumeSymbol() throws {
        if let c = currentChar, (c & 0x80) != 0 {
            throw SwiftProtobufError.parsingError(
                code: errorCode,
                message: "Non-UTF-8 code unit \(c)",
                inputLine: line,
                inputColumn: column
            )
        }
        advance()
    }

    /// Returns `true` if the current character matches the predicate.
    ///
    /// This method does not advance the tokenizer to the next character.
    private func lookingAt(_ predicate: (UInt8) -> Bool) -> Bool {
        guard let c = currentChar else { return false }
        return predicate(c)
    }

    /// Tries to consume a single character that satisfies the predicate.
    ///
    /// - Parameter predicate: The predicate to apply to the current character.
    /// - Returns: `true` if the character was consumed, `false` otherwise.
    private mutating func tryConsumeOne(_ predicate: (UInt8) -> Bool) -> Bool {
        guard let c = currentChar, predicate(c) else { return false }
        advance()
        return true
    }

    /// Tries to consume a single character.
    ///
    /// - Parameter char: The character to consume.
    /// - Returns: `true` if the character was consumed, `false` otherwise.
    private mutating func tryConsume(_ char: UInt8) -> Bool {
        guard currentChar == char else { return false }
        advance()
        return true
    }

    /// Consumes all characters that satisfy the predicate, if any.
    ///
    /// - Parameter predicate: The predicate to apply to the current character.
    private mutating func consumeZeroOrMore(_ predicate: (UInt8) -> Bool) {
        while let c = currentChar, predicate(c) {
            advance()
        }
    }

    /// Consumes one or more characters that satisfy the predicate.
    ///
    /// - Parameters:
    ///   - predicate: The predicate to apply to the current character.
    ///   - error: The error message to use if the predicate is not satisfied.
    /// - Throws: A `SwiftProtobufError` if the predicate is not satisfied.
    private mutating func consumeOneOrMore(_ predicate: (UInt8) -> Bool, _ error: String) throws {
        guard lookingAt(predicate) else {
            throw makeError(error)
        }
        while let c = currentChar, predicate(c) {
            advance()
        }
    }

    /// Returns `true` if the given byte is considered whitespace.
    private static func isWhitespace(_ c: UInt8) -> Bool {
        (characterTable[Int(c)] & 0x01) != 0
    }

    /// Returns `true` if the given byte is a decimal digit.
    static func isDigit(_ c: UInt8) -> Bool {
        // Identical to `isHexdigit && !isLetter`.
        (characterTable[Int(c)] & 0x06) == 0x02
    }

    /// Returns `true` if the given byte is an octal digit.
    fileprivate static func isOctalDigit(_ c: UInt8) -> Bool {
        c >= 48 && c <= 55
    }

    /// Returns `true` if the given byte is a hexadecimal digit.
    static func isHexDigit(_ c: UInt8) -> Bool {
        (characterTable[Int(c)] & 0x02) != 0
    }

    /// Returns `true` if the given byte is a letter.
    private static func isLetter(_ c: UInt8) -> Bool {
        (characterTable[Int(c)] & 0x04) != 0
    }

    /// Returns `true` if the given byte is an alphanumeric character.
    private static func isAlphanumeric(_ c: UInt8) -> Bool {
        // Identical to `isHexDigit || isLetter`.
        (characterTable[Int(c)] & 0x06) != 0
    }

    /// Returns `true` if the given byte is a valid escape character in a TextFormat string literal.
    ///
    /// Valid escape characters (that is, characters that may follow a backslash) are `a`, `b`, `f`,
    /// `n`, `r`, `t`, `v`, `\`, `?`, `'`, and `"`.
    private static func isEscape(_ c: UInt8) -> Bool {
        (characterTable[Int(c)] & 0x08) != 0
    }

    /// Returns `true` if the given byte is a valid escape character in a JSON string literal.
    ///
    /// Valid escape characters (that is, characters that may follow a backslash) are `b`, `f`, `n`,
    /// `r`, `t`, `\`, `/`, and `"`.
    private static func isJSONEscape(_ c: UInt8) -> Bool {
        (characterTable[Int(c)] & 0x10) != 0
    }

    /// Returns `true` if the given byte is valid punctuation in a JSON payload.
    ///
    /// Valid symbols are `{`, `}`, `[`, `]`, `:`, `,`, and `-` (because we tokenize minus
    /// separately for consistency with TextFormat).
    private static func isJSONSymbol(_ c: UInt8) -> Bool {
        (characterTable[Int(c)] & 0x20) != 0
    }

    /// Returns `true` if the given byte is a valid URL character.
    ///
    /// Valid URL characters are alphanumeric characters as well as any of `-`, `.`, `~`, `!`,
    /// `$`, `&`, `(`, `)`, `*`, `+`, `,`, `;`, `=`, `%`, and `/`.
    private static func isURLCharacter(_ c: UInt8) -> Bool {
        (characterTable[Int(c)] & 0x40) != 0
    }

    /// Returns `true` if the given byte is an unprintable character.
    private static func isUnprintable(_ c: UInt8) -> Bool {
        (characterTable[Int(c)] & 0x80) != 0
    }
}

/// Lookup table for the character properties defined above.
private let characterTable: [UInt8] = [
    0x00, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x01, 0x01, 0x01, 0x01, 0x01, 0x80, 0x80,
    0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80,
    0x01, 0x40, 0x18, 0x00, 0x40, 0x40, 0x40, 0x08, 0x40, 0x40, 0x40, 0x40, 0x60, 0x60, 0x40, 0x50,
    0x42, 0x42, 0x42, 0x42, 0x42, 0x42, 0x42, 0x42, 0x42, 0x42, 0x20, 0x40, 0x00, 0x40, 0x00, 0x08,
    0x00, 0x46, 0x46, 0x46, 0x46, 0x46, 0x46, 0x44, 0x44, 0x44, 0x44, 0x44, 0x44, 0x44, 0x44, 0x44,
    0x44, 0x44, 0x44, 0x44, 0x44, 0x44, 0x44, 0x44, 0x44, 0x44, 0x44, 0x20, 0x18, 0x20, 0x00, 0x44,
    0x00, 0x4E, 0x5E, 0x46, 0x46, 0x46, 0x5E, 0x44, 0x44, 0x44, 0x44, 0x44, 0x44, 0x44, 0x5C, 0x44,
    0x44, 0x44, 0x5C, 0x44, 0x5C, 0x44, 0x4C, 0x44, 0x44, 0x44, 0x44, 0x20, 0x00, 0x20, 0x40, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
]

/// Represents a token read from the token stream.
package struct Token: Equatable {
    /// The kind of token.
    package enum Kind: Equatable {
        /// The start of input; `next()` has not yet been called.
        case start

        /// End of input reached.
        case end

        /// A sequence of letters, digits, and underscores, not starting with a digit.
        case identifier

        /// A sequence of digits representing an integer.
        case integer

        /// A floating point literal, with a fractional part and/or an exponent.
        case float

        /// A quoted sequence of characters that contains no escapes.
        case string

        /// A quoted sequence of characters that contains escapes.
        case stringWithEscapes

        /// A sequence of accepted URL characters.
        case urlCharacters

        /// The left brace, "{".
        case leftBrace

        /// The right brace, "}".
        case rightBrace

        /// The left bracket, "[".
        case leftBracket

        /// The right bracket, "]".
        case rightBracket

        /// The left angle bracket, "<".
        case leftAngle

        /// The right angle bracket, ">".
        case rightAngle

        /// The colon, ":".
        case colon

        /// The comma, ",".
        case comma

        /// The semicolon, ";".
        case semicolon

        /// The minus sign, "-".
        case minus

        /// Any other printable character, like '!' or '+'.
        case symbol(UInt8)

        /// Creates the token kind associated with the given byte when it represents a symbol.
        init(symbol: UInt8) {
            switch symbol {
            case UInt8(ascii: "{"): self = .leftBrace
            case UInt8(ascii: "}"): self = .rightBrace
            case UInt8(ascii: "["): self = .leftBracket
            case UInt8(ascii: "]"): self = .rightBracket
            case UInt8(ascii: "<"): self = .leftAngle
            case UInt8(ascii: ">"): self = .rightAngle
            case UInt8(ascii: ":"): self = .colon
            case UInt8(ascii: ","): self = .comma
            case UInt8(ascii: ";"): self = .semicolon
            case UInt8(ascii: "-"): self = .minus
            default: self = .symbol(symbol)
            }
        }

        /// The description of the token that should be used by parsers when reporting that a token
        /// of an expected kind was not found.
        package var errorDescription: String {
            switch self {
            case .start: "start of input"
            case .end: "end of input"
            case .identifier: "an identifier"
            case .integer: "an integer"
            case .float: "a floating point number"
            case .string, .stringWithEscapes: "a string"
            case .urlCharacters: "a sequence of URL characters"
            case .leftBrace: "'{'"
            case .rightBrace: "'}'"
            case .leftBracket: "'['"
            case .rightBracket: "']'"
            case .leftAngle: "'<'"
            case .rightAngle: "'>'"
            case .colon: "':'"
            case .comma: "','"
            case .semicolon: "';'"
            case .minus: "'-'"
            case .symbol(let byte): "'\(UnicodeScalar(byte))'"
            }
        }
    }

    /// The kind of token.
    package let kind: Kind

    /// The exact text of the token as it appeared in the input. For example, tokens of
    /// ``Kind.stringWithEscapes`` will still be escaped and in quotes.
    package let text: UnsafeBufferPointer<UInt8>

    /// Zero-based index of the first character of the token within the input stream.
    package let line: Int

    /// Zero-based index of the first character of the token within the input stream.
    package let column: Int

    /// Zero-based index of the first character of the token within the input stream.
    package let endColumn: Int

    package init(
        type: Kind,
        text: UnsafeBufferPointer<UInt8>,
        line: Int,
        column: Int,
        endColumn: Int
    ) {
        self.kind = type
        self.text = text
        self.line = line
        self.column = column
        self.endColumn = endColumn
    }

    /// The exact text of the token as a `String`.
    ///
    /// Note that for ``Kind.string`` and ``Kind.stringWithEscapes``, this returns the raw text
    /// including the quotes and escapes. Callers should use `stringValue` to get the decoded value.
    package var exactString: String {
        String(decoding: text, as: UTF8.self)
    }

    package static func == (lhs: Token, rhs: Token) -> Bool {
        lhs.kind == rhs.kind && lhs.line == rhs.line && lhs.column == rhs.column && lhs.endColumn == rhs.endColumn
            && lhs.text.elementsEqual(rhs.text)
    }

    package static var start: Token {
        Token(type: .start, text: UnsafeBufferPointer(start: nil, count: 0), line: 0, column: 0, endColumn: 0)
    }

    /// Returns the integer value of the token, respecting an upper bound.
    ///
    /// - Throws: An error if the token is not a valid integer or if it is greater than the
    ///   provided upper bound.
    package func integerValue(
        upperBound: UInt64 = UInt64.max,
        errorCode: SwiftProtobufError.Code
    ) throws -> UInt64 {
        var string = self.exactString
        var radix = 10
        if string.hasPrefix("0x") || string.hasPrefix("0X") {
            string.removeFirst(2)
            radix = 16
        } else if string.hasPrefix("0") && string.count > 1 {
            string.removeFirst()
            radix = 8
        }
        guard let val = UInt64(string, radix: radix), val <= upperBound else {
            throw SwiftProtobufError.parsingError(
                code: errorCode,
                message: "Expected an integer no larger than \(upperBound)",
                inputLine: line,
                inputColumn: column
            )
        }
        return val
    }

    /// Returns the floating point value of the token.
    ///
    /// - Throws: An error if the token is not a valid floating point number.
    package func floatValue(errorCode: SwiftProtobufError.Code) throws -> Double {
        var string = self.exactString
        if string.lowercased().hasSuffix("f") {
            string.removeLast()
        }
        if let val = Double(string) {
            return val
        }
        if let eIndex = string.lowercased().firstIndex(of: "e"),
            let baseVal = Double(string[..<eIndex])
        {
            return baseVal
        }
        throw SwiftProtobufError.parsingError(
            code: errorCode,
            message: "Expected a floating point number",
            inputLine: line,
            inputColumn: column
        )
    }

    /// Returns the string value of the token.
    ///
    /// - Throws: An error if the token is not a valid UTF-8 string of if it contained surrogates
    ///   when they were not allowed.
    package func stringValue(allowSurrogates: Bool, errorCode: SwiftProtobufError.Code) throws -> String {
        guard text.count >= 2 else { return "" }
        let content = UnsafeBufferPointer(rebasing: text[1..<text.count - 1])

        func utf8Error() -> SwiftProtobufError {
            SwiftProtobufError.parsingError(
                code: errorCode,
                message: "Invalid UTF-8 in string",
                inputLine: line,
                inputColumn: column
            )
        }

        if self.kind == .string {
            // No escapes, so we can just decode it directly.
            guard let str = utf8ToString(bytes: content.baseAddress!, count: content.count) else {
                throw utf8Error()
            }
            return str
        } else {
            // If it had escapes, `bytesValue` will resolve them and then we can decode
            // the resulting bytes as UTF-8.
            let bytes = try bytesValue(allowSurrogates: allowSurrogates, errorCode: errorCode)
            return try bytes.withUnsafeBytes { rawBuffer in
                guard let str = utf8ToString(bytes: rawBuffer.baseAddress!, count: rawBuffer.count) else {
                    throw utf8Error()
                }
                return str
            }
        }
    }

    /// Returns the bytes value of the token.
    ///
    /// - Throws: An error if the token is not a valid UTF-8 string or if it contained surrogates
    ///   when they were not allowed.
    package func bytesValue(allowSurrogates: Bool, errorCode: SwiftProtobufError.Code) throws -> Data {
        guard text.count >= 2 else { return Data() }
        let content = UnsafeBufferPointer(rebasing: text[1..<text.count - 1])

        if kind == .string {
            return Data(buffer: content)
        }

        func makeError(_ reason: String) -> SwiftProtobufError {
            SwiftProtobufError.parsingError(
                code: errorCode,
                message: reason,
                inputLine: line,
                inputColumn: column
            )
        }

        var outputBytes = Data()
        // We know the output bytes will be no larger than the input bytes, so reserve that much to
        // avoid reallocations.
        outputBytes.reserveCapacity(content.count)

        var index = 0
        var highSurrogate: Int? = nil

        while index < content.count {
            if content[index] == UInt8(ascii: "\\") {
                index += 1
                guard index < content.count else { break }

                let next = content[index]
                index += 1

                switch next {
                case UInt8(ascii: "a"): outputBytes.append(0x07)
                case UInt8(ascii: "b"): outputBytes.append(0x08)
                case UInt8(ascii: "f"): outputBytes.append(0x0C)
                case UInt8(ascii: "n"): outputBytes.append(UInt8(ascii: "\n"))
                case UInt8(ascii: "r"): outputBytes.append(UInt8(ascii: "\r"))
                case UInt8(ascii: "t"): outputBytes.append(UInt8(ascii: "\t"))
                case UInt8(ascii: "v"): outputBytes.append(0x0B)
                case UInt8(ascii: "\\"): outputBytes.append(UInt8(ascii: "\\"))
                case UInt8(ascii: "?"): outputBytes.append(UInt8(ascii: "?"))
                case UInt8(ascii: "'"): outputBytes.append(UInt8(ascii: "'"))
                case UInt8(ascii: "\""): outputBytes.append(UInt8(ascii: "\""))

                case UInt8(ascii: "x"), UInt8(ascii: "X"):
                    let hexStart = index
                    if index < content.count && Tokenizer.isHexDigit(content[index]) {
                        index += 1
                        if index < content.count && Tokenizer.isHexDigit(content[index]) {
                            index += 1
                        }
                    }
                    let hex = String(decoding: content[hexStart..<index], as: UTF8.self)
                    guard let value = Int(hex, radix: 16) else {
                        preconditionFailure("tokenizer should have already failed for invalid hex")
                    }
                    outputBytes.append(UInt8(value))

                case UInt8(ascii: "0")...UInt8(ascii: "7"):
                    let octalStart = index - 1  // include `next`
                    if index < content.count && Tokenizer.isOctalDigit(content[index]) {
                        index += 1
                        if index < content.count && Tokenizer.isOctalDigit(content[index]) {
                            index += 1
                        }
                    }
                    let octal = String(decoding: content[octalStart..<index], as: UTF8.self)
                    guard let value = Int(octal, radix: 8) else {
                        preconditionFailure("tokenizer should have already failed for invalid octal")
                    }
                    outputBytes.append(UInt8(value % 256))

                case UInt8(ascii: "u"), UInt8(ascii: "U"):
                    let digitCount = (next == UInt8(ascii: "u") ? 4 : 8)
                    let unicodeHexStart = index
                    var count = 0
                    while count < digitCount && index < content.count {
                        index += 1
                        count += 1
                    }
                    let unicodeHex = String(decoding: content[unicodeHexStart..<index], as: UTF8.self)
                    if let value = Int(unicodeHex, radix: 16) {
                        if value >= 0xD800 && value <= 0xDBFF {
                            guard allowSurrogates else {
                                throw makeError("Surrogate code points are not allowed here")
                            }
                            guard highSurrogate == nil else {
                                throw makeError("Invalid surrogate pairing")
                            }
                            highSurrogate = value
                        } else if value >= 0xDC00 && value <= 0xDFFF {
                            guard allowSurrogates else {
                                throw makeError("Surrogate code points are not allowed here")
                            }
                            if let high = highSurrogate {
                                let combined = 0x10000 + ((high - 0xD800) << 10) + (value - 0xDC00)
                                Unicode.UTF8.encode(UnicodeScalar(combined)!) { outputBytes.append($0) }
                                highSurrogate = nil
                            } else {
                                throw makeError("Invalid surrogate pairing")
                            }
                        } else {
                            guard highSurrogate == nil else {
                                throw makeError("Invalid surrogate pairing")
                            }
                            if let scalar = UnicodeScalar(value) {
                                Unicode.UTF8.encode(scalar) { outputBytes.append($0) }
                            } else {
                                throw makeError("Invalid Unicode code point")
                            }
                            highSurrogate = nil
                        }
                    } else {
                        outputBytes.append(next)
                        outputBytes.append(contentsOf: content[unicodeHexStart..<index])
                    }

                default:
                    outputBytes.append(next)
                    highSurrogate = nil
                }
            } else {
                // Not an escaped character; copy an entire run.
                guard highSurrogate == nil else {
                    throw makeError("Invalid surrogate pairing")
                }
                let startOfRun = index
                let endOfRun = content[index...].firstIndex(of: UInt8(ascii: "\\")) ?? content.endIndex
                outputBytes.append(contentsOf: content[startOfRun..<endOfRun])
                index = endOfRun
                highSurrogate = nil
            }
        }
        guard highSurrogate == nil else {
            throw makeError("Invalid surrogate pairing")
        }
        return outputBytes
    }

    /// Indicates whether the token is a valid hexadecimal number.
    package var isHexNumber: Bool {
        text.count > 2 && text[0] == UInt8(ascii: "0") && (text[1] == UInt8(ascii: "x") || text[1] == UInt8(ascii: "X"))
    }

    /// Indicates whether the token is a valid octal number.
    package var isOctalNumber: Bool {
        text.count > 2 && text[0] == UInt8(ascii: "0") && (text[1] >= UInt8(ascii: "0") && text[1] <= UInt8(ascii: "7"))
    }
}
