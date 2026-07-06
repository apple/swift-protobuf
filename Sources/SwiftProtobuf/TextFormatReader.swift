// Sources/SwiftProtobuf/TextFormatReader.swift - Text format reader
//
// Copyright (c) 2014 - 2026 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// High-level wrapper around a `Tokenizer` that knows how to parse TextFormat
/// input.
///
// -----------------------------------------------------------------------------

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// This type is a high-level wrapper around a `Tokenizer` that knows how to
/// parse TextFormat input.
///
/// This reader adheres to the Text Format specification
/// (https://protobuf.dev/reference/protobuf/textformat-spec/) and is largely
/// based on the C++ protobuf implementation.
struct TextFormatReader: TextualParser {
    var tokenizer: Tokenizer
    var recursionBudget: Int
    var errorCode: SwiftProtobufError.Code { .textFormatDecodingError }

    private var messageSchema: MessageSchema
    private let options: TextFormatDecodingOptions
    private let extensions: ExtensionMap?

    var complete: Bool { tokenizer.current.kind == .end }

    /// Creates a new text format reader.
    ///
    /// - Precondition: `buffer.baseAddress` is not nil.
    internal init(
        buffer: UnsafeBufferPointer<UInt8>,
        messageSchema: MessageSchema,
        options: TextFormatDecodingOptions,
        extensions: ExtensionMap?
    ) throws {
        precondition(buffer.baseAddress != nil, "buffer.baseAddress must not be nil")

        var tokenizer = Tokenizer(buffer: buffer, mode: .textFormat, errorCode: .textFormatDecodingError)
        try tokenizer.next()

        self.tokenizer = tokenizer
        self.messageSchema = messageSchema
        self.extensions = extensions
        self.options = options
        self.recursionBudget = options.messageDepthLimit
    }

    /// Consumes a Boolean value from the tokenizer, which may be represented as an identifier or as
    /// a numeric value.
    mutating func consumeBool() throws -> Bool {
        switch tokenizer.current.kind {
        case .integer:
            return try consumeUnsignedInteger(upperBound: 1) == 1
        case .identifier:
            // Save the token we just peeked at before consuming it.
            let booleanToken = tokenizer.current

            // According to the Text Format specification, the only permitted
            // non-numeric spellings are "t", "true", "True" for true, and
            // "f", "false", "False" for false.
            switch try consumeIdentifier() {
            case "t", "true", "True":
                return true
            case "f", "false", "False":
                return false
            default:
                throw parsingError(expected: "a Boolean value", at: booleanToken)
            }
        default:
            throw parsingError(expected: [.integer, .identifier])
        }
    }

    /// Consumes an identifier from the tokenizer.
    mutating func consumeIdentifier() throws -> String {
        guard at(.identifier) else {
            throw parsingError(expected: .identifier)
        }
        let identifier = tokenizer.current.exactString
        _ = try tokenizer.next()
        return identifier
    }

    /// Consumes a signed integer from the tokenizer.
    ///
    /// - Parameter upperBound: The maximum value of the integer to consume. If the integer is
    ///   greater than `upperBound`, an error will be thrown.
    mutating func consumeSignedInteger(upperBound: Int64) throws -> Int64 {
        precondition(upperBound >= 0, "Upper bound must be non-negative")

        var negative = false
        var upperBound = UInt64(upperBound)
        if try consumeIfPresent(.minus) {
            negative = true
            // Two's compliment always allows one more negative integer than positive.
            upperBound += 1
        }

        let unsigned = try consumeUnsignedInteger(upperBound: upperBound)
        if negative {
            if unsigned == UInt64(Int64.max) + 1 {
                return Int64.min
            }
            return -Int64(unsigned)
        } else {
            return Int64(unsigned)
        }
    }

    /// Consumes an unsigned integer from the tokenizer.
    ///
    /// - Parameter upperBound: The maximum value of the integer to consume. If the integer is
    ///   greater than `upperBound`, an error will be thrown.
    mutating func consumeUnsignedInteger(upperBound: UInt64) throws -> UInt64 {
        guard at(.integer) else {
            throw parsingError(expected: .integer)
        }
        let value = try tokenizer.current.integerValue(upperBound: upperBound, errorCode: errorCode)
        _ = try tokenizer.next()
        return value
    }

