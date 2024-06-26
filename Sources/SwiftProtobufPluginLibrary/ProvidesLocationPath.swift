// Sources/SwiftProtobufPluginLibrary/ProvidesLocationPath.swift - Proto Field numbers
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------

import Foundation

/// Protocol that all the Descriptors conform to for original .proto file
/// location lookup.
public protocol ProvidesLocationPath {
  /// Updates `path` to the source location of the complete extent of
  /// the object conforming to this protocol. This is a replacement for
  /// `GetSourceLocation()` in the C++ Descriptor apis.
  func getLocationPath(path: inout IndexPath)
  /// Returns the File this conforming object is in.
  var file: FileDescriptor! { get }
}
