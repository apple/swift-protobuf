// Tests/PluginLibraryTests/Test_NamingUtils.swift - Test NamingUtils.swift
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------

import XCTest
@testable import PluginLibrary

class Test_NamingUtils: XCTestCase {

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

      ( "foo.BAR_baz", nil, "Foo_BARBaz_" ),
      ( "foo.bar_bAZ", nil, "Foo_BarBAZ_" ),
      ( "FOO.BAR_BAZ", nil, "FOO_BARBAZ_" ),

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

  func testSanitize_messageName() {
    // input, expected
    let tests: [(String, String)] = [
      ( "", "" ),

      ( "Foo", "Foo" ),
      ( "FooBar", "FooBar" ),
      ( "foo_bar", "foo_bar" ),

      // Some of our names get the disambiguator added.
      ( "SwiftProtobuf", "SwiftProtobufMessage" ),
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
      XCTAssertEqual(NamingUtils.sanitize(messageName: input), expected)
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
      XCTAssertEqual(NamingUtils.sanitize(enumName: input), expected)
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
      ( "SwiftProtobuf", "SwiftProtobufOneof" ),
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
      XCTAssertEqual(NamingUtils.sanitize(oneofName: input), expected)
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
      ( "associatedtype", "associatedtype_p" ),
      ( "class", "class_p" ),
      ( "break", "break_p" ),
      ( "do", "do_p" ),

      // "has"/"clear" get added by us, so they get the disambiguator.
      ( "hasFoo", "hasFoo_p" ),
      ( "clearFoo", "clearFoo_p" ),

      // Underscores get more underscores.
      ( "_", "___" ),
      ( "___", "_____" ),
    ]

    func uppercaseFirst(_ s: String) -> String {
      var result = s.characters
      if let first = result.popFirst() {
        return String(first).uppercased() + String(result)
      } else {
        return s
      }
    }

    for (input, expected) in tests {
      XCTAssertEqual(NamingUtils.sanitize(fieldName: input), expected)

      let inputPrefixed = "XX" + uppercaseFirst(input)
      let expected2 = "XX" + uppercaseFirst(expected)
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
}
