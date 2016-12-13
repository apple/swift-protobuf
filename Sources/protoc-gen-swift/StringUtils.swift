// Sources/protoc-gen-swift/StringUtils.swift - String processing utilities
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
/// Swift and proto conventions differ, so we need some basic tools to
/// translate identifiers between UPPER_SNAKE_CASE, lowerCamelCase, etc.
/// This also provides handling for generating Swift source code representations
/// of strings and byte arrays.
///
// -----------------------------------------------------------------------------
import Foundation

func splitPath(pathname: String) -> (dir:String, base:String, suffix:String) {
  var dir = ""
  var base = ""
  var suffix = ""

  for c in pathname.characters {
    if c == "/" {
      dir += base + suffix + String(c)
      base = ""
      suffix = ""
    } else if c == "." {
      base += suffix
      suffix = String(c)
    } else {
      suffix += String(c)
    }
  }
  if suffix.characters.first != "." {
    base += suffix
    suffix = ""
  }
  return (dir: dir, base: base, suffix: suffix)
}

func partition(string: String, atFirstOccurrenceOf substring: String) -> (String, String) {
  guard let index = string.range(of: substring)?.lowerBound else {
    return (string, "")
  }
  return (string.substring(to: index), string.substring(from: string.index(after: index)))
}

func parseParameter(string: String?) -> [(key:String, value:String)] {
  guard let string = string, string.characters.count > 0 else {
    return []
  }
  let parts = string.components(separatedBy: ",")
  let asPairs = parts.map { partition(string: $0, atFirstOccurrenceOf: "=") }
  let result = asPairs.map { (key:trimWhitespace($0), value:trimWhitespace($1)) }
  return result
}

private let digits: Set<String> = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]

private func splitIdentifier(_ s: String) -> [String] {
  var out = [String]()
  var current = ""
  var last = ""
  var lastIsUpper = false
  var lastIsLower = false

  for _c in s.characters {
    let c = String(_c)
    let cIsUpper = (c != c.lowercased())
    let cIsLower = (c != c.uppercased())
    if digits.contains(c) {
      if digits.contains(last) {
        current += c
      } else {
        out.append(current)
        current = c
      }
    } else if cIsUpper {
      if lastIsUpper {
        current += c.lowercased()
      } else {
        out.append(current)
        current = c.lowercased()
      }
    } else if cIsLower {
      if lastIsLower || lastIsUpper {
        current += c
      } else {
        out.append(current)
        current = c
      }
    } else {
      if last == "_" {
        out.append(current)
        current = last
      }
      if c != "_" {
        out.append(current)
        current = c
      }
    }
    last = c
    lastIsUpper = cIsUpper
    lastIsLower = cIsLower
  }
  out.append(current)
  if last == "_" {
    out.append(last)
  }
  return [String](out.dropFirst(1))
}

func uppercaseFirst(_ s: String) -> String {
  var out = s.characters
  if let first = out.popFirst() {
    return String(first).uppercased() + String(out)
  } else {
    return s
  }
}

/// Only allow ASCII alphanumerics and underscore.
private func basicSanitize(_ s: String) -> String {
  var out = ""
  for c in s.characters {
    switch c {
    case "A"..."Z": // A-Z
      out.append(c)
    case "a"..."z": // a-z
      out.append(c)
    case "0"..."9": // 0-9
      out.append(c)
    case "_":
      out.append(c)
    default:
      break
    }
  }
  return out
}

func periodsToUnderscores(_ s: String) -> String {
  var out = ""
  for c in s.characters {
    if c == "." {
      out += "_"
    } else {
      out += String(c)
    }
  }
  return out
}

private let upperInitials: Set<String> = ["url", "http", "https"]

func toUpperCamelCase(_ s: String) -> String {
  var out = ""
  let t = splitIdentifier(s)
  for word in t {
    if upperInitials.contains(word) {
      out.append(word.uppercased())
    } else {
      out.append(uppercaseFirst(basicSanitize(word)))
    }
  }
  return out
}

func toLowerCamelCase(_ s: String) -> String {
  var out = ""
  let t = splitIdentifier(s)
  // Lowercase the first letter/word
  var forceLower = true
  for word in t {
    if forceLower {
      out.append(basicSanitize(word).lowercased())
    } else if upperInitials.contains(word) {
      out.append(word.uppercased())
    } else {
      out.append(uppercaseFirst(basicSanitize(word)))
    }
    forceLower = false
  }
  return out
}

private let whitespace: Set<Character> = [" ", "\t", "\n"]

