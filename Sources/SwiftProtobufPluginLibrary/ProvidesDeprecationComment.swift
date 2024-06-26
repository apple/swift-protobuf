// Sources/SwiftProtobufPluginLibrary/ProvidesDeprecationComment.swift
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------

import Foundation


/// Protocol that all the Descriptors conform to provide deprecation comments
public protocol ProvidesDeprecationComment {
  /// Returns the deprecation comment to be used.
  func deprecationComment(commentPrefix: String) -> String
}

/// Protocol that a Descriptor can confirm to when only the Type controls depecation.
public protocol SimpleProvidesDeprecationComment: ProvidesDeprecationComment {
  /// Name used in the generated message.
  var typeName: String { get }
  /// If the type is deprecated.
  var isDeprecated: Bool { get }
}

extension SimpleProvidesDeprecationComment {
  /// Default implementation to provide the depectation comment.
  public func deprecationComment(commentPrefix: String) -> String {
    guard isDeprecated else { return String() }
    return "\(commentPrefix) NOTE: This \(typeName) was marked as deprecated in the .proto file\n"
  }
}

/// Protocol that a Descriptor can confirm to when the Type or the File controls depecation.
public protocol TypeOrFileProvidesDeprecationComment: ProvidesDeprecationComment {
  /// Name used in the generated message.
  var typeName: String { get }
  /// If the type is deprecated.
  var isDeprecated: Bool { get }
  /// Returns the File this conforming object is in.
  var file: FileDescriptor! { get }
}

extension TypeOrFileProvidesDeprecationComment {
  /// Default implementation to provide the depectation comment.
  public func deprecationComment(commentPrefix: String) -> String {
    if isDeprecated {
      return "\(commentPrefix) NOTE: This \(typeName) was marked as deprecated in the .proto file.\n"
    }
    guard file.options.deprecated else { return String() }
    return "\(commentPrefix) NOTE: The whole .proto file that defined this \(typeName) was marked as deprecated.\n"
  }
}

extension ProvidesDeprecationComment where Self: ProvidesSourceCodeLocation {
  /// Helper to get the protoSourceComments combined with any depectation comment.
  public func protoSourceCommentsWithDeprecation(
    commentPrefix: String = "///",
    leadingDetachedPrefix: String? = nil
  ) -> String {
    let protoSourceComments = protoSourceComments(
      commentPrefix: commentPrefix,
      leadingDetachedPrefix: leadingDetachedPrefix)
    let deprecationComments = deprecationComment(commentPrefix: commentPrefix)

    if deprecationComments.isEmpty {
      return protoSourceComments
    }
    if protoSourceComments.isEmpty {
      return deprecationComments
    }
    return "\(protoSourceComments)\(commentPrefix)\n\(deprecationComments)"
  }
}
