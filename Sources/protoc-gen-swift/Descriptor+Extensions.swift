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
  /// True if this file should perserve unknown enums within the enum.
  var hasUnknownEnumPreservingSemantics: Bool {
    return syntax == .proto3
  }

  var isBundledProto: Bool {
    return SwiftProtobufInfo.isBundledProto(file: self)
  }
}

extension Descriptor {
  /// Returns true if the message should use the message set wireformat.
  var useMessageSetWireFormat: Bool { return options.messageSetWireFormat }

  /// Returns True if this message recurisvely contains a required field.
  /// This is a helper for generating isInitialized methods.
  ///
  /// The logic for this check comes from google/protobuf; the C++ and Java
  /// generators specificly.
  func containsRequiredFields() -> Bool {
    var alreadySeen = Set<String>()

    func helper(_ descriptor: Descriptor) -> Bool {
      if alreadySeen.contains(descriptor.fullName) {
        // First required thing found causes this to return true, so one can
        // assume if it is already visited and and wasn't cached, it is part
        // of a recursive cycle, so return false without caching to allow
        // the evalutation to continue on other fields of the message.
        return false
      }
      alreadySeen.insert(descriptor.fullName)

      // If it can support extensions, then return true as an extension could
      // have a required field.
      if !descriptor.extensionRanges.isEmpty {
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
  /// contiguious (i.e. - [(21,30),(10,20)] -> [(10,30)])
  ///
  /// This also uses Range<> since the options that could be on
  /// `extensionRanges` no longer can apply as the things have been merged.
  var normalizedExtensionRanges: [Range<Int32>] {
    var ordered: [Range<Int32>] = self.extensionRanges.sorted(by: {
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
  var ambitiousExtensionRanges: [Range<Int32>] {
    var merged = self.normalizedExtensionRanges
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
        default: return defaultValue
        }
      case .float:
        switch defaultValue {
        case "inf": return "Float.infinity"
        case "-inf": return "-Float.infinity"
        case "nan": return "Float.nan"
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
        return "\(namer.swiftProtobufModuleName)._ProtobufMessageMap<\(keyTraits),\(valueTraits)>"
      case .enum:
        return "\(namer.swiftProtobufModuleName)._ProtobufEnumMap<\(keyTraits),\(valueTraits)>"
      default:
        return "\(namer.swiftProtobufModuleName)._ProtobufMap<\(keyTraits),\(valueTraits)>"
      }
    }
    switch type {
    case .double: return "\(namer.swiftProtobufModuleName).ProtobufDouble"
    case .float: return "\(namer.swiftProtobufModuleName).ProtobufFloat"
    case .int64: return "\(namer.swiftProtobufModuleName).ProtobufInt64"
    case .uint64: return "\(namer.swiftProtobufModuleName).ProtobufUInt64"
    case .int32: return "\(namer.swiftProtobufModuleName).ProtobufInt32"
    case .fixed64: return "\(namer.swiftProtobufModuleName).ProtobufFixed64"
    case .fixed32: return "\(namer.swiftProtobufModuleName).ProtobufFixed32"
    case .bool: return "\(namer.swiftProtobufModuleName).ProtobufBool"
    case .string: return "\(namer.swiftProtobufModuleName).ProtobufString"
    case .group, .message: return namer.fullName(message: messageType!)
    case .bytes: return "\(namer.swiftProtobufModuleName).ProtobufBytes"
    case .uint32: return "\(namer.swiftProtobufModuleName).ProtobufUInt32"
    case .enum: return namer.fullName(enum: enumType!)
    case .sfixed32: return "\(namer.swiftProtobufModuleName).ProtobufSFixed32"
    case .sfixed64: return "\(namer.swiftProtobufModuleName).ProtobufSFixed64"
    case .sint32: return "\(namer.swiftProtobufModuleName).ProtobufSInt32"
    case .sint64: return "\(namer.swiftProtobufModuleName).ProtobufSInt64"
    }
  }
}

extension EnumDescriptor {

  // True if this enum should perserve unknown enums within the enum.
  var hasUnknownPreservingSemantics: Bool {
    return file.hasUnknownEnumPreservingSemantics
  }

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
