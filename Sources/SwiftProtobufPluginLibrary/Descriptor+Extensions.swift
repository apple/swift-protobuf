// Sources/SwiftProtobufPluginLibrary/Descriptor+Extensions.swift - Additions to Descriptor
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------

import Foundation
import SwiftProtobuf

extension FileDescriptor: ProvidesSourceCodeLocation {
  public var sourceCodeInfoLocation: Google_Protobuf_SourceCodeInfo.Location? {
    // google/protobuf's descriptor.cc says it should be an empty path.
    return sourceCodeInfoLocation(path: IndexPath())
  }
}

extension Descriptor: ProvidesLocationPath, ProvidesSourceCodeLocation, TypeOrFileProvidesDeprecationComment {
  public func getLocationPath(path: inout IndexPath) {
    if let containingType = containingType {
      containingType.getLocationPath(path: &path)
      path.append(Google_Protobuf_DescriptorProto.FieldNumbers.nestedType)
    } else {
      path.append(Google_Protobuf_FileDescriptorProto.FieldNumbers.messageType)
    }
    path.append(index)
  }

  public var typeName: String { "message" }
  public var isDeprecated: Bool { options.deprecated }
}

extension Descriptor.ExtensionRange: ProvidesLocationPath, ProvidesSourceCodeLocation {
  public func getLocationPath(path: inout IndexPath) {
    containingType.getLocationPath(path: &path)
    path.append(Google_Protobuf_DescriptorProto.FieldNumbers.extensionRange)
    path.append(index)
  }
}

extension EnumDescriptor: ProvidesLocationPath, ProvidesSourceCodeLocation, TypeOrFileProvidesDeprecationComment {
  public func getLocationPath(path: inout IndexPath) {
    if let containingType = containingType {
      containingType.getLocationPath(path: &path)
      path.append(Google_Protobuf_DescriptorProto.FieldNumbers.enumType)
    } else {
      path.append(Google_Protobuf_FileDescriptorProto.FieldNumbers.enumType)
    }
    path.append(index)
  }

  public var typeName: String { "enum" }
  public var isDeprecated: Bool { options.deprecated }
}

extension EnumValueDescriptor: ProvidesLocationPath, ProvidesSourceCodeLocation, SimpleProvidesDeprecationComment {
  public func getLocationPath(path: inout IndexPath) {
    enumType.getLocationPath(path: &path)
    path.append(Google_Protobuf_EnumDescriptorProto.FieldNumbers.value)
    path.append(index)
  }

  public var typeName: String { "enum value" }
  public var isDeprecated: Bool { options.deprecated }
}

extension OneofDescriptor: ProvidesLocationPath, ProvidesSourceCodeLocation {
  public func getLocationPath(path: inout IndexPath) {
    containingType.getLocationPath(path: &path)
    path.append(Google_Protobuf_DescriptorProto.FieldNumbers.oneofDecl)
    path.append(index)
  }
}

extension FieldDescriptor: ProvidesLocationPath, ProvidesSourceCodeLocation, ProvidesDeprecationComment {
  public func getLocationPath(path: inout IndexPath) {
    if isExtension {
      if let extensionScope = extensionScope {
        extensionScope.getLocationPath(path: &path)
        path.append(Google_Protobuf_DescriptorProto.FieldNumbers.extension)
      } else {
        path.append(Google_Protobuf_FileDescriptorProto.FieldNumbers.extension)
      }
    } else {
      containingType.getLocationPath(path: &path)
      path.append(Google_Protobuf_DescriptorProto.FieldNumbers.field)
    }
    path.append(index)
  }

  public func deprecationComment(commentPrefix: String) -> String {
    // FieldDesciptor can be an extension field or a normal field, so it needs
    // a custom imply to only look at the file for extentsion fields.
    if options.deprecated {
      return "\(commentPrefix) NOTE: This \(isExtension ? "extension field" : "field") was marked as deprecated in the .proto file.\n"
    }
    if isExtension && file.options.deprecated {
      return "\(commentPrefix) NOTE: The whole .proto file that defined this extension field was marked as deprecated.\n"
    }
    return String()
  }

  /// Returns true if the type can be used for a Packed field.
  static func isPackable(type: Google_Protobuf_FieldDescriptorProto.TypeEnum) -> Bool {
    // This logic comes from the C++ FieldDescriptor::IsTypePackable() impl.
    switch type {
    case .string, .group, .message, .bytes:
      return false
    default:
      return true
    }
  }

  /// Helper to return the name to as the "base" for naming of generated fields.
  ///
  /// Groups use the underlying message's name. The way groups are declared in
  /// proto files, the filed names is derived by lowercasing the Group's name,
  /// so there are no underscores, etc. to rebuild a camel case name from.
  var namingBase: String {
    return internal_isGroupLike ? messageType!.name : name
  }

  /// Helper to see if this is "group-like". Edition 2024 will likely provide
  /// a new feature to better deal with this. See upsteam protobuf for more
  /// details on the problem.
  ///
  ///  This models upstream internal::cpp::IsGroupLike().
  ///
  ///  TODO(thomasvl): make this `package` instead of `public` and drop the
  ///  "internal" part from the name when 5.9 is the baseline.
  public var internal_isGroupLike: Bool {
    guard type == .group else {
      return false
    }
    // `messageType` can't realy be nil once we know it's a group.
    let messageType = messageType!

    // The original proto2 syntax concept of a group always has a field name
    // that is the exact lowercasing of the message name.
    guard name == messageType.name.lowercased() else {
      return false;
    }

    // The message defined by a group is at the same scope as the field. So...
    if isExtension {
      if extensionScope == nil {
        // Top level extension, so the message made by the group has to be the
        // same file and also a type level type.
        return messageType.file === file && messageType.containingType == nil
      } else {
        // Extension field was scoped to a message, so the group will be also
        // nested under that same message.
        return messageType.containingType === extensionScope
      }
    } else {
      // A regular message field, the message made by the group has to be
      // nested under this same message.
      return messageType.containingType === containingType
    }
  }
}

extension ServiceDescriptor: ProvidesLocationPath, ProvidesSourceCodeLocation, TypeOrFileProvidesDeprecationComment {
  public func getLocationPath(path: inout IndexPath) {
    path.append(Google_Protobuf_FileDescriptorProto.FieldNumbers.service)
    path.append(index)
  }

  public var typeName: String { "service" }
  public var isDeprecated: Bool { options.deprecated }
}

extension MethodDescriptor: ProvidesLocationPath, ProvidesSourceCodeLocation, SimpleProvidesDeprecationComment {
  public func getLocationPath(path: inout IndexPath) {
    service.getLocationPath(path: &path)
    path.append(Google_Protobuf_ServiceDescriptorProto.FieldNumbers.method)
    path.append(index)
  }

  public var typeName: String { "method" }
  public var isDeprecated: Bool { options.deprecated }
}
