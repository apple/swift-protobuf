// Sources/protoc-gen-swift/Descriptor+TestHelpers.swift - Additions to Descriptors
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------

import PluginLibrary

extension Google_Protobuf_FileDescriptorProto {
  init(name: String, dependencies: [String] = []) {
    self.init()
    self.name = name
    dependency = dependencies
  }
}

extension Google_Protobuf_EnumValueDescriptorProto {
  init(name: String, number: Int32) {
    self.init()
    self.name = name
    self.number = number
  }
}