    /// Consumes a type URL or extension name from the tokenizer, including the required square
    /// bracket delimiters (which are not included in the returned string).
    mutating func consumeAnyTypeURLOrExtensionName() throws -> String {
        // We must do this before consuming the left bracket since that will
        // advance the tokenizer to the next token.
        try reportingURLCharacters { reader in
            try reader.consume(.leftBracket)
            var urlCharacters: String = ""
            while reader.at(.urlCharacters) {
                urlCharacters.append(reader.tokenizer.current.exactString)
                _ = try reader.tokenizer.next()
            }
            try reader.consume(.rightBracket)

            guard let lastSlashIndex = urlCharacters.lastIndex(of: "/") else {
                // No slash found, so assume it's a type name and return it
                // without further validation.
                return urlCharacters
            }

            // Found a slash, so assume it's a type URL.
            let urlPrefix = urlCharacters[...lastSlashIndex]
            let fullTypeName = urlCharacters[urlCharacters.index(after: lastSlashIndex)...]

            // Validate the prefix.
            guard urlPrefix != "/" else {
                throw reader.parsingError(reason: "Type URL prefix cannot be empty")
            }
            guard urlPrefix.first != "/" else {
                throw reader.parsingError(reason: "Type URL cannot start with '/'")
            }

            // Validate URL percent encodings in the prefix. Every '%' must
            // be followed by two hex characters.
            var index = urlPrefix.startIndex
            while index < urlPrefix.endIndex {
                // Advance past any normal characters (non-percent).
                guard urlPrefix.utf8[index] == UInt8(ascii: "%") else {
                    index = urlPrefix.index(after: index)
                    continue
                }

                // Found '%'. Check that it's followed by two hex digits.
                guard
                    case let hex1Index = urlPrefix.index(after: index),
                    hex1Index != urlPrefix.endIndex,
                    case let hex2Index = urlPrefix.index(after: hex1Index),
                    hex2Index != urlPrefix.endIndex,
                    Tokenizer.isHexDigit(urlPrefix.utf8[hex1Index]),
                    Tokenizer.isHexDigit(urlPrefix.utf8[hex2Index])
                else {
                    let endIndex =
                        urlPrefix.index(
                            index,
                            offsetBy: 2,
                            limitedBy: urlPrefix.endIndex
                        ) ?? urlPrefix.endIndex
                    throw reader.parsingError(reason: "Invalid percent encoding: \(urlPrefix[index..<endIndex])")
                }
                index = urlPrefix.index(after: hex2Index)
            }

            // The type name must be valid identifiers separated by `.`.
            let components = fullTypeName.split(separator: ".", omittingEmptySubsequences: false)
            guard !components.isEmpty else {
                throw reader.parsingError(reason: "Type name cannot be empty")
            }
            for component in components {
                guard Tokenizer.isIdentifier(component) else {
                    throw reader.parsingError(reason: "Invalid identifier in type name: \(component)")
                }
            }

            return urlCharacters
        }
    }

    /// Consumes the next field or extension name (the latter including its
    /// square brackets) and returns the corresponding field/extension schema.
    ///
    /// If an unrecognized name or number was parsed, this method will return
    /// `.unknown` if the `TextFormatDecodingOptions` dictate that unknown
    /// fields should be ignored; otherwise it will throw a parsing error.
    ///
    /// Finally, this method returns `nil` if something other than a field name
    /// or number was parsed.
    mutating func consumeFieldOrExtensionIfPresent() throws -> FieldOrExtensionSchema? {
        if at(.leftBracket) {
            let extensionName = try consumeAnyTypeURLOrExtensionName()
            guard extensionName.firstIndex(of: "/") == nil else {
                throw parsingError(reason: "Extension name cannot contain '/'")
            }

            // Look up the extension field.
            if let ext = extensions?[fieldName: extensionName, in: messageSchema] {
                return .extension(ext)
            }
            if options.ignoreUnknownExtensionFields || messageSchema.isFieldNameReserved(extensionName) {
                return .unknown
            }
            throw parsingError(reason: "Unknown extension '\(extensionName)' on '\(messageSchema.messageName)'")
        }

        if at(.identifier) {
            // Look up the regular field.
            let identifier = try consumeIdentifier()
            if let fieldNumber = messageSchema.fieldNumber(forTextName: identifier) {
                return .field(messageSchema[fieldNumber: fieldNumber]!)
            }
            if options.ignoreUnknownFields || messageSchema.isFieldNameReserved(identifier) {
                return .unknown
            }
            throw parsingError(reason: "Unknown field '\(identifier)' on '\(messageSchema.messageName)'")
        }

        if at(.integer) {
            // Look up the regular field or extension field by number.
            let fieldNumber = UInt32(try consumeUnsignedInteger(upperBound: maximumFieldNumber))
            if let ext = extensions?[fieldNumber: fieldNumber, in: messageSchema] {
                return .extension(ext)
            }
            if let field = messageSchema[fieldNumber: fieldNumber] {
                return .field(field)
            }
            if options.ignoreUnknownFields || messageSchema.isFieldNumberReserved(fieldNumber) {
                return .unknown
            }
            throw parsingError(reason: "Unknown field number \(fieldNumber) on \(messageSchema.messageName)")
        }

        return nil
    }

