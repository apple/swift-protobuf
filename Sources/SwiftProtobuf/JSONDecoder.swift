// Sources/SwiftProtobuf/JSONDecoder.swift - JSON decoding
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
///
// -----------------------------------------------------------------------------

///
/// Note: Only `init(json:)` and `nextToken()` are public (they're used
/// by the test harness and @testable breaks release builds at this writing).
/// The rest is `private` where possible.
///
public class JSONDecoder {

    /// A stack of tokens that should be returned upon the next call to `nextToken()`
    /// before the input string is scanned again.
    private var tokenPushback: [JSONToken]

    /// The decoder uses the UnicodeScalarView of the string, which is
    /// significantly faster than operating on Characters.
    private let scalars: String.UnicodeScalarView

    /// The index where the current token being scanned begins.
    private var tokenStart: String.UnicodeScalarView.Index

    /// The index of the next scalar to be scanned.
    private var index: String.UnicodeScalarView.Index

    /// Returns true if a complete and well-formed JSON string was fully scanned
    /// (that is, the only scalars remaining after the current index are
    /// whitespace).
    var complete: Bool {
        skipWhitespace()
        return index == scalars.endIndex && tokenPushback.isEmpty
    }

    /// Creates a new JSON decoder for the given string.
    public init(json: String) {
        self.scalars = json.unicodeScalars
        self.tokenStart = self.scalars.startIndex
        self.index = self.tokenStart
        tokenPushback = []
    }

    init(tokens: [JSONToken]) {
        self.scalars = "".unicodeScalars
        self.tokenStart = self.scalars.startIndex
        self.index = self.tokenStart
        tokenPushback = tokens.reversed()
    }

    /// Pushes a token back onto the decoder. Pushed-back tokens are read in the
    /// reverse order that they were pushed until the stack is exhausted, at which
    /// point tokens will again be read from the input string.
    func pushback(token: JSONToken) {
        tokenPushback.append(token)
    }

    /// Returns the next scalar being scanned and advances the index, or nil if
    /// the end of the string has been reached.
    private func nextScalar() -> UnicodeScalar? {
        guard index != scalars.endIndex else {
            return nil
        }
        let scalar = scalars[index]
        index = scalars.index(after: index)
        return scalar
    }

