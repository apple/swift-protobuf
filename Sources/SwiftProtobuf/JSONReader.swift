// Sources/SwiftProtobuf/JSONReader.swift - JSON reader
//
// Copyright (c) 2014 - 2026 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// High-level wrapper around a `Tokenizer` that knows how to parse JSON input.
///
// -----------------------------------------------------------------------------

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// This type is a high-level wrapper around a `Tokenizer` that knows how to
/// parse JSON input.
///
/// This reader adheres to the ProtoJSON Format specification
/// (https://protobuf.dev/programming-guides/json/).
struct JSONReader: TextualParser {
    var tokenizer: Tokenizer
    var recursionBudget: Int
    var errorCode: SwiftProtobufError.Code { .jsonDecodingError }

    private var messageSchema: MessageSchema
    let options: JSONDecodingOptions
    let extensions: ExtensionMap?

    var complete: Bool { tokenizer.current.kind == .end }

    /// Creates a new text format reader.
    ///
    /// - Precondition: `buffer.baseAddress` is not nil.
    internal init(
        buffer: UnsafeBufferPointer<UInt8>,
        messageSchema: MessageSchema,
        options: JSONDecodingOptions,
        extensions: ExtensionMap?
    ) throws {
        precondition(buffer.baseAddress != nil, "buffer.baseAddress must not be nil")

        var tokenizer = Tokenizer(buffer: buffer, mode: .json, errorCode: .jsonDecodingError)
        try tokenizer.next()

        self.tokenizer = tokenizer
        self.messageSchema = messageSchema
        self.extensions = extensions
        self.options = options
        self.recursionBudget = options.messageDepthLimit
    }

    /// Consumes the next field or extension name (the latter including its square brackets) and
    /// returns the corresponding field/extension schema.
    ///
    /// If an unrecognized name or number was parsed, this method will return `.unknown` if the
    /// `TextFormatDecodingOptions` dictate that unknown fields should be ignored; otherwise it will
    /// throw a parsing error.
    mutating func consumeFieldOrExtension() throws -> FieldOrExtensionSchema {
        let key = try consumeString()
        if key.first == "[" && key.last == "]" {
            let extensionName = String(key.dropFirst().dropLast())

            // Look up the extension field.
            if let ext = extensions?[fieldName: extensionName, in: messageSchema] {
                return .extension(ext)
            }
            if options.ignoreUnknownFields || messageSchema.isFieldNameReserved(extensionName) {
                return .unknown
            }
            throw parsingError(reason: "Unknown extension '\(extensionName)' on '\(messageSchema.messageName)'")
        }

        if let fieldNumber = messageSchema.fieldNumber(forJSONName: key) {
            return .field(messageSchema[fieldNumber: fieldNumber]!)
        }
        if options.ignoreUnknownFields || messageSchema.isFieldNameReserved(key) {
            return .unknown
        }
        throw parsingError(reason: "Unknown field '\(key)' on '\(messageSchema.messageName)'")
    }

    /// Consumes a Boolean value from the tokenizer, which may be represented as an identifier or as
    /// a numeric value.
    mutating func consumeBool(asQuotedString: Bool = false) throws -> Bool {
        func valueError() -> SwiftProtobufError {
            parsingError(expected: "true or false")
        }

        let value: String

        // When parsing a map key, the value must be a string (required by JSON).
        if asQuotedString {
            guard at(.string, .stringWithEscapes) else {
                throw valueError()
            }
            value = try tokenizer.current.stringValue(allowSurrogates: false, errorCode: errorCode)
        } else {
            // Find it as an identifier (an unquoted string).
            guard at(.identifier) else {
                throw valueError()
            }
            value = tokenizer.current.exactString
        }

        _ = try tokenizer.next()

        switch value {
        case "true": return true
        case "false": return false
        default: throw valueError()
        }
    }

    /// Consumes a double-quoted string and returns it as raw bytes, resolving any escapes.
    mutating func consumeBytes() throws -> Data {
        guard at(.string, .stringWithEscapes) else {
            throw parsingError(expected: "a string value")
        }

        let string = try tokenizer.current.stringValue(allowSurrogates: false, errorCode: errorCode)
        _ = try tokenizer.next()
        return try decodeBase64(from: string)
    }