    /// Consumes a floating point value from the tokenizer.
    mutating func consumeDouble() throws -> Double {
        let negative = try consumeIfPresent(.minus)
        switch tokenizer.current.kind {
        case .integer:
            let value = try consumeUnsignedDecimalAsDouble()
            return negative ? -value : value

        case .float:
            let value = try tokenizer.current.floatValue(errorCode: errorCode)
            _ = try tokenizer.next()
            return negative ? -value : value

        case .identifier:
            let text = tokenizer.current.exactString.lowercased()
            _ = try tokenizer.next()
            switch text {
            case "inf", "infinity":
                return negative ? -.infinity : .infinity
            case "nan":
                return .nan
            default:
                throw parsingError(expected: "a floating point value")
            }

        default:
            throw parsingError(expected: "a floating point value")
        }
    }

    /// Consumes an unsigned decimal integer or floating point value from the tokenizer.
    mutating func consumeUnsignedDecimalAsDouble() throws -> Double {
        guard at(.integer) else {
            throw parsingError(expected: .integer)
        }
        guard !tokenizer.current.isHexNumber && !tokenizer.current.isOctalNumber else {
            throw parsingError(expected: "a decimal number")
        }

        // Try to parse is as a UInt64 first.
        do {
            let integerValue = try tokenizer.current.integerValue(errorCode: errorCode)
            _ = try tokenizer.next()
            return Double(integerValue)
        } catch {
            // If the integer value is too large to fit in a UInt64, try parsing
            // it as a double instead.
        }
        let doubleValue = try tokenizer.current.floatValue(errorCode: errorCode)
        _ = try tokenizer.next()
        return doubleValue
    }

    /// Consumes a sequence of zero or more string tokens, concatenting them
    /// together as raw bytes and resolving any escapes.
    mutating func consumeBytes() throws -> Data {
        guard at(.string, .stringWithEscapes) else {
            throw parsingError(expected: "a string value")
        }

        var result = Data()
        while at(.string, .stringWithEscapes) {
            let segment = try tokenizer.current.bytesValue(allowSurrogates: false, errorCode: errorCode)
            result.append(segment)
            _ = try tokenizer.next()
        }
        return result
    }

    /// Consumes a sequence of zero or more string tokens, concatenating them
    /// together and resolving any escapes.
    mutating func consumeString() throws -> String {
        guard at(.string, .stringWithEscapes) else {
            throw parsingError(expected: "a string value")
        }

        var result = ""
        while at(.string, .stringWithEscapes) {
            let segment = try tokenizer.current.stringValue(allowSurrogates: false, errorCode: errorCode)
            result += segment
            _ = try tokenizer.next()
        }
        return result
    }

    /// Consumes an enum value from the tokenizer, ensuring that it is valid for
    /// the given enum schema.
    mutating func consumeEnumValue(schema: EnumSchema) throws -> Int32 {
        if at(.identifier) {
            let identifier = try consumeIdentifier()
            if let rawValue = schema.enumCase(forTextName: identifier) {
                return rawValue
            }
        } else if at(.minus, .integer) {
            let rawValue = Int32(try consumeSignedInteger(upperBound: Int64(Int32.max)))
            if schema.isValidValue(rawValue) {
                return rawValue
            }
        }
        throw parsingError(expected: "a valid enum value for \(String(protobufUTF8Name: schema.enumName))")
    }

    /// Called to consume the next value, which might be an array of values.
    ///
    /// In text format, repeated fields of non-message types can be represented in two ways:
    /// repetition of the field name and value, or as the field name followed by an array of values
    /// in square brackets. If we detect the square bracket, we delegate to the given closure to
    /// scan and append the value until we encounter the corresponding closing bracket. Otherwise,
    /// we call the closure only once to scan and append an individual value.
    @inline(__always)
    mutating func consumePossibleArray(
        consumeValue: (inout TextFormatReader) throws -> Void
    ) throws {
        guard try consumeIfPresent(.leftBracket) else {
            // If we didn't see a square bracket, assume it's a single element and call the closure
            // once.
            try consumeValue(&self)
            return
        }

        // We saw a left bracket, so read multiple elements, calling the closure for each one.
        if try consumeIfPresent(.rightBracket) {
            // The array was empty.
            return
        }
        while true {
            try consumeValue(&self)
            if try consumeIfPresent(.rightBracket) {
                return
            }
            try consume(.comma)
        }
    }

