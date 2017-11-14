// Sources/SwiftProtobufPluginLibrary/LibraryInfo.swift - Helpers info about the SwiftProtobuf library
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Helpers for info about the SwiftProtobuf library itself.
///
// -----------------------------------------------------------------------------

import Foundation

/// Scope for helpers about the library.
public enum SwiftProtobufInfo {

  /// The name of the library
  public static let name = "SwiftProtobuf"

  /// Proto Files that ship with the library.
  public static let bundledProtoFiles: Set<String> = [
    "google/protobuf/any.proto",
    "google/protobuf/api.proto",
    // "google/protobuf/descriptor.proto"
    //    is not a WKT; and while it is used by generator, it does NOT ship
    //    with the library, if the library ever wants to expose full
    //    descriptors, that could change.
    "google/protobuf/duration.proto",
    "google/protobuf/empty.proto",
    "google/protobuf/field_mask.proto",
    "google/protobuf/source_context.proto",
    "google/protobuf/struct.proto",
    "google/protobuf/timestamp.proto",
    "google/protobuf/type.proto",
    "google/protobuf/wrappers.proto",
  ]

  // Checks if a FileDescriptor is a library bundled proto file.
  public static func isBundledProto(file: Google_Protobuf_FileDescriptorProto) -> Bool {
    return file.package == "google.protobuf" && bundledProtoFiles.contains(file.name)
  }
}
