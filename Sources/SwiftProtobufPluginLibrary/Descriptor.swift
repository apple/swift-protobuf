// Sources/SwiftProtobufPluginLibrary/Descriptor.swift - Descriptor wrappers
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// This is like Descriptor.{h,cc} in the google/protobuf C++ code, it provides
/// wrappers around the protos to make a more usable object graph for generation
/// and also provides some SwiftProtobuf specific additions that would be useful
/// to anyone generating something that uses SwiftProtobufs (like support the
/// `service` messages). It is *not* the intent for these to eventually be used
/// as part of some reflection or generate message api.
///
/// Unlike the C++ Descriptors, the intent is for these to *only* be used within
/// the context of a protoc plugin, meaning, the
/// `Google_Protobuf_FileDescriptorSet` used to create these will be *always*
/// be well formed by protoc and the guarentees it provides.
///
// -----------------------------------------------------------------------------

import Foundation
import SwiftProtobuf

/// The front interface for building/getting descriptors. The objects
/// vended from the here are different from the raw
/// `Google_Protobuf_*Proto` types in that they have all the cross object
/// references resolved or wired up, making for an easier to use object
/// model.
///
/// This is like the `DescriptorPool` class in the C++ protobuf library.
public final class DescriptorSet {
  /// The list of `FileDescriptor`s in this set.
  public let files: [FileDescriptor]
  private let registry = Registry()

  // Consturct out of a `Google_Protobuf_FileDescriptorSet` likely
  // created by protoc.
  public convenience init(proto: Google_Protobuf_FileDescriptorSet) {
    self.init(protos: proto.file)
  }

  /// Consturct out of a ordered list of
  /// `Google_Protobuf_FileDescriptorProto`s likely created by protoc. Since
  /// .proto files can import other .proto files, the imports have to be
  /// listed before the things that use them so the graph can be
  /// reconstructed.
  public init(protos: [Google_Protobuf_FileDescriptorProto]) {
    let registry = self.registry
    self.files = protos.map { return FileDescriptor(proto: $0, registry: registry) }
  }

  /// Lookup a specific file. The names for files are what was captured in
  /// the `Google_Protobuf_FileDescriptorProto` when it was created, protoc
  /// uses the path name for how the file was found.
  ///
  /// This is a legacy api since it requires the file to be found or it aborts.
  /// Mainly kept for grpc-swift compatibility.
  @available(*, deprecated, renamed: "fileDescriptor(named:)")
  public func lookupFileDescriptor(protoName name: String) -> FileDescriptor {
    return registry.fileDescriptor(named: name)!
  }

  /// Find a specific file. The names for files are what was captured in
  /// the `Google_Protobuf_FileDescriptorProto` when it was created, protoc
  /// uses the path name for how the file was found.
  public func fileDescriptor(named name: String) -> FileDescriptor? {
    return registry.fileDescriptor(named: name)
  }
  /// Find the `Descriptor` for a named proto message.
  public func descriptor(named fullName: String) -> Descriptor? {
    return registry.descriptor(named: ".\(fullName)")
  }
  /// Find the `EnumDescriptor` for a named proto enum.
  public func enumDescriptor(named fullName: String) -> EnumDescriptor? {
    return registry.enumDescriptor(named: ".\(fullName)")
  }
  /// Find the `ServiceDescriptor` for a named proto service.
  public func serviceDescriptor(named fullName: String) -> ServiceDescriptor? {
    return registry.serviceDescriptor(named: ".\(fullName)")
  }
}

/// Models a .proto file. `FileDescriptor`s are not directly created,
/// instead they are constructed/fetched via the `DescriptorSet` or
/// they are directly accessed via a `file` property on all the other
/// types of descriptors.
public final class FileDescriptor {
  /// Syntax of this file.
  public enum Syntax: RawRepresentable {
    case proto2
    case proto3
    case unknown(String)

    public init?(rawValue: String) {
      switch rawValue {
      case "proto2", "":
        self = .proto2
      case "proto3":
        self = .proto3
      default:
        self = .unknown(rawValue)
      }
    }

    public var rawValue: String {
      switch self {
      case .proto2:
        return "proto2"
      case .proto3:
        return "proto3"
      case .unknown(let value):
        return value
      }
    }

