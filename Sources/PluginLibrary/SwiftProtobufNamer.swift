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
  var mappings: ProtoFileToModuleMappings
  var targetModule: String

  /// Initializes a a new namer, assuming everything will be in the same Swift module.
  public convenience init() {
    self.init(protoFileToModuleMappings: ProtoFileToModuleMappings(), targetModule: "")
  }

  /// Initializes a a new namer.  All names will be generated as from the pov of the
  /// given file using the provided file to module mapper.
  public convenience init(
    currentFile file: FileDescriptor,
    protoFileToModuleMappings mappings: ProtoFileToModuleMappings
  ) {
    let targetModule = mappings.moduleName(forFile: file) ?? ""
    self.init(protoFileToModuleMappings: mappings, targetModule: targetModule)
  }

  /// Internal initializer.
  init(
    protoFileToModuleMappings mappings: ProtoFileToModuleMappings,
    targetModule: String
  ) {
    self.mappings = mappings
    self.targetModule = targetModule
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
      return modulePrefix(file: message.file) + relativeName
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
    guard let containingType = e.containingType else {
      return modulePrefix(file: e.file) + relativeName
    }
    return fullName(message: containingType) + "." + relativeName
  }

  /// Calculate the relative name for the given enum value.
  public func relativeName(enumValue: EnumValueDescriptor) -> String {
    let baseName = enumValue.name
    if let stripped = NamingUtils.strip(protoPrefix: enumValue.enumType.name, from: baseName) {
      let camelCased = NamingUtils.toLowerCamelCase(stripped)
      if isValidSwiftIdentifier(camelCased) {
        return NamingUtils.sanitize(enumCaseName: camelCased)
      }
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

  /// Calculate the relative name for the given oneof.
  public func relativeName(oneof: OneofDescriptor) -> String {
    let camelCase = NamingUtils.toUpperCamelCase(oneof.name)
    return NamingUtils.sanitize(oneofName: "OneOf_\(camelCase)")
  }

  /// Calculate the full name for the given oneof.
  public func fullName(oneof: OneofDescriptor) -> String {
    return fullName(message: oneof.containingType) + "." + relativeName(oneof: oneof)
  }

  /// Calculate the relative name for the given entension.
  ///
  /// - Precondition: `extensionField` must be FieldDescriptor for an extension.
  public func relativeName(extensionField field: FieldDescriptor) -> String {
    precondition(field.isExtension)

    if field.extensionScope != nil {
      return NamingUtils.sanitize(messageScopedExtensionName: field.namingBase)
    } else {
      let swiftPrefix = typePrefix(forFile: field.file)
      return swiftPrefix + "Extensions_" + field.namingBase
    }
  }

  /// Calculate the full name for the given extension.
  ///
  /// - Precondition: `extensionField` must be FieldDescriptor for an extension.
  public func fullName(extensionField field: FieldDescriptor) -> String {
    precondition(field.isExtension)

    let relativeName = self.relativeName(extensionField: field)
    guard let extensionScope = field.extensionScope else {
      return modulePrefix(file: field.file) + relativeName
    }
    let extensionScopeSwiftFullName = fullName(message: extensionScope)
    let relativeNameNoBackticks = NamingUtils.trimBackticks(relativeName)
    return extensionScopeSwiftFullName + ".Extensions." + relativeNameNoBackticks
  }

  public typealias MessageFieldNames = (name: String, prefixed: String, has: String, clear: String)

  /// Calculate the names to use for the Swift fields on the message.
  ///
  /// If `prefixed` is not empty, the name prefixed with that will also be included.
  ///
  /// If `includeHasAndClear` is False, the has:, clear: values in the result will
  /// be the empty string.
  ///
  /// - Precondition: `field` must be FieldDescriptor that's isn't for an extension.
  public func messagePropertyNames(field: FieldDescriptor,
                                   prefixed: String,
                                   includeHasAndClear: Bool) -> MessageFieldNames {
    precondition(!field.isExtension)

    let lowerName = NamingUtils.toLowerCamelCase(field.namingBase)
    let fieldName = NamingUtils.sanitize(fieldName: lowerName)
    let prefixedFieldName =
      prefixed.isEmpty ? "" : NamingUtils.sanitize(fieldName: "\(prefixed)\(lowerName)", basedOn: lowerName)

    if !includeHasAndClear {
      return MessageFieldNames(name: fieldName, prefixed: prefixedFieldName, has: "", clear: "")
    }

    let upperName = NamingUtils.toUpperCamelCase(field.namingBase)
    let hasName = NamingUtils.sanitize(fieldName: "has\(upperName)", basedOn: lowerName)
    let clearName = NamingUtils.sanitize(fieldName: "clear\(upperName)", basedOn: lowerName)

    return MessageFieldNames(name: fieldName, prefixed: prefixedFieldName, has: hasName, clear: clearName)
  }

  public typealias OneofFieldNames = (name: String, prefixed: String)

  /// Calculate the name to use for the Swift field on the message.
  public func messagePropertyName(oneof: OneofDescriptor, prefixed: String = "_") -> OneofFieldNames {
    let lowerName = NamingUtils.toLowerCamelCase(oneof.name)
    let fieldName = NamingUtils.sanitize(fieldName: lowerName)
    let prefixedFieldName = NamingUtils.sanitize(fieldName: "\(prefixed)\(lowerName)", basedOn: lowerName)
    return OneofFieldNames(name: fieldName, prefixed: prefixedFieldName)
  }

  public typealias MessageExtensionNames = (value: String, has: String, clear: String)

  /// Calculate the names to use for the Swift Extension on the extended
  /// message.
  ///
  /// - Precondition: `extensionField` must be FieldDescriptor for an extension.
  public func messagePropertyNames(extensionField field: FieldDescriptor) -> MessageExtensionNames {
    precondition(field.isExtension)

    let fieldBaseName = NamingUtils.toLowerCamelCase(field.namingBase)

    let fieldName: String
    let hasName: String
    let clearName: String

    if let extensionScope = field.extensionScope {
      let extensionScopeSwiftFullName = fullName(message: extensionScope)
      // Don't worry about any sanitize api on these names; since there is a
      // Message name on the front, it should never hit a reserved word.
      //
      // fieldBaseName is the lowerCase name even though we put more on the
      // front, this seems to help make the field name stick out a little
      // compared to the message name scoping it on the front.
      fieldName = NamingUtils.periodsToUnderscores(extensionScopeSwiftFullName + "_" + fieldBaseName)
      let fieldNameFirstUp = NamingUtils.uppercaseFirstCharacter(fieldName)
      hasName = "has" + fieldNameFirstUp
      clearName = "clear" + fieldNameFirstUp
    } else {
      // If there was no package and no prefix, fieldBaseName could be a reserved
      // word, so sanitize. These's also the slim chance the prefix plus the
      // extension name resulted in a reserved word, so the sanitize is always
      // needed.
      let swiftPrefix = typePrefix(forFile: field.file)
      fieldName = NamingUtils.sanitize(fieldName: swiftPrefix + fieldBaseName)
      if swiftPrefix.isEmpty {
        // No prefix, so got back to UpperCamelCasing the extension name, and then
        // sanitize it like we did for the lower form.
        let upperCleaned = NamingUtils.sanitize(fieldName: NamingUtils.toUpperCamelCase(field.namingBase),
                                                basedOn: fieldBaseName)
        hasName = "has" + upperCleaned
        clearName = "clear" + upperCleaned
      } else {
        // Since there was a prefix, just add has/clear and ensure the first letter
        // was capitalized.
        let fieldNameFirstUp = NamingUtils.uppercaseFirstCharacter(fieldName)
        hasName = "has" + fieldNameFirstUp
        clearName = "clear" + fieldNameFirstUp
      }
    }

    return MessageExtensionNames(value: fieldName, has: hasName, clear: clearName)
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

  /// Internal helper to find the module prefix for a symbol given a file.
  func modulePrefix(file: FileDescriptor) -> String {
    guard let prefix = mappings.moduleName(forFile: file) else {
      return String()
    }

    if prefix == targetModule {
      return String()
    }

    return "\(prefix)."
  }
}
