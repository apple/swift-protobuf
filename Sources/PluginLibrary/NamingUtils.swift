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
/// NOTE: These are *NOT* public since the expectation is the results exposed
/// on the Descriptor object is all that is needed.
///
// -----------------------------------------------------------------------------

///
/// We won't generate types (structs, enums) with these names:
///
private let reservedTypeNames: Set<String> = {
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

  names = names.union(swiftKeywordsUsedInDeclarations)
  names = names.union(swiftKeywordsUsedInStatements)
  names = names.union(swiftKeywordsUsedInExpressionsAndTypes)
  names = names.union(swiftCommonTypes)
  names = names.union(swiftSpecialVariables)
  return names
}()

private let reservedFieldNames: Set<String> = {
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
 * Many Swift reserved words can be used as enum cases if we put
 * backticks around them:
 */
private let quotableEnumCases: Set<String> = {
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
private let reservedEnumCases: Set<String> = [
  // Don't conflict with standard Swift property names:
  "debugDescription",
  "description",
  "dynamicType",
  "hashValue",
  "init",
  "rawValue",
  "self",
]


private func isAllUnderscore(_ s: String) -> Bool {
  if s.isEmpty {
    return false
  }
  for c in s.characters {
    if c != "_" {return false}
  }
  return true
}


private func sanitizeTypeName(_ s: String, disambiguator: String) -> String {
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


/*
 * Message scoped extensions are scoped within the Message struct with
 * `enum Extensions { ... }`, so we resuse the same sets for backticks
 * and reserved words.
 */
private let quotableMessageScopedExtensionNames: Set<String> = quotableEnumCases
private let reservedMessageScopedExtensionNames: Set<String> = reservedEnumCases

// Scope for the utilies to they are less likely to conflict when imported into
// generators.
enum NamingUtils {

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
    if basedOn.hasPrefix("clear") {
      return s + "_p"
    } else if basedOn.hasPrefix("has") {
      return s + "_p"
    } else if reservedFieldNames.contains(basedOn) {
      return s + "_p"
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

  static func sanitize(messageScopedExtensionName s: String, skipBackticks: Bool = false) -> String {
    if reservedMessageScopedExtensionNames.contains(s) {
      return "\(s)_"
    } else if quotableMessageScopedExtensionNames.contains(s) {
      if skipBackticks {
        return s
      }
      return "`\(s)`"
    } else if isAllUnderscore(s) {
      return s + "__"
    } else {
      return s
    }
  }

}