    /// The string form of the syntax.
    public var name: String { return rawValue }
  }

  /// The filename used with protoc.
  public let name: String
  /// The proto package.
  public let package: String

  /// Syntax of this file.
  public let syntax: Syntax

  /// The imports for this file.
  public let dependencies: [FileDescriptor]
  /// The subset of the imports that were declared `public`.
  public let publicDependencies: [FileDescriptor]
  /// The subset of the imports that were declared `weak`.
  public let weakDependencies: [FileDescriptor]

  /// The enum defintions at the file scope level.
  public let enums: [EnumDescriptor]
  /// The message defintions at the file scope level.
  public let messages: [Descriptor]
  /// The extension field defintions at the file scope level.
  public let extensions: [FieldDescriptor]
  /// The service defintions at the file scope level.
  public let services: [ServiceDescriptor]

  /// The `Google_Protobuf_FileOptions` set on this file.
  public let options: Google_Protobuf_FileOptions

  private let sourceCodeInfo: Google_Protobuf_SourceCodeInfo

  fileprivate init(proto: Google_Protobuf_FileDescriptorProto, registry: Registry) {
    self.name = proto.name
    self.package = proto.package
    self.syntax = Syntax(rawValue: proto.syntax)!
    self.options = proto.options

    let protoPackage = proto.package
    self.enums = proto.enumType.enumeratedMap {
      return EnumDescriptor(proto: $1, index: $0, registry: registry, scope: protoPackage)
    }
    self.messages = proto.messageType.enumeratedMap {
      return Descriptor(proto: $1, index: $0, registry: registry, scope: protoPackage)
    }
    self.extensions = proto.extension.enumeratedMap {
      return FieldDescriptor(proto: $1, index: $0, registry: registry, isExtension: true)
    }
    self.services = proto.service.enumeratedMap {
      return ServiceDescriptor(proto: $1, index: $0, registry: registry, scope: protoPackage)
    }

    // The compiler ensures there aren't cycles between a file and dependencies, so
    // this doesn't run the risk of creating any retain cycles that would force these
    // to have to be weak.
    let dependencies = proto.dependency.map { return registry.fileDescriptor(named: $0)! }
    self.dependencies = dependencies
    self.publicDependencies = proto.publicDependency.map { dependencies[Int($0)] }
    self.weakDependencies = proto.weakDependency.map { dependencies[Int($0)] }

    self.sourceCodeInfo = proto.sourceCodeInfo

    // Done initializing, register ourselves.
    registry.register(file: self)

    // descriptor.proto documents the files will be in deps order. That means we
    // any external reference will have been in the previous files in the set.
    self.enums.forEach { $0.bind(file: self, registry: registry, containingType: nil) }
    self.messages.forEach { $0.bind(file: self, registry: registry, containingType: nil) }
    self.extensions.forEach { $0.bind(file: self, registry: registry, containingType: nil) }
    self.services.forEach { $0.bind(file: self, registry: registry) }
  }

  /// Fetch the source information for a give path. For more details on the paths
  /// and what this information is, see `Google_Protobuf_SourceCodeInfo`.
  ///
  /// For simpler access to the comments for give message, fields, enums; see
  /// `Descriptor+Extensions.swift` and the `ProvidesLocationPath` and
  /// `ProvidesSourceCodeLocation` protocols.
  public func sourceCodeInfoLocation(path: IndexPath) -> Google_Protobuf_SourceCodeInfo.Location? {
    guard let location = locationMap[path] else {
      return nil
    }
    return location
  }

  // Lazy so this can be computed on demand, as the imported files won't need
  // comments during generation.
  private lazy var locationMap: [IndexPath:Google_Protobuf_SourceCodeInfo.Location] = {
    var result: [IndexPath:Google_Protobuf_SourceCodeInfo.Location] = [:]
    for loc in sourceCodeInfo.location {
      let intList = loc.path.map { return Int($0) }
      result[IndexPath(indexes: intList)] = loc
    }
    return result
  }()
}

