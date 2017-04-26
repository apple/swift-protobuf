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
}
