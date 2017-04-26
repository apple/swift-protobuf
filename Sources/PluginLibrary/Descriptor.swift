// Sources/PluginLibrary/Descriptor.swift - Descriptor wrappers
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// This is like Descriptor.{h,cc} in the google/protobuf C++ code, it provides
/// wrappers around the protos to make a more usable object graph for generation
/// and also provides some SwiftProtobuf specific additions that would be useful
/// to anyone generating something that uses SwiftProtobufs (like support the
/// `service` messages).
///
// -----------------------------------------------------------------------------

// NOTES:
// 1. `lazy` and `weak` (or `unowned`) doesn't seem to work, so the impl here
//    can't simply keep the `Resolver` and look things up when first accessed
//    instead `bind()` is used to force those lookups to happen.
// 2. Despite the Swift docs seeming to say `unowned` should work, there are
//    compile errors, `weak` ends up being used even though this code doesn't
//    need the zeroing behaviors.  If it did, things will be a little faster
//    as the tracking for weak references wouldn't be needed.

import Foundation
import SwiftProtobuf

public final class DescriptorSet {
  public let files: [FileDescriptor]
  private let registry = Registry()

  public convenience init(proto: Google_Protobuf_FileDescriptorSet) {
    self.init(protos: proto.file)
  }

  public init(protos: [Google_Protobuf_FileDescriptorProto]) {
    let registry = self.registry
    self.files = protos.map { return FileDescriptor(proto: $0, registry: registry) }
  }

  public func lookupFileDescriptor(protoName name: String) -> FileDescriptor {
    return registry.fileDescriptor(name: name)
  }
  public func lookupDescriptor(protoName name: String) -> Descriptor {
    return registry.descriptor(name: name)
  }
  public func lookupEnumDescriptor(protoName name: String) -> EnumDescriptor {
    return registry.enumDescriptor(name: name)
  }
  public func lookupServiceDescriptor(protoName name: String) -> ServiceDescriptor {
    return registry.serviceDescriptor(name: name)
  }
}

public final class FileDescriptor {
  public let proto: Google_Protobuf_FileDescriptorProto
  public var name: String { return self.proto.name }

  public let enums: [EnumDescriptor]
  public let messages: [Descriptor]
  public let extensions: [FieldDescriptor]
  public let services: [ServiceDescriptor]

  fileprivate init(proto: Google_Protobuf_FileDescriptorProto, registry: Registry) {
    self.proto = proto

    let prefix: String
    let pkg = proto.package
    if pkg.isEmpty {
      prefix = ""
    } else {
      prefix = "." + pkg
    }
    self.enums = proto.enumType.map {
      return EnumDescriptor(proto: $0, registry: registry, protoNamePrefix: prefix)
    }
    self.messages = proto.messageType.map {
      return Descriptor(proto: $0, registry: registry, protoNamePrefix: prefix)
    }
    self.extensions = proto.extension_p.map {
      return FieldDescriptor(proto: $0, registry: registry, isExtension: true)
    }
    self.services = proto.service.map {
      return ServiceDescriptor(proto: $0, registry: registry, protoNamePrefix: prefix)
    }

    // Done initializing, register ourselves.
    registry.register(file: self)

    // descriptor.proto documents the files will be in deps order. That means we
    // any external reference will have been in the previous files in the set.
    self.enums.forEach { $0.bind(file: self, registry: registry, containingType: nil) }
    self.messages.forEach { $0.bind(file: self, registry: registry, containingType: nil) }
    self.extensions.forEach { $0.bind(file: self, registry: registry, containingType: nil) }
    self.services.forEach { $0.bind(file: self, registry: registry) }
  }

}

public final class Descriptor {
  public let proto: Google_Protobuf_DescriptorProto
  public let protoName: String
  public private(set) weak var file: FileDescriptor!
  public private(set) weak var containingType: Descriptor?