    /// Consumes the separator after a field value, if present.
    ///
    /// It is not a failure if the end of a message is found instead of a
    /// separator; the caller will handle this case. A parsing error is only
    /// thrown if the next token is something that could not follow a field
    /// value.
    mutating func consumeFieldSeparatorIfPresent() throws {
        _ = try consumeIfPresent(.comma) || consumeIfPresent(.semicolon)
    }

    /// Skips the current field in the input.
    ///
    /// - Parameter wasNameAlreadyConsumed: Whether the field name has already been consumed (and
    ///   thus should not be skipped by this function).
    mutating func skipField(wasNameAlreadyConsumed: Bool) throws {
        if !wasNameAlreadyConsumed {
            if at(.leftBracket) {
                _ = try consumeAnyTypeURLOrExtensionName()
            } else if at(.identifier) {
                _ = try consumeIdentifier()
            } else if at(.integer) {
                _ = try consumeUnsignedInteger(upperBound: UInt64.max)
            } else {
                throw parsingError(expected: "a field name or number")
            }
        }

        if try consumeIfPresent(.colon) {
            if at(.leftBrace, .leftAngle) {
                try skipFieldMessage()
            } else {
                try skipFieldValue()
            }
        } else {
            // If there wasn't a colon immediately following the field name that
            // was just read, it must be a message value (or invalid).
            try skipFieldMessage()
        }
    }

    /// Skips a field value which is a message.
    mutating func skipFieldMessage() throws {
        try decrementRecursionBudget()
        defer { incrementRecursionBudget() }

        let delimiter = try consumeMessageDelimiter()
        while !at(.rightBrace, .rightAngle) {
            try skipField(wasNameAlreadyConsumed: false)
            try consumeFieldSeparatorIfPresent()
        }
        try consume(delimiter)
    }

    /// Skips a field value which is not a message.
    mutating func skipFieldValue() throws {
        try decrementRecursionBudget()
        defer { incrementRecursionBudget() }

        // If it's a string, consume it (multiple juxtaposted segments, possibly).
        if at(.string, .stringWithEscapes) {
            while at(.string, .stringWithEscapes) {
                _ = try tokenizer.next()
            }
            return
        }

        // If it's an array in `[...]` form, skip the contents.
        if try consumeIfPresent(.leftBracket) {
            if try !consumeIfPresent(.rightBracket) {
                while true {
                    if !at(.leftBrace, .leftAngle) {
                        try skipFieldValue()
                    } else {
                        try skipFieldMessage()
                    }
                    if try consumeIfPresent(.rightBracket) {
                        break
                    }
                    try consume(.comma)
                }
            }
            return
        }

        let hasMinus = try consumeIfPresent(.minus)
        if !at(.integer, .float, .identifier) {
            throw parsingError(expected: "a number or identifier")
        }
        if hasMinus && at(.identifier) {
            switch tokenizer.current.exactString.lowercased() {
            case "inf", "infinity", "nan":
                // Happy path; continue below.
                break
            default:
                throw parsingError(expected: "a floating point value")
            }
        }
        _ = try tokenizer.next()
    }

    /// Consumes an opening brace or angle bracket acting as a submessage
    /// delimiter and returns the corresponding closing delimiter.
    private mutating func consumeMessageDelimiter() throws -> Token.Kind {
        if try consumeIfPresent(.leftAngle) {
            return .rightAngle
        }
        try consume(.leftBrace)
        return .rightBrace
    }

    /// Calls the given closure with the `TextFormatReader` configured to start reading an object
    /// with a different schema at the given position.
    ///
    /// When the closure has completed, the receiver's state will be reverted to be suitable for
    /// reading from the original message again.
    ///
    /// - Parameters:
    ///   - expectedSchema: The `MessageSchema` of the message that we are expecting to read, from
    ///     which the name map will be retrieved.
    ///   - body: A closure that will be executed within the context of the sub-reader.
    @inline(__always)
    mutating func withReaderForNextObject(
        expectedSchema: MessageSchema,
        _ body: (inout TextFormatReader) throws -> Void
    ) throws {
        let delimiter = try consumeMessageDelimiter()

        try decrementRecursionBudget()
        defer { incrementRecursionBudget() }

        let originalSchema = self.messageSchema
        self.messageSchema = expectedSchema
        defer { self.messageSchema = originalSchema }

        try body(&self)
        try consume(delimiter)
    }
}

/// The highest possible field number allowed by protobuf.
///
/// This is a `UInt64` since it's passed as an upper bound to the tokenizer.
private var maximumFieldNumber: UInt64 { 1 << 29 - 1 }
