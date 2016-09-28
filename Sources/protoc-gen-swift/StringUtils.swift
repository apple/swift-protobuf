// Sources/StringUtils.swift - String processing utilities
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

private func uppercaseFirst(_ s: String) -> String {
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

///
/// This attempts to implement Google's (undocumented) translation
/// algorithm for converting proto field names to JSON field names:
///
/// 1. Drop all underscores
/// 2. Character preceded by underscore is uppercased
/// 3. First character is lowercased (unless preceded by underscore)
///
/// The rules above were derived by inspecting Google's conformance
/// test suite as of July 2016.  The C++ unit tests actually
/// contradict this, and some later conformance test additions
/// also contradict this.  (See github.com/google/protobuf PR #1963)
///
func toJsonFieldName(_ s: String) -> String {
    var result = ""
    var capitalizeNext = false
    var lowercaseNext = true

    for c in s.characters {
        if c == "_" {
            capitalizeNext = true
        } else if capitalizeNext {
            result.append(String(c).uppercased())
            capitalizeNext = false
        } else if lowercaseNext {
            result.append(String(c).lowercased())
        } else {
            result.append(String(c))
        }
        lowercaseNext = false
    }
    return result;
}

private let whitespace: Set<Character> = [" ", "\t", "\n"]

func trimWhitespace(_ s: String) -> String {
     var out = ""
     var ws = ""
     var cs = s.characters.makeIterator()
     var pending = cs.next()

     while let c = pending, whitespace.contains(c) {
        pending = cs.next()
     }

     while let c = pending {
        if whitespace.contains(c) {
            ws.append(c)
        } else {
            out.append(ws)
            ws = ""
            out.append(c)
        }
        pending = cs.next()
     }
     return out
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
