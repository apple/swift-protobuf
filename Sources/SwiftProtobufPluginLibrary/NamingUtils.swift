// Sources/SwiftProtobufPluginLibrary/NamingUtils.swift - Utilities for generating names
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
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
import SwiftProtobuf

///
/// We won't generate types (structs, enums) with these names:
///
fileprivate let reservedTypeNames: Set<String> = {
  () -> Set<String> in
  var names: Set<String> = []

  // Main SwiftProtobuf namespace
  // Shadowing this leads to Bad Things.
  names.insert("SwiftProtobuf")

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

  // Getting something called "Swift" would be bad as it blocks access
  // to built in things.
  names.insert("Swift")

  // And getting things on some of the common protocols could create
  // some odd confusion.
  names.insert("Equatable")
  names.insert("Hashable")
  names.insert("Sendable")

  names = names.union(swiftKeywordsUsedInDeclarations)
  names = names.union(swiftKeywordsUsedInStatements)
  names = names.union(swiftKeywordsUsedInExpressionsAndTypes)
  names = names.union(swiftCommonTypes)
  names = names.union(swiftSpecialVariables)
  return names
}()

///
/// Many Swift reserved words can be used as fields names if we put backticks
/// around them:
///
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

///
/// Many Swift reserved words can be used as enum cases if we put quotes
/// around them:
///
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

///
/// Some words cannot be used for enum cases, even if they are quoted with
/// backticks:
///
fileprivate let reservedEnumCases: Set<String> = [
  // Don't conflict with standard Swift property names:
  "allCases",
  "debugDescription",
  "description",
  "dynamicType",
  "hashValue",
  "init",
  "rawValue",
  "self",
]

///
/// Message scoped extensions are scoped within the Message struct with `enum
/// Extensions { ... }`, so we resuse the same sets for backticks and reserved
/// words.
///
fileprivate let quotableMessageScopedExtensionNames: Set<String> = quotableEnumCases
fileprivate let reservedMessageScopedExtensionNames: Set<String> = reservedEnumCases


fileprivate func isAllUnderscore(_ s: String) -> Bool {
  if s.isEmpty {
    return false
  }
  for c in s.unicodeScalars {
    if c != "_" {return false}
  }
  return true
}

fileprivate func sanitizeTypeName(_ s: String, disambiguator: String, forbiddenTypeNames: Set<String>) -> String {
  // NOTE: This code relies on the protoc validation of _identifier_ is defined
  // (in Tokenizer::Next() as `[a-zA-Z_][a-zA-Z0-9_]*`, so this does not need
  // any complex validation or handing of characters outside those ranges. Since
  // those rules prevent a leading digit; nothing needs to be done, and any
  // explicitly use Message or Enum name will be valid. The one exception is
  // this code is also used for determining the OneOf enums, but that code is
  // responsible for dealing with the issues in the transforms it makes.
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
    let e = s.index(s.endIndex, offsetBy: -disambiguator.count)
    let truncated = String(s[..<e])
    return sanitizeTypeName(truncated, disambiguator: disambiguator, forbiddenTypeNames: forbiddenTypeNames) + disambiguator
  } else if forbiddenTypeNames.contains(s) {
    // NOTE: It is important that this case runs after the hasSuffix case.
    // This set of forbidden type names is not fixed, and may contain something
    // like "FooMessage". If it does, and if s is "FooMessage with a
    // disambiguator of "Message", then we want to sanitize on the basis of
    // the suffix rather simply appending the disambiguator.
    // We use this for module imports that are configurable (like SwiftProtobuf
    // renaming).
    return s + disambiguator
  } else {
    return s
  }
}

fileprivate func isCharacterUppercase(_ s: String, index: Int) -> Bool {
  let scalars = s.unicodeScalars
  let start = scalars.index(scalars.startIndex, offsetBy: index)
  if start == scalars.endIndex {
    // it ended, so just say the next character wasn't uppercase.
    return false
  }
  return scalars[start].isASCUppercase
}

fileprivate func makeUnicodeScalarView(
  from unicodeScalar: UnicodeScalar
) -> String.UnicodeScalarView {
  var view = String.UnicodeScalarView()
  view.append(unicodeScalar)
  return view
}

