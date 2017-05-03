// Sources/protoc-gen-swift/Descriptor+Extensions.swift - Additions to Descriptors
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------

import PluginLibrary

extension FileDescriptor {
  // True if this file should perserve unknown enums within the enum.
  var hasUnknownEnumPreservingSemantics: Bool {
    return syntax == .proto3
  }
}

extension EnumDescriptor {
  // True if this enum should perserve unknown enums within the enum.
  var hasUnknownPreservingSemantics: Bool {
    return file.hasUnknownEnumPreservingSemantics
  }
}
