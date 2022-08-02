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
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
  ],
  targets: [
    .target(name: "SwiftProtobuf",
            exclude: ["CMakeLists.txt"]),
    .target(name: "SwiftProtobufPluginLibrary",
            dependencies: ["SwiftProtobuf"],
            exclude: ["CMakeLists.txt"]),
    .executableTarget(name: "protoc-gen-swift",
            dependencies: ["SwiftProtobufPluginLibrary", "SwiftProtobuf"],
            exclude: ["CMakeLists.txt"]),
    .executableTarget(name: "Conformance",
            dependencies: ["SwiftProtobuf"],
            exclude: ["failure_list_swift.txt", "text_format_failure_list_swift.txt"]),
    .testTarget(name: "SwiftProtobufTests",
                dependencies: ["SwiftProtobuf"]),
    .testTarget(name: "SwiftProtobufPluginLibraryTests",
                dependencies: ["SwiftProtobufPluginLibrary"]),
  ],
  swiftLanguageVersions: [.v5]
)
