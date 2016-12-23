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
    Target(name: "PluginLibrary",
           dependencies: ["SwiftProtobuf"]),
    Target(name: "protoc-gen-swift",
           dependencies: ["PluginLibrary", "SwiftProtobuf"]),
    Target(name: "Conformance",
           dependencies: ["SwiftProtobuf"]),
  ]
)

// Ensure that the dynamic library is created for the performance test harness.
products.append(
  Product(name: "SwiftProtobuf",
          type: .Library(.Dynamic),
          modules: "SwiftProtobuf")
)
