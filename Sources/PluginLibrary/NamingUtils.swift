// Sources/PluginLibrary/NamingUtils.swift - Utilities for generating names
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// This provides some utilities for generating names.
///
/// NOTE: Only a very small subset of this is public. The intent is for this to
/// expose a defined api within the PluginLib, but the the SwiftProtobufNamer
/// to be what exposes the reusable parts at a much higher level. This reduces
/// the changes of something being reimplemented but with minor differences.
///
// -----------------------------------------------------------------------------

import Foundation

///
/// We won't generate types (structs, enums) with these names:
///
fileprivate let reservedTypeNames: Set<String> = {
  () -> Set<String> in
  var names: Set<String> = []

  // Main SwiftProtobuf namespace
  // Shadowing this leads to Bad Things.
  names.insert(SwiftProtobufInfo.name)

  // Subtype of many messages, used to scope nested extensions
  names.insert("Extensions")

  // Subtypes are static references, so can conflict with static
  // class properties:
  names.insert("protoMessageName")

  // Methods on Message that we need to avoid shadowing.  Testing
  // shows we do not need to avoid `serializedData` or `isEqualTo`,
  // but it's not obvious to me what's different about them.  Maybe
  // because these two are generic?  Because they throw?
  names.insert("decodeMessage")
  names.insert("traverse")

  // Basic Message properties we don't want to shadow:
  names.insert("isInitialized")
  names.insert("unknownFields")

  // Standard Swift property names we don't want
  // to conflict with:
  names.insert("debugDescription")
  names.insert("description")
  names.insert("dynamicType")
  names.insert("hashValue")

  // We don't need to protect all of these keywords, just the ones
  // that interfere with type expressions:
  // names = names.union(swiftKeywordsReservedInParticularContexts)
  names.insert("Type")
  names.insert("Protocol")

  names = names.union(swiftKeywordsUsedInDeclarations)
  names = names.union(swiftKeywordsUsedInStatements)
  names = names.union(swiftKeywordsUsedInExpressionsAndTypes)
  names = names.union(swiftCommonTypes)
  names = names.union(swiftSpecialVariables)
  return names
}()

/*
 * Many Swift reserved words can be used as fields names if we put
 * backticks around them:
 */
fileprivate let quotableFieldNames: Set<String> = {
  () -> Set<String> in
  var names: Set<String> = []

  names = names.union(swiftKeywordsUsedInDeclarations)
  names = names.union(swiftKeywordsUsedInStatements)
  names = names.union(swiftKeywordsUsedInExpressionsAndTypes)
  return names
}()

fileprivate let reservedFieldNames: Set<String> = {
  () -> Set<String> in
  var names: Set<String> = []

  // Properties are instance names, so can't shadow static class
  // properties such as `protoMessageName`.

  // Properties can't shadow methods.  For example, we don't need to
  // avoid `isEqualTo` as a field name.

  // Basic Message properties that we don't want to shadow
  names.insert("isInitialized")
  names.insert("unknownFields")

  // Standard Swift property names we don't want
  // to conflict with:
  names.insert("debugDescription")
  names.insert("description")
  names.insert("dynamicType")
  names.insert("hashValue")
  names.insert("init")
  names.insert("self")

  // We don't need to protect all of these keywords, just the ones
  // that interfere with type expressions:
  // names = names.union(swiftKeywordsReservedInParticularContexts)
  names.insert("Type")
  names.insert("Protocol")

  names = names.union(swiftCommonTypes)
  names = names.union(swiftSpecialVariables)
  return names
}()

/*
 * Many Swift reserved words can be used as enum cases if we put
 * backticks around them:
 */
fileprivate let quotableEnumCases: Set<String> = {
  () -> Set<String> in
  var names: Set<String> = []

  // We don't need to protect all of these keywords, just the ones
  // that interfere with enum cases:
  // names = names.union(swiftKeywordsReservedInParticularContexts)
  names.insert("associativity")
  names.insert("dynamicType")
  names.insert("optional")
  names.insert("required")

  names = names.union(swiftKeywordsUsedInDeclarations)
  names = names.union(swiftKeywordsUsedInStatements)
  names = names.union(swiftKeywordsUsedInExpressionsAndTypes)
  // Common type and variable names don't cause problems as enum
  // cases, because enum case names only appear in special contexts:
  // names = names.union(swiftCommonTypes)
  // names = names.union(swiftSpecialVariables)
  return names
}()

