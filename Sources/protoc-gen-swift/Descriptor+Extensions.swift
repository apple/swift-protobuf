// Sources/protoc-gen-swift/Descriptor+Extensions.swift - Additions to Descriptors
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------

import SwiftProtobufPluginLibrary

extension FileDescriptor {
  var isBundledProto: Bool {
    return SwiftProtobufInfo.isBundledProto(file: self)
  }

  // Returns a string of any import lines for the give file based on the file's
  // imports. The string may include multiple lines.
  //
  // Protocol Buffers has the concept of "public imports", these are imports
  // into a file that expose everything from within the file to the new
  // context. From the docs -
  // https://protobuf.dev/programming-guides/proto/#importing
  //   `import public` dependencies can be transitively relied upon by anyone
  //    importing the proto containing the import public statement.
  // To properly expose the types for use, it means in each file, the public
  // imports from the dependencies (recursively) have to be hoisted and
  // reexported. This way someone importing a given module still sees the type
  // even when moved.
  //
  // NOTE: There is a weakness for Swift with protobuf extensions. To make
  // the protobuf extensions easier to use, a Swift extension is declared with
  // field exposed as a property on the extended message. There is no way
  // to reexport the Swift `extension` and/or added properties. But the raw
  // types are re-exported to minimize the breaking of code if a type is moved
  // between files/modules.
  //
  // `reexportPublicImports` will cause the `import public` types to be
  // reexported to avoid breaking downstream code using a type that might have
  // moved between .proto files.
  //
  // `asImplementationOnly` will cause all of the import directives to be
  // marked as `@_implementationOnly`. It will also cause all of the `file`'s
  // `publicDependencies` to instead be recursively pulled up as direct imports
  // to ensure the generate file compiles, and no `import public` files are
  // re-exported.
  //
  // Aside: This could be moved into the plugin library, but it doesn't seem
  // like anyone else would need the logic. Swift GRPC support probably stick
  // with the support for the module mappings.
  public func computeImports(
    namer: SwiftProtobufNamer,
    reexportPublicImports: Bool,
    asImplementationOnly: Bool
  ) -> String {
    // The namer should be configured with the module this file generated for.
    assert(namer.targetModule == (namer.mappings.moduleName(forFile: self) ?? ""))
    // Both options can't be enabled.
    assert(!reexportPublicImports ||
           !asImplementationOnly ||
           reexportPublicImports != asImplementationOnly)

    guard namer.mappings.hasMappings else {
      // No module mappings? Everything must be the same module, so no Swift
      // imports will be needed.
      return ""
    }

    if dependencies.isEmpty {
      // No proto dependencies (imports), then no Swift imports will be needed.
      return ""
    }

    let directive = asImplementationOnly ? "@_implementationOnly import" : "import"
    var imports = Set<String>()
    for dependency in dependencies {
      if SwiftProtobufInfo.isBundledProto(file: dependency) {
        continue  // No import needed for the runtime, that's always added.
      }
      if reexportPublicImports && publicDependencies.contains(where: { $0 === dependency }) {
        // When re-exporting, the `import public` types will be imported
        // instead of importing the module.
        continue
      }
      if let depModule = namer.mappings.moduleName(forFile: dependency),
         depModule != namer.targetModule {
        // Different module, import it.
        imports.insert("\(directive) \(depModule)")
      }
    }

    // If not re-exporting imports, then there is nothing special needed for
    // `import public` files, as any transitive `import public` directives
    // would have already re-exported the types, so everything this file needs
    // will be covered by the above imports.
    let exportingImports: [String] =
      reexportPublicImports ? computeSymbolReExports(namer: namer) : [String]()

    var result = imports.sorted().joined(separator: "\n")
    if !exportingImports.isEmpty {
      if !result.isEmpty {
        result.append("\n")
      }
      result.append("// Use of 'import public' causes re-exports:\n")
      result.append(exportingImports.sorted().joined(separator: "\n"))
    }
    return result
  }

