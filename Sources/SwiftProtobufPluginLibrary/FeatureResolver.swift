// Sources/SwiftProtobufPluginLibrary/FeatureResolve.swift - Feature helpers
//
// Copyright (c) 2014 - 2024 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------

import SwiftProtobuf

protocol ProvidesFeatureSets {
  var features: Google_Protobuf_FeatureSet { get }
  var hasFeatures: Bool { get }
}

// Skip `Google_Protobuf_FileOptions`, special case of `resolve`.
extension Google_Protobuf_MessageOptions : ProvidesFeatureSets {}
extension Google_Protobuf_EnumOptions : ProvidesFeatureSets {}
// Skip `Google_Protobuf_FieldOptions`, Field is special case of `resolve`.
extension Google_Protobuf_OneofOptions : ProvidesFeatureSets {}
extension Google_Protobuf_ExtensionRangeOptions : ProvidesFeatureSets {}
extension Google_Protobuf_EnumValueOptions : ProvidesFeatureSets {}
extension Google_Protobuf_ServiceOptions : ProvidesFeatureSets {}
extension Google_Protobuf_MethodOptions : ProvidesFeatureSets {}

/// Encapsulates the process of Feature resolution, sorta like the upstream
/// `feature_resolver.cpp`.
class FeatureResolver {

  enum Error: Swift.Error, Equatable, CustomStringConvertible {
    case unsupported(edition: Google_Protobuf_Edition,
                     supported: ClosedRange<Google_Protobuf_Edition>)
    case noDefault(edition: Google_Protobuf_Edition)
    case invalidExtension(type: String)

    var description: String {
      switch self {
      case .unsupported(let edition, let supported):
        return "Edition \(edition) is not in the supported range (\(supported))"
      case .noDefault(let edition):
        return "No default value found for edition \(edition)"
      case .invalidExtension(let type):
        return "Passed an extension that wasn't to google.protobuf.FeatureSet: \(type)"
      }
    }
  }

  /// The requested Edition.
  let edition: Google_Protobuf_Edition
  /// The detaults to use for this edition.
  let defaultFeatureSet: Google_Protobuf_FeatureSet

  private let extensionMap: (any ExtensionMap)?

  /// Construct a resolver for a given edition with the correct defaults.
  ///
  /// - Parameters:
  ///   - edition: The edition of defaults desired.
  ///   - defaults: A `Google_Protobuf_FeatureSetDefaults` created by protoc
  ///     from one or more proto files that define `Google_Protobuf_FeatureSet`
  ///     and any extensions.
  ///   - extensions: A list of Protobuf Extension extensions to
  ///     `google.protobuf.FeatureSet` that define custom features. If used, the
  ///     `defaults` should have been parsed with the extensions being
  ///     supported.
  /// - Returns: A configured resolver for the given edition/defaults.
  /// - Throws: `FeatureResolver.Error` if there edition requested can't be
  ///           supported by the given defaults.
  init(
    edition: Google_Protobuf_Edition,
    featureSetDefaults defaults: Google_Protobuf_FeatureSetDefaults,
    featureExtensions extensions: [any AnyMessageExtension] = []
  ) throws {
    guard edition >= defaults.minimumEdition &&
            edition <= defaults.maximumEdition else {
      throw Error.unsupported(edition: edition,
                              supported: defaults.minimumEdition...defaults.maximumEdition)
    }

    // When protoc generates defaults, they are ordered, so find the last one.
    var found: Google_Protobuf_FeatureSetDefaults.FeatureSetEditionDefault?
    for d in defaults.defaults {
      guard d.edition <= edition else { break }
      found = d
    }

    guard let found = found else {
      throw Error.noDefault(edition: edition)
    }
    self.edition = edition

    if extensions.isEmpty {
      extensionMap = nil
    } else {
      for e in extensions {
        if e.messageType != Google_Protobuf_FeatureSet.self {
          throw Error.invalidExtension(type: e.messageType.protoMessageName)
        }
      }
      var simpleMap = SimpleExtensionMap()
      simpleMap.insert(contentsOf: extensions)
      extensionMap = simpleMap
    }

    var features = found.fixedFeatures
    // Don't yet have a message level merge, so bounce through serialization.
    let bytes: [UInt8] = try! found.overridableFeatures.serializedBytes()
    try! features.merge(serializedBytes: bytes, extensions: extensionMap)
    defaultFeatureSet = features
  }

  /// Resolve the Features for a File.
  func resolve(_ options: Google_Protobuf_FileOptions) -> Google_Protobuf_FeatureSet {
    /// There is no parent, so the default options are used.
    return resolve(features: options.hasFeatures ? options.features : nil,
                   resolvedParent: defaultFeatureSet)
  }

  /// Resolve the Features for a Field.
  ///
  /// This needs to the full FieldDescriptorProto incase it has to do fallback
  /// inference.
  func resolve(_ proto: Google_Protobuf_FieldDescriptorProto,
               resolvedParent: Google_Protobuf_FeatureSet
  ) -> Google_Protobuf_FeatureSet {
    if edition >= .edition2023 {
      return resolve(features: proto.options.hasFeatures ? proto.options.features : nil,
                     resolvedParent: resolvedParent)
    }
    // For `.proto2` and `.proto3`, some of the field behaviors have to be
    // figured out as they can't be captured in the defaults and inherrited.
    // See `InferLegacyProtoFeatures` in the C++ descriptor.cc implementation
    // for this logic.
    var features = Google_Protobuf_FeatureSet()
    if proto.label == .required {
      features.fieldPresence = .legacyRequired
    }
    if proto.type == .group {
      features.messageEncoding = .delimited
    }
    let options = proto.options
    if options.packed {
      features.repeatedFieldEncoding = .packed
    }
    if edition == .proto3 && options.hasPacked && !options.packed {
      features.repeatedFieldEncoding = .expanded
    }
    // Now now merge the rest of the inherrited info from the defaults.
    return resolve(features: features, resolvedParent: defaultFeatureSet)
  }

  /// Resolve the Features for a given descriptor's options, the resolvedParent
  /// values used to inherrit from.
  func resolve<T: ProvidesFeatureSets>(
    _ options: T,
    resolvedParent: Google_Protobuf_FeatureSet
  ) -> Google_Protobuf_FeatureSet {
    return resolve(features: options.hasFeatures ? options.features : nil,
                   resolvedParent: resolvedParent)
  }

  /// Helper to do the merging.
  func resolve(features: Google_Protobuf_FeatureSet?,
               resolvedParent: Google_Protobuf_FeatureSet
  ) -> Google_Protobuf_FeatureSet {
    var result = resolvedParent
    if let features = features {
      // Don't yet have a message level merge, so bounce through serialization.
      let bytes: [UInt8] = try! features.serializedBytes()
      try! result.merge(serializedBytes: bytes, extensions: extensionMap)
    }
    return result
  }

}