  public let enums: [EnumDescriptor]
  public let messages: [Descriptor]
  public let fields: [FieldDescriptor]
  public let oneofs: [OneofDescriptor]
  public let extensions: [FieldDescriptor]

  fileprivate init(proto: Google_Protobuf_DescriptorProto,
                   registry: Registry,
                   protoNamePrefix prefix: String) {
    self.proto = proto
    let protoName = "\(prefix).\(proto.name)"
    self.protoName = protoName

    self.enums = proto.enumType.map {
      return EnumDescriptor(proto: $0, registry: registry, protoNamePrefix: protoName)
    }
    self.messages = proto.nestedType.map {
      return Descriptor(proto: $0, registry: registry, protoNamePrefix: protoName)
    }
    self.fields = proto.field.map {
      return FieldDescriptor(proto: $0, registry: registry)
    }
    var i: Int32 = 0
    var oneofs = [OneofDescriptor]()
    for o in proto.oneofDecl {
      let oneofFields = self.fields.filter { $0.oneofIndex == i }
      oneofs.append(OneofDescriptor(proto: o, registry: registry, fields: oneofFields))
      i += 1
    }
    self.oneofs = oneofs
    self.extensions = proto.extension_p.map {
      return FieldDescriptor(proto: $0, registry: registry, isExtension: true)
    }

    // Done initializing, register ourselves.
    registry.register(message: self)
  }

  fileprivate func bind(file: FileDescriptor, registry: Registry, containingType: Descriptor?) {
    self.file = file
    self.containingType = containingType
    self.enums.forEach { $0.bind(file: file, registry: registry, containingType: self) }
    self.messages.forEach { $0.bind(file: file, registry: registry, containingType: self) }
    self.fields.forEach { $0.bind(file: file, registry: registry, containingType: self) }
    self.oneofs.forEach { $0.bind(registry: registry, containingType: self) }
    self.extensions.forEach { $0.bind(file: file, registry: registry, containingType: self) }
  }
}

public final class EnumDescriptor {
  public let proto: Google_Protobuf_EnumDescriptorProto
  public let protoName: String
  public private(set) weak var file: FileDescriptor!
  public private(set) weak var containingType: Descriptor?

  fileprivate init(proto: Google_Protobuf_EnumDescriptorProto,
                   registry: Registry,
                   protoNamePrefix prefix: String) {
    self.proto = proto
    self.protoName = "\(prefix).\(proto.name)"

    // Done initializing, register ourselves.
    registry.register(enum: self)
  }

  fileprivate func bind(file: FileDescriptor, registry: Registry, containingType: Descriptor?) {
    self.file = file
    self.containingType = containingType
  }
}

public final class OneofDescriptor {
  public let proto: Google_Protobuf_OneofDescriptorProto
  public private(set) weak var containingType: Descriptor!

  public var name: String { return proto.name }

  public let fields: [FieldDescriptor]

  fileprivate init(proto: Google_Protobuf_OneofDescriptorProto,
                   registry: Registry,
                   fields: [FieldDescriptor]) {
    self.proto = proto
    self.fields = fields
  }

  fileprivate func bind(registry: Registry, containingType: Descriptor) {
    self.containingType = containingType
  }
}

public final class FieldDescriptor {
  public let proto: Google_Protobuf_FieldDescriptorProto
  public private(set) weak var file: FileDescriptor!
  /// The Descriptor of the message which this is a field of.  For extensions,
  /// this is the extended type.
  public private(set) weak var containingType: Descriptor!

  public var name: String { return proto.name }
  public var number: Int32 { return proto.number }
  public var label: Google_Protobuf_FieldDescriptorProto.Label { return proto.label }
  public var type: Google_Protobuf_FieldDescriptorProto.TypeEnum { return proto.type }

  /// If this is an extension field.
  public let isExtension: Bool
  /// Extensions can be declared within the scope of another message. If this
  /// is an extension field, then this will be the scope it was declared in
  /// nil if was declared at a global scope.
  public private(set) weak var extensionScope: Descriptor?