/// Describes a type of protocol message, or a particular group within a
/// message. `Descriptor`s are not directly created, instead they are
/// constructed/fetched via the `DescriptorSet` or they are directly accessed
/// via a `messageType` property on `FieldDescriptor`s, etc.
public final class Descriptor {
  /// The type of this Message.
  public enum WellKnownType: String {
    /// An instance of google.protobuf.DoubleValue.
    case doubleValue = "google.protobuf.DoubleValue"
    /// An instance of google.protobuf.FloatValue.
    case floatValue = "google.protobuf.FloatValue"
    /// An instance of google.protobuf.Int64Value.
    case int64Value = "google.protobuf.Int64Value"
    /// An instance of google.protobuf.UInt64Value.
    case uint64Value = "google.protobuf.UInt64Value"
    /// An instance of google.protobuf.Int32Value.
    case int32Value = "google.protobuf.Int32Value"
    /// An instance of google.protobuf.UInt32Value.
    case uint32Value = "google.protobuf.UInt32Value"
    /// An instance of google.protobuf.StringValue.
    case stringValue = "google.protobuf.StringValue"
    /// An instance of google.protobuf.BytesValue.
    case bytesValue = "google.protobuf.BytesValue"
    /// An instance of google.protobuf.BoolValue.
    case boolValue = "google.protobuf.BoolValue"

    /// An instance of google.protobuf.Any.
    case any = "google.protobuf.Any"
    /// An instance of google.protobuf.FieldMask.
    case fieldMask = "google.protobuf.FieldMask"
    /// An instance of google.protobuf.Duration.
    case duration = "google.protobuf.Duration"
    /// An instance of google.protobuf.Timestamp.
    case timestamp = "google.protobuf.Timestamp"
    /// An instance of google.protobuf.Value.
    case value = "google.protobuf.Value"
    /// An instance of google.protobuf.ListValue.
    case listValue = "google.protobuf.ListValue"
    /// An instance of google.protobuf.Struct.
    case `struct` = "google.protobuf.Struct"
  }

  /// The name of the message type, not including its scope.
  public let name: String
  /// The fully-qualified name of the message type, scope delimited by
  /// periods.  For example, message type "Foo" which is declared in package
  /// "bar" has full name "bar.Foo".  If a type "Baz" is nested within
  /// Foo, Baz's `fullName` is "bar.Foo.Baz".  To get only the part that
  /// comes after the last '.', use name().
  public let fullName: String
  /// Index of this descriptor within the file or containing type's message
  /// type array.
  public let index: Int

  /// The .proto file in which this message type was defined.
  public var file: FileDescriptor { return _file! }
  /// If this Descriptor describes a nested type, this returns the type
  /// in which it is nested.
  public private(set) unowned var containingType: Descriptor?

  /// The `Google_Protobuf_MessageOptions` set on this Message.
  public let options: Google_Protobuf_MessageOptions

  // If this descriptor represents a well known type, which type it is.
  public let wellKnownType: WellKnownType?

  /// The enum defintions under this message.
  public let enums: [EnumDescriptor]
  /// The message defintions under this message. In the C++ Descriptor this
  /// is `nested_type`.
  public let messages: [Descriptor]
  /// The fields of this message.
  public let fields: [FieldDescriptor]
  /// The oneofs in this message. This can include synthetic oneofs.
  public let oneofs: [OneofDescriptor]
  /// Non synthetic oneofs.
  ///
  /// These always come first (enforced by the C++ Descriptor code). So this is always a
  /// leading subset of `oneofs` (or the same if there are no synthetic entries).
  public private(set) lazy var realOneofs: [OneofDescriptor] = {
    // Lazy because `isSynthetic` can't be called until after `bind()`.
    return self.oneofs.filter { !$0.isSynthetic }
  }()
  /// The extension field defintions under this message.
  public let extensions: [FieldDescriptor]

  /// The extension ranges declared for this message. They are returned in
  /// the order they are defined in the .proto file.
  public let extensionRanges: [Google_Protobuf_DescriptorProto.ExtensionRange]

  /// The reserved field number ranges for this message. These are returned
  /// in the order they are defined in the .proto file.
  public let reservedRanges: [Range<Int32>]
  /// The reserved field names for this message. These are returned in the
  /// order they are defined in the .proto file.
  public let reservedNames: [String]

