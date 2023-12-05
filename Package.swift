// swift-tools-version:5.8

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
    .executable(
        name: "protoc-gen-swift",
        targets: ["protoc-gen-swift"]
    ),
    .library(
        name: "SwiftProtobuf",
        targets: ["SwiftProtobuf"]
    ),
    .library(
        name: "SwiftProtobufPluginLibrary",
        targets: ["SwiftProtobufPluginLibrary"]
    ),
    .plugin(
        name: "SwiftProtobufPlugin",
        targets: ["SwiftProtobufPlugin"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
  ],
  targets: [
    .target(
        name: "SwiftProtobuf",
        exclude: ["CMakeLists.txt"],
        swiftSettings: [
          .enableUpcomingFeature("ExistentialAny"),
          .enableExperimentalFeature("StrictConcurrency=complete"),
        ]
    ),
    .target(
        name: "SwiftProtobufPluginLibrary",
        dependencies: ["SwiftProtobuf"],
        exclude: ["CMakeLists.txt"],
        swiftSettings: [
          .enableUpcomingFeature("ExistentialAny"),
        ]
    ),
    .target(
        name: "SwiftProtobufTestHelpers",
        dependencies: ["SwiftProtobuf"],
        swiftSettings: [
          .enableUpcomingFeature("ExistentialAny"),
          .enableExperimentalFeature("StrictConcurrency=complete"),
        ]
    ),
    .executableTarget(
        name: "protoc-gen-swift",
        dependencies: ["SwiftProtobufPluginLibrary", "SwiftProtobuf"],
        exclude: ["CMakeLists.txt"],
        swiftSettings: [
          .enableUpcomingFeature("ExistentialAny")
        ]
    ),
    .executableTarget(
        name: "Conformance",
        dependencies: ["SwiftProtobuf"],
        exclude: ["failure_list_swift.txt", "text_format_failure_list_swift.txt"],
        swiftSettings: [
          .enableUpcomingFeature("ExistentialAny"),
        ]
    ),
    .plugin(
        name: "SwiftProtobufPlugin",
        capability: .buildTool(),
        dependencies: [
            "protoc-gen-swift"
        ]
    ),
    .testTarget(
        name: "SwiftProtobufTests",
        dependencies: ["SwiftProtobuf"],
        swiftSettings: [
          .enableUpcomingFeature("ExistentialAny"),
          .enableExperimentalFeature("StrictConcurrency=complete"),
        ]
    ),
    .testTarget(
        name: "SwiftProtobufPluginLibraryTests",
        dependencies: ["SwiftProtobufPluginLibrary", "SwiftProtobufTestHelpers"],
        swiftSettings: [
          .enableUpcomingFeature("ExistentialAny"),
          .enableExperimentalFeature("StrictConcurrency=complete"),
        ]
    ),
    .testTarget(
        name: "protoc-gen-swiftTests",
        dependencies: ["protoc-gen-swift", "SwiftProtobufTestHelpers"],
        swiftSettings: [
          .enableUpcomingFeature("ExistentialAny"),
          .enableExperimentalFeature("StrictConcurrency=complete"),
        ]
    ),
  ],
  swiftLanguageVersions: [.v5]
)