func trimWhitespace(_ s: String) -> String {
  return s.trimmingCharacters(in: .whitespacesAndNewlines)
}

/// The protoc parser emits byte literals using an escaped C convention.
/// Fortunately, it uses only a limited subset of the C escapse:
///  \n\r\t\\\'\" and three-digit octal escapes but nothing else.
func escapedToDataLiteral(_ s: String) -> String {
  var out = "Data(bytes: ["
  var separator = ""
  var escape = false
  var octal = 0
  var octalAccumulator = 0
  for c in s.utf8 {
    if octal > 0 {
      precondition(c >= 48 && c < 56)
      octalAccumulator <<= 3
      octalAccumulator |= (Int(c) - 48)
      octal -= 1
      if octal == 0 {
        out += separator
        out += "\(octalAccumulator)"
        separator = ", "
      }
    } else if escape {
      switch c {
      case 110:
        out += separator
        out += "10"
        separator = ", "
      case 114:
        out += separator
        out += "13"
        separator = ", "
      case 116:
        out += separator
        out += "9"
        separator = ", "
      case 48..<56:
        octal = 2 // 2 more digits
        octalAccumulator = Int(c) - 48
      default:
        out += separator
        out += "\(c)"
        separator = ", "
      }
      escape = false
    } else if c == 92 { // backslash
      escape = true
    } else {
      out += separator
      out += "\(c)"
      separator = ", "
    }
  }
  out += "])"
  return out
}

/// Generate a Swift string literal suitable for including in
/// source code
private let hexdigits = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e", "f"]

func stringToEscapedStringLiteral(_ s: String) -> String {
  var out = "\""
  for c in s.unicodeScalars {
    switch c.value {
    case 0:
      out += "\\0"
    case 1..<32:
      let n = Int(c.value)
      let hex1 = hexdigits[(n >> 4) & 15]
      let hex2 = hexdigits[n & 15]
      out += "\\u{" + hex1 + hex2 + "}"
    case 34:
      out += "\\\""
    case 92:
      out += "\\\\"
    default:
      out.append(String(c))
    }
  }
  return out + "\""
}


/*
 GRAMMAR OF AN IDENTIFIER

 identifier → identifier-head­identifier-characters­opt­
 identifier → `­identifier-head­identifier-characters­opt­`­
 identifier → implicit-parameter-name­
 identifier-list → identifier­  identifier­,­identifier-list­
 */
fileprivate let identifierHeadRanges: [String] = [
    //identifier-head → Upper- or lowercase letter A through Z
    "a-zA-Z",
    // identifier-head → _
    "_",
    // identifier-head → U+00A8, U+00AA, U+00AD, U+00AF, U+00B2–U+00B5, or U+00B7–U+00BA
    "\\u000a8\\u00aa\\u00ad\\u00af\\u00b2-\\u00b5\\u00b7-\\u00ba",
    // identifier-head → U+00BC–U+00BE, U+00C0–U+00D6, U+00D8–U+00F6, or U+00F8–U+00FF
    "\\u00bc–\\u00be\\u00c0–\\u00d6\\u00d8–\\u00f6\\u00f8–\\u00ff",
    // identifier-head → U+0100–U+02FF, U+0370–U+167F, U+1681–U+180D, or U+180F–U+1DBF
    "\\u0100–\\u02ff\\u0370–\\u167f\\u1681–\\u180d\\u180f–\\u1dbf",
    // identifier-head → U+1E00–U+1FFF
    "\\u1e00-\\u1fff",
    // identifier-head → U+200B–U+200D, U+202A–U+202E, U+203F–U+2040, U+2054, or U+2060–U+206F
    "\\u200b–\\u200d\\u202a–\\u202e\\u203F–\\u2040\\u2054\\u2060–\\u206f",
    // identifier-head → U+2070–U+20CF, U+2100–U+218F, U+2460–U+24FF, or U+2776–U+2793
    "\\u2070-\\u20cf\\u2100-\\u218f\\u2460-\\u24ff\\u2776-\\u2793",
    // identifier-head → U+2C00–U+2DFF or U+2E80–U+2FFF
    "\\u2c00–\\u2dff\\u2e80–\\u2fff",
    // identifier-head → U+3004–U+3007, U+3021–U+302F, U+3031–U+303F, or U+3040–U+D7FF
    "\\u3004–\\u3007\\u3021–\\u302f\\u3031–\\u303f\\u3040–\\ud7ff",
    // identifier-head → U+F900–U+FD3D, U+FD40–U+FDCF, U+FDF0–U+FE1F, or U+FE30–U+FE44
    "\\uf900–\\ufd3d\\ufd40–\\ufdcf\\ufdf0–\\ufe1f\\ufe30–\\ufe44",
    // identifier-head → U+FE47–U+FFFD
    "\\ufe47-\\ufffd",
    // identifier-head → U+10000–U+1FFFD, U+20000–U+2FFFD, U+30000–U+3FFFD, or U+40000–U+4FFFD,
    "\\U00010000-\\U0001fffd\\U00020000-\\U0002fffd\\U00030000-\\U0003fffd\\U00040000-\\U0004fffd",
    // identifier-head → U+50000–U+5FFFD, U+60000–U+6FFFD, U+70000–U+7FFFD, or U+80000–U+8FFFD
    "\\U00050000-\\U0005fffd\\U00060000-\\U0006fffd\\U00070000-\\U0007fffd\\U00080000-\\U0008fffd",
    // identifier-head → U+90000–U+9FFFD, U+A0000–U+AFFFD, U+B0000–U+BFFFD, or U+C0000–U+CFFFD
    "\\U00090000-\\U0009fffd\\U000a0000-\\U000afffd\\U000b0000-\\U000bfffd\\U000c0000-\\U000cfffd",
    // identifier-head → U+D0000–U+DFFFD or U+E0000–U+EFFFD
    "\\U000d0000-\\U000dfffd\\U000e0000-\\U000efffd"
]