/*
 * Some words cannot be used for enum cases, even if they
 * are quoted with backticks:
 */
fileprivate let reservedEnumCases: Set<String> = [
  // Don't conflict with standard Swift property names:
  "debugDescription",
  "description",
  "dynamicType",
  "hashValue",
  "init",
  "rawValue",
  "self",
]

/*
 * Message scoped extensions are scoped within the Message struct with
 * `enum Extensions { ... }`, so we resuse the same sets for backticks
 * and reserved words.
 */
fileprivate let quotableMessageScopedExtensionNames: Set<String> = quotableEnumCases
fileprivate let reservedMessageScopedExtensionNames: Set<String> = reservedEnumCases


fileprivate func isAllUnderscore(_ s: String) -> Bool {
  if s.isEmpty {
    return false
  }
  for c in s.characters {
    if c != "_" {return false}
  }
  return true
}

fileprivate func sanitizeTypeName(_ s: String, disambiguator: String) -> String {
  if reservedTypeNames.contains(s) {
    return s + disambiguator
  } else if isAllUnderscore(s) {
    return s + disambiguator
  } else if s.hasSuffix(disambiguator) {
    // If `foo` and `fooMessage` both exist, and `foo` gets
    // expanded to `fooMessage`, then we also should expand
    // `fooMessage` to `fooMessageMessage` to avoid creating a new
    // conflict.  This can be resolved recursively by stripping
    // the disambiguator, sanitizing the root, then re-adding the
    // disambiguator:
    let e = s.index(s.endIndex, offsetBy: -disambiguator.characters.count)
    let truncated = s.substring(to: e)
    return sanitizeTypeName(truncated, disambiguator: disambiguator) + disambiguator
  } else {
    return s
  }
}

fileprivate func isCharacterUppercase(_ s: String, index: Int) -> Bool {
  let start = s.index(s.startIndex, offsetBy: index)
  if start == s.endIndex {
    // it ended, so just say the next character wasn't uppercase.
    return false
  }
  let end = s.index(after: start)
  let sub = s[start..<end]
  return sub != sub.lowercased()
}

fileprivate let digits: Set<String> = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]

fileprivate func splitIdentifier(_ s: String) -> [String] {
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
  // An empty string will always get inserted first, so drop it.
  return [String](out.dropFirst(1))
}

