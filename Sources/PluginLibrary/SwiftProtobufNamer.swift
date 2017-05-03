// Sources/PluginLibrary/SwiftProtobufNamer - A helper that generates SwiftProtobuf names.
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// A helper that can generate SwiftProtobuf names from types.
///
// -----------------------------------------------------------------------------

import Foundation

public final class SwiftProtobufNamer {
  var filePrefixCache = [String:String]()
  var enumCanStripPrefixCache = [String:Bool]()

  public init() {
    // TODO(thomasvl): Eventually support taking a mapping of files to modules.
  }

  /// Calculate the relative name for the given message.
  public func relativeName(message: Descriptor) -> String {
    if message.containingType != nil {
      return NamingUtils.sanitize(messageName: message.name)
    } else {
      let prefix = typePrefix(forFile: message.file)
      return NamingUtils.sanitize(messageName: prefix + message.name)
    }
  }

  /// Calculate the full name for the given message.
  public func fullName(message: Descriptor) -> String {
    let relativeName = self.relativeName(message: message)
    guard let containingType = message.containingType else {
      return relativeName
    }
    return fullName(message:containingType) + "." + relativeName
  }

  /// Calculate the relative name for the given enum.
  public func relativeName(enum e: EnumDescriptor) -> String {
    if e.containingType != nil {
      return NamingUtils.sanitize(enumName: e.name)
    } else {
      let prefix = typePrefix(forFile: e.file)
      return NamingUtils.sanitize(enumName: prefix + e.name)
    }
  }

  /// Calculate the full name for the given enum.
  public func fullName(enum e: EnumDescriptor) -> String {
    let relativeName = self.relativeName(enum: e)
    guard  let containingType = e.containingType else {
      return relativeName
    }
    return fullName(message: containingType) + "." + relativeName
  }

  /// Calculate the relative name for the given enum value.
  public func relativeName(enumValue: EnumValueDescriptor) -> String {
    let baseName: String
    if canStripPrefix(enum: enumValue.enumType) {
      baseName = NamingUtils.strip(protoPrefix: enumValue.enumType.name, from: enumValue.name)!
    } else {
      baseName = enumValue.name
    }

    let camelCased = NamingUtils.toLowerCamelCase(baseName)
    return NamingUtils.sanitize(enumCaseName: camelCased)
  }

  /// Calculate the full name for the given enum value.
  public func fullName(enumValue: EnumValueDescriptor) -> String {
    return fullName(enum: enumValue.enumType) + "." + relativeName(enumValue: enumValue)
  }

  /// The relative name with a leading dot so it can be used where
  /// the type is known.
  public func dottedRelativeName(enumValue: EnumValueDescriptor) -> String {
    let relativeName = self.relativeName(enumValue: enumValue)
    return "." + NamingUtils.trimBackticks(relativeName)
  }

  /// Calculate the prefix to use for this file, it is derived from the
  /// proto package or swift_prefix file option.
  public func typePrefix(forFile file: FileDescriptor) -> String {
    if let result = filePrefixCache[file.name] {
      return result
    }

    let result = NamingUtils.typePrefix(protoPackage: file.package,
                                        fileOptions: file.fileOptions)
    filePrefixCache[file.name] = result
    return result
  }
  
  // MARK: - Internal helpers

  /// Calculate if the given enum's value can use prefix stripping.
  func canStripPrefix(enum e: EnumDescriptor) -> Bool {
    if let result = enumCanStripPrefixCache[e.fullName] {
      return result
    }

    let result = NamingUtils.canStripPrefix(enumProto: e.proto)
    enumCanStripPrefixCache[e.fullName] = result
    return result
  }

}
