// ProtobufRuntime/Sources/Protobuf/JSONScanner.swift - JSON tokenizer/scanner
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

public class JSONScanner {

  /// A stack of tokens that should be returned upon the next call to `next()`
  /// before the input string is scanned again.
  private var tokenPushback: [JSONToken]

  /// The scanner uses the UnicodeScalarView of the string, which is
  /// significantly faster than operating on Characters.
  private let scalars: String.UnicodeScalarView

  /// The index where the current token being scanned begins.
  private var tokenStart: String.UnicodeScalarView.Index

  /// The index of the next scalar to be scanned.
  private var index: String.UnicodeScalarView.Index

  /// Returns true if a complete and well-formed JSON string was fully scanned
  /// (that is, the only scalars remaining after the current index are
  /// whitespace).
  public var complete: Bool {
    while let scalar = nextScalar() {
      switch scalar {
      case " ", "\t", "\r", "\n":
        continue
      default:
        return false
      }
    }
    return true
  }

  /// Creates a new JSON scanner for the given string.
  public init(json: String, tokens: [JSONToken]) {
    self.scalars = json.unicodeScalars
    self.tokenStart = self.scalars.startIndex
    self.index = self.tokenStart
    tokenPushback = tokens.reversed()
  }

  /// Pushes a token back onto the scanner. Pushed-back tokens are read in the
  /// reverse order that they were pushed until the stack is exhausted, at which
  /// point tokens will again be read from the input string.
  public func pushback(token: JSONToken) {
    tokenPushback.append(token)
  }

  /// Returns the next token in the JSON string, or nil if the end of the string
  /// has been reached.
  public func next() throws -> JSONToken? {
    if let pushedBackToken = tokenPushback.popLast() {
      return pushedBackToken
    }

    while let scalar = nextScalar() {
      switch scalar {
      case " ", "\t", "\r", "\n":
        skip()
      case ":":
        skip()
        return .colon
      case ",":
        skip()
        return .comma
      case "{":
        skip()
        return .beginObject
      case "}":
        skip()
        return .endObject
      case "[":
        skip()
        return .beginArray
      case "]":
        skip()
        return .endArray
      case "n":
        if couldSkip("ull") {
          return .null
        }
        throw DecodingError.malformedJSON
      case "f":
        if couldSkip("alse") {
          return .boolean(false)
        }
        throw DecodingError.malformedJSON
      case "t":
        if couldSkip("rue") {
          return .boolean(true)
        }
        throw DecodingError.malformedJSON
      case "-", "0"..."9":
        return try numberToken(startingWith: scalar)
      case "\"":
        return try quotedStringToken()
      default:
        throw DecodingError.malformedJSON
      }
    }

    return nil
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

  /// Returns a `String` containing the text of the current token being scanned.
  private func currentTokenText(omittingLastScalar: Bool) -> String {
    let lastIndex = omittingLastScalar ? scalars.index(before: index) : index
    let text = String(scalars[tokenStart..<lastIndex])
    skip()
    return text
  }

  /// Backs up the current index to the scalar just before it.
  private func backtrack() {
    if index != scalars.startIndex {
      index = scalars.index(before: index)
    }
  }

  /// Updates the token-start index to indicate that the next token should begin
  /// at the scanner's current index.
  private func skip() {
    tokenStart = index
  }

  /// Looksahead at the scalars following the current index to see if they
  /// match those in `string`. If so, the index is advanced to the scalar just
  /// after the last one in `string` and the function returns `true`. Otherwise,
  /// the index is unchanged and this function returns `false`.
  private func couldSkip(_ string: String) -> Bool {
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
      skip()
      return true
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
  /// a token.
  private func quotedStringToken() throws -> JSONToken {
    var foundEndQuote = false
    var stringValue = ""

    // We want the token to start after the initial quote.
    skip()

    loop: while let scalar = nextScalar() {
      switch scalar {
      case "\"":
        foundEndQuote = true
        break loop
      case "\\":
        stringValue += currentTokenText(omittingLastScalar: true)
        stringValue += try String(unescapedSequence())
        skip()
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
    return .string(stringValue)
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
}
