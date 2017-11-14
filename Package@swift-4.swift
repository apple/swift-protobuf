// swift-tools-version:4.0

// Package.swift
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//

import PackageDescription

let package = Package(
  name: "SwiftProtobuf",
  products: [
    .executable(name: "protoc-gen-swift", targets: ["protoc-gen-swift"]),
    .library(name: "SwiftProtobuf", type: .static, targets: ["SwiftProtobuf"]),
    .library(name: "SwiftProtobufPluginLibrary", targets: ["PluginLibrary"]),
  ],
  targets: [
    .target(name: "SwiftProtobuf"),
    .target(name: "PluginLibrary",
            dependencies: ["SwiftProtobuf"]),
    .target(name: "protoc-gen-swift",
            dependencies: ["PluginLibrary", "SwiftProtobuf"]),
    .target(name: "Conformance",
            dependencies: ["SwiftProtobuf"]),
    .testTarget(name: "SwiftProtobufTests",
                dependencies: ["SwiftProtobuf"]),
    .testTarget(name: "PluginLibraryTests",
                dependencies: ["PluginLibrary"]),
  ],
  swiftLanguageVersions: [3, 4]
)