  /// Returns the `FieldDescriptor`s for the "key" and "value" fields. If
  /// this isn't a map entry field, returns nil.
  ///
  /// This is like the C++ Descriptor `map_key()` and `map_value()` methods.
  public var mapKeyAndValue: (key: FieldDescriptor, value: FieldDescriptor)? {
    guard options.mapEntry else { return nil }
    assert(fields.count == 2)
    return (key: fields[0], value: fields[1])
  }

  // Storage for `file`, will be set by bind()
  private unowned var _file: FileDescriptor?

  fileprivate init(proto: Google_Protobuf_DescriptorProto,
                   index: Int,
                   registry: Registry,
                   scope: String) {
    self.name = proto.name
    let fullName = scope.isEmpty ? proto.name : "\(scope).\(proto.name)"
    self.fullName = fullName
    self.index = index
    self.options = proto.options
    self.wellKnownType = WellKnownType(rawValue: fullName)
    self.extensionRanges = proto.extensionRange
    self.reservedRanges = proto.reservedRange.map { return $0.start ..< $0.end }
    self.reservedNames = proto.reservedName

    self.enums = proto.enumType.enumeratedMap {
      return EnumDescriptor(proto: $1, index: $0, registry: registry, scope: fullName)
    }
    self.messages = proto.nestedType.enumeratedMap {
      return Descriptor(proto: $1, index: $0, registry: registry, scope: fullName)
    }
    self.fields = proto.field.enumeratedMap {
      return FieldDescriptor(proto: $1, index: $0, registry: registry)
    }
    self.oneofs = proto.oneofDecl.enumeratedMap {
      return OneofDescriptor(proto: $1, index: $0, registry: registry)
    }
    self.extensions = proto.extension.enumeratedMap {
      return FieldDescriptor(proto: $1, index: $0, registry: registry, isExtension: true)
    }

    // Done initializing, register ourselves.
    registry.register(message: self)
  }

  fileprivate func bind(file: FileDescriptor, registry: Registry, containingType: Descriptor?) {
    _file = file
    self.containingType = containingType
    enums.forEach { $0.bind(file: file, registry: registry, containingType: self) }
    messages.forEach { $0.bind(file: file, registry: registry, containingType: self) }
    fields.forEach { $0.bind(file: file, registry: registry, containingType: self) }
    oneofs.forEach { $0.bind(registry: registry, containingType: self) }
    extensions.forEach { $0.bind(file: file, registry: registry, containingType: self) }

    // Synthetic oneofs come after normal oneofs. The C++ Descriptor enforces this, only
    // here as a secondary validation because other code can rely on it.
    var seenSynthetic = false
    for o in oneofs {
      if o.isSynthetic {
        seenSynthetic = true
      } else {
        assert(!seenSynthetic)
      }
    }
  }
}

/// Describes a type of protocol enum. `EnumDescriptor`s are not directly
/// created, instead they are constructed/fetched via the `DescriptorSet` or
/// they are directly accessed via a `EnumType` property on `FieldDescriptor`s,
/// etc.
public final class EnumDescriptor {
  /// The name of this enum type in the containing scope.
  public let name: String
  /// The fully-qualified name of the enum type, scope delimited by periods.
  public let fullName: String
  /// Index of this enum within the file or containing message's enums.
  public let index: Int

  /// The .proto file in which this message type was defined.
  public var file: FileDescriptor { return _file! }
  /// If this Descriptor describes a nested type, this returns the type
  /// in which it is nested.
  public private(set) unowned var containingType: Descriptor?

  /// The values defined for this enum. Guaranteed (by protoc) to be atleast
  /// one item. These are returned in the order they were defined in the .proto
  /// file.
  public let values: [EnumValueDescriptor]

  /// The `Google_Protobuf_MessageOptions` set on this enum.
  public let options: Google_Protobuf_EnumOptions

  /// The reserved value ranges for this enum. These are returned in the order
  /// they are defined in the .proto file.
  public let reservedRanges: [ClosedRange<Int32>]
  /// The reserved value names for this enum. These are returned in the order
  /// they are defined in the .proto file.
  public let reservedNames: [String]

  // Storage for `file`, will be set by bind()
  private unowned var _file: FileDescriptor?

