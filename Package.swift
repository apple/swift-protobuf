// Package.swift - description
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//

import PackageDescription

let package = Package(
  name: "SwiftProtobuf",
  targets: [
    Target(name: "SwiftProtobufPluginLibrary",
           dependencies: ["SwiftProtobuf"]),
    Target(name: "protoc-gen-swift",
           dependencies: ["SwiftProtobufPluginLibrary", "SwiftProtobuf"]),
    Target(name: "Conformance",
           dependencies: ["SwiftProtobuf"]),
  ]
)