/// Only allow ASCII alphanumerics and underscore.
fileprivate func basicSanitize(_ s: String) -> String {
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

fileprivate let upperInitials: Set<String> = ["url", "http", "https", "id"]

fileprivate let backtickCharacterSet = CharacterSet(charactersIn: "`")

// Scope for the utilies to they are less likely to conflict when imported into
// generators.
public enum NamingUtils {

  // Returns the type prefix to use for a given
  static func typePrefix(protoPackage: String, fileOptions: Google_Protobuf_FileOptions) -> String {
    // Explicit option (including blank), wins.
    if fileOptions.hasSwiftPrefix {
      return fileOptions.swiftPrefix
    }

    if protoPackage.isEmpty {
      return String()
    }

    // Transforms:
    //  "package.name" -> "Package_Name"
    //  "package_name" -> "PackageName"
    //  "pacakge.some_name" -> "Package_SomeName"
    var makeUpper = true
    var prefix = ""
    for c in protoPackage.characters {
      if c == "_" {
        makeUpper = true
      } else if c == "." {
        makeUpper = true
        prefix += "_"
      } else if makeUpper {
        prefix += String(c).uppercased()
        makeUpper = false
      } else {
        prefix += String(c)
      }
    }
    // End in an underscore to split off anything that gets added to it.
    return prefix + "_"
  }

  /// Remove the proto prefix from the given string.  A proto prefix means
  /// underscores and letter case are ignored.
  ///
  /// - Precodition: The two strings must only be 7bit ascii.
  ///
  /// - Returns: nil if nothing can be stripped, otherwise returns the stripping
  ///            string.
  static func strip(protoPrefix prefix: String, from: String) -> String? {
    let prefixChars = prefix.lowercased().unicodeScalars
    precondition(prefixChars.count == prefix.lengthOfBytes(using: .ascii))
    var prefixIndex = prefixChars.startIndex
    let prefixEnd = prefixChars.endIndex

    let fromChars = from.lowercased().unicodeScalars
    precondition(fromChars.count == from.lengthOfBytes(using: .ascii))
    var fromIndex = fromChars.startIndex
    let fromEnd = fromChars.endIndex

    while (prefixIndex != prefixEnd) {
      if (fromIndex == fromEnd) {
        // Reached the end of the string while still having prefix to go
        // nothing to strip.
        return nil
      }

      if prefixChars[prefixIndex] == "_" {
        prefixIndex = prefixChars.index(after: prefixIndex)
        continue
      }

      if fromChars[fromIndex] == "_" {
        fromIndex = fromChars.index(after: fromIndex)
        continue
      }

      if prefixChars[prefixIndex] != fromChars[fromIndex] {
        // They differed before the end of the prefix, can't drop.
        return nil
      }

      prefixIndex = prefixChars.index(after: prefixIndex)
      fromIndex = fromChars.index(after: fromIndex)
    }

    // Remove any more underscores.
    while fromIndex != fromEnd && fromChars[fromIndex] == "_" {
      fromIndex = fromChars.index(after: fromIndex)
    }

    if fromIndex == fromEnd {
      // They matched, can't strip.
      return nil
    }

    let count = fromChars.distance(from: fromChars.startIndex, to: fromIndex)
    let idx = from.index(from.startIndex, offsetBy: count)
    return from[idx..<from.endIndex]
  }

  static func sanitize(messageName s: String) -> String {
    return sanitizeTypeName(s, disambiguator: "Message")
  }

  static func sanitize(enumName s: String) -> String {
    return sanitizeTypeName(s, disambiguator: "Enum")
  }

  static func sanitize(oneofName s: String) -> String {
    return sanitizeTypeName(s, disambiguator: "Oneof")
  }

  static func sanitize(fieldName s: String, basedOn: String) -> String {
    if basedOn.hasPrefix("clear") && isCharacterUppercase(basedOn, index: 5) {
      return s + "_p"
    } else if basedOn.hasPrefix("has") && isCharacterUppercase(basedOn, index: 3) {
      return s + "_p"
    } else if reservedFieldNames.contains(basedOn) {
      return s + "_p"
    } else if basedOn == s && quotableFieldNames.contains(basedOn) {
      // backticks are only used on the base names, if we're sanitizing based on something else
      // this is skipped (the "hasFoo" doesn't get backticks just because the "foo" does).
      return "`\(s)`"
    } else if isAllUnderscore(basedOn) {
      return s + "__"
    } else {
      return s
    }
  }

  static func sanitize(fieldName s: String) -> String {
    return sanitize(fieldName: s, basedOn: s)
  }

  static func sanitize(enumCaseName s: String) -> String {
    if reservedEnumCases.contains(s) {
      return "\(s)_"
    } else if quotableEnumCases.contains(s) {
      return "`\(s)`"
    } else if isAllUnderscore(s) {
      return s + "__"
    } else {
      return s
    }
  }

  static func sanitize(messageScopedExtensionName s: String) -> String {
    if reservedMessageScopedExtensionNames.contains(s) {
      return "\(s)_"
    } else if quotableMessageScopedExtensionNames.contains(s) {
      return "`\(s)`"
    } else if isAllUnderscore(s) {
      return s + "__"
    } else {
      return s
    }
  }

  /// Use toUpperCamelCase() to get leading "HTTP", "URL", etc. correct.
  static func uppercaseFirstCharacter(_ s: String) -> String {
    var out = s.characters
    if let first = out.popFirst() {
      return String(first).uppercased() + String(out)
    } else {
      return s
    }
  }

  public static func toUpperCamelCase(_ s: String) -> String {
    var out = ""
    let t = splitIdentifier(s)
    for word in t {
      if upperInitials.contains(word) {
        out.append(word.uppercased())
      } else {
        out.append(uppercaseFirstCharacter(basicSanitize(word)))
      }
    }
    return out
  }

  public static func toLowerCamelCase(_ s: String) -> String {
    var out = ""
    let t = splitIdentifier(s)
    // Lowercase the first letter/word.
    var forceLower = true
    for word in t {
      if forceLower {
        out.append(basicSanitize(word).lowercased())
      } else if upperInitials.contains(word) {
        out.append(word.uppercased())
      } else {
        out.append(uppercaseFirstCharacter(basicSanitize(word)))
      }
      forceLower = false
    }
    return out
  }

  static func trimBackticks(_ s: String) -> String {
    return s.trimmingCharacters(in: backtickCharacterSet)
  }

  static func periodsToUnderscores(_ s: String) -> String {
    return s.replacingOccurrences(of: ".", with: "_")
  }

}
