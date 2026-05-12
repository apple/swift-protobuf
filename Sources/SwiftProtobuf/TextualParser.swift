// Sources/SwiftProtobuf/TextualParser.swift - TextFormat/JSON parser mixin
//
// Copyright (c) 2014 - 2026 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// A "mixin" that provides common parsing helpers for types that contain a
/// tokenizer.
///
// -----------------------------------------------------------------------------

/// A "mixin" that provides high-level parsing helpers for types that contain a tokenizer.
protocol TextualParser {
    /// The tokenizer that is used by this parser.
    var tokenizer: Tokenizer { get set }
}

extension TextualParser {
    /// Returns a value indicating whether the current token is of the given type, without consuming
    /// it.
    func at(_ kind: Token.Kind) -> Bool {
        tokenizer.current.kind == kind
    }

    /// Returns a value indicating whether the current token is one of the given types, without
    /// consuming it.
    func at(_ kinds: Token.Kind...) -> Bool {
        kinds.contains(tokenizer.current.kind)
    }

    /// Consume the next token if its type is one of the given kinds.
    ///
    /// - Returns: `true` if the end of the input has been reached, otherwise `false`.
    /// - Throws: an error with the given message if the token was not one of the given kinds.
    @discardableResult
    mutating func consume(anyOf kinds: Token.Kind...) throws -> Bool {
        guard kinds.contains(tokenizer.current.kind) else {
            let expectedDescription = kinds.map(\.errorDescription).joined(separator: ", ")
            throw tokenizer.makeError(
                "Expected one of \(expectedDescription); but found \(tokenizer.current.kind.errorDescription)"
            )
        }
        _ = try tokenizer.next()
        return true
    }

    /// Consume the next token if its type is one of the given kinds.
    ///
    /// - Returns: `true` if the end of the input has been reached, otherwise `false`.
    /// - Throws: an error with the given message if the token was not the given kind.
    @discardableResult
    mutating func consume(_ kind: Token.Kind) throws -> Bool {
        guard tokenizer.current.kind == kind else {
            throw tokenizer.makeError(
                "Expected \(kind.errorDescription) but found \(tokenizer.current.kind.errorDescription)"
            )
        }
        _ = try tokenizer.next()
        return true
    }

    /// Consume the token of the given type if it is the current token in the input, or leave the
    /// current token as-is otherwise.
    ///
    /// - Returns: `true` if the given token type was the current token and was consumed, `false`
    ///   otherwise.
    @discardableResult
    mutating func consumeIfPresent(_ tokenType: Token.Kind) throws -> Bool {
        guard tokenizer.current.kind == tokenType else {
            return false
        }
        _ = try tokenizer.next()
        return true
    }

    /// Creates and returns a `TextualParsingError` describing that a token of one of the expected
    /// kinds was not found.
    func parsingError(expected: Token.Kind...) -> TextualParsingError {
        parsingError(expected: expected)
    }

    /// Creates and returns a `TextualParsingError` describing that a token of one of the expected
    /// kinds was not found.
    func parsingError(expected: [Token.Kind]) -> TextualParsingError {
        assert(!expected.isEmpty)
        let expectation =
            if expected.count == 1 {
                expected[0].errorDescription
            } else {
                "one of \(expected.map(\.errorDescription).joined(separator: ", "))"
            }
        return parsingError(expected: expectation)
    }

    /// Creates and returns a `TextualParsingError` describing that the token was not what was
    /// expected.
    ///
    /// - Parameters:
    ///   - expected: A human-readable description of the token(s) that were expected.
    ///   - token: The token that was actually found, or `nil` to use the current token. The
    ///     location of this token will be associated with the error.
    func parsingError(expected: String, at token: Token? = nil) -> TextualParsingError {
        let token = token ?? tokenizer.current
        let actual = String(decoding: token.text, as: UTF8.self)
        return TextualParsingError(
            line: token.line,
            column: token.column,
            message: "Expected \(expected) but found '\(actual)'"
        )
    }

    /// Creates and returns a `TextualParsingError` describing some failing condition described by
    /// the given reason.
    ///
    /// - Parameters:
    ///   - reason: A human-readable description of the failing condition.
    ///   - token: The token that was found when the condition was detected, or `nil` to use the
    ///     current token. The location of this token will be associated with the error.
    func parsingError(reason: String, at token: Token? = nil) -> TextualParsingError {
        let token = token ?? tokenizer.current
        return TextualParsingError(
            line: token.line,
            column: token.column,
            message: reason
        )
    }

    /// Calls the supplied block with URL characters enabled. The previous value is restored when
    /// the block returns (whether normally or via an error).
    mutating func reportingURLCharacters<Result>(_ body: (inout Self) throws -> Result) rethrows -> Result {
        let oldValue = tokenizer.allowURLCharacters
        tokenizer.allowURLCharacters = true
        defer { tokenizer.allowURLCharacters = oldValue }
        return try body(&self)
    }
}

/// The error thrown by TextFormat and JSON parsers that indicates where and what kind of error
/// occurred.
package struct TextualParsingError: Error, CustomStringConvertible {
    package let line: Int
    package let column: Int
    package let message: String

    package var description: String {
        "\(line + 1):\(column + 1): \(message)"
    }
}

/// A convenience used to wrap either the schema for a regular field or an extension that is
/// returned when parsing TextFormat or JSON.
enum FieldOrExtensionSchema {
    /// A regular field.
    case field(FieldSchema)

    /// An extension field.
    case `extension`(ExtensionSchema)

    /// An unknown or reserved field.
    case unknown
}
