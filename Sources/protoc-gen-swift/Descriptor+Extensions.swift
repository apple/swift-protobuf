// Sources/protoc-gen-swift/Descriptor+Extensions.swift - Additions to Descriptors
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------

import PluginLibrary

extension FileDescriptor {
  // True if this file should perserve unknown enums within the enum.
  var hasUnknownEnumPreservingSemantics: Bool {
    return syntax == .proto3
  }
}

extension Descriptor {
  /// Returns True if this message recurisvely contains a required field.
  /// This is a helper for generating isInitialized methods.
  ///
  /// The logic for this check comes from google/protobuf; the C++ and Java
  /// generators specificly.
  func hasRequiredFields() -> Bool {
    var alreadySeen = Set<String>()

    func hasRequiredFieldsInner(_ descriptor: Descriptor) -> Bool {
      if alreadySeen.contains(descriptor.fullName) {
        // First required thing found causes this to return true, so one can
        // assume if it is already visited, it didn't have required fields.
        return false
      }
      alreadySeen.insert(descriptor.fullName)

      // If it can support extensions, then return true as the extension could
      // have a required field.
      if !descriptor.extensionRanges.isEmpty {
        return true
      }

      for f in descriptor.fields {
        if f.label == .required {
          return true
        }
        switch f.type {
        case .group, .message:
          if hasRequiredFieldsInner(f.messageType) {
            return true
          }
        default:
          break
        }
      }

      return false
    }

    return hasRequiredFieldsInner(self)
  }
}

extension FieldDescriptor {

  func swiftType(namer: SwiftProtobufNamer) -> String {
    if isMap {
      let mapDescriptor: Descriptor = messageType
      let keyField = mapDescriptor.fields[0]
      let keyType = keyField.swiftType(namer: namer)
      let valueField = mapDescriptor.fields[1]
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
    case .group: result = namer.fullName(message: messageType)
    case .message: result = namer.fullName(message: messageType)
    case .bytes: result = "Data"
    case .uint32: result = "UInt32"
    case .enum: result = namer.fullName(enum: enumType)
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

  func swiftDefaultValue(namer: SwiftProtobufNamer) -> String {
    if isMap {
      return "[:]"
    }
    if label == .repeated {
      return "[]"
    }

    if let defaultValue = explicitDefaultValue {
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
        let enumValue = enumType.value(named: defaultValue)!
        // TODO(thomasvl): Can't this be short name?
        return namer.fullName(enumValue: enumValue)
      default:
        return defaultValue
      }
    }

    switch type {
    case .bool: return "false"
    case .string: return "String()"
    case .bytes: return "SwiftProtobuf.Internal.emptyData"
    case .group, .message:
      return namer.fullName(message: messageType) + "()"
    case .enum:
      // TODO(thomasvl): Can't this be short name?
      return namer.fullName(enumValue: enumType.defaultValue)
    default:
      return "0"
    }
  }

  /// Calculates the traits type used for maps and extensions, they
  /// are used in decoding and visiting.
  func traitsType(namer: SwiftProtobufNamer) -> String {
    if isMap {
      let mapDescriptor: Descriptor = messageType
      let keyField = mapDescriptor.fields[0]
      let keyTraits = keyField.traitsType(namer: namer)
      let valueField = mapDescriptor.fields[1]
      let valueTraits = valueField.traitsType(namer: namer)
      switch valueField.type {
      case .message:  // Map's can't have a group as the value
        return "SwiftProtobuf._ProtobufMessageMap<\(keyTraits),\(valueTraits)>"
      case .enum:
        return "SwiftProtobuf._ProtobufEnumMap<\(keyTraits),\(valueTraits)>"
      default:
        return "SwiftProtobuf._ProtobufMap<\(keyTraits),\(valueTraits)>"
      }
    }
    switch type {
    case .double: return "SwiftProtobuf.ProtobufDouble"
    case .float: return "SwiftProtobuf.ProtobufFloat"
    case .int64: return "SwiftProtobuf.ProtobufInt64"
    case .uint64: return "SwiftProtobuf.ProtobufUInt64"
    case .int32: return "SwiftProtobuf.ProtobufInt32"
    case .fixed64: return "SwiftProtobuf.ProtobufFixed64"
    case .fixed32: return "SwiftProtobuf.ProtobufFixed32"
    case .bool: return "SwiftProtobuf.ProtobufBool"
    case .string: return "SwiftProtobuf.ProtobufString"
    case .group, .message: return namer.fullName(message: messageType)
    case .bytes: return "SwiftProtobuf.ProtobufBytes"
    case .uint32: return "SwiftProtobuf.ProtobufUInt32"
    case .enum: return namer.fullName(enum: enumType)
    case .sfixed32: return "SwiftProtobuf.ProtobufSFixed32"
    case .sfixed64: return "SwiftProtobuf.ProtobufSFixed64"
    case .sint32: return "SwiftProtobuf.ProtobufSInt32"
    case .sint64: return "SwiftProtobuf.ProtobufSInt64"
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
}