    /// Consumes a signed integer from the tokenizer.
    ///
    /// - Parameter upperBound: The maximum value of the integer to consume. If the integer is
    ///   greater than `upperBound`, an error will be thrown.
    mutating func consumeSignedInteger(upperBound: Int64) throws -> Int64 {
        precondition(upperBound >= 0, "Upper bound must be non-negative")

        var negative = false
        let unsigned: UInt64

        if at(.string, .stringWithEscapes) {
            unsigned = try parseQuotedInteger(isSigned: true, negative: &negative, upperBound: UInt64(upperBound))
        } else {
            unsigned = try consumeSignedMagnitude(negative: &negative, upperBound: UInt64(upperBound))
        }

        if negative {
            if unsigned == UInt64(Int64.max) + 1 {
                return Int64.min
            }
            return -Int64(unsigned)
        } else {
            return Int64(unsigned)
        }
    }

    private mutating func consumeSignedMagnitude(
        negative: inout Bool,
        upperBound: UInt64
    ) throws -> UInt64 {
        var upperBound = upperBound
        if try consumeIfPresent(.minus) {
            negative = true
            // Two's compliment always allows one more negative integer than positive.
            upperBound += 1
        }
        return try consumeUnsignedInteger(upperBound: upperBound)
    }

    /// Consumes an unsigned integer from the tokenizer.
    ///
    /// - Parameter upperBound: The maximum value of the integer to consume. If the integer is
    ///   greater than `upperBound`, an error will be thrown.
    mutating func consumeUnsignedInteger(upperBound: UInt64) throws -> UInt64 {
        if at(.string, .stringWithEscapes) {
            var negative = false
            return try parseQuotedInteger(isSigned: false, negative: &negative, upperBound: upperBound)
        }
        if at(.float) {
            // Floating-point numbers are allowed as long as they correspond exactly to an integer
            // value.
            let value = try tokenizer.current.floatValue(errorCode: errorCode)
            _ = try tokenizer.next()
            guard let result = UInt64(exactly: value), result <= upperBound else {
                throw parsingError(reason: "Expected an integer in 0...\(upperBound)")
            }
            return result
        }

        // Otherwise, it must be an integer token.
        guard at(.integer) else {
            throw parsingError(expected: .integer)
        }
        let value = try tokenizer.current.integerValue(upperBound: upperBound, errorCode: errorCode)
        _ = try tokenizer.next()
        return value
    }

    /// Consumes a double-quoted string, resolving any escapes, and parses it as an integer using
    /// `Tokenizer` so that quoted and unquoted numbers share the exact same validation.
    private mutating func parseQuotedInteger(
        isSigned: Bool,
        negative: inout Bool,
        upperBound: UInt64
    ) throws -> UInt64 {
        if at(.string) {
            let utf8Bytes = try consumeUnescapedStringBytes()
            return try parseQuotedInteger(
                from: utf8Bytes,
                isSigned: isSigned,
                negative: &negative,
                upperBound: upperBound
            )
        }
        var stringValue = try consumeString()
        return try stringValue.withUTF8 { utf8Bytes in
            try parseQuotedInteger(
                from: utf8Bytes,
                isSigned: isSigned,
                negative: &negative,
                upperBound: upperBound
            )
        }
    }

    private mutating func parseQuotedInteger(
        from utf8Bytes: UnsafeBufferPointer<UInt8>,
        isSigned: Bool,
        negative: inout Bool,
        upperBound: UInt64
    ) throws -> UInt64 {
        guard let subTokenizer = try makeQuotedNumberTokenizer(utf8Bytes) else {
            throw parsingError(reason: "Invalid number string")
        }
        let originalTokenizer = self.tokenizer
        defer { self.tokenizer = originalTokenizer }
        self.tokenizer = subTokenizer
        let result =
            isSigned
            ? try consumeSignedMagnitude(negative: &negative, upperBound: upperBound)
            : try consumeUnsignedInteger(upperBound: upperBound)
        guard complete else {
            throw parsingError(reason: "Invalid number string")
        }
        return result
    }

