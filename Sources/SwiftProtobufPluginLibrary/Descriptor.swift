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

  // Construct out of a `Google_Protobuf_FileDescriptorSet` likely
  // created by protoc.
  public convenience init(proto: Google_Protobuf_FileDescriptorSet) {
    self.init(protos: proto.file)
  }

  /// The bundled in `google.protobuf.FeatureSetDefault` that defines what
  /// the plugin library can support.
  private static let bundledFeatureSetDefaults =
    // Decoding the bundle defaults better never fail
    try! Google_Protobuf_FeatureSetDefaults(serializedBytes: bundledFeatureSetDefaultBytes)

  /// The range of Editions that the library can support.
  ///
  /// This will limit what edition versions a plugin can claim to support.
  public static var bundledEditionsSupport: ClosedRange<Google_Protobuf_Edition> {
    return bundledFeatureSetDefaults.minimumEdition...bundledFeatureSetDefaults.maximumEdition
  }

  /// Construct out of a ordered list of
  /// `Google_Protobuf_FileDescriptorProto`s likely created by protoc.
  public convenience init(protos: [Google_Protobuf_FileDescriptorProto]) {
    self.init(protos: protos,
              featureSetDefaults: DescriptorSet.bundledFeatureSetDefaults)
  }

  /// Construct out of a ordered list of
  /// `Google_Protobuf_FileDescriptorProto`s likely created by protoc. Since
  /// .proto files can import other .proto files, the imports have to be
  /// listed before the things that use them so the graph can be
  /// reconstructed.
  ///
  /// - Parameters:
  ///   - protos: An ordered list of `Google_Protobuf_FileDescriptorProto`.
  ///     They must be order such that a file is provided before another file
  ///     that depends on it.
  ///   - featureSetDefaults: A `Google_Protobuf_FeatureSetDefaults` that provides
  ///     the Feature defaults to use when parsing the give File protos.
  ///   - featureExtensions: A list of Protobuf Extension extensions to
  ///     `google.protobuf.FeatureSet` that define custom features. If used, the
  ///     `defaults` should have been parsed with the extensions being
  ///     supported.
  public init(
    protos: [Google_Protobuf_FileDescriptorProto],
    featureSetDefaults: Google_Protobuf_FeatureSetDefaults,
    featureExtensions: [any AnyMessageExtension] = []
  ) {
    precondition(Self.bundledEditionsSupport.contains(featureSetDefaults.minimumEdition),
                 "Attempt to use a FeatureSetDefault minimumEdition that isn't supported by the library.")
    precondition(Self.bundledEditionsSupport.contains(featureSetDefaults.maximumEdition),
                 "Attempt to use a FeatureSetDefault maximumEdition that isn't supported by the library.")
    // If a protoc is too old ≤v26, it might have `features` instead of `overridable_features` and
    // `fixed_features`, try to catch that.
    precondition(
        nil == featureSetDefaults.defaults.first(where: { !$0.hasOverridableFeatures && !$0.hasFixedFeatures }),
        "These FeatureSetDefault don't appear valid, make sure you are using a new enough protoc to generate them. ")
    let registry = self.registry
    self.files = protos.map {
      return FileDescriptor(proto: $0,
                            featureSetDefaults: featureSetDefaults,
                            featureExtensions: featureExtensions,
                            registry: registry)
    }
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
  ///
  /// This is a legacy api since it requires the proto to be found or it aborts.
  /// Mainly kept for grpc-swift compatibility.
  @available(*, deprecated, renamed: "descriptor(named:)")
  public func lookupDescriptor(protoName: String) -> Descriptor {
    self.descriptor(named: protoName)!
  }

  /// Find the `Descriptor` for a named proto message.
  public func descriptor(named fullName: String) -> Descriptor? {
    return registry.descriptor(named: ".\(fullName)")
  }

  /// Find the `EnumDescriptor` for a named proto enum.
  ///
  /// This is a legacy api since it requires the enum to be found or it aborts.
  /// Mainly kept for grpc-swift compatibility.
  @available(*, deprecated, renamed: "enumDescriptor(named:)")
  public func lookupEnumDescriptor(protoName: String) -> EnumDescriptor {
    return enumDescriptor(named: protoName)!
  }

  /// Find the `EnumDescriptor` for a named proto enum.
  public func enumDescriptor(named fullName: String) -> EnumDescriptor? {
    return registry.enumDescriptor(named: ".\(fullName)")
  }

  /// Find the `ServiceDescriptor` for a named proto service.
  ///
  /// This is a legacy api since it requires the enum to be found or it aborts.
  /// Mainly kept for grpc-swift compatibility.
  @available(*, deprecated, renamed: "serviceDescriptor(named:)")
  public func lookupServiceDescriptor(protoName: String) -> ServiceDescriptor {
    return serviceDescriptor(named: protoName)!
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
  @available(*, deprecated, message: "This enum has been deprecated. Use `Google_Protobuf_Edition` instead.")
  public enum Syntax: String {
    case proto2
    case proto3

    public init?(rawValue: String) {
      switch rawValue {
      case "proto2", "":
        self = .proto2
      case "proto3":
        self = .proto3
      default:
        return nil
      }
    }
  }

  /// The filename used with protoc.
  public let name: String
  /// The proto package.
  public let package: String

  @available(*, deprecated, message: "This property has been deprecated. Use `edition` instead.")
  public var syntax: Syntax {
    Syntax(rawValue: self._proto.syntax)!
  }

  /// The edition of the file.
  public let edition: Google_Protobuf_Edition

  /// The resolved features for this File.
  public let features: Google_Protobuf_FeatureSet

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
  @available(*, deprecated, renamed: "options")
  public var fileOptions: Google_Protobuf_FileOptions { self.options }

  /// The `Google_Protobuf_FileOptions` set on this file.
  public let options: Google_Protobuf_FileOptions

  private let sourceCodeInfo: Google_Protobuf_SourceCodeInfo

  /// The proto version of the descriptor that defines this File.
  ///
  /// Thanks to Editions, this isn't likely to be exactly what
  /// folks want anymore, so wave any other plugins off it.
  @available(*, deprecated,
             message: "Use the properties directly or open a GitHub issue for something missing")
  public var proto: Google_Protobuf_FileDescriptorProto { return _proto }
  private let _proto: Google_Protobuf_FileDescriptorProto

  @available(*, deprecated, message: "Use `fileOptions/deprecated` instead.")
  public var isDeprecated: Bool { return proto.options.deprecated }

  fileprivate init(
    proto: Google_Protobuf_FileDescriptorProto,
    featureSetDefaults: Google_Protobuf_FeatureSetDefaults,
    featureExtensions: [any AnyMessageExtension],
    registry: Registry
  ) {
    self.name = proto.name
    self.package = proto.package

    // This logic comes from upstream `DescriptorBuilder::BuildFileImpl()`.
    if proto.hasEdition {
      self.edition = proto.edition
    } else {
      switch proto.syntax {
      case "", "proto2":
        self.edition = .proto2
      case "proto3":
        self.edition = .proto3
      default:
        self.edition = .unknown
        fatalError(
          "protoc provided an expected value (\"\(proto.syntax)\") for syntax/edition: \(proto.name)")
      }
    }
    // TODO: Revsit capturing the error here and see about exposing it out
    // to be reported via plugins.
    let featureResolver: FeatureResolver
    do {
      featureResolver = try FeatureResolver(edition: self.edition,
                                            featureSetDefaults: featureSetDefaults,
                                            featureExtensions: featureExtensions)
    } catch let e {
      fatalError("Failed to make a FeatureResolver for \(self.name): \(e)")
    }
    let resolvedFeatures = featureResolver.resolve(proto.options)
    self.features = resolvedFeatures
    self.options = proto.options

    let protoPackage = proto.package
    self.enums = proto.enumType.enumerated().map {
      return EnumDescriptor(proto: $0.element,
                            index: $0.offset,
                            parentFeatures: resolvedFeatures,
                            featureResolver: featureResolver,
                            registry: registry,
                            scope: protoPackage)
    }
    self.messages = proto.messageType.enumerated().map {
      return Descriptor(proto: $0.element,
                        index: $0.offset,
                        parentFeatures: resolvedFeatures,
                        featureResolver: featureResolver,
                        registry: registry,
                        scope: protoPackage)
    }
    self.extensions = proto.extension.enumerated().map {
      return FieldDescriptor(extension: $0.element,
                             index: $0.offset,
                             parentFeatures: resolvedFeatures,
                             featureResolver: featureResolver,
                             registry: registry)
    }
    self.services = proto.service.enumerated().map {
      return ServiceDescriptor(proto: $0.element,
                               index: $0.offset,
                               fileFeatures: resolvedFeatures,
                               featureResolver: featureResolver,
                               registry: registry,
                               scope: protoPackage)
    }

    // The compiler ensures there aren't cycles between a file and dependencies, so
    // this doesn't run the risk of creating any retain cycles that would force these
    // to have to be weak.
    let dependencies = proto.dependency.map { return registry.fileDescriptor(named: $0)! }
    self.dependencies = dependencies
    self.publicDependencies = proto.publicDependency.map { dependencies[Int($0)] }
    self.weakDependencies = proto.weakDependency.map { dependencies[Int($0)] }

    self.sourceCodeInfo = proto.sourceCodeInfo

    self._proto = proto

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
  // We can't assign a value directly to `proto` in the init because we get the
  // deprecation warning. This private prop only exists as a workaround to avoid
  // this warning and preserve backwards compatibility - it should be removed
  // when removing `proto`.
  private let _proto: Google_Protobuf_DescriptorProto
  @available(*, deprecated, message: "Please open a GitHub issue if you think functionality is missing.")
  public var proto: Google_Protobuf_DescriptorProto {
    _proto
  }

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

  /// Describes an extension range of a message. `ExtensionRange`s are not
  /// directly created, instead they are constructed/fetched via the
  /// `Descriptor`.
  public final class ExtensionRange {
    /// The start field number of this range (inclusive).
    public let start: Int32

    // The end field number of this range (exclusive).
    public fileprivate(set) var end: Int32

    // Tndex of this extension range within the message's extension range array.
    public let index: Int

    /// The resolved features for this ExtensionRange.
    public let features: Google_Protobuf_FeatureSet

    /// The `Google_Protobuf_ExtensionRangeOptions` set on this ExtensionRange.
    public let options: Google_Protobuf_ExtensionRangeOptions

    /// The name of the containing type, not including its scope.
    public var name: String { return containingType.name }
    /// The fully-qualified name of the containing type, scope delimited by
    /// periods.
    public var fullName: String { return containingType.fullName }

    /// The .proto file in which this ExtensionRange was defined.
    public var file: FileDescriptor! { return containingType.file }
    /// The descriptor that owns with ExtensionRange.
    public var containingType: Descriptor { return _containingType! }

    // Storage for `containingType`, will be set by bind()
    private unowned var _containingType: Descriptor?

    fileprivate init(proto: Google_Protobuf_DescriptorProto.ExtensionRange,
                     index: Int,
                     features: Google_Protobuf_FeatureSet) {
      self.start = proto.start
      self.end = proto.end
      self.index = index
      self.features = features
      self.options = proto.options
    }

    fileprivate func bind(containingType: Descriptor, registry: Registry) {
      self._containingType = containingType
    }
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
  public var file: FileDescriptor! { return _file! }
  /// If this Descriptor describes a nested type, this returns the type
  /// in which it is nested.
  public private(set) unowned var containingType: Descriptor?

  /// The resolved features for this Descriptor.
  public let features: Google_Protobuf_FeatureSet

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
    return self.oneofs.filter { !$0._isSynthetic }
  }()
  /// The extension field defintions under this message.
  public let extensions: [FieldDescriptor]

  /// The extension ranges declared for this message. They are returned in
  /// the order they are defined in the .proto file.
  public let messageExtensionRanges: [ExtensionRange]

  /// The extension ranges declared for this message. They are returned in
  /// the order they are defined in the .proto file.
  @available(*, deprecated, message: "This property is now deprecated: please use proto.extensionRange instead.")
  public var extensionRanges: [Google_Protobuf_DescriptorProto.ExtensionRange] {
    proto.extensionRange
  }

  /// The `extensionRanges` are in the order they appear in the original .proto
  /// file; this orders them and then merges any ranges that are actually
  /// contiguious (i.e. - [(21,30),(10,20)] -> [(10,30)])
  @available(*, deprecated, message: "Please open a GitHub issue if you think functionality is missing.")
  public private(set) lazy var normalizedExtensionRanges: [Google_Protobuf_DescriptorProto.ExtensionRange] = {
    var ordered = self.extensionRanges.sorted(by: { return $0.start < $1.start })
    if ordered.count > 1 {
      for i in (0..<(ordered.count - 1)).reversed() {
        if ordered[i].end == ordered[i+1].start {
          // This is why we need `end`'s setter to be `fileprivate` instead of
          // having it be a `let`.
          // We should turn it back into a let once we get rid of this prop.
          ordered[i].end = ordered[i+1].end
          ordered.remove(at: i + 1)
        }
      }
    }
    return ordered
  }()

  /// The `extensionRanges` from `normalizedExtensionRanges`, but takes a step
  /// further in that any ranges that do _not_ have any fields inbetween them
  /// are also merged together. These can then be used in context where it is
  /// ok to include field numbers that have to be extension or unknown fields.
  @available(*, deprecated, message: "Please open a GitHub issue if you think functionality is missing.")
  public private(set) lazy var ambitiousExtensionRanges: [Google_Protobuf_DescriptorProto.ExtensionRange] = {
    var merged = self.normalizedExtensionRanges
    var sortedFields = self.fields.sorted {$0.number < $1.number}
    if merged.count > 1 {
      var fieldNumbersReversedIterator =
        self.fields.map({ Int($0.number) }).sorted(by: { $0 > $1 }).makeIterator()
      var nextFieldNumber = fieldNumbersReversedIterator.next()
      while nextFieldNumber != nil && merged.last!.start < nextFieldNumber! {
        nextFieldNumber = fieldNumbersReversedIterator.next()
      }

      for i in (0..<(merged.count - 1)).reversed() {
        if nextFieldNumber == nil || merged[i].start > nextFieldNumber! {
          // No fields left or range starts after the next field, merge it with
          // the previous one.
          merged[i].end = merged[i+1].end
          merged.remove(at: i + 1)
        } else {
          // can't merge, find the next field number below this range.
          while nextFieldNumber != nil && merged[i].start < nextFieldNumber! {
            nextFieldNumber = fieldNumbersReversedIterator.next()
          }
        }
      }
    }
    return merged
  }()

  /// The reserved field number ranges for this message. These are returned
  /// in the order they are defined in the .proto file.
  public let reservedRanges: [Range<Int32>]
  /// The reserved field names for this message. These are returned in the
  /// order they are defined in the .proto file.
  public let reservedNames: [String]

  /// True/False if this Message is just for a `map<>` entry.
  @available(*, deprecated, renamed: "options.mapEntry")
  public var isMapEntry: Bool { return options.mapEntry }

  /// Returns the `FieldDescriptor`s for the "key" and "value" fields. If
  /// this isn't a map entry field, returns nil.
  ///
  /// This is like the C++ Descriptor `map_key()` and `map_value()` methods.
  public var mapKeyAndValue: (key: FieldDescriptor, value: FieldDescriptor)? {
    guard options.mapEntry else { return nil }
    precondition(fields.count == 2)
    return (key: fields[0], value: fields[1])
  }

  // Storage for `file`, will be set by bind()
  private unowned var _file: FileDescriptor?

  @available(*, deprecated, renamed: "options.messageSetWireFormat")
  public var useMessageSetWireFormat: Bool { return options.messageSetWireFormat }

  fileprivate init(proto: Google_Protobuf_DescriptorProto,
                   index: Int,
                   parentFeatures: Google_Protobuf_FeatureSet,
                   featureResolver: FeatureResolver,
                   registry: Registry,
                   scope: String) {
    self._proto = proto
    self.name = proto.name
    let fullName = scope.isEmpty ? proto.name : "\(scope).\(proto.name)"
    self.fullName = fullName
    self.index = index
    let resolvedFeatures = featureResolver.resolve(proto.options, resolvedParent: parentFeatures)
    self.features = resolvedFeatures
    self.options = proto.options
    self.wellKnownType = WellKnownType(rawValue: fullName)
    self.reservedRanges = proto.reservedRange.map { return $0.start ..< $0.end }
    self.reservedNames = proto.reservedName

    // TODO: This can skip the synthetic oneofs as no features can be set on
    // them to inherrit things.
    let oneofFeatures = proto.oneofDecl.map {
      return featureResolver.resolve($0.options, resolvedParent: resolvedFeatures)
    }

    self.messageExtensionRanges = proto.extensionRange.enumerated().map {
      return ExtensionRange(proto: $0.element,
                            index: $0.offset,
                            features: featureResolver.resolve($0.element.options,
                                                              resolvedParent: resolvedFeatures))
    }
    self.enums = proto.enumType.enumerated().map {
      return EnumDescriptor(proto: $0.element,
                            index: $0.offset,
                            parentFeatures: resolvedFeatures,
                            featureResolver: featureResolver,
                            registry: registry,
                            scope: fullName)
    }
    self.messages = proto.nestedType.enumerated().map {
      return Descriptor(proto: $0.element,
                        index: $0.offset,
                        parentFeatures: resolvedFeatures,
                        featureResolver: featureResolver,
                        registry: registry,
                        scope: fullName)
    }
    self.fields = proto.field.enumerated().map {
      // For field Features inherrit from the parent oneof or message. A
      // synthetic oneof (for proto3 optional) can't get features, so those
      // don't come into play.
      let inRealOneof = $0.element.hasOneofIndex && !$0.element.proto3Optional
      return FieldDescriptor(messageField: $0.element,
                             index: $0.offset,
                             parentFeatures: inRealOneof ? oneofFeatures[Int($0.element.oneofIndex)] : resolvedFeatures,
                             featureResolver: featureResolver,
                             registry: registry)
    }
    self.oneofs = proto.oneofDecl.enumerated().map {
      return OneofDescriptor(proto: $0.element,
                             index: $0.offset,
                             features: oneofFeatures[$0.offset],
                             registry: registry)
    }
    self.extensions = proto.extension.enumerated().map {
      return FieldDescriptor(extension: $0.element,
                             index: $0.offset,
                             parentFeatures: resolvedFeatures,
                             featureResolver: featureResolver,
                             registry: registry)
    }

    // Done initializing, register ourselves.
    registry.register(message: self)
  }

  fileprivate func bind(file: FileDescriptor, registry: Registry, containingType: Descriptor?) {
    _file = file
    self.containingType = containingType
    messageExtensionRanges.forEach { $0.bind(containingType: self, registry: registry) }
    enums.forEach { $0.bind(file: file, registry: registry, containingType: self) }
    messages.forEach { $0.bind(file: file, registry: registry, containingType: self) }
    fields.forEach { $0.bind(file: file, registry: registry, containingType: self) }
    oneofs.forEach { $0.bind(registry: registry, containingType: self) }
    extensions.forEach { $0.bind(file: file, registry: registry, containingType: self) }

    // Synthetic oneofs come after normal oneofs. The C++ Descriptor enforces this, only
    // here as a secondary validation because other code can rely on it.
    var seenSynthetic = false
    for o in oneofs {
      if seenSynthetic {
        // Once we've seen one synthetic, all the rest must also be synthetic.
        precondition(o._isSynthetic)
      } else {
        seenSynthetic = o._isSynthetic
      }
    }
  }
}

/// Describes a type of protocol enum. `EnumDescriptor`s are not directly
/// created, instead they are constructed/fetched via the `DescriptorSet` or
/// they are directly accessed via a `EnumType` property on `FieldDescriptor`s,
/// etc.
public final class EnumDescriptor {
  // We can't assign a value directly to `proto` in the init because we get the
  // deprecation warning. This private prop only exists as a workaround to avoid
  // this warning and preserve backwards compatibility - it should be removed
  // when removing `proto`.
  private let _proto: Google_Protobuf_EnumDescriptorProto
  @available(*, deprecated, message: "Please open a GitHub issue if you think functionality is missing.")
  public var proto: Google_Protobuf_EnumDescriptorProto {
    _proto
  }

  /// The name of this enum type in the containing scope.
  public let name: String
  /// The fully-qualified name of the enum type, scope delimited by periods.
  public let fullName: String
  /// Index of this enum within the file or containing message's enums.
  public let index: Int

  /// The .proto file in which this message type was defined.
  public var file: FileDescriptor! { return _file! }
  /// If this Descriptor describes a nested type, this returns the type
  /// in which it is nested.
  public private(set) unowned var containingType: Descriptor?

  /// The resolved features for this Enum.
  public let features: Google_Protobuf_FeatureSet

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

  /// Returns true whether this is a "closed" enum, meaning that it:
  /// - Has a fixed set of named values.
  /// - Encountering values not in this set causes them to be treated as unknown
  ///   fields.
  /// - The first value (i.e., the default) may be nonzero.
  public var isClosed: Bool {
    // Implementation comes from C++ EnumDescriptor::is_closed().
    return features.enumType == .closed
  }

  // Storage for `file`, will be set by bind()
  private unowned var _file: FileDescriptor?

  @available(*, deprecated, message: "Please open a GitHub issue if you think functionality is missing.")
  public var defaultValue: EnumValueDescriptor {
    // The compiler requires the be atleast one value, so force unwrap is safe.
    return values.first!
  }

  fileprivate init(proto: Google_Protobuf_EnumDescriptorProto,
                   index: Int,
                   parentFeatures: Google_Protobuf_FeatureSet,
                   featureResolver: FeatureResolver,
                   registry: Registry,
                   scope: String) {
    self._proto = proto
    self.name = proto.name
    self.fullName = scope.isEmpty ? proto.name : "\(scope).\(proto.name)"
    self.index = index
    let resolvedFeatures = featureResolver.resolve(proto.options, resolvedParent: parentFeatures)
    self.features = resolvedFeatures
    self.options = proto.options
    self.reservedRanges = proto.reservedRange.map { return $0.start ... $0.end }
    self.reservedNames = proto.reservedName

    self.values = proto.value.enumerated().map {
      return EnumValueDescriptor(proto: $0.element,
                                 index: $0.offset,
                                 features: featureResolver.resolve($0.element.options,
                                                                   resolvedParent: resolvedFeatures),
                                 scope: scope)
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
  // We can't assign a value directly to `proto` in the init because we get the
  // deprecation warning. This private prop only exists as a workaround to avoid
  // this warning and preserve backwards compatibility - it should be removed
  // when removing `proto`.
  private let _proto: Google_Protobuf_EnumValueDescriptorProto
  @available(*, deprecated, message: "Please open a GitHub issue if you think functionality is missing.")
  public var proto: Google_Protobuf_EnumValueDescriptorProto {
    _proto
  }

  /// Name of this enum constant.
  public let name: String

  private var _fullName: String
  /// The full_name of an enum value is a sibling symbol of the enum type.
  /// e.g. the full name of FieldDescriptorProto::TYPE_INT32 is actually
  /// "google.protobuf.FieldDescriptorProto.TYPE_INT32", NOT
  /// "google.protobuf.FieldDescriptorProto.Type.TYPE_INT32". This is to conform
  /// with C++ scoping rules for enums.
  public var fullName: String {
    get {
      self._fullName
    }

    @available(*, deprecated, message: "fullName is now read-only")
    set {
      self._fullName = newValue
    }
  }
  /// Index within the enums's `EnumDescriptor`.
  public let index: Int
  /// Numeric value of this enum constant.
  public let number: Int32

  @available(*, deprecated, message: "Please open a GitHub issue if you think functionality is missing.")
  public private(set) weak var aliasOf: EnumValueDescriptor?
  @available(*, deprecated, message: "Please open a GitHub issue if you think functionality is missing.")
  public fileprivate(set) var aliases: [EnumValueDescriptor] = []

  /// The resolved features for this EnumValue.
  public let features: Google_Protobuf_FeatureSet

  /// The .proto file in which this message type was defined.
  public var file: FileDescriptor! { return enumType.file }
  /// The type of this value.
  public var enumType: EnumDescriptor! { return _enumType! }

  /// The `Google_Protobuf_EnumValueOptions` set on this value.
  public let options: Google_Protobuf_EnumValueOptions

  // Storage for `enumType`, will be set by bind()
  private unowned var _enumType: EnumDescriptor?

  fileprivate init(proto: Google_Protobuf_EnumValueDescriptorProto,
                   index: Int,
                   features: Google_Protobuf_FeatureSet,
                   scope: String) {
    self._proto = proto
    self.name = proto.name
    self._fullName = scope.isEmpty ? proto.name : "\(scope).\(proto.name)"
    self.index = index
    self.features = features
    self.number = proto.number
    self.options = proto.options
  }

  fileprivate func bind(enumType: EnumDescriptor) {
    self._enumType = enumType
  }
}

/// Describes a oneof defined in a message type.
public final class OneofDescriptor {
  // We can't assign a value directly to `proto` in the init because we get the
  // deprecation warning. This private prop only exists as a workaround to avoid
  // this warning and preserve backwards compatibility - it should be removed
  // when removing `proto`.
  private let _proto: Google_Protobuf_OneofDescriptorProto
  @available(*, deprecated, message: "Please open a GitHub issue if you think functionality is missing.")
  public var proto: Google_Protobuf_OneofDescriptorProto {
    _proto
  }

  /// Name of this oneof.
  public let name: String
  /// Fully-qualified name of the oneof.
  public var fullName: String { return "\(containingType.fullName).\(name)" }
  /// Index of this oneof within the message's oneofs.
  public let index: Int

  /// The resolved features for this Oneof.
  public let features: Google_Protobuf_FeatureSet

  /// Returns whether this oneof was inserted by the compiler to wrap a proto3
  /// optional field. If this returns true, code generators should *not* emit it.
  var _isSynthetic: Bool {
    return fields.count == 1 && fields.first!.proto3Optional
  }
  @available(*, deprecated, message: "Please open a GitHub issue if you think functionality is missing.")
  public var isSynthetic: Bool {
    _isSynthetic
  }

  /// The .proto file in which this oneof type was defined.
  public var file: FileDescriptor! { return containingType.file }
  /// The Descriptor of the message that defines this oneof.
  public var containingType: Descriptor! { return _containingType! }

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
                   features: Google_Protobuf_FeatureSet,
                   registry: Registry) {
    self._proto = proto
    self.name = proto.name
    self.index = index
    self.features = features
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
  // We can't assign a value directly to `proto` in the init because we get the
  // deprecation warning. This private prop only exists as a workaround to avoid
  // this warning and preserve backwards compatibility - it should be removed
  // when removing `proto`.
  private let _proto: Google_Protobuf_FieldDescriptorProto
  @available(*, deprecated, message: "Please open a GitHub issue if you think functionality is missing.")
  public var proto: Google_Protobuf_FieldDescriptorProto {
    _proto
  }

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
  public let jsonName: String?

  public let features: Google_Protobuf_FeatureSet

  /// File in which this field was defined.
  public var file: FileDescriptor! { return _file! }

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
  public private(set) var type: Google_Protobuf_FieldDescriptorProto.TypeEnum

  /// optional/required/repeated
  public let label: Google_Protobuf_FieldDescriptorProto.Label

  /// Shorthand for `label` == `.required`.
  ///
  /// NOTE: This could also be a map as the are also repeated fields.
  public var isRequired: Bool {
    // Implementation comes from FieldDescriptor::is_required()
    return features.fieldPresence == .legacyRequired
  }
  /// Shorthand for `label` == `.optional`
  public var isOptional: Bool { return label == .optional }
  /// Shorthand for `label` == `.repeated`
  public var isRepeated: Bool { return label == .repeated }

  /// Is this field packable.
  public var isPackable: Bool {
    // This logic comes from the C++ FieldDescriptor::is_packable() impl.
    return label == .repeated && FieldDescriptor.isPackable(type: type)
  }
  /// If this field is packable and packed.
  public var isPacked: Bool {
    // This logic comes from the C++ FieldDescriptor::is_packed() impl.
    guard isPackable else { return false }
    return features.repeatedFieldEncoding == .packed
  }
  /// True if this field is a map.
  public var isMap: Bool {
    // This logic comes from the C++ FieldDescriptor::is_map() impl.
    return type == .message && messageType!.options.mapEntry
  }

  /// Returns true if this field was syntactically written with "optional" in the
  /// .proto file. Excludes singular proto3 fields that do not have a label.
  var _hasOptionalKeyword: Bool {
    // This logic comes from the C++ FieldDescriptor::has_optional_keyword()
    // impl.
    return proto3Optional ||
      (file.edition == .proto2 && label == .optional && oneofIndex == nil)
  }
  @available(*, deprecated, message: "Please open a GitHub issue if you think functionality is missing.")
  public var hasOptionalKeyword: Bool {
    _hasOptionalKeyword
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
      break
    }
    return isExtension || oneofIndex != nil || features.fieldPresence != .implicit
  }

  /// Returns true if this is a string field and should do UTF-8 validation.
  ///
  /// This api is for completeness, but it likely should never be used. The
  /// concept comes from the C++ FieldDescriptory::requires_utf8_validation(),
  /// but doesn't make a lot of sense for Swift Protobuf because `string` fields
  /// are modeled as Swift `String` objects, and thus they always have to be
  /// valid UTF-8. If something were to try putting something else in the field,
  /// the library won't be able to parse it. While that sounds bad, other
  /// languages have similar issues with their _string_ types and thus have the
  /// same issues.
  public var requiresUTF8Validation: Bool {
    return type == .string && features.utf8Validation == .verify
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
  @available(*, deprecated, renamed: "defaultValue")
  public var explicitDefaultValue: String? {
    return defaultValue
  }

  /// The explicitly declared default value for this field.
  ///
  /// This is the *raw* string value from the .proto file that was listed as
  /// the default, it is up to the consumer to convert it correctly for the
  /// type of this field. The C++ FieldDescriptor does offer some apis to
  /// help with that, but at this time, that is not provided here.
  public let defaultValue: String?

  /// The `Descriptor` of the message which this is a field of. For extensions,
  /// this is the extended type.
  public var containingType: Descriptor! { return _containingType! }

  /// The oneof this field is a member of.
  @available(*, deprecated, renamed: "containingOneof")
  public var oneof: OneofDescriptor? {
    return containingOneof
  }
  /// The oneof this field is a member of.
  public var containingOneof: OneofDescriptor? {
    guard let oneofIndex = oneofIndex else { return nil }
    return containingType.oneofs[Int(oneofIndex)]
  }

  /// The non synthetic oneof this field is a member of.
  @available(*, deprecated, renamed: "realContainingOneof")
  public var realOneof: OneofDescriptor? {
    return realContainingOneof
  }
  /// The non synthetic oneof this field is a member of.
  public var realContainingOneof: OneofDescriptor? {
    guard let oneof = containingOneof, !oneof._isSynthetic else { return nil }
    return oneof
  }
  /// The index in a oneof this field is in.
  public let oneofIndex: Int32?

  // This builds basically a union for the storage for `extensionScope`
  // and the value to look it up with.
  private enum ExtensionScopeStorage {
    case extendee(String)  // The value to be used for looked up during `bind()`.
    case message(UnownedBox<Descriptor>)
  }
  private var _extensionScopeStorage: ExtensionScopeStorage?

  /// Extensions can be declared within the scope of another message. If this
  /// is an extension field, then this will be the scope it was declared in
  /// nil if was declared at a global scope.
  public var extensionScope: Descriptor? {
    guard case .message(let boxed) = _extensionScopeStorage else { return nil }
    return boxed.value
  }

  // This builds basically a union for the storage for `messageType`
  // and `enumType` since only one can needed at a time.
  private enum FieldTypeStorage {
    case typeName(String)  // The value to be looked up during `bind()`.
    case message(UnownedBox<Descriptor>)
    case `enum`(UnownedBox<EnumDescriptor>)
  }
  private var _fieldTypeStorage: FieldTypeStorage?

  /// When this is a message/group field, that message's `Descriptor`.
  public var messageType: Descriptor! {
    guard case .message(let boxed) = _fieldTypeStorage else { return nil }
    return boxed.value
  }
  /// When this is a enum field, that enum's `EnumDescriptor`.
  public var enumType: EnumDescriptor! {
    guard case .enum(let boxed) = _fieldTypeStorage else { return nil }
    return boxed.value
  }

  /// The FieldOptions for this field.
  public var options: Google_Protobuf_FieldOptions

  let proto3Optional: Bool

  // Storage for `containingType`, will be set by bind()
  private unowned var _containingType: Descriptor?
  // Storage for `file`, will be set by bind()
  private unowned var _file: FileDescriptor?

  fileprivate convenience init(messageField proto: Google_Protobuf_FieldDescriptorProto,
                               index: Int,
                               parentFeatures: Google_Protobuf_FeatureSet,
                               featureResolver: FeatureResolver,
                               registry: Registry) {
    precondition(proto.extendee.isEmpty)  // Only for extensions

    // On regular fields, it only makes sense to get `.proto3Optional`
    // when also in a (synthetic) oneof. So...no oneof index, it better
    // not be `.proto3Optional`
    precondition(proto.hasOneofIndex || !proto.proto3Optional)

    self.init(proto: proto,
              index: index,
              parentFeatures: parentFeatures,
              featureResolver: featureResolver,
              registry: registry,
              isExtension: false)
  }

  fileprivate convenience init(extension proto: Google_Protobuf_FieldDescriptorProto,
                               index: Int,
                               parentFeatures: Google_Protobuf_FeatureSet,
                               featureResolver: FeatureResolver,
                               registry: Registry) {
    precondition(!proto.extendee.isEmpty)  // Required for extensions

    // FieldDescriptorProto is used for fields or extensions, generally
    // .proto3Optional only makes sense on fields if it is in a oneof. But,
    // it is allowed on extensions. For information on that, see
    // https://github.com/protocolbuffers/protobuf/issues/8234#issuecomment-774224376
    // The C++ Descriptor code encorces the field/oneof part, but nothing
    // is checked on the oneof side.
    precondition(!proto.hasOneofIndex)

    self.init(proto: proto,
              index: index,
              parentFeatures: parentFeatures,
              featureResolver: featureResolver,
              registry: registry,
              isExtension: true)
  }

  private init(proto: Google_Protobuf_FieldDescriptorProto,
               index: Int,
               parentFeatures: Google_Protobuf_FeatureSet,
               featureResolver: FeatureResolver,
               registry: Registry,
               isExtension: Bool) {
    self._proto = proto
    self.name = proto.name
    self.index = index
    self.features = featureResolver.resolve(proto, resolvedParent: parentFeatures)
    self.defaultValue = proto.hasDefaultValue ? proto.defaultValue : nil
    precondition(proto.hasJsonName)  // protoc should always set the name
    self.jsonName = proto.jsonName
    self.isExtension = isExtension
    self.number = proto.number
    // This remapping is based follow part of what upstream
    // `DescriptorBuilder::PostProcessFieldFeatures()` does. It is needed to
    // help ensure basic transforms from .proto2 to .edition2023 generate the
    // same code/behaviors.
    if proto.type == .message && self.features.messageEncoding == .delimited {
      self.type = .group
    } else {
      self.type = proto.type
    }
    // This remapping is based follow part of what upstream
    // `DescriptorBuilder::PostProcessFieldFeatures()` does. If generators use
    // helper instead of access `label` directly, they won't need this, but for
    // consistency, remap `label` to expose the pre Editions/Features value.
    if self.features.fieldPresence == .legacyRequired &&  proto.label == .optional {
      self.label = .required
    } else {
      self.label = proto.label
    }
    self.options = proto.options
    self.oneofIndex = proto.hasOneofIndex ? proto.oneofIndex : nil
    self.proto3Optional = proto.proto3Optional
    self._extensionScopeStorage = isExtension ? .extendee(proto.extendee) : nil
    switch type {
    case .group, .message, .enum:
      _fieldTypeStorage = .typeName(proto.typeName)
    default:
      _fieldTypeStorage = nil
    }
  }

  fileprivate func bind(file: FileDescriptor, registry: Registry, containingType: Descriptor?) {
    _file = file

    // See the defintions of `containingType` and `extensionScope`, this
    // dance can otherwise be a little confusing.
    if case .extendee(let extendee) = _extensionScopeStorage {
      _containingType = registry.descriptor(named: extendee)!
      if let containingType = containingType {
        _extensionScopeStorage = .message(UnownedBox(value: containingType))
      } else {
        _extensionScopeStorage = nil  // Top level
      }
    } else {
      _containingType = containingType
    }

    if case .typeName(let typeName) = _fieldTypeStorage {
      if type == .enum {
        _fieldTypeStorage = .enum(UnownedBox(value: registry.enumDescriptor(named: typeName)!))
      } else {
        let msgtype = registry.descriptor(named: typeName)!
        _fieldTypeStorage = .message(UnownedBox(value: msgtype))
        if type == .group && (
          msgtype.options.mapEntry ||
          (_containingType != nil && _containingType!.options.mapEntry)
        ) {
          type = .message
        }
      }
    }
  }
}

/// Describes an RPC service.
///
/// SwiftProtobuf does *not* generate anything for these (or methods), but
/// they are here to support things that generate based off RPCs defined in
/// .proto file (gRPC, etc.).
public final class ServiceDescriptor {
  // We can't assign a value directly to `proto` in the init because we get the
  // deprecation warning. This private prop only exists as a workaround to avoid
  // this warning and preserve backwards compatibility - it should be removed
  // when removing `proto`.
  private let _proto: Google_Protobuf_ServiceDescriptorProto
  @available(*, deprecated, message: "Please open a GitHub issue if you think functionality is missing.")
  public var proto: Google_Protobuf_ServiceDescriptorProto {
    _proto
  }

  /// The name of the service, not including its containing scope.
  public let name: String
  /// The fully-qualified name of the service, scope delimited by periods.
  public let fullName: String
  /// Index of this service within the file's services.
  public let index: Int

  /// The .proto file in which this service was defined
  public var file: FileDescriptor! { return _file! }

  /// The resolved features for this Service.
  public let features: Google_Protobuf_FeatureSet

  /// Get `Google_Protobuf_ServiceOptions` for this service.
  public let options: Google_Protobuf_ServiceOptions

  /// The methods defined on this service. These are returned in the order they
  /// were defined in the .proto file.
  public let methods: [MethodDescriptor]

  // Storage for `file`, will be set by bind()
  private unowned var _file: FileDescriptor?

  fileprivate init(proto: Google_Protobuf_ServiceDescriptorProto,
                   index: Int,
                   fileFeatures: Google_Protobuf_FeatureSet,
                   featureResolver: FeatureResolver,
                   registry: Registry,
                   scope: String) {
    self._proto = proto
    self.name = proto.name
    self.fullName = scope.isEmpty ? proto.name : "\(scope).\(proto.name)"
    self.index = index
    let resolvedFeatures = featureResolver.resolve(proto.options, resolvedParent: fileFeatures)
    self.features = resolvedFeatures
    self.options = proto.options

    self.methods = proto.method.enumerated().map {
      return MethodDescriptor(proto: $0.element,
                              index: $0.offset,
                              features: featureResolver.resolve($0.element.options, resolvedParent: resolvedFeatures),
                              registry: registry)
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
  public var file: FileDescriptor! { return service.file }
  /// The service tha defines this method.
  public var service: ServiceDescriptor! { return _service! }

  /// The resolved features for this Method.
  public let features: Google_Protobuf_FeatureSet

  /// Get `Google_Protobuf_MethodOptions` for this method.
  public let options: Google_Protobuf_MethodOptions

  /// The type of protocol message which this method accepts as input.
  public private(set) var inputType: Descriptor!
  /// The type of protocol message which this message produces as output.
  public private(set) var outputType: Descriptor!

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
                   features: Google_Protobuf_FeatureSet,
                   registry: Registry) {
    self.name = proto.name
    self.index = index
    self.features = features
    self.options = proto.options
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

/// Helper for making an enum associated value `unowned`.
fileprivate struct UnownedBox<T: AnyObject> {
  unowned let value: T
}