  // Internal helper to `computeImports(...)`.
  private func computeSymbolReExports(namer: SwiftProtobufNamer) -> [String] {
    var result = [String]()

    // To handle re-exporting, recursively walk all the `import public` files
    // and make this module do a Swift exporting import of the specific
    // symbols. That will keep any type that gets moved between .proto files
    // still exposed from the same modules so as not to break developer
    // authored code.
    var toScan = publicDependencies
    var visited = Set<String>()
    while let dependency = toScan.popLast() {
      let dependencyName = dependency.name
      if visited.contains(dependencyName) { continue }
      visited.insert(dependencyName)

      if SwiftProtobufInfo.isBundledProto(file: dependency) {
        continue  // Bundlined file, nothing to do.
      }
      guard let depModule = namer.mappings.moduleName(forFile: dependency) else {
        continue  // No mapping, assume same module, nothing to do.
      }
      if depModule == namer.targetModule {
        // Same module, nothing to do (that generated file will do any re-exports).
        continue
      }

      toScan.append(contentsOf: dependency.publicDependencies)

      // NOTE: This re-exports/imports from the module that defines the type.
      // If Xcode/SwiftPM ever were to do some sort of "layering checks" to
      // ensure there is a direct dependency on the thing being imported, this
      // could be updated do the re-export/import from the middle step in
      // chained imports.

      for m in dependency.messages {
        result.append("@_exported import struct \(namer.fullName(message: m))")
      }
      for e in dependency.enums {
        result.append("@_exported import enum \(namer.fullName(enum: e))")
      }
      // There is nothing we can do for the Swift extensions declared on the
      // extended Messages, best we can do is expose the raw extensions
      // themselves.
      for e in dependency.extensions {
        result.append("@_exported import let \(namer.fullName(extensionField: e))")
      }
    }
    return result
  }
}

extension Descriptor {
  /// Returns true if the message should use the message set wireformat.
  var useMessageSetWireFormat: Bool { return options.messageSetWireFormat }

  /// Returns True if this message recursively contains a required field.
  /// This is a helper for generating isInitialized methods.
  ///
  /// The logic for this check comes from google/protobuf; the C++ and Java
  /// generators specifically
  func containsRequiredFields() -> Bool {
    var alreadySeen = Set<String>()

    func helper(_ descriptor: Descriptor) -> Bool {
      if alreadySeen.contains(descriptor.fullName) {
        // First required thing found causes this to return true, so one can
        // assume if it is already visited and and wasn't cached, it is part
        // of a recursive cycle, so return false without caching to allow
        // the evaluation to continue on other fields of the message.
        return false
      }
      alreadySeen.insert(descriptor.fullName)

      // If it can support extensions, then return true as an extension could
      // have a required field.
      if !descriptor.messageExtensionRanges.isEmpty {
        return true
      }

      for f in descriptor.fields {
        if f.isRequired {
          return true
        }
        if let messageType = f.messageType, helper(messageType) {
          return true
        }
      }

      return false
    }

    return helper(self)
  }

  /// The `extensionRanges` are in the order they appear in the original .proto
  /// file; this orders them and then merges any ranges that are actually
  /// contiguous (i.e. - [(21,30),(10,20)] -> [(10,30)])
  ///
  /// This also uses Range<> since the options that could be on
  /// `extensionRanges` no longer can apply as the things have been merged.
  var _normalizedExtensionRanges: [Range<Int32>] {
    var ordered: [Range<Int32>] = self.messageExtensionRanges.sorted(by: {
      return $0.start < $1.start }).map { return $0.start ..< $0.end
    }
    if ordered.count > 1 {
      for i in (0..<(ordered.count - 1)).reversed() {
        if ordered[i].upperBound == ordered[i+1].lowerBound {
          ordered[i] = ordered[i].lowerBound ..< ordered[i+1].upperBound
          ordered.remove(at: i + 1)
        }
      }
    }
    return ordered
  }

  /// The `extensionRanges` from `normalizedExtensionRanges`, but takes a step
  /// further in that any ranges that do _not_ have any fields inbetween them
  /// are also merged together. These can then be used in context where it is
  /// ok to include field numbers that have to be extension or unknown fields.
  ///
  /// This also uses Range<> since the options that could be on
  /// `extensionRanges` no longer can apply as the things have been merged.
  var _ambitiousExtensionRanges: [Range<Int32>] {
    var merged = self._normalizedExtensionRanges
    if merged.count > 1 {
      var fieldNumbersReversedIterator =
      self.fields.map({ Int($0.number) }).sorted(by: { $0 > $1 }).makeIterator()
      var nextFieldNumber = fieldNumbersReversedIterator.next()
      while nextFieldNumber != nil && merged.last!.lowerBound < nextFieldNumber! {
        nextFieldNumber = fieldNumbersReversedIterator.next()
      }

      for i in (0..<(merged.count - 1)).reversed() {
        if nextFieldNumber == nil || merged[i].lowerBound > nextFieldNumber! {
          // No fields left or range starts after the next field, merge it with
          // the previous one.
          merged[i] = merged[i].lowerBound ..< merged[i+1].upperBound
          merged.remove(at: i + 1)
        } else {
          // can't merge, find the next field number below this range.
          while nextFieldNumber != nil && merged[i].lowerBound < nextFieldNumber! {
            nextFieldNumber = fieldNumbersReversedIterator.next()
          }
        }
      }
    }
    return merged
  }
}