    /// Updates the token-start index to indicate that the next token should begin
    /// at the decoder's current index.
    private func skipScalars() {
        tokenStart = index
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
            default:
                index = lastIndex
                tokenStart = index
                return
            }
        }
    }

    /// Returns the next token in the JSON string, or nil if the end of the string
    /// has been reached.
    public func nextToken() throws -> JSONToken? {
        if let pushedBackToken = tokenPushback.popLast() {
            return pushedBackToken
        }
        skipWhitespace()
        if index == scalars.endIndex {
            return nil
        }
        tokenStart = index
        let scalar = scalars[index]
        switch scalar {
        case "\"":
            let s = try quotedString()
            return .string(s)
        case "-", "0"..."9":
            return try numberToken(startingWith: scalar)
        case ":":
            index = scalars.index(after: index)
            return .colon
        case ",":
            index = scalars.index(after: index)
            return .comma
        case "{":
            index = scalars.index(after: index)
            return .beginObject
        case "}":
            index = scalars.index(after: index)
            return .endObject
        case "[":
            index = scalars.index(after: index)
            return .beginArray
        case "]":
            index = scalars.index(after: index)
            return .endArray
        case "n":
            index = scalars.index(after: index)
            if matchesKeyword("ull") {
                return .null
            }
            throw DecodingError.malformedJSON
        case "f":
            index = scalars.index(after: index)
            if matchesKeyword("alse") {
                return .boolean(false)
            }
            throw DecodingError.malformedJSON
        case "t":
            index = scalars.index(after: index)
            if matchesKeyword("rue") {
                return .boolean(true)
            }
            throw DecodingError.malformedJSON
        default:
            throw DecodingError.malformedJSON
        }
    }

    /// Parse an object key and consume the following colon.
    ///
    /// This is likely the most-run function in the entire JSON decoder
    /// and therefore would likely benefit from ambitious optimization.
    /// Optimizing this is tricky because of the pushback case and
    /// because protobuf explicitly allows for keys to include escaped
    /// characters (e.g., {"name":1} can be written as {"n\u0061me":1}
    func nextKey() throws -> String {
        if let pushedBackToken = tokenPushback.popLast() {
            if case .string(let key) = pushedBackToken {
                try skipRequiredColon()
                return key
            } else {
                throw DecodingError.malformedJSON
            }
        } else {
            skipWhitespace()
            if index == scalars.endIndex {
                throw DecodingError.truncatedInput
            }
            tokenStart = index
            if scalars[index] != "\"" {
                throw DecodingError.malformedJSON
            }
            let s = try quotedString()
            skipWhitespace()
            if index == scalars.endIndex {
                throw DecodingError.truncatedInput
            }
            if scalars[index] != ":" {
                throw DecodingError.malformedJSON
            }
            index = scalars.index(after: index)
            return s
        }
    }

    func skipRequiredColon() throws {
        if tokenPushback.isEmpty {
            skipWhitespace()
            if let scalar = nextScalar(), scalar == ":" {
                skipScalars()
                return
            }
            throw DecodingError.malformedJSON
        } else if let pushedBackToken = tokenPushback.popLast(), pushedBackToken == .colon {
            return
        }
        throw DecodingError.malformedJSON
    }

    /// Skip the next token if it matches the expected token, else throw an error
    func skipRequired(token expected: JSONToken) throws {
        if let seen = try nextToken() {
            if seen != expected {
                throw DecodingError.malformedJSON
            }
        } else {
            throw DecodingError.truncatedInput
        }
    }

    /// If the next token is 'null', consume it and return true.
    /// Otherwise leave it alone and return false.
    func skipOptionalNull() throws -> Bool {
        if tokenPushback.isEmpty {
            skipWhitespace()
            if let scalar = nextScalar(), scalar == "n" {
                if matchesKeyword("ull") {
                    return true
                }
                throw DecodingError.malformedJSON
            } else {
                index = tokenStart
                return false
            }
        } else if let pushedBackToken = tokenPushback.last {
            if pushedBackToken == .null {
                _ = tokenPushback.popLast()
                return true
            }
        }
        return false
    }

    /// Skip the next token and return `true` if it matches, else leave it and return `false`
    func skipOptional(token expected: JSONToken) throws -> Bool {
        if let seen = try nextToken() {
            if seen != expected {
                pushback(token: seen)
                return false
            } else {
                return true
            }
        } else {
            return false
        }
    }

    /// Parse the initial "{" for an object type.
    /// If the immediately following token is "}",
    /// then consume it and return true.
    func isObjectEmpty() throws -> Bool {
        if tokenPushback.isEmpty {
            skipWhitespace()
            if index == scalars.endIndex {
                throw DecodingError.truncatedInput
            }
            if scalars[index] != "{" {
                throw DecodingError.malformedJSON
            }
            index = scalars.index(after: index)
            skipWhitespace()
            if index == scalars.endIndex {
                throw DecodingError.truncatedInput
            }
            if scalars[index] == "}" {
                index = scalars.index(after: index)
                return true
            }
            return false
        } else {
            try skipRequired(token: .beginObject)
            return try skipOptional(token: .endObject)
        }
    }

    /// Returns a `String` containing the text of the current token being scanned.
    private func currentTokenText(omittingLastScalar: Bool) -> String {
        let lastIndex = omittingLastScalar ? scalars.index(before: index) : index
        let text = String(scalars[tokenStart..<lastIndex])
        skipScalars()
        return text
    }

    /// Backs up the current index to the scalar just before it.
    private func backtrack() {
        if index != scalars.startIndex {
            index = scalars.index(before: index)
        }
    }

    /// Looksahead at the scalars following the current index to see if they
    /// match the provided keyword in `string`. If so, the index is advanced
    /// to the scalar just after the last one in `string` and the function
    /// returns `true`. Otherwise, the index is unchanged and this function
    /// returns `false`.
    private func matchesKeyword(_ string: String) -> Bool {
        let otherScalars = string.unicodeScalars
        let count = otherScalars.count
        if let possibleEnd = scalars.index(index,
                                           offsetBy: count,
                                           limitedBy: scalars.endIndex) {
            let slice = scalars[index..<possibleEnd]
            for (l, r) in zip(slice, otherScalars) {
                if l != r {
                    return false
                }
            }
            index = possibleEnd
            skipScalars()
            if index == scalars.endIndex {
                return true
            } else {
                switch scalars[index] {
                case "a"..."z": return false
                case "A"..."Z": return false
                case "0"..."9": return false
                default:
                    return true
                }
            }
        }
        return false
    }

    /// Scans a number and returns an appropriate token depending on the
    /// representation of that number (floating point, signed integer, or unsigned
    /// integer).
    private func numberToken(
        startingWith first: UnicodeScalar
        ) throws -> JSONToken {
        let isNegative = (first == "-")
        var isFloatingPoint = false

        loop: while let scalar = nextScalar() {
            switch scalar {
            case "0"..."9", "+", "-":
                continue
            case ".", "e", "E":
                isFloatingPoint = true
            default:
                backtrack()
                break loop
            }
        }

        let numberString = currentTokenText(omittingLastScalar: false)

        if isFloatingPoint {
            guard let parsedDouble = Double(numberString) else {
                throw DecodingError.malformedJSONNumber
            }
            return .number(.double(parsedDouble))
        }

        let scalars = numberString.unicodeScalars
        if isNegative {
            // Leading zeros (i.e., for octal or hexadecimal literals) are not allowed
            // for protobuf JSON.
            if scalars.count > 2 &&
                scalars[scalars.index(after: scalars.startIndex)] == "0" {
                throw DecodingError.malformedJSONNumber
            }
            guard let parsedInteger = IntMax(numberString) else {
                throw DecodingError.malformedJSONNumber
            }
            return .number(.int(parsedInteger))
        }

        // Likewise, forbid leading zeros for unsigned integers, but allow "0" if it
        // is alone. (See above.)
        if scalars.count > 1 && scalars.first == "0" {
            throw DecodingError.malformedJSONNumber
        }
        guard let parsedUnsignedInteger = UIntMax(numberString) else {
            throw DecodingError.malformedJSONNumber
        }
        return .number(.uint(parsedUnsignedInteger))
    }

    /// Scans a quoted string and returns its contents, unescaped and unquoted, as
    /// a string.
    /// Assumes index and tokenStart are currently pointing at the open quote.
    private func quotedString() throws -> String {
        var foundEndQuote = false
        var stringValue = ""

        // We want the token to start after the initial quote.
        index = scalars.index(after: index)
        tokenStart = index

        loop: while let scalar = nextScalar() {
            switch scalar {
            case "\"":
                foundEndQuote = true
                break loop
            case "\\":
                stringValue += currentTokenText(omittingLastScalar: true)
                stringValue += try String(unescapedSequence())
                skipScalars()
            default:
                continue
            }
        }

        // If the loop terminated without finding the end quote, it means we reached
        // the end of the input while still inside a string.
        if !foundEndQuote {
            throw DecodingError.malformedJSON
        }

        stringValue += currentTokenText(omittingLastScalar: true)
        return stringValue
    }

    /// Returns a `UnicodeScalar` corresponding to the next escape sequence
    /// scanned from the input.
    private func unescapedSequence() throws -> UnicodeScalar {
        guard let scalar = nextScalar() else {
            // Input terminated after the backslash but an escape sequence was
            // expected.
            throw DecodingError.malformedJSON
        }

        switch scalar {
        case "b":
            return "\u{0008}"
        case "t":
            return "\u{0009}"
        case "n":
            return "\u{000a}"
        case "f":
            return "\u{000c}"
        case "r":
            return "\u{000d}"
        case "\"", "\\", "/":
            return scalar
        case "u":
            return try unescapedUnicodeSequence()
        default:
            // Unrecognized escape sequence.
            throw DecodingError.malformedJSON
        }
    }

    /// Returns a `UnicodeScalar` corresponding to the next Unicode escape
    /// sequence scanned from the input.
    private func unescapedUnicodeSequence() throws -> UnicodeScalar {
        let codePoint = try nextHexadecimalCodePoint()
        if let scalar = UnicodeScalar(codePoint) {
            return scalar
        } else if codePoint < 0xD800 || codePoint >= 0xE000 {
            // Not a valid Unicode scalar.
            throw DecodingError.malformedJSON
        } else if codePoint >= 0xDC00 {
            // Low surrogate without a preceding high surrogate.
            throw DecodingError.malformedJSON
        } else {
            // We have a high surrogate (in the range 0xD800..<0xDC00), so verify that
            // it is followed by a low surrogate.
            guard nextScalar() == "\\", nextScalar() == "u" else {
                // High surrogate was not followed by a Unicode escape sequence.
                throw DecodingError.malformedJSON
            }

            let follower = try nextHexadecimalCodePoint()
            guard 0xDC00 <= follower && follower < 0xE000 else {
                // High surrogate was not followed by a low surrogate.
                throw DecodingError.malformedJSON
            }

            let high = codePoint - 0xD800
            let low = follower - 0xDC00
            let composed = 0x10000 | high << 10 | low
            guard let composedScalar = UnicodeScalar(composed) else {
                // Composed value is not a valid Unicode scalar.
                throw DecodingError.malformedJSON
            }
            return composedScalar
        }
    }

    /// Returns the unsigned 32-bit value represented by the next four scalars in
    /// the input when treated as hexadecimal digits. Throws an error if the next
    /// four scalars do not form a valid hexadecimal number.
    private func nextHexadecimalCodePoint() throws -> UInt32 {
        guard let end = scalars.index(index,
                                      offsetBy: 4,
                                      limitedBy: scalars.endIndex) else {
                                        // Input terminated before the expected number of scalars was found.
                                        throw DecodingError.malformedJSON
        }

        guard let value = UInt32(String(scalars[index..<end]), radix: 16) else {
            // Not a valid hexadecimal number.
            throw DecodingError.malformedJSON
        }

        index = end
        return value
    }

    /// Parses the next syntactically complete JSON value and returns
    /// an array containing the corresponding tokens.
    /// This is used to skip field bodies when the field name is not recognized.
    /// It is also used for deferred parsing of Any fields.
    func skip() throws -> [JSONToken] {
        var tokens = [JSONToken]()
        try skipValue(tokens: &tokens)
        return tokens
    }

    private func skipValue(tokens: inout [JSONToken]) throws {
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
    private func skipObject( tokens: inout [JSONToken]) throws {
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

    private func skipArray(tokens: inout [JSONToken]) throws {
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


/// FieldDecoder interface for JSONDecoder.
///
/// Note that the JSON decode flow just passes the decoder itself
/// as the field decoder for every field.  The general decoding flow
/// starts in the `setFromJSON()` method defined on `Message` in
/// `JSONTypeAdditions.swift`.  The logic runs as follows:
///
/// * Read field name via `getNextKey()`
/// * Look up field number on object
/// * Call `decodeField` on the object with the field number above (providing this decoder object as the field decoder)
/// * Object calls appropriate function below with schema details
/// * Function here parses value of field
///
/// Note that everything here is `public` since these methods
/// are called directly from the generated code (which is not part
/// of this library).
extension JSONDecoder: FieldDecoder {
    /// JSON decoder always rejects conflicting values for the same `oneof` group
    public var rejectConflictingOneof: Bool {return true}

    public func decodeSingularField<S: FieldType>(fieldType: S.Type, value: inout S.BaseType?) throws {
        if try skipOptionalNull() {
            value = nil
            return
        }
        try S.setFromJSON(decoder: self, value: &value)
    }

    public func decodeRepeatedField<S: FieldType>(fieldType: S.Type, value: inout [S.BaseType]) throws {
        if try skipOptionalNull() {
            return
        }
        try skipRequired(token: .beginArray)
        if try skipOptional(token: .endArray) {
            return
        }
        while true {
            try S.setFromJSON(decoder: self, value: &value)
            if let token = try nextToken() {
                switch token {
                case .endArray:
                    return
                case .comma:
                    break
                default:
                    throw DecodingError.malformedJSON
                }
            } else {
                throw DecodingError.truncatedInput
            }
        }
    }

    public func decodePackedField<S: FieldType>(fieldType: S.Type, value: inout [S.BaseType]) throws {
        try decodeRepeatedField(fieldType: fieldType, value: &value)
    }

    public func decodeSingularMessageField<M: Message>(fieldType: M.Type, value: inout M?) throws {
        try M.setFromJSON(decoder: self, value: &value)
    }

    public func decodeRepeatedMessageField<M: Message>(fieldType: M.Type, value: inout [M]) throws {
        if try skipOptionalNull() {
            return
        }
        try skipRequired(token: .beginArray)
        if try skipOptional(token: .endArray) {
            return
        }
        while true {
            // In repeated lists, 'null' is forbidden EXCEPT for
            // repeated Value objects:
            if try skipOptionalNull() {
                if M.self == Google_Protobuf_Value.self {
                    value.append(M())
                } else {
                    throw DecodingError.malformedJSON
                }
            } else {
                var m = M()
                try m.setFromJSON(decoder: self)
                value.append(m)
            }
            if let token = try nextToken() {
                switch token {
                case .endArray: return
                case .comma: break
                default:
                    throw DecodingError.malformedJSON
                }
            } else {
                throw DecodingError.truncatedInput
            }
        }
    }

    public func decodeSingularGroupField<G: Message>(fieldType: G.Type, value: inout G?) throws {
        /// Protobuf JSON explicitly rejects group fields
        throw DecodingError.schemaMismatch
    }

    public func decodeRepeatedGroupField<G: Message>(fieldType: G.Type, value: inout [G]) throws {
        /// Protobuf JSON explicitly rejects group fields
        throw DecodingError.schemaMismatch
    }

    public func decodeMapField<KeyType: MapKeyType, ValueType: MapValueType>(fieldType: ProtobufMap<KeyType, ValueType>.Type, value: inout ProtobufMap<KeyType, ValueType>.BaseType) throws where KeyType.BaseType: Hashable {
        if try skipOptionalNull() {
            return
        }
        if try isObjectEmpty() {
            return
        }
        while true {
            if let mapKeyToken = try nextToken(),
                case .string = mapKeyToken,
                let mapKey = try KeyType.decodeJSONMapKey(token: mapKeyToken) {
                try skipRequiredColon()
                var mapValue: ValueType.BaseType?
                try ValueType.setFromJSON(decoder: self, value: &mapValue)
                if mapValue == nil {
                    throw DecodingError.malformedJSON
                }
                value[mapKey] = mapValue
            } else {
                throw DecodingError.malformedJSON
            }
            if let token = try nextToken() {
                switch token {
                case .endObject:
                    return
                case .comma:
                    break
                default:
                    throw DecodingError.malformedJSON
                }
            } else {
                throw DecodingError.truncatedInput
            }
        }


    }

    public func decodeExtensionField(values: inout ExtensionFieldValueSet, messageType: Message.Type, protoFieldNumber: Int) throws {
        /// Protobuf JSON explicitly rejects extension fields
        throw DecodingError.schemaMismatch
    }
}