  /// The index in a oneof this field is in.
  public var oneofIndex: Int32? {
    if proto.hasOneofIndex {
      return proto.oneofIndex
    }
    return nil
  }
  /// The oneof this field is a member of.
  public private(set) weak var oneof: OneofDescriptor?

  /// When this is a message field, the message's desciptor.
  public private(set) weak var messageType: Descriptor!
  /// When this is a enum field, the enum's desciptor.
  public private(set) weak var enumType: EnumDescriptor!

  fileprivate init(proto: Google_Protobuf_FieldDescriptorProto,
                   registry: Registry,
                   isExtension: Bool = false) {
    self.proto = proto
    self.isExtension = isExtension
  }

  fileprivate func bind(file: FileDescriptor, registry: Registry, containingType: Descriptor?) {
    self.file = file

    assert(isExtension == !proto.extendee.isEmpty)
    if isExtension {
      extensionScope = containingType
      self.containingType = registry.descriptor(name: proto.extendee)
    } else {
      self.containingType = containingType
    }

    switch type {
    case .message:
      messageType = registry.descriptor(name: proto.typeName)
    case .enum:
      enumType = registry.enumDescriptor(name: proto.typeName)
    default:
      break
    }

    if let oneofIndex = oneofIndex {
      oneof = containingType?.oneofs[Int(oneofIndex)]
    }
  }
}

public final class ServiceDescriptor {
  public let proto: Google_Protobuf_ServiceDescriptorProto
  public let protoName: String
  public private(set) weak var file: FileDescriptor!

  public let methods: [MethodDescriptor]

  fileprivate init(proto: Google_Protobuf_ServiceDescriptorProto,
                   registry: Registry,
                   protoNamePrefix prefix: String) {
    self.proto = proto
    let protoName = "\(prefix).\(proto.name)"
    self.protoName = protoName

    self.methods = proto.method.map {
      return MethodDescriptor(proto: $0, registry: registry)
    }

    // Done initializing, register ourselves.
    registry.register(service: self)
  }

  fileprivate func bind(file: FileDescriptor, registry: Registry) {
    self.file = file
    methods.forEach { $0.bind(service: self, registry: registry) }
  }
}

public final class MethodDescriptor {
  public let proto: Google_Protobuf_MethodDescriptorProto

  public var name: String { return proto.name }

  public private(set) weak var service: ServiceDescriptor!
  public private(set) var inputType: Descriptor!
  public private(set) var outputType: Descriptor!

  fileprivate init(proto: Google_Protobuf_MethodDescriptorProto,
                   registry: Registry) {
    self.proto = proto
  }

  fileprivate func bind(service: ServiceDescriptor, registry: Registry) {
    self.service = service
    inputType = registry.descriptor(name: proto.inputType)
    outputType = registry.descriptor(name: proto.outputType)
  }

}

/// Helper used under the hood to build the mapping tables and look things up.
fileprivate final class Registry {
  private var fileMap = [String:FileDescriptor]()
  private var messageMap = [String:Descriptor]()
  private var enumMap = [String:EnumDescriptor]()
  private var serviceMap = [String:ServiceDescriptor]()

  init() {}

  func register(file: FileDescriptor) {
    fileMap[file.name] = file
  }
  func register(message: Descriptor) {
    messageMap[message.protoName] = message
  }
  func register(enum e: EnumDescriptor) {
    enumMap[e.protoName] = e
  }
  func register(service: ServiceDescriptor) {
    serviceMap[service.protoName] = service
  }

  // These are forced unwraps as the FileDescriptorSet should always be valid from protoc.
  func fileDescriptor(name: String) -> FileDescriptor {
    return fileMap[name]!
  }
  func descriptor(name: String) -> Descriptor {
    return messageMap[name]!
  }
  func enumDescriptor(name: String) -> EnumDescriptor {
    return enumMap[name]!
  }
  func serviceDescriptor(name: String) -> ServiceDescriptor {
    return serviceMap[name]!
  }
}