extension FieldDescriptor {
  func swiftType(namer: SwiftProtobufNamer) -> String {
    if case (let keyField, let valueField)? = messageType?.mapKeyAndValue {
      let keyType = keyField.swiftType(namer: namer)
      let valueType = valueField.swiftType(namer: namer)
      return "Dictionary<" + keyType + "," + valueType + ">"
    }

    let result: String
    switch type {
    case .double: result = "Double"
    case .float: result = "Float"
    case .int64: result = "Int64"
    case .uint64: result = "UInt64"
    case .int32: result = "Int32"
    case .fixed64: result = "UInt64"
    case .fixed32: result = "UInt32"
    case .bool: result = "Bool"
    case .string: result = "String"
    case .group: result = namer.fullName(message: messageType!)
    case .message: result = namer.fullName(message: messageType!)
    case .bytes: result = "Data"
    case .uint32: result = "UInt32"
    case .enum: result = namer.fullName(enum: enumType!)
    case .sfixed32: result = "Int32"
    case .sfixed64: result = "Int64"
    case .sint32: result = "Int32"
    case .sint64: result = "Int64"
    }

    if label == .repeated {
      return "[\(result)]"
    }
    return result
  }

  func swiftStorageType(namer: SwiftProtobufNamer) -> String {
    let swiftType = self.swiftType(namer: namer)
    switch label {
    case .repeated:
      return swiftType
    case .optional, .required:
      guard realContainingOneof == nil else {
        return swiftType
      }
      if hasPresence {
        return "\(swiftType)?"
      } else {
        return swiftType
      }
    }
  }

  var protoGenericType: String {
    precondition(!isMap)

    switch type {
    case .double: return "Double"
    case .float: return "Float"
    case .int64: return "Int64"
    case .uint64: return "UInt64"
    case .int32: return "Int32"
    case .fixed64: return "Fixed64"
    case .fixed32: return "Fixed32"
    case .bool: return "Bool"
    case .string: return "String"
    case .group: return "Group"
    case .message: return "Message"
    case .bytes: return "Bytes"
    case .uint32: return "UInt32"
    case .enum: return "Enum"
    case .sfixed32: return "SFixed32"
    case .sfixed64: return "SFixed64"
    case .sint32: return "SInt32"
    case .sint64: return "SInt64"
    }
  }

  func swiftDefaultValue(namer: SwiftProtobufNamer) -> String {
    if isMap {
      return "[:]"
    }
    if label == .repeated {
      return "[]"
    }

    if let defaultValue = defaultValue {
      switch type {
      case .double:
        switch defaultValue {
        case "inf": return "Double.infinity"
        case "-inf": return "-Double.infinity"
        case "nan": return "Double.nan"
        case "-nan": return "Double.nan"
        default: return defaultValue
        }
      case .float:
        switch defaultValue {
        case "inf": return "Float.infinity"
        case "-inf": return "-Float.infinity"
        case "nan": return "Float.nan"
        case "-nan": return "Float.nan"
        default: return defaultValue
        }
      case .string:
        return stringToEscapedStringLiteral(defaultValue)
      case .bytes:
        return escapedToDataLiteral(defaultValue)
      case .enum:
        let enumValue = enumType!.value(named: defaultValue)!
        return namer.dottedRelativeName(enumValue: enumValue)
      default:
        return defaultValue
      }
    }

    switch type {
    case .bool: return "false"
    case .string: return "String()"
    case .bytes: return "Data()"
    case .group, .message:
      return namer.fullName(message: messageType!) + "()"
    case .enum:
      return namer.dottedRelativeName(enumValue: enumType!.values.first!)
    default:
      return "0"
    }
  }

