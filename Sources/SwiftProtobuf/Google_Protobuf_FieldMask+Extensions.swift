// Sources/SwiftProtobuf/Google_Protobuf_FieldMask+Extensions.swift - Fieldmask extensions
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Extend the generated FieldMask message with customized JSON coding and
/// convenience methods.
///
// -----------------------------------------------------------------------------

// TODO: We should have utilities to apply a fieldmask to an arbitrary
// message, intersect two fieldmasks, etc.
// Google's C++ implementation does this by having utilities
// to build a tree of field paths that can be easily intersected,
// unioned, traversed to apply to submessages, etc.

extension Google_Protobuf_FieldMask {
  /// Creates a new `Google_Protobuf_FieldMask` from the given array of paths.
  ///
  /// The paths should match the names used in the .proto file, which may be
  /// different than the corresponding Swift property names.
  ///
  /// - Parameter protoPaths: The paths from which to create the field mask,
  ///   defined using the .proto names for the fields.
  public init(protoPaths: [String]) {
    self.init()
    paths = protoPaths
  }

  /// Creates a new `Google_Protobuf_FieldMask` from the given paths.
  ///
  /// The paths should match the names used in the .proto file, which may be
  /// different than the corresponding Swift property names.
  ///
  /// - Parameter protoPaths: The paths from which to create the field mask,
  ///   defined using the .proto names for the fields.
  public init(protoPaths: String...) {
    self.init(protoPaths: protoPaths)
  }

  // It would be nice if to have an initializer that accepted Swift property
  // names, but translating between swift and protobuf/json property
  // names is not entirely deterministic.
}