    /// Consumes a `.string` token (which has no escapes) and returns the slice of UTF-8 bytes
    /// between the quotes without creating a `String`.
    private mutating func consumeUnescapedStringBytes() throws -> UnsafeBufferPointer<UInt8> {
        let text = tokenizer.current.text
        _ = try tokenizer.next()
        return UnsafeBufferPointer(rebasing: text[1..<(text.count - 1)])
    }

    /// Creates a `Tokenizer` over the UTF-8 bytes of a quoted number string if it starts with a
    /// minus sign (immediately followed by a digit) or digit and ends with a digit (so leading,
    /// internal, and trailing whitespace are rejected). Returns `nil` if the bytes do not start
    /// and end with digits.
    private func makeQuotedNumberTokenizer(_ utf8Bytes: UnsafeBufferPointer<UInt8>) throws -> Tokenizer? {
        let firstDigitIndex = (utf8Bytes.first == UInt8(ascii: "-")) ? 1 : 0
        guard
            firstDigitIndex < utf8Bytes.count,
            Tokenizer.isDigit(utf8Bytes[firstDigitIndex]),
            Tokenizer.isDigit(utf8Bytes.last!)
        else {
            return nil
        }
        var subTokenizer = Tokenizer(buffer: utf8Bytes, mode: .json, errorCode: .jsonDecodingError)
        try subTokenizer.next()
        return subTokenizer
    }

    /// Consumes a double-quoted string, resolving any escapes.
    mutating func consumeString() throws -> String {
        guard at(.string, .stringWithEscapes) else {
            throw parsingError(expected: "a string value")
        }

        let string = try tokenizer.current.stringValue(allowSurrogates: true, errorCode: errorCode)
        _ = try tokenizer.next()
        return string
    }

    /// Consumes a 32-bit floating point value from the tokenizer, ensuring that it is within the
    /// valid range for `Float`.
    mutating func consumeFloat() throws -> Float {
        let doubleValue = try consumeDouble()
        if !doubleValue.isFinite {
            // If it's already non-finite, just convert it to the equivalent `Float`. This preserves
            // values like `"Infinity"` when decoded from a string. If it was a finite value that
            // was too large for a `Double`, we already would have thrown.
            return Float(doubleValue)
        }
        // Now, we know we have a finite `Double` value, but it might still be outside the range of
        // a `Float`, so check that.
        return try throwIfNotFinite(Float(doubleValue))
    }

    /// Consumes a 64-bit floating point value from the tokenizer.
    mutating func consumeDouble() throws -> Double {
        if at(.string) {
            let utf8Bytes = try consumeUnescapedStringBytes()
            return try parseQuotedDouble(from: utf8Bytes)
        }
        if at(.stringWithEscapes) {
            var stringValue = try consumeString()
            return try stringValue.withUTF8 { utf8Bytes in
                try parseQuotedDouble(from: utf8Bytes)
            }
        }

        let negative = try consumeIfPresent(.minus)
        switch tokenizer.current.kind {
        case .integer:
            let value = try consumeUnsignedDecimalAsDouble()
            return try throwIfNotFinite(negative ? -value : value)

        case .float:
            let value = try tokenizer.current.floatValue(errorCode: errorCode)
            _ = try tokenizer.next()
            return try throwIfNotFinite(negative ? -value : value)

        default:
            throw parsingError(expected: "a floating point value")
        }
    }

