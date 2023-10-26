// Tests/SwiftProtobufPluginLibraryTests/Test_NamingUtils.swift - Test NamingUtils.swift
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------

import XCTest
import SwiftProtobuf
@testable import SwiftProtobufPluginLibrary

final class Test_NamingUtils: XCTestCase {

  func testTypePrefix() throws {
    // package, swiftPrefix, expected
    let tests: [(String, String?, String)] = [
      ( "", nil, "" ),
      ( "", "", "" ),

      ( "foo", nil, "Foo_" ),
      ( "FOO", nil, "FOO_" ),
      ( "fooBar", nil, "FooBar_" ),
      ( "FooBar", nil, "FooBar_" ),

      ( "foo.bar.baz", nil, "Foo_Bar_Baz_" ),
      ( "foo_bar_baz", nil, "FooBarBaz_" ),
      ( "foo.bar_baz", nil, "Foo_BarBaz_" ),
      ( "foo_bar__baz", nil, "FooBarBaz_" ),
      ( "foo.bar_baz_", nil, "Foo_BarBaz_" ),
      ( "foo._bar_baz", nil, "Foo_BarBaz_" ),

      ( "foo.BAR_baz", nil, "Foo_BARBaz_" ),
      ( "foo.bar_bAZ", nil, "Foo_BarBAZ_" ),
      ( "FOO.BAR_BAZ", nil, "FOO_BARBAZ_" ),

      ( "_foo", nil, "Foo_" ),
      ( "__foo", nil, "Foo_" ),
      ( "_1foo", nil, "_1foo_" ),
      ( "__1foo", nil, "_1foo_" ),
      ( "_1foo.2bar._3baz", nil, "_1foo_2bar_3baz_" ),
      ( "_1foo_2bar_3baz", nil, "_1foo2bar3baz_" ),

      ( "foo.bar.baz", "", "" ),
      ( "", "ABC", "ABC" ),

      ( "foo.bar.baz", "ABC", "ABC" ),
      ( "foo.bar.baz", "abc", "abc" ),
      ( "foo.bar.baz", "aBc", "aBc" ),
    ]
    for (package, prefix, expected) in tests {
      var proto = Google_Protobuf_FileOptions()
      if let prefix = prefix {
        proto.swiftPrefix = prefix
      }
      let result = NamingUtils.typePrefix(protoPackage: package, fileOptions: proto)
      XCTAssertEqual(result, expected, "Package: \(package), Prefix: \(prefix ?? "nil")")
    }
  }

  func testPrefixStripper_strip() {
    // prefix, string, expected
    let tests: [(String, String, String?)] = [
      ( "", "", nil ),

      ( "FOO", "FOO", nil ),
      ( "fOo", "FOO", nil ),

      ( "foo_", "FOO", nil ),
      ( "_foo", "FOO", nil ),
      ( "_foo_", "FOO", nil ),

      ( "foo", "FOO_", nil ),
      ( "foo", "_FOO", nil ),
      ( "foo", "_FOO_", nil ),

      ( "foo_", "FOObar", "bar" ),
      ( "_foo", "FOObar", "bar" ),
      ( "_foo_", "FOObar", "bar" ),

      ( "foo", "FOO_bar", "bar" ),
      ( "foo", "_FOObar", "bar" ),
      ( "foo", "_FOO_bar", "bar" ),

      ( "FOO_bar", "foo_BAR_baz", "baz" ),
      ( "FooBar", "foo_bar_Baz", "Baz" ),
      ( "foo_bar", "foobar_bAZ", "bAZ" ),
      ( "_foo_bar", "foobar_bAZ", "bAZ" ),
      ( "foo__bar_", "_foo_bar__baz", "baz" ),

      ( "FooBar", "foo_bar_1", nil ),
      ( "FooBar", "foo_bar_1foo", nil ),
      ( "FooBar", "foo_bar_foo1", "foo1" ),
    ]
    for (prefix, str, expected) in tests {
      let stripper = NamingUtils.PrefixStripper(prefix: prefix)
      let result = stripper.strip(from: str)
      XCTAssertEqual(result, expected, "Prefix: \(prefix), Input: \(str)")
    }
  }