  fileprivate init(proto: Google_Protobuf_EnumDescriptorProto,
                   index: Int,
                   registry: Registry,
                   scope: String) {
    self.name = proto.name
    self.fullName = scope.isEmpty ? proto.name : "\(scope).\(proto.name)"
    self.index = index
    self.options = proto.options
    self.reservedRanges = proto.reservedRange.map { return $0.start ... $0.end }
    self.reservedNames = proto.reservedName

    self.values = proto.value.enumeratedMap {
      return EnumValueDescriptor(proto: $1, index: $0, scope: scope)
    }

    // Done initializing, register ourselves.
    registry.register(enum: self)

    values.forEach { $0.bind(enumType: self) }
  }

  fileprivate func bind(file: FileDescriptor, registry: Registry, containingType: Descriptor?) {
    _file = file
    self.containingType = containingType
  }
}

/// Describes an individual enum constant of a particular type. To get the
/// `EnumValueDescriptor` for a given enum value, first get the `EnumDescriptor`
/// for its type.
public final class EnumValueDescriptor {
  /// Name of this enum constant.
  public let name: String
  /// The full_name of an enum value is a sibling symbol of the enum type.
  /// e.g. the full name of FieldDescriptorProto::TYPE_INT32 is actually
  /// "google.protobuf.FieldDescriptorProto.TYPE_INT32", NOT
  /// "google.protobuf.FieldDescriptorProto.Type.TYPE_INT32". This is to conform
  /// with C++ scoping rules for enums.
  public let fullName: String
  /// Index within the enums's `EnumDescriptor`.
  public let index: Int
  /// Numeric value of this enum constant.
  public let number: Int32

  /// The .proto file in which this message type was defined.
  public var file: FileDescriptor { return enumType.file }
  /// The type of this value.
  public var enumType: EnumDescriptor { return _enumType! }

  /// The `Google_Protobuf_EnumValueOptions` set on this value.
  public let options: Google_Protobuf_EnumValueOptions

  // Storage for `service`, will be set by bind()
  private unowned var _enumType: EnumDescriptor?

  fileprivate init(proto: Google_Protobuf_EnumValueDescriptorProto,
                   index: Int,
                   scope: String) {
    self.name = proto.name
    self.fullName = scope.isEmpty ? proto.name : "\(scope).\(proto.name)"
    self.index = index
    self.number = proto.number
    self.options = proto.options
  }

  fileprivate func bind(enumType: EnumDescriptor) {
    self._enumType = enumType
  }
}

/// Describes a oneof defined in a message type.
public final class OneofDescriptor {
  /// Name of this oneof.
  public let name: String
  /// Fully-qualified name of the oneof.
  public var fullName: String { return "\(containingType.fullName).\(name)" }
  /// Index of this oneof within the message's oneofs.
  public let index: Int

  /// Returns whether this oneof was inserted by the compiler to wrap a proto3
  /// optional field. If this returns true, code generators should *not* emit it.
  public var isSynthetic: Bool {
    return fields.count == 1 && fields.first!.proto3Optional
  }

  /// The .proto file in which this oneof type was defined.
  public var file: FileDescriptor { return containingType.file }
  /// The Descriptor of the message that defines this oneof.
  public var containingType: Descriptor { return _containingType! }

  /// The `Google_Protobuf_OneofOptions` set on this oneof.
  public let options: Google_Protobuf_OneofOptions

  /// The members of this oneof, in the order in which they were declared in the
  /// .proto file.
  public private(set) lazy var fields: [FieldDescriptor] = {
    let myIndex = Int32(self.index)
    return containingType.fields.filter { $0.oneofIndex == myIndex }
  }()

  // Storage for `containingType`, will be set by bind()
  private unowned var _containingType: Descriptor?

  fileprivate init(proto: Google_Protobuf_OneofDescriptorProto,
                   index: Int,
                   registry: Registry) {
    self.name = proto.name
    self.index = index
    self.options = proto.options
  }

  fileprivate func bind(registry: Registry, containingType: Descriptor) {
    _containingType = containingType
  }
}

