// Sources/protoc-gen-swift/ReservedWords.swift - Reserved words database and sanitizing
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Reserved words that the Swift code generator will avoid using.
///
// -----------------------------------------------------------------------------

private let reservedTypeNames: Set<String> = [
            "Double",
            "Float",
            "Int",
            "Int32",
            "Int64",
            "Protocol",
            "String",
            "Type",
            "UInt",
            "UInt32",
            "UInt64",
            "__COLUMN__",
            "__FILE__",
            "__FUNCTION__",
            "__LINE__",
            "anyTypeURL",
            "as",
            "break",
            "case",
            "catch",
            "class",
            "continue",
            "debugDescription",
            "decodeField",
            "default",
            "defer",
            "deinit",
            "description",
            "do",
            "dynamicType",
            "else",
            "enum",
            "extension",
            "fallthrough",
            "false",
            "for",
            "func",
            "guard",
            "hashValue",
            "if",
            "import",
            "in",
            "init",
            "inout",
            "internal",
            "is",
            "isEmpty",
            "isEqual",
            "jsonFieldNames",
            "let",
            "nil",
            "operator",
            "private",
            "protocol",
            "public",
            "repeat",
            "rethrows",
            "return",
            "self",
            "static",
            "struct",
            "subscript",
            "super",
            "switch",
            "throw",
            "throws",
            "traverse",
            "true",
            "try",
            "typealias",
            "unknownFields",
            "var",
            "where",
            "while",
]

func sanitizeMessageTypeName(_ s: String) -> String {
    if reservedTypeNames.contains(s) {
        return s + "Message"
    } else if isAllUnderscore(s) {
        return s + "Message"
    } else {
        return s
    }
}


func sanitizeEnumTypeName(_ s: String) -> String {
    if reservedTypeNames.contains(s) {
        return s + "Enum"
    } else if isAllUnderscore(s) {
        return s + "Enum"
    } else {
        return s
    }
}

func sanitizeOneofTypeName(_ s: String) -> String {
    if reservedTypeNames.contains(s) {
        return s + "Oneof"
    } else if isAllUnderscore(s) {
        return s + "Oneof"
    } else {
        return s
    }
}

private let reservedFieldNames: Set<String> = [
            "Double",
            "Float",
            "Int",
            "Int32",
            "Int64",
            "String",
            "Type",
            "UInt",
            "UInt32",
            "UInt64",
            "as",
            "break",
            "case",
            "catch",
            "class",
            "continue",
            "debugDescription",
            "default",
            "defer",
            "deinit",
            "description",
            "do",
            "dynamicType",
            "else",
            "enum",
            "extension",
            "fallthrough",
            "false",
            "for",
            "func",
            "guard",
            "hashValue",
            "if",
            "import",
            "in",
            "init",
            "inout",
            "internal",
            "is",
            "isInitialized",
            "jsonFieldNames",
            "let",
            "nil",
            "operator",
            "private",
            "protocol",
            "public",
            "repeat",
            "rethrows",
            "return",
            "self",
            "static",
            "struct",
            "subscript",
            "super",
            "switch",
            "throw",
            "throws",
            "true",
            "try",
            "typealias",
            "unknownFields",
            "var",
            "where",
            "while",
]

/// Struct and class field names go through
/// this before going into the source code.
/// It appends "_p" to any name that can't be
/// used as a field name in Swift source code.
func sanitizeFieldName(_ s: String, basedOn: String) -> String {
    if reservedFieldNames.contains(basedOn) {
        return s + "_p"
    } else if isAllUnderscore(basedOn) {
        return s + "__"
    } else {
        return s
    }
}

func sanitizeFieldName(_ s: String) -> String {
  return sanitizeFieldName(s, basedOn: s)
}


/*
 * Many Swift reserved words can be used as enum cases if we put
 * backticks around them:
 */
private let quotableEnumCases: Set<String> = [
            "as",
            "associativity",
            "break",
            "case",
            "catch",
            "class",
            "continue",
            "default",
            "defer",
            "deinit",
            "do",
            "dynamicType",
            "else",
            "enum",
            "extension",
            "fallthrough",
            "false",
            "for",
            "func",
            "guard",
            "if",
            "import",
            "in",
            "init",
            "inout",
            "internal",
            "is",
            "let",
            "nil",
            "operator",
            "optional",
            "private",
            "protocol",
            "public",
            "repeat",
            "required",
            "rethrows",
            "return",
            "self",
            "static",
            "struct",
            "subscript",
            "super",
            "switch",
            "throw",
            "throws",
            "true",
            "try",
            "typealias",
            "var",
            "where",
            "while",
]

/*
 * Some words cannot be used for enum cases, even if they
 * are quoted with backticks:
 */
private let reservedEnumCases: Set<String> = [
            "debugDescription",
            "hashValue",
            "init",
            "rawValue",
            "self",
        ]

/*
 * Many Swift reserved words can be used as Extension names if we put
 * backticks around them.
 *
 * Note: To avoid the duplicate list to maintain, currently just reusing the
 *       EnumCases one.
 */
private let quotableMessageScopedExtensionNames: Set<String> = quotableEnumCases

/// enum case names are sanitized by adding
/// backticks `` around them.
func isAllUnderscore(_ s: String) -> Bool {
    for c in s.characters {
        if c != "_" {return false}
    }
    return true
}

func sanitizeEnumCase(_ s: String) -> String {
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

func sanitizeMessageScopedExtensionName(_ s: String, skipBackticks: Bool = false) -> String {
  // Since thing else is added to the "struct Extensions" for scoped
  // extensions, there is no need to have a reserved list.
  if quotableMessageScopedExtensionNames.contains(s) {
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