  func testSanitize_messageName() {
    // input, expected
    let tests: [(String, String)] = [
      ( "", "" ),

      ( "Foo", "Foo" ),
      ( "FooBar", "FooBar" ),
      ( "foo_bar", "foo_bar" ),

      // Some of our names get the disambiguator added.
      ( "SwiftProtobuf", "SwiftProtobufMessage" ),
      ( "RenamedSwiftProtobuf", "RenamedSwiftProtobufMessage" ),
      ( "isInitialized", "isInitializedMessage" ),

      // Some Swift keywords.
      ( "associatedtype", "associatedtypeMessage" ),
      ( "class", "classMessage" ),
      ( "break", "breakMessage" ),
      ( "do", "doMessage" ),

      // Inputs with the disambiguator.
      ( "classMessage", "classMessageMessage" ),
      ( "classMessageMessage", "classMessageMessageMessage" ),

      // Underscores
      ( "_", "_Message" ),
      ( "___", "___Message" ),
    ]
    for (input, expected) in tests {
      XCTAssertEqual(NamingUtils.sanitize(messageName: input, forbiddenTypeNames: ["RenamedSwiftProtobuf"]), expected)
    }
  }

  func testSanitize_enumName() {
    // input, expected
    let tests: [(String, String)] = [
      ( "", "" ),

      ( "Foo", "Foo" ),
      ( "FooBar", "FooBar" ),
      ( "foo_bar", "foo_bar" ),

      // Some of our names get the disambiguator added.
      ( "SwiftProtobuf", "SwiftProtobufEnum" ),
      ( "RenamedSwiftProtobuf", "RenamedSwiftProtobufEnum" ),
      ( "isInitialized", "isInitializedEnum" ),

      // Some Swift keywords.
      ( "associatedtype", "associatedtypeEnum" ),
      ( "class", "classEnum" ),
      ( "break", "breakEnum" ),
      ( "do", "doEnum" ),

      // Inputs with the disambiguator.
      ( "classEnum", "classEnumEnum" ),
      ( "classEnumEnum", "classEnumEnumEnum" ),

      // Underscores
      ( "_", "_Enum" ),
      ( "___", "___Enum" ),
    ]
    for (input, expected) in tests {
      XCTAssertEqual(NamingUtils.sanitize(enumName: input, forbiddenTypeNames: ["RenamedSwiftProtobuf"]), expected)
    }
  }

  func testSanitize_oneofName() {
    // input, expected
    let tests: [(String, String)] = [
      ( "", "" ),

      ( "Foo", "Foo" ),
      ( "FooBar", "FooBar" ),
      ( "foo_bar", "foo_bar" ),

      // Some of our names get the disambiguator added.
      ( "RenamedSwiftProtobuf", "RenamedSwiftProtobufOneof" ),
      ( "isInitialized", "isInitializedOneof" ),

      // Some Swift keywords.
      ( "associatedtype", "associatedtypeOneof" ),
      ( "class", "classOneof" ),
      ( "break", "breakOneof" ),
      ( "do", "doOneof" ),

      // Inputs with the disambiguator.
      ( "classOneof", "classOneofOneof" ),
      ( "classOneofOneof", "classOneofOneofOneof" ),

      // Underscores
      ( "_", "_Oneof" ),
      ( "___", "___Oneof" ),
    ]
    for (input, expected) in tests {
      XCTAssertEqual(NamingUtils.sanitize(oneofName: input, forbiddenTypeNames: ["RenamedSwiftProtobuf"]), expected)
    }
  }

  func testSanitize_fieldName() {
    // input, expected
    let tests: [(String, String)] = [
      ( "", "" ),

      ( "Foo", "Foo" ),
      ( "FooBar", "FooBar" ),
      ( "foo_bar", "foo_bar" ),

      // Some of our names get the disambiguator added.
      ( "debugDescription", "debugDescription_p" ),
      ( "isInitialized", "isInitialized_p" ),

      // Some Swift keywords.
      ( "associatedtype", "`associatedtype`" ),
      ( "class", "`class`" ),
      ( "break", "`break`" ),
      ( "do", "`do`" ),

      // "has"/"clear" get added by us, so they get the disambiguator...
      ( "hasFoo", "hasFoo_p" ),
      ( "clearFoo", "clearFoo_p" ),
      // ...but don't catch words...
      ( "hashtag", "hashtag" ),
      ( "clearable", "clearable" ),
      ( "has911", "has911" ),
      // ...or by themselves.
      ( "has", "has" ),
      ( "clear", "clear" ),

      // Underscores get more underscores.
      ( "_", "___" ),
      ( "___", "_____" ),
    ]

    for (input, expected) in tests {
      XCTAssertEqual(NamingUtils.sanitize(fieldName: input), expected)

      let inputPrefixed = "XX" + NamingUtils.uppercaseFirstCharacter(input)
      let expected2 = "XX" + NamingUtils.uppercaseFirstCharacter(NamingUtils.trimBackticks(expected))
      XCTAssertEqual(NamingUtils.sanitize(fieldName: inputPrefixed, basedOn: input), expected2)
    }
  }

