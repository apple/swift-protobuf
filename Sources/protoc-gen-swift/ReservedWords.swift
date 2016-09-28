// Sources/ReservedWords.swift - Reserved words database and sanitizing
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
            "protoFieldNames",
            "protoMessageName",
            "protoPackageName",
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
            "swiftClassName",
            "switch",
            "throw",
            "throws",
            "traverse",
            "true",
            "try",
            "typealias",
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
            "anyTypeURL",
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
            "jsonFieldNames",
            "let",
            "nil",
            "operator",
            "private",
            "protoFielNames",
            "protoMessageName",
            "protoPackageName",
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
            "swiftClassName",
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

/// Struct and class field names go through
/// this before going into the source code.
/// It appends "_p" to any name that can't be
/// used as a field name in Swift source code.
func sanitizeFieldName(_ s: String) -> String {
    if reservedFieldNames.contains(s) {
        return s + "_p"
    } else if isAllUnderscore(s) {
        return s + "__"
    } else {
        return s
    }
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
            "json",
            "rawValue",
            "self",
        ]

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

func sanitizeDisplayEnumCase(_ s: String) -> String {
    if reservedEnumCases.contains(s) {
        return "\(s)_"
    } else if quotableEnumCases.contains(s) {
        // Don't quote the bare enum case name
        return s
    } else if isAllUnderscore(s) {
        return s + "__"
    } else {
        return s
    }
}
