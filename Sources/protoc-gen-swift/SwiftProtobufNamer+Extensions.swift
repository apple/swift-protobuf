// Sources/SwiftProtobufPluginLibrary/SwiftProtobufNamer.swift - A helper that generates SwiftProtobuf names.
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// A helper that can generate SwiftProtobuf names from types.
///
// -----------------------------------------------------------------------------

import SwiftProtobufPluginLibrary

extension SwiftProtobufNamer {

  /// Filters the Enum's values to those that will have unique Swift
  /// names. Only poorly named proto enum alias values get filtered
  /// away, so the assumption is they aren't really needed from an
  /// api pov.
  func uniquelyNamedValues(
    valueAliasInfo aliasInfo: EnumDescriptor.ValueAliasInfo
  ) -> [EnumValueDescriptor] {
    return aliasInfo.mainValues.first!.enumType.values.filter {
      // Original are kept as is. The computations for relative
      // name already adds values for collisions with different
      // values.
      guard let aliasOf = aliasInfo.original(of: $0) else { return true }
      let relativeName = self.relativeName(enumValue: $0)
      let aliasOfRelativeName = self.relativeName(enumValue: aliasOf)
      // If the relative name matches for the alias and original, drop
      // the alias.
      guard relativeName != aliasOfRelativeName else { return false }
      // Only include this alias if it is the first one with this name.
      // (handles alias with different cases in their names that get
      // mangled to a single Swift name.)
      let firstAlias = aliasInfo.aliases(aliasOf)!.firstIndex {
        let otherRelativeName = self.relativeName(enumValue: $0)
        return relativeName == otherRelativeName
      }
      return aliasInfo.aliases(aliasOf)![firstAlias!] === $0
    }
  }
}