  func testSanitize_enumCaseName() {
    // input, expected
    let tests: [(String, String)] = [
      ( "", "" ),

      ( "Foo", "Foo" ),
      ( "FooBar", "FooBar" ),
      ( "foo_bar", "foo_bar" ),

      // Some of our names get the disambiguator added.
      ( "debugDescription", "debugDescription_" ),
      ( "dynamicType", "dynamicType_" ),

      // Some Swift keywords work with backticks
      ( "associatedtype", "`associatedtype`" ),
      ( "class", "`class`" ),
      ( "break", "`break`" ),
      ( "do", "`do`" ),

      // Underscores get more underscores.
      ( "_", "___" ),
      ( "___", "_____" ),
    ]

    for (input, expected) in tests {
      XCTAssertEqual(NamingUtils.sanitize(enumCaseName: input), expected)
    }
  }
  
  func testSanitize_messageScopedExtensionName() {
    // input, expected
    let tests: [(String, String)] = [
      ( "", "" ),

      ( "Foo", "Foo" ),
      ( "FooBar", "FooBar" ),
      ( "foo_bar", "foo_bar" ),

      // Some of our names get the disambiguator added.
      ( "debugDescription", "debugDescription_" ),
      ( "dynamicType", "dynamicType_" ),

      // Some Swift keywords work with backticks
      ( "associatedtype", "`associatedtype`" ),
      ( "class", "`class`" ),
      ( "break", "`break`" ),
      ( "do", "`do`" ),

      // Underscores get more underscores.
      ( "_", "___" ),
      ( "___", "_____" ),
    ]

    for (input, expected) in tests {
      XCTAssertEqual(NamingUtils.sanitize(messageScopedExtensionName: input), expected)
    }
  }

  func testToCamelCase() {
    // input, expectedLower, expectedUpper
    let tests: [(String, String, String)] = [
      ( "", "", "" ),

      ( "foo", "foo", "Foo" ),
      ( "FOO", "foo", "Foo" ),
      ( "foO", "foO", "FoO" ),

      ( "foo_bar", "fooBar", "FooBar" ),
      ( "foo_bar", "fooBar", "FooBar" ),
      ( "foo_bAr_BaZ", "fooBArBaZ", "FooBArBaZ" ),
      ( "foo_bAr_BaZ", "fooBArBaZ", "FooBArBaZ" ),

      ( "foo1bar", "foo1Bar", "Foo1Bar" ),
      ( "foo2bAr3BaZ", "foo2BAr3BaZ", "Foo2BAr3BaZ" ),

      ( "foo_1bar", "foo1Bar", "Foo1Bar" ),
      ( "foo_2bAr_3BaZ", "foo2BAr3BaZ", "Foo2BAr3BaZ" ),
      ( "_0foo_1bar", "_0Foo1Bar", "_0Foo1Bar" ),
      ( "_0foo_2bAr_3BaZ", "_0Foo2BAr3BaZ", "_0Foo2BAr3BaZ" ),

      ( "url", "url", "URL" ),
      ( "http", "http", "HTTP" ),
      ( "https", "https", "HTTPS" ),
      ( "id", "id", "ID" ),

      ( "the_url", "theURL", "TheURL" ),
      ( "use_http", "useHTTP", "UseHTTP" ),
      ( "use_https", "useHTTPS", "UseHTTPS" ),
      ( "request_id", "requestID", "RequestID" ),

      ( "url_number", "urlNumber", "URLNumber" ),
      ( "http_needed", "httpNeeded", "HTTPNeeded" ),
      ( "https_needed", "httpsNeeded", "HTTPSNeeded" ),
      ( "id_number", "idNumber", "IDNumber" ),

      ( "is_url_number", "isURLNumber", "IsURLNumber" ),
      ( "is_http_needed", "isHTTPNeeded", "IsHTTPNeeded" ),
      ( "is_https_needed", "isHTTPSNeeded", "IsHTTPSNeeded" ),
      ( "the_id_number", "theIDNumber", "TheIDNumber" ),

      ( "url_foo_http_id", "urlFooHTTPID", "URLFooHTTPID"),

      ( "göß", "göß", "Göß"),
      ( "göo", "göO", "GöO"),
      ( "gö_o", "göO", "GöO"),
      ( "g_🎉_o", "g🎉O", "G🎉O"),
      ( "g🎉o", "g🎉O", "G🎉O"),

      ( "m\u{AB}n", "m_u171N", "M_u171N"),
      ( "m\u{AB}_n", "m_u171N", "M_u171N"),
      ( "m_\u{AB}_n", "m_u171N", "M_u171N"),
    ]

    for (input, expectedLower, expectedUppper) in tests {
      XCTAssertEqual(NamingUtils.toLowerCamelCase(input), expectedLower)
      XCTAssertEqual(NamingUtils.toUpperCamelCase(input), expectedUppper)
    }
  }
}
