// swift-tools-version:5.0

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
  ],
  targets: [
    .target(name: "SwiftProtobuf"),
    .target(name: "SwiftProtobufPluginLibrary",
            dependencies: ["SwiftProtobuf"]),
    .target(name: "SwiftProtobufTestHelpers",
            dependencies: ["SwiftProtobuf"]),
    .target(name: "protoc-gen-swift",
            dependencies: ["SwiftProtobufPluginLibrary", "SwiftProtobuf"]),
    .target(name: "Conformance",
            dependencies: ["SwiftProtobuf"]),
    .testTarget(name: "SwiftProtobufTests",
                dependencies: ["SwiftProtobuf"]),
    .testTarget(name: "SwiftProtobufPluginLibraryTests",
                dependencies: ["SwiftProtobufPluginLibrary", "SwiftProtobufTestHelpers"]),
  ],
  swiftLanguageVersions: [.v5]
)