/// Describes a single field of a message. To get the descriptor for a given
/// field, first get the `Descriptor` for the message in which it is defined,
/// then find the field. To get a `FieldDescriptor` for an extension, get the
/// `Descriptor` or `FileDescriptor` for its containing scope, find the
/// extension.
public final class FieldDescriptor {
  /// Name of this field within the message.
  public let name: String
  /// Fully-qualified name of the field.
  public var fullName: String {
    // Since the fullName isn't needed on fields that often, compute it on demand.
    guard isExtension else {
      // Normal field on a message.
      return "\(containingType.fullName).\(name)"
    }
    if let extensionScope = extensionScope {
      return "\(extensionScope.fullName).\(name)"
    }
    let package = file.package
    return package.isEmpty ? name : "\(package).\(name)"
  }
  /// JSON name of this field.
  public let jsonName: String

  /// File in which this field was defined.
  public var file: FileDescriptor { return _file! }

  /// If this is an extension field.
  public let isExtension: Bool
  /// The field number.
  public let number: Int32

  /// Valid field numbers are positive integers up to kMaxNumber.
  static let kMaxNumber: Int = (1 << 29) - 1

  /// First field number reserved for the protocol buffer library
  /// implementation. Users may not declare fields that use reserved numbers.
  static let kFirstReservedNumber: Int = 19000
  /// Last field number reserved for the protocol buffer library implementation.
  /// Users may not declare fields that use reserved numbers.
  static let kLastReservedNumber: Int = 19999

  /// Declared type of this field.
  public let type: Google_Protobuf_FieldDescriptorProto.TypeEnum
  /// optional/required/repeated
  public let label: Google_Protobuf_FieldDescriptorProto.Label

  /// Shorthand for `label` == `.required`.
  ///
  /// NOTE: This could also be a map as the are also repeated fields.
  public var isRequired: Bool { return label == .required }
  /// Shorthand for `label` == `.optional`
  public var isOptional: Bool { return label == .optional }
  /// Shorthand for `label` == `.repeated`
  public var isRepeated: Bool { return label == .repeated }

  /// Is this field packable.
  public var isPackable: Bool {
    // This logic comes from the C++ FieldDescriptor::is_packable() impl.
    return label == .repeated && FieldDescriptor.isPackable(type: type)
  }
  /// Should this field be packed format.
  public var isPacked: Bool {
    // This logic comes from the C++ FieldDescriptor::is_packed() impl.
    // NOTE: It does not match what is in the C++ header for is_packed().
    guard isPackable else { return false }
    // The C++ imp also checks if the `options_` are null, but that is only for
    // their placeholder descriptor support, as once the FieldDescriptor is
    // fully wired it gets a default FileOptions instance, rendering nullptr
    // meaningless.
    if file.syntax == .proto2 {
      return options.packed
    } else {
      return !options.hasPacked || options.packed
    }
  }
  /// True if this field is a map.
  public var isMap: Bool {
    // This logic comes from the C++ FieldDescriptor::is_map() impl.
    return type == .message && messageType!.options.mapEntry
  }

  /// Returns true if this field was syntactically written with "optional" in the
  /// .proto file. Excludes singular proto3 fields that do not have a label.
  public var hasOptionalKeyword: Bool {
    // This logic comes from the C++ FieldDescriptor::has_optional_keyword()
    // impl.
    return proto3Optional ||
      (file.syntax == .proto2 && label == .optional && oneofIndex == nil)
  }

  /// Returns true if this field tracks presence, ie. does the field
  /// distinguish between "unset" and "present with default value."
  /// This includes required, optional, and oneof fields. It excludes maps,
  /// repeated fields, and singular proto3 fields without "optional".
  public var hasPresence: Bool {
    // This logic comes from the C++ FieldDescriptor::has_presence() impl.
    guard label != .repeated else { return false }
    switch type {
    case .group, .message:
      // Groups/messages always get field presence.
      return true
    default:
      return file.syntax == .proto2 || oneofIndex != nil
    }
  }

  /// Index of this field within the message's fields, or the file or
  /// extension scope's extensions.
  public let index: Int

  /// The explicitly declared default value for this field.
  ///
  /// This is the *raw* string value from the .proto file that was listed as
  /// the default, it is up to the consumer to convert it correctly for the
  /// type of this field. The C++ FieldDescriptor does offer some apis to
  /// help with that, but at this time, that is not provided here.
  public let defaultValue: String?