    private mutating func parseQuotedDouble(from utf8Bytes: UnsafeBufferPointer<UInt8>) throws -> Double {
        guard let subTokenizer = try makeQuotedNumberTokenizer(utf8Bytes) else {
            // The longest valid value here is "-Infinity" (9 bytes), so fail fast on larger input.
            guard utf8Bytes.count <= 9 else {
                throw parsingError(reason: "Invalid number string")
            }
            switch String(decoding: utf8Bytes, as: UTF8.self) {
            case "NaN":
                return .nan
            case "Inf", "Infinity":
                return .infinity
            case "-Inf", "-Infinity":
                return -.infinity
            default:
                throw parsingError(reason: "Invalid number string")
            }
        }
        let originalTokenizer = self.tokenizer
        defer { self.tokenizer = originalTokenizer }
        self.tokenizer = subTokenizer
        let result = try consumeDouble()
        guard complete else {
            throw parsingError(reason: "Invalid number string")
        }
        return result
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
            return try throwIfNotFinite(Double(integerValue))
        } catch {
            // If the integer value is too large to fit in a UInt64, try parsing
            // it as a double instead.
        }
        let doubleValue = try tokenizer.current.floatValue(errorCode: errorCode)
        _ = try tokenizer.next()
        return try throwIfNotFinite(doubleValue)
    }

    /// Verifies that the given floating point value is in the valid range for the given type.
    private func throwIfNotFinite<T: BinaryFloatingPoint>(_ value: T) throws -> T {
        guard value.isFinite else {
            throw parsingError(reason: "Out-of-range floating point value")
        }
        return value
    }

    /// Consumes the `null` keyword, if present.
    ///
    /// - Returns: `true` if `null` was consumed, `false` otherwise.
    mutating func consumeNullIfPresent() throws -> Bool {
        guard at(.identifier) else { return false }
        if tokenizer.current.exactString != "null" {
            return false
        }
        _ = try tokenizer.next()
        return true
    }

    /// Consumes an enum value from the tokenizer, ensuring that it is valid for
    /// the given enum schema.
    ///
    /// - Parameter schema: The enum schema to use for validation.
    /// - Returns: The raw value of the enum, or `nil` if the value is not valid and unknown
    ///   fields are being ignored.
    mutating func consumeEnumValue(schema: EnumSchema) throws -> Int32? {
        func valueError() -> SwiftProtobufError {
            parsingError(expected: "a valid enum value for \(schema.enumName)")
        }

        if try consumeNullIfPresent() {
            switch CustomJSONWKTClassification(enumSchema: schema) {
            case .nullValue:
                return 0
            default:
                throw valueError()
            }
        }

        if at(.string, .stringWithEscapes) {
            let enumValue = try consumeString()
            if let rawValue = schema.enumCase(forJSONName: enumValue) {
                return rawValue
            }
        } else if at(.minus, .integer) {
            let rawValue = Int32(try consumeSignedInteger(upperBound: Int64(Int32.max)))
            if schema.isValidValue(rawValue) {
                return rawValue
            }
        }

        guard options.ignoreUnknownFields && messageSchema.extensibilityMode != .mapEntry else {
            throw valueError()
        }
        return nil
    }

    /// Called to consume the next object, calling the given closure for each key and value in the
    /// object.
    ///
    /// - Parameters:
    ///   - consumeKeyAndValue: A closure that will be called for each key and value in the object.
    ///   - ifEmpty: A closure that will be called if the object is empty.
    @inline(__always)
    mutating func consumeObject(
        consumeKeyAndValue: (inout JSONReader) throws -> Void,
        ifEmpty: () -> Void = {}
    ) throws {
        try consume(.leftBrace)
        try decrementRecursionBudget()
        defer { incrementRecursionBudget() }

        if try consumeIfPresent(.rightBrace) {
            // The object was empty.
            ifEmpty()
            return
        }

        while true {
            try consumeKeyAndValue(&self)
            if try consumeIfPresent(.rightBrace) {
                return
            }
            try consume(.comma)
        }
    }

    /// Called to consume the next array of values, calling the given closure for each element in
    /// the array.
    ///
    /// - Parameter impactsRecursionDepth: Whether consuming the array should impact the recursion
    ///   depth. Used when processing the direct array representation of
    ///   `google.protobuf.ListValue` to ensure that deeply nested lists can't exceed the depth.
    @inline(__always)
    mutating func consumeArray(
        impactsRecursionDepth: Bool = false,
        consumeValue: (inout JSONReader) throws -> Void
    ) throws {
        if try consumeNullIfPresent() {
            // TODO: Figure out if we should clear the field. The old JSONDecoder implementation
            // just returns, but that might be because we don't have a distinction between
            // merge and init for JSON.
            return
        }

        // We saw a left bracket, so read multiple elements, calling the closure for each one.
        try consume(.leftBracket)
        if impactsRecursionDepth {
            try decrementRecursionBudget()
        }
        defer {
            if impactsRecursionDepth {
                incrementRecursionBudget()
            }
        }
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

    /// Skips the current field in the input.
    ///
    /// - Parameter wereNameAndColonAlreadyConsumed: Whether the field name and colon have already
    ///   been consumed (and thus should not be skipped by this function).
    /// - Returns: The slice of the buffer that was skipped.
    mutating func skipField(wereNameAndColonAlreadyConsumed: Bool) throws -> UnsafeBufferPointer<UInt8> {
        if !wereNameAndColonAlreadyConsumed {
            try consume(anyOf: .string, .stringWithEscapes)
            try consume(.colon)
        }

        let startOffset = tokenizer.currentOffset
        try skipFieldValue()
        let endOffset = tokenizer.currentOffset
        return .init(rebasing: tokenizer.buffer[startOffset..<endOffset])
    }

    /// Skips a field value which is a message.
    mutating func skipFieldMessage() throws {
        try consumeObject { reader in
            _ = try reader.skipField(wereNameAndColonAlreadyConsumed: false)
        }
    }

    /// Skips a field value which is not a message.
    mutating func skipFieldValue() throws {
        // If it's a string, consume it.
        if at(.string, .stringWithEscapes) {
            _ = try tokenizer.next()
            return
        }

        // If it's an object, skip the contents.
        if at(.leftBrace) {
            try skipFieldMessage()
            return
        }

        // If it's an array in `[...]` form, skip the contents.
        if try consumeIfPresent(.leftBracket) {
            if try !consumeIfPresent(.rightBracket) {
                while true {
                    if !at(.leftBrace) {
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

        try consumeIfPresent(.minus)
        if at(.integer) {
            _ = try consumeUnsignedInteger(upperBound: UInt64.max)
            return
        }
        if at(.float) {
            _ = try consumeDouble()
            return
        }
        if at(.identifier) {
            switch tokenizer.current.exactString {
            case "null", "true", "false":
                _ = try tokenizer.next()
                return
            default:
                // Error below.
                break
            }
        }
        throw parsingError(reason: "Malformed JSON")
    }

    /// Returns a `Data` value containing bytes equivalent to the given
    /// Base64-encoded string, or nil if the conversion fails.
    ///
    /// Notes on Google's implementation (Base64Unescape() in strutil.cc):
    ///  * Google's C++ implementation accepts arbitrary whitespace
    ///    mixed in with the base-64 characters
    ///  * Google's C++ implementation ignores missing '=' characters
    ///    but if present, there must be the exact correct number of them.
    ///  * The conformance test requires us to accept both standard RFC4648
    ///    Base 64 encoding and the "URL and Filename Safe Alphabet" variant.
    private func decodeBase64(from string: String) throws -> Data {
        let source = string.utf8
        var index = source.startIndex
        let end = source.endIndex

        // Count the base-64 digits
        // Ignore most unrecognized characters in this first pass,
        // stop at the closing double quote.
        let digitsStart = index
        var rawChars = 0
        var sawSection4Characters = false
        var sawSection5Characters = false
        while index != end {
            let digit = source[index]
            switch digit {
            case UInt8(ascii: "+"), UInt8(ascii: "/"):
                sawSection4Characters = true
            case UInt8(ascii: "-"), UInt8(ascii: "_"):
                sawSection5Characters = true
            case UInt8(ascii: "0")...UInt8(ascii: "9"),
                UInt8(ascii: "A")...UInt8(ascii: "Z"),
                UInt8(ascii: "a")...UInt8(ascii: "z"),
                UInt8(ascii: "="), UInt8(ascii: " "):
                // Valid base64 character or ignored whitespace.
                break
            default:
                throw parsingError(reason: "Invalid base64 string")
            }
            if base64Values[Int(digit)] >= 0 {
                rawChars += 1
            }
            source.formIndex(after: &index)
        }

        // Reject mixed encodings.
        if sawSection4Characters && sawSection5Characters {
            throw parsingError(reason: "Invalid base64 string")
        }

        // Allocate a Data object of exactly the right size
        var value = Data(count: rawChars * 3 / 4)

        // Scan the digits again and populate the Data object.
        // In this pass, we check for (and fail) if there are
        // unexpected characters.  But we don't check for end-of-input,
        // because the loop above already verified that there was
        // a closing double quote.
        index = digitsStart
        try value.withUnsafeMutableBytes {
            (body: UnsafeMutableRawBufferPointer) in
            if var p = body.baseAddress, body.count > 0 {
                var n = 0
                var chars = 0  // # chars in current group
                var padding = 0  // # padding '=' chars
                digits: while index != end {
                    let digit = source[index]
                    let k = base64Values[Int(digit)]
                    if k < 0 {
                        switch digit {
                        case UInt8(ascii: " "):
                            source.formIndex(after: &index)
                            continue digits
                        case UInt8(ascii: "="):  // Count padding
                            while index != end {
                                switch source[index] {
                                case UInt8(ascii: " "):
                                    break
                                case UInt8(ascii: "="):
                                    padding += 1
                                default:  // Only '=' and whitespace permitted
                                    throw parsingError(reason: "Invalid base64 string")
                                }
                                source.formIndex(after: &index)
                            }
                            break digits
                        default:
                            throw parsingError(reason: "Invalid base64 string")
                        }
                    }
                    n <<= 6
                    n |= k
                    chars += 1
                    if chars == 4 {
                        p[0] = UInt8(truncatingIfNeeded: n >> 16)
                        p[1] = UInt8(truncatingIfNeeded: n >> 8)
                        p[2] = UInt8(truncatingIfNeeded: n)
                        p += 3
                        chars = 0
                        n = 0
                    }
                    source.formIndex(after: &index)
                }
                switch chars {
                case 3:
                    p[0] = UInt8(truncatingIfNeeded: n >> 10)
                    p[1] = UInt8(truncatingIfNeeded: n >> 2)
                    if padding == 1 || padding == 0 {
                        return
                    }
                case 2:
                    p[0] = UInt8(truncatingIfNeeded: n >> 4)
                    if padding == 2 || padding == 0 {
                        return
                    }
                case 0:
                    if padding == 0 {
                        return
                    }
                default:
                    break
                }
                throw parsingError(reason: "Invalid base64 string")
            }
        }
        return value
    }

    /// Calls the given closure with the `JSONReader` configured to start reading an object with
    /// a different schema at the given position.
    ///
    /// When the closure has completed, the receiver's state will be reverted to be suitable for
    /// reading from the original message again.
    ///
    /// - Parameters:
    ///   - expectedSchema: The `MessageSchema` of the message that we are expecting to read, from
    ///     which the name map will be retrieved.
    ///   - body: A closure that will be executed within the context of the sub-reader.
    mutating func withReaderForNextObject(
        expectedSchema: MessageSchema,
        _ body: (inout JSONReader) throws -> Void
    ) throws {
        let originalSchema = self.messageSchema
        self.messageSchema = expectedSchema
        defer { self.messageSchema = originalSchema }

        try body(&self)
    }
}

// Decode both the RFC 4648 section 4 Base 64 encoding and the RFC
// 4648 section 5 Base 64 variant.  The section 5 variant is also
// known as "base64url" or the "URL-safe alphabet".
// Note that both "-" and "+" decode to 62 and "/" and "_" both
// decode as 63.
// swift-format-ignore: NoBlockComments
private let base64Values: [Int] = [
    /* 0x00 */ -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
    /* 0x10 */ -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
    /* 0x20 */ -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 62, -1, 62, -1, 63,
    /* 0x30 */ 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, -1, -1, -1, -1, -1, -1,
    /* 0x40 */ -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14,
    /* 0x50 */ 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, -1, -1, -1, -1, 63,
    /* 0x60 */ -1, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40,
    /* 0x70 */ 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, -1, -1, -1, -1, -1,
    /* 0x80 */ -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
    /* 0x90 */ -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
    /* 0xa0 */ -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
    /* 0xb0 */ -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
    /* 0xc0 */ -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
    /* 0xd0 */ -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
    /* 0xe0 */ -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
    /* 0xf0 */ -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
]