fileprivate enum CamelCaser {
  // Abbreviation that should be all uppercase when camelcasing. Used in
  // camelCased(:initialUpperCase:).
  static let appreviations: Set<String> = ["url", "http", "https", "id"]

  // The diffent "classes" a character can belong in for segmenting.
  enum CharClass {
    case digit
    case lower
    case upper
    case underscore
    case other

    init(_ from: UnicodeScalar) {
      switch from {
      case "0"..."9":
        self = .digit
      case "a"..."z":
        self = .lower
      case "A"..."Z":
        self = .upper
      case "_":
        self = .underscore
      default:
        self = .other
      }
    }
  }

  /// Transforms the input into a camelcase name that is a valid Swift
  /// identifier. The input is assumed to be a protocol buffer identifier (or
  /// something like that), meaning that it is a "snake_case_name" and the
  /// underscores and be used to split into segements and then capitalize as
  /// needed. The splits happen based on underscores and/or changes in case
  /// and/or use of digits. If underscores are repeated, then the "extras"
  /// (past the first) are carried over into the output.
  ///
  /// NOTE: protoc validation of an _identifier_ is defined (in Tokenizer::Next()
  /// as `[a-zA-Z_][a-zA-Z0-9_]*`, Since leading underscores are removed, it does
  /// have to handle if things would have started with a digit. If that happens,
  /// then an underscore is added before it (which matches what the proto file
  /// would have had to have a valid identifier also).
  static func transform(_ s: String, initialUpperCase: Bool) -> String {
    var result = String()
    var current = String.UnicodeScalarView()  // Collects in lowercase.
    var lastClass = CharClass("\0")

    func addCurrent() {
      guard !current.isEmpty else {
        return
      }
      var currentAsString = String(current)
      if result.isEmpty && !initialUpperCase {
        // Nothing, want it to stay lowercase.
      } else if appreviations.contains(currentAsString) {
        currentAsString = currentAsString.uppercased()
      } else {
        currentAsString = NamingUtils.uppercaseFirstCharacter(currentAsString)
      }
      result += String(currentAsString)
      current = String.UnicodeScalarView()
    }

    for scalar in s.unicodeScalars {
      let scalarClass = CharClass(scalar)
      switch scalarClass {
      case .digit:
        if lastClass != .digit {
          addCurrent()
        }
        if result.isEmpty {
          // Don't want to start with a number for the very first thing.
          result += "_"
        }
        current.append(scalar)
      case .upper:
        if lastClass != .upper {
          addCurrent()
        }
        current.append(scalar.ascLowercased())
      case .lower:
        if lastClass != .lower && lastClass != .upper {
          addCurrent()
        }
        current.append(scalar)
      case .underscore:
        addCurrent()
        if lastClass == .underscore {
          result += "_"
        }
      case .other:
        addCurrent()
        let escapeIt =
          result.isEmpty
            ? !isSwiftIdentifierHeadCharacter(scalar)
            : !isSwiftIdentifierCharacter(scalar)
        if escapeIt {
          result.append("_u\(scalar.value)")
        } else {
          current.append(scalar)
        }
      }

      lastClass = scalarClass
    }

    // Add the last segment collected.
    addCurrent()

    // If things end in an underscore, add one also.
    if lastClass == .underscore {
      result += "_"
    }

    return result
  }
}

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

    // NOTE: This code relies on the protoc validation of proto packages. Look
    // at Parser::ParsePackage() to see the logic, it comes down to reading
    // _identifiers_ joined by '.'.  And _identifier_ is defined (in
    // Tokenizer::Next() as `[a-zA-Z_][a-zA-Z0-9_]*`, so this does not need
    // any complex validation or handing of characters outside those ranges.
    // It just has to deal with ended up with a leading digit after the pruning
    // of '_'s.

    // Transforms:
    //  "package.name" -> "Package_Name"
    //  "package_name" -> "PackageName"
    //  "pacakge.some_name" -> "Package_SomeName"
    var prefix = String.UnicodeScalarView()
    var makeUpper = true
    for c in protoPackage.unicodeScalars {
      if c == "_" {
        makeUpper = true
      } else if c == "." {
        makeUpper = true
        prefix.append("_")
      } else {
        if prefix.isEmpty && c.isASCDigit {
          // If the first character is going to be a digit, add an underscore
          // to ensure it is a valid Swift identifier.
          prefix.append("_")
        }
        if makeUpper {
          prefix.append(c.ascUppercased())
          makeUpper = false
        } else {
          prefix.append(c)
        }
      }
    }
    // End in an underscore to split off anything that gets added to it.
    return String(prefix) + "_"
  }

  /// Helper a proto prefix from strings.  A proto prefix means underscores
  /// and letter case are ignored.
  ///
  /// NOTE: Since this is acting on proto enum names and enum cases, we know
  /// the values must be _identifier_s which is defined (in Tokenizer::Next() as
  /// `[a-zA-Z_][a-zA-Z0-9_]*`, so this code is based on that limited input.
  struct PrefixStripper {
    private let prefixChars: String.UnicodeScalarView

    init(prefix: String) {
      self.prefixChars = prefix.lowercased().replacingOccurrences(of: "_", with: "").unicodeScalars
    }

    /// Strip the prefix and return the result, or return nil if it can't
    /// be stripped.
    func strip(from: String) -> String? {
      var prefixIndex = prefixChars.startIndex
      let prefixEnd = prefixChars.endIndex

      let fromChars = from.lowercased().unicodeScalars
      var fromIndex = fromChars.startIndex
      let fromEnd = fromChars.endIndex

      while (prefixIndex != prefixEnd) {
        if (fromIndex == fromEnd) {
          // Reached the end of the string while still having prefix to go
          // nothing to strip.
          return nil
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

      guard fromChars[fromIndex].isASCLowercase else {
        // Next character isn't a lowercase letter (it must be a digit
        // (fromChars was lowercased)), that would mean to make an enum value it
        // would have to get prefixed with an underscore which most folks
        // wouldn't consider to be a better Swift naming, so don't strip the
        // prefix.
        return nil
      }

      let count = fromChars.distance(from: fromChars.startIndex, to: fromIndex)
      let idx = from.index(from.startIndex, offsetBy: count)
      return String(from[idx..<from.endIndex])
    }
  }

  static func sanitize(messageName s: String, forbiddenTypeNames: Set<String>) -> String {
    return sanitizeTypeName(s, disambiguator: "Message", forbiddenTypeNames: forbiddenTypeNames)
  }

  static func sanitize(enumName s: String, forbiddenTypeNames: Set<String>) -> String {
    return sanitizeTypeName(s, disambiguator: "Enum", forbiddenTypeNames: forbiddenTypeNames)
  }

  static func sanitize(oneofName s: String, forbiddenTypeNames: Set<String>) -> String {
    return sanitizeTypeName(s, disambiguator: "Oneof", forbiddenTypeNames: forbiddenTypeNames)
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

  /// Forces the first character to be uppercase (if possible) and leaves
  /// the rest of the characters in their existing case.
  ///
  /// Use toUpperCamelCase() to get leading "HTTP", "URL", etc. correct.
  static func uppercaseFirstCharacter(_ s: String) -> String {
    let out = s.unicodeScalars
    if let first = out.first {
      var result = makeUnicodeScalarView(from: first.ascUppercased())
      result.append(
        contentsOf: out[out.index(after: out.startIndex)..<out.endIndex])
      return String(result)
    } else {
      return s
    }
  }

  /// Accepts any inputs and tranforms form it into a leading
  /// UpperCaseCamelCased Swift identifier. It follows the same conventions as
  /// that are used for mapping field names into the Message property names.
  public static func toUpperCamelCase(_ s: String) -> String {
    return CamelCaser.transform(s, initialUpperCase: true)
  }

  /// Accepts any inputs and tranforms form it into a leading
  /// lowerCaseCamelCased Swift identifier. It follows the same conventions as
  /// that are used for mapping field names into the Message property names.
  public static func toLowerCamelCase(_ s: String) -> String {
    return CamelCaser.transform(s, initialUpperCase: false)
  }

  static func trimBackticks(_ s: String) -> String {
    // This only has to deal with the backticks added when computing relative names, so
    // they are always matched and a single set.
    let backtick = "`"
    guard s.hasPrefix(backtick) else {
        assert(!s.hasSuffix(backtick))
        return s
    }
    assert(s.hasSuffix(backtick))
    let result = s.dropFirst().dropLast()
    assert(!result.hasPrefix(backtick) && !result.hasSuffix(backtick))
    return String(result)
  }

  static func periodsToUnderscores(_ s: String) -> String {
    return s.replacingOccurrences(of: ".", with: "_")
  }

  /// This must be exactly the same as the corresponding code in the
  /// SwiftProtobuf library.  Changing it will break compatibility of
  /// the generated code with old library version.
  public static func toJsonFieldName(_ s: String) -> String {
    var result = String.UnicodeScalarView()
    var capitalizeNext = false

    for c in s.unicodeScalars {
      if c == "_" {
        capitalizeNext = true
      } else if capitalizeNext {
        result.append(c.ascUppercased())
        capitalizeNext = false
      } else {
        result.append(c)
      }
    }
    return String(result)
  }
}
