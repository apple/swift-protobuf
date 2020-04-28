// Sources/SwiftProtobufPluginLibrary/ProvidesSourceCodeLocation.swift - SourceCodeInfo.Location provider
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

/// Protocol that all the Descriptors conform to for original .proto file
/// location lookup.
public protocol ProvidesSourceCodeLocation {
  /// Returns the Location of a given object (Descriptor).
  var sourceCodeInfoLocation: Google_Protobuf_SourceCodeInfo.Location? { get }
}

/// Default implementation for things that support ProvidesLocationPath.
extension ProvidesSourceCodeLocation where Self: ProvidesLocationPath {
  public var sourceCodeInfoLocation: Google_Protobuf_SourceCodeInfo.Location? {
    var path = IndexPath()
    getLocationPath(path: &path)
    return file.sourceCodeInfoLocation(path: path)
  }
}

extension ProvidesSourceCodeLocation {
  /// Helper to get a source comments as a string.
  public func protoSourceComments(commentPrefix: String = "///",
                                  leadingDetachedPrefix: String? = nil) -> String {
    guard let loc = sourceCodeInfoLocation else { return String() }
    return loc.asSourceComment(commentPrefix: commentPrefix,
                               leadingDetachedPrefix: leadingDetachedPrefix)
  }
}