  /// Calculates the traits type used for maps and extensions, they
  /// are used in decoding and visiting.
  func traitsType(namer: SwiftProtobufNamer) -> String {
    if case (let keyField, let valueField)? = messageType?.mapKeyAndValue {
      let keyTraits = keyField.traitsType(namer: namer)
      let valueTraits = valueField.traitsType(namer: namer)
      switch valueField.type {
      case .message:  // Map's can't have a group as the value
        return "\(namer.swiftProtobufModulePrefix)_ProtobufMessageMap<\(keyTraits),\(valueTraits)>"
      case .enum:
        return "\(namer.swiftProtobufModulePrefix)_ProtobufEnumMap<\(keyTraits),\(valueTraits)>"
      default:
        return "\(namer.swiftProtobufModulePrefix)_ProtobufMap<\(keyTraits),\(valueTraits)>"
      }
    }
    switch type {
    case .double: return "\(namer.swiftProtobufModulePrefix)ProtobufDouble"
    case .float: return "\(namer.swiftProtobufModulePrefix)ProtobufFloat"
    case .int64: return "\(namer.swiftProtobufModulePrefix)ProtobufInt64"
    case .uint64: return "\(namer.swiftProtobufModulePrefix)ProtobufUInt64"
    case .int32: return "\(namer.swiftProtobufModulePrefix)ProtobufInt32"
    case .fixed64: return "\(namer.swiftProtobufModulePrefix)ProtobufFixed64"
    case .fixed32: return "\(namer.swiftProtobufModulePrefix)ProtobufFixed32"
    case .bool: return "\(namer.swiftProtobufModulePrefix)ProtobufBool"
    case .string: return "\(namer.swiftProtobufModulePrefix)ProtobufString"
    case .group, .message: return namer.fullName(message: messageType!)
    case .bytes: return "\(namer.swiftProtobufModulePrefix)ProtobufBytes"
    case .uint32: return "\(namer.swiftProtobufModulePrefix)ProtobufUInt32"
    case .enum: return namer.fullName(enum: enumType!)
    case .sfixed32: return "\(namer.swiftProtobufModulePrefix)ProtobufSFixed32"
    case .sfixed64: return "\(namer.swiftProtobufModulePrefix)ProtobufSFixed64"
    case .sint32: return "\(namer.swiftProtobufModulePrefix)ProtobufSInt32"
    case .sint64: return "\(namer.swiftProtobufModulePrefix)ProtobufSInt64"
    }
  }
}

extension EnumDescriptor {

  func value(named: String) -> EnumValueDescriptor? {
    for v in values {
      if v.name == named {
        return v
      }
    }
    return nil
  }

  /// Helper object that computes the alias relationships of
  /// `EnumValueDescriptor`s for a given `EnumDescriptor`.
  final class ValueAliasInfo {
    /// The `EnumValueDescriptor`s that are not aliases of another value. In
    /// the same order as the values on the `EnumDescriptor`.
    let mainValues : [EnumValueDescriptor]

    /// Find the alias values for the given value.
    ///
    /// - Parameter value: The value descriptor to look up.
    /// - Returns The list of value descriptors that are aliases for this
    ///     value, or `nil` if there are no alias (or if this was an alias).
    func aliases(_ value: EnumValueDescriptor) -> [EnumValueDescriptor]? {
      assert(mainValues.first!.enumType === value.enumType)
      return aliasesMap[value.index]
    }

    /// Find the original for an alias.
    ///
    /// - Parameter value: The value descriptor to look up.
    /// - Returns The original/main value if this was an alias otherwise `nil`.
    func original(of: EnumValueDescriptor) -> EnumValueDescriptor? {
      assert(mainValues.first!.enumType === of.enumType)
      return aliasOfMap[of.index]
    }

    /// Mapping from index of a "main" value to the aliases for it.
    private let aliasesMap: [Int:[EnumValueDescriptor]]

    /// Mapping from value's index the main value if it was an alias.
    private let aliasOfMap: [Int:EnumValueDescriptor]

    /// Initialize the mappings for the given `EnumDescriptor`.
    init(enumDescriptor descriptor: EnumDescriptor) {
      var mainValues = [EnumValueDescriptor]()
      var aliasesMap = [Int:[EnumValueDescriptor]]()
      var aliasOfMap = [Int:EnumValueDescriptor]()

      var firstValues = [Int32:EnumValueDescriptor]()
      for v in descriptor.values {
        if let aliasing = firstValues[v.number] {
          aliasesMap[aliasing.index, default: []].append(v)
          aliasOfMap[v.index] = aliasing
        } else {
          firstValues[v.number] = v
          mainValues.append(v)
        }
      }

      self.mainValues = mainValues
      self.aliasesMap = aliasesMap
      self.aliasOfMap = aliasOfMap
    }
  }

}
