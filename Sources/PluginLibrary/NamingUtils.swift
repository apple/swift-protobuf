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
// -----------------------------------------------------------------------------

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

}