  /// The `Descriptor` of the message which this is a field of. For extensions,
  /// this is the extended type.
  public var containingType: Descriptor { return _containingType! }

  /// The oneof this field is a member of.
  public var containingOneof: OneofDescriptor? {
    guard let oneofIndex = oneofIndex else { return nil }
    assert(!isExtension)
    return containingType.oneofs[Int(oneofIndex)]
  }
  /// The non synthetic oneof this field is a member of.
  public var realContainingOneof: OneofDescriptor? {
    guard let oneof = containingOneof, !oneof.isSynthetic else { return nil }
    return oneof
  }
  /// The index in a oneof this field is in.
  public let oneofIndex: Int32?

  /// Extensions can be declared within the scope of another message. If this
  /// is an extension field, then this will be the scope it was declared in
  /// nil if was declared at a global scope.
  public private(set) unowned var extensionScope: Descriptor?

  /// When this is a message/group field, that message's `Desciptor`.
  public private(set) unowned var messageType: Descriptor?
  /// When this is a enum field, that enum's `EnumDesciptor`.
  public private(set) unowned var enumType: EnumDescriptor?

  /// The FieldOptions for this field.
  public var options: Google_Protobuf_FieldOptions

  let proto3Optional: Bool
  // These next two cache values until bind().
  var extendee: String?
  var typeName: String?

  // Storage for `containingType`, will be set by bind()
  private unowned var _containingType: Descriptor?
  // Storage for `file`, will be set by bind()
  private unowned var _file: FileDescriptor?

  fileprivate init(proto: Google_Protobuf_FieldDescriptorProto,
                   index: Int,
                   registry: Registry,
                   isExtension: Bool = false) {
    self.name = proto.name
    self.index = index
    self.defaultValue = proto.hasDefaultValue ? proto.defaultValue : nil
    assert(proto.hasJsonName)  // protoc should always set the name
    self.jsonName = proto.jsonName
    assert(isExtension == !proto.extendee.isEmpty)
    self.isExtension = isExtension
    self.number = proto.number
    self.type = proto.type
    self.label = proto.label
    self.options = proto.options

    if proto.hasOneofIndex {
      assert(!isExtension)
      oneofIndex = proto.oneofIndex
    } else {
      oneofIndex = nil
      // FieldDescriptorProto is used for fields or extensions, generally
      // .proto3Optional only makes sense on fields if it is in a oneof. But
      // It is allowed on extensions. For information on that, see
      // https://github.com/protocolbuffers/protobuf/issues/8234#issuecomment-774224376
      // The C++ Descriptor code encorces the field/oneof part, but nothing
      // is checked on the oneof side.
      assert(!proto.proto3Optional || isExtension)
    }

    self.proto3Optional = proto.proto3Optional
    self.extendee = isExtension ? proto.extendee : nil
    switch type {
    case .group, .message, .enum:
      typeName = proto.typeName
    default:
      typeName = nil
    }
  }

  fileprivate func bind(file: FileDescriptor, registry: Registry, containingType: Descriptor?) {
    _file = file

    if let extendee = extendee {
      assert(isExtension)
      extensionScope = containingType
      _containingType = registry.descriptor(named: extendee)!
    } else {
      _containingType = containingType
    }
    extendee = nil

    if let typeName = typeName {
      if type == .enum {
        enumType = registry.enumDescriptor(named: typeName)!
      } else {
        messageType = registry.descriptor(named: typeName)!
      }
    }
    typeName = nil
  }
}

/// Describes an RPC service.
///
/// SwiftProtobuf does *not* generate anything for these (or methods), but
/// they are here to support things that generate based off RPCs defined in
/// .proto file (gRPC, etc.).
public final class ServiceDescriptor {
  /// The name of the service, not including its containing scope.
  public let name: String
  /// The fully-qualified name of the service, scope delimited by periods.
  public let fullName: String
  /// Index of this service within the file's services.
  public let index: Int

  /// The .proto file in which this service was defined
  public var file: FileDescriptor { return _file! }

  /// Get `Google_Protobuf_ServiceOptions` for this service.
  public let options: Google_Protobuf_ServiceOptions

