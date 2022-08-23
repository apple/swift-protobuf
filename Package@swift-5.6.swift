// swift-tools-version:5.6

// Package.swift
//
// Copyright (c) 2014 - 2018 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//

import PackageDescription

let package = Package(
  name: "SwiftProtobuf",
  products: [
    .executable(name: "protoc-gen-swift", targets: ["protoc-gen-swift"]),
    .library(name: "SwiftProtobuf", targets: ["SwiftProtobuf"]),
    .library(name: "SwiftProtobufPluginLibrary", targets: ["SwiftProtobufPluginLibrary"]),
    .plugin(
        name: "SwiftProtobufPlugin",
        targets: ["SwiftProtobufPlugin"]
    ),
  ],
  targets: [
    .target(name: "SwiftProtobuf"),
    .target(name: "SwiftProtobufPluginLibrary",
            dependencies: ["SwiftProtobuf"]),
    .target(name: "protoc-gen-swift",
            dependencies: ["SwiftProtobufPluginLibrary", "SwiftProtobuf"]),
    .target(name: "Conformance",
            dependencies: ["SwiftProtobuf"]),
    .plugin(
        name: "SwiftProtobufPlugin",
        capability: .buildTool(),
        dependencies: [
            "protoc-gen-swift"
        ]
    ),
    .testTarget(name: "SwiftProtobufTests",
                dependencies: ["SwiftProtobuf"]),
    .testTarget(name: "SwiftProtobufPluginLibraryTests",
                dependencies: ["SwiftProtobufPluginLibrary"]),
  ],
  swiftLanguageVersions: [.v4, .v4_2, .version("5")]
)