fileprivate let identifierHeadRegex = identifierHeadRanges.joined()

fileprivate let identifierCharacterRanges: [String] = [
    // identifier-character → Digit 0 through 9
    "0-9",
    // identifier-character → U+0300–U+036F, U+1DC0–U+1DFF, U+20D0–U+20FF, or U+FE20–U+FE2F
    "\\u0300–\\u036F\\u1dc0–\\u1dff\\u20d0–\\u20ff\\ufe20–\\ufe2f",
    // identifier-character → identifier-head­
    identifierHeadRegex
]

fileprivate let identifierCharactersRegex = identifierCharacterRanges.joined()
fileprivate let identifier = "[\(identifierHeadRegex)][\(identifierCharactersRegex)]*"

fileprivate let loneIdentifer = "\\A\(identifier)\\z"
fileprivate let quotedIdentifier = "\\A`\(identifier)`\\z"

fileprivate let implicitParameter = "\\A\\$[0-9]\\z"

fileprivate let allOptions = [loneIdentifer, quotedIdentifier, implicitParameter].joined(separator: "|")

#if os(OSX)
fileprivate let swiftIdentifierRegex = try! NSRegularExpression(pattern: allOptions, options: [])
#else
fileprivate let swiftIdentifierRegex = try! RegularExpression(pattern: allOptions, options: [])
#endif

#if os(OSX)
fileprivate func string(_ s: String, matches regex: NSRegularExpression) -> Bool {
    let nsLength = (s as NSString).length
    let range = NSRange(location: 0, length: nsLength)
    return regex.numberOfMatches(in: s, options: [], range: range) == 1
}
#else
fileprivate func string(_ s: String, matches regex: RegularExpression) -> Bool {
    let nsLength = s.utf16.count
    let range = NSRange(location: 0, length: nsLength)
    return regex.numberOfMatches(in: s, options: [], range: range) == 1
}
#endif

func isValidSwiftIdentifier(_ s: String) -> Bool {
    return string(s, matches: swiftIdentifierRegex)
}

fileprivate let usableOptions = [loneIdentifer, quotedIdentifier].joined(separator: "|")

#if os(OSX)
fileprivate let usableSwiftIdentifierRegex = try! NSRegularExpression(pattern: usableOptions)
#else
fileprivate let usableSwiftIdentifierRegex = try! RegularExpression(pattern: usableOptions, options: [])
#endif

func isUsableSwiftIdentifier(_ s: String) -> Bool {
    guard s != "_" else { return false }
    return string(s, matches: usableSwiftIdentifierRegex)
}

fileprivate let protobufIdentifierString = "\\A[a-zA-Z_][0-9a-zA-Z_]*\\z"

#if os(OSX)
fileprivate let protobufIdentifierRegex = try! NSRegularExpression(pattern: protobufIdentifierString, options: [])
#else
fileprivate let protobufIdentifierRegex = try! RegularExpression(pattern: protobufIdentifierString, options: [])
#endif

func isValidProtobufIdentifier(_ s: String) -> Bool {
    return string(s, matches: protobufIdentifierRegex)
}