  /// The methods defined on this service. These are returned in the order they
  /// were defined in the .proto file.
  public let methods: [MethodDescriptor]

  // Storage for `file`, will be set by bind()
  private unowned var _file: FileDescriptor?

  fileprivate init(proto: Google_Protobuf_ServiceDescriptorProto,
                   index: Int,
                   registry: Registry,
                   scope: String) {
    self.name = proto.name
    self.fullName = scope.isEmpty ? proto.name : "\(scope).\(proto.name)"
    self.index = index
    self.options = proto.options

    self.methods = proto.method.enumeratedMap {
      return MethodDescriptor(proto: $1, index: $0, registry: registry)
    }

    // Done initializing, register ourselves.
    registry.register(service: self)
  }

  fileprivate func bind(file: FileDescriptor, registry: Registry) {
    _file = file
    methods.forEach { $0.bind(service: self, registry: registry) }
  }
}

/// Describes an individual service method.
///
/// SwiftProtobuf does *not* generate anything for these (or services), but
/// they are here to support things that generate based off RPCs defined in
/// .proto file (gRPC, etc.).
public final class MethodDescriptor {
  /// The name of the method, not including its containing scope.
  public let name: String
  /// The fully-qualified name of the method, scope delimited by periods.
  public var fullName: String { return "\(service.fullName).\(name)" }
  /// Index of this service within the file's services.
  public let index: Int

  /// The .proto file in which this service was defined
  public var file: FileDescriptor { return service.file }
  /// The service tha defines this method.
  public var service: ServiceDescriptor { return _service! }

  /// The type of protocol message which this method accepts as input.
  public private(set) var inputType: Descriptor
  /// The type of protocol message which this message produces as output.
  public private(set) var outputType: Descriptor

  /// Whether the client streams multiple requests.
  public let clientStreaming: Bool
  // Whether the server streams multiple responses.
  public let serverStreaming: Bool

  /// The proto version of the descriptor that defines this method.
  @available(*, deprecated,
             message: "Use the properties directly or open a GitHub issue for something missing")
  public var proto: Google_Protobuf_MethodDescriptorProto { return _proto }
  private let _proto: Google_Protobuf_MethodDescriptorProto

  // Storage for `service`, will be set by bind()
  private unowned var _service: ServiceDescriptor?

  fileprivate init(proto: Google_Protobuf_MethodDescriptorProto,
                   index: Int,
                   registry: Registry) {
    self.name = proto.name
    self.index = index
    self.clientStreaming = proto.clientStreaming
    self.serverStreaming = proto.serverStreaming
    // Can look these up because all the Descriptors are already registered
    self.inputType = registry.descriptor(named: proto.inputType)!
    self.outputType = registry.descriptor(named: proto.outputType)!

    self._proto = proto
  }

  fileprivate func bind(service: ServiceDescriptor, registry: Registry) {
    self._service = service
  }
}

/// Helper used under the hood to build the mapping tables and look things up.
///
/// All fullNames are like defined in descriptor.proto, they start with a
/// leading '.'. This simplifies the string ops when assembling the message
/// graph.
fileprivate final class Registry {
  private var fileMap = [String:FileDescriptor]()
  // These three are all keyed by the full_name prefixed with a '.'.
  private var messageMap = [String:Descriptor]()
  private var enumMap = [String:EnumDescriptor]()
  private var serviceMap = [String:ServiceDescriptor]()

  init() {}

  func register(file: FileDescriptor) {
    fileMap[file.name] = file
  }
  func register(message: Descriptor) {
    messageMap[".\(message.fullName)"] = message
  }
  func register(enum e: EnumDescriptor) {
    enumMap[".\(e.fullName)"] = e
  }
  func register(service: ServiceDescriptor) {
    serviceMap[".\(service.fullName)"] = service
  }

  func fileDescriptor(named name: String) -> FileDescriptor? {
    return fileMap[name]
  }
  func descriptor(named fullName: String) -> Descriptor? {
    return messageMap[fullName]
  }
  func enumDescriptor(named fullName: String) -> EnumDescriptor? {
    return enumMap[fullName]
  }
  func serviceDescriptor(named fullName: String) -> ServiceDescriptor? {
    return serviceMap[fullName]
  }
}
